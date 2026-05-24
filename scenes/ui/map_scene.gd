class_name MapScene
extends Control

## 地图场景 - 爬塔地图导航（从下往上爬塔布局）

signal node_selected(node_index: int)
signal back_to_menu_pressed

const NODE_WIDTH: int = 104
const NODE_HEIGHT: int = 40
const NODE_SPACING_X: int = 108
const NODE_SPACING_Y: int = 94
const START_Y: int = 168  # 从底部开始显示
const MARGIN_X: int = 100  # 左右边距
const CHECKPOINT_COLOR := Color(1.0, 0.78, 0.30, 0.98)
@onready var title_label: Label = $TitleLabel
@onready var status_chip: Panel = $StatusChip
@onready var status_label: Label = $StatusLabel
@onready var materials_chip: Panel = get_node_or_null("MaterialsChip") as Panel
@onready var materials_label: Label = get_node_or_null("MaterialsLabel") as Label
@onready var map_container: Control = $ScrollContainer/MapContainer
@onready var back_button: Button = $BackButton
@onready var bottom_bar: Panel = $BottomBar
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var top_tool_dock: Panel = $TopToolDock
@onready var settings_button: Button = $SettingsButton
@onready var rules_button: Button = $RulesButton
@onready var sound_button: Button = $SoundButton

var player_class_script = null
var player_info_card: Panel = null
var player_info_button: Button = null
var player_info_title_label: Label = null
var player_info_stats_label: Label = null
var player_info_hint_label: Label = null
var _is_committing_node_choice: bool = false

func _ready() -> void:
	DebugLog.log("MapScene _ready called")
	
	# 加载 PlayerClassData 脚本
	player_class_script = load("res://resources/player_class_data.gd")
	if player_class_script == null:
		DebugLog.error("ERROR: Failed to load player_class_data.gd")
	
	# 兼容旧材料信号；材料已取消显示，统一刷新金币运营摘要。
	EventBus.materials_changed.connect(_on_materials_changed)
	
	_ensure_player_info_button()
	_update_display()
	_create_tree_map()  # 爬塔布局
	back_button.pressed.connect(_on_back_pressed)
	player_info_button.pressed.connect(_on_player_info_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	sound_button.pressed.connect(_on_sound_pressed)

func _on_back_pressed() -> void:
	back_to_menu_pressed.emit()

func _on_materials_changed(new_amount: int) -> void:
	"""旧材料变化信号兼容：刷新运营摘要"""
	_update_resource_label()

func _update_resource_label() -> void:
	if status_label:
		status_label.text = _get_operation_summary_text()
	_update_player_info_card()

func _load_era_seal_texture() -> Texture2D:
	var texture_path := ArtRegistry.get_era_ui_path("map_seal")
	if texture_path == "":
		return null
	return _load_texture_if_exists(texture_path)

func _load_texture_if_exists(texture_path: String) -> Texture2D:
	if texture_path == "":
		return null
	if ResourceLoader.exists(texture_path):
		return load(texture_path) as Texture2D
	var absolute_path := ProjectSettings.globalize_path(texture_path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image = Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _get_era_asset_key() -> String:
	return ArtRegistry.era_key()

func _load_map_background_texture() -> Texture2D:
	return _load_texture_if_exists(ArtRegistry.get_era_ui_path("map_bg"))

func _load_node_icon_texture(node_type: int) -> Texture2D:
	var icon_path := ArtRegistry.get_map_node_icon_path(node_type)
	return _load_texture_if_exists(icon_path)

func _update_display() -> void:
	var theme = GameState.get_era_theme()
	_configure_map_layout()
	var bg = get_node_or_null("Background")
	if bg:
		bg.color = theme.get("bg", Color(0.1, 0.1, 0.15, 1.0))
		var map_bg_texture = bg.get_node_or_null("EraMapBackground") as TextureRect
		if map_bg_texture == null:
			map_bg_texture = TextureRect.new()
			map_bg_texture.name = "EraMapBackground"
			map_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			map_bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
			map_bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			map_bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bg.add_child(map_bg_texture)
			bg.move_child(map_bg_texture, 0)
		map_bg_texture.texture = _load_map_background_texture()
		map_bg_texture.modulate = Color(1, 1, 1, 0.94)
		var title_back = get_node_or_null("TitleBack") as ColorRect
		if title_back == null:
			title_back = ColorRect.new()
			title_back.name = "TitleBack"
			title_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(title_back)
			move_child(title_back, 1)
		title_back.color = theme.get("panel", Color(0.18, 0.16, 0.14, 0.92))
		title_back.color.a = 0.24
		title_back.position = Vector2(338, 70)
		title_back.custom_minimum_size = Vector2(604, 42)
	_ensure_era_header_decor(theme)
	_apply_top_dock_theme(theme)
	_apply_bottom_bar_theme(theme)
	if title_label:
		title_label.modulate = theme.get("title", Color(1, 0.9, 0.6, 1))
		title_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.1, 0.1, 0.15, 1.0)).darkened(0.2))
		title_label.add_theme_constant_override("outline_size", 1)
	_apply_info_chip_theme(theme)
	if status_label:
		status_label.modulate = theme.get("accent", Color(0.85, 0.85, 0.75, 1))
	if materials_label:
		materials_label.modulate = theme.get("accent", Color(0.9, 0.8, 0.4, 1))
	var legend_label = get_node_or_null("LegendPanel/LegendLabel")
	if legend_label:
		legend_label.modulate = theme.get("title", Color(0.9, 0.9, 0.7, 1))
		legend_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.1, 0.1, 0.15, 1.0)).darkened(0.2))
		legend_label.add_theme_constant_override("outline_size", 1)
	var hint_label = get_node_or_null("HintLabel")
	if hint_label:
		hint_label.modulate = theme.get("accent", Color(0.7, 0.7, 0.7, 1))
		hint_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.1, 0.1, 0.15, 1.0)).darkened(0.2))
		hint_label.add_theme_constant_override("outline_size", 1)
	var legend_bg = get_node_or_null("LegendPanel/LegendBg")
	if legend_bg:
		legend_bg.color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.8))

	# 显示当前层
	var floor_num: int = GameState.current_floor + 1
	title_label.text = _get_map_title(floor_num)
	
	_update_resource_label()
	if legend_label:
		legend_label.text = _get_legend_text()
	if hint_label:
		hint_label.text = _get_hint_text()
		if sound_button:
			sound_button.text = "音效：关" if GameState.is_audio_muted() else "音效：开"
		_apply_system_button_icons()

func _configure_map_layout() -> void:
	if scroll_container:
		scroll_container.position = Vector2(0, 104)
		scroll_container.size = Vector2(1280, 516)
	if map_container:
		map_container.custom_minimum_size.x = 1280


func _apply_system_button_icons() -> void:
	if player_info_button != null:
		player_info_button.tooltip_text = "查看角色详情"
	var icon_specs := [
		{"button": settings_button, "key": "settings", "tip": "设置"},
		{"button": rules_button, "key": "rules", "tip": "规则"},
		{"button": sound_button, "key": "sound", "tip": "音效"},
		{"button": back_button, "key": "back", "tip": "返回"},
	]
	for spec in icon_specs:
		var btn := spec.get("button") as Button
		if btn == null:
			continue
		ArtRegistry.apply_button_icon(btn, str(spec.get("key", "")), true, str(spec.get("tip", "")))

func _ensure_player_info_button() -> void:
	player_info_card = get_node_or_null("PlayerInfoCard") as Panel
	if player_info_card == null:
		player_info_card = Panel.new()
		player_info_card.name = "PlayerInfoCard"
		player_info_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(player_info_card)
	var accent := player_info_card.get_node_or_null("Accent") as ColorRect
	if accent == null:
		accent = ColorRect.new()
		accent.name = "Accent"
		accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		player_info_card.add_child(accent)
	player_info_title_label = player_info_card.get_node_or_null("PlayerInfoTitle") as Label
	if player_info_title_label == null:
		player_info_title_label = Label.new()
		player_info_title_label.name = "PlayerInfoTitle"
		player_info_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		player_info_card.add_child(player_info_title_label)
	player_info_stats_label = player_info_card.get_node_or_null("PlayerInfoStats") as Label
	if player_info_stats_label == null:
		player_info_stats_label = Label.new()
		player_info_stats_label.name = "PlayerInfoStats"
		player_info_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		player_info_card.add_child(player_info_stats_label)
	player_info_hint_label = player_info_card.get_node_or_null("PlayerInfoHint") as Label
	if player_info_hint_label == null:
		player_info_hint_label = Label.new()
		player_info_hint_label.name = "PlayerInfoHint"
		player_info_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		player_info_card.add_child(player_info_hint_label)
	player_info_button = get_node_or_null("PlayerInfoButton") as Button
	if player_info_button != null:
		return
	player_info_button = Button.new()
	player_info_button.name = "PlayerInfoButton"
	player_info_button.text = ""
	player_info_button.flat = true
	player_info_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(player_info_button)

