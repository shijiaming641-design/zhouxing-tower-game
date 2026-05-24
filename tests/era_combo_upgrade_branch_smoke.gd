extends SceneTree

func _finish(code: int, game_state: Node = null) -> void:
	if game_state != null:
		game_state.free()
	quit(code)

func _initialize() -> void:
	var game_state = load("res://autoload/game_state.gd").new()
	game_state.player_gold = 1000
	game_state.materials = 60

	for combo_id in ["qin_tiger_push", "song_trade_turn", "china_unity_echo"]:
		for _i in range(5):
			var result = game_state.apply_combo_upgrade(combo_id, "upgrade")
			if not result.get("success", false):
				push_error("Expected combo upgrade to succeed for %s" % combo_id)
				_finish(1, game_state)
				return

	if not game_state.has_combo_effect("qin_tiger_push", "qin_guardbreak"):
		push_error("Qin unique branch lv4 should unlock guardbreak")
		_finish(1, game_state)
		return
	if not game_state.has_combo_effect("qin_tiger_push", "qin_battle_armor"):
		push_error("Qin unique branch lv5 should unlock battle armor")
		_finish(1, game_state)
		return
	if not game_state.has_combo_effect("song_trade_turn", "song_material_rebate"):
		push_error("Song unique branch lv4 should unlock material rebate")
		_finish(1, game_state)
		return
	if not game_state.has_combo_effect("song_trade_turn", "song_gold_bonus"):
		push_error("Song unique branch lv5 should unlock extra gold")
		_finish(1, game_state)
		return
	if not game_state.has_combo_effect("china_unity_echo", "china_cheat_restore"):
		push_error("China unique branch lv4 should unlock cheat restore")
		_finish(1, game_state)
		return
	if not game_state.has_combo_effect("china_unity_echo", "china_attack_rally"):
		push_error("China unique branch lv5 should unlock attack rally")
		_finish(1, game_state)
		return

	print("era_combo_upgrade_branch_smoke: ok")
	_finish(0, game_state)
