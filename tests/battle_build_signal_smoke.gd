extends SceneTree

const EnemyAI = preload("res://scripts/enemy_ai.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"player_class": int(game_state.player_class),
		"current_floor": int(game_state.current_floor),
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_attack": int(game_state.player_attack),
		"player_shield": int(game_state.player_shield),
		"player_gold": int(game_state.player_gold),
		"selected_heirloom_id": str(game_state.selected_heirloom_id),
		"field_pending_spend_attack": int(game_state.field_pending_spend_attack),
		"field_pending_blood_attack": int(game_state.field_pending_blood_attack),
		"equipped_combos": game_state.equipped_combos.duplicate(true),
		"combo_cooldowns": game_state.combo_cooldowns.duplicate(true),
		"combo_upgrades": game_state.combo_upgrades.duplicate(true),
		"max_combo_slots": int(game_state.max_combo_slots),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"backpack": game_state.backpack.duplicate(true)
	}
	game_state.equipment_slot.clear()
	game_state.backpack.clear()

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var ai := EnemyAI.new()
	ai.setup_boss()
	main.current_enemy_ai = ai
	main.is_current_battle_boss = false
	var support_probe = load("res://resources/enemy_data.gd").new()
	support_probe.max_hp = 22
	support_probe.attack = 5
	var support_nodes: Array[Dictionary] = main._build_battle_support_enemies({"support_count": 2, "route_name": "近攻线"}, false, support_probe)
	if support_nodes.size() != 2 or int(support_nodes[0].get("assist", 0)) > 1 or int(support_nodes[1].get("assist", 0)) > 1:
		push_error("Support enemies should pressure formation, not shred high-shield builds: %s" % str(support_nodes))
		_finish(1, main, ai, game_state, original_state)
		return

	var finisher := {"id": "formation_breaker", "name": "破阵终式", "sequence": [0, 1, 2, 0]}
	var triggered: Array[Dictionary] = [{"combo": finisher, "is_equipment": false}]
	var finisher_summary := str(main._get_finisher_summary(triggered))
	if finisher_summary.find("终式:") < 0:
		push_error("Finisher summary should mark four-step finishers, got: %s" % finisher_summary)
		_finish(1, main, ai, game_state, original_state)
		return

	game_state.player_shield = 7
	if str(main._get_build_breakthrough_signal(true, false, "")).find("护甲成势") < 0:
		push_error("Build signal should expose armor momentum.")
		_finish(1, main, ai, game_state, original_state)
		return
	if str(main._get_build_breakthrough_signal(true, false, "")) != "":
		push_error("Build signal should not repeat the same state every turn.")
		_finish(1, main, ai, game_state, original_state)
		return
	game_state.player_shield = 0
	game_state.player_gold = 0
	game_state.field_pending_spend_attack = 0
	game_state.player_hp = 10
	game_state.player_max_hp = 10
	game_state.player_attack = 5
	if str(main._get_build_breakthrough_signal(true, false, "")).find("杀机已成") < 0:
		push_error("Build signal should expose attack momentum.")
		_finish(1, main, ai, game_state, original_state)
		return
	game_state.player_hp = 2
	game_state.player_max_hp = 10
	game_state.player_shield = 0
	main.battle_enemy_hp = 10
	if str(main._get_turn_momentum_hint(false, false, ai)).find("命线危险") < 0:
		push_error("Turn momentum should expose low-hp pressure without teaching text.")
		_finish(1, main, ai, game_state, original_state)
		return
	game_state.player_hp = 8
	game_state.player_max_hp = 10
	game_state.player_shield = 1
	main.combo_sequence.clear()
	main.combo_sequence.append(0)
	main.combo_sequence.append(1)
	var summary_parts: Array = main._build_result_summary_parts("", "", "", "", main._get_turn_momentum_hint(false, true, ai))
	if summary_parts.is_empty() or str(summary_parts[-1]).find("局势:") < 0:
		push_error("Battle result summary should include a compact momentum line.")
		_finish(1, main, ai, game_state, original_state)
		return
	var hidden_signal_parts: Array = main._build_result_summary_parts("传家宝:盾刃", "护甲+2 盾刃-2", "", "护甲成势", "局势:节奏在手")
	if "护甲成势" in hidden_signal_parts:
		push_error("Battle result summary should not expose build naming labels.")
		_finish(1, main, ai, game_state, original_state)
		return
	if str(main._get_result_stage_text(hidden_signal_parts, "护甲成势")).find("成型信号") >= 0:
		push_error("Stage text should not tell players that a build has formed.")
		_finish(1, main, ai, game_state, original_state)
		return
	if str(main._get_result_stage_text(hidden_signal_parts, "护甲成势")).find("护甲+2") < 0:
		push_error("Stage text should show concrete result instead of build label.")
		_finish(1, main, ai, game_state, original_state)
		return
	var fixed_ai := EnemyAI.new()
	fixed_ai.setup_basic_fixed(1)
	if str(main._get_move_read_pressure_hint(0, fixed_ai)).find("预感:可压") < 0:
		push_error("Move hover should expose a readable pressure window against predictable enemies.")
		fixed_ai.free()
		_finish(1, main, ai, game_state, original_state)
		return
	fixed_ai.setup_basic_fixed(2)
	if str(main._get_move_read_pressure_hint(0, fixed_ai)).find("可能被") < 0:
		push_error("Move hover should expose risk against predictable counters.")
		fixed_ai.free()
		_finish(1, main, ai, game_state, original_state)
		return
	if str(main._get_move_read_state(0, fixed_ai)) != "risk":
		push_error("Move read state should mark predictable counters as risk.")
		fixed_ai.free()
		_finish(1, main, ai, game_state, original_state)
		return
	if str(main._get_move_read_state(1, fixed_ai)) != "advantage":
		push_error("Move read state should mark winning readable moves as advantage.")
		fixed_ai.free()
		_finish(1, main, ai, game_state, original_state)
		return
	if str(main._get_move_read_state(0, ai)) != "draw":
		push_error("Boss phase-one predictable cycle should expose draw state when matched.")
		fixed_ai.free()
		_finish(1, main, ai, game_state, original_state)
		return
	ai.set_boss_phase(2)
	if str(main._get_move_read_state(0, ai)) != "anti_read":
		push_error("Boss phase two should mark hover state as anti-read pressure.")
		fixed_ai.free()
		_finish(1, main, ai, game_state, original_state)
		return
	if str(main._get_move_read_state_label("advantage")) != "可压" or str(main._get_move_read_state_label("risk")) != "有险":
		push_error("Move read state labels should stay compact for hover subtitles.")
		fixed_ai.free()
		_finish(1, main, ai, game_state, original_state)
		return
	fixed_ai.free()
	game_state.equipment_slot.clear()
	game_state.select_heirloom("broken_coin")
	game_state.equipment_slot.append(game_state.ITEMS["trade_ledger"].duplicate(true))
	game_state.field_pending_spend_attack = 0
	if game_state.register_gold_spent_for_field(5) != 2 or int(game_state.field_pending_spend_attack) != 2:
		push_error("Trade ledger should resonate with broken coin and add extra spend attack.")
		_finish(1, main, ai, game_state, original_state)
		return
	game_state.equipment_slot.clear()
	game_state.select_heirloom("shield_blade")
	game_state.equipment_slot.append(game_state.ITEMS["wooden_shield"].duplicate(true))
	game_state.player_shield = 0
	main.battle_enemy_hp = 10
	main._field_shield_blade_triggers = 0
	main._gain_player_shield(2, null, "护甲")
	if int(main.battle_enemy_hp) != 8:
		push_error("Wooden shield should resonate with shield blade for +1 blade damage, enemy_hp=%d" % int(main.battle_enemy_hp))
		_finish(1, main, ai, game_state, original_state)
		return
	var blade_battle := Control.new()
	var blade_impact := Label.new()
	blade_impact.name = "BattleImpactLabel"
	blade_battle.add_child(blade_impact)
	var blade_flash := ColorRect.new()
	blade_flash.name = "BattleFlash"
	blade_battle.add_child(blade_flash)
	root.add_child(blade_battle)
	main.battle_enemy_hp = 10
	main._field_shield_blade_triggers = 0
	main._gain_player_shield(2, blade_battle, "护甲")
	if str(blade_impact.text).find("盾刃") < 0 or not _tree_has_label_text(blade_battle, "-2"):
		push_error("Shield blade reflect should show enemy damage feedback instead of only changing HP.")
		blade_battle.free()
		_finish(1, main, ai, game_state, original_state)
		return
	blade_battle.free()
	game_state.player_class = 3
	game_state.current_floor = 19
	var farmer_cap: int = game_state.get_farmer_shield_soft_cap()
	game_state.player_shield = farmer_cap
	main.battle_enemy_hp = 10
	var farmer_overflow_text: String = main._gain_player_shield(4, null, "护甲")
	if game_state.player_shield != farmer_cap or main.battle_enemy_hp != 8 or farmer_overflow_text.find("溢甲") < 0:
		push_error("Farmer over-cap armor should convert to pressure instead of infinite stacking. shield=%d cap=%d hp=%d text=%s" % [game_state.player_shield, farmer_cap, main.battle_enemy_hp, farmer_overflow_text])
		_finish(1, main, ai, game_state, original_state)
		return
	game_state.player_class = 0
	game_state.combo_cooldowns.clear()
	main._battle_combo_repeat_counts.clear()
	main.battle_enemy_hp = 20
	main.battle_enemy_max_hp = 20
	main.battle_support_enemies.clear()
	var repeated_combo = main._get_combo_database().get_combo_by_id("penetrating_strike")
	if repeated_combo == null:
		push_error("Repeat adaptation test requires penetrating_strike combo.")
		_finish(1, main, ai, game_state, original_state)
		return
	var expected_first_damage: int = game_state.get_combo_effect_amount("penetrating_strike", int(repeated_combo.effect_value), str(repeated_combo.effect_type))
	var first_repeat_result: Dictionary = main._apply_single_combo_effect(repeated_combo, false, null)
	if main.battle_enemy_hp != 20 - expected_first_damage or str(first_repeat_result.get("text", "")).find("敌识旧势") >= 0:
		push_error("First combo use should be full strength and not adapted. hp=%d text=%s" % [main.battle_enemy_hp, str(first_repeat_result.get("text", ""))])
		_finish(1, main, ai, game_state, original_state)
		return
	game_state.combo_cooldowns.clear()
	var second_repeat_result: Dictionary = main._apply_single_combo_effect(repeated_combo, false, null)
	var actual_second_damage: int = 20 - expected_first_damage - main.battle_enemy_hp
	if actual_second_damage >= expected_first_damage or str(second_repeat_result.get("text", "")).find("敌识旧势") < 0:
		push_error("Repeated combo should be read by enemies and lose some force. hp=%d text=%s" % [main.battle_enemy_hp, str(second_repeat_result.get("text", ""))])
		_finish(1, main, ai, game_state, original_state)
		return
	if int(game_state.combo_cooldowns.get("penetrating_strike", 0)) <= int(repeated_combo.cooldown):
		push_error("Repeated combo should gain extra cooldown pressure, cooldown=%s" % str(game_state.combo_cooldowns.get("penetrating_strike", null)))
		_finish(1, main, ai, game_state, original_state)
		return
	game_state.equipment_slot.clear()
	game_state.select_heirloom("counter_sigil")
	game_state.equipment_slot.append(game_state.ITEMS["precision_guidance"].duplicate(true))
	game_state.player_shield = 0
	main.battle_enemy_hp = 10
	main._apply_counter_sigil_on_draw(null)
	if int(game_state.player_shield) != 2 or int(main.battle_enemy_hp) != 8:
		push_error("Precision gear should resonate with counter sigil for +1 armor and damage.")
		_finish(1, main, ai, game_state, original_state)
		return
	if str(main._get_bonus_result_impact_type("破财", 4)) != "heavy_hit":
		push_error("Large field bonus should use heavy hit feedback.")
		_finish(1, main, ai, game_state, original_state)
		return
	var reward_summary := str(main._format_battle_reward_summary(7, 2, 3, ["机括+1"]))
	if reward_summary.find("金币+7") < 0 or reward_summary.find("经验+3") < 0 or reward_summary.find("机括+1") < 0:
		push_error("Battle reward summary should expose concrete gains, got: %s" % reward_summary)
		_finish(1, main, ai, game_state, original_state)
		return
	if reward_summary.find("材料") >= 0:
		push_error("Battle reward summary should not mention removed materials, got: %s" % reward_summary)
		_finish(1, main, ai, game_state, original_state)
		return
	if str(main._get_bonus_result_impact_type("盾刃", 3)) != "read":
		push_error("Readable heirloom hits should use read feedback at medium strength.")
		_finish(1, main, ai, game_state, original_state)
		return
	if int(main._get_bonus_result_shake("血契", 4)) <= int(main._get_bonus_result_shake("盾刃", 2)):
		push_error("Heavy blood/spend bonuses should shake harder than light heirloom hits.")
		_finish(1, main, ai, game_state, original_state)
		return
	game_state.max_combo_slots = 8
	game_state.equipped_combos.clear()
	var display_combo_ids: Array[String] = [
		"penetrating_strike",
		"tactical_interference",
		"lightning_strike",
		"solid_defense",
		"energy_charge",
		"cyclic_shield",
		"bind_fatal",
		"double_strike",
		"pierce"
	]
	for combo_id in display_combo_ids:
		game_state.equipped_combos.append(combo_id)
	game_state.combo_upgrades.clear()
	game_state.combo_upgrades["penetrating_strike"] = {"level": 3, "has_burn": false, "has_slow": false}
	game_state.equipment_slot.clear()
	for item_id in ["demon_blade", "heart_mirror", "precision_guidance", "long_sword", "life_crystal", "wooden_shield"]:
		game_state.equipment_slot.append(game_state.ITEMS[item_id].duplicate(true))
	game_state.backpack.clear()
	for item_id in ["blood_tyrant", "vampire_blade", "poison_coating", "thorn_armor", "life_armor", "soul_collector"]:
		game_state.backpack.append(game_state.ITEMS[item_id].duplicate(true))
	var enemy_data = load("res://resources/enemy_data.gd").new()
	enemy_data.enemy_id = "battle_ui_display_probe"
	enemy_data.display_name = "显示校验"
	enemy_data.max_hp = 12
	enemy_data.attack = 1
	enemy_data.ai_type = 0
	enemy_data.ai_subtype = 0
	main.battle_enemy_max_hp = enemy_data.max_hp
	main.battle_enemy_hp = enemy_data.max_hp
	main.battle_enemy_atk = enemy_data.attack
	var battle_ui: Control = main._create_battle_ui(enemy_data, ai, 0, 0)
	root.add_child(battle_ui)
	if battle_ui.get_node_or_null("MomentumField") != null:
		push_error("Battle momentum should no longer occupy the center field.")
		battle_ui.free()
		_finish(1, main, ai, game_state, original_state)
		return
	if battle_ui.get_node_or_null("PlayerMomentumField") == null or battle_ui.get_node_or_null("EnemyMomentumField") == null:
		push_error("Battle momentum should live inside both portrait frames.")
		battle_ui.free()
		_finish(1, main, ai, game_state, original_state)
		return
	if battle_ui.get_node_or_null("DuelMomentumRail") == null or battle_ui.get_node_or_null("DuelMomentumMarker") == null:
		push_error("Battle center should expose readable momentum rail instead of abstract center field.")
		battle_ui.free()
		_finish(1, main, ai, game_state, original_state)
		return
	var equipped_combo_text := str(battle_ui.get_node("EquippedCombosLabel").text)
	var equipped_combo_card := battle_ui.get_node_or_null("EquippedCombosCard") as Panel
	var combat_combo_btn := battle_ui.get_node_or_null("ComboButtons/CombatCombo_pierce") as Button
	var item_text := str(battle_ui.get_node("ItemsLabel").text)
	var backpack_text := str(battle_ui.get_node("BackpackLabel").text)
	if equipped_combo_text.find("…+") >= 0 or item_text.find("…+") >= 0 or backpack_text.find("…+") >= 0:
		push_error("Battle UI should show full combo/equipment/backpack lists without +N truncation.")
		battle_ui.free()
		_finish(1, main, ai, game_state, original_state)
		return
	if equipped_combo_text.find("双重打击") < 0 or item_text.find("木盾") < 0 or backpack_text.find("魂魄收集者") < 0:
		push_error("Battle UI should include the last visible combo/equipment/backpack entries.")
		battle_ui.free()
		_finish(1, main, ai, game_state, original_state)
		return
	if equipped_combo_text.find("全体伤害9") < 0 or equipped_combo_text.find("全体伤害5") >= 0 or equipped_combo_text.find("CD3") < 0:
		push_error("Battle layout panel should show upgraded current combo details, got: %s" % equipped_combo_text)
		battle_ui.free()
		_finish(1, main, ai, game_state, original_state)
		return
	if equipped_combo_card == null or str(equipped_combo_card.tooltip_text).find("全体穿透伤害") < 0 or str(equipped_combo_card.tooltip_text).find("当前：全体伤害9") < 0:
		push_error("Battle layout panel should expose full combo detail and current upgraded values in tooltip.")
		battle_ui.free()
		_finish(1, main, ai, game_state, original_state)
		return
	if combat_combo_btn == null or str(combat_combo_btn.tooltip_text).find("3次攻击") < 0:
		push_error("Combat combo button should show detailed tooltip for direct-use layouts.")
		battle_ui.free()
		_finish(1, main, ai, game_state, original_state)
		return
	battle_ui.free()

	print("battle_build_signal_smoke: ok")
	_finish(0, main, ai, game_state, original_state)

