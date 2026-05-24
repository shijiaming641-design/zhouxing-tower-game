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
		"combo_buffs": game_state.combo_buffs.duplicate(true),
		"combo_cooldowns": game_state.combo_cooldowns.duplicate(true)
	}

	game_state.selected_era_id = "qin"
	game_state.player_class = 1
	game_state.player_max_hp = 10
	game_state.player_hp = 10
	game_state.player_shield = 0
	game_state.player_attack = 2
	game_state.combo_buffs.clear()
	game_state.combo_cooldowns.clear()

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var combo_db = main._get_combo_database()
	var virus_combo = combo_db.get_combo_by_id("virus_implant")
	if virus_combo == null:
		push_error("virus_implant combo should exist.")
		_finish(1, game_state, original_state, main)
		return

	main.battle_enemy_hp = 20
	var combo_result: Dictionary = main._apply_single_combo_effect(virus_combo, false)
	if str(combo_result.get("text", "")).find("眩晕") < 0:
		push_error("virus_implant should report stun, got: %s" % str(combo_result))
		_finish(1, game_state, original_state, main)
		return
	if int(game_state.get_combo_buff("enemy_stun")) <= 0:
		push_error("virus_implant should apply enemy_stun immediately.")
		_finish(1, game_state, original_state, main)
		return

	game_state.process_combo_buffs()
	if int(game_state.get_combo_buff("enemy_stun")) <= 0:
		push_error("enemy_stun should survive until the next turn after combo phase.")
		_finish(1, game_state, original_state, main)
		return

	var hp_before := int(game_state.player_hp)
	main.battle_enemy_atk = 5
	var triggered_combos: Array[Dictionary] = []
	var dummy_battle := Control.new()
	var exchange_result: Dictionary = main._resolve_turn_exchange(0, 2, triggered_combos, false, false, dummy_battle)
	dummy_battle.free()
	if str(exchange_result.get("text", "")).find("眩晕跳过") < 0:
		push_error("Next lost exchange should be skipped by stun, got: %s" % str(exchange_result))
		_finish(1, game_state, original_state, main)
		return
	if int(game_state.player_hp) != hp_before:
		push_error("Stunned enemy should not damage player. HP %d -> %d" % [hp_before, int(game_state.player_hp)])
		_finish(1, game_state, original_state, main)
		return

	print("class_combo_stun_smoke: ok")
	_finish(0, game_state, original_state, main)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node) -> void:
	if main != null and is_instance_valid(main):
		main.free()
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.player_hp = int(original_state.get("player_hp", 6))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 6))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.player_attack = int(original_state.get("player_attack", 2))
	game_state.combo_buffs = (original_state.get("combo_buffs", {}) as Dictionary).duplicate(true)
	game_state.combo_cooldowns = (original_state.get("combo_cooldowns", {}) as Dictionary).duplicate(true)
	quit(code)
