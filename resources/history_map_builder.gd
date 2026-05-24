class_name HistoryMapBuilder
extends RefCounted

const NODE_BATTLE := 0
const NODE_SHOP := 1
const NODE_REST := 2
const NODE_EVENT := 3
const NODE_BOSS := 4
const MAJOR_LAYER_COUNT := 3
const FLOORS_PER_MAJOR_LAYER := 19

func generate(era_id: String, max_floors: int) -> Array[Array]:
	var map_data: Array[Array] = []
	var floor_count := maxi(max_floors, 1)
	for floor_num in range(floor_count):
		var floor_nodes: Array = []
		var layer_index := _get_major_layer_index(floor_num)
		var local_floor := _get_major_layer_local_floor(floor_num)
		var is_major_layer_boss := local_floor == FLOORS_PER_MAJOR_LAYER - 1 or floor_num == floor_count - 1
		if is_major_layer_boss:
			floor_nodes = [_create_history_node(
				NODE_BOSS,
				_get_era_layer_boss_route_name(era_id, layer_index),
				_get_era_layer_phase_name(era_id, layer_index),
				_get_era_layer_boss_title(era_id, layer_index),
				_get_era_layer_boss_desc(era_id, layer_index)
			)]
		else:
			floor_nodes = _get_era_history_floor_nodes(era_id, local_floor)
		_apply_major_layer_flavor(floor_nodes, floor_num)
		if not is_major_layer_boss:
			_apply_floor_variation(floor_nodes, era_id, floor_num, floor_count)
		map_data.append(floor_nodes)
	_assign_history_map_connections(map_data)
	_apply_route_pacing_constraints(map_data, era_id, floor_count)
	_refresh_map_after_pacing(map_data, floor_count)
	_assign_history_map_positions(map_data)
	if not map_data.is_empty():
		for node in map_data[0]:
			node.accessible = true
	return map_data

func _create_history_node(node_type: int, route_name: String, phase_name: String, event_title: String, event_desc: String) -> Dictionary:
	return {
		"type": node_type,
		"visited": false,
		"accessible": false,
		"route_name": route_name,
		"phase_name": phase_name,
		"event_title": event_title,
		"event_desc": event_desc,
		"base_event_desc": event_desc,
		"map_variant": "",
		"checkpoint_tier": "",
		"checkpoint_hint": "",
		"enemy_hp_delta": 0,
		"enemy_attack_delta": 0,
		"enemy_group_size": 1,
		"support_count": 0,
		"route_supply_lock": false,
		"difficulty_tier": "danger" if node_type == NODE_BOSS else "normal",
		"reward_profile": "rare" if node_type == NODE_BOSS else "material",
		"major_layer_index": 0,
		"major_layer_title": "",
		"next_indices": [],
		"map_x_offset": 0,
		"map_y_offset": 0
	}

func _get_major_layer_index(floor_num: int) -> int:
	return clamp(int(maxi(floor_num, 0) / FLOORS_PER_MAJOR_LAYER), 0, MAJOR_LAYER_COUNT - 1)

func _get_major_layer_local_floor(floor_num: int) -> int:
	return int(maxi(floor_num, 0) % FLOORS_PER_MAJOR_LAYER)

func _get_major_layer_title(layer_index: int) -> String:
	var titles := ["第一大层", "第二大层", "第三大层"]
	return titles[clamp(layer_index, 0, titles.size() - 1)]

func _apply_major_layer_flavor(floor_nodes: Array, floor_num: int) -> void:
	var layer_index := _get_major_layer_index(floor_num)
	var layer_title := _get_major_layer_title(layer_index)
	for node in floor_nodes:
		var dict := node as Dictionary
		dict["major_layer_index"] = layer_index
		dict["major_layer_title"] = layer_title
		var phase := str(dict.get("phase_name", ""))
		if phase != "" and not phase.begins_with(layer_title):
			dict["phase_name"] = "%s · %s" % [layer_title, phase]

func _apply_floor_variation(floor_nodes: Array, era_id: String, floor_num: int, floor_count: int) -> void:
	if floor_nodes.is_empty():
		return
	for node in floor_nodes:
		var old_type := int((node as Dictionary).get("type", NODE_BATTLE))
		var new_type := _roll_contextual_node_type(node as Dictionary, era_id, floor_num, floor_count)
		node["original_type"] = old_type
		node["type"] = new_type
		_apply_node_variant(node, era_id, floor_num, floor_count)
	_ensure_floor_pressure(floor_nodes, floor_num)
	for node in floor_nodes:
		_apply_multi_enemy_pressure(node as Dictionary, era_id, floor_num)
	_apply_mid_run_checkpoint(floor_nodes, floor_num)
	_apply_route_supply_guarantees(floor_nodes, era_id, floor_num)
	_apply_node_strategy_tags(floor_nodes, floor_num, floor_count)
	_refresh_variant_descriptions(floor_nodes)

func _roll_contextual_node_type(node: Dictionary, era_id: String, floor_num: int, floor_count: int) -> int:
	var base_type := int(node.get("type", NODE_BATTLE))
	if base_type == NODE_BOSS:
		return NODE_BOSS
	var progress := float(floor_num) / float(maxi(floor_count - 2, 1))
	var weights := _get_contextual_node_weights(
		era_id,
		str(node.get("route_name", "")),
		str(node.get("event_title", "")),
		base_type,
		progress
	)
	return _pick_weighted_node_type(weights, base_type)

