extends Control

# CharacterSelect - 角色选择界面
# 注意：不使用 class_name 以避免解析问题

signal character_selected(class_id: int)
signal back_pressed

@onready var back_button: Button = $BackButton
@onready var background: ColorRect = $Background
@onready var title_label: Label = $TitleLabel
@onready var combo_panel: Panel = $ComboPanel
@onready var combo_panel_bg: ColorRect = $ComboPanel/ComboPanelBg
@onready var combo_title: Label = $ComboPanel/ComboTitle
@onready var combo_list: VBoxContainer = $ComboPanel/ComboList
@onready var combo_scroll: ScrollContainer = null

var current_class_id: int = -1
var selected_class_id: int = -1
var combo_script = null
var player_class_script = null
var tooltip_popup: Control = null
var current_theme: Dictionary = {}

func _load_texture_resource(texture_path: String) -> Texture2D:
	if texture_path == "":
		return null
	if ResourceLoader.exists(texture_path):
		var resource = load(texture_path)
		return resource as Texture2D
	var image = Image.load_from_file(ProjectSettings.globalize_path(texture_path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _ready():
	DebugLog.log("CharacterSelect _ready")
	current_theme = GameState.get_era_theme()
	
	# 加载脚本
	combo_script = load("res://resources/combo_data.gd")
	player_class_script = load("res://resources/player_class_data.gd")
	_apply_era_theme()
	_configure_layout()
	
	var class_count = player_class_script.get_all_classes().size()
	for i in range(class_count):
		var btn: Button = get_node_or_null("Char%d" % i)
		if btn:
			var class_data = player_class_script.get_class_data(i)
			var display_name = player_class_script.get_class_display_name(i)
			btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.text = ""
			btn.tooltip_text = ""
			var locked = i == 4 and not GameState.has_meta_upgrade("new_character")
			if i == 4 and not GameState.has_meta_upgrade("new_character"):
				btn.disabled = true
			_apply_class_button_theme(btn, locked)
			_set_class_button_content(btn, i, display_name, int(class_data.get("hp", 0)), int(class_data.get("atk", 0)), locked)
			btn.pressed.connect(_on_class_selected.bind(i))
			btn.mouse_entered.connect(_on_class_hovered.bind(i))
			DebugLog.log("Connected button Char", i)
		else:
			DebugLog.log("ERROR: Button Char", i, " not found!")
	
	# 连接返回按钮
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		_ensure_action_button_feedback(back_button)
	else:
		DebugLog.log("ERROR: BackButton not found!")
	
	selected_class_id = 0
	current_class_id = 0
	call_deferred("_refresh_character_select_view")

func _exit_tree() -> void:
	_hide_class_tooltip()
	if combo_script != null and combo_script.has_method("clear_combo_db_cache"):
		combo_script.clear_combo_db_cache()

func _apply_era_theme() -> void:
	var accent: Color = current_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	var title_color: Color = current_theme.get("title", Color(0.94, 0.84, 0.66, 1.0))
	var panel_color: Color = current_theme.get("panel", Color(0.20, 0.16, 0.12, 0.9))
	if background:
		background.color = current_theme.get("bg", Color(0.12, 0.11, 0.10, 1.0))
		var bg_texture := background.get_node_or_null("CharacterSelectBackground") as TextureRect
		if bg_texture == null:
			bg_texture = TextureRect.new()
			bg_texture.name = "CharacterSelectBackground"
			bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			background.add_child(bg_texture)
			background.move_child(bg_texture, 0)
		bg_texture.texture = _load_texture_resource(ArtRegistry.get_era_ui_path("character_select_bg"))
		bg_texture.modulate = Color(1, 1, 1, 0.96)
		for overlay_name in ["TitleBack", "EraTopBar", "EraBottomBar", "BottomPlate"]:
			var overlay := background.get_node_or_null(overlay_name)
			if overlay != null:
				overlay.queue_free()
		_ensure_era_seal(accent, title_color, panel_color)
	if title_label:
		title_label.text = "%s · 群英名册" % GameState.get_current_era_definition().get("name", "秦")
		title_label.modulate = title_color
		title_label.add_theme_color_override("font_outline_color", current_theme.get("bg", Color(0.12, 0.11, 0.10, 1.0)).darkened(0.2))
		title_label.add_theme_constant_override("outline_size", 1)
	if combo_panel_bg:
		combo_panel_bg.color = Color(0, 0, 0, 0)
	if combo_panel:
		var dossier_frame_art := combo_panel.get_node_or_null("DossierFrameArt") as TextureRect
		if dossier_frame_art == null:
			dossier_frame_art = TextureRect.new()
			dossier_frame_art.name = "DossierFrameArt"
			dossier_frame_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dossier_frame_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			dossier_frame_art.stretch_mode = TextureRect.STRETCH_SCALE
			combo_panel.add_child(dossier_frame_art)
			combo_panel.move_child(dossier_frame_art, 0)
		dossier_frame_art.texture = _load_texture_resource(_get_character_dossier_frame_path())
		dossier_frame_art.position = Vector2(-28, -18)
		dossier_frame_art.size = Vector2(548, 560)
		dossier_frame_art.z_index = 0
		var combo_style := StyleBoxFlat.new()
		combo_style.bg_color = Color(0, 0, 0, 0)
		combo_style.border_color = Color(0, 0, 0, 0)
		combo_style.border_width_left = 0
		combo_style.border_width_top = 0
		combo_style.border_width_right = 0
		combo_style.border_width_bottom = 0
		combo_style.corner_radius_top_left = 0
		combo_style.corner_radius_top_right = 0
		combo_style.corner_radius_bottom_right = 0
		combo_style.corner_radius_bottom_left = 0
		combo_panel.add_theme_stylebox_override("panel", combo_style)
	if combo_title:
		combo_title.z_index = 10
		combo_title.add_theme_color_override("font_outline_color", current_theme.get("bg", Color(0.12, 0.11, 0.10, 1.0)).darkened(0.2))
		combo_title.add_theme_constant_override("outline_size", 1)
	if back_button:
		back_button.text = ""
		back_button.flat = true
		back_button.modulate = Color.WHITE
		var back_style := StyleBoxFlat.new()
		back_style.bg_color = Color(0, 0, 0, 0)
		back_style.border_color = Color(0, 0, 0, 0)
		back_style.set_border_width_all(0)
		back_style.content_margin_left = 0
		back_style.content_margin_right = 0
		back_style.content_margin_top = 0
		back_style.content_margin_bottom = 0
		var back_hover := back_style.duplicate()
		var back_pressed := back_style.duplicate()
		back_button.add_theme_stylebox_override("normal", back_style)
		back_button.add_theme_stylebox_override("hover", back_hover)
		back_button.add_theme_stylebox_override("pressed", back_pressed)
		back_button.add_theme_stylebox_override("focus", back_hover)
		var back_art := _ensure_back_button_art(back_button)
		if back_art != null:
			back_art.modulate = Color.WHITE
		var back_label := back_button.get_node_or_null("BackLabel") as Label
		if back_label == null:
			back_label = Label.new()
			back_label.name = "BackLabel"
			back_button.add_child(back_label)
		back_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		back_label.offset_left = 0
		back_label.offset_top = 0
		back_label.offset_right = 0
		back_label.offset_bottom = 0
		back_label.position = Vector2(-64, -6)
		back_label.text = "返回"
		back_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		back_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		back_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back_label.z_index = 8
		back_label.add_theme_font_size_override("font_size", 24)
		back_label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.90, 1.0))
		back_label.add_theme_color_override("font_outline_color", Color(0.10, 0.07, 0.05, 0.98))
		back_label.add_theme_constant_override("outline_size", 4)
		back_label.set_meta("base_position", back_label.position)
		_apply_action_button_feedback_state(back_button, false, false)