func _ensure_era_header_decor(theme: Dictionary) -> void:
	var band = get_node_or_null("EraBand") as ColorRect
	if band:
		band.queue_free()

	var seal = get_node_or_null("EraSeal") as Panel
	if seal == null:
		seal = Panel.new()
		seal.name = "EraSeal"
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal.position = Vector2(1092, 116)
		seal.size = Vector2(108, 34)
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
		seal_label.add_theme_font_size_override("font_size", 16)
		seal.add_child(seal_label)
		add_child(seal)
		move_child(seal, 2)
	var seal_style = seal.get_theme_stylebox("panel") as StyleBoxFlat
	if seal_style != null:
		seal_style.bg_color = Color(0, 0, 0, 0)
		seal_style.border_color = Color(0, 0, 0, 0)
		seal_style.set_border_width_all(0)
	var seal_texture = seal.get_node_or_null("Texture") as TextureRect
	if seal_texture == null:
		seal_texture = TextureRect.new()
		seal_texture.name = "Texture"
		seal_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
		seal_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		seal_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		seal_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal.add_child(seal_texture)
		seal.move_child(seal_texture, 0)
	var seal_tex = _load_era_seal_texture()
	seal_texture.texture = seal_tex
	var seal_label_ref = seal.get_node_or_null("Label") as Label
	if seal_label_ref:
		seal_label_ref.visible = seal_tex == null
		if seal_tex == null:
			match GameState.selected_era_id:
				"song":
					seal_label_ref.text = "〔宋卷〕"
				"china":
					seal_label_ref.text = "〔终局〕"
				_:
					seal_label_ref.text = "〔秦卷〕"
			seal_label_ref.modulate = theme.get("title", Color(0.95, 0.85, 0.66, 1.0))

func _apply_top_dock_theme(theme: Dictionary) -> void:
	_apply_player_info_card_theme(theme)
	if top_tool_dock:
		top_tool_dock.position = Vector2(884, 30)
		top_tool_dock.size = Vector2(376, 44)
		var dock_style = StyleBoxFlat.new()
		dock_style.bg_color = theme.get("panel", Color(0.12, 0.10, 0.10, 0.92))
		dock_style.border_color = Color(1, 1, 1, 0.08)
		dock_style.set_border_width_all(1)
		dock_style.corner_radius_top_left = 12
		dock_style.corner_radius_top_right = 12
		dock_style.corner_radius_bottom_left = 12
		dock_style.corner_radius_bottom_right = 12
		top_tool_dock.add_theme_stylebox_override("panel", dock_style)
	var button_specs := [
		{"button": settings_button, "x": 896, "w": 108},
		{"button": rules_button, "x": 1014, "w": 108},
		{"button": sound_button, "x": 1132, "w": 116},
	]
	for spec in button_specs:
		var btn := spec.get("button") as Button
		if btn == null:
			continue
		btn.position = Vector2(int(spec.get("x", 0)), 36)
		btn.size = Vector2(int(spec.get("w", 110)), 32)
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.10, 0.10, 0.12, 0.94)
		btn_style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
		btn_style.set_border_width_all(1)
		btn_style.corner_radius_top_left = 10
		btn_style.corner_radius_top_right = 10
		btn_style.corner_radius_bottom_left = 10
		btn_style.corner_radius_bottom_right = 10
		var btn_hover = btn_style.duplicate()
		btn_hover.bg_color = Color(0.16, 0.16, 0.20, 0.98)
		var btn_pressed = btn_style.duplicate()
		btn_pressed.bg_color = Color(0.20, 0.18, 0.14, 0.98)
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_pressed)
		btn.add_theme_color_override("font_color", theme.get("title", Color(1, 0.92, 0.72, 1.0)))

func _apply_player_info_card_theme(theme: Dictionary) -> void:
	if player_info_card == null or player_info_button == null:
		return
	player_info_card.position = Vector2(18, 14)
	player_info_card.size = Vector2(340, 88)
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.045, 0.095, 0.125, 0.98)
	card_style.border_color = Color(0.62, 0.88, 1.0, 1.0)
	card_style.set_border_width_all(2)
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_left = 16
	card_style.corner_radius_bottom_right = 16
	player_info_card.add_theme_stylebox_override("panel", card_style)
	var accent := player_info_card.get_node_or_null("Accent") as ColorRect
	if accent != null:
		accent.position = Vector2(122, 12)
		accent.size = Vector2(96, 3)
		accent.custom_minimum_size = accent.size
		accent.color = Color(0.58, 0.90, 1.0, 0.86)
	if player_info_title_label != null:
		player_info_title_label.text = _get_map_player_title_text()
		player_info_title_label.position = Vector2(20, 16)
		player_info_title_label.size = Vector2(300, 24)
		player_info_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_info_title_label.add_theme_font_size_override("font_size", 18)
		player_info_title_label.modulate = Color(0.90, 0.98, 1.0, 1.0)
		player_info_title_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.1, 0.1, 0.15, 1.0)).darkened(0.25))
		player_info_title_label.add_theme_constant_override("outline_size", 2)
	if player_info_stats_label != null:
		player_info_stats_label.text = _get_map_player_stats_text()
		player_info_stats_label.position = Vector2(20, 42)
		player_info_stats_label.size = Vector2(300, 22)
		player_info_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_info_stats_label.add_theme_font_size_override("font_size", 17)
		player_info_stats_label.modulate = Color(1.0, 0.95, 0.78, 1.0)
		player_info_stats_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.1, 0.1, 0.15, 1.0)).darkened(0.25))
		player_info_stats_label.add_theme_constant_override("outline_size", 2)
	if player_info_hint_label != null:
		player_info_hint_label.text = "点击查看角色详情"
		player_info_hint_label.position = Vector2(20, 66)
		player_info_hint_label.size = Vector2(300, 14)
		player_info_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_info_hint_label.add_theme_font_size_override("font_size", 11)
		player_info_hint_label.modulate = Color(0.66, 0.84, 0.90, 0.90)
	player_info_button.position = player_info_card.position
	player_info_button.size = player_info_card.size
	player_info_button.text = ""
	player_info_button.tooltip_text = "查看角色详情"
	var click_style = StyleBoxFlat.new()
	click_style.bg_color = Color(0, 0, 0, 0)
	click_style.border_color = Color(0, 0, 0, 0)
	var click_hover = click_style.duplicate()
	click_hover.bg_color = Color(0.72, 0.94, 1.0, 0.08)
	var click_pressed = click_style.duplicate()
	click_pressed.bg_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	click_pressed.bg_color.a = 0.12
	player_info_button.add_theme_stylebox_override("normal", click_style)
	player_info_button.add_theme_stylebox_override("hover", click_hover)
	player_info_button.add_theme_stylebox_override("pressed", click_pressed)

func _apply_info_chip_theme(theme: Dictionary) -> void:
	for chip in [status_chip]:
		if chip == null:
			continue
		chip.position = Vector2(372, 30)
		chip.size = Vector2(500, 44)
		var chip_style = StyleBoxFlat.new()
		chip_style.bg_color = Color(0.10, 0.10, 0.12, 0.92)
		chip_style.border_color = Color(1, 1, 1, 0.06)
		chip_style.set_border_width_all(1)
		chip_style.corner_radius_top_left = 10
		chip_style.corner_radius_top_right = 10
		chip_style.corner_radius_bottom_left = 10
		chip_style.corner_radius_bottom_right = 10
		chip.add_theme_stylebox_override("panel", chip_style)
	if status_label:
		status_label.position = Vector2(386, 39)
		status_label.size = Vector2(472, 26)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status_label.clip_text = true
		status_label.add_theme_font_size_override("font_size", 13)
		status_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.1, 0.1, 0.15, 1.0)).darkened(0.2))
		status_label.add_theme_constant_override("outline_size", 1)
	if materials_chip:
		materials_chip.visible = false
	if materials_label:
		materials_label.visible = false
	var legend_panel = get_node_or_null("LegendPanel") as PanelContainer
	if legend_panel:
		var legend_style = StyleBoxFlat.new()
		legend_style.bg_color = Color(0.10, 0.10, 0.12, 0.92)
		legend_style.border_color = Color(1, 1, 1, 0.06)
		legend_style.set_border_width_all(1)
		legend_style.corner_radius_top_left = 10
		legend_style.corner_radius_top_right = 10
		legend_style.corner_radius_bottom_left = 10
		legend_style.corner_radius_bottom_right = 10
		legend_panel.add_theme_stylebox_override("panel", legend_style)

