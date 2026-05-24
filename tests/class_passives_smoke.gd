extends SceneTree

func _finish(code: int, game_state: Node = null) -> void:
	if game_state != null:
		game_state.free()
	quit(code)

func _initialize() -> void:
	var game_state = load("res://autoload/game_state.gd").new()

	game_state.player_class = 1
	game_state.cheat_points = 0
	game_state.init_class_abilities(1)
	if game_state.cheat_points != 1:
		push_error("Hacker should start with 1 cheat point")
		_finish(1, game_state)
		return
	if game_state.get_max_cheat_points() != 3:
		push_error("Hacker cheat point cap should be 3")
		_finish(1, game_state)
		return
	game_state.add_cheat_point()
	game_state.add_cheat_point()
	game_state.add_cheat_point()
	if game_state.cheat_points != 3:
		push_error("Hacker cheat point cap not enforced correctly: %d" % game_state.cheat_points)
		_finish(1, game_state)
		return

	game_state.player_class = 2
	game_state.player_gold = 0
	game_state.current_floor = 4
	game_state.last_rest_income_floor = -1
	if not game_state.on_enter_rest_point():
		push_error("Merchant should gain gold when entering rest point")
		_finish(1, game_state)
		return
	if game_state.player_gold != 16:
		push_error("Merchant rest income should grant 16 gold in 秦 era, got %d" % game_state.player_gold)
		_finish(1, game_state)
		return
	if game_state.on_enter_rest_point():
		push_error("Merchant should not gain rest income twice on same floor")
		_finish(1, game_state)
		return
	game_state.player_gold = 25
	game_state.player_shield = 0
	game_state.field_pending_merchant_attack = 0
	game_state.setup_pre_battle()
	if game_state.player_shield != 2:
		push_error("Merchant should convert held gold into pre-battle shield, got %d" % game_state.player_shield)
		_finish(1, game_state)
		return
	game_state.register_gold_spent_for_field(25)
	if game_state.field_pending_merchant_attack != 2:
		push_error("Merchant should bank spent gold as pending hit damage, got %d" % game_state.field_pending_merchant_attack)
		_finish(1, game_state)
		return
	var trade_bonus: Dictionary = game_state.consume_field_attack_bonus()
	if int(trade_bonus.get("merchant", 0)) != 2 or int(trade_bonus.get("total", 0)) != 2:
		push_error("Merchant pending trade damage should cash out on hit, got %s" % str(trade_bonus))
		_finish(1, game_state)
		return

	game_state.player_class = 3
	game_state.player_shield = 4
	game_state.equipment_slot.clear()
	game_state.backpack.clear()
	game_state.unequip_all_after_battle()
	if game_state.player_shield != 4:
		push_error("Farmer shield should persist between battles")
		_finish(1, game_state)
		return
	game_state.player_shield = 99
	game_state.unequip_all_after_battle()
	if game_state.player_shield != game_state.get_farmer_shield_soft_cap():
		push_error("Farmer shield carryover should be capped to avoid infinite armor loops, got %d cap %d" % [game_state.player_shield, game_state.get_farmer_shield_soft_cap()])
		_finish(1, game_state)
		return

	game_state.player_class = 0
	game_state.player_shield = 4
	game_state.unequip_all_after_battle()
	if game_state.player_shield != 0:
		push_error("Non-farmer shield should clear after battle")
		_finish(1, game_state)
		return

	print("class_passives_smoke: ok")
	_finish(0, game_state)
