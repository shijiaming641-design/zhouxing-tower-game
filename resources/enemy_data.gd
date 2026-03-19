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
		# 1-5层：基础敌人 (11型)
		data.enemy_id = "basic_%d" % floor_num
		data.display_name = "学徒"
		data.max_hp = 8
		data.attack = 1
		data.ai_type = 0  # BASIC_FIXED
		data.ai_subtype = randi() % 3  # 随机固定出○、△或□
		
	elif floor_num <= 10:
		# 6-10层：精英敌人 (10型)
		data.enemy_id = "elite_%d" % floor_num
		data.display_name = "教习"
		data.max_hp = 13
		data.attack = 1
		data.ai_type = 1  # ELITE_CYCLE
		# 随机循环模式
		var patterns = [[0, 1], [0, 2], [1, 2], [0, 0, 1], [1, 1, 2]]
		data.ai_subtype = randi() % patterns.size()
		
	else:
		# 11-15层：高级敌人 (00型)
		data.enemy_id = "advanced_%d" % floor_num
		data.display_name = "大师"
		data.max_hp = 17
		data.attack = 2
		data.ai_type = 2  # ADVANCED_DYNAMIC
		data.ai_subtype = randi() % 3  # 随机子类型
	
	return data

## 生成BOSS数据 (01型)
static func generate_boss() -> EnemyData:
	var data = EnemyData.new()
	data.enemy_id = "boss"
	data.display_name = "塔之主宰"
	data.max_hp = 24
	data.attack = 1
	data.ai_type = 3  # BOSS_PHASE
	data.ai_subtype = 0
	return data

## 获取AI描述
func get_ai_description() -> String:
	match ai_type:
		0: return "固定套路"
		1: return "简单循环"
		2:
			match ai_subtype:
				0: return "读心型"
				1: return "状态型"
				2: return "模仿型"
				_: return "动态策略"
		3: return "阶段死局"
		_: return "未知"
