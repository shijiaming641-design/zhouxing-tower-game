extends SceneTree

const HistoryMapBuilder = preload("res://resources/history_map_builder.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_map_data: Array[Array] = game_state.map_data.duplicate(true)
	var builder := HistoryMapBuilder.new()
	var expected_floors := int(game_state.TOTAL_SMALL_FLOORS)
	for era_id in ["qin", "song", "china"]:
		var map_data := builder.generate(era_id, expected_floors)
		game_state.map_data = map_data
		if map_data.size() != expected_floors:
			push_error("History map for %s should have %d floors, got %d" % [era_id, expected_floors, map_data.size()])
			_restore(game_state, original_map_data, 1)
			return
		if not _first_floor_is_accessible(map_data):
			push_error("History map for %s should open first floor" % era_id)
			_restore(game_state, original_map_data, 1)
			return
		if not _final_floor_is_boss(map_data):
			push_error("History map for %s should end with boss node" % era_id)
			_restore(game_state, original_map_data, 1)
			return
		if not _major_layers_have_bosses(map_data, int(game_state.FLOORS_PER_MAJOR_LAYER)):
			push_error("History map for %s should put a boss at the end of each major layer" % era_id)
			_restore(game_state, original_map_data, 1)
			return
		if not _connections_are_valid(map_data):
			push_error("History map for %s has invalid route links" % era_id)
			_restore(game_state, original_map_data, 1)
			return
		if not _has_mid_run_checkpoint(map_data):
			push_error("History map for %s should include mid-run checkpoint floors" % era_id)
			_restore(game_state, original_map_data, 1)
			return
		if not _all_nodes_have_strategy_tags(map_data):
			push_error("History map for %s should tag nodes with difficulty and reward profiles" % era_id)
			_restore(game_state, original_map_data, 1)
			return
		if not _route_pacing_is_valid(map_data):
			push_error("History map for %s should not connect repeated shop/rest/event nodes." % era_id)
			_restore(game_state, original_map_data, 1)
			return
		if not _third_layer_has_spend_node(map_data):
			push_error("History map for %s should expose at least one third-layer shop checkpoint." % era_id)
			_restore(game_state, original_map_data, 1)
			return
	seed(7101)
	var map_a := builder.generate("song", expected_floors)
	seed(7102)
	var map_b := builder.generate("song", expected_floors)
	if _map_signature(map_a) == _map_signature(map_b):
		push_error("History map should vary between runs with different seeds.")
		_restore(game_state, original_map_data, 1)
		return
	print("history_map_builder_smoke: ok")
	_restore(game_state, original_map_data, 0)

func _restore(game_state: Node, original_map_data: Array[Array], code: int) -> void:
	game_state.map_data = original_map_data
	quit(code)

func _first_floor_is_accessible(map_data: Array) -> bool:
	if map_data.is_empty():
		return false
	for node in map_data[0]:
		if not bool((node as Dictionary).get("accessible", false)):
			return false
	return true

func _final_floor_is_boss(map_data: Array) -> bool:
	if map_data.is_empty() or (map_data[-1] as Array).is_empty():
		return false
	var final_node: Dictionary = (map_data[-1] as Array)[0]
	return int(final_node.get("type", -1)) == HistoryMapBuilder.NODE_BOSS

func _major_layers_have_bosses(map_data: Array, floors_per_layer: int) -> bool:
	if floors_per_layer <= 0:
		return false
	for boss_floor in [floors_per_layer - 1, floors_per_layer * 2 - 1, floors_per_layer * 3 - 1]:
		if boss_floor < 0 or boss_floor >= map_data.size():
			return false
		var floor_nodes: Array = map_data[boss_floor]
		if floor_nodes.size() != 1:
			return false
		if int((floor_nodes[0] as Dictionary).get("type", -1)) != HistoryMapBuilder.NODE_BOSS:
			return false
	return true

func _connections_are_valid(map_data: Array) -> bool:
	for floor_idx in range(map_data.size() - 1):
		var floor_nodes: Array = map_data[floor_idx]
		var next_nodes: Array = map_data[floor_idx + 1]
		if floor_nodes.is_empty() or next_nodes.is_empty():
			return false
		var incoming := {}
		for idx in range(next_nodes.size()):
			incoming[idx] = false
		for node in floor_nodes:
			var links: Array = (node as Dictionary).get("next_indices", [])
			if links.is_empty():
				return false
			for raw_idx in links:
				var idx := int(raw_idx)
				if idx < 0 or idx >= next_nodes.size():
					return false
				incoming[idx] = true
		for idx in incoming.keys():
			if not bool(incoming[idx]):
				return false
	return true

func _map_signature(map_data: Array) -> String:
	var parts: Array[String] = []
	for floor in map_data:
		var node_parts: Array[String] = []
		for node in floor:
			var dict := node as Dictionary
			node_parts.append("%s:%s:%s" % [
				str(dict.get("route_name", "")),
				str(dict.get("type", "")),
				str(dict.get("map_variant", ""))
			])
		parts.append("|".join(node_parts))
	return "\n".join(parts)

func _has_mid_run_checkpoint(map_data: Array) -> bool:
	for floor_idx in range(mini(map_data.size(), 8)):
		if floor_idx < 5:
			continue
		for node in map_data[floor_idx]:
			var dict := node as Dictionary
			if str(dict.get("checkpoint_tier", "")) == "mid_build":
				return true
	return false

func _all_nodes_have_strategy_tags(map_data: Array) -> bool:
	var difficulty_values := ["safe", "normal", "hard", "danger"]
	var reward_values := ["gold", "material", "heal", "event", "rare"]
	for floor in map_data:
		for node in floor:
			var dict := node as Dictionary
			if not str(dict.get("difficulty_tier", "")) in difficulty_values:
				return false
			if not str(dict.get("reward_profile", "")) in reward_values:
				return false
	return true

func _route_pacing_is_valid(map_data: Array) -> bool:
	for floor_idx in range(map_data.size() - 1):
		var current_nodes: Array = map_data[floor_idx]
		var next_nodes: Array = map_data[floor_idx + 1]
		for node in current_nodes:
			var dict := node as Dictionary
			var current_type := int(dict.get("type", -1))
			var links: Array = dict.get("next_indices", [])
			for raw_idx in links:
				var next_idx := int(raw_idx)
				if next_idx < 0 or next_idx >= next_nodes.size():
					return false
				var next_type := int((next_nodes[next_idx] as Dictionary).get("type", -1))
				if current_type == HistoryMapBuilder.NODE_SHOP and next_type == HistoryMapBuilder.NODE_SHOP:
					return false
				if current_type == HistoryMapBuilder.NODE_EVENT and next_type == HistoryMapBuilder.NODE_EVENT:
					return false
				if current_type == HistoryMapBuilder.NODE_REST and next_type == HistoryMapBuilder.NODE_REST:
					return false
	return true

func _third_layer_has_spend_node(map_data: Array) -> bool:
	var start_floor := HistoryMapBuilder.FLOORS_PER_MAJOR_LAYER * 2
	var end_floor := mini(start_floor + HistoryMapBuilder.FLOORS_PER_MAJOR_LAYER, map_data.size())
	for floor_idx in range(start_floor, end_floor):
		for node in map_data[floor_idx]:
			if int((node as Dictionary).get("type", -1)) == HistoryMapBuilder.NODE_SHOP:
				return true
	return false
