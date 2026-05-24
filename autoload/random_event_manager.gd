extends Node

signal good_event_triggered(event_type: String, event_data: Dictionary)
signal bad_event_triggered(event_type: String, event_data: Dictionary)
signal event_battle_started(is_good_event: bool, context: Dictionary)
signal event_battle_round_result(round_num: int, player_move: int, enemy_move: int, won: bool)
signal event_battle_ended(wins: int, is_good_event: bool, context: Dictionary)
signal event_attribute_changed(attribute: String, value: int)
signal event_gold_changed(amount: int)
signal event_discount_changed(discount: float)
signal event_equipment_lost(item: Dictionary, via_battle: bool)
signal event_skill_disabled(combo_id: String)
signal event_battle_reward(reward_type: String, item_data: Dictionary)

enum GoodEventType {
	HP_INCREASE = 0,
	ATTACK_INCREASE = 1,
	SHIELD_INCREASE = 2,
	CRIT_INCREASE = 3,
	GOLD_INCREASE = 4,
	RANDOM_EQUIP = 5,
	SHOP_DISCOUNT = 6
}

enum BadEventType {
	HP_DECREASE = 0,
	ATTACK_DECREASE = 1,
	SHIELD_DECREASE = 2,
	CRIT_DECREASE = 3,
	SKILL_LOCK = 4,
	EQUIP_LOSS = 5,
	GOLD_LOSS = 6
}

enum EquipmentRarity {
	WHITE = 0,
	BLUE = 1,
	RED = 2
}

const RARITY_NAMES = ["white", "blue", "red"]
const RARITY_COLORS = [
	Color(0.9, 0.9, 0.9),
	Color(0.5, 0.7, 1.0),
	Color(1.0, 0.5, 0.5)
]

const DISCOUNT_2_WINS = 0.7
const DISCOUNT_1_WIN = 0.8
const DISCOUNT_0_WIN = 0.9
const RARE_EVENT_CHANCE = 0.16

const GOOD_EVENT_POOL: Array[Dictionary] = [
	{"event_id": "hp_blessing", "type": "good", "subtype": 0, "name": "命数祝福", "description": "结果：命数上限+2，并立即恢复2命", "immediate": true, "value": 2, "battle_required": false, "weight": 18, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "attack_blessing", "type": "good", "subtype": 1, "name": "力量祝福", "description": "攻击+1", "immediate": true, "value": 1, "battle_required": false, "weight": 14, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "shield_blessing", "type": "good", "subtype": 2, "name": "守护祝福", "description": "护甲+2", "immediate": true, "value": 2, "battle_required": false, "weight": 14, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "crit_blessing", "type": "good", "subtype": 3, "name": "精准祝福", "description": "暴击率+20%", "immediate": true, "value": 1, "battle_required": false, "weight": 10, "min_floor": 2, "max_floor": 99, "rarity": "common"},
	{"event_id": "gold_cache", "type": "good", "subtype": 4, "name": "金币奖励", "description": "获得10金币", "immediate": true, "value": 10, "battle_required": false, "weight": 16, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "random_equip_duel", "type": "good", "subtype": 5, "name": "随机装备", "description": "通过战斗决定装备品质", "immediate": false, "battle_required": true, "battle_type": "random_equip", "weight": 8, "min_floor": 2, "max_floor": 99, "rarity": "common"},
	{"event_id": "shop_discount_duel", "type": "good", "subtype": 6, "name": "商店折扣", "description": "通过战斗决定折扣力度", "immediate": false, "battle_required": true, "battle_type": "shop_discount", "weight": 8, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "field_medic", "type": "good", "subtype": 7, "name": "战地医师", "description": "结果：恢复4命，不超过命数上限", "immediate": true, "value": 4, "battle_required": false, "weight": 14, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "scrap_cache", "type": "good", "subtype": 8, "name": "军资仓", "description": "获得12金币", "immediate": true, "value": 12, "battle_required": false, "weight": 12, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "combo_slot", "type": "good", "subtype": 9, "name": "战术拓展", "description": "结果：本局可携带布局槽位+1", "immediate": true, "value": 1, "battle_required": false, "weight": 4, "min_floor": 4, "max_floor": 99, "rarity": "rare"},
	{"event_id": "armory_gift", "type": "good", "subtype": 10, "name": "军械馈赠", "description": "获得一件随机蓝色装备", "immediate": true, "value": 1, "battle_required": false, "weight": 3, "min_floor": 3, "max_floor": 99, "rarity": "rare"},
	{"event_id": "cheat_console", "type": "good", "subtype": 11, "name": "黑箱终端", "description": "结果：机括次数+1", "immediate": true, "value": 1, "battle_required": false, "weight": 3, "min_floor": 5, "max_floor": 99, "rarity": "rare"},
	{"event_id": "qin_merit_grant", "type": "good", "subtype": 12, "name": "军功授爵", "description": "获得12金币并+1攻击，同时强化【虎符压阵】1级", "immediate": true, "value": 12, "battle_required": false, "weight": 4, "min_floor": 0, "max_floor": 99, "rarity": "rare"},
	{"event_id": "song_market_boom", "type": "good", "subtype": 13, "name": "市舶兴旺", "description": "获得16金币，同时强化【市舶周转】1级", "immediate": true, "value": 16, "battle_required": false, "weight": 4, "min_floor": 0, "max_floor": 99, "rarity": "rare"},
	{"event_id": "china_dragon_vein", "type": "good", "subtype": 14, "name": "龙脉回响", "description": "结果：机括+1并恢复2命，同时强化【山河同契】1级", "immediate": true, "value": 1, "battle_required": false, "weight": 4, "min_floor": 0, "max_floor": 99, "rarity": "rare"}
]

