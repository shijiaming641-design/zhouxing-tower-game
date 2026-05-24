extends SceneTree

func _finish(code: int, game_state: Node, original_state: Dictionary) -> void:
	for key in original_state.keys():
		game_state.set(key, original_state[key])
	quit(code)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"selected_heirloom_id": str(game_state.selected_heirloom_id),
		"field_pending_spend_attack": int(game_state.field_pending_spend_attack),
		"field_pending_blood_attack": int(game_state.field_pending_blood_attack),
		"field_pending_merchant_attack": int(game_state.field_pending_merchant_attack),
		"player_class": int(game_state.player_class),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"backpack": game_state.backpack.duplicate(true)
	}
	game_state.player_class = 0
	game_state.equipment_slot.clear()
	game_state.backpack.clear()

	for item_id in ["shield_blade", "afterlife_lamp", "broken_coin", "camp_banner", "blood_contract", "counter_sigil"]:
		if not game_state.HEIRLOOMS.has(item_id):
			push_error("Missing heirloom: %s" % item_id)
			_finish(1, game_state, original_state)
			return

	game_state.select_heirloom("broken_coin")
	game_state.field_pending_spend_attack = 0
	game_state.register_gold_spent_for_field(10)
	if game_state.get_heirloom_status_text() != "蓄势 2/14":
		push_error("破财印 status should expose pending attack, got %s" % game_state.get_heirloom_status_text())
		_finish(1, game_state, original_state)
		return
	if game_state.get_heirloom_detail_text().find("当前：蓄势 2/14") < 0:
		push_error("破财印 detail should include current status.")
		_finish(1, game_state, original_state)
		return
	var bonus: Dictionary = game_state.consume_field_attack_bonus()
	if int(bonus.get("spend", 0)) != 2 or int(bonus.get("total", 0)) != 2:
		push_error("破财印 should convert spent gold into pending attack, got %s" % str(bonus))
		_finish(1, game_state, original_state)
		return

	game_state.select_heirloom("blood_contract")
	game_state.field_pending_blood_attack = 0
	game_state.grant_blood_contract_bonus(3)
	if game_state.get_heirloom_status_text() != "血势 3/10":
		push_error("血契符 status should expose pending attack, got %s" % game_state.get_heirloom_status_text())
		_finish(1, game_state, original_state)
		return
	bonus = game_state.consume_field_attack_bonus()
	if int(bonus.get("blood", 0)) != 3 or int(bonus.get("total", 0)) != 3:
		push_error("血契符 should store lost HP as pending attack, got %s" % str(bonus))
		_finish(1, game_state, original_state)
		return

	print("field_status_cards_smoke: ok")
	_finish(0, game_state, original_state)
