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
	MIND_READER,     # 读心型：克制玩家最常用
	STATE_BASED,     # 状态型：根据血量调整
	MIMIC,           # 模仿型：克制玩家上一招
	RANDOM_SMART,    # 随机智者：随机但不连续3次相同
	SEQUENCE_MIMIC   # 序列模仿：克制玩家上招所克的招
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
var last_enemy_move: int = -1

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

# 精英敌人：根据子类型设置模式
func setup_elite_by_subtype(subtype: int):
	ai_type = Type.ELITE_CYCLE
	match subtype:
		0:  # 切换者：○→□→○→□
			cycle_pattern = [0, 2]
		1:  # 捍卫者：△→△→○→△→△→○
			cycle_pattern = [1, 1, 0]
		2:  # 反击者：用动态处理
			cycle_pattern = [2]  # 默认出□，在get_next_move中特殊处理
		3:  # 双变者：随机但不重复
			cycle_pattern = [0, 2]  # 占位，实际用随机
		_:  # 默认循环
			cycle_pattern = [0, 2]
	cycle_index = 0
	# 反击者和双变者需要特殊标记
	dynamic_subtype = subtype

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
	var move = randi() % 3
	match ai_type:
		Type.BASIC_FIXED:
			move = _basic_fixed_move()
		Type.ELITE_CYCLE:
			move = _elite_cycle_move(predicted_player_move)
		Type.ADVANCED_DYNAMIC:
			move = _advanced_dynamic_move(enemy_hp, enemy_max_hp, predicted_player_move)
		Type.BOSS_PHASE:
			move = _boss_phase_move(predicted_player_move)
		_:
			move = randi() % 3
	last_enemy_move = move
	return move

## 11型 - 基础敌人：只会固定出招
func _basic_fixed_move() -> int:
	return fixed_move

## 10型 - 精英敌人：按固定规律循环
func _elite_cycle_move(predicted_player_move: int = -1) -> int:
	# 反击者：专抓玩家重复手；没抓到时用固定底手，保持可读。
	if dynamic_subtype == 2:
		var repeat_trap := _repeat_trap_move(2, 0.84)
		if repeat_trap >= 0:
			return repeat_trap
		return 2

	# 破局者：看到玩家布局临门时，会尝试压住完成手。
	if dynamic_subtype == 4 and predicted_player_move >= 0:
		if randf() < 0.64:
			return _counter_move(predicted_player_move)
	
	# 双变者：随机但不连续出相同招
	if dynamic_subtype == 3:
		var move = randi() % 3
		var attempts = 0
		while move == last_enemy_move and attempts < 10:
			move = randi() % 3
			attempts += 1
		return move
	
	# 普通循环
	if cycle_pattern.is_empty():
		return randi() % 3
	
	var move = cycle_pattern[cycle_index]
	cycle_index = (cycle_index + 1) % cycle_pattern.size()
	return move

## 00型 - 高级敌人：动态策略
func _advanced_dynamic_move(enemy_hp: int, enemy_max_hp: int, predicted_player_move: int = -1) -> int:
	match dynamic_subtype:
		DynamicSubtype.MIND_READER:
			return _mind_reader_move()
		DynamicSubtype.STATE_BASED:
			return _state_based_move(enemy_hp, enemy_max_hp)
		DynamicSubtype.MIMIC:
			return _mimic_move()
		DynamicSubtype.RANDOM_SMART:
			return _random_smart_move()
		DynamicSubtype.SEQUENCE_MIMIC:
			return _anti_layout_move(predicted_player_move)
		_:
			return randi() % 3

