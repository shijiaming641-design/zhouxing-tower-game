class_name RestPointScene
extends Control

const MoveSymbols = preload("res://resources/move_symbols.gd")
const REST_CHOICE_ICON_PATHS := {
	"_on_heal_selected": "res://assets/items/icons/item_potion.png",
	"_on_equip_selected": "res://assets/icons/combat/icon_attack.png",
	"_on_combo_selected": "res://assets/icons/combat/icon_cheat.png",
}

## 休息点场景 - 楼层结束后的恢复和强化界面
## 优化：初始显示三个按钮选择界面，用户点击后进入对应功能

signal continue_to_next_floor

const MOVE_SYMBOLS: Array[String] = MoveSymbols.MOVE_NAMES
const EQUIPMENT_PANEL_POSITION := Vector2(300, 100)
const EQUIPMENT_PANEL_SIZE := Vector2(680, 550)
const COMBO_PANEL_POSITION := Vector2(390, 100)
const COMBO_PANEL_SIZE := Vector2(500, 550)
const HEAL_PANEL_POSITION := Vector2(370, 92)
const HEAL_PANEL_SIZE := Vector2(540, 540)

# 当前显示模式: "choice" = 选择界面, "heal" = 恢复界面, "combo" = 连招界面, "equip" = 装备界面
var _current_mode: String = "choice"

# 面板引用
var _choice_container: Control = null
var _heal_panel: Control = null
var _combo_panel: Control = null
var _equip_panel: Control = null
var _bottom_bar: Control = null
var _top_materials_label: Label = null
var _bottom_materials_label: Label = null
var _top_status_label: Label = null
var _heal_feedback_label: Label = null

func _load_texture_if_exists(texture_path: String) -> Texture2D:
	if texture_path == "":
		return null
	if ResourceLoader.exists(texture_path):
		return load(texture_path) as Texture2D
	var image = Image.load_from_file(ProjectSettings.globalize_path(texture_path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _load_rest_panel_texture() -> Texture2D:
	return _load_texture_if_exists(ArtRegistry.get_era_ui_path("rest_panel"))

func _get_rest_choice_icon_texture(action_name: String) -> Texture2D:
	return _load_texture_if_exists(str(REST_CHOICE_ICON_PATHS.get(action_name, "")))

func _get_item_icon_texture(item: Dictionary) -> Texture2D:
	var item_id := str(item.get("id", ""))
	var texture_path := ArtRegistry.get_item_icon_path(item_id, str(item.get("type", "")))
	return _load_texture_if_exists(texture_path)

func _get_rest_choice_buttons() -> Array:
	match GameState.selected_era_id:
		"song":
			return [
				{"icon": "💤", "title": "营寨歇息", "desc": _get_rest_heal_choice_desc(), "color": Color(0.3, 0.8, 0.4), "action": "_on_heal_selected"},
				{"icon": "⚔️", "title": "器物精修", "desc": "锻器", "color": Color(0.4, 0.6, 0.9), "action": "_on_equip_selected"},
				{"icon": "🔥", "title": "阵图修习", "desc": "修阵", "color": Color(0.9, 0.5, 0.3), "action": "_on_combo_selected"}
			]
		"china":
			return [
				{"icon": "💤", "title": "薪火修整", "desc": _get_rest_heal_choice_desc(), "color": Color(0.3, 0.8, 0.4), "action": "_on_heal_selected"},
				{"icon": "⚔️", "title": "遗器重铸", "desc": "锻器", "color": Color(0.4, 0.6, 0.9), "action": "_on_equip_selected"},
				{"icon": "🔥", "title": "终局推演", "desc": "修阵", "color": Color(0.9, 0.5, 0.3), "action": "_on_combo_selected"}
			]
		_:
			return [
				{"icon": "💤", "title": "行军歇息", "desc": _get_rest_heal_choice_desc(), "color": Color(0.3, 0.8, 0.4), "action": "_on_heal_selected"},
				{"icon": "⚔️", "title": "军械整修", "desc": "锻器", "color": Color(0.4, 0.6, 0.9), "action": "_on_equip_selected"},
				{"icon": "🔥", "title": "布局修习", "desc": "修阵", "color": Color(0.9, 0.5, 0.3), "action": "_on_combo_selected"}
			]

func _get_rest_panel_title(kind: String) -> String:
	match GameState.selected_era_id:
		"song":
			match kind:
				"heal": return "💤 营寨歇息"
				"combo": return "🔥 阵图修习"
				"equip": return "⚔️ 器物精修"
		"china":
			match kind:
				"heal": return "💤 薪火修整"
				"combo": return "🔥 终局推演"
				"equip": return "⚔️ 遗器重铸"
		_:
			match kind:
				"heal": return "💤 行军歇息"
				"combo": return "🔥 布局修习"
				"equip": return "⚔️ 军械整修"
	return kind

func _ready() -> void:
	# 金币是局内唯一强化资源；材料信号仅保留兼容旧存档。
	EventBus.player_gold_changed.connect(_on_gold_changed)
	EventBus.materials_changed.connect(_on_materials_changed)
	if GameState.on_enter_rest_point():
		GameState.save_progress("rest")
	_setup_choice_ui()
	_show_choice_mode()

func _on_materials_changed(new_amount: int) -> void:
	"""旧材料变化信号兼容：刷新金币显示"""
	_refresh_gold_labels()

func _on_gold_changed(new_amount: int) -> void:
	_refresh_gold_labels()

func _refresh_gold_labels() -> void:
	var text = "💰 金币: %d" % GameState.player_gold
	if _top_materials_label:
		_top_materials_label.text = text
	if _bottom_materials_label:
		_bottom_materials_label.text = text
	# 兜底：遍历查找
	for child in get_tree().get_nodes_in_group("materials_labels"):
		if child is Label:
			child.text = text

## ========== 选择界面 ==========

func _setup_choice_ui() -> void:
	"""创建选择界面（三按钮）"""
	var theme = GameState.get_era_theme()
	# 背景
	var bg = ColorRect.new()
	bg.color = theme.get("bg", Color(0.12, 0.12, 0.18))
	bg.offset_right = 1280
	bg.offset_bottom = 720
	bg.name = "Background"
	add_child(bg)
	var rest_panel_texture = _load_rest_panel_texture()
	if rest_panel_texture != null:
		var rest_frame = TextureRect.new()
		rest_frame.name = "EraRestPanel"
		rest_frame.texture = rest_panel_texture
		rest_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		rest_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rest_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rest_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rest_frame.modulate = Color(1, 1, 1, 0.52)
		add_child(rest_frame)
	var title_back = ColorRect.new()
	title_back.name = "TitleBack"
	title_back.color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.9))
	title_back.color.a = 0.24
	title_back.position = Vector2(302, 18)
	title_back.custom_minimum_size = Vector2(676, 44)
	add_child(title_back)
	var top_band = ColorRect.new()
	top_band.name = "EraTopBand"
	top_band.color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.9))
	top_band.position = Vector2(140, 62)
	top_band.custom_minimum_size = Vector2(1000, 10)
	add_child(top_band)
	var bottom_band = ColorRect.new()
	bottom_band.name = "EraBottomBand"
	bottom_band.color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	bottom_band.position = Vector2(180, 660)
	bottom_band.custom_minimum_size = Vector2(920, 3)
	add_child(bottom_band)
	add_child(_create_era_seal(Vector2(160, 78), Vector2(124, 38)))

	# 顶部信息栏
	var top_bar = _create_top_bar()
	top_bar.position = Vector2(0, 0)
	add_child(top_bar)

	# 选择界面容器
	_choice_container = Control.new()
	_choice_container.name = "ChoiceContainer"
	_choice_container.custom_minimum_size = Vector2(1280, 520)
	_choice_container.position = Vector2(0, 120)
	add_child(_choice_container)

	# 三个大按钮
	_create_choice_buttons()

func _create_top_bar() -> Control:
	var top_bar = Control.new()
	top_bar.name = "TopBar"
	top_bar.custom_minimum_size = Vector2(1280, 80)
	var theme = GameState.get_era_theme()

	# 标题
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "🏕️ %s 第 %d 层完成 - %s" % [_get_era_badge(), GameState.current_floor, _get_rest_panel_title("heal").trim_prefix("💤 ")]
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 15
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = theme.get("title", Color(1, 0.9, 0.7))
	title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	title.add_theme_constant_override("outline_size", 1)
	top_bar.add_child(title)

	# 金币显示
	var materials_label = Label.new()
	materials_label.name = "GoldLabel"
	materials_label.text = "💰 金币: %d" % GameState.player_gold
	materials_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	materials_label.offset_left = 30
	materials_label.offset_top = 20
	materials_label.add_theme_font_size_override("font_size", 20)
	materials_label.modulate = theme.get("accent", Color(0.9, 0.8, 0.4))
	materials_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	materials_label.add_theme_constant_override("outline_size", 1)
	top_bar.add_child(materials_label)
	_top_materials_label = materials_label

	# 玩家状态
	var status = _get_player_status_text()
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = status
	status_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	status_label.offset_right = -30
	status_label.offset_top = 20
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.modulate = theme.get("title", Color(0.8, 0.8, 0.8)).lerp(Color.WHITE, 0.2)
	status_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	status_label.add_theme_constant_override("outline_size", 1)
	top_bar.add_child(status_label)
	_top_status_label = status_label

	return top_bar

func _get_era_badge() -> String:
	match GameState.selected_era_id:
		"song":
			return "〔宋卷〕"
		"china":
			return "〔终局〕"
		_:
			return "〔秦卷〕"

func _create_era_seal(position: Vector2, size: Vector2 = Vector2(120, 34)) -> PanelContainer:
	var theme = GameState.get_era_theme()
	var seal = PanelContainer.new()
	seal.position = position
	seal.custom_minimum_size = size
	var style = StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.2, 0.16, 0.12, 0.92))
	style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	seal.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = _get_era_badge()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = size
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = theme.get("title", Color(0.95, 0.9, 0.75))
	seal.add_child(label)
	return seal

func _get_player_status_text() -> String:
	return "命数 %d/%d | 💰%d | %s" % [
		GameState.player_hp,
		GameState.player_max_hp,
		GameState.player_gold,
		GameState.get_level_progress_text()
	]

