## 连招选择界面
class_name ComboSelect
extends Control

# 信号：完成连招选择
signal combo_selection_complete
# 信号：返回上一页
signal back_pressed

# UI 组件
var title_label: Label
var slots_label: Label
var unlock_status_label: Label
var meta_summary_label: Label
var combo_container: VBoxContainer
var special_container: VBoxContainer  # 特殊连招容器
var start_button: Button
var back_button: Button
var equipped_container: HBoxContainer
var tooltip_popup: Control = null

# 数据
var combo_database: ComboDatabase
var unlocked_combos: Array = []
var selected_combos: Array[String] = []

# 装备联动连招
const EQUIPMENT_COMBOS = [
	{"id": "bloodthirsty_slash", "requires": "妖刀", "desc": "装备妖刀后可用"},
	{"id": "reflect_aura", "requires": "护心镜", "desc": "装备护心镜后可用"},
	{"id": "absolute_hit", "requires": "精确系统全套", "desc": "装备精确系统全套后可用"}
]

# 状态依赖连招
const STATUS_COMBOS = [
	{"id": "desperate_counter", "requires": "生命≤30%", "desc": "生命值低于30%时自动触发"},
	{"id": "iron_fortress", "requires": "护甲≥5", "desc": "护甲值达到5以上时可用"},
	{"id": "supply_bombard", "requires": "背包满格", "desc": "背包满时消耗1件物品可发动"}
]

func _ready():
	print("[ComboSelect] _ready called")
	_load_combos()
	_setup_ui()
	_refresh_combo_list()
	# 默认选择第一个连招（如果有）
	if unlocked_combos.size() > 0 and selected_combos.is_empty():
		var first_combo = unlocked_combos[0]
		selected_combos.append(first_combo.id)
		GameState.equip_combo(first_combo.id)
		print("[ComboSelect] Auto-selected first combo: ", first_combo.name)
		# 刷新显示
		_update_equipped_display()
		_refresh_combo_list()
	_update_start_button()