func _configure_layout() -> void:
	if title_label:
		title_label.position = Vector2(414, 54)
		title_label.size = Vector2(452, 48)
	if back_button:
		back_button.position = Vector2(48, 650)
		back_button.size = Vector2(296, 88)
		back_button.custom_minimum_size = back_button.size
	combo_panel.position = Vector2(744, 136)
	combo_panel.size = Vector2(492, 520)
	combo_title.position = Vector2(28, 72)
	combo_title.size = Vector2(404, 32)
	combo_title.add_theme_font_size_override("font_size", 26)
	_ensure_role_description_layer()
	_ensure_detail_scroll()
	combo_scroll.position = Vector2(48, 178)
	combo_scroll.size = Vector2(396, 306)
	combo_list.position = Vector2.ZERO
	combo_list.size = Vector2(388, 0)
	combo_list.custom_minimum_size = Vector2(388, 0)
	combo_list.add_theme_constant_override("separation", 2)

	var start_y := 144.0
	for i in range(player_class_script.get_all_classes().size()):
		var btn: Button = get_node_or_null("Char%d" % i)
		if btn == null:
			continue
		btn.position = Vector2(36, start_y + i * 104.0)
		btn.size = Vector2(272, 94)
		btn.custom_minimum_size = btn.size

	_ensure_preview_panel()
	_ensure_detail_footer()

func _ensure_detail_scroll() -> void:
	if combo_panel == null or combo_list == null:
		return
	if combo_scroll == null or not is_instance_valid(combo_scroll):
		combo_scroll = combo_panel.get_node_or_null("ComboScroll") as ScrollContainer
	if combo_scroll == null:
		combo_scroll = ScrollContainer.new()
		combo_scroll.name = "ComboScroll"
		combo_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		combo_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		combo_panel.add_child(combo_scroll)
		combo_panel.move_child(combo_scroll, combo_panel.get_children().find(combo_title) + 1)
	if combo_list.get_parent() != combo_scroll:
		var old_parent := combo_list.get_parent()
		if old_parent != null:
			old_parent.remove_child(combo_list)
		combo_scroll.add_child(combo_list)

func _ensure_role_description_layer() -> void:
	if combo_panel == null:
		return
	var art := combo_panel.get_node_or_null("RoleDescriptionArt") as TextureRect
	if art == null:
		art = TextureRect.new()
		art.name = "RoleDescriptionArt"
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		combo_panel.add_child(art)
		combo_panel.move_child(art, combo_panel.get_children().find(combo_title) + 1)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.texture = _load_texture_resource(_get_character_dossier_panel_path())
	art.position = Vector2(74, 42)
	art.size = Vector2(320, 96)
	art.z_index = 5

	var body := combo_panel.get_node_or_null("RoleDescriptionBody") as Label
	if body == null:
		body = Label.new()
		body.name = "RoleDescriptionBody"
		combo_panel.add_child(body)
	body.position = Vector2(148, 74)
	body.size = Vector2(180, 60)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.95, 0.92, 0.86, 1.0))
	body.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06, 0.9))
	body.add_theme_constant_override("outline_size", 2)
	body.z_index = 7
	body.visible = true
	art.visible = true