func _apply_bottom_bar_theme(theme: Dictionary) -> void:
	if bottom_bar:
		var bar_style = StyleBoxFlat.new()
		bar_style.bg_color = theme.get("panel", Color(0.12, 0.10, 0.10, 0.92))
		bar_style.border_color = Color(1, 1, 1, 0.06)
		bar_style.set_border_width_all(1)
		bar_style.corner_radius_top_left = 14
		bar_style.corner_radius_top_right = 14
		bar_style.corner_radius_bottom_left = 14
		bar_style.corner_radius_bottom_right = 14
		bottom_bar.add_theme_stylebox_override("panel", bar_style)
		move_child(bottom_bar, get_child_count() - 1)
	if back_button:
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.10, 0.10, 0.12, 0.96)
		btn_style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
		btn_style.set_border_width_all(1)
		btn_style.corner_radius_top_left = 12
		btn_style.corner_radius_top_right = 12
		btn_style.corner_radius_bottom_left = 12
		btn_style.corner_radius_bottom_right = 12
		var btn_hover = btn_style.duplicate()
		btn_hover.bg_color = Color(0.16, 0.16, 0.20, 0.98)
		var btn_pressed = btn_style.duplicate()
		btn_pressed.bg_color = Color(0.20, 0.18, 0.14, 0.98)
		back_button.add_theme_stylebox_override("normal", btn_style)
		back_button.add_theme_stylebox_override("hover", btn_hover)
		back_button.add_theme_stylebox_override("pressed", btn_pressed)
		back_button.add_theme_color_override("font_color", theme.get("title", Color(1, 0.92, 0.72, 1.0)))
		move_child(back_button, get_child_count() - 1)
	var hint_label = get_node_or_null("HintLabel") as Label
	if hint_label:
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.modulate = theme.get("title", Color(0.92, 0.86, 0.72, 1.0))
		move_child(hint_label, get_child_count() - 1)

func _show_top_overlay(title: String, body: String) -> void:
	var overlay = get_node_or_null("TopOverlay") as Control
	if overlay:
		overlay.queue_free()
		await get_tree().process_frame

	overlay = Control.new()
	overlay.name = "TopOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var panel = Panel.new()
	panel.position = Vector2(360, 180)
	panel.size = Vector2(560, 260)
	var style = StyleBoxFlat.new()
	style.bg_color = GameState.get_era_theme().get("panel", Color(0.15, 0.12, 0.10, 0.95))
	style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var title_label_popup = Label.new()
	title_label_popup.position = Vector2(24, 20)
	title_label_popup.size = Vector2(512, 34)
	title_label_popup.text = title
	title_label_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label_popup.add_theme_font_size_override("font_size", 24)
	title_label_popup.modulate = GameState.get_era_theme().get("title", Color(1, 0.9, 0.6, 1))
	title_label_popup.add_theme_color_override("font_outline_color", GameState.get_era_theme().get("bg", Color(0.1, 0.1, 0.15, 1.0)).darkened(0.2))
	title_label_popup.add_theme_constant_override("outline_size", 1)
	panel.add_child(title_label_popup)

	var body_label = Label.new()
	body_label.position = Vector2(24, 70)
	body_label.size = Vector2(512, 120)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.text = body
	body_label.add_theme_font_size_override("font_size", 18)
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_label.add_theme_color_override("font_outline_color", GameState.get_era_theme().get("bg", Color(0.1, 0.1, 0.15, 1.0)).darkened(0.2))
	body_label.add_theme_constant_override("outline_size", 1)
	panel.add_child(body_label)

	var close_btn = Button.new()
	close_btn.position = Vector2(200, 206)
	close_btn.size = Vector2(160, 34)
	close_btn.text = "关闭"
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = GameState.get_era_theme().get("panel", Color(0.15, 0.12, 0.10, 0.95)).darkened(0.08)
	close_style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	close_style.set_border_width_all(2)
	close_style.corner_radius_top_left = 10
	close_style.corner_radius_top_right = 10
	close_style.corner_radius_bottom_left = 10
	close_style.corner_radius_bottom_right = 10
	var close_hover = close_style.duplicate()
	close_hover.bg_color = GameState.get_era_theme().get("panel", Color(0.15, 0.12, 0.10, 0.95)).lightened(0.08)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.add_theme_stylebox_override("pressed", close_style)
	close_btn.add_theme_stylebox_override("focus", close_hover)
	close_btn.add_theme_color_override("font_color", GameState.get_era_theme().get("title", Color(1, 0.9, 0.6, 1)))
	close_btn.pressed.connect(func(): overlay.queue_free())
	panel.add_child(close_btn)

func _on_settings_pressed() -> void:
	_show_top_overlay("地图设置", "%s\n完整设置请回主菜单军机设置；这里显示的是当前全局设置状态。" % GameState.get_settings_status_text())

func _on_rules_pressed() -> void:
	_show_top_overlay("地图规则", "只能选择当前层可访问节点。\n地图节点分为征战、商队、营寨、异闻、灾主。\n不同时代卷会影响节点倾向与事件权重。")

func _on_sound_pressed() -> void:
	var muted := GameState.toggle_audio_muted()
	if sound_button:
		sound_button.text = "音效：关" if muted else "音效：开"
		ArtRegistry.apply_button_icon(sound_button, "sound", true, "音效：%s" % ("关" if muted else "开"))
	_show_top_overlay("系统音效", "地图页音效已%s。" % ("关闭" if muted else "开启"))

func _on_player_info_pressed() -> void:
	_show_player_info_overlay()