func _setup_ui():
	print("[ComboSelect] Setting up UI")
	
	# 背景 - 全屏
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 标题
	title_label = Label.new()
	title_label.text = "⚔️ 选择起始携带连招"
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 20
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.modulate = Color(1, 0.9, 0.6)
	add_child(title_label)
	
	# 槽位显示
	slots_label = Label.new()
	slots_label.name = "SlotsLabel"
	slots_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	slots_label.offset_top = 70
	slots_label.add_theme_font_size_override("font_size", 20)
	slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slots_label.modulate = Color(0.8, 0.9, 1)
	add_child(slots_label)

	unlock_status_label = Label.new()
	unlock_status_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	unlock_status_label.offset_top = 98
	unlock_status_label.add_theme_font_size_override("font_size", 14)
	unlock_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_status_label.modulate = Color(0.65, 0.7, 0.8)
	unlock_status_label.text = GameState.get_combo_unlock_status_text()
	add_child(unlock_status_label)

	meta_summary_label = Label.new()
	meta_summary_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	meta_summary_label.offset_top = 120
	meta_summary_label.add_theme_font_size_override("font_size", 14)
	meta_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_summary_label.modulate = Color(0.72, 0.92, 0.86)
	meta_summary_label.text = _get_meta_combo_summary_text()
	add_child(meta_summary_label)

	var start_combo_hint = _create_info_icon("选择说明", "选择开局携带的 3 段序列连招；角色/装备/状态连招会在战斗内按条件显示。")
	start_combo_hint.position = Vector2(1050, 118)
	add_child(start_combo_hint)
	
	# 已装备区域
	var equipped_title = Label.new()
	equipped_title.text = "📌 已装备连招（点击取消装备）"
	equipped_title.position = Vector2(50, 150)
	equipped_title.add_theme_font_size_override("font_size", 18)
	equipped_title.modulate = Color(0.9, 0.9, 0.7)
	add_child(equipped_title)
	
	equipped_container = HBoxContainer.new()
	equipped_container.position = Vector2(50, 180)
	equipped_container.add_theme_constant_override("separation", 20)
	add_child(equipped_container)
	
	# 可选连招区域
	var available_title = Label.new()
	available_title.text = "📋 已解锁：可携带连招"
	available_title.position = Vector2(50, 310)
	available_title.add_theme_font_size_override("font_size", 18)
	available_title.modulate = Color(0.7, 0.9, 0.7)
	add_child(available_title)
	
	# 连招列表容器（使用 ScrollContainer） - 左侧可选择连招
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(50, 350)
	scroll.size = Vector2(580, 290)
	add_child(scroll)
	
	combo_container = VBoxContainer.new()
	combo_container.add_theme_constant_override("separation", 15)
	combo_container.custom_minimum_size = Vector2(560, 0)
	combo_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(combo_container)

	# ===== 特殊连招区域（右侧）=====
	# 装备联动标题
	var equip_title = Label.new()
	equip_title.text = "🔮 装备联动连招"
	equip_title.position = Vector2(650, 310)
	equip_title.add_theme_font_size_override("font_size", 18)
	equip_title.modulate = Color(0.9, 0.7, 0.9)
	add_child(equip_title)
	
	# 装备联动容器
	var equip_scroll = ScrollContainer.new()
	equip_scroll.position = Vector2(650, 350)
	equip_scroll.size = Vector2(580, 135)
	add_child(equip_scroll)
	
	var equip_container = VBoxContainer.new()
	equip_container.add_theme_constant_override("separation", 10)
	equip_container.custom_minimum_size = Vector2(560, 0)
	equip_scroll.add_child(equip_container)
	
	# 添加装备联动连招
	for combo_data in EQUIPMENT_COMBOS:
		var item = _create_special_combo_item(combo_data, "equip")
		equip_container.add_child(item)
	
	# 状态依赖标题
	var status_title = Label.new()
	status_title.text = "⚡ 状态依赖连招"
	status_title.position = Vector2(650, 505)
	status_title.add_theme_font_size_override("font_size", 18)
	status_title.modulate = Color(0.7, 0.9, 0.9)
	add_child(status_title)
	
	# 状态依赖容器
	var status_scroll = ScrollContainer.new()
	status_scroll.position = Vector2(650, 545)
	status_scroll.size = Vector2(580, 95)
	add_child(status_scroll)
	
	special_container = VBoxContainer.new()
	special_container.add_theme_constant_override("separation", 10)
	special_container.custom_minimum_size = Vector2(560, 0)
	status_scroll.add_child(special_container)
	
	# 添加状态依赖连招
	for combo_data in STATUS_COMBOS:
		var item = _create_special_combo_item(combo_data, "status")
		special_container.add_child(item)
	
	# 底部按钮
	back_button = Button.new()
	back_button.text = "← 返回"
	back_button.custom_minimum_size = Vector2(120, 50)
	back_button.position = Vector2(100, 640)
	back_button.add_theme_font_size_override("font_size", 18)
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)
	
	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "🎮 开始游戏"
	start_button.custom_minimum_size = Vector2(200, 50)
	start_button.position = Vector2(900, 640)
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.modulate = Color(0.7, 1, 0.7)
	start_button.disabled = true
	start_button.pressed.connect(_on_start_pressed)
	add_child(start_button)
	
	# 图例
	var legend = _create_info_icon("规则", "猜拳克制：○ 克 △，△ 克 □，□ 克 ○。胜者造成攻击伤害。")
	legend.position = Vector2(625, 675)
	add_child(legend)
	
	_update_slots_display()
	_update_equipped_display()

func _load_combos():
	# 创建连招数据库实例
	combo_database = ComboDatabase.new()
	combo_database._init_database()  # 手动初始化
	add_child(combo_database)
	
	# 获取已解锁的连招
	unlocked_combos = combo_database.get_start_selectable_combos()
	print("[ComboSelect] Loaded ", unlocked_combos.size(), " unlocked combos")
	
	# 从 GameState 加载已选中的连招
	selected_combos = GameState.get_equipped_combos().duplicate()

