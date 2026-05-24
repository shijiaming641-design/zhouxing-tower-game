extends SceneTree

func _finish(code: int, combo_db: Node = null, game_state: Node = null, original_era: String = "qin") -> void:
	if game_state != null:
		game_state.set("selected_era_id", original_era)
	if combo_db != null:
		combo_db.free()
	quit(code)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_era := str(game_state.get("selected_era_id"))
	var combo_db = load("res://resources/combo_database.gd").new()

	game_state.set("selected_era_id", "qin")
	combo_db._init_database()
	var qin_combo = combo_db.get_combo_by_id("qin_tiger_push")
	var song_combo = combo_db.get_combo_by_id("song_trade_turn")
	var china_combo = combo_db.get_combo_by_id("china_unity_echo")
	if qin_combo == null or not qin_combo.is_unlocked:
		push_error("Qin era combo should be unlocked in 秦卷")
		_finish(1, combo_db, game_state, original_era)
		return
	if song_combo == null or song_combo.is_unlocked:
		push_error("Song era combo should stay hidden outside 宋卷")
		_finish(1, combo_db, game_state, original_era)
		return
	if china_combo == null or china_combo.is_unlocked:
		push_error("China era combo should stay hidden outside 中国卷")
		_finish(1, combo_db, game_state, original_era)
		return

	game_state.set("selected_era_id", "song")
	combo_db._init_database()
	song_combo = combo_db.get_combo_by_id("song_trade_turn")
	if song_combo == null or not song_combo.is_unlocked:
		push_error("Song era combo should be unlocked in 宋卷")
		_finish(1, combo_db, game_state, original_era)
		return

	game_state.set("selected_era_id", "china")
	combo_db._init_database()
	china_combo = combo_db.get_combo_by_id("china_unity_echo")
	if china_combo == null or not china_combo.is_unlocked:
		push_error("China era combo should be unlocked in 中国卷")
		_finish(1, combo_db, game_state, original_era)
		return

	print("era_combo_smoke: ok")
	_finish(0, combo_db, game_state, original_era)