const BAD_EVENT_POOL: Array[Dictionary] = [
	{"event_id": "hp_weaken", "type": "bad", "subtype": 0, "name": "命数削弱", "description": "结果：命数上限-2，最低保留1命", "immediate": false, "requires_choice": true, "choice_type": "attribute", "value": 2, "battle_required": false, "weight": 16, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "attack_weaken", "type": "bad", "subtype": 1, "name": "力量削弱", "description": "攻击-1", "immediate": false, "requires_choice": true, "choice_type": "attribute", "value": 1, "battle_required": false, "weight": 12, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "shield_weaken", "type": "bad", "subtype": 2, "name": "守护削弱", "description": "护甲-2", "immediate": false, "requires_choice": true, "choice_type": "attribute", "value": 2, "battle_required": false, "weight": 12, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "crit_weaken", "type": "bad", "subtype": 3, "name": "精准削弱", "description": "暴击率-20%", "immediate": false, "requires_choice": true, "choice_type": "attribute", "value": 1, "battle_required": false, "weight": 10, "min_floor": 2, "max_floor": 99, "rarity": "common"},
	{"event_id": "skill_lock", "type": "bad", "subtype": 4, "name": "布局封印", "description": "结果：随机封印1个已携带布局，本局不可再触发", "immediate": true, "battle_required": false, "weight": 9, "min_floor": 2, "max_floor": 99, "rarity": "common"},
	{"event_id": "equip_loss_duel", "type": "bad", "subtype": 5, "name": "装备损失", "description": "选择：直接丢失装备或通过战斗决定", "immediate": false, "requires_choice": true, "choice_type": "equip_loss", "battle_required": true, "battle_type": "equip_loss", "weight": 8, "min_floor": 2, "max_floor": 99, "rarity": "common"},
	{"event_id": "gold_loss", "type": "bad", "subtype": 6, "name": "金币损失", "description": "丢失5金币", "immediate": true, "value": 5, "battle_required": false, "weight": 14, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "material_leak", "type": "bad", "subtype": 7, "name": "军资流失", "description": "失去8金币", "immediate": true, "value": 8, "battle_required": false, "weight": 11, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "armor_crack", "type": "bad", "subtype": 8, "name": "护甲开裂", "description": "护甲-3", "immediate": true, "value": 3, "battle_required": false, "weight": 10, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "combo_slot_loss", "type": "bad", "subtype": 9, "name": "回路短缺", "description": "结果：本局可携带布局槽位-1，最低保留1格", "immediate": true, "value": 1, "battle_required": false, "weight": 3, "min_floor": 5, "max_floor": 99, "rarity": "rare"},
	{"event_id": "brittle_bones", "type": "bad", "subtype": 10, "name": "骨裂诅咒", "description": "结果：命数上限-2，当前命数会被截断到新上限", "immediate": true, "value": 2, "battle_required": false, "weight": 3, "min_floor": 4, "max_floor": 99, "rarity": "rare"},
	{"event_id": "qin_harsh_law", "type": "bad", "subtype": 11, "name": "严刑峻法", "description": "失去8金币并护甲-2", "immediate": true, "value": 8, "battle_required": false, "weight": 4, "min_floor": 0, "max_floor": 99, "rarity": "rare"},
	{"event_id": "song_border_alarm", "type": "bad", "subtype": 12, "name": "边患警讯", "description": "失去8金币并攻击-1", "immediate": true, "value": 8, "battle_required": false, "weight": 4, "min_floor": 0, "max_floor": 99, "rarity": "rare"},
	{"event_id": "china_old_debt", "type": "bad", "subtype": 13, "name": "百代旧债", "description": "结果：命数上限-1，并失去1点机括", "immediate": true, "value": 1, "battle_required": false, "weight": 4, "min_floor": 0, "max_floor": 99, "rarity": "rare"}
]

var _current_event_type: String = ""
var _current_event_subtype: int = -1
var _battle_context: Dictionary = {}
var _battle_round: int = 0
var _battle_wins: int = 0
var _is_in_event_battle: bool = false
var _crit_bonus: int = 0
var _recent_event_ids: Array[String] = []
var _last_reward_summary: String = ""

func _ready():
	DebugLog.log("[RandomEventManager] Ready")

func reset_state() -> void:
	_current_event_type = ""
	_current_event_subtype = -1
	_battle_context = {}
	_battle_round = 0
	_battle_wins = 0
	_is_in_event_battle = false
	_crit_bonus = 0
	_recent_event_ids.clear()
	_last_reward_summary = ""

func set_last_reward_summary(text: String) -> void:
	_last_reward_summary = text

func _append_last_reward_summary(text: String) -> void:
	if text == "":
		return
	if _last_reward_summary == "":
		_last_reward_summary = text
	else:
		_last_reward_summary += "\n%s" % text

func consume_last_reward_summary() -> String:
	var text := _last_reward_summary
	_last_reward_summary = ""
	return text

func get_random_good_event(floor_num: int = GameState.current_floor):
	return _select_event(GOOD_EVENT_POOL, floor_num)

func get_random_bad_event(floor_num: int = GameState.current_floor):
	return _select_event(BAD_EVENT_POOL, floor_num)

func get_event_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	for event_data in GOOD_EVENT_POOL + BAD_EVENT_POOL:
		catalog.append(_apply_era_event_flavor(event_data.duplicate(true)))
	return catalog

