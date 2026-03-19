class_name EnemyAI
extends Node

## 敌人AI系统 - 新设计
## 11=基础(固定) 10=精英(循环) 00=高级(动态) 01=BOSS(阶段)

enum Type {
	BASIC_FIXED,      # 11型 - 基础：固定套路
	ELITE_CYCLE,      # 10型 - 精英：简单循环
	ADVANCED_DYNAMIC, # 00型 - 高级：动态策略
	BOSS_PHASE        # 01型 - BOSS：阶段死局
}

enum DynamicSubtype {
	MIND_READER,  # 读心型：克制玩家最常用
	STATE_BASED,  # 状态型：根据血量调整
	MIMIC         # 模仿型：克制玩家上一招
}

var ai_type: int = Type.BASIC_FIXED
var dynamic_subtype: int = DynamicSubtype.MIND_READER

# 基础敌人：固定出招
var fixed_move: int = 0

# 精英敌人：循环模式
var cycle_pattern: Array[int] = [0, 2]  # 默认: ○→□→○→□
var cycle_index: int = 0

# BOSS敌人
var boss_phase: int = 1
var boss_cycle: Array[int] = [0, 1, 2]  # 一阶段: ○→△→□
var boss_cycle_index: int = 0

# 玩家历史记录
var player_history: Array[int] = []
var last_player_move: int = -1

## ===== 初始化函数 =====

# 基础敌人：设置固定出招
func setup_basic_fixed(move_type: int):
	ai_type = Type.BASIC_FIXED
	fixed_move = move_type

# 精英敌人：设置循环模式
func setup_elite_cycle(pattern: Array[int]):
	ai_type = Type.ELITE_CYCLE
	cycle_pattern = pattern.duplicate()
	cycle_index = 0

# 高级敌人：设置动态子类型
func setup_advanced_dynamic(subtype: int):
	ai_type = Type.ADVANCED_DYNAMIC
	dynamic_subtype = subtype

# BOSS敌人
func setup_boss():
	ai_type = Type.BOSS_PHASE
	boss_phase = 1
	boss_cycle_index = 0

## ===== 核心决策函数 =====

func get_next_move(enemy_hp: int, enemy_max_hp: int, predicted_player_move: int = -1) -> int:
	match ai_type:
		Type.BASIC_FIXED:
			return _basic_fixed_move()
		Type.ELITE_CYCLE:
			return _elite_cycle_move()
		Type.ADVANCED_DYNAMIC:
			return _advanced_dynamic_move(enemy_hp, enemy_max_hp)
		Type.BOSS_PHASE:
			return _boss_phase_move(predicted_player_move)
		_:
			return randi() % 3

## 11型 - 基础敌人：只会固定出招
func _basic_fixed_move() -> int:
	return fixed_move

## 10型 - 精英敌人：按固定规律循环
func _elite_cycle_move() -> int:
	if cycle_pattern.is_empty():
		return randi() % 3
	
	var move = cycle_pattern[cycle_index]
	cycle_index = (cycle_index + 1) % cycle_pattern.size()
	return move

## 00型 - 高级敌人：动态策略
func _advanced_dynamic_move(enemy_hp: int, enemy_max_hp: int) -> int:
	match dynamic_subtype:
		DynamicSubtype.MIND_READER:
			return _mind_reader_move()
		DynamicSubtype.STATE_BASED:
			return _state_based_move(enemy_hp, enemy_max_hp)
		DynamicSubtype.MIMIC:
			return _mimic_move()
		_:
			return randi() % 3

# 读心型：统计玩家最常用，然后克制
func _mind_reader_move() -> int:
	if player_history.size() < 2:
		return randi() % 3
	
	var counts = [0, 0, 0]
	for m in player_history:
		counts[m] += 1
	
	# 找出玩家最常用的
	var most_used = 0
	if counts[1] > counts[most_used]: most_used = 1
	if counts[2] > counts[most_used]: most_used = 2
	
	# 80%概率克制，20%随机
	if randf() < 0.8:
		return _counter_move(most_used)
	return randi() % 3

# 状态型：根据血量动态调整
func _state_based_move(enemy_hp: int, enemy_max_hp: int) -> int:
	var hp_percent = float(enemy_hp) / float(enemy_max_hp)
	
	if hp_percent > 0.6:
		# 高血量 - 激进进攻（70%出圆或三角）
		if randf() < 0.7:
			return 0 if randf() < 0.5 else 1  # ○或△
		return 2  # □
	elif hp_percent > 0.3:
		# 中血量 - 均衡
		return randi() % 3
	else:
		# 低血量 - 防御（70%出三角或方）
		if randf() < 0.7:
			return 1 if randf() < 0.5 else 2  # △或□
		return 0  # ○

# 模仿型：克制玩家上一招
func _mimic_move() -> int:
	if last_player_move < 0:
		return randi() % 3
	
	# 90%概率克制上一招，10%随机
	if randf() < 0.9:
		return _counter_move(last_player_move)
	return randi() % 3

## 01型 - BOSS：阶段死局
func _boss_phase_move(predicted_player_move: int) -> int:
	match boss_phase:
		1:
			# 一阶段：固定循环 ○→△→□
			var move = boss_cycle[boss_cycle_index]
			boss_cycle_index = (boss_cycle_index + 1) % boss_cycle.size()
			return move
		2:
			# 二阶段：完全克制玩家本回合出招
			if predicted_player_move >= 0:
				return _counter_move(predicted_player_move)
			# 如果没有预测到，使用读心
			return _mind_reader_move()
		_:
			return randi() % 3

## ===== 辅助函数 =====

func _counter_move(player_move: int) -> int:
	"""克制关系: ○克△, △克□, □克○"""
	match player_move:
		0: return 2  # 玩家出○, 我们出□来克制? 不对,应该是出○克△, △克□, □克○
		# 修正克制关系:
		# ○(0) > △(1): ○克△
		# △(1) > □(2): △克□  
		# □(2) > ○(0): □克○
		# 所以要克制玩家:
		# 玩家出○(0), 我们出□(2)
		# 玩家出△(1), 我们出○(0)
		# 玩家出□(2), 我们出△(1)
	return (player_move + 2) % 3  # 简洁写法: 0→2, 1→0, 2→1

func add_player_history(move: int):
	last_player_move = move
	player_history.append(move)
	if player_history.size() > 10:
		player_history.pop_front()

func set_boss_phase(phase: int):
	boss_phase = phase
	if phase == 2:
		print("BOSS进入二阶段：死局模式!")

func reset_cycle():
	cycle_index = 0
	boss_cycle_index = 0