func _ensure_preview_panel() -> void:
	var preview_panel := get_node_or_null("PreviewPanel") as PanelContainer
	if preview_panel == null:
		preview_panel = PanelContainer.new()
		preview_panel.name = "PreviewPanel"
		add_child(preview_panel)
	var roster_count := 0
	if player_class_script != null:
		roster_count = player_class_script.get_all_classes().size()
	var roster_start_y := 144.0
	var roster_spacing := 104.0
	var roster_button_height := 94.0
	var roster_art_height := roster_button_height * 1.72
	var roster_total_height := roster_art_height
	if roster_count > 1:
		roster_total_height = roster_art_height + (roster_count - 1) * roster_spacing
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	preview_panel.add_theme_stylebox_override("panel", style)
	preview_panel.position = Vector2(320, roster_start_y - (roster_art_height - roster_button_height) * 0.5)
	preview_panel.size = Vector2(392, roster_total_height)

	var card_art := preview_panel.get_node_or_null("PreviewCardArt") as TextureRect
	if card_art == null:
		card_art = TextureRect.new()
		card_art.name = "PreviewCardArt"
		card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_art.stretch_mode = TextureRect.STRETCH_SCALE
		preview_panel.add_child(card_art)
		preview_panel.move_child(card_art, 0)
	card_art.texture = _load_texture_resource(_get_character_preview_card_path())
	card_art.size = preview_panel.size
	card_art.position = Vector2.ZERO

	var portrait := preview_panel.get_node_or_null("PreviewPortrait") as TextureRect
	if portrait == null:
		portrait = TextureRect.new()
		portrait.name = "PreviewPortrait"
		preview_panel.add_child(portrait)
	portrait.position = Vector2(24, -72)
	portrait.custom_minimum_size = Vector2(344, 248)
	portrait.size = portrait.custom_minimum_size
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var summary_panel := preview_panel.get_node_or_null("PreviewSummaryPanel") as PanelContainer
	if summary_panel == null:
		summary_panel = PanelContainer.new()
		summary_panel.name = "PreviewSummaryPanel"
		preview_panel.add_child(summary_panel)
	var summary_style := StyleBoxFlat.new()
	summary_style.bg_color = Color(0, 0, 0, 0)
	summary_style.border_color = Color(0, 0, 0, 0)
	summary_style.set_border_width_all(0)
	summary_panel.add_theme_stylebox_override("panel", summary_style)
	summary_panel.position = Vector2(24, 274)
	summary_panel.size = Vector2(344, 212)
	summary_panel.z_index = 12

	var stats_art := summary_panel.get_node_or_null("PreviewStatsArt") as TextureRect
	if stats_art == null:
		stats_art = TextureRect.new()
		stats_art.name = "PreviewStatsArt"
		stats_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		summary_panel.add_child(stats_art)
		summary_panel.move_child(stats_art, 0)
	stats_art.position = Vector2(18, 48)
	stats_art.size = Vector2(300, 104)
	stats_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stats_art.stretch_mode = TextureRect.STRETCH_SCALE
	stats_art.texture = _load_texture_resource(_get_character_dossier_panel_path())
	stats_art.z_index = 2
	stats_art.visible = false

	var name_label := preview_panel.get_node_or_null("PreviewName") as Label
	if name_label == null:
		name_label = Label.new()
		name_label.name = "PreviewName"
		summary_panel.add_child(name_label)
	elif name_label.get_parent() != summary_panel:
		name_label.get_parent().remove_child(name_label)
		summary_panel.add_child(name_label)
	name_label.position = Vector2(18, 14)
	name_label.size = Vector2(308, 34)
	name_label.z_index = 3
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)

	var stat_label := preview_panel.get_node_or_null("PreviewStats") as Label
	if stat_label == null:
		stat_label = Label.new()
		stat_label.name = "PreviewStats"
		add_child(stat_label)
	elif stat_label.get_parent() != self:
		stat_label.get_parent().remove_child(stat_label)
		add_child(stat_label)
	stat_label.position = preview_panel.position + Vector2(148, 420)
	stat_label.size = Vector2(308, 78)
	stat_label.z_index = 30
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stat_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	stat_label.add_theme_font_size_override("font_size", 20)
	stat_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.86, 1.0))
	stat_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06, 0.96))
	stat_label.add_theme_constant_override("outline_size", 3)
	stat_label.visible = true

	var summary_label := preview_panel.get_node_or_null("PreviewSummary") as Label
	if summary_label == null:
		summary_label = Label.new()
		summary_label.name = "PreviewSummary"
		summary_panel.add_child(summary_label)
	elif summary_label.get_parent() != summary_panel:
		summary_label.get_parent().remove_child(summary_label)
		summary_panel.add_child(summary_label)
	summary_label.position = Vector2(18, 132)
	summary_label.size = Vector2(308, 70)
	summary_label.z_index = 3
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	summary_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	summary_label.add_theme_font_size_override("font_size", 17)

func _ensure_detail_footer() -> void:
	var note := get_node_or_null("SelectHint") as Label
	if note != null:
		note.queue_free()

	var confirm := get_node_or_null("ConfirmButton") as Button
	if confirm == null:
		confirm = Button.new()
		confirm.name = "ConfirmButton"
		add_child(confirm)
		confirm.pressed.connect(_confirm_current_class)
	confirm.size = Vector2(222, 82)
	confirm.custom_minimum_size = confirm.size
	var confirm_x := 1010.0
	var confirm_y := 650.0
	if back_button != null:
		var viewport_width := get_viewport_rect().size.x
		confirm_x = viewport_width - back_button.position.x - confirm.size.x
		confirm_y = back_button.position.y
	confirm.position = Vector2(confirm_x, confirm_y)
	confirm.text = ""
	confirm.flat = true
	var art_frame := _ensure_confirm_button_art(confirm)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	var hover := style.duplicate()
	confirm.add_theme_stylebox_override("normal", style)
	confirm.add_theme_stylebox_override("hover", hover)
	confirm.add_theme_stylebox_override("pressed", style)
	confirm.add_theme_stylebox_override("focus", hover)
	if art_frame != null:
		art_frame.set_meta("base_position", art_frame.position)
		art_frame.modulate = Color(0.55, 0.55, 0.58, 0.9) if confirm.disabled else Color.WHITE
	var confirm_label := confirm.get_node_or_null("ConfirmLabel") as Label
	if confirm_label == null:
		confirm_label = Label.new()
		confirm_label.name = "ConfirmLabel"
		confirm.add_child(confirm_label)
	confirm_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_label.offset_left = 0
	confirm_label.offset_top = 0
	confirm_label.offset_right = 0
	confirm_label.offset_bottom = 0
	confirm_label.text = "确认开局"
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	confirm_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confirm_label.z_index = 8
	confirm_label.position = Vector2(0, 4)
	confirm_label.add_theme_font_size_override("font_size", 24)
	confirm_label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.90, 1.0))
	confirm_label.add_theme_color_override("font_outline_color", Color(0.10, 0.07, 0.05, 0.98))
	confirm_label.add_theme_constant_override("outline_size", 4)
	confirm_label.set_meta("base_position", confirm_label.position)
	confirm_label.modulate = Color(0.72, 0.72, 0.74, 0.92) if confirm.disabled else Color.WHITE
	_ensure_action_button_feedback(confirm)
	_apply_action_button_feedback_state(confirm, false, false)

