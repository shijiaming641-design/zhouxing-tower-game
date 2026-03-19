class_name Main
extends Node2D

enum State { MENU, CHARACTER_SELECT, MAP, BATTLE, SHOP, GAME_OVER, VICTORY }

var current_state: State = State.MENU
var current_ui: Control = null

# 战斗状态
var battle_enemy_hp: int = 0
var battle_enemy_max_hp: int = 0
var battle_enemy_atk: int = 0
var current_enemy_ai: EnemyAI = null
var current_enemy_data: EnemyData = null

# 连招
var combo_sequence: Array[int] = []

func _ready():
	print("Main _ready")
	randomize()
	_show_main_menu()

func _show_main_menu():
	print("Showing main menu")
	_change_state(State.MENU)
	
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	
	# 直接连接按钮信号
	var start_btn = menu.get_node_or_null("StartButton")
	if start_btn:
		print("StartButton found, connecting...")
		start_btn.pressed.connect(func(): _show_character_select())
	else:
		print("ERROR: StartButton not found!")
	
	_add_ui(menu)

func _show_character_select():
	print("Showing character select")
	_change_state(State.CHARACTER_SELECT)
	
	var select = load("res://scenes/ui/character_select.tscn").instantiate()
	
	# 直接连接角色按钮
	for i in range(5):
		var btn = select.get_node_or_null("Char%d" % i)
		if btn:
			btn.pressed.connect(func(idx=i): _on_character_selected(idx))
	
	# 连接返回按钮
	var back_btn = select.get_node_or_null("BackButton")
	if back_btn:
		back_btn.pressed.connect(func(): _show_main_menu())
	
	_add_ui(select)

func _on_character_selected(class_id: int):
	print("Character selected: ", class_id)
	
	GameState.reset_game()
	GameState.player_class = class_id
	
	match class_id:
		0: GameState.player_max_hp = 6;  GameState.player_attack = 2
		1: GameState.player_max_hp = 10; GameState.player_attack = 1
		2: GameState.player_max_hp = 8;  GameState.player_attack = 2
		3: GameState.player_max_hp = 5;  GameState.player_attack = 4
		4: GameState.player_max_hp = 15; GameState.player_attack = 1
	
	GameState.player_hp = GameState.player_max_hp
	GameState.player_shield = 0
	
	_generate_map()
	_show_map()

func _show_map():
	print("Showing map, floor: ", GameState.current_floor)
	_change_state(State.MAP)
	
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
		var class_names = ["探索者", "长生者", "冒险家", "剑士", "坦克"]
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
			var heal_amount = 5
			if GameState.has_heal_double():
				heal_amount *= 2
			GameState.player_hp = mini(GameState.player_hp + heal_amount, GameState.player_max_hp)
			_advance_floor()
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
	var candidates = []
	
	for item_id in GameState.ITEMS:
		var item = GameState.ITEMS[item_id]
		if item.rarity == rarity and item.type == type_name:
			if not GameState.has_in_inventory(item_id):
				candidates.append(item_id)
	
	if candidates.is_empty():
		return ""
	
	return candidates[randi() % candidates.size()]

func _get_random_shop_items() -> Array:
	"""根据权重随机获取3件商店物品"""
	var result = []
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
		var all_items = []
		for item_id in GameState.ITEMS:
			if not GameState.has_in_inventory(item_id) and not item_id in result:
				all_items.append(item_id)
		
		all_items.shuffle()
		while result.size() < 3 and not all_items.is_empty():
			result.append(all_items.pop_front())
	
	return result