func _is_event_allowed_for_era(event_data: Dictionary, floor_num: int) -> bool:
	var event_id = str(event_data.get("event_id", ""))
	var chapter = GameState.get_reward_chapter(floor_num)
	match GameState.selected_era_id:
		"song":
			# 宋卷前中期更偏市易、工造、恢复，后期再逐步放开硬惩罚。
			if chapter <= 2:
				if event_id in ["qin_merit_grant", "qin_harsh_law"]:
					return false
				if event_id in ["brittle_bones", "combo_slot_loss"] and chapter == 1:
					return false
		"china":
			# 中国卷前期就能接触复合代价，后期彻底放开终局型事件。
			if chapter == 1 and event_id in ["qin_merit_grant", "song_market_boom"]:
				return false
			if chapter >= 2 and event_id in ["combo_slot_loss", "brittle_bones", "china_old_debt", "china_dragon_vein"]:
				return true
		_:
			# 秦卷更早给军功、法令和军械，后期压缩经营型异闻。
			if chapter == 1 and event_id in ["song_market_boom", "china_dragon_vein"]:
				return false
			if chapter >= 2 and event_id in ["shop_discount_duel", "gold_cache"]:
				return false
	return true

func _get_era_event_chapter_hint(event_data: Dictionary, floor_num: int) -> String:
	var event_id = str(event_data.get("event_id", ""))
	var chapter = GameState.get_reward_chapter(floor_num)
	match GameState.selected_era_id:
		"song":
			if event_id in ["song_market_boom", "shop_discount_duel", "scrap_cache"]:
				return "本卷前中段更常见"
			if chapter >= 3 and event_id in ["song_border_alarm", "equip_loss_duel"]:
				return "深层边患更易出现"
		"china":
			if event_id in ["china_old_debt", "equip_loss_duel", "combo_slot_loss"]:
				return "终局高压事件"
			if event_id in ["china_dragon_vein", "armory_gift"]:
				return "高风险高回报"
		_:
			if event_id in ["qin_merit_grant", "armory_gift", "field_medic"]:
				return "秦卷征战嘉赏"
			if event_id in ["qin_harsh_law", "attack_weaken", "armor_crack"]:
				return "秦卷法令惩压"
	return ""

func _get_era_event_name(base_name: String) -> String:
	var qin_map := {
		"命数祝福": "军命恩赐",
		"力量祝福": "锐卒嘉赏",
		"守护祝福": "甲胄加护",
		"精准祝福": "军机明断",
		"金币奖励": "军资封赏",
		"随机装备": "军械择授",
		"商店折扣": "行商议价",
		"战地医师": "军前医官",
		"废料仓": "辎重旧库",
		"战术拓展": "军阵扩编",
		"军械馈赠": "辎重馈赏",
		"黑箱终端": "黑匣机括",
		"命数削弱": "军命折损",
		"力量削弱": "锋锐折损",
		"守护削弱": "甲盾松脱",
		"精准削弱": "军机失算",
		"布局封印": "阵诀封缄",
		"装备损失": "军械折损",
		"金币损失": "军资流失",
		"材料流失": "军资流散",
		"护甲开裂": "甲胄崩裂",
		"回路短缺": "阵列短缺",
		"骨裂诅咒": "筋骨折损"
	}
	var song_map := {
		"命数祝福": "医馆施惠",
		"力量祝福": "武备整肃",
		"守护祝福": "城防加护",
		"精准祝福": "筹算加持",
		"金币奖励": "市易进账",
		"随机装备": "百工择器",
		"商店折扣": "行商让利",
		"战地医师": "太医巡营",
		"废料仓": "工造废库",
		"战术拓展": "阵图拓页",
		"军械馈赠": "百工馈礼",
		"黑箱终端": "机关黑匣",
		"命数削弱": "元气折损",
		"力量削弱": "军势减弱",
		"守护削弱": "城防松动",
		"精准削弱": "筹算失衡",
		"布局封印": "图谱封存",
		"装备损失": "器物折损",
		"金币损失": "库银亏空",
		"材料流失": "库银亏空",
		"护甲开裂": "甲片开裂",
		"回路短缺": "图谱缺页",
		"骨裂诅咒": "筋骨劳损"
	}
	var china_map := {
		"命数祝福": "薪火回响",
		"力量祝福": "山河加锋",
		"守护祝福": "长城护佑",
		"精准祝福": "星图指引",
		"金币奖励": "山河馈金",
		"随机装备": "百代遗器",
		"商店折扣": "山河议价",
		"战地医师": "复兴医者",
		"废料仓": "旧世残库",
		"战术拓展": "终局扩编",
		"军械馈赠": "山河馈器",
		"黑箱终端": "终局黑匣",
		"命数削弱": "旧伤反噬",
		"力量削弱": "锋芒折损",
		"守护削弱": "山河裂隙",
		"精准削弱": "星图偏离",
		"布局封印": "旧律封缄",
		"装备损失": "遗器折损",
		"金币损失": "旧账追索",
		"材料流失": "旧账追索",
		"护甲开裂": "城垣崩裂",
		"回路短缺": "回路断层",
		"骨裂诅咒": "旧伤裂骨"
	}
	match GameState.selected_era_id:
		"song":
			return str(song_map.get(base_name, base_name))
		"china":
			return str(china_map.get(base_name, base_name))
		_:
			return str(qin_map.get(base_name, base_name))

func _get_era_event_description(base_desc: String) -> String:
	match GameState.selected_era_id:
		"song":
			return "%s（偏经营与守势）" % base_desc
		"china":
			return "%s（终局余响叠加）" % base_desc
		_:
			return "%s（偏速决与强压）" % base_desc

