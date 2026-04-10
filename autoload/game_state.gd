extends Node

const SAVE_FILE_PATH := "user://savegame.json"
const SAVE_VERSION: int = 2

# 游戏状态
var player_hp: int = 6
var player_max_hp: int = 6
var player_attack: int = 2
var player_shield: int = 0
var player_gold: int = 0
var player_class: int = 0

var current_floor: int = 0
var max_floors: int = 19

var cheat_points: int = 0
var shop_discount: float = 1.0  # 商店折扣（1.0=原价，0.7=7折）

var map_data: Array[Array] = []  # [floor_idx][node_idx] -> Dictionary

# ===== 装备系统 =====
var equipment_slot: Array[Dictionary] = []  # 装备栏（6格，效果生效）
var backpack: Array[Dictionary] = []  # 背包（6格，仅存储，可强化）
const BASE_EQUIPMENT_SLOT_MAX: int = 2
const MAX_EQUIPMENT_SLOT_MAX: int = 6
const BASE_BACKPACK_MAX: int = 6
const MAX_BACKPACK_MAX: int = 12
var item_battle_wins: int = 0  # 战斗胜利计数（妖刀用）
var precision_battle_count: int = 0  # 精确辅助系统战斗计数
var current_shop_items: Array[String] = []  # 当前商店商品，用于断点继续

# ===== 连招记录 =====
var combo_moves: Array[int] = []  # 记录玩家最近的动作序列

# ===== 连击能量系统 =====
var combo_energy: int = 0  # 当前连击能量
var max_combo_energy: int = 10  # 上限10点
var unlocked_combos: Array[String] = []  # 已解锁的连招列表

# 初始解锁的连招
const DEFAULT_UNLOCKED_COMBOS: Array[String] = ["pierce", "whirlwind", "crush"]
const ADVANCED_COMBO_UNLOCK_FLOOR: int = 5
const ULTIMATE_COMBO_UNLOCK_WINS: int = 1

var highest_floor_reached: int = 0
var total_wins: int = 0
var runs_played: int = 0
var run_active: bool = false
var checkpoint_scene: String = "map"
var class_first_clears: Dictionary = {}
var discovered_items: Array[String] = []
var discovered_events: Array[String] = []
var unlocked_achievements: Array[String] = []
var memory_cores: int = 0
var meta_upgrades: Dictionary = {}

# ===== 局内升级系统 =====
const MAX_PLAYER_LEVEL: int = 10
const MAX_LEVEL_HP_BONUS: int = 10
const MAX_LEVEL_ATK_BONUS: int = 5
const MAX_BONUS_EQUIPMENT_SLOTS: int = 4
const MAX_BONUS_BACKPACK_SLOTS: int = 2

var player_level: int = 1
var player_exp: int = 0
var unspent_attribute_points: int = 0
var bonus_equipment_slots: int = 0
var bonus_backpack_slots: int = 0
var bonus_hp_from_level: int = 0
var bonus_atk_from_level: int = 0
var draw_protection_available: bool = false
var draw_protection_armed: bool = false

func _ready() -> void:
	print("GameState ready")
	# 初始化时解锁默认连招
	unlocked_combos = DEFAULT_UNLOCKED_COMBOS.duplicate()
	load_progress()
	_evaluate_achievements()

# ===== 材料系统 =====
var materials: int = 0  # 当前材料数量
var MATERIAL_PRICE: int = 5  # 商店购买材料的价格

func add_materials(amount: int) -> void:
	"""添加材料并发出信号"""
	materials += amount
	EventBus.materials_changed.emit(materials)
	print("[Materials] 获得 +%d，当前: %d" % [amount, materials])

func spend_materials(amount: int) -> bool:
	"""花费材料，返回是否成功"""
	if materials >= amount:
		materials -= amount
		EventBus.materials_changed.emit(materials)
		return true
	return false

# ===== 连击能量系统 =====
func add_combo_energy(amount: int) -> void:
	"""添加连击能量"""
	combo_energy = mini(combo_energy + amount, max_combo_energy)
	EventBus.combo_energy_changed.emit(combo_energy, max_combo_energy)
	print("[Combo Energy] +%d，当前: %d/%d" % [amount, combo_energy, max_combo_energy])

func consume_combo_energy(amount: int) -> bool:
	"""消耗连击能量，返回是否成功"""
	if combo_energy >= amount:
		combo_energy -= amount
		EventBus.combo_energy_changed.emit(combo_energy, max_combo_energy)
		print("[Combo Energy] -%d，剩余: %d/%d" % [amount, combo_energy, max_combo_energy])
		return true
	return false

func start_turn_energy() -> void:
	"""每回合开始时增加能量"""
	add_combo_energy(1)

func win_energy() -> void:
	"""猜拳获胜时增加能量"""
	add_combo_energy(1)

# 获取当前能量
func get_combo_energy() -> int:
	return combo_energy

# 获取能量上限
func get_max_combo_energy() -> int:
	return max_combo_energy

# 检查是否有足够的能量
func has_enough_combo_energy(needed: int) -> bool:
	return combo_energy >= needed

# 重置连击能量（战斗开始时）
func reset_combo_energy():
	combo_energy = 0
	EventBus.combo_energy_changed.emit(combo_energy, max_combo_energy)

func change_gold(amount: int) -> void:
	"""修改金币并发出信号"""
	player_gold += amount
	EventBus.player_gold_changed.emit(player_gold)

func get_current_equipment_slot_limit() -> int:
	return mini(BASE_EQUIPMENT_SLOT_MAX + get_meta_upgrade_count("equipment_slot") + bonus_equipment_slots, MAX_EQUIPMENT_SLOT_MAX)

func get_current_backpack_limit() -> int:
	return mini(BASE_BACKPACK_MAX + get_meta_upgrade_count("backpack_expand") * 4 + bonus_backpack_slots, MAX_BACKPACK_MAX)

func get_level_exp_requirement(level: int) -> int:
	if level <= 1:
		return 1
	return level

func get_level_progress_text() -> String:
	if player_level >= MAX_PLAYER_LEVEL:
		return "Lv.%d MAX" % player_level
	return "Lv.%d EXP %d/%d" % [player_level, player_exp, get_level_exp_requirement(player_level)]

func get_reward_chapter(floor_index: int) -> int:
	var boss_floor = maxi(max_floors - 1, 0)
	var non_boss_floors = maxi(boss_floor, 1)
	var chapter_size = maxi(int(ceil(float(non_boss_floors) / 3.0)), 1)
	var clamped_floor = clamp(floor_index, 0, maxi(boss_floor - 1, 0))
	return mini(3, int(clamped_floor / chapter_size) + 1)

func get_battle_exp_reward(battle_type: String, floor_index: int = current_floor) -> int:
	var chapter = get_reward_chapter(floor_index)
	match battle_type:
		"boss":
			return 15
		"elite":
			return [3, 6, 12][chapter - 1]
		_:
			return [1, 2, 4][chapter - 1]

func get_level_reward_summary(level: int) -> Array[String]:
	match level:
		2:
			return ["+1 装备栏"]
		3:
			return ["+2 属性点"]
		4:
			return ["+1 背包格"]
		5:
			return ["+1 装备栏"]
		6:
			return ["+1 属性点"]
		7:
			return ["+1 背包格"]
		8:
			return ["+1 装备栏"]
		9:
			return ["+1 属性点"]
		10:
			return ["+1 装备栏", "+1 属性点"]
		_:
			return []

func apply_level_reward(level: int) -> Array[String]:
	var rewards = get_level_reward_summary(level)
	match level:
		2, 5, 8, 10:
			bonus_equipment_slots = mini(bonus_equipment_slots + 1, MAX_BONUS_EQUIPMENT_SLOTS)
		4, 7:
			bonus_backpack_slots = mini(bonus_backpack_slots + 1, MAX_BONUS_BACKPACK_SLOTS)
		3:
			unspent_attribute_points += 2
		6, 9, 10:
			unspent_attribute_points += 1
	return rewards

