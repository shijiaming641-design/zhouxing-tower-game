extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_upgrades: Dictionary = game_state.combo_upgrades.duplicate(true)
	game_state.combo_upgrades.clear()
	game_state.combo_upgrades["penetrating_strike"] = {"level": 3, "has_burn": false, "has_slow": false}

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var combo_db = main._get_combo_database()
	var combo = combo_db.get_combo_by_id("penetrating_strike")
	var guard_combo = combo_db.get_combo_by_id("solid_defense")
	var control_combo = combo_db.get_combo_by_id("tactical_interference")
	if combo == null or guard_combo == null or control_combo == null:
		push_error("Expected combo feedback probe combos are missing.")
		_finish(1, game_state, original_upgrades, main)
		return

	var battle := Control.new()
	battle.name = "ComboCompletionFeedbackProbe"
	root.add_child(battle)
	var impact_label := Label.new()
	impact_label.name = "BattleImpactLabel"
	impact_label.visible = false
	battle.add_child(impact_label)
	var flash := ColorRect.new()
	flash.name = "BattleFlash"
	flash.visible = false
	battle.add_child(flash)
	var progress_panel := Panel.new()
	progress_panel.name = "ComboResourcePanel"
	battle.add_child(progress_panel)
	var progress := Label.new()
	progress.name = "ComboProgress"
	battle.add_child(progress)

	var triggered: Array[Dictionary] = [{"combo": combo, "is_equipment": false}]
	var guard_triggered: Array[Dictionary] = [{"combo": guard_combo, "is_equipment": false}]
	var control_triggered: Array[Dictionary] = [{"combo": control_combo, "is_equipment": false}]
	if main._get_combo_completion_impact_type(triggered) != "combo_damage":
		push_error("Damage combo should use damage-colored completion feedback.")
		_finish(1, game_state, original_upgrades, main, battle)
		return
	if main._get_combo_completion_impact_type(guard_triggered) != "combo_guard":
		push_error("Guard combo should use guard-colored completion feedback.")
		_finish(1, game_state, original_upgrades, main, battle)
		return
	if main._get_combo_completion_impact_type(control_triggered) != "combo_control":
		push_error("Control combo should use control-colored completion feedback.")
		_finish(1, game_state, original_upgrades, main, battle)
		return
	main._show_combo_completion_feedback(battle, triggered)
	await process_frame

	if impact_label.visible and impact_label.text.strip_edges() != "":
		push_error("Combo completion should no longer use center-screen text. got=%s" % impact_label.text)
		_finish(1, game_state, original_upgrades, main, battle)
		return
	if not progress.text.contains("兑现") or not progress.text.contains("Lv.3"):
		push_error("Upgraded combo completion should be folded into the bottom combo strip. got=%s" % progress.text)
		_finish(1, game_state, original_upgrades, main, battle)
		return
	if battle.get_node_or_null("ComboCompletionBadge") != null:
		push_error("Combo completion should not create a second badge layer after fusing into the bottom strip.")
		_finish(1, game_state, original_upgrades, main, battle)
		return
	if _count_named_children(battle, "ComboCompletionRing") < 3:
		push_error("Upgraded combo completion should create extra rings.")
		_finish(1, game_state, original_upgrades, main, battle)
		return

	print("combo_completion_feedback_smoke: ok")
	_finish(0, game_state, original_upgrades, main, battle)

func _count_named_children(node: Node, child_name: String) -> int:
	var count := 0
	for child in node.get_children():
		if str(child.name).contains(child_name):
			count += 1
		count += _count_named_children(child, child_name)
	return count

func _finish(code: int, game_state: Node, original_upgrades: Dictionary, main: Node, battle: Node = null) -> void:
	game_state.combo_upgrades = original_upgrades.duplicate(true)
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
	if main != null and is_instance_valid(main):
		if main.has_method("_dispose_combo_database_cache"):
			main._dispose_combo_database_cache()
		main.queue_free()
	quit(code)