func _get_contextual_node_weights(era_id: String, route_name: String, event_title: String, base_type: int, progress: float) -> Dictionary:
	var weights := {
		NODE_BATTLE: 8,
		NODE_SHOP: 8,
		NODE_REST: 8,
		NODE_EVENT: 8
	}
	match base_type:
		NODE_BATTLE:
			weights = {NODE_BATTLE: 68, NODE_EVENT: 16, NODE_REST: 9, NODE_SHOP: 7}
		NODE_SHOP:
			weights = {NODE_SHOP: 58, NODE_EVENT: 20, NODE_REST: 12, NODE_BATTLE: 10}
		NODE_REST:
			weights = {NODE_REST: 55, NODE_SHOP: 20, NODE_EVENT: 15, NODE_BATTLE: 10}
		NODE_EVENT:
			weights = {NODE_EVENT: 56, NODE_SHOP: 18, NODE_BATTLE: 16, NODE_REST: 10}

	match era_id:
		"song":
			_apply_song_context_weights(weights, route_name, event_title)
		"china":
			_apply_china_context_weights(weights, route_name, event_title)
		_:
			_apply_qin_context_weights(weights, route_name, event_title)
	if progress > 0.62:
		weights[NODE_BATTLE] = int(weights.get(NODE_BATTLE, 0)) + 4
		weights[NODE_SHOP] = int(weights.get(NODE_SHOP, 0)) + 8
		weights[NODE_REST] = int(weights.get(NODE_REST, 0)) + 4
	return weights

func _apply_qin_context_weights(weights: Dictionary, route_name: String, event_title: String) -> void:
	if route_name == "远交线":
		weights[NODE_EVENT] = int(weights.get(NODE_EVENT, 0)) + 18
		weights[NODE_SHOP] = int(weights.get(NODE_SHOP, 0)) + 12
		weights[NODE_BATTLE] = maxi(4, int(weights.get(NODE_BATTLE, 0)) - 16)
	if route_name == "近攻线":
		weights[NODE_BATTLE] = int(weights.get(NODE_BATTLE, 0)) + 14
		weights[NODE_SHOP] = int(weights.get(NODE_SHOP, 0)) + 14
		weights[NODE_REST] = int(weights.get(NODE_REST, 0)) + 4
		weights[NODE_EVENT] = maxi(3, int(weights.get(NODE_EVENT, 0)) - 8)
	if _title_has_any(event_title, ["攻", "破", "拔", "围", "灭", "扫", "压", "入", "会师", "并吞"]):
		weights[NODE_BATTLE] = int(weights.get(NODE_BATTLE, 0)) + 24
		if route_name == "近攻线":
			weights[NODE_SHOP] = int(weights.get(NODE_SHOP, 0)) + 10
	if _title_has_any(event_title, ["盟", "使", "通", "结", "说", "离间", "策反", "封赏", "外交"]):
		weights[NODE_EVENT] = int(weights.get(NODE_EVENT, 0)) + 22
		weights[NODE_SHOP] = int(weights.get(NODE_SHOP, 0)) + 8
	if _title_has_any(event_title, ["运粮", "粮道"]):
		weights[NODE_SHOP] = int(weights.get(NODE_SHOP, 0)) + 18
		weights[NODE_REST] = int(weights.get(NODE_REST, 0)) + 8

func _apply_song_context_weights(weights: Dictionary, route_name: String, event_title: String) -> void:
	if route_name == "十国线":
		weights[NODE_SHOP] = int(weights.get(NODE_SHOP, 0)) + 18
		weights[NODE_EVENT] = int(weights.get(NODE_EVENT, 0)) + 10
		weights[NODE_BATTLE] = maxi(5, int(weights.get(NODE_BATTLE, 0)) - 10)
	if route_name == "北境线":
		weights[NODE_BATTLE] = int(weights.get(NODE_BATTLE, 0)) + 18
		weights[NODE_REST] = int(weights.get(NODE_REST, 0)) + 8
	if route_name == "中原线":
		weights[NODE_EVENT] = int(weights.get(NODE_EVENT, 0)) + 8
		weights[NODE_BATTLE] = int(weights.get(NODE_BATTLE, 0)) + 8
	if _title_has_any(event_title, ["辽", "北伐", "晋阳", "太原", "燕云", "围困", "决战", "军镇"]):
		weights[NODE_BATTLE] = int(weights.get(NODE_BATTLE, 0)) + 26
	if _title_has_any(event_title, ["市舶", "商路", "吴越", "钱氏", "富庶", "水师", "文治"]):
		weights[NODE_SHOP] = int(weights.get(NODE_SHOP, 0)) + 24
		weights[NODE_EVENT] = int(weights.get(NODE_EVENT, 0)) + 8
	if _title_has_any(event_title, ["杯酒", "陈桥", "归附", "纳土", "观望", "词宴", "立国"]):
		weights[NODE_EVENT] = int(weights.get(NODE_EVENT, 0)) + 20

