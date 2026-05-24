extends SceneTree

const CLASS_NAMES: Array[String] = ["医生", "黑客", "商人", "农民", "流浪者"]
const SIM_SEED := 20260518
const RUNS_PER_CASE := 40
const TURN_LIMIT := 26

var game_state: Node
var enemy_data_script: GDScript
var enemy_ai_script: GDScript
var combo_data_script: GDScript
var selectable_combos: Array = []
var rng := RandomNumberGenerator.new()

func _initialize() -> void:
	game_state = load("res://autoload/game_state.gd").new()
	enemy_data_script = load("res://resources/enemy_data.gd")
	enemy_ai_script = load("res://scripts/enemy_ai.gd")
	combo_data_script = load("res://resources/combo_data.gd")
	rng.seed = SIM_SEED
	seed(SIM_SEED)

	var combo_db = load("res://resources/combo_database.gd").new()
	combo_db._init_database()
	selectable_combos = combo_db.get_start_selectable_combos()
	if selectable_combos.size() < 2:
		push_error("random_layout_experience_sim needs at least two selectable layouts.")
		_cleanup_and_quit(1, combo_db)
		return

	var total := _new_bucket()
	var weak_cases: Array[String] = []
	var hot_cases: Array[String] = []
	print("random_layout_experience_sim: seed=%d runs_per_case=%d cases=%d" % [SIM_SEED, RUNS_PER_CASE, CLASS_NAMES.size() * game_state.get_heirloom_ids().size()])
	for class_id in range(CLASS_NAMES.size()):
		for heirloom_id in game_state.get_heirloom_ids():
			var bucket := _simulate_case(class_id, str(heirloom_id))
			_merge_bucket(total, bucket)
			var line := _format_case_line(CLASS_NAMES[class_id], str(game_state.get_heirloom_data(str(heirloom_id)).get("name", heirloom_id)), bucket)
			print(line)
			var win_rate := _bucket_win_rate(bucket)
			var avg_combo := _bucket_avg(bucket, "combo_triggers")
			var avg_heirloom := _bucket_avg(bucket, "heirloom_triggers")
			if win_rate < 0.42 or avg_combo < 0.75:
				weak_cases.append("%s+%s 胜率%.1f%% 布局%.2f" % [CLASS_NAMES[class_id], str(game_state.get_heirloom_data(str(heirloom_id)).get("name", heirloom_id)), win_rate * 100.0, avg_combo])
			if win_rate > 0.72 and avg_heirloom >= 0.85:
				hot_cases.append("%s+%s 胜率%.1f%% 传家宝%.2f" % [CLASS_NAMES[class_id], str(game_state.get_heirloom_data(str(heirloom_id)).get("name", heirloom_id)), win_rate * 100.0, avg_heirloom])

	print("TOTAL %s" % _format_bucket(total))
	print("WEAK %s" % ("；".join(weak_cases) if not weak_cases.is_empty() else "无明显低反馈组合"))
	print("HOT %s" % ("；".join(hot_cases) if not hot_cases.is_empty() else "无明显过热组合"))
	_cleanup_and_quit(0, combo_db)

func _simulate_case(class_id: int, heirloom_id: String) -> Dictionary:
	var bucket := _new_bucket()
	for run_index in range(RUNS_PER_CASE):
		var result := _simulate_battle_sample(class_id, heirloom_id, run_index)
		_record_result(bucket, result)
	return bucket