func _ensure_era_seal(accent: Color, title_color: Color, panel_color: Color) -> void:
	if background == null:
		return
	var seal = background.get_node_or_null("EraSeal") as Panel
	if seal == null:
		seal = Panel.new()
		seal.name = "EraSeal"
		background.add_child(seal)
	var stylebox = seal.get_theme_stylebox("panel") as StyleBoxFlat
	if stylebox == null:
		stylebox = StyleBoxFlat.new()
		seal.add_theme_stylebox_override("panel", stylebox)
	stylebox.bg_color = Color(0, 0, 0, 0)
	stylebox.border_color = Color(0, 0, 0, 0)
	stylebox.set_border_width_all(0)
	var seal_texture := seal.get_node_or_null("Texture") as TextureRect
	if seal_texture == null:
		seal_texture = TextureRect.new()
		seal_texture.name = "Texture"
		seal_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal.add_child(seal_texture)
		seal.move_child(seal_texture, 0)
	var seal_label_ref = seal.get_node_or_null("Label") as Label
	if seal_label_ref == null:
		seal_label_ref = Label.new()
		seal_label_ref.name = "Label"
		seal_label_ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal_label_ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		seal_label_ref.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		seal.add_child(seal_label_ref)
	var seal_tex := _load_texture_resource(ArtRegistry.get_era_ui_path("main_menu_seal"))
	seal_texture.texture = seal_tex
	seal_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seal_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if GameState.selected_era_id == "song":
		seal.position = Vector2(774, 6)
		seal.size = Vector2(260, 128)
		seal_texture.position = Vector2.ZERO
		seal_texture.size = seal.size
		seal_label_ref.position = Vector2(4, -6)
		seal_label_ref.size = seal.size
		seal_label_ref.text = "宋"
		seal_label_ref.add_theme_color_override("font_color", Color(0.30, 0.34, 0.36, 1.0))
		seal_label_ref.add_theme_color_override("font_outline_color", Color(0.88, 0.82, 0.70, 0.94))
	elif GameState.selected_era_id == "china":
		seal.position = Vector2(810, 18)
		seal.size = Vector2(188, 92)
		seal_texture.position = Vector2.ZERO
		seal_texture.size = seal.size
		seal_label_ref.position = Vector2.ZERO
		seal_label_ref.size = seal.size
		seal_label_ref.text = "中"
		seal_label_ref.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62, 1.0))
		seal_label_ref.add_theme_color_override("font_outline_color", Color(0.14, 0.08, 0.04, 0.96))
	else:
		seal.position = Vector2(810, 18)
		seal.size = Vector2(188, 92)
		seal_texture.position = Vector2.ZERO
		seal_texture.size = seal.size
		seal_label_ref.position = Vector2(40, 18)
		seal_label_ref.size = Vector2(108, 48)
		seal_label_ref.text = "秦"
		seal_label_ref.add_theme_color_override("font_color", Color(0.92, 0.82, 0.58, 1.0))
		seal_label_ref.add_theme_color_override("font_outline_color", Color(0.14, 0.08, 0.04, 0.96))
	seal_label_ref.add_theme_font_size_override("font_size", 30)
	seal_label_ref.add_theme_constant_override("outline_size", 2)
	seal_label_ref.visible = true

func _apply_class_button_theme(btn: Button, locked: bool) -> void:
	var accent: Color = current_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	var title_color: Color = current_theme.get("title", Color(0.95, 0.88, 0.72, 1.0))
	var bg_color: Color = current_theme.get("bg", Color(0.12, 0.11, 0.10, 1.0))
	var art_frame := _ensure_class_button_art(btn)
	btn.modulate = Color(1, 1, 1, 1)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_color = Color(0, 0, 0, 0)
	normal.content_margin_left = 0
	normal.content_margin_right = 0
	normal.content_margin_top = 0
	normal.content_margin_bottom = 0
	var hover := normal.duplicate()
	var pressed := normal.duplicate()
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_color_override("font_color", title_color)
	btn.add_theme_color_override("font_hover_color", title_color)
	btn.add_theme_color_override("font_pressed_color", title_color)
	btn.add_theme_color_override("font_outline_color", bg_color.darkened(0.2))
	btn.add_theme_constant_override("outline_size", 1)
	btn.add_theme_constant_override("h_separation", 0)
	btn.add_theme_constant_override("v_separation", 0)
	_apply_class_button_visual_state(btn, false, false, locked)

func _get_character_roster_button_path() -> String:
	match GameState.selected_era_id:
		"song":
			return "res://assets/ui/song/buttons/song_character_roster_button.png"
		"china":
			return "res://assets/ui/china/buttons/china_character_roster_button.png"
		_:
			return "res://assets/ui/qin/buttons/qin_character_roster_button.png"

func _get_confirm_button_path() -> String:
	match GameState.selected_era_id:
		"song":
			return "res://assets/ui/song/buttons/song_confirm_start_button.png"
		"china":
			return "res://assets/ui/china/buttons/china_confirm_start_button.png"
		_:
			return "res://assets/ui/qin/buttons/qin_confirm_start_button.png"

func _get_back_button_path() -> String:
	match GameState.selected_era_id:
		"song":
			return "res://assets/ui/song/buttons/song_back_button.png"
		"china":
			return "res://assets/ui/china/buttons/china_back_button.png"
		_:
			return "res://assets/ui/qin/buttons/qin_back_button.png"

func _get_character_preview_card_path() -> String:
	match GameState.selected_era_id:
		"song":
			return "res://assets/ui/song/cards/song_character_card.png"
		"china":
			return "res://assets/ui/china/cards/china_character_card.png"
		_:
			return "res://assets/ui/qin/cards/qin_character_card.png"

func _get_character_dossier_panel_path() -> String:
	match GameState.selected_era_id:
		"song":
			return "res://assets/ui/song/cards/song_character_dossier_panel.png"
		"china":
			return "res://assets/ui/china/cards/china_character_dossier_panel.png"
		_:
			return "res://assets/ui/qin/cards/qin_character_dossier_panel.png"

func _get_character_dossier_frame_path() -> String:
	match GameState.selected_era_id:
		"song":
			return "res://assets/ui/song/cards/song_character_dossier_frame.png"
		"china":
			return "res://assets/ui/china/cards/china_character_dossier_frame.png"
		_:
			return "res://assets/ui/qin/cards/qin_character_dossier_frame.png"

