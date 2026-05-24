class_name EventScene
extends Control

const MoveSymbols = preload("res://resources/move_symbols.gd")

## 事件场景 - 好事件/坏事件选择界面
## 处理事件展示、选项选择、属性选择等

signal event_completed
signal battle_requested(is_good: bool, context: Dictionary)

const MOVE_SYMBOLS: Array[String] = MoveSymbols.MOVE_NAMES
const RARITY_NAMES: Array[String] = ["⚪白色", "🔵蓝色", "🔴红色"]

var _current_event: Dictionary = {}
var _selected_choice: int = -1  # 用于坏事件的四选一
var _input_locked: bool = false  # 输入锁，防止连点

@onready var title_label: Label = $TitleLabel
@onready var desc_label: Label = $DescLabel
@onready var options_container: VBoxContainer = $OptionsContainer
@onready var status_label: Label = $StatusLabel
@onready var back_button: Button = $BackButton

func _ready() -> void:
	DebugLog.log("[EventScene] Ready")

func _get_good_title() -> String:
	match GameState.selected_era_id:
		"song":
			return "🎉 市井良机"
		"china":
			return "🎉 山河回响"
		_:
			return "🎉 军功嘉赏"

func _get_bad_title() -> String:
	match GameState.selected_era_id:
		"song":
			return "💀 边患骤起"
		"china":
			return "💀 百代反噬"
		_:
			return "💀 法外加身"

func _get_good_intro() -> String:
	match GameState.selected_era_id:
		"song":
			return "行旅有利可图，你可择一良机纳入局势。"
		"china":
			return "山河回响显现，你可择一馈赠纳入终局。"
		_:
			return "军令之下，择一嘉赏以扩大战果。"

func _get_bad_intro() -> String:
	match GameState.selected_era_id:
		"song":
			return "边患骤起，你必须承受其一后果。"
		"china":
			return "百代旧债浮现，你必须承受其一代价。"
		_:
			return "法外加身，你需要承受这个后果。"

func _get_confirm_good_text() -> String:
	match GameState.selected_era_id:
		"song":
			return "纳入行囊"
		"china":
			return "接引回响"
		_:
			return "确认获得"

func _get_confirm_bad_text() -> String:
	match GameState.selected_era_id:
		"song":
			return "承受边患"
		"china":
			return "承受旧债"
		_:
			return "接受命运"

## 设置事件数据并显示
func setup_event(event_data: Dictionary) -> void:
	_current_event = event_data
	_selected_choice = -1
	_input_locked = false  # 重置输入锁
	_ensure_era_header_decor()
	
	# 清除旧选项
	_clear_options()
	
	var is_good: bool = event_data.type == "good"
	
	# 设置标题和描述
	if is_good:
		title_label.text = _get_good_title()
		title_label.modulate = Color(0.4, 1, 0.4)
		desc_label.text = _get_good_intro()
		desc_label.modulate = Color(0.5, 0.8, 0.5)
		_show_good_options(event_data)
	else:
		title_label.text = _get_bad_title()
		title_label.modulate = Color(1, 0.4, 0.4)
		desc_label.text = _get_bad_intro()
		desc_label.modulate = Color(0.8, 0.5, 0.5)
		_show_bad_options(event_data)
	
	_update_status()

func _ensure_era_header_decor() -> void:
	var theme = GameState.get_era_theme()
	var band = get_node_or_null("EraBand") as ColorRect
	if band == null:
		band = ColorRect.new()
		band.name = "EraBand"
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		band.position = Vector2(84, 30)
		band.size = Vector2(1112, 12)
		add_child(band)
		move_child(band, 1)
	band.color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))

	var seal = get_node_or_null("EraSeal") as Panel
	if seal == null:
		seal = Panel.new()
		seal.name = "EraSeal"
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal.position = Vector2(100, 48)
		seal.size = Vector2(132, 42)
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		seal.add_theme_stylebox_override("panel", style)
		var seal_label = Label.new()
		seal_label.name = "Label"
		seal_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		seal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		seal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		seal_label.add_theme_font_size_override("font_size", 18)
		seal.add_child(seal_label)
		add_child(seal)
		move_child(seal, 2)
	var seal_style = seal.get_theme_stylebox("panel") as StyleBoxFlat
	if seal_style != null:
		seal_style.bg_color = theme.get("panel", Color(0.16, 0.12, 0.10, 0.92))
		seal_style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	var seal_label_ref = seal.get_node_or_null("Label") as Label
	if seal_label_ref:
		match GameState.selected_era_id:
			"song":
				seal_label_ref.text = "〔宋卷〕"
			"china":
				seal_label_ref.text = "〔终局〕"
			_:
				seal_label_ref.text = "〔秦卷〕"
		seal_label_ref.modulate = theme.get("title", Color(0.95, 0.85, 0.66, 1.0))

