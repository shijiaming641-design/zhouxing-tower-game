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
		"desc": "青木·酸：命数归零时复起一次，恢复七成命数并获得护甲",
		"combos": ["望闻问切", "妙手回春"]
	},
	{
		"id": 1, 
		"name": "黑客", 
		"hp": 7,
		"atk": 4, 
		"desc": "赤火·苦：机括点数+1，机括存储上限+1，爆发最高但容错最低",
		"combos": ["病毒植入", "系统过载"]
	},
	{
		"id": 2, 
		"name": "商人", 
		"hp": 6,
		"atk": 2, 
		"desc": "白金·辛：进入休息点时自动获得金币，把路线收益转成器物优势",
		"combos": ["金钱帝国", "精算头脑"]
	},
	{
		"id": 3, 
		"name": "农民", 
		"hp": 11,
		"atk": 2, 
		"desc": "黄土·甘：护甲可叠加并带入下一战，垒满后溢出护甲会转成反压",
		"combos": ["固若金汤", "五谷丰登"]
	},
	{
		"id": 4,
		"name": "流浪者",
		"hp": 8,
		"atk": 3,
		"desc": "玄水·咸：均衡初始属性，拥有独立基础布局组，适合随机应变",
		"combos": ["记忆爆破", "相位护盾"]
	}
]

static func get_class_data(id: int) -> Dictionary:
	if id >= 0 and id < CLASS_DEFINITIONS.size():
		return CLASS_DEFINITIONS[id]
	return CLASS_DEFINITIONS[0]

static func get_class_display_name(id: int) -> String:
	var base_name := str(get_class_data(id).get("name", "未知"))
	match GameState.selected_era_id:
		"song":
			match id:
				0: return "医官"
				1: return "机巧吏"
				2: return "市舶商"
				3: return "乡勇"
				4: return "行旅客"
		"china":
			match id:
				0: return "复兴医官"
				1: return "星火算师"
				2: return "山河行商"
				3: return "守土义民"
				4: return "归乡者"
		_:
			match id:
				0: return "军医"
				1: return "术算师"
				2: return "行商"
				3: return "屯田客"
				4: return "游侠"
	return base_name

static func get_class_display_desc(id: int) -> String:
	match GameState.selected_era_id:
		"song":
			match id:
				0: return "青木·酸｜太医续命：初始命数+1，战后回稳1命，命数归零时复起并得护甲"
				1: return "赤火·苦｜机巧密算：机括+1，暴伤额外提高，战后获得5金币"
				2: return "白金·辛｜市易生财：初始8金币，持币开战得甲，花钱蓄击，休整得20金币"
				3: return "黄土·甘｜乡勇固守：初始6金币，护甲可叠加；垒满后溢出护甲转反压"
				4: return "玄水·咸｜行旅百转：初始命数+1与攻击+1，并拥有独立基础布局组"
		"china":
			match id:
				0: return "青木·酸｜薪火续命：开局得1机括，战后回稳1命，复起并得护甲"
				1: return "赤火·苦｜星图密算：初始攻击+1与机括+1，暴伤更高"
				2: return "白金·辛｜百业通筹：初始12金币，持币开战得甲，花钱蓄击，休整得18金币"
				3: return "黄土·甘｜守土成垒：初始命数+1与护甲+2，垒满后溢出护甲转反压"
				4: return "玄水·咸｜万里同归：开局得1机括与1护甲，战后再获1机括"
		_:
			match id:
				0: return "青木·酸｜军前续命：初始命数+1，战后回稳1命，命数归零时复起并得护甲"
				1: return "赤火·苦｜机巧密算：初始攻击+1，机括+1，战后再得1机括"
				2: return "白金·辛｜辎重滚利：初始5金币，持币开战得甲，花钱蓄击，休整得16金币"
				3: return "黄土·甘｜屯田成垒：初始护甲+2，战后得甲；垒满后溢出护甲转反压"
				4: return "玄水·咸｜异路同归：初始攻击+1，并拥有独立基础布局组"
	return str(get_class_data(id).get("desc", ""))

static func get_all_classes() -> Array[Dictionary]:
	return CLASS_DEFINITIONS

static func get_class_combos(class_id: int):
	var class_data := get_class_data(class_id)
	var combo_script = load("res://resources/combo_data.gd")
	var combos = combo_script.get_exclusive_combos(class_data["name"])
	combo_script.clear_combo_db_cache()
	return combos