func add_exp(amount: int) -> Array[int]:
	var leveled_up: Array[int] = []
	if amount <= 0 or player_level >= MAX_PLAYER_LEVEL:
		return leveled_up

	player_exp += amount
	while player_level < MAX_PLAYER_LEVEL:
		var need = get_level_exp_requirement(player_level)
		if player_exp < need:
			break
		player_exp -= need
		player_level += 1
		apply_level_reward(player_level)
		leveled_up.append(player_level)

	if player_level >= MAX_PLAYER_LEVEL:
		player_level = MAX_PLAYER_LEVEL
		player_exp = 0

	return leveled_up

func can_add_level_hp() -> bool:
	return bonus_hp_from_level < MAX_LEVEL_HP_BONUS

func can_add_level_atk() -> bool:
	return bonus_atk_from_level < MAX_LEVEL_ATK_BONUS

func allocate_level_stat(stat_type: String) -> bool:
	if unspent_attribute_points <= 0:
		return false

	match stat_type:
		"hp":
			if not can_add_level_hp():
				return false
			bonus_hp_from_level += 2
			player_max_hp += 2
			player_hp += 2
		"atk":
			if not can_add_level_atk():
				return false
			bonus_atk_from_level += 1
			player_attack += 1
		_:
			return false

	unspent_attribute_points -= 1
	return true

# ===== 连招强化系统 =====
# 连招强化存储: {combo_id: {damage_boost: int, energy_reduction: int, has_burn: bool, has_slow: bool}}
var combo_upgrades: Dictionary = {}

func get_combo_damage_multiplier(combo_id: String) -> float:
	# 读取强化等级，映射为伤害倍率
	# Lv1: +20% (×1.20), Lv2: +30% (×1.30), Lv3: +50% (×1.50)
	var level = get_combo_upgrade_level(combo_id)
	if level == 0:
		return 1.0
	var effects = [1.20, 1.30, 1.50]
	return effects[mini(level, 3) - 1]

func get_combo_energy_reduction(combo_id: String) -> int:
	if combo_upgrades.has(combo_id):
		return combo_upgrades[combo_id].get("energy_reduction", 0)
	return 0

func has_combo_effect(combo_id: String, effect: String) -> bool:
	if combo_upgrades.has(combo_id):
		return combo_upgrades[combo_id].get("has_" + effect, false)
	return false

func apply_combo_upgrade(combo_id: String, upgrade_type: String) -> Dictionary:
	"""应用连招强化，返回结果字典包含 success, cost, new_level"""
	var result = {"success": false, "cost": 0, "new_level": 0, "current_effect": ""}
	
	# 连招强化：前3级提升倍率，后2级解锁附加特效
	# 第1级：1材料 +20%
	# 第2级：2材料 +30%
	# 第3级：3材料 +50%
	# 第4级：4材料 解锁灼烧
	# 第5级：5材料 解锁减速
	var current_level = 0
	var max_level = 5
	
	if combo_upgrades.has(combo_id):
		current_level = combo_upgrades[combo_id].get("level", 0)
	
	# 检查是否已满级
	if current_level >= max_level:
		result.error = "已达满级"
		return result
	
	# 计算消耗：第1级1材料，第2级2材料，第3级3材料
	var cost = current_level + 1
	if not spend_materials(cost):
		result.error = "材料不足"
		return result
	
	# 初始化连招强化数据
	if not combo_upgrades.has(combo_id):
		combo_upgrades[combo_id] = {"level": 0, "has_burn": false, "has_slow": false}
	
	# 应用强化
	combo_upgrades[combo_id]["level"] += 1
	result.new_level = combo_upgrades[combo_id]["level"]
	
	match result.new_level:
		1, 2, 3:
			var effect_bonus = [20, 30, 50][result.new_level - 1]
			result.current_effect = "+%d%%效果" % effect_bonus
		4:
			combo_upgrades[combo_id]["has_burn"] = true
			result.current_effect = "解锁灼烧"
		5:
			combo_upgrades[combo_id]["has_slow"] = true
			result.current_effect = "解锁减速"
	
	result.success = true
	result.cost = cost
	return result

func get_combo_upgrade_level(combo_id: String) -> int:
	"""获取连招强化等级"""
	if combo_upgrades.has(combo_id):
		return combo_upgrades[combo_id].get("level", 0)
	return 0

# ===== 装备强化系统 =====
# 装备强化存储: {item_id: {level: int, quality: int, special_unlocked: bool}}
var equipment_upgrades: Dictionary = {}

func get_equipment_level_bonus(item_id: String) -> float:
	if equipment_upgrades.has(item_id):
		var level = equipment_upgrades[item_id].get("level", 0)
		return 1.0 + (level * 0.30)  # 每级+30%
	return 1.0

func get_equipment_quality_multiplier(item_id: String) -> float:
	match get_equipment_quality(item_id):
		1: return 1.10
		2: return 1.25
		_: return 1.0

func get_equipment_special_multiplier(item_id: String) -> float:
	return 1.15 if has_equipment_special(item_id) else 1.0

func get_equipment_effect_multiplier(item_id: String) -> float:
	return get_equipment_level_bonus(item_id) * get_equipment_quality_multiplier(item_id) * get_equipment_special_multiplier(item_id)

func get_equipment_scaled_int(item_id: String, base_value: int) -> int:
	if base_value <= 0:
		return 0
	return maxi(1, int(round(float(base_value) * get_equipment_effect_multiplier(item_id))))

func get_life_crystal_hp_bonus() -> int:
	return get_equipment_scaled_int("life_crystal", 6)

func get_wooden_shield_bonus() -> int:
	return get_equipment_scaled_int("wooden_shield", 5)

func get_total_equipment_level_bonus() -> float:
	"""兼容旧调用：装备强化不再提供全局伤害倍率。"""
	return 1.0

# ===== 局外升级系统 =====

func get_meta_upgrade_definitions() -> Array[Dictionary]:
	return [
		{"id": "basic_combo_slot", "name": "基础连招槽位", "cost": 1, "max": 1, "desc": "开局连招槽从1个提升到2个"},
		{"id": "base_hp", "name": "基础生命提升", "cost": 1, "max": 1, "desc": "每局开始最大生命+2"},
		{"id": "base_atk", "name": "基础攻击提升", "cost": 1, "max": 1, "desc": "每局开始攻击+1"},
		{"id": "backpack_expand", "name": "背包扩展", "cost": 1, "max": 1, "desc": "背包格子+4"},
		{"id": "advanced_combo", "name": "高级连招解锁", "cost": 2, "max": 1, "desc": "解锁更强连招和控制连招"},
		{"id": "combo_cooldown", "name": "连招冷却缩减", "cost": 2, "max": 1, "desc": "所有连招冷却-1回合，最低1回合"},
		{"id": "equipment_slot", "name": "装备槽位解锁", "cost": 2, "max": 1, "desc": "装备栏+1"},
		{"id": "ultimate_combo", "name": "终极连招解锁", "cost": 4, "max": 1, "desc": "解锁强效终极连招"},
		{"id": "passive_shield", "name": "永久被动天赋", "cost": 4, "max": 1, "desc": "每局开始获得1点护甲"},
		{"id": "cheat_charge", "name": "外挂充能+1", "cost": 4, "max": 1, "desc": "每局外挂可用次数+1"},
		{"id": "draw_protection", "name": "平局保护", "cost": 8, "max": 1, "desc": "每局首次平局后，免疫下一次受到的伤害"},
		{"id": "all_stats", "name": "全属性+1", "cost": 8, "max": 1, "desc": "每局开始生命+2、攻击+1、护甲+1"},
		{"id": "relic_purchase", "name": "信物购买权", "cost": 8, "max": 1, "desc": "解锁免除特定Boss信物要求的购买权"},
		{"id": "new_character", "name": "新角色解锁", "cost": 16, "max": 1, "desc": "解锁后续新角色入口"},
	]

