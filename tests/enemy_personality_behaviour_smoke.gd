extends SceneTree

const EnemyAI = preload("res://scripts/enemy_ai.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	seed(20260519)
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"player_class": int(game_state.player_class),
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_shield": int(game_state.player_shield),
		"equipped_combos": game_state.equipped_combos.duplicate(true)
	}
	game_state.selected_era_id = "qin"
	game_state.player_class = 0
	game_state.equipped_combos.clear()
	game_state.equipped_combos.append("penetrating_strike")

	var repeat_ai := EnemyAI.new()
	repeat_ai.setup_elite_by_subtype(2)
	repeat_ai.add_player_history(2)
	repeat_ai.add_player_history(2)
	if _count_move(repeat_ai, 10, 10, -1, 30, 1) < 20:
		_fail("Repeat-trap enemy should mostly counter repeated player hands.", game_state, original_state, null, [repeat_ai])
		return

	var low_hp_ai := EnemyAI.new()
	low_hp_ai.setup_advanced_dynamic(EnemyAI.DynamicSubtype.STATE_BASED)
	low_hp_ai.add_player_history(0)
	if _count_move(low_hp_ai, 2, 10, -1, 30, 2) < 18:
		_fail("Low-hp state enemy should clearly change into a countering pattern.", game_state, original_state, null, [repeat_ai, low_hp_ai])
		return

	var anti_layout_ai := EnemyAI.new()
	anti_layout_ai.setup_advanced_dynamic(EnemyAI.DynamicSubtype.SEQUENCE_MIMIC)
	if _count_move(anti_layout_ai, 10, 10, 1, 30, 0) < 22:
		_fail("Anti-layout enemy should mostly counter the exposed finishing hand.", game_state, original_state, null, [repeat_ai, low_hp_ai, anti_layout_ai])
		return

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.combo_sequence.clear()
	main.combo_sequence.append(1)
	main.combo_sequence.append(1)
	if int(main._predict_combo_linchpin_move()) != 2:
		_fail("Battle should predict the single exposed layout finishing hand.", game_state, original_state, main, [repeat_ai, low_hp_ai, anti_layout_ai])
		return
	var elite_breaker := EnemyAI.new()
	elite_breaker.setup_elite_by_subtype(4)
	var intent := str(main._get_enemy_intent_hint(elite_breaker))
	if intent.find("成局") < 0 and intent.find("布局") < 0:
		_fail("Anti-layout intent should surface as a readable behavior hint.", game_state, original_state, main, [repeat_ai, low_hp_ai, anti_layout_ai, elite_breaker])
		return
	var pressure_ai := EnemyAI.new()
	pressure_ai.setup_advanced_dynamic(EnemyAI.DynamicSubtype.MIND_READER)
	main.current_enemy_ai = pressure_ai
	main._battle_last_combo_family = ""
	main._battle_combo_family_streak = 0
	game_state.player_shield = 5
	var defense_probe := {"id": "defense_probe", "name": "守势探针", "effect_type": "shield_reflect"}
	if str(main._apply_enemy_tactic_pressure(defense_probe, null)) != "":
		_fail("First repeated-family layout should not be punished immediately.", game_state, original_state, main, [repeat_ai, low_hp_ai, anti_layout_ai, elite_breaker, pressure_ai])
		return
	var pressure_text := str(main._apply_enemy_tactic_pressure(defense_probe, null))
	if pressure_text.find("敌读守势") < 0 or int(game_state.player_shield) >= 5:
		_fail("Advanced enemies should pressure repeated defense-family layouts and lengthen the loop. shield=%d text=%s" % [int(game_state.player_shield), pressure_text], game_state, original_state, main, [repeat_ai, low_hp_ai, anti_layout_ai, elite_breaker, pressure_ai])
		return
	if str(main._get_enemy_tactic_memory_hint()).find("守势") < 0:
		_fail("Battle broadcast should compactly hint that the enemy is watching the repeated tactic.", game_state, original_state, main, [repeat_ai, low_hp_ai, anti_layout_ai, elite_breaker, pressure_ai])
		return
	main._battle_last_combo_family = "defense"
	main._battle_combo_family_streak = 1
	main.battle_enemy_hp = 6
	main.battle_enemy_max_hp = 8
	var attack_probe := {"id": "attack_probe", "name": "锋芒探针", "effect_type": "damage"}
	var rotation_text := str(main._apply_tactic_rotation_reward(attack_probe, null))
	if rotation_text.find("换势") < 0 or rotation_text.find("守势转锋芒") < 0 or int(main.battle_enemy_hp) != 5:
		_fail("Switching away from a watched tactic should reward longer rotation loops. hp=%d text=%s" % [int(main.battle_enemy_hp), rotation_text], game_state, original_state, main, [repeat_ai, low_hp_ai, anti_layout_ai, elite_breaker, pressure_ai])
		return
	var causal_text := str(main._extract_causal_feedback(rotation_text))
	if causal_text.find("守势被盯") < 0 or causal_text.find("转锋芒") < 0 or causal_text.find("主敌-1") < 0:
		_fail("Rotation result should be explained as cause-action-result, got: %s" % causal_text, game_state, original_state, main, [repeat_ai, low_hp_ai, anti_layout_ai, elite_breaker, pressure_ai])
		return
	var summary_probe: Array[String] = ["判定：读中｜命中｜-3", "因果：%s" % causal_text]
	var formatted_summary := str(main._format_battle_summary_lines(summary_probe))
	if formatted_summary.find("\n") < 0 or formatted_summary.find("守势被盯") < 0:
		_fail("Battle summary should preserve the result and show a causal chain, got: %s" % formatted_summary, game_state, original_state, main, [repeat_ai, low_hp_ai, anti_layout_ai, elite_breaker, pressure_ai])
		return

	print("enemy_personality_behaviour_smoke: ok")
	_finish(0, game_state, original_state, main, [repeat_ai, low_hp_ai, anti_layout_ai, elite_breaker, pressure_ai])

func _count_move(ai: EnemyAI, enemy_hp: int, enemy_max_hp: int, predicted_player_move: int, rolls: int, expected_move: int) -> int:
	var count := 0
	for _i in range(rolls):
		if int(ai.get_next_move(enemy_hp, enemy_max_hp, predicted_player_move)) == expected_move:
			count += 1
	return count

func _fail(message: String, game_state: Node, original_state: Dictionary, main: Node = null, ais: Array = []) -> void:
	push_error(message)
	_finish(1, game_state, original_state, main, ais)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node = null, ais: Array = []) -> void:
	for ai in ais:
		if ai != null and is_instance_valid(ai):
			ai.free()
	if main != null and is_instance_valid(main):
		if main.has_method("_dispose_combo_database_cache"):
			main._dispose_combo_database_cache()
		main.free()
	var combo_data_script = load("res://resources/combo_data.gd")
	if combo_data_script != null and combo_data_script.has_method("clear_combo_db_cache"):
		combo_data_script.clear_combo_db_cache()
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.player_hp = int(original_state.get("player_hp", 6))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 6))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.equipped_combos.clear()
	for combo_id in (original_state.get("equipped_combos", []) as Array):
		game_state.equipped_combos.append(str(combo_id))
	quit(code)
