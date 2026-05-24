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
		"route_switch_count": int(game_state.route_switch_count),
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_shield": int(game_state.player_shield),
		"cheat_points": int(game_state.cheat_points),
		"player_gold": int(game_state.player_gold),
		"materials": int(game_state.materials),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"equipment_upgrades": game_state.equipment_upgrades.duplicate(true),
		"equipped_combos": game_state.get_equipped_combos().duplicate()
	}

	game_state.selected_era_id = "qin"
	game_state.current_floor = 0
	game_state.max_floors = 3
	game_state.selected_route_name = ""
	game_state.route_switch_count = 0
	game_state.player_hp = 7
	game_state.player_max_hp = 10
	game_state.player_shield = 2
	game_state.cheat_points = 1
	game_state.player_gold = 12
	game_state.materials = 1
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["long_sword"].duplicate(true))
	game_state.equipment_upgrades.clear()
	game_state.get_equipped_combos().clear()
	game_state.get_equipped_combos().append("energy_charge")
	game_state.map_data = HistoryMapBuilder.new().generate("qin", game_state.max_floors)
	for floor_idx in range(game_state.map_data.size()):
		for node in game_state.map_data[floor_idx]:
			node.accessible = false
			node.visited = false
	var current_node := (game_state.map_data[0] as Array)[0] as Dictionary
	current_node["type"] = 0
	current_node["route_name"] = "近攻线"
	current_node["phase_name"] = "试运营"
	current_node["event_title"] = "高压遭遇"
	current_node["event_desc"] = "检验当前血线。"
	current_node["difficulty_tier"] = "danger"
	current_node["reward_profile"] = "rare"
	current_node["accessible"] = true
	current_node["visited"] = false

	var scene = load("res://scenes/ui/map_scene.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var status_label := scene.get_node_or_null("StatusLabel") as Label
	var player_card := scene.get_node_or_null("PlayerInfoCard") as Panel
	var player_stats := scene.get_node_or_null("PlayerInfoCard/PlayerInfoStats") as Label
	if player_card == null or player_stats == null or player_stats.text.find("命 7/10") < 0 or player_stats.text.find("甲 2") < 0 or player_stats.text.find("机 1/") < 0:
		push_error("Map should expose character stats in a separate player card, got: %s" % (player_stats.text if player_stats != null else "<missing>"))
		_finish(1, scene, game_state, original_state)
		return
	if status_label == null or status_label.text.find("金币 12") < 0 or status_label.text.find("可强化") < 0:
		push_error("Map should expose an operation summary, got: %s" % (status_label.text if status_label != null else "<missing>"))
		_finish(1, scene, game_state, original_state)
		return
	if status_label.text.find("命") >= 0 or status_label.text.find("甲") >= 0 or status_label.text.find("机") >= 0:
		push_error("Map operation summary should not mix character stats with gold, got: %s" % status_label.text)
		_finish(1, scene, game_state, original_state)
		return

	var node_button := scene.get_node_or_null("ScrollContainer/MapContainer/Node_0_0") as Button
	if node_button == null:
		push_error("Map should create the current operation node.")
		_finish(1, scene, game_state, original_state)
		return
	if node_button.tooltip_text.find("代价") < 0 or node_button.tooltip_text.find("高压战") < 0:
		push_error("Node tooltip should explain operation cost, got: %s" % node_button.tooltip_text)
		_finish(1, scene, game_state, original_state)
		return
	if not _map_has_label_text(scene, "险｜稀｜伤"):
		push_error("Map node feedback should show difficulty, reward, and cost.")
		_finish(1, scene, game_state, original_state)
		return

	print("map_operation_ui_smoke: ok")
	_finish(0, scene, game_state, original_state)

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
	game_state.player_hp = int(original_state.get("player_hp", 6))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 6))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.cheat_points = int(original_state.get("cheat_points", 0))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.materials = int(original_state.get("materials", 0))
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.equipment_upgrades = (original_state.get("equipment_upgrades", {}) as Dictionary).duplicate(true)
	game_state.get_equipped_combos().clear()
	for combo_id in (original_state.get("equipped_combos", []) as Array):
		game_state.get_equipped_combos().append(str(combo_id))
	quit(code)
