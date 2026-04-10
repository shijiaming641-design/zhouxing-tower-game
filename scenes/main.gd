class_name Main
extends Node2D

enum State { MENU, CHARACTER_SELECT, COMBO_SELECT, MAP, BATTLE, SHOP, GAME_OVER, VICTORY, EVENT, EVENT_BATTLE, REST_POINT }

var current_state: State = State.MENU
var current_ui: Control = null

# 战斗状态
var battle_enemy_hp: int = 0
var battle_enemy_max_hp: int = 0
var battle_enemy_atk: int = 0
var current_enemy_ai: EnemyAI = null
var current_enemy_data: EnemyData = null
var is_current_battle_boss: bool = false  # 当前战斗是否是BOSS

# 连招
var combo_sequence: Array[int] = []

# ComboData 脚本引用
const ComboData = preload("res://resources/combo_data.gd")

# 战斗结束锁，防止多次触发
var _battle_ending: bool = false
var _boss_memory_awarded: bool = false

func _get_battle_reward_type() -> String:
	if is_current_battle_boss:
		return "boss"
	if current_enemy_data != null and current_enemy_data.ai_type == 1:
		return "elite"
	return "normal"

func _show_level_up_panel(parent_ui: Control, leveled_up: Array[int], exp_gained: int) -> void:
	var overlay = Control.new()
	overlay.name = "LevelUpOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim = ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var panel = PanelContainer.new()
	panel.position = Vector2(290, 120)
	panel.custom_minimum_size = Vector2(700, 460)
	overlay.add_child(panel)

	var content = VBoxContainer.new()
	content.position = Vector2(24, 20)
	content.custom_minimum_size = Vector2(652, 420)
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var title = Label.new()
	title.text = "⭐ 升级"
	title.add_theme_font_size_override("font_size", 32)
	title.modulate = Color(1, 0.92, 0.68)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var summary = Label.new()
	summary.text = "本次获得 %d EXP | 当前 %s" % [exp_gained, GameState.get_level_progress_text()]
	summary.add_theme_font_size_override("font_size", 18)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.modulate = Color(0.84, 0.9, 0.98)
	content.add_child(summary)

	var rewards_box = VBoxContainer.new()
	rewards_box.add_theme_constant_override("separation", 8)
	content.add_child(rewards_box)

	for level in leveled_up:
		var reward_line = Label.new()
		var rewards = GameState.get_level_reward_summary(level)
		reward_line.text = "Lv.%d: %s" % [level, " / ".join(rewards) if not rewards.is_empty() else "无额外奖励"]
		reward_line.add_theme_font_size_override("font_size", 18)
		reward_line.modulate = Color(0.9, 0.95, 1)
		rewards_box.add_child(reward_line)

	var attr_title = Label.new()
	attr_title.text = "属性分配"
	attr_title.add_theme_font_size_override("font_size", 22)
	attr_title.modulate = Color(0.82, 0.96, 0.82)
	content.add_child(attr_title)

	var attr_status = Label.new()
	attr_status.add_theme_font_size_override("font_size", 18)
	content.add_child(attr_status)

	var hp_btn = Button.new()
	hp_btn.text = ""
	hp_btn.custom_minimum_size = Vector2(0, 52)
	content.add_child(hp_btn)

	var atk_btn = Button.new()
	atk_btn.text = ""
	atk_btn.custom_minimum_size = Vector2(0, 52)
	content.add_child(atk_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "继续"
	confirm_btn.custom_minimum_size = Vector2(0, 54)
	content.add_child(confirm_btn)

	var refresh_attr_ui = func():
		attr_status.text = "剩余属性点: %d | 升级生命 %+d/%d | 升级攻击 %+d/%d" % [
			GameState.unspent_attribute_points,
			GameState.bonus_hp_from_level,
			GameState.MAX_LEVEL_HP_BONUS,
			GameState.bonus_atk_from_level,
			GameState.MAX_LEVEL_ATK_BONUS
		]
		hp_btn.text = "+2 最大生命"
		atk_btn.text = "+1 攻击"
		hp_btn.disabled = GameState.unspent_attribute_points <= 0 or not GameState.can_add_level_hp()
		atk_btn.disabled = GameState.unspent_attribute_points <= 0 or not GameState.can_add_level_atk()
		confirm_btn.disabled = GameState.unspent_attribute_points > 0 and (not hp_btn.disabled or not atk_btn.disabled)

	hp_btn.pressed.connect(func():
		if GameState.allocate_level_stat("hp"):
			refresh_attr_ui.call()
	)
	atk_btn.pressed.connect(func():
		if GameState.allocate_level_stat("atk"):
			refresh_attr_ui.call()
	)
	confirm_btn.pressed.connect(func():
		GameState.save_progress("map")
		overlay.queue_free()
	)

	refresh_attr_ui.call()
	parent_ui.add_child(overlay)
	await overlay.tree_exited

func _handle_battle_victory_rewards(battle: Control) -> void:
	var reward_type = _get_battle_reward_type()
	var exp_gained = GameState.get_battle_exp_reward(reward_type)
	var leveled_up = GameState.add_exp(exp_gained)
	var memory_gained = 0
	if is_current_battle_boss and not _boss_memory_awarded and current_enemy_ai != null and current_enemy_ai.boss_phase >= 2:
		_boss_memory_awarded = true
		memory_gained = GameState.award_memory_cores(1, "boss_phase_clear")
	GameState.save_progress("map")
	if memory_gained > 0:
		var result_label = battle.get_node_or_null("ResultLabel")
		if result_label:
			result_label.text += "\n💾 获得存储器 +%d" % memory_gained
	if not leveled_up.is_empty():
		var result_label = battle.get_node_or_null("ResultLabel")
		if result_label:
			result_label.text += "\n⭐ 升至 Lv.%d" % GameState.player_level
		await _show_level_up_panel(battle, leveled_up, exp_gained)

func _ready():
	print("Main _ready")
	randomize()
	_show_main_menu()

func _show_main_menu():
	print("Showing main menu")
	_change_state(State.MENU)
	
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	if menu.has_method("configure_continue_state"):
		menu.configure_continue_state(GameState.has_active_run(), GameState.get_save_slot_summary())
	
	# 直接连接按钮信号
	var start_btn = menu.get_node_or_null("StartButton")
	if start_btn:
		print("StartButton found, connecting...")
		start_btn.pressed.connect(func(): _show_character_select())
	else:
		print("ERROR: StartButton not found!")

	var continue_btn = menu.get_node_or_null("ContinueButton")
	if continue_btn:
		continue_btn.pressed.connect(_resume_saved_run)
	else:
		print("ERROR: ContinueButton not found!")

	var stats_btn = menu.get_node_or_null("StatsButton")
	if stats_btn:
		stats_btn.pressed.connect(func(): _show_meta_panel("stats"))

	var codex_btn = menu.get_node_or_null("CodexButton")
	if codex_btn:
		codex_btn.pressed.connect(func(): _show_meta_panel("codex"))

	var upgrades_btn = menu.get_node_or_null("UpgradeButton")
	if upgrades_btn:
		upgrades_btn.pressed.connect(func(): _show_meta_panel("upgrades"))
	
	_add_ui(menu)

func _show_meta_panel(mode: String) -> void:
	if current_ui == null:
		return
	
	var existing = current_ui.get_node_or_null("MetaOverlay")
	if existing:
		existing.queue_free()
	
	var overlay = ColorRect.new()
	overlay.name = "MetaOverlay"
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	current_ui.add_child(overlay)

	var panel = Panel.new()
	panel.position = Vector2(120, 70)
	panel.size = Vector2(1040, 560)
	overlay.add_child(panel)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(992, 500)
	panel.add_child(scroll)
	scroll.position = Vector2(24, 44)
	scroll.size = Vector2(992, 492)

	var scroll_content = VBoxContainer.new()
	scroll_content.name = "MetaScrollContent"
	scroll_content.custom_minimum_size = Vector2(970, 492)
	scroll_content.add_theme_constant_override("separation", 14)
	scroll.add_child(scroll_content)

	var title = Label.new()
	match mode:
		"stats":
			title.text = "📊 局外统计"
		"upgrades":
			title.text = "💾 局外升级"
		_:
			title.text = "📚 图鉴与成就"
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = Color(0.95, 0.9, 0.75)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scroll_content.add_child(title)

	if mode == "stats":
		_populate_stats_panel(scroll_content)
	elif mode == "upgrades":
		_populate_upgrade_panel(scroll_content)
	else:
		_populate_codex_panel(scroll_content)

	var close_btn = Button.new()
	close_btn.text = "×"
	close_btn.tooltip_text = "关闭"
	close_btn.custom_minimum_size = Vector2(38, 34)
	close_btn.size = Vector2(38, 34)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.modulate = Color(0.9, 0.9, 0.95)
	close_btn.pressed.connect(func(): overlay.queue_free())
	close_btn.position = Vector2(988, 10)
	panel.add_child(close_btn)

func _populate_stats_panel(content: VBoxContainer) -> void:
	var summary = GameState.get_meta_progress_summary()
	var class_names = ["医生", "黑客", "商人", "农民", "流浪者"]

	var overview = Label.new()
	overview.text = "历史最高层数: %d    累计通关: %d    已解锁成就: %d/%d" % [
		summary.get("highest_floor", 0),
		summary.get("total_wins", 0),
		summary.get("achievement_count", 0),
		summary.get("total_achievement_count", 0)
	]
	overview.add_theme_font_size_override("font_size", 24)
	overview.modulate = Color(0.88, 0.88, 0.82)
	overview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(overview)

	var clear_title = Label.new()
	clear_title.text = "职业首通"
	clear_title.add_theme_font_size_override("font_size", 22)
	clear_title.modulate = Color(0.8, 0.85, 0.95)
	content.add_child(clear_title)

	var class_clear_box = HBoxContainer.new()
	class_clear_box.add_theme_constant_override("separation", 18)
	content.add_child(class_clear_box)

	var first_clears: Dictionary = summary.get("class_first_clears", {})
	for i in range(class_names.size()):
		var tag = Label.new()
		var cleared = bool(first_clears.get(str(i), false))
		tag.text = "%s %s" % [class_names[i], "✅" if cleared else "⬜"]
		tag.add_theme_font_size_override("font_size", 20)
		tag.modulate = Color(0.72, 0.95, 0.72) if cleared else Color(0.5, 0.5, 0.56)
		class_clear_box.add_child(tag)

	var collection = Label.new()
	collection.text = "装备发现: %d/%d    事件发现: %d" % [
		summary.get("discovered_item_count", 0),
		summary.get("total_item_count", 0),
		summary.get("discovered_event_count", 0)
	]
	collection.add_theme_font_size_override("font_size", 22)
	collection.modulate = Color(0.85, 0.82, 0.68)
	content.add_child(collection)

	var achievement_title = Label.new()
	achievement_title.text = "成就进度"
	achievement_title.add_theme_font_size_override("font_size", 22)
	achievement_title.modulate = Color(0.8, 0.85, 0.95)
	content.add_child(achievement_title)

	for achievement in GameState.get_achievement_status():
		var entry = Label.new()
		var unlocked = bool(achievement.get("unlocked", false))
		entry.text = "%s %s: %s" % ["✅" if unlocked else "⬜", achievement.get("name", ""), achievement.get("desc", "")]
		entry.add_theme_font_size_override("font_size", 18)
		entry.modulate = Color(0.75, 0.95, 0.75) if unlocked else Color(0.55, 0.55, 0.6)
		content.add_child(entry)

func _populate_upgrade_panel(content: VBoxContainer) -> void:
	var summary = Label.new()
	summary.text = "当前存储器: %d    来源: 通关Boss一形态或以上后击败Boss" % GameState.memory_cores
	summary.add_theme_font_size_override("font_size", 24)
	summary.modulate = Color(0.88, 0.92, 1.0)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(summary)

	var hint = Label.new()
	hint.text = "存储器用于永久解锁连招、槽位、基础属性和每局被动。购买后立即存档，新一局开始生效。"
	hint.add_theme_font_size_override("font_size", 17)
	hint.modulate = Color(0.7, 0.74, 0.82)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var owned_upgrades: Array[Dictionary] = []
	var available_upgrades: Array[Dictionary] = []
	for upgrade in GameState.get_meta_upgrade_definitions():
		var upgrade_id = str(upgrade.get("id", ""))
		var current_count = GameState.get_meta_upgrade_count(upgrade_id)
		var max_count = int(upgrade.get("max", 1))
		if current_count >= max_count:
			owned_upgrades.append(upgrade)
		else:
			available_upgrades.append(upgrade)

	_add_meta_upgrade_section(content, "下一步可规划", available_upgrades, false)
	_add_meta_upgrade_section(content, "已持有", owned_upgrades, true)

func _add_meta_upgrade_section(content: VBoxContainer, title_text: String, upgrades: Array[Dictionary], owned_section: bool) -> void:
	var title = Label.new()
	title.text = "%s（%d）" % [title_text, upgrades.size()]
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(0.78, 0.92, 0.82) if owned_section else Color(0.92, 0.84, 0.62)
	content.add_child(title)

	if upgrades.is_empty():
		var empty = Label.new()
		empty.text = "暂无"
		empty.add_theme_font_size_override("font_size", 16)
		empty.modulate = Color(0.5, 0.52, 0.58)
		content.add_child(empty)
		return

	for upgrade in upgrades:
		_add_meta_upgrade_row(content, upgrade, owned_section)

func _add_meta_upgrade_row(content: VBoxContainer, upgrade: Dictionary, owned: bool) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)

	var upgrade_id = str(upgrade.get("id", ""))
	var cost = int(upgrade.get("cost", 0))
	var can_buy = GameState.can_purchase_meta_upgrade(upgrade_id)
	var missing = maxi(cost - GameState.memory_cores, 0)

	var status_text = "已持有"
	if not owned:
		status_text = "可购买" if can_buy else "还差%d存储器" % missing

	var info = Label.new()
	info.text = "%s [%s]  消耗%d存储器\n%s" % [
		upgrade.get("name", ""),
		status_text,
		cost,
		upgrade.get("desc", "")
	]
	info.custom_minimum_size = Vector2(720, 58)
	info.add_theme_font_size_override("font_size", 17)
	if owned:
		info.modulate = Color(0.68, 0.95, 0.72)
	elif can_buy:
		info.modulate = Color(0.95, 0.86, 0.58)
	else:
		info.modulate = Color(0.55, 0.58, 0.66)
	row.add_child(info)

	var buy_btn = Button.new()
	buy_btn.text = "已持有" if owned else "买"
	buy_btn.tooltip_text = "已持有" if owned else ("购买" if can_buy else "存储器不足")
	buy_btn.custom_minimum_size = Vector2(74, 34)
	buy_btn.size = Vector2(74, 34)
	buy_btn.add_theme_font_size_override("font_size", 15)
	buy_btn.disabled = owned or not can_buy
	buy_btn.pressed.connect(_on_meta_upgrade_pressed.bind(upgrade_id))
	row.add_child(buy_btn)

func _on_meta_upgrade_pressed(upgrade_id: String) -> void:
	var result = GameState.purchase_meta_upgrade(upgrade_id)
	if result.get("success", false):
		_refresh_meta_upgrade_panel()

func _refresh_meta_upgrade_panel() -> void:
	if current_ui == null:
		return
	var overlay = current_ui.get_node_or_null("MetaOverlay")
	if overlay == null:
		return
	var content = overlay.find_child("MetaScrollContent", true, false)
	if content == null or not (content is VBoxContainer):
		return
	for child in content.get_children():
		child.queue_free()
	var title = Label.new()
	title.text = "💾 局外升级"
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = Color(0.95, 0.9, 0.75)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	_populate_upgrade_panel(content)

func _populate_codex_panel(content: VBoxContainer) -> void:
	var discovered_items = GameState.get_discovered_items()
	var discovered_events = GameState.get_discovered_events()

	var event_title = Label.new()
	event_title.text = "事件图鉴"
	event_title.add_theme_font_size_override("font_size", 24)
	event_title.modulate = Color(0.92, 0.82, 0.68)
	content.add_child(event_title)

	for event_data in RandomEventManager.get_event_catalog():
		var event_entry = Label.new()
		var seen = discovered_events.has(event_data.get("event_id", ""))
		var rarity = "★" if event_data.get("rarity", "common") == "rare" else "·"
		event_entry.text = "%s %s" % [rarity, "%s: %s" % [event_data.get("name", ""), event_data.get("description", "")] if seen else "？？？（未发现）"]
		event_entry.add_theme_font_size_override("font_size", 17)
		event_entry.modulate = Color(0.88, 0.88, 0.8) if seen else Color(0.45, 0.45, 0.5)
		content.add_child(event_entry)

	var item_title = Label.new()
	item_title.text = "装备图鉴"
	item_title.add_theme_font_size_override("font_size", 24)
	item_title.modulate = Color(0.82, 0.88, 0.96)
	content.add_child(item_title)

	for item_id in GameState.ITEMS.keys():
		var item = GameState.ITEMS[item_id]
		var seen_item = discovered_items.has(item_id)
		var item_entry = Label.new()
		item_entry.text = "%s" % ("%s: %s" % [item.get("name", "未知装备"), item.get("description", "")] if seen_item else "？？？（未发现）")
		item_entry.add_theme_font_size_override("font_size", 17)
		item_entry.modulate = Color(0.84, 0.88, 0.96) if seen_item else Color(0.45, 0.45, 0.5)
		content.add_child(item_entry)