func get_meta_upgrade_count(upgrade_id: String) -> int:
	return int(meta_upgrades.get(upgrade_id, 0))

func has_meta_upgrade(upgrade_id: String) -> bool:
	return get_meta_upgrade_count(upgrade_id) > 0

func get_meta_upgrade_definition(upgrade_id: String) -> Dictionary:
	for definition in get_meta_upgrade_definitions():
		if definition.get("id", "") == upgrade_id:
			return definition
	return {}

func can_purchase_meta_upgrade(upgrade_id: String) -> bool:
	var definition = get_meta_upgrade_definition(upgrade_id)
	if definition.is_empty():
		return false
	var current_count = get_meta_upgrade_count(upgrade_id)
	if current_count >= int(definition.get("max", 1)):
		return false
	return memory_cores >= int(definition.get("cost", 0))

func purchase_meta_upgrade(upgrade_id: String) -> Dictionary:
	var result = {"success": false, "error": "", "cost": 0}
	var definition = get_meta_upgrade_definition(upgrade_id)
	if definition.is_empty():
		result.error = "未知升级"
		return result
	if not can_purchase_meta_upgrade(upgrade_id):
		result.error = "存储器不足或已解锁"
		return result
	var cost = int(definition.get("cost", 0))
	memory_cores -= cost
	meta_upgrades[upgrade_id] = get_meta_upgrade_count(upgrade_id) + 1
	result.success = true
	result.cost = cost
	save_progress()
	return result

func award_memory_cores(amount: int, reason: String = "") -> int:
	var gained = maxi(amount, 0)
	if gained <= 0:
		return 0
	memory_cores += gained
	print("[Meta] 获得存储器 +%d (%s)，当前: %d" % [gained, reason, memory_cores])
	save_progress()
	return gained

func apply_meta_start_bonuses() -> void:
	var hp_bonus = get_meta_upgrade_count("base_hp") * 2 + get_meta_upgrade_count("all_stats") * 2
	var atk_bonus = get_meta_upgrade_count("base_atk") + get_meta_upgrade_count("all_stats")
	var shield_bonus = get_meta_upgrade_count("passive_shield") + get_meta_upgrade_count("all_stats")
	player_max_hp += hp_bonus
	player_hp = player_max_hp
	player_attack += atk_bonus
	player_shield += shield_bonus
	draw_protection_available = has_meta_upgrade("draw_protection")
	draw_protection_armed = false

func arm_draw_protection() -> bool:
	if not draw_protection_available:
		return false
	draw_protection_available = false
	draw_protection_armed = true
	return true

func consume_draw_protection() -> bool:
	if not draw_protection_armed:
		return false
	draw_protection_armed = false
	return true

func get_draw_protection_status_text() -> String:
	if not has_meta_upgrade("draw_protection"):
		return ""
	if draw_protection_armed:
		return "🛡 平局保护：已充能，下次受击免疫"
	if draw_protection_available:
		return "🛡 平局保护：等待首次平局"
	return "🛡 平局保护：本局已消耗"

func get_equipment_quality(item_id: String) -> int:
	if equipment_upgrades.has(item_id):
		return equipment_upgrades[item_id].get("quality", 0)
	return 0

func has_equipment_special(item_id: String) -> bool:
	if equipment_upgrades.has(item_id):
		return equipment_upgrades[item_id].get("special_unlocked", false)
	return false

func apply_equipment_upgrade(item_id: String, upgrade_type: String) -> Dictionary:
	"""应用装备强化，返回结果字典包含 success, cost, new_level"""
	var result = {"success": false, "cost": 0, "new_level": 0, "current_effect": ""}
	var old_hp_bonus = get_life_crystal_hp_bonus() if item_id == "life_crystal" and has_item(item_id) else 0
	var old_shield_bonus = get_wooden_shield_bonus() if item_id == "wooden_shield" and has_item(item_id) else 0
	
	# 计算当前等级和最大可升级次数
	var current_level = 0
	var max_upgrades = 0  # 剩余可升级次数
	var current_quality = 0
	
	match upgrade_type:
		"level":
			if equipment_upgrades.has(item_id):
				current_level = equipment_upgrades[item_id].get("level", 0)
			max_upgrades = 10 - current_level  # 等级最高10级
		"quality":
			current_quality = equipment_upgrades[item_id].get("quality", 0) if equipment_upgrades.has(item_id) else 0
			# 白色(0)可升级2次→蓝(1)→红(2)，蓝色(1)可升级1次→红(2)，红色(2)不可升级
			match current_quality:
				0: max_upgrades = 2  # 白→蓝→红
				1: max_upgrades = 1  # 蓝→红
				2: max_upgrades = 0  # 红为最高，不能再升品质
		"special":
			# 特效只有1级
			if equipment_upgrades.has(item_id) and equipment_upgrades[item_id].get("special_unlocked", false):
				result.error = "已达满级"
				return result
			max_upgrades = 1
	
	# 检查是否还有升级次数
	if max_upgrades <= 0:
		result.error = "已达满级"
		return result
	
	# 计算消耗：基础1 + 已升级次数（递增）
	var upgrades_done = 0
	match upgrade_type:
		"level": upgrades_done = current_level
		"quality": upgrades_done = current_quality
		"special": upgrades_done = 1  # 特效只有一次
	
	var cost = 1 + upgrades_done
	if not spend_materials(cost):
		result.error = "材料不足"
		return result
	
	# 初始化装备强化数据
	if not equipment_upgrades.has(item_id):
		equipment_upgrades[item_id] = {"level": 0, "quality": 0, "special_unlocked": false}
	
	# 应用强化
	match upgrade_type:
		"level":
			equipment_upgrades[item_id]["level"] += 1
			result.new_level = equipment_upgrades[item_id]["level"]
			result.current_effect = "自身效果等级+%d（+%d%%）" % [result.new_level, result.new_level * 30]
		"quality":
			equipment_upgrades[item_id]["quality"] += 1
			result.new_level = equipment_upgrades[item_id]["quality"]
			var quality_names = ["白", "蓝", "红"]
			result.current_effect = "品质升至%s" % quality_names[result.new_level]
		"special":
			equipment_upgrades[item_id]["special_unlocked"] = true
			result.new_level = 1
			result.current_effect = "解锁特效"
	
	result.success = true
	result.cost = cost
	if old_hp_bonus > 0:
		var hp_delta = get_life_crystal_hp_bonus() - old_hp_bonus
		player_max_hp += hp_delta
		player_hp += hp_delta
	if old_shield_bonus > 0:
		player_shield = maxi(player_shield + get_wooden_shield_bonus() - old_shield_bonus, 0)
	return result

# ===== 作弊点数系统 =====
func get_max_cheat_points() -> int:
	var base = 3 if player_class == 1 else 2
	return base + get_meta_upgrade_count("cheat_charge")

func get_cheat_label_text(prefix: String = "🔍") -> String:
	return "%s %d/%d" % [prefix, cheat_points, get_max_cheat_points()]

func add_cheat_point():
	cheat_points = mini(cheat_points + 1, get_max_cheat_points())

func consume_cheat_point() -> bool:
	if cheat_points > 0:
		cheat_points -= 1
		return true
	return false

# ===== 连招系统 =====
var equipped_combos: Array[String] = []  # 已装备的连招ID列表
var max_combo_slots: int = 2  # 最大连招槽位（可升级）
var combo_cooldowns: Dictionary = {}  # 连招冷却状态 {combo_id: remaining_cooldown}
var combo_buffs: Dictionary = {}  # 连招增益状态
var exclusive_combos: Array = []  # 当前角色的专属连招

