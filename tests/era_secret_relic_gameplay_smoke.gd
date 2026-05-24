extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_era_id": str(game_state.selected_era_id),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"player_gold": int(game_state.player_gold),
		"combo_energy": int(game_state.combo_energy),
		"player_shield": int(game_state.player_shield),
		"cheat_points": int(game_state.cheat_points),
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp)
	}

	var main = load("res://scenes/main.gd").new()
	root.add_child(main)

	game_state.selected_era_id = "qin"
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["tiger_tally"].duplicate(true))
	game_state.player_shield = 2
	main._battle_momentum_score = 1
	if int(main._get_tiger_tally_pressure_damage()) < 1:
		_fail("Tiger tally should add pressure damage after the player already holds momentum.", game_state, original_state, main)
		return
	main._battle_momentum_score = 0
	if int(main._get_tiger_tally_pressure_damage()) != 0:
		_fail("Tiger tally should not add pressure damage before the player has momentum.", game_state, original_state, main)
		return

	game_state.selected_era_id = "song"
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["trade_ledger"].duplicate(true))
	game_state.player_gold = 10
	game_state.combo_energy = 0
	main._battle_trade_ledger_triggers = 0
	var ledger_text: String = str(main._apply_trade_ledger_rotation_bonus(null))
	if ledger_text.find("市舶转手") < 0 or int(game_state.player_gold) != 12 or int(game_state.combo_energy) != 1:
		_fail("Trade ledger should convert successful rotation into gold and battle energy, text=%s gold=%d energy=%d" % [ledger_text, game_state.player_gold, game_state.combo_energy], game_state, original_state, main)
		return

	game_state.selected_era_id = "china"
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["unity_seal"].duplicate(true))
	game_state.player_shield = 0
	main._battle_momentum_score = 0
	var unity_text: String = str(main._apply_unity_seal_cheat_momentum(null, "draw"))
	if unity_text.find("山河印定势") < 0 or int(game_state.player_shield) < 1:
		_fail("Unity seal should turn cheat loop into momentum and guard value, text=%s shield=%d" % [unity_text, game_state.player_shield], game_state, original_state, main)
		return

	var tiger_desc := str(game_state.ITEMS["tiger_tally"].get("description", ""))
	var ledger_desc := str(game_state.ITEMS["trade_ledger"].get("description", ""))
	var unity_desc := str(game_state.ITEMS["unity_seal"].get("description", ""))
	if tiger_desc.find("占势") < 0 or ledger_desc.find("换势") < 0 or unity_desc.find("势轨") < 0:
		_fail("Era secret relic descriptions should explain their gameplay role.", game_state, original_state, main)
		return

	print("era_secret_relic_gameplay_smoke: ok")
	_finish(0, game_state, original_state, main)

func _fail(message: String, game_state: Node, original_state: Dictionary, main: Node) -> void:
	push_error(message)
	_finish(1, game_state, original_state, main)

func _finish(code: int, game_state: Node, original_state: Dictionary, main: Node) -> void:
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.combo_energy = int(original_state.get("combo_energy", 0))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.cheat_points = int(original_state.get("cheat_points", 0))
	game_state.player_hp = int(original_state.get("player_hp", 1))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 1))
	if main != null and is_instance_valid(main):
		main._dispose_combo_database_cache()
		main.free()
	quit(code)