func _show_player_info_overlay() -> void:
	var overlay = get_node_or_null("PlayerInfoOverlay") as Control
	if overlay:
		overlay.queue_free()
		await get_tree().process_frame

	overlay = Control.new()
	overlay.name = "PlayerInfoOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.50)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var panel = Panel.new()
	panel.position = Vector2(230, 92)
	panel.size = Vector2(820, 548)
	var style = StyleBoxFlat.new()
	style.bg_color = GameState.get_era_theme().get("panel", Color(0.15, 0.12, 0.10, 0.96))
	style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var title = Label.new()
	title.text = "玩家信息"
	title.position = Vector2(30, 20)
	title.size = Vector2(760, 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.modulate = GameState.get_era_theme().get("title", Color(1, 0.9, 0.6, 1))
	title.add_theme_color_override("font_outline_color", GameState.get_era_theme().get("bg", Color(0.1, 0.1, 0.15, 1.0)).darkened(0.2))
	title.add_theme_constant_override("outline_size", 2)
	panel.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(36, 72)
	scroll.size = Vector2(748, 398)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(748, 0)
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	for section in _get_player_info_sections():
		content.add_child(_create_player_info_section(str(section.get("title", "")), str(section.get("body", "")), section.get("accent", Color(0.9, 0.78, 0.48, 1.0))))

	var close_btn = Button.new()
	close_btn.position = Vector2(330, 490)
	close_btn.size = Vector2(160, 38)
	close_btn.text = "关闭"
	close_btn.add_theme_font_size_override("font_size", 18)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = GameState.get_era_theme().get("panel", Color(0.15, 0.12, 0.10, 0.95)).darkened(0.08)
	close_style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	close_style.set_border_width_all(2)
	close_style.corner_radius_top_left = 10
	close_style.corner_radius_top_right = 10
	close_style.corner_radius_bottom_left = 10
	close_style.corner_radius_bottom_right = 10
	var close_hover = close_style.duplicate()
	close_hover.bg_color = GameState.get_era_theme().get("panel", Color(0.15, 0.12, 0.10, 0.95)).lightened(0.08)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.add_theme_stylebox_override("pressed", close_style)
	close_btn.add_theme_color_override("font_color", GameState.get_era_theme().get("title", Color(1, 0.9, 0.6, 1)))
	close_btn.pressed.connect(func(): overlay.queue_free())
	panel.add_child(close_btn)

func _create_player_info_section(title_text: String, body_text: String, accent: Color) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(748, 86)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.075, 0.065, 0.74)
	style.border_color = accent
	style.set_border_width_all(1)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)

	var title = Label.new()
	title.text = title_text
	title.custom_minimum_size = Vector2(708, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = accent.lightened(0.10)
	box.add_child(title)

	var body = Label.new()
	body.text = body_text
	body.custom_minimum_size = Vector2(708, 0)
	body.add_theme_font_size_override("font_size", 15)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.modulate = Color(0.88, 0.86, 0.78, 1.0)
	box.add_child(body)
	return card

func _get_player_info_sections() -> Array[Dictionary]:
	var player_class_name := "未知"
	if player_class_script != null:
		player_class_name = player_class_script.get_class_display_name(GameState.player_class)
	var heirloom_data := GameState.get_heirloom_data(GameState.selected_heirloom_id)
	var heirloom_text := "未携带"
	if not heirloom_data.is_empty():
		heirloom_text = "%s｜%s" % [str(heirloom_data.get("name", "传家宝")), GameState.get_heirloom_status_text()]
	return [
		{
			"title": "角色状态",
			"body": "%s｜%s\n命数 %d/%d｜攻击 %d｜护甲 %d｜机括 %d/%d" % [
				player_class_name,
				GameState.get_level_progress_text(),
				GameState.player_hp,
				GameState.player_max_hp,
				GameState.get_total_attack(),
				GameState.player_shield,
				GameState.cheat_points,
				GameState.get_max_cheat_points()
			],
			"accent": Color(0.70, 0.92, 1.0, 1.0)
		},
		{
			"title": "资源与路线",
			"body": "金币 %d｜第 %d/%d 层｜%s\n路线：%s｜改道代价：%s" % [
				GameState.player_gold,
				GameState.current_floor + 1,
				GameState.max_floors,
				GameState.get_major_layer_status_text(GameState.current_floor),
				GameState.selected_route_name if GameState.selected_route_name != "" else "未锁定",
				GameState.get_route_switch_cost_text()
			],
			"accent": Color(1.0, 0.80, 0.42, 1.0)
		},
		{
			"title": "传家宝",
			"body": heirloom_text,
			"accent": Color(1.0, 0.70, 0.46, 1.0)
		},
		{
			"title": "已携带布局",
			"body": _get_map_combo_summary_text(),
			"accent": Color(0.95, 0.58, 0.34, 1.0)
		},
		{
			"title": "装备栏",
			"body": _get_map_item_summary_text(GameState.equipment_slot, "装备栏为空"),
			"accent": Color(0.54, 0.78, 1.0, 1.0)
		},
		{
			"title": "背包",
			"body": _get_map_item_summary_text(GameState.backpack, "背包为空"),
			"accent": Color(0.76, 0.72, 0.58, 1.0)
		}
	]

func _get_map_player_summary_text() -> String:
	return "%s\n%s" % [_get_map_player_title_text(), _get_map_player_stats_text()]

func _get_map_player_title_text() -> String:
	var player_class_name := "未知"
	if player_class_script != null:
		player_class_name = player_class_script.get_class_display_name(GameState.player_class)
	return "角色信息｜%s  %s" % [
		player_class_name,
		GameState.get_level_progress_text()
	]

func _get_map_player_stats_text() -> String:
	return "命 %d/%d   攻 %d   甲 %d   机 %d/%d" % [
		GameState.player_hp,
		GameState.player_max_hp,
		GameState.get_total_attack(),
		GameState.player_shield,
		GameState.cheat_points,
		GameState.get_max_cheat_points()
	]

func _update_player_info_card() -> void:
	if player_info_title_label != null:
		player_info_title_label.text = _get_map_player_title_text()
	if player_info_stats_label != null:
		player_info_stats_label.text = _get_map_player_stats_text()

func _get_operation_summary_text() -> String:
	return "金币 %d｜第 %d/%d 层｜%s｜%s" % [
		GameState.player_gold,
		GameState.current_floor + 1,
		GameState.max_floors,
		GameState.selected_route_name if GameState.selected_route_name != "" else "未定路线",
		_get_next_operation_hint()
	]

func _get_next_operation_hint() -> String:
	var best_target := ""
	var best_cost := 999

	for item in GameState.equipment_slot:
		if not (item is Dictionary):
			continue
		var item_id := str((item as Dictionary).get("id", ""))
		if item_id == "":
			continue
		var item_upgrades: Dictionary = GameState.equipment_upgrades.get(item_id, {})
		var item_level := int(item_upgrades.get("level", 0))
		if item_level >= 10:
			continue
		var item_cost := GameState.get_equipment_upgrade_gold_cost("level", item_level)
		if item_cost < best_cost:
			best_cost = item_cost
			best_target = "%s锻%d" % [GameState.get_item_display_name(item as Dictionary), item_level + 1]

	for combo_id_raw in GameState.get_equipped_combos():
		var combo_id := str(combo_id_raw)
		var combo_level := GameState.get_combo_upgrade_level(combo_id)
		if combo_level >= 5:
			continue
		var combo_cost := GameState.get_combo_upgrade_gold_cost(combo_level)
		if combo_cost < best_cost:
			best_cost = combo_cost
			best_target = "布局升%d" % (combo_level + 1)

	if best_target == "":
		return "强化已稳，找高收益节点"
	if GameState.player_gold >= best_cost:
		return "可强化：%s(%d金)" % [best_target, best_cost]
	return "差%d金：%s" % [best_cost - GameState.player_gold, best_target]

func _get_map_combo_summary_text() -> String:
	var combo_ids := GameState.get_equipped_combos()
	if combo_ids.is_empty():
		return "未携带布局"
	var combo_db = load("res://resources/combo_database.gd").new()
	combo_db._init_database()
	var rows: Array[String] = []
	for combo_id in combo_ids:
		var combo = combo_db.get_combo_by_id(str(combo_id))
		if combo != null:
			var status := GameState.get_combo_upgrade_status_text(str(combo_id)).strip_edges()
			rows.append("%s %s%s" % [combo_db.sequence_to_display(combo.sequence), ComboDatabase.get_era_combo_name(combo.name), status])
			continue
		var combat_combo = combo_db.get_combat_combo_by_id(str(combo_id))
		if combat_combo != null:
			rows.append("%s %s" % [combo_db.combat_combo_sequence_to_display(combat_combo.sequence), ComboDatabase.get_era_combo_name(combat_combo.name)])
	if combo_db != null:
		combo_db.all_combos.clear()
		combo_db.combat_combos.clear()
		combo_db.free()
	return "\n".join(rows) if not rows.is_empty() else "未携带布局"

func _get_map_item_summary_text(items: Array, empty_text: String) -> String:
	if items.is_empty():
		return empty_text
	var rows: Array[String] = []
	for item in items:
		if not (item is Dictionary):
			continue
		var item_data := item as Dictionary
		var item_id := str(item_data.get("id", ""))
		var upgrade := _get_map_item_upgrade_text(item_id)
		rows.append("%s%s｜%s" % [
			GameState.get_item_display_name(item_data),
			" " + upgrade if upgrade != "" else "",
			GameState.get_item_display_description(item_data)
		])
	return "\n".join(rows) if not rows.is_empty() else empty_text

func _get_map_item_upgrade_text(item_id: String) -> String:
	var upgrades: Dictionary = GameState.equipment_upgrades.get(item_id, {})
	if upgrades.is_empty():
		return ""
	var parts: Array[String] = []
	var level := int(upgrades.get("level", 0))
	if level > 0:
		parts.append("Lv.%d" % level)
	var quality := int(upgrades.get("quality", 0))
	if quality > 0:
		var quality_names := ["白", "蓝", "红"]
		parts.append(quality_names[clamp(quality, 0, quality_names.size() - 1)])
	if bool(upgrades.get("special_unlocked", false)):
		parts.append("特")
	return " ".join(parts)

func _get_map_title(floor_num: int) -> String:
	var layer_text := GameState.get_major_layer_status_text(GameState.current_floor)
	match GameState.selected_era_id:
		"song":
			return "〔宋卷〕🏮 宋卷行旅 · %s · 第 %d / %d 层" % [layer_text, floor_num, GameState.max_floors]
		"china":
			return "〔终局〕🏮 华夏终局 · %s · 第 %d / %d 层" % [layer_text, floor_num, GameState.max_floors]
		_:
			return "〔秦卷〕🏮 秦卷东出 · %s · 第 %d / %d 层" % [layer_text, floor_num, GameState.max_floors]

func _get_difficulty_hint() -> String:
	"""根据当前层数返回难度提示"""
	match GameState.get_major_layer_index():
		0: return "🌱 第一大层：立势"
		1: return "🔥 第二大层：加压"
		_: return "💀 第三大层：终局"

func _get_legend_text() -> String:
	match GameState.selected_era_id:
		"song":
			return "〔宋卷〕 绿线为主路，橙线为改道。只有主动改道收费。"
		"china":
			return "〔终局〕 绿线为主路，橙线为改道。只有主动改道收费。"
		_:
			return "〔秦卷〕 绿线为主路，橙线为改道。只有主动改道收费。"

func _get_hint_text() -> String:
	match GameState.selected_era_id:
		"song":
			return _get_route_lock_hint("选择五代十国时期的不同事件线。")
		"china":
			return _get_route_lock_hint("路线会随阶段推进：前期内战、抗战、再到内战终局。")
		_:
			return _get_route_lock_hint("秦卷分远交与近攻两线。")

func _get_route_lock_hint(prefix: String) -> String:
	if GameState.selected_route_name == "":
		return "%s 开局第一步会锁定本局主路线。" % prefix
	return "%s 当前路线：%s。绿为主路，橙为改道；主动改道：%s。" % [prefix, GameState.selected_route_name, GameState.get_route_switch_cost_text()]

func _get_node_tooltip(node: Dictionary) -> String:
	var node_type := int(node.get("type", 0))
	if node.has("event_title"):
		var route := str(node.get("route_name", ""))
		var phase := str(node.get("phase_name", ""))
		var desc := str(node.get("event_desc", ""))
		var type_text := _get_node_type_text(node_type)
		var lines: Array[String] = []
		if phase != "":
			lines.append(phase)
		if route != "":
			lines.append(route)
		lines.append("难度：%s｜收益：%s" % [_get_difficulty_text(str(node.get("difficulty_tier", "normal"))), _get_reward_text(str(node.get("reward_profile", "material")))])
		lines.append("代价：%s" % _get_node_cost_text(node))
		if _is_costly_route_change(route):
			lines.append("改道代价：%s" % GameState.get_route_switch_cost_text())
		elif _is_free_route_change(route):
			lines.append("局势推线：免费转入%s" % route)
		lines.append("%s｜%s" % [str(node.get("event_title", "")), type_text])
		if desc != "":
			lines.append(desc)
		lines.append(_get_node_feedback_text(node))
		return "\n".join(lines)
	match GameState.selected_era_id:
		"song":
			var full_names: Array[String] = ["征·军情", "商·市舶", "营·整备", "异·异闻", "灾·灾主"]
			return "〔宋卷〕%s\n%s" % [full_names[node_type], _get_node_feedback_text(node)]
		"china":
			var full_names: Array[String] = ["征·终局", "商·行商", "营·整备", "异·百代", "灾·共主"]
			return "〔终局〕%s\n%s" % [full_names[node_type], _get_node_feedback_text(node)]
		_:
			var full_names: Array[String] = ["征·军阵", "商·军需", "营·营帐", "异·野史", "灾·战主"]
			return "〔秦卷〕%s\n%s" % [full_names[node_type], _get_node_feedback_text(node)]

func _get_node_type_text(node_type: int) -> String:
	match GameState.selected_era_id:
		"song":
			return ["征·军情", "商·市舶", "营·整备", "异·异闻", "灾·灾主"][node_type]
		"china":
			return ["征·征战", "商·行商", "营·整备", "异·百代", "灾·共主"][node_type]
		_:
			return ["征·军阵", "商·军需", "营·营帐", "异·野史", "灾·战主"][node_type]

func _create_tree_map() -> void:
	"""创建爬塔地图布局（从下往上）"""
	DebugLog.log("Creating tower climbing map layout")
	DebugLog.log("GameState.map_data size:", GameState.map_data.size())
	DebugLog.log("GameState.current_floor:", GameState.current_floor)
	
	# 清除旧节点
	for child in map_container.get_children():
		child.queue_free()
	
	if GameState.map_data.is_empty():
		DebugLog.log("Map data is empty; skip route drawing until a run starts.")
		return
	
	# 每次只绘制当前大层，避免三大层挤在同一张长地图里。
	var screen_width: int = int(scroll_container.size.x) if scroll_container != null and scroll_container.size.x > 0.0 else 1280
	var visible_start: int = _get_visible_floor_start()
	var visible_end: int = _get_visible_floor_end()
	var visible_floor_count: int = maxi(visible_end - visible_start, 1)
	
	# 调试：打印当前大层入口节点状态
	if visible_start >= 0 and visible_start < GameState.map_data.size():
		DebugLog.log("Visible layer start floor nodes: ", visible_start)
		for i in range(GameState.map_data[visible_start].size()):
			var node = GameState.map_data[visible_start][i]
			var has_accessible = node.has("accessible")
			var accessible_val = node.get("accessible")
			DebugLog.log("  Node %d: type=%s has_accessible=%s accessible=%s visited=%s" % [i, node.get("type", -1), has_accessible, accessible_val, node.get("visited", "MISSING")])

	var node_positions := _build_node_positions(screen_width)
	_draw_route_lines(node_positions)
	
	for floor_idx in range(visible_start, visible_end):
		var floor_data: Array = GameState.map_data[floor_idx]
		var node_count: int = floor_data.size()
		
		# 绘制层级标签
		var floor_label = Label.new()
		var floor_display = floor_idx + 1
		var phase_name := ""
		if not floor_data.is_empty():
			phase_name = str((floor_data[0] as Dictionary).get("phase_name", ""))
			var layer_prefix := ""
			if GameState.get_major_layer_local_floor(floor_idx) == 1:
				layer_prefix = "%s｜" % GameState.get_major_layer_title(GameState.get_major_layer_index(floor_idx))
			if floor_idx == 0:
				floor_label.text = "%s%s ↓ %s" % [layer_prefix, _get_floor_badge(), phase_name if phase_name != "" else "起兵"]
			elif floor_idx == GameState.max_floors - 1:
				floor_label.text = "%s%s ↑ %s 💀" % [layer_prefix, _get_floor_badge(), phase_name if phase_name != "" else "终局灾主"]
			else:
				floor_label.text = "%s%s %s" % [layer_prefix, _get_floor_badge(), phase_name if phase_name != "" else "卷层 %d" % floor_display]
				if _floor_has_checkpoint(floor_data):
					floor_label.text += "｜检点"
			var label_pos: Vector2 = node_positions.get("%d:%d" % [floor_idx, 0], Vector2(120, START_Y + _get_visible_floor_local_index(floor_idx) * NODE_SPACING_Y))
			floor_label.position = Vector2(20, label_pos.y + 8)
		floor_label.add_theme_font_size_override("font_size", 14)
		floor_label.modulate = CHECKPOINT_COLOR if _floor_has_checkpoint(floor_data) else Color(0.7, 0.7, 0.65)
		map_container.add_child(floor_label)
		
		# 绘制该层的所有节点
		for node_idx in range(node_count):
			var node: Dictionary = floor_data[node_idx]
			if not _should_draw_map_node(floor_idx, node):
				continue
			var btn: Button = _create_node_button(node, node_idx, floor_idx)
			var node_pos: Vector2 = node_positions.get("%d:%d" % [floor_idx, node_idx], Vector2.ZERO)
			btn.position = node_pos
			map_container.add_child(btn)
			var feedback := _create_node_feedback_label(node, node_pos, floor_idx)
			if feedback != null:
				map_container.add_child(feedback)
	
	# 设置容器大小以容纳所有层
	var total_height = START_Y * 2 + visible_floor_count * NODE_SPACING_Y
	map_container.custom_minimum_size = Vector2(screen_width, total_height)
	
	# 滚动到当前层
	await get_tree().process_frame
	scroll_container.scroll_vertical = _get_visible_floor_local_index(GameState.current_floor) * NODE_SPACING_Y - 100

func _get_visible_floor_start() -> int:
	var layer_index: int = GameState.get_major_layer_index(GameState.current_floor)
	return clamp(layer_index * int(GameState.FLOORS_PER_MAJOR_LAYER), 0, maxi(GameState.map_data.size() - 1, 0))

func _get_visible_floor_end() -> int:
	return mini(_get_visible_floor_start() + int(GameState.FLOORS_PER_MAJOR_LAYER), GameState.map_data.size())

func _get_visible_floor_local_index(floor_idx: int) -> int:
	return maxi(floor_idx - _get_visible_floor_start(), 0)

func _build_node_positions(screen_width: int) -> Dictionary:
	var positions: Dictionary = {}
	var visible_start: int = _get_visible_floor_start()
	var visible_end: int = _get_visible_floor_end()
	for floor_idx in range(visible_start, visible_end):
		var floor_data: Array = GameState.map_data[floor_idx]
		var node_count: int = floor_data.size()
		var total_width: float = node_count * NODE_WIDTH + (node_count - 1) * NODE_SPACING_X
		var start_x: float = (screen_width - total_width) / 2
		var local_floor_idx: int = _get_visible_floor_local_index(floor_idx)
		for node_idx in range(node_count):
			var node: Dictionary = floor_data[node_idx]
			var x_offset := int(node.get("map_x_offset", 0))
			var y_offset := int(node.get("map_y_offset", 0))
			var x_pos := start_x + node_idx * (NODE_WIDTH + NODE_SPACING_X) + x_offset
			var y_pos := START_Y + local_floor_idx * NODE_SPACING_Y + y_offset
			positions["%d:%d" % [floor_idx, node_idx]] = Vector2(x_pos, y_pos)
	return positions

func _draw_route_lines(node_positions: Dictionary) -> void:
	var visible_start: int = _get_visible_floor_start()
	var visible_end: int = _get_visible_floor_end()
	for floor_idx in range(visible_start, visible_end - 1):
		var floor_data: Array = GameState.map_data[floor_idx]
		for node_idx in range(floor_data.size()):
			var node: Dictionary = floor_data[node_idx]
			var next_indices: Array = node.get("next_indices", [])
			if next_indices.is_empty():
				for i in range(GameState.map_data[floor_idx + 1].size()):
					next_indices.append(i)
			var from_pos: Vector2 = node_positions.get("%d:%d" % [floor_idx, node_idx], Vector2.ZERO) + Vector2(NODE_WIDTH / 2, NODE_HEIGHT + 2)
			for raw_next_idx in next_indices:
				var next_idx := int(raw_next_idx)
				var to_key := "%d:%d" % [floor_idx + 1, next_idx]
				if not node_positions.has(to_key):
					continue
				var next_node: Dictionary = (GameState.map_data[floor_idx + 1] as Array)[next_idx]
				if not _should_draw_route_segment(floor_idx, node, next_node):
					continue
				var to_pos: Vector2 = (node_positions[to_key] as Vector2) + Vector2(NODE_WIDTH / 2, -2)
				var route_color := _get_route_line_color(node, next_node, floor_idx)
				var outline := _create_route_line("RouteLineOutline_%d_%d_%d" % [floor_idx, node_idx, next_idx], from_pos, to_pos, Color(0.03, 0.022, 0.012, route_color.a * 0.86), _get_route_line_width(node, floor_idx) + 4.0)
				map_container.add_child(outline)
				var line := _create_route_line("RouteLine_%d_%d_%d" % [floor_idx, node_idx, next_idx], from_pos, to_pos, route_color, _get_route_line_width(node, floor_idx))
				map_container.add_child(line)

func _create_route_line(line_name: String, from_pos: Vector2, to_pos: Vector2, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.points = PackedVector2Array([from_pos, to_pos])
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	return line

func _should_draw_map_node(floor_idx: int, node: Dictionary) -> bool:
	if floor_idx < GameState.current_floor:
		return bool(node.get("visited", false))
	if floor_idx == GameState.current_floor:
		return bool(node.get("accessible", false)) or bool(node.get("visited", false))
	return true

func _should_draw_route_segment(floor_idx: int, from_node: Dictionary, to_node: Dictionary) -> bool:
	if not _should_draw_map_node(floor_idx, from_node):
		return false
	if not _should_draw_map_node(floor_idx + 1, to_node):
		return false
	if floor_idx < GameState.current_floor - 1:
		return bool(from_node.get("visited", false)) and bool(to_node.get("visited", false))
	if floor_idx == GameState.current_floor - 1:
		return bool(from_node.get("visited", false)) and bool(to_node.get("accessible", false))
	if floor_idx == GameState.current_floor:
		return bool(from_node.get("accessible", false)) or bool(from_node.get("visited", false))
	return true

func _get_route_line_color(node: Dictionary, next_node: Dictionary, floor_idx: int) -> Color:
	var base: Color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	var next_route := str(next_node.get("route_name", "")).strip_edges()
	var from_route := str(node.get("route_name", "")).strip_edges()
	var current_route := str(GameState.selected_route_name).strip_edges()
	var alpha := 0.94 if bool(node.get("accessible", false)) or bool(node.get("visited", false)) or floor_idx == GameState.current_floor else 0.50
	if bool(node.get("visited", false)):
		if current_route != "" and next_route != "" and next_route != current_route:
			return Color(0.95, 0.48, 0.28, 0.86)
		return Color(base.r, base.g, base.b, 0.96)
	if bool(node.get("accessible", false)) or floor_idx == GameState.current_floor:
		if current_route != "" and next_route != "":
			if next_route == current_route:
				return Color(0.52, 0.92, 0.58, alpha)
			return Color(1.0, 0.54, 0.28, alpha)
		if current_route == "" and from_route != "" and next_route != "" and next_route != from_route:
			return Color(1.0, 0.54, 0.28, alpha)
		return Color(1.0, 0.84, 0.38, alpha)
	return Color(0.82, 0.74, 0.58, 0.50)

func _get_route_line_width(node: Dictionary, floor_idx: int) -> float:
	if bool(node.get("visited", false)):
		return 4.2
	if bool(node.get("accessible", false)) or floor_idx == GameState.current_floor:
		return 4.8
	return 3.2

func _current_floor_has_route(route_name: String) -> bool:
	var route := route_name.strip_edges()
	if route == "" or GameState.current_floor < 0 or GameState.current_floor >= GameState.map_data.size():
		return false
	for node in GameState.map_data[GameState.current_floor]:
		var dict := node as Dictionary
		if not bool(dict.get("accessible", false)):
			continue
		if str(dict.get("route_name", "")).strip_edges() == route:
			return true
	return false

func _is_free_route_change(route_name: String) -> bool:
	var route := route_name.strip_edges()
	return GameState.is_route_change(route) and not _current_floor_has_route(GameState.selected_route_name)

func _is_costly_route_change(route_name: String) -> bool:
	var route := route_name.strip_edges()
	return GameState.is_route_change(route) and not _is_free_route_change(route)

func _is_main_route_node(node: Dictionary) -> bool:
	var route := str(node.get("route_name", "")).strip_edges()
	return route != "" and GameState.selected_route_name != "" and route == GameState.selected_route_name

func _get_accessible_route_tint(node: Dictionary) -> Color:
	var route := str(node.get("route_name", "")).strip_edges()
	if _is_main_route_node(node):
		return Color(0.54, 0.92, 0.58, 1.0)
	if _is_costly_route_change(route):
		return Color(1.0, 0.54, 0.28, 1.0)
	if _is_free_route_change(route):
		return Color(0.66, 0.82, 1.0, 1.0)
	return _get_difficulty_color(str(node.get("difficulty_tier", "normal")))

func _create_node_button(node: Dictionary, index: int, floor_idx: int) -> Button:
	var btn := Button.new()
	btn.name = "Node_%d_%d" % [floor_idx, index]
	
	var title := str(node.get("event_title", ""))
	var route := str(node.get("route_name", ""))
	btn.text = _get_compact_node_text("", int(node.type), _get_checkpoint_node_mark(node))
	btn.tooltip_text = _get_node_tooltip(node)
	btn.custom_minimum_size = Vector2(NODE_WIDTH, NODE_HEIGHT)
	btn.size = Vector2(NODE_WIDTH, NODE_HEIGHT)
	var node_icon = _load_node_icon_texture(int(node.type))
	if node_icon != null and title == "":
		btn.icon = node_icon
		btn.expand_icon = true
		btn.text = ""
	btn.add_theme_font_size_override("font_size", 16)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_color_override("font_color", Color(0.10, 0.10, 0.12, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.10, 0.10, 0.12, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.10, 0.10, 0.12, 1.0))
	
	# 样式设置
	var is_current_floor: bool = (floor_idx == GameState.current_floor)
	# 安全检查：确保 accessible 键存在，默认值为 false
	var is_accessible: bool = false
	if node.has("accessible"):
		is_accessible = bool(node.get("accessible"))

	var is_checkpoint := _is_checkpoint_node(node)
	var base_color := _get_node_color(node.type)
	var difficulty_color := _get_difficulty_color(str(node.get("difficulty_tier", "normal")))
	if is_checkpoint:
		base_color = base_color.lerp(CHECKPOINT_COLOR, 0.42)
		difficulty_color = CHECKPOINT_COLOR
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = base_color.darkened(0.22)
	normal_style.border_color = difficulty_color
	normal_style.set_border_width_all(2)
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.corner_radius_bottom_right = 12

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = base_color.darkened(0.04)
	hover_style.border_color = difficulty_color.lightened(0.16)

	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = base_color.darkened(0.32)

	var disabled_style := normal_style.duplicate()
	disabled_style.bg_color = Color(0.16, 0.16, 0.18, 0.96)
	disabled_style.border_color = Color(0.32, 0.32, 0.36, 0.9)

	if is_current_floor and is_accessible:
		normal_style.set_border_width_all(3)
		hover_style.set_border_width_all(3)
		pressed_style.set_border_width_all(3)
		normal_style.border_color = _get_accessible_route_tint(node).lightened(0.08)
		normal_style.bg_color = base_color.darkened(0.10)
		hover_style.border_color = _get_accessible_route_tint(node).lightened(0.18)
		hover_style.bg_color = base_color.lightened(0.04)

	if is_checkpoint:
		normal_style.set_border_width_all(3)
		hover_style.set_border_width_all(3)
		pressed_style.set_border_width_all(3)
		normal_style.border_color = CHECKPOINT_COLOR
		hover_style.border_color = Color(1.0, 0.92, 0.54, 1.0)
		pressed_style.border_color = CHECKPOINT_COLOR.darkened(0.12)
		btn.add_theme_color_override("font_color", Color(0.05, 0.04, 0.03, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.05, 0.04, 0.03, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.05, 0.04, 0.03, 1.0))
		btn.add_theme_color_override("font_disabled_color", Color(0.92, 0.78, 0.48, 0.86))

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	
	if is_accessible:
		btn.pressed.connect(_on_node_clicked.bind(floor_idx, index))
		
		if is_current_floor:
			btn.add_theme_color_override("font_color", Color(0.05, 0.05, 0.07, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.05, 0.05, 0.07, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.05, 0.05, 0.07, 1.0))
		else:
			var off_floor_style := normal_style.duplicate()
			off_floor_style.bg_color = base_color.darkened(0.26)
			off_floor_style.border_color = base_color.darkened(0.08)
			btn.add_theme_stylebox_override("normal", off_floor_style)
	else:
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.62, 0.62, 0.66, 0.72))
		btn.add_theme_color_override("font_disabled_color", Color(0.62, 0.62, 0.66, 0.72))
		if node.visited:
			var visited_style := disabled_style.duplicate()
			visited_style.bg_color = base_color.darkened(0.20)
			visited_style.border_color = base_color.lightened(0.20)
			if is_checkpoint:
				visited_style.border_color = CHECKPOINT_COLOR.darkened(0.08)
			btn.add_theme_stylebox_override("disabled", visited_style)
	
	# BOSS 层特殊显示
	if node.type == 4:
		btn.custom_minimum_size = Vector2(NODE_WIDTH + 10, NODE_HEIGHT)
		btn.text = "灾主"
		btn.add_theme_font_size_override("font_size", 12)

	return btn

