extends Node

const SAVE_FILE_PATH := "user://savegame.json"
const SAVE_TEMP_PATH := "user://savegame.tmp"
const SAVE_BACKUP_PATH := "user://savegame.bak"
const SAVE_VERSION: int = 3
const MAJOR_LAYER_COUNT: int = 3
const FLOORS_PER_MAJOR_LAYER: int = 19
const TOTAL_SMALL_FLOORS: int = MAJOR_LAYER_COUNT * FLOORS_PER_MAJOR_LAYER

# 游戏状态
var player_hp: int = 6
var player_max_hp: int = 6
var player_attack: int = 2
var player_shield: int = 0
var player_gold: int = 0
var player_class: int = 0

var current_floor: int = 0
var max_floors: int = TOTAL_SMALL_FLOORS

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
var selected_heirloom_id: String = ""
var field_pending_spend_attack: int = 0
var field_pending_blood_attack: int = 0
var field_pending_merchant_attack: int = 0
var selected_route_name: String = ""
var route_switch_count: int = 0
var acknowledged_major_layer_debuffs: Array[int] = []
var last_enemy_ai_type: int = -1
var last_enemy_ai_subtype: int = -1
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
var era_first_clears: Dictionary = {}
var discovered_items: Array[String] = []
var discovered_events: Array[String] = []
var unlocked_achievements: Array[String] = []
var memory_cores: int = 0
var meta_upgrades: Dictionary = {}
var selected_era_id: String = "qin"
var suppress_save_progress: bool = false

const DEFAULT_USER_SETTINGS := {
	"audio_muted": false,
	"battle_speed": 1.0
}
var user_settings: Dictionary = DEFAULT_USER_SETTINGS.duplicate(true)

# ===== 局内升级系统 =====
const MAX_PLAYER_LEVEL: int = 10
const MAX_LEVEL_HP_BONUS: int = 10
const MAX_LEVEL_ATK_BONUS: int = 5
const MAX_LEVEL_CHEAT_BONUS: int = 5
const MAX_BONUS_EQUIPMENT_SLOTS: int = 4
const MAX_BONUS_BACKPACK_SLOTS: int = 2

var player_level: int = 1
var player_exp: int = 0
var unspent_attribute_points: int = 0
var bonus_equipment_slots: int = 0
var bonus_backpack_slots: int = 0
var bonus_hp_from_level: int = 0
var bonus_atk_from_level: int = 0
var bonus_cheat_from_level: int = 0
var draw_protection_available: bool = false
var draw_protection_armed: bool = false

func _ready() -> void:
	DebugLog.log("GameState ready")
	# 初始化时解锁默认连招
	unlocked_combos = DEFAULT_UNLOCKED_COMBOS.duplicate()
	user_settings = _normalize_user_settings(user_settings)
	apply_user_settings()
	load_progress()
	_evaluate_achievements()

func get_default_user_settings() -> Dictionary:
	return DEFAULT_USER_SETTINGS.duplicate(true)

func _normalize_user_settings(raw_settings) -> Dictionary:
	var normalized := get_default_user_settings()
	if raw_settings is Dictionary:
		var raw: Dictionary = raw_settings
		if raw.has("audio_muted"):
			normalized["audio_muted"] = bool(raw.get("audio_muted", false))
		if raw.has("battle_speed"):
			normalized["battle_speed"] = _normalize_battle_speed(float(raw.get("battle_speed", 1.0)))
	return normalized

func _normalize_battle_speed(value: float) -> float:
	var allowed := [1.0, 1.25, 1.5]
	var nearest := 1.0
	var nearest_delta := INF
	for speed in allowed:
		var delta := absf(float(speed) - value)
		if delta < nearest_delta:
			nearest_delta = delta
			nearest = float(speed)
	return nearest

func apply_user_settings() -> void:
	user_settings = _normalize_user_settings(user_settings)
	AudioServer.set_bus_mute(0, bool(user_settings.get("audio_muted", false)))
	Engine.time_scale = float(user_settings.get("battle_speed", 1.0))

func set_user_setting(key: String, value, persist: bool = true) -> void:
	user_settings = _normalize_user_settings(user_settings)
	user_settings[key] = value
	user_settings = _normalize_user_settings(user_settings)
	apply_user_settings()
	if persist:
		save_progress()

func is_audio_muted() -> bool:
	return bool(user_settings.get("audio_muted", false))

func set_audio_muted(muted: bool, persist: bool = true) -> void:
	set_user_setting("audio_muted", muted, persist)

func toggle_audio_muted(persist: bool = true) -> bool:
	set_audio_muted(not is_audio_muted(), persist)
	return is_audio_muted()

func get_battle_speed() -> float:
	return float(user_settings.get("battle_speed", 1.0))

func set_battle_speed(speed: float, persist: bool = true) -> void:
	set_user_setting("battle_speed", speed, persist)

func cycle_battle_speed(persist: bool = true) -> float:
	var speeds := [1.0, 1.25, 1.5]
	var current := get_battle_speed()
	var next_idx := 0
	for i in range(speeds.size()):
		if absf(float(speeds[i]) - current) < 0.01:
			next_idx = (i + 1) % speeds.size()
			break
	set_battle_speed(float(speeds[next_idx]), persist)
	return get_battle_speed()

func reset_user_settings(persist: bool = true) -> void:
	user_settings = get_default_user_settings()
	apply_user_settings()
	if persist:
		save_progress()

func get_settings_status_text() -> String:
	return "当前音效：%s    当前速度：x%.2f" % [
		"关闭" if is_audio_muted() else "开启",
		get_battle_speed()
	]

# ===== 材料系统 =====
var materials: int = 0  # 当前材料数量
var MATERIAL_PRICE: int = 5  # 商店购买材料的价格

const COMBO_UPGRADE_GOLD_COSTS: Array[int] = [8, 14, 22, 32, 45]
const EQUIPMENT_LEVEL_GOLD_BASE: int = 10
const EQUIPMENT_LEVEL_GOLD_STEP: int = 4
const EQUIPMENT_QUALITY_GOLD_COSTS: Array[int] = [24, 38]
const EQUIPMENT_SPECIAL_GOLD_COST: int = 36

func add_materials(amount: int) -> void:
	"""添加材料并发出信号"""
	materials += amount
	EventBus.materials_changed.emit(materials)
	DebugLog.log("[Materials] 获得 +%d，当前: %d" % [amount, materials])

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
	DebugLog.log("[Combo Energy] +%d，当前: %d/%d" % [amount, combo_energy, max_combo_energy])

func consume_combo_energy(amount: int) -> bool:
	"""消耗连击能量，返回是否成功"""
	if combo_energy >= amount:
		combo_energy -= amount
		EventBus.combo_energy_changed.emit(combo_energy, max_combo_energy)
		DebugLog.log("[Combo Energy] -%d，剩余: %d/%d" % [amount, combo_energy, max_combo_energy])
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

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if player_gold < amount:
		return false
	player_gold -= amount
	EventBus.player_gold_changed.emit(player_gold)
	register_gold_spent_for_field(amount)
	return true

func get_combo_upgrade_gold_cost(current_level: int) -> int:
	var idx = clamp(current_level, 0, COMBO_UPGRADE_GOLD_COSTS.size() - 1)
	return int(COMBO_UPGRADE_GOLD_COSTS[idx])

func get_equipment_upgrade_gold_cost(upgrade_type: String, upgrades_done: int) -> int:
	match upgrade_type:
		"level":
			return EQUIPMENT_LEVEL_GOLD_BASE + maxi(upgrades_done, 0) * EQUIPMENT_LEVEL_GOLD_STEP
		"quality":
			var idx = clamp(upgrades_done, 0, EQUIPMENT_QUALITY_GOLD_COSTS.size() - 1)
			return int(EQUIPMENT_QUALITY_GOLD_COSTS[idx])
		"special":
			return EQUIPMENT_SPECIAL_GOLD_COST
		_:
			return EQUIPMENT_LEVEL_GOLD_BASE

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
	return get_major_layer_index(floor_index) + 1

func get_major_layer_index(floor_index: int = current_floor) -> int:
	return clamp(int(maxi(floor_index, 0) / FLOORS_PER_MAJOR_LAYER), 0, MAJOR_LAYER_COUNT - 1)

func get_major_layer_local_floor(floor_index: int = current_floor) -> int:
	return int(maxi(floor_index, 0) % FLOORS_PER_MAJOR_LAYER) + 1

func get_farmer_shield_soft_cap(floor_index: int = current_floor) -> int:
	var layer := get_major_layer_index(floor_index)
	var equipment_bonus := 0
	if has_item_anywhere("wooden_shield"):
		equipment_bonus += 5
	if has_item_anywhere("heart_mirror"):
		equipment_bonus += 4
	if has_item_anywhere("heart_armor"):
		equipment_bonus += 4
	if has_item_anywhere("thorn_armor"):
		equipment_bonus += 6
	return 32 + layer * 16 + equipment_bonus

func clamp_farmer_shield_carryover() -> int:
	if player_class != 3:
		return 0
	var cap := get_farmer_shield_soft_cap()
	if player_shield <= cap:
		return 0
	var trimmed := player_shield - cap
	player_shield = cap
	return trimmed

func get_major_layer_range_text(layer_index: int = get_major_layer_index()) -> String:
	var clamped_layer: int = clamp(layer_index, 0, MAJOR_LAYER_COUNT - 1)
	var start_floor: int = clamped_layer * FLOORS_PER_MAJOR_LAYER + 1
	var end_floor: int = start_floor + FLOORS_PER_MAJOR_LAYER - 1
	return "%d-%d" % [start_floor, end_floor]

func get_major_layer_title(layer_index: int = get_major_layer_index()) -> String:
	var titles := ["第一大层", "第二大层", "第三大层"]
	return titles[clamp(layer_index, 0, titles.size() - 1)]

func get_major_layer_status_text(floor_index: int = current_floor) -> String:
	var layer_index := get_major_layer_index(floor_index)
	return "%s · %d/%d" % [
		get_major_layer_title(layer_index),
		get_major_layer_local_floor(floor_index),
		FLOORS_PER_MAJOR_LAYER
	]

func should_show_current_major_layer_debuff() -> bool:
	var layer_index := get_major_layer_index()
	return get_major_layer_local_floor() == 1 and not layer_index in acknowledged_major_layer_debuffs

func mark_current_major_layer_debuff_seen() -> void:
	var layer_index := get_major_layer_index()
	if not layer_index in acknowledged_major_layer_debuffs:
		acknowledged_major_layer_debuffs.append(layer_index)

func get_current_major_layer_debuff() -> Dictionary:
	var layer_index := get_major_layer_index()
	var layer_titles := ["初入局", "势渐紧", "终局压境"]
	var layer_desc := [
		"规则开始落下，压力还轻，适合建立构筑雏形。",
		"敌军与资源压力同步抬高，路线选择会开始反噬。",
		"卷末压力完全展开，容错降低，构筑必须开始兑现。"
	]
	var era := get_current_era_definition()
	var debuff_name := str(era.get("debuff_name", "时代压力"))
	var debuff_desc := str(era.get("debuff_desc", "本卷会施加额外压力。"))
	var mechanical_text := ""
	match selected_era_id:
		"song":
			mechanical_text = "宋卷：后两大层敌方攻势逐步增强，Boss与后期小怪攻击更高。"
		"china":
			mechanical_text = "中国卷：后两大层敌方血量与攻击逐步提高，终局敌人叠加多重时代规则。"
		_:
			mechanical_text = "秦卷：商路更紧，行商价格偏高，路线选择更考验前期节奏。"
	return {
		"era_name": str(era.get("name", "秦")),
		"layer_index": layer_index,
		"layer_title": get_major_layer_title(layer_index),
		"layer_stage": layer_titles[clamp(layer_index, 0, layer_titles.size() - 1)],
		"floor_range": get_major_layer_range_text(layer_index),
		"debuff_name": debuff_name,
		"debuff_desc": debuff_desc,
		"layer_desc": layer_desc[clamp(layer_index, 0, layer_desc.size() - 1)],
		"mechanical_text": mechanical_text
	}

