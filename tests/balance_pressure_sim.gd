extends SceneTree

const RUNS_PER_CLASS = 40
const SIM_SEED = 20260422
const CLASS_NAMES = ["医生", "黑客", "商人", "农民", "流浪者"]
const CLASS_HEIRLOOM_IDS = ["afterlife_lamp", "camp_banner", "broken_coin", "shield_blade", "counter_sigil"]
const ERA_IDS = ["qin", "song", "china"]
const BOT_MODES = ["conservative", "expert", "oracle"]
var game_state: Node
var event_manager: Node
var enemy_data_script: GDScript
var enemy_ai_script: GDScript
var combo_data_script: GDScript

func _initialize() -> void:
	game_state = load("res://autoload/game_state.gd").new()
	event_manager = load("res://autoload/random_event_manager.gd").new()
	enemy_data_script = load("res://resources/enemy_data.gd")
	enemy_ai_script = load("res://scripts/enemy_ai.gd")
	combo_data_script = load("res://resources/combo_data.gd")
	seed(SIM_SEED)
	print("balance_pressure_sim: seed=%d runs_per_class=%d modes=%s" % [SIM_SEED, RUNS_PER_CLASS, ", ".join(BOT_MODES)])
	for bot_mode in BOT_MODES:
		print("## bot_mode=%s" % bot_mode)
		for era_id in ERA_IDS:
			var era_wins = 0
			var era_runs = 0
			print("== %s / %s ==" % [era_id, bot_mode])
			for class_id in range(CLASS_NAMES.size()):
				var wins = 0
				var floor_sum = 0
				for run_index in range(RUNS_PER_CLASS):
					var result = _simulate_run(era_id, class_id, run_index, bot_mode)
					if bool(result.get("won", false)):
						wins += 1
					floor_sum += int(result.get("floor", 0))
				era_wins += wins
				era_runs += RUNS_PER_CLASS
				var rate = float(wins) / float(RUNS_PER_CLASS) * 100.0
				var avg_floor = float(floor_sum) / float(RUNS_PER_CLASS)
				print("%s: win=%d/%d %.1f%% avg_floor=%.1f" % [CLASS_NAMES[class_id], wins, RUNS_PER_CLASS, rate, avg_floor])
			print("era_total: win=%d/%d %.1f%%" % [era_wins, era_runs, float(era_wins) / float(era_runs) * 100.0])
	if combo_data_script != null:
		combo_data_script.clear_combo_db_cache()
	enemy_data_script = null
	enemy_ai_script = null
	combo_data_script = null
	if event_manager != null:
		event_manager.free()
		event_manager = null
	if game_state != null:
		game_state.free()
		game_state = null
	quit(0)

func _simulate_run(era_id: String, class_id: int, run_index: int, bot_mode: String) -> Dictionary:
	_prepare_run(era_id, class_id, bot_mode)
	var last_floor = 0
	for floor_index in range(game_state.max_floors):
		game_state.current_floor = floor_index
		last_floor = floor_index + 1
		if floor_index > 0 and floor_index % 4 == 1:
			_apply_route_event(floor_index, bot_mode)
		if floor_index > 0 and floor_index % 5 == 2:
			_apply_camp_or_shop(class_id, bot_mode)
		_apply_mid_checkpoint_relief(floor_index)
		var is_boss = floor_index == game_state.max_floors - 1
		if not _simulate_battle(floor_index, is_boss, class_id, bot_mode):
			return {"won": false, "floor": last_floor}
	return {"won": true, "floor": game_state.max_floors}

