class_name EnemyData
extends Resource

## 敌人数据定义 - 新AI系统

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 8
@export var attack: int = 1
@export var ai_type: int = 0  # 对应 EnemyAI.Type
@export var ai_subtype: int = 0  # 用于高级敌人的子类型

const MID_ELITE_EARLY_POOL: Array[int] = [0, 2, 3]
const MID_ELITE_LATE_POOL: Array[int] = [1, 2, 3, 4, 4]
const ADVANCED_EARLY_POOL: Array[int] = [0, 1, 2, 4]
const ADVANCED_LATE_POOL: Array[int] = [0, 1, 2, 3, 4]
const FLOORS_PER_MAJOR_LAYER := 19
const MAJOR_LAYER_COUNT := 3

# 11=基础(固定) 10=精英(循环) 00=高级(动态) 01=BOSS(阶段)
## 根据层数生成敌人数据
static func generate_by_floor(floor_num: int) -> EnemyData:
	var data = EnemyData.new()
	var layer_index := _get_major_layer_index(floor_num)
	var local_floor := _get_major_layer_local_floor(floor_num)

	if local_floor <= 2:
		# 1-3层：基础敌人 - 明确展示三种固定手，让玩家先学会读敌
		data.enemy_id = "basic_%d" % floor_num
		data.display_name = get_era_enemy_name(_get_basic_name(local_floor))
		data.max_hp = 8 + layer_index * 2
		data.attack = 1 + int(layer_index >= 2)
		data.ai_type = 0  # BASIC_FIXED
		data.ai_subtype = local_floor % 3

	elif local_floor <= 5:
		# 4-6层：轻节奏敌人 - 开始引入循环、重复和反制
		data.enemy_id = "early_elite_%d" % floor_num
		data.display_name = get_era_enemy_name(_get_elite_name_by_subtype([0, 1, 2][local_floor - 3]))
		data.max_hp = 10 + int((local_floor - 3) * 0.8) + layer_index * 2
		data.attack = 1 + int(layer_index >= 1)
		data.ai_type = 1  # ELITE_CYCLE
		data.ai_subtype = [0, 1, 2][local_floor - 3]

	elif local_floor <= 11:
		# 7-12层：精英敌人 - 从中期性格池抽取，保持新鲜感但不破坏可读性
		data.enemy_id = "elite_%d" % floor_num
		data.ai_subtype = _pick_stage_subtype(MID_ELITE_EARLY_POOL if local_floor <= 8 else MID_ELITE_LATE_POOL, 1)
		data.max_hp = 13 + int((local_floor - 6) * 0.9) + layer_index * 2
		data.attack = 2 + int(layer_index >= 2)
		data.ai_type = 1  # ELITE_CYCLE
		_refresh_display_name(data)
		
	else:
		# 13层以后：高级敌人 - 高级性格池随机，让后半程有“这局遇到谁”的差异
		data.enemy_id = "advanced_%d" % floor_num
		data.ai_subtype = _pick_stage_subtype(ADVANCED_EARLY_POOL if local_floor <= 14 else ADVANCED_LATE_POOL, 2)
		data.max_hp = 17 + int((local_floor - 12) * 1.0) + layer_index * 3
		data.attack = 2 + layer_index
		data.ai_type = 2  # ADVANCED_DYNAMIC
		_refresh_display_name(data)
	
	_register_generated_personality(data)
	return data

static func generate_for_history_node(floor_num: int, node: Dictionary) -> EnemyData:
	var data := generate_by_floor(floor_num)
	data = tune_for_history_branch(data, floor_num, node)
	data = _apply_history_node_pressure(data, node)
	_register_generated_personality(data)
	return data

static func tune_for_history_branch(data: EnemyData, floor_num: int, node: Dictionary) -> EnemyData:
	if data == null or data.ai_type == 3:
		return data
	var route_name := str(node.get("route_name", ""))
	match GameState.selected_era_id:
		"song":
			_tune_song_branch(data, floor_num, route_name)
		"china":
			_tune_china_branch(data, floor_num, route_name)
		_:
			_tune_qin_branch(data, floor_num, route_name)
	_refresh_display_name(data)
	return data

static func _branch_pick(options: Array[int], ai_type: int) -> int:
	if options.is_empty():
		return 0
	return _pick_stage_subtype(options, ai_type)

static func _pick_stage_subtype(options: Array[int], ai_type: int) -> int:
	if options.is_empty():
		return 0
	var blocked := -1
	if int(GameState.last_enemy_ai_type) == ai_type:
		blocked = int(GameState.last_enemy_ai_subtype)
	var candidates: Array[int] = []
	for option in options:
		var subtype := int(option)
		if subtype != blocked:
			candidates.append(subtype)
	if candidates.is_empty():
		candidates = options.duplicate()
	return int(candidates[randi() % candidates.size()])

