extends Resource

# ComboData - 连招数据资源

@export var combo_id: String = ""
@export var display_name: String = ""
@export var sequence: Array = []
@export var effect_type: String = ""
@export var effect_value: int = 0
@export var description: String = ""
@export var cooldown: int = 0
@export var is_combat: bool = true
@export var is_exclusive: bool = false
@export var exclusive_class: String = ""
@export var role: String = ""
@export var usage_hint: String = ""

static var _combo_db_cache = null

static func _get_combo_db():
	if _combo_db_cache == null:
		_combo_db_cache = load("res://resources/combo_database.gd").new()
		_combo_db_cache._init_database()
	return _combo_db_cache

static func get_all_combos():
	var combos = []
	for combo_info in _get_combo_db().get_all_combos():
		combos.append(_from_combo_info(combo_info))
	return combos

static func get_combo_by_id(id: String):
	"""根据ID获取连招数据"""
	var combo_info = _get_combo_db().get_combo_by_id(id)
	if combo_info:
		return _from_combo_info(combo_info)
	return null

static func check_combo(moves):
	var all_combos = get_all_combos()
	
	for combo in all_combos:
		if _matches_sequence(moves, combo.sequence):
			return combo
	
	return null

static func _matches_sequence(moves, sequence):
	if moves.size() < sequence.size():
		return false
	
	var start_idx = moves.size() - sequence.size()
	for i in range(sequence.size()):
		if moves[start_idx + i] != sequence[i]:
			return false
	
	return true

# 医生专属连招
static func get_doctor_combos():
	return get_exclusive_combos("医生")

# 黑客专属连招
static func get_hacker_combos():
	return get_exclusive_combos("黑客")

# 商人专属连招
static func get_merchant_combos():
	return get_exclusive_combos("商人")

# 农民专属连招
static func get_farmer_combos():
	return get_exclusive_combos("农民")

static func get_wanderer_combos():
	return get_exclusive_combos("流浪者")

static func get_exclusive_combos(char_class: String) -> Array:
	var result: Array = []
	for combo_info in _get_combo_db().get_class_exclusive_combos(char_class):
		result.append(_from_combo_info(combo_info))
	return result

static func _from_combo_info(combo_info):
	var combo = load("res://resources/combo_data.gd").new()
	combo.combo_id = combo_info.id
	combo.display_name = combo_info.name
	combo.sequence = combo_info.sequence.duplicate()
	combo.effect_type = combo_info.effect_type
	combo.effect_value = combo_info.effect_value
	combo.description = combo_info.description
	combo.cooldown = combo_info.cooldown
	combo.is_combat = true
	combo.is_exclusive = combo_info.exclusive_class != ""
	combo.exclusive_class = combo_info.exclusive_class
	combo.role = combo_info.role
	combo.usage_hint = combo_info.usage_hint
	return combo

static func sequence_to_string(sequence):
	var symbols = ["○", "△", "□"]
	var result = ""
	for i in range(sequence.size()):
		if i > 0:
			result += "→"
		result += symbols[sequence[i]]
	return result