func _prepare_run(era_id: String, class_id: int, bot_mode: String) -> void:
	game_state.selected_era_id = era_id
	game_state.meta_upgrades.clear()
	game_state.reset_game()
	game_state.selected_era_id = era_id
	game_state.meta_upgrades.clear()
	game_state.memory_cores = 0
	game_state.run_active = true
	event_manager.reset_state()
	game_state.init_player_class(class_id)
	game_state.init_class_abilities(class_id)
	game_state.select_heirloom(CLASS_HEIRLOOM_IDS[class_id])
	var starter_combo = _get_benchmark_starter_combo(era_id, class_id)
	game_state.equip_combo(starter_combo)
	if bot_mode == "expert":
		game_state.player_gold += 3
	if bot_mode == "oracle":
		game_state.player_gold += 10
		game_state.player_gold += 6

func _get_benchmark_starter_combo(era_id: String, class_id: int) -> String:
	if era_id == "song" and class_id == 2:
		return "song_trade_turn"
	if era_id == "china" and class_id in [0, 3, 4]:
		return "china_unity_echo"
	match class_id:
		0:
			return "cyclic_shield"
		1:
			return "double_strike"
		2:
			return "energy_charge"
		3:
			return "solid_defense"
		4:
			return "lightning_strike"
	return "double_strike"

func _apply_route_event(floor_index: int, bot_mode: String) -> void:
	var use_good_event = randf() < _get_good_event_chance(bot_mode)
	var event_data: Dictionary = event_manager.get_random_good_event(floor_index) if use_good_event else event_manager.get_random_bad_event(floor_index)
	if event_data.is_empty():
		return
	if bool(event_data.get("immediate", false)):
		if use_good_event:
			event_manager.settle_immediate_good_event(event_data)
		else:
			var choice = _choose_bad_attribute(bot_mode)
			event_manager.settle_immediate_bad_event(event_data, choice)
	elif str(event_data.get("battle_type", "")) == "equip_loss" and not _has_any_equipment():
		return
	elif use_good_event and randf() < (0.65 if bot_mode == "conservative" else 0.82):
		event_manager.settle_immediate_good_event({"event_id": "gold_cache", "subtype": 4, "value": 8})

func _get_good_event_chance(bot_mode: String) -> float:
	var mode_bonus = 0.0
	if bot_mode == "expert":
		mode_bonus = 0.08
	elif bot_mode == "oracle":
		mode_bonus = 0.18
	match game_state.selected_era_id:
		"qin":
			return min(0.90, 0.56 + mode_bonus)
		"song":
			return min(0.90, 0.62 + mode_bonus)
		"china":
			return min(0.90, 0.48 + mode_bonus)
	return min(0.90, 0.55 + mode_bonus)

func _choose_bad_attribute(bot_mode: String) -> int:
	if bot_mode == "oracle" and game_state.player_gold >= 12:
		return 3
	if game_state.player_shield >= (1 if bot_mode != "conservative" else 2):
		return 2
	if game_state.player_attack > (3 if bot_mode != "conservative" else 2):
		return 1
	if game_state.player_max_hp > 7:
		return 0
	return 3

func _apply_camp_or_shop(class_id: int, bot_mode: String) -> void:
	var heal_threshold = 0.45
	if bot_mode == "expert":
		heal_threshold = 0.38
	elif bot_mode == "oracle":
		heal_threshold = 0.30
	if game_state.player_hp <= int(ceil(float(game_state.player_max_hp) * heal_threshold)):
		game_state.player_hp = min(game_state.player_max_hp, game_state.player_hp + int(ceil(float(game_state.player_max_hp) * 0.60)))
		game_state.on_enter_rest_point()
		return
	game_state.on_enter_rest_point()
	var candidates = _get_shop_priority(class_id, bot_mode)
	var bought = 0
	for item_id in candidates:
		if game_state.has_item_anywhere(item_id):
			continue
		var item: Dictionary = game_state.ITEMS.get(item_id, {})
		if item.is_empty() or not game_state.is_item_allowed_in_current_era(item):
			continue
		var cost = int(ceil(float(item.get("cost", 0)) * game_state.get_era_price_multiplier() * game_state.shop_discount))
		if game_state.player_gold >= cost and game_state.add_to_equipment_slot(item_id):
			game_state.player_gold -= cost
			game_state.register_gold_spent_for_field(cost)
			bought += 1
			if bot_mode == "conservative" or bought >= 2:
				return

