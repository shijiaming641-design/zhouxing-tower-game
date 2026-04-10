class_name RestPointScene
extends Control

## 休息点场景 - 楼层结束后的恢复和强化界面
## 优化：初始显示三个按钮选择界面，用户点击后进入对应功能

signal continue_to_next_floor

const MOVE_SYMBOLS: Array[String] = ["○", "△", "□"]

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

func _ready() -> void:
	# 连接材料变化信号
	EventBus.materials_changed.connect(_on_materials_changed)
	if GameState.on_enter_rest_point():
		GameState.save_progress("rest")
	_setup_choice_ui()
	_show_choice_mode()

func _on_materials_changed(new_amount: int) -> void:
	"""材料变化时实时更新所有材料显示"""
	var text = "🔧 材料: %d" % new_amount
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
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.18)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	bg.name = "Background"
	add_child(bg)
	
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
	
	# 标题
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "🏕️ 第 %d 层完成 - 休息站" % (GameState.current_floor)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 15
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.9, 0.7)
	top_bar.add_child(title)
	
	# 材料显示
	var materials_label = Label.new()
	materials_label.name = "MaterialsLabel"
	materials_label.text = "🔧 材料: %d" % GameState.materials
	materials_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	materials_label.offset_left = 30
	materials_label.offset_top = 20
	materials_label.add_theme_font_size_override("font_size", 20)
	materials_label.modulate = Color(0.9, 0.8, 0.4)
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
	status_label.modulate = Color(0.8, 0.8, 0.8)
	top_bar.add_child(status_label)
	
	return top_bar

func _get_player_status_text() -> String:
	var hp_bar = ""
	for i in range(GameState.player_max_hp):
		hp_bar += "❤️" if i < GameState.player_hp else "🖤"
	return "%s 💰%d | %s" % [hp_bar, GameState.player_gold, GameState.get_level_progress_text()]

func _create_choice_buttons() -> void:
	"""创建三个大按钮"""
	var container = Control.new()
	container.name = "ChoiceButtonsContainer"
	container.custom_minimum_size = Vector2(1280, 450)
	container.position = Vector2(0, 120)
	_choice_container.add_child(container)
	
	# 按钮配置
	var buttons = [
		{
			"icon": "💤",
			"title": "休息恢复",
			"desc": "恢复HP/状态\n免费充分休息",
			"color": Color(0.3, 0.8, 0.4),
			"action": "_on_heal_selected"
		},
		{
			"icon": "⚔️",
			"title": "装备升级",
			"desc": "强化装备\n提升战斗力",
			"color": Color(0.4, 0.6, 0.9),
			"action": "_on_equip_selected"
		},
		{
			"icon": "🔥",
			"title": "连招升级",
			"desc": "解锁/升级连招\n增强战斗技能",
			"color": Color(0.9, 0.5, 0.3),
			"action": "_on_combo_selected"
		}
	]
	
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
	
	# 创建按钮内容容器
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(width, height)
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# 图标
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
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# 描述
	var desc_label = Label.new()
	desc_label.text = btn_data.desc
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.modulate = Color(0.6, 0.6, 0.6)
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
	
	# 隐藏详情面板
	if _heal_panel:
		_heal_panel.visible = false
	if _combo_panel:
		_combo_panel.visible = false
	if _equip_panel:
		_equip_panel.visible = false
	
	# 显示选择界面
	if _choice_container:
		_choice_container.visible = true
	
	# 显示底部栏（只有继续按钮）
	_show_bottom_bar_only_continue()