func _get_max_slots() -> int:
	return GameState.max_combo_slots

func _get_meta_combo_summary_text() -> String:
	var slot_source = "基础槽位: %d" % GameState.max_combo_slots
	var cooldown = GameState.get_meta_upgrade_count("combo_cooldown")
	var cooldown_text = "冷却缩减: -%d回合" % cooldown if cooldown > 0 else "冷却缩减: 未解锁"
	var tier_text = GameState.get_combo_unlock_status_text()
	return "%s  |  %s  |  %s" % [slot_source, cooldown_text, tier_text]

func _create_info_icon(label_text: String, tooltip: String) -> Label:
	var info = Label.new()
	info.text = "ⓘ %s" % label_text
	info.mouse_filter = Control.MOUSE_FILTER_STOP
	info.add_theme_font_size_override("font_size", 14)
	info.modulate = Color(0.72, 0.84, 1.0)
	info.mouse_entered.connect(func(): _show_info_tooltip(info, tooltip))
	info.mouse_exited.connect(_hide_info_tooltip)
	return info

func _show_info_tooltip(anchor: Control, text: String) -> void:
	_hide_info_tooltip()
	tooltip_popup = PanelContainer.new()
	tooltip_popup.name = "InfoTooltip"
	tooltip_popup.z_index = 100

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.10, 0.96)
	style.border_color = Color(0.55, 0.68, 0.95, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	tooltip_popup.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(360, 0)
	label.add_theme_font_size_override("font_size", 15)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color(0.9, 0.92, 0.98)
	tooltip_popup.add_child(label)

	var local_pos = anchor.global_position - global_position + Vector2(-170, 24)
	local_pos.x = clamp(local_pos.x, 20.0, 880.0)
	local_pos.y = clamp(local_pos.y, 40.0, 640.0)
	tooltip_popup.position = local_pos
	add_child(tooltip_popup)

func _hide_info_tooltip() -> void:
	if tooltip_popup != null and is_instance_valid(tooltip_popup):
		tooltip_popup.queue_free()
	tooltip_popup = null

# 创建特殊连招项（锁定状态，无法选择）
func _create_special_combo_item(combo_data: Dictionary, combo_type: String) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 48)
	
	# 锁定样式 - 深紫色/深蓝色背景
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.bg_color = Color(0.2, 0.18, 0.25)
	style.border_color = Color(0.5, 0.4, 0.6)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	
	# 内容容器
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12
	hbox.offset_right = -12
	hbox.offset_top = 6
	hbox.offset_bottom = -6
	panel.add_child(hbox)
	
	# 锁定图标
	var lock_icon = Label.new()
	lock_icon.text = "🔒"
	lock_icon.add_theme_font_size_override("font_size", 20)
	lock_icon.custom_minimum_size = Vector2(35, 0)
	hbox.add_child(lock_icon)
	
	# 获取连招信息
	var combo = null
	if combo_database != null:
		combo = combo_database.get_combo_by_id(combo_data.id)
	var seq_text = "???→???→???"
	var name_text = combo_data.id
	var desc_text = combo_data.desc
	
	if combo != null:
		seq_text = _get_sequence_icons(combo.sequence)
		name_text = combo.name
	else:
		desc_text = "[需要: %s]" % combo_data.requires
	
	# 序列图标
	var seq_label = Label.new()
	seq_label.text = seq_text
	seq_label.add_theme_font_size_override("font_size", 18)
	seq_label.modulate = Color(0.6, 0.6, 0.8)
	seq_label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(seq_label)
	
	# 连招信息
	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(180, 0)
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.modulate = Color(0.8, 0.8, 1)
	info_vbox.add_child(name_label)

	var special_detail = desc_text
	if combo != null:
		special_detail = _get_combo_detail_text(combo)
	var info_icon = _create_info_icon("详情", "%s\n触发条件：%s" % [special_detail, combo_data.requires])
	info_icon.custom_minimum_size = Vector2(70, 0)
	hbox.add_child(info_icon)
	
	# 触发条件标签
	var condition_label = Label.new()
	condition_label.text = combo_data.requires
	condition_label.add_theme_font_size_override("font_size", 13)
	condition_label.modulate = Color(1, 0.8, 0.4)
	condition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(condition_label)
	
	return panel

