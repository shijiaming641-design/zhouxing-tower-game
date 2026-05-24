extends SceneTree

const EnemyAI = preload("res://scripts/enemy_ai.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_shield": int(game_state.player_shield),
		"selected_heirloom_id": str(game_state.selected_heirloom_id),
		"field_pending_spend_attack": int(game_state.field_pending_spend_attack),
		"field_pending_blood_attack": int(game_state.field_pending_blood_attack),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"equipped_combos": game_state.get_equipped_combos().duplicate(),
		"combo_cooldowns": game_state.combo_cooldowns.duplicate(true)
	}

	if not _check_qin_pressure(game_state):
		_restore(game_state, original_state, 1)
		return
	if not _check_song_pressure(game_state):
		_restore(game_state, original_state, 1)
		return
	if not _check_china_pressure(game_state):
		_restore(game_state, original_state, 1)
		return
	if not _check_boss_adaptation(game_state):
		_restore(game_state, original_state, 1)
		return
	if not _check_field_turning_points(game_state):
		_restore(game_state, original_state, 1)
		return

	print("boss_era_pressure_smoke: ok")
	_restore(game_state, original_state, 0)

func _make_boss_main(era_id: String, game_state: Node) -> Node:
	game_state.selected_era_id = era_id
	game_state.player_max_hp = 10
	game_state.player_hp = 10
	game_state.player_shield = 0
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var ai := EnemyAI.new()
	ai.setup_boss()
	ai.set_boss_phase(2)
	main.is_current_battle_boss = true
	main.current_enemy_ai = ai
	main.battle_enemy_max_hp = 12
	main.battle_enemy_hp = 6
	main.battle_enemy_atk = 3
	return main

func _check_qin_pressure(game_state: Node) -> bool:
	var main := _make_boss_main("qin", game_state)
	main._apply_era_boss_turn_pressure(false, false, "")
	main._apply_era_boss_turn_pressure(true, false, "")
	main._apply_era_boss_turn_pressure(true, false, "")
	if int(game_state.player_hp) != 9:
		push_error("Qin boss phase 2 should punish failed turns with 1 damage, hp=%d" % game_state.player_hp)
		return false
	if int(main.battle_enemy_atk) != 4:
		push_error("Qin boss phase 2 should raise attack every three phase turns, atk=%d" % main.battle_enemy_atk)
		return false
	main.current_enemy_ai.free()
	main.free()
	return true

func _check_song_pressure(game_state: Node) -> bool:
	var main := _make_boss_main("song", game_state)
	var text := str(main._apply_era_boss_turn_pressure(false, true, ""))
	if int(main.battle_enemy_hp) != 7:
		push_error("Song boss phase 2 should recover on stalemate, hp=%d" % main.battle_enemy_hp)
		return false
	if text.find("守势回稳") < 0:
		push_error("Song boss phase 2 should report recovery pressure, got: %s" % text)
		return false
	main.current_enemy_ai.free()
	main.free()
	return true

func _check_china_pressure(game_state: Node) -> bool:
	var main := _make_boss_main("china", game_state)
	game_state.get_equipped_combos().clear()
	game_state.get_equipped_combos().append("pierce")
	game_state.combo_cooldowns.clear()
	main._apply_era_boss_turn_pressure(false, false, "")
	main._apply_era_boss_turn_pressure(true, false, "")
	main._apply_era_boss_turn_pressure(true, false, "")
	if int(game_state.player_hp) != 9:
		push_error("China boss first old law should punish failed turns, hp=%d" % game_state.player_hp)
		return false
	if not _has_any_cooldown_pressure(game_state.combo_cooldowns):
		push_error("China boss second old law should push combo cooldown, cooldowns=%s" % str(game_state.combo_cooldowns))
		return false
	if int(main.battle_enemy_hp) != 7:
		push_error("China boss third old law should recover, hp=%d" % main.battle_enemy_hp)
		return false
	if not main._era_boss_china_burn_active:
		push_error("China boss third old law should arm final ember.")
		return false
	main.current_enemy_ai.free()
	main.free()
	return true

func _has_any_cooldown_pressure(cooldowns: Dictionary) -> bool:
	for value in cooldowns.values():
		if int(value) > 0:
			return true
	return false

