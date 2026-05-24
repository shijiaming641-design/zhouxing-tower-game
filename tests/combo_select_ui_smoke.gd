extends SceneTree

func _finish(code: int, game_state: Node, original_state: Dictionary) -> void:
	for key in original_state.keys():
		game_state.set(key, original_state[key])
	quit(code)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"equipped_combos": game_state.get_equipped_combos().duplicate(),
		"selected_heirloom_id": str(game_state.selected_heirloom_id)
	}

	var scene = load("res://scenes/ui/combo_select.tscn").instantiate()
	root.add_child(scene)
	await process_frame

	if scene.get_node_or_null("HeirloomOptions") == null:
		push_error("ComboSelect should create HeirloomOptions")
		scene.queue_free()
		_finish(1, game_state, original_state)
		return

	scene.queue_free()
	print("combo_select_ui_smoke: ok")
	_finish(0, game_state, original_state)
