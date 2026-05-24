extends SceneTree

func _finish(code: int, game_state: Node = null) -> void:
	if game_state != null:
		game_state.free()
	quit(code)

func _initialize() -> void:
	var game_state = load("res://autoload/game_state.gd").new()

	var level2_state = load("res://autoload/game_state.gd").new()
	var level2_levels = level2_state.add_exp(1)
	if level2_levels.size() != 1 or level2_state.player_level != 2:
		push_error("Expected level 2 from 1 EXP, got level=%d levels=%s" % [level2_state.player_level, str(level2_levels)])
		_finish(1, level2_state)
		return
	if level2_state.unspent_attribute_points != 1:
		push_error("Expected level 2 to grant one in-run boost, got %d" % level2_state.unspent_attribute_points)
		_finish(1, level2_state)
		return
	if not level2_state.allocate_level_stat("cheat") or level2_state.cheat_points != 1 or level2_state.get_max_cheat_points() != 3:
		push_error("Expected level 2 整阵 to grant one cheat point and one storage cap, points=%d cap=%d." % [level2_state.cheat_points, level2_state.get_max_cheat_points()])
		_finish(1, level2_state)
		return
	level2_state.unspent_attribute_points = 1
	level2_state.cheat_points = level2_state.get_max_cheat_points()
	var full_before: int = int(level2_state.cheat_points)
	if not level2_state.allocate_level_stat("cheat") or level2_state.get_max_cheat_points() != full_before + 1 or level2_state.cheat_points != full_before + 1:
		push_error("Expected 整阵 to increase storage even when cheat points are full, before=%d points=%d cap=%d." % [full_before, level2_state.cheat_points, level2_state.get_max_cheat_points()])
		_finish(1, level2_state)
		return
	level2_state.free()

	var levels = game_state.add_exp(10)
	if levels.size() != 4:
		push_error("Expected to reach level 5 from 10 EXP, got levels: %s" % str(levels))
		_finish(1, game_state)
		return

	if game_state.player_level != 5:
		push_error("Expected player level 5, got %d" % game_state.player_level)
		_finish(1, game_state)
		return

	if game_state.get_current_equipment_slot_limit() != 4:
		push_error("Expected 4 equipment slots at level 5, got %d" % game_state.get_current_equipment_slot_limit())
		_finish(1, game_state)
		return

	if game_state.get_current_backpack_limit() != 7:
		push_error("Expected 7 backpack slots at level 5, got %d" % game_state.get_current_backpack_limit())
		_finish(1, game_state)
		return

	if game_state.unspent_attribute_points != 2:
		push_error("Expected 2 unspent in-run boosts at level 5, got %d" % game_state.unspent_attribute_points)
		_finish(1, game_state)
		return

	if not game_state.allocate_level_stat("hp"):
		push_error("Expected HP attribute allocation to succeed")
		_finish(1, game_state)
		return

	if not game_state.allocate_level_stat("atk"):
		push_error("Expected ATK attribute allocation to succeed")
		_finish(1, game_state)
		return

	if game_state.bonus_hp_from_level != 2 or game_state.bonus_atk_from_level != 1:
		push_error("Unexpected level stat totals: hp=%d atk=%d" % [game_state.bonus_hp_from_level, game_state.bonus_atk_from_level])
		_finish(1, game_state)
		return

	game_state.unspent_attribute_points = 1
	game_state.bonus_hp_from_level = game_state.MAX_LEVEL_HP_BONUS
	if game_state.allocate_level_stat("hp"):
		push_error("HP allocation should fail at cap")
		_finish(1, game_state)
		return

	print("level_system_smoke: ok")
	_finish(0, game_state)