# 初始化角色（包含专属连招）
func init_player_class(class_id: int):
	player_class = class_id
	var player_class_script = load("res://resources/player_class_data.gd")
	var combo_script = load("res://resources/combo_data.gd")
	
	var class_data = player_class_script.get_class_data(class_id)
	
	# 设置基础属性
	player_max_hp = class_data["hp"]
	player_hp = player_max_hp
	player_attack = class_data["atk"]
	
	# 加载专属连招
	exclusive_combos = player_class_script.get_class_combos(class_id)
	print("[Class] 选择职业: ", class_data["name"], ", 专属连招数: ", exclusive_combos.size())
	
	# 显示专属连招信息
	for combo in exclusive_combos:
		print("  - ", combo.display_name, ": ", combo_script.sequence_to_string(combo.sequence))

# 获取专属连招列表
func get_exclusive_combos() -> Array:
	return exclusive_combos

# 检查是否有某个专属连招
func has_exclusive_combo(combo_id: String) -> bool:
	for combo in exclusive_combos:
		if combo.combo_id == combo_id:
			return true
	return false

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


func reset_game():
	player_hp = 6
	player_max_hp = 6
	player_attack = 2
	player_shield = 0
	player_gold = 0
	player_class = 0
	current_floor = 0
	cheat_points = 0
	shop_discount = 1.0
	materials = 0  # 重置材料
	
	# 重置连击能量系统
	combo_energy = 0
	unlocked_combos = DEFAULT_UNLOCKED_COMBOS.duplicate()
	combo_upgrades.clear()
	equipment_upgrades.clear()
	
	map_data.clear()
	equipment_slot.clear()
	backpack.clear()
	current_shop_items.clear()
	item_battle_wins = 0
	precision_battle_count = 0
	player_level = 1
	player_exp = 0
	unspent_attribute_points = 0
	bonus_equipment_slots = 0
	bonus_backpack_slots = 0
	bonus_hp_from_level = 0
	bonus_atk_from_level = 0
	draw_protection_available = false
	draw_protection_armed = false
	# 重置连招系统
	equipped_combos.clear()
	max_combo_slots = 1 + get_meta_upgrade_count("basic_combo_slot")
	combo_cooldowns.clear()
	combo_buffs.clear()
	combo_moves.clear()
	exclusive_combos.clear()  # 清空专属连招
	has_resurrection = false
	resurrection_used = false
	resurrection_hp = 5
	gold_bonus_percent = 0
	armor_regen = false
	critical_damage_bonus = 0
	last_rest_income_floor = -1
	run_active = true
	checkpoint_scene = "map"

# ===== 背包系统 =====

func add_to_backpack(item_id: String):
	"""添加物品到背包"""
	var item = ITEMS.get(item_id)
	if not item:
		return false
	
	# 检查背包是否已满
	if backpack.size() >= get_current_backpack_limit():
		print("Backpack full! Max slots: ", get_current_backpack_limit())
		return false
	
	# 检查是否已存在（某些装备可能唯一）
	if item_id in ["ai_system"] and has_in_backpack(item_id):
		return false
	
	backpack.append(item.duplicate())
	record_item_discovery(item_id)
	print("Added to backpack: ", item.name)
	return true

# ===== 装备效果系统 =====

func _apply_item_effect(item_id: String) -> void:
	"""装备时生效的效果"""
	match item_id:
		"life_crystal":
			var hp_bonus = get_life_crystal_hp_bonus()
			player_max_hp += hp_bonus
			player_hp += hp_bonus  # 同时恢复血量
			print("[Equip] 生命水晶: 最大生命+", hp_bonus, "，恢复", hp_bonus, "生命")
		"wooden_shield":
			var shield_bonus = get_wooden_shield_bonus()
			player_shield += shield_bonus
			print("[Equip] 木盾: 获得", shield_bonus, "护甲")

func _remove_item_effect(item_id: String) -> void:
	"""卸下时移除的效果"""
	match item_id:
		"life_crystal":
			var hp_bonus = get_life_crystal_hp_bonus()
			player_max_hp = maxi(player_max_hp - hp_bonus, 1)
			player_hp = mini(player_hp, player_max_hp)
			print("[Equip] 卸下生命水晶: 最大生命-", hp_bonus)
		"wooden_shield":
			var shield_bonus = get_wooden_shield_bonus()
			player_shield = maxi(player_shield - shield_bonus, 0)
			print("[Equip] 卸下木盾: 移除", shield_bonus, "护甲")

func add_to_equipment_slot(item_id: String):
	"""直接添加物品到装备栏"""
	var item = ITEMS.get(item_id)
	if not item:
		return false
	
	# 检查装备栏是否已满
	if equipment_slot.size() >= get_current_equipment_slot_limit():
		print("Equipment slot full! Max slots: ", get_current_equipment_slot_limit())
		return false
	
	# 检查是否已存在
	if item_id in ["ai_system"] and has_item(item_id):
		return false
	
	equipment_slot.append(item.duplicate())
	_apply_item_effect(item_id)
	record_item_discovery(item_id)
	print("Added to equipment slot: ", item.name)
	return true

func remove_from_backpack(index: int):
	"""从背包移除物品"""
	if index < 0 or index >= backpack.size():
		return {}
	
	var item = backpack[index]
	backpack.remove_at(index)
	print("Removed from backpack: ", item.name)
	return item

func remove_from_equipment_slot(index: int):
	"""从装备栏移除物品"""
	if index < 0 or index >= equipment_slot.size():
		return {}
	
	var item = equipment_slot[index]
	equipment_slot.remove_at(index)
	_remove_item_effect(item.id)
	print("Removed from equipment slot: ", item.name)
	return item

func get_backpack():
	return backpack

func get_equipment_slot():
	return equipment_slot

func has_in_backpack(item_id: String):
	"""检查物品是否在背包中"""
	for item in backpack:
		if item.id == item_id:
			return true
	return false

func has_in_equipment_slot(item_id: String):
	"""检查物品是否在装备栏中"""
	for item in equipment_slot:
		if item.id == item_id:
			return true
	return false

func sell_item(index: int, from_backpack: bool = true):
	"""出售物品（默认从背包出售）"""
	var item_array = backpack if from_backpack else equipment_slot
	if index < 0 or index >= item_array.size():
		return false
	
	var item = item_array[index]
	var sell_price = item.cost
	
	player_gold += sell_price
	item_array.remove_at(index)
	if not from_backpack:
		_remove_item_effect(item.id)
	
	print("Sold item: ", item.name, " for ", sell_price, " gold")
	EventBus.player_gold_changed.emit(player_gold)
	return true

# ===== 装备栏系统 =====

func equip_from_backpack(backpack_index: int) -> bool:
	"""从背包移动物品到装备栏"""
	if backpack_index < 0 or backpack_index >= backpack.size():
		return false
	
	# 检查装备栏是否已满
	if equipment_slot.size() >= get_current_equipment_slot_limit():
		print("Equipment slot full! Cannot equip.")
		return false
	
	var item = backpack[backpack_index]
	
	# 某些装备可能是唯一的，不能重复装备
	if item.id in ["ai_system"] and has_item(item.id):
		return false
	
	equipment_slot.append(item.duplicate())
	backpack.remove_at(backpack_index)
	_apply_item_effect(item.id)
	record_item_discovery(item.id)
	print("Equipped: ", item.name)
	return true

