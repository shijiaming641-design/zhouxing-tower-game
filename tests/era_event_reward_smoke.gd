extends SceneTree

func _finish(code: int, game_state: Node = null, original_era: String = "qin") -> void:
	if game_state != null:
		game_state.set("selected_era_id", original_era)
		game_state.set("combo_upgrades", {})
	quit(code)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var random_event_manager := root.get_node("/root/RandomEventManager")
	var original_era := str(game_state.get("selected_era_id"))

	game_state.set("combo_upgrades", {})
	game_state.set("selected_era_id", "qin")
	random_event_manager.settle_immediate_good_event({"event_id": "qin_merit_grant", "name": "军功授爵"})
	if game_state.get_combo_upgrade_level("qin_tiger_push") != 1:
		push_error("Qin event should upgrade qin_tiger_push by 1")
		_finish(1, game_state, original_era)
		return

	game_state.set("combo_upgrades", {})
	game_state.set("selected_era_id", "song")
	random_event_manager.settle_immediate_good_event({"event_id": "song_market_boom", "name": "市舶兴旺"})
	if game_state.get_combo_upgrade_level("song_trade_turn") != 1:
		push_error("Song event should upgrade song_trade_turn by 1")
		_finish(1, game_state, original_era)
		return

	game_state.set("combo_upgrades", {})
	game_state.set("selected_era_id", "china")
	random_event_manager.settle_immediate_good_event({"event_id": "china_dragon_vein", "name": "龙脉回响"})
	if game_state.get_combo_upgrade_level("china_unity_echo") != 1:
		push_error("China event should upgrade china_unity_echo by 1")
		_finish(1, game_state, original_era)
		return

	print("era_event_reward_smoke: ok")
	_finish(0, game_state, original_era)