static func _register_generated_personality(data: EnemyData) -> void:
	if data != null and data.ai_type >= 1 and data.ai_type <= 2:
		GameState.register_enemy_personality(data.ai_type, data.ai_subtype)

static func _refresh_display_name(data: EnemyData) -> void:
	if data == null:
		return
	match data.ai_type:
		0:
			data.display_name = get_era_enemy_name(_get_basic_name(data.ai_subtype))
		1:
			data.display_name = get_era_enemy_name(_get_elite_name_by_subtype(data.ai_subtype))
		2:
			data.display_name = get_era_enemy_name(_get_advanced_name_by_subtype(data.ai_subtype))

static func _tune_qin_branch(data: EnemyData, floor_num: int, route_name: String) -> void:
	var local_floor := _get_major_layer_local_floor(floor_num)
	match route_name:
		"远交线":
			_apply_branch_subtype(data, floor_num, [0, 1, 0], [0, 1, 4], [0, 4, 3])
			if data.ai_type >= 1:
				data.max_hp += 1
		"近攻线":
			_apply_branch_subtype(data, floor_num, [1, 2, 1], [2, 3, 0], [1, 2, 4])
			data.max_hp += 1
			if local_floor >= 8 and data.ai_type >= 1:
				data.attack += 1

static func _tune_song_branch(data: EnemyData, floor_num: int, route_name: String) -> void:
	var local_floor := _get_major_layer_local_floor(floor_num)
	match route_name:
		"中原线":
			_apply_branch_subtype(data, floor_num, [0, 1, 2], [0, 4, 2], [1, 3, 0])
		"十国线":
			_apply_branch_subtype(data, floor_num, [2, 0, 2], [1, 0, 4], [3, 1, 4])
			data.max_hp += 2
		"北境线":
			_apply_branch_subtype(data, floor_num, [2, 2, 1], [2, 1, 3], [0, 1, 2])
			data.max_hp += 2
			if local_floor >= 10 and data.ai_type >= 1:
				data.attack += 1

static func _tune_china_branch(data: EnemyData, floor_num: int, route_name: String) -> void:
	var local_floor := _get_major_layer_local_floor(floor_num)
	match route_name:
		"主战线":
			_apply_branch_subtype(data, floor_num, [1, 2, 0], [2, 3, 0], [1, 2, 0])
			if local_floor >= 10 and data.ai_type >= 1:
				data.attack += 1
		"根据地线":
			_apply_branch_subtype(data, floor_num, [0, 1, 0], [1, 0, 4], [3, 4, 1])
			data.max_hp += 1
		"危局线":
			_apply_branch_subtype(data, floor_num, [2, 1, 2], [3, 2, 4], [0, 2, 4])
			data.max_hp += 1
			if local_floor >= 12 and data.ai_type >= 1:
				data.attack += 1

static func _apply_history_node_pressure(data: EnemyData, node: Dictionary) -> EnemyData:
	if data == null:
		return data
	data.max_hp = maxi(1, data.max_hp + int(node.get("enemy_hp_delta", 0)))
	data.attack = maxi(1, data.attack + int(node.get("enemy_attack_delta", 0)))
	return data

static func _apply_branch_subtype(data: EnemyData, floor_num: int, basic: Array[int], elite: Array[int], advanced: Array[int]) -> void:
	match data.ai_type:
		0:
			data.ai_subtype = _branch_pick(basic, data.ai_type)
		1:
			data.ai_subtype = _branch_pick(elite, data.ai_type)
		2:
			data.ai_subtype = _branch_pick(advanced, data.ai_type)

static func _get_major_layer_index(floor_num: int) -> int:
	return clamp(int(maxi(floor_num, 0) / FLOORS_PER_MAJOR_LAYER), 0, MAJOR_LAYER_COUNT - 1)

static func _get_major_layer_local_floor(floor_num: int) -> int:
	return int(maxi(floor_num, 0) % FLOORS_PER_MAJOR_LAYER)

static func _get_basic_name(floor: int) -> String:
	var names = ["纯天学徒", "纯人学徒", "纯地学徒", "新兵", "见习生", "守门人"]
	return names[floor % names.size()]

static func _get_elite_name(floor: int) -> String:
	var names = ["切换者", "捍卫者", "反击者", "双变者", "教习", "战术家"]
	return names[floor % names.size()]

static func _get_elite_name_by_subtype(subtype: int) -> String:
	match subtype:
		0:
			return "切换者"
		1:
			return "捍卫者"
		2:
			return "反击者"
		3:
			return "双变者"
		_:
			return "战术家"

