extends Node

# 游戏状态
var player_hp: int = 6
var player_max_hp: int = 6
var player_attack: int = 2
var player_shield: int = 0
var player_gold: int = 0
var player_class: int = 0

var current_floor: int = 0
var max_floors: int = 16

var cheat_points: int = 0
var shop_discount: float = 1.0  # 商店折扣（1.0=原价，0.7=7折）

var map_data: Array = []

# ===== 背包系统 =====
var inventory: Array[Dictionary] = []  # 背包中的物品
var equipped_items: Array[Dictionary] = []  # 已装备的物品
var item_battle_wins: int = 0  # 战斗胜利计数（妖刀用）
var precision_battle_count: int = 0  # 精确辅助系统战斗计数

# 装备定义
const ITEMS: Dictionary = {
	# ===== 攻击类 =====
	"blood_tyrant": {
		"id": "blood_tyrant",
		"name": "鲜血暴君",
		"cost": 10,
		"rarity": "blue",
		"type": "attack",
		"description": "吸取造成伤害10%的血量"
	},
	"long_sword": {
		"id": "long_sword", 
		"name": "长剑",
		"cost": 5,
		"rarity": "white",
		"type": "attack",
		"description": "攻击+2"
	},
	"demon_blade": {
		"id": "demon_blade",
		"name": "妖刀",
		"cost": 20,
		"rarity": "red",
		"type": "attack", 
		"description": "每通过一场战斗攻击+1"
	},
	"bounty_blade": {
		"id": "bounty_blade",
		"name": "赏金宽刃",
		"cost": 20,
		"rarity": "red",
		"type": "attack",
		"description": "每10金币攻击+2"
	},
	"regicide": {
		"id": "regicide",
		"name": "弑君者",
		"cost": 5,
		"rarity": "white",
		"type": "attack",
		"description": "暴击率+20%"
	},
	
	# ===== 防御类 =====
	"wooden_shield": {
		"id": "wooden_shield",
		"name": "木盾",
		"cost": 5,
		"rarity": "white", 
		"type": "defense",
		"description": "获得护甲+5"
	},
	"life_crystal": {
		"id": "life_crystal",
		"name": "生命水晶",
		"cost": 10,
		"rarity": "blue",
		"type": "defense",
		"description": "最大生命值+6"
	},
	"heart_mirror": {
		"id": "heart_mirror",
		"name": "护心镜",
		"cost": 10,
		"rarity": "blue",
		"type": "defense",
		"description": "敌人对护甲的伤害反弹给自己"
	},
	"vampire_cross": {
		"id": "vampire_cross",
		"name": "吸血鬼十字架",
		"cost": 20,
		"rarity": "red",
		"type": "defense",
		"description": "战斗生命恢复效果翻倍"
	},
	
	# ===== 特殊类 =====
	"precision_guidance": {
		"id": "precision_guidance",
		"name": "精确制导系统",
		"cost": 5,
		"rarity": "white",
		"type": "special",
		"description": "生命值为1时，攻击+50%"
	},
	"precision_auxiliary": {
		"id": "precision_auxiliary",
		"name": "精确辅助系统",
		"cost": 20,
		"rarity": "red",
		"type": "special",
		"description": "生命转护甲，每场战斗生命-1护甲+1"
	},
	"precision_calculation": {
		"id": "precision_calculation",
		"name": "精确计算系统",
		"cost": 10,
		"rarity": "blue",
		"type": "special",
		"description": "生命为1时，暴击率+30%"
	},
	"ai_system": {
		"id": "ai_system",
		"name": "AI系统",
		"cost": 5,
		"rarity": "white",
		"type": "special",
		"description": "精确系统收集完且攻击为1时，效果+50%"
	},
	"explorer_notes": {
		"id": "explorer_notes",
		"name": "识图者的笔记",
		"cost": 5,
		"rarity": "white",
		"type": "special",
		"description": "战斗获得经验+30%"
	},
	"greedy_gloves": {
		"id": "greedy_gloves",
		"name": "贪婪手套",
		"cost": 5,
		"rarity": "white",
		"type": "special",
		"description": "金币+50%，受到伤害+50%"
	}
}

func _ready():
	print("GameState ready")

func reset_game():
	player_hp = 6
	player_max_hp = 6
	player_attack = 2
	player_shield = 0
	player_gold = 0
	player_class = 0
	current_floor = 0
	cheat_points = 0
	shop_discount = 1.0  # 重置商店折扣
	map_data.clear()
	inventory.clear()
	equipped_items.clear()
	item_battle_wins = 0
	precision_battle_count = 0

# ===== 背包系统 =====

func add_to_inventory(item_id: String):
	var item = ITEMS.get(item_id)
	if not item:
		return false
	
	# 检查是否已存在（某些装备可能唯一）
	if item_id in ["ai_system"] and has_in_inventory(item_id):
		return false
	
	inventory.append(item.duplicate())
	print("Added to inventory: ", item.name)
	return true