func _resume_saved_run() -> void:
	if not GameState.has_active_run():
		return
	
	RandomEventManager.reset_state()
	var checkpoint = GameState.get_checkpoint_scene()
	match checkpoint:
		"shop":
			_show_shop()
		"rest":
			_show_rest_point()
		_:
			_show_map()

func _show_character_select():
	print("Showing character select")
	_change_state(State.CHARACTER_SELECT)
	
	var select_scene = load("res://scenes/ui/character_select.tscn").instantiate()
	
	# 连接信号
	if select_scene.has_signal("character_selected"):
		select_scene.character_selected.connect(_on_character_selected)
	if select_scene.has_signal("back_pressed"):
		select_scene.back_pressed.connect(_show_main_menu)
	
	_add_ui(select_scene)

func _on_character_selected(class_id: int):
	print("Character selected: ", class_id)
	
	GameState.reset_game()
	RandomEventManager.reset_state()
	GameState.player_class = class_id
	
	match class_id:
		0: GameState.player_max_hp = 9;  GameState.player_attack = 2  # 医生
		1: GameState.player_max_hp = 6;  GameState.player_attack = 4  # 黑客
		2: GameState.player_max_hp = 7;  GameState.player_attack = 2  # 商人
		3: GameState.player_max_hp = 12; GameState.player_attack = 2  # 农民
		4: GameState.player_max_hp = 8;  GameState.player_attack = 3  # 流浪者
	
	GameState.player_hp = GameState.player_max_hp
	GameState.player_shield = 0
	
	# 初始化角色专属连招
	GameState.init_player_class(class_id)
	
	# 初始化角色技能
	GameState.init_class_abilities(class_id)
	GameState.apply_meta_start_bonuses()
	
	# 加载连招选择场景
	var combo_scene = load("res://scenes/ui/combo_select.tscn").instantiate()
	
	# 连接完成信号
	if combo_scene.has_signal("combo_selection_complete"):
		combo_scene.combo_selection_complete.connect(func(): 
			_generate_map()
			_show_map()
		)
	
	# 连接返回信号
	if combo_scene.has_signal("back_pressed"):
		combo_scene.back_pressed.connect(_show_character_select)
	
	_add_ui(combo_scene)

func _show_map():
	print("Showing map, floor: ", GameState.current_floor)
	_change_state(State.MAP)
	GameState.save_progress("map")
	
	print("Loading map_scene.tscn...")
	var map = load("res://scenes/ui/map_scene.tscn").instantiate()
	print("Map scene instantiated: ", map)
	
	# 更新标题 - 显示当前层（从下往上）
	var title_label = map.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = "🗼 第 %d / %d 层" % [GameState.current_floor + 1, GameState.max_floors]
	else:
		print("ERROR: TitleLabel not found!")
	
	# 更新状态栏
	var status_label = map.get_node_or_null("StatusLabel")
	if status_label:
		var class_names = ["医生", "黑客", "商人", "农民", "流浪者"]
		var hp_bar = ""
		for i in range(GameState.player_max_hp):
			hp_bar += "❤️" if i < GameState.player_hp else "🖤"
		
		var status_text = "%s %s 💰%d" % [class_names[GameState.player_class], hp_bar, GameState.player_gold]
		if GameState.player_shield > 0:
			status_text += " 🛡️%d" % GameState.player_shield
		
		# 添加难度提示
		var diff = GameState.max_floors - 1 - GameState.current_floor
		var difficulty_hints = ["🌱 初入地牢", "🌿 简单", "🌲 适中", "🔥 困难", "💀 凶险", "😈 极难", "👹 地狱", "⚰️ 死亡"]
		var hint = difficulty_hints[clamp(diff, 0, difficulty_hints.size() - 1)]
		status_text += " " + hint
		
		status_label.text = status_text
	else:
		print("ERROR: StatusLabel not found!")
	
	# 地图场景现在使用 MapContainer 和 ScrollContainer
	# 地图节点由 MapScene._create_tree_map() 自动创建
	# 这里只需要确保返回按钮连接正确
	
	var back_btn = map.get_node_or_null("BackButton")
	if back_btn:
		back_btn.pressed.connect(func(): _show_main_menu())
	
	# 连接地图节点选择信号
	map.node_selected.connect(_on_map_node_selected)
	map.back_to_menu_pressed.connect(func(): _show_main_menu())
	
	print("Calling _add_ui with map...")
	_add_ui(map)
	print("_show_map completed")

func _on_map_node_selected(node_index: int):
	print("Node selected: ", node_index)
	
	if GameState.current_floor >= GameState.map_data.size():
		return
	
	var node = GameState.map_data[GameState.current_floor][node_index]
	node.visited = true
	
	match node.type:
		0, 4:
			_show_battle(node.type == 4)
		1:
			_show_shop()
		2:
			# 休息节点 - 显示完整休息点UI
			_change_state(State.REST_POINT)
			GameState.save_progress("rest")
			var rest_point = load("res://scenes/ui/rest_point.tscn").instantiate()
			rest_point.name = "RestPoint"
			rest_point.continue_to_next_floor.connect(_on_rest_point_continue_from_map)
			_add_ui(rest_point)
			print("Rest point displayed from map node")
			return
		3:
			# 事件节点
			_show_event()
			return

# ===== 商店系统（稀有度权重 + 类型权重 + 刷新消耗）=====

# 商店刷新消耗
const SHOP_REFRESH_COST: int = 3

# 稀有度权重
const RARITY_WEIGHTS: Dictionary = {
	"white": 50,  # 50%
	"blue": 35,   # 35%
	"red": 15     # 15%
}

# 类型权重（在确定稀有度后）
const TYPE_WEIGHTS: Dictionary = {
	"attack": 40,   # 40%
	"defense": 40,  # 40%
	"special": 20   # 20%
}

func _get_random_rarity() -> String:
	"""根据权重随机获取稀有度"""
	var total_weight = 0
	for weight in RARITY_WEIGHTS.values():
		total_weight += weight
	
	var roll = randi() % total_weight
	var cumulative = 0
	
	for rarity in RARITY_WEIGHTS:
		cumulative += RARITY_WEIGHTS[rarity]
		if roll < cumulative:
			return rarity
	
	return "white"

func _get_random_type() -> String:
	"""根据权重随机获取类型"""
	var total_weight = 0
	for weight in TYPE_WEIGHTS.values():
		total_weight += weight
	
	var roll = randi() % total_weight
	var cumulative = 0
	
	for type_name in TYPE_WEIGHTS:
		cumulative += TYPE_WEIGHTS[type_name]
		if roll < cumulative:
			return type_name
	
	return "attack"

func _get_item_by_rarity_and_type(rarity: String, type_name: String) -> String:
	"""根据稀有度和类型获取一个随机装备ID"""
	var candidates: Array[String] = []
	
	for item_id in GameState.ITEMS:
		var item = GameState.ITEMS[item_id]
		if item.rarity == rarity and item.type == type_name:
			if not GameState.has_in_backpack(item_id):
				candidates.append(item_id)
	
	if candidates.is_empty():
		return ""
	
	return candidates[randi() % candidates.size()]

func _get_random_shop_items() -> Array[String]:
	"""根据权重随机获取3件商店物品"""
	var result: Array[String] = []
	var attempts = 0
	
	while result.size() < 3 and attempts < 30:
		attempts += 1
		
		# 第一步：确定稀有度
		var rarity = _get_random_rarity()
		
		# 第二步：确定类型
		var type_name = _get_random_type()
		
		# 第三步：获取装备
		var item_id = _get_item_by_rarity_and_type(rarity, type_name)
		
		if item_id != "" and not item_id in result:
			result.append(item_id)
	
	# 如果权重随机不足3件，补充随机物品
	if result.size() < 3:
		var all_items: Array[String] = []
		for item_id in GameState.ITEMS:
			if not GameState.has_in_backpack(item_id) and not item_id in result:
				all_items.append(item_id)
		
		all_items.shuffle()
		while result.size() < 3 and not all_items.is_empty():
			result.append(all_items.pop_front())
	
	return result

func _show_shop():
	print("Shop")
	_change_state(State.SHOP)
	GameState.set_checkpoint_scene("shop")
	GameState.save_progress("shop")
	
	var shop = Control.new()
	shop.name = "ShopScene"
	shop.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 背景 - 全屏
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.18)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	shop.add_child(bg)
	
	# 标题
	var title = Label.new()
	var discount_text = ""
	if GameState.shop_discount < 1.0:
		discount_text = " 【%.0f折】" % (GameState.shop_discount * 10)
	var remaining_floors = GameState.current_floor + 1
	title.text = "🏪 神秘商店 - 第%d层 (剩余%d层)%s" % [GameState.current_floor + 1, remaining_floors, discount_text]
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 10
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.9, 0.6)
	shop.add_child(title)
	
	# 金币显示
	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "💰 %d" % GameState.player_gold
	gold_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	gold_label.offset_left = 20
	gold_label.offset_top = 15
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_label.modulate = Color(1, 0.85, 0.4)
	shop.add_child(gold_label)
	
	# 材料显示
	var materials_label = Label.new()
	materials_label.name = "MaterialsLabel"
	materials_label.text = "🔧 材料: %d" % GameState.materials
	materials_label.position = Vector2(20, 45)
	materials_label.add_theme_font_size_override("font_size", 20)
	materials_label.modulate = Color(0.9, 0.8, 0.4)
	shop.add_child(materials_label)
	
	# 购买材料按钮
	var buy_material_btn = Button.new()
	buy_material_btn.name = "BuyMaterialBtn"
	buy_material_btn.text = "💰%d 购买材料 🔧" % GameState.MATERIAL_PRICE
	buy_material_btn.custom_minimum_size = Vector2(180, 40)
	buy_material_btn.position = Vector2(20, 75)
	buy_material_btn.add_theme_font_size_override("font_size", 14)
	buy_material_btn.modulate = Color(0.9, 0.8, 0.4)
	if GameState.player_gold < GameState.MATERIAL_PRICE:
		buy_material_btn.disabled = true
		buy_material_btn.modulate = Color(0.5, 0.5, 0.5)
	buy_material_btn.pressed.connect(func(): _buy_material(shop))
	shop.add_child(buy_material_btn)
	
	# ===== 随机3件商品 =====
	if GameState.current_shop_items.is_empty():
		GameState.current_shop_items = _get_random_shop_items()
	var shop_items = GameState.current_shop_items
	
	var shop_title = Label.new()
	shop_title.text = "📦 今日特供（剩余 %d 件）" % shop_items.size()
	shop_title.position = Vector2(490, 80)
	shop_title.add_theme_font_size_override("font_size", 22)
	shop_title.modulate = Color(0.8, 0.8, 0.7)
	shop.add_child(shop_title)
	
	# 显示3件商品
	var start_x = 165
	var spacing = 350
	
	for i in range(shop_items.size()):
		var item_id = shop_items[i]
		var item = GameState.ITEMS[item_id]
		
		var btn = Button.new()
		btn.name = "ShopItem_%s" % item_id
		btn.custom_minimum_size = Vector2(300, 200)
		btn.position = Vector2(start_x + i * spacing, 120)
		btn.add_theme_font_size_override("font_size", 16)
		
		# 根据稀有度设置背景色
		match item.rarity:
			"blue": btn.modulate = Color(0.4, 0.5, 0.8)
			"red": btn.modulate = Color(0.8, 0.4, 0.4)
			_: btn.modulate = Color(0.6, 0.6, 0.65)
		
		# 显示价格和描述
		var rarity_text = ""
		match item.rarity:
			"white": rarity_text = "⚪"
			"blue": rarity_text = "🔵"
			"red": rarity_text = "🔴"
		
		# 计算折扣后价格
		var discounted_price = int(item.cost * GameState.shop_discount)
		var price_text = "💰%d" % discounted_price
		if GameState.shop_discount < 1.0:
			price_text += " (原价%d)" % item.cost
		
		btn.text = "%s %s\n%s\n%s" % [rarity_text, item.name, price_text, item.description]
		
		# 金币不足时禁用
		if GameState.player_gold < discounted_price:
			btn.disabled = true
			btn.modulate = Color(0.35, 0.35, 0.35)
			btn.text += "\n[金币不足]"
		
		btn.pressed.connect(func(id=item_id): _buy_item(id, shop))
		shop.add_child(btn)
	
	# 没有商品时显示提示
	if shop_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "商店已售罄！"
		empty_label.position = Vector2(540, 200)
		empty_label.add_theme_font_size_override("font_size", 24)
		empty_label.modulate = Color(0.5, 0.5, 0.4)
		shop.add_child(empty_label)
	
	# ===== 刷新按钮 =====
	var refresh_btn = Button.new()
	refresh_btn.name = "RefreshBtn"
	refresh_btn.text = "🔄 刷新商店 (%d💰)" % SHOP_REFRESH_COST
	refresh_btn.custom_minimum_size = Vector2(250, 60)
	refresh_btn.position = Vector2(515, 360)
	refresh_btn.add_theme_font_size_override("font_size", 20)
	refresh_btn.modulate = Color(0.8, 1, 0.8)
	
	# 金币不足时禁用
	if GameState.player_gold < SHOP_REFRESH_COST:
		refresh_btn.disabled = true
		refresh_btn.modulate = Color(0.35, 0.35, 0.35)
		refresh_btn.text = "🔄 刷新商店 (金币不足)"
	
	refresh_btn.pressed.connect(func(): _refresh_shop(shop))
	shop.add_child(refresh_btn)
	
	# ===== 装备栏和背包区域 =====
	# 装备栏标题
	var equip_title = Label.new()
	equip_title.name = "EquipTitle"
	equip_title.text = "⚔️ 装备栏 (%d/%d) - 效果生效中" % [GameState.equipment_slot.size(), GameState.get_current_equipment_slot_limit()]
	equip_title.position = Vector2(50, 450)
	equip_title.add_theme_font_size_override("font_size", 18)
	equip_title.modulate = Color(0.5, 0.9, 0.5)
	shop.add_child(equip_title)
	
	# 背包标题
	var backpack_title = Label.new()
	backpack_title.name = "BackpackTitle"
	backpack_title.text = "🎒 背包 (%d/%d)" % [GameState.backpack.size(), GameState.get_current_backpack_limit()]
	backpack_title.position = Vector2(50, 560)
	backpack_title.add_theme_font_size_override("font_size", 18)
	backpack_title.modulate = Color(0.9, 0.7, 0.4)
	shop.add_child(backpack_title)
	
	# 显示背包物品
	_update_inventory_display(shop)
	
	# ===== 底部按钮区 =====
	var btn_y = 650
	
	# 返回按钮
	var back_btn = Button.new()
	back_btn.name = "BackBtn"
	back_btn.text = "← 返回地图"
	back_btn.custom_minimum_size = Vector2(140, 50)
	back_btn.position = Vector2(200, btn_y)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(func(): _show_map())
	shop.add_child(back_btn)
	
	# 下一层按钮
	var next_btn = Button.new()
	next_btn.name = "NextBtn"
	next_btn.text = "下一层 →"
	next_btn.custom_minimum_size = Vector2(140, 50)
	next_btn.position = Vector2(940, btn_y)
	next_btn.add_theme_font_size_override("font_size", 16)
	next_btn.modulate = Color(0.8, 1, 0.8)
	next_btn.pressed.connect(func(): _advance_from_shop())
	shop.add_child(next_btn)
	
	_add_ui(shop)

func _update_inventory_display(shop: Control):
	"""更新装备栏和背包显示"""
	# 清除旧的物品显示
	for child in shop.get_children():
		if child.name.begins_with("EquipItem_") or child.name.begins_with("BackpackItem_") or child.name.begins_with("InvHint_"):
			child.queue_free()
	
	# 更新标题显示容量
	var equip_title = shop.get_node_or_null("EquipTitle")
	if equip_title:
		equip_title.text = "⚔️ 装备栏 (%d/%d) - 效果生效中" % [GameState.equipment_slot.size(), GameState.get_current_equipment_slot_limit()]
	
	var backpack_title_node = shop.get_node_or_null("BackpackTitle")
	if backpack_title_node:
		backpack_title_node.text = "🎒 背包 (%d/%d)" % [GameState.backpack.size(), GameState.get_current_backpack_limit()]
	
	var start_x = 50
	var equip_y = 485
	var backpack_y = 595
	
	# ===== 显示装备栏 =====
	if GameState.equipment_slot.is_empty():
		var empty_label = Label.new()
		empty_label.name = "EquipItem_Empty"
		empty_label.text = "（装备栏为空）"
		empty_label.position = Vector2(start_x, equip_y)
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.modulate = Color(0.5, 0.5, 0.4)
		shop.add_child(empty_label)
	else:
		for i in range(GameState.equipment_slot.size()):
			var item = GameState.equipment_slot[i]
			var btn = _create_item_button(item, i, "EquipItem_", true, shop)
			btn.position = Vector2(start_x + i * 200, equip_y)
			shop.add_child(btn)
	
	# 装备栏提示
	var equip_hint = Label.new()
	equip_hint.name = "InvHint_Equip"
	equip_hint.text = "↑ 装备的物品才会生效 | 点击\"卸下\"放入背包"
	equip_hint.position = Vector2(start_x, equip_y + 30)
	equip_hint.add_theme_font_size_override("font_size", 12)
	equip_hint.modulate = Color(0.5, 0.5, 0.4)
	shop.add_child(equip_hint)
	
	# ===== 显示背包 =====
	if GameState.backpack.is_empty():
		var empty_label = Label.new()
		empty_label.name = "BackpackItem_Empty"
		empty_label.text = "（背包为空）"
		empty_label.position = Vector2(start_x, backpack_y)
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.modulate = Color(0.5, 0.5, 0.4)
		shop.add_child(empty_label)
	else:
		for i in range(GameState.backpack.size()):
			var item = GameState.backpack[i]
			var btn = _create_backpack_item_button(item, i, "BackpackItem_", shop)
			btn.position = Vector2(start_x + i * 200, backpack_y)
			shop.add_child(btn)
	
	# 背包提示
	var backpack_hint = Label.new()
	backpack_hint.name = "InvHint_Backpack"
	backpack_hint.text = "↑ 点击\"装备\"到装备栏 | 点击\"卖出\"出售"
	backpack_hint.position = Vector2(start_x, backpack_y + 80)
	backpack_hint.add_theme_font_size_override("font_size", 12)
	backpack_hint.modulate = Color(0.5, 0.5, 0.4)
	shop.add_child(backpack_hint)

