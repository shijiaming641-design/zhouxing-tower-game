extends Control

# CharacterSelect - 角色选择界面
# 注意：不使用 class_name 以避免解析问题

signal character_selected(class_id: int)
signal back_pressed

@onready var back_button: Button = $BackButton
@onready var combo_panel: Panel = $ComboPanel
@onready var combo_title: Label = $ComboPanel/ComboTitle
@onready var combo_list: VBoxContainer = $ComboPanel/ComboList

var current_class_id: int = -1
var combo_script = null
var player_class_script = null
var tooltip_popup: Control = null

func _ready():
	print("CharacterSelect _ready")
	
	# 加载脚本
	combo_script = load("res://resources/combo_data.gd")
	player_class_script = load("res://resources/player_class_data.gd")
	
	var class_count = player_class_script.get_all_classes().size()
	for i in range(class_count):
		var btn: Button = get_node_or_null("Char%d" % i)
		if btn:
			var class_data = player_class_script.get_class_data(i)
			btn.text = "%s\n生命:%d 攻击:%d\nⓘ 详情" % [
				_get_class_icon(i) + " " + class_data.get("name", "未知"),
				int(class_data.get("hp", 0)),
				int(class_data.get("atk", 0))
			]
			btn.tooltip_text = ""
			if i == 4 and not GameState.has_meta_upgrade("new_character"):
				btn.disabled = true
				btn.text = "🔒 流浪者\n需要局外升级\nⓘ 详情"
			btn.pressed.connect(_on_class_selected.bind(i))
			btn.mouse_entered.connect(_on_class_hovered.bind(i))
			btn.mouse_entered.connect(_show_class_tooltip.bind(btn, i))
			btn.mouse_exited.connect(_hide_class_tooltip)
			print("Connected button Char", i)
		else:
			print("ERROR: Button Char", i, " not found!")
	
	# 连接返回按钮
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	else:
		print("ERROR: BackButton not found!")
	
	# 默认显示第一个角色的专属连招
	call_deferred("_show_class_combos", 0)

func _on_class_hovered(class_id: int):
	_show_class_combos(class_id)

func _on_class_selected(class_id: int):
	print("Character selected from UI: ", class_id)
	current_class_id = class_id
	character_selected.emit(class_id)

func _on_back_pressed():
	print("Back pressed")
	back_pressed.emit()

func _get_class_icon(class_id: int) -> String:
	match class_id:
		0: return "🏥"
		1: return "💻"
		2: return "💰"
		3: return "🌾"
		4: return "🧭"
		_: return "?"

func _show_class_tooltip(anchor: Control, class_id: int) -> void:
	_hide_class_tooltip()
	if player_class_script == null:
		return
	var class_data = player_class_script.get_class_data(class_id)
	var locked_text = ""
	if class_id == 4 and not GameState.has_meta_upgrade("new_character"):
		locked_text = "\n解锁条件：局外升级「新角色解锁」"
	var text = "%s\n生命：%d  攻击：%d\n专属被动：%s%s" % [
		class_data.get("name", "未知"),
		int(class_data.get("hp", 0)),
		int(class_data.get("atk", 0)),
		class_data.get("desc", ""),
		locked_text
	]

	tooltip_popup = PanelContainer.new()
	tooltip_popup.name = "ClassTooltip"
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

	var local_pos = anchor.global_position - global_position + Vector2(-70, 155)
	local_pos.x = clamp(local_pos.x, 20.0, 880.0)
	local_pos.y = clamp(local_pos.y, 40.0, 610.0)
	tooltip_popup.position = local_pos
	add_child(tooltip_popup)

func _hide_class_tooltip() -> void:
	if tooltip_popup != null and is_instance_valid(tooltip_popup):
		tooltip_popup.queue_free()
	tooltip_popup = null

