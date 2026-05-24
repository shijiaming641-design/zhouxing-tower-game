extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var q := InputEventKey.new()
	q.physical_keycode = KEY_Q
	q.pressed = true
	if int(main._get_battle_move_index_from_key(q)) != 0:
		push_error("Q should submit the first battle move immediately.")
		_finish(1, main)
		return

	var battle := Control.new()
	battle.name = "BattleInputResponsivenessProbe"
	root.add_child(battle)
	for i in range(3):
		var card := Panel.new()
		card.name = "BattleMoveCard%d" % i
		battle.add_child(card)
		var title := Label.new()
		title.name = "BattleMoveTitle%d" % i
		battle.add_child(title)
		var subtitle := Label.new()
		subtitle.name = "BattleMoveSubtitle%d" % i
		subtitle.text = "原势%d" % i
		battle.add_child(subtitle)
		var key := Label.new()
		key.name = "BattleMoveKey%d" % i
		battle.add_child(key)
		var btn := Button.new()
		btn.name = "BattleMoveButton%d" % i
		btn.set_meta("battle_move_button", true)
		btn.set_meta("move_idx", i)
		btn.set_meta("base_subtitle", subtitle.text)
		battle.add_child(btn)

	battle.set_meta("battle_input_move_idx", 1)
	main._set_battle_turn_lock(battle, true)
	var selected_btn := battle.get_node("BattleMoveButton1") as Button
	var selected_subtitle := battle.get_node("BattleMoveSubtitle1") as Label
	var selected_card := battle.get_node("BattleMoveCard1") as Panel
	var other_subtitle := battle.get_node("BattleMoveSubtitle0") as Label
	if not selected_btn.disabled:
		push_error("Submitted move should lock input immediately.")
		_finish(1, main, battle)
		return
	if selected_subtitle.text != "已出手":
		push_error("Selected move should keep an immediate accepted-input label.")
		_finish(1, main, battle)
		return
	if selected_card.scale.x <= 1.0:
		push_error("Selected move should stay visually hot while the turn resolves.")
		_finish(1, main, battle)
		return
	if other_subtitle.text != "原势0":
		push_error("Unselected move should not pretend it was submitted.")
		_finish(1, main, battle)
		return

	main._set_battle_turn_lock(battle, false)
	if selected_subtitle.text != "原势1" or selected_btn.disabled:
		push_error("Move buttons should return to ready state after resolution.")
		_finish(1, main, battle)
		return

	print("battle_input_responsiveness_smoke: ok")
	_finish(0, main, battle)

func _finish(code: int, main: Node, battle: Node = null) -> void:
	if battle != null and is_instance_valid(battle):
		battle.free()
	if main != null and is_instance_valid(main):
		if main.has_method("_dispose_combo_database_cache"):
			main._dispose_combo_database_cache()
		main.free()
	var combo_data_script = load("res://resources/combo_data.gd")
	if combo_data_script != null and combo_data_script.has_method("clear_combo_db_cache"):
		combo_data_script.clear_combo_db_cache()
	quit(code)