func unequip_to_backpack(equipment_index: int) -> bool:
	"""从装备栏卸下物品到背包"""
	if equipment_index < 0 or equipment_index >= equipment_slot.size():
		return false
	
	# 检查背包是否已满
	if backpack.size() >= get_current_backpack_limit():
		print("Backpack full! Cannot unequip.")
		return false
	
	var item = equipment_slot[equipment_index]
	backpack.append(item.duplicate())
	equipment_slot.remove_at(equipment_index)
	_remove_item_effect(item.id)
	print("Unequipped to backpack: ", item.name)
	return true

func swap_equipment(from_equipment_index: int, to_backpack_index: int) -> bool:
	"""交换装备栏和背包的物品"""
	if from_equipment_index < 0 or from_equipment_index >= equipment_slot.size():
		return false
	if to_backpack_index < 0 or to_backpack_index >= backpack.size():
		return false
	
	var equip_item = equipment_slot[from_equipment_index]
	var backpack_item = backpack[to_backpack_index]
	
	# 移除旧装备效果，应用新装备效果
	_remove_item_effect(equip_item.id)
	equipment_slot[from_equipment_index] = backpack_item.duplicate()
	backpack[to_backpack_index] = equip_item.duplicate()
	_apply_item_effect(backpack_item.id)
	print("Swapped: ", equip_item.name, " <-> ", backpack_item.name)
	return true

func swap_equipment_with_backpack(equipment_index: int, backpack_index: int) -> bool:
	"""将装备栏物品与背包物品交换（用于交换选择界面）"""
	if equipment_index < 0 or equipment_index >= equipment_slot.size():
		return false
	if backpack_index < 0 or backpack_index >= backpack.size():
		return false
	
	var equip_item = equipment_slot[equipment_index]
	var backpack_item = backpack[backpack_index]
	
	# 移除旧装备效果，应用新装备效果
	_remove_item_effect(equip_item.id)
	equipment_slot[equipment_index] = backpack_item.duplicate()
	backpack[backpack_index] = equip_item.duplicate()
	_apply_item_effect(backpack_item.id)
	
	print("[Swap] 装备交换: ", equip_item.name, " <-> ", backpack_item.name)
	return true

func unequip_all_after_battle():
	"""战斗结束后卸下所有装备（如果需要）"""
	# 精确辅助系统战后效果 - 只有在装备栏时才生效
	if has_item("precision_auxiliary"):
		if player_hp > 1:
			var shield_gain = get_equipment_scaled_int("precision_auxiliary", 1)
			player_hp -= 1
			player_shield += shield_gain
			print("Precision Auxiliary: Post-battle HP-1, Shield+", shield_gain)

	if not shield_persists_between_battles():
		player_shield = 0
	
	# 注意：不再在战斗后自动清空装备栏！
	# 装备应该持久保存，只在休息点选择"清空装备栏"时才清空
	# equipment_slot.clear()  # 已移除，装备应该持久存在

func setup_pre_battle():
	"""战斗开始前准备"""
	# 精确辅助系统：战前将生命转化为护甲
	if has_item("precision_auxiliary"):
		_convert_hp_to_shield_pre_battle()

func _convert_hp_to_shield_pre_battle():
	"""精确辅助系统：战斗开始前将生命转化为护甲"""
	var convert_amount = player_hp - 1  # 保留1点生命
	if convert_amount > 0:
		var shield_gain = int(round(float(convert_amount) * get_equipment_effect_multiplier("precision_auxiliary")))
		player_shield += shield_gain
		player_hp = 1
		print("Precision Auxiliary (pre-battle): Converted ", convert_amount, " HP to shield ", shield_gain)

# ===== 效果查询（只检查装备栏）=====

func has_item(item_id: String):
	"""检查物品是否已装备（只在装备栏检查）"""
	for item in equipment_slot:
		if item.id == item_id:
			return true
	return false

func has_item_anywhere(item_id: String):
	"""检查物品是否在装备栏或背包中"""
	return has_item(item_id) or has_in_backpack(item_id)

func get_all_items() -> Array[Dictionary]:
	"""获取所有物品（装备栏+背包）"""
	return equipment_slot + backpack

# 基础攻击
func get_base_attack():
	var total = player_attack
	
	# 长剑
	if has_item("long_sword"):
		total += get_equipment_scaled_int("long_sword", 2)
	
	# 妖刀
	if has_item("demon_blade"):
		total += int(round(float(item_battle_wins) * get_equipment_effect_multiplier("demon_blade")))
	
	# 赏金宽刃
	if has_item("bounty_blade"):
		total += get_equipment_scaled_int("bounty_blade", int(player_gold / 10.0) * 2)
	
	return total

# 赏金宽刃加成（单独计算用于显示）
func get_bounty_bonus():
	if has_item("bounty_blade"):
		return get_equipment_scaled_int("bounty_blade", int(player_gold / 10.0) * 2)
	return 0

# 总攻击（含特殊效果）
func get_total_attack():
	var total = get_base_attack()
	
	# 精确制导系统：生命为1时攻击+50%
	if has_item("precision_guidance") and player_hp == 1:
		var bonus = (1.5 if _is_ai_system_active() else 1.0) * get_equipment_effect_multiplier("precision_guidance")
		total = int(total * bonus)
		print("Precision Guidance active: attack x", bonus)
	
	return total

# 暴击率
func get_crit_chance():
	var chance = 0.0
	
	# 弑君者
	if has_item("regicide"):
		chance += 0.2 * get_equipment_effect_multiplier("regicide")
	
	# 精确计算系统：生命为1时暴击+30%
	if has_item("precision_calculation") and player_hp == 1:
		chance += 0.3 * (1.5 if _is_ai_system_active() else 1.0) * get_equipment_effect_multiplier("precision_calculation")
		print("Precision Calculation active")

	# 随机事件提供的暴击加成，单位为每层 20%
	chance += RandomEventManager.get_crit_bonus() * 0.2
	
	return min(chance, 0.95)

# 生命偷取
func get_life_steal(damage: int):
	if has_item("blood_tyrant"):
		return maxi(1, int(damage * 0.1 * get_equipment_effect_multiplier("blood_tyrant")))
	return 0

# 护盾
func get_shield():
	return player_shield

# 护盾反射
func has_shield_reflect():
	return has_item("heart_mirror")

func get_shield_reflect_multiplier() -> float:
	if has_item("heart_mirror"):
		return get_equipment_effect_multiplier("heart_mirror")
	return 0.0

# 治疗翻倍
func has_heal_double():
	return has_item("vampire_cross")

func get_heal_multiplier() -> float:
	if has_item("vampire_cross"):
		return 2.0 * get_equipment_effect_multiplier("vampire_cross")
	return 1.0

# 贪婪手套受伤加成
func has_greedy_gloves():
	return has_item("greedy_gloves")

# 金币加成
func get_gold_bonus():
	if has_item("greedy_gloves"):
		return 0.5 * get_equipment_effect_multiplier("greedy_gloves")
	return 0.0

func get_gold_reward_multiplier() -> float:
	return 1.0 + get_gold_bonus()

# 受到伤害加成（贪婪手套）
func get_damage_taken_multiplier():
	if has_item("greedy_gloves"):
		return 1.5 * get_equipment_effect_multiplier("greedy_gloves")
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
		base_atk -= int(player_gold / 10.0) * 2
	
	if has_guidance and has_auxiliary and has_calculation and base_atk <= 1:
		print("AI System active! Precision effects +50%")
		return true
	
	return false

# 记录战斗胜利
func on_battle_won():
	item_battle_wins += 1
	precision_battle_count += 1

# ===== 连招系统函数 =====

# 装备连招
func equip_combo(combo_id: String) -> bool:
	if equipped_combos.size() >= max_combo_slots:
		print("[Combo] Cannot equip, slots full")
		return false
	
	if combo_id in equipped_combos:
		print("[Combo] Already equipped")
		return false
	
	equipped_combos.append(combo_id)
	print("[Combo] Equipped: ", combo_id)
	return true