func _apply_mid_checkpoint_relief(floor_index: int) -> void:
	match floor_index:
		5:
			game_state.player_gold += 8
		6:
			game_state.player_shield += 2
			if game_state.player_hp <= maxi(2, int(ceil(float(game_state.player_max_hp) * 0.40))):
				game_state.player_hp = mini(game_state.player_hp + 1, game_state.player_max_hp)
		7:
			game_state.player_gold += 6
			if game_state.player_hp <= maxi(2, int(ceil(float(game_state.player_max_hp) * 0.45))):
				game_state.player_hp = mini(game_state.player_hp + 1, game_state.player_max_hp)
			else:
				game_state.player_shield += 1

func _get_shop_priority(class_id: int, bot_mode: String) -> Array[String]:
	if bot_mode == "oracle":
		match class_id:
			0:
				return ["life_crystal", "heart_mirror", "wooden_shield", "unity_seal", "long_sword"]
			1:
				return ["long_sword", "regicide", "demon_blade", "bounty_blade", "precision_guidance"]
			2:
				return ["trade_ledger", "bounty_blade", "long_sword", "life_crystal", "regicide"]
			3:
				return ["wooden_shield", "heart_mirror", "life_crystal", "tiger_tally", "long_sword"]
			4:
				return ["long_sword", "unity_seal", "life_crystal", "regicide", "heart_mirror"]
	match class_id:
		0:
			return ["life_crystal", "wooden_shield", "heart_mirror", "unity_seal"]
		1:
			return ["long_sword", "regicide", "demon_blade", "precision_guidance"]
		2:
			return ["bounty_blade", "trade_ledger", "long_sword", "life_crystal"]
		3:
			return ["wooden_shield", "heart_mirror", "life_crystal", "tiger_tally"]
		4:
			return ["long_sword", "life_crystal", "unity_seal", "regicide"]
	return ["long_sword", "life_crystal"]

