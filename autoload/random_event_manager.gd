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
	{"event_id": "hp_blessing", "type": "good", "subtype": 0, "name": "生命祝福", "description": "血量+2", "immediate": true, "value": 2, "battle_required": false, "weight": 18, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "attack_blessing", "type": "good", "subtype": 1, "name": "力量祝福", "description": "攻击+1", "immediate": true, "value": 1, "battle_required": false, "weight": 14, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "shield_blessing", "type": "good", "subtype": 2, "name": "守护祝福", "description": "护甲+2", "immediate": true, "value": 2, "battle_required": false, "weight": 14, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "crit_blessing", "type": "good", "subtype": 3, "name": "精准祝福", "description": "暴击率+20%", "immediate": true, "value": 1, "battle_required": false, "weight": 10, "min_floor": 2, "max_floor": 99, "rarity": "common"},
	{"event_id": "gold_cache", "type": "good", "subtype": 4, "name": "金币奖励", "description": "获得10金币", "immediate": true, "value": 10, "battle_required": false, "weight": 16, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "random_equip_duel", "type": "good", "subtype": 5, "name": "随机装备", "description": "通过战斗决定装备品质", "immediate": false, "battle_required": true, "battle_type": "random_equip", "weight": 8, "min_floor": 2, "max_floor": 99, "rarity": "common"},
	{"event_id": "shop_discount_duel", "type": "good", "subtype": 6, "name": "商店折扣", "description": "通过战斗决定折扣力度", "immediate": false, "battle_required": true, "battle_type": "shop_discount", "weight": 8, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "field_medic", "type": "good", "subtype": 7, "name": "战地医师", "description": "恢复4点生命", "immediate": true, "value": 4, "battle_required": false, "weight": 14, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "scrap_cache", "type": "good", "subtype": 8, "name": "废料仓", "description": "获得3材料", "immediate": true, "value": 3, "battle_required": false, "weight": 12, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "combo_slot", "type": "good", "subtype": 9, "name": "战术拓展", "description": "连招槽位+1", "immediate": true, "value": 1, "battle_required": false, "weight": 4, "min_floor": 4, "max_floor": 99, "rarity": "rare"},
	{"event_id": "armory_gift", "type": "good", "subtype": 10, "name": "军械馈赠", "description": "获得一件随机蓝色装备", "immediate": true, "value": 1, "battle_required": false, "weight": 3, "min_floor": 3, "max_floor": 99, "rarity": "rare"},
	{"event_id": "cheat_console", "type": "good", "subtype": 11, "name": "黑箱终端", "description": "获得1点外挂次数", "immediate": true, "value": 1, "battle_required": false, "weight": 3, "min_floor": 5, "max_floor": 99, "rarity": "rare"}
]

