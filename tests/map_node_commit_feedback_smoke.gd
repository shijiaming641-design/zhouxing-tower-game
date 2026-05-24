extends SceneTree

const HistoryMapBuilder = preload("res://resources/history_map_builder.gd")

var _selected_index: int = -1

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
		"route_switch_count": int(game_state.route_switch_count),
		"player_gold": int(game_state.player_gold),
		"materials": int(game_state.materials)
	}

	game_state.selected_era_id = "qin"
	game_state.current_floor = 0
	game_state.max_floors = 3
	game_state.selected_route_name = ""
	game_state.route_switch_count = 0
	game_state.player_gold = 12
	game_state.materials = 2
	game_state.map_data = HistoryMapBuilder.new().generate("qin", game_state.max_floors)
	for floor_idx in range(game_state.map_data.size()):
		for node in game_state.map_data[floor_idx]:
			node.accessible = false
			node.visited = false

	var current_node := (game_state.map_data[0] as Array)[0] as Dictionary
	current_node["type"] = 0
	current_node["route_name"] = "近攻线"
	current_node["phase_name"] = "试运营"
	current_node["event_title"] = "险战"
	current_node["event_desc"] = "这一战会检验血线。"
	current_node["difficulty_tier"] = "danger"
	current_node["reward_profile"] = "rare"
	current_node["accessible"] = true

	var scene = load("res://scenes/ui/map_scene.tscn").instantiate()
	scene.node_selected.connect(func(index: int): _selected_index = index)
	root.add_child(scene)
	await process_frame
	await process_frame

	scene._on_node_clicked(0, 0)
	await process_frame

	var overlay: Node = scene.get_node_or_null("NodeCommitOverlay")
	if overlay == null:
		push_error("Node click should show a short commit feedback overlay before entering the node.")
		_finish(1, scene, game_state, original_state)
		return

	var body := overlay.get_node_or_null("CommitPanel/CommitBody") as Label
	if body == null or body.text.find("路线：锁定近攻线") < 0 or body.text.find("代价：高压战") < 0 or body.text.find("预期：高收益") < 0:
		push_error("Commit feedback should summarize route, cost, and reward, got: %s" % (body.text if body != null else "<missing>"))
		_finish(1, scene, game_state, original_state)
		return

	await create_timer(0.75).timeout
	if _selected_index != 0:
		push_error("Map should emit node_selected after short feedback, got: %d" % _selected_index)
		_finish(1, scene, game_state, original_state)
		return

	if game_state.selected_route_name != "近攻线":
		push_error("Commit feedback should preserve the route lock side effect.")
		_finish(1, scene, game_state, original_state)
		return

	print("map_node_commit_feedback_smoke: ok")
	_finish(0, scene, game_state, original_state)

func _finish(code: int, scene: Node, game_state: Node, original_state: Dictionary) -> void:
	if scene != null:
		scene.queue_free()
	game_state.map_data = (original_state.get("map_data", []) as Array).duplicate(true)
	game_state.current_floor = int(original_state.get("current_floor", 0))
	game_state.max_floors = int(original_state.get("max_floors", game_state.TOTAL_SMALL_FLOORS))
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.selected_route_name = str(original_state.get("selected_route_name", ""))
	game_state.route_switch_count = int(original_state.get("route_switch_count", 0))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.materials = int(original_state.get("materials", 0))
	quit(code)
