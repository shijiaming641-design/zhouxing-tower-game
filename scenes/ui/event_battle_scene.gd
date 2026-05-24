class_name EventBattleScene
extends Control

const MoveSymbols = preload("res://resources/move_symbols.gd")

## 事件战斗场景 - 2回合猜拳对战
## 用于：随机装备、商店折扣、装备损失事件的战斗判定
## 规则：第1回合不计入结果，第2、3回合决定最终奖励

signal battle_finished(result: Dictionary)
signal battle_cancelled

const MOVE_SYMBOLS: Array[String] = MoveSymbols.MOVE_NAMES

var _is_good_event: bool = true
var _context: Dictionary = {}
var _current_round: int = 0
var _wins: int = 0
var _round_results: Array[bool] = []  # 存储每回合胜负
var _battle_type: String = ""
var _enemy_move: int = -1  # 用于显示

@onready var title_label: Label = $TitleLabel
@onready var desc_label: Label = $DescLabel
@onready var result_label: Label = $ResultLabel
@onready var round_label: Label = $RoundLabel
@onready var move_info_label: Label = $MoveInfo

@onready var circle_btn: Button = $MoveButtons/CircleBtn
@onready var tri_btn: Button = $MoveButtons/TriBtn
@onready var square_btn: Button = $MoveButtons/SquareBtn

@onready var move_buttons: Array[Button] = []

func _ready() -> void:
	move_buttons = [circle_btn, tri_btn, square_btn]
	
	circle_btn.pressed.connect(_on_move_pressed.bind(0))
	tri_btn.pressed.connect(_on_move_pressed.bind(1))
	square_btn.pressed.connect(_on_move_pressed.bind(2))
	
	# 连接 RandomEventManager 信号
	RandomEventManager.event_battle_started.connect(_on_battle_started)
	RandomEventManager.event_battle_round_result.connect(_on_round_result)
	RandomEventManager.event_battle_ended.connect(_on_battle_ended)

## 初始化战斗
func setup_battle(is_good: bool, context: Dictionary) -> void:
	_is_good_event = is_good
	_context = context
	_battle_type = context.get("battle_type", "")
	_current_round = 0
	_wins = 0
	_round_results = []
	
	# 启动事件战斗
	RandomEventManager.start_event_battle(is_good, context)
	
	_update_ui()

func _update_ui() -> void:
	# 标题
	if _is_good_event:
		title_label.text = _get_good_battle_title()
		title_label.modulate = Color(0.4, 1, 0.4)
		desc_label.text = _get_good_event_desc()
		desc_label.modulate = Color(0.5, 0.8, 0.5)
	else:
		title_label.text = _get_bad_battle_title()
		title_label.modulate = Color(1, 0.4, 0.4)
		desc_label.text = _get_bad_event_desc()
		desc_label.modulate = Color(0.8, 0.5, 0.5)
	
	# 更新回合显示
	_update_round_display()
	
	# 更新奖励预览
	_update_reward_preview()

func _get_good_event_desc() -> String:
	match _battle_type:
		"random_equip":
			return _get_random_equip_desc()
		"shop_discount":
			return _get_discount_duel_desc()
		_:
			return _get_good_battle_title()

func _get_bad_event_desc() -> String:
	match _battle_type:
		"equip_loss":
			return _get_equip_loss_desc()
		_:
			return _get_bad_battle_title()

func _get_good_battle_title() -> String:
	match GameState.selected_era_id:
		"song":
			return "⚔️ 市易博弈"
		"china":
			return "⚔️ 山河争势"
		_:
			return "⚔️ 天时争夺"

func _get_bad_battle_title() -> String:
	match GameState.selected_era_id:
		"song":
			return "⚔️ 边患对冲"
		"china":
			return "⚔️ 旧债逼阵"
		_:
			return "⚔️ 逆势对抗"

func _get_random_equip_desc() -> String:
	match GameState.selected_era_id:
		"song":
			return "百工遗器争夺\n以布局胜负决定获得器物品秩。"
		"china":
			return "百代遗器争夺\n以布局胜负决定获得终局器物。"
		_:
			return "随机装备战斗\n选择出招来击败命运！"

func _get_discount_duel_desc() -> String:
	match GameState.selected_era_id:
		"song":
			return "市舶让利博弈\n选择布局来争取更好的行商折价。"
		"china":
			return "山河行商博弈\n选择布局来争取更好的终局折价。"
		_:
			return "行商让利对决\n选择布局来争取更好折扣！"

func _get_equip_loss_desc() -> String:
	match GameState.selected_era_id:
		"song":
			return "器物折损对抗\n选择布局来减少你的损失。"
		"china":
			return "遗器折损对抗\n选择布局来减少终局损失。"
		_:
			return "装备损失战斗\n选择出招来减少损失！"

func _update_round_display() -> void:
	var round_num = _current_round + 1
	var status_text = "第 %d / 3 回合" % [round_num]
	
	if _current_round == 0:
		status_text += " （不计入结果）"
	elif _current_round >= 1:
		status_text += " 胜利数：%d" % _wins
	
	round_label.text = status_text
	
	# 更新按钮文字
	circle_btn.text = MoveSymbols.move_name(0)
	tri_btn.text = MoveSymbols.move_name(1)
	square_btn.text = MoveSymbols.move_name(2)
	ArtRegistry.apply_button_icon(circle_btn, "tian", true, "天：%s" % MoveSymbols.move_name(0))
	ArtRegistry.apply_button_icon(tri_btn, "ren", true, "人：%s" % MoveSymbols.move_name(1))
	ArtRegistry.apply_button_icon(square_btn, "di", true, "地：%s" % MoveSymbols.move_name(2))