func _simulate_battle_sample(class_id: int, heirloom_id: String, run_index: int) -> Dictionary:
	var opening_heirloom_triggers := _prepare_sample_state(class_id, heirloom_id, run_index)
	var pair := _pick_random_combo_pair()
	var equipped_ids: Array[String] = []
	for combo in pair:
		equipped_ids.append(str(combo.id))
		game_state.equipped_combos.append(str(combo.id))

	var floor_index: int = [1, 3, 5, 7, 9][rng.randi_range(0, 4)]
	var enemy_data = enemy_data_script.generate_by_floor(floor_index)
	var enemy_hp := int(enemy_data.max_hp)
	var enemy_max_hp := int(enemy_data.max_hp)
	var enemy_attack := int(enemy_data.attack)
	var enemy_ai = enemy_ai_script.new()
	_setup_ai(enemy_ai, enemy_data)

	var move_history: Array[int] = []
	var cooldowns: Dictionary = {}
	var stats := {
		"won": false,
		"turns": 0,
		"combo_triggers": 0,
		"heirloom_triggers": opening_heirloom_triggers,
		"damage_dealt": 0,
		"damage_taken": 0,
		"fail_hp": false,
		"fail_timeout": false,
	}

	for turn in range(TURN_LIMIT):
		stats.turns = turn + 1
		var combo_before: int = int(stats.combo_triggers)
		var player_move: int = _choose_player_move(move_history, cooldowns, equipped_ids, enemy_ai, enemy_hp, enemy_max_hp)
		var enemy_move: int = enemy_ai.get_next_move(enemy_hp, enemy_max_hp, -1)
		move_history.append(player_move)
		enemy_ai.add_player_history(player_move)

		var combo_result: Dictionary = _apply_triggered_combo(move_history, cooldowns, equipped_ids)
		enemy_hp = maxi(enemy_hp - int(combo_result.get("damage", 0)), 0)
		stats.damage_dealt = int(stats.damage_dealt) + int(combo_result.get("damage", 0))
		stats.combo_triggers = int(stats.combo_triggers) + int(combo_result.get("triggers", 0))
		stats.heirloom_triggers = int(stats.heirloom_triggers) + int(combo_result.get("heirloom_triggers", 0))
		if enemy_hp <= 0:
			stats.won = true
			break

		var player_wins: bool = _player_beats_enemy(player_move, enemy_move)
		var is_draw: bool = player_move == enemy_move
		if player_wins:
			var damage: int = game_state.get_total_attack()
			var field_bonus: Dictionary = game_state.consume_field_attack_bonus()
			var field_total := int(field_bonus.get("total", 0))
			if field_total > 0:
				stats.heirloom_triggers = int(stats.heirloom_triggers) + 1
				damage += field_total
			enemy_hp = maxi(enemy_hp - damage, 0)
			stats.damage_dealt = int(stats.damage_dealt) + damage
		elif is_draw:
			game_state.add_cheat_point()
			if game_state.has_heirloom("counter_sigil"):
				game_state.player_shield += 1
				enemy_hp = maxi(enemy_hp - 1, 0)
				stats.damage_dealt = int(stats.damage_dealt) + 1
				stats.heirloom_triggers = int(stats.heirloom_triggers) + 1
		else:
			var damage_result: Dictionary = game_state.apply_damage(enemy_attack, false)
			var actual_damage := int(damage_result.get("actual_damage", 0))
			stats.damage_taken = int(stats.damage_taken) + actual_damage
			if actual_damage > 0 and game_state.has_heirloom("blood_contract"):
				game_state.grant_blood_contract_bonus(actual_damage)
				stats.heirloom_triggers = int(stats.heirloom_triggers) + 1

		if enemy_hp <= 0:
			stats.won = true
			break
		if game_state.player_hp <= 0:
			stats.fail_hp = true
			break

		_reduce_cooldowns(cooldowns)
		if int(stats.combo_triggers) > combo_before and game_state.has_heirloom("camp_banner") and int(stats.combo_triggers) >= 2:
			enemy_hp = maxi(enemy_hp - 3, 0)
			stats.damage_dealt = int(stats.damage_dealt) + 3
			stats.heirloom_triggers = int(stats.heirloom_triggers) + 1
			if enemy_hp <= 0:
				stats.won = true
				break

	if not bool(stats.won) and not bool(stats.fail_hp):
		stats.fail_timeout = true
	enemy_ai.free()
	return stats

func _prepare_sample_state(class_id: int, heirloom_id: String, run_index: int) -> int:
	game_state.selected_era_id = "qin"
	game_state.reset_game()
	game_state.selected_era_id = "qin"
	game_state.init_player_class(class_id)
	game_state.select_heirloom(heirloom_id)
	game_state.equipped_combos.clear()
	game_state.combo_cooldowns.clear()
	game_state.player_gold = 6 + (run_index % 5) * 2
	game_state.player_shield = 0
	var shield_before: int = game_state.player_shield
	game_state.setup_pre_battle()
	var opening_trigger := 1 if heirloom_id == "afterlife_lamp" and int(game_state.player_shield) > shield_before else 0
	if heirloom_id == "broken_coin":
		game_state.field_pending_spend_attack = rng.randi_range(1, 7)
	if heirloom_id == "blood_contract":
		game_state.field_pending_blood_attack = rng.randi_range(0, 3)
	return opening_trigger

func _pick_random_combo_pair() -> Array:
	var first_idx := rng.randi_range(0, selectable_combos.size() - 1)
	var second_idx := rng.randi_range(0, selectable_combos.size() - 1)
	while second_idx == first_idx:
		second_idx = rng.randi_range(0, selectable_combos.size() - 1)
	return [selectable_combos[first_idx], selectable_combos[second_idx]]

