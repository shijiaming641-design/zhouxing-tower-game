extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	if float(main.BATTLE_PHASE_RESOLVE_DELAY) < 0.35 or float(main.BATTLE_PHASE_COMBO_DELAY) < 0.30:
		push_error("Battle phase pauses should leave time for visual feedback.")
		_finish(1, main)
		return
	if float(main.BATTLE_COMBO_HIT_GAP) < 0.18 or float(main.BATTLE_COMBO_FOLLOWUP_GAP) < 0.12:
		push_error("Combo feedback gaps should keep chained hits readable.")
		_finish(1, main)
		return

	var battle := Control.new()
	battle.name = "BattleFeedbackProbe"
	root.add_child(battle)

	var impact_label := Label.new()
	impact_label.name = "BattleImpactLabel"
	impact_label.visible = false
	battle.add_child(impact_label)

	var flash := ColorRect.new()
	flash.name = "BattleFlash"
	flash.visible = false
	battle.add_child(flash)

	main._show_battle_impact(battle, "第一击\n-3", "hit", 0)
	main._show_battle_impact(battle, "第二击\n-5", "crit", 0)
	await create_timer(0.55).timeout
	if impact_label.text != "第二击\n-5" or not impact_label.visible or impact_label.modulate.a <= 0.1:
		push_error("Later battle impact should stay readable and not be hidden by an older tween.")
		_finish(1, main, battle)
		return

	await create_timer(0.90).timeout
	if impact_label.visible:
		push_error("Battle impact label should eventually hide after the readability hold.")
		_finish(1, main, battle)
		return

	print("battle_feedback_readability_smoke: ok")
	_finish(0, main, battle)

func _finish(code: int, main: Node, battle: Node = null) -> void:
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
	if main != null and is_instance_valid(main):
		main.queue_free()
	quit(code)