func _apply_china_context_weights(weights: Dictionary, route_name: String, event_title: String) -> void:
	if route_name == "主战线":
		weights[NODE_BATTLE] = int(weights.get(NODE_BATTLE, 0)) + 22
	if route_name == "根据地线":
		weights[NODE_REST] = int(weights.get(NODE_REST, 0)) + 16
		weights[NODE_SHOP] = int(weights.get(NODE_SHOP, 0)) + 12
		weights[NODE_EVENT] = int(weights.get(NODE_EVENT, 0)) + 8
		weights[NODE_BATTLE] = maxi(5, int(weights.get(NODE_BATTLE, 0)) - 12)
	if route_name == "危局线":
		weights[NODE_BATTLE] = int(weights.get(NODE_BATTLE, 0)) + 16
		weights[NODE_EVENT] = int(weights.get(NODE_EVENT, 0)) + 10
	if _title_has_any(event_title, ["会战", "战役", "反围剿", "长征", "卢沟桥", "淞沪", "百团", "辽沈", "淮海", "平津", "渡江", "围追", "决战"]):
		weights[NODE_BATTLE] = int(weights.get(NODE_BATTLE, 0)) + 28
	if _title_has_any(event_title, ["根据地", "大生产", "支前", "动员", "整训", "落脚", "游击"]):
		weights[NODE_REST] = int(weights.get(NODE_REST, 0)) + 22
		weights[NODE_SHOP] = int(weights.get(NODE_SHOP, 0)) + 8
	if _title_has_any(event_title, ["谈判", "协定", "和谈", "统一战线", "西安事变", "暗线", "工运"]):
		weights[NODE_EVENT] = int(weights.get(NODE_EVENT, 0)) + 24

func _title_has_any(title: String, needles: Array[String]) -> bool:
	for needle in needles:
		if title.find(needle) >= 0:
			return true
	return false

func _pick_weighted_node_type(weights: Dictionary, fallback_type: int) -> int:
	var total := 0
	for value in weights.values():
		total += maxi(int(value), 0)
	if total <= 0:
		return fallback_type
	var roll := randi() % total
	var cursor := 0
	for node_type in [NODE_BATTLE, NODE_SHOP, NODE_REST, NODE_EVENT]:
		cursor += maxi(int(weights.get(node_type, 0)), 0)
		if roll < cursor:
			return node_type
	return fallback_type

func _apply_node_variant(node: Dictionary, era_id: String, floor_num: int, floor_count: int) -> void:
	var node_type := int(node.get("type", NODE_BATTLE))
	var variant := _pick_node_variant(era_id, str(node.get("route_name", "")), str(node.get("event_title", "")), node_type)
	node["map_variant"] = variant
	node["enemy_hp_delta"] = 0
	node["enemy_attack_delta"] = 0
	if node_type == NODE_BATTLE:
		var progress := float(floor_num) / float(maxi(floor_count - 2, 1))
		var pressure_roll := randf()
		if pressure_roll < 0.18 + progress * 0.12:
			node["enemy_hp_delta"] = 1
			variant += "，敌阵更厚"
		elif pressure_roll < 0.30:
			node["enemy_hp_delta"] = -1
			variant += "，敌阵稍散"
		if _get_major_layer_local_floor(floor_num) >= 8 and randf() < 0.08 + progress * 0.08:
			node["enemy_attack_delta"] = 1
			variant += "，攻势更急"
	node["map_variant"] = variant
	var desc := str(node.get("base_event_desc", node.get("event_desc", "")))
	if desc != "":
		node["event_desc"] = "%s\n本局变体：%s。" % [desc, variant]
	else:
		node["event_desc"] = "本局变体：%s。" % variant

func _apply_multi_enemy_pressure(node: Dictionary, era_id: String, floor_num: int) -> void:
	var node_type := int(node.get("type", NODE_BATTLE))
	node["enemy_group_size"] = 1
	node["support_count"] = 0
	if node_type != NODE_BATTLE:
		return
	var layer_index := _get_major_layer_index(floor_num)
	var local_floor := _get_major_layer_local_floor(floor_num)
	if layer_index <= 0:
		return
	var support_count := 0
	if local_floor == FLOORS_PER_MAJOR_LAYER - 2:
		support_count = 2 if era_id == "china" and layer_index >= 2 else 1
	elif layer_index >= 2 and era_id == "china" and local_floor >= 6 and local_floor <= 16 and randf() < 0.35:
		support_count = 2
	elif layer_index >= 2 and local_floor >= 6 and local_floor <= 16 and randf() < 0.55:
		support_count = 1
	elif layer_index >= 1 and local_floor >= 6 and local_floor <= 11 and randf() < 0.35:
		support_count = 1
	elif layer_index >= 1 and local_floor >= 12 and local_floor <= 16 and randf() < 0.12:
		support_count = 1
	if support_count <= 0:
		return
	node["support_count"] = support_count
	node["enemy_group_size"] = 1 + support_count
	var variant := str(node.get("map_variant", ""))
	var group_text := "敌有副阵" if support_count == 1 else "敌有双副阵"
	node["map_variant"] = "%s，%s" % [variant, group_text] if variant != "" else group_text

func _refresh_variant_descriptions(floor_nodes: Array) -> void:
	for node in floor_nodes:
		var dict := node as Dictionary
		var desc := str(dict.get("base_event_desc", dict.get("event_desc", "")))
		var variant := str(dict.get("map_variant", "局势有变"))
		var checkpoint_hint := str(dict.get("checkpoint_hint", ""))
		if desc != "":
			dict["event_desc"] = "%s\n本局变体：%s。" % [desc, variant]
		else:
			dict["event_desc"] = "本局变体：%s。" % variant
		if checkpoint_hint != "":
			dict["event_desc"] += "\n中段检点：%s。" % checkpoint_hint

