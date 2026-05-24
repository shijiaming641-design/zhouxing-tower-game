extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"player_hp": int(game_state.player_hp),
		"player_max_hp": int(game_state.player_max_hp),
		"player_shield": int(game_state.player_shield),
		"player_gold": int(game_state.player_gold),
		"player_class": int(game_state.player_class),
		"selected_era_id": str(game_state.selected_era_id),
		"materials": int(game_state.materials)
	}

	game_state.selected_era_id = "qin"
	game_state.player_class = 0
	game_state.player_max_hp = 10
	game_state.player_hp = 4
	game_state.player_shield = 3
	game_state.player_gold = 12

	var rest = load("res://scenes/ui/rest_point.tscn").instantiate()
	root.add_child(rest)
	await process_frame

	rest._on_heal_selected()
	await process_frame

	var heal_panel: Node = rest.get_node_or_null("HealPanel")
	if heal_panel == null:
		push_error("Heal choice should open the heal panel.")
		_finish(1, rest, game_state, original_state)
		return
	var heal_control := heal_panel as Control
	if heal_control == null or heal_control.position != Vector2(370, 92) or heal_control.custom_minimum_size.x < 540 or heal_control.custom_minimum_size.y < 540:
		push_error("Heal panel should be centered and enlarged for rest UI readability.")
		_finish(1, rest, game_state, original_state)
		return

	var preview := heal_panel.find_child("RestHealPreviewLabel", true, false) as Label
	var full_btn := heal_panel.find_child("FullHealButton", true, false) as Button
	var half_btn := heal_panel.find_child("HalfHealButton", true, false) as Button
	if preview == null or full_btn == null or half_btn == null:
		push_error("Heal panel should expose preview and named heal buttons.")
		_finish(1, rest, game_state, original_state)
		return
	var hp_label := heal_panel.find_child("HPLabel", true, false) as Label
	if hp_label == null or hp_label.text.find("命数：4 / 10") < 0 or hp_label.text.find("❤️") >= 0 or hp_label.text.find("🖤") >= 0:
		push_error("Heal panel HP label should use centered numeric HP instead of the old heart bar.")
		_finish(1, rest, game_state, original_state)
		return
	if preview.text.find("当前命数 4/10") < 0 or preview.text.find("缺6命") < 0 or full_btn.text.find("4/10 → 10/10") < 0 or half_btn.text.find("4/10 → 9/10") < 0:
		push_error("Heal panel should preview exact numeric HP before and after resting.")
		_finish(1, rest, game_state, original_state)
		return

	rest._on_half_heal()
	await process_frame

	var feedback := heal_panel.find_child("RestHealFeedbackLabel", true, false) as Label
	if feedback == null or feedback.text.find("4/10 → 9/10") < 0 or feedback.text.find("恢复 +5") < 0:
		push_error("Half rest should show exact HP delta feedback.")
		_finish(1, rest, game_state, original_state)
		return
	if hp_label == null or hp_label.text.find("命数：9 / 10") < 0:
		push_error("Heal panel HP label should refresh after resting.")
		_finish(1, rest, game_state, original_state)
		return

	game_state.player_hp = game_state.player_max_hp
	rest._update_heal_panel_status()
	if preview.text.find("命数已满") < 0 or full_btn.text.find("命满") < 0:
		push_error("Heal panel should warn when HP is already full.")
		_finish(1, rest, game_state, original_state)
		return

	print("rest_heal_feedback_smoke: ok")
	_finish(0, rest, game_state, original_state)

func _finish(code: int, rest: Node, game_state: Node, original_state: Dictionary) -> void:
	if rest != null:
		rest.queue_free()
	game_state.player_hp = int(original_state.get("player_hp", 1))
	game_state.player_max_hp = int(original_state.get("player_max_hp", 10))
	game_state.player_shield = int(original_state.get("player_shield", 0))
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.player_class = int(original_state.get("player_class", 0))
	game_state.selected_era_id = str(original_state.get("selected_era_id", "qin"))
	game_state.materials = int(original_state.get("materials", 0))
	quit(code)
