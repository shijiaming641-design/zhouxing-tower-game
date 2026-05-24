extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"player_class": int(game_state.player_class),
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_shield": int(game_state.player_shield),
		"player_attack": int(game_state.player_attack),
		"combo_cooldowns": game_state.combo_cooldowns.duplicate(true),
	}
	game_state.selected_era_id = "qin"
	game_state.player_class = 1
	game_state.player_max_hp = 20
	game_state.player_hp = 20
	game_state.player_shield = 0
	game_state.player_attack = 3
	game_state.combo_cooldowns.clear()

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	main.battle_enemy_max_hp = 30
	main.battle_enemy_hp = 30
	main.battle_enemy_atk = 3
	main.battle_support_enemies.clear()

	var combo_db = main._get_combo_database()
	var all_hit = combo_db.get_combo_by_id("penetrating_strike")
	var overload = combo_db.get_combo_by_id("system_overload")
	if all_hit == null or overload == null:
		push_error("Expected combo spacing probe combos are missing.")
		_finish(1, game_state, original_state, main)
		return
	var expected_damage := int(game_state.get_combo_effect_amount("penetrating_strike", int(all_hit.effect_value), str(all_hit.effect_type))) \
		+ int(game_state.get_combo_effect_amount("system_overload", int(overload.effect_value), str(overload.effect_type)))

	var battle := Control.new()
	battle.name = "ComboFeedbackSpacingProbe"
	root.add_child(battle)
	var impact_label := Label.new()
	impact_label.name = "BattleImpactLabel"
	battle.add_child(impact_label)
	var flash := ColorRect.new()
	flash.name = "BattleFlash"
	battle.add_child(flash)
	for label_name in ["EnemyHP", "PlayerHP", "PlayerAtk"]:
		var label := Label.new()
		label.name = label_name
		battle.add_child(label)

	var triggered: Array[Dictionary] = [
		{"combo": all_hit, "is_equipment": false},
		{"combo": overload, "is_equipment": false},
	]
	var started := Time.get_ticks_msec()
	var combo_phase: Dictionary = await main._run_battle_combo_phase(triggered, battle)
	var elapsed := Time.get_ticks_msec() - started
	if int(main.battle_enemy_hp) != 30 - expected_damage:
		push_error("Combo phase should still apply all damage. hp=%d expected=%d" % [int(main.battle_enemy_hp), 30 - expected_damage])
		_finish(1, game_state, original_state, main, battle)
		return
	if str(combo_phase.get("result_text", "")).strip_edges() == "":
		push_error("Combo phase should return readable result text.")
		_finish(1, game_state, original_state, main, battle)
		return
	if elapsed < 420:
		push_error("Combo phase should keep visible gaps between chained hits. elapsed=%dms" % elapsed)
		_finish(1, game_state, original_state, main, battle)
		return

	print("combo_feedback_spacing_smoke: ok")
	_finish(0, game_state, original_state, main, battle)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node, battle: Node = null) -> void:
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.player_hp = int(original_state.get("player_hp", game_state.player_hp))
	game_state.player_max_hp = int(original_state.get("player_max_hp", game_state.player_max_hp))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.player_attack = int(original_state.get("player_attack", 3))
	game_state.combo_cooldowns = (original_state.get("combo_cooldowns", {}) as Dictionary).duplicate(true)
	if battle != null and is_instance_valid(battle):
		battle.free()
	if main != null and is_instance_valid(main):
		if main.has_method("_dispose_combo_database_cache"):
			main._dispose_combo_database_cache()
		main.free()
	var combo_data_script = load("res://resources/combo_data.gd")
	if combo_data_script != null and combo_data_script.has_method("clear_combo_db_cache"):
		combo_data_script.clear_combo_db_cache()
	quit(code)
