class_name EnemyData
extends Resource

## 敌人数据定义 - 新AI系统

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 8
@export var attack: int = 1
@export var ai_type: int = 0  # 对应 EnemyAI.Type
@export var ai_subtype: int = 0  # 用于高级敌人的子类型

# 11=基础(固定) 10=精英(循环) 00=高级(动态) 01=BOSS(阶段)
## 根据层数生成敌人数据
static func generate_by_floor(floor_num: int) -> EnemyData:
	var data = EnemyData.new()
	
	if floor_num <= 5:
		# 1-6层：基础敌人 (11型) - 固定单一出招
		data.enemy_id = "basic_%d" % floor_num
		data.display_name = _get_basic_name(floor_num)
		data.max_hp = 8
		data.attack = 1
		data.ai_type = 0  # BASIC_FIXED
		data.ai_subtype = randi() % 3  # 随机固定出○、△或□
		
	elif floor_num <= 11:
		# 7-12层：精英敌人 (10型) - 双招循环
		data.enemy_id = "elite_%d" % floor_num
		data.display_name = _get_elite_name(floor_num)
		data.max_hp = 13
		data.attack = 1
		data.ai_type = 1  # ELITE_CYCLE
		data.ai_subtype = randi() % 5  # 5种循环模式
		
	else:
		# 13-18层：高级敌人 (00型) - 三招策略
		data.enemy_id = "advanced_%d" % floor_num
		data.display_name = _get_advanced_name(floor_num)
		data.max_hp = 17
		data.attack = 2
		data.ai_type = 2  # ADVANCED_DYNAMIC
		data.ai_subtype = randi() % 5  # 5种策略模式
	
	return data

static func _get_basic_name(floor: int) -> String:
	var names = ["纯圆学徒", "纯角学徒", "纯方学徒", "新兵", "见习生", "守门人"]
	return names[floor % names.size()]

static func _get_elite_name(floor: int) -> String:
	var names = ["切换者", "捍卫者", "反击者", "双变者", "教习", "战术家"]
	return names[floor % names.size()]

static func _get_advanced_name(floor: int) -> String:
	var names = ["读心者", "攻防者", "模仿者", "智者", "大师", "宗师"]
	return names[floor % names.size()]

## 生成BOSS数据 (01型)
static func generate_boss() -> EnemyData:
	var data = EnemyData.new()
	data.enemy_id = "boss"
	data.display_name = "塔之主宰"
	data.max_hp = 30
	data.attack = 2
	data.ai_type = 3  # BOSS_PHASE
	data.ai_subtype = 0
	return data

## 获取AI描述
func get_ai_description() -> String:
	match ai_type:
		0:
			match ai_subtype:
				0: return "纯○型"
				1: return "纯△型"
				2: return "纯□型"
				_: return "固定套路"
		1:
			match ai_subtype:
				0: return "切换者(○□循环)"
				1: return "捍卫者(△△○循环)"
				2: return "反击者(条件切换)"
				3: return "双变者(不重复)"
				4: return "循环型"
				_: return "简单循环"
		2:
			match ai_subtype:
				0: return "读心者(克制常用)"
				1: return "攻防态(血量切换)"
				2: return "模仿者(克制上招)"
				3: return "随机智者"
				4: return "动态策略"
				_: return "高级策略"
		3: return "一阶段循环，最终形态100%克制"
		_: return "未知"
