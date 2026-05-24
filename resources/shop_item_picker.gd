class_name ShopItemPicker
extends RefCounted

const RARITY_WEIGHTS: Dictionary = {
	"white": 50,
	"blue": 35,
	"red": 15
}

const TYPE_WEIGHTS: Dictionary = {
	"attack": 40,
	"defense": 40,
	"special": 20
}

var game_state: Node

func _init(state: Node) -> void:
	game_state = state

func pick_shop_items(count: int = 3) -> Array[String]:
	var result: Array[String] = []
	var attempts := 0
	var type_weights := _get_type_weights()
	while result.size() < count and attempts < count * 10:
		attempts += 1
		var rarity := _pick_weighted_key(RARITY_WEIGHTS, "white")
		var type_name := _pick_weighted_key(type_weights, "attack")
		var item_id := _get_item_by_rarity_and_type(rarity, type_name)
		if item_id != "" and not item_id in result:
			result.append(item_id)

	if result.size() < count:
		var fallback_items := _get_fallback_items(result)
		fallback_items.shuffle()
		while result.size() < count and not fallback_items.is_empty():
			result.append(fallback_items.pop_front())
	_ensure_heirloom_anchor_offer(result)
	return result

func _pick_weighted_key(weights: Dictionary, fallback: String) -> String:
	var total_weight := 0
	for weight in weights.values():
		total_weight += int(weight)
	if total_weight <= 0:
		return fallback

	var roll := randi() % total_weight
	var cumulative := 0
	for key in weights.keys():
		cumulative += int(weights[key])
		if roll < cumulative:
			return str(key)
	return fallback

func _get_item_by_rarity_and_type(rarity: String, type_name: String) -> String:
	var candidates: Array[String] = []
	var weights: Dictionary = {}
	for item_id in game_state.ITEMS.keys():
		var item: Dictionary = game_state.ITEMS[item_id]
		if _can_offer_item(str(item_id), item) and item.get("rarity", "") == rarity and item.get("type", "") == type_name:
			var id := str(item_id)
			candidates.append(id)
			weights[id] = _get_item_offer_weight(id)
	if candidates.is_empty():
		return ""
	return _pick_weighted_key(weights, candidates[0])

func _get_item_offer_weight(item_id: String) -> int:
	var weight := 10
	if game_state == null:
		return weight
	var heirloom_id := str(game_state.get("selected_heirloom_id"))
	match heirloom_id:
		"shield_blade":
			if item_id in ["wooden_shield", "heart_mirror", "heart_armor", "thorn_armor"]:
				weight += 18
		"afterlife_lamp":
			if item_id in ["vampire_cross", "life_crystal", "life_armor", "soul_collector"]:
				weight += 18
		"broken_coin":
			if item_id in ["trade_ledger", "bounty_blade", "greedy_gloves"]:
				weight += 18
		"camp_banner":
			if item_id in ["tiger_tally", "unity_seal"]:
				weight += 18
		"blood_contract":
			if item_id in ["demon_blade", "blood_tyrant", "vampire_blade", "flesh_toxin"]:
				weight += 18
		"counter_sigil":
			if item_id in ["precision_guidance", "precision_auxiliary", "precision_calculation"]:
				weight += 18
	var tags: Array[String] = game_state.get_run_tendency_tags() if game_state.has_method("get_run_tendency_tags") else []
	if "defense" in tags and item_id in ["wooden_shield", "heart_mirror", "life_crystal", "life_armor", "soul_collector", "heart_armor", "thorn_armor", "vampire_cross", "tiger_tally"]:
		weight += 5
	if "economy" in tags and item_id in ["trade_ledger", "bounty_blade", "greedy_gloves"]:
		weight += 5
	if "aggression" in tags and item_id in ["long_sword", "demon_blade", "regicide", "blood_tyrant", "vampire_blade", "poison_coating", "flesh_toxin"]:
		weight += 5
	if "sustain" in tags and item_id in ["life_crystal", "life_armor", "soul_collector", "vampire_cross", "blood_tyrant", "vampire_blade", "unity_seal"]:
		weight += 5
	if "tempo" in tags and item_id in ["flesh_talisman", "plague_source"]:
		weight += 5
	if "tempo" in tags and item_id in ["precision_guidance", "precision_auxiliary", "precision_calculation", "ai_system", "unity_seal"]:
		weight += 5
	return weight

func _get_fallback_items(excluded_ids: Array[String]) -> Array[String]:
	var items: Array[String] = []
	for item_id in game_state.ITEMS.keys():
		var id := str(item_id)
		var item: Dictionary = game_state.ITEMS[item_id]
		if _can_offer_item(id, item) and not id in excluded_ids:
			items.append(id)
	return items

func _can_offer_item(item_id: String, item: Dictionary) -> bool:
	if not game_state.is_item_allowed_in_current_era(item):
		return false
	if game_state.has_item_anywhere(item_id):
		return false
	return true

func _get_type_weights() -> Dictionary:
	var weights := TYPE_WEIGHTS.duplicate(true)
	if game_state == null or not game_state.has_method("get_run_tendency_tags"):
		return weights
	var tags: Array[String] = game_state.get_run_tendency_tags()
	var intensity := float(game_state.get_run_tendency_strength()) if game_state.has_method("get_run_tendency_strength") else 1.0
	for tag in tags:
		match tag:
			"defense":
				weights["defense"] = int(round(float(weights.get("defense", 0)) + 10.0 * intensity))
				weights["special"] = int(round(float(weights.get("special", 0)) + 4.0 * intensity))
			"economy":
				weights["special"] = int(round(float(weights.get("special", 0)) + 11.0 * intensity))
				weights["attack"] = int(round(float(weights.get("attack", 0)) + 3.0 * intensity))
			"aggression":
				weights["attack"] = int(round(float(weights.get("attack", 0)) + 10.0 * intensity))
			"sustain":
				weights["defense"] = int(round(float(weights.get("defense", 0)) + 8.0 * intensity))
				weights["special"] = int(round(float(weights.get("special", 0)) + 3.0 * intensity))
			"tempo":
				weights["special"] = int(round(float(weights.get("special", 0)) + 7.0 * intensity))
	return weights

func _ensure_heirloom_anchor_offer(result: Array[String]) -> void:
	if game_state == null or result.is_empty():
		return
	var heirloom_id := str(game_state.get("selected_heirloom_id"))
	var anchors := _get_heirloom_anchor_items(heirloom_id)
	if anchors.is_empty() or _result_has_any(result, anchors):
		return
	for item_id in anchors:
		if not game_state.ITEMS.has(item_id):
			continue
		var item: Dictionary = game_state.ITEMS[item_id]
		if _can_offer_item(item_id, item):
			result[result.size() - 1] = item_id
			return

func _get_heirloom_anchor_items(heirloom_id: String) -> Array[String]:
	match heirloom_id:
		"shield_blade":
			return ["wooden_shield", "heart_mirror", "heart_armor", "thorn_armor"]
		"afterlife_lamp":
			return ["life_crystal", "vampire_cross", "life_armor", "soul_collector"]
		"broken_coin":
			return ["trade_ledger", "bounty_blade", "greedy_gloves"]
		"camp_banner":
			return ["tiger_tally", "unity_seal"]
		"blood_contract":
			return ["blood_tyrant", "demon_blade", "vampire_blade", "flesh_toxin"]
		"counter_sigil":
			return ["precision_guidance", "precision_auxiliary", "precision_calculation"]
	return []

func _result_has_any(result: Array[String], anchors: Array[String]) -> bool:
	for item_id in result:
		if item_id in anchors:
			return true
	return false