func _pick_node_variant(era_id: String, route_name: String, event_title: String, node_type: int) -> String:
	var contextual := _get_contextual_variant_options(era_id, route_name, event_title, node_type)
	if not contextual.is_empty():
		return str(contextual[randi() % contextual.size()])
	var qin_variants := {
		NODE_BATTLE: ["军令急促", "前锋试探", "敌阵未稳", "关隘压迫"],
		NODE_SHOP: ["军需改道", "客卿献策", "粮道暂通", "器械入营"],
		NODE_REST: ["营火尚存", "斥候回报", "军心稍定", "伤卒归队"],
		NODE_EVENT: ["密使来报", "诸侯异动", "旧盟生隙", "野史旁枝"]
	}
	var song_variants := {
		NODE_BATTLE: ["边报忽至", "军情反复", "辽骑扰境", "阵图试锋"],
		NODE_SHOP: ["市舶通利", "商队绕行", "库藏新开", "工造得材"],
		NODE_REST: ["驿站可歇", "营寨整备", "水陆稍安", "医工入帐"],
		NODE_EVENT: ["朝议横生", "旧臣进言", "江南传闻", "边镇暗流"]
	}
	var china_variants := {
		NODE_BATTLE: ["前线骤紧", "敌阵交错", "阵地拉锯", "火线突变"],
		NODE_SHOP: ["补给抵达", "工事转运", "行商穿线", "物资汇集"],
		NODE_REST: ["根据地整训", "战地喘息", "军民协力", "伤员后送"],
		NODE_EVENT: ["暗线浮现", "时局翻涌", "群众支援", "旧债来袭"]
	}
	var table := qin_variants
	if era_id == "song":
		table = song_variants
	elif era_id == "china":
		table = china_variants
	var options: Array = table.get(node_type, ["局势有变"])
	return str(options[randi() % options.size()])

func _get_contextual_variant_options(era_id: String, route_name: String, event_title: String, node_type: int) -> Array[String]:
	match era_id:
		"song":
			if _title_has_any(event_title, ["市舶", "商路", "吴越", "钱氏", "富庶"]):
				return _variant_by_type(node_type, ["海贸盘活", "库藏可用", "商队绕行"], ["水陆商队", "市井传闻"], ["驿站补给"], ["契书暗流", "地方归附"])
			if _title_has_any(event_title, ["辽", "北伐", "晋阳", "太原", "燕云"]):
				return _variant_by_type(node_type, ["边骑压境", "城下急战", "军情骤紧"], ["边市军需"], ["寨防整备"], ["边镇密报", "旧盟生变"])
			if _title_has_any(event_title, ["杯酒", "陈桥", "归附", "纳土"]):
				return _variant_by_type(node_type, ["禁军试锋"], ["朝贡入库"], ["禁军整肃"], ["朝议翻涌", "旧臣进言"])
		"china":
			if _title_has_any(event_title, ["会战", "战役", "卢沟桥", "淞沪", "百团", "辽沈", "淮海", "渡江"]):
				return _variant_by_type(node_type, ["火线拉锯", "阵地争夺", "敌阵压上"], ["前线补给"], ["战地喘息"], ["战报传来", "民众支援"])
			if _title_has_any(event_title, ["根据地", "大生产", "支前", "动员", "落脚", "游击"]):
				return _variant_by_type(node_type, ["游击遭遇"], ["物资汇集", "工事转运"], ["根据地整训", "军民协力"], ["群众路线", "暗线接应"])
			if _title_has_any(event_title, ["谈判", "协定", "和谈", "统一战线", "西安事变", "暗线"]):
				return _variant_by_type(node_type, ["谈判破裂"], ["补给交换"], ["短暂停火"], ["时局翻涌", "暗线浮现"])
		_:
			if _title_has_any(event_title, ["攻", "破", "拔", "围", "灭", "扫", "压", "入", "并吞"]):
				return _variant_by_type(node_type, ["军阵压境", "攻势提前", "关隘急战"], ["缴获军需"], ["营帐整备"], ["战前密报"])
			if _title_has_any(event_title, ["盟", "使", "通", "结", "说", "离间", "策反", "封赏", "外交"]):
				return _variant_by_type(node_type, ["谈判遇伏"], ["客卿献策", "粮道暂通"], ["使团休整"], ["密使来报", "诸侯异动"])
			if _title_has_any(event_title, ["运粮", "粮道"]):
				return _variant_by_type(node_type, ["粮道遇袭"], ["军需转运", "粮道暂通"], ["辎重整备"], ["押运异闻"])
	return []

func _variant_by_type(node_type: int, battle: Array[String], shop: Array[String], rest: Array[String], event: Array[String]) -> Array[String]:
	match node_type:
		NODE_BATTLE:
			return battle
		NODE_SHOP:
			return shop
		NODE_REST:
			return rest
		NODE_EVENT:
			return event
	return []

func _ensure_floor_pressure(floor_nodes: Array, floor_num: int) -> void:
	var battle_count := 0
	var rest_count := 0
	for node in floor_nodes:
		var node_type := int((node as Dictionary).get("type", NODE_BATTLE))
		if node_type == NODE_BATTLE:
			battle_count += 1
		elif node_type == NODE_REST:
			rest_count += 1
	if battle_count == 0 and floor_num % 3 != 1:
		var idx := randi() % floor_nodes.size()
		floor_nodes[idx]["type"] = NODE_BATTLE
		floor_nodes[idx]["map_variant"] = "%s，遭遇战" % str(floor_nodes[idx].get("map_variant", "局势有变"))
	if rest_count > 1:
		var changed := false
		for node in floor_nodes:
			if changed:
				break
			if int((node as Dictionary).get("type", NODE_BATTLE)) == NODE_REST:
				node["type"] = NODE_EVENT
				node["map_variant"] = "%s，转为异闻" % str(node.get("map_variant", "局势有变"))
				changed = true

