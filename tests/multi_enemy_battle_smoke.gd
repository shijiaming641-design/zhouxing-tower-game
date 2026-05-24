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
		"player_attack": int(game_state.player_attack),
		"player_gold": int(game_state.player_gold),
		"combo_buffs": game_state.combo_buffs.duplicate(true),
		"combo_cooldowns": game_state.combo_cooldowns.duplicate(true),
		"field_pending_spend_attack": int(game_state.field_pending_spend_attack),
		"field_pending_blood_attack": int(game_state.field_pending_blood_attack),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"backpack": game_state.backpack.duplicate(true),
		"selected_heirloom_id": str(game_state.selected_heirloom_id),
		"item_battle_wins": int(game_state.item_battle_wins)
	}

	game_state.selected_era_id = "qin"
	game_state.player_class = 0
	game_state.player_max_hp = 10
	game_state.player_hp = 10
	game_state.player_shield = 0
	game_state.player_attack = 3
	game_state.player_gold = 0
	game_state.combo_buffs.clear()
	game_state.combo_cooldowns.clear()
	game_state.field_pending_spend_attack = 0
	game_state.field_pending_blood_attack = 0
	game_state.equipment_slot.clear()
	game_state.backpack.clear()
	game_state.selected_heirloom_id = ""
	game_state.item_battle_wins = 0

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var enemy_data = load("res://resources/enemy_data.gd").new()
	enemy_data.enemy_id = "basic_formation_test"
	enemy_data.display_name = "测试主敌"
	enemy_data.max_hp = 20
	enemy_data.attack = 4
	enemy_data.ai_type = 0
	enemy_data.ai_subtype = 0
	main.current_enemy_data = enemy_data
	var ai := EnemyAI.new()
	ai.setup_basic_fixed(0)
	main.add_child(ai)

	var combo_db = main._get_combo_database()
	var overload = combo_db.get_combo_by_id("system_overload")
	var all_hit = combo_db.get_combo_by_id("penetrating_strike")
	if overload == null or all_hit == null:
		push_error("Expected multi-enemy test combos are missing.")
		_finish(1, game_state, original_state, main)
		return
	var overload_damage: int = int(game_state.get_combo_effect_amount("system_overload", int(overload.effect_value), str(overload.effect_type)))
	var all_hit_damage: int = int(game_state.get_combo_effect_amount("penetrating_strike", int(all_hit.effect_value), str(all_hit.effect_type)))

	_set_main_enemy(main, 20, 4)
	_set_supports(main, [{"name": "盾兵", "hp": 5, "max_hp": 5, "assist": 2}])
	var overload_result: Dictionary = main._apply_single_combo_effect(overload, false)
	if int((main.battle_support_enemies[0] as Dictionary).get("hp", 0)) != 0 or int(main.battle_enemy_hp) != 20:
		push_error("Support-first damage should defeat support before damaging main. result=%s" % str(overload_result))
		_finish(1, game_state, original_state, main)
		return

	main._apply_single_combo_effect(overload, false)
	if int(main.battle_enemy_hp) != 20 - overload_damage:
		push_error("Support-first damage should hit main once supports are down. enemy_hp=%d" % int(main.battle_enemy_hp))
		_finish(1, game_state, original_state, main)
		return

	_set_main_enemy(main, 20, 4)
	_set_supports(main, [{"name": "弓手", "hp": 4, "max_hp": 4, "assist": 2}])
	main._apply_single_combo_effect(all_hit, false)
	if int(main.battle_enemy_hp) != 20 - all_hit_damage or int((main.battle_support_enemies[0] as Dictionary).get("hp", 0)) != 0:
		push_error("All-enemy damage should hit main and support together.")
		_finish(1, game_state, original_state, main)
		return

	_set_main_enemy(main, 20, 4)
	_set_supports(main, [{"name": "弓手", "hp": 4, "max_hp": 4, "assist": 2}])
	var no_combos: Array[Dictionary] = []
	var win_result: Dictionary = main._resolve_turn_exchange(0, 1, no_combos, false, false, null)
	if int(main.battle_enemy_hp) != 17 or int((main.battle_support_enemies[0] as Dictionary).get("hp", 0)) != 4:
		push_error("Ordinary winning hit should target main enemy only. result=%s" % str(win_result))
		_finish(1, game_state, original_state, main)
		return

	_set_main_enemy(main, 20, 4)
	_set_supports(main, [{"name": "弓手", "hp": 4, "max_hp": 4, "assist": 2}])
	game_state.player_hp = 10
	game_state.player_shield = 0
	var loss_result: Dictionary = main._resolve_turn_exchange(0, 2, no_combos, false, false, null)
	if int(game_state.player_hp) != 4 or int(loss_result.get("actual_damage", 0)) != 6:
		push_error("Losing against support group should include support assist damage. hp=%d result=%s" % [int(game_state.player_hp), str(loss_result)])
		_finish(1, game_state, original_state, main)
		return
	if str(loss_result.get("text", "")).find("副阵协攻") < 0:
		push_error("Support assist should be visible in result text. result=%s" % str(loss_result))
		_finish(1, game_state, original_state, main)
		return

	_set_main_enemy(main, 20, 4)
	_set_supports(main, [
		{"name": "盾兵", "hp": 5, "max_hp": 5, "assist": 2},
		{"name": "弓手", "hp": 4, "max_hp": 4, "assist": 2}
	])
	var battle = main._create_battle_ui(enemy_data, ai, 0, 0)
	root.add_child(battle)
	await process_frame
	if not _support_ui_is_ready(battle):
		push_error("Support enemy UI should expose formation panel, cards, hp and assist labels.")
		battle.queue_free()
		await process_frame
		_finish(1, game_state, original_state, main)
		return
	var formation_title = battle.get_node_or_null("EnemyFormationTitle") as Label
	var formation_mode = battle.get_node_or_null("EnemyFormationMode") as Label
	if formation_title == null or formation_title.text.find("1v3") < 0 or formation_mode == null or formation_mode.text.find("副阵2/2") < 0:
		push_error("Support enemy UI should clearly display 1v3 formation, title=%s mode=%s" % [
			formation_title.text if formation_title != null else "missing",
			formation_mode.text if formation_mode != null else "missing"
		])
		battle.queue_free()
		await process_frame
		_finish(1, game_state, original_state, main)
		return
	main._damage_support_first(5, null, "破阵")
	main._update_battle_ui(battle)
	await process_frame
	var support_hp_label = battle.get_node_or_null("SupportHP0") as Label
	if support_hp_label == null or support_hp_label.text.find("退场") < 0:
		push_error("Support defeat should update its status label.")
		battle.queue_free()
		await process_frame
		_finish(1, game_state, original_state, main)
		return
	var group_label = battle.get_node_or_null("EnemyGroupLabel") as Label
	if group_label == null or group_label.text.find("副阵 1/2") < 0:
		push_error("Enemy group summary should reflect defeated support, got: %s" % (group_label.text if group_label != null else "missing"))
		battle.queue_free()
		await process_frame
		_finish(1, game_state, original_state, main)
		return
	if formation_mode == null or formation_mode.text.find("副阵1/2") < 0:
		push_error("Formation mode should reflect defeated support, got: %s" % (formation_mode.text if formation_mode != null else "missing"))
		battle.queue_free()
		await process_frame
		_finish(1, game_state, original_state, main)
		return
	battle.queue_free()
	await process_frame
	main.current_enemy_data = null

	print("multi_enemy_battle_smoke: ok")
	_finish(0, game_state, original_state, main)

