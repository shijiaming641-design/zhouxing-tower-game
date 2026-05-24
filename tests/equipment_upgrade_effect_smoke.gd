extends SceneTree

func _finish(code: int, game_state: Node = null) -> void:
	if game_state != null:
		game_state.free()
	quit(code)

func _initialize() -> void:
	var game_state = load("res://autoload/game_state.gd").new()
	game_state.player_gold = 100
	game_state.materials = 20
	game_state.player_attack = 2
	game_state.player_max_hp = 6
	game_state.player_hp = 6

	if not game_state.add_to_equipment_slot("long_sword"):
		push_error("Expected long_sword to equip")
		_finish(1, game_state)
		return
	if game_state.get_total_attack() != 4:
		push_error("Expected base long_sword attack 4, got %d" % game_state.get_total_attack())
		_finish(1, game_state)
		return

	var sword_result = game_state.apply_equipment_upgrade("long_sword", "level")
	if not sword_result.get("success", false):
		push_error("Expected long_sword upgrade to succeed")
		_finish(1, game_state)
		return
	if game_state.get_total_attack() != 5:
		push_error("Expected upgraded long_sword attack 5, got %d" % game_state.get_total_attack())
		_finish(1, game_state)
		return

	if not game_state.add_to_equipment_slot("life_crystal"):
		push_error("Expected life_crystal to equip")
		_finish(1, game_state)
		return
	if game_state.player_max_hp != 12:
		push_error("Expected life_crystal max HP 12 before upgrade, got %d" % game_state.player_max_hp)
		_finish(1, game_state)
		return

	var life_result = game_state.apply_equipment_upgrade("life_crystal", "level")
	if not life_result.get("success", false):
		push_error("Expected life_crystal upgrade to succeed")
		_finish(1, game_state)
		return
	if game_state.player_max_hp != 14:
		push_error("Expected upgraded life_crystal max HP 14, got %d" % game_state.player_max_hp)
		_finish(1, game_state)
		return

	print("equipment_upgrade_effect_smoke: ok")
	_finish(0, game_state)
