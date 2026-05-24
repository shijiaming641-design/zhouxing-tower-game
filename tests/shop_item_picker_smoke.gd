extends SceneTree

const ShopItemPicker = preload("res://resources/shop_item_picker.gd")

func _finish(code: int, game_state: Node, original_era: String, original_heirloom: String = "", original_gold: int = 0, original_shield: int = 0) -> void:
	game_state.set("selected_era_id", original_era)
	game_state.set("selected_heirloom_id", original_heirloom)
	game_state.set("player_gold", original_gold)
	game_state.set("player_shield", original_shield)
	game_state.set("backpack", [])
	game_state.set("equipment_slot", [])
	quit(code)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_era := str(game_state.get("selected_era_id"))
	var original_heirloom := str(game_state.get("selected_heirloom_id"))
	var original_gold := int(game_state.get("player_gold"))
	var original_shield := int(game_state.get("player_shield"))
	game_state.set("selected_era_id", "qin")
	game_state.set("backpack", [])
	game_state.set("equipment_slot", [])

	var picker := ShopItemPicker.new(game_state)
	var items := picker.pick_shop_items(3)
	if items.size() != 3:
		push_error("Shop picker should return 3 items, got %d" % items.size())
		_finish(1, game_state, original_era, original_heirloom, original_gold, original_shield)
		return
	if _has_duplicates(items):
		push_error("Shop picker should not return duplicate items: %s" % str(items))
		_finish(1, game_state, original_era, original_heirloom, original_gold, original_shield)
		return

	game_state.add_to_equipment_slot(items[0])
	var next_items := picker.pick_shop_items(3)
	if items[0] in next_items:
		push_error("Shop picker should exclude already owned item: %s" % items[0])
		_finish(1, game_state, original_era, original_heirloom, original_gold, original_shield)
		return

	game_state.set("selected_heirloom_id", "shield_blade")
	game_state.set("player_shield", 5)
	game_state.set("player_gold", 18)
	game_state.set("backpack", [])
	game_state.set("equipment_slot", [])
	var weighted_types := picker._get_type_weights()
	if int(weighted_types.get("defense", 0)) <= int(ShopItemPicker.TYPE_WEIGHTS.get("defense", 0)):
		push_error("Shop picker should bias defense weights for shield-focused runs: %s" % str(weighted_types))
		_finish(1, game_state, original_era, original_heirloom, original_gold, original_shield)
		return
	if int(weighted_types.get("special", 0)) <= int(ShopItemPicker.TYPE_WEIGHTS.get("special", 0)):
		push_error("Shop picker should bias special weights for economy-focused runs: %s" % str(weighted_types))
		_finish(1, game_state, original_era, original_heirloom, original_gold, original_shield)
		return
	if picker._get_item_offer_weight("heart_mirror") <= picker._get_item_offer_weight("long_sword"):
		push_error("Shop picker should prioritize equipment that resonates with shield blade.")
		_finish(1, game_state, original_era, original_heirloom, original_gold, original_shield)
		return
	var shield_items := picker.pick_shop_items(3)
	if not _has_any(shield_items, ["wooden_shield", "heart_mirror", "heart_armor", "thorn_armor"]):
		push_error("Shop picker should guarantee a shield anchor for shield blade runs: %s" % str(shield_items))
		_finish(1, game_state, original_era, original_heirloom, original_gold, original_shield)
		return
	game_state.set("selected_heirloom_id", "counter_sigil")
	if picker._get_item_offer_weight("precision_guidance") <= picker._get_item_offer_weight("long_sword"):
		push_error("Shop picker should prioritize precision gear for counter sigil runs.")
		_finish(1, game_state, original_era, original_heirloom, original_gold, original_shield)
		return

	print("shop_item_picker_smoke: ok")
	_finish(0, game_state, original_era, original_heirloom, original_gold, original_shield)

func _has_duplicates(items: Array[String]) -> bool:
	var seen := {}
	for item_id in items:
		if seen.has(item_id):
			return true
		seen[item_id] = true
	return false

func _has_any(items: Array[String], candidates: Array[String]) -> bool:
	for item_id in items:
		if item_id in candidates:
			return true
	return false