func _select_event(pool: Array[Dictionary], floor_num: int) -> Dictionary:
	var common_candidates: Array[Dictionary] = []
	var rare_candidates: Array[Dictionary] = []
	var is_good_pool = pool == GOOD_EVENT_POOL
	
	for event_data in pool:
		if floor_num < int(event_data.get("min_floor", 0)):
			continue
		if floor_num > int(event_data.get("max_floor", 999)):
			continue
		if not _is_event_allowed_for_era(event_data, floor_num):
			continue
		if _recent_event_ids.has(event_data["event_id"]):
			continue
		if event_data.get("rarity", "common") == "rare":
			rare_candidates.append(event_data)
		else:
			common_candidates.append(event_data)
	
	var selected: Dictionary = {}
	if not rare_candidates.is_empty() and randf() < RARE_EVENT_CHANCE:
		selected = _weighted_pick(rare_candidates, floor_num)
	elif not common_candidates.is_empty():
		selected = _weighted_pick(common_candidates, floor_num)
	elif not rare_candidates.is_empty():
		selected = _weighted_pick(rare_candidates, floor_num)
	else:
		selected = pool[randi() % pool.size()]
	
	_push_recent_event(str(selected.get("event_id", "")))
	GameState.record_event_discovery(str(selected.get("event_id", "")))
	return _apply_era_event_flavor(selected.duplicate(true))

func _weighted_pick(candidates: Array[Dictionary], floor_num: int = GameState.current_floor) -> Dictionary:
	var total_weight := 0.0
	var is_good_candidates := false
	if not candidates.is_empty():
		var candidate_type = str(candidates[0].get("type", ""))
		is_good_candidates = candidate_type == "good"
	for event_data in candidates:
		var base_weight = float(event_data.get("weight", 1))
		var event_id := str(event_data.get("event_id", ""))
		var mul = GameState.get_era_event_weight_multiplier(event_id, is_good_candidates)
		mul *= _get_build_bias_weight(event_id, is_good_candidates, floor_num)
		total_weight += base_weight * mul
	
	var roll = randf() * max(total_weight, 1.0)
	var cumulative := 0.0
	for event_data in candidates:
		var base_weight = float(event_data.get("weight", 1))
		var event_id := str(event_data.get("event_id", ""))
		var mul = GameState.get_era_event_weight_multiplier(event_id, is_good_candidates)
		mul *= _get_build_bias_weight(event_id, is_good_candidates, floor_num)
		cumulative += base_weight * mul
		if roll < cumulative:
			return event_data
	return candidates[0]

func _get_build_bias_weight(event_id: String, is_good: bool, floor_num: int) -> float:
	if not GameState.has_method("get_run_tendency_tags"):
		return 1.0
	var tags: Array[String] = GameState.get_run_tendency_tags()
	if tags.is_empty():
		return 1.0
	var intensity := 1.0
	if floor_num >= 7:
		intensity = 1.22
	elif floor_num >= 4:
		intensity = 1.12
	var weight := 1.0
	for tag in tags:
		match tag:
			"defense":
				if is_good and event_id in ["shield_blessing", "field_medic", "hp_blessing"]:
					weight = max(weight, 1.16 * intensity)
				elif not is_good and event_id in ["shield_weaken", "armor_crack"]:
					weight = max(weight, 1.08 * intensity)
			"economy":
				if is_good and event_id in ["gold_cache", "shop_discount_duel", "scrap_cache", "song_market_boom"]:
					weight = max(weight, 1.18 * intensity)
				elif not is_good and event_id in ["gold_loss", "material_leak", "qin_harsh_law"]:
					weight = max(weight, 1.08 * intensity)
			"aggression":
				if is_good and event_id in ["attack_blessing", "armory_gift", "qin_merit_grant"]:
					weight = max(weight, 1.16 * intensity)
				elif not is_good and event_id in ["attack_weaken", "equip_loss_duel"]:
					weight = max(weight, 1.06 * intensity)
			"sustain":
				if is_good and event_id in ["field_medic", "hp_blessing", "china_dragon_vein"]:
					weight = max(weight, 1.16 * intensity)
				elif not is_good and event_id in ["hp_weaken", "brittle_bones", "china_old_debt"]:
					weight = max(weight, 1.08 * intensity)
			"tempo":
				if is_good and event_id in ["combo_slot", "cheat_console", "random_equip_duel"]:
					weight = max(weight, 1.14 * intensity)
				elif not is_good and event_id in ["skill_lock", "combo_slot_loss"]:
					weight = max(weight, 1.08 * intensity)
	return weight

func _apply_era_event_flavor(event_data: Dictionary) -> Dictionary:
	var flavored = event_data.duplicate(true)
	flavored["name"] = "%s%s" % [GameState.get_era_event_name_prefix(), _get_era_event_name(str(flavored.get("name", "异闻")))]
	var chapter_hint = _get_era_event_chapter_hint(flavored, GameState.current_floor)
	flavored["description"] = _get_era_event_description(str(flavored.get("description", "")))
	if chapter_hint != "":
		flavored["description"] += " · %s" % chapter_hint
	return flavored

func _push_recent_event(event_id: String) -> void:
	if event_id == "":
		return
	_recent_event_ids.append(event_id)
	while _recent_event_ids.size() > 3:
		_recent_event_ids.pop_front()

func start_event_battle(is_good: bool, context: Dictionary):
	_current_event_type = "good" if is_good else "bad"
	_current_event_subtype = context.get("event_data", {}).get("subtype", -1)
	_battle_context = context
	_battle_round = 0
	_battle_wins = 0
	_is_in_event_battle = true
	event_battle_started.emit(is_good, context)
	DebugLog.log("[RandomEventManager] Event battle started:", _current_event_type)

func process_event_battle_round(player_move: int, enemy_move: int):
	if not _is_in_event_battle:
		return {"continues": false, "won": false, "message": "Not in event battle"}
	
	_battle_round += 1
	var is_draw = (player_move == enemy_move)
	var player_wins = false
	
	if not is_draw:
		player_wins = (player_move == 0 and enemy_move == 1) or \
					  (player_move == 1 and enemy_move == 2) or \
					  (player_move == 2 and enemy_move == 0)
	
	var result_msg = ""
	var continues = true
	
	if _battle_round == 1:
		result_msg = "第1回合: "
		if is_draw:
			result_msg += "平局（不计入）"
		elif player_wins:
			result_msg += "胜利（不计入）"
		else:
			result_msg += "失败（不计入）"
	else:
		if player_wins:
			_battle_wins += 1
		
		result_msg = "第%d回合: " % _battle_round
		if is_draw:
			result_msg += "平局"
		elif player_wins:
			result_msg += "胜利！"
		else:
			result_msg += "失败..."
		
		if _battle_round < 3:
			continues = true
		else:
			continues = false
	
	event_battle_round_result.emit(_battle_round, player_move, enemy_move, player_wins)
	
	return {
		"continues": continues,
		"won": player_wins,
		"message": result_msg,
		"round": _battle_round,
		"wins": _battle_wins
	}