func _show_bottom_bar_only_continue() -> void:
	"""底部栏：只有继续按钮"""
	if _bottom_bar:
		_bottom_bar.queue_free()
	
	_bottom_bar = Control.new()
	_bottom_bar.name = "BottomBar"
	_bottom_bar.custom_minimum_size = Vector2(1280, 80)
	_bottom_bar.position = Vector2(0, 640)
	add_child(_bottom_bar)
	
	var continue_btn = Button.new()
	continue_btn.text = "继续下一层 →"
	continue_btn.custom_minimum_size = Vector2(200, 55)
	continue_btn.position = Vector2(540, 10)
	continue_btn.add_theme_font_size_override("font_size", 22)
	continue_btn.modulate = Color(0.7, 1, 0.7)
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
	# 隐藏选择界面
	if _choice_container:
		_choice_container.visible = false
	
	# 显示/创建对应面板
	match panel_name:
		"heal":
			if not _heal_panel:
				_heal_panel = _create_heal_panel()
				_heal_panel.position = Vector2(50, 100)
				add_child(_heal_panel)
			_heal_panel.visible = true
		"combo":
			if not _combo_panel:
				_combo_panel = _create_combo_upgrade_panel()
				_combo_panel.position = Vector2(30, 100)
				add_child(_combo_panel)
			_combo_panel.visible = true
		"equip":
			if not _equip_panel:
				_equip_panel = _create_equipment_upgrade_panel()
				_equip_panel.position = Vector2(800, 100)
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
	
	# 返回按钮
	var back_btn = Button.new()
	back_btn.text = "← 返回"
	back_btn.custom_minimum_size = Vector2(120, 50)
	back_btn.position = Vector2(50, 10)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.modulate = Color(0.8, 0.8, 0.8)
	back_btn.pressed.connect(_show_choice_mode)
	_bottom_bar.add_child(back_btn)
	
	# 材料显示
	var materials_label = Label.new()
	materials_label.name = "MaterialsLabel"
	materials_label.text = "🔧 材料: %d" % GameState.materials
	materials_label.position = Vector2(560, 15)
	materials_label.add_theme_font_size_override("font_size", 18)
	materials_label.modulate = Color(0.9, 0.8, 0.4)
	_bottom_bar.add_child(materials_label)
	_bottom_materials_label = materials_label
	
	# 继续按钮
	var continue_btn = Button.new()
	continue_btn.text = "继续下一层 →"
	continue_btn.custom_minimum_size = Vector2(180, 50)
	continue_btn.position = Vector2(980, 10)
	continue_btn.add_theme_font_size_override("font_size", 20)
	continue_btn.modulate = Color(0.7, 1, 0.7)
	continue_btn.pressed.connect(_on_continue_pressed)
	_bottom_bar.add_child(continue_btn)

## ========== 恢复面板 ==========

func _create_heal_panel() -> Control:
	var panel = Control.new()
	panel.name = "HealPanel"
	panel.custom_minimum_size = Vector2(350, 500)
	
	# 背景
	var bg = Panel.new()
	bg.custom_minimum_size = Vector2(350, 500)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.15, 0.9)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.8, 0.4, 0.5)
	bg.add_theme_stylebox_override("panel", style)
	panel.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(330, 480)
	vbox.add_theme_constant_override("separation", 20)
	vbox.position = Vector2(10, 10)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "💤 休息恢复"
	title.add_theme_font_size_override("font_size", 26)
	title.modulate = Color(0.4, 1, 0.5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# 状态显示
	var status_container = VBoxContainer.new()
	status_container.add_theme_constant_override("separation", 10)
	vbox.add_child(status_container)
	
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	var hp_bar = ""
	for i in range(GameState.player_max_hp):
		hp_bar += "❤️" if i < GameState.player_hp else "🖤"
	hp_label.text = "❤️ 生命: %s\n%d/%d" % [hp_bar, GameState.player_hp, GameState.player_max_hp]
	hp_label.add_theme_font_size_override("font_size", 18)
	status_container.add_child(hp_label)
	
	var shield_label = Label.new()
	shield_label.name = "ShieldLabel"
	shield_label.text = "🛡️ 护甲: %d" % GameState.player_shield
	shield_label.add_theme_font_size_override("font_size", 18)
	status_container.add_child(shield_label)
	
	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "💰 金币: %d" % GameState.player_gold
	gold_label.add_theme_font_size_override("font_size", 18)
	status_container.add_child(gold_label)
	
	# 分隔线
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(300, 2)
	vbox.add_child(sep)
	
	# 恢复选项
	var full_btn = Button.new()
	full_btn.text = "💤 充分休息\n恢复100% HP"
	full_btn.custom_minimum_size = Vector2(300, 80)
	full_btn.add_theme_font_size_override("font_size", 20)
	full_btn.modulate = Color(0.6, 1, 0.6)
	full_btn.pressed.connect(_on_full_heal)
	vbox.add_child(full_btn)
	
	var half_btn = Button.new()
	half_btn.text = "😴 稍微休息\n恢复50% HP"
	half_btn.custom_minimum_size = Vector2(300, 80)
	half_btn.add_theme_font_size_override("font_size", 20)
	half_btn.modulate = Color(0.8, 0.9, 0.6)
	half_btn.pressed.connect(_on_half_heal)
	vbox.add_child(half_btn)
	
	# 提示
	var hint = Label.new()
	hint.text = "休息可以恢复HP，农民会保留护甲"
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(0.5, 0.5, 0.5)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)
	
	return panel