func _get_combo_layout_frame_path() -> String:
	match GameState.selected_era_id:
		"song":
			return "res://assets/ui/song/cards/song_combo_layout_frame.png"
		"china":
			return "res://assets/ui/china/cards/china_combo_layout_frame.png"
		_:
			return "res://assets/ui/qin/cards/qin_combo_layout_frame.png"

func _ensure_class_button_art(btn: Button) -> TextureRect:
	if btn == null:
		return null
	var art_frame := btn.get_node_or_null("RosterArtFrame") as TextureRect
	if art_frame == null:
		art_frame = TextureRect.new()
		art_frame.name = "RosterArtFrame"
		art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_frame.stretch_mode = TextureRect.STRETCH_SCALE
		btn.add_child(art_frame)
		btn.move_child(art_frame, 0)
	art_frame.texture = _load_texture_resource(_get_character_roster_button_path())
	var button_size := btn.size
	if button_size.x <= 0 or button_size.y <= 0:
		button_size = btn.custom_minimum_size
	var art_size := Vector2(button_size.x * 1.16, button_size.y * 1.72)
	art_frame.size = art_size
	art_frame.position = Vector2((button_size.x - art_size.x) * 0.5, (button_size.y - art_size.y) * 0.5 - 6.0)
	return art_frame

func _ensure_confirm_button_art(btn: Button) -> TextureRect:
	if btn == null:
		return null
	var art_frame := btn.get_node_or_null("ConfirmArtFrame") as TextureRect
	if art_frame == null:
		art_frame = TextureRect.new()
		art_frame.name = "ConfirmArtFrame"
		art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_frame.stretch_mode = TextureRect.STRETCH_SCALE
		btn.add_child(art_frame)
		btn.move_child(art_frame, 0)
	art_frame.texture = _load_texture_resource(_get_confirm_button_path())
	art_frame.position = Vector2.ZERO
	art_frame.size = btn.size
	return art_frame

func _ensure_back_button_art(btn: Button) -> TextureRect:
	if btn == null:
		return null
	var art_frame := btn.get_node_or_null("BackArtFrame") as TextureRect
	if art_frame == null:
		art_frame = TextureRect.new()
		art_frame.name = "BackArtFrame"
		art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_frame.stretch_mode = TextureRect.STRETCH_SCALE
		btn.add_child(art_frame)
		btn.move_child(art_frame, 0)
	art_frame.texture = _load_texture_resource(_get_back_button_path())
	var button_size := btn.size
	if button_size.x <= 0 or button_size.y <= 0:
		button_size = btn.custom_minimum_size
	var art_size := Vector2(button_size.x * 1.70, button_size.y * 1.98)
	art_frame.size = art_size
	art_frame.position = Vector2(
		(button_size.x - art_size.x) * 0.5 + 18.0,
		(button_size.y - art_size.y) * 0.5 + 16.0
	)
	art_frame.set_meta("base_position", art_frame.position)
	return art_frame

func _ensure_action_button_feedback(btn: Button) -> void:
	if btn == null or bool(btn.get_meta("feedback_connected", false)):
		return
	btn.mouse_entered.connect(_on_action_button_mouse_entered.bind(btn))
	btn.mouse_exited.connect(_on_action_button_mouse_exited.bind(btn))
	btn.button_down.connect(_on_action_button_down.bind(btn))
	btn.button_up.connect(_on_action_button_up.bind(btn))
	btn.set_meta("feedback_connected", true)

func _get_action_button_art(btn: Button) -> CanvasItem:
	if btn == null:
		return null
	var art = btn.get_node_or_null("ConfirmArtFrame") as CanvasItem
	if art == null:
		art = btn.get_node_or_null("BackArtFrame") as CanvasItem
	return art

func _get_action_button_label(btn: Button) -> Control:
	if btn == null:
		return null
	var label = btn.get_node_or_null("ConfirmLabel") as Control
	if label == null:
		label = btn.get_node_or_null("BackLabel") as Control
	return label

func _apply_action_button_feedback_state(btn: Button, hovered: bool, pressed: bool) -> void:
	if btn == null:
		return
	var art := _get_action_button_art(btn)
	var label := _get_action_button_label(btn)
	var base_art_position := Vector2.ZERO
	var base_label_position := Vector2.ZERO
	if art != null and art.has_meta("base_position"):
		base_art_position = art.get_meta("base_position")
	if label != null and label.has_meta("base_position"):
		base_label_position = label.get_meta("base_position")
	if btn.disabled:
		if art != null:
			art.scale = Vector2.ONE
			art.position = base_art_position
			art.modulate = Color(0.55, 0.55, 0.58, 0.9)
		if label != null:
			label.position = base_label_position
			label.modulate = Color(0.72, 0.72, 0.74, 0.92)
		return
	if art != null:
		if pressed:
			art.scale = Vector2(0.95, 0.95)
			art.position = base_art_position + Vector2(0, 4)
			art.modulate = Color(0.86, 0.84, 0.80, 1.0)
		elif hovered:
			art.scale = Vector2(1.07, 1.07)
			art.position = base_art_position + Vector2(0, -3)
			art.modulate = Color(1.14, 1.10, 1.06, 1.0)
		else:
			art.scale = Vector2.ONE
			art.position = base_art_position
			art.modulate = Color.WHITE
	if label != null:
		if pressed:
			label.position = base_label_position + Vector2(0, 4)
		elif hovered:
			label.position = base_label_position + Vector2(0, -3)
		else:
			label.position = base_label_position
		label.modulate = Color.WHITE

func _on_action_button_mouse_entered(btn: Button) -> void:
	_apply_action_button_feedback_state(btn, true, false)

func _on_action_button_mouse_exited(btn: Button) -> void:
	_apply_action_button_feedback_state(btn, false, false)

func _on_action_button_down(btn: Button) -> void:
	_apply_action_button_feedback_state(btn, true, true)

func _on_action_button_up(btn: Button) -> void:
	_apply_action_button_feedback_state(btn, btn.get_rect().has_point(btn.get_local_mouse_position()), false)