func get_battle_exp_reward(battle_type: String, floor_index: int = current_floor) -> int:
	var tier := int(maxi(floor_index, 0) / 5)
	var base_exp := 1 + tier * 2
	match battle_type:
		"boss":
			return base_exp + 6
		"elite":
			return base_exp + 2
		_:
			return base_exp

func get_battle_gold_reward(floor_index: int = current_floor) -> int:
	return 6 + int(maxi(floor_index, 0) / 4)

func get_level_reward_summary(level: int) -> Array[String]:
	match level:
		2:
			return ["+1 装备栏", "+1 提振"]
		3:
			return ["+1 提振"]
		4:
			return ["+1 背包格"]
		5:
			return ["+1 装备栏"]
		6:
			return ["+1 提振"]
		7:
			return ["+1 背包格"]
		8:
			return ["+1 装备栏"]
		9:
			return ["+1 提振"]
		10:
			return ["+1 装备栏", "+1 提振"]
		_:
			return []

func apply_level_reward(level: int) -> Array[String]:
	var rewards = get_level_reward_summary(level)
	match level:
		2, 5, 8, 10:
			bonus_equipment_slots = mini(bonus_equipment_slots + 1, MAX_BONUS_EQUIPMENT_SLOTS)
		4, 7:
			bonus_backpack_slots = mini(bonus_backpack_slots + 1, MAX_BONUS_BACKPACK_SLOTS)
	if level in [2, 3, 6, 9, 10]:
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

func can_add_level_cheat() -> bool:
	return bonus_cheat_from_level < MAX_LEVEL_CHEAT_BONUS

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
		"cheat":
			if not can_add_level_cheat():
				return false
			bonus_cheat_from_level += 1
			add_cheat_point()
		_:
			return false

	unspent_attribute_points -= 1
	return true

# ===== 连招强化系统 =====
# 连招强化存储: {combo_id: {level: int, has_burn: bool, has_break_momentum: bool}}
var combo_upgrades: Dictionary = {}

func get_combo_damage_multiplier(combo_id: String) -> float:
	# 读取强化等级，映射为伤害倍率
	# Lv1: +20% (×1.20), Lv2: +30% (×1.30), Lv3: +50% (×1.50)
	var level = get_combo_upgrade_level(combo_id)
	if level == 0:
		return 1.0
	var effects = [1.20, 1.30, 1.50]
	return effects[mini(level, 3) - 1]

func get_era_combo_effect_multiplier(combo_id: String, effect_type: String) -> float:
	match selected_era_id:
		"song":
			if combo_id == "song_trade_turn":
				return 1.20
			if effect_type in ["shield_reflect", "shield_reflect_adv", "shield_all", "shield_duration", "heal", "heal_shield", "bonus_gold", "regen", "armor_delayed"]:
				return 1.20
			if effect_type in ["enemy_cooldown", "stun_damage"]:
				return 1.10
		"china":
			if combo_id == "china_unity_echo":
				return 1.20
			if effect_type in ["damage", "damage_first", "damage_pierce", "damage_all", "ignore_armor_damage", "stun_damage", "pierce_buff"]:
				return 1.15
			if effect_type in ["enemy_cooldown", "bonus_gold", "crit_boost", "heal_shield", "regen", "armor_delayed"]:
				return 1.10
			if combo_id in ["perfect_cycle", "system_crash", "memory_burst", "phase_guard"]:
				return 1.20
		_:
			if combo_id == "qin_tiger_push":
				return 1.20
			if effect_type in ["damage", "damage_first", "damage_pierce", "damage_all", "ignore_armor_damage", "pierce_buff", "double_hit", "bind_damage"]:
				return 1.20
			if effect_type in ["attack_buff", "bonus_gold"]:
				return 1.10
	return 1.0

func get_combo_effect_amount(combo_id: String, base_value: int, effect_type: String) -> int:
	if base_value <= 0:
		return base_value
	var amount = float(base_value)
	amount *= get_combo_damage_multiplier(combo_id)
	amount *= get_era_combo_effect_multiplier(combo_id, effect_type)
	return maxi(int(round(amount)), 1)

func get_era_combo_bonus_text(combo_id: String, effect_type: String) -> String:
	match selected_era_id:
		"song":
			if combo_id == "song_trade_turn":
				return "宋卷专属：此布局只在宋卷出现，经营收益提高20%。"
			if effect_type in ["shield_reflect", "shield_reflect_adv", "shield_all", "shield_duration", "heal", "heal_shield", "bonus_gold", "regen", "armor_delayed"]:
				return "宋卷偏置：此布局的防守/经营收益提高20%。"
			if effect_type in ["enemy_cooldown", "stun_damage"]:
				return "宋卷偏置：此布局的控场收益提高10%。"
		"china":
			if combo_id == "china_unity_echo":
				return "终局专属：此布局只在中国卷出现，续战收益提高20%。"
			if combo_id in ["perfect_cycle", "system_crash", "memory_burst", "phase_guard"]:
				return "终局偏置：此布局作为关键回合布局，综合收益提高20%。"
			if effect_type in ["damage", "damage_first", "damage_pierce", "damage_all", "ignore_armor_damage", "stun_damage", "pierce_buff"]:
				return "终局偏置：此布局的压制收益提高15%。"
			if effect_type in ["enemy_cooldown", "bonus_gold", "crit_boost", "heal_shield", "regen", "armor_delayed"]:
				return "终局偏置：此布局的综合收益提高10%。"
		_:
			if combo_id == "qin_tiger_push":
				return "秦卷专属：此布局只在秦卷出现，强攻收益提高20%。"
			if effect_type in ["damage", "damage_first", "damage_pierce", "damage_all", "ignore_armor_damage", "pierce_buff", "double_hit", "bind_damage"]:
				return "秦卷偏置：此布局的强攻收益提高20%。"
			if effect_type in ["attack_buff", "bonus_gold"]:
				return "秦卷偏置：此布局的压阵收益提高10%。"
	return "当前时代无额外偏置。"

func get_combo_energy_reduction(combo_id: String) -> int:
	if combo_upgrades.has(combo_id):
		return combo_upgrades[combo_id].get("energy_reduction", 0)
	return 0

func has_combo_effect(combo_id: String, effect: String) -> bool:
	if combo_upgrades.has(combo_id):
		if effect == "break_momentum" and combo_upgrades[combo_id].get("has_slow", false):
			return true
		return combo_upgrades[combo_id].get("has_" + effect, false)
	return false

func get_combo_unique_upgrade_labels(combo_id: String) -> Array[String]:
	var parts: Array[String] = []
	match combo_id:
		"qin_tiger_push":
			if has_combo_effect(combo_id, "qin_guardbreak"):
				parts.append("破甲+1")
			if has_combo_effect(combo_id, "qin_battle_armor"):
				parts.append("得甲+2")
		"song_trade_turn":
			if has_combo_effect(combo_id, "song_material_rebate"):
				parts.append("战后+6金币")
			if has_combo_effect(combo_id, "song_gold_bonus"):
				parts.append("额外+4金币")
		"china_unity_echo":
			if has_combo_effect(combo_id, "china_cheat_restore"):
				parts.append("机括+1")
			if has_combo_effect(combo_id, "china_attack_rally"):
				parts.append("攻击+2")
	return parts

func get_combo_unique_upgrade_preview(combo_id: String, next_level: int) -> String:
	match combo_id:
		"qin_tiger_push":
			if next_level == 4:
				return "破甲+1"
			if next_level == 5:
				return "得甲+2"
		"song_trade_turn":
			if next_level == 4:
				return "战后+6金币"
			if next_level == 5:
				return "额外+4金币"
		"china_unity_echo":
			if next_level == 4:
				return "机括+1"
			if next_level == 5:
				return "攻击+2"
	return ""

func get_combo_upgrade_path_text(combo_id: String) -> String:
	var path_parts: Array[String] = [
		"Lv.1：+20%效果",
		"Lv.2：+30%效果",
		"Lv.3：+50%效果"
	]
	var level4_preview = get_combo_unique_upgrade_preview(combo_id, 4)
	var level5_preview = get_combo_unique_upgrade_preview(combo_id, 5)
	path_parts.append("Lv.4：%s" % (level4_preview if level4_preview != "" else "解锁灼烧"))
	path_parts.append("Lv.5：%s" % (level5_preview if level5_preview != "" else "解锁破势"))
	return "升级路径：%s" % "  |  ".join(path_parts)

func _ensure_combo_upgrade_entry(combo_id: String) -> void:
	if not combo_upgrades.has(combo_id):
		combo_upgrades[combo_id] = {"level": 0, "has_burn": false, "has_break_momentum": false}

func _apply_combo_upgrade_step(combo_id: String, new_level: int) -> Dictionary:
	_ensure_combo_upgrade_entry(combo_id)
	combo_upgrades[combo_id]["level"] = new_level
	var result := {"success": true, "cost": 0, "new_level": new_level, "current_effect": ""}
	match new_level:
		1, 2, 3:
			var effect_bonus = [20, 30, 50][new_level - 1]
			result.current_effect = "+%d%%效果" % effect_bonus
		4:
			var unique_preview = get_combo_unique_upgrade_preview(combo_id, 4)
			if unique_preview != "":
				match combo_id:
					"qin_tiger_push":
						combo_upgrades[combo_id]["has_qin_guardbreak"] = true
					"song_trade_turn":
						combo_upgrades[combo_id]["has_song_material_rebate"] = true
					"china_unity_echo":
						combo_upgrades[combo_id]["has_china_cheat_restore"] = true
				result.current_effect = unique_preview
			else:
				combo_upgrades[combo_id]["has_burn"] = true
				result.current_effect = "解锁灼烧"
		5:
			var unique_preview = get_combo_unique_upgrade_preview(combo_id, 5)
			if unique_preview != "":
				match combo_id:
					"qin_tiger_push":
						combo_upgrades[combo_id]["has_qin_battle_armor"] = true
					"song_trade_turn":
						combo_upgrades[combo_id]["has_song_gold_bonus"] = true
					"china_unity_echo":
						combo_upgrades[combo_id]["has_china_attack_rally"] = true
				result.current_effect = unique_preview
			else:
				combo_upgrades[combo_id]["has_break_momentum"] = true
				result.current_effect = "解锁破势"
	return result

func grant_combo_event_upgrade(combo_id: String) -> Dictionary:
	var result := {"success": false, "cost": 0, "new_level": 0, "current_effect": "", "error": ""}
	if combo_id == "":
		result.error = "连招ID为空"
		return result
	var current_level = get_combo_upgrade_level(combo_id)
	if current_level >= 5:
		result.error = "已达满级"
		return result
	result = _apply_combo_upgrade_step(combo_id, current_level + 1)
	return result