func _create_item_button(item: Dictionary, index: int, prefix: String, is_equipped: bool, shop: Control) -> Button:
	"""创建设备栏物品按钮"""
	var btn = Button.new()
	btn.name = "%s%d" % [prefix, index]
	btn.custom_minimum_size = Vector2(180, 70)
	
	match item.rarity:
		"blue": btn.modulate = Color(0.4, 0.5, 0.8)
		"red": btn.modulate = Color(0.8, 0.4, 0.4)
		_: btn.modulate = Color(0.6, 0.6, 0.65)
	
	btn.text = "%s\n[卸下]" % item.name
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(func(): _unequip_item_to_backpack(index, shop))
	return btn

func _create_backpack_item_button(item: Dictionary, index: int, prefix: String, shop: Control) -> Button:
	"""创建背包物品按钮"""
	var btn = Button.new()
	btn.name = "%s%d" % [prefix, index]
	btn.custom_minimum_size = Vector2(90, 70)
	
	match item.rarity:
		"blue": btn.modulate = Color(0.4, 0.5, 0.8)
		"red": btn.modulate = Color(0.8, 0.4, 0.4)
		_: btn.modulate = Color(0.6, 0.6, 0.65)
	
	btn.text = "%s\n[装备]" % item.name
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(func(): _equip_item_from_backpack(index, shop))
	return btn

func _unequip_item_to_backpack(index: int, shop: Control):
	"""从装备栏卸下物品到背包"""
	if GameState.unequip_to_backpack(index):
		GameState.save_progress("shop")
		_update_inventory_display(shop)
		print("Unequipped item to backpack")

func _equip_item_from_backpack(index: int, shop: Control):
	"""从背包装备物品"""
	if GameState.equip_from_backpack(index):
		GameState.save_progress("shop")
		_update_inventory_display(shop)
		print("Equipped item from backpack")

func _refresh_shop(_shop: Control):
	"""刷新商店（消耗金币）"""
	if GameState.player_gold >= SHOP_REFRESH_COST:
		GameState.player_gold -= SHOP_REFRESH_COST
		GameState.current_shop_items.clear()
		print("Shop refreshed, cost: ", SHOP_REFRESH_COST, " gold")
		_show_shop()
	else:
		print("Not enough gold to refresh shop")

func _buy_item(item_id: String, shop: Control):
	"""购买物品 - 进入背包"""
	var item = GameState.ITEMS.get(item_id)
	if not item:
		return
	
	# 检查是否已经拥有（装备栏或背包）
	if GameState.has_item_anywhere(item_id):
		return
	
	# 检查背包是否已满
	if GameState.backpack.size() >= GameState.get_current_backpack_limit():
		return
	
	# 计算折扣后价格
	var discounted_cost = int(item.cost * GameState.shop_discount)
	
	if GameState.player_gold < discounted_cost:
		return
	
	# 扣除金币
	GameState.player_gold -= discounted_cost
	
	# 优先添加到装备栏，装备栏满则放入背包
	if GameState.equipment_slot.size() < GameState.get_max_equipment_slots():
		GameState.add_to_equipment_slot(item_id)
		print("Bought and equipped: ", item.name, " cost: ", discounted_cost, " (discount: ", GameState.shop_discount, ")")
	else:
		GameState.add_to_backpack(item_id)
		print("Bought item to backpack: ", item.name, " cost: ", discounted_cost, " (discount: ", GameState.shop_discount, ")")
	
	GameState.current_shop_items.erase(item_id)
	GameState.save_progress("shop")
	
	# 刷新商店显示
	if shop and shop.has_method("update_shop_display"):
		shop.update_shop_display()
	else:
		_show_shop()

func _sell_item(index: int, shop: Control):
	"""卖出物品 - 原价回收"""
	if GameState.sell_item(index):
		GameState.save_progress("shop")
		print("Sold item at index: ", index)
		# 刷新显示
		if shop and shop.has_method("update_shop_display"):
			shop.update_shop_display()
		else:
			_show_shop()

func _buy_material(shop: Control):
	"""购买材料"""
	if GameState.player_gold >= GameState.MATERIAL_PRICE:
		GameState.player_gold -= GameState.MATERIAL_PRICE
		GameState.add_materials(1)
		EventBus.player_gold_changed.emit(GameState.player_gold)
		GameState.save_progress("shop")
		# 刷新商店显示
		_show_shop()
	else:
		print("[Materials] 金币不足，无法购买材料")

func _advance_from_shop():
	"""从商店进入下一层地图"""
	print("Advancing from shop to next floor")
	
	# 标记当前层已访问（不可返回）
	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = false
	
	# 从下往上走：递增层数
	GameState.current_floor += 1
	GameState.current_shop_items.clear()
	combo_sequence.clear()
	
	# 检查通关（到达塔顶）
	if GameState.current_floor >= GameState.max_floors:
		_show_victory()
		return
	
	# 设置下一层可访问
	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = true
	
	_show_map()

# ===== 事件系统（好事/坏事）=====

func _show_event():
	"""显示事件界面 - 先进行一局对战决定好事还是坏事"""
	print("Event triggered")
	_change_state(State.EVENT)
	
	# 重置战斗结束锁
	_battle_ending = false
	_boss_memory_awarded = false
	
	# 创建事件对战
	var battle = _create_event_battle()
	_add_ui(battle)

func _create_event_battle():
	"""创建事件对战界面（一局定胜负）"""
	var battle = Control.new()
	battle.name = "EventBattle"
	battle.custom_minimum_size = Vector2(1280, 720)
	
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.15, 0.25)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	battle.add_child(bg)
	
	# 标题
	var title = Label.new()
	title.text = "⚡ 命运之战"
	title.position = Vector2(540, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle.add_child(title)
	
	# 说明
	var desc = Label.new()
	desc.text = "胜利→好事  失败→坏事"
	desc.position = Vector2(540, 100)
	desc.add_theme_font_size_override("font_size", 20)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle.add_child(desc)
	
	# 结果标签
	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = "选择出招..."
	result_label.position = Vector2(540, 300)
	result_label.add_theme_font_size_override("font_size", 28)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle.add_child(result_label)
	
	# 出招按钮
	var circle_btn = Button.new()
	circle_btn.text = "○"
	circle_btn.custom_minimum_size = Vector2(100, 80)
	circle_btn.position = Vector2(480, 400)
	circle_btn.add_theme_font_size_override("font_size", 32)
	circle_btn.pressed.connect(func(): _process_event_battle_turn(0, battle))
	battle.add_child(circle_btn)
	
	var tri_btn = Button.new()
	tri_btn.text = "△"
	tri_btn.custom_minimum_size = Vector2(100, 80)
	tri_btn.position = Vector2(590, 400)
	tri_btn.add_theme_font_size_override("font_size", 32)
	tri_btn.pressed.connect(func(): _process_event_battle_turn(1, battle))
	battle.add_child(tri_btn)
	
	var square_btn = Button.new()
	square_btn.text = "□"
	square_btn.custom_minimum_size = Vector2(100, 80)
	square_btn.position = Vector2(700, 400)
	square_btn.add_theme_font_size_override("font_size", 32)
	square_btn.pressed.connect(func(): _process_event_battle_turn(2, battle))
	battle.add_child(square_btn)
	
	return battle

func _process_event_battle_turn(player_move: int, battle: Control):
	"""处理事件对战回合"""
	if _battle_ending:
		return
	
	var _symbols = ["○", "△", "□"]
	var enemy_move = randi() % 3
	
	var result_label = battle.get_node("ResultLabel")
	
	# 立即禁用所有按钮，防止连点
	_disable_battle_buttons(battle)
	
	if player_move == enemy_move:
		result_label.text = "🤝 平局! 再试一次..."
		# 平局时重新启用按钮，允许再次尝试
		_enable_battle_buttons(battle)
		return
	
	var player_wins = (player_move == 0 and enemy_move == 1) or \
					(player_move == 1 and enemy_move == 2) or \
					(player_move == 2 and enemy_move == 0)
	
	_battle_ending = true
	
	if player_wins:
		result_label.text = "✅ 胜利! 好事降临!"
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): _show_good_event())
	else:
		result_label.text = "❌ 失败! 坏事发生..."
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): _show_bad_event())

## 禁用事件对战的所有按钮
func _disable_battle_buttons(battle: Control) -> void:
	for child in battle.get_children():
		if child is Button:
			child.disabled = true
		elif child is HBoxContainer or child is VBoxContainer:
			for sub_child in child.get_children():
				if sub_child is Button:
					sub_child.disabled = true

## 启用事件对战的所有按钮
func _enable_battle_buttons(battle: Control) -> void:
	for child in battle.get_children():
		if child is Button:
			child.disabled = false
		elif child is HBoxContainer or child is VBoxContainer:
			for sub_child in child.get_children():
				if sub_child is Button:
					sub_child.disabled = false

func _show_good_event():
	"""好事事件"""
	print("Good event!")
	_change_state(State.EVENT)
	
	# 使用新的随机好事系统
	var event_data = RandomEventManager.get_random_good_event(GameState.current_floor)
	_show_good_event_with_data(event_data)

func _show_good_event_with_data(event_data: Dictionary):
	"""显示指定的好事事件"""
	var event = Control.new()
	event.custom_minimum_size = Vector2(1280, 720)
	
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.18)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	event.add_child(bg)
	
	# 标题
	var title = Label.new()
	title.text = "🎉 好事降临!"
	title.position = Vector2(540, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.4, 1, 0.4)
	event.add_child(title)
	
	# 状态栏
	var status_label = Label.new()
	status_label.text = _get_player_status_text()
	status_label.position = Vector2(30, 20)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.modulate = Color(0.8, 0.8, 0.7)
	event.add_child(status_label)
	
	# 事件名称
	var name_label = Label.new()
	name_label.text = event_data.get("name", "")
	name_label.position = Vector2(540, 150)
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.modulate = Color(1, 0.9, 0.6)
	event.add_child(name_label)
	
	# 事件描述
	var desc_label = Label.new()
	desc_label.text = event_data.get("description", "")
	desc_label.position = Vector2(540, 200)
	desc_label.add_theme_font_size_override("font_size", 22)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.modulate = Color(0.7, 0.7, 0.6)
	event.add_child(desc_label)

	var info_panel = _create_event_info_panel(event_data, true)
	info_panel.position = Vector2(840, 120)
	event.add_child(info_panel)
	
	# 选项容器
	var options_container = VBoxContainer.new()
	options_container.position = Vector2(490, 280)
	options_container.custom_minimum_size = Vector2(300, 300)
	event.add_child(options_container)
	
	# 根据事件类型显示选项
	if event_data.get("battle_required", false):
		_show_battle_required_options(event_data, options_container)
	else:
		_show_immediate_good_options(event_data, options_container)
	
	_add_ui(event)

func _show_immediate_good_options(event_data: Dictionary, container: VBoxContainer):
	"""显示直接生效的好事件选项"""
	var btn = Button.new()
	btn.text = "确认获得 %s" % event_data.get("description", "")
	btn.custom_minimum_size = Vector2(300, 60)
	btn.add_theme_font_size_override("font_size", 20)
	btn.modulate = Color(0.8, 1, 0.8)
	
	var data = event_data
	btn.pressed.connect(func():
		RandomEventManager.settle_immediate_good_event(data)
		EventBus.good_event_triggered.emit("immediate", data)
		_advance_floor()
	)
	container.add_child(btn)

func _show_battle_required_options(event_data: Dictionary, container: VBoxContainer):
	"""显示需要战斗的好事件选项"""
	var battle_type = event_data.get("battle_type", "")
	
	var label = Label.new()
	label.text = "需要通过2回合战斗决定结果\n⚠️第一回合不计入奖励"
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color(0.5, 0.5, 0.5)
	container.add_child(label)
	
	var preview = Label.new()
	preview.text = _get_good_battle_preview(battle_type)
	preview.add_theme_font_size_override("font_size", 16)
	preview.modulate = Color(0.4, 0.4, 0.4)
	container.add_child(preview)
	
	var btn = Button.new()
	btn.text = "开始战斗"
	btn.custom_minimum_size = Vector2(200, 60)
	btn.add_theme_font_size_override("font_size", 20)
	btn.modulate = Color(0.8, 1, 0.8)
	
	var data = event_data
	btn.pressed.connect(func():
		_start_new_event_battle(true, data)
	)
	container.add_child(btn)

func _get_good_battle_preview(battle_type: String) -> String:
	match battle_type:
		"random_equip":
			return "📦 奖励预览：\n2胜 = 🔴红色装备\n1胜 = 🔵蓝色装备\n0胜 = ⚪白色装备"
		"shop_discount":
			return "🏪 折扣预览：\n2胜 = 7折\n1胜 = 8折\n0胜 = 9折"
		_:
			return ""

func _show_bad_event():
	"""坏事事件"""
	print("Bad event!")
	_change_state(State.EVENT)
	
	# 使用新的随机坏事系统
	var event_data = RandomEventManager.get_random_bad_event(GameState.current_floor)
	_show_bad_event_with_data(event_data)

func _show_bad_event_with_data(event_data: Dictionary):
	"""显示指定的坏事事件"""
	var event = Control.new()
	event.custom_minimum_size = Vector2(1280, 720)
	
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.18)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	event.add_child(bg)
	
	# 标题
	var title = Label.new()
	title.text = "💀 坏事发生!"
	title.position = Vector2(540, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.4, 0.4)
	event.add_child(title)
	
	# 状态栏
	var status_label = Label.new()
	status_label.text = _get_player_status_text()
	status_label.position = Vector2(30, 20)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.modulate = Color(0.8, 0.8, 0.7)
	event.add_child(status_label)
	
	# 事件名称
	var name_label = Label.new()
	name_label.text = event_data.get("name", "")
	name_label.position = Vector2(540, 150)
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.modulate = Color(1, 0.9, 0.6)
	event.add_child(name_label)
	
	# 事件描述
	var desc_label = Label.new()
	desc_label.text = event_data.get("description", "")
	desc_label.position = Vector2(540, 200)
	desc_label.add_theme_font_size_override("font_size", 22)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.modulate = Color(0.7, 0.7, 0.6)
	event.add_child(desc_label)

	var info_panel = _create_event_info_panel(event_data, false)
	info_panel.position = Vector2(840, 120)
	event.add_child(info_panel)
	
	# 选项容器
	var options_container = VBoxContainer.new()
	options_container.position = Vector2(490, 280)
	options_container.custom_minimum_size = Vector2(300, 300)
	event.add_child(options_container)
	
	# 根据事件类型显示选项
	var choice_type = event_data.get("choice_type", "")
	match choice_type:
		"attribute":
			_show_attribute_penalty_options(event_data, options_container)
		"equip_loss":
			_show_equip_loss_options(event_data, options_container)
		_:
			_show_simple_bad_options(event_data, options_container)
	
	_add_ui(event)

func _show_attribute_penalty_options(event_data: Dictionary, container: VBoxContainer):
	"""显示属性惩罚选项（四选一）"""
	var label = Label.new()
	label.text = "选择要减少的属性："
	label.add_theme_font_size_override("font_size", 20)
	label.modulate = Color(0.9, 0.8, 0.8)
	container.add_child(label)
	
	var attributes = [
		{"name": "❤️ 生命", "desc": "血量-2（不会低于1）", "type": 0},
		{"name": "⚔️ 攻击", "desc": "攻击-1（不会低于1）", "type": 1},
		{"name": "🛡️ 护甲", "desc": "护甲-2", "type": 2},
		{"name": "💥 暴击", "desc": "暴击率-20%", "type": 3}
	]
	
	for attr in attributes:
		var btn = Button.new()
		btn.text = "%s\n%s" % [attr.name, attr.desc]
		btn.custom_minimum_size = Vector2(300, 60)
		btn.add_theme_font_size_override("font_size", 16)
		btn.modulate = Color(1, 0.85, 0.85)
		
		var data = event_data
		var attr_type = attr.type
		btn.pressed.connect(func():
			RandomEventManager.settle_immediate_bad_event(data, attr_type)
			EventBus.bad_event_triggered.emit("immediate", data)
			_advance_floor()
		)
		container.add_child(btn)