## ========== 连招升级面板 ==========

func _create_combo_upgrade_panel() -> Control:
	var panel = Control.new()
	panel.name = "ComboPanel"
	panel.custom_minimum_size = Vector2(500, 550)
	
	# 背景
	var bg = Panel.new()
	bg.custom_minimum_size = Vector2(500, 550)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.15, 0.12, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.9, 0.5, 0.3, 0.5)
	bg.add_theme_stylebox_override("panel", style)
	panel.add_child(bg)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 530)
	scroll.position = Vector2(10, 10)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(460, 900)
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "🔥 连招升级"
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(1, 0.6, 0.4)
	vbox.add_child(title)
	
	# 创建连招数据库实例
	var combo_db = load("res://resources/combo_database.gd").new()
	combo_db._init_database()
	add_child(combo_db)  # 需要添加到场景树才能访问
	
	# ===== 战斗连招（玩家本局携带的连招）=====
	var combat_title = Label.new()
	combat_title.text = "━━━ 战斗连招 ━━━"
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
		empty.text = "（无携带战斗连招）"
		empty.add_theme_font_size_override("font_size", 14)
		empty.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(empty)
	
	# ===== 武器专属连招 ======
	var weapon_title = Label.new()
	weapon_title.text = "━━━ 武器专属连招 ━━━"
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
		empty.text = "（无武器专属连招）"
		empty.add_theme_font_size_override("font_size", 14)
		empty.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(empty)
	
	# ===== 角色专属连招 ======
	var role_title = Label.new()
	role_title.text = "━━━ 角色专属连招 ━━━"
	role_title.add_theme_font_size_override("font_size", 14)
	role_title.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(role_title)
	
	# 获取角色专属连招
	var exclusive_combos = GameState.get_exclusive_combos()
	print("[RestPoint] 获取到专属连招数量: ", exclusive_combos.size())
	
	if exclusive_combos.is_empty():
		var empty = Label.new()
		empty.text = "（当前职业无专属连招）"
		empty.add_theme_font_size_override("font_size", 14)
		empty.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(empty)
	else:
		for combo in exclusive_combos:
			var combo_container = _create_skill_combo_item(combo_db, combo)
			vbox.add_child(combo_container)
	
	return panel

func _create_unlocked_combo_item(combo_db, combo) -> Control:
	"""显示玩家已解锁的战斗连招（开局选择的）"""
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(440, 110)
	container.add_theme_constant_override("separation", 5)
	
	var name_label = Label.new()
	var seq_str = combo_db.sequence_to_display(combo.sequence)
	name_label.text = "%s [%s]" % [combo.name, seq_str]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.modulate = Color(1, 0.9, 0.5)
	container.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = combo.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.6, 0.6, 0.6)
	container.add_child(desc_label)
	
	# 获取当前强化等级
	var current_level = GameState.get_combo_upgrade_level(combo.id)
	
	# 显示当前强化效果
	var current_effect_label = Label.new()
	var effect_text = "当前效果: %s" % _get_combo_upgrade_summary(combo.id)
	current_effect_label.text = effect_text
	current_effect_label.add_theme_font_size_override("font_size", 12)
	current_effect_label.modulate = Color(0.5, 0.9, 0.5)
	container.add_child(current_effect_label)
	
	# 强化按钮（三层强化）
	var upgrade_btn = Button.new()
	if current_level >= 5:
		upgrade_btn.text = "✅ 已满级 (+50%%+灼烧+减速)"
		upgrade_btn.disabled = true
	else:
		var next_level = current_level + 1
		upgrade_btn.text = "⬆️ 第%d层 → %s (消耗%d材料)" % [next_level, _get_combo_upgrade_preview(next_level), next_level]
	upgrade_btn.custom_minimum_size = Vector2(420, 32)
	upgrade_btn.add_theme_font_size_override("font_size", 12)
	upgrade_btn.pressed.connect(func(): _on_combo_upgrade(combo.id))
	container.add_child(upgrade_btn)
	
	return container