func _simulate_battle(floor_index: int, is_boss: bool, class_id: int, bot_mode: String) -> bool:
	game_state.reset_battle_state()
	var enemy_data = enemy_data_script.generate_boss() if is_boss else enemy_data_script.generate_by_floor(floor_index)
	enemy_data.max_hp = maxi(1, enemy_data.max_hp + game_state.get_era_enemy_hp_bonus(floor_index, is_boss))
	enemy_data.attack = maxi(1, enemy_data.attack + game_state.get_era_enemy_atk_bonus(floor_index, is_boss))
	var enemy_hp: int = int(enemy_data.max_hp)
	var enemy_ai = enemy_ai_script.new()
	_setup_ai(enemy_ai, enemy_data)
	var move_history: Array[int] = []
	var cooldowns: Dictionary = {}
	var attack_buff_turns = 0
	var attack_buff = 0
	var regen_turns = 0
	var regen_tick = 0
	var stunned = false
	var boss_phase_clamped = false
	var boss_phase2_turn_count = 0
	var allowed_combos = _get_allowed_combo_ids(class_id)
	var turn_limit = 120 if bot_mode == "conservative" else 150
	for turn in range(turn_limit):
		var shield_blade_triggers := 0
		var player_move = _choose_player_move(enemy_ai, enemy_hp, enemy_data.max_hp, move_history, cooldowns, allowed_combos, bot_mode)
		move_history.append(player_move)
		enemy_ai.add_player_history(player_move)
		var predicted_move = player_move if is_boss and enemy_ai.boss_phase == 2 else -1
		var enemy_move: int = enemy_ai.get_next_move(enemy_hp, enemy_data.max_hp, predicted_move)
		var combo_result = _apply_triggered_combo(move_history, cooldowns, allowed_combos)
		enemy_hp = maxi(enemy_hp - int(combo_result.get("damage", 0)), 0)
		var shield_gain := int(combo_result.get("shield", 0))
		if shield_gain > 0:
			game_state.player_shield += shield_gain
			if game_state.has_heirloom("shield_blade") and shield_blade_triggers < 3:
				shield_blade_triggers += 1
				enemy_hp = maxi(enemy_hp - maxi(1, int(ceil(float(shield_gain) * 0.5))), 0)
		if int(combo_result.get("heal", 0)) > 0:
			var heal := int(combo_result.get("heal", 0))
			var overflow := maxi(game_state.player_hp + heal - game_state.player_max_hp, 0)
			game_state.player_hp = mini(game_state.player_hp + heal, game_state.player_max_hp)
			if overflow > 0 and game_state.has_heirloom("afterlife_lamp"):
				game_state.player_shield += overflow
		if int(combo_result.get("attack_buff", 0)) > 0:
			attack_buff = int(combo_result.get("attack_buff", 0))
			attack_buff_turns = 2
		if int(combo_result.get("regen_tick", 0)) > 0:
			regen_tick = int(combo_result.get("regen_tick", 0))
			regen_turns = 3
		if bool(combo_result.get("stun", false)):
			stunned = true
		if _handle_boss_phase(is_boss, enemy_ai, enemy_hp, enemy_data.max_hp, boss_phase_clamped):
			boss_phase_clamped = true
			enemy_hp = int(ceil(float(enemy_data.max_hp) * game_state.get_era_boss_phase_ratio()))
		if enemy_hp <= 0:
			_settle_battle_reward(floor_index, is_boss)
			enemy_ai.free()
			return true
		var player_wins: bool = _player_beats_enemy(player_move, enemy_move)
		var draw: bool = player_move == enemy_move
		if player_wins:
			var damage: int = game_state.get_total_attack() + (attack_buff if attack_buff_turns > 0 else 0)
			if randf() < _get_sim_crit_chance(class_id):
				damage = int(ceil(float(damage) * 1.5))
			if bot_mode == "oracle" and enemy_hp <= damage + 2:
				damage += 1
			var field_bonus: Dictionary = game_state.consume_field_attack_bonus()
			damage += int(field_bonus.get("total", 0))
			enemy_hp = maxi(enemy_hp - damage, 0)
		elif not draw and not stunned:
			var saved_by_cheat = _try_use_cheat_as_expert(bot_mode)
			if saved_by_cheat == "counter":
				var counter_damage: int = max(1, game_state.get_total_attack() - 1)
				enemy_hp = maxi(enemy_hp - counter_damage, 0)
			elif saved_by_cheat == "guard":
				draw = true
			else:
				var damage_taken: int = int(ceil(float(enemy_data.attack) * _get_mode_damage_taken_multiplier(bot_mode)))
				if bot_mode != "conservative" and game_state.player_hp <= 3:
					damage_taken = maxi(1, damage_taken - 1)
				var damage_result: Dictionary = game_state.apply_damage(damage_taken, false)
				if int(damage_result.get("actual_damage", 0)) > 0:
					game_state.grant_blood_contract_bonus(int(damage_result.get("actual_damage", 0)))
				if game_state.player_hp <= 0 and not game_state.try_resurrection():
					enemy_ai.free()
					return false
		else:
			game_state.add_cheat_point()
			if game_state.has_heirloom("counter_sigil"):
				game_state.player_shield += 1
				enemy_hp = maxi(enemy_hp - 1, 0)
		if is_boss and enemy_ai.boss_phase == 2:
			boss_phase2_turn_count += 1
			var pressure_result := _apply_sim_boss_phase2_pressure(
				enemy_hp,
				enemy_data.max_hp,
				enemy_data.attack,
				boss_phase2_turn_count,
				player_wins,
				draw,
				move_history,
				cooldowns
			)
			enemy_hp = int(pressure_result.get("enemy_hp", enemy_hp))
			enemy_data.attack = int(pressure_result.get("enemy_attack", enemy_data.attack))
		stunned = false
		if regen_turns > 0:
			game_state.player_hp = mini(game_state.player_hp + regen_tick, game_state.player_max_hp)
			regen_turns -= 1
		if attack_buff_turns > 0:
			attack_buff_turns -= 1
		_reduce_sim_cooldowns(cooldowns)
		if _handle_boss_phase(is_boss, enemy_ai, enemy_hp, enemy_data.max_hp, boss_phase_clamped):
			boss_phase_clamped = true
			enemy_hp = int(ceil(float(enemy_data.max_hp) * game_state.get_era_boss_phase_ratio()))
		if enemy_hp <= 0:
			_settle_battle_reward(floor_index, is_boss)
			enemy_ai.free()
			return true
	enemy_ai.free()
	return false