func _show_class_combos(class_id: int):
	print("_show_class_combos called for class: ", class_id)
	
	if not is_instance_valid(combo_panel):
		print("ERROR: combo_panel is not valid!")
		return
	if not is_instance_valid(combo_list):
		print("ERROR: combo_list is not valid!")
		return
	if not is_instance_valid(combo_title):
		print("ERROR: combo_title is not valid!")
		return
	
	if player_class_script == null:
		print("ERROR: player_class_script is null!")
		return
	if combo_script == null:
		print("ERROR: combo_script is null!")
		return
	
	var class_data = player_class_script.get_class_data(class_id)
	var combos = player_class_script.get_class_combos(class_id)
	
	print("Class data: ", class_data)
	print("Combos count: ", combos.size() if combos else 0)
	
	# 更新标题
	combo_title.text = "【%s】专属连招（悬停详情查看用法）" % class_data["name"]
	combo_title.modulate = Color(1, 0.9, 0.6)
	
	# 清空现有列表
	for child in combo_list.get_children():
		child.queue_free()
	
	# 添加连招信息
	if combos == null or combos.is_empty():
		var label = Label.new()
		label.text = "该职业暂无专属连招"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.modulate = Color(0.6, 0.6, 0.6)
		combo_list.add_child(label)
	else:
		for combo in combos:
			if combo == null:
				continue
			print("Adding combo: ", combo.display_name)
			combo_list.add_child(_create_combo_card(combo))
	
	combo_panel.visible = true
	print("Combo panel visible set to true")

func _create_combo_card(combo) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(940, 52)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.18, 0.24, 0.95)
	style.border_color = Color(0.38, 0.46, 0.68, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 14
	hbox.offset_right = -14
	hbox.offset_top = 8
	hbox.offset_bottom = -8
	panel.add_child(hbox)

	var seq_label = Label.new()
	seq_label.text = combo_script.sequence_to_string(combo.sequence)
	seq_label.add_theme_font_size_override("font_size", 22)
	seq_label.custom_minimum_size = Vector2(150, 0)
	seq_label.modulate = Color(1, 0.9, 0.5)
	hbox.add_child(seq_label)

	var name_label = Label.new()
	name_label.text = combo.display_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.custom_minimum_size = Vector2(180, 0)
	name_label.modulate = Color(0.9, 0.9, 1)
	hbox.add_child(name_label)

	var role_text = combo.role if combo.get("role") != null and combo.role != "" else ("战斗" if combo.is_combat else "非战斗")
	var role_label = Label.new()
	role_label.text = role_text
	role_label.add_theme_font_size_override("font_size", 14)
	role_label.custom_minimum_size = Vector2(120, 0)
	role_label.modulate = Color(0.62, 0.84, 1.0)
	hbox.add_child(role_label)

	var cd_label = Label.new()
	cd_label.text = "CD:%d" % combo.cooldown
	cd_label.add_theme_font_size_override("font_size", 14)
	cd_label.custom_minimum_size = Vector2(70, 0)
	cd_label.modulate = Color(0.58, 0.62, 0.72)
	hbox.add_child(cd_label)

	var detail = "效果：%s" % combo.description
	if combo.get("usage_hint") != null and combo.usage_hint != "":
		detail += "\n用法：%s" % combo.usage_hint
	var detail_icon = Label.new()
	detail_icon.text = "ⓘ 详情"
	detail_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_icon.add_theme_font_size_override("font_size", 14)
	detail_icon.modulate = Color(0.72, 0.84, 1.0)
	detail_icon.mouse_entered.connect(_show_combo_tooltip.bind(detail_icon, detail))
	detail_icon.mouse_exited.connect(_hide_class_tooltip)
	hbox.add_child(detail_icon)

	return panel

func _show_combo_tooltip(anchor: Control, text: String) -> void:
	_hide_class_tooltip()
	tooltip_popup = PanelContainer.new()
	tooltip_popup.name = "ComboTooltip"
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
	label.custom_minimum_size = Vector2(420, 0)
	label.add_theme_font_size_override("font_size", 15)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color(0.9, 0.92, 0.98)
	tooltip_popup.add_child(label)

	var local_pos = anchor.global_position - global_position + Vector2(-260, 28)
	local_pos.x = clamp(local_pos.x, 20.0, 820.0)
	local_pos.y = clamp(local_pos.y, 40.0, 610.0)
	tooltip_popup.position = local_pos
	add_child(tooltip_popup)
