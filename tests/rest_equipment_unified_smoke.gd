extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"player_gold": int(game_state.player_gold),
		"materials": int(game_state.materials),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"backpack": game_state.backpack.duplicate(true),
		"equipment_upgrades": game_state.equipment_upgrades.duplicate(true),
		"selected_era_id": str(game_state.selected_era_id)
	}

	game_state.selected_era_id = "qin"
	game_state.player_gold = 100
	game_state.materials = 20
	game_state.equipment_slot.clear()
	game_state.backpack.clear()
	game_state.equipment_upgrades.clear()
	game_state.equipment_slot.append(game_state.ITEMS["long_sword"].duplicate(true))
	game_state.backpack.append(game_state.ITEMS["life_crystal"].duplicate(true))

	var rest = load("res://scenes/ui/rest_point.tscn").instantiate()
	root.add_child(rest)
	await process_frame

	if rest._get_rest_choice_buttons().size() != 3:
		push_error("Rest point should stay as three choices.")
		_finish(1, rest, game_state, original_state)
		return

	rest._on_equip_selected()
	await process_frame

	var equip_panel: Node = rest.get_node_or_null("EquipPanel")
	if equip_panel == null:
		push_error("Equipment choice should open unified equipment panel.")
		_finish(1, rest, game_state, original_state)
		return

	var title := equip_panel.find_child("UnifiedEquipmentTitle", true, false) as Label
	var list: Node = equip_panel.find_child("UnifiedEquipmentList", true, false)
	if title == null or title.text.find("器物库") < 0 or list == null:
		push_error("Equipment panel should use the unified equipment library structure.")
		_finish(1, rest, game_state, original_state)
		return

	var text_dump := _collect_label_text(equip_panel)
	if text_dump.find("装备中") < 0 or text_dump.find("背包") < 0:
		push_error("Unified equipment panel should show equipped and backpack items in one list.")
		_finish(1, rest, game_state, original_state)
		return

	rest._show_equipment_forge_menu("life_crystal", false)
	await process_frame
	var forge_menu: Node = rest.get_node_or_null("ForgeMenu")
	var quality_button := forge_menu.get_node_or_null("ForgeQualityButton") as Button if forge_menu != null else null
	var special_button := forge_menu.get_node_or_null("ForgeSpecialButton") as Button if forge_menu != null else null
	if quality_button == null or special_button == null:
		push_error("Forge menu should always expose level, quality, and special rows.")
		_finish(1, rest, game_state, original_state)
		return
	if not quality_button.disabled or not special_button.disabled:
		push_error("Backpack item quality/special rows should be disabled until equipped.")
		_finish(1, rest, game_state, original_state)
		return
	if quality_button.text.find("装后") < 0 or special_button.text.find("装后") < 0:
		push_error("Backpack item quality/special rows should explain they unlock after equip.")
		_finish(1, rest, game_state, original_state)
		return
	var exit_button := forge_menu.get_node_or_null("ForgeExitButton") as Button if forge_menu != null else null
	if exit_button == null:
		push_error("Forge menu should expose an explicit exit button.")
		_finish(1, rest, game_state, original_state)
		return
	var gold_before_exit := int(game_state.player_gold)
	var upgrades_before_exit: Dictionary = game_state.equipment_upgrades.duplicate(true)
	exit_button.pressed.emit()
	await process_frame
	if rest.get_node_or_null("ForgeMenu") != null:
		push_error("Forge exit should close the forge menu without requiring an upgrade.")
		_finish(1, rest, game_state, original_state)
		return
	if int(game_state.player_gold) != gold_before_exit or game_state.equipment_upgrades != upgrades_before_exit:
		push_error("Forge exit should not spend gold or change equipment upgrades.")
		_finish(1, rest, game_state, original_state)
		return

	print("rest_equipment_unified_smoke: ok")
	_finish(0, rest, game_state, original_state)

func _collect_label_text(node: Node) -> String:
	var parts: Array[String] = []
	if node is Label:
		parts.append((node as Label).text)
	for child in node.get_children():
		parts.append(_collect_label_text(child))
	return "\n".join(parts)

func _finish(code: int, rest: Node, game_state: Node, original_state: Dictionary) -> void:
	if rest != null:
		rest.queue_free()
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.materials = int(original_state.get("materials", 0))
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.backpack = (original_state.get("backpack", []) as Array).duplicate(true)
	game_state.equipment_upgrades = (original_state.get("equipment_upgrades", {}) as Dictionary).duplicate(true)
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	quit(code)
