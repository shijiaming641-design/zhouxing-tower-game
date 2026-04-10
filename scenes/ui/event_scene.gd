class_name EventScene
extends Control

## 事件场景 - 好事件/坏事件选择界面
## 处理事件展示、选项选择、属性选择等

signal event_completed
signal battle_requested(is_good: bool, context: Dictionary)

const MOVE_SYMBOLS: Array[String] = ["○", "△", "□"]
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
	print("[EventScene] Ready")

## 设置事件数据并显示
func setup_event(event_data: Dictionary) -> void:
	_current_event = event_data
	_selected_choice = -1
	_input_locked = false  # 重置输入锁
	
	# 清除旧选项
	_clear_options()
	
	var is_good: bool = event_data.type == "good"
	
	# 设置标题和描述
	if is_good:
		title_label.text = "🎉 好事降临！"
		title_label.modulate = Color(0.4, 1, 0.4)
		desc_label.text = "恭喜你！请选择你想要的好处："
		desc_label.modulate = Color(0.5, 0.8, 0.5)
		_show_good_options(event_data)
	else:
		title_label.text = "💀 坏事发生！"
		title_label.modulate = Color(1, 0.4, 0.4)
		desc_label.text = "很不幸，你需要承受这个后果。"
		desc_label.modulate = Color(0.8, 0.5, 0.5)
		_show_bad_options(event_data)
	
	_update_status()

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
	confirm_btn.text = "确认获得"
	confirm_btn.custom_minimum_size = Vector2(200, 60)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	confirm_btn.modulate = Color(0.6, 1, 0.6)
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
	battle_btn.text = "开始战斗"
	battle_btn.custom_minimum_size = Vector2(200, 60)
	battle_btn.add_theme_font_size_override("font_size", 20)
	battle_btn.modulate = Color(0.8, 1, 0.8)
	battle_btn.pressed.connect(_on_start_good_battle.bind(event_data))
	options_container.add_child(battle_btn)

func _get_battle_reward_preview_good(battle_type: String) -> String:
	match battle_type:
		"random_equip":
			return "2胜→🔴红色装备 | 1胜→🔵蓝色装备 | 0胜→⚪白色装备\n⚠️第一回合不计入结果"
		"shop_discount":
			return "2胜→商店7折 | 1胜→商店8折 | 0胜→商店9折\n⚠️第一回合不计入结果"
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
	confirm_btn.text = "接受命运"
	confirm_btn.custom_minimum_size = Vector2(200, 60)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	confirm_btn.modulate = Color(1, 0.7, 0.7)
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
		{"name": "❤️ 生命", "desc": "血量-2（上限-2）", "value": 0},
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
		btn.pressed.connect(_on_attribute_selected.bind(event_data, attr.value))
		options_container.add_child(btn)

## 装备损失选项
func _show_equip_loss_choice(event_data: Dictionary) -> void:
	var backpack = GameState.backpack
	var has_equipment: bool = not backpack.is_empty()
	
	# 选项1：直接丢失
	var option1_btn = Button.new()
	option1_btn.custom_minimum_size = Vector2(450, 80)
	option1_btn.add_theme_font_size_override("font_size", 18)
	option1_btn.modulate = Color(1, 0.75, 0.75)
	
	if has_equipment:
		var random_item = backpack[randi() % backpack.size()]
		option1_btn.text = "直接丢失一件随机装备\n将丢失：%s" % random_item.name
		option1_btn.pressed.connect(_on_direct_equip_loss.bind(event_data))
	else:
		option1_btn.text = "直接丢失一件随机装备\n（背包为空，无损失）"
		option1_btn.disabled = true
	options_container.add_child(option1_btn)
	
	# 选项2：通过战斗决定
	var option2_btn = Button.new()
	option2_btn.custom_minimum_size = Vector2(450, 80)
	option2_btn.add_theme_font_size_override("font_size", 18)
	option2_btn.modulate = Color(0.9, 0.9, 1)
	
	if has_equipment:
		option2_btn.text = "通过战斗决定\n2胜→丢🔴红色 | 1胜→丢🔵蓝色 | 0胜→丢⚪白色\n⚠️第一回合不计入结果"
	else:
		option2_btn.text = "通过战斗决定\n⚠️背包为空，战斗无意义"
		option2_btn.disabled = true
	
	option2_btn.pressed.connect(_on_start_equip_loss_battle.bind(event_data))
	options_container.add_child(option2_btn)
	
	# 如果背包为空，显示提示
	if not has_equipment:
		var empty_label = Label.new()
		empty_label.text = "⚠️ 背包为空，无需担心装备损失"
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.modulate = Color(0.6, 0.6, 0.5)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		options_container.add_child(empty_label)

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
	label.text = "✅ 获得：%s" % event_data.get("description", "")
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(0.3, 1, 0.3)
	options_container.add_child(label)
	
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(func(): event_completed.emit())

func _show_failure_and_advance(event_data: Dictionary) -> void:
	_clear_options()
	
	var label = Label.new()
	label.text = "❌ 承受：%s" % event_data.get("description", "")
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(1, 0.3, 0.3)
	options_container.add_child(label)
	
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(func(): event_completed.emit())