func _show_equip_loss_options(event_data: Dictionary, container: VBoxContainer):
	"""显示装备损失选项"""
	var backpack = GameState.backpack
	var has_equipment = not backpack.is_empty()
	
	# 选项1：直接丢失
	var option1 = Button.new()
	option1.custom_minimum_size = Vector2(400, 70)
	option1.add_theme_font_size_override("font_size", 18)
	option1.modulate = Color(1, 0.8, 0.8)
	
	if has_equipment:
		var random_item = backpack[randi() % backpack.size()]
		option1.text = "直接丢失一件随机装备\n将丢失：%s" % random_item.name
		option1.pressed.connect(func():
			RandomEventManager.settle_direct_equip_loss()
			_advance_floor()
		)
	else:
		option1.text = "直接丢失一件随机装备\n（背包为空）"
		option1.disabled = true
	container.add_child(option1)
	
	# 选项2：通过战斗决定
	var option2 = Button.new()
	option2.custom_minimum_size = Vector2(400, 90)
	option2.add_theme_font_size_override("font_size", 16)
	option2.modulate = Color(0.9, 0.9, 1)
	
	if has_equipment:
		option2.text = "通过战斗决定\n2胜→丢⚪白色 | 1胜→丢🔵蓝色 | 0胜→丢🔴红色\n⚠️第一回合不计入结果"
		option2.pressed.connect(func():
			_start_new_event_battle(false, event_data)
		)
	else:
		option2.text = "通过战斗决定\n（背包为空，战斗无意义）"
		option2.disabled = true
	container.add_child(option2)

func _show_simple_bad_options(event_data: Dictionary, container: VBoxContainer):
	"""显示简单坏事选项"""
	var btn = Button.new()
	btn.text = "接受命运 - %s" % event_data.get("description", "")
	btn.custom_minimum_size = Vector2(300, 60)
	btn.add_theme_font_size_override("font_size", 20)
	btn.modulate = Color(1, 0.8, 0.8)
	
	var data = event_data
	btn.pressed.connect(func():
		RandomEventManager.settle_immediate_bad_event(data, -1)
		EventBus.bad_event_triggered.emit("immediate", data)
		_advance_floor()
	)
	container.add_child(btn)

func _start_new_event_battle(is_good: bool, event_data: Dictionary):
	"""开始新的事件战斗"""
	print("[Main] Starting new event battle: is_good=", is_good)
	_change_state(State.EVENT_BATTLE)
	
	# 重置战斗结束锁
	_battle_ending = false
	
	var context = {
		"event_data": event_data,
		"battle_type": event_data.get("battle_type", "")
	}
	
	var battle = _create_new_event_battle_scene(is_good, context)
	_add_ui(battle)

func _create_new_event_battle_scene(is_good: bool, context: Dictionary) -> Control:
	"""创建新的事件战斗场景"""
	var battle = Control.new()
	battle.custom_minimum_size = Vector2(1280, 720)
	battle.set_meta("is_good", is_good)
	battle.set_meta("context", context)
	
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.15, 0.25)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	battle.add_child(bg)
	
	# 标题
	var title = Label.new()
	title.text = "⚔️ %s战斗" % ("好事" if is_good else "坏事")
	title.position = Vector2(540, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.2, 0.5, 0.2) if is_good else Color(0.7, 0.2, 0.2)
	battle.add_child(title)
	
	# 回合显示
	var round_label = Label.new()
	round_label.name = "RoundLabel"
	round_label.text = "第 1 / 3 回合 （不计入结果）"
	round_label.position = Vector2(540, 130)
	round_label.add_theme_font_size_override("font_size", 28)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle.add_child(round_label)
	
	# 奖励预览
	var preview_label = Label.new()
	preview_label.name = "PreviewLabel"
	var battle_type = context.get("battle_type", "")
	if is_good:
		preview_label.text = _get_good_battle_preview(battle_type)
	else:
		preview_label.text = _get_bad_battle_preview()
	preview_label.position = Vector2(900, 200)
	preview_label.add_theme_font_size_override("font_size", 18)
	preview_label.modulate = Color(0.5, 0.5, 0.5)
	battle.add_child(preview_label)
	
	# 结果标签
	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = "请选择出招..."
	result_label.position = Vector2(540, 250)
	result_label.add_theme_font_size_override("font_size", 28)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle.add_child(result_label)
	
	# 当前胜利数
	var wins_label = Label.new()
	wins_label.name = "WinsLabel"
	wins_label.text = "当前胜利：0"
	wins_label.position = Vector2(540, 300)
	wins_label.add_theme_font_size_override("font_size", 20)
	battle.add_child(wins_label)
	
	# 出招按钮
	var btn_container = HBoxContainer.new()
	btn_container.position = Vector2(490, 400)
	btn_container.custom_minimum_size = Vector2(300, 80)
	battle.add_child(btn_container)
	
	var circle_btn = Button.new()
	circle_btn.text = "○"
	circle_btn.custom_minimum_size = Vector2(80, 60)
	circle_btn.add_theme_font_size_override("font_size", 32)
	circle_btn.pressed.connect(func(): _process_new_event_battle_turn(0, battle))
	btn_container.add_child(circle_btn)
	
	var tri_btn = Button.new()
	tri_btn.text = "△"
	tri_btn.custom_minimum_size = Vector2(80, 60)
	tri_btn.add_theme_font_size_override("font_size", 32)
	tri_btn.pressed.connect(func(): _process_new_event_battle_turn(1, battle))
	btn_container.add_child(tri_btn)
	
	var square_btn = Button.new()
	square_btn.text = "□"
	square_btn.custom_minimum_size = Vector2(80, 60)
	square_btn.add_theme_font_size_override("font_size", 32)
	square_btn.pressed.connect(func(): _process_new_event_battle_turn(2, battle))
	btn_container.add_child(square_btn)
	
	# 初始化战斗状态
	RandomEventManager.start_event_battle(is_good, context)
	battle.set_meta("current_round", 0)
	
	return battle

func _process_new_event_battle_turn(player_move: int, battle: Control):
	"""处理新的事件战斗回合"""
	if _battle_ending:
		return
	
	var current_round = battle.get_meta("current_round")
	current_round += 1
	
	# 立即禁用按钮防止连点
	_disable_battle_buttons(battle)
	
	# 生成敌人出招
	var enemy_move = randi() % 3
	
	# 处理回合
	var result = RandomEventManager.process_event_battle_round(player_move, enemy_move)
	var wins = int(result.get("wins", 0))
	var round_won = result.get("won", false)
	
	battle.set_meta("current_round", current_round)
	
	var result_label = battle.get_node_or_null("ResultLabel")
	var round_label = battle.get_node_or_null("RoundLabel")
	var wins_label = battle.get_node_or_null("WinsLabel")
	
	var symbols = ["○", "△", "□"]
	var msg = result.get("message", "")
	
	if result_label:
		result_label.text = "%s\n你: %s vs 敌: %s" % [msg, symbols[player_move], symbols[enemy_move]]
		
		if current_round == 1:
			result_label.modulate = Color(0.6, 0.6, 0.6)
		elif round_won:
			result_label.modulate = Color(0.2, 0.7, 0.2)
		else:
			result_label.modulate = Color(0.7, 0.2, 0.2)
	
	if round_label:
		round_label.text = "第 %d / 3 回合" % current_round
		if current_round < 3:
			round_label.text += " 当前胜利：%d" % wins
	
	if wins_label:
		wins_label.text = "当前胜利：%d" % wins
	
	if not result.get("continues", false):
		# 战斗结束
		_battle_ending = true
		_finish_new_event_battle(battle, wins)
	else:
		# 继续下一回合 - 短暂延迟后重新启用按钮
		if result_label:
			result_label.text = "第%d回合开始！请选择..." % (current_round + 1)
			result_label.modulate = Color(0.9, 0.9, 0.9)
		
		# 延迟后重新启用按钮
		var enable_timer = get_tree().create_timer(0.3)
		enable_timer.timeout.connect(func(): _enable_battle_buttons(battle))

func _finish_new_event_battle(battle: Control, wins: int):
	"""结束新的事件战斗"""
	var is_good = battle.get_meta("is_good")
	var context = battle.get_meta("context")
	var battle_type = context.get("battle_type", "")
	
	# 禁用按钮
	var btn_container = battle.get_node_or_null(".")
	if btn_container:
		for child in btn_container.get_children():
			if child is HBoxContainer:
				for button in child.get_children():
					if button is Button:
						button.disabled = true
	
	# 显示结果
	var result_label = battle.get_node_or_null("ResultLabel")
	if result_label:
		result_label.text += "\n\n"
		if is_good:
			match battle_type:
				"random_equip":
					match wins:
						2: result_label.text += "🎉 获得 🔴红色装备！"
						1: result_label.text += "🎉 获得 🔵蓝色装备！"
						_: result_label.text += "🎉 获得 ⚪白色装备！"
				"shop_discount":
					match wins:
						2: result_label.text += "🎉 商店7折！"
						1: result_label.text += "🎉 商店8折！"
						_: result_label.text += "🎉 商店9折！"
		else:
			match wins:
				2: result_label.text += "😅 还好，只丢了⚪白色装备"
				1: result_label.text += "😰 糟糕，丢了🔵蓝色装备"
				_: result_label.text += "😭 倒霉，丢了🔴红色装备！"
		
		result_label.modulate = Color(0.8, 0.6, 0.2)
	
	# 延迟后返回
	await get_tree().create_timer(2.5).timeout
	_advance_floor()

func _get_bad_battle_preview() -> String:
	return "💀 损失预览：\n2胜 = 丢⚪白色（最小）\n1胜 = 丢🔵蓝色\n0胜 = 丢🔴红色（最大）"

func _create_event_info_panel(event_data: Dictionary, is_good: bool) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 300)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(16, 16)
	vbox.custom_minimum_size = Vector2(328, 260)
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var rarity_text = "稀有事件" if event_data.get("rarity", "common") == "rare" else "普通事件"
	var rarity_label = Label.new()
	rarity_label.text = ("★ " if event_data.get("rarity", "common") == "rare" else "· ") + rarity_text
	rarity_label.add_theme_font_size_override("font_size", 22)
	rarity_label.modulate = Color(1, 0.82, 0.45) if event_data.get("rarity", "common") == "rare" else Color(0.72, 0.72, 0.78)
	vbox.add_child(rarity_label)

	var category_label = Label.new()
	category_label.text = "类型: %s" % _get_event_category_text(event_data, is_good)
	category_label.add_theme_font_size_override("font_size", 18)
	category_label.modulate = Color(0.78, 0.82, 0.9)
	vbox.add_child(category_label)

	var floor_label = Label.new()
	floor_label.text = "出现层段: 第%d层起" % (int(event_data.get("min_floor", 0)) + 1)
	floor_label.add_theme_font_size_override("font_size", 17)
	floor_label.modulate = Color(0.64, 0.68, 0.76)
	vbox.add_child(floor_label)

	var detail_title = Label.new()
	detail_title.text = "具体效果"
	detail_title.add_theme_font_size_override("font_size", 18)
	detail_title.modulate = Color(0.88, 0.88, 0.8)
	vbox.add_child(detail_title)

	var detail_label = Label.new()
	detail_label.text = _get_event_detail_text(event_data, is_good)
	detail_label.add_theme_font_size_override("font_size", 16)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.modulate = Color(0.78, 0.78, 0.78)
	vbox.add_child(detail_label)

	if event_data.get("battle_required", false):
		var battle_tip = Label.new()
		battle_tip.text = "战斗判定: 第1回合不计入，后2回合决定最终奖励/惩罚"
		battle_tip.add_theme_font_size_override("font_size", 15)
		battle_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		battle_tip.modulate = Color(0.62, 0.66, 0.72)
		vbox.add_child(battle_tip)

	return panel

func _get_event_category_text(event_data: Dictionary, is_good: bool) -> String:
	if event_data.get("battle_required", false):
		return "战斗判定型增益" if is_good else "战斗规避型惩罚"
	if event_data.get("choice_type", "") == "attribute":
		return "属性取舍"
	if event_data.get("choice_type", "") == "equip_loss":
		return "装备损失"
	return "即时收益" if is_good else "即时代价"

func _get_event_detail_text(event_data: Dictionary, is_good: bool) -> String:
	var event_id = str(event_data.get("event_id", ""))
	if is_good:
		match event_id:
			"hp_blessing": return "最大生命 +2，并同步恢复 2 点生命。"
			"attack_blessing": return "攻击 +1。"
			"shield_blessing": return "当前护甲 +2。"
			"crit_blessing": return "暴击率 +20%。"
			"gold_cache": return "立即获得 10 金币。"
			"random_equip_duel": return "通过事件战斗决定获得的装备品质。"
			"shop_discount_duel": return "通过事件战斗决定下一次商店折扣力度。"
			"field_medic": return "恢复 4 点生命，不会超过最大生命。"
			"scrap_cache": return "立即获得 3 材料。"
			"combo_slot": return "最大可携带连招槽位 +1。"
			"armory_gift": return "立即获得 1 件随机蓝色装备；若没有候选则补发金币。"
			"cheat_console": return "获得 1 次外挂机会，可用于战斗中读招。"
	else:
		match event_id:
			"hp_weaken": return "在生命 / 攻击 / 护甲 / 暴击中四选一承受惩罚。"
			"attack_weaken": return "在生命 / 攻击 / 护甲 / 暴击中四选一承受惩罚。"
			"shield_weaken": return "在生命 / 攻击 / 护甲 / 暴击中四选一承受惩罚。"
			"crit_weaken": return "在生命 / 攻击 / 护甲 / 暴击中四选一承受惩罚。"
			"skill_lock": return "随机封印 1 个当前已装备连招。"
			"equip_loss_duel": return "可以直接丢装备，也可以通过事件战斗降低损失品质。"
			"gold_loss": return "立即失去 5 金币，不足则失去当前全部金币。"
			"material_leak": return "立即失去 2 材料，不足则扣到 0。"
			"armor_crack": return "当前护甲 -3，不会低于 0。"
			"combo_slot_loss": return "最大可携带连招槽位 -1，并自动卸下超出的连招。"
			"brittle_bones": return "最大生命 -2，并把当前生命截断到新的上限。"
	return event_data.get("description", "")

func _give_random_equipment():
	"""给予随机装备（添加到背包）"""
	var all_items = []
	for item_id in GameState.ITEMS:
		if not GameState.has_item_anywhere(item_id):
			all_items.append(item_id)
	
	if not all_items.is_empty():
		var random_item = all_items[randi() % all_items.size()]
		GameState.add_to_backpack(random_item)
		print("Gave random equipment: ", random_item)

func _lose_random_equipment():
	"""随机丢失一件装备（从背包）"""
	if GameState.backpack.is_empty():
		return
	
	var random_index = randi() % GameState.backpack.size()
	var lost_item = GameState.backpack[random_index]
	GameState.remove_from_backpack(random_index)
	print("Lost random equipment: ", lost_item.name)

func _return_to_map_after_event():
	"""事件结束后返回地图"""
	RandomEventManager.cancel_event_battle()
	_advance_floor()

func _get_player_status_text() -> String:
	"""获取玩家状态文本"""
	var class_names = ["医生", "黑客", "商人", "农民", "流浪者"]
	var hp_bar = ""
	for i in range(GameState.player_max_hp):
		hp_bar += "❤️" if i < GameState.player_hp else "🖤"
	
	var status = "%s %s 💰%d" % [class_names[GameState.player_class], hp_bar, GameState.player_gold]
	if GameState.player_shield > 0:
		status += " 🛡️%d" % GameState.player_shield
	return status

# ===== 战斗系统（新AI + 背包自动装备）=====

# ComboDatabase 缓存
var _combo_database_cache: ComboDatabase = null

func _get_combo_id(combo) -> String:
	"""兼容获取连招ID（ComboInfo.id 或 ComboData.combo_id）"""
	if combo == null:
		return ""
	if combo.get("id") != null:
		return combo.id
	if combo.get("combo_id") != null:
		return combo.combo_id
	return ""

func _get_combo_name(combo) -> String:
	"""兼容获取连招名称（ComboInfo.name 或 ComboData.display_name）"""
	if combo == null:
		return "???"
	if combo.get("name") != null:
		return combo.name
	if combo.get("display_name") != null:
		return combo.display_name
	return "???"

func _get_combo_database() -> ComboDatabase:
	"""获取或创建 ComboDatabase 实例"""
	if _combo_database_cache == null:
		_combo_database_cache = ComboDatabase.new()
		_combo_database_cache._init_database()  # 手动初始化数据库
	return _combo_database_cache