static func _get_advanced_name(floor: int) -> String:
	var names = ["读心者", "攻防者", "模仿者", "智者", "大师", "宗师"]
	return names[floor % names.size()]

static func _get_advanced_name_by_subtype(subtype: int) -> String:
	match subtype:
		0:
			return "读心者"
		1:
			return "攻防者"
		2:
			return "模仿者"
		3:
			return "智者"
		4:
			return "诱势者"
		_:
			return "宗师"

static func get_era_enemy_name(base_name: String) -> String:
	match GameState.selected_era_id:
		"song":
			var song_map = {
				"纯天学徒": "天势教习",
				"纯人学徒": "人势教习",
				"纯地学徒": "地势教习",
				"新兵": "边军新卒",
				"见习生": "行营见习",
				"守门人": "寨门巡卒",
				"切换者": "换阵都头",
				"捍卫者": "寨防统制",
				"反击者": "反锋校尉",
				"双变者": "双机都巡",
				"教习": "阵图教习",
				"战术家": "军议参佐",
				"读心者": "窥局谋士",
				"攻防者": "攻守提举",
				"模仿者": "镜策模仿者",
				"诱势者": "诱势谋士",
				"智者": "筹算智者",
				"大师": "兵图大师",
				"宗师": "国朝宗师",
				"塔之主宰": "汴梁旧影"
			}
			return str(song_map.get(base_name, base_name))
		"china":
			var china_map = {
				"纯天学徒": "天势残响",
				"纯人学徒": "人势残响",
				"纯地学徒": "地势残响",
				"新兵": "复线新锋",
				"见习生": "山河见证者",
				"守门人": "长城守望者",
				"切换者": "百代换相者",
				"捍卫者": "山河捍卫者",
				"反击者": "逆势反锋者",
				"双变者": "双相异变体",
				"教习": "终局教习",
				"战术家": "百代战术家",
				"读心者": "百代窥局者",
				"攻防者": "攻守同构体",
				"模仿者": "旧影模仿者",
				"诱势者": "旧势诱导者",
				"智者": "终局智者",
				"大师": "山河大师",
				"宗师": "百代宗师",
				"塔之主宰": "百代共主"
			}
			return str(china_map.get(base_name, base_name))
		_:
			var qin_map = {
				"纯天学徒": "天势卒",
				"纯人学徒": "人势卒",
				"纯地学徒": "地势卒",
				"新兵": "锐卒",
				"见习生": "军中见习",
				"守门人": "关门守卒",
				"切换者": "换阵锐士",
				"捍卫者": "方阵卫",
				"反击者": "反锋吏士",
				"双变者": "双变军候",
				"教习": "军阵教习",
				"战术家": "军议吏",
				"读心者": "窥势者",
				"攻防者": "攻守将",
				"模仿者": "仿势者",
				"诱势者": "诱势者",
				"智者": "军谋者",
				"大师": "阵法大师",
				"宗师": "兵家宗师",
				"塔之主宰": "赳秦战主"
			}
			return str(qin_map.get(base_name, base_name))

static func get_era_ai_description(base_text: String) -> String:
	match GameState.selected_era_id:
		"song":
			return "宋卷·%s" % base_text
		"china":
			return "终局·%s" % base_text
		_:
			return "秦卷·%s" % base_text

## 生成BOSS数据 (01型)
static func generate_boss() -> EnemyData:
	var data = EnemyData.new()
	data.enemy_id = "boss"
	data.display_name = get_era_enemy_name("塔之主宰")
	data.max_hp = 34
	data.attack = 3
	data.ai_type = 3  # BOSS_PHASE
	data.ai_subtype = 0
	return data

## 获取AI描述
func get_ai_description() -> String:
	var desc := ""
	match ai_type:
		0:
			match ai_subtype:
				0: desc = "纯天型"
				1: desc = "纯人型"
				2: desc = "纯地型"
				_: desc = "固定套路"
		1:
			match ai_subtype:
				0: desc = "切换者(天地循环)"
				1: desc = "捍卫者(人人天循环)"
				2: desc = "反击者(抓重复手)"
				3: desc = "双变者(不重复)"
				4: desc = "破局者(盯临门布局)"
				_: desc = "简单循环"
		2:
			match ai_subtype:
				0: desc = "读心者(抓重复/常用)"
				1: desc = "攻防态(低血变招)"
				2: desc = "模仿者(克制上招)"
				3: desc = "随机智者"
				4: desc = "诱势者(反布局手)"
				_: desc = "高级策略"
		3:
			desc = "一阶段循环，最终形态100%克制"
		_:
			desc = "未知"
	return get_era_ai_description(desc)
