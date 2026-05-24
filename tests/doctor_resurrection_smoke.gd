extends SceneTree

func _finish(code: int, game_state: Node = null) -> void:
	if game_state != null:
		game_state.free()
	quit(code)

func _initialize() -> void:
	var game_state = load("res://autoload/game_state.gd").new()
	game_state.init_class_abilities(0)
	game_state.player_max_hp = 9
	game_state.player_hp = 9

	game_state.player_hp = 0
	if not game_state.try_resurrection():
		push_error("Doctor resurrection should auto trigger when HP reaches 0")
		_finish(1, game_state)
		return

	var expected_hp = int(ceil(float(game_state.player_max_hp) * 0.70))
	if game_state.player_hp != expected_hp:
		push_error("Doctor resurrection restored unexpected HP: %d" % game_state.player_hp)
		_finish(1, game_state)
		return

	if game_state.player_shield != 2:
		push_error("Doctor resurrection should grant 2 armor, got %d" % game_state.player_shield)
		_finish(1, game_state)
		return

	if not game_state.resurrection_used:
		push_error("Doctor resurrection should be marked used after triggering")
		_finish(1, game_state)
		return

	game_state.player_hp = 0
	if game_state.try_resurrection():
		push_error("Doctor resurrection should not trigger a second time in one run")
		_finish(1, game_state)
		return

	print("doctor_resurrection_smoke: ok")
	_finish(0, game_state)
