extends SceneTree

const MomentumFieldScript = preload("res://scenes/ui/momentum_field.gd")

func _initialize() -> void:
	var field: Control = MomentumFieldScript.new()
	root.add_child(field)
	field.size = Vector2(540, 252)
	field.setup({
		"good": Color(0.38, 0.82, 0.62, 1.0),
		"bad": Color(0.92, 0.34, 0.28, 1.0),
		"accent": Color(0.86, 0.68, 0.36, 1.0),
		"panel": Color(0.08, 0.08, 0.10, 1.0)
	})
	field.refresh_state({
		"player_hp_ratio": 0.72,
		"enemy_hp_ratio": 0.48,
		"shield": 5,
		"pending_force": 7
	})
	field.show_reveal(0, 1)
	field.show_outcome(true, false, {"damage": 4})
	field.show_trigger("shield_blade")
	field.show_enemy_intent("read")
	await process_frame
	if field.mark_type != "shield_blade":
		push_error("MomentumField should keep latest trigger mark")
		quit(1)
		return
	if field.intent_type != "read":
		push_error("MomentumField should keep latest enemy intent")
		quit(1)
		return
	field.queue_free()
	print("momentum_field_smoke: ok")
	quit(0)