func _apply_mid_run_checkpoint(floor_nodes: Array, floor_num: int) -> void:
	var local_floor := _get_major_layer_local_floor(floor_num)
	if local_floor < 5 or local_floor > 7:
		return
	match local_floor:
		5:
			var preferred_types: Array[int] = []
			preferred_types.append(NODE_SHOP)
			if _get_major_layer_index(floor_num) < 2:
				preferred_types.append(NODE_EVENT)
			var support_idx := _ensure_floor_type(floor_nodes, preferred_types, NODE_SHOP)
			floor_nodes[support_idx]["checkpoint_tier"] = "mid_build"
			floor_nodes[support_idx]["checkpoint_hint"] = "这一层更容易补件，适合把当前方向补齐"
			floor_nodes[support_idx]["map_variant"] = "%s，补件在前" % str(floor_nodes[support_idx].get("map_variant", "局势有变"))
		6:
			var battle_idx := _ensure_floor_type(floor_nodes, [NODE_BATTLE], NODE_BATTLE)
			floor_nodes[battle_idx]["checkpoint_tier"] = "mid_build"
			floor_nodes[battle_idx]["checkpoint_hint"] = "这一层更容易遇到试锋战，检验当前构筑是否站得住"
			floor_nodes[battle_idx]["enemy_hp_delta"] = int(floor_nodes[battle_idx].get("enemy_hp_delta", 0)) + 1
			if randf() < 0.5:
				floor_nodes[battle_idx]["enemy_attack_delta"] = int(floor_nodes[battle_idx].get("enemy_attack_delta", 0)) + 1
			floor_nodes[battle_idx]["map_variant"] = "%s，先试一锋" % str(floor_nodes[battle_idx].get("map_variant", "局势有变"))
		7:
			var event_idx := _ensure_floor_type(floor_nodes, [NODE_EVENT, NODE_BATTLE], NODE_EVENT)
			floor_nodes[event_idx]["checkpoint_tier"] = "mid_build"
			floor_nodes[event_idx]["checkpoint_hint"] = "这一层收益和代价都会抬高，适合决定后半程走法"
			floor_nodes[event_idx]["map_variant"] = "%s，局势加注" % str(floor_nodes[event_idx].get("map_variant", "局势有变"))

func _apply_route_supply_guarantees(floor_nodes: Array, era_id: String, floor_num: int) -> void:
	if era_id != "qin":
		return
	var local_floor := _get_major_layer_local_floor(floor_num)
	if not local_floor in [4, 10, 15]:
		return
	for node in floor_nodes:
		var dict := node as Dictionary
		if str(dict.get("route_name", "")) != "近攻线":
			continue
		if int(dict.get("type", NODE_BATTLE)) == NODE_BOSS:
			return
		dict["type"] = NODE_SHOP
		dict["route_supply_lock"] = true
		dict["checkpoint_tier"] = "war_supply"
		dict["checkpoint_hint"] = "近攻缴获转为军需，适合把金币换成战力"
		dict["enemy_hp_delta"] = 0
		dict["enemy_attack_delta"] = 0
		dict["enemy_group_size"] = 1
		dict["support_count"] = 0
		var variant := str(dict.get("map_variant", "局势有变"))
		dict["map_variant"] = "%s，缴获军需" % variant if variant != "" else "缴获军需"
		return

func _apply_node_strategy_tags(floor_nodes: Array, floor_num: int, floor_count: int) -> void:
	for node in floor_nodes:
		var dict := node as Dictionary
		dict["difficulty_tier"] = _get_node_difficulty_tier(dict, floor_num, floor_count)
		dict["reward_profile"] = _get_node_reward_profile(dict)

func _get_node_difficulty_tier(node: Dictionary, floor_num: int, floor_count: int) -> String:
	var node_type := int(node.get("type", NODE_BATTLE))
	if node_type == NODE_BOSS:
		return "danger"
	if node_type in [NODE_SHOP, NODE_REST]:
		return "safe" if floor_num < floor_count - 4 else "normal"
	var pressure := 0
	pressure += int(node.get("enemy_hp_delta", 0))
	pressure += int(node.get("enemy_attack_delta", 0)) * 2
	pressure += int(node.get("support_count", 0)) * 2
	if node_type == NODE_EVENT:
		pressure += 1 if str(node.get("route_name", "")).find("危") >= 0 else 0
	if node_type == NODE_BATTLE:
		pressure += 1
	if floor_num >= 12:
		pressure += 2
	elif floor_num >= 7:
		pressure += 1
	if str(node.get("checkpoint_tier", "")) == "mid_build":
		pressure += 1
	match str(node.get("route_name", "")):
		"近攻线", "北境线", "主战线", "危局线":
			pressure += 1
		"远交线", "十国线", "根据地线":
			pressure -= 1
	if pressure <= 0:
		return "safe"
	if pressure <= 2:
		return "normal"
	if pressure <= 4:
		return "hard"
	return "danger"

func _get_node_reward_profile(node: Dictionary) -> String:
	if str(node.get("checkpoint_tier", "")) == "mid_build":
		match int(node.get("type", NODE_BATTLE)):
			NODE_BATTLE:
				return "rare"
			NODE_SHOP:
				return "material"
			NODE_REST:
				return "heal"
			NODE_EVENT:
				return "rare"
	match int(node.get("type", NODE_BATTLE)):
		NODE_BATTLE:
			if str(node.get("difficulty_tier", "normal")) in ["hard", "danger"]:
				return "rare"
			return "material"
		NODE_SHOP:
			return "gold"
		NODE_REST:
			return "heal"
		NODE_EVENT:
			return "event"
		NODE_BOSS:
			return "rare"
	return "material"

