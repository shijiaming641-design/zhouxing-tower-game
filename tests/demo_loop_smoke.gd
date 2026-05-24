extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := _capture_game_state(game_state)

	game_state.selected_era_id = "qin"
	game_state.memory_cores = 5
	game_state.meta_upgrades.clear()
	game_state.acknowledged_major_layer_debuffs.clear()
	game_state.run_active = false

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	main._show_main_menu()
	await process_frame
	if main.current_ui == null or main.current_ui.get_node_or_null("StartButton") == null:
		_fail("Main menu should expose the start button.", game_state, original_state, main)
		return

	main._show_meta_panel("upgrades")
	await process_frame
	var upgrade_text := _collect_labels(main.current_ui.get_node_or_null("MetaOverlay"))
	if upgrade_text.find("传承升级") < 0 or upgrade_text.find("行前筹备") < 0 or upgrade_text.find("兵马未动") < 0 or upgrade_text.find("全满约 138") < 0 or upgrade_text.find("秦通关+14") < 0:
		_fail("Meta upgrade panel should show demo progression estimates, got: %s" % upgrade_text, game_state, original_state, main)
		return
	for required_text in ["粮仓", "军械库", "演武场", "宗祠", "当前：", "下级：", "消耗：", "解锁："]:
		if upgrade_text.find(required_text) < 0:
			_fail("Meta upgrade panel should express upgrades as pre-war preparation cards, missing %s. got: %s" % [required_text, upgrade_text], game_state, original_state, main)
			return

	main._on_character_selected(0)
	await process_frame
	await process_frame
	if main.current_ui == null or main.current_ui.name != "ComboSelect":
		_fail("Character selection should enter the initial layout screen.", game_state, original_state, main)
		return
	var combo_start := main.current_ui.get_node_or_null("StartButton") as Button
	if combo_start == null or combo_start.disabled:
		_fail("Initial layout screen should auto-equip one playable layout and enable start.", game_state, original_state, main)
		return
	combo_start.pressed.emit()
	await process_frame

	if main.current_ui != null and main.current_ui.name == "MajorLayerDebuffGate":
		var gate_text := _collect_labels(main.current_ui)
		if gate_text.find("时代负面") < 0:
			_fail("Major layer gate should explain the current era pressure.", game_state, original_state, main)
			return
		var gate_button := _find_first_button(main.current_ui)
		if gate_button == null:
			_fail("Major layer gate should provide a close/continue button.", game_state, original_state, main)
			return
		gate_button.pressed.emit()
		await process_frame

	if main.current_ui == null or main.current_ui.name != "MapScene":
		_fail("Closing the era pressure gate should enter the map scene.", game_state, original_state, main)
		return
	if game_state.map_data.is_empty() or (game_state.map_data[0] as Array).is_empty():
		_fail("Starting a run should generate a playable historical map.", game_state, original_state, main)
		return

	var first_node := (game_state.map_data[0] as Array)[0] as Dictionary
	first_node["type"] = 0
	first_node["visited"] = false
	first_node["accessible"] = true
	main._on_map_node_selected(0)
	await process_frame
	await process_frame
	if main.current_ui == null or main.current_ui.name != "BattleScene":
		_fail("Selecting a battle map node should enter battle.", game_state, original_state, main)
		return

	if main.current_enemy_data != null:
		main.current_enemy_data.ai_type = 1
	var battle := main.current_ui as Control
	game_state.player_level = game_state.MAX_PLAYER_LEVEL
	game_state.player_exp = 0
	var before_state: Dictionary = main._capture_battle_settlement_state()
	game_state.player_gold += game_state.get_battle_gold_reward()
	var reward_info: Dictionary = await main._handle_battle_victory_rewards(battle)
	var after_state: Dictionary = main._capture_battle_settlement_state()
	main._show_battle_settlement_detail(battle, before_state, after_state, reward_info)
	await process_frame
	var settlement := battle.get_node_or_null("BattleSettlementOverlay")
	var settlement_text := _collect_labels(settlement)
	if settlement == null or settlement_text.find("对战详细") < 0 or settlement_text.find("金币：+") < 0 or settlement_text.find("经验：+") < 0:
		_fail("Battle victory should show a concrete settlement detail overlay, got: %s" % settlement_text, game_state, original_state, main)
		return
	if settlement_text.find("材料：") >= 0:
		_fail("Battle victory settlement should not show removed materials, got: %s" % settlement_text, game_state, original_state, main)
		return
	var continue_button := settlement.find_child("BattleSettlementContinueButton", true, false) as Button
	if continue_button == null:
		_fail("Battle settlement detail should provide a continue button.", game_state, original_state, main)
		return
	continue_button.pressed.emit()
	await process_frame

	main._show_rest_point()
	await process_frame
	if main.current_ui == null or main.current_ui.name != "RestPoint":
		_fail("Demo loop should be able to enter a rest point after battle.", game_state, original_state, main)
		return
	if main.current_ui.has_method("_get_rest_choice_buttons") and main.current_ui._get_rest_choice_buttons().size() != 3:
		_fail("Rest point should keep the three-choice structure.", game_state, original_state, main)
		return

	game_state.run_active = true
	game_state.current_floor = 3
	main._show_game_over(false)
	await process_frame
	var game_over_text := _collect_labels(main.current_ui)
	if game_over_text.find("死亡结算") < 0 or game_over_text.find("传承点") < 0:
		_fail("Game over should show death settlement and legacy progression.", game_state, original_state, main)
		return

	print("demo_loop_smoke: ok")
	_restore_and_quit(0, game_state, original_state, main)