func _get_class_button_visual_strength(btn: Button) -> float:
	if btn == null:
		return 1.0
	var button_size := btn.size
	if button_size.x <= 0 or button_size.y <= 0:
		button_size = btn.custom_minimum_size
	var width_factor := clampf(button_size.x / 272.0, 0.85, 1.35)
	var height_factor := clampf(button_size.y / 94.0, 0.85, 1.35)
	return (width_factor + height_factor) * 0.5

func _apply_class_button_visual_state(btn: Button, selected: bool, hovered: bool, locked: bool) -> void:
	if btn == null:
		return
	var art_frame := btn.get_node_or_null("RosterArtFrame") as TextureRect
	var content := btn.get_node_or_null("Content") as CanvasItem
	var base_content_offset_x := 0.0
	var base_content_offset_y := 0.0
	if content != null and content.has_meta("base_offset_x"):
		base_content_offset_x = float(content.get_meta("base_offset_x"))
	if content != null and content.has_meta("base_offset_y"):
		base_content_offset_y = float(content.get_meta("base_offset_y"))
	var strength := _get_class_button_visual_strength(btn)
	var hover_gain := 0.04 * strength
	var selected_gain := 0.08 * strength
	var hover_lift := 2.0 * strength
	var selected_lift := 4.0 * strength
	var hover_scale := 1.0 + 0.012 * strength
	var selected_scale := 1.0 + 0.022 * strength
	var art_modulate := Color.WHITE
	if locked:
		art_modulate = Color(0.55, 0.55, 0.58, 0.94)
	elif selected:
		art_modulate = Color(1.0 + selected_gain, 0.98 + selected_gain * 0.5, 0.94 + selected_gain * 0.35, 1.0)
	elif hovered:
		art_modulate = Color(1.0 + hover_gain, 0.99 + hover_gain * 0.35, 0.97 + hover_gain * 0.2, 1.0)
	if art_frame != null:
		art_frame.modulate = art_modulate
		if locked:
			art_frame.scale = Vector2.ONE
			art_frame.position.y = (btn.size.y - art_frame.size.y) * 0.5 - 6.0
		elif selected:
			art_frame.scale = Vector2(selected_scale, selected_scale)
			art_frame.position.y = (btn.size.y - art_frame.size.y) * 0.5 - 6.0 - selected_lift
		elif hovered:
			art_frame.scale = Vector2(hover_scale, hover_scale)
			art_frame.position.y = (btn.size.y - art_frame.size.y) * 0.5 - 6.0 - hover_lift
		else:
			art_frame.scale = Vector2.ONE
			art_frame.position.y = (btn.size.y - art_frame.size.y) * 0.5 - 6.0
		art_frame.position.x = (btn.size.x - art_frame.size.x) * 0.5
	if content != null:
		if locked:
			content.modulate = Color(0.82, 0.82, 0.84, 0.96)
			content.position = Vector2(base_content_offset_x, base_content_offset_y)
		elif selected:
			content.modulate = Color(1.0, 1.0, 1.0, 1.0)
			content.position = Vector2(base_content_offset_x, base_content_offset_y - selected_lift * 0.35)
		elif hovered:
			content.modulate = Color(0.99 + hover_gain * 0.2, 0.99 + hover_gain * 0.15, 0.99 + hover_gain * 0.1, 1.0)
			content.position = Vector2(base_content_offset_x, base_content_offset_y - hover_lift * 0.3)
		else:
			content.modulate = Color.WHITE
			content.position = Vector2(base_content_offset_x, base_content_offset_y)

func _set_class_button_content(btn: Button, class_id: int, display_name: String, hp: int, atk: int, locked: bool) -> void:
	var old = btn.get_node_or_null("Content")
	if old:
		old.queue_free()
	var button_size := btn.size
	if button_size.x <= 0 or button_size.y <= 0:
		button_size = btn.custom_minimum_size
	var inset_x := clampf(button_size.x * 0.08, 18.0, 26.0)
	var inset_y := clampf(button_size.y * 0.16, 12.0, 18.0)
	var portrait_size := clampf(button_size.y - inset_y * 2.0, 60.0, 76.0)
	var content = HBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = inset_x
	content.offset_top = inset_y
	content.offset_right = -inset_x
	content.offset_bottom = -inset_y
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	content.set_meta("base_offset_x", 8.0)
	content.set_meta("base_offset_y", 12.0)
	btn.add_child(content)

	var portrait = TextureRect.new()
	portrait.name = "Portrait"
	var texture_path = ArtRegistry.get_character_select_path(class_id)
	portrait.texture = _load_portrait_texture(texture_path)
	portrait.custom_minimum_size = Vector2(portrait_size, portrait_size)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if locked:
		portrait.modulate = Color(0.55, 0.55, 0.58, 0.92)
	content.add_child(portrait)

	var text_col = VBoxContainer.new()
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.custom_minimum_size = Vector2(maxf(button_size.x - portrait_size - inset_x * 2.0 - 20.0, 148.0), 0)
	text_col.add_theme_constant_override("separation", 2)
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(text_col)

	var name_label = Label.new()
	name_label.text = ("%s %s" % [_get_class_icon(class_id), display_name]) if not locked else "🔒 流浪者"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86, 1.0))
	name_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06, 0.92))
	name_label.add_theme_constant_override("outline_size", 3)
	name_label.modulate = Color.WHITE
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.add_child(name_label)

	var stats_label = Label.new()
	stats_label.text = ("生命:%d 攻击:%d" % [hp, atk]) if not locked else "需要国运秘库"
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.90, 0.86, 0.78, 1.0))
	stats_label.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06, 0.9))
	stats_label.add_theme_constant_override("outline_size", 2)
	stats_label.modulate = Color.WHITE
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.add_child(stats_label)

