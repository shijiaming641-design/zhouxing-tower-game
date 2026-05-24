extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"player_gold": int(game_state.player_gold),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"backpack": game_state.backpack.duplicate(true),
		"equipped_combos": game_state.get_equipped_combos().duplicate(),
		"combo_upgrades": game_state.combo_upgrades.duplicate(true),
		"equipment_upgrades": game_state.equipment_upgrades.duplicate(true),
		"selected_era_id": str(game_state.selected_era_id)
	}

	game_state.selected_era_id = "qin"
	game_state.player_gold = 200
	game_state.get_equipped_combos().clear()
	game_state.get_equipped_combos().append("energy_charge")
	game_state.combo_upgrades.clear()
	game_state.combo_upgrades["energy_charge"] = {"level": 2, "has_burn": false, "has_slow": false}
	game_state.equipment_slot.clear()
	game_state.backpack.clear()
	game_state.equipment_slot.append(game_state.ITEMS["long_sword"].duplicate(true))
	game_state.equipment_upgrades.clear()
	game_state.equipment_upgrades["long_sword"] = {"level": 1, "quality": 1, "special_unlocked": false}

	var rest = load("res://scenes/ui/rest_point.tscn").instantiate()
	root.add_child(rest)
	await process_frame

	rest._on_combo_selected()
	await process_frame
	var combo_panel: Node = rest.get_node_or_null("ComboPanel")
	var combo_text := _collect_text(combo_panel)
	if combo_text.find("已强化：Lv.2") < 0 or combo_text.find("强化信息：Lv.3") < 0 or combo_text.find("22金") < 0:
		_fail("Combo upgrade panel should show current and next upgrade information. got: %s" % combo_text, rest, game_state, original_state)
		return

	rest._on_equip_selected()
	await process_frame
	var equip_panel: Node = rest.get_node_or_null("EquipPanel")
	var equip_text := _collect_text(equip_panel)
	if equip_text.find("已强化：锻级Lv.1 品质蓝") < 0 or equip_text.find("强化信息：锻级Lv.2") < 0 or equip_text.find("开特") < 0:
		_fail("Equipment upgrade panel should show current and next upgrade information. got: %s" % equip_text, rest, game_state, original_state)
		return

	rest._show_equipment_forge_menu("long_sword", true)
	await process_frame
	var forge_menu: Node = rest.get_node_or_null("ForgeMenu")
	var forge_text := _collect_text(forge_menu)
	if forge_text.find("Forge") >= 0:
		_fail("Forge text dump should use player-facing upgrade copy only. got: %s" % forge_text, rest, game_state, original_state)
		return
	if forge_text.find("已强化：锻级Lv.1 品质蓝") < 0 or forge_text.find("强化信息：锻级Lv.2") < 0 or forge_text.find("升红") < 0:
		_fail("Forge menu should repeat current and next upgrade details. got: %s" % forge_text, rest, game_state, original_state)
		return

	print("rest_upgrade_info_smoke: ok")
	_finish(0, rest, game_state, original_state)

func _collect_text(node: Node) -> String:
	if node == null:
		return ""
	var parts: Array[String] = []
	if node is Label:
		parts.append((node as Label).text)
	if node is Button:
		parts.append((node as Button).text)
	for child in node.get_children():
		parts.append(_collect_text(child))
	return "\n".join(parts)

func _fail(message: String, rest: Node, game_state: Node, original_state: Dictionary) -> void:
	push_error(message)
	_finish(1, rest, game_state, original_state)

func _finish(code: int, rest: Node, game_state: Node, original_state: Dictionary) -> void:
	if rest != null:
		rest.queue_free()
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.backpack = (original_state.get("backpack", []) as Array).duplicate(true)
	game_state.combo_upgrades = (original_state.get("combo_upgrades", {}) as Dictionary).duplicate(true)
	game_state.equipment_upgrades = (original_state.get("equipment_upgrades", {}) as Dictionary).duplicate(true)
	game_state.get_equipped_combos().clear()
	for combo_id in (original_state.get("equipped_combos", []) as Array):
		game_state.get_equipped_combos().append(str(combo_id))
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	quit(code)
