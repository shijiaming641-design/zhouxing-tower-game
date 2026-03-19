class_name BattleScene
extends Control

## 战斗场景 - 猜拳战斗核心

signal battle_won
signal battle_lost
signal fled

const MOVE_SYMBOLS: Array[String] = ["○", "△", "□"]

# 敌人数据
var enemy_data: EnemyData = null
var enemy_hp: int = 0
var enemy_ai: EnemyAI = null

# 战斗状态
var is_player_turn: bool = true
var cheat_mode: bool = false
var predicted_move: int = -1

@onready var enemy_hp_label: Label = $EnemyPanel/HPLabel
@onready var enemy_atk_label: Label = $EnemyPanel/AtkLabel
@onready var enemy_combo_label: Label = $EnemyPanel/ComboLabel

@onready var player_hp_label: Label = $PlayerPanel/HPLabel
@onready var player_gold_label: Label = $PlayerPanel/GoldLabel
@onready var player_shield_label: Label = $PlayerPanel/ShieldLabel

@onready var move_info_label: Label = $CenterPanel/MoveInfo
@onready var last_move_label: Label = $CenterPanel/LastMove
@onready var result_label: Label = $CenterPanel/Result

@onready var combo_labels: Array[Label] = [$CenterPanel/Combo1, $CenterPanel/Combo2]
@onready var cheat_label: Label = $CenterPanel/CheatLabel

@onready var move_buttons: Array[Button] = [$CenterPanel/CircleBtn, $CenterPanel/TriBtn, $CenterPanel/SquareBtn]
@onready var cheat_btn: Button = $CenterPanel/CheatBtn

func _ready() -> void:
	_setup_battle()
	_update_ui()
	
	# 连接按钮
	move_buttons[0].pressed.connect(_on_move_pressed.bind(0))
	move_buttons[1].pressed.connect(_on_move_pressed.bind(1))
	move_buttons[2].pressed.connect(_on_move_pressed.bind(2))
	cheat_btn.pressed.connect(_on_cheat_pressed)

func setup_battle(data: EnemyData) -> void:
	enemy_data = data
	enemy_hp = data.max_hp
	enemy_ai = EnemyAI.new()
	enemy_ai.ai_type = data.ai_type as EnemyAI.Type

func _setup_battle() -> void:
	if enemy_data == null:
		return
	
	enemy_hp_label.text = _get_hp_bar(enemy_hp, enemy_data.max_hp, "💚")
	enemy_atk_label.text = "⚔️ %d" % enemy_data.attack
	enemy_combo_label.text = "📋 敌人: " + _get_enemy_combo_text()
	
	_update_player_ui()
	_update_combo_display()

func _get_hp_bar(current: int, max_hp: int, emoji: String) -> String:
	var bar: String = ""
	for i in range(max_hp):
		bar += emoji if i < current else "🖤"
	return bar + " %d/%d" % [current, max_hp]

func _get_enemy_combo_text() -> String:
	return "??"  # TODO: 根据AI显示提示

func _update_player_ui() -> void:
	player_hp_label.text = _get_hp_bar(GameState.player_hp, GameState.player_max_hp, "❤️")
	player_gold_label.text = "💰 %d" % GameState.player_gold
	player_shield_label.text = "🛡️ %d" % GameState.player_shield

func _update_ui() -> void:
	_update_player_ui()
	cheat_label.text = "🔍 外挂: %d/2" % GameState.cheat_points

func _update_combo_display() -> void:
	var combos: Array[ComboData] = ComboData.get_all_combos()
	for i in range(min(combos.size(), combo_labels.size())):
		var combo: ComboData = combos[i]
		var seq_text: String = ""
		for m in combo.sequence:
			seq_text += MOVE_SYMBOLS[m]
		combo_labels[i].text = "%s %s (%s)" % [combo.display_name, seq_text, combo.description]

func _on_move_pressed(move_type: int) -> void:
	if not is_player_turn or cheat_mode:
		return
	
	_process_turn(move_type)

func _process_turn(player_move: int) -> void:
	EventBus.player_moved.emit(player_move)
	
	var enemy_move: int = enemy_ai.get_next_move(enemy_hp, enemy_data.max_hp)
	enemy_ai.add_player_history(player_move)
	
	move_info_label.text = "你: %s" % MOVE_SYMBOLS[player_move]
	
	var result: String = _calculate_result(player_move, enemy_move)
	last_move_label.text = "上回合: 你%s 敌%s" % [MOVE_SYMBOLS[player_move], MOVE_SYMBOLS[enemy_move]]
	result_label.text = result
	
	_update_ui()
	
	# 检查战斗结束
	if GameState.player_hp <= 0:
		battle_lost.emit()
	elif enemy_hp <= 0:
		battle_won.emit()

