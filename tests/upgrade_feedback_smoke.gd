extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_state := {
		"player_gold": int(game_state.player_gold),
		"materials": int(game_state.materials),
		"equipment_slot": game_state.equipment_slot.duplicate(true),
		"backpack": game_state.backpack.duplicate(true),
		"combo_upgrades": game_state.combo_upgrades.duplicate(true),
		"equipment_upgrades": game_state.equipment_upgrades.duplicate(true)
	}

	game_state.player_gold = 200
	game_state.materials = 40
	game_state.equipment_slot.clear()
	game_state.backpack.clear()
	game_state.combo_upgrades.clear()
	game_state.equipment_upgrades.clear()
	game_state.equipment_slot.append(game_state.ITEMS["long_sword"].duplicate(true))

	var rest = load("res://scenes/ui/rest_point.tscn").instantiate()
	root.add_child(rest)

	rest._on_combo_upgrade("energy_charge")
	var combo_overlay: Node = rest.get_node_or_null("UpgradeEffectOverlay")
	if combo_overlay == null:
		push_error("Combo upgrade should spawn upgrade effect overlay")
		_finish(1, rest, game_state, original_state)
		return
	var combo_title := combo_overlay.get_node_or_null("UpgradeEffectTitle") as Label
	var combo_target := combo_overlay.get_node_or_null("UpgradeEffectTarget") as Label
	if combo_title == null or combo_title.text.find("布局强化") < 0:
		push_error("Combo upgrade effect should show upgrade title")
		_finish(1, rest, game_state, original_state)
		return
	if combo_target == null or combo_target.text.find("蓄势") < 0:
		push_error("Combo upgrade effect should show combo name")
		_finish(1, rest, game_state, original_state)
		return

	rest._on_equipment_level_upgrade("long_sword")
	var equip_overlay: Node = rest.get_node_or_null("UpgradeEffectOverlay")
	if equip_overlay == null:
		push_error("Equipment upgrade should spawn upgrade effect overlay")
		_finish(1, rest, game_state, original_state)
		return
	var equip_title := equip_overlay.get_node_or_null("UpgradeEffectTitle") as Label
	var equip_target := equip_overlay.get_node_or_null("UpgradeEffectTarget") as Label
	if equip_title == null or equip_title.text.find("器物锻造") < 0:
		push_error("Equipment upgrade effect should show forge title")
		_finish(1, rest, game_state, original_state)
		return
	if equip_target == null or equip_target.text.find("长剑") < 0:
		push_error("Equipment upgrade effect should show item name")
		_finish(1, rest, game_state, original_state)
		return

	print("upgrade_feedback_smoke: ok")
	_finish(0, rest, game_state, original_state)

func _finish(code: int, rest: Node, game_state: Node, original_state: Dictionary) -> void:
	if rest != null:
		rest.queue_free()
	game_state.player_gold = int(original_state.get("player_gold", 0))
	game_state.materials = int(original_state.get("materials", 0))
	game_state.equipment_slot = (original_state.get("equipment_slot", []) as Array).duplicate(true)
	game_state.backpack = (original_state.get("backpack", []) as Array).duplicate(true)
	game_state.combo_upgrades = (original_state.get("combo_upgrades", {}) as Dictionary).duplicate(true)
	game_state.equipment_upgrades = (original_state.get("equipment_upgrades", {}) as Dictionary).duplicate(true)
	quit(code)