func _ensure_floor_type(floor_nodes: Array, preferred_types: Array[int], fallback_type: int) -> int:
	for idx in range(floor_nodes.size()):
		var node_type := int((floor_nodes[idx] as Dictionary).get("type", NODE_BATTLE))
		if node_type in preferred_types:
			return idx
	var target_idx := randi() % maxi(floor_nodes.size(), 1)
	floor_nodes[target_idx]["type"] = fallback_type
	return target_idx

func _assign_history_map_connections(map_data: Array) -> void:
	for floor_idx in range(map_data.size() - 1):
		var current_nodes: Array = map_data[floor_idx]
		var next_nodes: Array = map_data[floor_idx + 1]
		if current_nodes.is_empty() or next_nodes.is_empty():
			continue
		var incoming: Dictionary = {}
		for idx in range(next_nodes.size()):
			incoming[idx] = false
		for node_idx in range(current_nodes.size()):
			var links := _build_history_node_links(node_idx, current_nodes.size(), next_nodes.size())
			current_nodes[node_idx].next_indices = links
			for link_idx in links:
				incoming[int(link_idx)] = true
		for next_idx in range(next_nodes.size()):
			if bool(incoming.get(next_idx, false)):
				continue
			var source_idx = clamp(next_idx, 0, current_nodes.size() - 1)
			if not next_idx in current_nodes[source_idx].next_indices:
				current_nodes[source_idx].next_indices.append(next_idx)

func _apply_route_pacing_constraints(map_data: Array, era_id: String, floor_count: int) -> void:
	for floor_idx in range(map_data.size() - 1):
		var current_nodes: Array = map_data[floor_idx]
		var next_nodes: Array = map_data[floor_idx + 1]
		if current_nodes.is_empty() or next_nodes.is_empty():
			continue
		for current_node in current_nodes:
			var current_dict := current_node as Dictionary
			var current_type := int(current_dict.get("type", NODE_BATTLE))
			var links: Array = current_dict.get("next_indices", [])
			for raw_idx in links:
				var next_idx := int(raw_idx)
				if next_idx < 0 or next_idx >= next_nodes.size():
					continue
				var next_node := next_nodes[next_idx] as Dictionary
				var next_type := int(next_node.get("type", NODE_BATTLE))
				if _should_break_route_pacing_pair(current_type, next_type):
					if bool(next_node.get("route_supply_lock", false)) and not bool(current_dict.get("route_supply_lock", false)):
						var current_replacement := _pick_pacing_replacement_type(current_dict, next_node, floor_idx, floor_count)
						_convert_node_type_for_pacing(current_dict, current_replacement, era_id, floor_idx, floor_count)
					else:
						var replacement := _pick_pacing_replacement_type(current_dict, next_node, floor_idx + 1, floor_count)
						_convert_node_type_for_pacing(next_node, replacement, era_id, floor_idx + 1, floor_count)
		_ensure_floor_not_all_soft(next_nodes, era_id, floor_idx + 1, floor_count)

func _should_break_route_pacing_pair(current_type: int, next_type: int) -> bool:
	if current_type == NODE_SHOP and next_type == NODE_SHOP:
		return true
	if current_type == NODE_REST and next_type == NODE_REST:
		return true
	if current_type == NODE_EVENT and next_type == NODE_EVENT:
		return true
	return false

func _pick_pacing_replacement_type(current_node: Dictionary, next_node: Dictionary, floor_num: int, floor_count: int) -> int:
	var local_floor := _get_major_layer_local_floor(floor_num)
	var next_type := int(next_node.get("type", NODE_BATTLE))
	if next_type == NODE_BOSS:
		return NODE_BOSS
	if local_floor >= FLOORS_PER_MAJOR_LAYER - 3 or floor_num >= floor_count - 3:
		return NODE_BATTLE
	return NODE_BATTLE

func _convert_node_type_for_pacing(node: Dictionary, new_type: int, era_id: String, floor_num: int, floor_count: int) -> void:
	var old_type := int(node.get("type", NODE_BATTLE))
	if old_type == NODE_BOSS or new_type == NODE_BOSS or old_type == new_type:
		return
	if bool(node.get("route_supply_lock", false)) and old_type == NODE_SHOP:
		return
	if not node.has("original_type"):
		node["original_type"] = old_type
	node["type"] = new_type
	node["route_supply_lock"] = false
	node["pacing_adjusted"] = true
	_apply_node_variant(node, era_id, floor_num, floor_count)
	_apply_multi_enemy_pressure(node, era_id, floor_num)
	var variant := str(node.get("map_variant", "局势有变"))
	node["map_variant"] = "%s，路线转折" % variant if variant != "" else "路线转折"

func _ensure_floor_not_all_soft(floor_nodes: Array, era_id: String, floor_num: int, floor_count: int) -> void:
	if floor_nodes.is_empty() or _get_major_layer_local_floor(floor_num) == FLOORS_PER_MAJOR_LAYER - 1:
		return
	var has_battle := false
	for node in floor_nodes:
		if int((node as Dictionary).get("type", NODE_BATTLE)) == NODE_BATTLE:
			has_battle = true
			break
	if has_battle:
		return
	var target_idx := randi() % floor_nodes.size()
	_convert_node_type_for_pacing(floor_nodes[target_idx] as Dictionary, NODE_BATTLE, era_id, floor_num, floor_count)

