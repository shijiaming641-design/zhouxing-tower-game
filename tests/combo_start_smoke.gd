extends SceneTree

func _initialize() -> void:
	var combo_db = load("res://resources/combo_database.gd").new()
	combo_db._init_database()

	var selectable = combo_db.get_start_selectable_combos()
	for combo in selectable:
		if combo.sequence.size() != 3:
			push_error("Found non-3-step combo in start selection: %s" % combo.id)
			quit(1)
			return

	var allowed_combo_ids: Array[String] = ["penetrating_strike"]
	var last_3: Array[int] = [1, 1, 2]
	var matched_id := ""

	for combo in combo_db.get_all_combos():
		if not combo.is_unlocked:
			continue
		if combo.sequence.size() != 3:
			continue
		if not combo.id in allowed_combo_ids:
			continue
		var match_found = true
		for i in range(3):
			if last_3[i] != combo.sequence[i]:
				match_found = false
				break
		if match_found:
			matched_id = combo.id
			break

	if matched_id != "penetrating_strike":
		push_error("Expected penetrating_strike to match, got: %s" % matched_id)
		quit(1)
		return

	print("combo_start_smoke: ok")
	quit()