func _capture_game_state(game_state: Node) -> Dictionary:
	return {
		"selected_era_id": str(game_state.selected_era_id),
		"memory_cores": int(game_state.memory_cores),
		"meta_upgrades": game_state.meta_upgrades.duplicate(true),
		"acknowledged_major_layer_debuffs": game_state.acknowledged_major_layer_debuffs.duplicate(true),
		"run_active": bool(game_state.run_active),
		"checkpoint_scene": str(game_state.checkpoint_scene),
		"current_floor": int(game_state.current_floor),
		"max_floors": int(game_state.max_floors),
		"map_data": game_state.map_data.duplicate(true),
		"player_class": int(game_state.player_class),
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_attack": int(game_state.player_attack),
		"player_shield": int(game_state.player_shield),
		"player_gold": int(game_state.player_gold),
		"materials": int(game_state.materials),
		"player_level": int(game_state.player_level),
		"player_exp": int(game_state.player_exp),
		"equipped_combos": game_state.get_equipped_combos().duplicate(true),
		"combo_energy": int(game_state.combo_energy),
		"max_combo_energy": int(game_state.max_combo_energy),
		"current_shop_items": game_state.current_shop_items.duplicate(true),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"backpack": game_state.backpack.duplicate(true)
	}

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

func _find_first_button(node: Node) -> Button:
	if node is Button:
		return node as Button
	for child in node.get_children():
		var found := _find_first_button(child)
		if found != null:
			return found
	return null

func _fail(message: String, game_state: Node, original_state: Dictionary, main: Node) -> void:
	push_error(message)
	_restore_and_quit(1, game_state, original_state, main)

func _restore_and_quit(code: int, game_state: Node, original_state: Dictionary, main: Node) -> void:
	if main != null and is_instance_valid(main):
		if main.has_method("_dispose_combo_database_cache"):
			main._dispose_combo_database_cache()
		if main.has_method("_dispose_current_enemy_ai"):
			main._dispose_current_enemy_ai()
		main.queue_free()
	var combo_data_script = load("res://resources/combo_data.gd")
	if combo_data_script != null and combo_data_script.has_method("clear_combo_db_cache"):
		combo_data_script.clear_combo_db_cache()
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.memory_cores = int(original_state.get("memory_cores", 0))
	game_state.meta_upgrades = (original_state.get("meta_upgrades", {}) as Dictionary).duplicate(true)
	game_state.acknowledged_major_layer_debuffs = (original_state.get("acknowledged_major_layer_debuffs", []) as Array).duplicate(true)
	game_state.run_active = bool(original_state.get("run_active", false))
	game_state.checkpoint_scene = str(original_state.get("checkpoint_scene", "map"))
	game_state.current_floor = int(original_state.get("current_floor", 0))
	game_state.max_floors = int(original_state.get("max_floors", game_state.TOTAL_SMALL_FLOORS))
	game_state.map_data = (original_state.get("map_data", []) as Array).duplicate(true)
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.player_hp = int(original_state.get("player_hp", 6))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 6))
	game_state.player_attack = int(original_state.get("player_attack", 2))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.materials = int(original_state.get("materials", 0))
	game_state.player_level = int(original_state.get("player_level", 1))
	game_state.player_exp = int(original_state.get("player_exp", 0))
	game_state.equipped_combos = (original_state.get("equipped_combos", []) as Array).duplicate(true)
	game_state.combo_energy = int(original_state.get("combo_energy", 0))
	game_state.max_combo_energy = int(original_state.get("max_combo_energy", 3))
	game_state.current_shop_items = (original_state.get("current_shop_items", []) as Array).duplicate(true)
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.backpack = (original_state.get("backpack", []) as Array).duplicate(true)
	game_state.save_progress()
	await process_frame
	await process_frame
	quit(code)