func _finish(code: int, main: Node, ai: Node, game_state: Node, original_state: Dictionary) -> void:
	if main != null and main.has_method("_dispose_combo_database_cache"):
		main._dispose_combo_database_cache()
	if ai != null:
		ai.free()
	if main != null:
		main.free()
	var combo_data_script = load("res://resources/combo_data.gd")
	if combo_data_script != null and combo_data_script.has_method("clear_combo_db_cache"):
		combo_data_script.clear_combo_db_cache()
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.current_floor = int(original_state.get("current_floor", 0))
	game_state.player_hp = int(original_state.get("player_hp", 6))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 6))
	game_state.player_attack = int(original_state.get("player_attack", 2))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.selected_heirloom_id = str(original_state.get("selected_heirloom_id", ""))
	game_state.field_pending_spend_attack = int(original_state.get("field_pending_spend_attack", 0))
	game_state.field_pending_blood_attack = int(original_state.get("field_pending_blood_attack", 0))
	game_state.equipped_combos.clear()
	for cid in (original_state.get("equipped_combos", []) as Array):
		game_state.equipped_combos.append(str(cid))
	game_state.combo_cooldowns = (original_state.get("combo_cooldowns", {}) as Dictionary).duplicate(true)
	game_state.combo_upgrades = (original_state.get("combo_upgrades", {}) as Dictionary).duplicate(true)
	game_state.max_combo_slots = int(original_state.get("max_combo_slots", 2))
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.backpack = (original_state.get("backpack", []) as Array).duplicate(true)
	quit(code)

func _tree_has_label_text(node: Node, text: String) -> bool:
	if node is Label and str((node as Label).text) == text:
		return true
	for child in node.get_children():
		if _tree_has_label_text(child, text):
			return true
	return false