func _update_status() -> void:
	var hp_bar: String = ""
	for i in range(GameState.player_max_hp):
		hp_bar += "❤️" if i < GameState.player_hp else "🖤"
	
	var crit_text: String = ""
	var crit_bonus = RandomEventManager.get_crit_bonus()
	if crit_bonus > 0:
		crit_text = " 暴击+%d%%" % (crit_bonus * 20)
	
	status_label.text = "%s 💰%d 攻击%d 护甲%d%s" % [
		hp_bar, GameState.player_gold, GameState.player_attack, GameState.player_shield, crit_text]

func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()

## 显示好事件选项
func _show_good_options(event_data: Dictionary) -> void:
	# 好事件直接显示结果
	# 如果需要战斗，显示战斗说明
	
	if event_data.get("battle_required", false):
		_show_battle_required_good(event_data)
	else:
		_show_immediate_good(event_data)

func _show_immediate_good(event_data: Dictionary) -> void:
	# 直接生效的好事件
	var name_text: String = event_data.get("name", "")
	var desc_text: String = event_data.get("description", "")
	
	var label = Label.new()
	label.text = "%s\n%s" % [name_text, desc_text]
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(500, 100)
	label.modulate = Color(0.9, 0.9, 0.8)
	options_container.add_child(label)
	
	var confirm_btn = Button.new()
	confirm_btn.text = _get_confirm_good_text()
	confirm_btn.custom_minimum_size = Vector2(200, 60)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	confirm_btn.modulate = Color(0.6, 1, 0.6)
	ArtRegistry.apply_button_icon(confirm_btn, "next", false, "确认并继续")
	confirm_btn.pressed.connect(_on_confirm_good_immediate.bind(event_data))
	options_container.add_child(confirm_btn)

func _show_battle_required_good(event_data: Dictionary) -> void:
	var battle_type: String = event_data.get("battle_type", "")
	var name_text: String = event_data.get("name", "")
	
	# 显示说明
	var label = Label.new()
	label.text = "%s\n需要通过2回合战斗决定结果" % name_text
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(500, 80)
	label.modulate = Color(0.9, 0.9, 0.8)
	options_container.add_child(label)
	
	# 显示奖励预览
	var reward_label = Label.new()
	reward_label.text = _get_battle_reward_preview_good(battle_type)
	reward_label.add_theme_font_size_override("font_size", 18)
	reward_label.modulate = Color(0.6, 0.6, 0.6)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options_container.add_child(reward_label)
	
	var battle_btn = Button.new()
	battle_btn.text = "开始布势"
	battle_btn.custom_minimum_size = Vector2(200, 60)
	battle_btn.add_theme_font_size_override("font_size", 20)
	battle_btn.modulate = Color(0.8, 1, 0.8)
	ArtRegistry.apply_button_icon(battle_btn, "start", false, "开始布势")
	battle_btn.pressed.connect(_on_start_good_battle.bind(event_data))
	options_container.add_child(battle_btn)

func _get_battle_reward_preview_good(battle_type: String) -> String:
	match battle_type:
		"random_equip":
			return "2胜→🔴红色装备 | 1胜→🔵蓝色装备 | 0胜→⚪白色装备\n⚠️第一回合不计入结果"
		"shop_discount":
			return "2胜→行商7折 | 1胜→行商8折 | 0胜→行商9折\n⚠️第一回合不计入结果"
		_:
			return ""

## 显示坏事件选项
func _show_bad_options(event_data: Dictionary) -> void:
	if event_data.get("requires_choice", false):
		match event_data.get("choice_type", ""):
			"attribute":
				_show_attribute_choice(event_data)
			"equip_loss":
				_show_equip_loss_choice(event_data)
			_:
				_show_simple_bad(event_data)
	else:
		_show_simple_bad(event_data)