func _create_node_feedback_label(node: Dictionary, node_pos: Vector2, floor_idx: int) -> Label:
	if floor_idx != GameState.current_floor or not bool(node.get("accessible", false)):
		return null
	var label := Label.new()
	label.text = _get_node_feedback_short(node)
	label.position = node_pos + Vector2(-28, NODE_HEIGHT + 4)
	label.custom_minimum_size = Vector2(NODE_WIDTH + 56, 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_outline_color", GameState.get_era_theme().get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	label.add_theme_constant_override("outline_size", 2)
	label.modulate = CHECKPOINT_COLOR if _is_checkpoint_node(node) else _get_accessible_route_tint(node)
	label.tooltip_text = _get_node_tooltip(node)
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	return label

func _get_node_feedback_short(node: Dictionary) -> String:
	var route_mark := _get_node_route_short(node)
	return "%s%s｜%s｜%s" % [
		route_mark + "｜" if route_mark != "" else "",
		_get_difficulty_short(str(node.get("difficulty_tier", "normal"))),
		_get_reward_short(str(node.get("reward_profile", "material"))),
		_get_node_cost_short(node)
	]

func _get_node_route_short(node: Dictionary) -> String:
	var route := str(node.get("route_name", "")).strip_edges()
	if _is_main_route_node(node):
		return "主路"
	if _is_costly_route_change(route):
		return "改道"
	if _is_free_route_change(route):
		return "转线"
	return ""

func _get_node_feedback_text(node: Dictionary) -> String:
	var summary := "难度：%s。收益：%s。代价：%s。" % [
		_get_difficulty_text(str(node.get("difficulty_tier", "normal"))),
		_get_reward_text(str(node.get("reward_profile", "material"))),
		_get_node_cost_text(node)
	]
	var route := str(node.get("route_name", ""))
	if _is_costly_route_change(route):
		summary += " 改道代价：%s。" % GameState.get_route_switch_cost_text()
	elif _is_free_route_change(route):
		summary += " 当前主路无可选节点，本次转线免费。"
	if _is_checkpoint_node(node):
		var hint := str(node.get("checkpoint_hint", "这一层会检验当前路线是否成型"))
		return "%s\n中段检点：%s。" % [summary, hint]
	match int(node.get("type", 0)):
		0:
			return "%s\n反馈：战斗会给金币，也会检验当前血线和布局触发率。" % summary
		1:
			return "%s\n反馈：商队用于补核心器物，金币会转化成下一段路线的安全感。" % summary
		2:
			return "%s\n反馈：营寨适合修正失误，恢复、强化或整理背包。" % summary
		3:
			return "%s\n反馈：异闻会改变资源结构，适合想赌一手转机时进入。" % summary
		4:
			return "%s\n反馈：Boss有两条命，第一命试探，第二命才是压迫。" % summary
		_:
			return "%s\n反馈：未知节点。" % summary

func _get_node_feedback_color(node_type: int) -> Color:
	match node_type:
		0:
			return Color(1.0, 0.72, 0.42, 0.95)
		1:
			return Color(1.0, 0.86, 0.38, 0.95)
		2:
			return Color(0.62, 1.0, 0.64, 0.95)
		3:
			return Color(0.76, 0.72, 1.0, 0.95)
		4:
			return Color(1.0, 0.36, 0.28, 0.98)
		_:
			return Color(0.82, 0.82, 0.78, 0.9)

func _get_difficulty_short(tier: String) -> String:
	match tier:
		"safe":
			return "稳"
		"hard":
			return "难"
		"danger":
			return "险"
		_:
			return "中"

func _get_difficulty_text(tier: String) -> String:
	match tier:
		"safe":
			return "稳"
		"hard":
			return "困难"
		"danger":
			return "凶险"
		_:
			return "普通"

func _get_difficulty_color(tier: String) -> Color:
	match tier:
		"safe":
			return Color(0.54, 0.86, 0.62, 0.98)
		"hard":
			return Color(1.0, 0.66, 0.28, 0.98)
		"danger":
			return Color(1.0, 0.26, 0.22, 0.98)
		_:
			return Color(0.66, 0.80, 1.0, 0.96)

func _get_reward_short(profile: String) -> String:
	match profile:
		"gold":
			return "钱"
		"heal":
			return "稳"
		"event":
			return "变"
		"rare":
			return "稀"
		_:
			return "钱"

func _get_reward_text(profile: String) -> String:
	match profile:
		"gold":
			return "金币/器物"
		"heal":
			return "恢复/整备"
		"event":
			return "异闻变化"
		"rare":
			return "高收益"
		_:
			return "金币/战利"

func _get_node_cost_short(node: Dictionary) -> String:
	var route := str(node.get("route_name", "")).strip_edges()
	if _is_costly_route_change(route):
		return "改"
	if _is_free_route_change(route):
		return "免"
	match int(node.get("type", 0)):
		0:
			var tier := str(node.get("difficulty_tier", "normal"))
			return "伤" if tier in ["hard", "danger"] else "战"
		1:
			return "金"
		2:
			return "歇"
		3:
			return "赌"
		4:
			return "命"
		_:
			return "耗"

func _get_node_cost_text(node: Dictionary) -> String:
	var route := str(node.get("route_name", "")).strip_edges()
	if _is_costly_route_change(route):
		return "改道需%s" % GameState.get_route_switch_cost_text()
	if _is_free_route_change(route):
		return "主路已断，本次转线不收金币"
	match int(node.get("type", 0)):
		0:
			var tier := str(node.get("difficulty_tier", "normal"))
			if tier == "danger":
				return "高压战，可能掉命但收益更厚"
			if tier == "hard":
				return "战斗压力偏高，吃血线与布局稳定度"
			return "常规战斗，检验当前构筑"
		1:
			return "消耗金币换器物"
		2:
			return "用一次节点机会换恢复或强化"
		3:
			return "收益与惩罚都不稳定"
		4:
			return "Boss战，要求保命和爆发"
		_:
			return "未知代价"

func _get_node_commit_title(node: Dictionary) -> String:
	match int(node.get("type", 0)):
		0:
			return "已择战局"
		1:
			return "已入商路"
		2:
			return "已扎营"
		3:
			return "已入异闻"
		4:
			return "灾主当前"
		_:
			return "路线已定"

func _get_node_commit_next_text(node: Dictionary) -> String:
	match int(node.get("type", 0)):
		0:
			return "接下来：用当前血线和布局试探敌人。"
		1:
			return "接下来：把金币换成下一段路的稳定性。"
		2:
			return "接下来：用一次节点机会修正状态。"
		3:
			return "接下来：接受不稳定收益，赌一手转机。"
		4:
			return "接下来：检验整局构筑是否成型。"
		_:
			return "接下来：继续推进。"

func _get_node_commit_body(node: Dictionary, route_feedback: String) -> String:
	var rows: Array[String] = []
	if route_feedback != "":
		rows.append(route_feedback)
	rows.append("代价：%s" % _get_node_cost_text(node))
	rows.append("预期：%s" % _get_reward_text(str(node.get("reward_profile", "material"))))
	rows.append(_get_node_commit_next_text(node))
	return "\n".join(rows)

func _show_node_commit_overlay(node: Dictionary, route_feedback: String) -> void:
	var overlay = get_node_or_null("NodeCommitOverlay") as Control
	if overlay:
		overlay.queue_free()
		await get_tree().process_frame

	overlay = Control.new()
	overlay.name = "NodeCommitOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.30)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var theme := GameState.get_era_theme()
	var panel := Panel.new()
	panel.name = "CommitPanel"
	panel.position = Vector2(388, 214)
	panel.size = Vector2(504, 206)
	var style := StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.15, 0.12, 0.10, 0.96))
	style.border_color = _get_difficulty_color(str(node.get("difficulty_tier", "normal")))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var title := Label.new()
	title.name = "CommitTitle"
	title.text = _get_node_commit_title(node)
	title.position = Vector2(24, 18)
	title.size = Vector2(456, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = theme.get("title", Color(1, 0.9, 0.6, 1))
	title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.1, 0.1, 0.15, 1.0)).darkened(0.2))
	title.add_theme_constant_override("outline_size", 1)
	panel.add_child(title)

	var body := Label.new()
	body.name = "CommitBody"
	body.text = _get_node_commit_body(node, route_feedback)
	body.position = Vector2(30, 66)
	body.size = Vector2(444, 110)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 17)
	body.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.1, 0.1, 0.15, 1.0)).darkened(0.2))
	body.add_theme_constant_override("outline_size", 1)
	panel.add_child(body)

	var foot := Label.new()
	foot.name = "CommitFoot"
	foot.text = "推进中..."
	foot.position = Vector2(24, 176)
	foot.size = Vector2(456, 18)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 13)
	foot.modulate = Color(0.76, 0.72, 0.64, 1.0)
	panel.add_child(foot)

	await get_tree().create_timer(0.34, true, false, true).timeout
	if is_instance_valid(overlay):
		overlay.queue_free()
		await get_tree().process_frame

