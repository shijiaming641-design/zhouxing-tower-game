extends Resource

# PlayerClassData - 角色职业数据资源

@export var class_id: int = 0
@export var display_name: String = ""
@export var description: String = ""
@export var base_hp: int = 6
@export var base_attack: int = 2
@export var special_ability: String = ""

const CLASS_DEFINITIONS: Array[Dictionary] = [
	{
		"id": 0, 
		"name": "医生", 
		"hp": 9, 
		"atk": 2, 
		"desc": "起死回生：血量归零时自动满血复活一次（每局一次）",
		"combos": ["望闻问切", "妙手回春"]
	},
	{
		"id": 1, 
		"name": "黑客", 
		"hp": 6, 
		"atk": 4, 
		"desc": "科学上网：外挂点数+1，外挂存储上限+1",
		"combos": ["病毒植入", "系统过载"]
	},
	{
		"id": 2, 
		"name": "商人", 
		"hp": 7, 
		"atk": 2, 
		"desc": "睡后收入：进入休息点时自动获得20金币",
		"combos": ["金钱帝国", "精算头脑"]
	},
	{
		"id": 3, 
		"name": "农民", 
		"hp": 12, 
		"atk": 2, 
		"desc": "种因得果：护盾可叠加，并保留到下一场战斗",
		"combos": ["固若金汤", "五谷丰登"]
	},
	{
		"id": 4,
		"name": "流浪者",
		"hp": 8,
		"atk": 3,
		"desc": "异路同归：均衡初始属性，拥有独立基础连招组",
		"combos": ["记忆爆破", "相位护盾"]
	}
]

static func get_class_data(id: int) -> Dictionary:
	if id >= 0 and id < CLASS_DEFINITIONS.size():
		return CLASS_DEFINITIONS[id]
	return CLASS_DEFINITIONS[0]

static func get_all_classes() -> Array[Dictionary]:
	return CLASS_DEFINITIONS

static func get_class_combos(class_id: int):
	var class_data := get_class_data(class_id)
	var combo_script = load("res://resources/combo_data.gd")
	return combo_script.get_exclusive_combos(class_data["name"])