func _create_combat_combo_item(combo_db, combat_combo) -> Control:
	"""显示战斗连招（CombatCombo类型）"""
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(440, 110)
	container.add_theme_constant_override("separation", 5)
	
	var name_label = Label.new()
	var seq_str = combo_db.combat_combo_sequence_to_display(combat_combo.sequence)
	name_label.text = "%s %s" % [combat_combo.name, seq_str]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.modulate = Color(1, 0.9, 0.5)
	container.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = "%d次攻击，每次%d%%伤害" % [combat_combo.attack_count, combat_combo.base_damage]
	if combat_combo.special_effect != "none":
		desc_label.text += " +%s" % _get_effect_name(combat_combo.special_effect)
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.6, 0.6, 0.6)
	container.add_child(desc_label)
	
	# 获取当前强化等级
	var current_level = GameState.get_combo_upgrade_level(combat_combo.id)
	
	# 显示当前强化效果
	var current_effect_label = Label.new()
	var effect_text = "当前效果: %s" % _get_combo_upgrade_summary(combat_combo.id)
	current_effect_label.text = effect_text
	current_effect_label.add_theme_font_size_override("font_size", 12)
	current_effect_label.modulate = Color(0.5, 0.9, 0.5)
	container.add_child(current_effect_label)
	
	# 强化按钮（三层强化）
	var upgrade_btn = Button.new()
	if current_level >= 5:
		upgrade_btn.text = "✅ 已满级 (+50%%+灼烧+减速)"
		upgrade_btn.disabled = true
	else:
		var next_level = current_level + 1
		upgrade_btn.text = "⬆️ 第%d层 → %s (消耗%d材料)" % [next_level, _get_combo_upgrade_preview(next_level), next_level]
	upgrade_btn.custom_minimum_size = Vector2(420, 32)
	upgrade_btn.add_theme_font_size_override("font_size", 12)
	upgrade_btn.pressed.connect(func(): _on_combo_upgrade(combat_combo.id))
	container.add_child(upgrade_btn)
	
	return container

func _create_skill_combo_item(combo_db, combo) -> Control:
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(440, 100)
	container.add_theme_constant_override("separation", 5)
	
	var combo_id = combo.combo_id
	var combo_name = combo.display_name
	var combo_seq = combo.sequence
	var combo_desc = combo.description if combo.description else ""
	
	var name_label = Label.new()
	var seq_str = combo_db.sequence_to_display(combo_seq)
	name_label.text = "%s [%s]" % [combo_name, seq_str]
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.modulate = Color(0.9, 0.8, 0.6)
	container.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = combo_desc
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.6, 0.6, 0.6)
	container.add_child(desc_label)
	
	# 获取当前强化等级
	var current_level = GameState.get_combo_upgrade_level(combo_id)
	
	# 显示当前强化效果
	var current_effect_label = Label.new()
	var effect_text = "当前效果: %s" % _get_combo_upgrade_summary(combo_id)
	current_effect_label.text = effect_text
	current_effect_label.add_theme_font_size_override("font_size", 11)
	current_effect_label.modulate = Color(0.5, 0.9, 0.5)
	container.add_child(current_effect_label)
	
	# 强化按钮（三层强化）
	var upgrade_btn = Button.new()
	if current_level >= 5:
		upgrade_btn.text = "✅ 已满级 (+50%%+灼烧+减速)"
		upgrade_btn.disabled = true
	else:
		var next_level = current_level + 1
		upgrade_btn.text = "⬆️ 第%d层 → %s (消耗%d材料)" % [next_level, _get_combo_upgrade_preview(next_level), next_level]
	upgrade_btn.custom_minimum_size = Vector2(420, 28)
	upgrade_btn.add_theme_font_size_override("font_size", 12)
	upgrade_btn.pressed.connect(func(): _on_combo_upgrade(combo_id))
	container.add_child(upgrade_btn)
	
	return container