func _refresh_map_after_pacing(map_data: Array, floor_count: int) -> void:
	for floor_idx in range(map_data.size()):
		var floor_nodes: Array = map_data[floor_idx]
		for node in floor_nodes:
			var dict := node as Dictionary
			if int(dict.get("type", NODE_BATTLE)) != NODE_BATTLE:
				dict["enemy_hp_delta"] = 0
				dict["enemy_attack_delta"] = 0
				dict["enemy_group_size"] = 1
				dict["support_count"] = 0
		_apply_node_strategy_tags(floor_nodes, floor_idx, floor_count)
		_refresh_variant_descriptions(floor_nodes)

func _build_history_node_links(node_idx: int, current_count: int, next_count: int) -> Array:
	if next_count <= 0:
		return []
	if next_count == 1:
		return [0]
	var denominator = maxi(current_count - 1, 1)
	var center = int(round(float(node_idx) * float(next_count - 1) / float(denominator)))
	center = clamp(center, 0, next_count - 1)
	var links: Array = [center]
	var offset = 1 if randf() < 0.5 else -1
	var side = clamp(center + offset, 0, next_count - 1)
	if side != center:
		links.append(side)
	return links

func _assign_history_map_positions(map_data: Array) -> void:
	for floor_idx in range(map_data.size()):
		var floor_nodes: Array = map_data[floor_idx]
		for node_idx in range(floor_nodes.size()):
			var node: Dictionary = floor_nodes[node_idx]
			if floor_nodes.size() == 1:
				node.map_x_offset = randi_range(-10, 10)
				node.map_y_offset = randi_range(-8, 8)
			else:
				node.map_x_offset = randi_range(-18, 18)
				node.map_y_offset = randi_range(-10, 10)

func _get_era_history_floor_nodes(era_id: String, floor_num: int) -> Array:
	match era_id:
		"song":
			return _get_song_history_floor_nodes(floor_num)
		"china":
			return _get_china_history_floor_nodes(floor_num)
		_:
			return _get_qin_history_floor_nodes(floor_num)

func _get_qin_history_floor_nodes(floor_num: int) -> Array:
	var far_events := [
		"盟诸侯", "使魏安边", "通齐断援", "结燕牵赵", "说韩缓兵", "离间赵臣",
		"远结齐楚", "策反边邑", "假道运粮", "合纵瓦解", "封赏客卿", "外交孤楚",
		"断赵外援", "逼韩献地", "齐国观望", "燕赵离心", "楚地失援", "天下归秦"
	]
	var near_events := [
		"函谷试锋", "攻韩取邑", "压魏河东", "拔赵边城", "破韩主力", "围赵都",
		"东出成皋", "夺魏粮道", "攻楚北境", "连破三晋", "取韩中枢", "灭赵残军",
		"扫魏旧地", "压楚江汉", "破燕关隘", "入齐旧道", "会师咸阳", "并吞六国"
	]
	var types_far := [3, 1, 3, 0, 1, 3, 1, 3, 2, 3, 1, 3, 0, 1, 3, 3, 0, 0]
	var types_near := [0, 0, 0, 0, 2, 0, 0, 1, 0, 0, 3, 0, 0, 2, 0, 0, 1, 0]
	var i = clamp(floor_num, 0, far_events.size() - 1)
	return [
		_create_history_node(types_far[i], "远交线", "远交近攻", far_events[i], "外交、离间、封赏与资源换取下一步攻势。"),
		_create_history_node(types_near[i], "近攻线", "远交近攻", near_events[i], "直接攻伐邻国，用连续战斗压出统一节奏。")
	]

func _get_song_history_floor_nodes(floor_num: int) -> Array:
	var phase := "五代十国"
	var central := ["朱温篡唐", "后梁争衡", "后唐入洛", "后晋割让", "契丹南下", "后汉短祚", "后周整军", "柴荣北伐", "陈桥兵变", "杯酒释兵", "伐荆湖", "收后蜀", "定南汉", "平南唐", "吴越归宋", "北汉孤城", "燕云未复", "宋室立国"]
	var south := ["江南割据", "吴越保境", "荆南观望", "楚地内乱", "闽地争权", "南汉海贸", "后蜀富庶", "南唐词宴", "水师整备", "市舶通利", "荆湖归附", "蜀道转运", "岭南入贡", "江南纳土", "钱氏献地", "南方一统", "文治开局", "天下归宋"]
	var north := ["河东军镇", "幽云旧盟", "晋阳坚城", "辽骑压境", "边镇募兵", "后周强军", "世宗亲征", "北伐未竟", "禁军拥立", "削藩归权", "边军整训", "汴梁商路", "北汉求辽", "围困晋阳", "太原未下", "太原决战", "燕云遗恨", "守成之局"]
	var types_c := [3, 0, 0, 3, 0, 1, 2, 0, 3, 1, 0, 0, 0, 0, 1, 0, 3, 0]
	var types_s := [1, 1, 3, 0, 3, 1, 2, 3, 0, 1, 0, 1, 0, 3, 1, 0, 2, 0]
	var types_n := [0, 3, 0, 0, 1, 2, 0, 3, 0, 3, 2, 1, 0, 0, 3, 0, 3, 0]
	var i = clamp(floor_num, 0, central.size() - 1)
	return [
		_create_history_node(types_c[i], "中原线", phase, central[i], "五代更替的主轴，战斗密度高但奖励更直接。"),
		_create_history_node(types_s[i], "十国线", phase, south[i], "南方割据与经营路线，商队、营寨与异闻更多。"),
		_create_history_node(types_n[i], "北境线", phase, north[i], "边镇、辽骑与北汉压力，风险高但收益稳定。")
	]

