extends SceneTree

const EnemyAI = preload("res://scripts/enemy_ai.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"player_class": int(game_state.player_class),
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_shield": int(game_state.player_shield),
		"player_gold": int(game_state.player_gold),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"backpack": game_state.backpack.duplicate(true)
	}
	game_state.selected_era_id = "qin"
	game_state.player_class = 0
	game_state.player_max_hp = 10
	game_state.player_hp = 10
	game_state.player_shield = 0
	game_state.player_gold = 0
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["tiger_tally"].duplicate(true))
	game_state.equipment_slot.append(game_state.ITEMS["wooden_shield"].duplicate(true))
	game_state.backpack.clear()

	var main = load("res://scenes/main.gd").new()
	root.add_child(main)

	var ai := EnemyAI.new()
	ai.setup_basic_fixed(0)
	var enemy_data = load("res://resources/enemy_data.gd").new()
	enemy_data.enemy_id = "momentum_rail_probe"
	enemy_data.display_name = "显示校验"
	enemy_data.max_hp = 12
	enemy_data.attack = 2
	enemy_data.ai_type = 0
	enemy_data.ai_subtype = 0
	main.current_enemy_ai = ai
	main.current_enemy_data = enemy_data
	main.battle_enemy_max_hp = enemy_data.max_hp
	main.battle_enemy_hp = enemy_data.max_hp
	main.battle_enemy_atk = enemy_data.attack
	main._battle_ending = false

	var battle: Control = main._create_battle_ui(enemy_data, ai, 0, 0)
	root.add_child(battle)
	await process_frame

	var rail := battle.get_node_or_null("DuelMomentumRail") as Control
	if rail == null:
		_fail("Battle UI should create the duel momentum rail.", game_state, original_state, main, battle, ai)
		return
	if rail.position.distance_to(Vector2(398, 82)) > 1.0:
		_fail("Duel momentum rail should replace the old enemy intent text area, got position=%s" % str(rail.position), game_state, original_state, main, battle, ai)
		return

	var momentum_text := battle.get_node_or_null("DuelMomentumText") as Label
	var momentum_hint := battle.get_node_or_null("DuelMomentumHint") as Label
	var momentum_track := battle.get_node_or_null("DuelMomentumTrack") as ColorRect
	if momentum_text == null or momentum_hint == null or momentum_track == null:
		_fail("Duel momentum rail should keep internal nodes for the visual rail.", game_state, original_state, main, battle, ai)
		return
	if momentum_text.visible or momentum_hint.visible or momentum_text.text != "" or momentum_hint.text != "":
		_fail("Duel momentum rail should not show text explanation below or beside the rail.", game_state, original_state, main, battle, ai)
		return
	if momentum_track.size.x < 370.0:
		_fail("Duel momentum rail should use the freed text space for a clearer track, size=%s" % str(momentum_track.size), game_state, original_state, main, battle, ai)
		return

	var move_info := battle.get_node_or_null("MoveInfo") as Label
	if move_info == null or move_info.visible:
		_fail("Old enemy intent text should remain hidden behind the momentum rail.", game_state, original_state, main, battle, ai)
		return

	var danger_panel := battle.get_node_or_null("DangerForecastPanel") as Panel
	var danger_label := battle.get_node_or_null("DangerForecastLabel") as Label
	if danger_panel == null or danger_label == null or not danger_panel.visible or danger_label.text.find("危险") < 0:
		_fail("Battle UI should show a compact danger forecast near the enemy portrait.", game_state, original_state, main, battle, ai)
		return

	var summary_panel := battle.get_node_or_null("BattleSummaryPanel") as Panel
	var summary_label := battle.get_node_or_null("ResultLabel") as Label
	if summary_panel == null or summary_label == null:
		_fail("Battle UI should keep a compact verdict/history strip.", game_state, original_state, main, battle, ai)
		return
	if summary_panel.position.y < 496.0 or summary_panel.size.y < 80.0 or summary_panel.position.y + summary_panel.size.y > 588.0:
		_fail("Verdict strip should merge into the history area above move buttons, pos=%s size=%s" % [str(summary_panel.position), str(summary_panel.size)], game_state, original_state, main, battle, ai)
		return
	if summary_label.position.y < summary_panel.position.y or summary_label.position.y > 532.0 or summary_label.get_theme_font_size("font_size") > 12:
		_fail("Verdict text should sit at the top of the history strip, pos=%s size=%s" % [str(summary_label.position), str(summary_label.size)], game_state, original_state, main, battle, ai)
		return

	var player_history := battle.get_node_or_null("PlayerHistory0") as Label
	var enemy_history := battle.get_node_or_null("EnemyHistory0") as Label
	var move_button := battle.get_node_or_null("BattleMoveButton0") as Button
	if player_history == null or enemy_history == null or move_button == null:
		_fail("Battle UI should expose history slots and move buttons.", game_state, original_state, main, battle, ai)
		return
	if player_history.position.y <= summary_label.position.y + summary_label.size.y or enemy_history.position.y <= summary_label.position.y + summary_label.size.y:
		_fail("Move history should sit below the verdict inside the same strip, player_y=%s enemy_y=%s verdict_y=%s" % [str(player_history.position.y), str(enemy_history.position.y), str(summary_label.position.y)], game_state, original_state, main, battle, ai)
		return
	if player_history.position.y >= move_button.position.y or enemy_history.position.y >= move_button.position.y:
		_fail("Move history should sit immediately above the Tian/Ren/Di buttons, player_y=%s enemy_y=%s button_y=%s" % [str(player_history.position.y), str(enemy_history.position.y), str(move_button.position.y)], game_state, original_state, main, battle, ai)
		return

	var layout_momentum_panel := battle.get_node_or_null("LayoutMomentumPanel") as Panel
	var layout_momentum_label := battle.get_node_or_null("LayoutMomentumLabel") as Label
	var combo_progress := battle.get_node_or_null("ComboProgress") as Label
	if layout_momentum_panel == null or layout_momentum_label == null or combo_progress == null:
		_fail("Battle UI should keep layout-momentum nodes and expose the fused bottom combo strip.", game_state, original_state, main, battle, ai)
		return
	if layout_momentum_panel.visible or layout_momentum_label.visible:
		_fail("Old separate dark-momentum strip should be hidden after fusion.", game_state, original_state, main, battle, ai)
		return
	if combo_progress.position.y < 660.0 or combo_progress.text.find("暗势") < 0:
		_fail("Fused combo strip should sit under player moves and express hidden buildup, pos=%s text=%s" % [str(combo_progress.position), combo_progress.text], game_state, original_state, main, battle, ai)
		return

	var utility_panel := battle.get_node_or_null("ComboResourcePanel") as Panel
	var cheat_btn := battle.get_node_or_null("CheatButton") as Button
	if utility_panel == null or cheat_btn == null:
		_fail("Battle UI should expose the combo resource panel and cheat button.", game_state, original_state, main, battle, ai)
		return
	if utility_panel.position.distance_to(main.BATTLE_UTILITY_ROW_POS) > 1.0 or utility_panel.size.distance_to(main.BATTLE_UTILITY_ROW_SIZE) > 1.0:
		_fail("Combo resource panel should use the shared utility-row size, pos=%s size=%s" % [str(utility_panel.position), str(utility_panel.size)], game_state, original_state, main, battle, ai)
		return
	if cheat_btn.position.distance_to(main.BATTLE_CHEAT_BUTTON_POS) > 1.0 or cheat_btn.size.distance_to(main.BATTLE_CHEAT_BUTTON_SIZE) > 1.0:
		_fail("Cheat button should align with the utility row, pos=%s size=%s" % [str(cheat_btn.position), str(cheat_btn.size)], game_state, original_state, main, battle, ai)
		return
	if absf(cheat_btn.position.y - utility_panel.position.y) > 1.0 or absf(cheat_btn.size.y - utility_panel.size.y) > 1.0:
		_fail("Cheat button height should match the utility row, button=%s panel=%s" % [str(cheat_btn.size), str(utility_panel.size)], game_state, original_state, main, battle, ai)
		return

	var era_card := battle.get_node_or_null("EraItemsCard") as Panel
	var era_label := battle.get_node_or_null("EraItemsLabel") as Label
	var equipment_label := battle.get_node_or_null("ItemsLabel") as Label
	if era_card == null or era_label == null or equipment_label == null:
		_fail("Battle UI should expose separate era relic and regular equipment cards.", game_state, original_state, main, battle, ai)
		return
	if era_card.position.y >= equipment_label.position.y:
		_fail("Era relic card should sit above regular equipment, era_y=%s equipment_y=%s" % [str(era_card.position.y), str(equipment_label.position.y)], game_state, original_state, main, battle, ai)
		return
	if era_label.text.find("虎符") < 0:
		_fail("Era relic card should show equipped era relics, got: %s" % era_label.text, game_state, original_state, main, battle, ai)
		return
	if equipment_label.text.find("虎符") >= 0 or equipment_label.text.find("木盾") < 0:
		_fail("Regular equipment card should exclude era relic duplicates and keep normal gear, got: %s" % equipment_label.text, game_state, original_state, main, battle, ai)
		return

	var player_frame := battle.get_node_or_null("PlayerPortraitPanel") as Panel
	var enemy_frame := battle.get_node_or_null("EnemyPortraitPanel") as Panel
	if player_frame == null or enemy_frame == null:
		_fail("Battle UI should name both portrait frames for momentum highlighting.", game_state, original_state, main, battle, ai)
		return

	main._battle_momentum_score = 3
	main._update_duel_momentum_rail(battle, "测试我势")
	var player_style := player_frame.get_theme_stylebox("panel") as StyleBoxFlat
	var enemy_style := enemy_frame.get_theme_stylebox("panel") as StyleBoxFlat
	if player_style == null or enemy_style == null or player_style.shadow_size <= enemy_style.shadow_size:
		_fail("Player portrait frame should glow more when player momentum is high.", game_state, original_state, main, battle, ai)
		return

	main._battle_momentum_score = -2
	main._update_duel_momentum_rail(battle, "测试压迫")
	if momentum_text.visible or momentum_hint.visible or momentum_text.text != "" or momentum_hint.text != "":
		_fail("Duel momentum updates should keep the rail textless, text=%s hint=%s" % [momentum_text.text, momentum_hint.text], game_state, original_state, main, battle, ai)
		return
	player_style = player_frame.get_theme_stylebox("panel") as StyleBoxFlat
	enemy_style = enemy_frame.get_theme_stylebox("panel") as StyleBoxFlat
	if player_style == null or enemy_style == null or enemy_style.shadow_size <= player_style.shadow_size:
		_fail("Enemy portrait frame should glow more when enemy momentum is high.", game_state, original_state, main, battle, ai)
		return
	if danger_label.text.find("杀机") < 0 or danger_label.text.find("对方得势") < 0:
		_fail("Danger forecast should escalate with negative momentum, got: %s" % danger_label.text, game_state, original_state, main, battle, ai)
		return

	var visible_text := _collect_visible_label_text(battle)
	if visible_text.find("敌势") >= 0:
		_fail("Visible battle UI should not show 敌势 wording, got: %s" % visible_text, game_state, original_state, main, battle, ai)
		return

	print("battle_momentum_rail_ui_smoke: ok")
	_finish(0, game_state, original_state, main, battle, ai)

func _collect_visible_label_text(node: Node) -> String:
	if node == null:
		return ""
	var parts: Array[String] = []
	if node is Label and (node as Label).visible:
		parts.append((node as Label).text)
	for child in node.get_children():
		var child_text := _collect_visible_label_text(child)
		if child_text != "":
			parts.append(child_text)
	return "\n".join(parts)

func _fail(message: String, game_state: Node, original_state: Dictionary, main: Node, battle: Node, ai: EnemyAI) -> void:
	push_error(message)
	_finish(1, game_state, original_state, main, battle, ai)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node, battle: Node, ai: EnemyAI) -> void:
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.player_hp = int(original_state.get("player_hp", 10))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 10))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.backpack = (original_state.get("backpack", []) as Array).duplicate(true)
	if main != null and is_instance_valid(main):
		main.current_enemy_ai = null
		main.current_enemy_data = null
		main._dispose_combo_database_cache()
	if battle != null and is_instance_valid(battle):
		battle.free()
	if ai != null and is_instance_valid(ai):
		ai.free()
	if main != null and is_instance_valid(main):
		main.free()
	call_deferred("_quit_after_cleanup", code)

func _quit_after_cleanup(code: int) -> void:
	await process_frame
	quit(code)