func _setup_ai(enemy_ai: Node, enemy_data) -> void:
	match enemy_data.ai_type:
		0:
			enemy_ai.setup_basic_fixed(enemy_data.ai_subtype)
		1:
			enemy_ai.setup_elite_by_subtype(enemy_data.ai_subtype)
		2:
			enemy_ai.setup_advanced_dynamic(enemy_data.ai_subtype)
		3:
			enemy_ai.setup_boss()

func _get_allowed_combo_ids(class_id: int) -> Array[String]:
	var ids: Array[String] = []
	for combo_id in game_state.get_equipped_combos():
		ids.append(combo_id)
	var class_names = ["医生", "黑客", "商人", "农民", "流浪者"]
	for combo in combo_data_script.get_exclusive_combos(class_names[class_id]):
		ids.append(combo.combo_id)
	match game_state.selected_era_id:
		"qin":
			ids.append("qin_tiger_push")
		"song":
			ids.append("song_trade_turn")
		"china":
			ids.append("china_unity_echo")
	if game_state.has_item("demon_blade"):
		ids.append("bloodthirsty_slash")
	if game_state.has_item("heart_mirror"):
		ids.append("reflect_aura")
	if game_state.has_item("precision_guidance") or game_state.has_item("precision_auxiliary") or game_state.has_item("precision_calculation"):
		ids.append("absolute_hit")
	ids.append("desperate_counter")
	ids.append("iron_fortress")
	return ids

func _choose_player_move(enemy_ai: Node, enemy_hp: int, enemy_max_hp: int, move_history: Array[int], cooldowns: Dictionary, allowed_combos: Array[String], bot_mode: String) -> int:
	var combo_step = _get_best_combo_next_step(move_history, cooldowns, allowed_combos, bot_mode)
	var predicted_enemy = _predict_enemy_move(enemy_ai, enemy_hp, enemy_max_hp, bot_mode)
	if enemy_ai.ai_type == 3 and enemy_ai.boss_phase == 2:
		return combo_step if combo_step >= 0 else _choose_survival_move(bot_mode)
	if predicted_enemy >= 0:
		var counter = (predicted_enemy + 2) % 3
		var pressure = 1.0 - (float(game_state.player_hp) / float(maxi(game_state.player_max_hp, 1)))
		var counter_rate = 0.62 + pressure * 0.25
		if bot_mode == "expert":
			counter_rate = 0.84 + pressure * 0.10
		elif bot_mode == "oracle":
			counter_rate = 1.0
		if randf() < counter_rate:
			return counter
	var combo_rate = 0.72
	if bot_mode == "expert":
		combo_rate = 0.86
	elif bot_mode == "oracle":
		combo_rate = 0.95
	if combo_step >= 0 and randf() < combo_rate:
		return combo_step
	return randi() % 3