# 卸下连招
func unequip_combo(combo_id: String) -> bool:
	if not combo_id in equipped_combos:
		return false
	
	equipped_combos.erase(combo_id)
	print("[Combo] Unequipped: ", combo_id)
	return true

# 检查是否已装备
func has_combo_equipped(combo_id: String) -> bool:
	return combo_id in equipped_combos

# 获取已装备连招ID列表
func get_equipped_combos() -> Array[String]:
	return equipped_combos

# 获取剩余槽位数量
func get_available_combo_slots() -> int:
	return max_combo_slots - equipped_combos.size()

# 检查连招是否冷却中
func is_combo_on_cooldown(combo_id: String) -> bool:
	return combo_cooldowns.has(combo_id) and combo_cooldowns[combo_id] > 0

# 获取连招剩余冷却
func get_combo_cooldown(combo_id: String) -> int:
	return combo_cooldowns.get(combo_id, 0)

# 触发连招（应用冷却）
func trigger_combo(combo_id: String, cooldown: int):
	var final_cooldown = maxi(cooldown - get_meta_upgrade_count("combo_cooldown"), 1)
	combo_cooldowns[combo_id] = final_cooldown
	print("[Combo] Triggered: ", combo_id, " cooldown: ", final_cooldown)

# 每回合减少冷却
func reduce_cooldowns():
	for combo_id in combo_cooldowns.keys():
		if combo_cooldowns[combo_id] > 0:
			combo_cooldowns[combo_id] -= 1
			if combo_cooldowns[combo_id] == 0:
				combo_cooldowns.erase(combo_id)
				print("[Combo] Cooldown ready: ", combo_id)

# 应用连招增益
func apply_combo_buff(buff_type: String, value: int, duration: int):
	combo_buffs[buff_type] = {"value": value, "duration": duration}
	print("[Combo] Buff applied: ", buff_type, " = ", value, " for ", duration, " turns")

# 获取连招增益
func get_combo_buff(buff_type: String) -> int:
	if combo_buffs.has(buff_type):
		return combo_buffs[buff_type].value
	return 0

# 处理连招增益回合
func process_combo_buffs():
	var expired_buffs: Array[String] = []
	
	for buff_type in combo_buffs.keys():
		combo_buffs[buff_type].duration -= 1
		if combo_buffs[buff_type].duration <= 0:
			expired_buffs.append(buff_type)
	
	for buff_type in expired_buffs:
		combo_buffs.erase(buff_type)
		print("[Combo] Buff expired: ", buff_type)

# ===== 角色技能系统 =====

# 医生 - 复活能力
var has_resurrection: bool = false  # 是否有复活资格
var resurrection_used: bool = false  # 本局是否已使用复活
var resurrection_hp: int = 5  # 复活后生命值

# 商人 - 金币加成
var gold_bonus_percent: int = 0  # 金币加成百分比
var last_rest_income_floor: int = -1

# 农民 - 高防御
var armor_regen: bool = false  # 是否拥有护甲恢复能力

# 黑客 - 高爆发
var critical_damage_bonus: int = 0  # 暴击伤害加成百分比

# 初始化角色技能
func init_class_abilities(class_id: int):
	# 重置所有技能
	has_resurrection = false
	resurrection_used = false
	resurrection_hp = player_max_hp
	gold_bonus_percent = 0
	armor_regen = false
	critical_damage_bonus = 0
	
	match class_id:
		0:  # 医生
			has_resurrection = true
			resurrection_hp = player_max_hp
			print("[Class] 医生：起死回生已就绪，本局可满血复活一次")
		
		1:  # 黑客
			critical_damage_bonus = 50
			cheat_points = maxi(cheat_points, 1)
			print("[Class] 黑客：科学上网，外挂点数+1，上限", get_max_cheat_points())
		
		2:  # 商人
			gold_bonus_percent = 30
			print("[Class] 商人：睡后收入，进入休息点自动获得20金币")
		
		3:  # 农民
			armor_regen = true
			print("[Class] 农民：种因得果，护盾可叠加并带入下一场战斗")
		4:
			print("[Class] 流浪者：异路同归，使用独立基础连招组")

func on_enter_rest_point() -> bool:
	if player_class != 2:
		return false
	if last_rest_income_floor == current_floor:
		return false
	last_rest_income_floor = current_floor
	player_gold += 20
	print("[Class] 商人睡后收入：进入休息点获得20金币")
	return true

# 检查是否触发复活
func try_resurrection() -> bool:
	if has_resurrection and not resurrection_used and player_hp <= 0:
		resurrection_used = true
		player_hp = player_max_hp
		print("[Resurrection] 医生起死回生！恢复至满血", player_max_hp)
		return true
	return false

# 获取宝箱选择数量
func get_chest_choices() -> int:
	return 1  # 基础1个

# 获取最大装备栏数量
func get_max_equipment_slots() -> int:
	return get_current_equipment_slot_limit()

func get_max_backpack_slots() -> int:
	return get_current_backpack_limit()

# ===== 护盾伤害处理系统 =====

# 处理受到的伤害，优先扣除护盾
# 返回实际受到的生命伤害和护盾抵扣的伤害
func apply_damage(incoming_damage: int, ignore_shield: bool = false) -> Dictionary:
	var result = {
		"actual_damage": 0,
		"shield_absorbed": 0,
		"shield_broken": false
	}
	
	if ignore_shield or player_shield <= 0:
		# 无视护盾或没有护盾，全额伤害
		result.actual_damage = incoming_damage
		player_hp = maxi(player_hp - incoming_damage, 0)
	else:
		# 优先扣除护盾
		if player_shield >= incoming_damage:
			# 护盾足够吸收全部伤害
			player_shield -= incoming_damage
			result.shield_absorbed = incoming_damage
			result.shield_broken = false
		else:
			# 护盾不足，破盾后剩余伤害扣血
			result.shield_absorbed = player_shield
			result.actual_damage = incoming_damage - player_shield
			result.shield_broken = true
			player_shield = 0
			player_hp = maxi(player_hp - result.actual_damage, 0)
	
	print("[Damage] 受到", incoming_damage, "伤害, 护盾吸收", result.shield_absorbed, 
		", 实际伤害", result.actual_damage, ", 剩余护盾", player_shield, ", 剩余生命", player_hp)
	
	return result

# 添加护盾
func add_shield(amount: int):
	player_shield += amount
	print("[Shield] 获得", amount, "护盾, 当前", player_shield)

# 减少护盾（直接减少，不扣血）
func reduce_shield(amount: int):
	player_shield = maxi(player_shield - amount, 0)
	print("[Shield] 减少", amount, "护盾, 当前", player_shield)

# 重置战斗状态（每场战斗开始时调用）
func reset_battle_state():
	combo_buffs.clear()
	combo_cooldowns.clear()

func shield_persists_between_battles() -> bool:
	return player_class == 3

# ===== 装备相关连招检查 =====

# 检查是否有妖刀
func has_demon_blade() -> bool:
	return has_item("demon_blade") or has_in_backpack("demon_blade")

# 检查是否有护心镜
func has_heart_mirror() -> bool:
	return has_item("heart_mirror") or has_in_backpack("heart_mirror")

# 检查是否有精确系统全套
func has_precision_system_full() -> bool:
	var has_guidance = has_item("precision_guidance") or has_in_backpack("precision_guidance")
	var has_aux = has_item("precision_auxiliary") or has_in_backpack("precision_auxiliary")
	var has_calc = has_item("precision_calculation") or has_in_backpack("precision_calculation")
	return has_guidance and has_aux and has_calc

# 检查是否满足绝地反击条件（生命≤30%）
func can_trigger_desperate() -> bool:
	var hp_percent = float(player_hp) / float(player_max_hp)
	return hp_percent <= 0.3

