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
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_attack": int(game_state.player_attack),
		"player_gold": int(game_state.player_gold),
		"materials": int(game_state.materials),
		"selected_heirloom_id": str(game_state.selected_heirloom_id),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"backpack": game_state.backpack.duplicate(true),
		"equipped_combos": game_state.get_equipped_combos().duplicate()
	}

	game_state.selected_era_id = "qin"
	game_state.max_floors = int(game_state.TOTAL_SMALL_FLOORS)
	game_state.current_floor = 3
	game_state.selected_route_name = "远交线"
	game_state.player_hp = 8
	game_state.player_max_hp = 12
	game_state.player_attack = 3
	game_state.player_gold = 11
	game_state.materials = 4
	game_state.selected_heirloom_id = "shield_blade"
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["long_sword"].duplicate(true))
	game_state.backpack.clear()
	game_state.backpack.append(game_state.ITEMS["life_crystal"].duplicate(true))
	game_state.get_equipped_combos().clear()
	game_state.get_equipped_combos().append("energy_charge")
	game_state.map_data = HistoryMapBuilder.new().generate("qin", game_state.max_floors)

	var scene = load("res://scenes/ui/map_scene.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var info_btn := scene.get_node_or_null("PlayerInfoButton") as Button
	if info_btn == null:
		push_error("Map UI should create player info button")
		_finish(1, scene, game_state, original_state)
		return
	var status_label := scene.get_node_or_null("StatusLabel") as Label
	var info_card := scene.get_node_or_null("PlayerInfoCard") as Panel
	var info_title := scene.get_node_or_null("PlayerInfoCard/PlayerInfoTitle") as Label
	var info_stats := scene.get_node_or_null("PlayerInfoCard/PlayerInfoStats") as Label
	if info_card == null or info_title == null or info_stats == null:
		push_error("Map player info should use a dedicated visible card with title and stats.")
		_finish(1, scene, game_state, original_state)
		return
	if info_title.text.find("角色信息") < 0 or info_stats.text.find("命 8/12") < 0 or info_stats.text.find("攻") < 0 or info_stats.text.find("机") < 0:
		push_error("Map player info card should visibly show character combat stats, got: %s / %s" % [info_title.text, info_stats.text])
		_finish(1, scene, game_state, original_state)
		return
	if status_label == null or status_label.text.find("金币 11") < 0:
		push_error("Map operation strip should keep gold visible, got: %s" % (status_label.text if status_label != null else "missing"))
		_finish(1, scene, game_state, original_state)
		return
	if status_label.text.find("命") >= 0 or status_label.text.find("甲") >= 0 or status_label.text.find("机") >= 0:
		push_error("Gold operation strip should not mix character stats, got: %s" % status_label.text)
		_finish(1, scene, game_state, original_state)
		return
	if info_card.position.x + info_card.size.x >= status_label.position.x:
		push_error("Player info card should be visually separate from gold operation strip.")
		_finish(1, scene, game_state, original_state)
		return
	scene._on_player_info_pressed()
	await process_frame
	var overlay: Node = scene.get_node_or_null("PlayerInfoOverlay")
	if overlay == null:
		push_error("Player info button should open info overlay")
		_finish(1, scene, game_state, original_state)
		return
	if not _tree_has_label_text(overlay, "角色状态") or not _tree_has_label_text(overlay, "装备栏") or not _tree_has_label_text(overlay, "已携带布局"):
		push_error("Player info overlay should show core sections")
		_finish(1, scene, game_state, original_state)
		return
	if not _tree_has_label_text(overlay, "长剑") or not _tree_has_label_text(overlay, "玉魄") or not _tree_has_label_text(overlay, "蓄势"):
		push_error("Player info overlay should show equipment, backpack, and combo details")
		_finish(1, scene, game_state, original_state)
		return

	print("map_player_info_smoke: ok")
	_finish(0, scene, game_state, original_state)

func _tree_has_label_text(node: Node, needle: String) -> bool:
	if node is Label and (node as Label).text.find(needle) >= 0:
		return true
	for child in node.get_children():
		if _tree_has_label_text(child, needle):
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
	game_state.player_hp = int(original_state.get("player_hp", 6))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 6))
	game_state.player_attack = int(original_state.get("player_attack", 2))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.materials = int(original_state.get("materials", 0))
	game_state.selected_heirloom_id = str(original_state.get("selected_heirloom_id", ""))
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.backpack = (original_state.get("backpack", []) as Array).duplicate(true)
	game_state.get_equipped_combos().clear()
	for combo_id in (original_state.get("equipped_combos", []) as Array):
		game_state.get_equipped_combos().append(str(combo_id))
	quit(code)