func _show_simple_bad(event_data: Dictionary) -> void:
	var name_text: String = event_data.get("name", "")
	var desc_text: String = event_data.get("description", "")
	
	var label = Label.new()
	label.text = "%s\n%s" % [name_text, desc_text]
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(500, 100)
	label.modulate = Color(0.9, 0.8, 0.8)
	options_container.add_child(label)
	
	var confirm_btn = Button.new()
	confirm_btn.text = _get_confirm_bad_text()
	confirm_btn.custom_minimum_size = Vector2(200, 60)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	confirm_btn.modulate = Color(1, 0.7, 0.7)
	ArtRegistry.apply_button_icon(confirm_btn, "next", false, "承受结果并继续")
	confirm_btn.pressed.connect(_on_confirm_bad_immediate.bind(event_data))
	options_container.add_child(confirm_btn)

## 四选一属性选择（坏事件的属性减少）
func _show_attribute_choice(event_data: Dictionary) -> void:
	var label = Label.new()
	label.text = "选择要减少的属性："
	label.add_theme_font_size_override("font_size", 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(0.9, 0.8, 0.8)
	options_container.add_child(label)
	
	# 属性选项
	var attributes: Array[Dictionary] = [
		{"name": "命数", "desc": "命数上限-2", "value": 0},
		{"name": "⚔️ 攻击", "desc": "攻击-1", "value": 1},
		{"name": "🛡️ 护甲", "desc": "护甲-2", "value": 2},
		{"name": "💥 暴击", "desc": "暴击率-20%", "value": 3}
	]
	
	for attr in attributes:
		var btn = Button.new()
		btn.text = "%s\n%s" % [attr.name, attr.desc]
		btn.custom_minimum_size = Vector2(300, 70)
		btn.add_theme_font_size_override("font_size", 18)
		btn.modulate = Color(1, 0.75, 0.75)
		ArtRegistry.apply_button_icon(btn, "shield" if int(attr.value) == 2 else ("attack" if int(attr.value) == 1 else "heal"), false, str(attr.name))
		btn.pressed.connect(_on_attribute_selected.bind(event_data, attr.value))
		options_container.add_child(btn)

## 装备损失选项
func _show_equip_loss_choice(event_data: Dictionary) -> void:
	var loss_candidates := _get_equipment_loss_candidates()
	var has_equipment: bool = not loss_candidates.is_empty()
	
	# 选项1：直接丢失
	var option1_btn = Button.new()
	option1_btn.custom_minimum_size = Vector2(450, 80)
	option1_btn.add_theme_font_size_override("font_size", 18)
	option1_btn.modulate = Color(1, 0.75, 0.75)
	ArtRegistry.apply_button_icon(option1_btn, "equip", false, "直接丢失随机装备")
	
	if has_equipment:
		var random_item = loss_candidates[randi() % loss_candidates.size()]
		option1_btn.text = "直接丢失一件随机装备\n将丢失：%s" % GameState.get_item_display_name(random_item)
		option1_btn.pressed.connect(_on_direct_equip_loss.bind(event_data))
	else:
		option1_btn.text = "直接丢失一件随机装备\n（无装备，无损失）"
		option1_btn.disabled = true
	options_container.add_child(option1_btn)
	
	# 选项2：通过战斗决定
	var option2_btn = Button.new()
	option2_btn.custom_minimum_size = Vector2(450, 80)
	option2_btn.add_theme_font_size_override("font_size", 18)
	option2_btn.modulate = Color(0.9, 0.9, 1)
	ArtRegistry.apply_button_icon(option2_btn, "combo", false, "通过布势战斗决定")
	
	if has_equipment:
		option2_btn.text = "通过战斗决定\n2胜→丢🔴红色 | 1胜→丢🔵蓝色 | 0胜→丢⚪白色\n⚠️第一回合不计入结果"
	else:
		option2_btn.text = "通过战斗决定\n⚠️无装备，战斗无意义"
		option2_btn.disabled = true
	
	option2_btn.pressed.connect(_on_start_equip_loss_battle.bind(event_data))
	options_container.add_child(option2_btn)
	
	# 如果背包为空，显示提示
	if not has_equipment:
		var empty_label = Label.new()
		empty_label.text = "⚠️ 无装备可折损，可以直接继续"
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.modulate = Color(0.6, 0.6, 0.5)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		options_container.add_child(empty_label)

		var continue_btn = Button.new()
		continue_btn.text = "无损失继续"
		continue_btn.custom_minimum_size = Vector2(240, 56)
		continue_btn.add_theme_font_size_override("font_size", 18)
		continue_btn.modulate = Color(0.86, 0.86, 0.78)
		ArtRegistry.apply_button_icon(continue_btn, "next", false, "继续")
		continue_btn.pressed.connect(func():
			RandomEventManager.set_last_reward_summary("结果已结算：无装备可折损。")
			_show_failure_and_advance(event_data)
		)
		options_container.add_child(continue_btn)

func _get_equipment_loss_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for item in GameState.backpack:
		candidates.append(item)
	for item in GameState.equipment_slot:
		candidates.append(item)
	return candidates

# ===== 按钮回调 =====

func _on_confirm_good_immediate(event_data: Dictionary) -> void:
	if _input_locked:
		return
	_input_locked = true
	RandomEventManager.settle_immediate_good_event(event_data)
	_show_success_and_advance(event_data)

func _on_start_good_battle(event_data: Dictionary) -> void:
	if _input_locked:
		return
	_input_locked = true
	var context: Dictionary = {
		"event_data": event_data,
		"battle_type": event_data.get("battle_type", "")
	}
	battle_requested.emit(true, context)

func _on_confirm_bad_immediate(event_data: Dictionary) -> void:
	if _input_locked:
		return
	_input_locked = true
	RandomEventManager.settle_immediate_bad_event(event_data, -1)
	_show_failure_and_advance(event_data)

func _on_attribute_selected(event_data: Dictionary, choice: int) -> void:
	if _input_locked:
		return
	_input_locked = true
	_selected_choice = choice
	RandomEventManager.settle_immediate_bad_event(event_data, choice)
	_show_failure_and_advance(event_data)

func _on_direct_equip_loss(event_data: Dictionary) -> void:
	if _input_locked:
		return
	_input_locked = true
	RandomEventManager.settle_direct_equip_loss()
	_show_failure_and_advance(event_data)

func _on_start_equip_loss_battle(event_data: Dictionary) -> void:
	if _input_locked:
		return
	_input_locked = true
	var context: Dictionary = {
		"event_data": event_data,
		"battle_type": event_data.get("battle_type", "")
	}
	battle_requested.emit(false, context)

# ===== 结果显示 =====

func _show_success_and_advance(event_data: Dictionary) -> void:
	_clear_options()
	
	var label = Label.new()
	label.text = "✅ 纳入：%s" % _get_success_feedback_text(event_data)
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(720, 0)
	label.modulate = Color(0.3, 1, 0.3)
	options_container.add_child(label)
	
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(func(): event_completed.emit())

func _show_failure_and_advance(event_data: Dictionary) -> void:
	_clear_options()
	
	var label = Label.new()
	var settlement_summary := RandomEventManager.consume_last_reward_summary()
	label.text = "❌ 承受：%s" % event_data.get("description", "")
	if settlement_summary != "":
		label.text += "\n%s" % settlement_summary
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(720, 0)
	label.modulate = Color(1, 0.3, 0.3)
	options_container.add_child(label)
	
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(func(): event_completed.emit())

func _get_success_feedback_text(event_data: Dictionary) -> String:
	var event_id = str(event_data.get("event_id", ""))
	var reward_summary = RandomEventManager.consume_last_reward_summary()
	match event_id:
		"qin_merit_grant":
			return "%s\n军令虎符压阵已强化至 Lv.%d" % [event_data.get("description", ""), GameState.get_combo_upgrade_level("qin_tiger_push")]
		"song_market_boom":
			return "%s\n市舶周转已强化至 Lv.%d" % [event_data.get("description", ""), GameState.get_combo_upgrade_level("song_trade_turn")]
		"china_dragon_vein":
			return "%s\n山河同契已强化至 Lv.%d" % [event_data.get("description", ""), GameState.get_combo_upgrade_level("china_unity_echo")]
		"armory_gift", "random_equip_duel":
			if reward_summary != "":
				return "%s\n%s" % [event_data.get("description", ""), reward_summary]
			return str(event_data.get("description", ""))
		_:
			if reward_summary != "":
				return "%s\n%s" % [event_data.get("description", ""), reward_summary]
			return str(event_data.get("description", ""))