func _get_compact_node_text(route: String, node_type: int, checkpoint_mark: String = "") -> String:
	var type_names: Array[String] = ["征", "商", "营", "异", "灾"]
	var type_text := type_names[clamp(node_type, 0, type_names.size() - 1)]
	if checkpoint_mark != "":
		type_text = checkpoint_mark
	if route == "":
		return type_text
	if route.length() <= 3:
		return "%s\n%s" % [route, type_text]
	return "%s\n%s" % [route.left(2), type_text]

func _floor_has_checkpoint(floor_data: Array) -> bool:
	for node in floor_data:
		if _is_checkpoint_node(node as Dictionary):
			return true
	return false

func _is_checkpoint_node(node: Dictionary) -> bool:
	return str(node.get("checkpoint_tier", "")) == "mid_build"

func _get_checkpoint_node_mark(node: Dictionary) -> String:
	if not _is_checkpoint_node(node):
		return ""
	match int(node.get("type", 0)):
		0:
			return "试"
		1:
			return "补"
		2:
			return "稳"
		3:
			return "注"
		_:
			return "检"

func _get_floor_badge() -> String:
	match GameState.selected_era_id:
		"song":
			return "〔宋卷〕"
		"china":
			return "〔终局〕"
		_:
			return "〔秦卷〕"

