extends SceneTree

const CLASS_NAMES: Array[String] = ["医生", "黑客", "商人", "农民", "流浪者"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := _capture_state(game_state)

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

	var combo_db = main._get_combo_database()
	if combo_db == null:
		_fail("Combo database should load.", game_state, original_state, main)
		return
	var selectable: Array = combo_db.get_start_selectable_combos()
	if selectable.size() < 2:
		_fail("Need at least two selectable layouts for random pair coverage.", game_state, original_state, main)
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260518
	var cases_checked := 0
	var representative_triggered_pair: Array[Dictionary] = []
	for class_id in range(CLASS_NAMES.size()):
		for heirloom_id in game_state.get_heirloom_ids():
			game_state.selected_era_id = "qin"
			game_state.init_player_class(class_id)
			if not game_state.select_heirloom(str(heirloom_id)):
				_fail("Heirloom should be selectable: %s" % heirloom_id, game_state, original_state, main)
				return
			game_state.equipped_combos.clear()
			game_state.combo_cooldowns.clear()
			var pair := _pick_random_combo_pair(selectable, rng)
			for combo in pair:
				game_state.equipped_combos.append(str(combo.id))

			var allowed_ids: Array[String] = []
			for combo in pair:
				allowed_ids.append(str(combo.id))
			for combo in pair:
				var history: Array[int] = []
				for move in combo.sequence:
					history.append(int(move))
				var triggered: Array[Dictionary] = main._gather_triggered_combos(history, allowed_ids, combo_db)
				if not _has_triggered_combo(triggered, str(combo.id), main):
					_fail(
						"%s + %s random layout should trigger: %s" % [
							CLASS_NAMES[class_id],
							str(game_state.get_heirloom_data(str(heirloom_id)).get("name", heirloom_id)),
							str(combo.id)
						],
						game_state,
						original_state,
						main
					)
					return

			var triggered_pair: Array[Dictionary] = []
			for combo in pair:
				triggered_pair.append({"combo": combo, "is_equipment": false})
			if str(main._get_combo_impact_text(triggered_pair)).find("布局") < 0:
				_fail("Random layout pair should produce completion text.", game_state, original_state, main)
				return
			if representative_triggered_pair.is_empty():
				representative_triggered_pair = triggered_pair
			cases_checked += 1

	if cases_checked != CLASS_NAMES.size() * game_state.get_heirloom_ids().size():
		_fail("Unexpected case count: %d" % cases_checked, game_state, original_state, main)
		return

	representative_triggered_pair.clear()
	selectable.clear()
	if combo_db != null and is_instance_valid(combo_db):
		combo_db.all_combos.clear()
		combo_db.combat_combos.clear()
		combo_db.free()
	main._combo_database_cache = null
	combo_db = null
	var combo_data_script = load("res://resources/combo_data.gd")
	if combo_data_script != null and combo_data_script.has_method("clear_combo_db_cache"):
		combo_data_script.clear_combo_db_cache()

	print("class_heirloom_random_combo_smoke: ok cases=%d" % cases_checked)
	_restore_and_quit(0, game_state, original_state, main)

func _pick_random_combo_pair(selectable: Array, rng: RandomNumberGenerator) -> Array:
	var first_idx := rng.randi_range(0, selectable.size() - 1)
	var second_idx := rng.randi_range(0, selectable.size() - 1)
	while second_idx == first_idx:
		second_idx = rng.randi_range(0, selectable.size() - 1)
	return [selectable[first_idx], selectable[second_idx]]

func _has_triggered_combo(triggered: Array[Dictionary], combo_id: String, main: Node) -> bool:
	for entry in triggered:
		var combo = entry.get("combo")
		if combo != null and main._get_combo_id(combo) == combo_id:
			return true
	return false

func _capture_state(game_state: Node) -> Dictionary:
	return {
		"selected_era_id": str(game_state.selected_era_id),
		"player_class": int(game_state.player_class),
		"selected_heirloom_id": str(game_state.selected_heirloom_id),
		"field_pending_spend_attack": int(game_state.field_pending_spend_attack),
		"field_pending_blood_attack": int(game_state.field_pending_blood_attack),
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_attack": int(game_state.player_attack),
		"player_shield": int(game_state.player_shield),
		"equipped_combos": game_state.equipped_combos.duplicate(true),
		"combo_cooldowns": game_state.combo_cooldowns.duplicate(true),
	}

func _fail(message: String, game_state: Node, original_state: Dictionary, main: Node, battle: Node = null) -> void:
	push_error(message)
	_restore_and_quit(1, game_state, original_state, main, battle)

func _restore_and_quit(code: int, game_state: Node, original_state: Dictionary, main: Node, battle: Node = null) -> void:
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
	if main != null and is_instance_valid(main):
		if main.has_method("_dispose_combo_database_cache"):
			main._dispose_combo_database_cache()
		main.free()
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.selected_heirloom_id = str(original_state.get("selected_heirloom_id", ""))
	game_state.field_pending_spend_attack = int(original_state.get("field_pending_spend_attack", 0))
	game_state.field_pending_blood_attack = int(original_state.get("field_pending_blood_attack", 0))
	game_state.player_hp = int(original_state.get("player_hp", 6))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 6))
	game_state.player_attack = int(original_state.get("player_attack", 2))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.equipped_combos = (original_state.get("equipped_combos", []) as Array).duplicate(true)
	game_state.combo_cooldowns = (original_state.get("combo_cooldowns", {}) as Dictionary).duplicate(true)
	call_deferred("quit", code)