func _get_numeric_hp_status_text() -> String:
	return "命数：%d / %d" % [GameState.player_hp, GameState.player_max_hp]

func _get_hp_bar_text() -> String:
	var hp_bar := ""
	for i in range(GameState.player_max_hp):
		hp_bar += "❤️" if i < GameState.player_hp else "🖤"
	return hp_bar

func _get_missing_hp() -> int:
	return maxi(GameState.player_max_hp - GameState.player_hp, 0)

func _get_half_rest_recovery_cap() -> int:
	return maxi(int(GameState.player_max_hp * 0.5), 1)

func _get_rest_heal_choice_desc() -> String:
	var missing_hp := _get_missing_hp()
	if missing_hp <= 0:
		return "命数已满"
	return "回命｜%d/%d｜缺%d" % [GameState.player_hp, GameState.player_max_hp, missing_hp]

func _get_heal_preview_text() -> String:
	var missing_hp := _get_missing_hp()
	if missing_hp <= 0:
		return "命数已满。休息不会再提高命数，可以考虑锻器或修阵。"
	var half_recover := mini(_get_half_rest_recovery_cap(), missing_hp)
	return "当前命数 %d/%d，缺%d命。充分休息 +%d；稍作歇息 +%d。" % [
		GameState.player_hp,
		GameState.player_max_hp,
		missing_hp,
		missing_hp,
		half_recover
	]

func _refresh_top_status_label() -> void:
	if _top_status_label:
		_top_status_label.text = _get_player_status_text()

func _get_era_combo_name(combo_name: String) -> String:
	var qin_map := {
		"全体穿透": "军阵贯杀",
		"战术干扰": "军令扰阵",
		"闪电突袭": "疾骑突袭",
		"稳固防御": "坚垒拒敌",
		"能量充能": "蓄势待发",
		"循环护盾": "玄甲回环",
		"束缚致命": "缚敌斩首",
		"双重打击": "双锋并进",
		"虎符压阵": "虎符压阵",
		"望闻问切": "军医望诊",
		"妙手回春": "营救回春",
		"病毒植入": "秘符暗植",
		"系统过载": "机关过载",
		"金钱帝国": "盐铁通筹",
		"精算头脑": "度支神算",
		"固若金汤": "城寨金汤",
		"五谷丰登": "屯田丰收",
		"记忆爆破": "旧忆裂阵",
		"相位护盾": "游身护势"
	}
	var song_map := {
		"全体穿透": "弩阵齐发",
		"战术干扰": "机宜牵制",
		"闪电突袭": "轻骑急袭",
		"稳固防御": "城防固守",
		"能量充能": "点将蓄势",
		"循环护盾": "楼橹回护",
		"束缚致命": "缚敌点杀",
		"双重打击": "双锋连断",
		"市舶周转": "市舶周转",
		"望闻问切": "太医四诊",
		"妙手回春": "杏林回春",
		"病毒植入": "机巧暗植",
		"系统过载": "算筹过载",
		"金钱帝国": "市舶通利",
		"精算头脑": "筹算入微",
		"固若金汤": "铁壁保甲",
		"五谷丰登": "丰年积粟",
		"记忆爆破": "行旅旧梦",
		"相位护盾": "帷幕护身"
	}
	var china_map := {
		"全体穿透": "山河贯杀号",
		"战术干扰": "终局牵制",
		"闪电突袭": "星火突进",
		"稳固防御": "长城固守",
		"能量充能": "薪火蓄势",
		"循环护盾": "山海回护",
		"束缚致命": "锁敌定锋",
		"双重打击": "双锋复断",
		"山河同契": "山河同契",
		"望闻问切": "国医四诊",
		"妙手回春": "山河回春",
		"病毒植入": "星图暗植",
		"系统过载": "星火过载",
		"金钱帝国": "百业通筹",
		"精算头脑": "山河筹算",
		"固若金汤": "守土成城",
		"五谷丰登": "仓廪丰年",
		"记忆爆破": "百代裂响",
		"相位护盾": "归乡护势"
	}
	match GameState.selected_era_id:
		"song":
			var song_name := str(song_map.get(combo_name, combo_name))
			return "〔宋秘〕%s" % song_name if combo_name == "市舶周转" else song_name
		"china":
			var china_name := str(china_map.get(combo_name, combo_name))
			return "〔终局〕%s" % china_name if combo_name == "山河同契" else china_name
		_:
			var qin_name := str(qin_map.get(combo_name, combo_name))
			return "〔秦秘〕%s" % qin_name if combo_name == "虎符压阵" else qin_name

func _create_choice_buttons() -> void:
	"""创建三个大按钮"""
	var container = Control.new()
	container.name = "ChoiceButtonsContainer"
	container.custom_minimum_size = Vector2(1280, 450)
	container.position = Vector2(0, 120)
	_choice_container.add_child(container)

	# 按钮配置
	var buttons = _get_rest_choice_buttons()

	var start_x = 165
	var spacing = 350
	var btn_width = 280
	var btn_height = 320

	for i in range(buttons.size()):
		var btn_data = buttons[i]
		var btn = _create_choice_button(btn_data, btn_width, btn_height)
		btn.position = Vector2(start_x + i * spacing, 60)
		container.add_child(btn)

func _create_choice_button(btn_data: Dictionary, width: int, height: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(width, height)
	btn.clip_contents = true
	btn.text = ""
	btn.tooltip_text = "%s：%s" % [str(btn_data.title), str(btn_data.desc).replace("\n", " ")]
	var theme = GameState.get_era_theme()
	var style = StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94)).darkened(0.04)
	style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	var hover = style.duplicate()
	hover.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94)).lightened(0.08)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", hover)

	var card_texture := _load_texture_if_exists(ArtRegistry.get_reference_ui_path("card"))
	if card_texture != null:
		var card_frame := TextureRect.new()
		card_frame.texture = card_texture
		card_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_frame.stretch_mode = TextureRect.STRETCH_SCALE
		card_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_frame.modulate = Color(1, 1, 1, 0.72)
		btn.add_child(card_frame)

	# 创建按钮内容容器
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(width, height)
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# 图标
	var icon_texture := _get_rest_choice_icon_texture(str(btn_data.action))
	if icon_texture != null:
		var icon_rect = TextureRect.new()
		icon_rect.texture = icon_texture
		icon_rect.custom_minimum_size = Vector2(76, 76)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon_rect)
	else:
		var icon_label = Label.new()
		icon_label.text = btn_data.icon
		icon_label.add_theme_font_size_override("font_size", 64)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(icon_label)

	# 标题
	var title_label = Label.new()
	title_label.text = btn_data.title
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.modulate = btn_data.color
	title_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	title_label.add_theme_constant_override("outline_size", 1)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# 描述
	var desc_label = Label.new()
	desc_label.text = btn_data.desc
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.modulate = theme.get("title", Color(0.82, 0.82, 0.86, 1.0))
	desc_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	desc_label.add_theme_constant_override("outline_size", 1)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	btn.add_child(vbox)

	# 根据action连接信号
	match btn_data.action:
		"_on_heal_selected":
			btn.pressed.connect(_on_heal_selected)
		"_on_equip_selected":
			btn.pressed.connect(_on_equip_selected)
		"_on_combo_selected":
			btn.pressed.connect(_on_combo_selected)

	return btn

func _show_choice_mode() -> void:
	"""显示选择界面"""
	_current_mode = "choice"
	_hide_equipment_forge_menu()

	# 隐藏详情面板
	if _heal_panel:
		_heal_panel.visible = false
	if _combo_panel:
		_combo_panel.visible = false
	if _equip_panel:
		_equip_panel.visible = false

	# 显示选择界面
	if _choice_container:
		_refresh_choice_buttons()
		_choice_container.visible = true

	# 显示底部栏（只有继续按钮）
	_show_bottom_bar_only_continue()

func _refresh_choice_buttons() -> void:
	if _choice_container == null:
		return
	for child in _choice_container.get_children():
		_choice_container.remove_child(child)
		child.queue_free()
	_create_choice_buttons()

func _show_bottom_bar_only_continue() -> void:
	"""底部栏：只有继续按钮"""
	if _bottom_bar:
		_bottom_bar.queue_free()

	_bottom_bar = Control.new()
	_bottom_bar.name = "BottomBar"
	_bottom_bar.custom_minimum_size = Vector2(1280, 80)
	_bottom_bar.position = Vector2(0, 640)
	add_child(_bottom_bar)
	var bottom_plate = ColorRect.new()
	bottom_plate.color = GameState.get_era_theme().get("panel", Color(0.18, 0.18, 0.22, 0.9))
	bottom_plate.color.a = 0.18
	bottom_plate.position = Vector2(36, 6)
	bottom_plate.custom_minimum_size = Vector2(1208, 68)
	_bottom_bar.add_child(bottom_plate)

	var continue_btn = Button.new()
	continue_btn.text = "继续下一层 →"
	continue_btn.custom_minimum_size = Vector2(200, 55)
	continue_btn.position = Vector2(540, 10)
	continue_btn.add_theme_font_size_override("font_size", 22)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = GameState.get_era_theme().get("panel", Color(0.18, 0.18, 0.22, 0.9)).darkened(0.08)
	btn_style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	btn_style.set_border_width_all(2)
	btn_style.corner_radius_top_left = 12
	btn_style.corner_radius_top_right = 12
	btn_style.corner_radius_bottom_left = 12
	btn_style.corner_radius_bottom_right = 12
	continue_btn.add_theme_stylebox_override("normal", btn_style)
	continue_btn.add_theme_stylebox_override("hover", btn_style)
	continue_btn.add_theme_stylebox_override("pressed", btn_style)
	continue_btn.add_theme_color_override("font_color", GameState.get_era_theme().get("title", Color(1, 0.9, 0.7)))
	ArtRegistry.apply_button_icon(continue_btn, "next", false, "继续下一层")
	continue_btn.pressed.connect(_on_continue_pressed)
	_bottom_bar.add_child(continue_btn)

## ========== 按钮回调 ==========

func _on_heal_selected() -> void:
	"""选择休息功能"""
	_current_mode = "heal"
	_hide_choice_and_show_panel("heal")