func _show_battle(is_boss: bool):
	print("Battle, is_boss: ", is_boss)
	_change_state(State.BATTLE)
	
	# 保存是否是BOSS战斗
	is_current_battle_boss = is_boss
	
	# 重置战斗结束锁
	_battle_ending = false
	
	# 战前准备：处理精确辅助系统（将生命转化为护甲）
	GameState.setup_pre_battle()
	
	# 生成敌人数据
	print("Generating enemy data...")
	var enemy_data: EnemyData
	if is_boss:
		enemy_data = EnemyData.generate_boss()
	else:
		enemy_data = EnemyData.generate_by_floor(GameState.current_floor)
	print("Enemy data generated: ", enemy_data.display_name)
	
	current_enemy_data = enemy_data
	battle_enemy_max_hp = enemy_data.max_hp
	battle_enemy_atk = enemy_data.attack
	battle_enemy_hp = battle_enemy_max_hp
	
	# 创建AI
	print("Creating enemy AI...")
	var enemy_ai = EnemyAI.new()
	print("AI created, setting up...")
	_setup_enemy_ai(enemy_ai, enemy_data)
	print("AI setup completed")
	current_enemy_ai = enemy_ai
	
	combo_sequence.clear()
	_player_move_history.clear()
	_enemy_move_history.clear()
	_battle_ending = false  # 重置战斗结束锁
	
	print("Creating battle UI...")
	var battle = _create_battle_ui(enemy_data, enemy_ai)
	print("Battle UI created, adding to scene...")
	_add_ui(battle)
	print("Battle UI added successfully")

func _setup_enemy_ai(ai: EnemyAI, data: EnemyData):
	"""配置敌人AI"""
	print("Setting up AI type: ", data.ai_type, " subtype: ", data.ai_subtype)
	match data.ai_type:
		0: # 基础：固定套路
			print("Setting up BASIC_FIXED with move: ", data.ai_subtype)
			ai.setup_basic_fixed(data.ai_subtype)
		1: # 精英：双招循环（5种模式）
			print("Setting up ELITE_CYCLE subtype: ", data.ai_subtype)
			ai.setup_elite_by_subtype(data.ai_subtype)
		2: # 高级：三招策略（5种模式）
			print("Setting up ADVANCED_DYNAMIC subtype: ", data.ai_subtype)
			ai.setup_advanced_dynamic(data.ai_subtype)
		3: # BOSS：阶段死局
			print("Setting up BOSS")
			ai.setup_boss()
		_:
			print("Unknown AI type: ", data.ai_type)

func _create_battle_ui(enemy_data: EnemyData, enemy_ai: EnemyAI):
	var battle = Control.new()
	battle.name = "BattleScene"
	battle.custom_minimum_size = Vector2(1280, 720)
	
	# ===== 背景 =====
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.18)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	battle.add_child(bg)
	
	var class_names = ["医生", "黑客", "商人", "农民", "流浪者"]
	
	# ===== 顶部信息栏 =====
	var top_bar = ColorRect.new()
	top_bar.color = Color(0.08, 0.08, 0.12, 0.9)
	top_bar.offset_right = 1280
	top_bar.offset_bottom = 50
	battle.add_child(top_bar)
	
	var floor_label = Label.new()
	floor_label.text = "🗼 第 %d / %d 层" % [GameState.current_floor + 1, GameState.max_floors]
	floor_label.position = Vector2(20, 12)
	floor_label.add_theme_font_size_override("font_size", 18)
	floor_label.modulate = Color(1, 0.9, 0.6)
	battle.add_child(floor_label)
	
	var top_class = Label.new()
	top_class.text = "🧑 %s | %s" % [class_names[GameState.player_class], GameState.get_level_progress_text()]
	top_class.position = Vector2(550, 12)
	top_class.add_theme_font_size_override("font_size", 18)
	top_class.modulate = Color(0.8, 0.8, 0.8)
	battle.add_child(top_class)
	
	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "💰 %d" % GameState.player_gold
	gold_label.position = Vector2(750, 12)
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.modulate = Color(1, 0.85, 0.3)
	battle.add_child(gold_label)
	
	var materials_top_label = Label.new()
	materials_top_label.name = "MaterialsLabel"
	materials_top_label.text = "🔧 %d" % GameState.materials
	materials_top_label.position = Vector2(920, 12)
	materials_top_label.add_theme_font_size_override("font_size", 18)
	materials_top_label.modulate = Color(0.9, 0.8, 0.4)
	battle.add_child(materials_top_label)
	
	# ===== 左侧：玩家信息面板 =====
	var player_panel = ColorRect.new()
	player_panel.color = Color(0.15, 0.2, 0.15, 0.85)
	player_panel.position = Vector2(15, 65)
	player_panel.custom_minimum_size = Vector2(320, 300)
	player_panel.offset_right = 335
	player_panel.offset_bottom = 365
	battle.add_child(player_panel)
	
	var player_title = Label.new()
	player_title.text = "🧑 %s" % class_names[GameState.player_class]
	player_title.position = Vector2(25, 72)
	player_title.add_theme_font_size_override("font_size", 22)
	player_title.modulate = Color(0.9, 1, 0.9)
	battle.add_child(player_title)
	
	var player_hp = Label.new()
	player_hp.name = "PlayerHP"
	var p_hp_bar = ""
	for i in range(GameState.player_max_hp):
		p_hp_bar += "❤️" if i < GameState.player_hp else "🖤"
	player_hp.text = p_hp_bar + " %d/%d" % [GameState.player_hp, GameState.player_max_hp]
	player_hp.position = Vector2(25, 105)
	player_hp.add_theme_font_size_override("font_size", 14)
	player_hp.modulate = Color(1, 0.9, 0.9)
	battle.add_child(player_hp)
	
	var player_atk = Label.new()
	player_atk.name = "PlayerAtk"
	player_atk.text = "⚔️ %d" % GameState.get_total_attack()
	player_atk.position = Vector2(25, 130)
	player_atk.add_theme_font_size_override("font_size", 16)
	player_atk.modulate = Color(1, 0.7, 0.7)
	battle.add_child(player_atk)
	
	var player_shield = Label.new()
	player_shield.name = "PlayerShield"
	player_shield.text = "🛡️ %d" % GameState.player_shield
	player_shield.position = Vector2(130, 130)
	player_shield.add_theme_font_size_override("font_size", 16)
	player_shield.modulate = Color(0.6, 0.8, 1)
	player_shield.visible = GameState.player_shield > 0
	battle.add_child(player_shield)
	
	var energy_label = Label.new()
	energy_label.name = "ComboEnergyLabel"
	energy_label.text = "⚡ %d/%d" % [GameState.get_combo_energy(), GameState.get_max_combo_energy()]
	energy_label.position = Vector2(230, 130)
	energy_label.add_theme_font_size_override("font_size", 16)
	energy_label.modulate = Color(0.6, 0.6, 0.6)
	battle.add_child(energy_label)
	
	# 装备栏
	var equip_title = Label.new()
	equip_title.text = "🎒 装备栏"
	equip_title.position = Vector2(25, 165)
	equip_title.add_theme_font_size_override("font_size", 14)
	equip_title.modulate = Color(0.7, 0.7, 0.7)
	battle.add_child(equip_title)
	
	var equip_text = ""
	if GameState.equipment_slot.is_empty():
		equip_text = "（空）"
	else:
		for item in GameState.equipment_slot:
			equip_text += "[%s] " % item.name
	
	var equip_label = Label.new()
	equip_label.name = "ItemsLabel"
	equip_label.text = equip_text
	equip_label.position = Vector2(25, 190)
	equip_label.custom_minimum_size = Vector2(290, 50)
	equip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equip_label.add_theme_font_size_override("font_size", 13)
	equip_label.modulate = Color(0.7, 0.7, 0.6)
	battle.add_child(equip_label)
	
	# 连招信息
	var combo_y = 250
	var combo_db_ref = _get_combo_database()
	
	# 携带连招（显示顺序和效果）
	var equipped_combos = GameState.get_equipped_combos()
	var eq_label = Label.new()
	eq_label.name = "EquippedCombosLabel"
	eq_label.text = "携带连招:"
	eq_label.position = Vector2(25, combo_y)
	eq_label.custom_minimum_size = Vector2(290, 18)
	eq_label.add_theme_font_size_override("font_size", 12)
	eq_label.modulate = Color(0.8, 0.6, 0.2)
	battle.add_child(eq_label)
	
	var next_y = combo_y + 18
	if not equipped_combos.is_empty():
		var ci = 0
		for cid in equipped_combos:
			# 先查ComboInfo（序列连招），再查CombatCombo（能量连招）
			var cd = combo_db_ref.get_combo_by_id(cid)
			if cd:
				var seq_s = ComboData.sequence_to_string(cd.sequence)
				var combo_line = Label.new()
				combo_line.text = "  %s %s" % [seq_s, cd.name]
				if cd.cooldown > 0:
					combo_line.text += " (CD%d)" % cd.cooldown
				combo_line.position = Vector2(25, next_y + ci * 16)
				combo_line.custom_minimum_size = Vector2(290, 16)
				combo_line.add_theme_font_size_override("font_size", 11)
				combo_line.modulate = Color(0.9, 0.8, 0.5)
				battle.add_child(combo_line)
				ci += 1
			else:
				# 尝试CombatCombo
				var cc = combo_db_ref.get_combat_combo_by_id(cid)
				if cc:
					var seq_s2 = combo_db_ref.combat_combo_sequence_to_display(cc.sequence)
					var combo_line2 = Label.new()
					combo_line2.text = "  %s %s (%d⚡)" % [seq_s2, cc.name, cc.energy_cost]
					combo_line2.position = Vector2(25, next_y + ci * 16)
					combo_line2.custom_minimum_size = Vector2(290, 16)
					combo_line2.add_theme_font_size_override("font_size", 11)
					combo_line2.modulate = Color(0.9, 0.8, 0.5)
					battle.add_child(combo_line2)
					ci += 1
		next_y += ci * 16 + 4
	else:
		var empty_label = Label.new()
		empty_label.text = "  无"
		empty_label.position = Vector2(25, next_y)
		empty_label.add_theme_font_size_override("font_size", 11)
		empty_label.modulate = Color(0.5, 0.5, 0.5)
		battle.add_child(empty_label)
		next_y += 18
	
	# 角色专属（显示顺序）
	var excl_combos = ComboData.get_exclusive_combos(class_names[GameState.player_class])
	var cl_title = Label.new()
	cl_title.name = "ClassExclusiveLabel"
	cl_title.text = "%s专属:" % class_names[GameState.player_class]
	cl_title.position = Vector2(25, next_y)
	cl_title.custom_minimum_size = Vector2(290, 18)
	cl_title.add_theme_font_size_override("font_size", 12)
	cl_title.modulate = Color(0.4, 0.7, 1)
	battle.add_child(cl_title)
	next_y += 18
	
	if excl_combos.is_empty():
		var empty_cl = Label.new()
		empty_cl.text = "  无"
		empty_cl.position = Vector2(25, next_y)
		empty_cl.add_theme_font_size_override("font_size", 11)
		empty_cl.modulate = Color(0.5, 0.5, 0.5)
		battle.add_child(empty_cl)
		next_y += 16
	else:
		for combo in excl_combos:
			var seq_s = ComboData.sequence_to_string(combo.sequence)
			var combo_line = Label.new()
			combo_line.text = "  %s %s" % [seq_s, combo.display_name]
			combo_line.position = Vector2(25, next_y)
			combo_line.custom_minimum_size = Vector2(290, 16)
			combo_line.add_theme_font_size_override("font_size", 11)
			combo_line.modulate = Color(0.6, 0.85, 1)
			battle.add_child(combo_line)
			next_y += 16
	next_y += 4
	
	# 武器专属（显示顺序）
	var wp_title = Label.new()
	wp_title.name = "WeaponExclusiveLabel"
	var has_wp = false
	var wp_text = "武器专属:"
	for item in GameState.equipment_slot:
		if item.has("exclusive_combo") and item.exclusive_combo != "":
			var wc = combo_db_ref.get_combo_by_id(item.exclusive_combo)
			if wc:
				var seq_ws = combo_db_ref.sequence_to_display(wc.sequence) if wc.get("sequence") != null else ""
				wp_text += "\n  %s %s" % [seq_ws, wc.name] if seq_ws != "" else "\n  %s" % wc.name
				has_wp = true
	if not has_wp:
		wp_text += "\n  无"
	wp_title.text = wp_text
	wp_title.position = Vector2(25, next_y)
	wp_title.custom_minimum_size = Vector2(290, 36)
	wp_title.add_theme_font_size_override("font_size", 12)
	wp_title.modulate = Color(0.8, 0.5, 0.8)
	battle.add_child(wp_title)
	
	# ===== 右侧：敌人信息面板 =====
	var enemy_panel = ColorRect.new()
	enemy_panel.color = Color(0.2, 0.12, 0.12, 0.85)
	enemy_panel.position = Vector2(945, 65)
	enemy_panel.custom_minimum_size = Vector2(320, 200)
	enemy_panel.offset_right = 1265
	enemy_panel.offset_bottom = 265
	battle.add_child(enemy_panel)
	
	var enemy_name = Label.new()
	enemy_name.text = "👹 %s" % enemy_data.display_name
	enemy_name.position = Vector2(955, 72)
	enemy_name.add_theme_font_size_override("font_size", 24)
	enemy_name.modulate = Color(1, 0.7, 0.7)
	battle.add_child(enemy_name)
	
	var ai_desc = Label.new()
	ai_desc.text = "📋 %s" % enemy_data.get_ai_description()
	ai_desc.position = Vector2(955, 102)
	ai_desc.add_theme_font_size_override("font_size", 14)
	ai_desc.modulate = Color(0.7, 0.5, 0.5)
	battle.add_child(ai_desc)
	
	var enemy_hp = Label.new()
	enemy_hp.name = "EnemyHP"
	var e_hp_bar = ""
	for i in range(battle_enemy_max_hp):
		e_hp_bar += "💚" if i < battle_enemy_hp else "🖤"
	enemy_hp.text = e_hp_bar + " %d/%d" % [battle_enemy_hp, battle_enemy_max_hp]
	enemy_hp.position = Vector2(955, 130)
	enemy_hp.add_theme_font_size_override("font_size", 13)
	enemy_hp.modulate = Color(0.9, 1, 0.9)
	battle.add_child(enemy_hp)
	
	var enemy_atk = Label.new()
	enemy_atk.text = "⚔️ %d" % battle_enemy_atk
	enemy_atk.position = Vector2(955, 160)
	enemy_atk.add_theme_font_size_override("font_size", 18)
	enemy_atk.modulate = Color(1, 0.6, 0.6)
	battle.add_child(enemy_atk)
	
	# ===== 中央：战斗区域 =====
	var center_panel = ColorRect.new()
	center_panel.color = Color(0.18, 0.18, 0.22, 0.9)
	center_panel.position = Vector2(350, 65)
	center_panel.custom_minimum_size = Vector2(580, 640)
	center_panel.offset_right = 930
	center_panel.offset_bottom = 705
	battle.add_child(center_panel)
	
	# 回合信息
	var move_info = Label.new()
	move_info.name = "MoveInfo"
	move_info.text = "选择出招..."
	move_info.position = Vector2(350, 100)
	move_info.custom_minimum_size = Vector2(580, 40)
	move_info.add_theme_font_size_override("font_size", 28)
	move_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_info.modulate = Color(1, 1, 0.8)
	battle.add_child(move_info)
	
	# 战斗结果
	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = ""
	result_label.position = Vector2(350, 160)
	result_label.custom_minimum_size = Vector2(580, 100)
	result_label.add_theme_font_size_override("font_size", 20)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.modulate = Color(0.9, 0.9, 0.8)
	battle.add_child(result_label)
	
	# ===== 出招历史面板 =====
	# 玩家最近3回合
	var player_hist_panel = ColorRect.new()
	player_hist_panel.color = Color(0.15, 0.2, 0.15, 0.7)
	player_hist_panel.position = Vector2(370, 275)
	player_hist_panel.custom_minimum_size = Vector2(230, 70)
	player_hist_panel.offset_right = 600
	player_hist_panel.offset_bottom = 345
	battle.add_child(player_hist_panel)
	
	var player_hist_title = Label.new()
	player_hist_title.text = "🧑 你的最近出招"
	player_hist_title.position = Vector2(380, 278)
	player_hist_title.add_theme_font_size_override("font_size", 12)
	player_hist_title.modulate = Color(0.7, 0.9, 0.7)
	battle.add_child(player_hist_title)
	
	var player_hist_moves = Label.new()
	player_hist_moves.name = "PlayerHistory"
	player_hist_moves.text = "---"
	player_hist_moves.position = Vector2(380, 296)
	player_hist_moves.custom_minimum_size = Vector2(210, 40)
	player_hist_moves.add_theme_font_size_override("font_size", 24)
	player_hist_moves.modulate = Color(0.8, 1, 0.8)
	battle.add_child(player_hist_moves)
	
	# 敌人最近3回合
	var enemy_hist_panel = ColorRect.new()
	enemy_hist_panel.color = Color(0.2, 0.15, 0.15, 0.7)
	enemy_hist_panel.position = Vector2(680, 275)
	enemy_hist_panel.custom_minimum_size = Vector2(230, 70)
	enemy_hist_panel.offset_right = 910
	enemy_hist_panel.offset_bottom = 345
	battle.add_child(enemy_hist_panel)
	
	var enemy_hist_title = Label.new()
	enemy_hist_title.text = "👹 敌人最近出招"
	enemy_hist_title.position = Vector2(690, 278)
	enemy_hist_title.add_theme_font_size_override("font_size", 12)
	enemy_hist_title.modulate = Color(0.9, 0.7, 0.7)
	battle.add_child(enemy_hist_title)
	
	var enemy_hist_moves = Label.new()
	enemy_hist_moves.name = "EnemyHistory"
	enemy_hist_moves.text = "---"
	enemy_hist_moves.position = Vector2(690, 296)
	enemy_hist_moves.custom_minimum_size = Vector2(210, 40)
	enemy_hist_moves.add_theme_font_size_override("font_size", 24)
	enemy_hist_moves.modulate = Color(1, 0.8, 0.8)
	battle.add_child(enemy_hist_moves)
	
	# ===== 出招按钮 =====
	var btn_y = 380
	var btn_w = 140
	var btn_h = 90
	var btn_start_x = 400
	var btn_gap = 170
	
	# ○ 按钮
	var circle_btn = Button.new()
	circle_btn.text = "○"
	circle_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	circle_btn.position = Vector2(btn_start_x, btn_y)
	circle_btn.add_theme_font_size_override("font_size", 48)
	circle_btn.modulate = Color(0.8, 0.9, 1)
	circle_btn.pressed.connect(func(): _process_battle_turn(0, battle, enemy_ai))
	battle.add_child(circle_btn)
	
	var q_hint = Label.new()
	q_hint.text = "Q"
	q_hint.position = Vector2(btn_start_x + 55, btn_y + btn_h + 2)
	q_hint.add_theme_font_size_override("font_size", 14)
	q_hint.modulate = Color(0.5, 0.5, 0.5)
	battle.add_child(q_hint)
	
	# △ 按钮
	var tri_btn = Button.new()
	tri_btn.text = "△"
	tri_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	tri_btn.position = Vector2(btn_start_x + btn_gap, btn_y)
	tri_btn.add_theme_font_size_override("font_size", 48)
	tri_btn.modulate = Color(1, 0.9, 0.7)
	tri_btn.pressed.connect(func(): _process_battle_turn(1, battle, enemy_ai))
	battle.add_child(tri_btn)
	
	var w_hint = Label.new()
	w_hint.text = "W"
	w_hint.position = Vector2(btn_start_x + btn_gap + 55, btn_y + btn_h + 2)
	w_hint.add_theme_font_size_override("font_size", 14)
	w_hint.modulate = Color(0.5, 0.5, 0.5)
	battle.add_child(w_hint)
	
	# □ 按钮
	var square_btn = Button.new()
	square_btn.text = "□"
	square_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	square_btn.position = Vector2(btn_start_x + btn_gap * 2, btn_y)
	square_btn.add_theme_font_size_override("font_size", 48)
	square_btn.modulate = Color(0.9, 1, 0.8)
	square_btn.pressed.connect(func(): _process_battle_turn(2, battle, enemy_ai))
	battle.add_child(square_btn)
	
	var e_hint = Label.new()
	e_hint.text = "E"
	e_hint.position = Vector2(btn_start_x + btn_gap * 2 + 55, btn_y + btn_h + 2)
	e_hint.add_theme_font_size_override("font_size", 14)
	e_hint.modulate = Color(0.5, 0.5, 0.5)
	battle.add_child(e_hint)

	var cheat_btn = Button.new()
	cheat_btn.name = "CheatButton"
	cheat_btn.text = GameState.get_cheat_label_text("🔍 外挂")
	cheat_btn.custom_minimum_size = Vector2(150, 42)
	cheat_btn.position = Vector2(760, 492)
	cheat_btn.add_theme_font_size_override("font_size", 15)
	cheat_btn.disabled = GameState.cheat_points <= 0
	cheat_btn.pressed.connect(func(): _use_cheat(battle, enemy_ai))
	battle.add_child(cheat_btn)
	
	# 连招能量显示
	var combo_energy_display = Label.new()
	combo_energy_display.name = "ComboEnergyDisplay"
	combo_energy_display.text = "⚡ 连击能量: %d/%d" % [GameState.get_combo_energy(), GameState.get_max_combo_energy()]
	combo_energy_display.position = Vector2(370, 500)
	combo_energy_display.add_theme_font_size_override("font_size", 14)
	combo_energy_display.modulate = Color(0.8, 0.8, 0.5)
	battle.add_child(combo_energy_display)
	
	# 连招进度追踪（显示哪些连招接近完成）
	var combo_progress_label = Label.new()
	combo_progress_label.name = "ComboProgress"
	combo_progress_label.text = _get_combo_progress_text()
	combo_progress_label.position = Vector2(370, 518)
	combo_progress_label.custom_minimum_size = Vector2(540, 18)
	combo_progress_label.add_theme_font_size_override("font_size", 12)
	combo_progress_label.modulate = Color(0.9, 0.8, 0.4)
	battle.add_child(combo_progress_label)

	var protection_label = Label.new()
	protection_label.name = "DrawProtectionLabel"
	protection_label.text = GameState.get_draw_protection_status_text()
	protection_label.position = Vector2(370, 618)
	protection_label.custom_minimum_size = Vector2(540, 18)
	protection_label.add_theme_font_size_override("font_size", 13)
	protection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	protection_label.modulate = Color(0.55, 0.85, 1.0)
	protection_label.visible = protection_label.text != ""
	battle.add_child(protection_label)
	
	# 连招按钮容器
	var combo_btn_container = HBoxContainer.new()
	combo_btn_container.name = "ComboButtons"
	combo_btn_container.position = Vector2(370, 540)
	combo_btn_container.add_theme_constant_override("separation", 10)
	battle.add_child(combo_btn_container)
	
	_update_combo_buttons(combo_btn_container, battle, enemy_ai)
	
	# 底部提示
	var bottom_hint = Label.new()
	bottom_hint.text = "○克△ > △克□ > □克○    |    猜拳胜者造成攻击伤害"
	bottom_hint.position = Vector2(370, 642)
	bottom_hint.custom_minimum_size = Vector2(540, 20)
	bottom_hint.add_theme_font_size_override("font_size", 13)
	bottom_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_hint.modulate = Color(0.4, 0.4, 0.4)
	battle.add_child(bottom_hint)
	
	return battle

