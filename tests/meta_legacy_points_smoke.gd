extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"memory_cores": int(game_state.memory_cores),
		"meta_upgrades": game_state.meta_upgrades.duplicate(true),
		"current_floor": int(game_state.current_floor),
		"max_floors": int(game_state.max_floors),
		"runs_played": int(game_state.runs_played),
		"total_wins": int(game_state.total_wins),
		"run_active": bool(game_state.run_active),
		"checkpoint_scene": str(game_state.checkpoint_scene),
		"class_first_clears": game_state.class_first_clears.duplicate(true),
		"era_first_clears": game_state.era_first_clears.duplicate(true),
		"selected_era_id": str(game_state.selected_era_id)
	}

	game_state.memory_cores = 4
	game_state.meta_upgrades.clear()
	game_state.era_first_clears.clear()
	var definitions: Array = game_state.get_meta_upgrade_definitions()
	if definitions.size() > 12:
		push_error("Meta upgrades should stay compact and easy to scan.")
		_finish(1, game_state, original_state)
		return
	if not _meta_camps_are_ready(definitions):
		push_error("Meta upgrades should use four preparation camps: 粮仓、军械库、演武场、宗祠.")
		_finish(1, game_state, original_state)
		return
	if int(game_state.get_meta_upgrade_total_cost()) != 138:
		push_error("Meta upgrade total cost should be 138, got %d." % int(game_state.get_meta_upgrade_total_cost()))
		_finish(1, game_state, original_state)
		return
	if game_state.can_purchase_meta_upgrade("basic_combo_slot"):
		push_error("Basic meta upgrade should cost more than 4 legacy points.")
		_finish(1, game_state, original_state)
		return
	game_state.memory_cores = 5
	if not game_state.purchase_meta_upgrade("basic_combo_slot").get("success", false):
		push_error("Basic meta upgrade should be purchasable with 5 legacy points.")
		_finish(1, game_state, original_state)
		return

	if int(game_state.get_era_full_clear_legacy_estimate("qin")) != 14:
		push_error("Qin full-clear estimate should be 14 legacy points.")
		_finish(1, game_state, original_state)
		return
	if int(game_state.get_era_full_clear_legacy_estimate("song")) != 21:
		push_error("Song full-clear estimate should be 21 legacy points.")
		_finish(1, game_state, original_state)
		return
	if int(game_state.get_era_full_clear_legacy_estimate("china")) != 28:
		push_error("China full-clear estimate should be 28 legacy points.")
		_finish(1, game_state, original_state)
		return

	game_state.memory_cores = 0
	game_state.meta_upgrades.clear()
	game_state.era_first_clears.clear()
	game_state.max_floors = int(game_state.TOTAL_SMALL_FLOORS)
	game_state.selected_era_id = "qin"
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	if int(main._award_major_layer_legacy_points(18)) != 2:
		push_error("Clearing first major layer should award 2 legacy points.")
		_finish(1, game_state, original_state, main)
		return
	if int(main._award_major_layer_legacy_points(37)) != 3:
		push_error("Clearing second major layer should award 3 legacy points.")
		_finish(1, game_state, original_state, main)
		return
	if int(main._award_major_layer_legacy_points(56)) != 0:
		push_error("Final floor should not duplicate major-layer legacy points; clear bonus handles it.")
		_finish(1, game_state, original_state, main)
		return
	if int(game_state.memory_cores) != 5:
		push_error("Major layer legacy awards should total 5, got %d." % int(game_state.memory_cores))
		_finish(1, game_state, original_state, main)
		return

	game_state.run_active = true
	game_state.current_floor = int(game_state.max_floors) - 1
	game_state.complete_run(true)
	if int(game_state.memory_cores) != 11:
		push_error("Clearing a Qin run should add 6 legacy points after layer awards, got %d." % int(game_state.memory_cores))
		_finish(1, game_state, original_state, main)
		return
	if not game_state.has_era_first_clear("qin") or int(game_state.get_meta_upgrade_stage()) != 1:
		push_error("Clearing Qin should record era clear and open stage 1 logistics.")
		_finish(1, game_state, original_state, main)
		return

	print("meta_legacy_points_smoke: ok")
	_finish(0, game_state, original_state, main)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node = null) -> void:
	if main != null and is_instance_valid(main):
		main.queue_free()
	game_state.memory_cores = int(original_state.get("memory_cores", 0))
	game_state.meta_upgrades = (original_state.get("meta_upgrades", {}) as Dictionary).duplicate(true)
	game_state.current_floor = int(original_state.get("current_floor", 0))
	game_state.max_floors = int(original_state.get("max_floors", game_state.TOTAL_SMALL_FLOORS))
	game_state.runs_played = int(original_state.get("runs_played", 0))
	game_state.total_wins = int(original_state.get("total_wins", 0))
	game_state.run_active = bool(original_state.get("run_active", false))
	game_state.checkpoint_scene = str(original_state.get("checkpoint_scene", "map"))
	game_state.class_first_clears = (original_state.get("class_first_clears", {}) as Dictionary).duplicate(true)
	game_state.era_first_clears = (original_state.get("era_first_clears", {}) as Dictionary).duplicate(true)
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.save_progress()
	quit(code)

func _meta_camps_are_ready(definitions: Array) -> bool:
	var expected := ["粮仓", "军械库", "演武场", "宗祠"]
	var seen := {}
	for category in expected:
		seen[category] = false
	for definition in definitions:
		var category := str((definition as Dictionary).get("category", ""))
		if seen.has(category):
			seen[category] = true
	for category in expected:
		if not bool(seen.get(category, false)):
			return false
	return true