func apply_combo_upgrade(combo_id: String, upgrade_type: String) -> Dictionary:
	"""应用连招强化，返回结果字典包含 success, cost, new_level"""
	var result = {"success": false, "cost": 0, "new_level": 0, "current_effect": ""}
	
	# 连招强化：前3级提升倍率，后2级解锁附加特效
	# 布局强化改为金币消费：保留材料字段仅用于旧存档兼容
	var current_level = 0
	var max_level = 5
	
	if combo_upgrades.has(combo_id):
		current_level = combo_upgrades[combo_id].get("level", 0)
	
	# 检查是否已满级
	if current_level >= max_level:
		result.error = "已达满级"
		return result
	
	var cost = get_combo_upgrade_gold_cost(current_level)
	if not spend_gold(cost):
		result.error = "金币不足"
		return result
	
	result = _apply_combo_upgrade_step(combo_id, current_level + 1)
	result.cost = cost
	return result

func get_combo_upgrade_level(combo_id: String) -> int:
	"""获取连招强化等级"""
	if combo_upgrades.has(combo_id):
		return combo_upgrades[combo_id].get("level", 0)
	return 0

func get_combo_upgrade_status_text(combo_id: String) -> String:
	var level = get_combo_upgrade_level(combo_id)
	if level <= 0:
		return ""
	var parts: Array[String] = ["Lv.%d" % level]
	for label in get_combo_unique_upgrade_labels(combo_id):
		parts.append(label)
	if has_combo_effect(combo_id, "burn"):
		parts.append("灼烧")
	if has_combo_effect(combo_id, "break_momentum"):
		parts.append("破势")
	return " [%s]" % " ".join(parts)

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

func get_life_armor_hp_bonus() -> int:
	return get_equipment_scaled_int("life_armor", 10)

func get_heart_mirror_shield_bonus() -> int:
	return get_equipment_scaled_int("heart_mirror", 4)

func get_wooden_shield_bonus() -> int:
	return get_equipment_scaled_int("wooden_shield", 5)

func get_heirloom_item_synergy_bonus(heirloom_id: String) -> int:
	if not has_heirloom(heirloom_id):
		return 0
	match heirloom_id:
		"shield_blade":
			return 1 if has_item("wooden_shield") or has_item("heart_mirror") or has_item("heart_armor") or has_item("thorn_armor") else 0
		"afterlife_lamp":
			return 1 if has_item("vampire_cross") or has_item("life_crystal") or has_item("life_armor") or has_item("soul_collector") else 0
		"broken_coin":
			return 1 if has_item("trade_ledger") or has_item("bounty_blade") or has_item("greedy_gloves") else 0
		"camp_banner":
			return 1 if has_item("tiger_tally") or has_item("unity_seal") else 0
		"blood_contract":
			return 1 if has_item("demon_blade") or has_item("blood_tyrant") or has_item("vampire_blade") or has_item("flesh_toxin") else 0
		"counter_sigil":
			return 1 if has_item("precision_guidance") or has_item("precision_auxiliary") or has_item("precision_calculation") else 0
	return 0

func get_total_equipment_level_bonus() -> float:
	"""兼容旧调用：装备强化不再提供全局伤害倍率。"""
	return 1.0

# ===== 局外升级系统 =====

func get_meta_upgrade_definitions() -> Array[Dictionary]:
	return [
		{"id": "supply_line", "category": "粮仓", "stage": 0, "name": "粮道", "costs": [3, 4, 5, 6], "max": 4, "desc": "出征前备足钱粮，每级开局金币+3。", "effects": ["开局金币 +3", "开局金币 +6", "开局金币 +9", "开局金币 +12"]},
		{"id": "base_hp", "category": "粮仓", "stage": 0, "name": "军帐", "costs": [4, 5, 6], "max": 3, "desc": "军帐更稳，每级开局命数上限+1。", "effects": ["开局命数 +1", "开局命数 +2", "开局命数 +3"]},
		{"id": "basic_combo_slot", "category": "演武场", "stage": 0, "name": "副阵位", "costs": [5], "max": 1, "desc": "开局布局槽从1个提升到2个。", "effects": ["开局布局槽 +1"]},
		{"id": "base_atk", "category": "军械库", "stage": 1, "name": "兵锋", "costs": [6, 8], "max": 2, "desc": "秦卷通关后开放，每级开局攻击+1。", "effects": ["开局攻击 +1", "开局攻击 +2"]},
		{"id": "backpack_expand", "category": "军械库", "stage": 1, "name": "行囊", "costs": [6], "max": 1, "desc": "秦卷通关后开放，背包格子+4。", "effects": ["背包格子 +4"]},
		{"id": "combo_cooldown", "category": "演武场", "stage": 1, "name": "调度", "costs": [8, 10], "max": 2, "desc": "秦卷通关后开放，每级布局冷却-1，最低1回合。", "effects": ["布局冷却 -1", "布局冷却 -2"]},
		{"id": "advanced_combo", "category": "演武场", "stage": 1, "name": "中军阵册", "costs": [10], "max": 1, "desc": "秦卷通关后开放，选择布局时解锁更强的中段布局。", "effects": ["解锁高级布局"]},
		{"id": "equipment_slot", "category": "军械库", "stage": 2, "name": "器架", "costs": [10], "max": 1, "desc": "宋卷通关后开放，装备栏+1。", "effects": ["装备栏 +1"]},
		{"id": "draw_protection", "category": "宗祠", "stage": 2, "name": "护行令", "costs": [12], "max": 1, "desc": "宋卷通关后开放，每局首次平局后，免疫下一次受到的伤害。", "effects": ["平局保护 1次"]},
		{"id": "ultimate_combo", "category": "宗祠", "stage": 2, "name": "终式残卷", "costs": [14], "max": 1, "desc": "宋卷通关后开放，选择布局时解锁更强的后段布局。", "effects": ["解锁终极布局"]},
		{"id": "new_character", "category": "宗祠", "stage": 2, "name": "异路来客", "costs": [16], "max": 1, "desc": "宋卷通关后开放，解锁新角色流浪者。", "effects": ["解锁流浪者"]},
	]

func get_meta_upgrade_total_cost() -> int:
	var total := 0
	for definition in get_meta_upgrade_definitions():
		for cost in _get_meta_upgrade_costs(definition):
			total += int(cost)
	return total

func _get_meta_upgrade_costs(definition: Dictionary) -> Array:
	if definition.has("costs") and definition.get("costs") is Array:
		return definition.get("costs", [])
	return [int(definition.get("cost", 0))]

func get_meta_upgrade_next_cost(upgrade_id: String) -> int:
	var definition = get_meta_upgrade_definition(upgrade_id)
	if definition.is_empty():
		return 0
	var costs := _get_meta_upgrade_costs(definition)
	if costs.is_empty():
		return 0
	var current_count = get_meta_upgrade_count(upgrade_id)
	if current_count >= costs.size():
		return int(costs[costs.size() - 1])
	return int(costs[current_count])

func has_era_first_clear(era_id: String) -> bool:
	return bool(era_first_clears.get(era_id, false))

func get_meta_upgrade_stage() -> int:
	if has_era_first_clear("qin") and has_era_first_clear("song"):
		return 2
	if has_era_first_clear("qin"):
		return 1
	return 0

func get_meta_upgrade_stage_text() -> String:
	match get_meta_upgrade_stage():
		0:
			return "基础筹备：粮仓与演武场先行"
		1:
			return "秦卷已通：开放军械库与中军阵册"
		_:
			return "宋卷已通：宗祠与全部筹备开放"

func get_meta_upgrade_unlock_text(stage: int) -> String:
	match stage:
		1:
			return "通关秦卷后开放"
		2:
			return "通关秦卷与宋卷后开放"
		_:
			return "已开放"

func is_meta_upgrade_unlocked(upgrade_id: String) -> bool:
	var definition = get_meta_upgrade_definition(upgrade_id)
	if definition.is_empty():
		return false
	return get_meta_upgrade_stage() >= int(definition.get("stage", 0))

func get_meta_upgrade_effect_text(upgrade_id: String, level: int) -> String:
	var definition = get_meta_upgrade_definition(upgrade_id)
	if definition.is_empty():
		return "无"
	var effects: Array = definition.get("effects", [])
	if effects.is_empty() or level <= 0:
		return "尚未筹备"
	var idx = clamp(level - 1, 0, effects.size() - 1)
	return str(effects[idx])

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
	if not is_meta_upgrade_unlocked(upgrade_id):
		return false
	var current_count = get_meta_upgrade_count(upgrade_id)
	if current_count >= int(definition.get("max", 1)):
		return false
	return memory_cores >= get_meta_upgrade_next_cost(upgrade_id)

func purchase_meta_upgrade(upgrade_id: String) -> Dictionary:
	var result = {"success": false, "error": "", "cost": 0}
	var definition = get_meta_upgrade_definition(upgrade_id)
	if definition.is_empty():
		result.error = "未知升级"
		return result
	if not can_purchase_meta_upgrade(upgrade_id):
		result.error = "传承点不足、未开放或已满级"
		return result
	var cost = get_meta_upgrade_next_cost(upgrade_id)
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
	DebugLog.log("[Meta] 获得传承点 +%d (%s)，当前: %d" % [gained, reason, memory_cores])
	save_progress()
	return gained

func get_era_legacy_boss_reward(era_id: String = selected_era_id) -> int:
	match era_id:
		"song":
			return 2
		"china":
			return 3
		_:
			return 1

func get_era_legacy_elite_reward(era_id: String = selected_era_id) -> int:
	match era_id:
		"china":
			return 2
		_:
			return 1

func get_era_legacy_layer_reward(completed_layer: int, era_id: String = selected_era_id) -> int:
	var layer_base: int = clamp(completed_layer, 1, 2) + 1
	match era_id:
		"song":
			return layer_base + 1
		"china":
			return layer_base + 2
		_:
			return layer_base

func get_era_legacy_clear_reward(era_id: String = selected_era_id) -> int:
	match era_id:
		"song":
			return 8
		"china":
			return 10
		_:
			return 6

func get_era_full_clear_legacy_estimate(era_id: String = selected_era_id) -> int:
	return (
		get_era_legacy_boss_reward(era_id) * MAJOR_LAYER_COUNT
		+ get_era_legacy_layer_reward(1, era_id)
		+ get_era_legacy_layer_reward(2, era_id)
		+ get_era_legacy_clear_reward(era_id)
	)

func get_meta_full_unlock_clear_estimates() -> Dictionary:
	var total_cost := get_meta_upgrade_total_cost()
	var qin_reward := get_era_full_clear_legacy_estimate("qin")
	var song_reward := get_era_full_clear_legacy_estimate("song")
	var china_reward := get_era_full_clear_legacy_estimate("china")
	return {
		"total_cost": total_cost,
		"qin_reward": qin_reward,
		"song_reward": song_reward,
		"china_reward": china_reward,
		"qin_clears": int(ceil(float(total_cost) / float(qin_reward))),
		"song_clears": int(ceil(float(total_cost) / float(song_reward))),
		"china_clears": int(ceil(float(total_cost) / float(china_reward))),
	}

