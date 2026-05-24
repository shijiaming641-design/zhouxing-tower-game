extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"player_level": int(game_state.player_level),
		"player_exp": int(game_state.player_exp),
		"unspent_attribute_points": int(game_state.unspent_attribute_points),
		"bonus_hp_from_level": int(game_state.bonus_hp_from_level),
		"bonus_atk_from_level": int(game_state.bonus_atk_from_level),
		"bonus_cheat_from_level": int(game_state.bonus_cheat_from_level),
		"cheat_points": int(game_state.cheat_points),
		"player_class": int(game_state.player_class)
	}

	game_state.player_class = 0
	game_state.player_level = 2
	game_state.player_exp = 0
	game_state.unspent_attribute_points = 1
	game_state.bonus_hp_from_level = 0
	game_state.bonus_atk_from_level = 0
	game_state.bonus_cheat_from_level = 0
	game_state.cheat_points = 0

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var battle := Control.new()
	battle.name = "LevelUpUiProbe"
	root.add_child(battle)
	var rail := Control.new()
	rail.name = "DuelMomentumRail"
	rail.visible = true
	battle.add_child(rail)

	var leveled: Array[int] = [2]
	main._show_level_up_panel(battle, leveled, 1)
	await process_frame

	var overlay := battle.get_node_or_null("LevelUpOverlay")
	if overlay == null:
		_fail("Level-up overlay should be visible.", game_state, original_state, main, battle)
		return
	if rail.visible:
		_fail("Duel momentum rail should be hidden behind level-up overlay.", game_state, original_state, main, battle)
		return
	var text := _collect_labels(overlay)
	for required_text in ["战中提振", "临阵整军", "稳军", "锐卒", "整阵", "可提振次数"]:
		if text.find(required_text) < 0:
			_fail("Level-up UI should present in-run boost choices, missing %s. got: %s" % [required_text, text], game_state, original_state, main, battle)
			return

	var tactic_button := _find_button_containing(overlay, "整阵")
	if tactic_button == null:
		_fail("Level-up UI should expose the 整阵 choice.", game_state, original_state, main, battle)
		return
	tactic_button.pressed.emit()
	await process_frame
	if int(game_state.cheat_points) != 1 or int(game_state.get_max_cheat_points()) != 3 or int(game_state.bonus_cheat_from_level) != 1 or int(game_state.unspent_attribute_points) != 0:
		_fail("Selecting 整阵 should spend one boost, increase cheat storage, and grant one cheat point.", game_state, original_state, main, battle)
		return

	print("level_up_panel_ui_smoke: ok")
	_finish(0, game_state, original_state, main, battle)

func _collect_labels(node: Node) -> String:
	if node == null:
		return ""
	var parts: Array[String] = []
	if node is Label:
		parts.append((node as Label).text)
	elif node is Button:
		parts.append((node as Button).text)
	for child in node.get_children():
		var child_text := _collect_labels(child)
		if child_text != "":
			parts.append(child_text)
	return "\n".join(parts)

func _find_button_containing(node: Node, needle: String) -> Button:
	if node is Button and (node as Button).text.find(needle) >= 0:
		return node as Button
	for child in node.get_children():
		var found := _find_button_containing(child, needle)
		if found != null:
			return found
	return null

func _fail(message: String, game_state: Node, original_state: Dictionary, main: Node, battle: Node) -> void:
	push_error(message)
	_finish(1, game_state, original_state, main, battle)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node, battle: Node) -> void:
	game_state.player_level = int(original_state.get("player_level", 1))
	game_state.player_exp = int(original_state.get("player_exp", 0))
	game_state.unspent_attribute_points = int(original_state.get("unspent_attribute_points", 0))
	game_state.bonus_hp_from_level = int(original_state.get("bonus_hp_from_level", 0))
	game_state.bonus_atk_from_level = int(original_state.get("bonus_atk_from_level", 0))
	game_state.bonus_cheat_from_level = int(original_state.get("bonus_cheat_from_level", 0))
	game_state.cheat_points = int(original_state.get("cheat_points", 0))
	game_state.player_class = int(original_state.get("player_class", 0))
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
	if main != null and is_instance_valid(main):
		main.queue_free()
	quit(code)
