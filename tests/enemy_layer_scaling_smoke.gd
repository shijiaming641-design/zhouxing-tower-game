extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_era := str(game_state.selected_era_id)
	game_state.selected_era_id = "qin"
	var enemy_data_script: GDScript = load("res://resources/enemy_data.gd")

	var layer1_late = enemy_data_script.generate_by_floor(17)
	var layer2_late = enemy_data_script.generate_by_floor(36)
	var layer3_open = enemy_data_script.generate_by_floor(38)
	var layer3_late = enemy_data_script.generate_by_floor(55)

	if int(layer3_open.attack) > 2:
		push_error("Third layer opening enemy should not spike above 2 attack, got %d" % int(layer3_open.attack))
		_finish(game_state, original_era, 1)
		return
	if int(layer3_late.attack) > int(layer1_late.attack) + 2:
		push_error("Third layer late enemy attack should rise by layer, not absolute floor. l1=%d l3=%d" % [int(layer1_late.attack), int(layer3_late.attack)])
		_finish(game_state, original_era, 1)
		return
	if int(layer2_late.attack) > int(layer1_late.attack) + 1:
		push_error("Second layer late enemy attack should be a modest step. l1=%d l2=%d" % [int(layer1_late.attack), int(layer2_late.attack)])
		_finish(game_state, original_era, 1)
		return
	if int(layer3_late.max_hp) > int(layer1_late.max_hp) + 7:
		push_error("Third layer HP should not inherit absolute-floor runaway scaling. l1=%d l3=%d" % [int(layer1_late.max_hp), int(layer3_late.max_hp)])
		_finish(game_state, original_era, 1)
		return

	print("enemy_layer_scaling_smoke: ok")
	_finish(game_state, original_era, 0)

func _finish(game_state: Node, original_era: String, code: int) -> void:
	game_state.selected_era_id = original_era
	quit(code)