func _get_china_history_floor_nodes(floor_num: int) -> Array:
	var phase := "前期内战" if floor_num < 6 else ("抗战" if floor_num < 12 else "内战")
	var front_a := ["南昌风雷", "秋收转折", "井冈会师", "反围剿", "长征启程", "遵义转折", "卢沟桥", "淞沪会战", "太原会战", "徐州会战", "武汉会战", "百团出击", "重庆谈判", "东北争夺", "辽沈战役", "淮海战役", "平津战役", "渡江战役"]
	var front_b := ["城市暗线", "工运潮起", "根据地初成", "苏区经营", "湘江血战", "陕北落脚", "统一战线", "敌后游击", "根据地扩张", "破袭交通", "持久战论", "大生产", "双十协定", "中原突围", "战略反攻", "支前动员", "北平和谈", "南京解放"]
	var front_c := ["军阀混战", "白色恐怖", "围追堵截", "土地动员", "雪山草地", "西安事变", "全面抗战", "南京危局", "长沙防线", "滇缅通道", "敌后反扫荡", "战略相持", "和谈破裂", "三大战役序幕", "黑土决战", "华东合围", "华北收束", "开国前夜"]
	var types_a := [0, 3, 0, 0, 0, 3, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0, 0, 0]
	var types_b := [3, 1, 2, 1, 0, 2, 3, 0, 1, 0, 3, 2, 3, 0, 0, 1, 3, 0]
	var types_c := [0, 3, 0, 1, 0, 3, 0, 3, 0, 1, 0, 2, 3, 0, 0, 0, 3, 0]
	var i = clamp(floor_num, 0, front_a.size() - 1)
	return [
		_create_history_node(types_a[i], "主战线", phase, front_a[i], "正面推进，战斗压力最高。"),
		_create_history_node(types_b[i], "根据地线", phase, front_b[i], "经营、整备与异闻更多，适合构筑成长。"),
		_create_history_node(types_c[i], "危局线", phase, front_c[i], "高风险历史节点，奖励与惩罚都更明显。")
	]

func _get_era_final_route_name(era_id: String) -> String:
	match era_id:
		"song":
			return "宋兴线"
		"china":
			return "终局线"
		_:
			return "并天下"

func _get_era_final_phase_name(era_id: String) -> String:
	match era_id:
		"song":
			return "天下归宋"
		"china":
			return "新中国"
		_:
			return "秦并六国"

func _get_era_final_event_title(era_id: String) -> String:
	match era_id:
		"song":
			return "定鼎汴梁"
		"china":
			return "开国大典"
		_:
			return "一统天下"

func _get_era_final_event_desc(era_id: String) -> String:
	match era_id:
		"song":
			return "五代十国终局，面对最后灾主。"
		"china":
			return "前期内战、抗战、内战之后的终局决战。"
		_:
			return "远交与近攻都汇入最后一战。"

func _get_era_layer_boss_route_name(era_id: String, layer_index: int) -> String:
	if layer_index >= MAJOR_LAYER_COUNT - 1:
		return _get_era_final_route_name(era_id)
	match era_id:
		"song":
			return ["五代关", "北境关"][clamp(layer_index, 0, 1)]
		"china":
			return ["内战关", "抗战关"][clamp(layer_index, 0, 1)]
		_:
			return ["函谷关", "关东关"][clamp(layer_index, 0, 1)]

func _get_era_layer_phase_name(era_id: String, layer_index: int) -> String:
	var layer_title := _get_major_layer_title(layer_index)
	if layer_index >= MAJOR_LAYER_COUNT - 1:
		return "%s · %s" % [layer_title, _get_era_final_phase_name(era_id)]
	match era_id:
		"song":
			return "%s · %s" % [layer_title, ["五代初定", "北境承压"][clamp(layer_index, 0, 1)]]
		"china":
			return "%s · %s" % [layer_title, ["前期内战", "全面抗战"][clamp(layer_index, 0, 1)]]
		_:
			return "%s · %s" % [layer_title, ["西出立势", "东进强压"][clamp(layer_index, 0, 1)]]

func _get_era_layer_boss_title(era_id: String, layer_index: int) -> String:
	if layer_index >= MAJOR_LAYER_COUNT - 1:
		return _get_era_final_event_title(era_id)
	match era_id:
		"song":
			return ["陈桥旧影", "燕云重压"][clamp(layer_index, 0, 1)]
		"china":
			return ["围剿旧影", "烽火国难"][clamp(layer_index, 0, 1)]
		_:
			return ["函谷令主", "关东战主"][clamp(layer_index, 0, 1)]

func _get_era_layer_boss_desc(era_id: String, layer_index: int) -> String:
	if layer_index >= MAJOR_LAYER_COUNT - 1:
		return _get_era_final_event_desc(era_id)
	match era_id:
		"song":
			return ["第一大层关底，检验前期经营是否站稳。", "第二大层关底，边患压力开始逼迫取舍。"][clamp(layer_index, 0, 1)]
		"china":
			return ["第一大层关底，检验早期血线与基础布局。", "第二大层关底，抗战压力要求资源与节奏同时成立。"][clamp(layer_index, 0, 1)]
		_:
			return ["第一大层关底，检验快攻与补给是否成型。", "第二大层关底，连续强压会惩罚摇摆路线。"][clamp(layer_index, 0, 1)]
