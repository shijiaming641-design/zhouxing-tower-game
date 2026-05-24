extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"player_class": int(game_state.player_class),
		"equipped_combos": game_state.get_equipped_combos().duplicate(true),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"backpack": game_state.backpack.duplicate(true)
	}

	game_state.selected_era_id = "qin"
	game_state.player_class = 0
	game_state.equipped_combos.clear()
	for combo_id in ["penetrating_strike", "tactical_interference", "lightning_strike"]:
		game_state.equipped_combos.append(combo_id)
	game_state.equipment_slot.clear()
	game_state.backpack.clear()

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	_set_combo_sequence(main, [1])
	var one_step_hint := str(main._get_combo_progress_text())
	if one_step_hint.find("可接") < 0 or one_step_hint.find("军阵贯杀") < 0 or one_step_hint.find("军令扰阵") < 0:
		push_error("One-step hint should show possible next routes, got: %s" % one_step_hint)
		_finish(1, game_state, original_state, main)
		return

	_set_combo_sequence(main, [1, 1])
	var two_step_hint := str(main._get_combo_progress_text())
	if two_step_hint.find("临门一脚") < 0 or two_step_hint.find("地") < 0 or two_step_hint.find("军阵贯杀") < 0:
		push_error("Two-step hint should show the exact finishing move, got: %s" % two_step_hint)
		_finish(1, game_state, original_state, main)
		return

	_set_combo_sequence(main, [2, 0])
	var class_hint := str(main._get_combo_progress_text())
	if class_hint.find("临门一脚") < 0 or class_hint.find("军医望诊") < 0:
		push_error("Hints should include current class layouts, got: %s" % class_hint)
		_finish(1, game_state, original_state, main)
		return

	_set_combo_sequence(main, [0, 0])
	var broken_hint := str(main._get_combo_progress_text())
	if broken_hint.find("布局断线") < 0:
		push_error("Broken route should ask player to re-probe, got: %s" % broken_hint)
		_finish(1, game_state, original_state, main)
		return

	print("combo_route_hint_smoke: ok")
	_finish(0, game_state, original_state, main)

func _set_combo_sequence(main: Node, moves: Array) -> void:
	main.combo_sequence.clear()
	for move in moves:
		main.combo_sequence.append(int(move))

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node) -> void:
	if main != null and is_instance_valid(main):
		if main.has_method("_dispose_combo_database_cache"):
			main._dispose_combo_database_cache()
		main.free()
	var combo_data_script = load("res://resources/combo_data.gd")
	if combo_data_script != null and combo_data_script.has_method("clear_combo_db_cache"):
		combo_data_script.clear_combo_db_cache()
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.equipped_combos.clear()
	for combo_id in (original_state.get("equipped_combos", []) as Array):
		game_state.equipped_combos.append(str(combo_id))
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.backpack = (original_state.get("backpack", []) as Array).duplicate(true)
	quit(code)