func _refresh_combo_list():
	if combo_container == null:
		print("[ComboSelect] ERROR: combo_container is null!")
		return
	# 清除旧列表
	for child in combo_container.get_children():
		child.queue_free()

	print("[ComboSelect] Refreshing combo list, unlocked_combos size: ", unlocked_combos.size())
	# 添加连招项
	for combo in unlocked_combos:
		var combo_item = _create_combo_item(combo)
		combo_container.add_child(combo_item)

func _create_combo_item(combo) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 56)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 背景颜色根据选中状态
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	if combo.id in selected_combos:
		# 已选中 - 绿色背景
		style.bg_color = Color(0.2, 0.4, 0.2)
		style.border_color = Color(0.4, 0.8, 0.4)
		style.set_border_width_all(2)
	else:
		# 未选中 - 灰色背景
		style.bg_color = Color(0.25, 0.25, 0.3)
		style.border_color = Color(0.4, 0.4, 0.5)
		style.set_border_width_all(1)
	
	panel.add_theme_stylebox_override("panel", style)
	
	# 内容容器
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 15
	hbox.offset_right = -15
	hbox.offset_top = 8
	hbox.offset_bottom = -8
	panel.add_child(hbox)
	
	# 序列图标
	var seq_label = Label.new()
	seq_label.text = _get_sequence_icons(combo.sequence)
	seq_label.add_theme_font_size_override("font_size", 20)
	seq_label.modulate = Color(1, 0.9, 0.5)
	seq_label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(seq_label)
	
	# 连招信息
	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = combo.name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.modulate = Color.WHITE
	info_vbox.add_child(name_label)

	var info_icon = _create_info_icon("详情", _get_combo_detail_text(combo))
	info_icon.custom_minimum_size = Vector2(70, 0)
	hbox.add_child(info_icon)
	
	# 冷却信息
	var cooldown_reduce = GameState.get_meta_upgrade_count("combo_cooldown")
	var actual_cooldown = maxi(combo.cooldown - cooldown_reduce, 1)
	var cooldown_label = Label.new()
	cooldown_label.text = "⏳ CD:%d" % actual_cooldown
	if cooldown_reduce > 0:
		cooldown_label.text += " (-%d)" % cooldown_reduce
	cooldown_label.add_theme_font_size_override("font_size", 14)
	cooldown_label.modulate = Color(0.7, 0.7, 0.9)
	hbox.add_child(cooldown_label)
	
	# 选中状态
	var status_label = Label.new()
	status_label.custom_minimum_size = Vector2(80, 0)
	if combo.id in selected_combos:
		status_label.text = "✅ 已装备"
		status_label.add_theme_font_size_override("font_size", 16)
		status_label.modulate = Color(0.5, 1, 0.5)
	else:
		status_label.text = "➕ 点击装备"
		status_label.add_theme_font_size_override("font_size", 14)
		status_label.modulate = Color(0.6, 0.6, 0.6)
	hbox.add_child(status_label)
	
	# 点击事件
	var combo_id = combo.id
	panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_combo_clicked(combo_id)
	)
	
	return panel

func _get_combo_detail_text(combo) -> String:
	var cooldown_reduce = GameState.get_meta_upgrade_count("combo_cooldown")
	var actual_cooldown = maxi(combo.cooldown - cooldown_reduce, 1)
	var parts: Array[String] = []
	if combo.get("role") != null and combo.role != "":
		parts.append("定位：%s" % combo.role)
	parts.append("效果：%s" % combo.description)
	if combo.get("usage_hint") != null and combo.usage_hint != "":
		parts.append("用法：%s" % combo.usage_hint)
	var cd_text = "实际冷却：%d回合" % actual_cooldown
	if cooldown_reduce > 0:
		cd_text += "（局外升级-%d）" % cooldown_reduce
	parts.append(cd_text)
	return "\n".join(parts)

