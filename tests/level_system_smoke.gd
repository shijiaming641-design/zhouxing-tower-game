extends SceneTree

func _initialize() -> void:
	var game_state = load("res://autoload/game_state.gd").new()

	var levels = game_state.add_exp(10)
	if levels.size() != 4:
		push_error("Expected to reach level 5 from 10 EXP, got levels: %s" % str(levels))
		quit(1)
		return

	if game_state.player_level != 5:
		push_error("Expected player level 5, got %d" % game_state.player_level)
		quit(1)
		return

	if game_state.get_current_equipment_slot_limit() != 4:
		push_error("Expected 4 equipment slots at level 5, got %d" % game_state.get_current_equipment_slot_limit())
		quit(1)
		return

	if game_state.get_current_backpack_limit() != 7:
		push_error("Expected 7 backpack slots at level 5, got %d" % game_state.get_current_backpack_limit())
		quit(1)
		return

	if game_state.unspent_attribute_points != 2:
		push_error("Expected 2 unspent attribute points at level 5, got %d" % game_state.unspent_attribute_points)
		quit(1)
		return

	if not game_state.allocate_level_stat("hp"):
		push_error("Expected HP attribute allocation to succeed")
		quit(1)
		return

	if not game_state.allocate_level_stat("atk"):
		push_error("Expected ATK attribute allocation to succeed")
		quit(1)
		return

	if game_state.bonus_hp_from_level != 2 or game_state.bonus_atk_from_level != 1:
		push_error("Unexpected level stat totals: hp=%d atk=%d" % [game_state.bonus_hp_from_level, game_state.bonus_atk_from_level])
		quit(1)
		return

	game_state.unspent_attribute_points = 1
	game_state.bonus_hp_from_level = game_state.MAX_LEVEL_HP_BONUS
	if game_state.allocate_level_stat("hp"):
		push_error("HP allocation should fail at cap")
		quit(1)
		return

	print("level_system_smoke: ok")
	quit()