func _show_shop():
	print("Shop")
	_change_state(State.SHOP)
	
	var shop = Control.new()
	shop.name = "ShopScene"
	shop.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 背景 - 全屏
	var bg = ColorRect.new()
	bg.color = Color(0.85, 0.85, 0.8)
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
	title.modulate = Color.BLACK
	shop.add_child(title)
	
	# 金币显示
	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "💰 %d" % GameState.player_gold
	gold_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	gold_label.offset_left = 20
	gold_label.offset_top = 15
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_label.modulate = Color.BLACK
	shop.add_child(gold_label)
	
	# ===== 随机3件商品 =====
	var shop_items = _get_random_shop_items()
	
	var shop_title = Label.new()
	shop_title.text = "📦 今日特供（剩余 %d 件）" % shop_items.size()
	shop_title.position = Vector2(490, 80)
	shop_title.add_theme_font_size_override("font_size", 22)
	shop_title.modulate = Color.BLACK
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
			"blue": btn.modulate = Color(0.75, 0.85, 1)
			"red": btn.modulate = Color(1, 0.75, 0.75)
			_: btn.modulate = Color(0.95, 0.95, 0.95)
		
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
			btn.modulate = Color(0.6, 0.6, 0.6)
			btn.text += "\n[金币不足]"
		
		btn.pressed.connect(func(id=item_id): _buy_item(id, shop))
		shop.add_child(btn)
	
	# 没有商品时显示提示
	if shop_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "商店已售罄！"
		empty_label.position = Vector2(540, 200)
		empty_label.add_theme_font_size_override("font_size", 24)
		empty_label.modulate = Color(0.5, 0.5, 0.5)
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
		refresh_btn.modulate = Color(0.6, 0.6, 0.6)
		refresh_btn.text = "🔄 刷新商店 (金币不足)"
	
	refresh_btn.pressed.connect(func(): _refresh_shop(shop))
	shop.add_child(refresh_btn)
	
	# ===== 背包区域 =====
	var inventory_title = Label.new()
	inventory_title.text = "🎒 我的背包"
	inventory_title.position = Vector2(50, 450)
	inventory_title.add_theme_font_size_override("font_size", 20)
	inventory_title.modulate = Color.BLACK
	shop.add_child(inventory_title)
	
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
	"""更新背包显示"""
	# 清除旧的背包显示
	for child in shop.get_children():
		if child.name.begins_with("InvItem_"):
			child.queue_free()
	
	var inventory = GameState.get_inventory()
	var start_x = 50
	var start_y = 490
	
	if inventory.is_empty():
		var empty_label = Label.new()
		empty_label.name = "InvItem_Empty"
		empty_label.text = "（背包空空如也）"
		empty_label.position = Vector2(start_x, start_y)
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.modulate = Color(0.5, 0.5, 0.5)
		shop.add_child(empty_label)
	else:
		# 横向排列背包物品
		for i in range(inventory.size()):
			var item = inventory[i]
			
			# 物品按钮
			var btn = Button.new()
			btn.name = "InvItem_%d" % i
			btn.custom_minimum_size = Vector2(180, 70)
			btn.position = Vector2(start_x + i * 200, start_y)
			
			# 根据稀有度设置颜色
			match item.rarity:
				"blue": btn.modulate = Color(0.75, 0.85, 1)
				"red": btn.modulate = Color(1, 0.75, 0.75)
				_: btn.modulate = Color(0.95, 0.95, 0.95)
			
			btn.text = "%s\n💰%d（卖出）" % [item.name, item.cost]
			btn.add_theme_font_size_override("font_size", 14)
			btn.pressed.connect(func(idx=i): _sell_item(idx, shop))
			shop.add_child(btn)
	
	# 提示文字
	var hint_label = Label.new()
	hint_label.name = "InvItem_Hint"
	hint_label.text = "点击物品卖出（原价回收）"
	hint_label.position = Vector2(start_x, start_y + 80)
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.modulate = Color(0.5, 0.5, 0.5)
	shop.add_child(hint_label)

func _refresh_shop(shop: Control):
	"""刷新商店（消耗金币）"""
	if GameState.player_gold >= SHOP_REFRESH_COST:
		GameState.player_gold -= SHOP_REFRESH_COST
		print("Shop refreshed, cost: ", SHOP_REFRESH_COST, " gold")
		_show_shop()
	else:
		print("Not enough gold to refresh shop")