func apply_meta_start_bonuses() -> void:
	var hp_bonus = get_meta_upgrade_count("base_hp") + get_meta_upgrade_count("all_stats") * 2
	var atk_bonus = get_meta_upgrade_count("base_atk") + get_meta_upgrade_count("all_stats")
	var shield_bonus = get_meta_upgrade_count("passive_shield") + get_meta_upgrade_count("all_stats")
	player_max_hp += hp_bonus
	player_hp = player_max_hp
	player_attack += atk_bonus
	player_shield += shield_bonus
	player_gold += get_meta_upgrade_count("supply_line") * 3
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
	
	# 计算金币消耗：等级锻造递增，品质/特效使用独立价格
	var upgrades_done = 0
	match upgrade_type:
		"level": upgrades_done = current_level
		"quality": upgrades_done = current_quality
		"special": upgrades_done = 1  # 特效只有一次
	
	var cost = get_equipment_upgrade_gold_cost(upgrade_type, upgrades_done)
	if not spend_gold(cost):
		result.error = "金币不足"
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
	if has_item("unity_seal"):
		base += 1
	return base + get_meta_upgrade_count("cheat_charge") + bonus_cheat_from_level

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
var _exclusive_combos_loaded: bool = false

func _apply_era_class_base_adjustments(class_id: int) -> void:
	match selected_era_id:
		"song":
			match class_id:
				0:
					player_max_hp += 1
					player_hp += 1
				2:
					player_gold += 8
				3:
					player_gold += 6
				4:
					player_max_hp += 1
					player_hp += 1
					player_attack += 1
		"china":
			match class_id:
				0:
					add_cheat_point()
				1:
					player_attack += 1
					add_cheat_point()
				2:
					player_gold += 12
				3:
					player_max_hp += 1
					player_hp += 1
					player_shield += 2
				4:
					add_cheat_point()
					player_shield += 1
		_:
			match class_id:
				0:
					player_max_hp += 1
					player_hp += 1
				1:
					player_attack += 1
				2:
					player_gold += 5
				3:
					player_shield += 2
				4:
					player_attack += 1

func _apply_era_class_ability_adjustments(class_id: int) -> void:
	match selected_era_id:
		"song":
			match class_id:
				0:
					resurrection_hp = int(ceil(float(player_max_hp) * 0.70))
				1:
					critical_damage_bonus += 25
				3:
					armor_regen = true
				4:
					critical_damage_bonus += 20
		"china":
			match class_id:
				0:
					resurrection_hp = int(ceil(float(player_max_hp) * 0.70))
				1:
					critical_damage_bonus += 25
				3:
					armor_regen = true
				4:
					critical_damage_bonus += 15
		_:
			match class_id:
				0:
					resurrection_hp = int(ceil(float(player_max_hp) * 0.70))
				1:
					critical_damage_bonus += 10
				3:
					armor_regen = true
				4:
					critical_damage_bonus += 10

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
	_apply_era_class_base_adjustments(class_id)
	
	# 加载专属连招
	exclusive_combos = player_class_script.get_class_combos(class_id)
	_exclusive_combos_loaded = true
	DebugLog.log("[Class] 选择职业: ", class_data["name"], ", 专属连招数: ", exclusive_combos.size())
	
	# 显示专属连招信息
	for combo in exclusive_combos:
		DebugLog.log("  - ", combo.display_name, ": ", combo_script.sequence_to_string(combo.sequence))

# 获取专属连招列表
func get_exclusive_combos() -> Array:
	_ensure_exclusive_combos_loaded()
	return exclusive_combos

# 检查是否有某个专属连招
func has_exclusive_combo(combo_id: String) -> bool:
	_ensure_exclusive_combos_loaded()
	for combo in exclusive_combos:
		if combo.combo_id == combo_id:
			return true
	return false

func _ensure_exclusive_combos_loaded() -> void:
	if _exclusive_combos_loaded:
		return
	var player_class_script = load("res://resources/player_class_data.gd")
	exclusive_combos = player_class_script.get_class_combos(player_class)
	_exclusive_combos_loaded = true

