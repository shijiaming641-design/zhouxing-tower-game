extends SceneTree

const EnemyAI = preload("res://scripts/enemy_ai.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_era := str(game_state.selected_era_id)
	var original_last_type := int(game_state.last_enemy_ai_type)
	var original_last_subtype := int(game_state.last_enemy_ai_subtype)
	game_state.selected_era_id = "qin"
	game_state.register_enemy_personality(-1, -1)
	var enemy_data_script: GDScript = load("res://resources/enemy_data.gd")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

	for floor_num in range(3):
		var data = enemy_data_script.generate_by_floor(floor_num)
		if int(data.ai_type) != 0 or int(data.ai_subtype) != floor_num % 3:
			push_error("First three floors should teach fixed readable moves, floor=%d ai=%d/%d" % [floor_num, int(data.ai_type), int(data.ai_subtype)])
			_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
			return

	var expected_early_elites := [0, 1, 2]
	var expected_name_fragments := ["换阵", "方阵", "反锋"]
	for offset in range(expected_early_elites.size()):
		var floor_num := offset + 3
		var data = enemy_data_script.generate_by_floor(floor_num)
		if int(data.ai_type) != 1 or int(data.ai_subtype) != int(expected_early_elites[offset]):
			push_error("Floors 4-6 should introduce light readable elite rhythms, floor=%d ai=%d/%d" % [floor_num, int(data.ai_type), int(data.ai_subtype)])
			_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
			return
		if str(data.display_name).find(str(expected_name_fragments[offset])) < 0:
			push_error("Early elite name should match readable behavior, floor=%d name=%s" % [floor_num, str(data.display_name)])
			_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
			return

	var mid_allowed := [0, 1, 2, 3, 4]
	var mid_name_fragments := {
		0: "换阵",
		1: "方阵",
		2: "反锋",
		3: "双变",
		4: "军议"
	}
	for offset in range(6):
		var floor_num := offset + 6
		var data = enemy_data_script.generate_by_floor(floor_num)
		if int(data.ai_type) != 1 or not (int(data.ai_subtype) in mid_allowed):
			push_error("Mid floors should randomize inside memorable elite pools, floor=%d ai=%d/%d" % [floor_num, int(data.ai_type), int(data.ai_subtype)])
			_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
			return
		if str(data.display_name).find(str(mid_name_fragments.get(int(data.ai_subtype), ""))) < 0:
			push_error("Mid elite name should match randomized behavior, floor=%d subtype=%d name=%s" % [floor_num, int(data.ai_subtype), str(data.display_name)])
			_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
			return

	game_state.register_enemy_personality(1, 2)
	var anti_repeat_data = enemy_data_script.generate_by_floor(8)
	if int(anti_repeat_data.ai_subtype) == 2:
		push_error("Mid enemy randomizer should avoid repeating the previous elite personality when alternatives exist.")
		_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
		return

	var late_allowed := [0, 1, 2, 3, 4]
	var late_name_fragments := {
		0: "窥势",
		1: "攻守",
		2: "仿势",
		3: "军谋",
		4: "诱势"
	}
	for offset in range(6):
		var floor_num := offset + 12
		var data = enemy_data_script.generate_by_floor(floor_num)
		if int(data.ai_type) != 2 or not (int(data.ai_subtype) in late_allowed):
			push_error("Late floors should randomize inside advanced personality pools, floor=%d ai=%d/%d" % [floor_num, int(data.ai_type), int(data.ai_subtype)])
			_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
			return
		if str(data.display_name).find(str(late_name_fragments.get(int(data.ai_subtype), ""))) < 0:
			push_error("Late advanced name should match its behavior, floor=%d name=%s" % [floor_num, str(data.display_name)])
			_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
			return

	game_state.register_enemy_personality(-1, -1)
	var near_node := {"route_name": "近攻线", "enemy_hp_delta": 0, "enemy_attack_delta": 0}
	var route_data = enemy_data_script.generate_for_history_node(9, near_node)
	if int(route_data.ai_type) != 1 or not (int(route_data.ai_subtype) in [0, 2, 3]):
		push_error("Historical route should bias enemy personality inside its route pool, got=%d/%d" % [int(route_data.ai_type), int(route_data.ai_subtype)])
		_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
		return
	if str(route_data.display_name).find(str(mid_name_fragments.get(int(route_data.ai_subtype), ""))) < 0:
		push_error("Historical route enemy name should refresh after route bias, name=%s subtype=%d" % [str(route_data.display_name), int(route_data.ai_subtype)])
		_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
		return

	game_state.register_enemy_personality(2, 4)
	var advanced_anti_repeat = enemy_data_script.generate_by_floor(13)
	if int(advanced_anti_repeat.ai_subtype) == 4:
		push_error("Late enemy randomizer should avoid repeating the previous advanced personality when alternatives exist.")
		_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
		return

	main._battle_read_streak = 0
	var win_read := {"player_wins": true, "is_draw": false}
	if int(main._update_read_streak(win_read, "你读中了这一手")) != 1:
		push_error("Read streak should start after a clean read.")
		_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
		return
	if int(main._update_read_streak(win_read, "你抓住了敌人的旧手，顺势把它压穿了")) != 2:
		push_error("Read streak should rise on consecutive reads.")
		_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
		return
	if int(main._update_read_streak({"player_wins": false, "is_draw": false}, "主动权被对面拿走了")) != 0:
		push_error("Read streak should reset after losing the exchange.")
		_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
		return
	var fixed_ai := EnemyAI.new()
	fixed_ai.setup_basic_fixed(1)
	if str(main._get_enemy_intent_hint(fixed_ai)).find("守着") < 0:
		push_error("Basic enemy intent should expose its readable fixed hand.")
		fixed_ai.free()
		_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
		return
	fixed_ai.free()
	var cycle_ai := EnemyAI.new()
	cycle_ai.setup_elite_by_subtype(1)
	if str(main._get_enemy_intent_hint(cycle_ai)).find("重复") < 0:
		push_error("Elite guardian intent should match its repeated-hand behavior.")
		cycle_ai.free()
		_finish(1, main, game_state, original_era, original_last_type, original_last_subtype)
		return
	cycle_ai.free()

	print("early_enemy_readability_smoke: ok")
	_finish(0, main, game_state, original_era, original_last_type, original_last_subtype)

func _finish(code: int, main: Node, game_state: Node = null, original_era: String = "qin", original_last_type: int = -1, original_last_subtype: int = -1) -> void:
	if main != null:
		main.free()
	if game_state != null:
		game_state.selected_era_id = original_era
		game_state.register_enemy_personality(original_last_type, original_last_subtype)
	quit(code)
