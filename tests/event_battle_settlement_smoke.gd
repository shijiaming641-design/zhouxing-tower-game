extends SceneTree

func _finish(code: int, game_state: Node = null, original_era: String = "qin", original_hp: int = 6, original_max_hp: int = 6) -> void:
	if game_state != null:
		game_state.set("selected_era_id", original_era)
		game_state.backpack.clear()
		game_state.equipment_slot.clear()
		game_state.set("shop_discount", 1.0)
		game_state.set("player_gold", 0)
		game_state.set("materials", 0)
		game_state.set("player_max_hp", original_max_hp)
		game_state.set("player_hp", original_hp)
	quit(code)

func _initialize() -> void:
	call_deferred("_run")

func _win_rounds(manager: Node) -> void:
	manager.process_event_battle_round(0, 1)
	manager.process_event_battle_round(0, 1)
	manager.process_event_battle_round(0, 1)

func _lose_rounds(manager: Node) -> void:
	manager.process_event_battle_round(0, 2)
	manager.process_event_battle_round(0, 2)
	manager.process_event_battle_round(0, 2)

func _one_counted_win(manager: Node) -> void:
	manager.process_event_battle_round(0, 1)
	manager.process_event_battle_round(0, 1)
	manager.process_event_battle_round(0, 2)

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var manager := root.get_node("/root/RandomEventManager")
	var original_era := str(game_state.get("selected_era_id"))
	var original_hp := int(game_state.get("player_hp"))
	var original_max_hp := int(game_state.get("player_max_hp"))

	game_state.set("selected_era_id", "qin")
	game_state.backpack.clear()
	game_state.equipment_slot.clear()
	game_state.set("shop_discount", 1.0)

	manager.reset_state()
	manager.start_event_battle(true, {"battle_type": "random_equip", "event_data": {"event_id": "random_equip_duel"}})
	_win_rounds(manager)
	manager.finish_event_battle()
	if game_state.backpack.is_empty():
		push_error("Event random equipment battle should add a real backpack item")
		_finish(1, game_state, original_era, original_hp, original_max_hp)
		return

	manager.reset_state()
	game_state.set("shop_discount", 1.0)
	manager.start_event_battle(true, {"battle_type": "shop_discount", "event_data": {"event_id": "shop_discount_duel"}})
	manager.process_event_battle_round(0, 1)
	manager.process_event_battle_round(0, 1)
	manager.process_event_battle_round(0, 2)
	manager.finish_event_battle()
	if not is_equal_approx(float(game_state.shop_discount), 0.8):
		push_error("Event shop discount battle should set 8折 for one counted win, got %.2f" % game_state.shop_discount)
		_finish(1, game_state, original_era, original_hp, original_max_hp)
		return

	manager.reset_state()
	game_state.backpack.clear()
	game_state.backpack.append(game_state.ITEMS["long_sword"].duplicate(true))
	manager.start_event_battle(false, {"battle_type": "equip_loss", "event_data": {"event_id": "equip_loss_duel"}})
	manager.process_event_battle_round(0, 1)
	manager.process_event_battle_round(0, 2)
	manager.process_event_battle_round(0, 2)
	manager.finish_event_battle()
	if not game_state.backpack.is_empty():
		push_error("Event equipment loss battle should remove a backpack item when available")
		_finish(1, game_state, original_era, original_hp, original_max_hp)
		return

	manager.reset_state()
	game_state.backpack.clear()
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["wooden_shield"].duplicate(true))
	manager.start_event_battle(false, {"battle_type": "equip_loss", "event_data": {"event_id": "equip_loss_duel"}})
	manager.process_event_battle_round(0, 1)
	manager.process_event_battle_round(0, 2)
	manager.process_event_battle_round(0, 2)
	manager.finish_event_battle()
	if not game_state.equipment_slot.is_empty():
		push_error("Event equipment loss battle should remove equipped item when backpack is empty")
		_finish(1, game_state, original_era, original_hp, original_max_hp)
		return

	manager.reset_state()
	game_state.set("player_gold", 0)
	game_state.set("materials", 0)
	manager.start_event_battle(true, {"battle_type": "good_gamble_bonus", "event_data": {"event_id": "gold_cache", "subtype": 4, "value": 10}})
	_win_rounds(manager)
	manager.finish_event_battle()
	if int(game_state.player_gold) != 16 or int(game_state.materials) != 0:
		push_error("Good gamble 2 wins should grant base reward plus bonus, got gold=%d materials=%d" % [game_state.player_gold, game_state.materials])
		_finish(1, game_state, original_era, original_hp, original_max_hp)
		return

	manager.reset_state()
	game_state.set("player_gold", 0)
	game_state.set("materials", 0)
	manager.start_event_battle(true, {"battle_type": "good_gamble_bonus", "event_data": {"event_id": "gold_cache", "subtype": 4, "value": 10}})
	_lose_rounds(manager)
	manager.finish_event_battle()
	if int(game_state.player_gold) != 6 or int(game_state.materials) != 0:
		push_error("Good gamble 0 wins should grant consolation gold, got gold=%d materials=%d" % [game_state.player_gold, game_state.materials])
		_finish(1, game_state, original_era, original_hp, original_max_hp)
		return

	manager.reset_state()
	game_state.set("player_gold", 10)
	game_state.set("materials", 0)
	game_state.set("player_max_hp", 6)
	game_state.set("player_hp", 6)
	manager.start_event_battle(false, {"battle_type": "bad_gamble_relief", "event_data": {"event_id": "gold_loss", "subtype": 6, "value": 5}})
	_win_rounds(manager)
	manager.finish_event_battle()
	if int(game_state.player_gold) != 16 or int(game_state.materials) != 0 or int(game_state.player_hp) != 6:
		push_error("Bad gamble 2 wins should avoid loss and grant gold, got gold=%d materials=%d hp=%d" % [game_state.player_gold, game_state.materials, game_state.player_hp])
		_finish(1, game_state, original_era, original_hp, original_max_hp)
		return

	manager.reset_state()
	game_state.set("player_gold", 10)
	game_state.set("materials", 0)
	game_state.set("player_max_hp", 6)
	game_state.set("player_hp", 6)
	manager.start_event_battle(false, {"battle_type": "bad_gamble_relief", "event_data": {"event_id": "gold_loss", "subtype": 6, "value": 5}})
	_one_counted_win(manager)
	manager.finish_event_battle()
	if int(game_state.player_gold) != 10 or int(game_state.player_hp) != 5:
		push_error("Bad gamble 1 win should keep original penalty away and cost 1 hp, got gold=%d hp=%d" % [game_state.player_gold, game_state.player_hp])
		_finish(1, game_state, original_era, original_hp, original_max_hp)
		return

	manager.reset_state()
	game_state.set("player_gold", 10)
	game_state.set("materials", 0)
	game_state.set("player_max_hp", 6)
	game_state.set("player_hp", 6)
	manager.start_event_battle(false, {"battle_type": "bad_gamble_relief", "event_data": {"event_id": "gold_loss", "subtype": 6, "value": 5}})
	_lose_rounds(manager)
	manager.finish_event_battle()
	if int(game_state.player_gold) != 10 or int(game_state.player_hp) != 4:
		push_error("Bad gamble 0 wins should keep original penalty away and cost 2 hp, got gold=%d hp=%d" % [game_state.player_gold, game_state.player_hp])
		_finish(1, game_state, original_era, original_hp, original_max_hp)
		return

	manager.reset_state()
	game_state.set("player_gold", 10)
	game_state.set("materials", 0)
	game_state.set("player_max_hp", 6)
	game_state.set("player_hp", 1)
	manager.start_event_battle(false, {"battle_type": "bad_gamble_relief", "event_data": {"event_id": "gold_loss", "subtype": 6, "value": 5}})
	_lose_rounds(manager)
	manager.finish_event_battle()
	if int(game_state.player_gold) != 10 or int(game_state.player_hp) != 1:
		push_error("Bad gamble should not kill player at 1 hp, got gold=%d hp=%d" % [game_state.player_gold, game_state.player_hp])
		_finish(1, game_state, original_era, original_hp, original_max_hp)
		return

	print("event_battle_settlement_smoke: ok")
	_finish(0, game_state, original_era, original_hp, original_max_hp)