func _buy_item(item_id: String, shop: Control):
	"""购买物品 - 进入背包"""
	var item = GameState.ITEMS.get(item_id)
	if not item:
		return
	
	if GameState.has_in_inventory(item_id):
		return
	
	# 计算折扣后价格
	var discounted_cost = int(item.cost * GameState.shop_discount)
	
	if GameState.player_gold < discounted_cost:
		return
	
	# 扣除金币
	GameState.player_gold -= discounted_cost
	
	# 添加到背包（不是直接装备）
	GameState.add_to_inventory(item_id)
	
	print("Bought item to inventory: ", item.name, " cost: ", discounted_cost, " (discount: ", GameState.shop_discount, ")")
	
	# 刷新商店显示
	_show_shop()

func _sell_item(index: int, shop: Control):
	"""卖出物品 - 原价回收"""
	if GameState.sell_item(index):
		print("Sold item at index: ", index)
		# 刷新显示
		_show_shop()

func _advance_from_shop():
	"""从商店进入下一层地图"""
	print("Advancing from shop to next floor")
	
	# 标记当前层已访问（不可返回）
	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = false
	
	# 从下往上走：递增层数
	GameState.current_floor += 1
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
	_change_state(State.BATTLE)
	
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
	var symbols = ["○", "△", "□"]
	var enemy_move = randi() % 3
	
	var result_label = battle.get_node("ResultLabel")
	
	if player_move == enemy_move:
		result_label.text = "🤝 平局! 再试一次..."
		return
	
	var player_wins = (player_move == 0 and enemy_move == 1) or \
					(player_move == 1 and enemy_move == 2) or \
					(player_move == 2 and enemy_move == 0)
	
	if player_wins:
		result_label.text = "✅ 胜利! 好事降临!"
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): _show_good_event())
	else:
		result_label.text = "❌ 失败! 坏事发生..."
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): _show_bad_event())