func _update_combo_buttons(container: HBoxContainer, battle: Control, enemy_ai: EnemyAI):
	"""更新连招按钮（三类连招）"""
	for child in container.get_children():
		child.queue_free()
	
	var allowed_combo_ids: Array[String] = []
	for cid in GameState.get_equipped_combos():
		if not cid in allowed_combo_ids:
			allowed_combo_ids.append(cid)
	var cn: Array[String] = ["医生", "黑客", "商人", "农民", "流浪者"]
	var ec = ComboData.get_exclusive_combos(cn[GameState.player_class])
	for c in ec:
		if not c.combo_id in allowed_combo_ids:
			allowed_combo_ids.append(c.combo_id)
	for item in GameState.equipment_slot:
		if item.has("exclusive_combo") and item.exclusive_combo != "":
			if not item.exclusive_combo in allowed_combo_ids:
				allowed_combo_ids.append(item.exclusive_combo)
	
	var combo_db = _get_combo_database()
	var combat_combos = combo_db.get_combat_combos()
	for combo in combat_combos:
		if not combo.id in allowed_combo_ids:
			continue
		var reduction = GameState.get_combo_energy_reduction(combo.id)
		var actual_cost = maxi(combo.energy_cost - reduction, 2)
		var can_use = GameState.has_enough_combo_energy(actual_cost)
		var btn = Button.new()
		var seq_str = combo_db.combat_combo_sequence_to_display(combo.sequence)
		btn.text = "%s %s (%d⚡)" % [combo.name, seq_str, actual_cost]
		btn.disabled = not can_use
		btn.custom_minimum_size = Vector2(150, 35)
		btn.add_theme_font_size_override("font_size", 12)
		if can_use:
			btn.modulate = Color(1, 0.9, 0.5)
		else:
			btn.modulate = Color(0.5, 0.5, 0.5)
		btn.pressed.connect(_on_combo_button_pressed.bind(combo.id, battle, enemy_ai))
		container.add_child(btn)

func _on_combo_button_pressed(combo_id: String, battle: Control, enemy_ai: EnemyAI):
	"""连招按钮点击"""
	var combo_db = _get_combo_database()
	var combat_combo = combo_db.get_combat_combo_by_id(combo_id)
	if not combat_combo:
		return
	var reduction = GameState.get_combo_energy_reduction(combo_id)
	var actual_cost = maxi(combat_combo.energy_cost - reduction, 2)
	if not GameState.consume_combo_energy(actual_cost):
		return
	# 执行连招伤害
	var player_atk = GameState.get_total_attack()
	var dmg_mult = GameState.get_combo_damage_multiplier(combo_id)
	var total_damage = 0
	for i in range(combat_combo.attack_count):
		var dmg = int(player_atk * combat_combo.base_damage / 100.0 * dmg_mult)
		if combat_combo.special_effect == "crit":
			dmg = int(dmg * 1.5)
		total_damage += dmg
		battle_enemy_hp = maxi(battle_enemy_hp - dmg, 0)
	if GameState.has_combo_effect(combo_id, "burn"):
		GameState.apply_combo_buff("enemy_burn", 2, 2)
	if GameState.has_combo_effect(combo_id, "slow"):
		GameState.apply_combo_buff("enemy_slow", 1, 2)
	# BOSS锁血检查
	var combo_result_label = battle.get_node_or_null("ResultLabel")
	_clamp_boss_phase(combo_result_label)
	# 特殊效果
	if combat_combo.special_effect == "knockback":
		battle_enemy_atk = maxi(battle_enemy_atk - 1, 1)
	# 更新UI
	var result_label = battle.get_node_or_null("ResultLabel")
	if result_label:
		var extra_effect_text = ""
		if GameState.has_combo_effect(combo_id, "burn"):
			extra_effect_text += " +灼烧"
		if GameState.has_combo_effect(combo_id, "slow"):
			extra_effect_text += " +减速"
		result_label.text = "⚔️ %s 完成! %d伤害%s" % [combat_combo.name, total_damage, extra_effect_text]
	_update_battle_ui(battle)
	# 检查胜利
	if battle_enemy_hp <= 0 and not _battle_ending:
		_battle_ending = true
		if result_label:
			result_label.text += "\n🎉 战斗胜利!"
		var gold_reward = 10 + (GameState.current_floor + 1) * 2
		if GameState.has_greedy_gloves():
			gold_reward = int(gold_reward * GameState.get_gold_reward_multiplier())
		var bonus_gold = GameState.get_combo_buff("bonus_gold")
		if bonus_gold > 0:
			gold_reward += bonus_gold
		GameState.player_gold += gold_reward
		GameState.on_battle_won()
		var material_drop = 1
		if is_current_battle_boss: material_drop = 3
		elif GameState.current_floor >= 5: material_drop = 2
		GameState.add_materials(material_drop)
		GameState.unequip_all_after_battle()
		await _handle_battle_victory_rewards(battle)
		await get_tree().create_timer(1.5).timeout
		_advance_floor()

func _clamp_boss_phase(result_label: Label = null) -> void:
	"""BOSS锁血：一阶段HP不低于50%，触发时进入二阶段"""
	if not is_current_battle_boss or current_enemy_ai == null:
		return
	if current_enemy_ai.boss_phase != 1:
		return
	var phase2_hp = int(battle_enemy_max_hp / 2.0)
	if battle_enemy_hp <= phase2_hp:
		battle_enemy_hp = phase2_hp
		current_enemy_ai.set_boss_phase(2)
		if result_label:
			result_label.text += "\n💀 BOSS进入最终形态！将100%克制你的出招！"
			result_label.text += "\n⚡ 必须依靠装备升级和连招强化来击败！"

const MOVE_SYMBOLS: Array[String] = ["○", "△", "□"]
var _player_move_history: Array[int] = []
var _enemy_move_history: Array[int] = []

func _get_combo_progress_text() -> String:
	"""连招进度：显示距离每个连招还差几步"""
	if combo_sequence.size() == 0:
		return ""
	var combo_db = _get_combo_database()
	if not combo_db:
		return ""
	var all_combos: Array = []
	for cid in GameState.get_equipped_combos():
		var cd = combo_db.get_combo_by_id(cid)
		if cd:
			all_combos.append({"name": cd.name, "sequence": cd.sequence})
	var cn: Array[String] = ["医生", "黑客", "商人", "农民", "流浪者"]
	for c in ComboData.get_exclusive_combos(cn[GameState.player_class]):
		all_combos.append({"name": c.display_name, "sequence": c.sequence})
	for item in GameState.equipment_slot:
		if item.has("exclusive_combo") and item.exclusive_combo != "":
			var wc = combo_db.get_combo_by_id(item.exclusive_combo)
			if wc:
				all_combos.append({"name": wc.name, "sequence": wc.sequence})
	if all_combos.is_empty():
		return ""
	var parts: Array[String] = []
	var recent = combo_sequence
	for combo in all_combos:
		var seq = combo.sequence
		if seq.size() != 3:
			continue
		var matched = 0
		if recent.size() > 0:
			for i in range(min(recent.size(), seq.size())):
				if recent[recent.size() - 1 - i] == seq[seq.size() - 1 - i]:
					matched += 1
				else:
					break
		if matched > 0:
			var syms = ""
			for m in seq:
				syms += MOVE_SYMBOLS[m]
			parts.append("%s %s(%d/3)" % [syms, combo.name, matched])
	if parts.is_empty():
		return ""
	return "🎯 " + " | ".join(parts)

func _get_history_text(history: Array[int]) -> String:
	if history.is_empty():
		return "---"
	var text = ""
	var start = maxi(0, history.size() - 3)
	for i in range(start, history.size()):
		text += MOVE_SYMBOLS[history[i]]
		if i < history.size() - 1:
			text += " "
	return text

func _update_history_display(battle: Control) -> void:
	var ph = battle.get_node_or_null("PlayerHistory")
	if ph: ph.text = _get_history_text(_player_move_history)
	var eh = battle.get_node_or_null("EnemyHistory")
	if eh: eh.text = _get_history_text(_enemy_move_history)
	var cp = battle.get_node_or_null("ComboProgress")
	if cp: cp.text = _get_combo_progress_text()

