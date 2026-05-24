extends SceneTree

const HistoryMapBuilder = preload("res://resources/history_map_builder.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"run_active": bool(game_state.run_active),
		"checkpoint_scene": str(game_state.checkpoint_scene),
		"selected_era_id": str(game_state.selected_era_id),
		"current_floor": int(game_state.current_floor),
		"max_floors": int(game_state.max_floors),
		"map_data": game_state.map_data.duplicate(true),
		"selected_route_name": str(game_state.selected_route_name),
		"route_switch_count": int(game_state.route_switch_count),
		"acknowledged_major_layer_debuffs": game_state.acknowledged_major_layer_debuffs.duplicate(),
		"player_class": int(game_state.player_class),
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_attack": int(game_state.player_attack),
		"player_gold": int(game_state.player_gold)
	}

	game_state.run_active = true
	game_state.checkpoint_scene = "map"
	game_state.selected_era_id = "qin"
	game_state.player_class = 0
	game_state.player_max_hp = 10
	game_state.player_hp = 10
	game_state.player_attack = 2
	game_state.player_gold = 20
	game_state.max_floors = game_state.TOTAL_SMALL_FLOORS
	game_state.current_floor = 0
	game_state.selected_route_name = ""
	game_state.route_switch_count = 0
	game_state.acknowledged_major_layer_debuffs.clear()
	game_state.mark_current_major_layer_debuff_seen()
	game_state.map_data = HistoryMapBuilder.new().generate("qin", game_state.max_floors)
	for floor_idx in range(game_state.map_data.size()):
		for node in game_state.map_data[floor_idx]:
			node["visited"] = false
			node["accessible"] = floor_idx == 0
	var first_node := (game_state.map_data[0] as Array)[0] as Dictionary
	first_node["type"] = 0
	first_node["accessible"] = true

	var main = load("res://scenes/main.gd").new()
	root.add_child(main)
	main._resume_saved_run()
	await process_frame
	await process_frame

	var map_scene: Node = main.current_ui
	if map_scene == null or map_scene.name != "MapScene":
		_fail("Resume should open map scene before node selection.", game_state, original_state, main)
		return

	var node_button := map_scene.get_node_or_null("ScrollContainer/MapContainer/Node_0_0") as Button
	if node_button == null:
		_fail("Map should expose current node button after resume.", game_state, original_state, main)
		return
	node_button.pressed.emit()

	await create_timer(1.0).timeout

	if main.current_ui == map_scene and map_scene.get_node_or_null("NodeCommitOverlay") != null:
		_fail("Clicking a map node should leave the route detail overlay and enter the selected node.", game_state, original_state, main)
		return
	if main.current_ui == null or main.current_ui.name == "MapScene":
		_fail("Clicking a map node should transition away from map scene, got: %s" % (main.current_ui.name if main.current_ui != null else "null"), game_state, original_state, main)
		return

	print("map_node_click_commit_smoke: ok")
	_finish(0, game_state, original_state, main)

func _fail(message: String, game_state: Node, original_state: Dictionary, main: Node) -> void:
	push_error(message)
	_finish(1, game_state, original_state, main)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node) -> void:
	if main != null:
		if main.get_parent() != null:
			main.get_parent().remove_child(main)
		main.free()
	game_state.run_active = bool(original_state.get("run_active", false))
	game_state.checkpoint_scene = str(original_state.get("checkpoint_scene", "map"))
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.current_floor = int(original_state.get("current_floor", 0))
	game_state.max_floors = int(original_state.get("max_floors", game_state.TOTAL_SMALL_FLOORS))
	game_state.map_data = (original_state.get("map_data", []) as Array).duplicate(true)
	game_state.selected_route_name = str(original_state.get("selected_route_name", ""))
	game_state.route_switch_count = int(original_state.get("route_switch_count", 0))
	game_state.acknowledged_major_layer_debuffs = (original_state.get("acknowledged_major_layer_debuffs", []) as Array).duplicate()
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.player_hp = int(original_state.get("player_hp", 1))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 10))
	game_state.player_attack = int(original_state.get("player_attack", 2))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	quit(code)