func _get_node_color(node_type: int) -> Color:
	match GameState.selected_era_id:
		"song":
			match node_type:
				0: return Color(0.86, 0.58, 0.52)
				1: return Color(0.58, 0.78, 0.95)
				2: return Color(0.60, 0.88, 0.72)
				3: return Color(0.95, 0.86, 0.60)
				4: return Color(0.82, 0.36, 0.30)
				_: return Color.WHITE
		"china":
			match node_type:
				0: return Color(0.92, 0.48, 0.40)
				1: return Color(0.64, 0.76, 0.88)
				2: return Color(0.72, 0.84, 0.70)
				3: return Color(0.90, 0.78, 0.46)
				4: return Color(0.95, 0.28, 0.24)
				_: return Color.WHITE
		_:
			match node_type:
				0: return Color(0.92, 0.56, 0.44)
				1: return Color(0.56, 0.74, 0.90)
				2: return Color(0.62, 0.82, 0.56)
				3: return Color(0.90, 0.80, 0.46)
				4: return Color(0.88, 0.24, 0.20)
				_: return Color.WHITE

func _on_node_clicked(floor_idx: int, node_index: int) -> void:
	if _is_committing_node_choice:
		return
	# 确保只能点击当前层的节点
	if floor_idx != GameState.current_floor:
		DebugLog.log("Can only select nodes on current floor!")
		return
	if floor_idx < 0 or floor_idx >= GameState.map_data.size():
		return
	if node_index < 0 or node_index >= GameState.map_data[floor_idx].size():
		return
	var node := GameState.map_data[floor_idx][node_index] as Dictionary
	var route := str(node.get("route_name", "")).strip_edges()
	var route_feedback := ""
	_is_committing_node_choice = true
	if route != "" and int(node.get("type", 0)) != 4:
		if GameState.selected_route_name == "":
			GameState.commit_route_choice(route)
			route_feedback = "路线：锁定%s。" % route
		elif _is_free_route_change(route):
			GameState.force_route_choice(route)
			route_feedback = "路线：主路已断，免费转入%s。" % route
			_update_resource_label()
		elif _is_costly_route_change(route):
			var cost_text := GameState.get_route_switch_cost_text()
			var switch_result := GameState.try_switch_route(route)
			if not bool(switch_result.get("ok", false)):
				_is_committing_node_choice = false
				_show_top_overlay("改道受阻", str(switch_result.get("message", "")))
				_update_resource_label()
				return
			route_feedback = "路线：改道至%s，已付%s。" % [route, cost_text]
			_update_resource_label()
		else:
			route_feedback = "路线：继续%s。" % route
	elif route == "":
		route_feedback = "路线：不改道。"
	
	await _show_node_commit_overlay(node, route_feedback)
	DebugLog.log("Node clicked: floor", floor_idx, "index", node_index)
	_is_committing_node_choice = false
	node_selected.emit(node_index)

func refresh_map() -> void:
	_update_display()
	_create_tree_map()
