extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_settings: Dictionary = game_state.user_settings.duplicate(true)
	var original_suppress := bool(game_state.suppress_save_progress)
	var original_mute := AudioServer.is_bus_mute(0)
	var original_speed := Engine.time_scale
	game_state.suppress_save_progress = true

	game_state.set_audio_muted(true)
	if not game_state.is_audio_muted() or not AudioServer.is_bus_mute(0):
		_fail("Audio mute setting should apply immediately and update the audio bus.", game_state, original_settings, original_suppress, original_mute, original_speed)
		return

	game_state.set_battle_speed(1.5)
	if absf(game_state.get_battle_speed() - 1.5) > 0.01 or absf(Engine.time_scale - 1.5) > 0.01:
		_fail("Battle speed setting should apply immediately and update Engine.time_scale.", game_state, original_settings, original_suppress, original_mute, original_speed)
		return

	game_state.cycle_battle_speed()
	if absf(game_state.get_battle_speed() - 1.0) > 0.01:
		_fail("Battle speed should cycle back to x1.0 after x1.5.", game_state, original_settings, original_suppress, original_mute, original_speed)
		return

	var migrated: Dictionary = game_state.migrate_save_data({
		"meta": {
			"user_settings": {
				"audio_muted": true,
				"battle_speed": 1.47
			}
		},
		"run_active": false
	})
	var settings: Dictionary = (migrated.get("meta", {}) as Dictionary).get("user_settings", {})
	if not bool(settings.get("audio_muted", false)) or absf(float(settings.get("battle_speed", 0.0)) - 1.5) > 0.01:
		_fail("Save migration should preserve and normalize user settings.", game_state, original_settings, original_suppress, original_mute, original_speed)
		return

	game_state.reset_user_settings()
	if game_state.is_audio_muted() or absf(game_state.get_battle_speed() - 1.0) > 0.01:
		_fail("Reset should restore default settings.", game_state, original_settings, original_suppress, original_mute, original_speed)
		return

	print("settings_follow_smoke: ok")
	_finish(0, game_state, original_settings, original_suppress, original_mute, original_speed)

func _fail(message: String, game_state: Node, original_settings: Dictionary, original_suppress: bool, original_mute: bool, original_speed: float) -> void:
	push_error(message)
	_finish(1, game_state, original_settings, original_suppress, original_mute, original_speed)

func _finish(code: int, game_state: Node, original_settings: Dictionary, original_suppress: bool, original_mute: bool, original_speed: float) -> void:
	if game_state != null:
		game_state.user_settings = original_settings.duplicate(true)
		game_state.suppress_save_progress = original_suppress
		AudioServer.set_bus_mute(0, original_mute)
		Engine.time_scale = original_speed
	quit(code)
