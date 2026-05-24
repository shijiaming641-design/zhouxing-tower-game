extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"player_gold": int(game_state.player_gold),
		"materials": int(game_state.materials),
		"selected_route_name": str(game_state.selected_route_name),
		"route_switch_count": int(game_state.route_switch_count)
	}

	game_state.player_gold = 10
	game_state.materials = 0
	game_state.selected_route_name = ""
	game_state.route_switch_count = 0

	if not game_state.commit_route_choice("远交线"):
		push_error("First route choice should lock the route.")
		_finish(1, game_state, original_state)
		return
	if game_state.selected_route_name != "远交线":
		push_error("Selected route should be 远交线, got: %s" % game_state.selected_route_name)
		_finish(1, game_state, original_state)
		return
	var switch_result: Dictionary = game_state.try_switch_route("近攻线")
	if not bool(switch_result.get("ok", false)):
		push_error("First route switch should be payable with 10 gold: %s" % str(switch_result))
		_finish(1, game_state, original_state)
		return
	if game_state.player_gold != 0 or game_state.route_switch_count != 1 or game_state.selected_route_name != "近攻线":
		push_error("Route switch should cost 10 gold and update route, got gold=%d switches=%d route=%s" % [game_state.player_gold, game_state.route_switch_count, game_state.selected_route_name])
		_finish(1, game_state, original_state)
		return
	switch_result = game_state.try_switch_route("远交线")
	if bool(switch_result.get("ok", false)):
		push_error("Second route switch should fail when gold is insufficient.")
		_finish(1, game_state, original_state)
		return
	if not game_state.force_route_choice("远交线"):
		push_error("Forced historical reroute should be allowed without gold.")
		_finish(1, game_state, original_state)
		return
	if game_state.player_gold != 0 or game_state.route_switch_count != 1 or game_state.selected_route_name != "远交线":
		push_error("Forced route choice should not cost gold or increase switch count.")
		_finish(1, game_state, original_state)
		return

	print("map_route_lock_smoke: ok")
	_finish(0, game_state, original_state)

func _finish(code: int, game_state: Node, original_state: Dictionary) -> void:
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.materials = int(original_state.get("materials", 0))
	game_state.selected_route_name = str(original_state.get("selected_route_name", ""))
	game_state.route_switch_count = int(original_state.get("route_switch_count", 0))
	quit(code)