func _check_boss_adaptation(game_state: Node) -> bool:
	var armor_main := _make_boss_main("qin", game_state)
	game_state.player_shield = 6
	if str(armor_main._get_boss_danger_preview(armor_main.current_enemy_ai)).find("碎甲") < 0:
		push_error("Boss adaptation preview should warn about armor crack.")
		return false
	armor_main._apply_era_boss_turn_pressure(true, false, "")
	if int(game_state.player_shield) != 4:
		push_error("Boss armor adaptation should crack 2 shield, shield=%d" % game_state.player_shield)
		return false
	armor_main.current_enemy_ai.free()
	armor_main.free()

	var aggression_main := _make_boss_main("qin", game_state)
	game_state.player_shield = 0
	game_state.player_hp = 10
	aggression_main._record_battle_history(1, 0, aggression_main.current_enemy_ai)
	aggression_main._record_battle_history(1, 0, aggression_main.current_enemy_ai)
	if str(aggression_main._get_boss_danger_preview(aggression_main.current_enemy_ai)).find("连续抢攻") < 0:
		push_error("Boss adaptation preview should warn about repeated aggression.")
		return false
	aggression_main._apply_era_boss_turn_pressure(false, false, "")
	if int(game_state.player_hp) != 8:
		push_error("Boss repeated aggression adaptation should add pressure damage on failed turns, hp=%d" % game_state.player_hp)
		return false
	aggression_main.current_enemy_ai.free()
	aggression_main.free()

	var spend_main := _make_boss_main("qin", game_state)
	game_state.selected_heirloom_id = "broken_coin"
	_set_equipment_slot(game_state, [{"id": "trade_ledger"}])
	game_state.field_pending_spend_attack = 7
	if str(spend_main._get_boss_danger_preview(spend_main.current_enemy_ai)).find("蓄着重势") < 0:
		push_error("Boss adaptation preview should warn against loaded spend pressure.")
		return false
	var spend_text := str(spend_main._apply_era_boss_turn_pressure(true, false, ""))
	if int(game_state.field_pending_spend_attack) != 5 or spend_text.find("针对破财-2") < 0:
		push_error("Boss loaded-spend adaptation should drain pending spend, pending=%d text=%s" % [game_state.field_pending_spend_attack, spend_text])
		return false
	spend_main.current_enemy_ai.free()
	spend_main.free()

	var low_life_main := _make_boss_main("qin", game_state)
	game_state.selected_heirloom_id = "blood_contract"
	game_state.player_hp = 3
	game_state.player_max_hp = 10
	game_state.player_shield = 0
	if str(low_life_main._get_boss_danger_preview(low_life_main.current_enemy_ai)).find("命线边缘") < 0:
		push_error("Boss adaptation preview should warn against low-life sustain play.")
		return false
	low_life_main._apply_era_boss_turn_pressure(false, false, "")
	if int(game_state.player_hp) != 1:
		push_error("Boss low-life adaptation should add chase damage after the base boss pressure, hp=%d" % game_state.player_hp)
		return false
	low_life_main.current_enemy_ai.free()
	low_life_main.free()
	return true

func _check_field_turning_points(game_state: Node) -> bool:
	game_state.selected_heirloom_id = "broken_coin"
	_set_equipment_slot(game_state, [{"id": "trade_ledger"}])
	game_state.field_pending_spend_attack = 8
	game_state.field_pending_blood_attack = 0
	var spend_bonus: Dictionary = game_state.consume_field_attack_bonus()
	if int(spend_bonus.get("spend", 0)) != 10 or not bool(spend_bonus.get("spend_break", false)):
		push_error("Broken coin should turn high spend into a bigger attack swing, got=%s" % str(spend_bonus))
		return false

	game_state.selected_heirloom_id = "blood_contract"
	_set_equipment_slot(game_state, [{"id": "demon_blade"}])
	game_state.field_pending_spend_attack = 0
	game_state.field_pending_blood_attack = 6
	var blood_bonus: Dictionary = game_state.consume_field_attack_bonus()
	if int(blood_bonus.get("blood", 0)) != 7 or not bool(blood_bonus.get("blood_break", false)):
		push_error("Blood contract should turn high blood debt into a stronger payoff, got=%s" % str(blood_bonus))
		return false
	return true

func _set_equipment_slot(game_state: Node, items: Array) -> void:
	game_state.equipment_slot.clear()
	for item in items:
		game_state.equipment_slot.append(item)

func _restore(game_state: Node, original_state: Dictionary, code: int) -> void:
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.player_hp = int(original_state.get("player_hp", 6))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 6))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.selected_heirloom_id = str(original_state.get("selected_heirloom_id", ""))
	game_state.field_pending_spend_attack = int(original_state.get("field_pending_spend_attack", 0))
	game_state.field_pending_blood_attack = int(original_state.get("field_pending_blood_attack", 0))
	_set_equipment_slot(game_state, (original_state.get("equipment_slot", []) as Array).duplicate(true))
	game_state.set("equipped_combos", (original_state.get("equipped_combos", []) as Array).duplicate())
	game_state.set("combo_cooldowns", (original_state.get("combo_cooldowns", {}) as Dictionary).duplicate(true))
	quit(code)
