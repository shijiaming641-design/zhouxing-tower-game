extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"current_floor": int(game_state.current_floor),
		"max_floors": int(game_state.max_floors),
		"selected_era_id": str(game_state.selected_era_id),
		"acknowledged_major_layer_debuffs": game_state.acknowledged_major_layer_debuffs.duplicate()
	}

	game_state.max_floors = int(game_state.TOTAL_SMALL_FLOORS)
	game_state.selected_era_id = "song"
	game_state.acknowledged_major_layer_debuffs.clear()

	for floor_index in [0, 19, 38]:
		game_state.current_floor = floor_index
		if not game_state.should_show_current_major_layer_debuff():
			push_error("Major layer debuff should show at floor %d" % floor_index)
			_restore(game_state, original_state, 1)
			return
		var info: Dictionary = game_state.get_current_major_layer_debuff()
		if str(info.get("debuff_name", "")) == "" or str(info.get("floor_range", "")) == "":
			push_error("Major layer debuff info should include name and floor range: %s" % str(info))
			_restore(game_state, original_state, 1)
			return
		game_state.mark_current_major_layer_debuff_seen()
		if game_state.should_show_current_major_layer_debuff():
			push_error("Major layer debuff should not repeat after acknowledgement at floor %d" % floor_index)
			_restore(game_state, original_state, 1)
			return

	game_state.current_floor = 20
	if game_state.should_show_current_major_layer_debuff():
		push_error("Major layer debuff should not show inside a layer.")
		_restore(game_state, original_state, 1)
		return

	print("major_layer_debuff_smoke: ok")
	_restore(game_state, original_state, 0)

func _restore(game_state: Node, original_state: Dictionary, code: int) -> void:
	game_state.current_floor = int(original_state.get("current_floor", 0))
	game_state.max_floors = int(original_state.get("max_floors", game_state.TOTAL_SMALL_FLOORS))
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.acknowledged_major_layer_debuffs = (original_state.get("acknowledged_major_layer_debuffs", []) as Array).duplicate()
	quit(code)