const BAD_EVENT_POOL: Array[Dictionary] = [
	{"event_id": "hp_weaken", "type": "bad", "subtype": 0, "name": "生命削弱", "description": "血量-2", "immediate": false, "requires_choice": true, "choice_type": "attribute", "value": 2, "battle_required": false, "weight": 16, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "attack_weaken", "type": "bad", "subtype": 1, "name": "力量削弱", "description": "攻击-1", "immediate": false, "requires_choice": true, "choice_type": "attribute", "value": 1, "battle_required": false, "weight": 12, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "shield_weaken", "type": "bad", "subtype": 2, "name": "守护削弱", "description": "护甲-2", "immediate": false, "requires_choice": true, "choice_type": "attribute", "value": 2, "battle_required": false, "weight": 12, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "crit_weaken", "type": "bad", "subtype": 3, "name": "精准削弱", "description": "暴击率-20%", "immediate": false, "requires_choice": true, "choice_type": "attribute", "value": 1, "battle_required": false, "weight": 10, "min_floor": 2, "max_floor": 99, "rarity": "common"},
	{"event_id": "skill_lock", "type": "bad", "subtype": 4, "name": "技能封印", "description": "禁用1个连招", "immediate": true, "battle_required": false, "weight": 9, "min_floor": 2, "max_floor": 99, "rarity": "common"},
	{"event_id": "equip_loss_duel", "type": "bad", "subtype": 5, "name": "装备损失", "description": "选择：直接丢失装备或通过战斗决定", "immediate": false, "requires_choice": true, "choice_type": "equip_loss", "battle_required": true, "battle_type": "equip_loss", "weight": 8, "min_floor": 2, "max_floor": 99, "rarity": "common"},
	{"event_id": "gold_loss", "type": "bad", "subtype": 6, "name": "金币损失", "description": "丢失5金币", "immediate": true, "value": 5, "battle_required": false, "weight": 14, "min_floor": 0, "max_floor": 99, "rarity": "common"},
	{"event_id": "material_leak", "type": "bad", "subtype": 7, "name": "材料流失", "description": "失去2材料", "immediate": true, "value": 2, "battle_required": false, "weight": 11, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "armor_crack", "type": "bad", "subtype": 8, "name": "护甲开裂", "description": "护甲-3", "immediate": true, "value": 3, "battle_required": false, "weight": 10, "min_floor": 1, "max_floor": 99, "rarity": "common"},
	{"event_id": "combo_slot_loss", "type": "bad", "subtype": 9, "name": "回路短缺", "description": "失去1个连招槽位", "immediate": true, "value": 1, "battle_required": false, "weight": 3, "min_floor": 5, "max_floor": 99, "rarity": "rare"},
	{"event_id": "brittle_bones", "type": "bad", "subtype": 10, "name": "骨裂诅咒", "description": "最大生命-2", "immediate": true, "value": 2, "battle_required": false, "weight": 3, "min_floor": 4, "max_floor": 99, "rarity": "rare"}
]

var _current_event_type: String = ""
var _current_event_subtype: int = -1
var _battle_context: Dictionary = {}
var _battle_round: int = 0
var _battle_wins: int = 0
var _is_in_event_battle: bool = false
var _crit_bonus: int = 0
var _recent_event_ids: Array[String] = []

func _ready():
	print("[RandomEventManager] Ready")

func reset_state() -> void:
	_current_event_type = ""
	_current_event_subtype = -1
	_battle_context = {}
	_battle_round = 0
	_battle_wins = 0
	_is_in_event_battle = false
	_crit_bonus = 0
	_recent_event_ids.clear()

func get_random_good_event(floor_num: int = GameState.current_floor):
	return _select_event(GOOD_EVENT_POOL, floor_num)

func get_random_bad_event(floor_num: int = GameState.current_floor):
	return _select_event(BAD_EVENT_POOL, floor_num)

func get_event_catalog() -> Array[Dictionary]:
	return GOOD_EVENT_POOL + BAD_EVENT_POOL

func _select_event(pool: Array[Dictionary], floor_num: int) -> Dictionary:
	var common_candidates: Array[Dictionary] = []
	var rare_candidates: Array[Dictionary] = []
	
	for event_data in pool:
		if floor_num < int(event_data.get("min_floor", 0)):
			continue
		if floor_num > int(event_data.get("max_floor", 999)):
			continue
		if _recent_event_ids.has(event_data["event_id"]):
			continue
		if event_data.get("rarity", "common") == "rare":
			rare_candidates.append(event_data)
		else:
			common_candidates.append(event_data)
	
	var selected: Dictionary = {}
	if not rare_candidates.is_empty() and randf() < RARE_EVENT_CHANCE:
		selected = _weighted_pick(rare_candidates)
	elif not common_candidates.is_empty():
		selected = _weighted_pick(common_candidates)
	elif not rare_candidates.is_empty():
		selected = _weighted_pick(rare_candidates)
	else:
		selected = pool[randi() % pool.size()]
	
	_push_recent_event(str(selected.get("event_id", "")))
	GameState.record_event_discovery(str(selected.get("event_id", "")))
	return selected.duplicate(true)

