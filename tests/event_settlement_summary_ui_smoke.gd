extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var manager := root.get_node("/root/RandomEventManager")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"player_gold": int(game_state.player_gold),
		"materials": int(game_state.materials),
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"backpack": game_state.backpack.duplicate(true),
		"equipment_slot": game_state.equipment_slot.duplicate(true)
	}

	game_state.selected_era_id = "qin"
	game_state.player_gold = 0
	game_state.materials = 0
	game_state.player_hp = 6
	game_state.player_max_hp = 6
	game_state.backpack.clear()
	game_state.equipment_slot.clear()
	manager.reset_state()

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	main._show_good_event_with_data({"event_id": "gold_cache", "type": "good", "subtype": 4, "name": "金币奖励", "description": "获得10金币", "value": 10})
	await process_frame
	var stable_btn := _find_button_with_text(main.current_ui, "稳拿")
	if stable_btn == null:
		_fail("Good event should expose stable choice.", main, game_state, original_state)
		return
	stable_btn.pressed.emit()
	await process_frame
	var good_text := _collect_labels(main.current_ui.get_node_or_null("EventSettlementOverlay"))
	if good_text.find("事件结算") < 0 or good_text.find("金币+10") < 0 or good_text.find("金币：+10") < 0:
		_fail("Stable good event should show concrete gained resources, got: %s" % good_text, main, game_state, original_state)
		return

	game_state.player_gold = 10
	manager.reset_state()
	main._show_bad_event_with_data({"event_id": "gold_loss", "type": "bad", "subtype": 6, "name": "金币损失", "description": "丢失5金币", "value": 5})
	await process_frame
	var penalty_btn := _find_button_with_text(main.current_ui, "认罚")
	if penalty_btn == null:
		_fail("Bad event should expose penalty choice.", main, game_state, original_state)
		return
	penalty_btn.pressed.emit()
	await process_frame
	var bad_text := _collect_labels(main.current_ui.get_node_or_null("EventSettlementOverlay"))
	if bad_text.find("事件结算") < 0 or bad_text.find("金币-5") < 0 or bad_text.find("金币：-5") < 0:
		_fail("Penalty event should show concrete lost resources, got: %s" % bad_text, main, game_state, original_state)
		return

	game_state.backpack.clear()
	game_state.backpack.append(game_state.ITEMS["long_sword"].duplicate(true))
	manager.reset_state()
	main._show_bad_event_with_data({"event_id": "equip_loss_duel", "type": "bad", "subtype": 5, "name": "装备损失", "description": "选择：直接丢失装备或通过战斗决定", "choice_type": "equip_loss", "value": 1})
	await process_frame
	var equip_penalty_btn := _find_button_with_text(main.current_ui, "认罚")
	if equip_penalty_btn == null:
		_fail("Equipment loss event should expose direct penalty choice.", main, game_state, original_state)
		return
	equip_penalty_btn.pressed.emit()
	await process_frame
	var equip_text := _collect_labels(main.current_ui.get_node_or_null("EventSettlementOverlay"))
	if equip_text.find("失去器物") < 0 or equip_text.find("长剑") < 0:
		_fail("Equipment penalty should show lost item, got: %s" % equip_text, main, game_state, original_state)
		return

	print("event_settlement_summary_ui_smoke: ok")
	_finish(0, main, game_state, original_state)

func _find_button_with_text(node: Node, needle: String) -> Button:
	if node == null:
		return null
	if node is Button and (node as Button).text.find(needle) >= 0:
		return node as Button
	for child in node.get_children():
		var found := _find_button_with_text(child, needle)
		if found != null:
			return found
	return null

func _collect_labels(node: Node) -> String:
	if node == null:
		return ""
	var parts: Array[String] = []
	_collect_labels_into(node, parts)
	return "\n".join(parts)

func _collect_labels_into(node: Node, parts: Array[String]) -> void:
	if node is Label:
		parts.append((node as Label).text)
	if node is Button:
		parts.append((node as Button).text)
	for child in node.get_children():
		_collect_labels_into(child, parts)

func _fail(message: String, main: Node, game_state: Node, original_state: Dictionary) -> void:
	push_error(message)
	_finish(1, main, game_state, original_state)

func _finish(code: int, main: Node, game_state: Node, original_state: Dictionary) -> void:
	if main != null:
		main.queue_free()
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.materials = int(original_state.get("materials", 0))
	game_state.player_hp = int(original_state.get("player_hp", 6))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 6))
	game_state.backpack = (original_state.get("backpack", []) as Array).duplicate(true)
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	quit(code)