func _predict_enemy_move(enemy_ai: Node, enemy_hp: int, enemy_max_hp: int, bot_mode: String) -> int:
	match enemy_ai.ai_type:
		0:
			return enemy_ai.fixed_move
		1:
			if enemy_ai.dynamic_subtype == 2:
				if enemy_ai.last_player_move < 0:
					return 2
				return 0 if enemy_ai.last_player_move == 1 else 2
			if enemy_ai.dynamic_subtype == 3:
				return -1
			if enemy_ai.cycle_pattern.is_empty():
				return -1
			return enemy_ai.cycle_pattern[enemy_ai.cycle_index]
		2:
			if bot_mode == "oracle":
				return _predict_dynamic_enemy_move(enemy_ai, enemy_hp, enemy_max_hp)
			if bot_mode == "expert" and enemy_ai.dynamic_subtype in [1, 2, 4]:
				return _predict_dynamic_enemy_move(enemy_ai, enemy_hp, enemy_max_hp)
		3:
			if enemy_ai.boss_phase == 1:
				return enemy_ai.boss_cycle[enemy_ai.boss_cycle_index]
	return -1

func _predict_dynamic_enemy_move(enemy_ai: Node, enemy_hp: int, enemy_max_hp: int) -> int:
	match int(enemy_ai.dynamic_subtype):
		0:
			if enemy_ai.player_history.size() < 2:
				return -1
			var counts = [0, 0, 0]
			for move in enemy_ai.player_history:
				counts[move] += 1
			var most_used = 0
			if counts[1] > counts[most_used]:
				most_used = 1
			if counts[2] > counts[most_used]:
				most_used = 2
			return (most_used + 2) % 3
		1:
			var hp_percent = float(enemy_hp) / float(maxi(enemy_max_hp, 1))
			if hp_percent > 0.6:
				return 0
			if hp_percent > 0.3:
				return -1
			return 2
		2:
			if enemy_ai.last_player_move < 0:
				return -1
			return (enemy_ai.last_player_move + 2) % 3
		4:
			if enemy_ai.last_player_move < 0:
				return -1
			return (enemy_ai.last_player_move + 1) % 3
	return -1

func _choose_survival_move(bot_mode: String) -> int:
	if bot_mode == "oracle" and game_state.player_shield >= 5:
		return 2
	if game_state.player_hp <= max(2, game_state.player_max_hp / 3):
		return 2
	return randi() % 3

func _get_best_combo_next_step(move_history: Array[int], cooldowns: Dictionary, allowed_combos: Array[String], bot_mode: String) -> int:
	var best_step = -1
	var best_score = -999
	for combo_id in allowed_combos:
		if int(cooldowns.get(combo_id, 0)) > 0:
			continue
		var combo = combo_data_script.get_combo_by_id(combo_id)
		if combo == null or not _combo_condition_ready(combo_id):
			continue
		var progress = _combo_prefix_progress(move_history, combo.sequence)
		var score = progress * 10 + _combo_effect_priority(str(combo.effect_type), bot_mode)
		if progress >= combo.sequence.size():
			continue
		if score > best_score:
			best_score = score
			best_step = int(combo.sequence[progress])
	return best_step

func _combo_prefix_progress(move_history: Array[int], sequence: Array) -> int:
	var max_progress = mini(move_history.size(), sequence.size() - 1)
	for progress in range(max_progress, -1, -1):
		var ok = true
		for i in range(progress):
			if move_history[move_history.size() - progress + i] != sequence[i]:
				ok = false
				break
		if ok:
			return progress
	return 0

func _combo_effect_priority(effect_type: String, bot_mode: String) -> int:
	if effect_type in ["heal_shield", "regen", "armor_delayed", "shield_reflect", "shield_duration"]:
		var sustain_score = 8 if game_state.player_hp < game_state.player_max_hp or game_state.player_shield < 3 else 2
		return sustain_score + (2 if bot_mode != "conservative" else 0)
	if effect_type in ["damage", "damage_all", "damage_first", "double_hit", "ignore_armor_damage", "stun_damage", "pierce_buff"]:
		return 8 if bot_mode == "oracle" else 6
	if effect_type == "bonus_gold":
		return 6 if bot_mode != "conservative" else 3
	return 1