func _on_equip_selected() -> void:
	"""选择装备升级功能"""
	_current_mode = "equip"
	_hide_choice_and_show_panel("equip")

func _on_combo_selected() -> void:
	"""选择连招升级功能"""
	_current_mode = "combo"
	_hide_choice_and_show_panel("combo")

func _hide_choice_and_show_panel(panel_name: String) -> void:
	"""隐藏选择界面，显示对应面板"""
	if panel_name != "equip":
		_hide_equipment_forge_menu()
	# 隐藏选择界面
	if _choice_container:
		_choice_container.visible = false
	if _heal_panel:
		_heal_panel.visible = false
	if _combo_panel:
		_combo_panel.visible = false
	if _equip_panel:
		_equip_panel.visible = false

	# 显示/创建对应面板
	match panel_name:
		"heal":
			if not _heal_panel:
				_heal_panel = _create_heal_panel()
				_heal_panel.position = HEAL_PANEL_POSITION
				add_child(_heal_panel)
			_heal_panel.visible = true
		"combo":
			if not _combo_panel:
				_combo_panel = _create_combo_upgrade_panel()
				_combo_panel.position = COMBO_PANEL_POSITION
				add_child(_combo_panel)
			_combo_panel.visible = true
		"equip":
			if not _equip_panel:
				_equip_panel = _create_equipment_upgrade_panel()
				_equip_panel.position = EQUIPMENT_PANEL_POSITION
				add_child(_equip_panel)
			_equip_panel.visible = true

	# 显示带返回按钮的底部栏
	_show_bottom_bar_with_back()

func _show_bottom_bar_with_back() -> void:
	"""底部栏：返回按钮 + 继续按钮"""
	if _bottom_bar:
		_bottom_bar.queue_free()

	_bottom_bar = Control.new()
	_bottom_bar.name = "BottomBar"
	_bottom_bar.custom_minimum_size = Vector2(1280, 80)
	_bottom_bar.position = Vector2(0, 640)
	add_child(_bottom_bar)
	var bottom_plate = ColorRect.new()
	bottom_plate.color = GameState.get_era_theme().get("panel", Color(0.18, 0.18, 0.22, 0.9))
	bottom_plate.color.a = 0.18
	bottom_plate.position = Vector2(36, 6)
	bottom_plate.custom_minimum_size = Vector2(1208, 68)
	_bottom_bar.add_child(bottom_plate)

	# 返回按钮
	var back_btn = Button.new()
	back_btn.text = "← 返回"
	back_btn.custom_minimum_size = Vector2(120, 50)
	back_btn.position = Vector2(50, 10)
	back_btn.add_theme_font_size_override("font_size", 18)
	var nav_style = StyleBoxFlat.new()
	nav_style.bg_color = GameState.get_era_theme().get("panel", Color(0.18, 0.18, 0.22, 0.9)).darkened(0.08)
	nav_style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	nav_style.set_border_width_all(2)
	nav_style.corner_radius_top_left = 12
	nav_style.corner_radius_top_right = 12
	nav_style.corner_radius_bottom_left = 12
	nav_style.corner_radius_bottom_right = 12
	back_btn.add_theme_stylebox_override("normal", nav_style)
	back_btn.add_theme_stylebox_override("hover", nav_style)
	back_btn.add_theme_stylebox_override("pressed", nav_style)
	back_btn.add_theme_color_override("font_color", GameState.get_era_theme().get("title", Color(1, 0.9, 0.7)))
	ArtRegistry.apply_button_icon(back_btn, "back", false, "返回营寨选项")
	back_btn.pressed.connect(_show_choice_mode)
	_bottom_bar.add_child(back_btn)

	# 金币显示
	var materials_label = Label.new()
	materials_label.name = "GoldLabel"
	materials_label.text = "💰 金币: %d" % GameState.player_gold
	materials_label.position = Vector2(560, 15)
	materials_label.add_theme_font_size_override("font_size", 18)
	materials_label.modulate = Color(0.9, 0.8, 0.4)
	materials_label.add_theme_color_override("font_outline_color", GameState.get_era_theme().get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	materials_label.add_theme_constant_override("outline_size", 1)
	_bottom_bar.add_child(materials_label)
	_bottom_materials_label = materials_label

	# 继续按钮
	var continue_btn = Button.new()
	continue_btn.text = "继续下一层 →"
	continue_btn.custom_minimum_size = Vector2(180, 50)
	continue_btn.position = Vector2(980, 10)
	continue_btn.add_theme_font_size_override("font_size", 20)
	continue_btn.add_theme_stylebox_override("normal", nav_style)
	continue_btn.add_theme_stylebox_override("hover", nav_style)
	continue_btn.add_theme_stylebox_override("pressed", nav_style)
	continue_btn.add_theme_color_override("font_color", GameState.get_era_theme().get("title", Color(1, 0.9, 0.7)))
	ArtRegistry.apply_button_icon(continue_btn, "next", false, "继续下一层")
	continue_btn.pressed.connect(_on_continue_pressed)
	_bottom_bar.add_child(continue_btn)

## ========== 恢复面板 ==========

func _create_heal_panel() -> Control:
	var panel = Control.new()
	panel.name = "HealPanel"
	panel.custom_minimum_size = HEAL_PANEL_SIZE
	panel.size = HEAL_PANEL_SIZE

	# 背景
	var bg = Panel.new()
	bg.custom_minimum_size = HEAL_PANEL_SIZE
	bg.size = HEAL_PANEL_SIZE
	var theme = GameState.get_era_theme()
	var style = StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94)).darkened(0.03)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	bg.add_theme_stylebox_override("panel", style)
	panel.add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(492, 500)
	vbox.size = Vector2(492, 500)
	vbox.add_theme_constant_override("separation", 14)
	vbox.position = Vector2(24, 20)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = _get_rest_panel_title("heal")
	title.add_theme_font_size_override("font_size", 26)
	title.modulate = theme.get("title", Color(1, 0.9, 0.7))
	title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	title.add_theme_constant_override("outline_size", 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# 状态显示
	var status_container = VBoxContainer.new()
	status_container.add_theme_constant_override("separation", 10)
	status_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(status_container)

	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = _get_numeric_hp_status_text()
	hp_label.custom_minimum_size = Vector2(492, 38)
	hp_label.add_theme_font_size_override("font_size", 24)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.modulate = theme.get("title", Color(1, 0.9, 0.7))
	status_container.add_child(hp_label)

	var shield_label = Label.new()
	shield_label.name = "ShieldLabel"
	shield_label.text = "🛡️ 护甲: %d" % GameState.player_shield
	shield_label.add_theme_font_size_override("font_size", 18)
	shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_container.add_child(shield_label)

	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "💰 金币: %d" % GameState.player_gold
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_container.add_child(gold_label)

	var preview_label = Label.new()
	preview_label.name = "RestHealPreviewLabel"
	preview_label.text = _get_heal_preview_text()
	preview_label.custom_minimum_size = Vector2(492, 54)
	preview_label.add_theme_font_size_override("font_size", 16)
	preview_label.modulate = theme.get("title", Color(0.82, 0.82, 0.86, 1.0))
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_container.add_child(preview_label)

	# 分隔线
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(492, 2)
	vbox.add_child(sep)

	# 恢复选项
	var full_btn = Button.new()
	full_btn.name = "FullHealButton"
	full_btn.custom_minimum_size = Vector2(492, 76)
	full_btn.add_theme_font_size_override("font_size", 18)
	var action_style := StyleBoxFlat.new()
	action_style.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94)).darkened(0.08)
	action_style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	action_style.set_border_width_all(2)
	action_style.corner_radius_top_left = 12
	action_style.corner_radius_top_right = 12
	action_style.corner_radius_bottom_left = 12
	action_style.corner_radius_bottom_right = 12
	full_btn.add_theme_stylebox_override("normal", action_style)
	full_btn.add_theme_stylebox_override("hover", action_style)
	full_btn.add_theme_stylebox_override("pressed", action_style)
	full_btn.add_theme_color_override("font_color", theme.get("title", Color(1, 0.9, 0.7)))
	ArtRegistry.apply_button_icon(full_btn, "heal", false, "充分休息，恢复全部命数")
	full_btn.pressed.connect(_on_full_heal)
	vbox.add_child(full_btn)

	var half_btn = Button.new()
	half_btn.name = "HalfHealButton"
	half_btn.custom_minimum_size = Vector2(492, 76)
	half_btn.add_theme_font_size_override("font_size", 18)
	half_btn.add_theme_stylebox_override("normal", action_style)
	half_btn.add_theme_stylebox_override("hover", action_style)
	half_btn.add_theme_stylebox_override("pressed", action_style)
	half_btn.add_theme_color_override("font_color", theme.get("title", Color(1, 0.9, 0.7)))
	ArtRegistry.apply_button_icon(half_btn, "heal", false, "稍微休息，恢复一半命数")
	half_btn.pressed.connect(_on_half_heal)
	vbox.add_child(half_btn)
	_apply_heal_button_state(full_btn, half_btn)

	var feedback = Label.new()
	feedback.name = "RestHealFeedbackLabel"
	feedback.text = "选择休息方式后，会在这里显示命数变化。"
	feedback.custom_minimum_size = Vector2(492, 58)
	feedback.add_theme_font_size_override("font_size", 16)
	feedback.modulate = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(feedback)
	_heal_feedback_label = feedback

	# 提示
	var hint = Label.new()
	hint.text = "秦卷休息补护甲；宋卷得金币；终局得推演点。"
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(0.5, 0.5, 0.5)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	return panel

func _get_rest_side_reward_text(is_full_rest: bool) -> String:
	match GameState.selected_era_id:
		"song":
			return "金币 +8" if is_full_rest else "护甲 +1"
		"china":
			return "推演点 +1"
		_:
			return "护甲 +2" if is_full_rest else "护甲 +1"

