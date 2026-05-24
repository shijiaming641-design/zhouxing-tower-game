extends RefCounted

const BACKDROP := "res://demo/assets/zhouxing_ui/demo_qin_backdrop.svg"
const TOP_BAR := "res://demo/assets/zhouxing_ui/demo_top_bar.svg"
const BOTTOM_BAR := "res://demo/assets/zhouxing_ui/demo_bottom_bar.svg"
const STAMP_QIN := "res://demo/assets/zhouxing_ui/demo_stamp_qin.svg"

const GOLD := Color(0.86, 0.66, 0.36, 1.0)
const PAPER := Color(0.93, 0.84, 0.68, 1.0)
const INK := Color(0.14, 0.10, 0.07, 1.0)
const PANEL := Color(0.09, 0.075, 0.055, 0.91)
const PANEL_LIGHT := Color(0.20, 0.145, 0.085, 0.94)

static func install_showcase(root: Node) -> void:
	var control := root.get_node_or_null("UI Layer/Control") as Control
	if control == null:
		return
	_add_backdrop(control, 0.34)
	_add_stamp(control, Vector2(24, 82), Vector2(118, 118))
	_add_banner(control, "行阵演示", "秦卷·演武场 / 行为树敌兵预览", Vector2(158, 86), Vector2(390, 92))
	_skin_panel(root.get_node_or_null("UI Layer/Control/Toolbar") as PanelContainer, TOP_BAR, 0.92)
	_skin_panel(root.get_node_or_null("UI Layer/Control/BehaviorInspector") as PanelContainer, "", 1.0)
	_skin_panel(root.get_node_or_null("UI Layer/Control/PanelContainer") as PanelContainer, BOTTOM_BAR, 0.92)
	_skin_buttons(control)
	_set_button_text(root, "UI Layer/Control/Toolbar/HBoxContainer/ToggleFullscreen", "全屏")
	_set_button_text(root, "UI Layer/Control/Toolbar/HBoxContainer/SwitchToGame", "进入战斗演示")
	_set_button_text(root, "UI Layer/Control/Toolbar/HBoxContainer/BeginTutorial", "教程演示")
	_set_label_text(root, "UI Layer/Control/Toolbar/HBoxContainer/SceneTitle", "敌兵行阵")
	_set_label_text(root, "UI Layer/Control/Toolbar/HBoxContainer/NavigationHint", "切换敌兵")
	_set_label_text(root, "UI Layer/Control/PanelContainer/Control/Header/Label", "演示说明")
	_set_label_text(root, "UI Layer/Control/PanelContainer/Control/Logo/Demo project", "周行 Demo")

static func install_game(root: Node) -> void:
	var control := root.get_node_or_null("UI Layer/Control") as Control
	if control == null:
		return
	_add_backdrop(control, 0.24)
	_add_stamp(control, Vector2(24, 92), Vector2(124, 124))
	_add_banner(control, "战斗演示", "敲响战鼓，检验敌兵波次与战斗反馈", Vector2(160, 96), Vector2(430, 92))
	_add_bottom_command_bar(control)
	_skin_panel(root.get_node_or_null("UI Layer/Control/Toolbar") as PanelContainer, TOP_BAR, 0.92)
	_skin_buttons(control)
	_set_button_text(root, "UI Layer/Control/Toolbar/HBoxContainer/ToggleFullscreen", "全屏")
	_set_button_text(root, "UI Layer/Control/Toolbar/HBoxContainer/Switch to Showcase", "返回行阵演示")
	_set_label_text(root, "UI Layer/Control/Toolbar/HBoxContainer/RoundCounter", "击鼓开战")
	_set_label_text(root, "UI Layer/Control/Logo/Demo project", "秦卷演武")
	_set_label_text(root, "UI Layer/Control/Keys", "移动  WASD\n闪避  SPACE\n攻击  ENTER / F")

static func _load_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

static func _add_backdrop(control: Control, alpha: float) -> void:
	if control.get_node_or_null("ZhouxingDemoBackdrop") != null:
		return
	var tex := _load_texture(BACKDROP)
	if tex == null:
		return
	var rect := TextureRect.new()
	rect.name = "ZhouxingDemoBackdrop"
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate = Color(1, 1, 1, alpha)
	control.add_child(rect)
	control.move_child(rect, 0)

static func _add_stamp(control: Control, pos: Vector2, size: Vector2) -> void:
	if control.get_node_or_null("ZhouxingDemoStamp") != null:
		return
	var tex := _load_texture(STAMP_QIN)
	if tex == null:
		return
	var rect := TextureRect.new()
	rect.name = "ZhouxingDemoStamp"
	rect.texture = tex
	rect.position = pos
	rect.custom_minimum_size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(rect)

static func _add_banner(control: Control, title: String, subtitle: String, pos: Vector2, size: Vector2) -> void:
	if control.get_node_or_null("ZhouxingDemoBanner") != null:
		return
	var panel := PanelContainer.new()
	panel.name = "ZhouxingDemoBanner"
	panel.position = pos
	panel.custom_minimum_size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(0.88, 3, 14))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", PAPER)
	title_label.add_theme_color_override("font_outline_color", INK)
	title_label.add_theme_constant_override("outline_size", 2)
	vbox.add_child(title_label)
	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.add_theme_color_override("font_color", GOLD)
	vbox.add_child(subtitle_label)
	control.add_child(panel)

static func _add_bottom_command_bar(control: Control) -> void:
	if control.get_node_or_null("ZhouxingDemoCommandBar") != null:
		return
	var tex := _load_texture(BOTTOM_BAR)
	var rect := TextureRect.new()
	rect.name = "ZhouxingDemoCommandBar"
	if tex != null:
		rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rect.offset_top = -150
	rect.offset_bottom = 0
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(rect)
	control.move_child(rect, 1)
	var hint := Label.new()
	hint.name = "ZhouxingDemoCommandHint"
	hint.text = "演武指令：WASD 行军   SPACE 闪身   F / ENTER 出击   击鼓召敌"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -92
	hint.offset_bottom = -42
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", PAPER)
	hint.add_theme_color_override("font_outline_color", INK)
	hint.add_theme_constant_override("outline_size", 3)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(hint)

static func _skin_panel(panel: PanelContainer, texture_path: String, alpha: float) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", _panel_style(alpha, 2, 10))
	if texture_path == "":
		return
	if panel.get_node_or_null("ZhouxingPanelTexture") != null:
		return
	var tex := _load_texture(texture_path)
	if tex == null:
		return
	var rect := TextureRect.new()
	rect.name = "ZhouxingPanelTexture"
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate = Color(1, 1, 1, 0.62)
	panel.add_child(rect)
	panel.move_child(rect, 0)

static func _skin_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			_apply_button_style(child)
		_skin_buttons(child)

static func _apply_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _button_style(PANEL_LIGHT))
	button.add_theme_stylebox_override("hover", _button_style(PANEL_LIGHT.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", _button_style(PANEL_LIGHT.darkened(0.12)))
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_outline_color", INK)
	button.add_theme_constant_override("outline_size", 2)

static func _panel_style(alpha: float, border: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.bg_color.a = alpha
	style.border_color = GOLD
	style.set_border_width_all(border)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

static func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func _set_button_text(root: Node, node_path: String, text: String) -> void:
	var button := root.get_node_or_null(node_path) as Button
	if button != null:
		button.text = text

static func _set_label_text(root: Node, node_path: String, text: String) -> void:
	var label := root.get_node_or_null(node_path) as Label
	if label != null:
		label.text = text
