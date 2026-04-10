extends SceneTree

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
		quit(1)
		return

	var meta: Dictionary = migrated.get("meta", {})
	if int(meta.get("memory_cores", -1)) != 0:
		push_error("Save migration should default memory_cores to 0")
		quit(1)
		return
	if not (meta.get("meta_upgrades", null) is Dictionary):
		push_error("Save migration should default meta_upgrades to Dictionary")
		quit(1)
		return

	var run_data: Dictionary = migrated.get("run", {})
	if bool(run_data.get("draw_protection_available", true)):
		push_error("Save migration should default draw_protection_available to false")
		quit(1)
		return
	if bool(run_data.get("draw_protection_armed", true)):
		push_error("Save migration should default draw_protection_armed to false")
		quit(1)
		return
	if not (run_data.get("current_shop_items", null) is Array):
		push_error("Save migration should default current_shop_items to Array")
		quit(1)
		return

	print("save_migration_smoke: ok")
	quit()