func _apply_heal_button_state(full_btn: Button, half_btn: Button) -> void:
	var missing_hp := _get_missing_hp()
	var half_recover := mini(_get_half_rest_recovery_cap(), missing_hp)
	if missing_hp > 0:
		var full_after := GameState.player_max_hp
		var half_after := mini(GameState.player_hp + half_recover, GameState.player_max_hp)
		full_btn.text = "💤 充分休息\n%d/%d → %d/%d（+%d）" % [
			GameState.player_hp,
			GameState.player_max_hp,
			full_after,
			GameState.player_max_hp,
			missing_hp
		]
		half_btn.text = "😴 稍作歇息\n%d/%d → %d/%d（+%d）" % [
			GameState.player_hp,
			GameState.player_max_hp,
			half_after,
			GameState.player_max_hp,
			half_recover
		]
	else:
		full_btn.text = "💤 充分休息\n命满 %d/%d，取整备收益" % [GameState.player_hp, GameState.player_max_hp]
		half_btn.text = "😴 稍作歇息\n命满 %d/%d，取轻整备" % [GameState.player_hp, GameState.player_max_hp]
	full_btn.tooltip_text = "命数补满；%s" % _get_rest_side_reward_text(true)
	half_btn.tooltip_text = "恢复最多%d命；%s" % [_get_half_rest_recovery_cap(), _get_rest_side_reward_text(false)]
	full_btn.disabled = false
	half_btn.disabled = false

func _format_heal_feedback(action_name: String, before_hp: int, before_shield: int, side_reward: String) -> String:
	var healed := maxi(GameState.player_hp - before_hp, 0)
	var hp_text := ""
	if healed > 0:
		hp_text = "%s：命数 %d/%d → %d/%d，恢复 +%d。" % [
			action_name,
			before_hp,
			GameState.player_max_hp,
			GameState.player_hp,
			GameState.player_max_hp,
			healed
		]
	else:
		hp_text = "%s：命数已满，没有额外恢复。" % action_name

	var shield_delta := GameState.player_shield - before_shield
	if shield_delta > 0:
		return "%s\n整备收益：%s，护甲 %d → %d。" % [hp_text, side_reward, before_shield, GameState.player_shield]
	if shield_delta < 0:
		return "%s\n护甲变化：%d → %d。整备收益：%s。" % [hp_text, before_shield, GameState.player_shield, side_reward]
	return "%s\n整备收益：%s。" % [hp_text, side_reward]

func _set_heal_feedback(text: String) -> void:
	var feedback := _heal_feedback_label
	if feedback == null and _heal_panel:
		feedback = _heal_panel.find_child("RestHealFeedbackLabel", true, false) as Label
	if feedback == null:
		return
	feedback.text = text
	var theme = GameState.get_era_theme()
	feedback.modulate = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lerp(Color.WHITE, 0.25)
	feedback.scale = Vector2(1.02, 1.02)
	var tween := create_tween()
	tween.tween_property(feedback, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(feedback, "modulate", theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)), 0.18)

## ========== 连招升级面板 ==========

func _create_combo_upgrade_panel() -> Control:
	var panel = Control.new()
	panel.name = "ComboPanel"
	panel.custom_minimum_size = COMBO_PANEL_SIZE
	panel.size = COMBO_PANEL_SIZE

	# 背景
	var bg = Panel.new()
	bg.custom_minimum_size = COMBO_PANEL_SIZE
	bg.size = COMBO_PANEL_SIZE
	var theme = GameState.get_era_theme()
	var style = StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94)).darkened(0.03)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	bg.add_theme_stylebox_override("panel", style)
	panel.add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 530)
	scroll.size = Vector2(480, 530)
	scroll.position = Vector2(10, 10)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(460, 900)
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	var title = Label.new()
	title.text = _get_rest_panel_title("combo")
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = theme.get("title", Color(1, 0.9, 0.7))
	title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	title.add_theme_constant_override("outline_size", 1)
	vbox.add_child(title)

	# 创建连招数据库实例
	var combo_db = load("res://resources/combo_database.gd").new()
	combo_db._init_database()

	# ===== 战斗连招（玩家本局携带的连招）=====
	var combat_title = Label.new()
	combat_title.text = "━━━ 战斗布局 ━━━"
	combat_title.add_theme_font_size_override("font_size", 14)
	combat_title.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(combat_title)

	# 获取玩家本局携带的战斗连招
	var equipped_ids = GameState.get_equipped_combos()
	var has_equipped_combo = false
	for combo_id in equipped_ids:
		# 尝试从 ComboInfo 获取
		var combo_info = combo_db.get_combo_by_id(combo_id)
		if combo_info:
			var combo_container = _create_unlocked_combo_item(combo_db, combo_info)
			vbox.add_child(combo_container)
			has_equipped_combo = true
		else:
			# 尝试从 CombatCombo 获取
			var combat_combo = combo_db.get_combat_combo_by_id(combo_id)
			if combat_combo:
				var combo_container = _create_combat_combo_item(combo_db, combat_combo)
				vbox.add_child(combo_container)
				has_equipped_combo = true

	if not has_equipped_combo:
		var empty = Label.new()
		empty.text = "（无携带战斗布局）"
		empty.add_theme_font_size_override("font_size", 14)
		empty.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(empty)

	# ===== 武器专属连招 ======
	var weapon_title = Label.new()
	weapon_title.text = "━━━ 器物专属布局 ━━━"
	weapon_title.add_theme_font_size_override("font_size", 14)
	weapon_title.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(weapon_title)

	# 武器专属连招列表
	var weapon_combo_ids = ["bloodthirsty_slash", "reflect_aura", "absolute_hit"]
	var has_weapon_combo = false
	for combo_id in weapon_combo_ids:
		var weapon_combo = combo_db.get_combo_by_id(combo_id)
		if weapon_combo:
			# 检查是否拥有对应装备
			var has_requirement = false
			match combo_id:
				"bloodthirsty_slash": has_requirement = GameState.has_item("demon_blade")
				"reflect_aura": has_requirement = GameState.has_item("heart_mirror")
				"absolute_hit": has_requirement = GameState.has_precision_system_full()

			var combo_container = _create_weapon_combo_item(combo_db, weapon_combo, has_requirement)
			vbox.add_child(combo_container)
			has_weapon_combo = true

	if not has_weapon_combo:
		var empty = Label.new()
		empty.text = "（无器物专属布局）"
		empty.add_theme_font_size_override("font_size", 14)
		empty.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(empty)

	# ===== 角色专属连招 ======
	var role_title = Label.new()
	role_title.text = "━━━ 角色秘传布局 ━━━"
	role_title.add_theme_font_size_override("font_size", 14)
	role_title.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(role_title)

	# 获取角色专属连招
	var exclusive_combos = GameState.get_exclusive_combos()
	DebugLog.log("[RestPoint] 获取到专属连招数量: ", exclusive_combos.size())

	if exclusive_combos.is_empty():
		var empty = Label.new()
		empty.text = "（当前职业无本命布局）"
		empty.add_theme_font_size_override("font_size", 14)
		empty.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(empty)
	else:
		for combo in exclusive_combos:
			var combo_container = _create_skill_combo_item(combo_db, combo)
			vbox.add_child(combo_container)

	var combo_data_script = load("res://resources/combo_data.gd")
	combo_data_script.clear_combo_db_cache()
	combo_db.all_combos.clear()
	combo_db.combat_combos.clear()
	combo_db.free()
	return panel

func _create_unlocked_combo_item(combo_db, combo) -> Control:
	"""显示玩家已解锁的战斗连招（开局选择的）"""
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(440, 102)
	container.add_theme_constant_override("separation", 3)
	var combo_id := str(combo.id)

	var name_label = Label.new()
	var seq_str = combo_db.sequence_to_display(combo.sequence)
	var is_era_combo = combo.get("exclusive_era") != null and str(combo.exclusive_era) != ""
	var title_prefix = "【时代秘】" if is_era_combo else ""
	name_label.text = "%s%s  %s" % [title_prefix, _get_era_combo_name(combo.name), seq_str]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.modulate = Color(1, 0.82, 0.42) if is_era_combo else Color(1, 0.9, 0.5)
	container.add_child(name_label)

	# 获取当前强化等级
	var current_level = GameState.get_combo_upgrade_level(combo_id)

	container.add_child(_create_upgrade_info_label(_get_combo_current_upgrade_text(combo_id), Color(0.56, 0.92, 0.56)))
	container.add_child(_create_upgrade_info_label(_get_combo_next_upgrade_text(combo_id), Color(0.88, 0.78, 0.52)))

	# 强化按钮（三层强化）
	var upgrade_btn = Button.new()
	if current_level >= 5:
		upgrade_btn.text = "✅ 已满级"
		upgrade_btn.disabled = true
	else:
		var next_level = current_level + 1
		upgrade_btn.text = "升 %d  ·  %d金" % [next_level, GameState.get_combo_upgrade_gold_cost(current_level)]
	upgrade_btn.custom_minimum_size = Vector2(420, 32)
	upgrade_btn.add_theme_font_size_override("font_size", 12)
	ArtRegistry.apply_button_icon(upgrade_btn, "upgrade", false, "强化布局")
	upgrade_btn.pressed.connect(func(): _on_combo_upgrade(combo_id))
	container.add_child(upgrade_btn)

	return container

func _create_combat_combo_item(combo_db, combat_combo) -> Control:
	"""显示战斗连招（CombatCombo类型）"""
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(440, 102)
	container.add_theme_constant_override("separation", 3)
	var combo_id := str(combat_combo.id)

	var name_label = Label.new()
	var seq_str = combo_db.combat_combo_sequence_to_display(combat_combo.sequence)
	name_label.text = "%s %s" % [_get_era_combo_name(combat_combo.name), seq_str]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.modulate = Color(1, 0.9, 0.5)
	container.add_child(name_label)

	# 获取当前强化等级
	var current_level = GameState.get_combo_upgrade_level(combo_id)

	container.add_child(_create_upgrade_info_label("%s｜%d击" % [_get_combo_current_upgrade_text(combo_id), combat_combo.attack_count], Color(0.56, 0.92, 0.56)))
	container.add_child(_create_upgrade_info_label(_get_combo_next_upgrade_text(combo_id), Color(0.88, 0.78, 0.52)))

	# 强化按钮（三层强化）
	var upgrade_btn = Button.new()
	if current_level >= 5:
		upgrade_btn.text = "✅ 已满级"
		upgrade_btn.disabled = true
	else:
		var next_level = current_level + 1
		upgrade_btn.text = "升 %d  ·  %d金" % [next_level, GameState.get_combo_upgrade_gold_cost(current_level)]
	upgrade_btn.custom_minimum_size = Vector2(420, 32)
	upgrade_btn.add_theme_font_size_override("font_size", 12)
	ArtRegistry.apply_button_icon(upgrade_btn, "upgrade", false, "强化布局")
	upgrade_btn.pressed.connect(func(): _on_combo_upgrade(combo_id))
	container.add_child(upgrade_btn)

	return container

