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
		"selected_route_name": str(game_state.selected_route_name),
		"route_switch_count": int(game_state.route_switch_count)
	}

	seed(9105)
	game_state.selected_era_id = "qin"
	game_state.max_floors = int(game_state.TOTAL_SMALL_FLOORS)
	game_state.current_floor = 5
	game_state.map_data = HistoryMapBuilder.new().generate("qin", game_state.max_floors)
	for floor_idx in range(game_state.map_data.size()):
		for node in game_state.map_data[floor_idx]:
			node.accessible = floor_idx == game_state.current_floor

	var scene = load("res://scenes/ui/map_scene.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var checkpoint := _find_checkpoint_node(game_state.map_data[5])
	if checkpoint.node_idx < 0:
		push_error("Generated map should include a visible checkpoint node on floor 6.")
		_finish(1, scene, game_state, original_state)
		return

	var node_button := scene.get_node_or_null("ScrollContainer/MapContainer/Node_5_%d" % checkpoint.node_idx) as Button
	if node_button == null:
		push_error("Map UI should create a button for the checkpoint node.")
		_finish(1, scene, game_state, original_state)
		return
	if not _button_has_checkpoint_mark(node_button):
		push_error("Checkpoint node button should use a compact checkpoint mark, got: %s" % node_button.text)
		_finish(1, scene, game_state, original_state)
		return
	if not _map_has_label_text(scene, "稳") and not _map_has_label_text(scene, "中") and not _map_has_label_text(scene, "难") and not _map_has_label_text(scene, "险"):
		push_error("Map UI should show compact difficulty labels.")
		_finish(1, scene, game_state, original_state)
		return
	if not _map_has_label_text(scene, "材") and not _map_has_label_text(scene, "钱") and not _map_has_label_text(scene, "稀"):
		push_error("Map UI should show compact reward labels.")
		_finish(1, scene, game_state, original_state)
		return
	if not _map_has_label_text(scene, "检点"):
		push_error("Map UI should mark the checkpoint floor label.")
		_finish(1, scene, game_state, original_state)
		return

	print("map_checkpoint_ui_smoke: ok")
	_finish(0, scene, game_state, original_state)

func _find_checkpoint_node(floor_data: Array) -> Dictionary:
	for idx in range(floor_data.size()):
		var node := floor_data[idx] as Dictionary
		if str(node.get("checkpoint_tier", "")) == "mid_build":
			return {"node_idx": idx, "node": node}
	return {"node_idx": -1, "node": {}}

func _button_has_checkpoint_mark(button: Button) -> bool:
	for mark in ["补", "试", "稳", "注", "检"]:
		if button.text.find(mark) >= 0:
			return true
	return false

func _map_has_label_text(scene: Node, needle: String) -> bool:
	var map_container := scene.get_node_or_null("ScrollContainer/MapContainer")
	if map_container == null:
		return false
	return _node_tree_has_label_text(map_container, needle)

func _node_tree_has_label_text(node: Node, needle: String) -> bool:
	if node is Label and (node as Label).text.find(needle) >= 0:
		return true
	for child in node.get_children():
		if _node_tree_has_label_text(child, needle):
			return true
	return false

func _finish(code: int, scene: Node, game_state: Node, original_state: Dictionary) -> void:
	if scene != null:
		scene.queue_free()
	game_state.map_data = (original_state.get("map_data", []) as Array).duplicate(true)
	game_state.current_floor = int(original_state.get("current_floor", 0))
	game_state.max_floors = int(original_state.get("max_floors", game_state.TOTAL_SMALL_FLOORS))
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.selected_route_name = str(original_state.get("selected_route_name", ""))
	game_state.route_switch_count = int(original_state.get("route_switch_count", 0))
	quit(code)
