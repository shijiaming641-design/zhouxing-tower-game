extends SceneTree

const ShopFlow = preload("res://resources/shop_flow.gd")

func _finish(code: int, game_state: Node, original_state: Dictionary) -> void:
	for key in original_state.keys():
		game_state.set(key, original_state[key])
	quit(code)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var event_bus := root.get_node("/root/EventBus")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"player_gold": int(game_state.player_gold),
		"materials": int(game_state.materials),
		"backpack": game_state.backpack.duplicate(true),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"current_shop_items": game_state.current_shop_items.duplicate(true),
		"shop_discount": float(game_state.shop_discount)
	}

	game_state.set("selected_era_id", "qin")
	game_state.set("player_gold", 100)
	game_state.set("materials", 0)
	game_state.backpack.clear()
	game_state.equipment_slot.clear()
	game_state.set("current_shop_items", ["long_sword"])
	game_state.set("shop_discount", 1.0)

	var flow := ShopFlow.new(game_state, 3, event_bus)
	var buy_result := flow.buy_item("long_sword")
	if not bool(buy_result.get("ok", false)):
		push_error("ShopFlow should buy long_sword: %s" % str(buy_result))
		_finish(1, game_state, original_state)
		return
	if int(game_state.player_gold) >= 100 or not game_state.has_item_anywhere("long_sword"):
		push_error("ShopFlow buy should spend gold and grant item")
		_finish(1, game_state, original_state)
		return
	if "long_sword" in game_state.current_shop_items:
		push_error("ShopFlow buy should remove item from current shop list")
		_finish(1, game_state, original_state)
		return

	var gold_after_buy := int(game_state.player_gold)
	var refresh_result := flow.refresh_shop()
	if not bool(refresh_result.get("ok", false)):
		push_error("ShopFlow should refresh shop: %s" % str(refresh_result))
		_finish(1, game_state, original_state)
		return
	if int(game_state.player_gold) != gold_after_buy - 3:
		push_error("ShopFlow refresh should cost 3 gold in qin")
		_finish(1, game_state, original_state)
		return

	var material_result := flow.buy_material()
	if bool(material_result.get("ok", false)) or int(game_state.materials) != 0:
		push_error("ShopFlow should no longer sell materials")
		_finish(1, game_state, original_state)
		return

	print("shop_flow_smoke: ok")
	_finish(0, game_state, original_state)