func _weighted_pick(candidates: Array[Dictionary]) -> Dictionary:
	var total_weight := 0
	for event_data in candidates:
		total_weight += int(event_data.get("weight", 1))
	
	var roll = randi() % maxi(total_weight, 1)
	var cumulative := 0
	for event_data in candidates:
		cumulative += int(event_data.get("weight", 1))
		if roll < cumulative:
			return event_data
	return candidates[0]

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
	print("[RandomEventManager] Event battle started: ", _current_event_type)

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
	
	print("[RandomEventManager] Event battle finished: wins=%d type=%s" % [_battle_wins, _current_event_type])
	
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
	print("[RandomEventManager] Event battle cancelled")

func get_battle_status():
	return {
		"is_in_battle": _is_in_event_battle,
		"round": _battle_round,
		"wins": _battle_wins,
		"type": _current_event_type,
		"context": _battle_context
	}

func settle_immediate_good_event(event_data: Dictionary):
	print("[RandomEventManager] Settling immediate good event: ", event_data.name)
	var event_id = str(event_data.get("event_id", ""))
	
	match event_id:
		"field_medic":
			GameState.player_hp = mini(GameState.player_hp + int(event_data.get("value", 4)), GameState.player_max_hp)
			event_attribute_changed.emit("hp", int(event_data.get("value", 4)))
			EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
		"scrap_cache":
			GameState.add_materials(int(event_data.get("value", 3)))
		"combo_slot":
			GameState.max_combo_slots += int(event_data.get("value", 1))
			event_attribute_changed.emit("combo_slot", int(event_data.get("value", 1)))
		"armory_gift":
			var item = _generate_random_equip_by_rarity(1)
			if item.is_empty():
				GameState.player_gold += 12
				event_gold_changed.emit(12)
				EventBus.player_gold_changed.emit(GameState.player_gold)
			else:
				GameState.add_to_backpack(item.id)
				event_battle_reward.emit("equip", item)
		"cheat_console":
			GameState.add_cheat_point()
			event_attribute_changed.emit("cheat", int(event_data.get("value", 1)))
		_:
			match event_data.subtype:
				0:
					GameState.player_max_hp += event_data.value
					GameState.player_hp += event_data.value
					event_attribute_changed.emit("hp", event_data.value)
					EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
				1:
					GameState.player_attack += event_data.value
					event_attribute_changed.emit("attack", event_data.value)
				2:
					GameState.player_shield += event_data.value
					event_attribute_changed.emit("shield", event_data.value)
				3:
					_crit_bonus += event_data.value
					event_attribute_changed.emit("crit", event_data.value)
				4:
					GameState.player_gold += event_data.value
					event_gold_changed.emit(event_data.value)
					EventBus.player_gold_changed.emit(GameState.player_gold)
	
	good_event_triggered.emit("immediate", event_data)