# 装备定义
const ITEMS: Dictionary = {
	# ===== 攻击类 =====
	"blood_tyrant": {
		"id": "blood_tyrant",
		"name": "吸血刀",
		"cost": 10,
		"rarity": "blue",
		"type": "attack",
		"description": "吸取造成伤害10%的命数"
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
		"cost": 50,
		"rarity": "red",
		"type": "attack", 
		"description": "每通过一场战斗攻击+1",
		"exclusive_combo": "bloodthirsty_slash"
	},
	"bounty_blade": {
		"id": "bounty_blade",
		"name": "赏金宽刃",
		"cost": 50,
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
	"vampire_blade": {
		"id": "vampire_blade",
		"name": "吸血鬼刀",
		"cost": 50,
		"rarity": "red",
		"type": "attack",
		"description": "吸血额外+20%"
	},
	"poison_coating": {
		"id": "poison_coating",
		"name": "淬毒",
		"cost": 10,
		"rarity": "blue",
		"type": "attack",
		"description": "敌我受伤时，敌方获得1层中毒"
	},
	"flesh_toxin": {
		"id": "flesh_toxin",
		"name": "血肉毒素",
		"cost": 50,
		"rarity": "red",
		"type": "attack",
		"description": "自身损失命数时，敌方获得等量中毒"
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
		"name": "命数水晶",
		"cost": 10,
		"rarity": "blue",
		"type": "defense",
		"description": "命数上限+6"
	},
	"life_armor": {
		"id": "life_armor",
		"name": "生命盔甲",
		"cost": 50,
		"rarity": "red",
		"type": "defense",
		"description": "命数上限+10"
	},
	"soul_collector": {
		"id": "soul_collector",
		"name": "魂魄收集者",
		"cost": 50,
		"rarity": "red",
		"type": "defense",
		"description": "每经历一场困难战斗，命数上限+10；生命三件套齐全时额外+5"
	},
	"heart_armor": {
		"id": "heart_armor",
		"name": "护心甲",
		"cost": 10,
		"rarity": "blue",
		"type": "defense",
		"description": "每回合开局获得2临时护甲；触发布局时获得1临时护甲"
	},
	"heart_mirror": {
		"id": "heart_mirror",
		"name": "护心镜",
		"cost": 10,
		"rarity": "blue",
		"type": "defense",
		"description": "战斗开始获得4护甲；敌人对护甲的伤害反弹给自己",
		"exclusive_combo": "reflect_aura"
	},
	"thorn_armor": {
		"id": "thorn_armor",
		"name": "反甲",
		"cost": 50,
		"rarity": "red",
		"type": "defense",
		"description": "护甲损失时，敌方损失等量命数"
	},
	"tiger_tally": {
		"id": "tiger_tally",
		"name": "虎符",
		"cost": 10,
		"rarity": "blue",
		"type": "special",
		"description": "战斗开始获得2护甲；有护甲时攻击+1；占势后命中追加1军令伤害",
		"era": "qin"
	},
	"vampire_cross": {
		"id": "vampire_cross",
		"name": "吸血鬼十字架",
		"cost": 50,
		"rarity": "red",
		"type": "defense",
		"description": "战斗命数恢复效果翻倍"
	},
	
	# ===== 特殊类 =====
	"precision_guidance": {
		"id": "precision_guidance",
		"name": "精确制导系统",
		"cost": 5,
		"rarity": "white",
		"type": "special",
		"description": "命数为1时，攻击+50%",
		"exclusive_combo": "absolute_hit"
	},
	"precision_auxiliary": {
		"id": "precision_auxiliary",
		"name": "精确辅助系统",
		"cost": 50,
		"rarity": "red",
		"type": "special",
		"description": "命数转护甲，每场战斗命数-1护甲+1",
		"exclusive_combo": "absolute_hit"
	},
	"precision_calculation": {
		"id": "precision_calculation",
		"name": "精确计算系统",
		"cost": 10,
		"rarity": "blue",
		"type": "special",
		"description": "命数为1时，暴击率+30%",
		"exclusive_combo": "absolute_hit"
	},
	"trade_ledger": {
		"id": "trade_ledger",
		"name": "市舶账册",
		"cost": 10,
		"rarity": "blue",
		"type": "special",
		"description": "进入营寨获得6金币；商队刷新额外-1金币；战斗中换势成功时最多2次获得2金币与1布势",
		"era": "song"
	},
	"flesh_talisman": {
		"id": "flesh_talisman",
		"name": "血肉符纸",
		"cost": 10,
		"rarity": "blue",
		"type": "special",
		"description": "触发布局时，使中毒者当前回合额外受到一次中毒伤害"
	},
	"plague_source": {
		"id": "plague_source",
		"name": "瘟疫之源",
		"cost": 50,
		"rarity": "red",
		"type": "special",
		"description": "触发布局时，使当前中毒层数翻倍"
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
	},
	"unity_seal": {
		"id": "unity_seal",
		"name": "山河印",
		"cost": 50,
		"rarity": "red",
		"type": "special",
		"description": "机括上限+1；战前获得1机括；使用机括时势轨+1，回环额外得甲；胜利后回1命",
		"era": "china"
	}
}

const HEIRLOOMS: Dictionary = {
	"shield_blade": {
		"id": "shield_blade",
		"name": "盾刃",
		"description": "战斗中获得护甲时，对敌造成护甲值一半伤害。每回合最多3次。装备木盾或护心镜时，盾刃伤害+1。"
	},
	"afterlife_lamp": {
		"id": "afterlife_lamp",
		"name": "余命灯",
		"description": "战斗中治疗溢出时，溢出命数转化为护甲；满血获得治疗时至少转化1护甲。装备吸血鬼十字架或命数水晶时，余命护甲+1。"
	},
	"broken_coin": {
		"id": "broken_coin",
		"name": "破财印",
		"description": "每花5金币，下一次命中附加1伤害。装备市舶账册、赏金宽刃或贪婪手套时，每次花钱额外蓄1，最多蓄14。"
	},
	"camp_banner": {
		"id": "camp_banner",
		"name": "连营旗",
		"description": "同一回合触发第二个布局时，额外追击3伤害。装备虎符或山河印时，追击+1。"
	},
	"blood_contract": {
		"id": "blood_contract",
		"name": "血契符",
		"description": "失去命数后，下一次命中附加等量伤害。装备妖刀或吸血刀时，每次受创额外蓄1，最多蓄10。"
	},
	"counter_sigil": {
		"id": "counter_sigil",
		"name": "反制令",
		"description": "打平时获得1护甲，并对敌造成1伤害。装备任一精确系统时，护甲与伤害各+1。"
	}
}

func get_heirloom_ids() -> Array[String]:
	var ids: Array[String] = []
	for heirloom_id in HEIRLOOMS.keys():
		ids.append(str(heirloom_id))
	return ids

func get_heirloom_data(heirloom_id: String) -> Dictionary:
	return HEIRLOOMS.get(heirloom_id, {})

func get_heirloom_short_effect(heirloom_id: String) -> String:
	match heirloom_id:
		"shield_blade":
			return "得甲反伤"
		"afterlife_lamp":
			return "溢疗成甲"
		"broken_coin":
			return "花钱蓄击"
		"camp_banner":
			return "二触追击"
		"blood_contract":
			return "失血蓄击"
		"counter_sigil":
			return "平局反制"
	return "场外入局"

func get_heirloom_synergy_text(heirloom_id: String) -> String:
	var active := get_heirloom_item_synergy_bonus(heirloom_id) > 0
	match heirloom_id:
		"shield_blade":
			return "联动：盾器已激活，盾刃伤害+1。" if active else "联动：木盾、护心镜、护心甲、荆棘甲可强化。"
		"afterlife_lamp":
			return "联动：命器已激活，余命护甲+1。" if active else "联动：吸血鬼十字架、命数水晶、命甲、魂匣可强化。"
		"broken_coin":
			return "联动：财器已激活，每次花钱额外蓄1。" if active else "联动：市舶账册、赏金宽刃、贪婪手套可强化。"
		"camp_banner":
			return "联动：军令已激活，连营追击+1。" if active else "联动：虎符、山河印可强化。"
		"blood_contract":
			return "联动：血器已激活，每次受创额外蓄1。" if active else "联动：妖刀、血暴君、吸血刀、血肉毒符可强化。"
		"counter_sigil":
			return "联动：精确系统已激活，反制护甲与伤害+1。" if active else "联动：任一精确系统可强化。"
	return ""

func get_heirloom_status_text(heirloom_id: String = selected_heirloom_id) -> String:
	if heirloom_id == "":
		return "未携带"
	match heirloom_id:
		"broken_coin":
			return "蓄势 %d/14" % field_pending_spend_attack
		"blood_contract":
			return "血势 %d/10" % field_pending_blood_attack
		"shield_blade":
			return "本回合得甲触发，最多3次"
		"afterlife_lamp":
			return "溢疗/满血治疗转护甲"
		"camp_banner":
			return "本回合第二个布局追击"
		"counter_sigil":
			return "平局得甲并反伤"
	return get_heirloom_short_effect(heirloom_id)

func get_heirloom_detail_text(heirloom_id: String = selected_heirloom_id) -> String:
	var data := get_heirloom_data(heirloom_id)
	if data.is_empty():
		return "未携带传家宝。"
	var lines: Array[String] = [
		"%s｜%s" % [str(data.get("name", "传家宝")), get_heirloom_short_effect(heirloom_id)],
		str(data.get("description", "")),
		get_heirloom_synergy_text(heirloom_id),
		"当前：%s" % get_heirloom_status_text(heirloom_id)
	]
	var filtered: Array[String] = []
	for line in lines:
		var text := line.strip_edges()
		if text != "":
			filtered.append(text)
	return "\n".join(filtered)

func select_heirloom(heirloom_id: String) -> bool:
	if not HEIRLOOMS.has(heirloom_id):
		return false
	selected_heirloom_id = heirloom_id
	field_pending_spend_attack = 0
	field_pending_blood_attack = 0
	return true

func has_heirloom(heirloom_id: String) -> bool:
	return selected_heirloom_id == heirloom_id

func commit_route_choice(route_name: String) -> bool:
	var route := route_name.strip_edges()
	if route == "" or selected_route_name != "":
		return false
	selected_route_name = route
	return true

func is_route_change(route_name: String) -> bool:
	var route := route_name.strip_edges()
	return selected_route_name != "" and route != "" and route != selected_route_name

func get_route_switch_cost_text() -> String:
	match route_switch_count:
		0:
			return "金币-10"
		1:
			return "金币-16"
		_:
			return "金币-24"

func try_switch_route(route_name: String) -> Dictionary:
	var route := route_name.strip_edges()
	if route == "":
		return {"ok": true, "message": ""}
	if selected_route_name == "":
		selected_route_name = route
		return {"ok": true, "message": "定线：%s" % selected_route_name}
	if route == selected_route_name:
		return {"ok": true, "message": ""}
	var old_route := selected_route_name
	var paid_text := ""
	match route_switch_count:
		0:
			if player_gold < 10:
				return {"ok": false, "message": "改道需要金币10。当前金币不足。"}
			spend_gold(10)
			paid_text = "金币-10"
		1:
			if player_gold < 16:
				return {"ok": false, "message": "二次改道需要金币16。当前金币不足。"}
			spend_gold(16)
			paid_text = "金币-16"
		_:
			if player_gold < 24:
				return {"ok": false, "message": "多次改道需要金币24。当前金币不足。"}
			spend_gold(24)
			paid_text = "金币-24"
	selected_route_name = route
	route_switch_count += 1
	EventBus.player_gold_changed.emit(player_gold)
	return {
		"ok": true,
		"message": "改道：%s → %s｜%s" % [old_route, selected_route_name, paid_text]
	}

func force_route_choice(route_name: String) -> bool:
	var route := route_name.strip_edges()
	if route == "":
		return false
	selected_route_name = route
	return true

func get_run_tendency_tags() -> Array[String]:
	var tags: Array[String] = []
	if player_shield >= 4 or selected_heirloom_id in ["shield_blade", "counter_sigil", "afterlife_lamp"] \
		or has_item_anywhere("wooden_shield") or has_item_anywhere("heart_mirror") \
		or has_item_anywhere("heart_armor") or has_item_anywhere("thorn_armor") \
		or has_item_anywhere("tiger_tally") or has_item_anywhere("vampire_cross"):
		tags.append("defense")
	if player_gold >= 15 or selected_heirloom_id == "broken_coin" \
		or has_item_anywhere("trade_ledger") or has_item_anywhere("greedy_gloves") \
		or has_item_anywhere("bounty_blade"):
		tags.append("economy")
	if player_attack >= 4 or selected_heirloom_id in ["camp_banner", "blood_contract"] \
		or has_item_anywhere("long_sword") or has_item_anywhere("demon_blade") \
		or has_item_anywhere("regicide") or has_item_anywhere("vampire_blade") \
		or has_item_anywhere("poison_coating") or has_item_anywhere("flesh_toxin"):
		tags.append("aggression")
	if player_hp <= maxi(2, int(ceil(float(player_max_hp) * 0.4))) \
		or selected_heirloom_id in ["afterlife_lamp", "blood_contract"] \
		or has_item_anywhere("blood_tyrant") or has_item_anywhere("vampire_blade") \
		or has_item_anywhere("life_crystal") or has_item_anywhere("life_armor") \
		or has_item_anywhere("soul_collector") \
		or has_item_anywhere("unity_seal"):
		tags.append("sustain")
	if selected_heirloom_id in ["counter_sigil", "camp_banner"] \
		or has_item_anywhere("precision_guidance") or has_item_anywhere("precision_calculation") \
		or has_item_anywhere("precision_auxiliary") or has_item_anywhere("ai_system") \
		or has_item_anywhere("flesh_talisman") or has_item_anywhere("plague_source"):
		tags.append("tempo")
	return tags

func get_run_tendency_strength() -> float:
	if current_floor >= 7:
		return 1.2
	if current_floor >= 4:
		return 1.12
	return 1.0

func register_enemy_personality(ai_type: int, ai_subtype: int) -> void:
	last_enemy_ai_type = ai_type
	last_enemy_ai_subtype = ai_subtype


func reset_game():
	player_hp = 6
	player_max_hp = 6
	player_attack = 2
	player_shield = 0
	player_gold = 0
	player_class = 0
	current_floor = 0
	max_floors = TOTAL_SMALL_FLOORS
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
	selected_heirloom_id = ""
	field_pending_spend_attack = 0
	field_pending_blood_attack = 0
	field_pending_merchant_attack = 0
	selected_route_name = ""
	route_switch_count = 0
	acknowledged_major_layer_debuffs.clear()
	last_enemy_ai_type = -1
	last_enemy_ai_subtype = -1
	player_level = 1
	player_exp = 0
	unspent_attribute_points = 0
	bonus_equipment_slots = 0
	bonus_backpack_slots = 0
	bonus_hp_from_level = 0
	bonus_atk_from_level = 0
	bonus_cheat_from_level = 0
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
		DebugLog.log("Backpack full! Max slots: ", get_current_backpack_limit())
		return false
	
	# 检查是否已存在（某些装备可能唯一）
	if item_id in ["ai_system"] and has_in_backpack(item_id):
		return false
	
	backpack.append(item.duplicate())
	record_item_discovery(item_id)
	DebugLog.log("Added to backpack: ", item.name)
	return true

# ===== 装备效果系统 =====

func _apply_item_effect(item_id: String) -> void:
	"""装备时生效的效果"""
	match item_id:
		"life_crystal":
			var hp_bonus = get_life_crystal_hp_bonus()
			player_max_hp += hp_bonus
			player_hp += hp_bonus  # 同时恢复命数
			DebugLog.log("[Equip] 命数水晶: 命数上限+", hp_bonus, "，恢复", hp_bonus, "命")
		"life_armor":
			var hp_bonus = get_life_armor_hp_bonus()
			player_max_hp += hp_bonus
			player_hp += hp_bonus
			DebugLog.log("[Equip] 生命盔甲: 命数上限+", hp_bonus, "，恢复", hp_bonus, "命")
		"wooden_shield":
			var shield_bonus = get_wooden_shield_bonus()
			player_shield += shield_bonus
			DebugLog.log("[Equip] 木盾: 获得", shield_bonus, "护甲")

func _remove_item_effect(item_id: String) -> void:
	"""卸下时移除的效果"""
	match item_id:
		"life_crystal":
			var hp_bonus = get_life_crystal_hp_bonus()
			player_max_hp = maxi(player_max_hp - hp_bonus, 1)
			player_hp = mini(player_hp, player_max_hp)
			DebugLog.log("[Equip] 卸下命数水晶: 命数上限-", hp_bonus)
		"life_armor":
			var hp_bonus = get_life_armor_hp_bonus()
			player_max_hp = maxi(player_max_hp - hp_bonus, 1)
			player_hp = mini(player_hp, player_max_hp)
			DebugLog.log("[Equip] 卸下生命盔甲: 命数上限-", hp_bonus)
		"wooden_shield":
			var shield_bonus = get_wooden_shield_bonus()
			player_shield = maxi(player_shield - shield_bonus, 0)
			DebugLog.log("[Equip] 卸下木盾: 移除", shield_bonus, "护甲")

func add_to_equipment_slot(item_id: String):
	"""直接添加物品到装备栏"""
	var item = ITEMS.get(item_id)
	if not item:
		return false
	
	# 检查装备栏是否已满
	if equipment_slot.size() >= get_current_equipment_slot_limit():
		DebugLog.log("Equipment slot full! Max slots: ", get_current_equipment_slot_limit())
		return false
	
	# 检查是否已存在
	if item_id in ["ai_system"] and has_item(item_id):
		return false
	
	equipment_slot.append(item.duplicate())
	_apply_item_effect(item_id)
	record_item_discovery(item_id)
	DebugLog.log("Added to equipment slot: ", item.name)
	return true

func remove_from_backpack(index: int):
	"""从背包移除物品"""
	if index < 0 or index >= backpack.size():
		return {}
	
	var item = backpack[index]
	backpack.remove_at(index)
	DebugLog.log("Removed from backpack: ", item.name)
	return item

func remove_from_equipment_slot(index: int):
	"""从装备栏移除物品"""
	if index < 0 or index >= equipment_slot.size():
		return {}
	
	var item = equipment_slot[index]
	equipment_slot.remove_at(index)
	_remove_item_effect(item.id)
	DebugLog.log("Removed from equipment slot: ", item.name)
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
	
	DebugLog.log("Sold item: ", item.name, " for ", sell_price, " gold")
	EventBus.player_gold_changed.emit(player_gold)
	return true

# ===== 装备栏系统 =====

func equip_from_backpack(backpack_index: int) -> bool:
	"""从背包移动物品到装备栏"""
	if backpack_index < 0 or backpack_index >= backpack.size():
		return false
	
	# 检查装备栏是否已满
	if equipment_slot.size() >= get_current_equipment_slot_limit():
		DebugLog.log("Equipment slot full! Cannot equip.")
		return false
	
	var item = backpack[backpack_index]
	
	# 某些装备可能是唯一的，不能重复装备
	if item.id in ["ai_system"] and has_item(item.id):
		return false
	
	equipment_slot.append(item.duplicate())
	backpack.remove_at(backpack_index)
	_apply_item_effect(item.id)
	record_item_discovery(item.id)
	DebugLog.log("Equipped: ", item.name)
	return true

func unequip_to_backpack(equipment_index: int) -> bool:
	"""从装备栏卸下物品到背包"""
	if equipment_index < 0 or equipment_index >= equipment_slot.size():
		return false
	
	# 检查背包是否已满
	if backpack.size() >= get_current_backpack_limit():
		DebugLog.log("Backpack full! Cannot unequip.")
		return false
	
	var item = equipment_slot[equipment_index]
	backpack.append(item.duplicate())
	equipment_slot.remove_at(equipment_index)
	_remove_item_effect(item.id)
	DebugLog.log("Unequipped to backpack: ", item.name)
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
	DebugLog.log("Swapped: ", equip_item.name, " <-> ", backpack_item.name)
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
	
	DebugLog.log("[Swap] 装备交换: ", equip_item.name, " <-> ", backpack_item.name)
	return true

func unequip_all_after_battle():
	"""战斗结束后卸下所有装备（如果需要）"""
	# 精确辅助系统战后效果 - 只有在装备栏时才生效
	if has_item("precision_auxiliary"):
		if player_hp > 1:
			var shield_gain = get_equipment_scaled_int("precision_auxiliary", 1)
			player_hp -= 1
			player_shield += shield_gain
			DebugLog.log("Precision Auxiliary: Post-battle HP-1, Shield+", shield_gain)

	if not shield_persists_between_battles():
		player_shield = 0
	else:
		var trimmed := clamp_farmer_shield_carryover()
		if trimmed > 0:
			DebugLog.log("[Class] 农民垒势封顶，战后护甲收束-", trimmed)
	
	# 注意：不再在战斗后自动清空装备栏！
	# 装备应该持久保存，只在休息点选择"清空装备栏"时才清空
	# equipment_slot.clear()  # 已移除，装备应该持久存在

func setup_pre_battle():
	"""战斗开始前准备"""
	reset_combo_energy()
	if selected_era_id == "china":
		add_combo_energy(1)
	if has_heirloom("afterlife_lamp") and player_hp >= player_max_hp:
		player_shield += 1 + get_heirloom_item_synergy_bonus("afterlife_lamp")
	if player_class == 2:
		var merchant_shield := mini(int(player_gold / 10), 3)
		if merchant_shield > 0:
			player_shield += merchant_shield
			DebugLog.log("[Class] 商人辎重护身：持币护甲+", merchant_shield)
	if has_item("tiger_tally"):
		player_shield += get_equipment_scaled_int("tiger_tally", 2)
	if has_item("heart_mirror"):
		player_shield += get_heart_mirror_shield_bonus()
	if has_item("unity_seal"):
		add_cheat_point()
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
		DebugLog.log("Precision Auxiliary (pre-battle): Converted ", convert_amount, " HP to shield ", shield_gain)

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
	
	# 虎符：有护甲时攻击+1
	if has_item("tiger_tally") and player_shield > 0:
		total += get_equipment_scaled_int("tiger_tally", 1)

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
		DebugLog.log("Precision Guidance active: attack x", bonus)
	
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
		DebugLog.log("Precision Calculation active")

	# 随机事件提供的暴击加成，单位为每层 20%
	chance += RandomEventManager.get_crit_bonus() * 0.2
	
	return min(chance, 0.95)

# 生命偷取
func get_life_steal(damage: int):
	var rate := 0.0
	if has_item("blood_tyrant"):
		rate += 0.1 * get_equipment_effect_multiplier("blood_tyrant")
	if has_item("vampire_blade"):
		rate += 0.2 * get_equipment_effect_multiplier("vampire_blade")
	if rate <= 0.0:
		return 0
	return maxi(1, int(damage * rate))

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

func has_thorn_armor() -> bool:
	return has_item("thorn_armor")

func get_thorn_armor_multiplier() -> float:
	if has_item("thorn_armor"):
		return get_equipment_effect_multiplier("thorn_armor")
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
	var bonus := float(gold_bonus_percent) / 100.0
	if has_item("greedy_gloves"):
		bonus += 0.5 * get_equipment_effect_multiplier("greedy_gloves")
	return bonus

func get_gold_reward_multiplier() -> float:
	return 1.0 + get_gold_bonus()

func register_gold_spent_for_field(amount: int) -> int:
	if amount <= 0:
		return 0
	var broken_bonus := 0
	if has_heirloom("broken_coin"):
		broken_bonus = maxi(1, int(floor(float(amount) / 5.0)))
		broken_bonus += get_heirloom_item_synergy_bonus("broken_coin")
		field_pending_spend_attack = mini(field_pending_spend_attack + broken_bonus, 14)
		DebugLog.log("[Field] 破财印蓄势 +", broken_bonus, " 当前 ", field_pending_spend_attack)
	if player_class == 2:
		var merchant_bonus := int(floor(float(amount) / 10.0))
		if merchant_bonus > 0:
			field_pending_merchant_attack = mini(field_pending_merchant_attack + merchant_bonus, 6)
			DebugLog.log("[Class] 商人花钱滚利 +", merchant_bonus, " 当前 ", field_pending_merchant_attack)
	return broken_bonus

func grant_blood_contract_bonus(amount: int) -> int:
	if amount <= 0 or not has_heirloom("blood_contract"):
		return 0
	var bonus := mini(amount + get_heirloom_item_synergy_bonus("blood_contract"), 10)
	field_pending_blood_attack = mini(field_pending_blood_attack + bonus, 10)
	DebugLog.log("[Field] 血契符蓄势 +", bonus, " 当前 ", field_pending_blood_attack)
	return bonus

func consume_field_attack_bonus() -> Dictionary:
	var spend_bonus := field_pending_spend_attack
	var blood_bonus := field_pending_blood_attack
	var merchant_bonus := field_pending_merchant_attack
	var spend_break := spend_bonus >= 8 and get_heirloom_item_synergy_bonus("broken_coin") > 0
	var blood_break := blood_bonus >= 6 and get_heirloom_item_synergy_bonus("blood_contract") > 0
	if spend_break:
		spend_bonus += 2
	if blood_break:
		blood_bonus += 1
	field_pending_spend_attack = 0
	field_pending_blood_attack = 0
	field_pending_merchant_attack = 0
	return {
		"total": spend_bonus + blood_bonus + merchant_bonus,
		"spend": spend_bonus,
		"blood": blood_bonus,
		"merchant": merchant_bonus,
		"spend_break": spend_break,
		"blood_break": blood_break
	}

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
		DebugLog.log("AI System active! Precision effects +50%")
		return true
	
	return false

# 记录战斗胜利
func on_battle_won():
	item_battle_wins += 1
	precision_battle_count += 1
	if has_item("unity_seal"):
		player_hp = mini(player_hp + get_equipment_scaled_int("unity_seal", 1), player_max_hp)
	match selected_era_id:
		"song":
			if player_class == 0:
				player_hp = mini(player_hp + 1, player_max_hp)
			elif player_class == 1:
				player_gold += 5
				EventBus.player_gold_changed.emit(player_gold)
		"china":
			if player_class == 0:
				player_hp = mini(player_hp + 1, player_max_hp)
				add_cheat_point()
			elif player_class == 4:
				add_cheat_point()
		_:
			if player_class == 0:
				player_hp = mini(player_hp + 1, player_max_hp)
			elif player_class == 1:
				add_cheat_point()
			elif player_class == 3:
				player_shield += 1

func has_life_set() -> bool:
	return has_item("life_crystal") and has_item("life_armor") and has_item("soul_collector")

func on_difficult_battle_won() -> int:
	if not has_item("soul_collector"):
		return 0
	var hp_gain := get_equipment_scaled_int("soul_collector", 10)
	if has_life_set():
		hp_gain += get_equipment_scaled_int("soul_collector", 5)
	player_max_hp += hp_gain
	player_hp += hp_gain
	DebugLog.log("[Equip] 魂魄收集者: 困难战斗后命数上限+", hp_gain)
	return hp_gain

# ===== 连招系统函数 =====

# 装备连招
func equip_combo(combo_id: String) -> bool:
	if equipped_combos.size() >= max_combo_slots:
		DebugLog.log("[Combo] Cannot equip, slots full")
		return false
	
	if combo_id in equipped_combos:
		DebugLog.log("[Combo] Already equipped")
		return false
	
	equipped_combos.append(combo_id)
	DebugLog.log("[Combo] Equipped: ", combo_id)
	return true

# 卸下连招
func unequip_combo(combo_id: String) -> bool:
	if not combo_id in equipped_combos:
		return false
	
	equipped_combos.erase(combo_id)
	DebugLog.log("[Combo] Unequipped: ", combo_id)
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
	DebugLog.log("[Combo] Triggered: ", combo_id, " cooldown: ", final_cooldown)

# 每回合减少冷却
func reduce_cooldowns():
	for combo_id in combo_cooldowns.keys():
		if combo_cooldowns[combo_id] > 0:
			combo_cooldowns[combo_id] -= 1
			if combo_cooldowns[combo_id] == 0:
				combo_cooldowns.erase(combo_id)
				DebugLog.log("[Combo] Cooldown ready: ", combo_id)

# 应用连招增益
func apply_combo_buff(buff_type: String, value: int, duration: int):
	combo_buffs[buff_type] = {"value": value, "duration": duration}
	DebugLog.log("[Combo] Buff applied: ", buff_type, " = ", value, " for ", duration, " turns")

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
		DebugLog.log("[Combo] Buff expired: ", buff_type)

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
			resurrection_hp = int(ceil(float(player_max_hp) * 0.70))
			DebugLog.log("[Class] 医生：复起已就绪，本局可恢复七成命数并获得护甲")
		
		1:  # 黑客
			critical_damage_bonus = 50
			cheat_points = maxi(cheat_points, 1)
			DebugLog.log("[Class] 黑客：机巧密算，机括点数+1，上限", get_max_cheat_points())
		
		2:  # 商人
			gold_bonus_percent = 20
			DebugLog.log("[Class] 商人：辎重滚利，持币得甲，花钱蓄击")
		
		3:  # 农民
			armor_regen = true
			player_shield += 1
			DebugLog.log("[Class] 农民：种因得果，护甲+1，护甲可叠加并带入下一场战斗")
		4:
			DebugLog.log("[Class] 流浪者：异路同归，使用独立基础布局组")
	_apply_era_class_ability_adjustments(class_id)

func on_enter_rest_point() -> bool:
	if has_item("trade_ledger"):
		player_gold += 6
		EventBus.player_gold_changed.emit(player_gold)
	if player_class != 2:
		return false
	if last_rest_income_floor == current_floor:
		return false
	last_rest_income_floor = current_floor
	var rest_income = 16
	match selected_era_id:
		"song":
			rest_income = 20
		"china":
			rest_income = 18
		_:
			rest_income = 16
	player_gold += rest_income
	DebugLog.log("[Class] 商人睡后收入：进入休息点获得%d金币" % rest_income)
	return true

func is_item_allowed_in_current_era(item: Dictionary) -> bool:
	var era = str(item.get("era", ""))
	return era == "" or era == selected_era_id

# 检查是否触发复活
func try_resurrection() -> bool:
	if has_resurrection and not resurrection_used and player_hp <= 0:
		resurrection_used = true
		var restore_hp = clamp(maxi(resurrection_hp, int(ceil(float(player_max_hp) * 0.70))), 1, player_max_hp)
		player_hp = restore_hp
		player_shield += 2
		DebugLog.log("[Resurrection] 医生复起！恢复命数", restore_hp, "，护甲+2")
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
	
	DebugLog.log("[Damage] 受到", incoming_damage, "伤害, 护盾吸收", result.shield_absorbed,
		", 实际伤害", result.actual_damage, ", 剩余护盾", player_shield, ", 剩余生命", player_hp)
	
	return result

# 添加护盾
func add_shield(amount: int):
	player_shield += amount
	DebugLog.log("[Shield] 获得", amount, "护盾, 当前", player_shield)

# 减少护盾（直接减少，不扣血）
func reduce_shield(amount: int):
	player_shield = maxi(player_shield - amount, 0)
	DebugLog.log("[Shield] 减少", amount, "护盾, 当前", player_shield)

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
	var advanced_text = "已解锁" if has_combo_tier_unlocked(1) else "行前筹备解锁（秦通后，10传承点）"
	var ultimate_text = "已解锁" if has_combo_tier_unlocked(2) else "行前筹备解锁（宋通后，14传承点）"
	return "高级布局: %s | 终极布局: %s" % [advanced_text, ultimate_text]

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
	var item_ids: Array[String] = []
	var class_display_name = "未知职业"
	if player_class >= 0 and player_class < class_names.size():
		class_display_name = class_names[player_class]
	for item in equipment_slot:
		item_ids.append(str(item.get("id", "")))
	
	return {
		"class_name": class_display_name,
		"floor_reached": mini(current_floor, max_floors - 1) + 1,
		"gold": player_gold,
		"materials": materials,
		"legacy_points": memory_cores,
		"hp": player_hp,
		"max_hp": player_max_hp,
		"attack": player_attack,
		"equipped_combos": equipped_combos.duplicate(),
		"equipment_ids": item_ids
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

func record_era_first_clear(era_id: String) -> void:
	if era_id == "":
		return
	if not bool(era_first_clears.get(era_id, false)):
		era_first_clears[era_id] = true
		_evaluate_achievements()

func _unlock_achievement(achievement_id: String) -> void:
	if unlocked_achievements.has(achievement_id):
		return
	unlocked_achievements.append(achievement_id)
	DebugLog.log("[Achievement] Unlocked: ", achievement_id)

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
	if has_era_first_clear("qin") and has_era_first_clear("song"):
		_unlock_achievement("logistics_complete")

func get_achievement_definitions() -> Array[Dictionary]:
	return [
		{"id": "reach_floor_6", "name": "初窥门径", "desc": "历史最高到达第6层"},
		{"id": "first_victory", "name": "塔顶来客", "desc": "首次完成通关"},
		{"id": "triple_crown", "name": "三冠挑战", "desc": "累计通关3次"},
		{"id": "collector", "name": "收藏癖", "desc": "累计发现5种装备"},
		{"id": "event_hunter", "name": "命运观测者", "desc": "累计遭遇6种不同事件"},
		{"id": "all_classes_clear", "name": "四相归一", "desc": "四个职业都完成首通"},
		{"id": "logistics_complete", "name": "粮草先行", "desc": "通关秦卷与宋卷，开放全部行前筹备"}
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
			"era_first_clears": era_first_clears.duplicate(true),
			"meta_upgrade_stage": get_meta_upgrade_stage(),
			"meta_upgrade_stage_text": get_meta_upgrade_stage_text(),
			"discovered_item_count": discovered_items.size(),
		"total_item_count": all_items.size(),
		"discovered_event_count": discovered_events.size(),
		"achievement_count": unlocked_achievements.size(),
		"total_achievement_count": get_achievement_definitions().size(),
		"selected_era_id": selected_era_id,
		"selected_era_name": get_current_era_definition().get("name", "秦")
	}

func get_era_definitions() -> Array[Dictionary]:
	return [
		{
			"id": "qin",
			"name": "秦",
			"title": "赳赳老秦",
			"summary": "直接、强压、简单",
			"buff_name": "军功授爵",
			"buff_desc": "连胜与速胜收益更高，鼓励前期果断出手。",
			"debuff_name": "法令森严",
			"debuff_desc": "商路紧缩，行商让利偏少，容错略低。",
			"playstyle": "偏人地，适合快攻、硬抗、速决。",
			"boss_rule": "Boss 机制直接，高攻击、低花招，压迫感明确。",
			"ui_note": "黑甲、青铜、朱印、军令。"
		},
		{
			"id": "song",
			"name": "宋",
			"title": "市易繁荣",
			"summary": "运营、经济、偏弱军力",
			"buff_name": "市易繁荣",
			"buff_desc": "商店与制造收益更优，器物和资源构筑更顺滑。",
			"debuff_name": "积贫积弱",
			"debuff_desc": "后期敌方攻势更强，纯正面硬拼更吃亏。",
			"playstyle": "偏天地，适合运营、反制、资源换回合。",
			"boss_rule": "Boss 擅长持续施压与破甲，逼迫玩家经营战局。",
			"ui_note": "绢纸、墨线、铜钱、城防图。"
		},
		{
			"id": "china",
			"name": "中国",
			"title": "百代共卷",
			"summary": "复杂、复合、终局",
			"buff_name": "薪火不灭",
			"buff_desc": "构筑空间最完整，布局、器物、被动联动上限最高。",
			"debuff_name": "百代之重",
			"debuff_desc": "敌人会叠加并切换多重时代规则，终局压力最大。",
			"playstyle": "天地人并重，要求真正理解布局节奏。",
			"boss_rule": "Boss 多阶段切换时代逻辑，兼具强压、运营反制与复合机制。",
			"ui_note": "山河、龙脉、星图、铜鼎、残卷合一。"
		}
	]

func get_era_definition(era_id: String) -> Dictionary:
	for era in get_era_definitions():
		if str(era.get("id", "")) == era_id:
			return era
	return get_era_definitions()[0]

func get_current_era_definition() -> Dictionary:
	return get_era_definition(selected_era_id)

func set_selected_era(era_id: String) -> void:
	selected_era_id = str(get_era_definition(era_id).get("id", "qin"))
	save_progress()

func get_current_era_status_text() -> String:
	var era = get_current_era_definition()
	return "时代卷：%s [%s]" % [era.get("name", "秦"), era.get("summary", "")]

func get_era_price_multiplier() -> float:
	match selected_era_id:
		"qin":
			return 1.10
		"song":
			return 0.85
		"china":
			return 1.00
		_:
			return 1.0

func get_era_refresh_cost(base_cost: int) -> int:
	match selected_era_id:
		"song":
			return maxi(base_cost - 1, 1)
		"china":
			return base_cost + 1
		_:
			return base_cost

func get_era_gold_reward_multiplier() -> float:
	match selected_era_id:
		"qin":
			return 1.25
		"song":
			return 1.05
		_:
			return 1.0

func get_era_material_bonus(is_boss: bool, battle_type: String) -> int:
	if selected_era_id != "song":
		return 0
	if is_boss:
		return 1
	if battle_type == "elite":
		return 1
	return 0

func get_era_enemy_hp_bonus(floor_num: int, is_boss: bool) -> int:
	var layer := get_major_layer_index(floor_num)
	match selected_era_id:
		"qin":
			return -3 if is_boss else -1
		"china":
			return 4 if is_boss else (1 if layer >= 1 else 0)
		_:
			return 0

func get_era_enemy_atk_bonus(floor_num: int, is_boss: bool) -> int:
	var layer := get_major_layer_index(floor_num)
	match selected_era_id:
		"song":
			return 1 if is_boss or layer >= 1 else 0
		"china":
			return 2 if is_boss else (1 if layer >= 1 else 0)
		_:
			return 0

func get_era_boss_phase_ratio() -> float:
	return 0.60 if selected_era_id == "china" else 0.50

func get_era_boss_phase_text() -> String:
	match selected_era_id:
		"china":
			return "💀 终局之敌提前显形！百代规则开始叠加。"
		"song":
			return "💀 敌军转入疲兵压阵！防线会被持续施压。"
		_:
			return "💀 BOSS进入最终形态！将100%克制你的出招！"

func get_era_boss_name() -> String:
	match selected_era_id:
		"song":
			return "靖康遗影"
		"china":
			return "百代共主"
		_:
			return "赳秦战主"

func get_era_boss_intro() -> String:
	match selected_era_id:
		"song":
			return "以守代攻，久耗取胜。"
		"china":
			return "百代兴亡尽归一敌。"
		_:
			return "军令如山，速决压境。"

func get_era_event_weight_multiplier(event_id: String, is_good: bool) -> float:
	match selected_era_id:
		"qin":
			if is_good:
				if event_id in ["attack_blessing", "shield_blessing", "armory_gift", "qin_merit_grant"]:
					return 1.35
				if event_id in ["shop_discount_duel", "gold_cache"]:
					return 0.75
			else:
				if event_id in ["gold_loss", "material_leak", "qin_harsh_law"]:
					return 1.15
		"song":
			if is_good:
				if event_id in ["gold_cache", "shop_discount_duel", "scrap_cache", "song_market_boom"]:
					return 1.45
				if event_id in ["attack_blessing", "shield_blessing"]:
					return 0.8
			else:
				if event_id in ["skill_lock", "armor_crack", "song_border_alarm"]:
					return 1.2
		"china":
			if is_good:
				if event_id in ["armory_gift", "combo_slot", "cheat_console", "china_dragon_vein"]:
					return 1.2
			else:
				if event_id in ["equip_loss_duel", "skill_lock", "combo_slot_loss", "brittle_bones", "china_old_debt"]:
					return 1.35
	return 1.0

func get_era_event_name_prefix() -> String:
	match selected_era_id:
		"song":
			return "【宋】"
		"china":
			return "【中国】"
		_:
			return "【秦】"

func get_era_theme() -> Dictionary:
	match selected_era_id:
		"song":
			return {
				"bg": Color(0.11, 0.13, 0.16, 1.0),
				"panel": Color(0.16, 0.18, 0.22, 0.9),
				"accent": Color(0.78, 0.86, 0.96, 1.0),
				"title": Color(0.92, 0.92, 0.78, 1.0),
				"good": Color(0.45, 0.82, 0.62, 1.0),
				"bad": Color(0.88, 0.54, 0.42, 1.0)
			}
		"china":
			return {
				"bg": Color(0.08, 0.09, 0.12, 1.0),
				"panel": Color(0.17, 0.14, 0.12, 0.92),
				"accent": Color(0.88, 0.72, 0.36, 1.0),
				"title": Color(0.95, 0.88, 0.72, 1.0),
				"good": Color(0.62, 0.86, 0.72, 1.0),
				"bad": Color(0.90, 0.42, 0.38, 1.0)
			}
		_:
			return {
				"bg": Color(0.12, 0.11, 0.10, 1.0),
				"panel": Color(0.20, 0.16, 0.12, 0.9),
				"accent": Color(0.84, 0.68, 0.38, 1.0),
				"title": Color(0.94, 0.84, 0.66, 1.0),
				"good": Color(0.66, 0.88, 0.56, 1.0),
				"bad": Color(0.86, 0.44, 0.36, 1.0)
			}

func get_era_menu_subtitle() -> String:
	match selected_era_id:
		"song":
			return "市易繁荣，积弱难安"
		"china":
			return "百代兴亡，一卷归一"
		_:
			return "军令如山，开疆定鼎"

func get_era_menu_banner() -> String:
	match selected_era_id:
		"song":
			return "市舶司印"
		"china":
			return "山河共卷"
		_:
			return "黑甲军令"

func get_era_boss_skill_name() -> String:
	match selected_era_id:
		"song":
			return "守势延压"
		"china":
			return "百代叠律"
		_:
			return "军令压阵"

func get_era_boss_skill_desc() -> String:
	match selected_era_id:
		"song":
			return "二阶段后持续拖慢你的节奏，逼你在消耗中失误。"
		"china":
			return "二阶段更早降临，并叠加终局级强压。"
		_:
			return "二阶段维持强压与直接克制，要求速决。"

func get_era_item_name(item_name: String) -> String:
	var qin_map := {
		"鲜血暴君": "血战军玺",
		"长剑": "秦军长剑",
		"妖刀": "斩将妖锋",
		"赏金宽刃": "军功宽刃",
		"弑君者": "诛王短兵",
		"木盾": "军阵木盾",
		"命数水晶": "续命玉魄",
		"护心镜": "玄甲心镜",
		"虎符": "军令虎符",
		"吸血鬼十字架": "猩红战契",
		"精确制导系统": "定锋机括",
		"精确辅助系统": "辅战机括",
		"精确计算系统": "算筹机括",
		"AI系统": "军机总枢",
		"识图者的笔记": "行军图志",
		"贪婪手套": "夺财手套"
	}
	var song_map := {
		"鲜血暴君": "赤帑血玺",
		"长剑": "禁军长剑",
		"妖刀": "夜行斩锋",
		"赏金宽刃": "市赏宽刃",
		"弑君者": "破阙短兵",
		"木盾": "城防木盾",
		"命数水晶": "养生玉晶",
		"护心镜": "照心铜镜",
		"市舶账册": "市舶总账",
		"吸血鬼十字架": "血契十字",
		"精确制导系统": "机巧导引仪",
		"精确辅助系统": "机巧辅战仪",
		"精确计算系统": "机巧筹算仪",
		"AI系统": "百工总枢",
		"识图者的笔记": "舆图手札",
		"贪婪手套": "聚敛手套"
	}
	var china_map := {
		"鲜血暴君": "赤旗血玺",
		"长剑": "复兴长锋",
		"妖刀": "裂界妖锋",
		"赏金宽刃": "山河宽刃",
		"弑君者": "终局诛锋",
		"木盾": "长城木盾",
		"命数水晶": "薪火晶核",
		"护心镜": "山河心镜",
		"山河印": "薪火山河印",
		"吸血鬼十字架": "旧债血契",
		"精确制导系统": "星火导引仪",
		"精确辅助系统": "星火辅战仪",
		"精确计算系统": "星图筹算仪",
		"AI系统": "百代总枢",
		"识图者的笔记": "山河图卷",
		"贪婪手套": "逐利手套"
	}
	match selected_era_id:
		"song":
			return str(song_map.get(item_name, item_name))
		"china":
			return str(china_map.get(item_name, item_name))
		_:
			return str(qin_map.get(item_name, item_name))

func get_era_item_description(item_description: String) -> String:
	match selected_era_id:
		"song":
			return "%s 适合经营、市易与稳守局。" % item_description
		"china":
			return "%s 终局压强更高，越到后段越关键。" % item_description
		_:
			return "%s 适合速战压阵与直接破局。" % item_description

func get_era_item_bonus_text(item: Dictionary) -> String:
	var item_id = str(item.get("id", ""))
	var item_type = str(item.get("type", ""))
	match selected_era_id:
		"song":
			if item_id == "trade_ledger":
				return "宋卷专属：路线收益更高，战斗中换势可入账，适合市易、工造与滚雪球。"
			if item_type in ["defense", "special"]:
				return "宋卷偏置：此器物更适合稳守、工造与资源换回合。"
			if item_id in ["greedy_gloves", "bounty_blade", "explorer_notes"]:
				return "宋卷偏置：此器物更适合经营路线，收益兑现更顺滑。"
		"china":
			if item_id == "unity_seal":
				return "终局专属：抬高机括上限，机括能推动势轨，适合高压复合构筑。"
			if item_type in ["special", "attack"]:
				return "终局偏置：此器物在高压长战中更关键。"
			if item_id in ["precision_auxiliary", "ai_system", "regicide", "demon_blade"]:
				return "终局偏置：此器物更适合终局压强与复合构筑。"
		_:
			if item_id == "tiger_tally":
				return "秦卷专属：开局立甲、持甲增锋，占势命中会追加军令伤害。"
			if item_type in ["attack", "special"]:
				return "秦卷偏置：此器物更适合速战压阵与正面破局。"
			if item_id in ["long_sword", "wooden_shield", "regicide"]:
				return "秦卷偏置：此器物更适合前中段直接决胜。"
	return "当前时代无额外器物偏置。"

func is_era_item(item: Dictionary) -> bool:
	return str(item.get("era", "")) != ""

func get_item_source_text(item: Dictionary) -> String:
	var item_id = str(item.get("id", ""))
	match item_id:
		"tiger_tally":
			return "来源：秦卷商队与器物池独有。"
		"trade_ledger":
			return "来源：宋卷商队与器物池独有。"
		"unity_seal":
			return "来源：中国卷商队与器物池独有。"
		_:
			return ""

func get_era_item_badge_text(item: Dictionary) -> String:
	var era_id = str(item.get("era", ""))
	match era_id:
		"qin":
			return "〔秦秘〕"
		"song":
			return "〔宋秘〕"
		"china":
			return "〔终局〕"
		_:
			return ""

func get_item_display_name(item: Dictionary) -> String:
	var base_name = get_era_item_name(str(item.get("name", "未知器物")))
	if is_era_item(item):
		return "%s%s" % [get_era_item_badge_text(item), base_name]
	return base_name

func get_item_display_description(item: Dictionary) -> String:
	var parts: Array[String] = [
		get_era_item_description(str(item.get("description", ""))),
		get_era_item_bonus_text(item)
	]
	var source_text = get_item_source_text(item)
	if source_text != "":
		parts.append(source_text)
	return "\n".join(parts)

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
		record_era_first_clear(selected_era_id)
		award_memory_cores(get_era_legacy_clear_reward(selected_era_id), "run_clear_%s" % selected_era_id)
	run_active = false
	checkpoint_scene = "map"
	current_shop_items.clear()
	_evaluate_achievements()
	save_progress()

func save_progress(scene_name: String = "") -> void:
	if suppress_save_progress:
		return
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
				"era_first_clears": era_first_clears,
				"discovered_items": discovered_items,
			"discovered_events": discovered_events,
			"unlocked_achievements": unlocked_achievements,
			"memory_cores": memory_cores,
			"meta_upgrades": meta_upgrades,
			"selected_era_id": selected_era_id,
			"user_settings": _normalize_user_settings(user_settings)
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
			"selected_heirloom_id": selected_heirloom_id,
			"field_pending_spend_attack": field_pending_spend_attack,
			"field_pending_blood_attack": field_pending_blood_attack,
			"field_pending_merchant_attack": field_pending_merchant_attack,
			"selected_route_name": selected_route_name,
			"route_switch_count": route_switch_count,
			"acknowledged_major_layer_debuffs": acknowledged_major_layer_debuffs,
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
			"bonus_cheat_from_level": bonus_cheat_from_level,
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
	
	var file := FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save temp file: " + SAVE_TEMP_PATH)
		return
	file.store_string(JSON.stringify(save_data))
	file = null
	_commit_save_file()

func _commit_save_file() -> void:
	var user_dir := DirAccess.open("user://")
	if user_dir == null:
		push_error("Failed to open user:// for save commit")
		return
	if FileAccess.file_exists(SAVE_FILE_PATH):
		_write_save_backup()
	var remove_result := OK
	if FileAccess.file_exists(SAVE_FILE_PATH):
		remove_result = user_dir.remove("savegame.json")
	if remove_result != OK:
		push_error("Failed to replace save file, error: %d" % remove_result)
		return
	var rename_result := user_dir.rename("savegame.tmp", "savegame.json")
	if rename_result != OK:
		push_error("Failed to commit save file, error: %d" % rename_result)
		return

func _write_save_backup() -> void:
	var current_file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if current_file == null:
		return
	var current_text := current_file.get_as_text()
	current_file = null
	var backup_file := FileAccess.open(SAVE_BACKUP_PATH, FileAccess.WRITE)
	if backup_file == null:
		push_warning("Failed to open save backup file: " + SAVE_BACKUP_PATH)
		return
	backup_file.store_string(current_text)

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
		if not meta.has("era_first_clears") or not (meta["era_first_clears"] is Dictionary):
			meta["era_first_clears"] = {}
	if not meta.has("discovered_items"):
		meta["discovered_items"] = []
	if not meta.has("discovered_events"):
		meta["discovered_events"] = []
	if not meta.has("unlocked_achievements"):
		meta["unlocked_achievements"] = []
	if not meta.has("selected_era_id"):
		meta["selected_era_id"] = "qin"
	meta["user_settings"] = _normalize_user_settings(meta.get("user_settings", {}))

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
		if not run_data.has("acknowledged_major_layer_debuffs"):
			run_data["acknowledged_major_layer_debuffs"] = []
		if int(run_data.get("max_floors", TOTAL_SMALL_FLOORS)) < TOTAL_SMALL_FLOORS:
			run_data["max_floors"] = TOTAL_SMALL_FLOORS

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
	era_first_clears = meta.get("era_first_clears", {}).duplicate(true)
	discovered_items = _to_string_array(meta.get("discovered_items", []))
	discovered_events = _to_string_array(meta.get("discovered_events", []))
	unlocked_achievements = _to_string_array(meta.get("unlocked_achievements", []))
	memory_cores = int(meta.get("memory_cores", 0))
	meta_upgrades = meta.get("meta_upgrades", {}).duplicate(true)
	selected_era_id = str(meta.get("selected_era_id", "qin"))
	user_settings = _normalize_user_settings(meta.get("user_settings", {}))
	apply_user_settings()
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
	if max_floors < TOTAL_SMALL_FLOORS:
		max_floors = TOTAL_SMALL_FLOORS
	cheat_points = int(run_data.get("cheat_points", cheat_points))
	shop_discount = float(run_data.get("shop_discount", shop_discount))
	map_data = _to_nested_dictionary_array(run_data.get("map_data", []))
	equipment_slot = _to_dictionary_array(run_data.get("equipment_slot", []))
	backpack = _to_dictionary_array(run_data.get("backpack", []))
	item_battle_wins = int(run_data.get("item_battle_wins", item_battle_wins))
	precision_battle_count = int(run_data.get("precision_battle_count", precision_battle_count))
	selected_heirloom_id = str(run_data.get("selected_heirloom_id", ""))
	field_pending_spend_attack = int(run_data.get("field_pending_spend_attack", 0))
	field_pending_blood_attack = int(run_data.get("field_pending_blood_attack", 0))
	field_pending_merchant_attack = int(run_data.get("field_pending_merchant_attack", 0))
	selected_route_name = str(run_data.get("selected_route_name", ""))
	route_switch_count = int(run_data.get("route_switch_count", 0))
	acknowledged_major_layer_debuffs = _to_int_array(run_data.get("acknowledged_major_layer_debuffs", []))
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
	bonus_cheat_from_level = int(run_data.get("bonus_cheat_from_level", 0))
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
	exclusive_combos.clear()
	_exclusive_combos_loaded = false
