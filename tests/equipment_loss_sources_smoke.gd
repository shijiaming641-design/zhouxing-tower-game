extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var manager := root.get_node("/root/RandomEventManager")
	var original_backpack: Array = game_state.backpack.duplicate(true)
	var original_equipment: Array = game_state.equipment_slot.duplicate(true)

	manager.reset_state()
	game_state.backpack.clear()
	game_state.backpack.append(game_state.ITEMS["long_sword"].duplicate(true))
	game_state.equipment_slot.clear()
	manager.settle_direct_equip_loss()
	if not game_state.backpack.is_empty():
		push_error("Direct equipment loss should remove backpack item")
		_restore(game_state, original_backpack, original_equipment, 1)
		return

	manager.reset_state()
	game_state.backpack.clear()
	game_state.equipment_slot.clear()
	game_state.equipment_slot.append(game_state.ITEMS["wooden_shield"].duplicate(true))
	manager.settle_direct_equip_loss()
	if not game_state.equipment_slot.is_empty():
		push_error("Direct equipment loss should remove equipped item")
		_restore(game_state, original_backpack, original_equipment, 1)
		return

	print("equipment_loss_sources_smoke: ok")
	_restore(game_state, original_backpack, original_equipment, 0)

func _restore(game_state: Node, original_backpack: Array, original_equipment: Array, code: int) -> void:
	game_state.backpack.clear()
	for item in original_backpack:
		game_state.backpack.append(item)
	game_state.equipment_slot.clear()
	for item in original_equipment:
		game_state.equipment_slot.append(item)
	quit(code)
