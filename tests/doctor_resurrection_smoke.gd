extends SceneTree

func _initialize() -> void:
	var game_state = load("res://autoload/game_state.gd").new()
	game_state.init_class_abilities(0)
	game_state.player_max_hp = 9
	game_state.player_hp = 9

	game_state.player_hp = 0
	if not game_state.try_resurrection():
		push_error("Doctor resurrection should auto trigger when HP reaches 0")
		quit(1)
		return

	if game_state.player_hp != game_state.player_max_hp:
		push_error("Doctor resurrection restored unexpected HP: %d" % game_state.player_hp)
		quit(1)
		return

	if not game_state.resurrection_used:
		push_error("Doctor resurrection should be marked used after triggering")
		quit(1)
		return

	game_state.player_hp = 0
	if game_state.try_resurrection():
		push_error("Doctor resurrection should not trigger a second time in one run")
		quit(1)
		return

	print("doctor_resurrection_smoke: ok")
	quit()