func finish_event_battle():
	if not _is_in_event_battle:
		return {}
	
	_is_in_event_battle = false
	
	var result = {
		"wins": _battle_wins,
		"type": _current_event_type,
		"subtype": _current_event_subtype,
		"context": _battle_context
	}
	
	DebugLog.log("[RandomEventManager] Event battle finished: wins=%d type=%s" % [_battle_wins, _current_event_type])
	
	if _current_event_type == "good":
		_settle_good_event_battle(result)
	else:
		_settle_bad_event_battle(result)
	
	event_battle_ended.emit(_battle_wins, _current_event_type == "good", _battle_context)
	
	return result

func cancel_event_battle():
	_is_in_event_battle = false
	_battle_round = 0
	_battle_wins = 0
	_current_event_type = ""
	_current_event_subtype = -1
	_battle_context = {}
	DebugLog.log("[RandomEventManager] Event battle cancelled")

func get_battle_status():
	return {
		"is_in_battle": _is_in_event_battle,
		"round": _battle_round,
		"wins": _battle_wins,
		"type": _current_event_type,
		"context": _battle_context
	}

func settle_immediate_good_event(event_data: Dictionary):
	DebugLog.log("[RandomEventManager] Settling immediate good event:", event_data.get("name", ""))
	var event_id = str(event_data.get("event_id", ""))
	var value = int(event_data.get("value", 0))
	var subtype = int(event_data.get("subtype", -1))
	
	match event_id:
		"qin_merit_grant":
			GameState.player_gold += 12
			GameState.player_attack += 1
			GameState.grant_combo_event_upgrade("qin_tiger_push")
			event_gold_changed.emit(12)
			event_attribute_changed.emit("attack", 1)
			event_attribute_changed.emit("combo_upgrade", 1)
			EventBus.player_gold_changed.emit(GameState.player_gold)
			set_last_reward_summary("结果已结算：金币+12，攻击+1，【虎符压阵】强化+1。")
		"song_market_boom":
			GameState.player_gold += 16
			GameState.grant_combo_event_upgrade("song_trade_turn")
			event_gold_changed.emit(16)
			event_attribute_changed.emit("combo_upgrade", 1)
			EventBus.player_gold_changed.emit(GameState.player_gold)
			set_last_reward_summary("结果已结算：金币+16，【市舶周转】强化+1。")
		"china_dragon_vein":
			GameState.add_cheat_point()
			GameState.player_hp = mini(GameState.player_hp + 2, GameState.player_max_hp)
			GameState.grant_combo_event_upgrade("china_unity_echo")
			event_attribute_changed.emit("cheat", 1)
			event_attribute_changed.emit("hp", 2)
			event_attribute_changed.emit("combo_upgrade", 1)
			EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
			set_last_reward_summary("结果已结算：机括+1，恢复2命，【山河同契】强化+1。")
		"field_medic":
			GameState.player_hp = mini(GameState.player_hp + value, GameState.player_max_hp)
			event_attribute_changed.emit("hp", value)
			EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
			set_last_reward_summary("结果已结算：恢复%d命，当前命数 %d/%d。" % [value, GameState.player_hp, GameState.player_max_hp])
		"scrap_cache":
			GameState.player_gold += value
			event_gold_changed.emit(value)
			EventBus.player_gold_changed.emit(GameState.player_gold)
			set_last_reward_summary("结果已结算：金币+%d，当前金币 %d。" % [value, GameState.player_gold])
		"combo_slot":
			GameState.max_combo_slots += value
			event_attribute_changed.emit("combo_slot", value)
			set_last_reward_summary("结果已结算：本局布局槽位+%d，当前可携带 %d 格。" % [value, GameState.max_combo_slots])
		"armory_gift":
			var item = _generate_random_equip_by_rarity(1)
			if item.is_empty():
				GameState.player_gold += 12
				event_gold_changed.emit(12)
				EventBus.player_gold_changed.emit(GameState.player_gold)
				set_last_reward_summary("器物池空缺，改为纳入 12 金币。")
			else:
				GameState.add_to_backpack(item.id)
				var reward_text = "纳入器物：%s" % GameState.get_item_display_name(item)
				var source_text = GameState.get_item_source_text(item)
				if source_text != "":
					reward_text += "\n%s" % source_text
				set_last_reward_summary(reward_text)
				event_battle_reward.emit("equip", item)
		"cheat_console":
			GameState.add_cheat_point()
			event_attribute_changed.emit("cheat", value)
			set_last_reward_summary("结果已结算：机括+%d，当前 %d/%d。" % [value, GameState.cheat_points, GameState.get_max_cheat_points()])
		_:
			match subtype:
				0:
					GameState.player_max_hp += value
					GameState.player_hp += value
					event_attribute_changed.emit("hp", value)
					EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
					set_last_reward_summary("结果已结算：命数上限+%d，当前命数 %d/%d。" % [value, GameState.player_hp, GameState.player_max_hp])
				1:
					GameState.player_attack += value
					event_attribute_changed.emit("attack", value)
					set_last_reward_summary("结果已结算：攻击+%d，当前攻击 %d。" % [value, GameState.player_attack])
				2:
					GameState.player_shield += value
					event_attribute_changed.emit("shield", value)
					set_last_reward_summary("结果已结算：护甲+%d，当前护甲 %d。" % [value, GameState.player_shield])
				3:
					_crit_bonus += value
					event_attribute_changed.emit("crit", value)
					set_last_reward_summary("结果已结算：暴击率+%d%%。" % (value * 20))
				4:
					GameState.player_gold += value
					event_gold_changed.emit(value)
					EventBus.player_gold_changed.emit(GameState.player_gold)
					set_last_reward_summary("结果已结算：金币+%d，当前金币 %d。" % [value, GameState.player_gold])

	if GameState.selected_era_id == "china":
		GameState.add_cheat_point()
		event_attribute_changed.emit("cheat", 1)
		if _last_reward_summary != "":
			_last_reward_summary += "\n中国卷余响：机括+1。"
	
	good_event_triggered.emit("immediate", event_data)

