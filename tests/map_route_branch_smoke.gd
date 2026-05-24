extends SceneTree

const HistoryMapBuilder = preload("res://resources/history_map_builder.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_route_name": str(game_state.selected_route_name),
		"route_switch_count": int(game_state.route_switch_count),
		"player_gold": int(game_state.player_gold),
		"current_floor": int(game_state.current_floor),
		"map_data": game_state.map_data.duplicate(true)
	}

	var builder := HistoryMapBuilder.new()
	for seed_value in range(20, 40):
		seed(seed_value)
		var map_data := builder.generate("qin", HistoryMapBuilder.FLOORS_PER_MAJOR_LAYER * HistoryMapBuilder.MAJOR_LAYER_COUNT)
		for floor_idx in range(0, 4):
			var floor_nodes: Array = map_data[floor_idx]
			if floor_nodes.size() != 2:
				continue
			for node_idx in range(2):
				var links: Array = (floor_nodes[node_idx] as Dictionary).get("next_indices", [])
				if not node_idx in links:
					push_error("Two-lane route should keep its own main lane. seed=%d floor=%d node=%d links=%s" % [seed_value, floor_idx, node_idx, str(links)])
					_finish(1, game_state, original_state)
					return
		if not _qin_near_attack_has_supply(map_data):
			push_error("Qin near-attack route should guarantee war supply shops in every major layer. seed=%d" % seed_value)
			_finish(1, game_state, original_state)
			return

	game_state.selected_route_name = "远交线"
	game_state.route_switch_count = 0
	game_state.player_gold = 0
	if not game_state.force_route_choice("近攻线"):
		push_error("Forced route choice should allow historical forced reroutes.")
		_finish(1, game_state, original_state)
		return
	if game_state.player_gold != 0 or game_state.route_switch_count != 0 or game_state.selected_route_name != "近攻线":
		push_error("Forced route choice should not spend gold or count as a paid detour.")
		_finish(1, game_state, original_state)
		return

	print("map_route_branch_smoke: ok")
	_finish(0, game_state, original_state)

func _finish(code: int, game_state: Node, original_state: Dictionary) -> void:
	game_state.selected_route_name = str(original_state.get("selected_route_name", ""))
	game_state.route_switch_count = int(original_state.get("route_switch_count", 0))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.current_floor = int(original_state.get("current_floor", 0))
	game_state.map_data = (original_state.get("map_data", []) as Array).duplicate(true)
	quit(code)

func _qin_near_attack_has_supply(map_data: Array) -> bool:
	for layer_index in range(HistoryMapBuilder.MAJOR_LAYER_COUNT):
		var layer_start := layer_index * HistoryMapBuilder.FLOORS_PER_MAJOR_LAYER
		var supply_count := 0
		for local_floor in [4, 10, 15]:
			var floor_idx: int = layer_start + int(local_floor)
			if floor_idx < 0 or floor_idx >= map_data.size():
				return false
			var found_supply := false
			for node in map_data[floor_idx]:
				var dict := node as Dictionary
				if str(dict.get("route_name", "")) == "近攻线" and int(dict.get("type", -1)) == HistoryMapBuilder.NODE_SHOP:
					found_supply = true
					break
			if found_supply:
				supply_count += 1
		if supply_count < 2:
			return false
	return true
