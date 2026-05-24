extends SceneTree

func _finish(code: int, game_state: Node = null) -> void:
	if game_state != null:
		game_state.free()
	quit(code)

func _initialize() -> void:
	var game_state = load("res://autoload/game_state.gd").new()
	game_state.suppress_save_progress = true
	game_state.meta_upgrades.clear()
	game_state.era_first_clears = {"qin": true, "song": true}
	game_state.memory_cores = 32

	if not game_state.purchase_meta_upgrade("basic_combo_slot").get("success", false):
		push_error("Expected basic combo slot purchase to succeed")
		_finish(1, game_state)
		return
	if not game_state.purchase_meta_upgrade("draw_protection").get("success", false):
		push_error("Expected draw protection purchase to succeed")
		_finish(1, game_state)
		return
	if not game_state.purchase_meta_upgrade("combo_cooldown").get("success", false):
		push_error("Expected combo cooldown purchase to succeed")
		_finish(1, game_state)
		return

	game_state.reset_game()
	if game_state.max_combo_slots != 2:
		push_error("Expected meta combo slot to set max_combo_slots to 2, got %d" % game_state.max_combo_slots)
		_finish(1, game_state)
		return

	game_state.apply_meta_start_bonuses()
	if not game_state.draw_protection_available:
		push_error("Expected draw protection to be available at run start")
		_finish(1, game_state)
		return
	if not game_state.arm_draw_protection():
		push_error("Expected draw protection to arm after draw")
		_finish(1, game_state)
		return
	if not game_state.consume_draw_protection():
		push_error("Expected draw protection to consume on next damage")
		_finish(1, game_state)
		return

	game_state.trigger_combo("test_combo", 3)
	if game_state.get_combo_cooldown("test_combo") != 2:
		push_error("Expected meta cooldown reduction to reduce 3 to 2, got %d" % game_state.get_combo_cooldown("test_combo"))
		_finish(1, game_state)
		return

	print("meta_upgrade_smoke: ok")
	_finish(0, game_state)