func remove_from_inventory(index: int):
	if index < 0 or index >= inventory.size():
		return {}
	
	var item = inventory[index]
	inventory.remove_at(index)
	print("Removed from inventory: ", item.name)
	return item

func get_inventory():
	return inventory

func has_in_inventory(item_id: String):
	for item in inventory:
		if item.id == item_id:
			return true
	return false

func sell_item(index: int):
	if index < 0 or index >= inventory.size():
		return false
	
	var item = inventory[index]
	var sell_price = item.cost
	
	player_gold += sell_price
	inventory.remove_at(index)
	
	print("Sold item: ", item.name, " for ", sell_price, " gold")
	EventBus.player_gold_changed.emit(player_gold)
	return true

# ===== 装备系统 =====

func auto_equip_from_inventory():
	_unequip_all()
	
	# 处理精确辅助系统：先转化生命为护甲
	if has_in_inventory("precision_auxiliary"):
		_convert_hp_to_shield()
	
	# 装备所有物品
	for item in inventory:
		equipped_items.append(item.duplicate())
		print("Auto-equipped: ", item.name)
	
	print("Auto-equipped ", equipped_items.size(), " items from inventory")

func _convert_hp_to_shield():
	"""精确辅助系统：将生命转化为护甲"""
	var convert_amount = player_hp - 1  # 保留1点生命
	if convert_amount > 0:
		player_shield += convert_amount
		player_hp = 1
		print("Precision Auxiliary: Converted ", convert_amount, " HP to shield")

func _unequip_all():
	equipped_items.clear()

func unequip_all_after_battle():
	# 精确辅助系统战后效果
	if has_item("precision_auxiliary"):
		if player_hp > 1:
			player_hp -= 1
			player_shield += 1
			print("Precision Auxiliary: Post-battle HP-1, Shield+1")
	
	_unequip_all()
	print("Unequipped all items after battle")

# ===== 效果查询 =====

func has_item(item_id: String):
	for item in equipped_items:
		if item.id == item_id:
			return true
	return false

# 基础攻击
func get_base_attack():
	var total = player_attack
	
	# 长剑
	if has_item("long_sword"):
		total += 2
	
	# 妖刀
	if has_item("demon_blade"):
		total += item_battle_wins
	
	# 赏金宽刃
	if has_item("bounty_blade"):
		total += (player_gold / 10) * 2
	
	return total

# 赏金宽刃加成（单独计算用于显示）
func get_bounty_bonus():
	if has_item("bounty_blade"):
		return (player_gold / 10) * 2
	return 0

# 总攻击（含特殊效果）
func get_total_attack():
	var total = get_base_attack()
	
	# 精确制导系统：生命为1时攻击+50%
	if has_item("precision_guidance") and player_hp == 1:
		var bonus = 1.5 if _is_ai_system_active() else 1.5
		total = int(total * bonus)
		print("Precision Guidance active: attack x", bonus)
	
	return total

# 暴击率
func get_crit_chance():
	var chance = 0.0
	
	# 弑君者
	if has_item("regicide"):
		chance += 0.2
	
	# 精确计算系统：生命为1时暴击+30%
	if has_item("precision_calculation") and player_hp == 1:
		chance += 0.3 * (1.5 if _is_ai_system_active() else 1.0)
		print("Precision Calculation active")
	
	return chance

# 生命偷取
func get_life_steal(damage: int):
	if has_item("blood_tyrant"):
		return maxi(1, int(damage * 0.1))
	return 0

# 护盾
func get_shield():
	var shield = player_shield
	
	# 木盾
	if has_item("wooden_shield"):
		shield += 5
	
	return shield

# 护盾反射
func has_shield_reflect():
	return has_item("heart_mirror")

# 治疗翻倍
func has_heal_double():
	return has_item("vampire_cross")

# 贪婪手套受伤加成
func has_greedy_gloves():
	return has_item("greedy_gloves")

# 金币加成
func get_gold_bonus():
	if has_item("greedy_gloves"):
		return 0.5
	return 0.0

# 受到伤害加成（贪婪手套）
func get_damage_taken_multiplier():
	if has_item("greedy_gloves"):
		return 1.5
	return 1.0

# AI系统是否激活
func _is_ai_system_active():
	if not has_item("ai_system"):
		return false
	
	# 检查是否收集了所有精确系统
	var has_guidance = has_item("precision_guidance")
	var has_auxiliary = has_item("precision_auxiliary")
	var has_calculation = has_item("precision_calculation")
	
	# 检查攻击是否为1
	var base_atk = player_attack
	if has_item("long_sword"):
		base_atk -= 2
	if has_item("demon_blade"):
		base_atk -= item_battle_wins
	if has_item("bounty_blade"):
		base_atk -= (player_gold / 10) * 2
	
	if has_guidance and has_auxiliary and has_calculation and base_atk <= 1:
		print("AI System active! Precision effects +50%")
		return true
	
	return false

# 记录战斗胜利
func on_battle_won():
	item_battle_wins += 1
	precision_battle_count += 1
