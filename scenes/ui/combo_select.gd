## 连招选择界面
class_name ComboSelect
extends Control

const MoveSymbols = preload("res://resources/move_symbols.gd")

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
var start_button: Button
var back_button: Button
var equipped_container: HBoxContainer
var heirloom_container: HBoxContainer
var tooltip_popup: Control = null
var detail_name_label: Label
var detail_sequence_label: Label
var detail_meta_label: Label
var detail_desc_label: Label
var detail_hint_label: Label
var focused_combo_id: String = ""

# 数据
var combo_database: ComboDatabase
var unlocked_combos: Array = []
var selected_combos: Array[String] = []
var selected_heirloom_id: String = ""
var current_theme: Dictionary = {}
var action_button_states: Dictionary = {}

func _exit_tree() -> void:
	dispose_runtime_cache()

func dispose_runtime_cache() -> void:
	unlocked_combos.clear()
	if combo_database != null and is_instance_valid(combo_database):
		combo_database.all_combos.clear()
		combo_database.combat_combos.clear()
		if combo_database.get_parent() == self:
			remove_child(combo_database)
		combo_database.free()
	combo_database = null

func _load_texture_resource(texture_path: String) -> Texture2D:
	if texture_path == "":
		return null
	if ResourceLoader.exists(texture_path):
		var resource = load(texture_path)
		return resource as Texture2D
	var absolute_path := ProjectSettings.globalize_path(texture_path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image = Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _load_combo_select_texture(slot: String, fallback_slot: String = "") -> Texture2D:
	var texture = _load_texture_resource(ArtRegistry.get_era_ui_path(slot))
	if texture != null:
		return texture
	if fallback_slot != "":
		return _load_texture_resource(ArtRegistry.get_era_ui_path(fallback_slot))
	return null

func _create_ui_texture_rect(texture: Texture2D, pos: Vector2, rect_size: Vector2, node_name: String) -> TextureRect:
	var art = TextureRect.new()
	art.name = node_name
	art.position = pos
	art.custom_minimum_size = rect_size
	art.size = rect_size
	art.texture = texture
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	return art

func _apply_transparent_button_skin(btn: Button, slot: String) -> void:
	var texture = _load_combo_select_texture(slot)
	if texture == null:
		return
	var blank := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", blank)
	btn.add_theme_stylebox_override("hover", blank)
	btn.add_theme_stylebox_override("pressed", blank)
	btn.add_theme_stylebox_override("focus", blank)
	var art := TextureRect.new()
	art.name = "ButtonArt"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(art)
	btn.move_child(art, 0)

func _ready():
	DebugLog.log("[ComboSelect] _ready called")
	current_theme = GameState.get_era_theme()
	_load_combos()
	_setup_ui()
	_refresh_combo_list()
	# 默认选择第一个连招（如果有）
	if unlocked_combos.size() > 0 and selected_combos.is_empty():
		var first_combo = unlocked_combos[0]
		selected_combos.append(first_combo.id)
		GameState.equip_combo(first_combo.id)
		DebugLog.log("[ComboSelect] Auto-selected first combo: ", first_combo.name)
		# 刷新显示
		_update_equipped_display()
		_refresh_combo_list()
	_update_start_button()

func _setup_ui():
	DebugLog.log("[ComboSelect] Setting up UI")
	var era_name = GameState.get_current_era_definition().get("name", "秦")
	var accent: Color = current_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	var title_color: Color = current_theme.get("title", Color(0.94, 0.84, 0.66, 1.0))
	var panel_color: Color = current_theme.get("panel", Color(0.20, 0.16, 0.12, 0.9))

	# 背景 - 全屏
	var bg = ColorRect.new()
	bg.name = "ComboSelectBackdrop"
	bg.color = current_theme.get("bg", Color(0.12, 0.12, 0.18))
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var bg_texture = TextureRect.new()
	bg_texture.name = "ComboSelectBackground"
	bg_texture.texture = _load_texture_resource(ArtRegistry.get_era_ui_path("combo_select_bg"))
	bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_texture.modulate = Color(1, 1, 1, 0.96)
	bg.add_child(bg_texture)
	var title_plate_texture = _load_combo_select_texture("combo_select_title_plate")
	if title_plate_texture != null:
		bg.add_child(_create_ui_texture_rect(title_plate_texture, Vector2(356, 0), Vector2(568, 126), "ComboSelectTitlePlate"))
	else:
		var title_back = ColorRect.new()
		title_back.name = "TitleBackdrop"
		title_back.color = panel_color
		title_back.color.a = 0.16
		title_back.position = Vector2(356, 0)
		title_back.custom_minimum_size = Vector2(568, 126)
		bg.add_child(title_back)
	var top_bar = ColorRect.new()
	top_bar.name = "TopBand"
	top_bar.color = panel_color
	top_bar.color.a = 0.42
	top_bar.position = Vector2(160, 110)
	top_bar.custom_minimum_size = Vector2(960, 14)
	bg.add_child(top_bar)
	var bottom_bar = ColorRect.new()
	bottom_bar.name = "BottomAccentBand"
	bottom_bar.color = accent
	bottom_bar.position = Vector2(210, 694)
	bottom_bar.custom_minimum_size = Vector2(860, 3)
	bg.add_child(bottom_bar)
	var bottom_plate_texture = _load_combo_select_texture("combo_select_bottom_plate")
	if bottom_plate_texture != null:
		bg.add_child(_create_ui_texture_rect(bottom_plate_texture, Vector2(42, 628), Vector2(1196, 68), "ComboSelectBottomPlate"))
	else:
		var bottom_plate = ColorRect.new()
		bottom_plate.name = "BottomPlate"
		bottom_plate.color = panel_color
		bottom_plate.color.a = 0.12
		bottom_plate.position = Vector2(42, 628)
		bottom_plate.custom_minimum_size = Vector2(1196, 68)
		bg.add_child(bottom_plate)
	var era_seal = Panel.new()
	era_seal.name = "EraSeal"
	var seal_texture = _load_combo_select_texture("combo_select_seal", "main_menu_seal")
	if seal_texture != null:
		match GameState.selected_era_id:
			"song":
				era_seal.position = Vector2(154, 88)
				era_seal.size = Vector2(260, 128)
			"china":
				era_seal.position = Vector2(182, 104)
				era_seal.size = Vector2(188, 92)
			_:
				era_seal.position = Vector2(182, 104)
				era_seal.size = Vector2(188, 92)
		era_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var seal_art := TextureRect.new()
		seal_art.name = "Texture"
		seal_art.set_anchors_preset(Control.PRESET_FULL_RECT)
		seal_art.texture = seal_texture
		seal_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		seal_art.stretch_mode = TextureRect.STRETCH_SCALE
		seal_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		era_seal.add_child(seal_art)
	else:
		era_seal.position = Vector2(168, 124)
		era_seal.size = Vector2(132, 40)
		var era_seal_style := StyleBoxFlat.new()
		era_seal_style.corner_radius_top_left = 4
		era_seal_style.corner_radius_top_right = 4
		era_seal_style.corner_radius_bottom_left = 4
		era_seal_style.corner_radius_bottom_right = 4
		era_seal_style.border_width_left = 2
		era_seal_style.border_width_right = 2
		era_seal_style.border_width_top = 2
		era_seal_style.border_width_bottom = 2
		era_seal_style.bg_color = panel_color
		era_seal_style.border_color = accent
		era_seal.add_theme_stylebox_override("panel", era_seal_style)
	var era_seal_label = Label.new()
	era_seal_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	era_seal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	era_seal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	era_seal_label.add_theme_font_size_override("font_size", 18)
	era_seal_label.modulate = title_color
	match GameState.selected_era_id:
		"song":
			era_seal_label.text = "〔宋卷〕"
		"china":
			era_seal_label.text = "〔终局〕"
		_:
			era_seal_label.text = "〔秦卷〕"
	era_seal.add_child(era_seal_label)
	bg.add_child(era_seal)

	# 标题
	title_label = Label.new()
	title_label.text = "⚔️ %s卷 · 初始布局" % era_name
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 34
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.modulate = title_color
	title_label.add_theme_color_override("font_outline_color", current_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	title_label.add_theme_constant_override("outline_size", 1)
	add_child(title_label)

	# 槽位显示
	slots_label = Label.new()
	slots_label.name = "SlotsLabel"
	slots_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	slots_label.offset_top = 70
	slots_label.add_theme_font_size_override("font_size", 20)
	slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slots_label.modulate = accent.lerp(Color.WHITE, 0.35)
	add_child(slots_label)

	unlock_status_label = Label.new()
	unlock_status_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	unlock_status_label.offset_top = 98
	unlock_status_label.add_theme_font_size_override("font_size", 14)
	unlock_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_status_label.modulate = accent.lerp(Color(0.6, 0.64, 0.72, 1.0), 0.45)
	unlock_status_label.text = GameState.get_combo_unlock_status_text()
	add_child(unlock_status_label)

	meta_summary_label = Label.new()
	meta_summary_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	meta_summary_label.offset_top = 120
	meta_summary_label.add_theme_font_size_override("font_size", 14)
	meta_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_summary_label.modulate = title_color.lerp(Color(0.8, 0.92, 0.86, 1.0), 0.35)
	meta_summary_label.text = _get_meta_combo_summary_text()
	add_child(meta_summary_label)

	var start_combo_hint = _create_info_icon("选择说明", "这里只选择开局可携带布局；隐藏布局、器物联动、状态依赖布局已收入百代异闻录。")
	start_combo_hint.name = "ComboSelectHint"
	start_combo_hint.position = Vector2(1030, 118)
	add_child(start_combo_hint)

	# 已装备区域
	var equipped_title = Label.new()
	equipped_title.name = "EquippedTitle"
	equipped_title.text = "📌 已备布局"
	equipped_title.position = Vector2(50, 150)
	equipped_title.add_theme_font_size_override("font_size", 20)
	equipped_title.modulate = title_color
	equipped_title.add_theme_color_override("font_outline_color", current_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	equipped_title.add_theme_constant_override("outline_size", 1)
	add_child(equipped_title)

	equipped_container = HBoxContainer.new()
	equipped_container.name = "EquippedSlots"
	equipped_container.position = Vector2(50, 184)
	equipped_container.add_theme_constant_override("separation", 18)
	add_child(equipped_container)

	# 可选连招区域
	var available_title = Label.new()
	available_title.name = "AvailableTitle"
	available_title.text = "📋 可携带布局"
	available_title.position = Vector2(76, 310)
	available_title.size = Vector2(580, 28)
	available_title.add_theme_font_size_override("font_size", 19)
	available_title.modulate = current_theme.get("good", Color(0.7, 0.9, 0.7))
	available_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	available_title.add_theme_color_override("font_outline_color", current_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	available_title.add_theme_constant_override("outline_size", 1)
	add_child(available_title)
	var left_style := StyleBoxFlat.new()
	left_style.bg_color = panel_color.darkened(0.05)
	left_style.border_color = accent
	left_style.border_width_left = 2
	left_style.border_width_top = 2
	left_style.border_width_right = 2
	left_style.border_width_bottom = 2
	left_style.corner_radius_top_left = 14
	left_style.corner_radius_top_right = 14
	left_style.corner_radius_bottom_right = 14
	left_style.corner_radius_bottom_left = 14
	var left_frame_texture = _load_combo_select_texture("combo_select_left_frame")
	if left_frame_texture != null:
		add_child(_create_ui_texture_rect(left_frame_texture, Vector2(64, 298), Vector2(604, 344), "ComboListFrameArt"))
	else:
		var left_frame = PanelContainer.new()
		left_frame.name = "ComboListFrame"
		left_frame.position = Vector2(64, 298)
		left_frame.custom_minimum_size = Vector2(604, 344)
		left_frame.add_theme_stylebox_override("panel", left_style)
		add_child(left_frame)

	# 连招列表容器（使用 ScrollContainer） - 左侧可选择连招
	var scroll = ScrollContainer.new()
	scroll.name = "ComboListScroll"
	scroll.position = Vector2(82, 320)
	scroll.size = Vector2(566, 312)
	add_child(scroll)

	combo_container = VBoxContainer.new()
	combo_container.add_theme_constant_override("separation", 15)
	combo_container.custom_minimum_size = Vector2(500, 0)
	combo_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(combo_container)

	var heirloom_title = Label.new()
	heirloom_title.name = "HeirloomTitle"
	heirloom_title.text = "传家宝"
	heirloom_title.position = Vector2(700, 198)
	heirloom_title.size = Vector2(530, 24)
	heirloom_title.add_theme_font_size_override("font_size", 18)
	heirloom_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heirloom_title.modulate = title_color
	heirloom_title.add_theme_color_override("font_outline_color", current_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	heirloom_title.add_theme_constant_override("outline_size", 1)
	add_child(heirloom_title)

	heirloom_container = HBoxContainer.new()
	heirloom_container.name = "HeirloomOptions"
	heirloom_container.position = Vector2(700, 224)
	heirloom_container.add_theme_constant_override("separation", 6)
	add_child(heirloom_container)

	# 当前详情区域
	var detail_title = Label.new()
	detail_title.name = "DetailTitle"
	detail_title.text = "🧭 当前详情"
	detail_title.position = Vector2(700, 278)
	detail_title.size = Vector2(530, 28)
	detail_title.add_theme_font_size_override("font_size", 20)
	detail_title.modulate = accent
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_title.add_theme_color_override("font_outline_color", current_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	detail_title.add_theme_constant_override("outline_size", 1)
	add_child(detail_title)

	var detail_frame = PanelContainer.new()
	detail_frame.name = "DetailFrame"
	detail_frame.position = Vector2(688, 306)
	detail_frame.custom_minimum_size = Vector2(554, 270)
	var detail_frame_art_texture = _load_combo_select_texture("combo_select_upper_right_frame")
	if detail_frame_art_texture != null:
		var detail_frame_art := TextureRect.new()
		detail_frame_art.name = "DetailFrameArt"
		detail_frame_art.anchor_left = 0.0
		detail_frame_art.anchor_top = 0.0
		detail_frame_art.anchor_right = 1.0
		detail_frame_art.anchor_bottom = 1.0
		detail_frame_art.offset_left = -24
		detail_frame_art.offset_top = -18
		detail_frame_art.offset_right = 24
		detail_frame_art.offset_bottom = 18
		detail_frame_art.texture = detail_frame_art_texture
		detail_frame_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		detail_frame_art.stretch_mode = TextureRect.STRETCH_SCALE
		detail_frame_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		detail_frame.add_child(detail_frame_art)
	else:
		detail_frame.add_theme_stylebox_override("panel", left_style)
	add_child(detail_frame)

	var detail_frame_overlay = TextureRect.new()
	detail_frame_overlay.name = "DetailFrameTexture"
	detail_frame_overlay.texture = null
	detail_frame_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_frame_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_frame_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_frame_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	detail_frame_overlay.modulate = Color(1, 1, 1, 0.0)
	detail_frame.add_child(detail_frame_overlay)

	var detail_body = VBoxContainer.new()
	detail_body.name = "DetailBody"
	detail_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_body.offset_left = 18
	detail_body.offset_top = 16
	detail_body.offset_right = -18
	detail_body.offset_bottom = -16
	detail_body.add_theme_constant_override("separation", 8)
	detail_frame.add_child(detail_body)

	detail_name_label = Label.new()
	detail_name_label.add_theme_font_size_override("font_size", 26)
	detail_name_label.modulate = title_color
	detail_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_body.add_child(detail_name_label)

	detail_sequence_label = Label.new()
	detail_sequence_label.add_theme_font_size_override("font_size", 28)
	detail_sequence_label.modulate = accent.lerp(Color.WHITE, 0.18)
	detail_sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_body.add_child(detail_sequence_label)

	detail_meta_label = Label.new()
	detail_meta_label.add_theme_font_size_override("font_size", 13)
	detail_meta_label.modulate = current_theme.get("good", Color(0.7, 0.9, 0.7)).lerp(Color.WHITE, 0.18)
	detail_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_body.add_child(detail_meta_label)

	var detail_desc_panel = PanelContainer.new()
	detail_desc_panel.name = "DetailSummaryPlate"
	detail_desc_panel.custom_minimum_size = Vector2(0, 118)
	var detail_desc_style := StyleBoxFlat.new()
	detail_desc_style.bg_color = panel_color.darkened(0.08)
	detail_desc_style.border_color = accent.lerp(Color(0.5, 0.5, 0.56, 1.0), 0.45)
	detail_desc_style.set_border_width_all(1)
	detail_desc_style.corner_radius_top_left = 12
	detail_desc_style.corner_radius_top_right = 12
	detail_desc_style.corner_radius_bottom_left = 12
	detail_desc_style.corner_radius_bottom_right = 12
	detail_desc_panel.add_theme_stylebox_override("panel", detail_desc_style)
	detail_body.add_child(detail_desc_panel)

	detail_desc_label = Label.new()
	detail_desc_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_desc_label.offset_left = 14
	detail_desc_label.offset_top = 12
	detail_desc_label.offset_right = -14
	detail_desc_label.offset_bottom = -12
	detail_desc_label.add_theme_font_size_override("font_size", 16)
	detail_desc_label.modulate = title_color.lerp(Color.WHITE, 0.18)
	detail_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_desc_panel.add_child(detail_desc_label)

	detail_hint_label = Label.new()
	detail_hint_label.add_theme_font_size_override("font_size", 14)
	detail_hint_label.modulate = accent.lerp(Color(0.72, 0.78, 0.9, 1.0), 0.3)
	detail_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_body.add_child(detail_hint_label)

	# 底部按钮
	back_button = Button.new()
	back_button.text = "← 返回"
	back_button.custom_minimum_size = Vector2(120, 50)
	back_button.position = Vector2(100, 640)
	back_button.add_theme_font_size_override("font_size", 18)
	var nav_style := StyleBoxFlat.new()
	nav_style.bg_color = panel_color.darkened(0.06)
	nav_style.border_color = accent
	nav_style.border_width_left = 2
	nav_style.border_width_top = 2
	nav_style.border_width_right = 2
	nav_style.border_width_bottom = 2
	nav_style.corner_radius_top_left = 12
	nav_style.corner_radius_top_right = 12
	nav_style.corner_radius_bottom_right = 12
	nav_style.corner_radius_bottom_left = 12
	var nav_hover := nav_style.duplicate()
	nav_hover.bg_color = panel_color.lightened(0.08)
	var nav_pressed := nav_style.duplicate()
	nav_pressed.bg_color = panel_color.darkened(0.1)
	back_button.add_theme_stylebox_override("normal", nav_style)
	back_button.add_theme_stylebox_override("hover", nav_hover)
	back_button.add_theme_stylebox_override("pressed", nav_pressed)
	back_button.add_theme_stylebox_override("focus", nav_hover)
	back_button.add_theme_color_override("font_color", title_color)
	back_button.add_theme_color_override("font_outline_color", current_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	back_button.add_theme_constant_override("outline_size", 1)
	ArtRegistry.apply_button_icon(back_button, "back", false, "返回角色选择")
	_apply_transparent_button_skin(back_button, "combo_select_back_button")
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "起兵开局"
	start_button.custom_minimum_size = Vector2(200, 50)
	start_button.position = Vector2(900, 640)
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.add_theme_stylebox_override("normal", nav_style)
	start_button.add_theme_stylebox_override("hover", nav_hover)
	start_button.add_theme_stylebox_override("pressed", nav_pressed)
	start_button.add_theme_stylebox_override("focus", nav_hover)
	start_button.add_theme_color_override("font_color", title_color)
	start_button.add_theme_color_override("font_outline_color", current_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	start_button.add_theme_constant_override("outline_size", 1)
	ArtRegistry.apply_button_icon(start_button, "start", false, "起兵开局")
	_apply_transparent_button_skin(start_button, "combo_select_start_button")
	start_button.disabled = true
	start_button.pressed.connect(_on_start_pressed)
	add_child(start_button)
	_ensure_action_button_feedback(back_button)
	_ensure_action_button_feedback(start_button)
	_apply_action_button_feedback_state(back_button, false, false)
	_apply_action_button_feedback_state(start_button, false, false)

	# 图例
	var legend = _create_info_icon("规则", "%s。布局胜者造成攻击伤害。" % MoveSymbols.matchup_hint())
	legend.name = "RuleHint"
	legend.position = Vector2(625, 675)
	add_child(legend)

	_update_slots_display()
	_update_equipped_display()
	_refresh_heirloom_display()
	_update_detail_panel()

func _load_combos():
	# 创建连招数据库实例
	combo_database = ComboDatabase.new()
	combo_database._init_database()  # 手动初始化

	# 获取已解锁的连招
	unlocked_combos = combo_database.get_start_selectable_combos()
	DebugLog.log("[ComboSelect] Loaded ", unlocked_combos.size(), " unlocked combos")

	# 从 GameState 加载已选中的连招
	selected_combos = GameState.get_equipped_combos().duplicate()
	selected_heirloom_id = str(GameState.selected_heirloom_id)
	if selected_heirloom_id == "":
		var heirloom_ids := GameState.get_heirloom_ids()
		if not heirloom_ids.is_empty():
			selected_heirloom_id = heirloom_ids[0]
			GameState.select_heirloom(selected_heirloom_id)

func _get_max_slots() -> int:
	return GameState.max_combo_slots

func _get_meta_combo_summary_text() -> String:
	var slot_source = "基础槽位: %d" % GameState.max_combo_slots
	var cooldown = GameState.get_meta_upgrade_count("combo_cooldown")
	var cooldown_text = "冷却缩减: -%d回合" % cooldown if cooldown > 0 else "冷却缩减: 未解锁"
	var tier_text = GameState.get_combo_unlock_status_text()
	return "%s  |  %s  |  %s" % [slot_source, cooldown_text, tier_text]

func _theme_accent() -> Color:
	return current_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))

func _theme_title() -> Color:
	return current_theme.get("title", Color(0.94, 0.84, 0.66, 1.0))

func _theme_panel() -> Color:
	return current_theme.get("panel", Color(0.20, 0.16, 0.12, 0.9))

func _create_info_icon(label_text: String, tooltip: String) -> Label:
	var info = Label.new()
	info.text = "ⓘ %s" % label_text
	info.mouse_filter = Control.MOUSE_FILTER_STOP
	info.add_theme_font_size_override("font_size", 14)
	info.modulate = current_theme.get("accent", Color(0.72, 0.84, 1.0))
	info.mouse_entered.connect(func(): _show_info_tooltip(info, tooltip))
	info.mouse_exited.connect(_hide_info_tooltip)
	return info

func _show_info_tooltip(anchor: Control, text: String) -> void:
	_hide_info_tooltip()
	tooltip_popup = PanelContainer.new()
	tooltip_popup.name = "InfoTooltip"
	tooltip_popup.z_index = 100
	tooltip_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style = StyleBoxFlat.new()
	style.bg_color = current_theme.get("panel", Color(0.06, 0.07, 0.10, 0.96))
	style.border_color = current_theme.get("accent", Color(0.55, 0.68, 0.95, 0.9))
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
	label.modulate = current_theme.get("title", Color(0.9, 0.92, 0.98))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_popup.add_child(label)

	var local_pos = anchor.global_position - global_position + Vector2(-170, anchor.size.y + 14)
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
	panel.custom_minimum_size = Vector2(510, 48)
	var frame_texture = _load_combo_select_texture("combo_select_special_item_frame")
	if frame_texture != null:
		var art := TextureRect.new()
		art.name = "SpecialItemFrameArt"
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.texture = frame_texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(art)
		panel.move_child(art, 0)
	else:
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.bg_color = _theme_panel().darkened(0.06)
		style.border_color = _theme_accent().lerp(Color(0.46, 0.46, 0.56, 1.0), 0.25)
		style.set_border_width_all(2)
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
	lock_icon.modulate = _theme_accent().lerp(Color.WHITE, 0.2)
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
		name_text = ComboDatabase.get_era_combo_name(combo.name)
	else:
		desc_text = "[需要: %s]" % combo_data.requires

	# 序列图标
	var seq_label = Label.new()
	seq_label.text = seq_text
	seq_label.add_theme_font_size_override("font_size", 18)
	seq_label.modulate = _theme_title()
	seq_label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(seq_label)

	# 连招信息
	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(180, 0)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.modulate = _theme_title().lerp(Color.WHITE, 0.12)
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
	condition_label.modulate = _theme_accent().lerp(Color(0.92, 0.82, 0.64, 1.0), 0.2)
	condition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(condition_label)

	return panel

func _refresh_combo_list():
	if combo_container == null:
		DebugLog.log("[ComboSelect] ERROR: combo_container is null!")
		return
	# 清除旧列表
	for child in combo_container.get_children():
		child.queue_free()

	DebugLog.log("[ComboSelect] Refreshing combo list, unlocked_combos size: ", unlocked_combos.size())
	# 添加连招项
	for combo in unlocked_combos:
		var combo_item = _create_combo_item(combo)
		combo_container.add_child(combo_item)
	_update_detail_panel(focused_combo_id)

func _create_combo_item(combo) -> Control:
	var panel = PanelContainer.new()
	panel.name = "ComboCard_%s" % str(combo.id)
	panel.custom_minimum_size = Vector2(500, 68)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var frame_texture = _load_combo_select_texture("combo_select_combo_item_frame")
	if frame_texture != null:
		var art := TextureRect.new()
		art.name = "ComboItemFrameArt"
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.texture = frame_texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if combo.id in selected_combos:
			art.modulate = current_theme.get("good", Color(0.92, 1.0, 0.92, 1.0))
		panel.add_child(art)
		panel.move_child(art, 0)
	else:
		# 背景颜色根据选中状态
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10

		if combo.id in selected_combos:
			style.bg_color = current_theme.get("good", Color(0.2, 0.4, 0.2)).lerp(_theme_panel(), 0.65)
			style.border_color = current_theme.get("good", Color(0.4, 0.8, 0.4))
			style.set_border_width_all(2)
		else:
			style.bg_color = _theme_panel().darkened(0.04)
			style.border_color = _theme_accent().lerp(Color(0.4, 0.4, 0.5, 1.0), 0.35)
			style.set_border_width_all(2)

		panel.add_theme_stylebox_override("panel", style)

	var art_plate = PanelContainer.new()
	art_plate.name = "CardArtPlate"
	art_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_plate.offset_left = 10
	art_plate.offset_right = -96
	art_plate.offset_top = 8
	art_plate.offset_bottom = -8
	var art_style := StyleBoxFlat.new()
	art_style.bg_color = _theme_panel().lightened(0.04)
	if combo.id in selected_combos:
		art_style.bg_color = current_theme.get("good", Color(0.2, 0.4, 0.2)).lerp(_theme_panel().lightened(0.08), 0.78)
	art_style.border_color = _theme_accent().lerp(Color.WHITE, 0.06)
	art_style.set_border_width_all(1)
	art_style.corner_radius_top_left = 8
	art_style.corner_radius_top_right = 8
	art_style.corner_radius_bottom_left = 8
	art_style.corner_radius_bottom_right = 8
	art_plate.add_theme_stylebox_override("panel", art_style)
	panel.add_child(art_plate)

	var art_texture = TextureRect.new()
	art_texture.name = "CardArtTexture"
	art_texture.texture = null
	art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_texture.stretch_mode = TextureRect.STRETCH_SCALE
	art_texture.modulate = Color(1, 1, 1, 0.0)
	art_plate.add_child(art_texture)

	# 内容容器
	var hbox = HBoxContainer.new()
	hbox.name = "CardContent"
	hbox.add_theme_constant_override("separation", 16)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 15
	hbox.offset_right = -15
	hbox.offset_top = 10
	hbox.offset_bottom = -10
	panel.add_child(hbox)

	# 中段序列区
	var seq_wrap = VBoxContainer.new()
	seq_wrap.name = "CardSequenceWrap"
	seq_wrap.custom_minimum_size = Vector2(104, 0)
	seq_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(seq_wrap)

	var seq_label = Label.new()
	seq_label.name = "CardSequenceLabel"
	seq_label.text = _get_sequence_icons(combo.sequence)
	seq_label.add_theme_font_size_override("font_size", 22)
	seq_label.modulate = _theme_title()
	seq_label.custom_minimum_size = Vector2(104, 0)
	seq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seq_wrap.add_child(seq_label)

	# 中央文本区
	var info_vbox = VBoxContainer.new()
	info_vbox.name = "CardTextWrap"
	info_vbox.custom_minimum_size = Vector2(188, 0)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.name = "CardNameLabel"
	name_label.text = "%s%s" % [
		ComboDatabase.get_era_combo_name(combo.name),
		GameState.get_combo_upgrade_status_text(str(combo.id))
	]
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.modulate = _theme_title().lerp(Color.WHITE, 0.15)
	info_vbox.add_child(name_label)

	var role_label = Label.new()
	role_label.name = "CardRoleLabel"
	role_label.add_theme_font_size_override("font_size", 12)
	role_label.modulate = _theme_accent().lerp(Color.WHITE, 0.12)
	role_label.text = ComboDatabase.get_era_role_text(combo.role) if combo.get("role") != null and combo.role != "" else "通用布局"
	info_vbox.add_child(role_label)

	var info_icon = _create_info_icon("详情", _get_combo_detail_text(combo))
	info_icon.name = "CardInfoButton"
	info_icon.custom_minimum_size = Vector2(54, 0)

	# 右侧状态区
	var status_vbox = VBoxContainer.new()
	status_vbox.name = "CardStatusWrap"
	status_vbox.custom_minimum_size = Vector2(86, 0)
	status_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(status_vbox)

	var cooldown_reduce = GameState.get_meta_upgrade_count("combo_cooldown")
	var actual_cooldown = maxi(combo.cooldown - cooldown_reduce, 1)
	var cooldown_label = Label.new()
	cooldown_label.name = "CardCooldownLabel"
	cooldown_label.text = "⏳ CD:%d" % actual_cooldown
	if cooldown_reduce > 0:
		cooldown_label.text += " (-%d)" % cooldown_reduce
	cooldown_label.add_theme_font_size_override("font_size", 13)
	cooldown_label.modulate = _theme_accent().lerp(Color.WHITE, 0.2)
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(cooldown_label)

	# 选中状态
	var status_label = Label.new()
	status_label.name = "CardStateLabel"
	status_label.custom_minimum_size = Vector2(72, 0)
	if combo.id in selected_combos:
		status_label.text = "✅ 已装备"
		status_label.add_theme_font_size_override("font_size", 15)
		status_label.modulate = current_theme.get("good", Color(0.5, 1, 0.5))
	else:
		status_label.text = "➕ 点击装备"
		status_label.add_theme_font_size_override("font_size", 13)
		status_label.modulate = _theme_accent().lerp(Color(0.55, 0.55, 0.6, 1.0), 0.55)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_vbox.add_child(status_label)
	status_vbox.add_child(info_icon)

	# 点击事件
	var combo_id = combo.id
	panel.mouse_entered.connect(func(): _update_detail_panel(combo_id))
	panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_combo_clicked(combo_id)
	)

	return panel

func _update_detail_panel(combo_id: String = "") -> void:
	if detail_name_label == null:
		return
	var target_id := combo_id
	if target_id == "":
		if focused_combo_id != "":
			target_id = focused_combo_id
		elif not selected_combos.is_empty():
			target_id = selected_combos[0]
		elif not unlocked_combos.is_empty():
			target_id = str(unlocked_combos[0].id)
	var combo = combo_database.get_combo_by_id(target_id) if combo_database != null and target_id != "" else null
	if combo == null:
		focused_combo_id = ""
		detail_name_label.text = "待定布局"
		detail_sequence_label.text = "○ △ □"
		detail_meta_label.text = "定位 / 冷却 / 时代偏置"
		detail_desc_label.text = "开局编组区，只看这套布局本身的战术价值。"
		detail_hint_label.text = "隐藏布局与联动布局见百代异闻录。"
		return
	focused_combo_id = str(combo.id)
	var upgrade_status = GameState.get_combo_upgrade_status_text(str(combo.id))
	detail_name_label.text = "%s%s" % [ComboDatabase.get_era_combo_name(combo.name), upgrade_status]
	detail_sequence_label.text = _get_sequence_icons(combo.sequence)
	var meta_parts: Array[String] = []
	if combo.get("role") != null and combo.role != "":
		meta_parts.append("定位：%s" % ComboDatabase.get_era_role_text(combo.role))
	var cooldown_reduce = GameState.get_meta_upgrade_count("combo_cooldown")
	var actual_cooldown = maxi(combo.cooldown - cooldown_reduce, 1)
	meta_parts.append("冷却：%d回合" % actual_cooldown)
	if combo.get("exclusive_era") != null and str(combo.exclusive_era) != "":
		meta_parts.append("时代专属")
	meta_parts.append(GameState.get_era_combo_bonus_text(str(combo.id), str(combo.effect_type)))
	detail_meta_label.text = "  |  ".join(meta_parts)
	detail_desc_label.text = _get_combo_detail_text(combo)
	var hint_text = "战术摘要"
	if combo.get("usage_hint") != null and combo.usage_hint != "":
		hint_text += "：%s" % ComboDatabase.get_era_hint_text(combo.usage_hint)
	if combo.get("exclusive_era") != null and str(combo.exclusive_era) != "":
		hint_text += "\n时代轴心"
	detail_hint_label.text = hint_text

func _get_combo_detail_text(combo) -> String:
	var cooldown_reduce = GameState.get_meta_upgrade_count("combo_cooldown")
	var actual_cooldown = maxi(combo.cooldown - cooldown_reduce, 1)
	var parts: Array[String] = []
	if combo.get("role") != null and combo.role != "":
		parts.append(ComboDatabase.get_era_role_text(combo.role))
	parts.append(combo.description)
	if combo.get("exclusive_era") != null and str(combo.exclusive_era) != "":
		parts.append("%s卷专属" % GameState.get_current_era_definition().get("name", "秦"))
	var upgrade_status = GameState.get_combo_upgrade_status_text(str(combo.id))
	if upgrade_status != "":
		parts.append("强化：%s" % upgrade_status.strip_edges())
	var cd_text = "CD %d回合" % actual_cooldown
	if cooldown_reduce > 0:
		cd_text += " / 局外-%d" % cooldown_reduce
	parts.append(cd_text)
	return "\n".join(parts)

func _get_sequence_icons(sequence: Array[int]) -> String:
	return MoveSymbols.sequence_to_text(sequence)

func _on_combo_clicked(combo_id: String):
	DebugLog.log("[ComboSelect] Combo clicked: ", combo_id)

	if combo_id in selected_combos:
		# 取消装备
		selected_combos.erase(combo_id)
		GameState.unequip_combo(combo_id)
	else:
		# 装备（检查槽位）
		if selected_combos.size() >= _get_max_slots():
			DebugLog.log("[ComboSelect] Slots full!")
			return

		selected_combos.append(combo_id)
		GameState.equip_combo(combo_id)

	# 刷新显示
	_update_slots_display()
	_update_equipped_display()
	_refresh_combo_list()
	_update_detail_panel(combo_id)
	_update_start_button()

func _update_slots_display():
	slots_label.text = "槽位: %d / %d" % [selected_combos.size(), _get_max_slots()]
	if meta_summary_label:
		meta_summary_label.text = _get_meta_combo_summary_text()

	# 根据槽位状态改变颜色
	if selected_combos.size() >= _get_max_slots():
		slots_label.modulate = current_theme.get("bad", Color(1, 0.7, 0.7))
	elif selected_combos.size() > 0:
		slots_label.modulate = current_theme.get("good", Color(0.7, 1, 0.7))
	else:
		slots_label.modulate = current_theme.get("accent", Color(0.8, 0.9, 1)).lerp(Color.WHITE, 0.35)

func _refresh_heirloom_display() -> void:
	if heirloom_container == null:
		return
	for child in heirloom_container.get_children():
		child.queue_free()
	var ids := GameState.get_heirloom_ids()
	for heirloom_id in ids:
		var data := GameState.get_heirloom_data(heirloom_id)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(84, 58)
		btn.text = "%s\n%s" % [
			str(data.get("name", heirloom_id)),
			GameState.get_heirloom_short_effect(heirloom_id)
		]
		btn.tooltip_text = ""
		btn.add_theme_font_size_override("font_size", 12)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var selected := heirloom_id == selected_heirloom_id
		var style := StyleBoxFlat.new()
		style.bg_color = _theme_panel().lightened(0.06) if selected else _theme_panel().darkened(0.08)
		style.border_color = current_theme.get("good", Color(0.7, 1.0, 0.7)) if selected else _theme_accent().darkened(0.2)
		style.set_border_width_all(2 if selected else 1)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		var hover := style.duplicate()
		hover.bg_color = style.bg_color.lightened(0.08)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("focus", hover)
		btn.add_theme_color_override("font_color", _theme_title())
		btn.add_theme_color_override("font_outline_color", current_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		btn.add_theme_constant_override("outline_size", 1)
		btn.pressed.connect(_on_heirloom_selected.bind(heirloom_id))
		btn.mouse_entered.connect(func():
			_update_heirloom_detail_panel(heirloom_id)
			_show_info_tooltip(btn, GameState.get_heirloom_detail_text(heirloom_id))
		)
		btn.mouse_exited.connect(func():
			_hide_info_tooltip()
			_update_detail_panel(focused_combo_id)
		)
		heirloom_container.add_child(btn)

func _on_heirloom_selected(heirloom_id: String) -> void:
	if not GameState.select_heirloom(heirloom_id):
		return
	selected_heirloom_id = heirloom_id
	_refresh_heirloom_display()
	_update_heirloom_detail_panel(heirloom_id)

func _update_heirloom_detail_panel(heirloom_id: String) -> void:
	if detail_name_label == null:
		return
	var data := GameState.get_heirloom_data(heirloom_id)
	if data.is_empty():
		return
	detail_name_label.text = "%s｜传家宝" % str(data.get("name", heirloom_id))
	detail_sequence_label.text = GameState.get_heirloom_short_effect(heirloom_id)
	detail_meta_label.text = GameState.get_heirloom_synergy_text(heirloom_id)
	detail_desc_label.text = str(data.get("description", ""))
	detail_hint_label.text = "当前：%s\n传家宝是场外带入局内的流派支点。" % GameState.get_heirloom_status_text(heirloom_id)

func _update_equipped_display():
	# 清除旧显示
	for child in equipped_container.get_children():
		child.queue_free()

	# 显示已装备的连招槽位
	var slot_names := ["起手位", "主轴位", "变招位", "加成位", "扩展位"]
	for i in range(_get_max_slots()):
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(196, 92)
		var slot_texture = _load_combo_select_texture("combo_select_equipped_slot_frame")
		if slot_texture != null:
			var slot_art := TextureRect.new()
			slot_art.name = "EquippedSlotFrameArt"
			slot_art.set_anchors_preset(Control.PRESET_FULL_RECT)
			slot_art.texture = slot_texture
			slot_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			slot_art.stretch_mode = TextureRect.STRETCH_SCALE
			slot_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if i < selected_combos.size():
				slot_art.modulate = current_theme.get("good", Color(0.92, 1.0, 0.92, 1.0))
			slot_panel.add_child(slot_art)
			slot_panel.move_child(slot_art, 0)
		else:
			var style = StyleBoxFlat.new()
			style.corner_radius_top_left = 10
			style.corner_radius_top_right = 10
			style.corner_radius_bottom_left = 10
			style.corner_radius_bottom_right = 10

			if i < selected_combos.size():
				style.bg_color = current_theme.get("good", Color(0.2, 0.35, 0.2)).lerp(_theme_panel(), 0.68)
				style.border_color = current_theme.get("good", Color(0.4, 0.7, 0.4))
				style.set_border_width_all(2)
			else:
				style.bg_color = _theme_panel().darkened(0.04)
				style.border_color = _theme_accent().lerp(Color(0.4, 0.4, 0.5, 1.0), 0.35)
				style.set_border_width_all(2)

			slot_panel.add_theme_stylebox_override("panel", style)

		var slot_vbox = VBoxContainer.new()
		slot_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_vbox.offset_left = 8
		slot_vbox.offset_top = 8
		slot_vbox.offset_right = -8
		slot_vbox.offset_bottom = -8
		slot_vbox.add_theme_constant_override("separation", 4)
		slot_panel.add_child(slot_vbox)

		var slot_name_label = Label.new()
		slot_name_label.text = slot_names[min(i, slot_names.size() - 1)]
		slot_name_label.add_theme_font_size_override("font_size", 13)
		slot_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_name_label.modulate = _theme_accent().lerp(Color.WHITE, 0.15)
		slot_vbox.add_child(slot_name_label)

		var label = Label.new()
		label.add_theme_font_size_override("font_size", 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(0, 58)

		if i < selected_combos.size():
			var combo = combo_database.get_combo_by_id(selected_combos[i])
			if combo:
				label.text = "%s\n%s%s" % [
					_get_sequence_icons(combo.sequence),
					ComboDatabase.get_era_combo_name(combo.name),
					GameState.get_combo_upgrade_status_text(str(combo.id))
				]
				label.modulate = _theme_title().lerp(current_theme.get("good", Color(0.9, 1, 0.9)), 0.35)
			else:
				label.text = "错误"
				label.modulate = current_theme.get("bad", Color(1, 0.5, 0.5))
		else:
			label.text = "空槽位"
			label.modulate = _theme_accent().lerp(Color(0.45, 0.45, 0.45, 1.0), 0.55)

		slot_vbox.add_child(label)

		# 点击槽位取消装备
		var slot_index = i
		slot_panel.mouse_entered.connect(func():
			if slot_index < selected_combos.size():
				_update_detail_panel(selected_combos[slot_index])
		)
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
		start_button.modulate = current_theme.get("good", Color(0.7, 1, 0.7))
	_apply_action_button_feedback_state(start_button, start_button.is_hovered(), false)

func _on_back_pressed():
	DebugLog.log("[ComboSelect] Back pressed")
	# 发出返回信号，让 Main 处理场景切换
	back_pressed.emit()

func _on_start_pressed():
	DebugLog.log("[ComboSelect] Start pressed with combos: ", selected_combos)

	# 确保至少选择了1个连招
	if selected_combos.size() < 1:
		DebugLog.log("[ComboSelect] No combos selected!")
		return

	# 保存已选连招到 GameState（实际上已经在 GameState 中了）
	dispose_runtime_cache()
	# 发送完成信号，让 Main 处理场景切换
	combo_selection_complete.emit()

func _ensure_action_button_feedback(btn: Button) -> void:
	if btn == null or bool(btn.get_meta("feedback_connected", false)):
		return
	action_button_states[btn.get_instance_id()] = {"hovered": false, "pressed": false}
	btn.mouse_entered.connect(_on_action_button_mouse_entered.bind(btn))
	btn.mouse_exited.connect(_on_action_button_mouse_exited.bind(btn))
	btn.button_down.connect(_on_action_button_down.bind(btn))
	btn.button_up.connect(_on_action_button_up.bind(btn))
	btn.set_meta("feedback_connected", true)
	btn.set_meta("base_scale", btn.scale)
	btn.set_meta("base_position", btn.position)

func _apply_action_button_feedback_state(btn: Button, hovered: bool, pressed: bool) -> void:
	if btn == null:
		return
	action_button_states[btn.get_instance_id()] = {"hovered": hovered, "pressed": pressed}
	var base_scale: Vector2 = btn.get_meta("base_scale", Vector2.ONE)
	var base_position: Vector2 = btn.get_meta("base_position", btn.position)
	if btn.disabled:
		btn.scale = base_scale
		btn.position = base_position
		btn.modulate = Color(0.60, 0.60, 0.64, 0.94)
		return
	btn.modulate = Color.WHITE
	if pressed:
		btn.scale = base_scale * 0.95
		btn.position = base_position + Vector2(0, 4)
	elif hovered:
		btn.scale = base_scale * 1.06
		btn.position = base_position + Vector2(0, -3)
	else:
		btn.scale = base_scale
		btn.position = base_position

func _on_action_button_mouse_entered(btn: Button) -> void:
	_apply_action_button_feedback_state(btn, true, false)

func _on_action_button_mouse_exited(btn: Button) -> void:
	_apply_action_button_feedback_state(btn, false, false)

func _on_action_button_down(btn: Button) -> void:
	_apply_action_button_feedback_state(btn, true, true)

func _on_action_button_up(btn: Button) -> void:
	_apply_action_button_feedback_state(btn, btn.get_rect().has_point(btn.get_local_mouse_position()), false)
