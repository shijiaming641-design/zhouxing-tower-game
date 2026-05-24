extends SceneTree

func _finish(code: int, game_state: Node = null) -> void:
	if game_state != null:
		game_state.free()
	quit(code)

func _initialize() -> void:
	var game_state = load("res://autoload/game_state.gd").new()

	var legacy_save := {
		"meta": {
			"highest_floor_reached": 3,
			"total_wins": 1,
			"runs_played": 2
		},
		"run_active": true,
		"checkpoint_scene": "map",
		"run": {
			"player_hp": 5,
			"player_max_hp": 9,
			"player_attack": 2
		}
	}

	var migrated = game_state.migrate_save_data(legacy_save)
	if int(migrated.get("save_version", 0)) != game_state.SAVE_VERSION:
		push_error("Save migration should stamp current save version")
		_finish(1, game_state)
		return

	var meta: Dictionary = migrated.get("meta", {})
	if int(meta.get("memory_cores", -1)) != 0:
		push_error("Save migration should default memory_cores to 0")
		_finish(1, game_state)
		return
	if not (meta.get("meta_upgrades", null) is Dictionary):
		push_error("Save migration should default meta_upgrades to Dictionary")
		_finish(1, game_state)
		return
	if not (meta.get("era_first_clears", null) is Dictionary):
		push_error("Save migration should default era_first_clears to Dictionary")
		_finish(1, game_state)
		return
	if not (meta.get("user_settings", null) is Dictionary):
		push_error("Save migration should default user_settings to Dictionary")
		_finish(1, game_state)
		return
	var settings: Dictionary = meta.get("user_settings", {})
	if bool(settings.get("audio_muted", true)) or absf(float(settings.get("battle_speed", 0.0)) - 1.0) > 0.01:
		push_error("Save migration should default user settings to sound on and speed x1.0")
		_finish(1, game_state)
		return

	var run_data: Dictionary = migrated.get("run", {})
	if bool(run_data.get("draw_protection_available", true)):
		push_error("Save migration should default draw_protection_available to false")
		_finish(1, game_state)
		return
	if bool(run_data.get("draw_protection_armed", true)):
		push_error("Save migration should default draw_protection_armed to false")
		_finish(1, game_state)
		return
	if not (run_data.get("current_shop_items", null) is Array):
		push_error("Save migration should default current_shop_items to Array")
		_finish(1, game_state)
		return

	print("save_migration_smoke: ok")
	_finish(0, game_state)
