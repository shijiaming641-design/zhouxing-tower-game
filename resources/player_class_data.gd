class_name PlayerClassData
extends Resource

## 角色职业数据定义

@export var class_id: int = 0
@export var display_name: String = ""
@export var description: String = ""
@export var base_hp: int = 6
@export var base_attack: int = 2
@export var special_ability: String = ""

const CLASS_DEFINITIONS: Array[Dictionary] = [
	{"id": 0, "name": "探索者", "hp": 6, "atk": 2, "desc": "平衡型"},
	{"id": 1, "name": "长生者", "hp": 10, "atk": 1, "desc": "高血量"},
	{"id": 2, "name": "冒险家", "hp": 8, "atk": 2, "desc": "连击加成"},
	{"id": 3, "name": "剑士", "hp": 5, "atk": 4, "desc": "高攻击"},
	{"id": 4, "name": "坦克", "hp": 15, "atk": 1, "desc": "超高血量"}
]

static func get_class_data(class_id: int) -> Dictionary:
	if class_id >= 0 and class_id < CLASS_DEFINITIONS.size():
		return CLASS_DEFINITIONS[class_id]
	return CLASS_DEFINITIONS[0]

static func get_all_classes() -> Array[Dictionary]:
	return CLASS_DEFINITIONS