func settle_immediate_bad_event(event_data: Dictionary, choice_value: int = -1):
	DebugLog.log("[RandomEventManager] Settling immediate bad event:", event_data.get("name", ""))
	var event_id = str(event_data.get("event_id", ""))
	var subtype = int(event_data.get("subtype", -1))
	var value = int(event_data.get("value", 0))

	if event_data.get("choice_type", "") == "attribute":
		var attribute_type = choice_value if choice_value >= 0 else subtype
		var reduction = value
		
		match attribute_type:
			0:
				reduction = mini(reduction, GameState.player_max_hp - 1)
				GameState.player_max_hp -= reduction
				GameState.player_hp = mini(GameState.player_hp, GameState.player_max_hp)
				event_attribute_changed.emit("hp", -reduction)
				EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
				set_last_reward_summary("结果已结算：命数上限-%d，当前命数 %d/%d。" % [reduction, GameState.player_hp, GameState.player_max_hp])
			1:
				GameState.player_attack = maxi(GameState.player_attack - reduction, 1)
				event_attribute_changed.emit("attack", -reduction)
				set_last_reward_summary("结果已结算：攻击-%d，当前攻击 %d。" % [reduction, GameState.player_attack])
			2:
				GameState.player_shield = maxi(GameState.player_shield - reduction, 0)
				event_attribute_changed.emit("shield", -reduction)
				set_last_reward_summary("结果已结算：护甲-%d，当前护甲 %d。" % [reduction, GameState.player_shield])
			3:
				_crit_bonus = maxi(_crit_bonus - reduction, 0)
				event_attribute_changed.emit("crit", -reduction)
				set_last_reward_summary("结果已结算：暴击率下降，当前异闻暴击加成为 %d 层。" % _crit_bonus)
	elif event_id == "material_leak":
		var gold_loss := mini(int(event_data.get("value", 8)), GameState.player_gold)
		GameState.player_gold -= gold_loss
		event_gold_changed.emit(-gold_loss)
		EventBus.player_gold_changed.emit(GameState.player_gold)
		set_last_reward_summary("结果已结算：金币-%d，当前金币 %d。" % [gold_loss, GameState.player_gold])
	elif event_id == "qin_harsh_law":
		var requested_loss := int(event_data.get("value", 8))
		var gold_loss = mini(requested_loss, GameState.player_gold)
		var shield_loss := 2 if requested_loss >= 8 else 1
		GameState.player_gold -= gold_loss
		GameState.player_shield = maxi(GameState.player_shield - shield_loss, 0)
		event_gold_changed.emit(-gold_loss)
		event_attribute_changed.emit("shield", -shield_loss)
		EventBus.player_gold_changed.emit(GameState.player_gold)
		set_last_reward_summary("结果已结算：金币-%d，护甲-%d。法令无常，但代价已明确。" % [gold_loss, shield_loss])
	elif event_id == "song_border_alarm":
		var requested_gold_loss := int(event_data.get("value", 8))
		var gold_loss = mini(requested_gold_loss, GameState.player_gold)
		GameState.player_gold -= gold_loss
		event_gold_changed.emit(-gold_loss)
		EventBus.player_gold_changed.emit(GameState.player_gold)
		var attack_loss := 1 if requested_gold_loss >= 8 else 0
		if attack_loss > 0:
			GameState.player_attack = maxi(GameState.player_attack - attack_loss, 1)
			event_attribute_changed.emit("attack", -attack_loss)
		set_last_reward_summary("结果已结算：金币-%d%s，当前攻击 %d。" % [gold_loss, "，攻击-1" if attack_loss > 0 else "", GameState.player_attack])
	elif event_id == "china_old_debt":
		var reduction = mini(1, GameState.player_max_hp - 1)
		GameState.player_max_hp -= reduction
		GameState.player_hp = mini(GameState.player_hp, GameState.player_max_hp)
		GameState.consume_cheat_point()
		event_attribute_changed.emit("hp", -reduction)
		event_attribute_changed.emit("cheat", -1)
		EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
		set_last_reward_summary("结果已结算：命数上限-%d，机括-1。旧债落定，继续前行。" % reduction)
	elif event_id == "armor_crack":
		GameState.player_shield = maxi(GameState.player_shield - int(event_data.get("value", 3)), 0)
		event_attribute_changed.emit("shield", -int(event_data.get("value", 3)))
		set_last_reward_summary("结果已结算：护甲-%d，当前护甲 %d。" % [int(event_data.get("value", 3)), GameState.player_shield])
	elif event_id == "combo_slot_loss":
		GameState.max_combo_slots = maxi(GameState.max_combo_slots - int(event_data.get("value", 1)), 1)
		while GameState.equipped_combos.size() > GameState.max_combo_slots:
			var combo_to_remove = GameState.equipped_combos[GameState.equipped_combos.size() - 1]
			GameState.unequip_combo(combo_to_remove)
		event_attribute_changed.emit("combo_slot", -int(event_data.get("value", 1)))
		set_last_reward_summary("结果已结算：本局布局槽位-%d，当前可携带 %d 格。" % [int(event_data.get("value", 1)), GameState.max_combo_slots])
	elif event_id == "brittle_bones":
		var reduction = mini(int(event_data.get("value", 2)), GameState.player_max_hp - 1)
		GameState.player_max_hp -= reduction
		GameState.player_hp = mini(GameState.player_hp, GameState.player_max_hp)
		event_attribute_changed.emit("hp", -reduction)
		EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
		set_last_reward_summary("结果已结算：命数上限-%d，当前命数 %d/%d。" % [reduction, GameState.player_hp, GameState.player_max_hp])
	else:
		match subtype:
			4:
				var equipped = GameState.get_equipped_combos()
				if not equipped.is_empty():
					var combo_to_lock = equipped[randi() % equipped.size()]
					GameState.trigger_combo(combo_to_lock, 999)
					event_skill_disabled.emit(combo_to_lock)
					set_last_reward_summary("结果已结算：布局【%s】被封印，本局不可再触发。" % combo_to_lock)
				else:
					set_last_reward_summary("结果已结算：没有已携带布局可封印。")
			6:
				var loss = mini(value, GameState.player_gold)
				GameState.player_gold -= loss
				event_gold_changed.emit(-loss)
				EventBus.player_gold_changed.emit(GameState.player_gold)
				set_last_reward_summary("结果已结算：金币-%d，当前金币 %d。" % [loss, GameState.player_gold])

	if GameState.selected_era_id == "china":
		GameState.player_gold += 6
		event_gold_changed.emit(6)
		EventBus.player_gold_changed.emit(GameState.player_gold)
		if _last_reward_summary != "":
			_last_reward_summary += "\n中国卷余响：金币+6。"
	
	bad_event_triggered.emit("immediate", event_data)

