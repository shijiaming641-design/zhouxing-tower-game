extends SceneTree

const EnemyAI = preload("res://scripts/enemy_ai.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_buffs: Dictionary = game_state.combo_buffs.duplicate(true)
	var original_cheat_points := int(game_state.cheat_points)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

	var fixed_ai := EnemyAI.new()
	fixed_ai.setup_basic_fixed(1)
	if str(main._get_cheat_read_preview(fixed_ai)).find(MoveSymbols.move_name(1)) < 0:
		_fail("Cheat preview should expose fixed enemy hand.", main, fixed_ai, null, game_state, original_buffs, original_cheat_points)
		return

	var cycle_ai := EnemyAI.new()
	cycle_ai.setup_elite_cycle([0, 2])
	cycle_ai.cycle_index = 1
	var preview := str(main._get_cheat_read_preview(cycle_ai))
	if preview.find(MoveSymbols.move_name(2)) < 0:
		_fail("Cheat preview should expose current cycle hand.", main, fixed_ai, cycle_ai, game_state, original_buffs, original_cheat_points)
		return
	if int(cycle_ai.cycle_index) != 1:
		_fail("Cheat preview must not advance enemy cycle state.", main, fixed_ai, cycle_ai, game_state, original_buffs, original_cheat_points)
		return

	game_state.combo_buffs.clear()
	var bonus_text := str(main._apply_cheat_counterread_bonus())
	if bonus_text.find("反抓+1攻") < 0 or int(game_state.get_combo_buff("attack")) != 1:
		_fail("Counter-read should grant one-turn attack when no stronger attack buff exists.", main, fixed_ai, cycle_ai, game_state, original_buffs, original_cheat_points)
		return

	game_state.combo_buffs.clear()
	game_state.apply_combo_buff("attack", 2, 2)
	var keep_text := str(main._apply_cheat_counterread_bonus())
	if keep_text.find("续势") < 0 or int(game_state.get_combo_buff("attack")) != 2:
		_fail("Counter-read should not overwrite an existing stronger attack buff.", main, fixed_ai, cycle_ai, game_state, original_buffs, original_cheat_points)
		return

	var battle := Control.new()
	battle.name = "CheatUiProbe"
	root.add_child(battle)
	game_state.cheat_points = 1
	main._use_cheat(battle, fixed_ai)
	await process_frame
	var cheat_panel := battle.get_node_or_null("CheatPanel") as Panel
	var win_btn := battle.get_node_or_null("CheatPanel/CheatWinButton") as Button
	var draw_btn := battle.get_node_or_null("CheatPanel/CheatDrawButton") as Button
	if cheat_panel == null or win_btn == null or draw_btn == null:
		_fail("Cheat UI should expose named panel and action buttons.", main, fixed_ai, cycle_ai, game_state, original_buffs, original_cheat_points, battle)
		return
	if cheat_panel.position.distance_to(main.BATTLE_CHEAT_PANEL_POS) > 1.0 or cheat_panel.size.distance_to(main.BATTLE_CHEAT_PANEL_SIZE) > 1.0:
		_fail("Cheat panel should use the shared panel size, pos=%s size=%s" % [str(cheat_panel.position), str(cheat_panel.size)], main, fixed_ai, cycle_ai, game_state, original_buffs, original_cheat_points, battle)
		return
	if win_btn.size.distance_to(main.BATTLE_CHEAT_ACTION_BUTTON_SIZE) > 1.0 or draw_btn.size.distance_to(main.BATTLE_CHEAT_ACTION_BUTTON_SIZE) > 1.0:
		_fail("Cheat action buttons should share one size, win=%s draw=%s" % [str(win_btn.size), str(draw_btn.size)], main, fixed_ai, cycle_ai, game_state, original_buffs, original_cheat_points, battle)
		return
	if absf(win_btn.position.y - draw_btn.position.y) > 1.0 or draw_btn.position.x <= win_btn.position.x:
		_fail("Cheat action buttons should sit on one row with stable ordering, win=%s draw=%s" % [str(win_btn.position), str(draw_btn.position)], main, fixed_ai, cycle_ai, game_state, original_buffs, original_cheat_points, battle)
		return

	print("cheat_counterread_smoke: ok")
	_finish(0, main, fixed_ai, cycle_ai, game_state, original_buffs, original_cheat_points, battle)

func _fail(message: String, main: Node, fixed_ai: Node, cycle_ai: Node, game_state: Node, original_buffs: Dictionary, original_cheat_points: int = -1, battle: Node = null) -> void:
	push_error(message)
	_finish(1, main, fixed_ai, cycle_ai, game_state, original_buffs, original_cheat_points, battle)

func _finish(code: int, main: Node, fixed_ai: Node, cycle_ai: Node, game_state: Node, original_buffs: Dictionary, original_cheat_points: int = -1, battle: Node = null) -> void:
	if battle != null:
		battle.free()
	if fixed_ai != null:
		fixed_ai.free()
	if cycle_ai != null:
		cycle_ai.free()
	if main != null:
		main.free()
	if game_state != null:
		game_state.combo_buffs = original_buffs.duplicate(true)
		if original_cheat_points >= 0:
			game_state.cheat_points = original_cheat_points
	quit(code)
