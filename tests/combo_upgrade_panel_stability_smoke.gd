extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"player_gold": int(game_state.player_gold),
		"materials": int(game_state.materials),
		"equipped_combos": game_state.get_equipped_combos().duplicate(),
		"combo_upgrades": game_state.combo_upgrades.duplicate(true)
	}

	game_state.player_gold = 100
	game_state.materials = 20
	game_state.combo_upgrades.clear()
	game_state.get_equipped_combos().clear()
	game_state.get_equipped_combos().append("energy_charge")

	var rest = load("res://scenes/ui/rest_point.tscn").instantiate()
	root.add_child(rest)
	await process_frame

	rest._on_combo_selected()
	await process_frame
	var panel_before := rest.get_node_or_null("ComboPanel") as Control
	if panel_before == null:
		_fail("Combo upgrade panel should be visible after selecting combo rest option.", rest, game_state, original_state)
		return
	var before_pos := panel_before.position
	var before_size := panel_before.size

	rest._on_combo_upgrade("energy_charge")
	await process_frame
	var panel_after := rest.get_node_or_null("ComboPanel") as Control
	if panel_after == null:
		_fail("Combo upgrade panel should still exist after upgrade refresh.", rest, game_state, original_state)
		return

	if panel_after.position != before_pos:
		_fail("Combo upgrade panel should not jump after refresh, before=%s after=%s" % [str(before_pos), str(panel_after.position)], rest, game_state, original_state)
		return

	if panel_after.size != before_size:
		_fail("Combo upgrade panel size should stay stable after refresh, before=%s after=%s" % [str(before_size), str(panel_after.size)], rest, game_state, original_state)
		return

	print("combo_upgrade_panel_stability_smoke: ok")
	_finish(0, rest, game_state, original_state)

func _fail(message: String, rest: Node, game_state: Node, original_state: Dictionary) -> void:
	push_error(message)
	_finish(1, rest, game_state, original_state)

func _finish(code: int, rest: Node, game_state: Node, original_state: Dictionary) -> void:
	if rest != null:
		rest.queue_free()
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.materials = int(original_state.get("materials", 0))
	game_state.combo_upgrades = (original_state.get("combo_upgrades", {}) as Dictionary).duplicate(true)
	game_state.get_equipped_combos().clear()
	for combo_id in (original_state.get("equipped_combos", []) as Array):
		game_state.get_equipped_combos().append(str(combo_id))
	quit(code)