func _choose_player_move(move_history: Array[int], cooldowns: Dictionary, equipped_ids: Array[String], enemy_ai: Node, enemy_hp: int, enemy_max_hp: int) -> int:
	var combo_step := _get_best_combo_next_step(move_history, cooldowns, equipped_ids)
	if combo_step >= 0 and rng.randf() < 0.78:
		return combo_step
	var predicted := _predict_enemy_move(enemy_ai, enemy_hp, enemy_max_hp)
	if predicted >= 0 and rng.randf() < 0.62:
		return (predicted + 2) % 3
	return rng.randi_range(0, 2)

func _get_best_combo_next_step(move_history: Array[int], cooldowns: Dictionary, equipped_ids: Array[String]) -> int:
	var best_step := -1
	var best_score := -999
	for combo_id in equipped_ids:
		if int(cooldowns.get(combo_id, 0)) > 0:
			continue
		var combo = combo_data_script.get_combo_by_id(combo_id)
		if combo == null:
			continue
		var progress := _combo_prefix_progress(move_history, combo.sequence)
		if progress >= combo.sequence.size():
			continue
		var score := progress * 10 + _combo_effect_priority(str(combo.effect_type))
		if score > best_score:
			best_score = score
			best_step = int(combo.sequence[progress])
	return best_step

func _combo_prefix_progress(move_history: Array[int], sequence: Array) -> int:
	var max_progress := mini(move_history.size(), sequence.size() - 1)
	for progress in range(max_progress, -1, -1):
		var ok := true
		for i in range(progress):
			if move_history[move_history.size() - progress + i] != sequence[i]:
				ok = false
				break
		if ok:
			return progress
	return 0

func _combo_effect_priority(effect_type: String) -> int:
	if effect_type in ["damage", "damage_all", "damage_first", "ignore_armor_damage", "stun_damage", "pierce_buff"]:
		return 8
	if effect_type in ["shield_reflect", "shield_duration", "shield_all", "heal_shield", "regen", "armor_delayed"]:
		return 7 if game_state.player_hp < game_state.player_max_hp or game_state.player_shield < 3 else 3
	if effect_type == "bonus_gold":
		return 4
	return 2

func _apply_triggered_combo(move_history: Array[int], cooldowns: Dictionary, equipped_ids: Array[String]) -> Dictionary:
	var result := {"damage": 0, "shield": 0, "heal": 0, "triggers": 0, "heirloom_triggers": 0}
	if move_history.size() < 3:
		return result
	for combo_id in equipped_ids:
		if int(cooldowns.get(combo_id, 0)) > 0:
			continue
		var combo = combo_data_script.get_combo_by_id(combo_id)
		if combo == null or not _recent_sequence_match(move_history, combo.sequence):
			continue
		var value := int(combo.effect_value)
		match str(combo.effect_type):
			"damage", "damage_all", "damage_first", "ignore_armor_damage", "stun_damage":
				result.damage += value
			"pierce_buff", "attack_buff", "crit_boost":
				result.damage += maxi(1, value)
			"shield_reflect", "shield_duration", "shield_all", "armor_delayed":
				result.shield += value
			"heal", "heal_shield", "regen":
				result.heal += maxi(1, value)
			"bonus_gold":
				game_state.register_gold_spent_for_field(5)
				result.heirloom_triggers += 1 if game_state.has_heirloom("broken_coin") else 0
		if int(result.get("shield", 0)) > 0:
			var shield_gain := int(result.get("shield", 0))
			game_state.player_shield += shield_gain
			if game_state.has_heirloom("shield_blade"):
				result.damage += maxi(1, int(ceil(float(shield_gain) * 0.5)))
				result.heirloom_triggers += 1
		if int(result.get("heal", 0)) > 0:
			var heal := int(result.get("heal", 0))
			var hp_before: int = game_state.player_hp
			var overflow := maxi(game_state.player_hp + heal - game_state.player_max_hp, 0)
			game_state.player_hp = mini(game_state.player_hp + heal, game_state.player_max_hp)
			var actual_heal: int = game_state.player_hp - hp_before
			if game_state.has_heirloom("afterlife_lamp") and (overflow > 0 or actual_heal == 0):
				game_state.player_shield += maxi(overflow, 1)
				result.heirloom_triggers += 1
		result.triggers += 1
		cooldowns[combo_id] = maxi(1, int(combo.cooldown))
		break
	return result