func _create_weapon_combo_item(combo_db, combo, has_requirement: bool) -> Control:
	"""显示武器专属连招"""
	var container = VBoxContainer.new()
	container.custom_minimum_size = Vector2(440, 110)
	container.add_theme_constant_override("separation", 5)
	
	var name_label = Label.new()
	var seq_str = combo_db.sequence_to_display(combo.sequence)
	name_label.text = "%s [%s]" % [combo.name, seq_str]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.modulate = Color(1, 0.7, 0.3)  # 橙色表示武器专属
	container.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = combo.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.6, 0.6, 0.6)
	container.add_child(desc_label)
	
	# 检查是否有对应装备
	if not has_requirement:
		var lock_label = Label.new()
		lock_label.text = "🔒 需要对应装备"
		lock_label.add_theme_font_size_override("font_size", 12)
		lock_label.modulate = Color(0.5, 0.5, 0.5)
		container.add_child(lock_label)
	else:
		# 获取当前强化等级
		var current_level = GameState.get_combo_upgrade_level(combo.id)
		
		# 显示当前强化效果
		var current_effect_label = Label.new()
		var effect_text = "当前效果: %s" % _get_combo_upgrade_summary(combo.id)
		current_effect_label.text = effect_text
		current_effect_label.add_theme_font_size_override("font_size", 12)
		current_effect_label.modulate = Color(0.5, 0.9, 0.5)
		container.add_child(current_effect_label)
		
		# 强化按钮
		var upgrade_btn = Button.new()
		if current_level >= 5:
			upgrade_btn.text = "✅ 已满级 (+50%%+灼烧+减速)"
			upgrade_btn.disabled = true
		else:
			var next_level = current_level + 1
			upgrade_btn.text = "⬆️ 第%d层 → %s (消耗%d材料)" % [next_level, _get_combo_upgrade_preview(next_level), next_level]
		upgrade_btn.custom_minimum_size = Vector2(420, 32)
		upgrade_btn.add_theme_font_size_override("font_size", 12)
		upgrade_btn.pressed.connect(func(): _on_combo_upgrade(combo.id))
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

func _get_combo_upgrade_preview(next_level: int) -> String:
	match next_level:
		1: return "+20%"
		2: return "+30%"
		3: return "+50%"
		4: return "解锁灼烧"
		5: return "解锁减速"
		_: return "已满级"

func _get_combo_upgrade_summary(combo_id: String) -> String:
	var level = GameState.get_combo_upgrade_level(combo_id)
	var parts: Array[String] = []
	if level >= 1:
		parts.append("+20%")
	if level >= 2:
		parts.append("+30%")
	if level >= 3:
		parts.append("+50%")
	if GameState.has_combo_effect(combo_id, "burn"):
		parts.append("灼烧")
	if GameState.has_combo_effect(combo_id, "slow"):
		parts.append("减速")
	if parts.is_empty():
		return "无"
	return " ".join(parts)

## ========== 装备升级面板 ==========

func _create_equipment_upgrade_panel() -> Control:
	var panel = Control.new()
	panel.name = "EquipPanel"
	panel.custom_minimum_size = Vector2(420, 550)
	
	# 背景
	var bg = Panel.new()
	bg.custom_minimum_size = Vector2(420, 550)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.2, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.6, 0.9, 0.5)
	bg.add_theme_stylebox_override("panel", style)
	panel.add_child(bg)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 530)
	scroll.position = Vector2(10, 10)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(380, 900)
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "⚔️ 装备升级"
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(0.5, 0.7, 1)
	vbox.add_child(title)
	
	# ===== 装备栏 =====
	var equip_title = Label.new()
	equip_title.text = "━━━ 装备栏 (%d/%d) ━━━" % [GameState.equipment_slot.size(), GameState.get_current_equipment_slot_limit()]
	equip_title.add_theme_font_size_override("font_size", 14)
	equip_title.modulate = Color(0.7, 0.9, 0.7)
	vbox.add_child(equip_title)
	
	if GameState.equipment_slot.is_empty():
		var empty = Label.new()
		empty.text = "（装备栏为空）"
		empty.add_theme_font_size_override("font_size", 14)
		empty.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(empty)
	else:
		for i in range(GameState.equipment_slot.size()):
			var item = GameState.equipment_slot[i]
			var item_container = _create_equipment_item_container(item, i, true)
			vbox.add_child(item_container)
	
	# ===== 背包 =====
	var backpack_title = Label.new()
	backpack_title.text = "━━━ 背包 (%d/%d) ━━━" % [GameState.backpack.size(), GameState.get_current_backpack_limit()]
	backpack_title.add_theme_font_size_override("font_size", 14)
	backpack_title.modulate = Color(0.9, 0.7, 0.5)
	vbox.add_child(backpack_title)
	
	if GameState.backpack.is_empty():
		var empty = Label.new()
		empty.text = "（背包为空）"
		empty.add_theme_font_size_override("font_size", 14)
		empty.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(empty)
	else:
		for i in range(GameState.backpack.size()):
			var item = GameState.backpack[i]
			var item_container = _create_equipment_item_container(item, i, false)
			vbox.add_child(item_container)
	
	return panel