func _calculate_result(player_move: int, enemy_move: int) -> String:
	# 检查连招
	var combo: ComboData = ComboData.check_combo(GameState.combo_moves)
	var combo_text: String = ""
	
	if combo != null:
		combo_text = combo.display_name
		if combo.effect_type == "direct_damage":
			enemy_hp = maxi(enemy_hp - combo.effect_value, 0)
			combo_text += "(造成%d点伤害!)" % combo.effect_value
		elif combo.effect_type == "shield":
			GameState.player_shield = combo.effect_value
			combo_text += "(护盾+%d)" % combo.effect_value
		GameState.combo_moves.clear()
	
	if player_move == enemy_move:
		# 平局
		GameState.add_cheat_point()
		enemy_hp = maxi(enemy_hp - 1, 0)  # 平局1点基础伤害
		return "🤝 平局! %s" % combo_text
	
	# 判断胜负: ○ > △ > □ > ○
	var player_wins: bool = (player_move == 0 and enemy_move == 1) or \
							(player_move == 1 and enemy_move == 2) or \
							(player_move == 2 and enemy_move == 0)
	
	if player_wins:
		enemy_hp = maxi(enemy_hp - GameState.player_attack, 0)
		return "✅ 命中! %s" % combo_text
	else:
		var damage: int = enemy_data.attack
		var shield_absorb: int = mini(GameState.player_shield, damage)
		GameState.player_shield -= shield_absorb
		var actual_damage: int = damage - shield_absorb
		GameState.player_hp = maxi(GameState.player_hp - actual_damage, 0)
		
		var result: String = "❌ 失误!"
		if shield_absorb > 0:
			result += " 护盾抵消%d!" % shield_absorb
		return result + " %s" % combo_text

func _on_cheat_pressed() -> void:
	if GameState.cheat_points <= 0 or cheat_mode:
		return
	
	GameState.consume_cheat_point()
	cheat_mode = true
	predicted_move = randi() % 3
	result_label.text = "🔍 预知: 敌人将出%s | 请选择结果" % MOVE_SYMBOLS[predicted_move]
	
	# 显示选择按钮
	_show_cheat_buttons()

func _show_cheat_buttons() -> void:
	# 临时隐藏出招按钮，显示结果选择
	for btn in move_buttons:
		btn.visible = false
	
	var win_btn: Button = Button.new()
	win_btn.text = "强制胜利"
	win_btn.position = Vector2(480, 490)
	win_btn.custom_minimum_size = Vector2(100, 35)
	win_btn.pressed.connect(_apply_cheat_result.bind("win"))
	win_btn.name = "CheatWin"
	$CenterPanel.add_child(win_btn)
	
	var draw_btn: Button = Button.new()
	draw_btn.text = "强制平局"
	draw_btn.position = Vector2(590, 490)
	draw_btn.custom_minimum_size = Vector2(100, 35)
	draw_btn.pressed.connect(_apply_cheat_result.bind("draw"))
	draw_btn.name = "CheatDraw"
	$CenterPanel.add_child(draw_btn)
	
	var lose_btn: Button = Button.new()
	lose_btn.text = "强制失败"
	lose_btn.position = Vector2(700, 490)
	lose_btn.custom_minimum_size = Vector2(100, 35)
	lose_btn.pressed.connect(_apply_cheat_result.bind("lose"))
	lose_btn.name = "CheatLose"
	$CenterPanel.add_child(lose_btn)

func _hide_cheat_buttons() -> void:
	for btn_name in ["CheatWin", "CheatDraw", "CheatLose"]:
		var btn: Button = $CenterPanel.get_node_or_null(btn_name)
		if btn:
			btn.queue_free()
	
	for btn in move_buttons:
		btn.visible = true

func _apply_cheat_result(result: String) -> void:
	_hide_cheat_buttons()
	cheat_mode = false
	
	var enemy_move: int = predicted_move
	var player_move: int = 0
	
	match result:
		"win":
			# 强制胜利：玩家出招克制敌人
			if enemy_move == 0: player_move = 2
			elif enemy_move == 1: player_move = 0
			else: player_move = 1
		"draw":
			player_move = enemy_move
		"lose":
			if enemy_move == 0: player_move = 1
			elif enemy_move == 1: player_move = 2
			else: player_move = 0
	
	_process_turn(player_move)