func _set_main_enemy(main: Node, hp: int, attack: int) -> void:
	main.battle_enemy_max_hp = hp
	main.battle_enemy_hp = hp
	main.battle_enemy_atk = attack

func _set_supports(main: Node, raw_supports: Array) -> void:
	var supports: Array[Dictionary] = []
	for raw in raw_supports:
		var dict := raw as Dictionary
		supports.append({
			"name": str(dict.get("name", "副敌")),
			"role": "test",
			"hp": int(dict.get("hp", 1)),
			"max_hp": int(dict.get("max_hp", dict.get("hp", 1))),
			"attack": int(dict.get("assist", 1)),
			"assist": int(dict.get("assist", 1)),
			"suppressed": false
		})
	main.battle_support_enemies = supports

func _support_ui_is_ready(battle: Control) -> bool:
	var formation_panel = battle.get_node_or_null("EnemyFormationPanel") as Panel
	if formation_panel == null or not formation_panel.visible:
		return false
	for i in range(2):
		var card = battle.get_node_or_null("SupportCard%d" % i) as Panel
		var hp = battle.get_node_or_null("SupportHP%d" % i) as Label
		var assist = battle.get_node_or_null("SupportAssist%d" % i) as Label
		if card == null or hp == null or assist == null:
			return false
		if not card.visible or hp.text.find("/") < 0 or assist.text.find("协攻") < 0:
			return false
	return true

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node) -> void:
	if main != null and is_instance_valid(main):
		if main.has_method("_dispose_combo_database_cache"):
			main._dispose_combo_database_cache()
		if main.has_method("_dispose_current_enemy_ai"):
			main._dispose_current_enemy_ai()
		main.current_enemy_data = null
		main.free()
	var combo_data_script = load("res://resources/combo_data.gd")
	if combo_data_script != null and combo_data_script.has_method("clear_combo_db_cache"):
		combo_data_script.clear_combo_db_cache()
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.player_hp = int(original_state.get("player_hp", 6))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 6))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.player_attack = int(original_state.get("player_attack", 2))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.combo_buffs = (original_state.get("combo_buffs", {}) as Dictionary).duplicate(true)
	game_state.combo_cooldowns = (original_state.get("combo_cooldowns", {}) as Dictionary).duplicate(true)
	game_state.field_pending_spend_attack = int(original_state.get("field_pending_spend_attack", 0))
	game_state.field_pending_blood_attack = int(original_state.get("field_pending_blood_attack", 0))
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.backpack = (original_state.get("backpack", []) as Array).duplicate(true)
	game_state.selected_heirloom_id = str(original_state.get("selected_heirloom_id", ""))
	game_state.item_battle_wins = int(original_state.get("item_battle_wins", 0))
	call_deferred("_quit_after_cleanup", code)

func _quit_after_cleanup(code: int) -> void:
	quit(code)
