extends SceneTree

func _initialize() -> void:
	var game_state = load("res://autoload/game_state.gd").new()
	game_state.meta_upgrades.clear()
	game_state.memory_cores = 32

	if not game_state.purchase_meta_upgrade("basic_combo_slot").get("success", false):
		push_error("Expected basic combo slot purchase to succeed")
		quit(1)
		return
	if not game_state.purchase_meta_upgrade("draw_protection").get("success", false):
		push_error("Expected draw protection purchase to succeed")
		quit(1)
		return
	if not game_state.purchase_meta_upgrade("combo_cooldown").get("success", false):
		push_error("Expected combo cooldown purchase to succeed")
		quit(1)
		return

	game_state.reset_game()
	if game_state.max_combo_slots != 2:
		push_error("Expected meta combo slot to set max_combo_slots to 2, got %d" % game_state.max_combo_slots)
		quit(1)
		return

	game_state.apply_meta_start_bonuses()
	if not game_state.draw_protection_available:
		push_error("Expected draw protection to be available at run start")
		quit(1)
		return
	if not game_state.arm_draw_protection():
		push_error("Expected draw protection to arm after draw")
		quit(1)
		return
	if not game_state.consume_draw_protection():
		push_error("Expected draw protection to consume on next damage")
		quit(1)
		return

	game_state.trigger_combo("test_combo", 3)
	if game_state.get_combo_cooldown("test_combo") != 2:
		push_error("Expected meta cooldown reduction to reduce 3 to 2, got %d" % game_state.get_combo_cooldown("test_combo"))
		quit(1)
		return

	print("meta_upgrade_smoke: ok")
	quit()