func settle_good_gamble_event(event_data: Dictionary, wins: int) -> void:
	if wins >= 1:
		settle_immediate_good_event(event_data)
		if wins >= 2:
			var bonus_gold := 6
			GameState.player_gold += bonus_gold
			event_gold_changed.emit(bonus_gold)
			EventBus.player_gold_changed.emit(GameState.player_gold)
			_append_last_reward_summary("加码成功：额外金币+%d。" % bonus_gold)
		else:
			_append_last_reward_summary("加码未成，但保住了原本收益。")
	else:
		GameState.player_gold += 6
		event_gold_changed.emit(6)
		EventBus.player_gold_changed.emit(GameState.player_gold)
		set_last_reward_summary("加码失手：原收益擦肩而过，仅带回金币+6。")
		good_event_triggered.emit("gamble", event_data)

func settle_bad_gamble_event(event_data: Dictionary, wins: int) -> void:
	if wins >= 2:
		GameState.player_gold += 6
		event_gold_changed.emit(6)
		EventBus.player_gold_changed.emit(GameState.player_gold)
		set_last_reward_summary("化解灾厄：没有发生损失，并夺回金币+6。")
		bad_event_triggered.emit("gamble", event_data)
	elif wins >= 1:
		_settle_bad_trial_hp_cost(event_data, 1, "险中求稳")
	else:
		_settle_bad_trial_hp_cost(event_data, 2, "试锋失利")

func _settle_bad_trial_hp_cost(event_data: Dictionary, requested_loss: int, result_text: String) -> void:
	var hp_loss := mini(maxi(requested_loss, 0), maxi(int(GameState.player_hp) - 1, 0))
	if hp_loss > 0:
		GameState.player_hp = maxi(int(GameState.player_hp) - hp_loss, 1)
		event_attribute_changed.emit("hp", -hp_loss)
		EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
		set_last_reward_summary("%s：命数-%d，当前命数 %d/%d。原灾厄未落。" % [
			result_text,
			hp_loss,
			GameState.player_hp,
			GameState.player_max_hp
		])
	else:
		set_last_reward_summary("%s：命线已低，未再扣命，原灾厄未落。" % result_text)
	bad_event_triggered.emit("gamble", event_data)

func _settle_reduced_bad_event(event_data: Dictionary) -> void:
	var reduced := event_data.duplicate(true)
	var value := int(reduced.get("value", 1))
	if value <= 1:
		set_last_reward_summary("擦边化解：原本的损失被压到最低，没有实际折损。")
		if GameState.selected_era_id == "china":
			GameState.player_gold += 6
			event_gold_changed.emit(6)
			EventBus.player_gold_changed.emit(GameState.player_gold)
			_append_last_reward_summary("中国卷余响：金币+6。")
		bad_event_triggered.emit("gamble", event_data)
		return
	reduced["value"] = maxi(1, int(ceil(float(value) * 0.5)))
	var choice := int(reduced.get("subtype", -1))
	settle_immediate_bad_event(reduced, choice)

func _settle_good_event_battle(result: Dictionary):
	var battle_type = _battle_context.get("battle_type", "")
	
	if battle_type == "random_equip":
		var rarity = 0
		if result.wins >= 2:
			rarity = 2
		elif result.wins >= 1:
			rarity = 1
		
		var item = _generate_random_equip_by_rarity(rarity)
		if item.is_empty():
			DebugLog.log("[RandomEventManager] No item found, giving gold instead")
			GameState.player_gold += 10
			event_gold_changed.emit(10)
			EventBus.player_gold_changed.emit(GameState.player_gold)
			set_last_reward_summary("器物池空缺，改为纳入 10 金币。")
		else:
			GameState.add_to_backpack(item.id)
			var reward_text = "纳入器物：%s" % GameState.get_item_display_name(item)
			var source_text = GameState.get_item_source_text(item)
			if source_text != "":
				reward_text += "\n%s" % source_text
			set_last_reward_summary(reward_text)
			event_battle_reward.emit("equip", item)
		
		GameState.on_battle_won()
	
	elif battle_type == "shop_discount":
		var discount = DISCOUNT_0_WIN
		if result.wins >= 2:
			discount = DISCOUNT_2_WINS
		elif result.wins >= 1:
			discount = DISCOUNT_1_WIN
		
		GameState.shop_discount = discount
		event_discount_changed.emit(discount)
		set_last_reward_summary("行商折价已生效：%d折。" % int(round(discount * 10.0)))
		GameState.on_battle_won()

	elif battle_type == "good_gamble_bonus":
		settle_good_gamble_event(_battle_context.get("event_data", {}), int(result.get("wins", 0)))

	if GameState.selected_era_id == "china" and (battle_type != "good_gamble_bonus" or int(result.get("wins", 0)) <= 0):
		GameState.add_cheat_point()
		event_attribute_changed.emit("cheat", 1)