func _load_portrait_texture(texture_path: String) -> Texture2D:
	if texture_path == "":
		return null
	var image = Image.load_from_file(ProjectSettings.globalize_path(texture_path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _on_class_hovered(class_id: int):
	current_class_id = class_id
	_refresh_character_select_view()

func _on_class_selected(class_id: int):
	DebugLog.log("Character selected from UI: ", class_id)
	selected_class_id = class_id
	current_class_id = class_id
	_refresh_character_select_view()

func _on_back_pressed():
	DebugLog.log("Back pressed")
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
	var display_name = player_class_script.get_class_display_name(class_id)
	var display_desc = player_class_script.get_class_display_desc(class_id)
	var locked_text = ""
	if class_id == 4 and not GameState.has_meta_upgrade("new_character"):
		locked_text = "\n解锁条件：国运秘库「新角色解锁」"
	var text = "%s\n生命：%d  攻击：%d\n专属被动：%s%s" % [
		display_name,
		int(class_data.get("hp", 0)),
		int(class_data.get("atk", 0)),
		display_desc,
		locked_text
	]

	tooltip_popup = PanelContainer.new()
	tooltip_popup.name = "ClassTooltip"
	tooltip_popup.z_index = 100

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
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = current_theme.get("title", Color(0.9, 0.92, 0.98))
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
	_refresh_character_detail(class_id)

func _refresh_character_select_view() -> void:
	_refresh_character_buttons()
	_refresh_character_preview(current_class_id if current_class_id >= 0 else selected_class_id)
	_refresh_character_detail(current_class_id if current_class_id >= 0 else selected_class_id)
	var confirm := get_node_or_null("ConfirmButton") as Button
	if confirm != null:
		confirm.disabled = selected_class_id < 0 or (selected_class_id == 4 and not GameState.has_meta_upgrade("new_character"))
		_apply_action_button_feedback_state(confirm, confirm.is_hovered(), false)

func _refresh_character_buttons() -> void:
	for i in range(player_class_script.get_all_classes().size()):
		var btn: Button = get_node_or_null("Char%d" % i)
		if btn == null:
			continue
		var locked := i == 4 and not GameState.has_meta_upgrade("new_character")
		var hovered := i == current_class_id and current_class_id != selected_class_id
		var selected := i == selected_class_id
		_apply_class_button_visual_state(btn, selected, hovered, locked)

func _refresh_character_preview(class_id: int) -> void:
	if class_id < 0 or player_class_script == null:
		return
	var class_data = player_class_script.get_class_data(class_id)
	var display_name = player_class_script.get_class_display_name(class_id)
	var display_desc = player_class_script.get_class_display_desc(class_id)
	var preview_panel := get_node_or_null("PreviewPanel") as PanelContainer
	if preview_panel == null:
		return
	var portrait := preview_panel.get_node_or_null("PreviewPortrait") as TextureRect
	var name_label := preview_panel.get_node_or_null("PreviewName") as Label
	var stat_label := get_node_or_null("PreviewStats") as Label
	var summary_label := preview_panel.get_node_or_null("PreviewSummary") as Label
	if portrait != null:
		portrait.texture = _load_portrait_texture(ArtRegistry.get_character_select_path(class_id))
		portrait.modulate = Color.WHITE if not (class_id == 4 and not GameState.has_meta_upgrade("new_character")) else Color(0.55, 0.55, 0.58, 0.92)
	if name_label != null:
		name_label.text = "%s %s" % [_get_class_icon(class_id), display_name]
		name_label.modulate = current_theme.get("title", Color(0.95, 0.88, 0.72, 1.0))
	if stat_label != null:
		stat_label.text = "生命：%d\n攻击：%d\n定位：%s" % [int(class_data.get("hp", 0)), int(class_data.get("atk", 0)), _get_role_label(class_id)]
		stat_label.modulate = current_theme.get("accent", Color(0.82, 0.78, 0.66, 1.0))
		stat_label.visible = true
	if summary_label != null:
		summary_label.text = display_desc
		summary_label.modulate = current_theme.get("title", Color(0.92, 0.90, 0.84, 1.0))

func _refresh_character_detail(class_id: int) -> void:
	if class_id < 0 or player_class_script == null or combo_script == null:
		return
	combo_title.text = "【%s】角色卷宗" % player_class_script.get_class_display_name(class_id)
	combo_title.modulate = current_theme.get("title", Color(1, 0.9, 0.6))
	combo_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for child in combo_list.get_children():
		child.queue_free()
	_ensure_role_description_layer()
	var role_art := combo_panel.get_node_or_null("RoleDescriptionArt") as TextureRect
	if role_art != null:
		role_art.visible = false
	var role_body := combo_panel.get_node_or_null("RoleDescriptionBody") as Label
	if role_body != null:
		role_body.text = ""
		role_body.visible = false
	_add_detail_block("专属被动", _get_core_mechanic(class_id))
	if class_id == 4 and not GameState.has_meta_upgrade("new_character"):
		_add_detail_block("解锁条件", "需要在行前筹备中解锁「异路来客」。")
	var combos = player_class_script.get_class_combos(class_id)
	var combos_title_wrap = MarginContainer.new()
	combos_title_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combos_title_wrap.add_theme_constant_override("margin_left", 144)
	combo_list.add_child(combos_title_wrap)
	var combos_title = Label.new()
	combos_title.text = "本命布局"
	combos_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combos_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	combos_title.add_theme_font_size_override("font_size", 22)
	combos_title.modulate = current_theme.get("title", Color(0.95, 0.88, 0.72, 1.0))
	combos_title_wrap.add_child(combos_title)
	if combos == null or combos.is_empty():
		var empty := Label.new()
		empty.text = "该职业暂无本命布局"
		empty.add_theme_font_size_override("font_size", 16)
		empty.modulate = current_theme.get("accent", Color(0.72, 0.72, 0.76))
		combo_list.add_child(empty)
	else:
		for combo in combos:
			if combo != null:
				combo_list.add_child(_create_combo_card(combo))
	call_deferred("_reset_detail_scroll")

func _reset_detail_scroll() -> void:
	if combo_scroll != null and is_instance_valid(combo_scroll):
		combo_scroll.scroll_vertical = 0

func _add_detail_block(title_text: String, body_text: String) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(356, 68)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = current_theme.get("panel", Color(0.20, 0.16, 0.12, 0.92)).darkened(0.04)
	style.border_color = current_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	style.set_border_width_all(1)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	combo_list.add_child(panel)
	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 12
	inner.offset_top = 10
	inner.offset_right = -12
	inner.offset_bottom = -10
	panel.add_child(inner)
	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = current_theme.get("title", Color(0.95, 0.88, 0.72, 1.0))
	inner.add_child(title)
	var body = Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 15)
	body.modulate = current_theme.get("accent", Color(0.82, 0.78, 0.66, 1.0))
	inner.add_child(body)

func _confirm_current_class() -> void:
	if selected_class_id < 0:
		return
	if selected_class_id == 4 and not GameState.has_meta_upgrade("new_character"):
		return
	character_selected.emit(selected_class_id)

func _get_role_label(class_id: int) -> String:
	match class_id:
		0: return "续航"
		1: return "爆发"
		2: return "运营"
		3: return "防守"
		4: return "均衡"
		_: return "通用"

func _get_resource_summary(class_id: int) -> String:
	match GameState.selected_era_id:
		"song":
			match class_id:
				0: return "开局更稳，战后回命，适合拉长战线。"
				1: return "开局机括更强，适合压前两回合。"
				2: return "金币周转更快，适合路线运营。"
				3: return "护甲叠层更快，适合稳吃普通战。"
				4: return "属性均衡，适合通用路线。"
		"china":
			match class_id:
				0: return "开局得机括，复起容错高。"
				1: return "攻击和机括双高，适合极限爆发。"
				2: return "初始金币更厚，适合滚雪球。"
				3: return "初始护甲和命数都更厚。"
				4: return "机括护甲双起手，节奏最平。"
		_:
			match class_id:
				0: return "命数厚，复起强，打持久战。"
				1: return "前期爆发最高，但也最脆。"
				2: return "拿经济优势，后续器物更快成型。"
				3: return "护甲滚起来后最稳。"
				4: return "没有明显短板，转型自由。"
	return ""

func _get_core_mechanic(class_id: int) -> String:
	return player_class_script.get_class_display_desc(class_id)

func _get_recommended_play(class_id: int) -> String:
	match class_id:
		0: return "优先保命和续航布局，前两战稳血量，靠复起和回复把局面拖进中盘。"
		1: return "优先选高爆发与机括联动，尽量在前两回合打穿敌人，不要拖成长线。"
		2: return "优先路线收益和商店价值，拿金币转器物与升级，靠资源差取胜。"
		3: return "优先护甲和减伤组件，先稳住再反打，适合吃普通怪和长战斗。"
		4: return "根据路线和首批布局临场转型，哪里资源顺就往哪里倾斜。"
		_: return "按当前路线灵活应对。"

func _get_opening_risk(class_id: int) -> String:
	match class_id:
		0: return "爆发不足，前期收不掉敌人时容易被持续消耗。"
		1: return "容错最低，一旦前两回合没打出优势会很难补救。"
		2: return "前期战力平，需要靠运营换强度，短线压制不足。"
		3: return "输出偏慢，遇到高频压制型敌人会拖得比较难受。"
		4: return "没有极端强项，开局布局如果不顺会显得平。"
		_: return "需要按路线补短板。"

func _create_combo_card(combo) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(356, 128)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)

	var frame_art := TextureRect.new()
	frame_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_art.stretch_mode = TextureRect.STRETCH_SCALE
	frame_art.texture = _load_texture_resource(_get_combo_layout_frame_path())
	frame_art.position = Vector2.ZERO
	panel.add_child(frame_art)
	panel.move_child(frame_art, 0)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 32
	hbox.offset_right = -32
	hbox.offset_top = 22
	hbox.offset_bottom = -22
	panel.add_child(hbox)

	var seq_label = Label.new()
	seq_label.text = combo_script.sequence_to_string(combo.sequence)
	seq_label.add_theme_font_size_override("font_size", 16)
	seq_label.custom_minimum_size = Vector2(52, 0)
	seq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	seq_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seq_label.modulate = current_theme.get("title", Color(1, 0.9, 0.5))
	hbox.add_child(seq_label)

	var role_text = combo.role if combo.get("role") != null and combo.role != "" else ("战斗" if combo.is_combat else "非战斗")
	role_text = ComboDatabase.get_era_role_text(role_text)
	var role_label = Label.new()
	role_label.text = role_text
	role_label.add_theme_font_size_override("font_size", 13)
	role_label.custom_minimum_size = Vector2(44, 0)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	role_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	role_label.modulate = current_theme.get("accent", Color(0.62, 0.84, 1.0))
	hbox.add_child(role_label)

	var cd_label = Label.new()
	cd_label.text = "CD:%d" % combo.cooldown
	cd_label.add_theme_font_size_override("font_size", 13)
	cd_label.custom_minimum_size = Vector2(38, 0)
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_label.modulate = current_theme.get("accent", Color(0.58, 0.62, 0.72)).lerp(Color(0.6, 0.62, 0.68, 1.0), 0.3)
	hbox.add_child(cd_label)

	var detail = "效果：%s" % combo.description
	if combo.get("exclusive_era") != null and str(combo.exclusive_era) != "":
		detail += "\n时代专属：%s卷独有布局" % GameState.get_current_era_definition().get("name", "秦")
		detail += "\n%s" % GameState.get_combo_upgrade_path_text(str(combo.combo_id))
	detail += "\n时代偏置：%s" % GameState.get_era_combo_bonus_text(str(combo.combo_id), str(combo.effect_type))
	if combo.get("usage_hint") != null and combo.usage_hint != "":
		detail += "\n用法：%s" % ComboDatabase.get_era_hint_text(combo.usage_hint)
	var upgrade_status = GameState.get_combo_upgrade_status_text(str(combo.combo_id))
	if upgrade_status != "":
		detail += "\n当前强化：%s" % upgrade_status.strip_edges()
	var detail_icon = Label.new()
	detail_icon.text = "ⓘ 详情"
	detail_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_icon.add_theme_font_size_override("font_size", 13)
	detail_icon.custom_minimum_size = Vector2(50, 0)
	detail_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_icon.modulate = current_theme.get("accent", Color(0.72, 0.84, 1.0))
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
	label.custom_minimum_size = Vector2(420, 0)
	label.add_theme_font_size_override("font_size", 15)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = current_theme.get("title", Color(0.9, 0.92, 0.98))
	tooltip_popup.add_child(label)

	var local_pos = anchor.global_position - global_position + Vector2(-260, 28)
	local_pos.x = clamp(local_pos.x, 20.0, 820.0)
	local_pos.y = clamp(local_pos.y, 40.0, 610.0)
	tooltip_popup.position = local_pos
	add_child(tooltip_popup)
