extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"equipped_combos": game_state.equipped_combos.duplicate(true),
		"combo_cooldowns": game_state.combo_cooldowns.duplicate(true)
	}

	var main = load("res://scenes/main.gd").new()
	root.add_child(main)
	game_state.equipped_combos.clear()
	game_state.equipped_combos.append("penetrating_strike")
	game_state.combo_cooldowns.clear()

	main.combo_sequence.clear()
	main.combo_sequence.append(1)
	var early_text := str(main._get_layout_momentum_text("失一手"))
	if early_text.find("失一手") < 0 or early_text.find("暗势") < 0 or early_text.find("1/3") < 0:
		_fail("Dark layout momentum should show progress even when the exchange is lost, got: %s" % early_text, game_state, original_state, main)
		return

	main.combo_sequence.append(1)
	var near_text := str(main._get_layout_momentum_text("对面压来"))
	if near_text.find("对面压来") < 0 or near_text.find("临门") < 0:
		_fail("Dark layout momentum should show impending completion under pressure, got: %s" % near_text, game_state, original_state, main)
		return

	main._battle_momentum_score = -2
	var battle := Control.new()
	root.add_child(battle)
	var triggered: Array[Dictionary] = [{"length": 3}]
	var completion_text := str(main._apply_layout_completion_momentum(triggered, battle))
	if completion_text.find("暗势兑现") < 0 or int(main._battle_momentum_score) != -1:
		_fail("Layout completion should pull visible momentum back by one step, text=%s score=%d" % [completion_text, main._battle_momentum_score], game_state, original_state, main, battle)
		return
	battle.free()

	print("layout_momentum_smoke: ok")
	_finish(0, game_state, original_state, main)

func _fail(message: String, game_state: Node, original_state: Dictionary, main: Node, battle: Node = null) -> void:
	push_error(message)
	if battle != null and is_instance_valid(battle):
		battle.free()
	_finish(1, game_state, original_state, main)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node) -> void:
	game_state.equipped_combos = (original_state.get("equipped_combos", []) as Array).duplicate(true)
	game_state.combo_cooldowns = (original_state.get("combo_cooldowns", {}) as Dictionary).duplicate(true)
	if main != null and is_instance_valid(main):
		main._dispose_combo_database_cache()
		main.free()
	quit(code)
