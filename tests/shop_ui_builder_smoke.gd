extends SceneTree

const ShopFlow = preload("res://resources/shop_flow.gd")
const ShopUiBuilder = preload("res://resources/shop_ui_builder.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var event_bus := root.get_node("/root/EventBus")
	var original_gold := int(game_state.player_gold)
	var original_items: Array = game_state.current_shop_items.duplicate(true)
	var test_item_id := "long_sword"
	game_state.set("player_gold", 100)
	game_state.set("current_shop_items", [test_item_id])

	var flow := ShopFlow.new(game_state, 3, event_bus)
	var shop := ShopUiBuilder.new(game_state, flow).build({
		"shop_items": [test_item_id],
		"buy_material_callback": Callable(self, "_noop_shop"),
		"buy_item_callback": Callable(self, "_noop_item_shop"),
		"refresh_callback": Callable(self, "_noop_shop"),
		"back_callback": Callable(self, "_noop"),
		"next_callback": Callable(self, "_noop")
	})

	if shop.name != "ShopScene":
		push_error("Shop UI root should be named ShopScene")
		_restore(game_state, original_gold, original_items, 1, shop)
		return
	for node_name in ["GoldLabel", "ShopNotice", "RefreshBtn", "EquipTitle", "BackpackTitle", "BackBtn", "NextBtn"]:
		if shop.get_node_or_null(node_name) == null:
			push_error("Shop UI missing node: %s" % node_name)
			_restore(game_state, original_gold, original_items, 1, shop)
			return
	var item_card := shop.get_node_or_null("ShopItem_%s" % test_item_id)
	if item_card == null:
		push_error("Shop UI should include test item card: %s" % test_item_id)
		_restore(game_state, original_gold, original_items, 1, shop)
		return
	if item_card.get_node_or_null("CardFrame") == null or item_card.get_node_or_null("ItemIcon") == null:
		push_error("Shop item card should use art frame and icon content")
		_restore(game_state, original_gold, original_items, 1, shop)
		return
	var attr_label := item_card.get_node_or_null("ItemAttributeLine") as Label
	if attr_label == null or attr_label.text.find("攻击+2") < 0:
		push_error("Shop weapon card should show weapon attributes, got: %s" % (attr_label.text if attr_label != null else "<missing>"))
		_restore(game_state, original_gold, original_items, 1, shop)
		return
	if item_card.tooltip_text.find("属性：攻击+2") < 0 or item_card.tooltip_text.find("详情：") < 0 or item_card.tooltip_text.find("价格：") < 0:
		push_error("Shop item tooltip should show full details, got: %s" % item_card.tooltip_text)
		_restore(game_state, original_gold, original_items, 1, shop)
		return

	print("shop_ui_builder_smoke: ok")
	_restore(game_state, original_gold, original_items, 0, shop)

func _restore(game_state: Node, original_gold: int, original_items: Array, code: int, shop: Control = null) -> void:
	if shop != null:
		shop.free()
	game_state.set("player_gold", original_gold)
	game_state.set("current_shop_items", original_items)
	quit(code)

func _noop() -> void:
	pass

func _noop_shop(_shop: Control) -> void:
	pass

func _noop_item_shop(_item_id: String, _shop: Control) -> void:
	pass