# 读心型：统计玩家最常用，然后克制
func _mind_reader_move() -> int:
	var repeat_trap := _repeat_trap_move(-1, 0.78)
	if repeat_trap >= 0:
		return repeat_trap
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
		# 高血量 - 两拍压前，给玩家读到节奏。
		return 0 if player_history.size() % 2 == 0 else 1
	elif hp_percent > 0.3:
		# 中血量 - 仍有摇摆，但避免完全无规则。
		if last_enemy_move >= 0 and randf() < 0.58:
			return (last_enemy_move + 1) % 3
		return randi() % 3
	else:
		# 低血量 - 明确变招，开始抓玩家上一手/重复手。
		var repeat_trap := _repeat_trap_move(-1, 0.82)
		if repeat_trap >= 0:
			return repeat_trap
		if last_player_move >= 0 and randf() < 0.74:
			return _counter_move(last_player_move)
		return 2

# 模仿型：克制玩家上一招
func _mimic_move() -> int:
	if last_player_move < 0:
		return randi() % 3
	
	# 90%概率克制上一招，10%随机
	if randf() < 0.9:
		return _counter_move(last_player_move)
	return randi() % 3

# 随机智者：完全随机但不会连续3回合出相同招
var _last_two_moves: Array[int] = []
func _random_smart_move() -> int:
	var move = randi() % 3
	# 检查是否会导致连续3次相同
	if _last_two_moves.size() >= 2:
		if _last_two_moves[0] == _last_two_moves[1] and move == _last_two_moves[0]:
			# 换一个不同的
			move = (move + 1 + randi() % 2) % 3
	_last_two_moves.append(move)
	if _last_two_moves.size() > 2:
		_last_two_moves.pop_front()
	return move

# 序列模仿：克制玩家上招所克制的招（引诱策略）
func _sequence_mimic_move() -> int:
	if last_player_move < 0:
		return randi() % 3
	
	# 玩家上招克的招 → 我们出那个招来反克
	# 例如玩家出○(克△)，我们出△引诱 → 但实际上我们要克制玩家上招的克制对象
	# 玩家出○(0) → ○克△(1) → 我们有高概率出△(1)
	# 玩家出△(1) → △克□(2) → 我们有高概率出□(2)
	# 玩家出□(2) → □克○(0) → 我们有高概率出○(0)
	# 即：我们出玩家上招的克制对象（被玩家上招克的那个）
	var target = (last_player_move + 1) % 3  # 0→1, 1→2, 2→0
	if randf() < 0.8:
		return target
	return randi() % 3

func _anti_layout_move(predicted_player_move: int) -> int:
	if predicted_player_move >= 0:
		if randf() < 0.80:
			return _counter_move(predicted_player_move)
		return predicted_player_move
	return _sequence_mimic_move()

func _repeat_trap_move(fallback_move: int = -1, trap_chance: float = 0.80) -> int:
	if player_history.size() >= 2:
		var last := int(player_history[player_history.size() - 1])
		var prev := int(player_history[player_history.size() - 2])
		if last == prev and randf() < trap_chance:
			return _counter_move(last)
	return fallback_move

## 01型 - BOSS：阶段死局
func _boss_phase_move(predicted_player_move: int) -> int:
	match boss_phase:
		1:
			# 一阶段：固定循环 ○→△→□（可预测，给玩家适应时间）
			var move = boss_cycle[boss_cycle_index]
			boss_cycle_index = (boss_cycle_index + 1) % boss_cycle.size()
			return move
		2:
			# 二阶段/最终形态：100%克制玩家出招
			# 玩家必须依靠装备加成、连招升级带来的数值优势来弥补猜拳劣势
			if predicted_player_move >= 0:
				return _counter_move(predicted_player_move)
			# 没有预测时，使用读心（100%概率克制最常用招）
			if player_history.size() >= 2:
				var counts = [0, 0, 0]
				for m in player_history:
					counts[m] += 1
				var most_used = 0
				if counts[1] > counts[most_used]: most_used = 1
				if counts[2] > counts[most_used]: most_used = 2
				return _counter_move(most_used)
			return randi() % 3
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
		print("💀 BOSS进入最终形态：100%克制模式!")

func reset_cycle():
	cycle_index = 0
	boss_cycle_index = 0
	last_enemy_move = -1
	_last_two_moves.clear()