func _create_skill_combo_item(combo_db, combo) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(440, 100)
	container.add_theme_constant_override("separation", 3)

	var combo_id = combo.combo_id
	var combo_name = _get_era_combo_name(combo.display_name)
	var combo_seq = combo.sequence
	var combo_desc = combo.description if combo.description else ""

	var name_label = Label.new()
	var seq_str = combo_db.sequence_to_display(combo_seq)
	name_label.text = "%s  %s" % [combo_name, seq_str]
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.modulate = Color(0.9, 0.8, 0.6)
	container.add_child(name_label)

	# 获取当前强化等级
	var current_level = GameState.get_combo_upgrade_level(combo_id)

	container.add_child(_create_upgrade_info_label(_get_combo_current_upgrade_text(combo_id, combo_desc), Color(0.56, 0.92, 0.56), 11))
	container.add_child(_create_upgrade_info_label(_get_combo_next_upgrade_text(combo_id), Color(0.88, 0.78, 0.52), 11))

	# 强化按钮（三层强化）
	var upgrade_btn = Button.new()
	if current_level >= 5:
		upgrade_btn.text = "✅ 已满级"
		upgrade_btn.disabled = true
	else:
		var next_level = current_level + 1
		upgrade_btn.text = "升 %d  ·  %d金" % [next_level, GameState.get_combo_upgrade_gold_cost(current_level)]
	upgrade_btn.custom_minimum_size = Vector2(420, 28)
	upgrade_btn.add_theme_font_size_override("font_size", 12)
	ArtRegistry.apply_button_icon(upgrade_btn, "upgrade", false, "强化布局")
	upgrade_btn.pressed.connect(func(): _on_combo_upgrade(combo_id))
	container.add_child(upgrade_btn)

	return container

func _create_weapon_combo_item(combo_db, combo, has_requirement: bool) -> Control:
	"""显示武器专属连招"""
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(440, 102)
	container.add_theme_constant_override("separation", 3)
	var combo_id := str(combo.id)

	var name_label = Label.new()
	var seq_str = combo_db.sequence_to_display(combo.sequence)
	name_label.text = "%s  %s" % [_get_era_combo_name(combo.name), seq_str]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.modulate = Color(1, 0.7, 0.3)  # 橙色表示武器专属
	container.add_child(name_label)

	# 检查是否有对应装备
	if not has_requirement:
		var lock_label = Label.new()
		lock_label.text = "🔒 需要对应装备"
		lock_label.add_theme_font_size_override("font_size", 12)
		lock_label.modulate = Color(0.5, 0.5, 0.5)
		container.add_child(lock_label)
	else:
		# 获取当前强化等级
		var current_level = GameState.get_combo_upgrade_level(combo_id)

		container.add_child(_create_upgrade_info_label(_get_combo_current_upgrade_text(combo_id), Color(0.56, 0.92, 0.56)))
		container.add_child(_create_upgrade_info_label(_get_combo_next_upgrade_text(combo_id), Color(0.88, 0.78, 0.52)))

		# 强化按钮
		var upgrade_btn = Button.new()
		if current_level >= 5:
			upgrade_btn.text = "✅ 已满级"
			upgrade_btn.disabled = true
		else:
			var next_level = current_level + 1
			upgrade_btn.text = "升 %d  ·  %d金" % [next_level, GameState.get_combo_upgrade_gold_cost(current_level)]
		upgrade_btn.custom_minimum_size = Vector2(420, 32)
		upgrade_btn.add_theme_font_size_override("font_size", 12)
		ArtRegistry.apply_button_icon(upgrade_btn, "upgrade", false, "强化器物专属布局")
		upgrade_btn.pressed.connect(func(): _on_combo_upgrade(combo_id))
		container.add_child(upgrade_btn)

	return container

func _get_effect_name(effect: String) -> String:
	match effect:
		"none": return "无"
		"knockback": return "击退"
		"crit": return "暴击"
		"burn": return "灼烧"
		"slow": return "减速"
		_: return effect

func _get_combo_upgrade_brief(combo_id: String, fallback: String = "") -> String:
	var lower_id := combo_id.to_lower()
	if lower_id.contains("shield") or lower_id.contains("guard") or fallback.contains("护"):
		return "守"
	if lower_id.contains("heal") or lower_id.contains("life") or fallback.contains("恢复"):
		return "续"
	if lower_id.contains("gold") or lower_id.contains("trade") or fallback.contains("金币"):
		return "财"
	if lower_id.contains("stun") or lower_id.contains("slow") or fallback.contains("眩晕") or fallback.contains("减速"):
		return "控"
	return "攻"

func _get_combo_upgrade_preview(next_level: int) -> String:
	match next_level:
		1: return "+20%"
		2: return "+30%"
		3: return "+50%"
		_: return "已满级"

func _get_combo_upgrade_preview_for(combo_id: String, next_level: int) -> String:
	var unique_preview = GameState.get_combo_unique_upgrade_preview(combo_id, next_level)
	if unique_preview != "":
		return unique_preview
	match next_level:
		4: return "解锁灼烧"
		5: return "解锁减速"
		_: return _get_combo_upgrade_preview(next_level)

func _get_combo_upgrade_summary(combo_id: String) -> String:
	var level = GameState.get_combo_upgrade_level(combo_id)
	var parts: Array[String] = []
	if level >= 1:
		parts.append("+20%")
	if level >= 2:
		parts.append("+30%")
	if level >= 3:
		parts.append("+50%")
	for label in GameState.get_combo_unique_upgrade_labels(combo_id):
		parts.append(label)
	if GameState.has_combo_effect(combo_id, "burn"):
		parts.append("灼烧")
	if GameState.has_combo_effect(combo_id, "slow"):
		parts.append("减速")
	if parts.is_empty():
		return "无"
	return " ".join(parts)

func _create_upgrade_info_label(text: String, color: Color, font_size: int = 12, min_size: Vector2 = Vector2(420, 18)) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = min_size
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _get_combo_current_upgrade_text(combo_id: String, fallback: String = "") -> String:
	var level := GameState.get_combo_upgrade_level(combo_id)
	if level <= 0:
		return "已强化：未强化｜倾向 %s" % _get_combo_upgrade_brief(combo_id, fallback)
	return "已强化：Lv.%d｜%s" % [level, _get_combo_upgrade_summary(combo_id)]

func _get_combo_next_upgrade_text(combo_id: String) -> String:
	var level := GameState.get_combo_upgrade_level(combo_id)
	if level >= 5:
		return "强化信息：已满级"
	var next_level := level + 1
	return "强化信息：Lv.%d 得 %s｜%d金" % [
		next_level,
		_get_combo_upgrade_preview_for(combo_id, next_level),
		GameState.get_combo_upgrade_gold_cost(level)
	]

func _get_era_combo_source_text(combo_id: String) -> String:
	match combo_id:
		"qin_tiger_push":
			return "来源：秦卷独有；专属异闻【军功授爵】可免费强化 1 级"
		"song_trade_turn":
			return "来源：宋卷独有；专属异闻【市舶兴旺】可免费强化 1 级"
		"china_unity_echo":
			return "来源：中国卷独有；专属异闻【龙脉回响】可免费强化 1 级"
		_:
			return "来源：对应时代卷独有"

## ========== 装备升级面板 ==========

func _create_equipment_upgrade_panel() -> Control:
	var panel = Control.new()
	panel.name = "EquipPanel"
	panel.custom_minimum_size = EQUIPMENT_PANEL_SIZE

	# 背景
	var bg = Panel.new()
	bg.name = "UnifiedEquipmentPanelBg"
	bg.custom_minimum_size = EQUIPMENT_PANEL_SIZE
	bg.size = EQUIPMENT_PANEL_SIZE
	var theme = GameState.get_era_theme()
	var style = StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94)).darkened(0.03)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	bg.add_theme_stylebox_override("panel", style)
	panel.add_child(bg)

	var header = VBoxContainer.new()
	header.position = Vector2(20, 16)
	header.custom_minimum_size = Vector2(640, 62)
	header.add_theme_constant_override("separation", 4)
	panel.add_child(header)

	var title = Label.new()
	title.name = "UnifiedEquipmentTitle"
	title.text = "%s｜器物库" % _get_rest_panel_title("equip")
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = theme.get("title", Color(1, 0.9, 0.7))
	title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	title.add_theme_constant_override("outline_size", 1)
	header.add_child(title)

	var count_label = Label.new()
	count_label.name = "UnifiedEquipmentCount"
	count_label.text = "装备 %d/%d｜背包 %d/%d｜金币 %d" % [
		GameState.equipment_slot.size(),
		GameState.get_current_equipment_slot_limit(),
		GameState.backpack.size(),
		GameState.get_current_backpack_limit(),
		GameState.player_gold
	]
	count_label.add_theme_font_size_override("font_size", 13)
	count_label.modulate = theme.get("body", Color(0.78, 0.78, 0.82))
	header.add_child(count_label)

	var rule_label = Label.new()
	rule_label.name = "UnifiedEquipmentRule"
	rule_label.text = "同一器物库管理：背包可锻级，装备后可升品、开特。"
	rule_label.add_theme_font_size_override("font_size", 12)
	rule_label.modulate = Color(0.72, 0.72, 0.72, 0.92)
	header.add_child(rule_label)

	var scroll = ScrollContainer.new()
	scroll.name = "UnifiedEquipmentScroll"
	scroll.custom_minimum_size = Vector2(650, 450)
	scroll.position = Vector2(15, 88)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.name = "UnifiedEquipmentList"
	vbox.custom_minimum_size = Vector2(630, 900)
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	var entries := _get_unified_equipment_entries()
	if entries.is_empty():
		var empty := Label.new()
		empty.name = "UnifiedEquipmentEmpty"
		empty.text = "暂无器物。"
		empty.custom_minimum_size = Vector2(620, 80)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 16)
		empty.modulate = Color(0.58, 0.58, 0.62)
		vbox.add_child(empty)
	else:
		for entry in entries:
			var item_container = _create_equipment_item_container(
				entry.get("item", {}),
				int(entry.get("index", 0)),
				bool(entry.get("is_equipped", false))
			)
			vbox.add_child(item_container)

	return panel