# 检查是否满足固若金汤条件（护甲≥5）
func can_trigger_iron_fortress() -> bool:
	return player_shield >= 5

# 检查是否满足物资轰炸条件（背包满格）
func can_trigger_supply_bombard() -> bool:
	return backpack.size() >= get_current_backpack_limit()

# ===== 存档 / 局外成长 =====

func has_active_run() -> bool:
	return run_active

func get_checkpoint_scene() -> String:
	return checkpoint_scene

func set_checkpoint_scene(scene_name: String) -> void:
	checkpoint_scene = scene_name

func update_highest_floor(floor_value: int) -> void:
	var clamped_floor = clamp(floor_value, 0, max_floors - 1)
	highest_floor_reached = maxi(highest_floor_reached, clamped_floor)

func has_combo_tier_unlocked(tier: int) -> bool:
	if tier <= 0:
		return true
	if tier == 1:
		return has_meta_upgrade("advanced_combo")
	if tier == 2:
		return has_meta_upgrade("ultimate_combo")
	return false

func get_combo_unlock_status_text() -> String:
	var advanced_text = "已解锁" if has_combo_tier_unlocked(1) else "局外升级解锁（2存储器）"
	var ultimate_text = "已解锁" if has_combo_tier_unlocked(2) else "局外升级解锁（4存储器）"
	return "高级连招: %s | 终极连招: %s" % [advanced_text, ultimate_text]

func get_save_slot_summary() -> String:
	if not run_active:
		return "暂无可继续的冒险"
	var class_names = ["医生", "黑客", "商人", "农民", "流浪者"]
	var class_display_name = "未知职业"
	if player_class >= 0 and player_class < class_names.size():
		class_display_name = class_names[player_class]
	return "%s | 第%d层 | HP %d/%d | 金币 %d" % [class_display_name, current_floor + 1, player_hp, player_max_hp, player_gold]

func get_run_summary() -> Dictionary:
	var class_names = ["医生", "黑客", "商人", "农民", "流浪者"]
	var combo_names: Array[String] = []
	var item_names: Array[String] = []
	var class_display_name = "未知职业"
	if player_class >= 0 and player_class < class_names.size():
		class_display_name = class_names[player_class]
	var combo_db = load("res://resources/combo_database.gd").new()
	combo_db._init_database()
	
	for combo_id in equipped_combos:
		var combo_info = combo_db.get_combo_by_id(combo_id)
		if combo_info:
			combo_names.append(combo_info.name)
			continue
		var combat_combo = combo_db.get_combat_combo_by_id(combo_id)
		if combat_combo:
			combo_names.append(combat_combo.name)
		else:
			combo_names.append(combo_id)
	for item in equipment_slot:
		item_names.append(item.get("name", "未知装备"))
	
	return {
		"class_name": class_display_name,
		"floor_reached": mini(current_floor, max_floors - 1) + 1,
		"gold": player_gold,
		"materials": materials,
		"hp": player_hp,
		"max_hp": player_max_hp,
		"attack": player_attack,
		"equipped_combos": combo_names,
		"equipment_names": item_names
	}

func record_item_discovery(item_id: String) -> void:
	if item_id == "":
		return
	if not discovered_items.has(item_id):
		discovered_items.append(item_id)
		_evaluate_achievements()

func record_event_discovery(event_id: String) -> void:
	if event_id == "":
		return
	if not discovered_events.has(event_id):
		discovered_events.append(event_id)
		_evaluate_achievements()

func record_class_first_clear(class_id: int) -> void:
	var key = str(class_id)
	if not class_first_clears.get(key, false):
		class_first_clears[key] = true
		_evaluate_achievements()

func _unlock_achievement(achievement_id: String) -> void:
	if unlocked_achievements.has(achievement_id):
		return
	unlocked_achievements.append(achievement_id)
	print("[Achievement] Unlocked: ", achievement_id)

func _evaluate_achievements() -> void:
	if highest_floor_reached >= 5:
		_unlock_achievement("reach_floor_6")
	if total_wins >= 1:
		_unlock_achievement("first_victory")
	if total_wins >= 3:
		_unlock_achievement("triple_crown")
	if discovered_items.size() >= 5:
		_unlock_achievement("collector")
	if discovered_events.size() >= 6:
		_unlock_achievement("event_hunter")
	if class_first_clears.size() >= 4:
		_unlock_achievement("all_classes_clear")

func get_achievement_definitions() -> Array[Dictionary]:
	return [
		{"id": "reach_floor_6", "name": "初窥门径", "desc": "历史最高到达第6层"},
		{"id": "first_victory", "name": "塔顶来客", "desc": "首次完成通关"},
		{"id": "triple_crown", "name": "三冠挑战", "desc": "累计通关3次"},
		{"id": "collector", "name": "收藏癖", "desc": "累计发现5种装备"},
		{"id": "event_hunter", "name": "命运观测者", "desc": "累计遭遇6种不同事件"},
		{"id": "all_classes_clear", "name": "四相归一", "desc": "四个职业都完成首通"}
	]

func get_achievement_status() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in get_achievement_definitions():
		var entry = definition.duplicate(true)
		entry["unlocked"] = unlocked_achievements.has(definition["id"])
		result.append(entry)
	return result

func get_meta_progress_summary() -> Dictionary:
	var all_items = ITEMS.keys()
	return {
		"highest_floor": highest_floor_reached + 1 if runs_played > 0 or run_active else 0,
		"total_wins": total_wins,
		"memory_cores": memory_cores,
		"meta_upgrades": meta_upgrades.duplicate(true),
		"class_first_clears": class_first_clears.duplicate(true),
		"discovered_item_count": discovered_items.size(),
		"total_item_count": all_items.size(),
		"discovered_event_count": discovered_events.size(),
		"achievement_count": unlocked_achievements.size(),
		"total_achievement_count": get_achievement_definitions().size()
	}

func get_discovered_items() -> Array[String]:
	return discovered_items.duplicate()

func get_discovered_events() -> Array[String]:
	return discovered_events.duplicate()

func _to_string_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result