func _settle_bad_event_battle(result: Dictionary):
	var battle_type = _battle_context.get("battle_type", "")
	
	if battle_type == "equip_loss":
		var rarity_to_lose = 0
		if result.wins >= 2:
			rarity_to_lose = 2
		elif result.wins >= 1:
			rarity_to_lose = 1
		
		var candidate = _find_equipment_loss_candidate_by_rarity(rarity_to_lose)
		if not candidate.is_empty():
			var item: Dictionary = candidate.get("item", {})
			var lost_item = _remove_equipment_loss_candidate(candidate)
			event_equipment_lost.emit(lost_item, true)
			set_last_reward_summary("折损器物：%s" % GameState.get_item_display_name(item))
		else:
			var candidates := _get_equipment_loss_candidates()
			if not candidates.is_empty():
				var fallback_candidate = candidates[randi() % candidates.size()]
				var lost_item = _remove_equipment_loss_candidate(fallback_candidate)
				event_equipment_lost.emit(lost_item, true)
				set_last_reward_summary("折损器物：%s" % GameState.get_item_display_name(lost_item))
			else:
				set_last_reward_summary("行囊无器物，未发生折损。")

	elif battle_type == "bad_gamble_relief":
		settle_bad_gamble_event(_battle_context.get("event_data", {}), int(result.get("wins", 0)))

	if GameState.selected_era_id == "china" and (battle_type != "bad_gamble_relief" or int(result.get("wins", 0)) >= 2):
		GameState.player_gold += 6
		event_gold_changed.emit(6)
		EventBus.player_gold_changed.emit(GameState.player_gold)
		_append_last_reward_summary("中国卷余响：金币+6。")

func _generate_random_equip_by_rarity(rarity: int):
	var rarity_name = RARITY_NAMES[rarity]
	var candidates = []
	
	for item_id in GameState.ITEMS:
		var item = GameState.ITEMS[item_id]
		if not GameState.is_item_allowed_in_current_era(item):
			continue
		if item.rarity == rarity_name and not GameState.has_item_anywhere(item_id):
			candidates.append(item_id)
	
	if candidates.is_empty():
		return {}
	
	var selected_id = candidates[randi() % candidates.size()]
	return GameState.ITEMS[selected_id]

func _find_equip_by_rarity(rarity: int):
	var candidate := _find_equipment_loss_candidate_by_rarity(rarity)
	if not candidate.is_empty():
		return candidate.get("item", {})
	return {}

func _find_equip_index(item_id: String):
	var backpack = GameState.backpack
	for i in range(backpack.size()):
		if backpack[i].id == item_id:
			return i
	return -1

func lose_random_equipment():
	var candidates := _get_equipment_loss_candidates()
	if candidates.is_empty():
		return {}
	
	var candidate = candidates[randi() % candidates.size()]
	var item = _remove_equipment_loss_candidate(candidate)
	event_equipment_lost.emit(item, false)
	return item

func _get_equipment_loss_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for i in range(GameState.backpack.size()):
		candidates.append({"source": "backpack", "index": i, "item": GameState.backpack[i]})
	for i in range(GameState.equipment_slot.size()):
		candidates.append({"source": "equipment", "index": i, "item": GameState.equipment_slot[i]})
	return candidates

func _find_equipment_loss_candidate_by_id(item_id: String) -> Dictionary:
	for candidate in _get_equipment_loss_candidates():
		var item: Dictionary = candidate.get("item", {})
		if str(item.get("id", "")) == item_id:
			return candidate
	return {}

func _find_equipment_loss_candidate_by_rarity(rarity: int) -> Dictionary:
	var rarity_name = RARITY_NAMES[rarity]
	for candidate in _get_equipment_loss_candidates():
		var item: Dictionary = candidate.get("item", {})
		if str(item.get("rarity", "")) == rarity_name:
			return candidate
	return {}

func _remove_equipment_loss_candidate(candidate: Dictionary) -> Dictionary:
	var source := str(candidate.get("source", ""))
	var index := int(candidate.get("index", -1))
	if source == "equipment":
		return GameState.remove_from_equipment_slot(index)
	return GameState.remove_from_backpack(index)

func get_crit_bonus():
	return _crit_bonus

func get_total_crit_chance():
	var base = 0.0
	if GameState.has_item("regicide"):
		base += 0.2
	return base

func settle_direct_equip_loss():
	var lost_item = lose_random_equipment()
	if lost_item is Dictionary and not lost_item.is_empty():
		set_last_reward_summary("结果已结算：失去器物【%s】。" % GameState.get_item_display_name(lost_item))
	else:
		set_last_reward_summary("结果已结算：无器物可失去。")
	return lost_item

func get_crit_bonus_description():
	match _crit_bonus:
		0: return "无"
		1: return "+20%"
		2: return "+40%"
		3: return "+60%"
		_: return "+%d%%" % (_crit_bonus * 20)