func _get_unified_equipment_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for i in range(GameState.equipment_slot.size()):
		entries.append({
			"item": GameState.equipment_slot[i],
			"index": i,
			"is_equipped": true
		})
	for i in range(GameState.backpack.size()):
		entries.append({
			"item": GameState.backpack[i],
			"index": i,
			"is_equipped": false
		})
	return entries

func _get_equipment_current_upgrade_text(item_id: String) -> String:
	var upgrades: Dictionary = GameState.equipment_upgrades.get(item_id, {})
	var current_level := int(upgrades.get("level", 0))
	var current_quality := int(upgrades.get("quality", 0))
	var has_special := bool(upgrades.get("special_unlocked", false))
	var parts: Array[String] = []
	if current_level > 0:
		parts.append("锻级Lv.%d" % current_level)
	if current_quality > 0:
		var quality_names := ["白", "蓝", "红"]
		parts.append("品质%s" % quality_names[clampi(current_quality, 0, quality_names.size() - 1)])
	if has_special:
		parts.append("特效已开")
	if parts.is_empty():
		return "已强化：未精修"
	return "已强化：%s｜效果×%.2f" % [" ".join(parts), GameState.get_equipment_effect_multiplier(item_id)]

func _get_equipment_next_upgrade_text(item_id: String, is_equipped: bool) -> String:
	var upgrades: Dictionary = GameState.equipment_upgrades.get(item_id, {})
	var current_level := int(upgrades.get("level", 0))
	var current_quality := int(upgrades.get("quality", 0))
	var has_special := bool(upgrades.get("special_unlocked", false))
	var parts: Array[String] = []
	if current_level < 10:
		parts.append("锻级Lv.%d %d金" % [
			current_level + 1,
			GameState.get_equipment_upgrade_gold_cost("level", current_level)
		])
	if is_equipped and current_quality < 2:
		var quality_names := ["蓝", "红"]
		parts.append("升%s %d金" % [
			quality_names[mini(current_quality, 1)],
			GameState.get_equipment_upgrade_gold_cost("quality", current_quality)
		])
	elif not is_equipped:
		parts.append("升品/开特需装备")
	if is_equipped and not has_special:
		parts.append("开特 %d金" % GameState.get_equipment_upgrade_gold_cost("special", 1))
	if parts.is_empty():
		return "强化信息：已满"
	return "强化信息：%s" % "；".join(parts)

func _create_equipment_item_container(item: Dictionary, index: int, is_equipped: bool) -> Control:
	var container = Control.new()
	container.name = "UnifiedEquipmentItem"
	container.custom_minimum_size = Vector2(620, 126)

	var rarity_color = Color.WHITE
	match item.rarity:
		"white": rarity_color = Color(0.9, 0.9, 0.9)
		"blue": rarity_color = Color(0.6, 0.8, 1)
		"red": rarity_color = Color(1, 0.6, 0.6)

	var theme = GameState.get_era_theme()
	var card := Panel.new()
	card.custom_minimum_size = Vector2(620, 120)
	card.size = Vector2(620, 120)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = theme.get("bg", Color(0.1, 0.1, 0.14, 1.0)).lightened(0.04)
	card_style.border_color = rarity_color.darkened(0.15) if is_equipped else theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).darkened(0.25)
	card_style.set_border_width_all(1)
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", card_style)
	container.add_child(card)

	var info_vbox = VBoxContainer.new()
	info_vbox.position = Vector2(76, 8)
	info_vbox.custom_minimum_size = Vector2(340, 106)
	info_vbox.add_theme_constant_override("separation", 2)
	container.add_child(info_vbox)

	var icon_texture := _get_item_icon_texture(item)
	if icon_texture != null:
		var item_icon = TextureRect.new()
		item_icon.texture = icon_texture
		item_icon.position = Vector2(16, 18)
		item_icon.custom_minimum_size = Vector2(48, 48)
		item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(item_icon)

	var name_label = Label.new()
	name_label.text = "%s %s %s" % [
			_get_rarity_emoji(item.rarity),
		GameState.get_item_display_name(item),
		""
	]
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.modulate = rarity_color
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = _get_equipment_brief(item)
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.68, 0.68, 0.68)
	info_vbox.add_child(desc_label)

	info_vbox.add_child(_create_upgrade_info_label(_get_equipment_current_upgrade_text(str(item.id)), Color(0.56, 0.92, 0.56), 12, Vector2(330, 18)))
	info_vbox.add_child(_create_upgrade_info_label(_get_equipment_next_upgrade_text(str(item.id), is_equipped), Color(0.88, 0.78, 0.52), 12, Vector2(330, 34)))

	var source_badge := Label.new()
	source_badge.name = "EquipmentSourceBadge"
	source_badge.text = "装备中" if is_equipped else "背包"
	source_badge.position = Vector2(426, 12)
	source_badge.custom_minimum_size = Vector2(164, 22)
	source_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	source_badge.add_theme_font_size_override("font_size", 12)
	source_badge.modulate = Color(0.74, 0.94, 0.72) if is_equipped else Color(0.92, 0.74, 0.52)
	container.add_child(source_badge)

	# 按钮
	var btn_container = HBoxContainer.new()
	btn_container.custom_minimum_size = Vector2(176, 34)
	btn_container.add_theme_constant_override("separation", 6)
	btn_container.position = Vector2(426, 74)
	container.add_child(btn_container)

	var forge_btn = Button.new()
	forge_btn.name = "EquipmentForgeButton"
	forge_btn.text = "精修"
	forge_btn.custom_minimum_size = Vector2(82, 30)
	forge_btn.add_theme_font_size_override("font_size", 12)
	ArtRegistry.apply_button_icon(forge_btn, "upgrade", false, "锻造")
	forge_btn.pressed.connect(func(): _show_equipment_forge_menu(item.id, is_equipped))
	btn_container.add_child(forge_btn)

	if is_equipped:
		var unequip_btn = Button.new()
		unequip_btn.name = "EquipmentMoveButton"
		unequip_btn.text = "卸下"
		unequip_btn.custom_minimum_size = Vector2(82, 30)
		unequip_btn.add_theme_font_size_override("font_size", 12)
		ArtRegistry.apply_button_icon(unequip_btn, "back", true, "卸下装备")
		unequip_btn.pressed.connect(func(): _on_unequip_item(index))
		btn_container.add_child(unequip_btn)
	else:
		var equip_btn = Button.new()
		equip_btn.name = "EquipmentMoveButton"
		equip_btn.text = "装备"
		equip_btn.custom_minimum_size = Vector2(82, 30)
		equip_btn.add_theme_font_size_override("font_size", 12)
		ArtRegistry.apply_button_icon(equip_btn, "equip", true, "装备此物品")
		equip_btn.pressed.connect(func(): _on_equip_item(index))
		btn_container.add_child(equip_btn)

	return container

