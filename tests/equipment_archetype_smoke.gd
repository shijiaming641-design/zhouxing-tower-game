extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_shield": int(game_state.player_shield),
		"combo_cooldowns": game_state.combo_cooldowns.duplicate(true),
		"combo_buffs": game_state.combo_buffs.duplicate(true),
		"combo_upgrades": game_state.combo_upgrades.duplicate(true),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"backpack": game_state.backpack.duplicate(true)
	}
	game_state.equipment_slot.clear()
	game_state.backpack.clear()
	game_state.combo_buffs.clear()
	game_state.player_max_hp = 10
	game_state.player_hp = 10
	game_state.player_shield = 0

	if not game_state.add_to_equipment_slot("life_armor"):
		push_error("life_armor should equip")
		_finish(1, game_state, original_state)
		return
	if int(game_state.player_max_hp) != 20 or int(game_state.player_hp) != 20:
		push_error("life_armor should grant +10 max hp and heal, got %d/%d" % [game_state.player_hp, game_state.player_max_hp])
		_finish(1, game_state, original_state)
		return

	game_state.equipment_slot.clear()
	game_state.player_max_hp = 10
	game_state.player_hp = 10
	game_state.equipment_slot.append(game_state.ITEMS["life_crystal"].duplicate(true))
	game_state.equipment_slot.append(game_state.ITEMS["life_armor"].duplicate(true))
	game_state.equipment_slot.append(game_state.ITEMS["soul_collector"].duplicate(true))
	var soul_gain: int = game_state.on_difficult_battle_won()
	if soul_gain != 15 or int(game_state.player_max_hp) != 25:
		push_error("soul_collector life set should grant +15 max hp, got gain=%d max=%d" % [soul_gain, game_state.player_max_hp])
		_finish(1, game_state, original_state)
		return

	game_state.equipment_slot.clear()
	game_state.player_shield = 0
	game_state.equipment_slot.append(game_state.ITEMS["heart_mirror"].duplicate(true))
	game_state.setup_pre_battle()
	if int(game_state.player_shield) != 4:
		push_error("heart_mirror should grant 4 prebattle armor, got %d" % game_state.player_shield)
		_finish(1, game_state, original_state)
		return

	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["vampire_blade"].duplicate(true))
	if int(game_state.get_life_steal(10)) != 2:
		push_error("vampire_blade should steal 20%% of damage")
		_finish(1, game_state, original_state)
		return

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

	game_state.combo_cooldowns.clear()
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["demon_blade"].duplicate(true))
	var slash_sequence: Array[int] = [1, 2, 1]
	var empty_allowed: Array[String] = []
	var slash_matches: Array[Dictionary] = main._gather_triggered_combos(slash_sequence, empty_allowed, main._get_combo_database())
	if slash_matches.size() != 1 or _combo_id(slash_matches[0].get("combo")) != "bloodthirsty_slash":
		push_error("demon_blade should unlock bloodthirsty_slash on △□△, got %s" % str(slash_matches))
		_finish(1, game_state, original_state, main)
		return
	var slash_result: Dictionary = main._apply_single_combo_effect(slash_matches[0].get("combo"), bool(slash_matches[0].get("is_equipment", false)))
	if not bool(slash_result.get("consumes_sequence", false)):
		push_error("bloodthirsty_slash should consume the combo sequence")
		_finish(1, game_state, original_state, main)
		return
	if not game_state.is_combo_on_cooldown("bloodthirsty_slash"):
		push_error("bloodthirsty_slash should enter cooldown after trigger")
		_finish(1, game_state, original_state, main)
		return
	var blocked_matches: Array[Dictionary] = main._gather_triggered_combos(slash_sequence, empty_allowed, main._get_combo_database())
	if not blocked_matches.is_empty():
		push_error("bloodthirsty_slash should not retrigger while cooling down")
		_finish(1, game_state, original_state, main)
		return

	game_state.combo_cooldowns.clear()
	game_state.combo_upgrades.clear()
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["heart_mirror"].duplicate(true))
	var reflect_sequence: Array[int] = [0, 2, 0]
	var reflect_matches: Array[Dictionary] = main._gather_triggered_combos(reflect_sequence, empty_allowed, main._get_combo_database())
	if reflect_matches.size() != 1 or _combo_id(reflect_matches[0].get("combo")) != "reflect_aura":
		push_error("heart_mirror should unlock reflect_aura on ○□○, got %s" % str(reflect_matches))
		_finish(1, game_state, original_state, main)
		return
	var reflect_result: Dictionary = main._apply_single_combo_effect(reflect_matches[0].get("combo"), bool(reflect_matches[0].get("is_equipment", false)))
	if not bool(reflect_result.get("consumes_sequence", false)) or str(reflect_result.get("text", "")).find("反弹3倍") < 0:
		push_error("reflect_aura should consume sequence and expose x3 reflect, got %s" % str(reflect_result))
		_finish(1, game_state, original_state, main)
		return
	var reflect_summary: String = main._extract_trigger_summary(reflect_matches, str(reflect_result.get("text", "")))
	if reflect_summary.find("反伤光环") < 0 or reflect_summary.find("护心镜") < 0:
		push_error("reflect_aura summary should support ComboData resources, got %s" % reflect_summary)
		_finish(1, game_state, original_state, main)
		return
	var reflect_battle := _make_minimal_battle_ui()
	root.add_child(reflect_battle)
	main.battle_enemy_max_hp = 20
	main.battle_enemy_hp = 20
	var reflect_phase: Dictionary = await main._run_battle_combo_phase(reflect_matches, reflect_battle)
	if str(reflect_phase.get("summary_line", "")).find("反伤光环") < 0:
		push_error("reflect_aura full combo phase should summarize without Resource.name access, got %s" % str(reflect_phase))
		await create_timer(1.25).timeout
		reflect_battle.free()
		_finish(1, game_state, original_state, main)
		return
	await create_timer(1.25).timeout
	reflect_battle.free()
	main.battle_enemy_hp = 20
	main.battle_enemy_atk = 3
	game_state.player_shield = 4
	var reflect_exchange: Dictionary = main._resolve_turn_exchange(0, 2, reflect_matches, false, false, null)
	if int(main.battle_enemy_hp) != 11 or int(game_state.player_shield) != 1 or str(reflect_exchange.get("text", "")).find("反伤光环×3:9") < 0:
		push_error("reflect_aura should triple heart_mirror reflect, hp=%d shield=%d text=%s" % [main.battle_enemy_hp, game_state.player_shield, str(reflect_exchange.get("text", ""))])
		_finish(1, game_state, original_state, main)
		return
	game_state.combo_cooldowns.clear()
	game_state.combo_upgrades["reflect_aura"] = {"level": 3, "has_burn": false, "has_slow": false}
	var upgraded_matches: Array[Dictionary] = main._gather_triggered_combos(reflect_sequence, empty_allowed, main._get_combo_database())
	main.battle_enemy_hp = 20
	main.battle_enemy_atk = 3
	game_state.player_shield = 4
	var upgraded_exchange: Dictionary = main._resolve_turn_exchange(0, 2, upgraded_matches, false, false, null)
	if int(main.battle_enemy_hp) != 5 or str(upgraded_exchange.get("text", "")).find("反伤光环×5:15") < 0:
		push_error("upgraded reflect_aura should scale reflect multiplier, hp=%d text=%s" % [main.battle_enemy_hp, str(upgraded_exchange.get("text", ""))])
		_finish(1, game_state, original_state, main)
		return

	main.battle_enemy_hp = 20
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["poison_coating"].duplicate(true))
	main._apply_poison_from_enemy_damage(3, null)
	var poison_text: String = main._apply_enemy_poison_tick("", null)
	if int(main.battle_enemy_hp) != 19 or poison_text.find("中毒-1") < 0:
		push_error("poison_coating should add poison that ticks for damage")
		_finish(1, game_state, original_state, main)
		return

	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["heart_armor"].duplicate(true))
	game_state.player_shield = 0
	var heart_text: String = main._start_equipment_turn_state(null)
	if int(game_state.player_shield) != 2 or heart_text.find("护心甲+2") < 0:
		push_error("heart_armor should grant 2 temporary armor at turn start")
		_finish(1, game_state, original_state, main)
		return
	main._clear_heart_armor_temp_shield()
	if int(game_state.player_shield) != 0:
		push_error("heart_armor temporary armor should clear before carrying forward")
		_finish(1, game_state, original_state, main)
		return

	main.battle_enemy_hp = 20
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["thorn_armor"].duplicate(true))
	var thorn_text: String = main._apply_thorn_armor_reflect(3, null)
	if int(main.battle_enemy_hp) != 17 or thorn_text.find("反甲3") < 0:
		push_error("thorn_armor should reflect lost armor as damage")
		_finish(1, game_state, original_state, main)
		return

	print("equipment_archetype_smoke: ok")
	_finish(0, game_state, original_state, main)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node = null) -> void:
	if main != null:
		if main.has_method("_dispose_combo_database_cache"):
			main._dispose_combo_database_cache()
		main.queue_free()
	var combo_data_script = load("res://resources/combo_data.gd")
	if combo_data_script != null and combo_data_script.has_method("clear_combo_db_cache"):
		combo_data_script.clear_combo_db_cache()
	game_state.player_hp = int(original_state.get("player_hp", 6))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 6))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.combo_cooldowns = (original_state.get("combo_cooldowns", {}) as Dictionary).duplicate(true)
	game_state.combo_buffs = (original_state.get("combo_buffs", {}) as Dictionary).duplicate(true)
	game_state.combo_upgrades = (original_state.get("combo_upgrades", {}) as Dictionary).duplicate(true)
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.backpack = (original_state.get("backpack", []) as Array).duplicate(true)
	quit(code)

func _combo_id(combo) -> String:
	if combo == null:
		return ""
	if combo.get("id") != null:
		return str(combo.id)
	if combo.get("combo_id") != null:
		return str(combo.combo_id)
	return ""

func _make_minimal_battle_ui() -> Control:
	var battle := Control.new()
	for label_name in ["EnemyHP", "PlayerHP", "PlayerAtk", "PlayerShield"]:
		var label := Label.new()
		label.name = label_name
		battle.add_child(label)
	var impact := Label.new()
	impact.name = "BattleImpactLabel"
	battle.add_child(impact)
	var flash := ColorRect.new()
	flash.name = "BattleFlash"
	battle.add_child(flash)
	return battle
