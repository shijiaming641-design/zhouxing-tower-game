class_name ComboData
extends Resource

## 连招数据定义

@export var combo_id: String = ""
@export var display_name: String = ""
@export var sequence: Array[int] = []
@export var effect_type: String = ""  ## direct_damage, shield, heal
@export var effect_value: int = 0
@export var description: String = ""

## 预定义连招列表
static func get_all_combos() -> Array[ComboData]:
	var combos: Array[ComboData] = []
	
	var combo1 := ComboData.new()
	combo1.combo_id = "lightning"
	combo1.display_name = "闪电突袭"
	combo1.sequence = [0, 0, 1]  # OO△
	combo1.effect_type = "direct_damage"
	combo1.effect_value = 3
	combo1.description = "造成3点伤害"
	combos.append(combo1)
	
	var combo2 := ComboData.new()
	combo2.combo_id = "defense"
	combo2.display_name = "稳固防御"
	combo2.sequence = [1, 1, 2]  # △△□
	combo2.effect_type = "shield"
	combo2.effect_value = 1
	combo2.description = "护甲+1"
	combos.append(combo2)
	
	return combos

## 检查输入序列是否匹配连招
static func check_combo(moves: Array[int]) -> ComboData:
	var all_combos := get_all_combos()
	
	for combo in all_combos:
		if _matches_sequence(moves, combo.sequence):
			return combo
	
	return null

static func _matches_sequence(moves: Array[int], sequence: Array[int]) -> bool:
	if moves.size() < sequence.size():
		return false
	
	var start_idx := moves.size() - sequence.size()
	for i in range(sequence.size()):
		if moves[start_idx + i] != sequence[i]:
			return false
	
	return true