func _show_equipment_forge_menu(item_id: String, is_equipped: bool) -> void:
	var old := get_node_or_null("ForgeMenu")
	if old != null:
		old.queue_free()
	var menu := Panel.new()
	menu.name = "ForgeMenu"
	menu.position = Vector2(460, 196)
	menu.size = Vector2(360, 306)
	menu.z_index = 80
	var theme = GameState.get_era_theme()
	var style := StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.96)).darkened(0.04)
	style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	menu.add_theme_stylebox_override("panel", style)
	add_child(menu)

	var title := Label.new()
	title.text = "器物精修"
	title.position = Vector2(0, 12)
	title.custom_minimum_size = Vector2(360, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = theme.get("title", Color(1, 0.9, 0.7))
	menu.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "ForgeItemName"
	subtitle.text = _get_equipment_display_name(item_id)
	subtitle.position = Vector2(0, 38)
	subtitle.custom_minimum_size = Vector2(360, 20)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.modulate = Color(0.72, 0.72, 0.76)
	menu.add_child(subtitle)

	var upgrades = GameState.equipment_upgrades.get(item_id, {})
	var current_level := int(upgrades.get("level", 0))
	var current_quality := int(upgrades.get("quality", 0))
	var has_special := bool(upgrades.get("special_unlocked", false))
	var current_info := Label.new()
	current_info.name = "ForgeCurrentUpgradeInfo"
	current_info.text = _get_equipment_current_upgrade_text(item_id)
	current_info.position = Vector2(24, 66)
	current_info.custom_minimum_size = Vector2(312, 22)
	current_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_info.add_theme_font_size_override("font_size", 12)
	current_info.modulate = Color(0.56, 0.92, 0.56)
	menu.add_child(current_info)

	var next_info := Label.new()
	next_info.name = "ForgeNextUpgradeInfo"
	next_info.text = _get_equipment_next_upgrade_text(item_id, is_equipped)
	next_info.position = Vector2(24, 91)
	next_info.custom_minimum_size = Vector2(312, 34)
	next_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_info.add_theme_font_size_override("font_size", 12)
	next_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_info.modulate = Color(0.88, 0.78, 0.52)
	menu.add_child(next_info)

	var quality_names := ["蓝", "红"]
	var button_specs: Array[Dictionary] = [
		{
			"name": "ForgeLevelButton",
			"text": "锻级 Lv.%d  %d金" % [current_level + 1, GameState.get_equipment_upgrade_gold_cost("level", current_level)] if current_level < 10 else "锻级已满",
			"disabled": current_level >= 10,
			"call": func(): _on_equipment_level_upgrade(item_id)
		},
		{
			"name": "ForgeQualityButton",
			"text": "升%s  %d金" % [quality_names[mini(current_quality, 1)], GameState.get_equipment_upgrade_gold_cost("quality", current_quality)] if is_equipped and current_quality < 2 else ("升品已满" if is_equipped else "升品  装后"),
			"disabled": (not is_equipped) or current_quality >= 2,
			"call": func(): _on_equipment_quality_upgrade(item_id)
		},
		{
			"name": "ForgeSpecialButton",
			"text": "开特  %d金" % GameState.get_equipment_upgrade_gold_cost("special", 1) if is_equipped and not has_special else ("开特已满" if is_equipped else "开特  装后"),
			"disabled": (not is_equipped) or has_special,
			"call": func(): _on_equipment_special_upgrade(item_id)
		}
	]
	for i in range(button_specs.size()):
		var spec := button_specs[i]
		var btn := Button.new()
		btn.name = str(spec.get("name", "ForgeButton"))
		btn.text = str(spec.get("text", ""))
		btn.disabled = bool(spec.get("disabled", false))
		btn.position = Vector2(62, 136 + i * 40)
		btn.custom_minimum_size = Vector2(236, 34)
		btn.add_theme_font_size_override("font_size", 13)
		ArtRegistry.apply_button_icon(btn, "upgrade", false, "锻造")
		var callback: Callable = spec.get("call", Callable())
		btn.pressed.connect(func():
			if callback.is_valid():
				callback.call()
			if is_instance_valid(menu):
				menu.queue_free()
		)
		menu.add_child(btn)

	var exit_btn := Button.new()
	exit_btn.name = "ForgeExitButton"
	exit_btn.text = "返回器物库"
	exit_btn.position = Vector2(62, 256)
	exit_btn.custom_minimum_size = Vector2(236, 30)
	exit_btn.add_theme_font_size_override("font_size", 13)
	ArtRegistry.apply_button_icon(exit_btn, "back", false, "不强化，返回器物库")
	exit_btn.pressed.connect(_hide_equipment_forge_menu)
	menu.add_child(exit_btn)

func _hide_equipment_forge_menu() -> void:
	var menu := get_node_or_null("ForgeMenu")
	if menu != null:
		menu.queue_free()

func _get_rarity_emoji(rarity: String) -> String:
	match rarity:
		"white": return "⚪"
		"blue": return "🔵"
		"red": return "🔴"
		_: return "⚪"

func _get_equipment_brief(item: Dictionary) -> String:
	var item_id := str(item.get("id", ""))
	var desc := GameState.get_item_display_description(item)
	if item_id in ["long_sword", "demon_blade", "bounty_blade", "regicide"] or desc.contains("攻击") or desc.contains("伤害"):
		return "锋"
	if item_id in ["wooden_shield", "heart_mirror", "tiger_tally", "counter_sigil"] or desc.contains("护甲") or desc.contains("护盾"):
		return "甲"
	if item_id in ["life_crystal", "vampire_cross", "blood_tyrant", "afterlife_lamp"] or desc.contains("恢复") or desc.contains("命数"):
		return "命"
	if item_id in ["trade_ledger", "greedy_gloves", "broken_coin"] or desc.contains("金币"):
		return "财"
	if item_id in ["precision_guidance", "precision_auxiliary", "precision_calculation", "ai_system", "unity_seal"]:
		return "机"
	if item_id in ["camp_banner"]:
		return "营"
	return "器"

## ========== 恢复按钮回调 ==========

func _on_full_heal() -> void:
	var before_hp := GameState.player_hp
	var before_shield := GameState.player_shield
	var side_reward := _get_rest_side_reward_text(true)
	GameState.player_hp = GameState.player_max_hp
	if not GameState.shield_persists_between_battles():
		GameState.player_shield = 0
	match GameState.selected_era_id:
		"song":
			GameState.player_gold += 8
			EventBus.player_gold_changed.emit(GameState.player_gold)
		"china":
			GameState.add_cheat_point()
		_:
			GameState.player_shield += 2
	GameState.save_progress("rest")
	_update_heal_panel_status()
	_set_heal_feedback(_format_heal_feedback("充分休息", before_hp, before_shield, side_reward))
	DebugLog.log("[RestPoint] 充分休息: HP恢复至100%")

func _on_half_heal() -> void:
	var before_hp := GameState.player_hp
	var before_shield := GameState.player_shield
	var side_reward := _get_rest_side_reward_text(false)
	var heal_amount = _get_half_rest_recovery_cap()
	GameState.player_hp = mini(GameState.player_hp + heal_amount, GameState.player_max_hp)
	match GameState.selected_era_id:
		"song":
			GameState.player_shield += 1
		"china":
			GameState.add_cheat_point()
		_:
			GameState.player_shield += 1
	GameState.save_progress("rest")
	_update_heal_panel_status()
	_set_heal_feedback(_format_heal_feedback("稍作歇息", before_hp, before_shield, side_reward))
	DebugLog.log("[RestPoint] 稍微休息: HP恢复50%%")

func _update_heal_panel_status() -> void:
	if not _heal_panel:
		return

	var hp_label = _heal_panel.find_child("HPLabel", true, false) as Label
	if hp_label:
		hp_label.text = _get_numeric_hp_status_text()

	var shield_label = _heal_panel.find_child("ShieldLabel", true, false) as Label
	if shield_label:
		shield_label.text = "🛡️ 护甲: %d" % GameState.player_shield

	var preview_label = _heal_panel.find_child("RestHealPreviewLabel", true, false) as Label
	if preview_label:
		preview_label.text = _get_heal_preview_text()

	var full_btn = _heal_panel.find_child("FullHealButton", true, false) as Button
	var half_btn = _heal_panel.find_child("HalfHealButton", true, false) as Button
	if full_btn and half_btn:
		_apply_heal_button_state(full_btn, half_btn)

	_refresh_top_status_label()

## ========== 连招强化回调 ==========

func _on_combo_upgrade(combo_id: String) -> void:
	var result = GameState.apply_combo_upgrade(combo_id, "upgrade")
	if result.success:
		GameState.save_progress("rest")
		_refresh_combo_panel()
		_show_upgrade_effect(
			"combo",
			"布局强化",
			_get_combo_display_name(combo_id),
			"升至 Lv.%d\n%s" % [int(result.get("new_level", 0)), str(result.get("current_effect", ""))]
		)
		DebugLog.log("[RestPoint] 连招强化: %s, %s, 消耗%d金币" % [combo_id, result.current_effect, result.cost])
	else:
		DebugLog.log("[RestPoint] 强化失败: ", result.get("error", "未知错误"))

func _refresh_combo_panel() -> void:
	# 重新生成连招面板以刷新显示（金币信号已在 apply_xxx_upgrade 中 emit）
	if _combo_panel:
		if _combo_panel.get_parent() != null:
			_combo_panel.get_parent().remove_child(_combo_panel)
		_combo_panel.queue_free()
		_combo_panel = null
	_combo_panel = _create_combo_upgrade_panel()
	_combo_panel.position = COMBO_PANEL_POSITION
	add_child(_combo_panel)

## ========== 装备强化回调 ==========

func _on_equipment_level_upgrade(item_id: String) -> void:
	var result = GameState.apply_equipment_upgrade(item_id, "level")
	if result.success:
		GameState.save_progress("rest")
		_refresh_equip_panel()
		_show_upgrade_effect(
			"equipment",
			"器物锻造",
			_get_equipment_display_name(item_id),
			"升至 Lv.%d\n%s" % [int(result.get("new_level", 0)), str(result.get("current_effect", ""))]
		)
		DebugLog.log("[RestPoint] 装备等级提升: %s, %s, 消耗%d金币" % [item_id, result.current_effect, result.cost])
	else:
		DebugLog.log("[RestPoint] 强化失败: ", result.get("error", "未知错误"))

func _on_equipment_quality_upgrade(item_id: String) -> void:
	var result = GameState.apply_equipment_upgrade(item_id, "quality")
	if result.success:
		GameState.save_progress("rest")
		_refresh_equip_panel()
		_show_upgrade_effect(
			"equipment",
			"品质进阶",
			_get_equipment_display_name(item_id),
			str(result.get("current_effect", ""))
		)
		DebugLog.log("[RestPoint] 装备品质进阶: %s, %s, 消耗%d金币" % [item_id, result.current_effect, result.cost])
	else:
		DebugLog.log("[RestPoint] 强化失败: ", result.get("error", "未知错误"))

func _on_equipment_special_upgrade(item_id: String) -> void:
	var result = GameState.apply_equipment_upgrade(item_id, "special")
	if result.success:
		GameState.save_progress("rest")
		_refresh_equip_panel()
		_show_upgrade_effect(
			"equipment",
			"特效觉醒",
			_get_equipment_display_name(item_id),
			str(result.get("current_effect", ""))
		)
		DebugLog.log("[RestPoint] 装备特效解锁: %s, %s, 消耗%d金币" % [item_id, result.current_effect, result.cost])
	else:
		DebugLog.log("[RestPoint] 强化失败: ", result.get("error", "未知错误"))

func _on_equip_item(backpack_index: int) -> void:
	if GameState.equipment_slot.size() < GameState.get_current_equipment_slot_limit():
		if GameState.equip_from_backpack(backpack_index):
			GameState.save_progress("rest")
			_refresh_equip_panel()
			DebugLog.log("[RestPoint] 从背包装备物品")
		else:
			DebugLog.log("[RestPoint] 装备失败")
	else:
		_show_equipment_swap_dialog(backpack_index)

func _on_unequip_item(equipment_index: int) -> void:
	if GameState.unequip_to_backpack(equipment_index):
		GameState.save_progress("rest")
		_refresh_equip_panel()
		DebugLog.log("[RestPoint] 卸下物品到背包")
	else:
		DebugLog.log("[RestPoint] 卸下失败（背包已满）")

func _refresh_equip_panel() -> void:
	# 重新生成装备面板以刷新显示（金币信号已在 apply_xxx_upgrade 中 emit）
	_hide_equipment_forge_menu()
	if _equip_panel:
		_equip_panel.queue_free()
		_equip_panel = null
	_equip_panel = _create_equipment_upgrade_panel()
	_equip_panel.position = EQUIPMENT_PANEL_POSITION
	add_child(_equip_panel)

func _show_upgrade_effect(effect_kind: String, title_text: String, target_text: String, detail_text: String) -> void:
	var old_overlay := get_node_or_null("UpgradeEffectOverlay")
	if old_overlay != null:
		remove_child(old_overlay)
		old_overlay.queue_free()
	var overlay := Control.new()
	overlay.name = "UpgradeEffectOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var accent := Color(1.0, 0.70, 0.32, 1.0)
	if effect_kind == "combo":
		accent = Color(0.98, 0.52, 0.26, 1.0)
	elif effect_kind == "equipment":
		accent = Color(0.48, 0.72, 1.0, 1.0)

	var flash := ColorRect.new()
	flash.name = "UpgradeFlash"
	flash.color = Color(accent.r, accent.g, accent.b, 0.16)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(flash)

	var burst := Panel.new()
	burst.name = "UpgradeBurstCard"
	burst.position = Vector2(398, 218)
	burst.size = Vector2(484, 174)
	burst.scale = Vector2(0.72, 0.72)
	burst.pivot_offset = Vector2(242, 87)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.075, 0.065, 0.94)
	style.border_color = accent
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	burst.add_theme_stylebox_override("panel", style)
	overlay.add_child(burst)

	var title := Label.new()
	title.name = "UpgradeEffectTitle"
	title.text = title_text
	title.position = Vector2(398, 232)
	title.custom_minimum_size = Vector2(484, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.01, 1.0))
	title.add_theme_constant_override("outline_size", 3)
	title.modulate = accent.lightened(0.18)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(title)

	var target := Label.new()
	target.name = "UpgradeEffectTarget"
	target.text = target_text
	target.position = Vector2(420, 275)
	target.custom_minimum_size = Vector2(440, 28)
	target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target.add_theme_font_size_override("font_size", 20)
	target.modulate = Color(0.96, 0.92, 0.82, 1.0)
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(target)

	var detail := Label.new()
	detail.name = "UpgradeEffectDetail"
	detail.text = detail_text
	detail.position = Vector2(420, 314)
	detail.custom_minimum_size = Vector2(440, 58)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 17)
	detail.modulate = Color(0.84, 0.90, 1.0, 1.0) if effect_kind == "equipment" else Color(1.0, 0.84, 0.62, 1.0)
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(detail)

	for i in range(10):
		var spark := ColorRect.new()
		spark.name = "UpgradeSpark%d" % i
		spark.color = Color(accent.r, accent.g, accent.b, 0.82)
		spark.position = Vector2(620 + cos(float(i) * 0.63) * 72, 306 + sin(float(i) * 0.63) * 36)
		spark.custom_minimum_size = Vector2(6, 6)
		spark.size = Vector2(6, 6)
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(spark)
		var spark_tween := create_tween()
		spark_tween.set_parallel(true)
		spark_tween.tween_property(spark, "position", spark.position + Vector2(cos(float(i) * 0.63) * 92, sin(float(i) * 0.63) * 58), 0.52).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		spark_tween.tween_property(spark, "color:a", 0.0, 0.50)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "color:a", 0.0, 0.70)
	tween.tween_property(burst, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(burst, "modulate:a", 1.0, 0.16).from(0.0)
	tween.tween_property(title, "position:y", 218.0, 0.30).from(250.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.28).set_delay(0.82)
	tween.chain().tween_callback(func():
		if is_instance_valid(overlay):
			overlay.queue_free()
	)

func _get_combo_display_name(combo_id: String) -> String:
	var base_names := {
		"penetrating_strike": "全体穿透",
		"tactical_interference": "战术干扰",
		"lightning_strike": "闪电突袭",
		"solid_defense": "稳固防御",
		"energy_charge": "能量充能",
		"cyclic_shield": "循环护盾",
		"bind_fatal": "束缚致命",
		"double_strike": "双重打击",
		"qin_tiger_push": "虎符压阵",
		"song_trade_turn": "市舶周转",
		"china_unity_echo": "山河同契",
		"bloodthirsty_slash": "嗜血斩",
		"reflect_aura": "反伤光环",
		"absolute_hit": "绝对命中",
		"desperate_counter": "绝地反击",
		"iron_fortress": "铁壁反震",
		"supply_bombard": "物资轰炸",
		"diagnose": "望闻问切",
		"heal_wave": "妙手回春",
		"virus_implant": "病毒植入",
		"system_overload": "系统过载",
		"money_empire": "金钱帝国",
		"precise_mind": "精算头脑",
		"iron_wall": "固若金汤",
		"harvest_blessing": "五谷丰登",
		"memory_burst": "记忆爆破",
		"phase_guard": "相位护盾",
		"formation_breaker": "破阵连环",
		"mountain_reversal": "山岳回震",
		"lockstep_snare": "连环锁势",
		"renewal_cycle": "生息轮转",
		"trade_tide": "商潮回涌",
		"last_lamp_reversal": "残灯逆照",
		"arsenal_unload": "倾仓齐发",
		"pierce": "穿刺",
		"whirlwind": "旋风",
		"crush": "粉碎"
	}
	var base_name := str(base_names.get(combo_id, combo_id))
	return _get_era_combo_name(base_name)

func _get_equipment_display_name(item_id: String) -> String:
	var item_data: Dictionary = GameState.ITEMS.get(item_id, {})
	if item_data.is_empty():
		return item_id
	return GameState.get_item_display_name(item_data)

## ========== 装备交换选择界面 ==========

var _pending_backpack_index: int = -1

func _show_equipment_swap_dialog(backpack_index: int) -> void:
	_pending_backpack_index = backpack_index
	var incoming_item = GameState.backpack[backpack_index]

	# 创建遮罩层
	var overlay = ColorRect.new()
	overlay.name = "SwapOverlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# 创建对话框
	var dialog = PanelContainer.new()
	dialog.name = "SwapDialog"
	dialog.custom_minimum_size = Vector2(500, 400)
	dialog.position = Vector2(390, 160)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.28, 0.98)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.7, 1, 0.6)
	dialog.add_theme_stylebox_override("panel", style)
	add_child(dialog)

	var dialog_vbox = VBoxContainer.new()
	dialog_vbox.custom_minimum_size = Vector2(480, 380)
	dialog_vbox.add_theme_constant_override("separation", 10)
	dialog.add_child(dialog_vbox)

	var title_label = Label.new()
	title_label.text = "⚔️ 装备栏已满，请选择要替换的装备"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.modulate = Color(1, 0.85, 0.5)
	dialog_vbox.add_child(title_label)

	# 待装备物品信息
	var incoming_container = HBoxContainer.new()
	incoming_container.custom_minimum_size = Vector2(460, 40)
	dialog_vbox.add_child(incoming_container)

	var incoming_name = Label.new()
	incoming_name.text = "📥 将装备: %s %s" % [_get_rarity_emoji(incoming_item.rarity), GameState.get_item_display_name(incoming_item)]
	incoming_name.add_theme_font_size_override("font_size", 15)
	incoming_name.modulate = _get_rarity_color(incoming_item.rarity)
	incoming_container.add_child(incoming_name)

	var incoming_desc = Label.new()
	incoming_desc.text = GameState.get_item_display_description(incoming_item)
	incoming_desc.custom_minimum_size = Vector2(460, 0)
	incoming_desc.add_theme_font_size_override("font_size", 12)
	incoming_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	incoming_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	incoming_desc.modulate = Color(0.85, 0.85, 0.8)
	dialog_vbox.add_child(incoming_desc)

	# 分隔线
	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(460, 2)
	dialog_vbox.add_child(separator)

	# 装备栏选择区域
	var select_title = Label.new()
	select_title.text = "━━━ 点击下方装备进行替换 ━━━"
	select_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_title.add_theme_font_size_override("font_size", 13)
	select_title.modulate = Color(0.7, 0.7, 0.7)
	dialog_vbox.add_child(select_title)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(460, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialog_vbox.add_child(scroll)

	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.custom_minimum_size = Vector2(440, 200)
	scroll_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(scroll_vbox)

	for i in range(GameState.equipment_slot.size()):
		var equip_item = GameState.equipment_slot[i]
		var equip_btn = Button.new()
		equip_btn.custom_minimum_size = Vector2(440, 72)
		var equip_text = "%s %s" % [_get_rarity_emoji(equip_item.rarity), GameState.get_item_display_name(equip_item)]
		var source_text = GameState.get_item_source_text(equip_item)
		if source_text != "":
			equip_text += "\n%s" % source_text
		equip_btn.text = equip_text
		equip_btn.add_theme_font_size_override("font_size", 13)
		equip_btn.modulate = _get_rarity_color(equip_item.rarity)
		ArtRegistry.apply_button_icon(equip_btn, "equip", false, "选择要替换的装备")
		equip_btn.pressed.connect(_on_select_equipment_to_swap.bind(i))
		scroll_vbox.add_child(equip_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(460, 35)
	cancel_btn.add_theme_font_size_override("font_size", 14)
	cancel_btn.modulate = Color(0.7, 0.7, 0.7)
	ArtRegistry.apply_button_icon(cancel_btn, "back", false, "取消替换")
	cancel_btn.pressed.connect(_hide_swap_dialog)
	dialog_vbox.add_child(cancel_btn)

func _on_select_equipment_to_swap(equipment_index: int) -> void:
	if _pending_backpack_index < 0:
		return

	if GameState.swap_equipment_with_backpack(equipment_index, _pending_backpack_index):
		DebugLog.log("[RestPoint] 装备交换成功！")
		GameState.save_progress("rest")
		_hide_swap_dialog()
		_refresh_equip_panel()
	else:
		DebugLog.log("[RestPoint] 装备交换失败！")
		_hide_swap_dialog()

func _hide_swap_dialog() -> void:
	_pending_backpack_index = -1
	var overlay = get_node_or_null("SwapOverlay")
	var dialog = get_node_or_null("SwapDialog")
	if overlay:
		overlay.queue_free()
	if dialog:
		dialog.queue_free()

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"white": return Color(0.9, 0.9, 0.9)
		"blue": return Color(0.6, 0.8, 1)
		"red": return Color(1, 0.6, 0.6)
		_: return Color.WHITE

## ========== 继续按钮 ==========

func _on_continue_pressed() -> void:
	continue_to_next_floor.emit()