func _process_battle_turn(player_move: int, battle: Control, enemy_ai: EnemyAI):
	# 检查战斗结束锁，防止多次触发
	if _battle_ending:
		print("Battle already ending, ignoring input")
		return
	
	print("Battle turn - Player: ", player_move)
	
	combo_sequence.append(player_move)
	enemy_ai.add_player_history(player_move)
	
	var symbols = ["○", "△", "□"]
	
	# 如果是BOSS二阶段，预测玩家出招
	var predicted_move = -1
	if enemy_ai.ai_type == 3 and enemy_ai.boss_phase == 2:
		predicted_move = player_move
	
	var enemy_move = enemy_ai.get_next_move(battle_enemy_hp, battle_enemy_max_hp, predicted_move)
	
	# 记录出招历史
	_player_move_history.append(player_move)
	_enemy_move_history.append(enemy_move)
	if _player_move_history.size() > 20:
		_player_move_history.pop_front()
	if _enemy_move_history.size() > 20:
		_enemy_move_history.pop_front()
	
	# ===== 先检查连招 =====
	var _combo_triggered = ""
	var combo_info = null
	var is_equipment_combo = false
	
	# 收集允许使用的连招ID（三类）
	var allowed_combo_ids: Array[String] = []
	# 1. 开局选择携带的连招
	for cid in GameState.get_equipped_combos():
		if not cid in allowed_combo_ids:
			allowed_combo_ids.append(cid)
	# 2. 角色专属连招
	var class_names_local: Array[String] = ["医生", "黑客", "商人", "农民", "流浪者"]
	var excl_combos = ComboData.get_exclusive_combos(class_names_local[GameState.player_class])
	for c in excl_combos:
		if not c.combo_id in allowed_combo_ids:
			allowed_combo_ids.append(c.combo_id)
	# 3. 武器专属连招
	for item in GameState.equipment_slot:
		if item.has("exclusive_combo") and item.exclusive_combo != "":
			if not item.exclusive_combo in allowed_combo_ids:
				allowed_combo_ids.append(item.exclusive_combo)
	
	var combo_db = _get_combo_database()
	if combo_db and combo_sequence.size() >= 3:
		# 手动取最后3个（避免slice类型问题）
		var s = combo_sequence.size()
		var last_3: Array[int] = [combo_sequence[s - 3], combo_sequence[s - 2], combo_sequence[s - 1]]
		print("[Combo] 序列匹配: 最近3招 = ", last_3, " 总序列 = ", combo_sequence)
		print("[Combo] 允许的连招ID: ", allowed_combo_ids)
		var _checked_count = 0
		
		# 检查装备连招（必须拥有对应装备且在允许列表中）
		for combo in combo_db.get_all_combos():
			if not combo.is_unlocked or combo.sequence.size() != 3:
				continue
			if not combo.id in allowed_combo_ids:
				continue
			_checked_count += 1
			
			var match_found = true
			for i in range(3):
				if last_3[i] != combo.sequence[i]:
					match_found = false
					break
			
			if not match_found:
				continue
			
			if combo.id == "bloodthirsty_slash" and GameState.has_demon_blade():
				combo_info = combo
				is_equipment_combo = true
				break
			elif combo.id == "reflect_aura" and GameState.has_heart_mirror():
				combo_info = combo
				is_equipment_combo = true
				break
			elif combo.id == "absolute_hit" and GameState.has_precision_system_full():
				combo_info = combo
				is_equipment_combo = true
				break
		
		print("[Combo] 已检查 ", _checked_count, " 个连招, 匹配: ", combo_info != null)
		
		# 检查普通连招（在允许列表中）
		if not combo_info:
			for combo in combo_db.get_all_combos():
				if not combo.is_unlocked or combo.sequence.size() != 3:
					continue
				if not combo.id in allowed_combo_ids:
					continue
				if GameState.is_combo_on_cooldown(combo.id):
					continue
				
				var match_found = true
				for i in range(3):
					if last_3[i] != combo.sequence[i]:
						match_found = false
						break
				
				if not match_found:
					continue
				
				var can_trigger = true
				if combo.id == "desperate_counter" and not GameState.can_trigger_desperate():
					can_trigger = false
				elif combo.id == "iron_fortress" and not GameState.can_trigger_iron_fortress():
					can_trigger = false
				elif combo.id == "supply_bombard" and not GameState.can_trigger_supply_bombard():
					can_trigger = false
				
				if can_trigger:
					combo_info = combo
					_combo_triggered = combo.effect_type
					print("[Combo] ✅ 匹配连招: ", combo.name, " (", combo.id, ")")
					break
		
		# 检查角色专属连招 + 武器专属连招（combo_data.gd 定义）
		if not combo_info and combo_sequence.size() >= 3:
			var ss = combo_sequence.size()
			var last_3_seq: Array[int] = [combo_sequence[ss - 3], combo_sequence[ss - 2], combo_sequence[ss - 1]]
			# 角色专属
			var class_names_arr: Array[String] = ["医生", "黑客", "商人", "农民", "流浪者"]
			var class_combos = ComboData.get_exclusive_combos(class_names_arr[GameState.player_class])
			for cc in class_combos:
				if cc.sequence.size() != 3:
					continue
				if GameState.is_combo_on_cooldown(cc.combo_id):
					continue
				var matched = true
				for i in range(3):
					if last_3_seq[i] != cc.sequence[i]:
						matched = false
						break
				if matched:
					combo_info = cc
					_combo_triggered = cc.effect_type
					break
			# 武器专属
			if not combo_info:
				for item in GameState.equipment_slot:
					if not item.has("exclusive_combo") or item.exclusive_combo == "":
						continue
					var wc = ComboData.get_combo_by_id(item.exclusive_combo)
					if wc == null:
						continue
					if wc.sequence.size() != 3:
						continue
					if GameState.is_combo_on_cooldown(wc.combo_id):
						continue
					var w_matched = true
					for i in range(3):
						if last_3_seq[i] != wc.sequence[i]:
							w_matched = false
							break
					if w_matched:
						combo_info = wc
						is_equipment_combo = true
						_combo_triggered = wc.effect_type
						break
	
	# 暴击判定
	var is_crit = false
	var force_crit = false
	
	# 检查暴击增益
	var crit_boost_val = GameState.get_combo_buff("crit_boost")
	
	# 检查绝对命中
	if combo_info and combo_info.effect_type == "auto_crit":
		force_crit = true
		is_crit = true
		print("[Battle] 绝对命中：强制暴击")
	elif GameState.get_crit_chance() > 0 or crit_boost_val > 0:
		var total_crit_chance = GameState.get_crit_chance() + crit_boost_val
		is_crit = randf() < total_crit_chance
	
	# 显示出招
	battle.get_node("MoveInfo").text = "你: %s vs 敌: %s" % [symbols[player_move], symbols[enemy_move]]
	
	# 初始化结果文本
	var result_text = ""
	
	# 处理连招效果
	if combo_info:
		match combo_info.effect_type:
			"damage", "damage_first", "damage_pierce", "damage_all":
				var dmg = combo_info.effect_value
				# 应用连招强化倍率
				var combo_mult = GameState.get_combo_damage_multiplier(_get_combo_id(combo_info))
				dmg = int(dmg * combo_mult)
				if combo_info.effect_type == "damage_pierce":
					result_text += "【%s】穿透攻击! " % _get_combo_name(combo_info)
				elif combo_info.effect_type == "damage_all":
					result_text += "【%s】全体攻击! " % _get_combo_name(combo_info)
				else:
					result_text += "【%s】造成%d伤害! " % [_get_combo_name(combo_info), dmg]
				battle_enemy_hp = maxi(battle_enemy_hp - dmg, 0)
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"shield_reflect", "shield_reflect_adv", "shield_all":
				var shield_val = int(combo_info.effect_value * GameState.get_combo_damage_multiplier(_get_combo_id(combo_info)))
				GameState.player_shield += shield_val
				if combo_info.effect_type == "shield_all":
					result_text += "【%s】全体护盾+%d! " % [_get_combo_name(combo_info), shield_val]
				else:
					result_text += "【%s】获得%d护甲，反弹伤害! " % [_get_combo_name(combo_info), shield_val]
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"attack_buff":
				GameState.apply_combo_buff("attack", combo_info.effect_value, combo_info.effect_value)
				result_text += "【%s】下%d回合攻击+%d! " % [_get_combo_name(combo_info), combo_info.effect_value, combo_info.effect_value]
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"enemy_cooldown":
				battle_enemy_hp = maxi(battle_enemy_hp - 1, 0)
				result_text += "【%s】干扰敌人! " % _get_combo_name(combo_info)
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"shield_duration":
				var sd_val = int(combo_info.effect_value * GameState.get_combo_damage_multiplier(_get_combo_id(combo_info)))
				GameState.player_shield += sd_val
				GameState.apply_combo_buff("shield_duration", sd_val, sd_val)
				result_text += "【%s】获得%d护甲，持续%d回合! " % [_get_combo_name(combo_info), sd_val, sd_val]
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"heal":
				var heal_val = int(combo_info.effect_value * GameState.get_combo_damage_multiplier(_get_combo_id(combo_info)))
				GameState.player_hp = mini(GameState.player_hp + heal_val, GameState.player_max_hp)
				result_text += "【%s】恢复%d生命! " % [_get_combo_name(combo_info), heal_val]
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"crit_buff":
				result_text += "【%s】暴击率+50%%! " % _get_combo_name(combo_info)
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"ignore_armor":
				result_text += "【%s】无视护甲! " % _get_combo_name(combo_info)
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"life_steal_50":
				result_text += "【%s】伤害50%%吸血! " % _get_combo_name(combo_info)
				# 装备连招：不消耗序列，不冷却
			
			"reflect_3x":
				result_text += "【%s】反弹3倍伤害! " % _get_combo_name(combo_info)
				# 装备连招：不消耗序列，不冷却
			
			"auto_crit":
				result_text += "【%s】必中暴击! " % _get_combo_name(combo_info)
				# 装备连招：不消耗序列，不冷却
			
			"desperate":
				if GameState.can_trigger_desperate():
					result_text += "【%s】绝地反击!伤害×2+3护甲 " % _get_combo_name(combo_info)
					GameState.player_shield += 3
				else:
					result_text += "【%s】条件不满足 " % _get_combo_name(combo_info)
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"shield_to_damage":
				if GameState.can_trigger_iron_fortress():
					var shield_dmg = GameState.player_shield
					battle_enemy_hp = maxi(battle_enemy_hp - shield_dmg, 0)
					result_text += "【%s】护甲反击%d伤害! " % [_get_combo_name(combo_info), shield_dmg]
				else:
					result_text += "【%s】条件不满足 " % _get_combo_name(combo_info)
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"consume_item_damage":
				if GameState.can_trigger_supply_bombard():
					if GameState.backpack.size() > 0:
						GameState.remove_from_backpack(0)  # 消耗第一个物品
						var item_dmg = int(combo_info.effect_value * GameState.get_combo_damage_multiplier(_get_combo_id(combo_info)))
						battle_enemy_hp = maxi(battle_enemy_hp - item_dmg, 0)
						result_text += "【%s】消耗物品造成%d伤害! " % [_get_combo_name(combo_info), item_dmg]
					else:
						result_text += "【%s】背包为空 " % _get_combo_name(combo_info)
				else:
					result_text += "【%s】条件不满足 " % _get_combo_name(combo_info)
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"invincible":
				result_text += "【%s】下回合无敌! " % _get_combo_name(combo_info)
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			# ===== 角色专属连招效果 =====
			
			"pierce_buff":
				# 医生-望闻问切：攻击+3，无视1护甲
				var pierce_atk = int(combo_info.effect_value * GameState.get_combo_damage_multiplier(_get_combo_id(combo_info)))
				GameState.apply_combo_buff("attack", pierce_atk, 1)
				GameState.apply_combo_buff("pierce", 1, 1)
				result_text += "【%s】攻击+%d，无视1护甲! " % [_get_combo_name(combo_info), pierce_atk]
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"heal_shield":
				# 医生-妙手回春：恢复5生命，满血则+2护甲
				var heal_val = int(combo_info.effect_value * GameState.get_combo_damage_multiplier(_get_combo_id(combo_info)))
				if GameState.player_hp < GameState.player_max_hp:
					GameState.player_hp = mini(GameState.player_hp + heal_val, GameState.player_max_hp)
					result_text += "【%s】恢复%d生命! " % [_get_combo_name(combo_info), heal_val]
				else:
					GameState.player_shield += 2
					result_text += "【%s】满血转护甲+2! " % _get_combo_name(combo_info)
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"stun_damage":
				# 黑客-病毒植入：敌人无法行动，2伤害
				var stun_dmg = int(combo_info.effect_value * GameState.get_combo_damage_multiplier(_get_combo_id(combo_info)))
				battle_enemy_hp = maxi(battle_enemy_hp - stun_dmg, 0)
				GameState.apply_combo_buff("enemy_stun", 1, 1)
				result_text += "【%s】造成%d伤害+眩晕! " % [_get_combo_name(combo_info), stun_dmg]
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"ignore_armor_damage":
				# 黑客-系统过载：无视护甲，6伤害
				var ia_dmg = int(combo_info.effect_value * GameState.get_combo_damage_multiplier(_get_combo_id(combo_info)))
				battle_enemy_hp = maxi(battle_enemy_hp - ia_dmg, 0)
				result_text += "【%s】无视护甲%d伤害! " % [_get_combo_name(combo_info), ia_dmg]
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"bonus_gold":
				# 商人-金钱帝国：战斗胜利额外获得金币
				var gold_val = combo_info.effect_value
				GameState.apply_combo_buff("bonus_gold", gold_val, 99)
				result_text += "【%s】胜利额外+%d金币! " % [_get_combo_name(combo_info), gold_val]
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"crit_boost":
				# 商人-精算头脑：暴击率+40%，暴击伤害+50%
				GameState.apply_combo_buff("crit_boost", combo_info.effect_value, 1)
				result_text += "【%s】暴击率+%%40! " % _get_combo_name(combo_info)
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"armor_delayed":
				# 农民-固若金汤：获得护甲，下回合再获得
				var armor_total = int(combo_info.effect_value * GameState.get_combo_damage_multiplier(_get_combo_id(combo_info)))
				var armor_now = 5
				var armor_next = armor_total - armor_now
				GameState.player_shield += armor_now
				GameState.apply_combo_buff("shield_delayed", armor_next, 1)
				result_text += "【%s】护甲+%d，下回合+%d! " % [_get_combo_name(combo_info), armor_now, armor_next]
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			"regen":
				# 农民-五谷丰登：每回合恢复，持续3回合
				var regen_total = int(combo_info.effect_value * GameState.get_combo_damage_multiplier(_get_combo_id(combo_info)))
				GameState.apply_combo_buff("regen", 2, 3)
				result_text += "【%s】每回合恢复2生命，持续3回合! " % _get_combo_name(combo_info)
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				combo_sequence.clear()
			
			_:
				result_text += "【%s】触发! " % _get_combo_name(combo_info)
				if is_equipment_combo:
					print("[Battle] 装备连招效果: ", _get_combo_name(combo_info))
				else:
					GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
					combo_sequence.clear()
		
		if combo_info:
			var triggered_combo_id = _get_combo_id(combo_info)
			if triggered_combo_id != "":
				if GameState.has_combo_effect(triggered_combo_id, "burn"):
					GameState.apply_combo_buff("enemy_burn", 2, 2)
					result_text += "【灼烧】"
				if GameState.has_combo_effect(triggered_combo_id, "slow"):
					GameState.apply_combo_buff("enemy_slow", 1, 2)
					result_text += "【减速】"
		
	# 应用连招攻击加成
	var total_attack = GameState.get_total_attack()
	var combo_buff_attack = GameState.get_combo_buff("attack")
	if combo_buff_attack > 0:
		total_attack += combo_buff_attack
		print("[Battle] Attack buff active: +", combo_buff_attack)
	
	# 判断胜负
	var is_draw = (player_move == enemy_move)
	var player_wins = false
	
	if not is_draw:
		player_wins = (player_move == 0 and enemy_move == 1) or \
					(player_move == 1 and enemy_move == 2) or \
					(player_move == 2 and enemy_move == 0)
	
	var damage_dealt = 0
	var life_steal = 0
	
	if is_draw:
		result_text += "🤝 平局!"
		GameState.add_cheat_point()
		if GameState.arm_draw_protection():
			result_text += " 【平局保护已就绪】"
		# 平局不扣血，但给1点外挂点数
		
	elif player_wins:
		var base_damage = total_attack
		
		# 装备强化倍率
		# 绝地反击：伤害×2
		if combo_info and combo_info.effect_type == "desperate":
			base_damage = base_damage * 2
			print("[Battle] 绝地反击：伤害×2 = ", base_damage)
		
		if is_crit or force_crit:
			base_damage = int(base_damage * 1.5)
			damage_dealt = base_damage
			result_text += "✅ 暴击!"
		else:
			damage_dealt = base_damage
			result_text += "✅ 命中!"
		
		battle_enemy_hp = maxi(battle_enemy_hp - damage_dealt, 0)
		# BOSS锁血
		_clamp_boss_phase(battle.get_node_or_null("ResultLabel"))
		
		# 嗜血斩：伤害50%转化为生命
		if combo_info and combo_info.effect_type == "life_steal_50":
			var blood_heal = int(damage_dealt * 0.5)
			GameState.player_hp = mini(GameState.player_hp + blood_heal, GameState.player_max_hp)
			result_text += " (嗜血+%d)" % blood_heal
		
		life_steal = GameState.get_life_steal(damage_dealt)
		if life_steal > 0:
			GameState.player_hp = mini(GameState.player_hp + life_steal, GameState.player_max_hp)
			result_text += " (偷取%d)" % life_steal
	
	else:
		# 检查眩晕效果
		var stun_val = GameState.get_combo_buff("enemy_stun")
		if stun_val > 0:
			result_text += "💫 敌人眩晕跳过! "
		else:
			result_text += "❌ 失误!"
			
			var damage = battle_enemy_atk
			var slow_val = GameState.get_combo_buff("enemy_slow")
			if slow_val > 0:
				damage = maxi(damage - slow_val, 1)
				result_text += " 【减速-%d攻】" % slow_val
			
			# 贪婪手套：受到伤害+50%
			var damage_taken_mult = GameState.get_damage_taken_multiplier()
			if damage_taken_mult > 1.0:
				damage = int(damage * damage_taken_mult)
				result_text += " 【贪婪+50%伤】"

			if GameState.consume_draw_protection():
				result_text += " 【平局保护免疫%d伤害】" % damage
				damage = 0
			
			# 使用新的护盾伤害处理系统
			var ignore_shield = false
			var damage_result = GameState.apply_damage(damage, ignore_shield)
			var damage_to_shield = damage_result.shield_absorbed
			var actual_damage = damage_result.actual_damage
			
			# 护盾反射效果（护心镜或反伤光环）
			if damage_to_shield > 0 and GameState.has_shield_reflect():
				var reflect_amount = int(round(float(damage_to_shield) * GameState.get_shield_reflect_multiplier()))
				if combo_info and combo_info.effect_type == "reflect_3x":
					reflect_amount *= 3
					result_text += " 【反伤光环×3:%d】" % reflect_amount
				else:
					result_text += " 【护心镜反弹%d】" % reflect_amount
				battle_enemy_hp = maxi(battle_enemy_hp - reflect_amount, 0)
			
			if damage_to_shield > 0:
				if damage_result.shield_broken:
					result_text += " (护盾%d破!)" % damage_to_shield
				else:
					result_text += " (护盾-%d)" % damage_to_shield
			
			if actual_damage > 0:
				result_text += " 生命-%d" % actual_damage
	
	# 回合结束效果处理
	var burn_val = GameState.get_combo_buff("enemy_burn")
	if burn_val > 0 and battle_enemy_hp > 0:
		battle_enemy_hp = maxi(battle_enemy_hp - burn_val, 0)
		result_text += " 🔥灼烧-%d" % burn_val
	var regen_val = GameState.get_combo_buff("regen")
	if regen_val > 0:
		GameState.player_hp = mini(GameState.player_hp + regen_val, GameState.player_max_hp)
	var delayed_shield = GameState.get_combo_buff("shield_delayed")
	if delayed_shield > 0:
		GameState.player_shield += delayed_shield
	
	battle.get_node("ResultLabel").text = result_text
	_update_battle_ui(battle)
	_update_history_display(battle)
	
	# 处理连招冷却和增益
	GameState.reduce_cooldowns()
	GameState.process_combo_buffs()
	
	# BOSS转阶段检测
	_clamp_boss_phase(battle.get_node_or_null("ResultLabel"))
	
	# 检查战斗结束
	if battle_enemy_hp <= 0:
		_battle_ending = true  # 设置战斗结束锁
		battle.get_node("ResultLabel").text += "\n🎉 战斗胜利!"
		
		# 计算金币奖励（贪婪手套加成）
		var gold_reward = 10 + (GameState.current_floor + 1) * 2
		if GameState.has_greedy_gloves():
			gold_reward = int(gold_reward * GameState.get_gold_reward_multiplier())
			result_text += " 【贪婪+50%金币】"
		
		# 商人专属：金钱帝国额外金币
		var bonus_gold = GameState.get_combo_buff("bonus_gold")
		if bonus_gold > 0:
			gold_reward += bonus_gold
		
		GameState.player_gold += gold_reward
		GameState.on_battle_won()
		
		# 材料掉落（战斗/精英怪/BOSS）
		var material_drop = 1
		if is_current_battle_boss:  # BOSS战奖励更多材料
			material_drop = 3
		elif GameState.current_floor >= 5:  # 深层战斗更多材料
			material_drop = 2
		GameState.add_materials(material_drop)
		
		GameState.unequip_all_after_battle()
		await _handle_battle_victory_rewards(battle)
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): _advance_floor())
		return  # 防止函数继续执行
	
	elif GameState.player_hp <= 0:
		# 医生复活检查
		if GameState.try_resurrection():
			battle.get_node("ResultLabel").text += "\n✨ 医生复活！恢复%d生命" % GameState.resurrection_hp
			_update_battle_ui(battle)
		else:
			_battle_ending = true  # 设置战斗结束锁
			battle.get_node("ResultLabel").text += "\n💀 战斗失败!"
			var timer = get_tree().create_timer(1.5)
			timer.timeout.connect(func(): _show_game_over(false))
			return  # 防止函数继续执行