func _recent_sequence_match(move_history: Array[int], sequence: Array) -> bool:
	if sequence.size() < 3 or move_history.size() < sequence.size():
		return false
	var start := move_history.size() - sequence.size()
	for i in range(sequence.size()):
		if int(move_history[start + i]) != int(sequence[i]):
			return false
	return true

func _reduce_cooldowns(cooldowns: Dictionary) -> void:
	for combo_id in cooldowns.keys():
		cooldowns[combo_id] = maxi(0, int(cooldowns[combo_id]) - 1)

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

func _predict_enemy_move(enemy_ai: Node, enemy_hp: int, enemy_max_hp: int) -> int:
	match enemy_ai.ai_type:
		0:
			return enemy_ai.fixed_move
		1:
			if enemy_ai.dynamic_subtype == 2:
				if enemy_ai.last_player_move < 0:
					return 2
				return 0 if enemy_ai.last_player_move == 1 else 2
			if not enemy_ai.cycle_pattern.is_empty():
				return enemy_ai.cycle_pattern[enemy_ai.cycle_index]
		2:
			if enemy_ai.dynamic_subtype == 1:
				var hp_percent := float(enemy_hp) / float(maxi(enemy_max_hp, 1))
				if hp_percent > 0.6:
					return 0
				if hp_percent <= 0.3:
					return 2
	return -1

func _player_beats_enemy(player_move: int, enemy_move: int) -> bool:
	return (player_move == 0 and enemy_move == 1) or (player_move == 1 and enemy_move == 2) or (player_move == 2 and enemy_move == 0)

func _new_bucket() -> Dictionary:
	return {
		"runs": 0,
		"wins": 0,
		"turns": 0,
		"combo_triggers": 0,
		"heirloom_triggers": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"fail_hp": 0,
		"fail_timeout": 0,
	}

func _record_result(bucket: Dictionary, result: Dictionary) -> void:
	bucket.runs += 1
	bucket.wins += 1 if bool(result.get("won", false)) else 0
	bucket.turns += int(result.get("turns", 0))
	bucket.combo_triggers += int(result.get("combo_triggers", 0))
	bucket.heirloom_triggers += int(result.get("heirloom_triggers", 0))
	bucket.damage_dealt += int(result.get("damage_dealt", 0))
	bucket.damage_taken += int(result.get("damage_taken", 0))
	bucket.fail_hp += 1 if bool(result.get("fail_hp", false)) else 0
	bucket.fail_timeout += 1 if bool(result.get("fail_timeout", false)) else 0

func _merge_bucket(total: Dictionary, bucket: Dictionary) -> void:
	for key in total.keys():
		total[key] = int(total.get(key, 0)) + int(bucket.get(key, 0))

func _bucket_win_rate(bucket: Dictionary) -> float:
	return float(bucket.get("wins", 0)) / float(maxi(int(bucket.get("runs", 1)), 1))

func _bucket_avg(bucket: Dictionary, key: String) -> float:
	return float(bucket.get(key, 0)) / float(maxi(int(bucket.get("runs", 1)), 1))

func _format_case_line(class_label: String, heirloom_name: String, bucket: Dictionary) -> String:
	return "%s+%s %s" % [class_label, heirloom_name, _format_bucket(bucket)]

func _format_bucket(bucket: Dictionary) -> String:
	return "win=%d/%d %.1f%% avg_turn=%.1f combo=%.2f heirloom=%.2f dmg=%.1f taken=%.1f fail_hp=%d timeout=%d" % [
		int(bucket.get("wins", 0)),
		int(bucket.get("runs", 0)),
		_bucket_win_rate(bucket) * 100.0,
		_bucket_avg(bucket, "turns"),
		_bucket_avg(bucket, "combo_triggers"),
		_bucket_avg(bucket, "heirloom_triggers"),
		_bucket_avg(bucket, "damage_dealt"),
		_bucket_avg(bucket, "damage_taken"),
		int(bucket.get("fail_hp", 0)),
		int(bucket.get("fail_timeout", 0))
	]

func _cleanup_and_quit(code: int, combo_db: Node = null) -> void:
	selectable_combos.clear()
	if combo_db != null and is_instance_valid(combo_db):
		combo_db.all_combos.clear()
		combo_db.combat_combos.clear()
		combo_db.free()
	if combo_data_script != null and combo_data_script.has_method("clear_combo_db_cache"):
		combo_data_script.clear_combo_db_cache()
	enemy_data_script = null
	enemy_ai_script = null
	combo_data_script = null
	if game_state != null:
		game_state.free()
		game_state = null
	quit(code)
