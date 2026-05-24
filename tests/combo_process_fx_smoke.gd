extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"player_class": int(game_state.player_class),
		"equipped_combos": game_state.equipped_combos.duplicate(true)
	}
	game_state.selected_era_id = "qin"
	game_state.player_class = 0
	game_state.equipped_combos.clear()
	game_state.equipped_combos.append("penetrating_strike")

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var combo_db = main._get_combo_database()
	var combo = combo_db.get_combo_by_id("penetrating_strike")
	if combo == null:
		_fail("Expected penetrating_strike combo.", game_state, original_state, main)
		return

	main.combo_sequence.clear()
	main.combo_sequence.append(1)
	main.combo_sequence.append(1)
	var battle := _make_battle_probe()
	root.add_child(battle)
	main._update_combo_linchpin_feedback(battle)
	var subtitle := battle.get_node("BattleMoveSubtitle2") as Label
	if subtitle.text != "临门":
		_fail("2/3 combo route should light the finishing move button.", game_state, original_state, main, battle)
		return
	var progress := battle.get_node("ComboProgress") as Label
	if progress.text.find("暗势") < 0 or progress.text.find("临门") < 0:
		_fail("Linchpin feedback should pulse combo progress text.", game_state, original_state, main, battle)
		return

	var triggered: Array[Dictionary] = [{"combo": combo, "is_equipment": false, "length": 3}]
	_set_process_history(main, [1, 1, 2], [2, 2, 0])
	if main._get_combo_completion_impact_type(triggered) != "combo_clean":
		_fail("All-win combo process should use clean gold feedback.", game_state, original_state, main, battle)
		return
	if str(main._get_combo_completion_hint(triggered, 0)).find("全胜成势") < 0:
		_fail("Clean process should be named in completion hint.", game_state, original_state, main, battle)
		return

	_set_process_history(main, [1, 1, 2], [0, 2, 0])
	if main._get_combo_completion_impact_type(triggered) != "combo_bloody":
		_fail("Damaged/lost exchange inside combo process should use bloody feedback.", game_state, original_state, main, battle)
		return

	_set_process_history(main, [1, 1, 2], [1, 2, 0])
	if main._get_combo_completion_impact_type(triggered) != "combo_guarded":
		_fail("Draw inside combo process should use guarded feedback.", game_state, original_state, main, battle)
		return

	_set_process_history(main, [0, 1, 2], [1, 1, 0])
	if main._get_combo_completion_impact_type(triggered) != "combo_read":
		_fail("Repeated enemy hand inside combo process should use read feedback.", game_state, original_state, main, battle)
		return

	print("combo_process_fx_smoke: ok")
	_finish(0, game_state, original_state, main, battle)

func _make_battle_probe() -> Control:
	var battle := Control.new()
	battle.name = "ComboProcessFxProbe"
	var panel := Panel.new()
	panel.name = "ComboResourcePanel"
	battle.add_child(panel)
	var progress := Label.new()
	progress.name = "ComboProgress"
	battle.add_child(progress)
	for i in range(3):
		var card := Panel.new()
		card.name = "BattleMoveCard%d" % i
		battle.add_child(card)
		var btn := Button.new()
		btn.name = "BattleMoveButton%d" % i
		btn.set_meta("battle_move_button", true)
		btn.set_meta("move_idx", i)
		btn.set_meta("base_subtitle", "试探")
		battle.add_child(btn)
		var title := Label.new()
		title.name = "BattleMoveTitle%d" % i
		battle.add_child(title)
		var subtitle := Label.new()
		subtitle.name = "BattleMoveSubtitle%d" % i
		battle.add_child(subtitle)
		var key := Label.new()
		key.name = "BattleMoveKey%d" % i
		battle.add_child(key)
	return battle

func _set_process_history(main: Node, player_moves: Array, enemy_moves: Array) -> void:
	main._player_move_history.clear()
	main._enemy_move_history.clear()
	for move in player_moves:
		main._player_move_history.append(int(move))
	for move in enemy_moves:
		main._enemy_move_history.append(int(move))

func _fail(message: String, game_state: Node, original_state: Dictionary, main: Node, battle: Node = null) -> void:
	push_error(message)
	_finish(1, game_state, original_state, main, battle)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node, battle: Node = null) -> void:
	if battle != null and is_instance_valid(battle):
		battle.free()
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
	quit(code)