func _show_good_event():
	"""好事事件"""
	print("Good event!")
	_change_state(State.SHOP)
	
	var event = Control.new()
	event.name = "GoodEvent"
	event.custom_minimum_size = Vector2(1280, 720)
	
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.85, 0.95, 0.85)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	event.add_child(bg)
	
	# 标题
	var title = Label.new()
	title.text = "🎉 好事降临!"
	title.position = Vector2(540, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color.BLACK
	event.add_child(title)
	
	# 随机好事
	var good_options = [
		{"name": "生命祝福", "desc": "血量+2", "action": func(): GameState.player_max_hp += 2; GameState.player_hp += 2},
		{"name": "力量祝福", "desc": "攻击+1", "action": func(): GameState.player_attack += 1},
		{"name": "守护祝福", "desc": "护甲+2", "action": func(): GameState.player_shield += 2},
		{"name": "金币奖励", "desc": "获得10金币", "action": func(): GameState.player_gold += 10},
		{"name": "随机装备", "desc": "获得随机装备", "action": func(): _give_random_equipment()},
		{"name": "商店折扣", "desc": "商店7折", "action": func(): GameState.shop_discount = 0.7}
	]
	
	# 随机打乱并取前3个
	good_options.shuffle()
	var options = good_options.slice(0, 3)
	
	# 显示选项
	var start_y = 200
	for i in range(options.size()):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(400, 100)
		btn.position = Vector2(440, start_y + i * 120)
		btn.add_theme_font_size_override("font_size", 20)
		btn.text = "%s\n%s" % [options[i].name, options[i].desc]
		var action = options[i].action
		btn.pressed.connect(func(): 
			action.call()
			_advance_floor()
		)
		event.add_child(btn)
	
	_add_ui(event)

func _show_bad_event():
	"""坏事事件"""
	print("Bad event!")
	_change_state(State.SHOP)
	
	var event = Control.new()
	event.name = "BadEvent"
	event.custom_minimum_size = Vector2(1280, 720)
	
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.95, 0.85, 0.85)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	event.add_child(bg)
	
	# 标题
	var title = Label.new()
	title.text = "💀 坏事发生!"
	title.position = Vector2(540, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color.BLACK
	event.add_child(title)
	
	# 随机坏事
	var bad_options = [
		{"name": "生命削弱", "desc": "血量-2", "action": func(): GameState.player_max_hp = maxi(GameState.player_max_hp - 2, 1); GameState.player_hp = mini(GameState.player_hp, GameState.player_max_hp)},
		{"name": "力量削弱", "desc": "攻击-1", "action": func(): GameState.player_attack = maxi(GameState.player_attack - 1, 1)},
		{"name": "守护削弱", "desc": "护甲-2", "action": func(): GameState.player_shield = maxi(GameState.player_shield - 2, 0)},
		{"name": "金币损失", "desc": "丢失5金币", "action": func(): GameState.player_gold = maxi(GameState.player_gold - 5, 0)},
		{"name": "装备损失", "desc": "随机丢失一件装备", "action": func(): _lose_random_equipment()}
	]
	
	# 随机取一个坏事
	bad_options.shuffle()
	var bad_thing = bad_options[0]
	
	# 显示
	var desc = Label.new()
	desc.text = "%s\n%s" % [bad_thing.name, bad_thing.desc]
	desc.position = Vector2(540, 300)
	desc.add_theme_font_size_override("font_size", 24)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.modulate = Color.BLACK
	event.add_child(desc)
	
	# 确认按钮
	var btn = Button.new()
	btn.text = "接受命运"
	btn.custom_minimum_size = Vector2(200, 60)
	btn.position = Vector2(540, 500)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(func():
		bad_thing.action.call()
		_advance_floor()
	)
	event.add_child(btn)
	
	_add_ui(event)

func _give_random_equipment():
	"""给予随机装备"""
	var all_items = []
	for item_id in GameState.ITEMS:
		if not GameState.has_in_inventory(item_id):
			all_items.append(item_id)
	
	if not all_items.is_empty():
		var random_item = all_items[randi() % all_items.size()]
		GameState.add_to_inventory(random_item)

func _lose_random_equipment():
	"""随机丢失一件装备"""
	var inventory = GameState.get_inventory()
	if not inventory.is_empty():
		var random_index = randi() % inventory.size()
		GameState.remove_from_inventory(random_index)

# ===== 战斗系统（新AI + 背包自动装备）=====

func _show_battle(is_boss: bool):
	print("Battle, is_boss: ", is_boss)
	_change_state(State.BATTLE)
	
	# 自动装备背包
	print("Calling auto_equip_from_inventory...")
	GameState.auto_equip_from_inventory()
	print("Auto-equip completed")
	
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
		1: # 精英：简单循环
			print("Setting up ELITE_CYCLE")
			var patterns = [[0, 1], [0, 2], [1, 2], [0, 0, 1], [1, 1, 2]]
			ai.setup_elite_cycle(patterns[data.ai_subtype % patterns.size()])
		2: # 高级：动态策略
			print("Setting up ADVANCED_DYNAMIC")
			ai.setup_advanced_dynamic(data.ai_subtype)
		3: # BOSS：阶段死局
			print("Setting up BOSS")
			ai.setup_boss()
		_:
			print("Unknown AI type: ", data.ai_type)

func _create_battle_ui(enemy_data: EnemyData, enemy_ai: EnemyAI):
	print("Creating battle Control...")
	var battle = Control.new()
	battle.name = "BattleScene"
	print("Setting battle size...")
	battle.custom_minimum_size = Vector2(1280, 720)
	
	print("Creating background...")
	# 背景 - 全屏
	var bg = ColorRect.new()
	bg.color = Color(0.85, 0.85, 0.8)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	battle.add_child(bg)
	print("Background added")
	
	# ===== 敌人信息 (右上) =====
	print("Creating enemy info labels...")
	var enemy_name = Label.new()
	enemy_name.text = "👹 %s" % enemy_data.display_name
	enemy_name.position = Vector2(950, 30)
	enemy_name.add_theme_font_size_override("font_size", 20)
	enemy_name.modulate = Color.BLACK
	battle.add_child(enemy_name)
	print("Enemy name label added")
	
	print("Creating AI desc label...")
	var ai_desc_text = enemy_data.get_ai_description()
	print("AI description: ", ai_desc_text)
	var ai_desc = Label.new()
	ai_desc.text = "📋 %s" % ai_desc_text
	ai_desc.position = Vector2(950, 55)
	ai_desc.add_theme_font_size_override("font_size", 14)
	ai_desc.modulate = Color(0.4, 0.4, 0.4)
	battle.add_child(ai_desc)
	print("AI desc label added")
	
	print("Creating enemy HP bar...")
	var enemy_hp_bar = ""
	for i in range(battle_enemy_max_hp):
		enemy_hp_bar += "💚" if i < battle_enemy_hp else "🖤"
	print("HP bar created: ", enemy_hp_bar)
	
	var enemy_hp = Label.new()
	enemy_hp.name = "EnemyHP"
	enemy_hp.text = enemy_hp_bar + " %d/%d" % [battle_enemy_hp, battle_enemy_max_hp]
	enemy_hp.position = Vector2(950, 80)
	enemy_hp.add_theme_font_size_override("font_size", 16)
	enemy_hp.modulate = Color.BLACK
	battle.add_child(enemy_hp)
	print("Enemy HP label added")
	
	print("Creating enemy ATK label...")
	var enemy_atk = Label.new()
	enemy_atk.text = "⚔️ %d" % battle_enemy_atk
	enemy_atk.position = Vector2(950, 105)
	enemy_atk.add_theme_font_size_override("font_size", 16)
	enemy_atk.modulate = Color.BLACK
	battle.add_child(enemy_atk)
	print("Enemy ATK label added")
	
	# ===== 玩家信息 (左下) =====
	print("Creating player info...")
	var class_names = ["探索者", "长生者", "冒险家", "剑士", "坦克"]
	
	print("Creating player title...")
	var player_title = Label.new()
	player_title.text = "🧑 %s" % class_names[GameState.player_class]
	player_title.position = Vector2(30, 480)
	player_title.add_theme_font_size_override("font_size", 20)
	player_title.modulate = Color.BLACK
	battle.add_child(player_title)
	print("Player title added")
	
	print("Creating player HP bar...")
	var player_hp_bar = ""
	for i in range(GameState.player_max_hp):
		player_hp_bar += "❤️" if i < GameState.player_hp else "🖤"
	print("Player HP bar: ", player_hp_bar)
	
	var player_hp = Label.new()
	player_hp.name = "PlayerHP"
	player_hp.text = player_hp_bar + " %d/%d" % [GameState.player_hp, GameState.player_max_hp]
	player_hp.position = Vector2(30, 505)
	player_hp.add_theme_font_size_override("font_size", 16)
	player_hp.modulate = Color.BLACK
	battle.add_child(player_hp)
	print("Player HP label added")
	
	print("Creating player ATK label...")
	print("get_total_attack: ", GameState.get_total_attack())
	print("get_bounty_bonus: ", GameState.get_bounty_bonus())
	var player_atk = Label.new()
	player_atk.name = "PlayerAtk"
	player_atk.text = "⚔️ %d (基础%+d)" % [GameState.get_total_attack(), GameState.get_bounty_bonus()]
	player_atk.position = Vector2(30, 530)
	player_atk.add_theme_font_size_override("font_size", 16)
	player_atk.modulate = Color.BLACK
	battle.add_child(player_atk)
	print("Player ATK label added")
	
	if GameState.get_shield() > 0:
		var player_shield = Label.new()
		player_shield.name = "PlayerShield"
		player_shield.text = "🛡️ %d" % GameState.get_shield()
		player_shield.position = Vector2(30, 555)
		player_shield.add_theme_font_size_override("font_size", 16)
		player_shield.modulate = Color.BLACK
		battle.add_child(player_shield)
	
	# ===== 已装备物品 =====
	var items_title = Label.new()
	items_title.text = "🎒 已装备（来自背包）："
	items_title.position = Vector2(30, 590)
	items_title.add_theme_font_size_override("font_size", 14)
	items_title.modulate = Color.BLACK
	battle.add_child(items_title)
	
	var items_text = ""
	if GameState.equipped_items.is_empty():
		items_text = "无"
	else:
		for item in GameState.equipped_items:
			items_text += "[%s] " % item.name
	
	var items_label = Label.new()
	items_label.name = "ItemsLabel"
	items_label.text = items_text
	items_label.position = Vector2(30, 615)
	items_label.add_theme_font_size_override("font_size", 13)
	items_label.modulate = Color.BLACK
	battle.add_child(items_label)
	
	# ===== 中央战斗区域 =====
	var move_info = Label.new()
	move_info.name = "MoveInfo"
	move_info.text = "选择出招..."
	move_info.position = Vector2(490, 180)
	move_info.add_theme_font_size_override("font_size", 32)
	move_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_info.modulate = Color.BLACK
	battle.add_child(move_info)
	
	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = ""
	result_label.position = Vector2(490, 230)
	result_label.add_theme_font_size_override("font_size", 20)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.modulate = Color.BLACK
	battle.add_child(result_label)
	
	# 出招按钮
	var circle_btn = Button.new()
	circle_btn.text = "○ (Q)"
	circle_btn.custom_minimum_size = Vector2(80, 50)
	circle_btn.position = Vector2(500, 360)
	circle_btn.pressed.connect(func(): _process_battle_turn(0, battle, enemy_ai))
	battle.add_child(circle_btn)
	
	var tri_btn = Button.new()
	tri_btn.text = "△ (W)"
	tri_btn.custom_minimum_size = Vector2(80, 50)
	tri_btn.position = Vector2(600, 360)
	tri_btn.pressed.connect(func(): _process_battle_turn(1, battle, enemy_ai))
	battle.add_child(tri_btn)
	
	var square_btn = Button.new()
	square_btn.text = "□ (E)"
	square_btn.custom_minimum_size = Vector2(80, 50)
	square_btn.position = Vector2(700, 360)
	square_btn.pressed.connect(func(): _process_battle_turn(2, battle, enemy_ai))
	battle.add_child(square_btn)
	
	# 连招提示
	var combo_label = Label.new()
	combo_label.text = "连招: OO△=闪电突袭(3伤害)  △△□=稳固防御(+1护盾)"
	combo_label.position = Vector2(440, 420)
	combo_label.add_theme_font_size_override("font_size", 14)
	combo_label.modulate = Color(0.4, 0.4, 0.4)
	battle.add_child(combo_label)
	
	# 外挂标签
	var cheat_label = Label.new()
	cheat_label.name = "CheatLabel"
	cheat_label.text = "🔍 外挂: %d/2" % GameState.cheat_points
	cheat_label.position = Vector2(580, 280)
	cheat_label.add_theme_font_size_override("font_size", 16)
	cheat_label.modulate = Color.BLACK
	battle.add_child(cheat_label)
	
	var cheat_btn = Button.new()
	cheat_btn.text = "使用外挂"
	cheat_btn.custom_minimum_size = Vector2(100, 40)
	cheat_btn.position = Vector2(570, 310)
	cheat_btn.disabled = GameState.cheat_points <= 0
	cheat_btn.pressed.connect(func(): _use_cheat(battle, enemy_ai))
	battle.add_child(cheat_btn)
	
	return battle

func _process_battle_turn(player_move: int, battle: Control, enemy_ai: EnemyAI):
	print("Battle turn - Player: ", player_move)
	
	combo_sequence.append(player_move)
	enemy_ai.add_player_history(player_move)
	
	var symbols = ["○", "△", "□"]
	
	# 如果是BOSS二阶段，预测玩家出招
	var predicted_move = -1
	if enemy_ai.ai_type == 3 and enemy_ai.boss_phase == 2:
		predicted_move = player_move
	
	var enemy_move = enemy_ai.get_next_move(battle_enemy_hp, battle_enemy_max_hp, predicted_move)
	
	# 暴击判定
	var is_crit = false
	if GameState.get_crit_chance() > 0:
		is_crit = randf() < GameState.get_crit_chance()
	
	# 显示出招
	battle.get_node("MoveInfo").text = "你: %s vs 敌: %s" % [symbols[player_move], symbols[enemy_move]]
	
	# 检查连招（在判断胜负前检查）
	var combo_triggered = ""
	if combo_sequence.size() >= 3:
		var last3 = combo_sequence.slice(-3)
		if last3 == [0, 0, 1]:
			combo_triggered = "lightning"
		elif last3 == [1, 1, 2]:
			combo_triggered = "defense"
	
	# 初始化结果文本
	var result_text = ""
	
	# 处理连招效果（在任何情况下都先处理）
	if combo_triggered == "lightning":
		# 闪电突袭：造成3点伤害
		battle_enemy_hp = maxi(battle_enemy_hp - 3, 0)
		result_text += "【闪电突袭】造成3点伤害! "
		combo_sequence.clear()
	elif combo_triggered == "defense":
		# 稳固防御：获得1点护盾
		GameState.player_shield += 1
		result_text += "【稳固防御】护盾+1! "
		combo_sequence.clear()
	
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
		GameState.cheat_points = mini(GameState.cheat_points + 1, 2)
		# 平局不扣血，但给1点外挂点数
		
	elif player_wins:
		var base_damage = GameState.get_total_attack()
		if is_crit:
			base_damage = int(base_damage * 1.5)
			damage_dealt = base_damage
			result_text += "✅ 暴击!"
		else:
			damage_dealt = base_damage
			result_text += "✅ 命中!"
		
		battle_enemy_hp = maxi(battle_enemy_hp - damage_dealt, 0)
		
		life_steal = GameState.get_life_steal(damage_dealt)
		if life_steal > 0:
			GameState.player_hp = mini(GameState.player_hp + life_steal, GameState.player_max_hp)
			result_text += " (偷取%d)" % life_steal
		
	else:
		result_text += "❌ 失误!"
		
		var damage = battle_enemy_atk
		
		# 贪婪手套：受到伤害+50%
		if GameState.has_greedy_gloves():
			damage = int(damage * 1.5)
			result_text += " 【贪婪+50%伤】"
		
		var damage_to_shield = mini(GameState.get_shield(), damage)
		GameState.player_shield -= damage_to_shield
		var actual_damage = damage - damage_to_shield
		
		if damage_to_shield > 0 and GameState.has_shield_reflect():
			battle_enemy_hp = maxi(battle_enemy_hp - damage_to_shield, 0)
			result_text += " 【护心镜反弹%d】" % damage_to_shield
		
		GameState.player_hp = maxi(GameState.player_hp - actual_damage, 0)
		
		if damage_to_shield > 0 and not GameState.has_shield_reflect():
			result_text += " (护盾抵消%d)" % damage_to_shield
	
	battle.get_node("ResultLabel").text = result_text
	battle.get_node("CheatLabel").text = "🔍 外挂: %d/2" % GameState.cheat_points
	
	_update_battle_ui(battle)
	
	# BOSS转阶段检测
	if current_enemy_data and current_enemy_data.ai_type == 3:
		if enemy_ai.boss_phase == 1 and battle_enemy_hp <= battle_enemy_max_hp / 2:
			enemy_ai.set_boss_phase(2)
			battle.get_node("ResultLabel").text += "\n💀 BOSS进入二阶段：死局模式!"
	
	# 检查战斗结束
	if battle_enemy_hp <= 0:
		battle.get_node("ResultLabel").text += "\n🎉 战斗胜利!"
		
		# 计算金币奖励（贪婪手套加成）
		var gold_reward = 10 + (GameState.current_floor + 1) * 2
		if GameState.has_greedy_gloves():
			gold_reward = int(gold_reward * 1.5)
			result_text += " 【贪婪+50%金币】"
		
		GameState.player_gold += gold_reward
		GameState.on_battle_won()
		GameState.unequip_all_after_battle()
		
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): _advance_floor())
		
	elif GameState.player_hp <= 0:
		battle.get_node("ResultLabel").text += "\n💀 战斗失败!"
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): _show_game_over(false))

