class_name ShopFlow
extends RefCounted

var game_state: Node
var event_bus: Node
var refresh_base_cost: int

func _init(state: Node, base_refresh_cost: int = 3, bus: Node = null) -> void:
	game_state = state
	refresh_base_cost = base_refresh_cost
	event_bus = bus

func get_refresh_cost() -> int:
	var cost := int(game_state.get_era_refresh_cost(refresh_base_cost))
	if game_state.has_item("trade_ledger"):
		cost = maxi(cost - 1, 1)
	return cost

func get_item_price(item: Dictionary) -> int:
	var cost := int(round(float(item.get("cost", 0)) * float(game_state.shop_discount) * float(game_state.get_era_price_multiplier())))
	return maxi(cost, 1)

func refresh_shop() -> Dictionary:
	var cost := get_refresh_cost()
	if int(game_state.player_gold) < cost:
		return {"ok": false, "message": "Not enough gold to refresh shop", "notice": "金币不足，刷新还差%d" % (cost - int(game_state.player_gold)), "cost": cost}
	game_state.player_gold -= cost
	game_state.register_gold_spent_for_field(cost)
	game_state.current_shop_items.clear()
	game_state.save_progress("shop")
	return {"ok": true, "message": "Shop refreshed", "notice": "商队已换货，消耗%d金币" % cost, "cost": cost}

func buy_item(item_id: String) -> Dictionary:
	var item: Dictionary = game_state.ITEMS.get(item_id, {})
	if item.is_empty():
		return {"ok": false, "message": "Item not found", "notice": "此器物已不可购买"}
	if game_state.has_item_anywhere(item_id):
		return {"ok": false, "message": "Already owned", "notice": "已持有同名器物，商队不会重复出售"}
	if game_state.backpack.size() >= game_state.get_current_backpack_limit():
		return {"ok": false, "message": "Backpack full", "notice": "背包已满，无法纳入新器物"}

	var cost := get_item_price(item)
	if int(game_state.player_gold) < cost:
		return {"ok": false, "message": "Not enough gold", "notice": "金币不足，还差%d" % (cost - int(game_state.player_gold))}

	game_state.player_gold -= cost
	game_state.register_gold_spent_for_field(cost)

	var destination := "equipment"
	if game_state.equipment_slot.size() < game_state.get_max_equipment_slots():
		game_state.add_to_equipment_slot(item_id)
	else:
		destination = "backpack"
		game_state.add_to_backpack(item_id)

	game_state.current_shop_items.erase(item_id)
	game_state.save_progress("shop")
	return {
		"ok": true,
		"message": "Bought item",
		"notice": _build_purchase_notice(item, destination),
		"cost": cost,
		"destination": destination
	}

func sell_item(index: int, from_backpack: bool = true) -> Dictionary:
	if not game_state.sell_item(index, from_backpack):
		return {"ok": false, "message": "Sell failed"}
	game_state.save_progress("shop")
	return {"ok": true, "message": "Sold item"}

func buy_material() -> Dictionary:
	return {"ok": false, "message": "Materials removed", "notice": "材料已取消，金币直接用于强化", "cost": 0}

func _build_purchase_notice(item: Dictionary, destination: String) -> String:
	var destination_text := "已装备" if destination == "equipment" else "已入背包"
	var notice := "%s：%s" % [destination_text, game_state.get_item_display_name(item)]
	if destination == "equipment":
		notice += "\n当前已生效"
	else:
		notice += "\n装备后生效"
	return notice
