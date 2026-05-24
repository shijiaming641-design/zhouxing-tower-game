extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"current_floor": int(game_state.current_floor),
		"player_level": int(game_state.player_level),
		"player_exp": int(game_state.player_exp)
	}
	game_state.selected_era_id = "qin"
	game_state.current_floor = 3
	game_state.player_level = 2
	game_state.player_exp = 0

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var battle := Control.new()
	battle.name = "BattleScene"
	battle.custom_minimum_size = Vector2(1280, 720)
	root.add_child(battle)
	var rail := Control.new()
	rail.name = "DuelMomentumRail"
	rail.visible = true
	battle.add_child(rail)

	var before_state := {
		"gold": 10,
		"materials": 2,
		"level": 2,
		"exp": 0,
		"exp_need": 2,
		"hp": 4,
		"max_hp": 6,
		"attack": 2,
		"shield": 1,
		"cheat": 0,
		"memory": 0
	}
	var after_state := {
		"gold": 17,
		"materials": 5,
		"level": 3,
		"exp": 1,
		"exp_need": 3,
		"hp": 5,
		"max_hp": 8,
		"attack": 2,
		"shield": 2,
		"cheat": 1,
		"memory": 0
	}
	var reward_info := {
		"reward_type": "elite",
		"exp_gained": 3,
		"leveled_up": [3],
		"memory_gained": 0
	}

	main._show_battle_settlement_detail(battle, before_state, after_state, reward_info)
	await process_frame

	var overlay := battle.get_node_or_null("BattleSettlementOverlay")
	if overlay == null:
		push_error("Battle settlement detail overlay should be shown after victory.")
		_finish(1, game_state, original_state, main, battle)
		return
	if rail.visible:
		push_error("Duel momentum rail should be hidden behind settlement detail overlay.")
		_finish(1, game_state, original_state, main, battle)
		return

	var text := _collect_labels(overlay)
	if text.find("对战详细") < 0 or text.find("金币：+7") < 0 or text.find("经验：+3") < 0:
		push_error("Settlement detail should show concrete resource and exp gains, got: %s" % text)
		_finish(1, game_state, original_state, main, battle)
		return
	if text.find("材料：") >= 0:
		push_error("Settlement detail should not show removed material gains, got: %s" % text)
		_finish(1, game_state, original_state, main, battle)
		return
	if text.find("升级：Lv.3") < 0 or text.find("机括：+1") < 0 or text.find("命数上限+2") < 0:
		push_error("Settlement detail should show level and state changes, got: %s" % text)
		_finish(1, game_state, original_state, main, battle)
		return

	var continue_button := overlay.find_child("BattleSettlementContinueButton", true, false) as Button
	if continue_button == null:
		push_error("Settlement detail should provide a continue button.")
		_finish(1, game_state, original_state, main, battle)
		return
	var button_rect := continue_button.get_global_rect()
	if button_rect.size.x <= 1.0 or button_rect.size.y <= 1.0:
		push_error("Settlement continue button should have a real clickable area, rect=%s" % str(button_rect))
		_finish(1, game_state, original_state, main, battle)
		return
	if continue_button.mouse_filter != Control.MOUSE_FILTER_STOP:
		push_error("Settlement continue button should receive mouse input directly.")
		_finish(1, game_state, original_state, main, battle)
		return
	var swallowed_click := InputEventMouseButton.new()
	swallowed_click.button_index = MOUSE_BUTTON_LEFT
	swallowed_click.pressed = true
	swallowed_click.position = button_rect.get_center()
	swallowed_click.global_position = button_rect.get_center()
	overlay.emit_signal("gui_input", swallowed_click)
	await process_frame
	await process_frame
	if is_instance_valid(overlay) and overlay.is_inside_tree():
		push_error("Settlement detail should close even if the full-screen overlay swallows the continue-button click.")
		_finish(1, game_state, original_state, main, battle)
		return

	print("battle_settlement_detail_smoke: ok")
	_finish(0, game_state, original_state, main, battle)

func _collect_labels(node: Node) -> String:
	if node == null:
		return ""
	var parts: Array[String] = []
	if node is Label:
		parts.append((node as Label).text)
	for child in node.get_children():
		var child_text := _collect_labels(child)
		if child_text != "":
			parts.append(child_text)
	return "\n".join(parts)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node, battle: Node) -> void:
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
	if main != null and is_instance_valid(main):
		main.queue_free()
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.current_floor = int(original_state.get("current_floor", 0))
	game_state.player_level = int(original_state.get("player_level", 1))
	game_state.player_exp = int(original_state.get("player_exp", 0))
	quit(code)