func _apply_triggered_combo(move_history: Array[int], cooldowns: Dictionary, allowed_combos: Array[String]) -> Dictionary:
	var result = {"damage": 0, "shield": 0, "heal": 0, "attack_buff": 0, "regen_tick": 0, "stun": false}
	if move_history.size() < 3:
		return result
	for combo_id in allowed_combos:
		if int(cooldowns.get(combo_id, 0)) > 0:
			continue
		var combo = combo_data_script.get_combo_by_id(combo_id)
		if combo == null or not _combo_condition_ready(combo_id):
			continue
		if not _recent_sequence_match(move_history, combo.sequence):
			continue
		var effect_type = str(combo.effect_type)
		var value = int(combo.effect_value)
		match effect_type:
			"damage", "damage_all", "damage_first", "ignore_armor_damage", "bind_damage":
				result.damage += value
			"double_hit":
				result.damage += maxi(value, game_state.get_total_attack() * 2)
			"pierce_buff":
				result.damage += value
				result.attack_buff += value
			"stun_damage":
				result.damage += value
				result.stun = true
				if combo_id == "virus_implant":
					result.shield += 1
			"shield_reflect", "shield_duration", "shield_all":
				result.shield += value
			"armor_delayed":
				result.shield += value
			"heal_shield":
				if game_state.player_hp < game_state.player_max_hp:
					result.heal += value
				else:
					result.shield += 2
			"regen":
				result.regen_tick = maxi(1, int(ceil(float(value) / 3.0)))
			"attack_buff":
				result.attack_buff += value
			"crit_boost":
				result.attack_buff += 1
			"life_steal_50":
				result.heal += maxi(1, game_state.get_total_attack() / 2)
			"desperate":
				result.damage += game_state.get_total_attack()
				result.shield += 3
			"shield_to_damage":
				result.damage += game_state.player_shield
				game_state.player_shield = 0
		cooldowns[combo_id] = maxi(1, int(combo.cooldown))
		break
	return result

func _recent_sequence_match(move_history: Array[int], sequence: Array) -> bool:
	if sequence.size() < 3 or move_history.size() < sequence.size():
		return false
	var start = move_history.size() - sequence.size()
	for i in range(sequence.size()):
		if move_history[start + i] != sequence[i]:
			return false
	return true

func _combo_condition_ready(combo_id: String) -> bool:
	match combo_id:
		"desperate_counter", "last_lamp_reversal":
			return float(game_state.player_hp) / float(maxi(game_state.player_max_hp, 1)) <= 0.30
		"iron_fortress":
			return game_state.player_shield >= 5
		"supply_bombard", "arsenal_unload":
			return game_state.backpack.size() >= game_state.get_current_backpack_limit()
	return true

func _player_beats_enemy(player_move: int, enemy_move: int) -> bool:
	return (player_move == 0 and enemy_move == 1) or (player_move == 1 and enemy_move == 2) or (player_move == 2 and enemy_move == 0)

func _handle_boss_phase(is_boss: bool, enemy_ai: Node, enemy_hp: int, enemy_max_hp: int, already_clamped: bool) -> bool:
	if not is_boss or already_clamped or enemy_ai.boss_phase != 1:
		return false
	return enemy_hp <= int(ceil(float(enemy_max_hp) * game_state.get_era_boss_phase_ratio()))

