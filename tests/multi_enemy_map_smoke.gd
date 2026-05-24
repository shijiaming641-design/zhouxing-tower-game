extends SceneTree

const HistoryMapBuilder = preload("res://resources/history_map_builder.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var builder := HistoryMapBuilder.new()
	var floors := HistoryMapBuilder.FLOORS_PER_MAJOR_LAYER * HistoryMapBuilder.MAJOR_LAYER_COUNT
	for era_id in ["qin", "song", "china"]:
		seed(9100)
		var map_data := builder.generate(era_id, floors)
		var boss_front_floor := HistoryMapBuilder.FLOORS_PER_MAJOR_LAYER * 2 - 2
		if boss_front_floor >= map_data.size():
			push_error("Boss-front floor is missing for %s." % era_id)
			quit(1)
			return
		if not _floor_has_support_battle(map_data[boss_front_floor]):
			push_error("%s second-layer boss-front floor should include a support battle." % era_id)
			quit(1)
			return
		if not _support_battles_are_marked_hard(map_data[boss_front_floor]):
			push_error("%s support battle should be marked as hard or danger." % era_id)
			quit(1)
			return

	var china_double := {
		"type": HistoryMapBuilder.NODE_BATTLE,
		"map_variant": "火线突变",
		"event_desc": "",
		"base_event_desc": "",
		"route_name": "主战线",
		"enemy_hp_delta": 0,
		"enemy_attack_delta": 0
	}
	builder._apply_multi_enemy_pressure(china_double, "china", HistoryMapBuilder.FLOORS_PER_MAJOR_LAYER * 3 - 2)
	if int(china_double.get("support_count", 0)) != 2:
		push_error("China third-layer boss-front battle should force two support enemies.")
		quit(1)
		return
	print("multi_enemy_map_smoke: ok")
	quit(0)

func _floor_has_support_battle(floor_nodes: Array) -> bool:
	for node in floor_nodes:
		var dict := node as Dictionary
		if int(dict.get("type", -1)) == HistoryMapBuilder.NODE_BATTLE and int(dict.get("support_count", 0)) > 0:
			if str(dict.get("map_variant", "")).find("副阵") < 0:
				return false
			return true
	return false

func _support_battles_are_marked_hard(floor_nodes: Array) -> bool:
	for node in floor_nodes:
		var dict := node as Dictionary
		if int(dict.get("type", -1)) == HistoryMapBuilder.NODE_BATTLE and int(dict.get("support_count", 0)) > 0:
			if not str(dict.get("difficulty_tier", "")) in ["hard", "danger"]:
				return false
	return true