func _get_sequence_icons(sequence: Array[int]) -> String:
	var icons = ["○", "△", "□"]
	var result = ""
	for i in range(sequence.size()):
		if i > 0:
			result += "→"
		result += icons[sequence[i]]
	return result

func _on_combo_clicked(combo_id: String):
	print("[ComboSelect] Combo clicked: ", combo_id)
	
	if combo_id in selected_combos:
		# 取消装备
		selected_combos.erase(combo_id)
		GameState.unequip_combo(combo_id)
	else:
		# 装备（检查槽位）
		if selected_combos.size() >= _get_max_slots():
			print("[ComboSelect] Slots full!")
			return
		
		selected_combos.append(combo_id)
		GameState.equip_combo(combo_id)
	
	# 刷新显示
	_update_slots_display()
	_update_equipped_display()
	_refresh_combo_list()
	_update_start_button()

func _update_slots_display():
	slots_label.text = "槽位: %d / %d" % [selected_combos.size(), _get_max_slots()]
	if meta_summary_label:
		meta_summary_label.text = _get_meta_combo_summary_text()
	
	# 根据槽位状态改变颜色
	if selected_combos.size() >= _get_max_slots():
		slots_label.modulate = Color(1, 0.7, 0.7)  # 红色 - 已满
	elif selected_combos.size() > 0:
		slots_label.modulate = Color(0.7, 1, 0.7)  # 绿色 - 部分填充
	else:
		slots_label.modulate = Color(0.8, 0.9, 1)  # 蓝色 - 空

func _update_equipped_display():
	# 清除旧显示
	for child in equipped_container.get_children():
		child.queue_free()
	
	# 显示已装备的连招槽位
	for i in range(_get_max_slots()):
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(200, 60)
		
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		
		if i < selected_combos.size():
			# 已装备槽位
			style.bg_color = Color(0.2, 0.35, 0.2)
			style.border_color = Color(0.4, 0.7, 0.4)
			style.set_border_width_all(2)
		else:
			# 空槽位
			style.bg_color = Color(0.2, 0.2, 0.25)
			style.border_color = Color(0.4, 0.4, 0.5)
			style.set_border_width_all(1)
		
		slot_panel.add_theme_stylebox_override("panel", style)
		
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.offset_top = 20
		
		if i < selected_combos.size():
			var combo = combo_database.get_combo_by_id(selected_combos[i])
			if combo:
				label.text = "%s\n%s" % [_get_sequence_icons(combo.sequence), combo.name]
				label.modulate = Color(0.9, 1, 0.9)
			else:
				label.text = "错误"
				label.modulate = Color(1, 0.5, 0.5)
		else:
			label.text = "空槽位"
			label.modulate = Color(0.5, 0.5, 0.5)
		
		slot_panel.add_child(label)
		
		# 点击槽位取消装备
		var slot_index = i
		slot_panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if slot_index < selected_combos.size():
					var combo_id = selected_combos[slot_index]
					_on_combo_clicked(combo_id)
		)
		
		equipped_container.add_child(slot_panel)

func _update_start_button():
	start_button.disabled = selected_combos.size() < 1  # 至少需要1个连招
	if start_button.disabled:
		start_button.modulate = Color(0.5, 0.5, 0.5)
	else:
		start_button.modulate = Color(0.7, 1, 0.7)

func _on_back_pressed():
	print("[ComboSelect] Back pressed")
	# 发出返回信号，让 Main 处理场景切换
	back_pressed.emit()

func _on_start_pressed():
	print("[ComboSelect] Start pressed with combos: ", selected_combos)
	
	# 确保至少选择了1个连招
	if selected_combos.size() < 1:
		print("[ComboSelect] No combos selected!")
		return
	
	# 保存已选连招到 GameState（实际上已经在 GameState 中了）
	# 发送完成信号，让 Main 处理场景切换
	combo_selection_complete.emit()