func _update_battle_ui(battle: Control):
	var enemy_hp_bar = ""
	for i in range(battle_enemy_max_hp):
		enemy_hp_bar += "💚" if i < battle_enemy_hp else "🖤"
	battle.get_node("EnemyHP").text = enemy_hp_bar + " %d/%d" % [battle_enemy_hp, battle_enemy_max_hp]
	
	var player_hp_bar = ""
	for i in range(GameState.player_max_hp):
		player_hp_bar += "❤️" if i < GameState.player_hp else "🖤"
	battle.get_node("PlayerHP").text = player_hp_bar + " %d/%d" % [GameState.player_hp, GameState.player_max_hp]
	
	battle.get_node("PlayerAtk").text = "⚔️ %d" % GameState.get_total_attack()
	
	var shield_label = battle.get_node_or_null("PlayerShield")
	if shield_label:
		shield_label.text = "🛡️ %d" % GameState.player_shield
		shield_label.visible = GameState.player_shield > 0
	
	var cheat_label = battle.get_node_or_null("CheatLabel")
	if cheat_label:
		cheat_label.text = GameState.get_cheat_label_text("🔍")

	var cheat_btn = battle.get_node_or_null("CheatButton")
	if cheat_btn:
		cheat_btn.text = GameState.get_cheat_label_text("🔍 外挂")
		cheat_btn.disabled = GameState.cheat_points <= 0

	var protection_label = battle.get_node_or_null("DrawProtectionLabel")
	if protection_label:
		protection_label.text = GameState.get_draw_protection_status_text()
		protection_label.visible = protection_label.text != ""
	
	var materials_label = battle.get_node_or_null("MaterialsLabel")
	if materials_label:
		materials_label.text = "🔧 %d" % GameState.materials
	
	var energy_label = battle.get_node_or_null("ComboEnergyLabel")
	if energy_label:
		energy_label.text = "⚡ %d/%d" % [GameState.get_combo_energy(), GameState.get_max_combo_energy()]
	
	var energy_display = battle.get_node_or_null("ComboEnergyDisplay")
	if energy_display:
		energy_display.text = "⚡ 连击能量: %d/%d" % [GameState.get_combo_energy(), GameState.get_max_combo_energy()]
	
	# 刷新连招按钮
	var combo_container = battle.get_node_or_null("ComboButtons")
	if combo_container:
		_update_combo_buttons(combo_container, battle, current_enemy_ai)

func _use_cheat(battle: Control, enemy_ai: EnemyAI):
	if GameState.cheat_points <= 0:
		return
	
	if not GameState.consume_cheat_point():
		return
	
	var cheat_panel = Panel.new()
	cheat_panel.name = "CheatPanel"
	cheat_panel.position = Vector2(440, 260)
	cheat_panel.custom_minimum_size = Vector2(400, 200)
	cheat_panel.size = Vector2(400, 200)
	
	var bg = ColorRect.new()
	bg.color = Color(0.18, 0.18, 0.22)
	bg.custom_minimum_size = Vector2(400, 200)
	bg.size = Vector2(400, 200)
	cheat_panel.add_child(bg)
	
	var cheat_title = Label.new()
	cheat_title.text = "🔍 预知外挂\n选择要强制的结果:"
	cheat_title.position = Vector2(0, 20)
	cheat_title.add_theme_font_size_override("font_size", 20)
	cheat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cheat_title.custom_minimum_size = Vector2(400, 60)
	cheat_panel.add_child(cheat_title)
	
	var win_btn = Button.new()
	win_btn.text = "强制胜利"
	win_btn.custom_minimum_size = Vector2(120, 50)
	win_btn.position = Vector2(60, 120)
	win_btn.pressed.connect(func(): _apply_cheat("win", cheat_panel, battle, enemy_ai))
	cheat_panel.add_child(win_btn)
	
	var draw_btn = Button.new()
	draw_btn.text = "强制平局"
	draw_btn.custom_minimum_size = Vector2(120, 50)
	draw_btn.position = Vector2(220, 120)
	draw_btn.pressed.connect(func(): _apply_cheat("draw", cheat_panel, battle, enemy_ai))
	cheat_panel.add_child(draw_btn)
	
	battle.add_child(cheat_panel)

func _apply_cheat(result: String, panel: Panel, battle: Control, enemy_ai: EnemyAI):
	panel.queue_free()
	
	var enemy_move = randi() % 3
	var symbols = ["○", "△", "□"]
	var player_move = 0
	
	if result == "win":
		if enemy_move == 0: player_move = 2
		elif enemy_move == 1: player_move = 0
		else: player_move = 1
		
		battle.get_node("MoveInfo").text = "🔍 强制胜利! 你%s 敌%s" % [symbols[player_move], symbols[enemy_move]]
		battle_enemy_hp = maxi(battle_enemy_hp - GameState.get_total_attack(), 0)
		_clamp_boss_phase(battle.get_node_or_null("ResultLabel"))
		
	else:
		player_move = enemy_move
		battle.get_node("MoveInfo").text = "🔍 强制平局! 你%s 敌%s" % [symbols[player_move], symbols[enemy_move]]
		battle_enemy_hp = maxi(battle_enemy_hp - 1, 0)
		GameState.add_cheat_point()
	
	combo_sequence.append(player_move)
	enemy_ai.add_player_history(player_move)
	_update_battle_ui(battle)
	
	if battle_enemy_hp <= 0:
		battle.get_node("ResultLabel").text = "🎉 战斗胜利! (外挂)"
		GameState.player_gold += 10 + (GameState.current_floor + 1) * 2
		GameState.on_battle_won()
		GameState.unequip_all_after_battle()
		await _handle_battle_victory_rewards(battle)
		
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): _advance_floor())

func _advance_floor():
	print("Advancing from floor ", GameState.current_floor)
	
	# 标记当前层已访问（不可返回）
	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = false
	
	# 从下往上走：递增层数
	GameState.current_floor += 1
	combo_sequence.clear()
	current_enemy_ai = null
	current_enemy_data = null
	
	# 检查是否到达塔顶（通关）
	if GameState.current_floor >= GameState.max_floors:
		_show_victory()
		return
	
	# 设置下一层可访问
	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = true
	
	# 返回地图选择节点（不再自动进入休息点）
	_show_map()

func _show_rest_point():
	"""显示休息点场景"""
	print("Showing rest point")
	_change_state(State.REST_POINT)
	GameState.save_progress("rest")
	
	var rest_point = load("res://scenes/ui/rest_point.tscn").instantiate()
	rest_point.name = "RestPoint"
	
	# 连接信号
	rest_point.continue_to_next_floor.connect(_on_rest_point_continue)
	
	_add_ui(rest_point)
	print("Rest point displayed")

func _on_rest_point_continue():
	"""休息点继续下一层（战斗后休息点）"""
	print("Continuing from rest point (post-battle) to next floor")
	_advance_floor_after_rest_point()

func _on_rest_point_continue_from_map():
	"""休息点继续下一层（从地图休息节点进入）"""
	print("Continuing from rest point (from map node) to next floor")
	
	# 标记当前层已访问
	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = false
	
	# 递增层数
	GameState.current_floor += 1
	combo_sequence.clear()
	current_enemy_ai = null
	current_enemy_data = null
	
	# 检查通关
	if GameState.current_floor >= GameState.max_floors:
		_show_victory()
		return
	
	# 设置下一层可访问
	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = true
	
	_show_map()

func _advance_floor_after_rest_point():
	"""从战斗后休息点进入下一层"""
	print("Advancing after rest point to next floor")
	
	# 标记当前层已访问
	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = false
	
	# 递增层数
	GameState.current_floor += 1
	combo_sequence.clear()
	current_enemy_ai = null
	current_enemy_data = null
	
	# 检查通关
	if GameState.current_floor >= GameState.max_floors:
		_show_victory()
		return
	
	# 设置下一层可访问
	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = true
	
	_show_map()

func _show_victory():
	_show_game_over(true)

func _show_game_over(win: bool):
	_change_state(State.GAME_OVER)
	var gameover_ui = Control.new()
	gameover_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	GameState.complete_run(win)
	var summary = GameState.get_run_summary()
	
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_ui.add_child(bg)
	
	var label = Label.new()
	label.text = "🎉 通关胜利" if win else "💀 本局失败"
	label.add_theme_font_size_override("font_size", 56)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 70)
	label.custom_minimum_size = Vector2(1280, 70)
	label.modulate = Color(1, 0.9, 0.6) if win else Color(1, 0.4, 0.4)
	gameover_ui.add_child(label)

	var summary_panel = PanelContainer.new()
	summary_panel.position = Vector2(260, 180)
	summary_panel.custom_minimum_size = Vector2(760, 300)
	gameover_ui.add_child(summary_panel)

	var summary_box = VBoxContainer.new()
	summary_box.position = Vector2(30, 25)
	summary_box.custom_minimum_size = Vector2(700, 250)
	summary_box.add_theme_constant_override("separation", 14)
	summary_panel.add_child(summary_box)

	var headline = Label.new()
	headline.text = "%s | 第%d层 | HP %d/%d | 攻击 %d" % [
		summary.get("class_name", "未知职业"),
		summary.get("floor_reached", 1),
		summary.get("hp", 0),
		summary.get("max_hp", 0),
		summary.get("attack", 0)
	]
	headline.add_theme_font_size_override("font_size", 24)
	headline.modulate = Color(0.9, 0.9, 0.85)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_box.add_child(headline)

	var resource_line = Label.new()
	resource_line.text = "💰 金币 %d    🔧 材料 %d" % [summary.get("gold", 0), summary.get("materials", 0)]
	resource_line.add_theme_font_size_override("font_size", 20)
	resource_line.modulate = Color(0.8, 0.82, 0.75)
	resource_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_box.add_child(resource_line)

	var combo_line = Label.new()
	var combo_ids: Array = summary.get("equipped_combos", [])
	combo_line.text = "本局携带连招: " + (", ".join(combo_ids) if not combo_ids.is_empty() else "无")
	combo_line.add_theme_font_size_override("font_size", 18)
	combo_line.modulate = Color(0.85, 0.8, 0.55)
	combo_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combo_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_box.add_child(combo_line)

	var equip_line = Label.new()
	var equipment_names: Array = summary.get("equipment_names", [])
	equip_line.text = "本局核心装备: " + (", ".join(equipment_names) if not equipment_names.is_empty() else "无")
	equip_line.add_theme_font_size_override("font_size", 18)
	equip_line.modulate = Color(0.75, 0.82, 0.92)
	equip_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equip_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_box.add_child(equip_line)

	var unlock_line = Label.new()
	unlock_line.text = GameState.get_combo_unlock_status_text()
	unlock_line.add_theme_font_size_override("font_size", 18)
	unlock_line.modulate = Color(0.7, 0.75, 0.85)
	unlock_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_box.add_child(unlock_line)

	var button_row = HBoxContainer.new()
	button_row.position = Vector2(400, 540)
	button_row.add_theme_constant_override("separation", 30)
	gameover_ui.add_child(button_row)

	var retry_btn = Button.new()
	retry_btn.text = "再来一局"
	retry_btn.custom_minimum_size = Vector2(180, 56)
	retry_btn.add_theme_font_size_override("font_size", 22)
	retry_btn.modulate = Color(0.74, 0.96, 0.74)
	retry_btn.pressed.connect(_show_character_select)
	button_row.add_child(retry_btn)

	var menu_btn = Button.new()
	menu_btn.text = "返回菜单"
	menu_btn.custom_minimum_size = Vector2(180, 56)
	menu_btn.add_theme_font_size_override("font_size", 22)
	menu_btn.modulate = Color(0.82, 0.84, 0.9)
	menu_btn.pressed.connect(_show_main_menu)
	button_row.add_child(menu_btn)

	_add_ui(gameover_ui)

func _generate_map():
	print("Generating map with tower climbing layout...")
	GameState.map_data.clear()
	
	# 爬塔布局：从下往上
	# floor 0 = 底部（起点/简单）→ floor 15 = 顶部（BOSS）
	
	for floor_num in range(GameState.max_floors):
		var floor_nodes = []
		
		# 计算当前层的难度（0 = 最简单，15 = 最难）
		var difficulty = floor_num  # floor 0 → 0, floor 15 → 15
		
		# 每层节点数量：从下往上逐渐增加
		# floor 0: 3个节点, floor 15: 5个节点
		var node_count = 3 + int(float(difficulty) / float(GameState.max_floors - 1) * 2)
		node_count = clamp(node_count, 3, 5)
		
		# 最后一层（floor 15 / 塔顶）全部是 BOSS
		if floor_num == GameState.max_floors - 1:
			for i in range(node_count):
				floor_nodes.append({"type": 4, "visited": false, "accessible": false})  # 4 = BOSS
		else:
			for i in range(node_count):
				var node_type = _get_node_type_by_difficulty(floor_num, difficulty)
				floor_nodes.append({"type": node_type, "visited": false, "accessible": false})
		
		GameState.map_data.append(floor_nodes)
	
	# 从下往上走模式：初始在最低层 (floor 0)
	GameState.current_floor = 0
	
	# 设置第一层可访问
	for node in GameState.map_data[GameState.current_floor]:
		node.accessible = true
	
	print("Map generated: ", GameState.map_data.size(), " floors, tower climbing layout")
	print("  - Bottom floor (0): Easy nodes")
	print("  - Top floor (15): All BOSS nodes")
	print("  - Difficulty increases as you ascend")

func _get_node_type_by_difficulty(_floor_num: int, difficulty: int) -> int:
	"""
	根据难度获取节点类型
	difficulty: 0 = 最简单, 15 = 最难
	越往上（difficulty越大），战斗节点比例越高
	"""
	# 难度系数：0-15 对应 0%-100%
	var battle_chance = 30 + (difficulty * 4)  # 30% → 90%
	var shop_chance = 25 - (difficulty * 1)     # 25% → 10%
	var rest_chance = 25 - (difficulty * 1.5)   # 25% → 5%
	var event_chance = 20 - (difficulty * 1.5)  # 20% → 0% (后期没有事件)
	
	# 确保概率不小于0
	battle_chance = clamp(battle_chance, 30, 90)
	shop_chance = clamp(shop_chance, 5, 25)
	rest_chance = clamp(rest_chance, 5, 25)
	event_chance = clamp(event_chance, 0, 20)
	
	var roll = randi() % 100
	
	if roll < battle_chance:
		return 0  # 战斗
	elif roll < battle_chance + shop_chance:
		return 1  # 商店
	elif roll < battle_chance + shop_chance + rest_chance:
		return 2  # 休息
	else:
		return 3  # 事件

func _change_state(new_state):
	print("State: ", current_state, " -> ", new_state)
	current_state = new_state
	if current_ui:
		current_ui.queue_free()
		current_ui = null

func _add_ui(ui):
	print("_add_ui called with: ", ui)
	current_ui = ui
	
	# 设置根节点大小为游戏窗口大小
	if ui is Control:
		print("Setting size for Control")
		ui.custom_minimum_size = Vector2(1280, 720)
		# 重要：设置offset让Control有实际大小
		ui.offset_right = 1280
		ui.offset_bottom = 720
	
	print("Adding child...")
	add_child(ui)
	print("Added UI: ", ui.name, " size: ", ui.size)
