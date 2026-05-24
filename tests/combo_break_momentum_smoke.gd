extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"combo_upgrades": game_state.combo_upgrades.duplicate(true),
		"combo_buffs": game_state.combo_buffs.duplicate(true),
		"combo_cooldowns": game_state.combo_cooldowns.duplicate(true),
		"player_shield": int(game_state.player_shield),
		"player_class": int(game_state.player_class),
		"selected_heirloom_id": str(game_state.selected_heirloom_id),
		"cheat_points": int(game_state.cheat_points),
		"draw_protection_available": bool(game_state.draw_protection_available),
		"draw_protection_armed": bool(game_state.draw_protection_armed),
	}

	game_state.combo_upgrades.clear()
	game_state.combo_buffs.clear()
	game_state.combo_cooldowns.clear()
	game_state.player_class = 0
	game_state.player_shield = 0
	game_state.selected_heirloom_id = ""
	game_state.draw_protection_available = false
	game_state.draw_protection_armed = false

	if game_state.get_combo_upgrade_path_text("penetrating_strike").find("解锁破势") < 0:
		_fail("Default Lv.5 upgrade path should advertise 破势.", game_state, original_state)
		return

	var final_result: Dictionary = {}
	for i in range(5):
		final_result = game_state.grant_combo_event_upgrade("penetrating_strike")
	if str(final_result.get("current_effect", "")).find("破势") < 0:
		_fail("Lv.5 upgrade should unlock 破势, got %s" % str(final_result), game_state, original_state)
		return
	var status: String = game_state.get_combo_upgrade_status_text("penetrating_strike")
	if status.find("破势") < 0 or status.find("减速") >= 0:
		_fail("Upgrade status should show 破势 instead of 减速, got %s" % status, game_state, original_state)
		return

	game_state.combo_upgrades["legacy_slow"] = {"level": 5, "has_burn": true, "has_slow": true}
	if not game_state.has_combo_effect("legacy_slow", "break_momentum"):
		_fail("Old has_slow saves should map to break_momentum.", game_state, original_state)
		return

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var combo = main._get_combo_database().get_combo_by_id("penetrating_strike")
	if combo == null:
		_fail("Expected penetrating_strike combo.", game_state, original_state, main)
		return

	main._battle_round_count = 1
	main.battle_enemy_max_hp = 20
	main.battle_enemy_hp = 20
	var trigger_result: Dictionary = main._apply_single_combo_effect(combo, false, null)
	if str(trigger_result.get("text", "")).find("破势") < 0 or int(game_state.get_combo_buff("break_momentum")) != 1:
		_fail("Triggering Lv.5 layout should arm 破势 for the next beat, got %s buff=%d" % [str(trigger_result), int(game_state.get_combo_buff("break_momentum"))], game_state, original_state, main)
		return

	main._enemy_move_history.clear()
	main._enemy_move_history.append(1)
	main._enemy_move_history.append(1)
	main.battle_enemy_hp = 20
	game_state.player_shield = 0
	var no_triggered: Array[Dictionary] = []
	var same_round: Dictionary = main._resolve_turn_exchange(0, 0, no_triggered, false, false, null)
	if int(main.battle_enemy_hp) != 20 or int(game_state.player_shield) != 0 or str(same_round.get("text", "")).find("破势") >= 0:
		_fail("破势 should not resolve on the same beat it is armed. hp=%d shield=%d text=%s" % [int(main.battle_enemy_hp), int(game_state.player_shield), str(same_round.get("text", ""))], game_state, original_state, main)
		return

	main._battle_round_count = 2
	main.battle_enemy_hp = 20
	game_state.player_shield = 0
	var next_round: Dictionary = main._resolve_turn_exchange(0, 0, no_triggered, false, false, null)
	var next_text := str(next_round.get("text", ""))
	if int(main.battle_enemy_hp) != 18 or int(game_state.player_shield) != 2 or next_text.find("破势") < 0 or next_text.find("抓旧手-2") < 0:
		_fail("破势 should punish repeated enemy hands and reward draws next beat. hp=%d shield=%d text=%s" % [int(main.battle_enemy_hp), int(game_state.player_shield), next_text], game_state, original_state, main)
		return

	print("combo_break_momentum_smoke: ok")
	_finish(0, game_state, original_state, main)

func _fail(message: String, game_state: Node, original_state: Dictionary, main: Node = null) -> void:
	push_error(message)
	_finish(1, game_state, original_state, main)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node = null) -> void:
	if main != null and is_instance_valid(main):
		if main.has_method("_dispose_combo_database_cache"):
			main._dispose_combo_database_cache()
		main.queue_free()
	game_state.combo_upgrades = (original_state.get("combo_upgrades", {}) as Dictionary).duplicate(true)
	game_state.combo_buffs = (original_state.get("combo_buffs", {}) as Dictionary).duplicate(true)
	game_state.combo_cooldowns = (original_state.get("combo_cooldowns", {}) as Dictionary).duplicate(true)
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.selected_heirloom_id = str(original_state.get("selected_heirloom_id", ""))
	game_state.cheat_points = int(original_state.get("cheat_points", 0))
	game_state.draw_protection_available = bool(original_state.get("draw_protection_available", false))
	game_state.draw_protection_armed = bool(original_state.get("draw_protection_armed", false))
	quit(code)
