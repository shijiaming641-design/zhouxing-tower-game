extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_heirloom_id": str(game_state.selected_heirloom_id),
		"field_pending_spend_attack": int(game_state.field_pending_spend_attack),
		"field_pending_blood_attack": int(game_state.field_pending_blood_attack)
	}
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

	game_state.select_heirloom("broken_coin")
	game_state.field_pending_spend_attack = 5
	if not main._get_heirloom_cashout_preview().is_empty():
		_fail("Broken coin should not preview cashout below 6/14.", main, game_state, original_state)
		return

	game_state.field_pending_spend_attack = 6
	var preview: Dictionary = main._get_heirloom_cashout_preview()
	if str(preview.get("text", "")).find("命中 +6") < 0 or str(preview.get("hint", "")).find("下一次命中") < 0:
		_fail("Broken coin should preview next-hit cashout at 6/14.", main, game_state, original_state)
		return

	var battle := Control.new()
	var card := Panel.new()
	card.name = "HeirloomCard"
	battle.add_child(card)
	var label := Label.new()
	label.name = "HeirloomLabel"
	battle.add_child(label)
	main._update_heirloom_cashout_preview(battle)
	if str(card.get_meta("cashout_state", "")) != "broken_coin_warm":
		battle.free()
		_fail("Heirloom card should enter warm cashout glow state.", main, game_state, original_state)
		return
	if label.modulate == Color(1.0, 0.86, 0.52, 1.0):
		battle.free()
		_fail("Heirloom label should tint when cashout is pending.", main, game_state, original_state)
		return
	battle.free()

	game_state.select_heirloom("blood_contract")
	game_state.field_pending_blood_attack = 5
	var blood_preview: Dictionary = main._get_heirloom_cashout_preview()
	if str(blood_preview.get("text", "")).find("命中 +5") < 0:
		_fail("Blood contract should also preview next-hit cashout.", main, game_state, original_state)
		return

	print("heirloom_cashout_preview_smoke: ok")
	_finish(0, main, game_state, original_state)

func _fail(message: String, main: Node, game_state: Node, original_state: Dictionary) -> void:
	push_error(message)
	_finish(1, main, game_state, original_state)

func _finish(code: int, main: Node, game_state: Node, original_state: Dictionary) -> void:
	if main != null:
		main.free()
	if game_state != null:
		game_state.selected_heirloom_id = str(original_state.get("selected_heirloom_id", ""))
		game_state.field_pending_spend_attack = int(original_state.get("field_pending_spend_attack", 0))
		game_state.field_pending_blood_attack = int(original_state.get("field_pending_blood_attack", 0))
	quit(code)
