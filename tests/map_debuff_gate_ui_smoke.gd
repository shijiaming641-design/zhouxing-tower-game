extends SceneTree

const HistoryMapBuilder = preload("res://resources/history_map_builder.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"map_data": game_state.map_data.duplicate(true),
		"current_floor": int(game_state.current_floor),
		"max_floors": int(game_state.max_floors),
		"selected_era_id": str(game_state.selected_era_id),
		"acknowledged_major_layer_debuffs": game_state.acknowledged_major_layer_debuffs.duplicate(),
		"run_active": bool(game_state.run_active)
	}

	game_state.selected_era_id = "qin"
	game_state.max_floors = int(game_state.TOTAL_SMALL_FLOORS)
	game_state.current_floor = 0
	game_state.run_active = true
	game_state.acknowledged_major_layer_debuffs.clear()
	game_state.map_data = HistoryMapBuilder.new().generate("qin", game_state.max_floors)
	_open_only_current_floor(game_state)

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._show_map()
	await process_frame
	if main.current_ui == null or str(main.current_ui.name) != "MajorLayerDebuffGate":
		push_error("Map should show major layer debuff gate before the node map, got: %s" % str(main.current_ui))
		_restore(game_state, original_state, main, 1)
		return

	game_state.mark_current_major_layer_debuff_seen()
	main._show_map()
	await process_frame
	if main.current_ui == null or str(main.current_ui.name) == "MajorLayerDebuffGate":
		push_error("Map should open node map after debuff acknowledgement.")
		_restore(game_state, original_state, main, 1)
		return
	if not _map_has_node(main.current_ui, "Node_0_0") or _map_has_node(main.current_ui, "Node_19_0"):
		push_error("First major layer map should show only floors 1-19.")
		_restore(game_state, original_state, main, 1)
		return

	game_state.current_floor = 19
	game_state.mark_current_major_layer_debuff_seen()
	_open_only_current_floor(game_state)
	main._show_map()
	await process_frame
	if not _map_has_node(main.current_ui, "Node_19_0") or _map_has_node(main.current_ui, "Node_0_0") or _map_has_node(main.current_ui, "Node_38_0"):
		push_error("Second major layer map should show only floors 20-38.")
		_restore(game_state, original_state, main, 1)
		return

	print("map_debuff_gate_ui_smoke: ok")
	_restore(game_state, original_state, main, 0)

func _open_only_current_floor(game_state: Node) -> void:
	for floor_idx in range(game_state.map_data.size()):
		for node in game_state.map_data[floor_idx]:
			node.accessible = floor_idx == int(game_state.current_floor)

func _map_has_node(scene: Node, node_name: String) -> bool:
	if scene == null:
		return false
	var map_container := scene.get_node_or_null("ScrollContainer/MapContainer")
	if map_container == null:
		return false
	return map_container.get_node_or_null(node_name) != null

func _restore(game_state: Node, original_state: Dictionary, main: Node, code: int) -> void:
	if main != null and is_instance_valid(main):
		main.free()
	game_state.map_data = (original_state.get("map_data", []) as Array).duplicate(true)
	game_state.current_floor = int(original_state.get("current_floor", 0))
	game_state.max_floors = int(original_state.get("max_floors", game_state.TOTAL_SMALL_FLOORS))
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.acknowledged_major_layer_debuffs = (original_state.get("acknowledged_major_layer_debuffs", []) as Array).duplicate()
	game_state.run_active = bool(original_state.get("run_active", false))
	quit(code)