func _update_reward_preview() -> void:
	var preview_text = ""
	
	if _is_good_event:
		match _battle_type:
			"random_equip":
				preview_text = "📦 奖励预览：\n2胜 = 🔴红色装备\n1胜 = 🔵蓝色装备\n0胜 = ⚪白色装备"
			"shop_discount":
				preview_text = "🏪 折扣预览：\n2胜 = 7折\n1胜 = 8折\n0胜 = 9折"
	else:
		match _battle_type:
			"equip_loss":
				preview_text = "💀 损失预览：\n2胜 = 丢⚪白色装备（最小损失）\n1胜 = 丢🔵蓝色装备\n0胜 = 丢🔴红色装备（最大损失）"
	
	if _current_round > 0:
		preview_text += "\n\n当前胜利：%d" % _wins
	
	move_info_label.text = preview_text
	move_info_label.modulate = Color(0.7, 0.7, 0.6)

func _on_move_pressed(player_move: int) -> void:
	if _current_round >= 3:
		return
	
	# 生成敌人出招
	_enemy_move = randi() % 3
	
	# 处理回合
	var result = RandomEventManager.process_event_battle_round(player_move, _enemy_move)
	
	if result.get("continues", false):
		_show_round_result(player_move, _enemy_move, result)
	else:
		_show_final_result(player_move, _enemy_move, result)

func _show_round_result(player_move: int, enemy_move: int, result: Dictionary) -> void:
	_current_round += 1
	var round_won = result.get("won", false)
	if _current_round > 1 and round_won:  # 第1回合不计入
		_wins += 1
	_round_results.append(round_won)
	
	# 显示结果
	var symbols = MOVE_SYMBOLS
	var result_text = result.get("message", "")
	
	if _current_round == 1:
		result_label.text = "%s\n你: %s vs 敌: %s" % [result_text, symbols[player_move], symbols[enemy_move]]
		result_label.modulate = Color(0.7, 0.7, 0.6)  # 第一回合灰色
		_update_round_display()
		_update_reward_preview()
		
		# 延迟后继续下一回合
		await get_tree().create_timer(1.5).timeout
		
		result_label.text = "第2回合开始，请继续布势..."
		result_label.modulate = Color(0.9, 0.9, 0.8)
	else:
		result_label.text = "%s\n你: %s vs 敌: %s" % [result_text, symbols[player_move], symbols[enemy_move]]
		if round_won:
			result_label.modulate = Color(0.3, 1, 0.3)
		else:
			result_label.modulate = Color(1, 0.3, 0.3)
		
		_update_round_display()
		_update_reward_preview()
		
		# 延迟后继续下一回合
		await get_tree().create_timer(1.5).timeout
		
		if _current_round < 3:
			result_label.text = "第%d回合开始，请继续布势..." % (_current_round + 1)
			result_label.modulate = Color(0.9, 0.9, 0.8)

func _show_final_result(player_move: int, enemy_move: int, result: Dictionary) -> void:
	_current_round = 3
	var symbols = MOVE_SYMBOLS
	
	# 显示最终结果
	var final_text = result.get("message", "")
	result_label.text = "%s\n你: %s vs 敌: %s" % [final_text, symbols[player_move], symbols[enemy_move]]
	result_label.modulate = Color(1, 0.8, 0.3)
	
	# 禁用按钮
	for btn in move_buttons:
		btn.disabled = true
	
	# 结算战斗
	var final_result = RandomEventManager.finish_event_battle()
	final_result.wins = _wins
	
	# 显示最终奖励
	var reward_text = _get_reward_text(_wins)
	
	await get_tree().create_timer(1.0).timeout
	
	result_label.text += "\n\n%s" % reward_text
	
	# 通知完成
	await get_tree().create_timer(2.0).timeout
	battle_finished.emit(final_result)

func _get_reward_text(wins: int) -> String:
	if _is_good_event:
		match _battle_type:
			"random_equip":
				match wins:
					2: return "🎉 争得 🔴红色器物！"
					1: return "🎉 争得 🔵蓝色器物！"
					_: return "🎉 争得 ⚪白色器物！"
			"shop_discount":
				match wins:
					2: return "🎉 行商7折！"
					1: return "🎉 行商8折！"
					_: return "🎉 行商9折！"
	else:
		match _battle_type:
			"equip_loss":
				match wins:
					2: return "😅 尚可，只折损⚪白色器物"
					1: return "😰 失手，折损🔵蓝色器物"
					_: return "😭 惨败，折损🔴红色器物！"
	return ""

# ===== 信号回调 =====

func _on_battle_started(is_good: bool, context: Dictionary) -> void:
	DebugLog.log("[EventBattleScene] Battle started: is_good=", is_good)

func _on_round_result(round_num: int, player_move: int, enemy_move: int, won: bool) -> void:
	DebugLog.log("[EventBattleScene] Round %d: player=%d enemy=%d won=%s" % [round_num, player_move, enemy_move, won])

func _on_battle_ended(wins: int, is_good_event: bool, context: Dictionary) -> void:
	DebugLog.log("[EventBattleScene] Battle ended: wins=%d is_good=%s" % [wins, is_good_event])
