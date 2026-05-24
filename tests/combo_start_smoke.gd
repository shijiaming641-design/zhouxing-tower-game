extends SceneTree

func _finish(code: int, combo_db: Node = null) -> void:
	if combo_db != null:
		combo_db.free()
	quit(code)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_era := str(game_state.selected_era_id)
	var combo_db = load("res://resources/combo_database.gd").new()
	combo_db._init_database()

	for era_id in ["qin", "song", "china"]:
		game_state.selected_era_id = era_id
		combo_db._apply_unlock_progression()
		var selectable = combo_db.get_start_selectable_combos()
		var selectable_ids := []
		for combo in selectable:
			selectable_ids.append(str(combo.id))
			if combo.sequence.size() != 3:
				push_error("Start selection should only show 3-step layouts: %s" % combo.id)
				game_state.selected_era_id = original_era
				_finish(1, combo_db)
				return
		if selectable_ids.size() != 6:
			push_error("Start selection should show 5 common layouts plus 1 era layout in %s, got %s" % [era_id, str(selectable_ids)])
			game_state.selected_era_id = original_era
			_finish(1, combo_db)
			return
		for removed_id in ["energy_charge", "cyclic_shield", "bind_fatal"]:
			if removed_id in selectable_ids:
				push_error("%s should be held back from the initial common pool." % removed_id)
				game_state.selected_era_id = original_era
				_finish(1, combo_db)
				return
	for combo in combo_db.get_start_selectable_combos():
		if combo.sequence.size() != 3 and combo.sequence.size() != 4:
			push_error("Found invalid sequence length in start selection: %s" % combo.id)
			game_state.selected_era_id = original_era
			_finish(1, combo_db)
			return

	game_state.selected_era_id = original_era
	combo_db._apply_unlock_progression()
	var allowed_combo_ids: Array[String] = ["penetrating_strike"]
	var last_3: Array[int] = [1, 1, 2]
	var matched_id := ""

	for combo in combo_db.get_all_combos():
		if not combo.is_unlocked:
			continue
		if combo.sequence.size() != 3:
			continue
		if not combo.id in allowed_combo_ids:
			continue
		var match_found = true
		for i in range(3):
			if last_3[i] != combo.sequence[i]:
				match_found = false
				break
		if match_found:
			matched_id = combo.id
			break

	if matched_id != "penetrating_strike":
		push_error("Expected penetrating_strike to match, got: %s" % matched_id)
		_finish(1, combo_db)
		return

	var four_step = combo_db.get_combo_by_id("formation_breaker")
	if four_step == null or four_step.sequence.size() != 4:
		push_error("Expected formation_breaker to provide a 4-step terminal layout.")
		_finish(1, combo_db)
		return

	print("combo_start_smoke: ok")
	_finish(0, combo_db)