func _update_battle_ui(battle: Control):
	var enemy_hp_bar = ""
	for i in range(battle_enemy_max_hp):
		enemy_hp_bar += "💚" if i < battle_enemy_hp else "🖤"
	battle.get_node("EnemyHP").text = enemy_hp_bar + " %d/%d" % [battle_enemy_hp, battle_enemy_max_hp]
	
	var player_hp_bar = ""
	for i in range(GameState.player_max_hp):
		player_hp_bar += "❤️" if i < GameState.player_hp else "🖤"
	battle.get_node("PlayerHP").text = player_hp_bar + " %d/%d" % [GameState.player_hp, GameState.player_max_hp]
	
	battle.get_node("PlayerAtk").text = "⚔️ %d (基础%+d)" % [GameState.get_total_attack(), GameState.get_bounty_bonus()]
	
	# 更新护盾显示
	var shield_label = battle.get_node_or_null("PlayerShield")
	if shield_label:
		var shield = GameState.get_shield()
		shield_label.text = "🛡️ %d" % shield
		shield_label.visible = shield > 0

func _use_cheat(battle: Control, enemy_ai: EnemyAI):
	if GameState.cheat_points <= 0:
		return
	
	GameState.cheat_points -= 1
	
	var cheat_panel = Panel.new()
	cheat_panel.name = "CheatPanel"
	cheat_panel.position = Vector2(440, 260)
	cheat_panel.custom_minimum_size = Vector2(400, 200)
	
	var bg = ColorRect.new()
	bg.color = Color(0.9, 0.9, 0.85)
	bg.custom_minimum_size = Vector2(400, 200)
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
		
	else:
		player_move = enemy_move
		battle.get_node("MoveInfo").text = "🔍 强制平局! 你%s 敌%s" % [symbols[player_move], symbols[enemy_move]]
		battle_enemy_hp = maxi(battle_enemy_hp - 1, 0)
		GameState.cheat_points = mini(GameState.cheat_points + 1, 2)
	
	combo_sequence.append(player_move)
	enemy_ai.add_player_history(player_move)
	battle.get_node("CheatLabel").text = "🔍 外挂: %d/2" % GameState.cheat_points
	_update_battle_ui(battle)
	
	if battle_enemy_hp <= 0:
		battle.get_node("ResultLabel").text = "🎉 战斗胜利! (外挂)"
		GameState.player_gold += 10 + (GameState.current_floor + 1) * 2
		GameState.on_battle_won()
		GameState.unequip_all_after_battle()
		
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
	
	# 设置下一层可访问（往上走）
	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = true
	
	_show_map()

func _show_victory():
	_change_state(State.VICTORY)
	var label = Label.new()
	label.text = "🎉 通关胜利!"
	label.add_theme_font_size_override("font_size", 56)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	_add_ui(label)
	
	await get_tree().create_timer(3.0).timeout
	_show_main_menu()

func _show_game_over(win: bool):
	_change_state(State.GAME_OVER)
	var label = Label.new()
	label.text = "胜利!" if win else "失败!"
	label.add_theme_font_size_override("font_size", 56)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	_add_ui(label)
	
	await get_tree().create_timer(2.0).timeout
	_show_main_menu()

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

func _get_node_type_by_difficulty(floor_num: int, difficulty: int) -> int:
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