func _create_equipment_item_container(item: Dictionary, index: int, is_equipped: bool) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(360, 110)
	
	var rarity_color = Color.WHITE
	match item.rarity:
		"white": rarity_color = Color(0.9, 0.9, 0.9)
		"blue": rarity_color = Color(0.6, 0.8, 1)
		"red": rarity_color = Color(1, 0.6, 0.6)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(260, 100)
	info_vbox.add_theme_constant_override("separation", 3)
	container.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = "%s %s %s" % [
		_get_rarity_emoji(item.rarity), 
		item.name, 
		"[已装备]" if is_equipped else "[背包]"
	]
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.modulate = rarity_color
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.6, 0.6, 0.6)
	info_vbox.add_child(desc_label)
	
	# 获取当前强化状态
	var upgrades = GameState.equipment_upgrades.get(item.id, {})
	var current_level = upgrades.get("level", 0)
	var current_quality = upgrades.get("quality", 0)
	var has_special = upgrades.get("special_unlocked", false)
	
	# 显示当前强化效果
	var current_effect_label = Label.new()
	var effect_text = "当前: "
	if current_level > 0:
		effect_text += "等级+%d(+%d%%) " % [current_level, current_level * 30]
	if current_quality > 0:
		var quality_names = ["白", "蓝", "红"]
		var quality_bonus = ["", "+10%", "+25%"]
		effect_text += "品质%s(%s) " % [quality_names[current_quality], quality_bonus[current_quality]]
	if has_special:
		effect_text += "特效(+15%) "
	if effect_text == "当前: ":
		effect_text += "无"
	current_effect_label.text = effect_text
	current_effect_label.add_theme_font_size_override("font_size", 11)
	current_effect_label.modulate = Color(0.5, 0.9, 0.5)
	info_vbox.add_child(current_effect_label)
	
	# 按钮
	var btn_container = VBoxContainer.new()
	btn_container.custom_minimum_size = Vector2(90, 135)
	btn_container.add_theme_constant_override("separation", 5)
	btn_container.position = Vector2(270, 0)
	container.add_child(btn_container)
	
	if is_equipped:
		# 等级强化按钮
		var level_cost = 1 + current_level
		var level_btn = Button.new()
		if current_level >= 10:
			level_btn.text = "✅ 满级"
			level_btn.disabled = true
		else:
			level_btn.text = "⬆️ Lv(%d材料)" % level_cost
		level_btn.custom_minimum_size = Vector2(85, 28)
		level_btn.add_theme_font_size_override("font_size", 11)
		level_btn.pressed.connect(func(): _on_equipment_level_upgrade(item.id))
		btn_container.add_child(level_btn)
		
		# 品质强化按钮
		# 白(0)可升级2次→蓝→红，蓝(1)可升级1次→红，红(2)不可升级
		var quality_btn = Button.new()
		var quality_cost = 1 + current_quality
		if current_quality >= 2:  # 红色为最高
			quality_btn.text = "✅ 红品质"
			quality_btn.disabled = true
		else:
			var next_quality_names = ["蓝", "红"]
			quality_btn.text = "⬆️ %s(%d材料)" % [next_quality_names[current_quality], quality_cost]
		quality_btn.custom_minimum_size = Vector2(85, 28)
		quality_btn.add_theme_font_size_override("font_size", 11)
		quality_btn.pressed.connect(func(): _on_equipment_quality_upgrade(item.id))
		btn_container.add_child(quality_btn)
		
		# 特效解锁按钮
		var special_btn = Button.new()
		if has_special:
			special_btn.text = "✅ 特效"
			special_btn.disabled = true
		else:
			special_btn.text = "✨ 特效(2材料)"
		special_btn.custom_minimum_size = Vector2(85, 28)
		special_btn.add_theme_font_size_override("font_size", 11)
		special_btn.pressed.connect(func(): _on_equipment_special_upgrade(item.id))
		btn_container.add_child(special_btn)
		
		# 卸下按钮
		var unequip_btn = Button.new()
		unequip_btn.text = "卸下→"
		unequip_btn.custom_minimum_size = Vector2(85, 28)
		unequip_btn.add_theme_font_size_override("font_size", 11)
		unequip_btn.pressed.connect(func(): _on_unequip_item(index))
		btn_container.add_child(unequip_btn)
	else:
		# 背包物品的按钮
		var upgrade_btn = Button.new()
		upgrade_btn.text = "⬆️ Lv(%d材料)" % (1 + current_level)
		upgrade_btn.custom_minimum_size = Vector2(85, 28)
		upgrade_btn.add_theme_font_size_override("font_size", 11)
		upgrade_btn.pressed.connect(func(): _on_equipment_level_upgrade(item.id))
		btn_container.add_child(upgrade_btn)
		
		var equip_btn = Button.new()
		equip_btn.text = "←装备"
		equip_btn.custom_minimum_size = Vector2(85, 28)
		equip_btn.add_theme_font_size_override("font_size", 11)
		equip_btn.pressed.connect(func(): _on_equip_item(index))
		btn_container.add_child(equip_btn)
	
	return container