func settle_immediate_bad_event(event_data: Dictionary, choice_value: int = -1):
	print("[RandomEventManager] Settling immediate bad event: ", event_data.name)
	var event_id = str(event_data.get("event_id", ""))

	if event_data.get("choice_type", "") == "attribute":
		var attribute_type = choice_value if choice_value >= 0 else event_data.subtype
		var reduction = event_data.get("value", 0)
		
		match attribute_type:
			0:
				reduction = mini(reduction, GameState.player_max_hp - 1)
				GameState.player_max_hp -= reduction
				GameState.player_hp = mini(GameState.player_hp, GameState.player_max_hp)
				event_attribute_changed.emit("hp", -reduction)
				EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
			1:
				GameState.player_attack = maxi(GameState.player_attack - reduction, 1)
				event_attribute_changed.emit("attack", -reduction)
			2:
				GameState.player_shield = maxi(GameState.player_shield - reduction, 0)
				event_attribute_changed.emit("shield", -reduction)
			3:
				_crit_bonus = maxi(_crit_bonus - reduction, 0)
				event_attribute_changed.emit("crit", -reduction)
	elif event_id == "material_leak":
		GameState.spend_materials(int(event_data.get("value", 2)))
	elif event_id == "armor_crack":
		GameState.player_shield = maxi(GameState.player_shield - int(event_data.get("value", 3)), 0)
		event_attribute_changed.emit("shield", -int(event_data.get("value", 3)))
	elif event_id == "combo_slot_loss":
		GameState.max_combo_slots = maxi(GameState.max_combo_slots - int(event_data.get("value", 1)), 1)
		while GameState.equipped_combos.size() > GameState.max_combo_slots:
			var combo_to_remove = GameState.equipped_combos[GameState.equipped_combos.size() - 1]
			GameState.unequip_combo(combo_to_remove)
		event_attribute_changed.emit("combo_slot", -int(event_data.get("value", 1)))
	elif event_id == "brittle_bones":
		var reduction = mini(int(event_data.get("value", 2)), GameState.player_max_hp - 1)
		GameState.player_max_hp -= reduction
		GameState.player_hp = mini(GameState.player_hp, GameState.player_max_hp)
		event_attribute_changed.emit("hp", -reduction)
		EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
	else:
		match event_data.subtype:
			4:
				var equipped = GameState.get_equipped_combos()
				if not equipped.is_empty():
					var combo_to_lock = equipped[randi() % equipped.size()]
					GameState.trigger_combo(combo_to_lock, 999)
					event_skill_disabled.emit(combo_to_lock)
			6:
				var loss = mini(event_data.value, GameState.player_gold)
				GameState.player_gold -= loss
				event_gold_changed.emit(-loss)
				EventBus.player_gold_changed.emit(GameState.player_gold)
	
	bad_event_triggered.emit("immediate", event_data)

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
			print("[RandomEventManager] No item found, giving gold instead")
			GameState.player_gold += 10
			event_gold_changed.emit(10)
			EventBus.player_gold_changed.emit(GameState.player_gold)
		else:
			GameState.add_to_backpack(item.id)
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
		GameState.on_battle_won()

func _settle_bad_event_battle(result: Dictionary):
	var battle_type = _battle_context.get("battle_type", "")
	
	if battle_type == "equip_loss":
		var rarity_to_lose = 0
		if result.wins >= 2:
			rarity_to_lose = 2
		elif result.wins >= 1:
			rarity_to_lose = 1
		
		var item = _find_equip_by_rarity(rarity_to_lose)
		if not item.is_empty():
			var index = _find_equip_index(item.id)
			if index >= 0:
				GameState.remove_from_backpack(index)
				event_equipment_lost.emit(item, true)
		else:
			var backpack = GameState.backpack
			if not backpack.is_empty():
				var idx = randi() % backpack.size()
				var lost_item = GameState.remove_from_backpack(idx)
				event_equipment_lost.emit(lost_item, true)

func _generate_random_equip_by_rarity(rarity: int):
	var rarity_name = RARITY_NAMES[rarity]
	var candidates = []
	
	for item_id in GameState.ITEMS:
		var item = GameState.ITEMS[item_id]
		if item.rarity == rarity_name and not GameState.has_item_anywhere(item_id):
			candidates.append(item_id)
	
	if candidates.is_empty():
		return {}
	
	var selected_id = candidates[randi() % candidates.size()]
	return GameState.ITEMS[selected_id]

func _find_equip_by_rarity(rarity: int):
	var rarity_name = RARITY_NAMES[rarity]
	var backpack = GameState.backpack
	
	for item in backpack:
		if item.rarity == rarity_name:
			return item
	
	return {}

func _find_equip_index(item_id: String):
	var backpack = GameState.backpack
	for i in range(backpack.size()):
		if backpack[i].id == item_id:
			return i
	return -1

func lose_random_equipment():
	var backpack = GameState.backpack
	if backpack.is_empty():
		return {}
	
	var idx = randi() % backpack.size()
	var item = GameState.remove_from_backpack(idx)
	event_equipment_lost.emit(item, false)
	return item

func get_crit_bonus():
	return _crit_bonus

func get_total_crit_chance():
	var base = 0.0
	if GameState.has_item("regicide"):
		base += 0.2
	return base

func settle_direct_equip_loss():
	return lose_random_equipment()

func get_crit_bonus_description():
	match _crit_bonus:
		0: return "无"
		1: return "+20%"
		2: return "+40%"
		3: return "+60%"
		_: return "+%d%%" % (_crit_bonus * 20)