func _to_dictionary_array(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result

func _to_int_array(values: Array) -> Array[int]:
	var result: Array[int] = []
	for value in values:
		result.append(int(value))
	return result

func _to_nested_dictionary_array(values: Array) -> Array[Array]:
	var result: Array[Array] = []
	for row in values:
		if row is Array:
			var row_result: Array = []
			for item in row:
				if item is Dictionary:
					row_result.append((item as Dictionary).duplicate(true))
			result.append(row_result)
	return result

func complete_run(won: bool) -> void:
	update_highest_floor(current_floor)
	runs_played += 1
	if won:
		total_wins += 1
		record_class_first_clear(player_class)
	run_active = false
	checkpoint_scene = "map"
	current_shop_items.clear()
	_evaluate_achievements()
	save_progress()

func save_progress(scene_name: String = "") -> void:
	if scene_name != "":
		checkpoint_scene = scene_name
	if run_active:
		update_highest_floor(current_floor)
	
	var save_data: Dictionary = {
		"save_version": SAVE_VERSION,
		"meta": {
			"highest_floor_reached": highest_floor_reached,
			"total_wins": total_wins,
			"runs_played": runs_played,
			"class_first_clears": class_first_clears,
			"discovered_items": discovered_items,
			"discovered_events": discovered_events,
			"unlocked_achievements": unlocked_achievements,
			"memory_cores": memory_cores,
			"meta_upgrades": meta_upgrades
		},
		"run_active": run_active,
		"checkpoint_scene": checkpoint_scene
	}
	
	if run_active:
		save_data["run"] = {
			"player_hp": player_hp,
			"player_max_hp": player_max_hp,
			"player_attack": player_attack,
			"player_shield": player_shield,
			"player_gold": player_gold,
			"player_class": player_class,
			"player_level": player_level,
			"player_exp": player_exp,
			"current_floor": current_floor,
			"max_floors": max_floors,
			"cheat_points": cheat_points,
			"shop_discount": shop_discount,
			"map_data": map_data,
			"equipment_slot": equipment_slot,
			"backpack": backpack,
			"item_battle_wins": item_battle_wins,
			"precision_battle_count": precision_battle_count,
			"combo_moves": combo_moves,
			"combo_energy": combo_energy,
			"max_combo_energy": max_combo_energy,
			"unlocked_combos": unlocked_combos,
			"materials": materials,
			"combo_upgrades": combo_upgrades,
			"equipment_upgrades": equipment_upgrades,
			"equipped_combos": equipped_combos,
			"max_combo_slots": max_combo_slots,
			"bonus_equipment_slots": bonus_equipment_slots,
			"bonus_backpack_slots": bonus_backpack_slots,
			"bonus_hp_from_level": bonus_hp_from_level,
			"bonus_atk_from_level": bonus_atk_from_level,
			"unspent_attribute_points": unspent_attribute_points,
			"combo_cooldowns": combo_cooldowns,
			"combo_buffs": combo_buffs,
			"draw_protection_available": draw_protection_available,
			"draw_protection_armed": draw_protection_armed,
			"has_resurrection": has_resurrection,
			"resurrection_used": resurrection_used,
			"resurrection_hp": resurrection_hp,
			"gold_bonus_percent": gold_bonus_percent,
			"last_rest_income_floor": last_rest_income_floor,
			"armor_regen": armor_regen,
			"critical_damage_bonus": critical_damage_bonus,
			"current_shop_items": current_shop_items
		}
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file: " + SAVE_FILE_PATH)
		return
	file.store_string(JSON.stringify(save_data))

func migrate_save_data(save_data: Dictionary) -> Dictionary:
	var migrated = save_data.duplicate(true)
	var version = int(migrated.get("save_version", 1))
	if version < 1:
		version = 1

	if not migrated.has("meta") or not (migrated["meta"] is Dictionary):
		migrated["meta"] = {}
	var meta: Dictionary = migrated["meta"]
	if not meta.has("memory_cores"):
		meta["memory_cores"] = 0
	if not meta.has("meta_upgrades") or not (meta["meta_upgrades"] is Dictionary):
		meta["meta_upgrades"] = {}
	if not meta.has("class_first_clears") or not (meta["class_first_clears"] is Dictionary):
		meta["class_first_clears"] = {}
	if not meta.has("discovered_items"):
		meta["discovered_items"] = []
	if not meta.has("discovered_events"):
		meta["discovered_events"] = []
	if not meta.has("unlocked_achievements"):
		meta["unlocked_achievements"] = []

	if bool(migrated.get("run_active", false)):
		if not migrated.has("run") or not (migrated["run"] is Dictionary):
			migrated["run"] = {}
		var run_data: Dictionary = migrated["run"]
		if not run_data.has("draw_protection_available"):
			run_data["draw_protection_available"] = false
		if not run_data.has("draw_protection_armed"):
			run_data["draw_protection_armed"] = false
		if not run_data.has("current_shop_items"):
			run_data["current_shop_items"] = []
		if not run_data.has("bonus_equipment_slots"):
			run_data["bonus_equipment_slots"] = 0
		if not run_data.has("bonus_backpack_slots"):
			run_data["bonus_backpack_slots"] = 0

	migrated["save_version"] = SAVE_VERSION
	return migrated

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		return
	
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	parsed = migrate_save_data(parsed)
	
	var meta: Dictionary = parsed.get("meta", {})
	highest_floor_reached = int(meta.get("highest_floor_reached", 0))
	total_wins = int(meta.get("total_wins", 0))
	runs_played = int(meta.get("runs_played", 0))
	class_first_clears = meta.get("class_first_clears", {}).duplicate(true)
	discovered_items = _to_string_array(meta.get("discovered_items", []))
	discovered_events = _to_string_array(meta.get("discovered_events", []))
	unlocked_achievements = _to_string_array(meta.get("unlocked_achievements", []))
	memory_cores = int(meta.get("memory_cores", 0))
	meta_upgrades = meta.get("meta_upgrades", {}).duplicate(true)
	run_active = bool(parsed.get("run_active", false))
	checkpoint_scene = str(parsed.get("checkpoint_scene", "map"))
	_evaluate_achievements()
	
	if not run_active:
		return
	
	var run_data: Dictionary = parsed.get("run", {})
	player_hp = int(run_data.get("player_hp", player_hp))
	player_max_hp = int(run_data.get("player_max_hp", player_max_hp))
	player_attack = int(run_data.get("player_attack", player_attack))
	player_shield = int(run_data.get("player_shield", player_shield))
	player_gold = int(run_data.get("player_gold", player_gold))
	player_class = int(run_data.get("player_class", player_class))
	player_level = int(run_data.get("player_level", 1))
	player_exp = int(run_data.get("player_exp", 0))
	current_floor = int(run_data.get("current_floor", current_floor))
	max_floors = int(run_data.get("max_floors", max_floors))
	cheat_points = int(run_data.get("cheat_points", cheat_points))
	shop_discount = float(run_data.get("shop_discount", shop_discount))
	map_data = _to_nested_dictionary_array(run_data.get("map_data", []))
	equipment_slot = _to_dictionary_array(run_data.get("equipment_slot", []))
	backpack = _to_dictionary_array(run_data.get("backpack", []))
	item_battle_wins = int(run_data.get("item_battle_wins", item_battle_wins))
	precision_battle_count = int(run_data.get("precision_battle_count", precision_battle_count))
	combo_moves = _to_int_array(run_data.get("combo_moves", []))
	combo_energy = int(run_data.get("combo_energy", combo_energy))
	max_combo_energy = int(run_data.get("max_combo_energy", max_combo_energy))
	unlocked_combos = _to_string_array(run_data.get("unlocked_combos", DEFAULT_UNLOCKED_COMBOS))
	materials = int(run_data.get("materials", materials))
	combo_upgrades = run_data.get("combo_upgrades", {}).duplicate(true)
	equipment_upgrades = run_data.get("equipment_upgrades", {}).duplicate(true)
	equipped_combos = _to_string_array(run_data.get("equipped_combos", []))
	max_combo_slots = int(run_data.get("max_combo_slots", max_combo_slots))
	bonus_equipment_slots = int(run_data.get("bonus_equipment_slots", 0))
	bonus_backpack_slots = int(run_data.get("bonus_backpack_slots", 0))
	bonus_hp_from_level = int(run_data.get("bonus_hp_from_level", 0))
	bonus_atk_from_level = int(run_data.get("bonus_atk_from_level", 0))
	unspent_attribute_points = int(run_data.get("unspent_attribute_points", 0))
	combo_cooldowns = run_data.get("combo_cooldowns", {}).duplicate(true)
	combo_buffs = run_data.get("combo_buffs", {}).duplicate(true)
	draw_protection_available = bool(run_data.get("draw_protection_available", false))
	draw_protection_armed = bool(run_data.get("draw_protection_armed", false))
	current_shop_items = _to_string_array(run_data.get("current_shop_items", []))
	
	has_resurrection = bool(run_data.get("has_resurrection", false))
	resurrection_used = bool(run_data.get("resurrection_used", false))
	resurrection_hp = int(run_data.get("resurrection_hp", 5))
	gold_bonus_percent = int(run_data.get("gold_bonus_percent", 0))
	last_rest_income_floor = int(run_data.get("last_rest_income_floor", -1))
	armor_regen = bool(run_data.get("armor_regen", false))
	critical_damage_bonus = int(run_data.get("critical_damage_bonus", 0))
	
	var player_class_script = load("res://resources/player_class_data.gd")
	exclusive_combos = player_class_script.get_class_combos(player_class)