func _get_rarity_emoji(rarity: String) -> String:
	match rarity:
		"white": return "⚪"
		"blue": return "🔵"
		"red": return "🔴"
		_: return "⚪"

## ========== 恢复按钮回调 ==========

func _on_full_heal() -> void:
	GameState.player_hp = GameState.player_max_hp
	if not GameState.shield_persists_between_battles():
		GameState.player_shield = 0
	GameState.save_progress("rest")
	_update_heal_panel_status()
	print("[RestPoint] 充分休息: HP恢复至100%")

func _on_half_heal() -> void:
	var heal_amount = int(GameState.player_max_hp * 0.5)
	GameState.player_hp = mini(GameState.player_hp + heal_amount, GameState.player_max_hp)
	GameState.save_progress("rest")
	_update_heal_panel_status()
	print("[RestPoint] 稍微休息: HP恢复50%%")

func _update_heal_panel_status() -> void:
	if not _heal_panel:
		return
	
	var hp_label = _heal_panel.get_node_or_null("HPLabel")
	if hp_label:
		var hp_bar = ""
		for i in range(GameState.player_max_hp):
			hp_bar += "❤️" if i < GameState.player_hp else "🖤"
		hp_label.text = "❤️ 生命: %s\n%d/%d" % [hp_bar, GameState.player_hp, GameState.player_max_hp]
	
	var shield_label = _heal_panel.get_node_or_null("ShieldLabel")
	if shield_label:
		shield_label.text = "🛡️ 护甲: %d" % GameState.player_shield

## ========== 连招强化回调 ==========

func _on_combo_upgrade(combo_id: String) -> void:
	var result = GameState.apply_combo_upgrade(combo_id, "upgrade")
	if result.success:
		GameState.save_progress("rest")
		_refresh_combo_panel()
		print("[RestPoint] 连招强化: %s, %s, 消耗%d材料" % [combo_id, result.current_effect, result.cost])
	else:
		print("[RestPoint] 强化失败: ", result.get("error", "未知错误"))

