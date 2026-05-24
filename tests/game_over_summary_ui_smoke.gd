extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"current_floor": int(game_state.current_floor),
		"max_floors": int(game_state.max_floors),
		"player_gold": int(game_state.player_gold),
		"materials": int(game_state.materials),
		"player_level": int(game_state.player_level),
		"bonus_hp_from_level": int(game_state.bonus_hp_from_level),
		"bonus_atk_from_level": int(game_state.bonus_atk_from_level),
		"unspent_attribute_points": int(game_state.unspent_attribute_points),
		"combo_upgrades": game_state.combo_upgrades.duplicate(true),
		"equipment_upgrades": game_state.equipment_upgrades.duplicate(true),
		"run_active": bool(game_state.run_active),
		"checkpoint_scene": str(game_state.checkpoint_scene)
	}

	game_state.selected_era_id = "qin"
	game_state.current_floor = 12
	game_state.max_floors = int(game_state.TOTAL_SMALL_FLOORS)
	game_state.player_gold = 23
	game_state.materials = 7
	game_state.player_level = 4
	game_state.bonus_hp_from_level = 2
	game_state.bonus_atk_from_level = 1
	game_state.unspent_attribute_points = 0
	game_state.combo_upgrades = {"pierce": {"level": 3}}
	game_state.equipment_upgrades = {"long_sword": {"level": 2, "quality": 1, "special_unlocked": true}}
	game_state.run_active = true

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._show_game_over(false)
	await process_frame

	var text := _collect_labels(main.current_ui)
	if text.find("死亡结算") < 0:
		push_error("Game over UI should show death settlement title.")
		_restore(game_state, original_state, main, 1)
		return
	if text.find("结余金币 23") < 0:
		push_error("Game over UI should show final resources, got: %s" % text)
		_restore(game_state, original_state, main, 1)
		return
	if text.find("材料") >= 0:
		push_error("Game over UI should not show removed materials, got: %s" % text)
		_restore(game_state, original_state, main, 1)
		return
	if text.find("Lv.4") < 0 or text.find("升级 3 次") < 0:
		push_error("Game over UI should show level progress, got: %s" % text)
		_restore(game_state, original_state, main, 1)
		return
	if text.find("布局：") < 0 or text.find("器物：") < 0:
		push_error("Game over UI should show combo and equipment upgrades, got: %s" % text)
		_restore(game_state, original_state, main, 1)
		return

	print("game_over_summary_ui_smoke: ok")
	_restore(game_state, original_state, main, 0)

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

func _restore(game_state: Node, original_state: Dictionary, main: Node, code: int) -> void:
	if main != null and is_instance_valid(main):
		main.free()
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.current_floor = int(original_state.get("current_floor", 0))
	game_state.max_floors = int(original_state.get("max_floors", game_state.TOTAL_SMALL_FLOORS))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.materials = int(original_state.get("materials", 0))
	game_state.player_level = int(original_state.get("player_level", 1))
	game_state.bonus_hp_from_level = int(original_state.get("bonus_hp_from_level", 0))
	game_state.bonus_atk_from_level = int(original_state.get("bonus_atk_from_level", 0))
	game_state.unspent_attribute_points = int(original_state.get("unspent_attribute_points", 0))
	game_state.combo_upgrades = (original_state.get("combo_upgrades", {}) as Dictionary).duplicate(true)
	game_state.equipment_upgrades = (original_state.get("equipment_upgrades", {}) as Dictionary).duplicate(true)
	game_state.run_active = bool(original_state.get("run_active", false))
	game_state.checkpoint_scene = str(original_state.get("checkpoint_scene", "map"))
	quit(code)
