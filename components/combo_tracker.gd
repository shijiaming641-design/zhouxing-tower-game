class_name ComboTracker
extends Node

## 连招追踪器 - 追踪玩家出招并检测连招

signal combo_detected(combo: ComboData)
signal move_added(move_type: int, sequence: Array[int])

const MAX_HISTORY: int = 3

var move_history: Array[int] = []
var current_combo: ComboData = null

func _ready() -> void:
	EventBus.player_moved.connect(_on_player_moved)

func _on_player_moved(move_type: int) -> void:
	add_move(move_type)

func add_move(move_type: int) -> void:
	move_history.append(move_type)
	
	# 只保留最近3个出招
	if move_history.size() > MAX_HISTORY:
		move_history.pop_front()
	
	move_added.emit(move_type, move_history.duplicate())
	_check_combo()

func _check_combo() -> void:
	var detected := ComboData.check_combo(move_history)
	
	if detected != null:
		current_combo = detected
		combo_detected.emit(detected)
		# 触发连招后清空历史
		move_history.clear()

func clear_history() -> void:
	move_history.clear()
	current_combo = null

func get_history() -> Array[int]:
	return move_history.duplicate()

func get_move_symbol(move_type: int) -> String:
	match move_type:
		0: return "○"  # 圆
		1: return "△"  # 三角
		2: return "□"  # 方
		_: return "?"

func get_history_text() -> String:
	var text := ""
	for move in move_history:
		text += get_move_symbol(move)
	return text