func _refresh_combo_panel() -> void:
	# 重新生成连招面板以刷新显示（材料信号已在 apply_xxx_upgrade 中 emit）
	if _combo_panel:
		_combo_panel.queue_free()
		_combo_panel = null
	_combo_panel = _create_combo_upgrade_panel()
	_combo_panel.position = Vector2(30, 100)
	add_child(_combo_panel)

## ========== 装备强化回调 ==========

func _on_equipment_level_upgrade(item_id: String) -> void:
	var result = GameState.apply_equipment_upgrade(item_id, "level")
	if result.success:
		GameState.save_progress("rest")
		_refresh_equip_panel()
		print("[RestPoint] 装备等级提升: %s, %s, 消耗%d材料" % [item_id, result.current_effect, result.cost])
	else:
		print("[RestPoint] 强化失败: ", result.get("error", "未知错误"))

func _on_equipment_quality_upgrade(item_id: String) -> void:
	var result = GameState.apply_equipment_upgrade(item_id, "quality")
	if result.success:
		GameState.save_progress("rest")
		_refresh_equip_panel()
		print("[RestPoint] 装备品质进阶: %s, %s, 消耗%d材料" % [item_id, result.current_effect, result.cost])
	else:
		print("[RestPoint] 强化失败: ", result.get("error", "未知错误"))

func _on_equipment_special_upgrade(item_id: String) -> void:
	var result = GameState.apply_equipment_upgrade(item_id, "special")
	if result.success:
		GameState.save_progress("rest")
		_refresh_equip_panel()
		print("[RestPoint] 装备特效解锁: %s, %s, 消耗%d材料" % [item_id, result.current_effect, result.cost])
	else:
		print("[RestPoint] 强化失败: ", result.get("error", "未知错误"))

func _on_equip_item(backpack_index: int) -> void:
	if GameState.equipment_slot.size() < GameState.get_current_equipment_slot_limit():
		if GameState.equip_from_backpack(backpack_index):
			GameState.save_progress("rest")
			_refresh_equip_panel()
			print("[RestPoint] 从背包装备物品")
		else:
			print("[RestPoint] 装备失败")
	else:
		_show_equipment_swap_dialog(backpack_index)

func _on_unequip_item(equipment_index: int) -> void:
	if GameState.unequip_to_backpack(equipment_index):
		GameState.save_progress("rest")
		_refresh_equip_panel()
		print("[RestPoint] 卸下物品到背包")
	else:
		print("[RestPoint] 卸下失败（背包已满）")

func _refresh_equip_panel() -> void:
	# 重新生成装备面板以刷新显示（材料信号已在 apply_xxx_upgrade 中 emit）
	if _equip_panel:
		_equip_panel.queue_free()
		_equip_panel = null
	_equip_panel = _create_equipment_upgrade_panel()
	_equip_panel.position = Vector2(800, 100)
	add_child(_equip_panel)

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
	incoming_name.text = "📥 将装备: %s %s" % [_get_rarity_emoji(incoming_item.rarity), incoming_item.name]
	incoming_name.add_theme_font_size_override("font_size", 15)
	incoming_name.modulate = _get_rarity_color(incoming_item.rarity)
	incoming_container.add_child(incoming_name)
	
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
		equip_btn.custom_minimum_size = Vector2(440, 50)
		equip_btn.text = "%s %s" % [_get_rarity_emoji(equip_item.rarity), equip_item.name]
		equip_btn.add_theme_font_size_override("font_size", 14)
		equip_btn.modulate = _get_rarity_color(equip_item.rarity)
		equip_btn.pressed.connect(_on_select_equipment_to_swap.bind(i))
		scroll_vbox.add_child(equip_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(460, 35)
	cancel_btn.add_theme_font_size_override("font_size", 14)
	cancel_btn.modulate = Color(0.7, 0.7, 0.7)
	cancel_btn.pressed.connect(_hide_swap_dialog)
	dialog_vbox.add_child(cancel_btn)

func _on_select_equipment_to_swap(equipment_index: int) -> void:
	if _pending_backpack_index < 0:
		return
	
	if GameState.swap_equipment_with_backpack(equipment_index, _pending_backpack_index):
		print("[RestPoint] 装备交换成功！")
		GameState.save_progress("rest")
		_hide_swap_dialog()
		_refresh_equip_panel()
	else:
		print("[RestPoint] 装备交换失败！")
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
