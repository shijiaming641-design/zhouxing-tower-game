extends SceneTree

func _initialize() -> void:
	var game_state = load("res://autoload/game_state.gd").new()

	game_state.player_class = 1
	game_state.cheat_points = 0
	game_state.init_class_abilities(1)
	if game_state.cheat_points != 1:
		push_error("Hacker should start with 1 cheat point")
		quit(1)
		return
	if game_state.get_max_cheat_points() != 3:
		push_error("Hacker cheat point cap should be 3")
		quit(1)
		return
	game_state.add_cheat_point()
	game_state.add_cheat_point()
	game_state.add_cheat_point()
	if game_state.cheat_points != 3:
		push_error("Hacker cheat point cap not enforced correctly: %d" % game_state.cheat_points)
		quit(1)
		return

	game_state.player_class = 2
	game_state.player_gold = 0
	game_state.current_floor = 4
	game_state.last_rest_income_floor = -1
	if not game_state.on_enter_rest_point():
		push_error("Merchant should gain gold when entering rest point")
		quit(1)
		return
	if game_state.player_gold != 20:
		push_error("Merchant rest income should grant 20 gold, got %d" % game_state.player_gold)
		quit(1)
		return
	if game_state.on_enter_rest_point():
		push_error("Merchant should not gain rest income twice on same floor")
		quit(1)
		return

	game_state.player_class = 3
	game_state.player_shield = 4
	game_state.equipment_slot.clear()
	game_state.backpack.clear()
	game_state.unequip_all_after_battle()
	if game_state.player_shield != 4:
		push_error("Farmer shield should persist between battles")
		quit(1)
		return

	game_state.player_class = 0
	game_state.player_shield = 4
	game_state.unequip_all_after_battle()
	if game_state.player_shield != 0:
		push_error("Non-farmer shield should clear after battle")
		quit(1)
		return

	print("class_passives_smoke: ok")
	quit()