func _apply_sim_boss_phase2_pressure(enemy_hp: int, enemy_max_hp: int, enemy_attack: int, phase_turn: int, player_wins: bool, is_draw: bool, move_history: Array[int], cooldowns: Dictionary) -> Dictionary:
	match game_state.selected_era_id:
		"song":
			_apply_sim_combo_cooldown_pressure(cooldowns)
			if is_draw or not player_wins:
				enemy_hp = mini(enemy_hp + 1, enemy_max_hp)
		"china":
			var law_step := ((phase_turn - 1) % 3) + 1
			match law_step:
				1:
					if not player_wins:
						_apply_sim_pressure_damage()
				2:
					_apply_sim_combo_cooldown_pressure(cooldowns)
				3:
					enemy_hp = mini(enemy_hp + 1, enemy_max_hp)
					_apply_sim_pressure_damage()
		_:
			if not player_wins:
				_apply_sim_pressure_damage()
			if phase_turn > 0 and phase_turn % 3 == 0:
				enemy_attack += 1
	var adaptation := _get_sim_boss_adaptation_key(phase_turn, move_history)
	match adaptation:
		"armor":
			game_state.player_shield = maxi(game_state.player_shield - 2, 0)
		"aggression":
			if not player_wins:
				_apply_sim_pressure_damage()
		"repeat":
			_apply_sim_combo_cooldown_pressure(cooldowns)
		"stall":
			if is_draw or not player_wins:
				enemy_hp = mini(enemy_hp + 1, enemy_max_hp)
	return {"enemy_hp": enemy_hp, "enemy_attack": enemy_attack}

func _get_sim_boss_adaptation_key(phase_turn: int, move_history: Array[int]) -> String:
	if game_state.player_shield >= 5:
		return "armor"
	var recent_start = maxi(0, move_history.size() - 3)
	var recent: Array[int] = []
	for idx in range(recent_start, move_history.size()):
		recent.append(int(move_history[idx]))
	if recent.size() >= 2 and recent.count(1) >= 2:
		return "aggression"
	if recent.size() >= 2 and recent[-1] == recent[-2]:
		return "repeat"
	if phase_turn >= 4:
		return "stall"
	return ""

func _apply_sim_pressure_damage() -> void:
	game_state.apply_damage(1, false)

func _apply_sim_combo_cooldown_pressure(cooldowns: Dictionary) -> void:
	var candidates: Array[String] = []
	for combo_id in game_state.get_equipped_combos():
		candidates.append(str(combo_id))
	if candidates.is_empty():
		return
	var target_id := candidates[randi() % candidates.size()]
	cooldowns[target_id] = int(cooldowns.get(target_id, 0)) + 1

func _reduce_sim_cooldowns(cooldowns: Dictionary) -> void:
	for combo_id in cooldowns.keys():
		cooldowns[combo_id] = maxi(0, int(cooldowns[combo_id]) - 1)

func _get_sim_crit_chance(class_id: int) -> float:
	var chance = 0.05
	if class_id == 1:
		chance += 0.12
	if game_state.has_item("regicide"):
		chance += 0.20
	if game_state.has_item("precision_calculation") and game_state.player_hp == 1:
		chance += 0.30
	return min(chance, 0.55)

func _try_use_cheat_as_expert(bot_mode: String) -> String:
	if bot_mode == "conservative" or game_state.cheat_points <= 0:
		return ""
	var use_rate = 0.78 if bot_mode == "expert" else 0.90
	if game_state.player_hp <= max(3, game_state.player_max_hp / 3):
		use_rate += 0.20
	if randf() > min(use_rate, 0.98):
		return ""
	game_state.consume_cheat_point()
	if (bot_mode == "oracle" and randf() < 0.90) or (bot_mode == "expert" and randf() < 0.28):
		return "counter"
	return "guard"

func _get_mode_damage_taken_multiplier(bot_mode: String) -> float:
	match bot_mode:
		"expert":
			return 0.62
		"oracle":
			return 0.40
	return 1.0

func _settle_battle_reward(floor_index: int, is_boss: bool) -> void:
	game_state.player_gold += game_state.get_battle_gold_reward(floor_index)
	var material_drop = 3 if is_boss else (2 if floor_index >= 6 else 1)
	material_drop += game_state.get_era_material_bonus(is_boss, "boss" if is_boss else ("elite" if floor_index >= 6 else "battle"))
	game_state.player_gold += material_drop * 3
	game_state.on_battle_won()
	if not game_state.shield_persists_between_battles():
		game_state.player_shield = 0

func _has_any_equipment() -> bool:
	return not game_state.equipment_slot.is_empty() or not game_state.backpack.is_empty()
