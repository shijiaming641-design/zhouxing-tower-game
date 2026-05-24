class_name Main
extends Node2D

const MoveSymbols = preload("res://resources/move_symbols.gd")
const HistoryMapBuilder = preload("res://resources/history_map_builder.gd")
const ShopItemPicker = preload("res://resources/shop_item_picker.gd")
const ShopFlow = preload("res://resources/shop_flow.gd")
const ShopUiBuilder = preload("res://resources/shop_ui_builder.gd")
const MomentumField = preload("res://scenes/ui/momentum_field.gd")
const CHARACTER_PORTRAIT_PATHS := {
	0: "res://assets/characters/doctor_portrait.png",
	1: "res://assets/characters/hacker_portrait.png",
	2: "res://assets/characters/merchant_portrait.png",
	3: "res://assets/characters/farmer_portrait.png",
	4: "res://assets/characters/wanderer_portrait.png",
}
const CHARACTER_BATTLE_PATHS := {
	0: "res://assets/characters/doctor_battle.png",
	1: "res://assets/characters/hacker_battle.png",
	2: "res://assets/characters/merchant_battle.png",
	3: "res://assets/characters/farmer_battle.png",
	4: "res://assets/characters/wanderer_battle.png",
}
const CHARACTER_ART_KEYS := {
	0: "doctor",
	1: "artisan",
	2: "merchant",
	3: "farmer",
	4: "wanderer",
}
const ENEMY_PORTRAIT_PATHS := {
	"basic_tian": "res://assets/enemies/enemy_basic_tian.png",
	"basic_ren": "res://assets/enemies/enemy_basic_ren.png",
	"basic_di": "res://assets/enemies/enemy_basic_di.png",
	"basic_soldier": "res://assets/enemies/enemy_basic_soldier.png",
	"basic_trainee": "res://assets/enemies/enemy_basic_trainee.png",
	"basic_guard": "res://assets/enemies/enemy_basic_guard.png",
	"elite_switch": "res://assets/enemies/enemy_elite_switch.png",
	"elite_guardian": "res://assets/enemies/enemy_elite_guardian.png",
	"elite_counter": "res://assets/enemies/enemy_elite_counter.png",
	"elite_dual": "res://assets/enemies/enemy_elite_dual.png",
	"elite_tactician": "res://assets/enemies/enemy_elite_tactician.png",
	"advanced_mind": "res://assets/enemies/enemy_advanced_mind.png",
	"advanced_assault": "res://assets/enemies/enemy_advanced_assault.png",
	"advanced_mimic": "res://assets/enemies/enemy_advanced_mimic.png",
	"advanced_sage": "res://assets/enemies/enemy_advanced_sage.png",
	"advanced_master": "res://assets/enemies/enemy_advanced_master.png",
	"boss_qin": "res://assets/enemies/enemy_boss_qin.png",
	"boss_song": "res://assets/enemies/enemy_boss_song.png",
	"boss_china": "res://assets/enemies/enemy_boss_china.png",
}

const ERA_MAIN_MENU_BG_PATHS := {
	"qin": "res://assets/ui/qin/backgrounds/qin_main_menu_bg.png",
	"song": "res://assets/ui/song/backgrounds/song_main_menu_bg.png",
	"china": "res://assets/ui/china/backgrounds/china_main_menu_bg.png",
}

const ERA_MAIN_MENU_SEAL_PATHS := {
	"qin": "res://assets/ui/qin/seals/qin_main_menu_seal.png",
	"song": "res://assets/ui/song/seals/song_main_menu_seal.png",
	"china": "res://assets/ui/china/seals/china_main_menu_seal.png",
}

const ERA_BATTLE_BG_PATHS := {
	"qin": "res://assets/ui/qin/backgrounds/qin_battle_bg.png",
	"song": "res://assets/ui/song/backgrounds/song_battle_bg.png",
	"china": "res://assets/ui/china/backgrounds/china_battle_bg.png",
}

const ERA_BATTLE_FRAME_PATHS := {
	"qin": "res://assets/ui/qin/frames/qin_battle_frame.png",
	"song": "res://assets/ui/song/frames/song_battle_frame.png",
	"china": "res://assets/ui/china/frames/china_battle_frame.png",
}

const ERA_SHOP_PANEL_PATHS := {
	"qin": "res://assets/ui/qin/frames/qin_shop_panel.png",
	"song": "res://assets/ui/song/frames/song_shop_panel.png",
	"china": "res://assets/ui/china/frames/china_shop_panel.png",
}

const ERA_OVERLAY_FRAME_PATHS := {
	"qin": "res://assets/ui/qin/frames/qin_overlay_frame.png",
	"song": "res://assets/ui/song/frames/song_overlay_frame.png",
	"china": "res://assets/ui/china/frames/china_overlay_frame.png",
}

const ITEM_ICON_PATHS := {
	"long_sword": "res://assets/items/icons/item_sword.png",
	"demon_blade": "res://assets/items/icons/item_sword.png",
	"bounty_blade": "res://assets/items/icons/item_sword.png",
	"regicide": "res://assets/items/icons/item_sword.png",
	"vampire_blade": "res://assets/items/icons/item_sword.png",
	"poison_coating": "res://assets/items/icons/item_potion.png",
	"flesh_toxin": "res://assets/items/icons/item_potion.png",
	"blood_tyrant": "res://assets/items/icons/item_amulet.png",
	"wooden_shield": "res://assets/items/icons/item_shield.png",
	"shield_blade": "res://assets/items/icons/item_shield.png",
	"life_crystal": "res://assets/items/icons/item_crystal.png",
	"life_armor": "res://assets/items/icons/item_shield.png",
	"soul_collector": "res://assets/items/icons/item_amulet.png",
	"heart_armor": "res://assets/items/icons/item_shield.png",
	"heart_mirror": "res://assets/items/icons/item_mirror.png",
	"thorn_armor": "res://assets/items/icons/item_shield.png",
	"vampire_cross": "res://assets/items/icons/item_amulet.png",
	"afterlife_lamp": "res://assets/items/icons/item_amulet.png",
	"precision_guidance": "res://assets/items/icons/item_amulet.png",
	"precision_auxiliary": "res://assets/items/icons/item_amulet.png",
	"precision_calculation": "res://assets/items/icons/item_mirror.png",
	"broken_coin": "res://assets/items/icons/item_amulet.png",
	"camp_banner": "res://assets/items/icons/item_amulet.png",
	"blood_contract": "res://assets/items/icons/item_amulet.png",
	"counter_sigil": "res://assets/items/icons/item_mirror.png",
	"ai_system": "res://assets/items/icons/item_amulet.png",
	"explorer_notes": "res://assets/items/icons/item_potion.png",
	"greedy_gloves": "res://assets/items/icons/item_amulet.png",
	"tiger_tally": "res://assets/items/era_sets/qin/qin_item_tiger_tally.png",
	"trade_ledger": "res://assets/items/era_sets/song/song_item_trade_ledger.png",
	"flesh_talisman": "res://assets/items/icons/item_potion.png",
	"plague_source": "res://assets/items/icons/item_potion.png",
	"unity_seal": "res://assets/items/era_sets/china/china_item_mountain_seal.png",
}

const SCENE_MUSIC_PATHS := {
	"menu": "res://assets/audio/bgm/menu.wav",
	"battle": "res://assets/audio/bgm/battle.wav",
	"shop": "res://assets/audio/bgm/shop.wav",
	"rest": "res://assets/audio/bgm/rest.wav",
	"event_neutral": "res://assets/audio/bgm/event_neutral.wav",
	"event_good_1": "res://assets/audio/bgm/event_good_1.wav",
	"event_good_2": "res://assets/audio/bgm/event_good_2.wav",
	"event_good_3": "res://assets/audio/bgm/event_good_3.wav",
	"event_bad": "res://assets/audio/bgm/event_bad.wav",
}

const SCENE_AMBIENT_PATHS := {
	"battle": "res://assets/audio/ambient/battle_urgency.wav",
	"shop": "res://assets/audio/ambient/shop_forge.wav",
	"rest": "res://assets/audio/ambient/rest_fire.wav",
}

const BATTLE_UTILITY_ROW_POS := Vector2(378, 662)
const BATTLE_UTILITY_ROW_SIZE := Vector2(524, 32)
const BATTLE_CHEAT_BUTTON_POS := Vector2(744, 662)
const BATTLE_CHEAT_BUTTON_SIZE := Vector2(150, 32)
const BATTLE_CHEAT_PANEL_POS := Vector2(428, 250)
const BATTLE_CHEAT_PANEL_SIZE := Vector2(424, 220)
const BATTLE_CHEAT_ACTION_BUTTON_SIZE := Vector2(148, 54)

enum State { MENU, CHARACTER_SELECT, COMBO_SELECT, MAP, BATTLE, SHOP, GAME_OVER, VICTORY, EVENT, EVENT_BATTLE, REST_POINT }

var current_state: State = State.MENU
var current_ui: Control = null

# 战斗状态
var battle_enemy_hp: int = 0
var battle_enemy_max_hp: int = 0
var battle_enemy_atk: int = 0
var battle_support_enemies: Array[Dictionary] = []
var current_enemy_ai: EnemyAI = null
var current_enemy_data: EnemyData = null
var is_current_battle_boss: bool = false  # 当前战斗是否是BOSS
var _era_boss_phase_bonus_applied: bool = false
var _era_boss_china_burn_active: bool = false
var _era_enemy_china_burn_active: bool = false
var _battle_round_count: int = 0
var _boss_phase2_turn_count: int = 0
var _field_shield_blade_triggers: int = 0
var _field_combo_trigger_count: int = 0
var _field_camp_followup_done: bool = false
var _battle_enemy_poison: int = 0
var _heart_armor_temp_shield: int = 0
var _poison_relic_triggered_this_turn: bool = false
var _support_assist_suppressed_this_turn: bool = false
var _battle_build_signals_seen: Dictionary = {}
var _battle_read_streak: int = 0
var _battle_combo_repeat_counts: Dictionary = {}
var _battle_last_combo_family: String = ""
var _battle_combo_family_streak: int = 0
var _battle_momentum_score: int = 0
var _battle_trade_ledger_triggers: int = 0

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.BATTLE or current_ui == null or current_enemy_ai == null:
		return
	var move_idx := _get_battle_move_index_from_key(event)
	if move_idx < 0:
		return
	if _battle_ending or _is_battle_turn_locked(current_ui):
		return
	if current_ui.get_node_or_null("CheatPanel") != null or current_ui.get_node_or_null("BattleSettlementOverlay") != null:
		return
	get_viewport().set_input_as_handled()
	_submit_battle_move(move_idx, current_ui, current_enemy_ai)

func _get_battle_move_index_from_key(event: InputEvent) -> int:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return -1
	match key_event.physical_keycode:
		KEY_Q:
			return 0
		KEY_W:
			return 1
		KEY_E:
			return 2
	return -1

# 连招
var combo_sequence: Array[int] = []

# ComboData 脚本引用
const ComboData = preload("res://resources/combo_data.gd")

# 战斗结束锁，防止多次触发
var _battle_ending: bool = false
var _music_player: AudioStreamPlayer = null
var _ambient_player: AudioStreamPlayer = null
var _music_playback: AudioStreamGeneratorPlayback = null
var _music_scene: String = ""
var _music_profile: Dictionary = {}
var _music_time: float = 0.0
var _music_rng := RandomNumberGenerator.new()
var _event_good_streak: int = 0

func _get_battle_reward_type() -> String:
	if is_current_battle_boss:
		return "boss"
	if current_enemy_data != null and current_enemy_data.ai_type == 1:
		return "elite"
	return "normal"

func _load_character_portrait(class_id: int) -> Texture2D:
	var texture_path = ArtRegistry.get_character_portrait_path(class_id, true)
	if texture_path == "":
		return null
	var absolute_path := ProjectSettings.globalize_path(texture_path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image = Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _load_texture_resource(texture_path: String) -> Texture2D:
	if texture_path == "":
		return null
	if ResourceLoader.exists(texture_path):
		var resource = load(texture_path)
		return resource as Texture2D
	var absolute_path := ProjectSettings.globalize_path(texture_path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image = Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _resource_path_exists(texture_path: String) -> bool:
	if texture_path == "":
		return false
	return ResourceLoader.exists(texture_path) or FileAccess.file_exists(ProjectSettings.globalize_path(texture_path))

func _get_character_animation_frame_paths(class_id: int, action: String) -> Array[String]:
	var key := str(CHARACTER_ART_KEYS.get(class_id, ""))
	if key == "":
		return []
	var paths: Array[String] = []
	for i in range(8):
		var path := "res://assets/characters/%s/frames/%s/%s_%s_%02d.png" % [key, action, key, action, i]
		if not _resource_path_exists(path):
			break
		paths.append(path)
	return paths

func _get_enemy_art_tier(enemy_key: String) -> String:
	if enemy_key.begins_with("enemy_"):
		enemy_key = enemy_key.trim_prefix("enemy_")
	if enemy_key.begins_with("basic_"):
		return "basic"
	if enemy_key.begins_with("elite_"):
		return "elite"
	if enemy_key.begins_with("advanced_"):
		return "advanced"
	if enemy_key.begins_with("boss_"):
		return "boss"
	return "basic"

func _get_enemy_animation_key(enemy_data: EnemyData) -> String:
	var key := _get_enemy_portrait_key(enemy_data)
	if key.begins_with("boss_") and current_enemy_ai != null and current_enemy_ai.boss_phase == 2:
		var phase_key := "%s_phase2" % key
		var phase_path := "res://assets/enemies/boss/frames/%s/idle/%s_idle_00.png" % [phase_key, phase_key]
		if _resource_path_exists(phase_path):
			return phase_key
	return key

func _get_enemy_animation_frame_paths(enemy_data: EnemyData, action: String) -> Array[String]:
	var key := _get_enemy_animation_key(enemy_data)
	if key == "":
		return []
	var tier := _get_enemy_art_tier(key)
	var paths: Array[String] = []
	for i in range(8):
		var path := "res://assets/enemies/%s/frames/%s/%s/%s_%s_%02d.png" % [tier, key, action, key, action, i]
		if not _resource_path_exists(path):
			break
		paths.append(path)
	return paths

func _play_texture_rect_frames(rect: TextureRect, frame_paths: Array[String], idle_paths: Array[String] = [], frame_time: float = 0.075, hold_last: bool = false) -> void:
	if rect == null or frame_paths.is_empty():
		return
	var token := int(rect.get_meta("anim_token", 0)) + 1
	rect.set_meta("anim_token", token)
	var original_texture := rect.texture
	for path in frame_paths:
		if not is_instance_valid(rect) or int(rect.get_meta("anim_token", 0)) != token:
			return
		var frame_texture := _load_texture_resource(path)
		if frame_texture != null:
			rect.texture = frame_texture
		await get_tree().create_timer(frame_time).timeout
	if not is_instance_valid(rect) or int(rect.get_meta("anim_token", 0)) != token:
		return
	if hold_last:
		return
	if not idle_paths.is_empty():
		var idle_texture := _load_texture_resource(idle_paths[0])
		if idle_texture != null:
			rect.texture = idle_texture
			return
	rect.texture = original_texture

func _play_player_battle_animation(battle: Control, action: String, hold_last: bool = false) -> void:
	if battle == null:
		return
	var rect := battle.get_node_or_null("PlayerPortrait") as TextureRect
	if rect == null:
		return
	_play_battle_actor_motion(rect, "player", action, hold_last)
	var frames := _get_character_animation_frame_paths(GameState.player_class, action)
	var idle := _get_character_animation_frame_paths(GameState.player_class, "idle")
	_play_texture_rect_frames(rect, frames, idle, 0.075, hold_last)

func _play_enemy_battle_animation(battle: Control, action: String, hold_last: bool = false) -> void:
	if battle == null:
		return
	var rect := battle.get_node_or_null("EnemyPortrait") as TextureRect
	if rect == null:
		return
	_play_battle_actor_motion(rect, "enemy", action, hold_last)
	var frames := _get_enemy_animation_frame_paths(current_enemy_data, action)
	var idle := _get_enemy_animation_frame_paths(current_enemy_data, "idle")
	_play_texture_rect_frames(rect, frames, idle, 0.075, hold_last)

func _play_battle_actor_motion(rect: TextureRect, actor: String, action: String, hold_last: bool = false) -> void:
	if rect == null:
		return
	if not rect.has_meta("battle_base_position"):
		rect.set_meta("battle_base_position", rect.position)
	if not rect.has_meta("battle_base_modulate"):
		rect.set_meta("battle_base_modulate", rect.modulate)
	var token := int(rect.get_meta("motion_token", 0)) + 1
	rect.set_meta("motion_token", token)
	var base_position: Vector2 = rect.get_meta("battle_base_position")
	var base_modulate: Color = rect.get_meta("battle_base_modulate")
	rect.position = base_position
	rect.modulate = base_modulate
	rect.scale = Vector2.ONE
	rect.pivot_offset = rect.size * 0.5
	var attack_dir := 1.0 if actor == "player" else -1.0
	match action:
		"attack":
			var tween := create_tween()
			tween.tween_property(rect, "position", base_position + Vector2(-10.0 * attack_dir, -3), 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(rect, "position", base_position + Vector2(34.0 * attack_dir, 2), 0.075).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(rect, "position", base_position, 0.105).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		"hurt":
			rect.modulate = Color(1.0, 0.58, 0.52, base_modulate.a)
			var tween := create_tween()
			tween.tween_property(rect, "position", base_position + Vector2(12.0 * -attack_dir, 0), 0.032)
			tween.tween_property(rect, "position", base_position + Vector2(-8.0 * -attack_dir, 0), 0.032)
			tween.tween_property(rect, "position", base_position + Vector2(5.0 * -attack_dir, 0), 0.032)
			tween.tween_property(rect, "position", base_position, 0.052)
			tween.parallel().tween_property(rect, "modulate", base_modulate, 0.18)
		"heal":
			rect.modulate = Color(0.72, 1.0, 0.76, base_modulate.a)
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(rect, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(rect, "modulate", base_modulate, 0.28)
			tween.chain().tween_property(rect, "scale", Vector2.ONE, 0.12)
		"death":
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(rect, "position", base_position + Vector2(0, 18), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(rect, "rotation", deg_to_rad(4.0 * attack_dir), 0.42)
			tween.tween_property(rect, "modulate", Color(0.58, 0.58, 0.58, 0.82), 0.42)
			if not hold_last:
				tween.chain().tween_property(rect, "position", base_position, 0.16)
				tween.parallel().tween_property(rect, "rotation", 0.0, 0.16)
				tween.parallel().tween_property(rect, "modulate", base_modulate, 0.16)
		_:
			return

func _get_era_main_menu_bg_texture() -> Texture2D:
	return _load_texture_resource(ArtRegistry.get_era_ui_path("main_menu_bg"))

func _get_era_main_menu_seal_texture() -> Texture2D:
	return _load_texture_resource(ArtRegistry.get_era_ui_path("main_menu_seal"))

func _get_era_main_menu_frame_texture() -> Texture2D:
	return _load_texture_resource(ArtRegistry.get_era_ui_path("menu_frame"))

func _get_main_menu_button_frame_texture(action_key: String, icon_only: bool = false) -> Texture2D:
	if GameState.selected_era_id == "qin" and action_key == "era":
		var qin_era_button := _load_texture_resource("res://assets/ui/qin/buttons/qin_button_medium.png")
		if qin_era_button != null:
			return qin_era_button
	if GameState.selected_era_id == "song" and action_key == "era":
		var song_era_button := _load_texture_resource("res://assets/ui/song/buttons/song_button_medium.png")
		if song_era_button != null:
			return song_era_button
	if GameState.selected_era_id == "china" and action_key == "era":
		var china_era_button := _load_texture_resource("res://assets/ui/china/buttons/china_era_button.png")
		if china_era_button != null:
			return china_era_button
	if GameState.selected_era_id == "qin" and icon_only and action_key == "settings":
		var qin_system_button := _load_texture_resource("res://assets/ui/qin/buttons/qin_button_icon.png")
		if qin_system_button != null:
			return qin_system_button
	if GameState.selected_era_id == "song" and icon_only and action_key == "settings":
		var song_system_button := _load_texture_resource("res://assets/ui/song/buttons/song_button_icon.png")
		if song_system_button != null:
			return song_system_button
	if GameState.selected_era_id == "china" and icon_only and action_key == "settings":
		var china_system_button := _load_texture_resource("res://assets/ui/china/buttons/china_button_icon_main_menu.png")
		if china_system_button != null:
			return china_system_button
	if not icon_only and GameState.selected_era_id == "qin":
		var qin_button_frame := _load_texture_resource("res://assets/ui/qin/buttons/qin_button_large.png")
		if qin_button_frame != null:
			return qin_button_frame
	if not icon_only and GameState.selected_era_id == "song":
		var song_button_frame := _load_texture_resource("res://assets/ui/song/buttons/song_button_large.png")
		if song_button_frame != null:
			return song_button_frame
	if not icon_only and GameState.selected_era_id == "china":
		var china_button_frame := _load_texture_resource("res://assets/ui/china/buttons/china_button_large_main_menu.png")
		if china_button_frame != null:
			return china_button_frame
	return _load_texture_resource(ArtRegistry.get_reference_ui_path("button_frame"))

func _get_main_menu_title_plate_texture() -> Texture2D:
	if GameState.selected_era_id == "qin":
		return _load_texture_resource("res://assets/ui/qin/titles/qin_main_menu_title_plate.png")
	if GameState.selected_era_id == "song":
		return _load_texture_resource("res://assets/ui/song/titles/song_main_menu_title_plate.png")
	if GameState.selected_era_id == "china":
		return _load_texture_resource("res://assets/ui/china/titles/china_main_menu_title_plate.png")
	return null

func _get_main_menu_action_icon_texture(action_key: String) -> Texture2D:
	var main_menu_icon_paths := {
		"start": "res://assets/ui/main_menu/icons/ui_main_menu_start_icon_pixel.png",
		"continue": "res://assets/ui/main_menu/icons/ui_main_menu_continue_icon_pixel.png",
		"settings": "res://assets/ui/main_menu/icons/ui_main_menu_settings_icon_pixel.png",
		"stats": "res://assets/ui/main_menu/icons/ui_main_menu_stats_icon_pixel.png",
		"upgrade": "res://assets/ui/main_menu/icons/ui_main_menu_upgrade_icon_pixel.png",
		"codex": "res://assets/ui/main_menu/icons/ui_main_menu_codex_icon_pixel.png",
	}
	var icon_path := str(main_menu_icon_paths.get(action_key, ""))
	var texture := _load_texture_resource(icon_path)
	if texture != null:
		return texture
	return _load_texture_resource(ArtRegistry.get_action_icon_path(action_key))

func _get_era_battle_bg_texture() -> Texture2D:
	return _load_texture_resource(ArtRegistry.get_era_ui_path("battle_bg"))

func _get_era_battle_seal_texture() -> Texture2D:
	return _load_texture_resource(ArtRegistry.get_era_ui_path("battle_seal"))

func _get_era_battle_frame_texture() -> Texture2D:
	return _load_texture_resource(ArtRegistry.get_era_ui_path("battle_frame"))

func _get_era_shop_panel_texture() -> Texture2D:
	return _load_texture_resource(ArtRegistry.get_era_ui_path("shop_panel"))

func _get_era_overlay_frame_texture() -> Texture2D:
	return _load_texture_resource(ArtRegistry.get_era_ui_path("overlay_frame"))

func _get_item_icon_texture(item: Dictionary) -> Texture2D:
	var item_id := str(item.get("id", ""))
	var texture_path := ArtRegistry.get_item_icon_path(item_id, str(item.get("type", "")))
	return _load_texture_resource(texture_path)

func _get_enemy_portrait_key(enemy_data: EnemyData) -> String:
	if enemy_data == null:
		return ""
	if enemy_data.ai_type == 3 or enemy_data.enemy_id == "boss":
		match GameState.selected_era_id:
			"song":
				return "boss_song"
			"china":
				return "boss_china"
			_:
				return "boss_qin"
	if enemy_data.ai_type == 2:
		match enemy_data.ai_subtype:
			0:
				return "advanced_mind"
			1:
				return "advanced_assault"
			2:
				return "advanced_mimic"
			3:
				return "advanced_sage"
			_:
				return "advanced_master"
	if enemy_data.ai_type == 1:
		match enemy_data.ai_subtype:
			0:
				return "elite_switch"
			1:
				return "elite_guardian"
			2:
				return "elite_counter"
			3:
				return "elite_dual"
			_:
				return "elite_tactician"
	match enemy_data.display_name:
		"天势卒", "天势教习", "天势残响":
			return "basic_tian"
		"人势卒", "人势教习", "人势残响":
			return "basic_ren"
		"地势卒", "地势教习", "地势残响":
			return "basic_di"
		"锐卒", "边军新卒", "复线新锋":
			return "basic_soldier"
		"军中见习", "行营见习", "山河见证者":
			return "basic_trainee"
		_:
			return "basic_guard"

func _load_enemy_portrait(enemy_data: EnemyData) -> Texture2D:
	var texture_path := ArtRegistry.get_enemy_portrait_path(_get_enemy_portrait_key(enemy_data))
	if texture_path == "":
		return null
	var absolute_path := ProjectSettings.globalize_path(texture_path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image = Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _show_battle_system_hint(battle: Control, text: String) -> void:
	var result_label = battle.get_node_or_null("ResultLabel")
	if result_label:
		result_label.text = text

func _toggle_battle_speed(battle: Control) -> void:
	var speed := GameState.cycle_battle_speed()
	_show_battle_system_hint(battle, "战斗速度：x%.2f" % speed)

func _toggle_battle_mute(battle: Control) -> void:
	var muted := GameState.toggle_audio_muted()
	_show_battle_system_hint(battle, "系统音效：%s" % ("关闭" if muted else "开启"))

func _summarize_text_rows(entries: Array[String], empty_text: String = "（无）", max_lines: int = 3, max_per_line: int = 2) -> String:
	if entries.is_empty():
		return empty_text
	var lines: Array[String] = []
	var current: Array[String] = []
	var unlimited_lines := max_lines <= 0
	for entry in entries:
		current.append(entry)
		if current.size() >= max_per_line:
			lines.append(" · ".join(current))
			current.clear()
			if not unlimited_lines and lines.size() >= max_lines:
				break
	if (unlimited_lines or lines.size() < max_lines) and not current.is_empty():
		lines.append(" · ".join(current))
	var remaining := 0 if unlimited_lines else entries.size() - lines.size() * max_per_line
	if remaining > 0 and not lines.is_empty():
		lines[lines.size() - 1] += " …+%d" % remaining
	return "\n".join(lines)

func _get_layout_effect_brief(effect_type: String, effect_value: int, description: String, cooldown: int) -> String:
	var primary := ""
	match effect_type:
		"damage_all":
			primary = "全体伤害%d" % effect_value
		"damage", "damage_first", "ignore_armor_damage", "stun_damage", "bind_damage":
			primary = "伤害%d" % effect_value
		"double_hit":
			primary = "二连%d" % effect_value
		"shield_reflect":
			primary = "护甲%d反弹" % effect_value
		"shield_duration", "absolute_defense", "iron_wall":
			primary = "护甲%d" % effect_value
		"shield_to_damage":
			primary = "护甲转伤"
		"heal_shield":
			primary = "治疗护甲%d" % effect_value
		"heal_wave", "regen":
			primary = "恢复%d" % effect_value
		"attack_buff", "crit_boost", "pierce_buff":
			primary = "攻击+%d" % effect_value
		"enemy_cooldown":
			primary = "敌冷却+%d" % effect_value
		"bonus_gold", "money_empire", "trade_tide":
			primary = "金币收益"
		"auto_crit", "crit":
			primary = "暴击"
		"desperate", "desperate_counter":
			primary = "低命反击"
		"consume_item_damage", "arsenal_unload", "supply_bombard":
			primary = "器物爆发"
		"absolute_hit", "phase_guard", "memory_burst":
			primary = "特殊时机"
		_:
			primary = description.strip_edges()
	if primary == "":
		primary = "效果待观察"
	if primary.length() > 16:
		primary = primary.substr(0, 16) + "…"
	var parts: Array[String] = [primary]
	if cooldown > 0:
		parts.append("CD%d" % cooldown)
	return "｜".join(parts)

func _format_layout_combo_row(sequence_text: String, combo_name: String, description: String, effect_type: String, effect_value: int, cooldown: int, upgrade_text: String = "") -> String:
	var prefix := "%s " % sequence_text if sequence_text != "" else ""
	var brief := _get_layout_effect_brief(effect_type, effect_value, description, cooldown)
	return "%s%s%s｜%s" % [prefix, combo_name, upgrade_text, brief]

func _format_layout_combo_tooltip(section_title: String, sequence_text: String, combo_name: String, description: String, effect_type: String, effect_value: int, cooldown: int, upgrade_text: String = "") -> String:
	var lines: Array[String] = [section_title]
	var prefix := "%s " % sequence_text if sequence_text != "" else ""
	lines.append("%s%s%s" % [prefix, combo_name, upgrade_text])
	var desc := description.strip_edges()
	var current_brief := _get_layout_effect_brief(effect_type, effect_value, "", cooldown)
	if desc == "":
		desc = current_brief
	lines.append("效果：%s" % desc)
	if current_brief != desc:
		lines.append("当前：%s" % current_brief)
	if cooldown > 0:
		lines.append("冷却：%d回合" % cooldown)
	return "\n".join(lines)

func _get_layout_display_effect_value(combo, effect_type: String, base_value: int) -> int:
	var combo_id := _get_combo_id(combo)
	if combo_id == "":
		return base_value
	return GameState.get_combo_effect_amount(combo_id, base_value, effect_type)

func _get_layout_display_upgrade_text(combo) -> String:
	var combo_id := _get_combo_id(combo)
	if combo_id == "":
		return ""
	return GameState.get_combo_upgrade_status_text(combo_id)

func _get_combat_combo_brief(combo, actual_cost: int) -> String:
	return "%d段×%d%%｜耗%d气" % [int(combo.attack_count), int(combo.base_damage), actual_cost]

func _get_combat_combo_tooltip(combo, sequence_text: String, actual_cost: int, can_use: bool) -> String:
	var lines: Array[String] = [
		str(combo.name),
		"序列：%s" % sequence_text,
		"消耗：%d气机" % actual_cost,
		"效果：%s" % str(combo.description),
		"段数：%d段，每段%d%%伤害" % [int(combo.attack_count), int(combo.base_damage)],
		"状态：%s" % ("可发动" if can_use else "气机不足")
	]
	return "\n".join(lines)

func _show_level_up_panel(parent_ui: Control, leveled_up: Array[int], exp_gained: int) -> void:
	_set_duel_momentum_rail_visible(parent_ui, false)
	var overlay = Control.new()
	overlay.name = "LevelUpOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim = ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var panel = PanelContainer.new()
	panel.name = "LevelUpPanel"
	panel.position = Vector2(290, 120)
	panel.custom_minimum_size = Vector2(700, 460)
	panel.scale = Vector2(0.92, 0.92)
	panel.pivot_offset = Vector2(350, 230)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.09, 0.07, 0.96)
	panel_style.border_color = Color(1.0, 0.78, 0.32, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var content = VBoxContainer.new()
	content.position = Vector2(24, 20)
	content.custom_minimum_size = Vector2(652, 420)
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var title = Label.new()
	title.name = "LevelUpTitle"
	title.text = "战中提振"
	title.add_theme_font_size_override("font_size", 32)
	title.modulate = Color(1, 0.92, 0.68)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var summary = Label.new()
	summary.text = "此役已有所得，可临阵整军一次｜本次获得 %d EXP｜当前 %s" % [exp_gained, GameState.get_level_progress_text()]
	summary.add_theme_font_size_override("font_size", 18)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.modulate = Color(0.84, 0.9, 0.98)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(summary)

	var rewards_box = VBoxContainer.new()
	rewards_box.add_theme_constant_override("separation", 8)
	content.add_child(rewards_box)

	for level in leveled_up:
		var reward_line = Label.new()
		reward_line.name = "LevelRewardLine%d" % level
		var rewards = GameState.get_level_reward_summary(level)
		reward_line.text = "Lv.%d: %s" % [level, " / ".join(rewards) if not rewards.is_empty() else "无额外奖励"]
		reward_line.add_theme_font_size_override("font_size", 18)
		reward_line.modulate = Color(0.9, 0.95, 1)
		rewards_box.add_child(reward_line)

	var attr_title = Label.new()
	attr_title.text = "临阵整军"
	attr_title.add_theme_font_size_override("font_size", 22)
	attr_title.modulate = Color(0.82, 0.96, 0.82)
	content.add_child(attr_title)

	var attr_status = Label.new()
	attr_status.add_theme_font_size_override("font_size", 18)
	content.add_child(attr_status)

	var choice_row = HBoxContainer.new()
	choice_row.add_theme_constant_override("separation", 10)
	content.add_child(choice_row)

	var hp_btn = Button.new()
	hp_btn.text = ""
	hp_btn.custom_minimum_size = Vector2(208, 88)
	hp_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_row.add_child(hp_btn)

	var atk_btn = Button.new()
	atk_btn.text = ""
	atk_btn.custom_minimum_size = Vector2(208, 88)
	atk_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_row.add_child(atk_btn)

	var cheat_btn = Button.new()
	cheat_btn.text = ""
	cheat_btn.custom_minimum_size = Vector2(208, 88)
	cheat_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_row.add_child(cheat_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "继续"
	confirm_btn.custom_minimum_size = Vector2(0, 54)
	ArtRegistry.apply_button_icon(confirm_btn, "next", false, "继续")
	content.add_child(confirm_btn)

	var refresh_attr_ui = func():
		attr_status.text = "可提振次数：%d｜稳军 %+d/%d｜锐卒 %+d/%d｜机括存储 %+d/%d｜当前 %d/%d" % [
			GameState.unspent_attribute_points,
			GameState.bonus_hp_from_level,
			GameState.MAX_LEVEL_HP_BONUS,
			GameState.bonus_atk_from_level,
			GameState.MAX_LEVEL_ATK_BONUS,
			GameState.bonus_cheat_from_level,
			GameState.MAX_LEVEL_CHEAT_BONUS,
			GameState.cheat_points,
			GameState.get_max_cheat_points()
		]
		hp_btn.text = "稳军\n命数上限+2\n立即恢复2命"
		atk_btn.text = "锐卒\n攻击+1\n此役兵锋更利"
		cheat_btn.text = "整阵\n机括存储+1\n并补1机括"
		hp_btn.tooltip_text = "稳军：提高容错，适合血线压力大或准备打高压节点时选择。"
		atk_btn.tooltip_text = "锐卒：提高输出，适合构筑已经稳定、想缩短战斗时选择。"
		cheat_btn.tooltip_text = "整阵：机括存储上限+1，并立即补1点机括，用于关键回合预判或改命。"
		hp_btn.disabled = GameState.unspent_attribute_points <= 0 or not GameState.can_add_level_hp()
		atk_btn.disabled = GameState.unspent_attribute_points <= 0 or not GameState.can_add_level_atk()
		cheat_btn.disabled = GameState.unspent_attribute_points <= 0 or not GameState.can_add_level_cheat()
		confirm_btn.disabled = GameState.unspent_attribute_points > 0 and (not hp_btn.disabled or not atk_btn.disabled or not cheat_btn.disabled)

	hp_btn.pressed.connect(func():
		if GameState.allocate_level_stat("hp"):
			_show_level_attr_feedback(overlay, "稳军\n命数上限+2", Color(0.42, 1.0, 0.62, 1.0))
			refresh_attr_ui.call()
	)
	atk_btn.pressed.connect(func():
		if GameState.allocate_level_stat("atk"):
			_show_level_attr_feedback(overlay, "锐卒\n攻击+1", Color(1.0, 0.58, 0.36, 1.0))
			refresh_attr_ui.call()
	)
	cheat_btn.pressed.connect(func():
		if GameState.allocate_level_stat("cheat"):
			_show_level_attr_feedback(overlay, "整阵\n机括存储+1", Color(0.60, 0.82, 1.0, 1.0))
			refresh_attr_ui.call()
	)
	confirm_btn.pressed.connect(func():
		GameState.save_progress("map")
		overlay.queue_free()
	)

	refresh_attr_ui.call()
	parent_ui.add_child(overlay)
	_play_level_up_intro(overlay, panel, title)
	await overlay.tree_exited
	_restore_duel_momentum_rail_if_battle_active(parent_ui)

func _play_level_up_intro(overlay: Control, panel: Control, title: Label) -> void:
	if overlay == null or panel == null:
		return
	var burst := ColorRect.new()
	burst.name = "LevelUpgradeBurst"
	burst.color = Color(1.0, 0.78, 0.26, 0.22)
	burst.position = Vector2(250, 88)
	burst.custom_minimum_size = Vector2(780, 500)
	burst.size = Vector2(780, 500)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(burst)
	overlay.move_child(burst, 1)
	var burst_tween := create_tween()
	burst_tween.set_parallel(true)
	burst_tween.tween_property(burst, "scale", Vector2(1.12, 1.12), 0.42).from(Vector2(0.84, 0.84)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	burst_tween.tween_property(burst, "color:a", 0.0, 0.48)
	burst_tween.chain().tween_callback(func():
		if is_instance_valid(burst):
			burst.queue_free()
	)
	var panel_tween := create_tween()
	panel_tween.set_parallel(true)
	panel_tween.tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.18).from(0.0)
	if title != null:
		var title_tween := create_tween()
		title_tween.set_loops(2)
		title_tween.tween_property(title, "modulate", Color(1.0, 0.78, 0.28, 1.0), 0.16)
		title_tween.tween_property(title, "modulate", Color(1.0, 0.92, 0.68, 1.0), 0.18)

func _show_level_attr_feedback(parent: Control, text: String, color: Color) -> void:
	if parent == null:
		return
	var flash := Label.new()
	flash.name = "LevelAttrFeedback"
	flash.text = text
	flash.position = Vector2(0, 360)
	flash.custom_minimum_size = Vector2(1280, 48)
	flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash.add_theme_font_size_override("font_size", 34)
	flash.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.01, 1.0))
	flash.add_theme_constant_override("outline_size", 4)
	flash.modulate = color
	flash.scale = Vector2(0.72, 0.72)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(flash)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "position:y", 318.0, 0.46).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "scale", Vector2(1.08, 1.08), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.54).set_delay(0.30)
	tween.chain().tween_callback(func():
		if is_instance_valid(flash):
			flash.queue_free()
	)

func _capture_battle_settlement_state() -> Dictionary:
	return {
		"gold": int(GameState.player_gold),
		"materials": int(GameState.materials),
		"level": int(GameState.player_level),
		"exp": int(GameState.player_exp),
		"exp_need": int(GameState.get_level_exp_requirement(GameState.player_level)),
		"hp": int(GameState.player_hp),
		"max_hp": int(GameState.player_max_hp),
		"attack": int(GameState.get_total_attack()),
		"shield": int(GameState.player_shield),
		"cheat": int(GameState.cheat_points),
		"memory": int(GameState.memory_cores)
	}

func _handle_battle_victory_rewards(battle: Control) -> Dictionary:
	var reward_type = _get_battle_reward_type()
	var exp_gained = GameState.get_battle_exp_reward(reward_type)
	var leveled_up = GameState.add_exp(exp_gained)
	var memory_gained = _get_battle_legacy_point_reward()
	if memory_gained > 0:
		memory_gained = GameState.award_memory_cores(memory_gained, "battle_%s" % reward_type)
	GameState.save_progress("map")
	if memory_gained > 0:
		var result_label = battle.get_node_or_null("ResultLabel")
		if result_label:
			result_label.text += "\n💠 获得传承点 +%d" % memory_gained
	if not leveled_up.is_empty():
		var result_label = battle.get_node_or_null("ResultLabel")
		if result_label:
			result_label.text += "\n⭐ 升至 Lv.%d" % GameState.player_level
		await _show_level_up_panel(battle, leveled_up, exp_gained)
	return {
		"reward_type": reward_type,
		"exp_gained": exp_gained,
		"leveled_up": leveled_up.duplicate(),
		"memory_gained": memory_gained,
		"level_after": int(GameState.player_level),
		"exp_after": int(GameState.player_exp)
	}

func _get_battle_legacy_point_reward() -> int:
	if is_current_battle_boss:
		return GameState.get_era_legacy_boss_reward()
	if current_enemy_data != null and int(current_enemy_data.ai_type) >= 1:
		return GameState.get_era_legacy_elite_reward()
	return 0

func _show_battle_settlement_detail(battle: Control, before_state: Dictionary, after_state: Dictionary, reward_info: Dictionary) -> void:
	if battle == null or not is_instance_valid(battle):
		return
	_set_duel_momentum_rail_visible(battle, false)
	var old_overlay := battle.get_node_or_null("BattleSettlementOverlay")
	if old_overlay != null:
		old_overlay.queue_free()

	var overlay := Control.new()
	overlay.name = "BattleSettlementOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 120
	battle.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.035, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var panel := Panel.new()
	panel.name = "BattleSettlementPanel"
	panel.position = Vector2(330, 92)
	panel.size = Vector2(620, 500)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 121
	panel.scale = Vector2(0.94, 0.94)
	panel.pivot_offset = Vector2(310, 250)
	var theme = GameState.get_era_theme()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = theme.get("panel", Color(0.12, 0.11, 0.10, 0.97)).darkened(0.03)
	panel_style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.position = Vector2(28, 24)
	box.size = Vector2(564, 366)
	box.custom_minimum_size = Vector2(564, 366)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Label.new()
	title.name = "BattleSettlementTitle"
	title.text = "对战详细"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.modulate = theme.get("title", Color(1.0, 0.92, 0.72, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "BattleSettlementSubtitle"
	subtitle.text = "%s｜第 %d 层｜%s" % [
		"灾主战" if is_current_battle_boss else ("精英战" if str(reward_info.get("reward_type", "normal")) == "elite" else "征战"),
		GameState.current_floor + 1,
		str(current_enemy_data.display_name if current_enemy_data != null else "敌阵")
	]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.modulate = Color(0.78, 0.80, 0.84, 1.0)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(subtitle)

	var lines := _build_battle_settlement_lines(before_state, after_state, reward_info)
	for i in range(lines.size()):
		var line := Label.new()
		line.name = "BattleSettlementLine%d" % i
		line.text = str(lines[i])
		line.custom_minimum_size = Vector2(0, 32)
		line.add_theme_font_size_override("font_size", 18)
		line.modulate = Color(0.92, 0.90, 0.82, 1.0)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(line)

	var continue_btn := Button.new()
	continue_btn.name = "BattleSettlementContinueButton"
	continue_btn.text = "继续查看地图"
	continue_btn.position = Vector2(358, 520)
	continue_btn.size = Vector2(564, 54)
	continue_btn.custom_minimum_size = Vector2(564, 54)
	continue_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	continue_btn.z_index = 122
	continue_btn.focus_mode = Control.FOCUS_ALL
	continue_btn.disabled = false
	continue_btn.add_theme_font_size_override("font_size", 20)
	ArtRegistry.apply_button_icon(continue_btn, "next", false, "继续查看地图")
	var close_settlement := func():
		if is_instance_valid(overlay):
			overlay.queue_free()
	continue_btn.pressed.connect(close_settlement)
	overlay.add_child(continue_btn)

	var close_from_swallowed_click := func(event: InputEvent):
		var mouse_event := event as InputEventMouseButton
		if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if is_instance_valid(continue_btn) and continue_btn.get_global_rect().has_point(mouse_event.position):
			close_settlement.call()
	overlay.gui_input.connect(close_from_swallowed_click)
	dim.gui_input.connect(close_from_swallowed_click)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.18).from(0.0)
	await overlay.tree_exited
	_restore_duel_momentum_rail_if_battle_active(battle)

func _build_battle_settlement_lines(before_state: Dictionary, after_state: Dictionary, reward_info: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var gold_gain := int(after_state.get("gold", 0)) - int(before_state.get("gold", 0))
	var exp_gained := int(reward_info.get("exp_gained", 0))
	var memory_gain := int(after_state.get("memory", 0)) - int(before_state.get("memory", 0))
	var cheat_gain := int(after_state.get("cheat", 0)) - int(before_state.get("cheat", 0))
	var max_hp_gain := int(after_state.get("max_hp", 0)) - int(before_state.get("max_hp", 0))
	var hp_gain := int(after_state.get("hp", 0)) - int(before_state.get("hp", 0))
	var shield_gain := int(after_state.get("shield", 0)) - int(before_state.get("shield", 0))
	var after_level := int(after_state.get("level", GameState.player_level))
	var after_exp := int(after_state.get("exp", GameState.player_exp))
	var after_exp_need := int(after_state.get("exp_need", GameState.get_level_exp_requirement(after_level)))
	var progress_text := "Lv.%d MAX" % after_level if after_level >= GameState.MAX_PLAYER_LEVEL else "Lv.%d EXP %d/%d" % [after_level, after_exp, after_exp_need]
	lines.append("金币：%+d（%d → %d）" % [gold_gain, int(before_state.get("gold", 0)), int(after_state.get("gold", 0))])
	lines.append("经验：+%d｜%s" % [exp_gained, progress_text])
	var leveled_up: Array = reward_info.get("leveled_up", [])
	if not leveled_up.is_empty():
		var level_texts: Array[String] = []
		for level in leveled_up:
			var rewards := GameState.get_level_reward_summary(int(level))
			level_texts.append("Lv.%d %s" % [int(level), " / ".join(rewards) if not rewards.is_empty() else "无额外奖励"])
		lines.append("升级：" + "；".join(level_texts))
	if memory_gain != 0:
		lines.append("传承点：%+d（%d → %d）" % [memory_gain, int(before_state.get("memory", 0)), int(after_state.get("memory", 0))])
	if cheat_gain != 0:
		lines.append("机括：%+d（%d → %d）" % [cheat_gain, int(before_state.get("cheat", 0)), int(after_state.get("cheat", 0))])
	var growth_parts: Array[String] = []
	if hp_gain != 0:
		growth_parts.append("命数%+d" % hp_gain)
	if max_hp_gain != 0:
		growth_parts.append("命数上限%+d" % max_hp_gain)
	if shield_gain != 0:
		growth_parts.append("护甲%+d" % shield_gain)
	if not growth_parts.is_empty():
		lines.append("战后状态：" + "｜".join(growth_parts))
	return lines

func _capture_event_settlement_state() -> Dictionary:
	return {
		"gold": int(GameState.player_gold),
		"materials": int(GameState.materials),
		"hp": int(GameState.player_hp),
		"max_hp": int(GameState.player_max_hp),
		"attack": int(GameState.player_attack),
		"shield": int(GameState.player_shield),
		"cheat": int(GameState.cheat_points),
		"combo_slots": int(GameState.max_combo_slots),
		"shop_discount": float(GameState.shop_discount),
		"backpack_items": _get_event_item_snapshot(GameState.backpack),
		"equipped_items": _get_event_item_snapshot(GameState.equipment_slot)
	}

func _get_event_item_snapshot(items: Array) -> Array[String]:
	var names: Array[String] = []
	for item in items:
		if item is Dictionary:
			names.append(GameState.get_item_display_name(item))
	return names

func _subtract_text_multiset(left: Array, right: Array) -> Array[String]:
	var remaining: Array[String] = []
	for value in right:
		remaining.append(str(value))
	var result: Array[String] = []
	for value in left:
		var text := str(value)
		var idx := remaining.find(text)
		if idx >= 0:
			remaining.remove_at(idx)
		else:
			result.append(text)
	return result

func _format_event_delta_line(label: String, before_value: int, after_value: int) -> String:
	var delta := after_value - before_value
	return "%s：%+d（%d → %d）" % [label, delta, before_value, after_value]

func _build_event_settlement_lines(before_state: Dictionary, after_state: Dictionary, summary: String) -> Array[String]:
	var lines: Array[String] = []
	if summary.strip_edges() != "":
		for raw_line in summary.split("\n", false):
			var line := str(raw_line).strip_edges()
			if line != "":
				lines.append(line)

	var gold_before := int(before_state.get("gold", 0))
	var gold_after := int(after_state.get("gold", 0))
	var hp_before := int(before_state.get("hp", 0))
	var hp_after := int(after_state.get("hp", 0))
	var max_hp_before := int(before_state.get("max_hp", 0))
	var max_hp_after := int(after_state.get("max_hp", 0))
	var attack_before := int(before_state.get("attack", 0))
	var attack_after := int(after_state.get("attack", 0))
	var shield_before := int(before_state.get("shield", 0))
	var shield_after := int(after_state.get("shield", 0))
	var cheat_before := int(before_state.get("cheat", 0))
	var cheat_after := int(after_state.get("cheat", 0))
	var slots_before := int(before_state.get("combo_slots", 0))
	var slots_after := int(after_state.get("combo_slots", 0))

	if gold_before != gold_after:
		lines.append(_format_event_delta_line("金币", gold_before, gold_after))
	if hp_before != hp_after:
		lines.append(_format_event_delta_line("命数", hp_before, hp_after))
	if max_hp_before != max_hp_after:
		lines.append(_format_event_delta_line("命数上限", max_hp_before, max_hp_after))
	if attack_before != attack_after:
		lines.append(_format_event_delta_line("攻击", attack_before, attack_after))
	if shield_before != shield_after:
		lines.append(_format_event_delta_line("护甲", shield_before, shield_after))
	if cheat_before != cheat_after:
		lines.append(_format_event_delta_line("机括", cheat_before, cheat_after))
	if slots_before != slots_after:
		lines.append(_format_event_delta_line("布局槽", slots_before, slots_after))

	var discount_before := float(before_state.get("shop_discount", 1.0))
	var discount_after := float(after_state.get("shop_discount", 1.0))
	if not is_equal_approx(discount_before, discount_after):
		lines.append("行商折扣：%d折 → %d折" % [int(round(discount_before * 10.0)), int(round(discount_after * 10.0))])

	var items_before: Array = []
	items_before.append_array(before_state.get("backpack_items", []) as Array)
	items_before.append_array(before_state.get("equipped_items", []) as Array)
	var items_after: Array = []
	items_after.append_array(after_state.get("backpack_items", []) as Array)
	items_after.append_array(after_state.get("equipped_items", []) as Array)
	var gained_items := _subtract_text_multiset(items_after, items_before)
	var lost_items := _subtract_text_multiset(items_before, items_after)
	if not gained_items.is_empty():
		lines.append("获得器物：%s" % "、".join(gained_items))
	if not lost_items.is_empty():
		lines.append("失去器物：%s" % "、".join(lost_items))

	if lines.is_empty():
		lines.append("结果：没有实际得失。")
	return lines

func _show_event_settlement_detail(parent: Control, event_data: Dictionary, is_good: bool, choice_title: String, before_state: Dictionary, after_state: Dictionary, summary: String) -> void:
	if parent == null or not is_instance_valid(parent):
		_advance_floor()
		return
	var old_overlay := parent.get_node_or_null("EventSettlementOverlay")
	if old_overlay != null:
		old_overlay.queue_free()

	var overlay := Control.new()
	overlay.name = "EventSettlementOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 150
	parent.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.025, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var panel := Panel.new()
	panel.name = "EventSettlementPanel"
	panel.position = Vector2(340, 112)
	panel.size = Vector2(600, 462)
	panel.scale = Vector2(0.94, 0.94)
	panel.pivot_offset = Vector2(300, 231)
	var theme = GameState.get_era_theme()
	var style := StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.13, 0.11, 0.10, 0.97)).darkened(0.02)
	style.border_color = theme.get("good", Color(0.4, 1.0, 0.4, 1.0)) if is_good else theme.get("bad", Color(1.0, 0.42, 0.36, 1.0))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var box := VBoxContainer.new()
	box.position = Vector2(30, 24)
	box.custom_minimum_size = Vector2(540, 414)
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.name = "EventSettlementTitle"
	title.text = "事件结算"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.modulate = theme.get("title", Color(1.0, 0.92, 0.72, 1.0))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "EventSettlementSubtitle"
	subtitle.text = "%s｜%s｜%s" % [
		"收益" if is_good else "代价",
		choice_title,
		str(event_data.get("name", "异闻"))
	]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.modulate = Color(0.78, 0.80, 0.84, 1.0)
	box.add_child(subtitle)

	var lines := _build_event_settlement_lines(before_state, after_state, summary)
	for i in range(lines.size()):
		var line := Label.new()
		line.name = "EventSettlementLine%d" % i
		line.text = str(lines[i])
		line.custom_minimum_size = Vector2(0, 28)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size", 17)
		line.modulate = Color(0.92, 0.90, 0.82, 1.0)
		box.add_child(line)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 8)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var continue_btn := Button.new()
	continue_btn.name = "EventSettlementContinueButton"
	continue_btn.text = "继续前进"
	continue_btn.custom_minimum_size = Vector2(0, 52)
	continue_btn.add_theme_font_size_override("font_size", 20)
	ArtRegistry.apply_button_icon(continue_btn, "next", false, "继续前进")
	continue_btn.pressed.connect(func():
		if is_instance_valid(overlay):
			overlay.queue_free()
		_advance_floor()
	)
	box.add_child(continue_btn)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.16).from(0.0)

func _finish_event_choice_with_summary(event_data: Dictionary, is_good: bool, choice_title: String, before_state: Dictionary) -> void:
	var summary := RandomEventManager.consume_last_reward_summary()
	var after_state := _capture_event_settlement_state()
	_show_event_settlement_detail(current_ui, event_data, is_good, choice_title, before_state, after_state, summary)

func _format_battle_reward_summary(gold_reward: int, material_drop: int, exp_gained: int = -1, extra_parts: Array = []) -> String:
	var parts: Array[String] = []
	if gold_reward > 0:
		parts.append("金币+%d" % gold_reward)
	if exp_gained >= 0:
		parts.append("经验+%d" % exp_gained)
	for raw_part in extra_parts:
		var part := str(raw_part).strip_edges()
		if part != "":
			parts.append(part)
	if parts.is_empty():
		return ""
	return "战利：%s" % "｜".join(parts)

func _append_battle_reward_summary(result_label: Label, gold_reward: int, material_drop: int, extra_parts: Array = []) -> void:
	if result_label == null:
		return
	var reward_text := _format_battle_reward_summary(gold_reward, material_drop, GameState.get_battle_exp_reward(_get_battle_reward_type()), extra_parts)
	if reward_text == "":
		return
	result_label.text = _append_result_text(result_label.text, reward_text)

func _get_era_map_title() -> String:
	var era_name = GameState.get_current_era_definition().get("name", "秦")
	var layer_text = GameState.get_major_layer_status_text()
	match GameState.selected_era_id:
		"song":
			return "%s 🏮 %s卷 · %s · 第 %d / %d 层" % [_get_era_badge(), era_name, layer_text, GameState.current_floor + 1, GameState.max_floors]
		"china":
			return "%s 🏮 %s终局 · %s · 第 %d / %d 层" % [_get_era_badge(), era_name, layer_text, GameState.current_floor + 1, GameState.max_floors]
		_:
			return "%s 🏮 %s征途 · %s · 第 %d / %d 层" % [_get_era_badge(), era_name, layer_text, GameState.current_floor + 1, GameState.max_floors]

func _get_era_good_event_title() -> String:
	match GameState.selected_era_id:
		"song":
			return "%s 🎉 市井良机" % _get_era_badge()
		"china":
			return "%s 🎉 山河回响" % _get_era_badge()
		_:
			return "%s 🎉 军功嘉赏" % _get_era_badge()

func _get_era_bad_event_title() -> String:
	match GameState.selected_era_id:
		"song":
			return "%s 💀 边患骤起" % _get_era_badge()
		"china":
			return "%s 💀 百代反噬" % _get_era_badge()
		_:
			return "%s 💀 法外加身" % _get_era_badge()

func _get_era_end_title(win: bool) -> String:
	if win:
		match GameState.selected_era_id:
			"song":
				return "〔宋卷〕🎉 中兴得见"
			"china":
				return "〔终局〕🎉 山河重铸"
			_:
				return "〔秦卷〕🎉 开疆定鼎"
	match GameState.selected_era_id:
		"song":
			return "〔宋卷〕💀 山河未复"
		"china":
			return "〔终局〕💀 百代未竟"
		_:
			return "〔秦卷〕💀 王业中断"

func _get_era_badge() -> String:
	match GameState.selected_era_id:
		"song":
			return "〔宋卷〕"
		"china":
			return "〔终局〕"
		_:
			return "〔秦卷〕"

func _create_era_seal(position: Vector2, size: Vector2 = Vector2(120, 34)) -> PanelContainer:
	var seal = PanelContainer.new()
	seal.position = position
	seal.custom_minimum_size = size
	var style = StyleBoxFlat.new()
	style.bg_color = GameState.get_era_theme().get("panel", Color(0.2, 0.16, 0.12, 0.92))
	style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	seal.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = _get_era_badge()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = size
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = GameState.get_era_theme().get("title", Color(0.95, 0.9, 0.75))
	seal.add_child(label)
	return seal

func _get_era_shop_title(discount_text: String, remaining_floors: int) -> String:
	match GameState.selected_era_id:
		"song":
			return "%s 🏪 市舶营帐 - 第%d层 (剩余%d层)%s" % [_get_era_badge(), GameState.current_floor + 1, remaining_floors, discount_text]
		"china":
			return "%s 🏪 山河行商 - 第%d层 (剩余%d层)%s" % [_get_era_badge(), GameState.current_floor + 1, remaining_floors, discount_text]
		_:
			return "%s 🏪 军需营帐 - 第%d层 (剩余%d层)%s" % [_get_era_badge(), GameState.current_floor + 1, remaining_floors, discount_text]

func _get_era_boss_opening_text() -> String:
	match GameState.selected_era_id:
		"song":
			return "「山河未复，先试你能守几回。」"
		"china":
			return "「百代兴亡都在此局，你要背起整部历史。」"
		_:
			return "「军令既下，生死速决。」"

func _apply_era_enemy_modifiers(enemy_data: EnemyData, is_boss: bool) -> EnemyData:
	var hp_bonus = GameState.get_era_enemy_hp_bonus(GameState.current_floor, is_boss)
	var atk_bonus = GameState.get_era_enemy_atk_bonus(GameState.current_floor, is_boss)
	enemy_data.max_hp = maxi(1, enemy_data.max_hp + hp_bonus)
	enemy_data.attack = maxi(1, enemy_data.attack + atk_bonus)
	if is_boss:
		enemy_data.display_name = "%s·%s" % [GameState.get_current_era_definition().get("name", "秦"), GameState.get_era_boss_name()]
	return enemy_data

func _ensure_music_player() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _music_player == null or not is_instance_valid(_music_player):
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "SceneMusicPlayer"
		_music_player.volume_db = -8.0
		_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_music_player)
	if _ambient_player == null or not is_instance_valid(_ambient_player):
		_ambient_player = AudioStreamPlayer.new()
		_ambient_player.name = "SceneAmbientPlayer"
		_ambient_player.volume_db = -13.0
		_ambient_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_ambient_player)

func _switch_scene_music(scene_key: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _music_scene == scene_key:
		return
	_ensure_music_player()
	_music_scene = scene_key
	_music_profile = _get_scene_music_profile(scene_key)
	_music_time = 0.0
	var file_stream := _load_scene_music_stream(scene_key)
	if file_stream != null:
		_music_playback = null
		_music_player.stream = file_stream
		_music_player.volume_db = float(_music_profile.get("volume_db", -18.0))
		_music_player.play()
		_switch_scene_ambient(scene_key)
		return
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 1.0
	_music_player.stream = generator
	_music_player.volume_db = float(_music_profile.get("volume_db", -18.0))
	_music_player.play()
	_music_playback = _music_player.get_stream_playback() as AudioStreamGeneratorPlayback
	for _i in range(8):
		_fill_music_buffer()
	_switch_scene_ambient(scene_key)

func _switch_scene_ambient(scene_key: String) -> void:
	if _ambient_player == null or not is_instance_valid(_ambient_player):
		return
	var ambient_path := str(SCENE_AMBIENT_PATHS.get(scene_key, ""))
	if ambient_path == "":
		_ambient_player.stop()
		_ambient_player.stream = null
		return
	var ambient_stream := AudioStreamWAV.load_from_file(ambient_path)
	if ambient_stream == null:
		_ambient_player.stop()
		_ambient_player.stream = null
		return
	ambient_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_ambient_player.stream = ambient_stream
	_ambient_player.volume_db = _get_scene_ambient_volume(scene_key)
	_ambient_player.play()

func _get_scene_ambient_volume(scene_key: String) -> float:
	match scene_key:
		"battle":
			return -11.0
		"shop":
			return -9.5
		"rest":
			return -12.0
		_:
			return -80.0

func _load_scene_music_stream(scene_key: String) -> AudioStream:
	var music_path := str(SCENE_MUSIC_PATHS.get(scene_key, ""))
	if music_path == "":
		return null
	if not FileAccess.file_exists(music_path):
		return null
	var stream := AudioStreamWAV.load_from_file(music_path)
	if stream == null:
		return null
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream

func _fill_music_buffer() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _music_playback == null or _music_profile.is_empty() or AudioServer.is_bus_mute(0):
		return
	var frames_available := _music_playback.get_frames_available()
	var mix_rate := float(_music_profile.get("mix_rate", 22050.0))
	var frames_to_write = mini(frames_available, 4096)
	for _i in range(frames_to_write):
		var sample := _render_scene_music_sample(_music_time, _music_profile)
		_music_playback.push_frame(Vector2(sample, sample))
		_music_time += 1.0 / mix_rate

func _get_scene_music_profile(scene_key: String) -> Dictionary:
	match scene_key:
		"menu":
			return {
				"mix_rate": 22050.0,
				"volume_db": -7.5,
				"drone": 43.0,
				"drone_amp": 0.085,
				"pulse": 0.42,
				"pulse_amp": 0.052,
				"solemn": 0.048
			}
		"battle":
			return {
				"mix_rate": 22050.0,
				"volume_db": -6.0,
				"drone": 57.0,
				"drone_amp": 0.074,
				"pulse": 7.5,
				"pulse_amp": 0.135,
				"bass_step": 114.0,
				"urgent": 0.078
			}
		"shop":
			return {
				"mix_rate": 22050.0,
				"volume_db": -8.0,
				"drone": 82.0,
				"drone_amp": 0.070,
				"pulse": 0.9,
				"pulse_amp": 0.040,
				"soft": 0.040
			}
		"rest":
			return {
				"mix_rate": 22050.0,
				"volume_db": -9.0,
				"drone": 73.0,
				"drone_amp": 0.072,
				"pulse": 0.78,
				"pulse_amp": 0.040,
				"soft": 0.052
			}
		"event_neutral":
			return {
				"mix_rate": 22050.0,
				"volume_db": -8.0,
				"drone": 61.0,
				"drone_amp": 0.074,
				"pulse": 1.35,
				"pulse_amp": 0.050,
				"unease": 0.034
			}
		"event_good_1":
			return {
				"mix_rate": 22050.0,
				"volume_db": -7.5,
				"drone": 66.0,
				"drone_amp": 0.074,
				"pulse": 2.4,
				"pulse_amp": 0.060,
				"bright": 0.040
			}
		"event_good_2":
			return {
				"mix_rate": 22050.0,
				"volume_db": -7.0,
				"drone": 69.0,
				"drone_amp": 0.076,
				"pulse": 3.6,
				"pulse_amp": 0.078,
				"bright": 0.056
			}
		"event_good_3":
			return {
				"mix_rate": 22050.0,
				"volume_db": -6.5,
				"drone": 72.0,
				"drone_amp": 0.078,
				"pulse": 5.2,
				"pulse_amp": 0.095,
				"bright": 0.070,
				"urgent": 0.045
			}
		"event_bad":
			return {
				"mix_rate": 22050.0,
				"volume_db": -10.0,
				"drone": 48.0,
				"drone_amp": 0.066,
				"pulse": 0.42,
				"pulse_amp": 0.030,
				"soft": 0.052
			}
		_:
			return {
				"mix_rate": 22050.0,
				"volume_db": -8.0,
				"drone": 49.0,
				"drone_amp": 0.070,
				"pulse": 0.55,
				"pulse_amp": 0.036
			}

func _render_scene_music_sample(t: float, profile: Dictionary) -> float:
	var drone := float(profile.get("drone", 55.0))
	var drone_amp := float(profile.get("drone_amp", 0.04))
	var sample := sin(TAU * drone * t) * drone_amp
	sample += sin(TAU * drone * 0.5 * t) * drone_amp * 0.38
	sample += sin(TAU * drone * 1.5 * t) * drone_amp * 0.18
	var pulse_rate := float(profile.get("pulse", 0.0))
	if pulse_rate > 0.0:
		var pulse_lfo := 0.5 + 0.5 * sin(TAU * pulse_rate * t)
		var pulse_env := pow(pulse_lfo, 2.0)
		sample += sin(TAU * float(profile.get("bass_step", drone * 2.0)) * t) * pulse_env * float(profile.get("pulse_amp", 0.025))
	var solemn := float(profile.get("solemn", 0.0))
	if solemn > 0.0:
		sample += sin(TAU * drone * 1.5 * t) * solemn * 0.55
		sample += sin(TAU * drone * 2.0 * t) * solemn * 0.28
	var urgent := float(profile.get("urgent", 0.0))
	if urgent > 0.0:
		var urgent_lfo := 0.5 + 0.5 * sin(TAU * 5.0 * t)
		sample += (sin(TAU * 228.0 * t) + sin(TAU * 456.0 * t) * 0.24) * urgent_lfo * urgent
	var bright := float(profile.get("bright", 0.0))
	if bright > 0.0:
		var bright_env := 0.5 + 0.5 * sin(TAU * 1.5 * t)
		sample += (sin(TAU * 880.0 * t) * 0.32 + sin(TAU * 1320.0 * t) * 0.18) * bright_env * bright
	var soft := float(profile.get("soft", 0.0))
	if soft > 0.0:
		sample += sin(TAU * drone * 0.75 * t) * soft * 0.62
		sample += sin(TAU * drone * 1.25 * t) * soft * 0.24
	var unease := float(profile.get("unease", 0.0))
	if unease > 0.0:
		sample += sin(TAU * (drone + 7.0) * t) * unease * 0.45
	return clampf(sample, -0.22, 0.22)

func _switch_event_good_music() -> void:
	_event_good_streak = clampi(_event_good_streak + 1, 1, 3)
	_switch_scene_music("event_good_%d" % _event_good_streak)

func _switch_event_bad_music() -> void:
	_event_good_streak = 0
	_switch_scene_music("event_bad")

func _ready():
	DebugLog.log("Main _ready")
	randomize()
	_music_rng.randomize()
	_ensure_music_player()
	_show_main_menu()

func _process(_delta: float) -> void:
	_fill_music_buffer()

func _exit_tree() -> void:
	if _music_player != null and is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.stream = null
	if _ambient_player != null and is_instance_valid(_ambient_player):
		_ambient_player.stop()
		_ambient_player.stream = null
	_music_playback = null
	_music_profile.clear()
	_dispose_current_enemy_ai()
	_dispose_combo_database_cache()

func _dispose_combo_database_cache() -> void:
	if _combo_database_cache == null:
		return
	if is_instance_valid(_combo_database_cache):
		_combo_database_cache.all_combos.clear()
		_combo_database_cache.combat_combos.clear()
		if _combo_database_cache.get_parent() != null:
			_combo_database_cache.get_parent().remove_child(_combo_database_cache)
		_combo_database_cache.free()
	_combo_database_cache = null

func _dispose_current_enemy_ai() -> void:
	if current_enemy_ai == null:
		return
	if is_instance_valid(current_enemy_ai) and not current_enemy_ai.is_inside_tree():
		current_enemy_ai.free()
	current_enemy_ai = null

func _show_main_menu():
	DebugLog.log("Showing main menu")
	_change_state(State.MENU)
	_switch_scene_music("menu")

	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	if menu.has_method("configure_continue_state"):
		menu.configure_continue_state(GameState.has_active_run(), GameState.get_save_slot_summary())

	# 直接连接按钮信号
	var start_btn = menu.get_node_or_null("StartButton")
	if start_btn:
		DebugLog.log("StartButton found, connecting...")
		start_btn.pressed.connect(func(): _show_character_select())
	else:
		DebugLog.error("ERROR: StartButton not found!")

	var continue_btn = menu.get_node_or_null("ContinueButton")
	if continue_btn:
		continue_btn.pressed.connect(_resume_saved_run)
	else:
		DebugLog.error("ERROR: ContinueButton not found!")

	var stats_btn = menu.get_node_or_null("StatsButton")
	if stats_btn:
		stats_btn.pressed.connect(func(): _show_meta_panel("stats"))

	var settings_btn = menu.get_node_or_null("SettingsButton")
	if settings_btn:
		settings_btn.pressed.connect(func(): _show_meta_panel("settings"))

	var era_btn = menu.get_node_or_null("EraButton")
	if era_btn:
		era_btn.pressed.connect(func(): _show_meta_panel("eras"))
		era_btn.text = "%s %s" % [_get_era_badge(), GameState.get_current_era_definition().get("name", "秦")]
		era_btn.tooltip_text = "时代卷"

	var codex_btn = menu.get_node_or_null("CodexButton")
	if codex_btn:
		codex_btn.pressed.connect(func(): _show_meta_panel("codex"))

	var upgrades_btn = menu.get_node_or_null("UpgradeButton")
	if upgrades_btn:
		upgrades_btn.pressed.connect(func(): _show_meta_panel("upgrades"))

	_layout_main_menu_buttons(start_btn, continue_btn, settings_btn, era_btn, stats_btn, upgrades_btn, codex_btn)

	var hint_label = menu.get_node_or_null("HintLabel")
	if hint_label:
		hint_label.text = "操作：Q=天  W=人  E=地  |  %s" % GameState.get_current_era_status_text()

	var theme = GameState.get_era_theme()
	var bg = menu.get_node_or_null("Background")
	if bg:
		bg.color = theme.get("bg", Color(0.12, 0.12, 0.18, 1.0))
		var bg_texture = menu.get_node_or_null("EraBackground") as TextureRect
		if bg_texture == null:
			bg_texture = TextureRect.new()
			bg_texture.name = "EraBackground"
			bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bg.add_child(bg_texture)
			bg.move_child(bg_texture, 0)
		bg_texture.texture = _get_era_main_menu_bg_texture()
		bg_texture.modulate = Color(1, 1, 1, 1.0)

		var menu_frame = bg.get_node_or_null("EraMenuFrame") as TextureRect
		if menu_frame != null:
			menu_frame.visible = false

		var menu_seal_texture = _get_era_main_menu_seal_texture()
		var menu_seal = bg.get_node_or_null("EraMenuSealArt") as TextureRect
		var menu_seal_glyph = bg.get_node_or_null("EraMenuSealGlyph") as Label
		if menu_seal_texture != null:
			if menu_seal == null:
				menu_seal = TextureRect.new()
				menu_seal.name = "EraMenuSealArt"
				menu_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
				bg.add_child(menu_seal)
			menu_seal.texture = menu_seal_texture
			if GameState.selected_era_id == "song":
				menu_seal.position = Vector2(774, 6)
				menu_seal.custom_minimum_size = Vector2(260, 128)
			else:
				menu_seal.position = Vector2(810, 18)
				menu_seal.custom_minimum_size = Vector2(188, 92)
			menu_seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			menu_seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			menu_seal.visible = true
			if GameState.selected_era_id == "qin" or GameState.selected_era_id == "song" or GameState.selected_era_id == "china":
				if menu_seal_glyph == null:
					menu_seal_glyph = Label.new()
				menu_seal_glyph.name = "EraMenuSealGlyph"
				menu_seal_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
				menu_seal_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				menu_seal_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				bg.add_child(menu_seal_glyph)
				menu_seal_glyph.text = "宋" if GameState.selected_era_id == "song" else ("中" if GameState.selected_era_id == "china" else "秦")
				if GameState.selected_era_id == "song":
					menu_seal_glyph.position = menu_seal.position + Vector2(4, -6)
					menu_seal_glyph.custom_minimum_size = menu_seal.custom_minimum_size
				elif GameState.selected_era_id == "china":
					menu_seal_glyph.position = menu_seal.position
					menu_seal_glyph.custom_minimum_size = menu_seal.custom_minimum_size
				else:
					menu_seal_glyph.position = menu_seal.position + Vector2(40, 18)
					menu_seal_glyph.custom_minimum_size = Vector2(108, 48)
				menu_seal_glyph.add_theme_font_size_override("font_size", 30)
				if GameState.selected_era_id == "song":
					menu_seal_glyph.add_theme_color_override("font_color", Color(0.30, 0.34, 0.36, 1.0))
					menu_seal_glyph.add_theme_color_override("font_outline_color", Color(0.88, 0.82, 0.70, 0.94))
				elif GameState.selected_era_id == "china":
					menu_seal_glyph.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62, 1.0))
					menu_seal_glyph.add_theme_color_override("font_outline_color", Color(0.14, 0.08, 0.04, 0.96))
				else:
					menu_seal_glyph.add_theme_color_override("font_color", Color(0.92, 0.82, 0.58, 1.0))
					menu_seal_glyph.add_theme_color_override("font_outline_color", Color(0.14, 0.08, 0.04, 0.96))
				menu_seal_glyph.add_theme_constant_override("outline_size", 2)
				menu_seal_glyph.scale = Vector2.ONE
				menu_seal_glyph.rotation = 0.0
				menu_seal_glyph.visible = true
			elif menu_seal_glyph != null:
				menu_seal_glyph.visible = false
		elif menu_seal != null:
			menu_seal.visible = false
			if menu_seal_glyph != null:
				menu_seal_glyph.visible = false
		var title_plate_texture := _get_main_menu_title_plate_texture()
		if title_plate_texture != null:
			var title_back = TextureRect.new()
			title_back.name = "MainMenuTitlePlate"
			title_back.texture = title_plate_texture
			if GameState.selected_era_id == "song":
				title_back.position = Vector2(47, 51)
				title_back.custom_minimum_size = Vector2(510, 165)
			elif GameState.selected_era_id == "china":
				title_back.position = Vector2(38, -8)
				title_back.custom_minimum_size = Vector2(528, 256)
			else:
				title_back.position = Vector2(2, 0)
				title_back.custom_minimum_size = Vector2(600, 292)
			title_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			title_back.stretch_mode = TextureRect.STRETCH_SCALE
			title_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg.add_child(title_back)
		else:
			var title_back = ColorRect.new()
			title_back.color = theme.get("panel", Color(0.2, 0.16, 0.12, 0.9))
			title_back.color.a = 0.24
			title_back.position = Vector2(50, 70)
			title_back.custom_minimum_size = Vector2(398, 132)
			bg.add_child(title_back)
		var left_caption = Label.new()
		left_caption.text = "时代卷章"
		left_caption.position = Vector2(556, 604)
		left_caption.size = Vector2(268, 22)
		left_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		left_caption.add_theme_font_size_override("font_size", 16)
		left_caption.add_theme_color_override("font_color", theme.get("title", Color(0.96, 0.9, 0.8, 1.0)))
		left_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
		left_caption.add_theme_constant_override("shadow_offset_x", 1)
		left_caption.add_theme_constant_override("shadow_offset_y", 1)
		bg.add_child(left_caption)

	var side_button_fill: Color = theme.get("panel", Color(0.2, 0.16, 0.12, 0.9))
	var side_button_border: Color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	var side_button_font: Color = theme.get("title", Color(0.96, 0.9, 0.8, 1.0))
	for main_btn in [start_btn, continue_btn]:
		if main_btn == null:
			continue
		var main_normal := StyleBoxFlat.new()
		main_normal.bg_color = Color(0, 0, 0, 0)
		main_normal.border_width_left = 0
		main_normal.border_width_top = 0
		main_normal.border_width_right = 0
		main_normal.border_width_bottom = 0
		var main_hover := StyleBoxFlat.new()
		if GameState.selected_era_id == "song":
			main_hover.bg_color = Color(0, 0, 0, 0)
		else:
			main_hover.bg_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lightened(0.35)
			main_hover.bg_color.a = 0.12
			main_hover.corner_radius_top_left = 14
			main_hover.corner_radius_top_right = 14
			main_hover.corner_radius_bottom_right = 14
			main_hover.corner_radius_bottom_left = 14
		var main_pressed := main_hover.duplicate()
		main_pressed.bg_color.a = 0.2
		main_btn.add_theme_stylebox_override("normal", main_normal)
		main_btn.add_theme_stylebox_override("hover", main_hover)
		main_btn.add_theme_stylebox_override("pressed", main_pressed)
		main_btn.add_theme_stylebox_override("focus", main_hover)
		main_btn.add_theme_color_override("font_color", side_button_font)
		main_btn.add_theme_color_override("font_hover_color", side_button_font)
		main_btn.add_theme_color_override("font_pressed_color", side_button_font)
		main_btn.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		main_btn.add_theme_constant_override("outline_size", 1)

	for side_btn in [settings_btn, era_btn]:
		if side_btn == null:
			continue
		var normal_style := StyleBoxFlat.new()
		if GameState.selected_era_id == "song":
			normal_style.bg_color = Color(0, 0, 0, 0)
		else:
			normal_style.bg_color = side_button_fill
			normal_style.border_color = side_button_border
			normal_style.border_width_left = 2
			normal_style.border_width_top = 2
			normal_style.border_width_right = 2
			normal_style.border_width_bottom = 2
			normal_style.corner_radius_top_left = 12
			normal_style.corner_radius_top_right = 12
			normal_style.corner_radius_bottom_right = 12
			normal_style.corner_radius_bottom_left = 12
			normal_style.content_margin_left = 10
			normal_style.content_margin_right = 10
			normal_style.content_margin_top = 8
			normal_style.content_margin_bottom = 8

		var hover_style := normal_style.duplicate()
		if GameState.selected_era_id != "song":
			hover_style.bg_color = side_button_fill.lightened(0.08)
			hover_style.border_color = side_button_border.lightened(0.12)

		var pressed_style := normal_style.duplicate()
		if GameState.selected_era_id != "song":
			pressed_style.bg_color = side_button_fill.darkened(0.08)
			pressed_style.border_color = side_button_border

		side_btn.add_theme_stylebox_override("normal", normal_style)
		side_btn.add_theme_stylebox_override("hover", hover_style)
		side_btn.add_theme_stylebox_override("pressed", pressed_style)
		side_btn.add_theme_stylebox_override("focus", hover_style)
		side_btn.add_theme_color_override("font_color", side_button_font)
		side_btn.add_theme_color_override("font_hover_color", side_button_font)
		side_btn.add_theme_color_override("font_pressed_color", side_button_font)
		side_btn.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		side_btn.add_theme_constant_override("outline_size", 1)

	var lower_buttons = [stats_btn, upgrades_btn, codex_btn]
	if GameState.selected_era_id != "china" and GameState.selected_era_id != "song":
		for lower_frame_rect in [
			Rect2(Vector2(76, 414), Vector2(336, 66)),
			Rect2(Vector2(76, 484), Vector2(336, 66)),
			Rect2(Vector2(76, 554), Vector2(336, 66))
		]:
			var lower_frame = PanelContainer.new()
			lower_frame.position = lower_frame_rect.position
			lower_frame.custom_minimum_size = lower_frame_rect.size
			var lower_style := StyleBoxFlat.new()
			lower_style.bg_color = theme.get("panel", Color(0.2, 0.16, 0.12, 0.74))
			lower_style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).darkened(0.06)
			lower_style.border_width_left = 2
			lower_style.border_width_top = 2
			lower_style.border_width_right = 2
			lower_style.border_width_bottom = 2
			lower_style.corner_radius_top_left = 14
			lower_style.corner_radius_top_right = 14
			lower_style.corner_radius_bottom_right = 14
			lower_style.corner_radius_bottom_left = 14
			lower_frame.add_theme_stylebox_override("panel", lower_style)
			bg.add_child(lower_frame)
	for lower_btn in lower_buttons:
		if lower_btn == null:
			continue
		var lower_normal := StyleBoxFlat.new()
		lower_normal.bg_color = Color(0, 0, 0, 0)
		lower_normal.border_width_left = 0
		lower_normal.border_width_top = 0
		lower_normal.border_width_right = 0
		lower_normal.border_width_bottom = 0
		var lower_hover := StyleBoxFlat.new()
		if GameState.selected_era_id == "china" or GameState.selected_era_id == "song":
			lower_hover.bg_color = Color(0, 0, 0, 0)
		else:
			lower_hover.bg_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lightened(0.35)
			lower_hover.bg_color.a = 0.12
			lower_hover.corner_radius_top_left = 10
			lower_hover.corner_radius_top_right = 10
			lower_hover.corner_radius_bottom_right = 10
			lower_hover.corner_radius_bottom_left = 10
		var lower_pressed := lower_hover.duplicate()
		lower_pressed.bg_color.a = 0.2
		lower_btn.add_theme_stylebox_override("normal", lower_normal)
		lower_btn.add_theme_stylebox_override("hover", lower_hover)
		lower_btn.add_theme_stylebox_override("pressed", lower_pressed)
		lower_btn.add_theme_stylebox_override("focus", lower_hover)
		lower_btn.add_theme_color_override("font_color", side_button_font)
		lower_btn.add_theme_color_override("font_hover_color", side_button_font)
		lower_btn.add_theme_color_override("font_pressed_color", side_button_font)
		lower_btn.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		lower_btn.add_theme_constant_override("outline_size", 1)

	ArtRegistry.apply_button_icon(start_btn, "start", false, "起兵开局")
	ArtRegistry.apply_button_icon(continue_btn, "continue", false, "续写征途")
	ArtRegistry.apply_button_icon(settings_btn, "settings", true, "军机设置")
	ArtRegistry.apply_button_icon(era_btn, "era", true, "时代卷切换")
	ArtRegistry.apply_button_icon(stats_btn, "stats", false, "征途簿")
	ArtRegistry.apply_button_icon(upgrades_btn, "upgrade", false, "传承升级")
	ArtRegistry.apply_button_icon(codex_btn, "codex", false, "百代异闻录")
	_decorate_menu_button(start_btn, "start", "起兵开局", "进入角色与布局选择", theme, false)
	_decorate_menu_button(continue_btn, "continue", "续写征途", "读取当前征途", theme, false)
	_decorate_menu_button(settings_btn, "settings", "军机设置", "", theme, true)
	_decorate_menu_button(era_btn, "era", "时代卷", "", theme, true)
	_apply_era_seal_to_menu_button(era_btn)
	_decorate_menu_button(stats_btn, "stats", "征途簿", "统计", theme, false)
	_decorate_menu_button(upgrades_btn, "upgrade", "传承升级", "局外成长", theme, false)
	_decorate_menu_button(codex_btn, "codex", "百代异闻录", "图鉴成就", theme, false)

	var title_label = menu.get_node_or_null("TitleLabel")
	if title_label:
		if GameState.selected_era_id == "song":
			title_label.modulate = Color(0.28, 0.34, 0.36, 1.0)
		else:
			title_label.modulate = theme.get("title", Color(1, 0.9, 0.6, 1))
		title_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		title_label.add_theme_constant_override("outline_size", 1)
	var subtitle_label = menu.get_node_or_null("SubtitleLabel")
	if subtitle_label:
		subtitle_label.text = "%s  |  %s" % [GameState.get_era_menu_banner(), GameState.get_era_menu_subtitle()]
		if GameState.selected_era_id == "song":
			subtitle_label.modulate = Color(0.50, 0.54, 0.46, 1.0)
		else:
			subtitle_label.modulate = theme.get("accent", Color(0.7, 0.7, 0.7, 1))
		subtitle_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		subtitle_label.add_theme_constant_override("outline_size", 1)
	var save_summary = menu.get_node_or_null("SaveSummaryLabel")
	if save_summary:
		save_summary.add_theme_color_override("font_color", theme.get("title", Color(0.82, 0.84, 0.88, 1.0)))
		save_summary.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		save_summary.add_theme_constant_override("outline_size", 1)
	if hint_label:
		hint_label.add_theme_color_override("font_color", theme.get("accent", Color(0.68, 0.68, 0.68, 1.0)).darkened(0.1))
		hint_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		hint_label.add_theme_constant_override("outline_size", 1)

	_add_ui(menu)

func _layout_main_menu_buttons(start_btn: Button, continue_btn: Button, settings_btn: Button, era_btn: Button, stats_btn: Button, upgrades_btn: Button, codex_btn: Button) -> void:
	var main_size := Vector2(320, 58)
	var settings_size := Vector2(168, 60)
	var era_size := Vector2(340, 66)
	var lower_size := Vector2(320, 58)
	_apply_menu_button_rect(start_btn, Vector2(84, 236), main_size)
	_apply_menu_button_rect(continue_btn, Vector2(84, 306), main_size)
	_apply_menu_button_rect(settings_btn, Vector2(1034, 34), settings_size)
	_apply_menu_button_rect(era_btn, Vector2(520, 634), era_size)
	_apply_menu_button_rect(stats_btn, Vector2(84, 418), lower_size)
	_apply_menu_button_rect(upgrades_btn, Vector2(84, 488), lower_size)
	_apply_menu_button_rect(codex_btn, Vector2(84, 558), lower_size)

func _apply_menu_button_rect(button: Button, position: Vector2, size: Vector2) -> void:
	if button == null:
		return
	button.position = position
	button.size = size
	button.custom_minimum_size = size
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER

func _clear_menu_button_art(button: Button) -> void:
	if button == null:
		return
	for child_name in [
		"ArtButtonGlow",
		"ArtButtonFrame",
		"ArtButtonIcon",
		"ArtButtonTitle",
		"ArtButtonSubtitle",
		"ArtButtonEraTitle",
		"ArtButtonEraSubtitle"
	]:
		var child := button.get_node_or_null(child_name)
		if child != null:
			button.remove_child(child)
			child.queue_free()

func _decorate_menu_button(button: Button, action_key: String, title_text: String, subtitle_text: String, theme: Dictionary, icon_only: bool = false) -> void:
	if button == null:
		return
	_clear_menu_button_art(button)
	button.clip_contents = false
	button.tooltip_text = title_text if subtitle_text == "" else "%s：%s" % [title_text, subtitle_text]
	button.text = ""
	button.icon = null
	var clear_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", clear_style)
	button.add_theme_stylebox_override("hover", clear_style)
	button.add_theme_stylebox_override("pressed", clear_style)
	button.add_theme_stylebox_override("focus", clear_style)
	button.add_theme_stylebox_override("disabled", clear_style)

	var button_size := button.size
	if button_size.x <= 0 or button_size.y <= 0:
		button_size = button.custom_minimum_size
	if button_size.x <= 0 or button_size.y <= 0:
		button_size = Vector2(160, 64)

	var frame_texture := _get_main_menu_button_frame_texture(action_key, icon_only)
	if frame_texture != null:
		var add_glow := true
		var glow: TextureRect = null
		var frame := TextureRect.new()
		frame.name = "ArtButtonFrame"
		frame.texture = frame_texture
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.modulate = Color(1, 1, 1, 1.0) if (GameState.selected_era_id == "qin" or GameState.selected_era_id == "china" or (GameState.selected_era_id == "song" and icon_only and action_key == "settings")) else Color(1, 1, 1, 0.76)
		if action_key != "era":
			glow = TextureRect.new()
			glow.name = "ArtButtonGlow"
			glow.texture = frame_texture
			glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			glow.stretch_mode = TextureRect.STRETCH_SCALE
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			glow.modulate = Color(1.0, 0.78, 0.30, 0.0)
		if icon_only and action_key == "settings":
			var art_size := Vector2(236, 120)
			if GameState.selected_era_id == "song":
				art_size = Vector2(173, 72)
			elif GameState.selected_era_id == "china":
				art_size = Vector2(212, 108)
			if glow != null:
				glow.custom_minimum_size = art_size * (1.01 if GameState.selected_era_id == "song" else 1.04)
				glow.size = glow.custom_minimum_size
				if GameState.selected_era_id == "song":
					glow.position = Vector2((button_size.x - glow.size.x) * 0.5, -4)
				elif GameState.selected_era_id == "china":
					glow.position = Vector2((button_size.x - glow.size.x) * 0.5, -33)
				else:
					glow.position = Vector2((button_size.x - glow.size.x) * 0.5, -41)
			frame.custom_minimum_size = art_size
			frame.size = art_size
			if GameState.selected_era_id == "song":
				frame.position = Vector2((button_size.x - art_size.x) * 0.5, -4)
			elif GameState.selected_era_id == "china":
				frame.position = Vector2((button_size.x - art_size.x) * 0.5, -27)
			else:
				frame.position = Vector2((button_size.x - art_size.x) * 0.5, -35)
		elif action_key == "era" and (GameState.selected_era_id == "qin" or GameState.selected_era_id == "song" or GameState.selected_era_id == "china"):
			add_glow = false
			var art_size := Vector2(360, 464)
			var era_visual_offset_y := 178.0
			var era_visual_offset_x := 0.0
			if GameState.selected_era_id == "song":
				art_size = Vector2(405, 418)
				era_visual_offset_y = 144.0
			elif GameState.selected_era_id == "china":
				art_size = Vector2(420, 232)
				era_visual_offset_y = 44.0
				era_visual_offset_x = 12.0
			frame.custom_minimum_size = art_size
			frame.size = art_size
			frame.position = Vector2((button_size.x - art_size.x) * 0.5 + era_visual_offset_x, button_size.y - art_size.y + era_visual_offset_y)
		elif not icon_only and (GameState.selected_era_id == "qin" or GameState.selected_era_id == "song" or GameState.selected_era_id == "china"):
			var art_size := Vector2(button_size.x * 1.18, button_size.y * 3.05)
			var art_offset_y := -button_size.y
			var art_offset_x := 0.0
			if GameState.selected_era_id == "china":
				art_size = Vector2(button_size.x * 1.12, button_size.y * 1.90)
				art_offset_y = -button_size.y + 34
				art_offset_x = 8.0
			if glow != null:
				glow.custom_minimum_size = art_size * 1.04
				glow.size = glow.custom_minimum_size
				glow.position = Vector2((button_size.x - glow.size.x) * 0.5 + art_offset_x, art_offset_y - 4)
			frame.custom_minimum_size = art_size
			frame.size = art_size
			frame.position = Vector2((button_size.x - art_size.x) * 0.5 + art_offset_x, art_offset_y)
		else:
			glow.set_anchors_preset(Control.PRESET_FULL_RECT)
			frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		if add_glow:
			button.add_child(glow)
		button.add_child(frame)

	var skip_icon := action_key == "era" and (GameState.selected_era_id == "qin" or GameState.selected_era_id == "song" or GameState.selected_era_id == "china")
	var icon_texture := null if skip_icon else _get_main_menu_action_icon_texture(action_key)
	if icon_texture != null:
		var icon := TextureRect.new()
		icon.name = "ArtButtonIcon"
		icon.texture = icon_texture
		var icon_size := Vector2(42, 42) if icon_only else Vector2(38, 38)
		icon.custom_minimum_size = icon_size
		icon.position = Vector2((button_size.x - icon_size.x) * 0.5, (button_size.y - icon_size.y) * 0.5) if icon_only else Vector2(18, (button_size.y - icon_size.y) * 0.5)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)

	if icon_only:
		if action_key == "era" and (GameState.selected_era_id == "qin" or GameState.selected_era_id == "song" or GameState.selected_era_id == "china"):
			var era_title := Label.new()
			era_title.name = "ArtButtonEraTitle"
			era_title.text = "宋卷" if GameState.selected_era_id == "song" else ("中国卷" if GameState.selected_era_id == "china" else "秦卷")
			era_title.position = Vector2(12, -72)
			era_title.custom_minimum_size = Vector2(button_size.x, 120)
			era_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			era_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			era_title.add_theme_font_size_override("font_size", 64)
			if GameState.selected_era_id == "song":
				era_title.add_theme_color_override("font_color", Color(0.30, 0.34, 0.36, 1.0))
				era_title.add_theme_color_override("font_outline_color", Color(0.88, 0.82, 0.70, 0.92))
			elif GameState.selected_era_id == "china":
				era_title.add_theme_color_override("font_color", Color(0.94, 0.84, 0.60, 1.0))
				era_title.add_theme_color_override("font_outline_color", Color(0.14, 0.08, 0.04, 0.96))
			else:
				era_title.add_theme_color_override("font_color", Color(0.94, 0.84, 0.60, 1.0))
				era_title.add_theme_color_override("font_outline_color", Color(0.14, 0.08, 0.04, 0.96))
			era_title.add_theme_constant_override("outline_size", 2)
			era_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(era_title)
			var era_subtitle := Label.new()
			era_subtitle.name = "ArtButtonEraSubtitle"
			era_subtitle.text = "时代卷"
			era_subtitle.position = Vector2(12, 18)
			era_subtitle.custom_minimum_size = Vector2(button_size.x, 24)
			era_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			era_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			era_subtitle.add_theme_font_size_override("font_size", 14)
			if GameState.selected_era_id == "song":
				era_subtitle.add_theme_color_override("font_color", Color(0.58, 0.56, 0.46, 1.0))
				era_subtitle.add_theme_color_override("font_outline_color", Color(0.88, 0.82, 0.70, 0.84))
			elif GameState.selected_era_id == "china":
				era_subtitle.add_theme_color_override("font_color", Color(0.90, 0.76, 0.48, 1.0))
				era_subtitle.add_theme_color_override("font_outline_color", Color(0.14, 0.08, 0.04, 0.92))
			else:
				era_subtitle.add_theme_color_override("font_color", Color(0.90, 0.76, 0.48, 1.0))
				era_subtitle.add_theme_color_override("font_outline_color", Color(0.14, 0.08, 0.04, 0.92))
			era_subtitle.add_theme_constant_override("outline_size", 1)
			era_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(era_subtitle)
		_bind_menu_button_feedback(button, icon_only)
		return

	var title := Label.new()
	title.name = "ArtButtonTitle"
	title.text = title_text
	if GameState.selected_era_id == "qin" or GameState.selected_era_id == "song":
		title.position = Vector2(28, 2)
		title.custom_minimum_size = Vector2(maxf(button_size.x - 56, 40), 40)
	else:
		title.position = Vector2(62, button_size.y * 0.22)
		title.custom_minimum_size = Vector2(maxf(button_size.x - 78, 40), 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24 if GameState.selected_era_id == "qin" or GameState.selected_era_id == "song" else (25 if button_size.y >= 70 else 18))
	if GameState.selected_era_id == "song":
		title.add_theme_color_override("font_color", Color(0.26, 0.32, 0.34, 1.0))
		title.add_theme_color_override("font_outline_color", Color(0.91, 0.84, 0.68, 0.78))
	else:
		title.add_theme_color_override("font_color", theme.get("title", Color(0.96, 0.9, 0.8, 1.0)))
		title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	title.add_theme_constant_override("outline_size", 2 if GameState.selected_era_id == "qin" or GameState.selected_era_id == "song" else 1)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)

	if subtitle_text != "":
		var subtitle := Label.new()
		subtitle.name = "ArtButtonSubtitle"
		subtitle.text = subtitle_text
		if GameState.selected_era_id == "qin" or GameState.selected_era_id == "song":
			subtitle.position = Vector2(28, 31)
			subtitle.custom_minimum_size = Vector2(maxf(button_size.x - 56, 40), 18)
		else:
			subtitle.position = Vector2(62, button_size.y * 0.62)
			subtitle.custom_minimum_size = Vector2(maxf(button_size.x - 78, 40), 18)
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.add_theme_font_size_override("font_size", 12)
		if GameState.selected_era_id == "song":
			subtitle.add_theme_color_override("font_color", Color(0.58, 0.56, 0.46, 1.0))
		else:
			subtitle.add_theme_color_override("font_color", theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lightened(0.18))
		subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(subtitle)

	_bind_menu_button_feedback(button, icon_only)

func _bind_menu_button_feedback(button: Button, icon_only: bool = false) -> void:
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	_apply_menu_button_visual_state(button, "normal", icon_only)
	if button.has_meta("menu_feedback_bound"):
		return
	button.set_meta("menu_feedback_bound", true)
	button.mouse_entered.connect(func(): _apply_menu_button_visual_state(button, "hover", icon_only))
	button.mouse_exited.connect(func(): _apply_menu_button_visual_state(button, "normal", icon_only))
	button.button_down.connect(func(): _apply_menu_button_visual_state(button, "pressed", icon_only))
	button.button_up.connect(func():
		var target_state := "hover" if button.get_global_rect().has_point(button.get_global_mouse_position()) else "normal"
		_apply_menu_button_visual_state(button, target_state, icon_only)
	)

func _apply_menu_button_visual_state(button: Button, state: String, icon_only: bool = false) -> void:
	if button == null:
		return
	var glow := button.get_node_or_null("ArtButtonGlow") as CanvasItem
	var frame := button.get_node_or_null("ArtButtonFrame") as CanvasItem
	var icon := button.get_node_or_null("ArtButtonIcon") as CanvasItem
	var title := button.get_node_or_null("ArtButtonTitle") as Label
	var subtitle := button.get_node_or_null("ArtButtonSubtitle") as Label
	var era_title := button.get_node_or_null("ArtButtonEraTitle") as Label
	var era_subtitle := button.get_node_or_null("ArtButtonEraSubtitle") as Label
	var is_song := GameState.selected_era_id == "song"
	var hover := state == "hover"
	var pressed := state == "pressed"
	button.scale = Vector2(0.985, 0.985) if pressed else (Vector2(1.02, 1.02) if hover else Vector2.ONE)
	if glow != null:
		glow.modulate = Color(1.0, 0.76, 0.24, 0.24) if pressed else (Color(1.0, 0.82, 0.34, 0.46) if hover else Color(1.0, 0.78, 0.30, 0.0))
	if frame != null:
		frame.modulate = Color(1.0, 0.96, 0.88, 1.0) if pressed else (Color(1.08, 1.04, 0.96, 1.0) if hover else Color(1, 1, 1, 1.0) if (GameState.selected_era_id == "qin" or GameState.selected_era_id == "china") else Color(1, 1, 1, 0.76))
	if icon != null:
		icon.modulate = Color(1.0, 0.96, 0.86, 1.0) if pressed else (Color(1.08, 1.05, 0.94, 1.0) if hover else Color.WHITE)
	if title != null:
		if is_song:
			title.modulate = Color(0.88, 0.92, 0.90, 1.0) if pressed else (Color(1.02, 1.06, 1.02, 1.0) if hover else Color.WHITE)
		else:
			title.modulate = Color(1.0, 0.94, 0.82, 1.0) if pressed else (Color(1.08, 1.0, 0.9, 1.0) if hover else Color.WHITE)
	if subtitle != null:
		if is_song:
			subtitle.modulate = Color(0.86, 0.90, 0.82, 1.0) if pressed else (Color(0.98, 1.02, 0.94, 1.0) if hover else Color.WHITE)
		else:
			subtitle.modulate = Color(1.0, 0.88, 0.58, 1.0) if pressed else (Color(1.08, 0.96, 0.72, 1.0) if hover else Color.WHITE)
	if era_title != null:
		era_title.modulate = Color(1.0, 0.94, 0.82, 1.0) if pressed else (Color(1.08, 1.0, 0.88, 1.0) if hover else Color.WHITE)
	if era_subtitle != null:
		era_subtitle.modulate = Color(1.0, 0.88, 0.58, 1.0) if pressed else (Color(1.08, 0.96, 0.72, 1.0) if hover else Color.WHITE)
	if icon_only:
		button.modulate = Color(0.98, 0.94, 0.88, 1.0) if pressed else (Color(1.04, 1.0, 0.94, 1.0) if hover else Color.WHITE)
	else:
		button.modulate = Color.WHITE

func _apply_era_seal_to_menu_button(button: Button) -> void:
	if button == null:
		return
	if GameState.selected_era_id == "qin" or GameState.selected_era_id == "song" or GameState.selected_era_id == "china":
		return
	var old_icon = button.get_node_or_null("ArtButtonIcon")
	if old_icon:
		old_icon.queue_free()
	var seal_texture := _get_era_main_menu_seal_texture()
	if seal_texture == null:
		return
	var seal := TextureRect.new()
	seal.name = "ArtButtonEraSeal"
	seal.texture = seal_texture
	seal.custom_minimum_size = Vector2(122, 42)
	seal.size = seal.custom_minimum_size
	seal.position = Vector2((button.size.x - seal.size.x) * 0.5, (button.size.y - seal.size.y) * 0.5)
	seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(seal)

func _show_meta_panel(mode: String) -> void:
	if current_ui == null:
		return
	var theme = GameState.get_era_theme()

	var existing = current_ui.get_node_or_null("MetaOverlay")
	if existing:
		existing.queue_free()

	var overlay = ColorRect.new()
	overlay.name = "MetaOverlay"
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	current_ui.add_child(overlay)

	var panel = Panel.new()
	panel.position = Vector2(120, 70)
	panel.size = Vector2(1040, 560)
	overlay.add_child(panel)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = theme.get("panel", Color(0.18, 0.16, 0.14, 0.96))
	panel_style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	var overlay_frame_texture = _get_era_overlay_frame_texture()
	if overlay_frame_texture != null:
		var overlay_frame = TextureRect.new()
		overlay_frame.name = "EraOverlayFrame"
		overlay_frame.texture = overlay_frame_texture
		overlay_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay_frame.stretch_mode = TextureRect.STRETCH_SCALE
		overlay_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_frame.modulate = Color(1, 1, 1, 0.48)
		panel.add_child(overlay_frame)
	var panel_band = ColorRect.new()
	panel_band.color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	panel_band.position = Vector2(24, 20)
	panel_band.custom_minimum_size = Vector2(992, 4)
	panel.add_child(panel_band)
	var panel_bottom_band = ColorRect.new()
	panel_bottom_band.color = theme.get("panel", Color(0.18, 0.16, 0.14, 0.96)).lerp(theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)), 0.55)
	panel_bottom_band.position = Vector2(80, 546)
	panel_bottom_band.custom_minimum_size = Vector2(880, 3)
	panel.add_child(panel_bottom_band)
	panel.add_child(_create_era_seal(Vector2(24, 6), Vector2(110, 30)))

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(992, 500)
	panel.add_child(scroll)
	scroll.position = Vector2(24, 44)
	scroll.size = Vector2(992, 492)

	var scroll_content = VBoxContainer.new()
	scroll_content.name = "MetaScrollContent"
	scroll_content.custom_minimum_size = Vector2(970, 492)
	scroll_content.add_theme_constant_override("separation", 14)
	scroll.add_child(scroll_content)

	var title = Label.new()
	match mode:
		"stats":
			title.text = "%s 📊 征途簿" % _get_era_badge()
		"settings":
			title.text = "%s ⚙ 设置" % _get_era_badge()
		"eras":
			title.text = "%s 🏮 时代卷" % _get_era_badge()
		"upgrades":
			title.text = "%s 兵马未动｜行前筹备（传承升级）" % _get_era_badge()
		_:
			title.text = "%s 📚 百代异闻录" % _get_era_badge()
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = theme.get("title", Color(0.95, 0.9, 0.75))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	title.add_theme_constant_override("outline_size", 1)
	scroll_content.add_child(title)

	if mode == "stats":
		_populate_stats_panel(scroll_content)
	elif mode == "settings":
		_populate_settings_panel(scroll_content)
	elif mode == "eras":
		_populate_era_panel(scroll_content)
	elif mode == "upgrades":
		_populate_upgrade_panel(scroll_content)
	else:
		_populate_codex_panel(scroll_content)

	var close_btn = Button.new()
	close_btn.text = "×"
	close_btn.tooltip_text = "关闭"
	close_btn.custom_minimum_size = Vector2(38, 34)
	close_btn.size = Vector2(38, 34)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.modulate = theme.get("accent", Color(0.9, 0.9, 0.95))
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = theme.get("panel", Color(0.18, 0.16, 0.14, 0.96)).darkened(0.08)
	close_style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	close_style.border_width_left = 2
	close_style.border_width_top = 2
	close_style.border_width_right = 2
	close_style.border_width_bottom = 2
	close_style.corner_radius_top_left = 10
	close_style.corner_radius_top_right = 10
	close_style.corner_radius_bottom_right = 10
	close_style.corner_radius_bottom_left = 10
	var close_hover := close_style.duplicate()
	close_hover.bg_color = theme.get("panel", Color(0.18, 0.16, 0.14, 0.96)).lightened(0.08)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.add_theme_stylebox_override("pressed", close_style)
	close_btn.add_theme_stylebox_override("focus", close_hover)
	ArtRegistry.apply_button_icon(close_btn, "back", true, "关闭")
	close_btn.pressed.connect(func(): overlay.queue_free())
	close_btn.position = Vector2(988, 10)
	panel.add_child(close_btn)

func _populate_stats_panel(content: VBoxContainer) -> void:
	var summary = GameState.get_meta_progress_summary()
	var class_names = ["医生", "黑客", "商人", "农民", "流浪者"]

	var overview = Label.new()
	overview.text = "历史最高层数: %d    累计通关: %d    已解锁成就: %d/%d" % [
		summary.get("highest_floor", 0),
		summary.get("total_wins", 0),
		summary.get("achievement_count", 0),
		summary.get("total_achievement_count", 0)
	]
	overview.add_theme_font_size_override("font_size", 24)
	overview.modulate = Color(0.88, 0.88, 0.82)
	overview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(overview)

	var clear_title = Label.new()
	clear_title.text = "职业首通"
	clear_title.add_theme_font_size_override("font_size", 22)
	clear_title.modulate = Color(0.8, 0.85, 0.95)
	content.add_child(clear_title)

	var class_clear_box = HBoxContainer.new()
	class_clear_box.add_theme_constant_override("separation", 18)
	content.add_child(class_clear_box)

	var first_clears: Dictionary = summary.get("class_first_clears", {})
	for i in range(class_names.size()):
		var tag = Label.new()
		var cleared = bool(first_clears.get(str(i), false))
		tag.text = "%s %s" % [class_names[i], "✅" if cleared else "⬜"]
		tag.add_theme_font_size_override("font_size", 20)
		tag.modulate = Color(0.72, 0.95, 0.72) if cleared else Color(0.5, 0.5, 0.56)
		class_clear_box.add_child(tag)

	var collection = Label.new()
	collection.text = "装备发现: %d/%d    事件发现: %d" % [
		summary.get("discovered_item_count", 0),
		summary.get("total_item_count", 0),
		summary.get("discovered_event_count", 0)
	]
	collection.add_theme_font_size_override("font_size", 22)
	collection.modulate = Color(0.85, 0.82, 0.68)
	content.add_child(collection)

	var achievement_title = Label.new()
	achievement_title.text = "史册功业"
	achievement_title.add_theme_font_size_override("font_size", 22)
	achievement_title.modulate = Color(0.8, 0.85, 0.95)
	content.add_child(achievement_title)

	for achievement in GameState.get_achievement_status():
		var entry = Label.new()
		var unlocked = bool(achievement.get("unlocked", false))
		entry.text = "%s %s: %s" % ["✅" if unlocked else "⬜", achievement.get("name", ""), achievement.get("desc", "")]
		entry.add_theme_font_size_override("font_size", 18)
		entry.modulate = Color(0.75, 0.95, 0.75) if unlocked else Color(0.55, 0.55, 0.6)
		content.add_child(entry)

func _populate_upgrade_panel(content: VBoxContainer) -> void:
	var theme = GameState.get_era_theme()
	var estimates := GameState.get_meta_full_unlock_clear_estimates()
	var summary = Label.new()
	summary.text = "当前传承点: %d / 全满约 %d    秦通关+%d｜宋+%d｜中国+%d\n筹备进度：%s" % [
		GameState.memory_cores,
		int(estimates.get("total_cost", 0)),
		int(estimates.get("qin_reward", 0)),
		int(estimates.get("song_reward", 0)),
		int(estimates.get("china_reward", 0)),
		GameState.get_meta_upgrade_stage_text()
	]
	summary.add_theme_font_size_override("font_size", 24)
	summary.modulate = theme.get("title", Color(0.88, 0.92, 1.0))
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(summary)

	var hint = Label.new()
	hint.text = "兵马未动，粮草先行。四座营帐承载局外成长：粮仓保稳定，军械库补构筑，演武场练布局，宗祠承传承。"
	hint.add_theme_font_size_override("font_size", 17)
	hint.modulate = theme.get("accent", Color(0.7, 0.74, 0.82)).lerp(Color(0.72, 0.72, 0.76, 1.0), 0.35)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	var categories := ["粮仓", "军械库", "演武场", "宗祠"]
	var grouped: Dictionary = {}
	for category in categories:
		grouped[category] = []
	for upgrade in GameState.get_meta_upgrade_definitions():
		var category := str(upgrade.get("category", "其他"))
		if not grouped.has(category):
			grouped[category] = []
		(grouped[category] as Array).append(upgrade)

	for category in categories:
		var upgrades: Array = grouped.get(category, [])
		if not upgrades.is_empty():
			_add_meta_upgrade_section(content, category, upgrades)

func _populate_settings_panel(content: VBoxContainer) -> void:
	var intro = Label.new()
	intro.text = "全局系统设置。这里修改后会写入存档，并跟随主菜单、地图、战斗等界面。"
	intro.add_theme_font_size_override("font_size", 22)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.86, 0.86, 0.80)
	content.add_child(intro)

	var status = Label.new()
	status.name = "SettingsStatus"
	status.text = GameState.get_settings_status_text()
	status.add_theme_font_size_override("font_size", 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.modulate = Color(0.92, 0.84, 0.70)
	content.add_child(status)

	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	content.add_child(row)

	var mute_btn = Button.new()
	mute_btn.text = "音效开关"
	mute_btn.custom_minimum_size = Vector2(180, 52)
	mute_btn.add_theme_font_size_override("font_size", 20)
	ArtRegistry.apply_button_icon(mute_btn, "sound", false, "音效开关")
	row.add_child(mute_btn)

	var speed_btn = Button.new()
	speed_btn.text = "速度切换"
	speed_btn.custom_minimum_size = Vector2(180, 52)
	speed_btn.add_theme_font_size_override("font_size", 20)
	ArtRegistry.apply_button_icon(speed_btn, "settings", false, "速度切换")
	row.add_child(speed_btn)

	var reset_btn = Button.new()
	reset_btn.text = "恢复默认"
	reset_btn.custom_minimum_size = Vector2(180, 52)
	reset_btn.add_theme_font_size_override("font_size", 20)
	ArtRegistry.apply_button_icon(reset_btn, "back", false, "恢复默认")
	row.add_child(reset_btn)

	var help = Label.new()
	help.text = "已接入：音效开关、战斗演出速度、默认恢复、跨页面跟随、下次启动恢复。\n建议后续再补：全屏/窗口、文本密度、减少闪光与屏幕震动、键位查看。"
	help.add_theme_font_size_override("font_size", 18)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.modulate = Color(0.72, 0.72, 0.76)
	content.add_child(help)

	var refresh_status := func():
		if is_instance_valid(status):
			status.text = GameState.get_settings_status_text()

	mute_btn.pressed.connect(func():
		GameState.toggle_audio_muted()
		refresh_status.call()
	)
	speed_btn.pressed.connect(func():
		GameState.cycle_battle_speed()
		refresh_status.call()
	)
	reset_btn.pressed.connect(func():
		GameState.reset_user_settings()
		refresh_status.call()
	)

func _populate_era_panel(content: VBoxContainer) -> void:
	var theme = GameState.get_era_theme()
	var summary = Label.new()
	summary.text = "%s 当前时代卷：%s" % [_get_era_badge(), GameState.get_current_era_definition().get("name", "秦")]
	summary.add_theme_font_size_override("font_size", 24)
	summary.modulate = theme.get("title", Color(0.92, 0.9, 0.82))
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(summary)

	var hint = Label.new()
	hint.text = "当前时代卷已接入主菜单、地图、商队、事件、Boss 标题、节点倾向与基础规则偏置。后续再补专属 Boss 行为与更深的章节内容。"
	hint.add_theme_font_size_override("font_size", 16)
	hint.modulate = theme.get("accent", Color(0.68, 0.72, 0.8)).lerp(Color(0.7, 0.72, 0.76, 1.0), 0.3)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)

	for era in GameState.get_era_definitions():
		_add_era_row(content, era)

func _add_era_row(content: VBoxContainer, era: Dictionary) -> void:
	var current_theme = GameState.get_era_theme()
	var row = VBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	content.add_child(row)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(930, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(panel)

	var style = StyleBoxFlat.new()
	var selected = str(era.get("id", "")) == GameState.selected_era_id
	style.bg_color = current_theme.get("panel", Color(0.20, 0.16, 0.12, 0.96)) if selected else Color(0.14, 0.15, 0.19, 0.94)
	style.border_color = current_theme.get("accent", Color(0.84, 0.68, 0.38, 0.96)) if selected else Color(0.42, 0.46, 0.54, 0.9)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)

	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)

	var head = HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	inner.add_child(head)

	var title = Label.new()
	var badge = "〔秦卷〕"
	match str(era.get("id", "")):
		"song":
			badge = "〔宋卷〕"
		"china":
			badge = "〔终局〕"
	title.text = "%s【%s】%s  |  %s" % [badge, era.get("name", ""), era.get("title", ""), era.get("summary", "")]
	title.custom_minimum_size = Vector2(760, 0)
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = current_theme.get("title", Color(0.96, 0.9, 0.74)) if selected else Color(0.88, 0.88, 0.84)
	head.add_child(title)

	var select_btn = Button.new()
	select_btn.text = "已选定" if selected else "选定"
	select_btn.custom_minimum_size = Vector2(92, 34)
	select_btn.disabled = selected
	var select_style := StyleBoxFlat.new()
	select_style.bg_color = current_theme.get("panel", Color(0.20, 0.16, 0.12, 0.96)).darkened(0.06)
	select_style.border_color = current_theme.get("accent", Color(0.84, 0.68, 0.38, 0.96))
	select_style.border_width_left = 2
	select_style.border_width_top = 2
	select_style.border_width_right = 2
	select_style.border_width_bottom = 2
	select_style.corner_radius_top_left = 10
	select_style.corner_radius_top_right = 10
	select_style.corner_radius_bottom_left = 10
	select_style.corner_radius_bottom_right = 10
	var select_hover := select_style.duplicate()
	select_hover.bg_color = current_theme.get("panel", Color(0.20, 0.16, 0.12, 0.96)).lightened(0.08)
	select_btn.add_theme_stylebox_override("normal", select_style)
	select_btn.add_theme_stylebox_override("hover", select_hover)
	select_btn.add_theme_stylebox_override("pressed", select_style)
	select_btn.add_theme_stylebox_override("focus", select_hover)
	select_btn.pressed.connect(_on_era_selected.bind(str(era.get("id", ""))))
	head.add_child(select_btn)

	var body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 17)
	body.modulate = current_theme.get("accent", Color(0.82, 0.84, 0.9)).lerp(Color(0.86, 0.86, 0.9, 1.0), 0.35)
	body.text = "正面规则【%s】：%s\n负面规则【%s】：%s\n战斗倾向：%s\nBoss 样板：%s\nUI 气质：%s" % [
		era.get("buff_name", ""),
		era.get("buff_desc", ""),
		era.get("debuff_name", ""),
		era.get("debuff_desc", ""),
		era.get("playstyle", ""),
		era.get("boss_rule", ""),
		era.get("ui_note", "")
	]
	inner.add_child(body)

func _on_era_selected(era_id: String) -> void:
	GameState.set_selected_era(era_id)
	if current_state == State.MENU:
		_show_main_menu()
		_show_meta_panel("eras")
		return
	_refresh_era_panel()

func _refresh_era_panel() -> void:
	if current_ui == null:
		return
	var theme = GameState.get_era_theme()
	var overlay = current_ui.get_node_or_null("MetaOverlay")
	if overlay == null:
		return
	var content = overlay.find_child("MetaScrollContent", true, false)
	if content == null or not (content is VBoxContainer):
		return
	for child in content.get_children():
		child.queue_free()
	var title = Label.new()
	title.text = "%s 🏮 时代卷" % _get_era_badge()
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = theme.get("title", Color(0.95, 0.9, 0.75))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	_populate_era_panel(content)
	var hint_label = current_ui.get_node_or_null("HintLabel")
	if hint_label:
		hint_label.text = "操作：Q=天  W=人  E=地  |  %s" % GameState.get_current_era_status_text()

func _add_meta_upgrade_section(content: VBoxContainer, title_text: String, upgrades: Array) -> void:
	var theme = GameState.get_era_theme()
	var title = Label.new()
	title.text = "%s（%d）" % [_get_meta_camp_title(title_text), upgrades.size()]
	title.add_theme_font_size_override("font_size", 23)
	title.modulate = theme.get("title", Color(0.92, 0.84, 0.62))
	title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	title.add_theme_constant_override("outline_size", 1)
	content.add_child(title)

	var desc = Label.new()
	desc.text = _get_meta_camp_desc(title_text)
	desc.add_theme_font_size_override("font_size", 15)
	desc.modulate = theme.get("accent", Color(0.74, 0.70, 0.58)).lerp(Color(0.76, 0.76, 0.80, 1.0), 0.32)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(desc)

	if upgrades.is_empty():
		var empty = Label.new()
		empty.text = "暂无"
		empty.add_theme_font_size_override("font_size", 16)
		empty.modulate = theme.get("accent", Color(0.5, 0.52, 0.58)).lerp(Color(0.46, 0.46, 0.5, 1.0), 0.45)
		content.add_child(empty)
		return

	for upgrade in upgrades:
		_add_meta_upgrade_row(content, upgrade)

func _get_meta_camp_title(category: String) -> String:
	match category:
		"粮仓":
			return "粮仓｜粮草先行"
		"军械库":
			return "军械库｜器甲整肃"
		"演武场":
			return "演武场｜阵法演练"
		"宗祠":
			return "宗祠｜百代传承"
		_:
			return category

func _get_meta_camp_desc(category: String) -> String:
	match category:
		"粮仓":
			return "开局资源与命数容错，负责让一局起步更稳。"
		"军械库":
			return "器物、行囊与兵锋相关筹备，负责让构筑更容易成型。"
		"演武场":
			return "布局槽、冷却与阵册相关筹备，负责让战斗选择更顺手。"
		"宗祠":
			return "朝代通关后的传承权限，负责解锁特殊规则、终式与角色。"
		_:
			return "出征前的长期筹备。"

func _add_meta_upgrade_row(content: VBoxContainer, upgrade: Dictionary) -> void:
	var theme = GameState.get_era_theme()
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(930, 136)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var upgrade_id = str(upgrade.get("id", ""))
	var current_count = GameState.get_meta_upgrade_count(upgrade_id)
	var max_count = int(upgrade.get("max", 1))
	var owned = current_count >= max_count
	var unlocked = GameState.is_meta_upgrade_unlocked(upgrade_id)
	var cost = GameState.get_meta_upgrade_next_cost(upgrade_id)
	var can_buy = GameState.can_purchase_meta_upgrade(upgrade_id)
	var missing = maxi(cost - GameState.memory_cores, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.20, 0.16, 0.12, 0.96)).darkened(0.04)
	if not unlocked:
		style.border_color = Color(0.38, 0.39, 0.44, 0.92)
	elif owned:
		style.border_color = theme.get("good", Color(0.68, 0.95, 0.72))
	else:
		style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	content.add_child(panel)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -16
	row.offset_top = 12
	row.offset_bottom = -12
	panel.add_child(row)

	var status_text = "已满"
	if not unlocked:
		status_text = GameState.get_meta_upgrade_unlock_text(int(upgrade.get("stage", 0)))
	elif not owned:
		status_text = "可筹备" if can_buy else "还差%d传承点" % missing

	var info = Label.new()
	var next_level = mini(current_count + 1, max_count)
	var cost_text = "已完成" if owned else "%d传承点" % cost
	var unlock_text = GameState.get_meta_upgrade_unlock_text(int(upgrade.get("stage", 0)))
	info.text = "%s  Lv.%d/%d  [%s]\n当前：%s\n下级：%s\n消耗：%s｜解锁：%s" % [
		upgrade.get("name", ""),
		current_count,
		max_count,
		status_text,
		GameState.get_meta_upgrade_effect_text(upgrade_id, current_count),
		"已到上限" if owned else GameState.get_meta_upgrade_effect_text(upgrade_id, next_level),
		cost_text,
		unlock_text
	]
	info.tooltip_text = str(upgrade.get("desc", ""))
	info.custom_minimum_size = Vector2(720, 104)
	info.add_theme_font_size_override("font_size", 17)
	if not unlocked:
		info.modulate = Color(0.52, 0.53, 0.58, 0.95)
	elif owned:
		info.modulate = theme.get("good", Color(0.68, 0.95, 0.72))
	elif can_buy:
		info.modulate = theme.get("title", Color(0.95, 0.86, 0.58))
	else:
		info.modulate = theme.get("accent", Color(0.55, 0.58, 0.66)).lerp(Color(0.54, 0.56, 0.6, 1.0), 0.35)
	row.add_child(info)

	var buy_btn = Button.new()
	buy_btn.text = "已满" if owned else ("未开" if not unlocked else "筹备")
	buy_btn.tooltip_text = status_text
	buy_btn.custom_minimum_size = Vector2(74, 34)
	buy_btn.size = Vector2(74, 34)
	buy_btn.add_theme_font_size_override("font_size", 15)
	buy_btn.modulate = theme.get("accent", Color(0.82, 0.72, 0.48))
	buy_btn.disabled = owned or not can_buy
	var buy_style := StyleBoxFlat.new()
	buy_style.bg_color = theme.get("panel", Color(0.20, 0.16, 0.12, 0.96)).darkened(0.08)
	buy_style.border_color = theme.get("accent", Color(0.82, 0.72, 0.48))
	buy_style.border_width_left = 2
	buy_style.border_width_top = 2
	buy_style.border_width_right = 2
	buy_style.border_width_bottom = 2
	buy_style.corner_radius_top_left = 10
	buy_style.corner_radius_top_right = 10
	buy_style.corner_radius_bottom_left = 10
	buy_style.corner_radius_bottom_right = 10
	buy_btn.add_theme_stylebox_override("normal", buy_style)
	buy_btn.add_theme_stylebox_override("hover", buy_style)
	buy_btn.add_theme_stylebox_override("pressed", buy_style)
	buy_btn.add_theme_stylebox_override("focus", buy_style)
	buy_btn.pressed.connect(_on_meta_upgrade_pressed.bind(upgrade_id))
	row.add_child(buy_btn)

func _on_meta_upgrade_pressed(upgrade_id: String) -> void:
	var result = GameState.purchase_meta_upgrade(upgrade_id)
	if result.get("success", false):
		_refresh_meta_upgrade_panel()

func _refresh_meta_upgrade_panel() -> void:
	if current_ui == null:
		return
	var theme = GameState.get_era_theme()
	var overlay = current_ui.get_node_or_null("MetaOverlay")
	if overlay == null:
		return
	var content = overlay.find_child("MetaScrollContent", true, false)
	if content == null or not (content is VBoxContainer):
		return
	for child in content.get_children():
		child.queue_free()
	var title = Label.new()
	title.text = "%s 兵马未动｜行前筹备（传承升级）" % _get_era_badge()
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = theme.get("title", Color(0.95, 0.9, 0.75))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	_populate_upgrade_panel(content)

func _add_codex_entry_panel(content: VBoxContainer, text: String, seen: bool, tint: Color) -> void:
	var theme = GameState.get_era_theme()
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(930, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.20, 0.16, 0.12, 0.96)).darkened(0.04) if seen else Color(0.14, 0.14, 0.16, 0.92)
	style.border_color = tint if seen else Color(0.38, 0.38, 0.42, 0.95)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	content.add_child(panel)

	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.modulate = tint if seen else Color(0.5, 0.5, 0.54)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 16
	label.offset_right = -16
	label.offset_top = 12
	label.offset_bottom = -12
	panel.add_child(label)

func _populate_codex_panel(content: VBoxContainer) -> void:
	var theme = GameState.get_era_theme()
	var discovered_items = GameState.get_discovered_items()
	var discovered_events = GameState.get_discovered_events()

	_add_codex_lore_section(content)

	var era_combo_title = Label.new()
	era_combo_title.text = "时代秘布局"
	era_combo_title.add_theme_font_size_override("font_size", 24)
	era_combo_title.modulate = theme.get("title", Color(0.95, 0.86, 0.68))
	era_combo_title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	era_combo_title.add_theme_constant_override("outline_size", 1)
	content.add_child(era_combo_title)

	var era_combo_hint = Label.new()
	era_combo_hint.text = "当前时代卷独有的布局，会在开局选择和专属异闻中持续影响本局构筑。"
	era_combo_hint.add_theme_font_size_override("font_size", 16)
	era_combo_hint.modulate = theme.get("accent", Color(0.72, 0.74, 0.82))
	era_combo_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(era_combo_hint)

	var combo_db = _get_combo_database()
	for combo in combo_db.get_all_combos():
		if combo.get("exclusive_era") == null or str(combo.exclusive_era) == "":
			continue
		if str(combo.exclusive_era) != GameState.selected_era_id:
			continue
		var source_text = _get_era_combo_source_text(str(combo.id))
		var upgrade_path_text = GameState.get_combo_upgrade_path_text(str(combo.id))
		var combo_text = "✦ %s  %s\n%s | %s\n%s\n%s\n来源：%s" % [
			ComboData.sequence_to_string(combo.sequence),
			ComboDatabase.get_era_combo_name(combo.name),
			ComboDatabase.get_era_role_text(combo.role),
			GameState.get_era_combo_bonus_text(str(combo.id), str(combo.effect_type)),
			combo.description,
			upgrade_path_text,
			source_text
		]
		_add_codex_entry_panel(content, combo_text, true, theme.get("title", Color(0.9, 0.9, 0.84)))

	var hidden_combo_title = Label.new()
	hidden_combo_title.text = "玄机布局"
	hidden_combo_title.add_theme_font_size_override("font_size", 24)
	hidden_combo_title.modulate = Color(0.88, 0.9, 0.98)
	hidden_combo_title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	hidden_combo_title.add_theme_constant_override("outline_size", 1)
	content.add_child(hidden_combo_title)

	var hidden_combo_hint = Label.new()
	hidden_combo_hint.text = "器物联动、状态依赖与后续可研习布局不会出现在开局携带列表；满足条件后会在战斗或成长中显现。"
	hidden_combo_hint.add_theme_font_size_override("font_size", 16)
	hidden_combo_hint.modulate = theme.get("accent", Color(0.72, 0.74, 0.82))
	hidden_combo_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hidden_combo_hint)

	var hidden_catalog = ComboDatabase.get_hidden_combo_catalog()
	for category_name in ["器物联动布局", "状态依赖布局"]:
		var category_title = Label.new()
		category_title.text = category_name
		category_title.add_theme_font_size_override("font_size", 20)
		category_title.modulate = Color(0.86, 0.88, 0.96)
		content.add_child(category_title)
		for entry in hidden_catalog:
			if str(entry.get("category", "")) != category_name:
				continue
			var hidden_combo = combo_db.get_combo_by_id(str(entry.get("id", "")))
			if hidden_combo == null:
				continue
			var hidden_text = "✦ %s  %s\n触发：%s\n%s" % [
				ComboData.sequence_to_string(hidden_combo.sequence),
				ComboDatabase.get_era_combo_name(hidden_combo.name),
				str(entry.get("requires", "")),
				hidden_combo.description
			]
			_add_codex_entry_panel(content, hidden_text, true, Color(0.82, 0.9, 0.98))

	var locked_combos: Array = []
	for combo in combo_db.get_all_combos():
		if int(combo.unlock_level) <= int(ComboDatabase.UnlockLevel.BASIC):
			continue
		if combo.id in ComboDatabase.HIDDEN_COMBO_IDS:
			continue
		if str(combo.exclusive_class) != "":
			continue
		if str(combo.exclusive_era) != "":
			continue
		locked_combos.append(combo)
	if not locked_combos.is_empty():
		var locked_title = Label.new()
		locked_title.text = "未解锁布局"
		locked_title.add_theme_font_size_override("font_size", 20)
		locked_title.modulate = Color(0.94, 0.86, 0.74)
		content.add_child(locked_title)
		for combo in locked_combos:
			var locked_text = "✦ %s  %s\n需要更高布局研习等级\n%s" % [
				ComboData.sequence_to_string(combo.sequence),
				ComboDatabase.get_era_combo_name(combo.name),
				combo.description
			]
			_add_codex_entry_panel(content, locked_text, true, Color(0.94, 0.86, 0.74))

	var event_title = Label.new()
	event_title.text = "异闻录"
	event_title.add_theme_font_size_override("font_size", 24)
	event_title.modulate = Color(0.92, 0.82, 0.68)
	event_title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	event_title.add_theme_constant_override("outline_size", 1)
	content.add_child(event_title)

	for event_data in RandomEventManager.get_event_catalog():
		var seen = discovered_events.has(event_data.get("event_id", ""))
		var rarity = "★" if event_data.get("rarity", "common") == "rare" else "·"
		var event_text = "%s %s" % [rarity, "%s: %s" % [event_data.get("name", ""), event_data.get("description", "")] if seen else "？？？（未发现）"]
		_add_codex_entry_panel(content, event_text, seen, Color(0.88, 0.88, 0.8))

	var item_title = Label.new()
	item_title.text = "器物录"
	item_title.add_theme_font_size_override("font_size", 24)
	item_title.modulate = Color(0.82, 0.88, 0.96)
	item_title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	item_title.add_theme_constant_override("outline_size", 1)
	content.add_child(item_title)

	var era_item_title = Label.new()
	era_item_title.text = "时代秘器物"
	era_item_title.add_theme_font_size_override("font_size", 24)
	era_item_title.modulate = theme.get("title", Color(0.95, 0.86, 0.68))
	era_item_title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	era_item_title.add_theme_constant_override("outline_size", 1)
	content.add_child(era_item_title)

	var era_item_hint = Label.new()
	era_item_hint.text = "当前时代卷独有的器物，只会在对应时代的商队与器物池中出现。"
	era_item_hint.add_theme_font_size_override("font_size", 16)
	era_item_hint.modulate = theme.get("accent", Color(0.72, 0.74, 0.82))
	era_item_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(era_item_hint)

	for item_id in GameState.ITEMS.keys():
		var era_item = GameState.ITEMS[item_id]
		if str(era_item.get("era", "")) != GameState.selected_era_id:
			continue
		var era_seen = discovered_items.has(item_id)
		var era_item_text = "%s" % (
			"%s\n%s" % [GameState.get_item_display_name(era_item), GameState.get_item_display_description(era_item)]
			if era_seen else "？？？（未发现）"
		)
		_add_codex_entry_panel(content, era_item_text, era_seen, theme.get("title", Color(0.88, 0.88, 0.84)))

	for item_id in GameState.ITEMS.keys():
		var item = GameState.ITEMS[item_id]
		if str(item.get("era", "")) == GameState.selected_era_id:
			continue
		var seen_item = discovered_items.has(item_id)
		var item_text = "%s" % ("%s\n%s" % [GameState.get_item_display_name(item), GameState.get_item_display_description(item)] if seen_item else "？？？（未发现）")
		_add_codex_entry_panel(content, item_text, seen_item, Color(0.84, 0.88, 0.96))

func _add_codex_lore_section(content: VBoxContainer) -> void:
	var theme = GameState.get_era_theme()
	var lore_title = Label.new()
	lore_title.text = "卷首"
	lore_title.add_theme_font_size_override("font_size", 24)
	lore_title.modulate = theme.get("title", Color(0.95, 0.86, 0.68))
	lore_title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	lore_title.add_theme_constant_override("outline_size", 1)
	content.add_child(lore_title)

	for entry in _get_codex_lore_entries():
		_add_codex_entry_panel(content, str(entry.get("text", "")), true, entry.get("tint", theme.get("title", Color(0.9, 0.9, 0.84))))

	var divider = HSeparator.new()
	divider.modulate = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	content.add_child(divider)

func _get_codex_lore_entries() -> Array[Dictionary]:
	var theme = GameState.get_era_theme()
	return [
		{
			"text": "《百代异闻录》原是一部记录历史缝隙的古卷。百代同震之后，秦、宋与终局残响开始互相污染，书页化作一座反复重组的历史之塔。\n\n残卷只余一句：天不自明，人不自定，地不自守。入卷者，补其缺。",
			"tint": theme.get("title", Color(0.95, 0.86, 0.68))
		},
		{
			"text": "执卷人不是改写历史的神。你继承一件传家宝，带着开局布局入卷，在战斗、商队、营寨与异闻之间选择路径。每一次失败都会让古卷重排，只留下被记住的经验。",
			"tint": Color(0.86, 0.9, 0.98)
		},
		{
			"text": "天势是大局与命数，人势是谋略与判断，地势是根基与承受。战斗中的天、人、地不是单纯猜拳，而是你与势影之间的试探：顺势、用人，或守地。",
			"tint": Color(0.86, 0.94, 0.82)
		},
		{
			"text": "秦卷重军功与法度，宋卷重商路与边患，中国卷是百代同震后的终局残响。击败灾主不代表改写历史，只代表这一卷暂时闭合。",
			"tint": Color(0.92, 0.84, 0.72)
		}
	]

func _get_era_combo_source_text(combo_id: String) -> String:
	match combo_id:
		"qin_tiger_push":
			return "秦卷开局可选；专属异闻【军功授爵】会免费强化 1 级。"
		"song_trade_turn":
			return "宋卷开局可选；专属异闻【市舶兴旺】会免费强化 1 级。"
		"china_unity_echo":
			return "中国卷开局可选；专属异闻【龙脉回响】会免费强化 1 级。"
		_:
			return "当前仅能在对应时代卷中接触。"

func _resume_saved_run() -> void:
	if not GameState.has_active_run():
		return

	RandomEventManager.reset_state()
	var checkpoint = GameState.get_checkpoint_scene()
	match checkpoint:
		"shop":
			_show_shop()
		"rest":
			_show_rest_point()
		_:
			_show_map()

func _show_character_select():
	DebugLog.log("Showing character select")
	_change_state(State.CHARACTER_SELECT)

	var select_scene = load("res://scenes/ui/character_select.tscn").instantiate()

	# 连接信号
	if select_scene.has_signal("character_selected"):
		select_scene.character_selected.connect(_on_character_selected)
	if select_scene.has_signal("back_pressed"):
		select_scene.back_pressed.connect(_show_main_menu)

	_add_ui(select_scene)

func _on_character_selected(class_id: int):
	DebugLog.log("Character selected: ", class_id)

	GameState.reset_game()
	RandomEventManager.reset_state()
	GameState.player_class = class_id

	match class_id:
		0: GameState.player_max_hp = 9;  GameState.player_attack = 2  # 医生
		1: GameState.player_max_hp = 6;  GameState.player_attack = 4  # 黑客
		2: GameState.player_max_hp = 7;  GameState.player_attack = 2  # 商人
		3: GameState.player_max_hp = 12; GameState.player_attack = 2  # 农民
		4: GameState.player_max_hp = 8;  GameState.player_attack = 3  # 流浪者

	GameState.player_hp = GameState.player_max_hp
	GameState.player_shield = 0

	# 初始化角色专属连招
	GameState.init_player_class(class_id)

	# 初始化角色技能
	GameState.init_class_abilities(class_id)
	GameState.apply_meta_start_bonuses()

	# 加载连招选择场景
	var combo_scene = load("res://scenes/ui/combo_select.tscn").instantiate()

	# 连接完成信号
	if combo_scene.has_signal("combo_selection_complete"):
		combo_scene.combo_selection_complete.connect(func():
			_generate_map()
			_show_map()
		, CONNECT_DEFERRED)

	# 连接返回信号
	if combo_scene.has_signal("back_pressed"):
		combo_scene.back_pressed.connect(_show_character_select, CONNECT_DEFERRED)

	_add_ui(combo_scene)

func _show_map():
	DebugLog.log("Showing map, floor: ", GameState.current_floor)
	_ensure_history_map_data()
	if GameState.should_show_current_major_layer_debuff():
		_show_major_layer_debuff_gate()
		return
	_change_state(State.MAP)
	_switch_scene_music("menu")
	GameState.save_progress("map")

	DebugLog.log("Loading map_scene.tscn...")
	var map = load("res://scenes/ui/map_scene.tscn").instantiate()
	DebugLog.log("Map scene instantiated: ", map)

	# 更新标题 - 显示当前层（从下往上）
	var title_label = map.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = _get_era_map_title()
	else:
		DebugLog.log("ERROR: TitleLabel not found!")

	# 更新状态栏
	var status_label = map.get_node_or_null("StatusLabel")
	if status_label:
		var class_names = ["医生", "黑客", "商人", "农民", "流浪者"]
		var hp_bar = ""
		for i in range(GameState.player_max_hp):
			hp_bar += "❤️" if i < GameState.player_hp else "🖤"

		var status_text = "%s %s 💰%d" % [class_names[GameState.player_class], hp_bar, GameState.player_gold]
		if GameState.player_shield > 0:
			status_text += " 🛡️%d" % GameState.player_shield
		status_text += "  🏮%s" % GameState.get_current_era_definition().get("name", "秦")

		var layer_hints = ["🌱 初入大层", "🔥 压力抬升", "💀 终局压境"]
		var hint = layer_hints[GameState.get_major_layer_index()]
		status_text += "  %s" % hint

		status_label.text = status_text
	else:
		DebugLog.log("ERROR: StatusLabel not found!")

	# 地图场景现在使用 MapContainer 和 ScrollContainer
	# 地图节点由 MapScene._create_tree_map() 自动创建
	# 这里只需要确保返回按钮连接正确

	var back_btn = map.get_node_or_null("BackButton")
	if back_btn:
		back_btn.pressed.connect(func(): _show_main_menu())

	# 连接地图节点选择信号
	map.node_selected.connect(_on_map_node_selected)
	map.back_to_menu_pressed.connect(func(): _show_main_menu())

	DebugLog.log("Calling _add_ui with map...")
	_add_ui(map)
	DebugLog.log("_show_map completed")

func _show_major_layer_debuff_gate() -> void:
	_change_state(State.MAP)
	_switch_scene_music("menu")
	GameState.save_progress("map")
	var info := GameState.get_current_major_layer_debuff()
	var theme = GameState.get_era_theme()
	var gate := Control.new()
	gate.name = "MajorLayerDebuffGate"
	gate.custom_minimum_size = Vector2(1280, 720)

	var bg := ColorRect.new()
	bg.color = theme.get("bg", Color(0.12, 0.10, 0.08, 1.0)).darkened(0.08)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	gate.add_child(bg)

	var panel := PanelContainer.new()
	panel.position = Vector2(275, 118)
	panel.custom_minimum_size = Vector2(730, 462)
	var style := StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.18, 0.16, 0.12, 0.96)).darkened(0.06)
	style.border_color = theme.get("bad", Color(1.0, 0.42, 0.32, 1.0))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	gate.add_child(panel)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(662, 402)
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title := Label.new()
	title.text = "%s · %s" % [str(info.get("layer_title", "第一大层")), str(info.get("layer_stage", ""))]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = theme.get("title", Color(0.96, 0.86, 0.62, 1.0))
	box.add_child(title)

	var range_label := Label.new()
	range_label.text = "%s卷｜小层 %s" % [str(info.get("era_name", "秦")), str(info.get("floor_range", "1-19"))]
	range_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	range_label.add_theme_font_size_override("font_size", 18)
	range_label.modulate = Color(0.76, 0.72, 0.64, 1.0)
	box.add_child(range_label)

	var debuff_name := Label.new()
	debuff_name.text = "时代负面：%s" % str(info.get("debuff_name", "时代压力"))
	debuff_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debuff_name.add_theme_font_size_override("font_size", 28)
	debuff_name.modulate = theme.get("bad", Color(1.0, 0.48, 0.38, 1.0)).lightened(0.08)
	box.add_child(debuff_name)

	var desc := Label.new()
	desc.text = "%s\n\n%s\n\n%s" % [
		str(info.get("debuff_desc", "")),
		str(info.get("layer_desc", "")),
		str(info.get("mechanical_text", ""))
	]
	desc.custom_minimum_size = Vector2(650, 152)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 20)
	desc.modulate = Color(0.86, 0.82, 0.72, 1.0)
	box.add_child(desc)

	var note := Label.new()
	note.text = "关闭后进入本大层地图。该提示本大层只出现一次。"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 16)
	note.modulate = Color(0.58, 0.56, 0.50, 1.0)
	box.add_child(note)

	var btn := Button.new()
	btn.text = "我知道了，进入地图"
	btn.custom_minimum_size = Vector2(360, 62)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 22)
	btn.modulate = Color(1.0, 0.88, 0.62, 1.0)
	_style_event_decision_button(btn, false, "continue")
	btn.pressed.connect(func():
		GameState.mark_current_major_layer_debuff_seen()
		GameState.save_progress("map")
		_show_map()
	)
	box.add_child(btn)

	_add_ui(gate)

func _ensure_history_map_data() -> void:
	if GameState.max_floors < GameState.TOTAL_SMALL_FLOORS:
		GameState.max_floors = GameState.TOTAL_SMALL_FLOORS
	if GameState.map_data.is_empty():
		_generate_map()
		return
	if GameState.map_data.size() != GameState.max_floors:
		var preserved_sized_floor = clamp(GameState.current_floor, 0, GameState.max_floors - 1)
		DebugLog.log("Regenerating map for current floor count, preserving floor: ", preserved_sized_floor)
		_generate_map()
		GameState.current_floor = preserved_sized_floor
		for floor_nodes in GameState.map_data:
			for node in floor_nodes:
				node.accessible = false
		if GameState.current_floor < GameState.map_data.size():
			for node in GameState.map_data[GameState.current_floor]:
				node.accessible = true
		return
	var first_floor: Array = GameState.map_data[0]
	if first_floor.is_empty():
		_generate_map()
		return
	var first_node: Dictionary = first_floor[0]
	if first_node.has("event_title") and first_node.has("route_name") and first_node.has("next_indices") and first_node.has("map_x_offset"):
		return
	var preserved_floor = clamp(GameState.current_floor, 0, GameState.max_floors - 1)
	DebugLog.log("Migrating old map data to historical route map, preserving floor: ", preserved_floor)
	_generate_map()
	GameState.current_floor = preserved_floor
	for floor_nodes in GameState.map_data:
		for node in floor_nodes:
			node.accessible = false
	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = true

func _on_map_node_selected(node_index: int):
	DebugLog.log("Node selected: ", node_index)

	if GameState.current_floor >= GameState.map_data.size():
		return

	var node = GameState.map_data[GameState.current_floor][node_index]
	node.visited = true
	_apply_mid_build_checkpoint_bonus(node)

	match node.type:
		0, 4:
			_show_battle(node.type == 4, node)
		1:
			_show_shop()
		2:
			# 休息节点 - 显示完整休息点UI
			_change_state(State.REST_POINT)
			_switch_scene_music("rest")
			GameState.save_progress("rest")
			var rest_point = load("res://scenes/ui/rest_point.tscn").instantiate()
			rest_point.name = "RestPoint"
			rest_point.continue_to_next_floor.connect(_on_rest_point_continue_from_map)
			_add_ui(rest_point)
			DebugLog.log("Rest point displayed from map node")
			return
		3:
			# 事件节点
			_show_event()
			return

func _apply_mid_build_checkpoint_bonus(node: Dictionary) -> void:
	if str(node.get("checkpoint_tier", "")) != "mid_build":
		return
	if bool(node.get("checkpoint_claimed", false)):
		return
	node["checkpoint_claimed"] = true
	match int(node.get("type", 0)):
		0:
			GameState.player_shield += 2
			if GameState.player_hp <= maxi(2, int(ceil(float(GameState.player_max_hp) * 0.40))):
				GameState.player_hp = mini(GameState.player_hp + 1, GameState.player_max_hp)
		1:
			GameState.player_gold += 8
			EventBus.player_gold_changed.emit(GameState.player_gold)
		2:
			GameState.player_hp = mini(GameState.player_hp + 2, GameState.player_max_hp)
			GameState.player_shield += 1
		3:
			GameState.player_gold += 6
			EventBus.player_gold_changed.emit(GameState.player_gold)
			if GameState.player_hp <= maxi(2, int(ceil(float(GameState.player_max_hp) * 0.45))):
				GameState.player_hp = mini(GameState.player_hp + 1, GameState.player_max_hp)
			else:
				GameState.player_shield += 1
		_:
			GameState.player_shield += 1

# ===== 商店系统（稀有度权重 + 类型权重 + 刷新消耗）=====

# 商店刷新消耗
const SHOP_REFRESH_COST: int = 3

func _get_random_shop_items() -> Array[String]:
	return ShopItemPicker.new(GameState).pick_shop_items(3)

func _dedupe_current_shop_items() -> void:
	var unique_items: Array[String] = []
	for item_id_value in GameState.current_shop_items:
		var item_id := str(item_id_value)
		if item_id == "" or item_id in unique_items:
			continue
		if not GameState.ITEMS.has(item_id):
			continue
		if GameState.has_item_anywhere(item_id):
			continue
		unique_items.append(item_id)
	if unique_items.size() < 3:
		for refill_id in _get_random_shop_items():
			if unique_items.size() >= 3:
				break
			if not refill_id in unique_items:
				unique_items.append(refill_id)
	GameState.current_shop_items = unique_items

func _show_shop():
	DebugLog.log("Shop")
	_change_state(State.SHOP)
	_switch_scene_music("shop")
	GameState.set_checkpoint_scene("shop")
	GameState.save_progress("shop")

	if GameState.current_shop_items.is_empty():
		GameState.current_shop_items = _get_random_shop_items()
	else:
		_dedupe_current_shop_items()
		if GameState.current_shop_items.is_empty():
			GameState.current_shop_items = _get_random_shop_items()

	var shop_flow := ShopFlow.new(GameState, SHOP_REFRESH_COST, EventBus)
	var shop := ShopUiBuilder.new(GameState, shop_flow).build({
		"shop_panel_texture": _get_era_shop_panel_texture(),
		"shop_items": GameState.current_shop_items,
		"seal_factory": Callable(self, "_create_era_seal"),
		"shop_title_factory": Callable(self, "_get_era_shop_title"),
		"item_icon_factory": Callable(self, "_get_item_icon_texture"),
		"buy_material_callback": Callable(self, "_buy_material"),
		"buy_item_callback": Callable(self, "_buy_item"),
		"refresh_callback": Callable(self, "_refresh_shop"),
		"back_callback": Callable(self, "_show_map"),
		"next_callback": Callable(self, "_advance_from_shop")
	})
	_update_inventory_display(shop)
	_add_ui(shop)

func _update_inventory_display(shop: Control):
	"""更新装备栏和背包显示"""
	# 清除旧的物品显示
	for child in shop.get_children():
		if child.name.begins_with("EquipItem_") or child.name.begins_with("BackpackItem_") or child.name.begins_with("InvHint_"):
			child.queue_free()

	# 更新标题显示容量
	var equip_title = shop.get_node_or_null("EquipTitle")
	if equip_title:
		equip_title.text = "装备  %d/%d" % [GameState.equipment_slot.size(), GameState.get_current_equipment_slot_limit()]

	var backpack_title_node = shop.get_node_or_null("BackpackTitle")
	if backpack_title_node:
		backpack_title_node.text = "背包  %d/%d" % [GameState.backpack.size(), GameState.get_current_backpack_limit()]

	var start_x = 50
	var equip_y = 458
	var backpack_y = 560

	# ===== 显示装备栏 =====
	if GameState.equipment_slot.is_empty():
		var empty_label = Label.new()
		empty_label.name = "EquipItem_Empty"
		empty_label.text = "空"
		empty_label.position = Vector2(start_x, equip_y)
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.modulate = Color(0.5, 0.5, 0.4)
		shop.add_child(empty_label)
	else:
		for i in range(GameState.equipment_slot.size()):
			var item = GameState.equipment_slot[i]
			var btn = _create_item_button(item, i, "EquipItem_", true, shop)
			btn.position = Vector2(start_x + i * 136, equip_y)
			shop.add_child(btn)

	# ===== 显示背包 =====
	if GameState.backpack.is_empty():
		var empty_label = Label.new()
		empty_label.name = "BackpackItem_Empty"
		empty_label.text = "空"
		empty_label.position = Vector2(start_x, backpack_y)
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.modulate = Color(0.5, 0.5, 0.4)
		shop.add_child(empty_label)
	else:
		for i in range(GameState.backpack.size()):
			var item = GameState.backpack[i]
			var btn = _create_backpack_item_button(item, i, "BackpackItem_", shop)
			btn.position = Vector2(start_x + i * 96, backpack_y)
			shop.add_child(btn)

func _create_item_button(item: Dictionary, index: int, prefix: String, is_equipped: bool, shop: Control) -> Button:
	"""创建设备栏物品按钮"""
	var btn = Button.new()
	btn.name = "%s%d" % [prefix, index]
	btn.custom_minimum_size = Vector2(124, 42)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = GameState.get_era_theme().get("panel", Color(0.18, 0.18, 0.22, 0.94)).darkened(0.06)
	btn_style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	btn_style.set_border_width_all(2)
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("hover", btn_style)
	btn.add_theme_stylebox_override("pressed", btn_style)
	btn.add_theme_color_override("font_outline_color", GameState.get_era_theme().get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	btn.add_theme_constant_override("outline_size", 1)

	match item.rarity:
		"blue": btn.modulate = Color(0.4, 0.5, 0.8)
		"red": btn.modulate = Color(0.8, 0.4, 0.4)
		_: btn.modulate = Color(0.6, 0.6, 0.65)

	btn.text = "%s\n卸" % GameState.get_item_display_name(item)
	btn.tooltip_text = _get_item_detail_tooltip(item, "")
	btn.icon = _get_item_icon_texture(item)
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(func(): _unequip_item_to_backpack(index, shop))
	return btn

func _create_backpack_item_button(item: Dictionary, index: int, prefix: String, shop: Control) -> Button:
	"""创建背包物品按钮"""
	var btn = Button.new()
	btn.name = "%s%d" % [prefix, index]
	btn.custom_minimum_size = Vector2(84, 42)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = GameState.get_era_theme().get("panel", Color(0.18, 0.18, 0.22, 0.94)).darkened(0.06)
	btn_style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	btn_style.set_border_width_all(2)
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("hover", btn_style)
	btn.add_theme_stylebox_override("pressed", btn_style)
	btn.add_theme_color_override("font_outline_color", GameState.get_era_theme().get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	btn.add_theme_constant_override("outline_size", 1)

	match item.rarity:
		"blue": btn.modulate = Color(0.4, 0.5, 0.8)
		"red": btn.modulate = Color(0.8, 0.4, 0.4)
		_: btn.modulate = Color(0.6, 0.6, 0.65)

	btn.text = "%s\n装" % GameState.get_item_display_name(item)
	btn.tooltip_text = _get_item_detail_tooltip(item, "")
	btn.icon = _get_item_icon_texture(item)
	btn.add_theme_font_size_override("font_size", 10)
	btn.pressed.connect(func(): _equip_item_from_backpack(index, shop))
	return btn

func _get_item_detail_tooltip(item: Dictionary, prefix: String = "") -> String:
	var lines: Array[String] = []
	if prefix != "":
		lines.append(prefix)
	lines.append(GameState.get_item_display_name(item))
	var rarity := str(item.get("rarity", "white"))
	var type_text := str(item.get("type", "unknown"))
	lines.append("品秩：%s | 类型：%s" % [rarity, type_text])
	var desc := GameState.get_item_display_description(item)
	if desc != "":
		lines.append(desc)
	if item.has("exclusive_combo") and str(item.get("exclusive_combo", "")) != "":
		var combo_db := _get_combo_database()
		var combo = combo_db.get_combo_by_id(str(item.get("exclusive_combo", ""))) if combo_db != null else null
		if combo != null:
			lines.append("联动布局：%s %s" % [ComboData.sequence_to_string(combo.sequence), _get_combo_name(combo)])
	return "\n".join(lines)

func _get_battle_item_row_text(item: Dictionary) -> String:
	var rarity_text := _get_item_rarity_short_text(str(item.get("rarity", "white")))
	var item_name := GameState.get_item_display_name(item)
	return "%s·%s" % [rarity_text, item_name] if rarity_text != "" else item_name

func _get_item_rarity_short_text(rarity: String) -> String:
	match rarity:
		"red":
			return "红"
		"blue":
			return "蓝"
		"white":
			return "白"
		_:
			return ""

func _get_item_list_tooltip(items: Array, empty_text: String, title: String) -> String:
	if items.is_empty():
		return "%s\n%s" % [title, empty_text]
	var lines: Array[String] = [title]
	for item in items:
		if item is Dictionary:
			lines.append("——")
			lines.append(_get_item_detail_tooltip(item))
	return "\n".join(lines)

func _unequip_item_to_backpack(index: int, shop: Control):
	"""从装备栏卸下物品到背包"""
	if GameState.unequip_to_backpack(index):
		GameState.save_progress("shop")
		_update_inventory_display(shop)
		DebugLog.log("Unequipped item to backpack")

func _equip_item_from_backpack(index: int, shop: Control):
	"""从背包装备物品"""
	var item_name := ""
	if index >= 0 and index < GameState.backpack.size():
		item_name = GameState.get_item_display_name(GameState.backpack[index])
	if GameState.equip_from_backpack(index):
		GameState.save_progress("shop")
		_update_inventory_display(shop)
		if item_name != "":
			_show_shop_notice(shop, "已装备：%s" % item_name)
		DebugLog.log("Equipped item from backpack")

func _refresh_shop(_shop: Control):
	"""刷新商店（消耗金币）"""
	var result := ShopFlow.new(GameState, SHOP_REFRESH_COST, EventBus).refresh_shop()
	if bool(result.get("ok", false)):
		DebugLog.log("Shop refreshed, cost: ", result.get("cost", 0), " gold")
		_show_shop()
		if current_ui != null and current_ui.name == "ShopScene":
			_show_shop_notice(current_ui, str(result.get("notice", "")))
	else:
		DebugLog.log(result.get("message", "Shop refresh failed"))
		_show_shop_notice(_shop, str(result.get("notice", result.get("message", "刷新失败"))))

func _buy_item(item_id: String, shop: Control):
	"""购买物品 - 进入背包"""
	var result := ShopFlow.new(GameState, SHOP_REFRESH_COST, EventBus).buy_item(item_id)
	if not bool(result.get("ok", false)):
		DebugLog.log(result.get("message", "Buy item failed"))
		_show_shop_notice(shop, str(result.get("notice", result.get("message", "购买失败"))))
		return

	DebugLog.log("Bought item: ", item_id, " cost: ", result.get("cost", 0), " destination: ", result.get("destination", ""))
	_show_shop()
	var current_shop = current_ui
	var notice_text := str(result.get("notice", ""))
	if current_shop != null and current_shop.name == "ShopScene" and notice_text != "":
		_show_shop_notice(current_shop, notice_text)

func _show_shop_notice(shop: Control, text: String) -> void:
	if shop == null or text == "":
		return
	var notice_label = shop.get_node_or_null("ShopNotice")
	if notice_label != null and notice_label is Label:
		notice_label.text = text
	_show_center_notice(shop, text, "shop")

func _show_center_notice(parent: Control, text: String, notice_type: String = "normal") -> void:
	if parent == null or text == "":
		return
	var old = parent.get_node_or_null("CenterNotice")
	if old != null:
		old.queue_free()
	var panel := PanelContainer.new()
	panel.name = "CenterNotice"
	panel.position = Vector2(390, 250)
	panel.custom_minimum_size = Vector2(500, 92)
	panel.z_index = 120
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.055, 0.94)
	style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	if notice_type == "bad":
		style.border_color = Color(1.0, 0.35, 0.25, 1.0)
	elif notice_type == "good" or notice_type == "shop":
		style.border_color = Color(1.0, 0.78, 0.30, 1.0)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(470, 74)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.01, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	label.modulate = Color(1.0, 0.91, 0.66, 1.0)
	panel.add_child(label)
	parent.add_child(panel)

	panel.scale = Vector2(0.82, 0.82)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 0.0, 0.38).set_delay(1.25)
	tween.chain().tween_callback(func():
		if is_instance_valid(panel):
			panel.queue_free()
	)

func _sell_item(index: int, shop: Control):
	"""卖出物品 - 原价回收"""
	var result := ShopFlow.new(GameState, SHOP_REFRESH_COST, EventBus).sell_item(index)
	if bool(result.get("ok", false)):
		DebugLog.log("Sold item at index: ", index)
		if shop and shop.has_method("update_shop_display"):
			shop.update_shop_display()
		else:
			_show_shop()
	else:
		DebugLog.log(result.get("message", "Sell item failed"))

func _buy_material(shop: Control):
	"""旧材料购买入口已停用。"""
	_show_shop_notice(shop, "材料已取消，金币直接用于强化。")

func _advance_from_shop():
	"""从商店进入下一层地图"""
	DebugLog.log("Advancing from shop to next floor")
	GameState.current_shop_items.clear()
	_advance_map_floor()

# ===== 事件系统（好事/坏事）=====

func _show_event():
	"""显示事件界面 - 先进行一局对战决定好事还是坏事"""
	DebugLog.log("Event triggered")
	_change_state(State.EVENT)
	_switch_scene_music("event_neutral")

	# 重置战斗结束锁
	_battle_ending = false

	# 创建事件对战
	var battle = _create_event_battle()
	_add_ui(battle)

func _create_event_battle():
	"""创建事件对战界面（一局定胜负）"""
	var battle = Control.new()
	battle.name = "EventBattle"
	battle.custom_minimum_size = Vector2(1280, 720)

	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.15, 0.25)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	battle.add_child(bg)

	# 标题
	var title = Label.new()
	title.text = _get_era_event_battle_title()
	title.position = Vector2(540, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle.add_child(title)

	# 说明
	var desc = Label.new()
	desc.text = _get_era_event_battle_desc()
	desc.position = Vector2(540, 100)
	desc.add_theme_font_size_override("font_size", 20)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle.add_child(desc)

	# 结果标签
	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = _get_era_event_battle_prompt()
	result_label.position = Vector2(540, 300)
	result_label.add_theme_font_size_override("font_size", 28)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle.add_child(result_label)

	# 出招按钮
	var circle_btn = Button.new()
	circle_btn.text = MoveSymbols.move_name(0)
	circle_btn.custom_minimum_size = Vector2(100, 80)
	circle_btn.position = Vector2(480, 400)
	circle_btn.add_theme_font_size_override("font_size", 32)
	circle_btn.pressed.connect(func(): _process_event_battle_turn(0, battle))
	battle.add_child(circle_btn)

	var tri_btn = Button.new()
	tri_btn.text = MoveSymbols.move_name(1)
	tri_btn.custom_minimum_size = Vector2(100, 80)
	tri_btn.position = Vector2(590, 400)
	tri_btn.add_theme_font_size_override("font_size", 32)
	tri_btn.pressed.connect(func(): _process_event_battle_turn(1, battle))
	battle.add_child(tri_btn)

	var square_btn = Button.new()
	square_btn.text = MoveSymbols.move_name(2)
	square_btn.custom_minimum_size = Vector2(100, 80)
	square_btn.position = Vector2(700, 400)
	square_btn.add_theme_font_size_override("font_size", 32)
	square_btn.pressed.connect(func(): _process_event_battle_turn(2, battle))
	battle.add_child(square_btn)

	return battle

func _process_event_battle_turn(player_move: int, battle: Control):
	"""处理事件对战回合"""
	if _battle_ending:
		return

	var _symbols = MoveSymbols.MOVE_NAMES
	var enemy_move = randi() % 3

	var result_label = battle.get_node("ResultLabel")

	# 立即禁用所有按钮，防止连点
	_disable_battle_buttons(battle)

	if player_move == enemy_move:
		result_label.text = _get_era_event_battle_draw_text()
		# 平局时重新启用按钮，允许再次尝试
		_enable_battle_buttons(battle)
		return

	var player_wins = (player_move == 0 and enemy_move == 1) or \
					(player_move == 1 and enemy_move == 2) or \
					(player_move == 2 and enemy_move == 0)

	_battle_ending = true

	if player_wins:
		result_label.text = _get_era_event_battle_win_text()
		_switch_event_good_music()
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): _show_good_event())
	else:
		result_label.text = _get_era_event_battle_lose_text()
		_switch_event_bad_music()
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): _show_bad_event())

## 禁用事件对战的所有按钮
func _apply_battle_button_locked_state(button: Button, battle: Control) -> void:
	if bool(button.get_meta("battle_move_button", false)):
		var selected_move := int(battle.get_meta("battle_input_move_idx", -1))
		var move_idx := int(button.get_meta("move_idx", -2))
		_apply_battle_move_button_state(button, "afterglow" if move_idx == selected_move else "disabled")
	elif bool(button.get_meta("battle_action_button", false)):
		_apply_battle_action_button_state(button, "disabled")

func _disable_battle_buttons(battle: Control) -> void:
	for child in battle.get_children():
		if child is Button:
			child.disabled = true
			_apply_battle_button_locked_state(child, battle)
		elif child is HBoxContainer or child is VBoxContainer:
			for sub_child in child.get_children():
				if sub_child is Button:
					sub_child.disabled = true
					_apply_battle_button_locked_state(sub_child, battle)

## 启用事件对战的所有按钮
func _enable_battle_buttons(battle: Control) -> void:
	battle.set_meta("battle_input_move_idx", -1)
	for child in battle.get_children():
		if child is Button:
			child.disabled = false
			if bool(child.get_meta("battle_move_button", false)):
				_apply_battle_move_button_state(child, "normal")
			elif bool(child.get_meta("battle_action_button", false)):
				_apply_battle_action_button_state(child, "normal")
		elif child is HBoxContainer or child is VBoxContainer:
			for sub_child in child.get_children():
				if sub_child is Button:
					sub_child.disabled = false
					if bool(sub_child.get_meta("battle_move_button", false)):
						_apply_battle_move_button_state(sub_child, "normal")
					elif bool(sub_child.get_meta("battle_action_button", false)):
						_apply_battle_action_button_state(sub_child, "normal")
	_update_combo_linchpin_feedback(battle)

func _get_battle_move_nodes(battle: Control, move_idx: int) -> Dictionary:
	if battle == null:
		return {}
	return {
		"card": battle.get_node_or_null("BattleMoveCard%d" % move_idx) as Control,
		"icon": battle.get_node_or_null("BattleMoveIcon%d" % move_idx) as CanvasItem,
		"title": battle.get_node_or_null("BattleMoveTitle%d" % move_idx) as Label,
		"subtitle": battle.get_node_or_null("BattleMoveSubtitle%d" % move_idx) as Label,
		"key": battle.get_node_or_null("BattleMoveKey%d" % move_idx) as Label
	}

func _apply_battle_move_button_state(button: Button, state: String) -> void:
	if button == null:
		return
	var battle := button.get_parent() as Control
	if battle == null:
		return
	var move_idx := int(button.get_meta("move_idx", -1))
	if move_idx < 0:
		return
	var nodes := _get_battle_move_nodes(battle, move_idx)
	var card := nodes.get("card") as Control
	var icon := nodes.get("icon") as CanvasItem
	var title := nodes.get("title") as Label
	var subtitle := nodes.get("subtitle") as Label
	var key := nodes.get("key") as Label
	if card == null:
		return
	var base_scale := Vector2.ONE
	var card_modulate := Color.WHITE
	var title_modulate := Color.WHITE
	var subtitle_modulate := Color(1, 1, 1, 0.72)
	var key_modulate := Color(0.82, 0.82, 0.82)
	var icon_modulate := Color(1, 1, 1, 0.84)
	match state:
		"hover":
			base_scale = Vector2(1.03, 1.03)
			card_modulate = Color(1.08, 1.08, 1.08, 1.0)
			title_modulate = Color(1.06, 1.04, 1.0, 1.0)
			subtitle_modulate = Color(1.0, 1.0, 1.0, 0.9)
			key_modulate = Color(1.0, 0.94, 0.82, 1.0)
			icon_modulate = Color(1.0, 1.0, 1.0, 1.0)
		"pressed":
			base_scale = Vector2(0.97, 0.97)
			card_modulate = Color(0.96, 0.92, 0.88, 1.0)
			title_modulate = Color(1.0, 0.94, 0.82, 1.0)
			subtitle_modulate = Color(1.0, 0.96, 0.88, 0.92)
			key_modulate = Color(1.0, 0.90, 0.70, 1.0)
			icon_modulate = Color(1.0, 0.96, 0.88, 1.0)
		"disabled":
			base_scale = Vector2.ONE
			card_modulate = Color(0.56, 0.56, 0.60, 0.88)
			title_modulate = Color(0.74, 0.74, 0.76, 0.92)
			subtitle_modulate = Color(0.72, 0.72, 0.74, 0.62)
			key_modulate = Color(0.58, 0.58, 0.60, 0.84)
			icon_modulate = Color(0.72, 0.72, 0.74, 0.60)
		"afterglow":
			base_scale = Vector2(1.05, 1.05)
			card_modulate = Color(1.14, 1.08, 0.96, 1.0)
			title_modulate = Color(1.0, 0.96, 0.84, 1.0)
			subtitle_modulate = Color(1.0, 0.98, 0.92, 0.95)
			key_modulate = Color(1.0, 0.92, 0.74, 1.0)
			icon_modulate = Color(1.0, 0.98, 0.90, 1.0)
		"combo_linchpin":
			base_scale = Vector2(1.035, 1.035)
			card_modulate = Color(1.16, 1.08, 0.78, 1.0)
			title_modulate = Color(1.0, 0.90, 0.38, 1.0)
			subtitle_modulate = Color(1.0, 0.78, 0.30, 0.98)
			key_modulate = Color(1.0, 0.84, 0.36, 1.0)
			icon_modulate = Color(1.0, 0.88, 0.52, 1.0)
		_:
			base_scale = Vector2.ONE
	if state == "hover":
		var read_tint := _get_move_read_state_tint(str(button.get_meta("read_state", "")))
		card_modulate = card_modulate * read_tint.get("card", Color.WHITE)
		title_modulate = title_modulate * read_tint.get("title", Color.WHITE)
		subtitle_modulate = subtitle_modulate * read_tint.get("subtitle", Color.WHITE)
		key_modulate = key_modulate * read_tint.get("key", Color.WHITE)
		icon_modulate = icon_modulate * read_tint.get("icon", Color.WHITE)
	card.scale = base_scale
	card.modulate = card_modulate
	if title != null:
		title.modulate = title_modulate
	if subtitle != null:
		subtitle.modulate = subtitle_modulate
		if state == "hover":
			subtitle.text = _get_move_read_state_label(str(button.get_meta("read_state", "")))
		elif state == "afterglow":
			subtitle.text = "已出手"
		elif state == "combo_linchpin":
			subtitle.text = "临门"
		else:
			subtitle.text = str(button.get_meta("base_subtitle", subtitle.text))
	if key != null:
		key.modulate = key_modulate
	if icon != null:
		icon.modulate = icon_modulate

func _get_move_read_state_label(read_state: String) -> String:
	match read_state:
		"advantage":
			return "可压"
		"risk":
			return "有险"
		"draw":
			return "对住"
		"anti_read":
			return "反读"
		"uncertain":
			return "难读"
	return "试探"

func _get_move_read_state_tint(read_state: String) -> Dictionary:
	match read_state:
		"advantage":
			return {
				"card": Color(1.10, 1.03, 0.82, 1.0),
				"title": Color(1.08, 1.04, 0.82, 1.0),
				"subtitle": Color(1.10, 1.02, 0.76, 1.0),
				"key": Color(1.12, 1.02, 0.76, 1.0),
				"icon": Color(1.08, 1.02, 0.82, 1.0)
			}
		"risk":
			return {
				"card": Color(1.08, 0.78, 0.72, 1.0),
				"title": Color(1.10, 0.82, 0.76, 1.0),
				"subtitle": Color(1.10, 0.80, 0.74, 1.0),
				"key": Color(1.12, 0.74, 0.68, 1.0),
				"icon": Color(1.08, 0.82, 0.76, 1.0)
			}
		"draw":
			return {
				"card": Color(0.86, 0.94, 1.08, 1.0),
				"title": Color(0.86, 0.96, 1.10, 1.0),
				"subtitle": Color(0.86, 0.94, 1.08, 1.0),
				"key": Color(0.82, 0.92, 1.10, 1.0),
				"icon": Color(0.88, 0.96, 1.08, 1.0)
			}
		"uncertain", "anti_read":
			return {
				"card": Color(0.96, 0.88, 1.10, 1.0),
				"title": Color(1.02, 0.92, 1.10, 1.0),
				"subtitle": Color(1.00, 0.88, 1.08, 1.0),
				"key": Color(1.02, 0.86, 1.08, 1.0),
				"icon": Color(1.0, 0.92, 1.08, 1.0)
			}
	return {
		"card": Color.WHITE,
		"title": Color.WHITE,
		"subtitle": Color.WHITE,
		"key": Color.WHITE,
		"icon": Color.WHITE
	}

func _pulse_battle_move_button_afterglow(button: Button) -> void:
	if button == null:
		return
	_apply_battle_move_button_state(button, "afterglow")
	var tween := create_tween()
	tween.tween_interval(0.12)
	tween.tween_callback(func():
		if is_instance_valid(button):
			_apply_battle_move_button_state(button, "disabled" if button.disabled else "normal")
	)

func _get_combo_linchpin_state() -> Dictionary:
	var result := {
		"moves": [],
		"names": PackedStringArray()
	}
	for route_state in _get_combo_route_hint_states():
		var sequence: Array = route_state.get("sequence", [])
		var matched := int(route_state.get("matched", 0))
		if sequence.is_empty() or matched != sequence.size() - 1:
			continue
		var next_move := int(sequence[matched])
		var moves: Array = result["moves"]
		if not next_move in moves:
			moves.append(next_move)
		var names: PackedStringArray = result["names"]
		if names.size() < 3:
			names.append(str(route_state.get("name", "")))
		result["moves"] = moves
		result["names"] = names
	return result

func _update_combo_linchpin_feedback(battle: Control) -> void:
	if battle == null or _is_battle_turn_locked(battle):
		return
	var state := _get_combo_linchpin_state()
	var moves: Array = state.get("moves", [])
	for i in range(3):
		var btn := _get_battle_move_button(battle, i)
		if btn == null or btn.disabled:
			continue
		if i in moves:
			_apply_battle_move_button_state(btn, "combo_linchpin")
		else:
			_apply_battle_move_button_state(btn, "normal")
	if not moves.is_empty():
		var names: PackedStringArray = state.get("names", PackedStringArray())
		_pulse_combo_linchpin_route(battle, moves, names)

func _pulse_combo_linchpin_route(battle: Control, moves: Array, names: PackedStringArray) -> void:
	var panel := battle.get_node_or_null("ComboResourcePanel") as Panel
	var progress_label := battle.get_node_or_null("ComboProgress") as Label
	if panel == null and progress_label == null:
		return
	var state_key := "%s:%s" % [str(moves), ",".join(names)]
	if str(battle.get_meta("combo_linchpin_state", "")) == state_key:
		return
	battle.set_meta("combo_linchpin_state", state_key)
	if progress_label != null:
		progress_label.text = "暗势｜临门｜%s" % (" / ".join(names) if names.size() > 0 else "布局")
		progress_label.modulate = Color(1.0, 0.86, 0.30, 1.0)
		progress_label.scale = Vector2(1.0, 1.0)
		var label_tween := create_tween()
		label_tween.tween_property(progress_label, "scale", Vector2(1.035, 1.035), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		label_tween.tween_property(progress_label, "scale", Vector2.ONE, 0.18)
	if panel != null:
		var tween := create_tween()
		tween.tween_property(panel, "modulate", Color(1.10, 1.04, 0.86, 1.0), 0.16)
		tween.tween_property(panel, "modulate", Color.WHITE, 0.28)

func _get_battle_move_button(battle: Control, move_idx: int) -> Button:
	if battle == null:
		return null
	return battle.get_node_or_null("BattleMoveButton%d" % move_idx) as Button

func _apply_battle_move_input_feedback(battle: Control, move_idx: int) -> void:
	if battle == null:
		return
	battle.set_meta("battle_input_move_idx", move_idx)
	for i in range(3):
		var btn := _get_battle_move_button(battle, i)
		if btn != null:
			_apply_battle_move_button_state(btn, "afterglow" if i == move_idx else "disabled")
	_set_battle_broadcast(battle, "已出%s，等敌亮招" % MoveSymbols.move_name(move_idx))
	_show_battle_stage_text(battle, "已出手\n%s" % MoveSymbols.move_name(move_idx), "combo")

func _submit_battle_move(move_idx: int, battle: Control, enemy_ai: EnemyAI) -> void:
	if battle == null or enemy_ai == null or _battle_ending or _is_battle_turn_locked(battle):
		return
	_apply_battle_move_input_feedback(battle, move_idx)
	_process_battle_turn(move_idx, battle, enemy_ai)

func _setup_battle_action_button(button: Button, button_kind: String) -> void:
	if button == null:
		return
	button.set_meta("battle_action_button", true)
	button.set_meta("battle_action_kind", button_kind)
	button.pivot_offset = button.size * 0.5
	if button.has_meta("battle_action_bound"):
		_apply_battle_action_button_state(button, "disabled" if button.disabled else "normal")
		return
	button.set_meta("battle_action_bound", true)
	button.mouse_entered.connect(func():
		if not button.disabled:
			_apply_battle_action_button_state(button, "hover")
	)
	button.mouse_exited.connect(func():
		if not button.disabled:
			_apply_battle_action_button_state(button, "normal")
	)
	button.button_down.connect(func():
		if not button.disabled:
			_apply_battle_action_button_state(button, "pressed")
	)
	button.button_up.connect(func():
		if not button.disabled:
			var state := "hover" if button.get_global_rect().has_point(button.get_global_mouse_position()) else "normal"
			_apply_battle_action_button_state(button, state)
	)
	_apply_battle_action_button_state(button, "disabled" if button.disabled else "normal")

func _apply_battle_action_button_state(button: Button, state: String) -> void:
	if button == null:
		return
	var kind := str(button.get_meta("battle_action_kind", "combo"))
	var normal := Color.WHITE
	var hover := Color(1.06, 1.03, 0.96, 1.0)
	var pressed := Color(0.98, 0.93, 0.84, 1.0)
	var disabled := Color(0.62, 0.62, 0.62, 1.0)
	var afterglow := Color(1.12, 1.06, 0.90, 1.0)
	if kind == "cheat":
		hover = Color(1.04, 1.00, 0.90, 1.0)
		pressed = Color(0.98, 0.92, 0.76, 1.0)
		afterglow = Color(1.08, 1.02, 0.82, 1.0)
	match state:
		"hover":
			button.scale = Vector2(1.02, 1.02)
			button.modulate = hover
		"pressed":
			button.scale = Vector2(0.98, 0.98)
			button.modulate = pressed
		"disabled":
			button.scale = Vector2.ONE
			button.modulate = disabled
		"afterglow":
			button.scale = Vector2(1.04, 1.04)
			button.modulate = afterglow
		_:
			button.scale = Vector2.ONE
			button.modulate = normal

func _pulse_battle_action_button_afterglow(button: Button) -> void:
	if button == null:
		return
	_apply_battle_action_button_state(button, "afterglow")
	var tween := create_tween()
	tween.tween_interval(0.12)
	tween.tween_callback(func():
		if is_instance_valid(button):
			_apply_battle_action_button_state(button, "disabled" if button.disabled else "normal")
	)

func _add_event_page_chrome(event: Control, is_good: bool) -> void:
	var theme = GameState.get_era_theme()
	event.add_child(_create_era_seal(Vector2(106, 58), Vector2(126, 38)))

	var top_band = ColorRect.new()
	top_band.color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	top_band.position = Vector2(170, 100)
	top_band.custom_minimum_size = Vector2(940, 4)
	event.add_child(top_band)

	var main_card = PanelContainer.new()
	main_card.position = Vector2(270, 126)
	main_card.custom_minimum_size = Vector2(740, 500)
	var main_style := StyleBoxFlat.new()
	main_style.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94)).darkened(0.03)
	main_style.border_color = theme.get("good", Color(0.4, 1.0, 0.4, 1.0)) if is_good else theme.get("bad", Color(1.0, 0.4, 0.4, 1.0))
	main_style.set_border_width_all(2)
	main_style.corner_radius_top_left = 18
	main_style.corner_radius_top_right = 18
	main_style.corner_radius_bottom_left = 18
	main_style.corner_radius_bottom_right = 18
	main_card.add_theme_stylebox_override("panel", main_style)
	event.add_child(main_card)

	var bottom_line = ColorRect.new()
	bottom_line.color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).darkened(0.08)
	bottom_line.position = Vector2(250, 638)
	bottom_line.custom_minimum_size = Vector2(780, 3)
	event.add_child(bottom_line)

func _style_event_action_button(button: Button, is_good: bool) -> void:
	if button == null:
		return
	var theme = GameState.get_era_theme()
	var accent: Color = theme.get("good", Color(0.4, 1.0, 0.4, 1.0)) if is_good else theme.get("bad", Color(1.0, 0.4, 0.4, 1.0))
	var normal := StyleBoxFlat.new()
	normal.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.96)).lightened(0.04)
	normal.border_color = accent
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	hover.border_color = accent.lightened(0.12)
	var pressed := normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.08)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	button.add_theme_constant_override("outline_size", 1)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER

func _format_event_choice_text(title: String, body: String) -> String:
	if body.strip_edges() == "":
		return title
	return "%s\n%s" % [title, body]

func _style_event_decision_button(button: Button, is_good: bool, role: String) -> void:
	if button == null:
		return
	var theme = GameState.get_era_theme()
	var safe_color: Color = theme.get("good", Color(0.44, 0.92, 0.58, 1.0)) if is_good else Color(0.92, 0.62, 0.54, 1.0)
	var gamble_color := Color(0.46, 0.68, 1.0, 1.0) if is_good else Color(1.0, 0.66, 0.36, 1.0)
	var penalty_color: Color = theme.get("bad", Color(1.0, 0.4, 0.4, 1.0))
	var accent := safe_color
	match role:
		"gamble":
			accent = gamble_color
		"penalty":
			accent = penalty_color
		"continue":
			accent = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	var normal := StyleBoxFlat.new()
	normal.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.96)).darkened(0.04)
	if role == "gamble":
		normal.bg_color = normal.bg_color.lightened(0.07)
	elif role == "penalty":
		normal.bg_color = normal.bg_color.darkened(0.02)
	normal.border_color = accent
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	hover.border_color = accent.lightened(0.16)
	var pressed := normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.08)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(0.94, 0.91, 0.82, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.84, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.86, 0.82, 0.72, 1.0))
	button.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	button.add_theme_constant_override("outline_size", 1)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER

func _add_event_symbol(event: Control, is_good: bool) -> void:
	var theme = GameState.get_era_theme()
	var symbol_panel := Panel.new()
	symbol_panel.position = Vector2(585, 230)
	symbol_panel.size = Vector2(110, 76)
	var style := StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94)).darkened(0.08)
	style.border_color = theme.get("good", Color(0.4, 1.0, 0.4, 1.0)) if is_good else theme.get("bad", Color(1.0, 0.4, 0.4, 1.0))
	style.border_color.a = 0.72
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	symbol_panel.add_theme_stylebox_override("panel", style)
	symbol_panel.modulate.a = 0.86
	event.add_child(symbol_panel)

	var symbol := Label.new()
	symbol.text = "得" if is_good else "厄"
	symbol.position = Vector2(585, 230)
	symbol.custom_minimum_size = Vector2(110, 76)
	symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol.add_theme_font_size_override("font_size", 38)
	symbol.modulate = theme.get("title", Color(0.95, 0.9, 0.75))
	symbol.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	symbol.add_theme_constant_override("outline_size", 1)
	event.add_child(symbol)

func _show_good_event():
	"""好事事件"""
	DebugLog.log("Good event!")
	_change_state(State.EVENT)
	_switch_event_good_music()

	# 使用新的随机好事系统
	var event_data = RandomEventManager.get_random_good_event(GameState.current_floor)
	_show_good_event_with_data(event_data)

func _show_good_event_with_data(event_data: Dictionary):
	"""显示指定的好事事件"""
	var event = Control.new()
	event.name = "GoodEventScene"
	event.custom_minimum_size = Vector2(1280, 720)
	var era_theme = GameState.get_era_theme()

	# 背景
	var bg = ColorRect.new()
	bg.color = era_theme.get("bg", Color(0.12, 0.12, 0.18))
	bg.offset_right = 1280
	bg.offset_bottom = 720
	event.add_child(bg)
	_add_event_page_chrome(event, true)

	# 标题
	var title = Label.new()
	title.text = _get_era_good_event_title()
	title.position = Vector2(340, 42)
	title.custom_minimum_size = Vector2(600, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = era_theme.get("good", Color(0.4, 1, 0.4))
	event.add_child(title)

	# 状态栏
	var status_label = Label.new()
	status_label.text = _get_player_status_text()
	status_label.position = Vector2(30, 20)
	status_label.custom_minimum_size = Vector2(390, 26)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.modulate = Color(0.8, 0.8, 0.7)
	event.add_child(status_label)

	# 事件名称
	var name_label = Label.new()
	name_label.text = event_data.get("name", "")
	name_label.position = Vector2(330, 154)
	name_label.custom_minimum_size = Vector2(620, 44)
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.modulate = Color(1, 0.9, 0.6)
	event.add_child(name_label)

	# 事件描述
	var desc_label = Label.new()
	desc_label.text = _get_event_brief_text(event_data, true)
	desc_label.position = Vector2(330, 286)
	desc_label.custom_minimum_size = Vector2(620, 90)
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.modulate = Color(0.7, 0.7, 0.6)
	event.add_child(desc_label)
	_add_event_symbol(event, true)

	# 选项容器
	var options_container = VBoxContainer.new()
	options_container.position = Vector2(415, 396)
	options_container.custom_minimum_size = Vector2(450, 284)
	options_container.add_theme_constant_override("separation", 12)
	event.add_child(options_container)

	# 根据事件类型显示选项
	if event_data.get("battle_required", false):
		_show_battle_required_options(event_data, options_container)
	else:
		_show_immediate_good_options(event_data, options_container)

	_add_ui(event)

func _show_immediate_good_options(event_data: Dictionary, container: VBoxContainer):
	"""显示直接生效的好事件选项"""
	var stable_btn = Button.new()
	stable_btn.text = _format_event_choice_text("稳拿", "立即结算")
	stable_btn.custom_minimum_size = Vector2(450, 76)
	stable_btn.add_theme_font_size_override("font_size", 19)
	stable_btn.modulate = Color(0.96, 1.0, 0.92)
	_style_event_decision_button(stable_btn, true, "safe")

	var stable_data = event_data
	stable_btn.pressed.connect(func():
		var before_state := _capture_event_settlement_state()
		RandomEventManager.settle_immediate_good_event(stable_data)
		EventBus.good_event_triggered.emit("immediate", stable_data)
		_finish_event_choice_with_summary(stable_data, true, "稳拿", before_state)
	)
	container.add_child(stable_btn)

	var gamble_btn = Button.new()
	gamble_btn.text = _format_event_choice_text("加码", "试锋提高收益")
	gamble_btn.custom_minimum_size = Vector2(450, 88)
	gamble_btn.add_theme_font_size_override("font_size", 20)
	gamble_btn.modulate = Color(0.9, 0.96, 1.0)
	_style_event_decision_button(gamble_btn, true, "gamble")

	var gamble_data = event_data.duplicate(true)
	gamble_data["battle_required"] = true
	gamble_data["battle_type"] = "good_gamble_bonus"
	gamble_btn.pressed.connect(func():
		_start_new_event_battle(true, gamble_data)
	)
	container.add_child(gamble_btn)

func _show_good_stable_fallback_option(event_data: Dictionary, container: VBoxContainer):
	"""给原本只有战斗的好事件补一个低收益保底选项"""
	var btn = Button.new()
	btn.text = _format_event_choice_text("取小利", "金币+16")
	btn.custom_minimum_size = Vector2(450, 68)
	btn.add_theme_font_size_override("font_size", 18)
	btn.modulate = Color(0.78, 0.92, 0.78)
	_style_event_decision_button(btn, true, "safe")

	var data = event_data
	btn.pressed.connect(func():
		var before_state := _capture_event_settlement_state()
		GameState.player_gold += 16
		RandomEventManager.event_gold_changed.emit(16)
		RandomEventManager.set_last_reward_summary("选择稳拿小利：金币+16。")
		EventBus.good_event_triggered.emit("immediate", data)
		EventBus.player_gold_changed.emit(GameState.player_gold)
		_finish_event_choice_with_summary(data, true, "取小利", before_state)
	)
	container.add_child(btn)

func _show_battle_required_options(event_data: Dictionary, container: VBoxContainer):
	"""显示需要战斗的好事件选项"""
	var battle_type = event_data.get("battle_type", "")

	var label = Label.new()
	label.text = "三回合定局"
	label.add_theme_font_size_override("font_size", 17)
	label.modulate = Color(0.5, 0.5, 0.5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(450, 32)
	container.add_child(label)

	var preview = Label.new()
	preview.text = _get_good_battle_preview(battle_type)
	preview.add_theme_font_size_override("font_size", 15)
	preview.modulate = Color(0.4, 0.4, 0.4)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview.custom_minimum_size = Vector2(450, 72)
	container.add_child(preview)

	_show_good_stable_fallback_option(event_data, container)

	var btn = Button.new()
	btn.text = _format_event_choice_text("试锋", "")
	btn.custom_minimum_size = Vector2(450, 78)
	btn.add_theme_font_size_override("font_size", 20)
	btn.modulate = Color(0.8, 1, 0.8)
	_style_event_decision_button(btn, true, "gamble")

	var data = event_data
	btn.pressed.connect(func():
		_start_new_event_battle(true, data)
	)
	container.add_child(btn)

func _get_good_battle_preview(battle_type: String) -> String:
	match battle_type:
		"random_equip":
			return "2胜红｜1胜蓝｜0胜白"
		"shop_discount":
			return "2胜七折｜1胜八折｜0胜九折"
		"good_gamble_bonus":
			return "胜多则厚，失手则薄"
		_:
			return ""

func _show_bad_event():
	"""坏事事件"""
	DebugLog.log("Bad event!")
	_change_state(State.EVENT)
	_switch_event_bad_music()

	# 使用新的随机坏事系统
	var event_data = RandomEventManager.get_random_bad_event(GameState.current_floor)
	_show_bad_event_with_data(event_data)

func _show_bad_event_with_data(event_data: Dictionary):
	"""显示指定的坏事事件"""
	var event = Control.new()
	event.name = "BadEventScene"
	event.custom_minimum_size = Vector2(1280, 720)
	var era_theme = GameState.get_era_theme()

	# 背景
	var bg = ColorRect.new()
	bg.color = era_theme.get("bg", Color(0.12, 0.12, 0.18))
	bg.offset_right = 1280
	bg.offset_bottom = 720
	event.add_child(bg)
	_add_event_page_chrome(event, false)

	# 标题
	var title = Label.new()
	title.text = _get_era_bad_event_title()
	title.position = Vector2(340, 42)
	title.custom_minimum_size = Vector2(600, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = era_theme.get("bad", Color(1, 0.4, 0.4))
	event.add_child(title)

	# 状态栏
	var status_label = Label.new()
	status_label.text = _get_player_status_text()
	status_label.position = Vector2(30, 20)
	status_label.custom_minimum_size = Vector2(390, 26)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.modulate = Color(0.8, 0.8, 0.7)
	event.add_child(status_label)

	# 事件名称
	var name_label = Label.new()
	name_label.text = event_data.get("name", "")
	name_label.position = Vector2(330, 154)
	name_label.custom_minimum_size = Vector2(620, 44)
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.modulate = Color(1, 0.9, 0.6)
	event.add_child(name_label)

	# 事件描述
	var desc_label = Label.new()
	desc_label.text = _get_event_brief_text(event_data, false)
	desc_label.position = Vector2(330, 286)
	desc_label.custom_minimum_size = Vector2(620, 90)
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.modulate = Color(0.7, 0.7, 0.6)
	event.add_child(desc_label)
	_add_event_symbol(event, false)

	# 选项容器
	var options_container = VBoxContainer.new()
	options_container.position = Vector2(415, 396)
	options_container.custom_minimum_size = Vector2(450, 284)
	options_container.add_theme_constant_override("separation", 12)
	event.add_child(options_container)

	# 根据事件类型显示选项
	var choice_type = event_data.get("choice_type", "")
	match choice_type:
		"attribute":
			_show_attribute_penalty_options(event_data, options_container)
		"equip_loss":
			_show_equip_loss_options(event_data, options_container)
		_:
			_show_simple_bad_options(event_data, options_container)

	_add_ui(event)

func _show_attribute_penalty_options(event_data: Dictionary, container: VBoxContainer):
	"""显示属性惩罚选项（四选一）"""
	var gamble_btn = Button.new()
	gamble_btn.text = _format_event_choice_text("试锋化解", _get_bad_trial_choice_body())
	gamble_btn.custom_minimum_size = Vector2(450, 76)
	gamble_btn.add_theme_font_size_override("font_size", 19)
	gamble_btn.modulate = Color(0.88, 0.9, 1.0)
	_style_event_decision_button(gamble_btn, false, "gamble")
	var gamble_data = event_data.duplicate(true)
	gamble_data["battle_required"] = true
	gamble_data["battle_type"] = "bad_gamble_relief"
	gamble_btn.pressed.connect(func():
		_start_new_event_battle(false, gamble_data)
	)
	container.add_child(gamble_btn)

	var label = Label.new()
	label.text = "或直接认罚"
	label.add_theme_font_size_override("font_size", 15)
	label.modulate = Color(0.9, 0.8, 0.8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(450, 24)
	container.add_child(label)

	var attributes = [
		{"name": "命数", "desc": "上限-2", "type": 0},
		{"name": "⚔️ 攻击", "desc": "-1", "type": 1},
		{"name": "🛡️ 护甲", "desc": "护甲-2", "type": 2},
		{"name": "💥 暴击", "desc": "-20%", "type": 3}
	]

	for attr in attributes:
		var btn = Button.new()
		btn.text = "%s  %s" % [attr.name, attr.desc]
		btn.custom_minimum_size = Vector2(450, 38)
		btn.add_theme_font_size_override("font_size", 14)
		btn.modulate = Color(1, 0.85, 0.85)
		_style_event_decision_button(btn, false, "penalty")

		var data = event_data
		var attr_type = attr.type
		btn.pressed.connect(func():
			var before_state := _capture_event_settlement_state()
			RandomEventManager.settle_immediate_bad_event(data, attr_type)
			EventBus.bad_event_triggered.emit("immediate", data)
			_finish_event_choice_with_summary(data, false, "认罚", before_state)
		)
		container.add_child(btn)

func _show_equip_loss_options(event_data: Dictionary, container: VBoxContainer):
	"""显示装备损失选项"""
	var loss_candidates := _get_equipment_loss_candidates_for_event()
	var has_equipment := not loss_candidates.is_empty()

	# 选项1：直接丢失
	var option1 = Button.new()
	option1.custom_minimum_size = Vector2(450, 76)
	option1.add_theme_font_size_override("font_size", 18)
	option1.modulate = Color(1, 0.8, 0.8)
	_style_event_decision_button(option1, false, "penalty")

	if has_equipment:
		var random_item = loss_candidates[randi() % loss_candidates.size()]
		option1.text = _format_event_choice_text("认罚", GameState.get_item_display_name(random_item))
		option1.pressed.connect(func():
			var before_state := _capture_event_settlement_state()
			RandomEventManager.settle_direct_equip_loss()
			EventBus.bad_event_triggered.emit("immediate", event_data)
			_finish_event_choice_with_summary(event_data, false, "认罚", before_state)
		)
	else:
		option1.text = _format_event_choice_text("认罚", "无装备，无损失")
		option1.disabled = true
	container.add_child(option1)

	# 选项2：通过战斗决定
	var option2 = Button.new()
	option2.custom_minimum_size = Vector2(450, 88)
	option2.add_theme_font_size_override("font_size", 17)
	option2.modulate = Color(0.9, 0.9, 1)
	_style_event_decision_button(option2, false, "gamble")

	if has_equipment:
		option2.text = _format_event_choice_text("试锋护器", _get_bad_trial_choice_body())
		var trial_data = event_data.duplicate(true)
		trial_data["battle_required"] = true
		trial_data["battle_type"] = "bad_gamble_relief"
		option2.pressed.connect(func():
			_start_new_event_battle(false, trial_data)
		)
	else:
		option2.text = _format_event_choice_text("试锋避厄", _get_bad_trial_choice_body())
		var no_equip_trial_data = event_data.duplicate(true)
		no_equip_trial_data["battle_required"] = true
		no_equip_trial_data["battle_type"] = "bad_gamble_relief"
		option2.pressed.connect(func():
			_start_new_event_battle(false, no_equip_trial_data)
		)
	container.add_child(option2)

	if not has_equipment:
		var continue_btn = Button.new()
		continue_btn.text = "无装备可折损，继续前进"
		continue_btn.custom_minimum_size = Vector2(450, 62)
		continue_btn.add_theme_font_size_override("font_size", 18)
		continue_btn.modulate = Color(0.86, 0.86, 0.78)
		_style_event_decision_button(continue_btn, false, "continue")
		continue_btn.pressed.connect(func():
			var before_state := _capture_event_settlement_state()
			RandomEventManager.set_last_reward_summary("无装备可折损。")
			_finish_event_choice_with_summary(event_data, false, "无损失", before_state)
		)
		container.add_child(continue_btn)

func _get_equipment_loss_candidates_for_event() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for item in GameState.backpack:
		candidates.append(item)
	for item in GameState.equipment_slot:
		candidates.append(item)
	return candidates

func _show_simple_bad_options(event_data: Dictionary, container: VBoxContainer):
	"""显示简单坏事选项"""
	var gamble_btn = Button.new()
	gamble_btn.text = _format_event_choice_text("试锋化解", _get_bad_trial_choice_body())
	gamble_btn.custom_minimum_size = Vector2(450, 84)
	gamble_btn.add_theme_font_size_override("font_size", 19)
	gamble_btn.modulate = Color(0.88, 0.9, 1.0)
	_style_event_decision_button(gamble_btn, false, "gamble")
	var gamble_data = event_data.duplicate(true)
	gamble_data["battle_required"] = true
	gamble_data["battle_type"] = "bad_gamble_relief"
	gamble_btn.pressed.connect(func():
		_start_new_event_battle(false, gamble_data)
	)
	container.add_child(gamble_btn)

	var btn = Button.new()
	btn.text = _format_event_choice_text("认罚", "")
	btn.custom_minimum_size = Vector2(450, 74)
	btn.add_theme_font_size_override("font_size", 18)
	btn.modulate = Color(1, 0.8, 0.8)
	_style_event_decision_button(btn, false, "penalty")

	var data = event_data
	btn.pressed.connect(func():
		var before_state := _capture_event_settlement_state()
		RandomEventManager.settle_immediate_bad_event(data, -1)
		EventBus.bad_event_triggered.emit("immediate", data)
		_finish_event_choice_with_summary(data, false, "认罚", before_state)
	)
	container.add_child(btn)

func _get_bad_trial_choice_body() -> String:
	return "2胜无伤｜1胜-1命｜0胜-2命"

func _start_new_event_battle(is_good: bool, event_data: Dictionary):
	"""开始新的事件战斗"""
	DebugLog.log("[Main] Starting new event battle: is_good=", is_good)
	_change_state(State.EVENT_BATTLE)
	if is_good:
		_switch_event_good_music()
	else:
		_switch_event_bad_music()

	# 重置战斗结束锁
	_battle_ending = false

	var context = {
		"event_data": event_data,
		"battle_type": event_data.get("battle_type", "")
	}

	var battle = _create_new_event_battle_scene(is_good, context)
	_add_ui(battle)

func _create_new_event_battle_scene(is_good: bool, context: Dictionary) -> Control:
	"""创建新的事件战斗场景"""
	var battle = Control.new()
	battle.custom_minimum_size = Vector2(1280, 720)
	battle.set_meta("is_good", is_good)
	battle.set_meta("context", context)

	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.15, 0.25)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	battle.add_child(bg)

	# 标题
	var title = Label.new()
	title.text = "⚔️ %s战斗" % ("好事" if is_good else "坏事")
	title.position = Vector2(540, 50)
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.2, 0.5, 0.2) if is_good else Color(0.7, 0.2, 0.2)
	battle.add_child(title)

	# 回合显示
	var round_label = Label.new()
	round_label.name = "RoundLabel"
	round_label.text = "第 1 / 3 回合 （不计入结果）"
	round_label.position = Vector2(540, 130)
	round_label.add_theme_font_size_override("font_size", 28)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle.add_child(round_label)

	# 奖励预览
	var preview_label = Label.new()
	preview_label.name = "PreviewLabel"
	var battle_type = context.get("battle_type", "")
	if is_good:
		preview_label.text = _get_good_battle_preview(battle_type)
	else:
		preview_label.text = _get_bad_battle_preview(battle_type)
	preview_label.position = Vector2(900, 200)
	preview_label.add_theme_font_size_override("font_size", 18)
	preview_label.modulate = Color(0.5, 0.5, 0.5)
	battle.add_child(preview_label)

	# 结果标签
	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = "请选择出招..."
	result_label.position = Vector2(540, 250)
	result_label.add_theme_font_size_override("font_size", 28)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle.add_child(result_label)

	# 当前胜利数
	var wins_label = Label.new()
	wins_label.name = "WinsLabel"
	wins_label.text = "当前胜利：0"
	wins_label.position = Vector2(540, 300)
	wins_label.add_theme_font_size_override("font_size", 20)
	battle.add_child(wins_label)

	# 出招按钮
	var btn_container = HBoxContainer.new()
	btn_container.position = Vector2(490, 400)
	btn_container.custom_minimum_size = Vector2(300, 80)
	battle.add_child(btn_container)

	var circle_btn = Button.new()
	circle_btn.text = MoveSymbols.move_name(0)
	circle_btn.custom_minimum_size = Vector2(80, 60)
	circle_btn.add_theme_font_size_override("font_size", 32)
	circle_btn.pressed.connect(func(): _process_new_event_battle_turn(0, battle))
	btn_container.add_child(circle_btn)

	var tri_btn = Button.new()
	tri_btn.text = MoveSymbols.move_name(1)
	tri_btn.custom_minimum_size = Vector2(80, 60)
	tri_btn.add_theme_font_size_override("font_size", 32)
	tri_btn.pressed.connect(func(): _process_new_event_battle_turn(1, battle))
	btn_container.add_child(tri_btn)

	var square_btn = Button.new()
	square_btn.text = MoveSymbols.move_name(2)
	square_btn.custom_minimum_size = Vector2(80, 60)
	square_btn.add_theme_font_size_override("font_size", 32)
	square_btn.pressed.connect(func(): _process_new_event_battle_turn(2, battle))
	btn_container.add_child(square_btn)

	# 初始化战斗状态
	RandomEventManager.start_event_battle(is_good, context)
	battle.set_meta("current_round", 0)

	return battle

func _process_new_event_battle_turn(player_move: int, battle: Control):
	"""处理新的事件战斗回合"""
	if _battle_ending:
		return

	var current_round = battle.get_meta("current_round")
	current_round += 1

	# 立即禁用按钮防止连点
	_disable_battle_buttons(battle)

	# 生成敌人出招
	var enemy_move = randi() % 3

	# 处理回合
	var result = RandomEventManager.process_event_battle_round(player_move, enemy_move)
	var wins = int(result.get("wins", 0))
	var round_won = result.get("won", false)

	battle.set_meta("current_round", current_round)

	var result_label = battle.get_node_or_null("ResultLabel")
	var round_label = battle.get_node_or_null("RoundLabel")
	var wins_label = battle.get_node_or_null("WinsLabel")

	var symbols = MoveSymbols.MOVE_NAMES
	var msg = result.get("message", "")

	if result_label:
		result_label.text = "%s\n你: %s vs 敌: %s" % [msg, symbols[player_move], symbols[enemy_move]]

		if current_round == 1:
			result_label.modulate = Color(0.6, 0.6, 0.6)
		elif round_won:
			result_label.modulate = Color(0.2, 0.7, 0.2)
		else:
			result_label.modulate = Color(0.7, 0.2, 0.2)

	if round_label:
		round_label.text = "第 %d / 3 回合" % current_round
		if current_round < 3:
			round_label.text += " 当前胜利：%d" % wins

	if wins_label:
		wins_label.text = "当前胜利：%d" % wins

	if not result.get("continues", false):
		# 战斗结束
		_battle_ending = true
		_finish_new_event_battle(battle, wins)
	else:
		# 继续下一回合 - 短暂延迟后重新启用按钮
		if result_label:
			result_label.text = "第%d回合开始！请选择..." % (current_round + 1)
			result_label.modulate = Color(0.9, 0.9, 0.9)

		# 延迟后重新启用按钮
		var enable_timer = get_tree().create_timer(0.3)
		enable_timer.timeout.connect(func(): _enable_battle_buttons(battle))

func _finish_new_event_battle(battle: Control, wins: int):
	"""结束新的事件战斗"""
	var is_good = battle.get_meta("is_good")
	var context = battle.get_meta("context")
	var battle_type = context.get("battle_type", "")
	var final_result: Dictionary = RandomEventManager.finish_event_battle()
	if not final_result.is_empty():
		wins = int(final_result.get("wins", wins))

	# 禁用按钮
	var btn_container = battle.get_node_or_null(".")
	if btn_container:
		for child in btn_container.get_children():
			if child is HBoxContainer:
				for button in child.get_children():
					if button is Button:
						button.disabled = true

	# 显示结果
	var result_label = battle.get_node_or_null("ResultLabel")
	if result_label:
		result_label.text += "\n\n"
		if is_good:
			match battle_type:
				"random_equip":
					match wins:
						2: result_label.text += "🎉 获得 🔴红色装备！"
						1: result_label.text += "🎉 获得 🔵蓝色装备！"
						_: result_label.text += "🎉 获得 ⚪白色装备！"
				"shop_discount":
					match wins:
						2: result_label.text += "🎉 商店7折！"
						1: result_label.text += "🎉 商店8折！"
						_: result_label.text += "🎉 商店9折！"
				"good_gamble_bonus":
					match wins:
						2: result_label.text += "加码成功。"
						1: result_label.text += "保住收益。"
						_: result_label.text += "加码失手，只带回小补偿。"
		else:
			if battle_type == "bad_gamble_relief":
				match wins:
					2: result_label.text += "化解成功，无伤过关。"
					1: result_label.text += "勉强化解，只受轻伤。"
					_: result_label.text += "试锋失利，以命数抵灾。"
			else:
				match wins:
					2: result_label.text += "😅 还好，只丢了⚪白色装备"
					1: result_label.text += "😰 糟糕，丢了🔵蓝色装备"
					_: result_label.text += "😭 倒霉，丢了🔴红色装备！"
		var reward_summary := RandomEventManager.consume_last_reward_summary()
		if reward_summary != "":
			result_label.text += "\n%s" % reward_summary

		result_label.modulate = Color(0.8, 0.6, 0.2)

	# 延迟后返回
	await get_tree().create_timer(2.5).timeout
	_advance_floor()

func _get_bad_battle_preview(battle_type: String = "") -> String:
	if battle_type == "bad_gamble_relief":
		return _get_bad_trial_choice_body()
	return "2胜白｜1胜蓝｜0胜红"

func _get_event_brief_text(event_data: Dictionary, is_good: bool) -> String:
	var event_id := str(event_data.get("event_id", ""))
	if event_data.get("battle_required", false):
		if is_good:
			return "可稳拿，也可试锋加码。"
		return "可认罚，也可试锋抵灾。%s。" % _get_bad_trial_choice_body()
	if is_good:
		match event_id:
			"hp_blessing", "field_medic":
				return "命线回暖。"
			"attack_blessing", "crit_blessing":
				return "锋芒渐起。"
			"shield_blessing":
				return "甲势暂成。"
			"gold_cache", "scrap_cache", "song_market_boom":
				return "资粮入手。"
			"combo_slot", "qin_merit_grant", "china_dragon_vein":
				return "局势开阔。"
			"armory_gift", "random_equip_duel":
				return "器物将至。"
			"cheat_console":
				return "机括入袖。"
			"shop_discount_duel":
				return "行商让路。"
	else:
		match event_id:
			"hp_weaken", "brittle_bones":
				return "命线受损。"
			"attack_weaken", "crit_weaken":
				return "锋芒受挫。"
			"shield_weaken", "armor_crack":
				return "甲势裂开。"
			"gold_loss", "material_leak", "qin_harsh_law", "song_border_alarm":
				return "资粮外泄。"
			"skill_lock", "combo_slot_loss":
				return "布局受阻。"
			"equip_loss_duel":
				return "可认罚折器，也可试锋抵灾。"
			"china_old_debt":
				return "旧债追身。"
	return str(event_data.get("description", ""))

func _create_event_info_panel(event_data: Dictionary, is_good: bool) -> Control:
	var theme = GameState.get_era_theme()
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 360)
	var style := StyleBoxFlat.new()
	style.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94)).darkened(0.12)
	style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	style.set_border_width_all(1)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(324, 320)
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var rarity_text = "稀有事件" if event_data.get("rarity", "common") == "rare" else "普通事件"
	var rarity_label = Label.new()
	rarity_label.text = "异闻档案 · %s" % rarity_text
	rarity_label.add_theme_font_size_override("font_size", 21)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.modulate = Color(1, 0.82, 0.45) if event_data.get("rarity", "common") == "rare" else Color(0.72, 0.72, 0.78)
	vbox.add_child(rarity_label)

	var category_label = Label.new()
	category_label.text = _get_event_category_text(event_data, is_good)
	category_label.add_theme_font_size_override("font_size", 17)
	category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	category_label.modulate = Color(0.78, 0.82, 0.9)
	category_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(category_label)

	var floor_label = Label.new()
	floor_label.text = "第%d层起可能出现" % (int(event_data.get("min_floor", 0)) + 1)
	floor_label.add_theme_font_size_override("font_size", 15)
	floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floor_label.modulate = Color(0.64, 0.68, 0.76)
	vbox.add_child(floor_label)

	var divider = ColorRect.new()
	divider.color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).darkened(0.12)
	divider.custom_minimum_size = Vector2(310, 2)
	vbox.add_child(divider)

	var detail_title = Label.new()
	detail_title.text = "影响"
	detail_title.add_theme_font_size_override("font_size", 17)
	detail_title.modulate = Color(0.88, 0.88, 0.8)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(detail_title)

	var detail_label = Label.new()
	detail_label.text = _get_event_detail_text(event_data, is_good)
	detail_label.add_theme_font_size_override("font_size", 15)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.modulate = Color(0.76, 0.76, 0.72)
	detail_label.custom_minimum_size = Vector2(310, 0)
	vbox.add_child(detail_label)

	if event_data.get("battle_required", false):
		var battle_tip = Label.new()
		battle_tip.text = "试探后定档"
		battle_tip.add_theme_font_size_override("font_size", 15)
		battle_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		battle_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		battle_tip.modulate = Color(0.62, 0.66, 0.72)
		vbox.add_child(battle_tip)

	return panel

func _get_event_category_text(event_data: Dictionary, is_good: bool) -> String:
	if event_data.get("battle_required", false):
		return "需判定" if is_good else "可化解"
	if event_data.get("choice_type", "") == "attribute":
		return "取舍"
	if event_data.get("choice_type", "") == "equip_loss":
		return "器物风险"
	return "收益" if is_good else "代价"

func _get_event_detail_text(event_data: Dictionary, is_good: bool) -> String:
	var event_id = str(event_data.get("event_id", ""))
	if is_good:
		match event_id:
			"hp_blessing": return "命数上限 +2，并同步恢复 2 命。"
			"attack_blessing": return "攻击 +1。"
			"shield_blessing": return "当前护甲 +2。"
			"crit_blessing": return "暴击率 +20%。"
			"gold_cache": return "立即获得 10 金币。"
			"random_equip_duel": return "通过事件战斗决定获得的装备品质。"
			"shop_discount_duel": return "通过天时争夺决定下一次行商让利的力度。"
			"field_medic": return "恢复 4 命，不会超过命数上限。"
			"scrap_cache": return "立即获得 12 金币。"
			"combo_slot": return "最大可携带布局槽位 +1。"
			"armory_gift": return "立即获得 1 件随机蓝色装备；若没有候选则补发金币。"
			"cheat_console": return "获得 1 次机括机会，可用于战斗中读招。"
			"qin_merit_grant": return "获得 12 金币、攻击 +1，并把【虎符压阵】免费强化 1 级。"
			"song_market_boom": return "获得 16 金币，并把【市舶周转】免费强化 1 级。"
			"china_dragon_vein": return "获得 1 点机括、恢复 2 命，并把【山河同契】免费强化 1 级。"
	else:
		match event_id:
			"hp_weaken": return "在命数 / 攻击 / 护甲 / 暴击中四选一承受惩罚。"
			"attack_weaken": return "在命数 / 攻击 / 护甲 / 暴击中四选一承受惩罚。"
			"shield_weaken": return "在命数 / 攻击 / 护甲 / 暴击中四选一承受惩罚。"
			"crit_weaken": return "在命数 / 攻击 / 护甲 / 暴击中四选一承受惩罚。"
			"skill_lock": return "随机封印 1 个当前已备布局。"
			"equip_loss_duel": return "可认罚折器，也可试锋抵灾：2胜无伤，1胜-1命，0胜-2命。"
			"gold_loss": return "可认罚失去金币，也可试锋抵灾：2胜无伤，1胜-1命，0胜-2命。"
			"material_leak": return "可认罚失去金币，也可试锋抵灾：2胜无伤，1胜-1命，0胜-2命。"
			"armor_crack": return "可认罚护甲受损，也可试锋抵灾：2胜无伤，1胜-1命，0胜-2命。"
			"combo_slot_loss": return "可认罚失去布局槽，也可试锋抵灾：2胜无伤，1胜-1命，0胜-2命。"
			"brittle_bones": return "可认罚命数上限受损，也可试锋抵灾：2胜无伤，1胜-1命，0胜-2命。"
	return event_data.get("description", "")

func _give_random_equipment():
	"""给予随机装备（添加到背包）"""
	var all_items = []
	for item_id in GameState.ITEMS:
		if not GameState.has_item_anywhere(item_id):
			all_items.append(item_id)

	if not all_items.is_empty():
		var random_item = all_items[randi() % all_items.size()]
		GameState.add_to_backpack(random_item)
		DebugLog.log("Gave random equipment: ", random_item)

func _lose_random_equipment():
	"""随机丢失一件装备（从背包）"""
	if GameState.backpack.is_empty():
		return

	var random_index = randi() % GameState.backpack.size()
	var lost_item = GameState.backpack[random_index]
	GameState.remove_from_backpack(random_index)
	DebugLog.log("Lost random equipment: ", lost_item.name)

func _return_to_map_after_event():
	"""事件结束后返回地图"""
	RandomEventManager.cancel_event_battle()
	_advance_floor()

func _get_player_status_text() -> String:
	"""获取玩家状态文本"""
	var class_names = ["医生", "黑客", "商人", "农民", "流浪者"]
	var hp_bar = ""
	for i in range(GameState.player_max_hp):
		hp_bar += "❤️" if i < GameState.player_hp else "🖤"

	var status = "%s %s 💰%d" % [class_names[GameState.player_class], hp_bar, GameState.player_gold]
	if GameState.player_shield > 0:
		status += " 🛡️%d" % GameState.player_shield
	return status

# ===== 战斗系统（新AI + 背包自动装备）=====

# ComboDatabase 缓存
var _combo_database_cache: ComboDatabase = null

func _get_combo_id(combo) -> String:
	"""兼容获取连招ID（ComboInfo.id 或 ComboData.combo_id）"""
	if combo == null:
		return ""
	if combo.get("id") != null:
		return str(combo.get("id"))
	if combo.get("combo_id") != null:
		return str(combo.get("combo_id"))
	return ""

func _get_combo_name(combo) -> String:
	"""兼容获取连招名称（ComboInfo.name 或 ComboData.display_name）"""
	if combo == null:
		return "???"
	if combo.get("name") != null:
		return ComboDatabase.get_era_combo_name(str(combo.get("name")))
	if combo.get("display_name") != null:
		return ComboDatabase.get_era_combo_name(str(combo.get("display_name")))
	return "???"

func _get_era_event_battle_title() -> String:
	match GameState.selected_era_id:
		"song":
			return "%s ⚡ 市井博弈" % _get_era_badge()
		"china":
			return "%s ⚡ 山河争势" % _get_era_badge()
		_:
			return "%s ⚡ 命运之战" % _get_era_badge()

func _get_era_event_battle_desc() -> String:
	match GameState.selected_era_id:
		"song":
			return "胜势→得利  失势→遭祸"
		"china":
			return "得势→纳益  失势→受债"
		_:
			return "胜利→好事  失败→坏事"

func _get_era_event_battle_prompt() -> String:
	match GameState.selected_era_id:
		"song":
			return "布势定夺..."
		"china":
			return "布势入局..."
		_:
			return "选择出招..."

func _get_era_event_battle_draw_text() -> String:
	match GameState.selected_era_id:
		"song":
			return "🤝 僵持! 再布一手..."
		"china":
			return "🤝 对峙! 再争一势..."
		_:
			return "🤝 平局! 再试一次..."

func _get_era_event_battle_win_text() -> String:
	match GameState.selected_era_id:
		"song":
			return "✅ 得势! 良机在前!"
		"china":
			return "✅ 抢势! 山河回响!"
		_:
			return "✅ 胜利! 好事降临!"

func _get_era_event_battle_lose_text() -> String:
	match GameState.selected_era_id:
		"song":
			return "❌ 失势! 边患骤起..."
		"china":
			return "❌ 失手! 旧债加身..."
		_:
			return "❌ 失败! 坏事发生..."

func _get_era_boss_warning_text() -> String:
	match GameState.selected_era_id:
		"song":
			return "⚡ 需依靠器物精修与阵图修习才能压住战局！"
		"china":
			return "⚡ 需依靠遗器重铸与终局布局才能撕开终局！"
		_:
			return "⚡ 必须依靠器物升级和布局强化来击败！"

func _get_era_boss_phase_bonus_text() -> String:
	match GameState.selected_era_id:
		"song":
			return "【守势延压】灾主回稳2点命数；之后会拆你的布局冷却，并在僵持时回稳。"
		"china":
			return "【百代叠律】灾主回稳2点命数、攻击+1；之后旧律会轮流追命、压阵、回稳。"
		_:
			return "【军令压阵】灾主攻击+1；之后会持续逼你速决，拖久还会再提攻。"

func _apply_combo_cooldown_pressure(tag_name: String) -> String:
	var candidates: Array[String] = []
	for combo_id in GameState.get_equipped_combos():
		candidates.append(str(combo_id))
	if candidates.is_empty():
		return ""
	var target_id = candidates[randi() % candidates.size()]
	var current_cd = int(GameState.combo_cooldowns.get(target_id, 0))
	GameState.combo_cooldowns[target_id] = current_cd + 1
	var combo_db = _get_combo_database()
	var combo_info = combo_db.get_combo_by_id(target_id) if combo_db != null else null
	var combo_name = _get_combo_name(combo_info) if combo_info != null else target_id
	return " 【%s:%s冷却+1】" % [tag_name, combo_name]

func _apply_song_boss_cooldown_pressure() -> String:
	return _apply_combo_cooldown_pressure("守势延压")

func _get_era_enemy_trait_text() -> String:
	if is_current_battle_boss or current_enemy_data == null:
		return ""
	match GameState.selected_era_id:
		"song":
			if current_enemy_data.ai_type <= 0:
				return "平局回稳1"
			return "平局回稳1 / 3回合压冷却"
		"china":
			if current_enemy_data.ai_type <= 0:
				return "平局回稳1"
			if current_enemy_data.ai_type == 1:
				return "平局回稳1 / 失手追击 / 3回合压冷却"
			return "平局回稳1 / 失手追击 / 3回合压冷却+残烬"
		_:
			if current_enemy_data.ai_type <= 0:
				return ""
			return "失手追击+1"

func _apply_era_boss_phase_bonus(result_label: Label = null) -> void:
	if not is_current_battle_boss or current_enemy_ai == null:
		return
	if current_enemy_ai.boss_phase != 2 or _era_boss_phase_bonus_applied:
		return
	_era_boss_phase_bonus_applied = true
	_boss_phase2_turn_count = 0
	var extra_text = _get_era_boss_phase_bonus_text()
	match GameState.selected_era_id:
		"song":
			battle_enemy_hp = mini(battle_enemy_hp + 2, battle_enemy_max_hp)
			extra_text += _apply_song_boss_cooldown_pressure()
		"china":
			battle_enemy_hp = mini(battle_enemy_hp + 2, battle_enemy_max_hp)
			battle_enemy_atk += 1
			extra_text += _apply_song_boss_cooldown_pressure()
			_era_boss_china_burn_active = true
		_:
			battle_enemy_atk += 1
	if result_label:
		result_label.text += "\n%s" % extra_text

func _apply_era_boss_turn_pressure(player_wins: bool, is_draw: bool, result_text: String) -> String:
	if not is_current_battle_boss or current_enemy_ai == null or current_enemy_ai.boss_phase != 2:
		return result_text
	_boss_phase2_turn_count += 1
	match GameState.selected_era_id:
		"song":
			result_text += _apply_song_boss_cooldown_pressure()
			if is_draw or not player_wins:
				battle_enemy_hp = mini(battle_enemy_hp + 1, battle_enemy_max_hp)
				result_text += " 【守势回稳+1】"
		"china":
			var law_step := ((_boss_phase2_turn_count - 1) % 3) + 1
			match law_step:
				1:
					if not player_wins:
						result_text += _apply_boss_pressure_damage("旧律追命")
				2:
					result_text += _apply_combo_cooldown_pressure("旧律压阵")
				3:
					battle_enemy_hp = mini(battle_enemy_hp + 1, battle_enemy_max_hp)
					_era_boss_china_burn_active = true
					result_text += " 【旧律回稳+1】 【终局余烬】"
		_:
			if not player_wins:
				result_text += _apply_boss_pressure_damage("军令追击")
			if _boss_phase2_turn_count > 0 and _boss_phase2_turn_count % 3 == 0:
				battle_enemy_atk += 1
				result_text += " 【军令迫近:灾主攻击+1】"
	result_text = _apply_boss_adaptation_pressure(player_wins, is_draw, result_text)
	return result_text

func _apply_boss_pressure_damage(tag_name: String) -> String:
	var extra_damage_result = GameState.apply_damage(1, false)
	if int(extra_damage_result.get("actual_damage", 0)) > 0:
		return " 【%s-1命】" % tag_name
	if int(extra_damage_result.get("shield_absorbed", 0)) > 0:
		return " 【%s破盾1】" % tag_name
	return ""

func _get_boss_adaptation_key() -> String:
	if not is_current_battle_boss or current_enemy_ai == null or current_enemy_ai.boss_phase != 2:
		return ""
	var tendency_tags := GameState.get_run_tendency_tags()
	if GameState.field_pending_spend_attack >= 6 and ("economy" in tendency_tags or GameState.has_heirloom("broken_coin")):
		return "loaded_spend"
	if GameState.player_hp <= maxi(2, int(ceil(float(GameState.player_max_hp) * 0.30))) \
		and ("sustain" in tendency_tags or GameState.has_heirloom("blood_contract") or GameState.has_heirloom("afterlife_lamp")):
		return "low_life"
	if GameState.player_shield >= 5 or (GameState.player_shield >= 3 and "defense" in tendency_tags):
		return "armor"
	var recent_start = maxi(0, _player_move_history.size() - 3)
	var recent: Array[int] = []
	for idx in range(recent_start, _player_move_history.size()):
		recent.append(int(_player_move_history[idx]))
	if recent.size() >= 2 and recent.count(1) >= 2:
		return "aggression"
	if recent.size() >= 2 and recent[-1] == recent[-2]:
		return "repeat"
	if _boss_phase2_turn_count >= 4:
		return "stall"
	return ""

func _get_boss_adaptation_preview() -> String:
	match _get_boss_adaptation_key():
		"loaded_spend":
			return "针对｜你蓄着重势，灾主下一拍会削你的蓄势"
		"low_life":
			return "针对｜你在命线边缘，灾主下一拍会追命"
		"armor":
			return "针对｜你护甲已厚，灾主下一拍会先碎甲"
		"aggression":
			return "针对｜你连续抢攻，灾主下一拍会反压失手"
		"repeat":
			return "针对｜你露出重复旧手，灾主下一拍会拖慢布局"
		"stall":
			return "针对｜二阶段拖久了，灾主下一拍会催战回稳"
	return ""

func _apply_boss_adaptation_pressure(player_wins: bool, is_draw: bool, result_text: String) -> String:
	match _get_boss_adaptation_key():
		"loaded_spend":
			var drain := mini(GameState.field_pending_spend_attack, 2)
			if drain > 0:
				GameState.field_pending_spend_attack = maxi(GameState.field_pending_spend_attack - drain, 0)
				result_text += " 【针对破财-%d】" % drain
		"low_life":
			if not player_wins:
				result_text += _apply_boss_pressure_damage("针对追命")
		"armor":
			var crack := mini(GameState.player_shield, 2)
			if crack > 0:
				GameState.reduce_shield(crack)
				result_text += " 【针对碎甲-%d】" % crack
		"aggression":
			if not player_wins:
				result_text += _apply_boss_pressure_damage("针对反压")
		"repeat":
			result_text += _apply_combo_cooldown_pressure("针对旧手")
		"stall":
			if is_draw or not player_wins:
				battle_enemy_hp = mini(battle_enemy_hp + 1, battle_enemy_max_hp)
				result_text += " 【针对回稳+1】"
	return result_text

func _apply_era_enemy_turn_pressure(player_wins: bool, is_draw: bool, result_text: String) -> String:
	if is_current_battle_boss or current_enemy_data == null:
		return result_text
	if is_draw and (GameState.selected_era_id == "song" or GameState.selected_era_id == "china") and battle_enemy_hp > 0:
		battle_enemy_hp = mini(battle_enemy_hp + 1, battle_enemy_max_hp)
		result_text += " 【守势回稳+1】"
	if not is_draw and not player_wins and (GameState.selected_era_id == "qin" or GameState.selected_era_id == "china"):
		if current_enemy_data.ai_type >= 1:
			var extra_damage_result = GameState.apply_damage(1, false)
			if int(extra_damage_result.get("actual_damage", 0)) > 0:
				result_text += " 【敌阵追击-1命】"
			elif int(extra_damage_result.get("shield_absorbed", 0)) > 0:
				result_text += " 【敌阵追击破盾1】"
	if _battle_round_count > 0 and _battle_round_count % 3 == 0 and (GameState.selected_era_id == "song" or GameState.selected_era_id == "china"):
		if current_enemy_data.ai_type >= 1:
			result_text += _apply_combo_cooldown_pressure("阵势压缓")
			if GameState.selected_era_id == "china" and current_enemy_data.ai_type >= 2:
				_era_enemy_china_burn_active = true
				result_text += " 【终局残烬】"
	return result_text

func _get_era_battle_victory_text() -> String:
	match GameState.selected_era_id:
		"song":
			return "🎉 对阵得胜!"
		"china":
			return "🎉 终局得势!"
		_:
			return "🎉 战斗胜利!"

func _get_era_combo_complete_text(combo_name: String, total_damage: int, extra_effect_text: String) -> String:
	match GameState.selected_era_id:
		"song":
			return "⚔️ %s 成式! 造成%d伤害%s" % [combo_name, total_damage, extra_effect_text]
		"china":
			return "⚔️ %s 成局! 造成%d伤害%s" % [combo_name, total_damage, extra_effect_text]
		_:
			return "⚔️ %s 完成! %d伤害%s" % [combo_name, total_damage, extra_effect_text]

func _get_tiger_tally_pressure_damage() -> int:
	if not GameState.has_item("tiger_tally"):
		return 0
	if GameState.player_shield <= 0 or _battle_momentum_score < 1:
		return 0
	return maxi(1, GameState.get_equipment_scaled_int("tiger_tally", 1))

func _apply_trade_ledger_rotation_bonus(battle: Control) -> String:
	if not GameState.has_item("trade_ledger") or _battle_trade_ledger_triggers >= 2:
		return ""
	_battle_trade_ledger_triggers += 1
	GameState.player_gold += 2
	EventBus.player_gold_changed.emit(GameState.player_gold)
	GameState.add_combo_energy(1)
	if battle != null:
		_show_battle_impact(battle, "市舶转手\n+2金", "combo_growth", 7)
		_shift_duel_momentum(battle, 1, "换势入账，势向我")
	return "【市舶转手：金币+2，布势+1】"

func _apply_unity_seal_cheat_momentum(battle: Control, result: String) -> String:
	if not GameState.has_item("unity_seal"):
		return ""
	var parts: Array[String] = ["山河印定势"]
	if battle != null:
		_shift_duel_momentum(battle, 1, "山河印定势")
		_show_battle_impact(battle, "山河定势", "cheat_guard", 8)
	if result == "draw":
		var shield_text := _gain_player_shield(1, battle, "山河护持")
		if shield_text != "":
			parts.append(shield_text)
	return "｜".join(parts)

func _get_combo_database() -> ComboDatabase:
	"""获取或创建 ComboDatabase 实例"""
	if _combo_database_cache == null:
		_combo_database_cache = ComboDatabase.new()
		_combo_database_cache._init_database()  # 手动初始化数据库
	return _combo_database_cache

func _get_era_item_battle_start_text(old_shield: int, old_cheat: int) -> String:
	var parts: Array[String] = []
	if GameState.has_item("tiger_tally"):
		var shield_gain = GameState.player_shield - old_shield
		if shield_gain > 0:
			parts.append("【军令虎符开战得甲+%d】" % shield_gain)
	if GameState.has_item("unity_seal"):
		var cheat_gain = GameState.cheat_points - old_cheat
		if cheat_gain > 0:
			parts.append("【薪火山河印战前机括+%d】" % cheat_gain)
	return "\n".join(parts)

func _get_era_item_battle_start_summary(old_shield: int, old_cheat: int) -> String:
	var parts: Array[String] = []
	if GameState.has_item("tiger_tally"):
		var shield_gain = GameState.player_shield - old_shield
		if shield_gain > 0:
			parts.append("甲+%d" % shield_gain)
	if GameState.has_item("unity_seal"):
		var cheat_gain = GameState.cheat_points - old_cheat
		if cheat_gain > 0:
			parts.append("机括+%d" % cheat_gain)
	if parts.is_empty():
		return ""
	return "起手：%s" % " / ".join(parts)

func _compact_battle_status_text(status_text: String) -> String:
	var compact := status_text.replace("\n", " ").strip_edges()
	var replacements := {
		"【残烬-1命】": "残烬-1",
		"【残烬灼盾1】": "残烬灼盾1",
		"【终局余烬-1命】": "余烬-1",
		"【终局余烬灼盾1】": "余烬灼盾1",
		"【军令追击-1命】": "追击-1",
		"【军令追击破盾1】": "追击破盾1",
		"🔥灼烧-": "灼烧-",
		" 【": " ",
		"】": "",
		"!": "",
		"  ": " "
	}
	for key in replacements.keys():
		compact = compact.replace(key, replacements[key])
	return compact.strip_edges()

func _append_era_item_victory_text(result_label: Label, hp_before: int) -> void:
	if result_label == null:
		return
	if GameState.has_item("unity_seal"):
		var healed = GameState.player_hp - hp_before
		if healed > 0:
			result_label.text += "\n【薪火山河印胜后回命+%d】" % healed

func _is_current_battle_difficult() -> bool:
	if is_current_battle_boss:
		return true
	return current_enemy_data != null and current_enemy_data.ai_type >= 1

func _apply_difficult_battle_victory_growth(result_label: Label) -> void:
	if not _is_current_battle_difficult():
		return
	var hp_gain := GameState.on_difficult_battle_won()
	if hp_gain > 0 and result_label != null:
		result_label.text += "\n【魂魄收集者 命数上限+%d】" % hp_gain

func _show_battle(is_boss: bool, map_node: Dictionary = {}):
	DebugLog.log("Battle, is_boss: ", is_boss)
	_change_state(State.BATTLE)
	_switch_scene_music("battle")

	# 保存是否是BOSS战斗
	is_current_battle_boss = is_boss
	_era_boss_phase_bonus_applied = false
	_era_boss_china_burn_active = false
	_era_enemy_china_burn_active = false
	_battle_round_count = 0
	_boss_phase2_turn_count = 0
	_battle_enemy_poison = 0
	battle_support_enemies.clear()
	_heart_armor_temp_shield = 0
	_poison_relic_triggered_this_turn = false

	# 重置战斗结束锁
	_battle_ending = false

	# 战前准备：处理精确辅助系统（将生命转化为护甲）
	var prebattle_shield = GameState.player_shield
	var prebattle_cheat = GameState.cheat_points
	GameState.setup_pre_battle()

	# 生成敌人数据
	DebugLog.log("Generating enemy data...")
	var enemy_data: EnemyData
	if is_boss:
		enemy_data = EnemyData.generate_boss()
	elif not map_node.is_empty():
		enemy_data = EnemyData.generate_for_history_node(GameState.current_floor, map_node)
	else:
		enemy_data = EnemyData.generate_by_floor(GameState.current_floor)
	enemy_data = _apply_era_enemy_modifiers(enemy_data, is_boss)
	DebugLog.log("Enemy data generated: ", enemy_data.display_name, " route=", str(map_node.get("route_name", "")), " ai=", enemy_data.ai_type, "/", enemy_data.ai_subtype)

	current_enemy_data = enemy_data
	battle_enemy_max_hp = enemy_data.max_hp
	battle_enemy_atk = enemy_data.attack
	battle_enemy_hp = battle_enemy_max_hp
	battle_support_enemies = _build_battle_support_enemies(map_node, is_boss, enemy_data)

	# 创建AI
	DebugLog.log("Creating enemy AI...")
	_dispose_current_enemy_ai()
	var enemy_ai = EnemyAI.new()
	DebugLog.log("AI created, setting up...")
	_setup_enemy_ai(enemy_ai, enemy_data)
	DebugLog.log("AI setup completed")
	current_enemy_ai = enemy_ai

	combo_sequence.clear()
	_player_move_history.clear()
	_enemy_move_history.clear()
	_battle_build_signals_seen.clear()
	_battle_combo_repeat_counts.clear()
	_battle_last_combo_family = ""
	_battle_combo_family_streak = 0
	_battle_momentum_score = 0
	_battle_trade_ledger_triggers = 0
	_battle_read_streak = 0
	_battle_ending = false  # 重置战斗结束锁

	DebugLog.log("Creating battle UI...")
	var battle = _create_battle_ui(enemy_data, enemy_ai, prebattle_shield, prebattle_cheat)
	DebugLog.log("Battle UI created, adding to scene...")
	_add_ui(battle)
	DebugLog.log("Battle UI added successfully")

func _setup_enemy_ai(ai: EnemyAI, data: EnemyData):
	"""配置敌人AI"""
	DebugLog.log("Setting up AI type: ", data.ai_type, " subtype: ", data.ai_subtype)
	match data.ai_type:
		0: # 基础：固定套路
			DebugLog.log("Setting up BASIC_FIXED with move: ", data.ai_subtype)
			ai.setup_basic_fixed(data.ai_subtype)
		1: # 精英：双招循环（5种模式）
			DebugLog.log("Setting up ELITE_CYCLE subtype: ", data.ai_subtype)
			ai.setup_elite_by_subtype(data.ai_subtype)
		2: # 高级：三招策略（5种模式）
			DebugLog.log("Setting up ADVANCED_DYNAMIC subtype: ", data.ai_subtype)
			ai.setup_advanced_dynamic(data.ai_subtype)
		3: # BOSS：阶段死局
			DebugLog.log("Setting up BOSS")
			ai.setup_boss()
		_:
			DebugLog.log("Unknown AI type: ", data.ai_type)

func _build_battle_support_enemies(map_node: Dictionary, is_boss: bool, main_enemy: EnemyData) -> Array[Dictionary]:
	var supports: Array[Dictionary] = []
	var support_count := int(map_node.get("support_count", 0))
	if support_count <= 0:
		support_count = maxi(int(map_node.get("enemy_group_size", 1)) - 1, 0)
	if is_boss:
		support_count = 0
	support_count = clamp(support_count, 0, 2)
	for i in range(support_count):
		var role := _get_support_enemy_role(i, map_node)
		var max_hp := maxi(2, int(round(float(main_enemy.max_hp) * (0.34 if support_count == 1 else 0.28))) + i)
		var attack := 1
		supports.append({
			"id": "support_%d" % i,
			"name": _get_support_enemy_name(role),
			"role": role,
			"hp": max_hp,
			"max_hp": max_hp,
			"attack": attack,
			"assist": attack,
			"suppressed": false
		})
	return supports

func _get_support_enemy_role(index: int, map_node: Dictionary) -> String:
	var route := str(map_node.get("route_name", ""))
	if route.find("危") >= 0:
		return "raider" if index == 0 else "archer"
	if route.find("商") >= 0 or route.find("十国") >= 0:
		return "taxman" if index == 0 else "guard"
	if route.find("近攻") >= 0 or route.find("主战") >= 0:
		return "shield" if index == 0 else "raider"
	return "guard" if index == 0 else "archer"

func _get_support_enemy_name(role: String) -> String:
	match role:
		"shield":
			return "盾兵"
		"raider":
			return "突骑"
		"archer":
			return "弓手"
		"taxman":
			return "税吏"
		_:
			return "护卫"

func _create_support_enemy_status_ui(battle: Control, era_theme: Dictionary) -> void:
	var formation_panel = Panel.new()
	formation_panel.name = "EnemyFormationPanel"
	formation_panel.position = Vector2(650, 166)
	formation_panel.size = Vector2(262, 132)
	formation_panel.visible = not battle_support_enemies.is_empty()
	formation_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	formation_panel.z_index = 62
	var formation_style = StyleBoxFlat.new()
	formation_style.bg_color = Color(0.12, 0.07, 0.055, 0.94)
	formation_style.border_color = Color(1.0, 0.56, 0.28, 0.95)
	formation_style.set_border_width_all(2)
	formation_style.corner_radius_top_left = 12
	formation_style.corner_radius_top_right = 12
	formation_style.corner_radius_bottom_left = 12
	formation_style.corner_radius_bottom_right = 12
	formation_panel.add_theme_stylebox_override("panel", formation_style)
	battle.add_child(formation_panel)

	var formation_title = Label.new()
	formation_title.name = "EnemyFormationTitle"
	formation_title.text = _get_enemy_formation_title_text()
	formation_title.position = Vector2(664, 174)
	formation_title.custom_minimum_size = Vector2(234, 18)
	formation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formation_title.add_theme_font_size_override("font_size", 15)
	formation_title.modulate = Color(1.0, 0.76, 0.42, 0.98)
	formation_title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	formation_title.add_theme_constant_override("outline_size", 2)
	formation_title.visible = not battle_support_enemies.is_empty()
	formation_title.z_index = 63
	battle.add_child(formation_title)

	var formation_mode = Label.new()
	formation_mode.name = "EnemyFormationMode"
	formation_mode.text = _get_enemy_formation_mode_text()
	formation_mode.position = Vector2(664, 194)
	formation_mode.custom_minimum_size = Vector2(234, 16)
	formation_mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formation_mode.add_theme_font_size_override("font_size", 10)
	formation_mode.modulate = Color(1.0, 0.88, 0.66, 0.82)
	formation_mode.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.01, 1.0))
	formation_mode.add_theme_constant_override("outline_size", 1)
	formation_mode.visible = not battle_support_enemies.is_empty()
	formation_mode.z_index = 63
	battle.add_child(formation_mode)

	for i in range(2):
		var card = Panel.new()
		card.name = "SupportCard%d" % i
		card.position = _get_support_card_base_position(i)
		card.size = Vector2(112, 74)
		card.visible = i < battle_support_enemies.size()
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.z_index = 64
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.20, 0.10, 0.08, 0.96)
		card_style.border_color = Color(0.94, 0.46, 0.24, 0.96)
		card_style.set_border_width_all(1)
		card_style.corner_radius_top_left = 9
		card_style.corner_radius_top_right = 9
		card_style.corner_radius_bottom_left = 9
		card_style.corner_radius_bottom_right = 9
		card.add_theme_stylebox_override("panel", card_style)
		battle.add_child(card)

		var name_label = Label.new()
		name_label.name = "SupportName%d" % i
		name_label.position = card.position + Vector2(8, 5)
		name_label.custom_minimum_size = Vector2(96, 16)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.modulate = Color(1.0, 0.82, 0.58, 0.96)
		name_label.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		name_label.add_theme_constant_override("outline_size", 1)
		name_label.visible = card.visible
		name_label.z_index = 65
		battle.add_child(name_label)

		var hp_bar = ProgressBar.new()
		hp_bar.name = "SupportHPBar%d" % i
		hp_bar.position = card.position + Vector2(10, 27)
		hp_bar.custom_minimum_size = Vector2(92, 12)
		hp_bar.show_percentage = false
		hp_bar.modulate = Color(0.98, 0.58, 0.46, 1.0)
		hp_bar.visible = card.visible
		hp_bar.z_index = 65
		battle.add_child(hp_bar)

		var hp_label = Label.new()
		hp_label.name = "SupportHP%d" % i
		hp_label.position = card.position + Vector2(10, 24)
		hp_label.custom_minimum_size = Vector2(92, 18)
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.add_theme_font_size_override("font_size", 9)
		hp_label.modulate = Color(1.0, 0.94, 0.90, 0.94)
		hp_label.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.01, 1.0))
		hp_label.add_theme_constant_override("outline_size", 1)
		hp_label.visible = card.visible
		hp_label.z_index = 66
		battle.add_child(hp_label)

		var assist_label = Label.new()
		assist_label.name = "SupportAssist%d" % i
		assist_label.position = card.position + Vector2(8, 47)
		assist_label.custom_minimum_size = Vector2(96, 20)
		assist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		assist_label.add_theme_font_size_override("font_size", 11)
		assist_label.modulate = Color(1.0, 0.70, 0.44, 0.95)
		assist_label.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.01, 1.0))
		assist_label.add_theme_constant_override("outline_size", 1)
		assist_label.visible = card.visible
		assist_label.z_index = 65
		battle.add_child(assist_label)

	_update_support_enemy_ui(battle)

func _create_battle_ui(enemy_data: EnemyData, enemy_ai: EnemyAI, prebattle_shield: int = 0, prebattle_cheat: int = 0):
	var battle = Control.new()
	battle.name = "BattleScene"
	battle.custom_minimum_size = Vector2(1280, 720)
	var era_theme = GameState.get_era_theme()

	# ===== 背景 =====
	var bg = ColorRect.new()
	bg.color = era_theme.get("bg", Color(0.12, 0.12, 0.18))
	bg.offset_right = 1280
	bg.offset_bottom = 720
	battle.add_child(bg)
	var battle_bg_texture = _get_era_battle_bg_texture()
	if battle_bg_texture != null:
		var battle_bg = TextureRect.new()
		battle_bg.name = "EraBattleBackground"
		battle_bg.texture = battle_bg_texture
		battle_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		battle_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		battle_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		battle_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		battle_bg.modulate = Color(1, 1, 1, 0.96)
		battle.add_child(battle_bg)
	var battle_seal_texture = _get_era_battle_seal_texture()
	if battle_seal_texture != null:
		var battle_seal = TextureRect.new()
		battle_seal.name = "EraBattleSeal"
		battle_seal.texture = battle_seal_texture
		battle_seal.position = Vector2(756, 8)
		battle_seal.custom_minimum_size = Vector2(142, 42)
		battle_seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		battle_seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		battle_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		battle_seal.modulate = Color(1, 1, 1, 0.92)
		battle.add_child(battle_seal)

	var class_names = ["医生", "黑客", "商人", "农民", "流浪者"]

	# ===== 顶部信息栏 =====
	var top_bar = ColorRect.new()
	top_bar.color = era_theme.get("panel", Color(0.08, 0.08, 0.12, 0.9))
	top_bar.offset_right = 1280
	top_bar.offset_bottom = 58
	battle.add_child(top_bar)
	var top_accent = ColorRect.new()
	top_accent.color = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	top_accent.position = Vector2(140, 50)
	top_accent.custom_minimum_size = Vector2(1000, 6)
	battle.add_child(top_accent)

	var floor_label = Label.new()
	floor_label.text = "🗼 第 %d / %d 层" % [GameState.current_floor + 1, GameState.max_floors]
	var floor_chip = Panel.new()
	floor_chip.position = Vector2(16, 10)
	floor_chip.size = Vector2(170, 32)
	var floor_chip_style = StyleBoxFlat.new()
	floor_chip_style.bg_color = Color(0.10, 0.10, 0.12, 0.92)
	floor_chip_style.border_color = Color(1, 1, 1, 0.06)
	floor_chip_style.set_border_width_all(1)
	floor_chip_style.corner_radius_top_left = 10
	floor_chip_style.corner_radius_top_right = 10
	floor_chip_style.corner_radius_bottom_left = 10
	floor_chip_style.corner_radius_bottom_right = 10
	floor_chip.add_theme_stylebox_override("panel", floor_chip_style)
	battle.add_child(floor_chip)
	floor_label.position = Vector2(20, 14)
	floor_label.custom_minimum_size = Vector2(162, 22)
	floor_label.add_theme_font_size_override("font_size", 18)
	floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floor_label.modulate = era_theme.get("title", Color(1, 0.9, 0.6))
	floor_label.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	floor_label.add_theme_constant_override("outline_size", 1)
	battle.add_child(floor_label)

	var top_class = Label.new()
	top_class.text = "🧑 %s | %s" % [class_names[GameState.player_class], GameState.get_level_progress_text()]
	var class_chip = Panel.new()
	class_chip.position = Vector2(252, 10)
	class_chip.size = Vector2(248, 32)
	var class_chip_style = floor_chip_style.duplicate()
	class_chip.add_theme_stylebox_override("panel", class_chip_style)
	battle.add_child(class_chip)
	top_class.position = Vector2(260, 14)
	top_class.custom_minimum_size = Vector2(232, 22)
	top_class.add_theme_font_size_override("font_size", 18)
	top_class.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_class.modulate = Color(0.8, 0.8, 0.8)
	top_class.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	top_class.add_theme_constant_override("outline_size", 1)
	battle.add_child(top_class)

	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "💰 %d" % GameState.player_gold
	var gold_chip = Panel.new()
	gold_chip.position = Vector2(530, 10)
	gold_chip.size = Vector2(100, 32)
	var gold_chip_style = floor_chip_style.duplicate()
	gold_chip.add_theme_stylebox_override("panel", gold_chip_style)
	battle.add_child(gold_chip)
	gold_label.position = Vector2(538, 14)
	gold_label.custom_minimum_size = Vector2(84, 22)
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.modulate = Color(1, 0.85, 0.3)
	gold_label.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	gold_label.add_theme_constant_override("outline_size", 1)
	battle.add_child(gold_label)

	var materials_top_label = Label.new()
	materials_top_label.name = "MaterialsLabel"
	materials_top_label.text = ""
	var materials_chip = Panel.new()
	materials_chip.position = Vector2(642, 10)
	materials_chip.size = Vector2(100, 32)
	var materials_chip_style = floor_chip_style.duplicate()
	materials_chip.add_theme_stylebox_override("panel", materials_chip_style)
	materials_chip.visible = false
	battle.add_child(materials_chip)
	materials_top_label.position = Vector2(650, 14)
	materials_top_label.custom_minimum_size = Vector2(84, 22)
	materials_top_label.add_theme_font_size_override("font_size", 18)
	materials_top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	materials_top_label.modulate = Color(0.9, 0.8, 0.4)
	materials_top_label.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	materials_top_label.add_theme_constant_override("outline_size", 1)
	materials_top_label.visible = false
	battle.add_child(materials_top_label)

	var sys_dock = Panel.new()
	sys_dock.position = Vector2(942, 8)
	sys_dock.size = Vector2(300, 38)
	var sys_dock_style = StyleBoxFlat.new()
	sys_dock_style.bg_color = Color(0.10, 0.10, 0.12, 0.92)
	sys_dock_style.border_color = Color(1, 1, 1, 0.06)
	sys_dock_style.set_border_width_all(1)
	sys_dock_style.corner_radius_top_left = 10
	sys_dock_style.corner_radius_top_right = 10
	sys_dock_style.corner_radius_bottom_left = 10
	sys_dock_style.corner_radius_bottom_right = 10
	sys_dock.add_theme_stylebox_override("panel", sys_dock_style)
	battle.add_child(sys_dock)

	var sys_labels = ["设置", "规则", "音量", "速度"]
	for i in range(sys_labels.size()):
		var sys_btn = Button.new()
		sys_btn.text = sys_labels[i]
		sys_btn.custom_minimum_size = Vector2(64, 24)
		sys_btn.position = Vector2(950 + i * 72, 15)
		sys_btn.add_theme_font_size_override("font_size", 12)
		sys_btn.modulate = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lerp(Color.WHITE, 0.15)
		sys_btn.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		sys_btn.add_theme_constant_override("outline_size", 1)
		match i:
			0:
				sys_btn.pressed.connect(func(): _show_battle_system_hint(battle, GameState.get_settings_status_text()))
			1:
				sys_btn.pressed.connect(func(): _show_battle_system_hint(battle, "%s | 布局胜者造成攻击伤害" % MoveSymbols.matchup_hint()))
			2:
				sys_btn.pressed.connect(func(): _toggle_battle_mute(battle))
			3:
				sys_btn.pressed.connect(func(): _toggle_battle_speed(battle))
		battle.add_child(sys_btn)

	# ===== 左侧：玩家信息面板 =====
	var player_panel = ColorRect.new()
	player_panel.color = Color(0.15, 0.2, 0.15, 0.82)
	player_panel.position = Vector2(15, 72)
	player_panel.custom_minimum_size = Vector2(320, 350)
	player_panel.offset_right = 335
	player_panel.offset_bottom = 422
	battle.add_child(player_panel)

	var player_portrait_panel = Panel.new()
	player_portrait_panel.name = "PlayerPortraitPanel"
	player_portrait_panel.position = Vector2(48, 162)
	player_portrait_panel.size = Vector2(240, 238)
	var player_portrait_style = StyleBoxFlat.new()
	player_portrait_style.bg_color = Color(0.08, 0.14, 0.10, 0.86)
	player_portrait_style.border_color = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lerp(Color(0.56, 1.0, 0.70, 1.0), 0.42)
	player_portrait_style.set_border_width_all(2)
	player_portrait_style.corner_radius_top_left = 8
	player_portrait_style.corner_radius_top_right = 8
	player_portrait_style.corner_radius_bottom_left = 8
	player_portrait_style.corner_radius_bottom_right = 8
	player_portrait_panel.add_theme_stylebox_override("panel", player_portrait_style)
	player_portrait_panel.set_meta("base_style", player_portrait_style.duplicate())
	player_portrait_panel.set_meta("momentum_owner", "player")
	battle.add_child(player_portrait_panel)

	var player_portrait = TextureRect.new()
	player_portrait.name = "PlayerPortrait"
	player_portrait.texture = _load_character_portrait(GameState.player_class)
	player_portrait.position = Vector2(58, 172)
	player_portrait.custom_minimum_size = Vector2(220, 218)
	player_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_portrait.modulate = Color(1, 1, 1, 0.96)
	player_portrait.visible = true
	battle.add_child(player_portrait)

	var player_momentum_field = MomentumField.new()
	player_momentum_field.name = "PlayerMomentumField"
	player_momentum_field.position = Vector2(58, 172)
	player_momentum_field.custom_minimum_size = Vector2(220, 218)
	player_momentum_field.size = Vector2(220, 218)
	player_momentum_field.z_index = 18
	player_momentum_field.setup(era_theme, "player")
	battle.add_child(player_momentum_field)

	var player_hp_title = Label.new()
	player_hp_title.text = ""
	player_hp_title.position = Vector2(126, 80)
	player_hp_title.custom_minimum_size = Vector2(100, 16)
	player_hp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hp_title.add_theme_font_size_override("font_size", 11)
	player_hp_title.modulate = Color(0.88, 0.82, 0.82)
	player_hp_title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	player_hp_title.add_theme_constant_override("outline_size", 1)
	battle.add_child(player_hp_title)

	var player_hp_bar = ProgressBar.new()
	player_hp_bar.name = "PlayerHPBar"
	player_hp_bar.min_value = 0
	player_hp_bar.max_value = GameState.player_max_hp
	player_hp_bar.value = GameState.player_hp
	player_hp_bar.position = Vector2(38, 98)
	player_hp_bar.custom_minimum_size = Vector2(284, 20)
	player_hp_bar.show_percentage = false
	player_hp_bar.modulate = Color(1.0, 0.78, 0.80, 1.0)
	battle.add_child(player_hp_bar)

	var player_hp = Label.new()
	player_hp.name = "PlayerHP"
	player_hp.text = "%d / %d" % [GameState.player_hp, GameState.player_max_hp]
	player_hp.position = Vector2(22, 94)
	player_hp.custom_minimum_size = Vector2(290, 30)
	player_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hp.add_theme_font_size_override("font_size", 15)
	player_hp.modulate = Color(1, 0.94, 0.94)
	player_hp.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	player_hp.add_theme_constant_override("outline_size", 1)
	battle.add_child(player_hp)

	var player_atk_card = Panel.new()
	player_atk_card.position = Vector2(129, 122)
	player_atk_card.size = Vector2(86, 28)
	var player_atk_style = StyleBoxFlat.new()
	player_atk_style.bg_color = Color(0.20, 0.10, 0.10, 0.88)
	player_atk_style.border_color = Color(0.78, 0.42, 0.42, 1.0)
	player_atk_style.set_border_width_all(1)
	player_atk_style.corner_radius_top_left = 7
	player_atk_style.corner_radius_top_right = 7
	player_atk_style.corner_radius_bottom_left = 7
	player_atk_style.corner_radius_bottom_right = 7
	player_atk_card.add_theme_stylebox_override("panel", player_atk_style)
	battle.add_child(player_atk_card)

	var player_atk = Label.new()
	player_atk.name = "PlayerAtk"
	player_atk.text = "⚔ %d" % GameState.get_total_attack()
	player_atk.position = Vector2(129, 126)
	player_atk.custom_minimum_size = Vector2(86, 20)
	player_atk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_atk.add_theme_font_size_override("font_size", 14)
	player_atk.modulate = Color(1, 0.7, 0.7)
	player_atk.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	player_atk.add_theme_constant_override("outline_size", 1)
	battle.add_child(player_atk)

	var player_shield_card = Panel.new()
	player_shield_card.position = Vector2(216, 122)
	player_shield_card.size = Vector2(86, 28)
	var player_shield_style = StyleBoxFlat.new()
	player_shield_style.bg_color = Color(0.10, 0.14, 0.22, 0.88)
	player_shield_style.border_color = Color(0.46, 0.72, 1.0, 1.0)
	player_shield_style.set_border_width_all(1)
	player_shield_style.corner_radius_top_left = 7
	player_shield_style.corner_radius_top_right = 7
	player_shield_style.corner_radius_bottom_left = 7
	player_shield_style.corner_radius_bottom_right = 7
	player_shield_card.add_theme_stylebox_override("panel", player_shield_style)
	battle.add_child(player_shield_card)

	var player_shield = Label.new()
	player_shield.name = "PlayerShield"
	player_shield.text = "🛡 %d" % GameState.player_shield
	player_shield.position = Vector2(216, 126)
	player_shield.custom_minimum_size = Vector2(86, 20)
	player_shield.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_shield.add_theme_font_size_override("font_size", 14)
	player_shield.modulate = Color(0.6, 0.8, 1)
	player_shield.visible = GameState.player_shield > 0
	player_shield.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	player_shield.add_theme_constant_override("outline_size", 1)
	battle.add_child(player_shield)

	var equipped_names: Array[String] = []
	var equipped_item_dicts: Array = []
	for item in GameState.equipment_slot:
		if GameState.is_era_item(item):
			continue
		equipped_names.append(_get_battle_item_row_text(item))
		equipped_item_dicts.append(item)

	var backpack_names: Array[String] = []
	for item in GameState.backpack:
		backpack_names.append(_get_battle_item_row_text(item))

	var era_items: Array[String] = []
	var era_item_dicts: Array = []
	for item in GameState.equipment_slot:
		if GameState.is_era_item(item):
			era_items.append(_get_battle_item_row_text(item))
			era_item_dicts.append(item)
	var heirloom_data := GameState.get_heirloom_data(GameState.selected_heirloom_id)
	var heirloom_rows: Array[String] = []
	var heirloom_tooltip := "未携带传家宝"
	if not heirloom_data.is_empty():
		heirloom_rows.append(str(heirloom_data.get("name", "传家宝")))
		heirloom_rows.append(GameState.get_heirloom_status_text())
		heirloom_tooltip = GameState.get_heirloom_detail_text()

	var item_card_specs = [
		{
			"title": "传家宝",
			"name": "HeirloomLabel",
			"rows": heirloom_rows,
			"items": [],
			"tooltip": heirloom_tooltip,
			"color": Color(1.0, 0.86, 0.52),
			"border": Color(0.88, 0.68, 0.32, 1.0),
				"x": 958,
				"y": 430,
				"h": 58,
			"lines": 2,
			"empty": "（未携带）",
			"per_line": 1
		},
		{
			"title": "时代秘器物",
			"name": "EraItemsLabel",
			"rows": era_items,
			"items": era_item_dicts,
			"color": Color(0.92, 0.82, 0.58),
			"border": Color(0.78, 0.66, 0.38, 1.0),
				"x": 958,
				"y": 492,
				"h": 58,
			"lines": 0,
			"empty": "（无）",
			"per_line": 2
		},
		{
			"title": "装备栏",
			"name": "ItemsLabel",
			"rows": equipped_names,
			"items": equipped_item_dicts,
			"color": Color(0.72, 0.72, 0.66),
			"border": Color(0.46, 0.46, 0.42, 1.0),
				"x": 958,
				"y": 554,
				"h": 64,
				"lines": 0,
			"empty": "（空）",
			"per_line": 2
		},
		{
			"title": "背包栏",
			"name": "BackpackLabel",
			"rows": backpack_names,
			"items": GameState.backpack,
			"color": Color(0.72, 0.72, 0.66),
			"border": Color(0.50, 0.48, 0.40, 1.0),
				"x": 958,
				"y": 622,
				"h": 82,
			"lines": 0,
			"empty": "（空）",
			"per_line": 2
		}
	]
	var item_nodes: Array[CanvasItem] = []

	var item_section_line = ColorRect.new()
	item_section_line.color = Color(1, 1, 1, 0.08)
	item_section_line.position = Vector2(970, 422)
	item_section_line.custom_minimum_size = Vector2(270, 1)
	battle.add_child(item_section_line)
	item_nodes.append(item_section_line)

	var item_section_title = Label.new()
	item_section_title.text = "器物"
	item_section_title.position = Vector2(966, 406)
	item_section_title.custom_minimum_size = Vector2(272, 22)
	item_section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_section_title.add_theme_font_size_override("font_size", 14)
	item_section_title.modulate = Color(0.92, 0.82, 0.70, 0.82)
	battle.add_child(item_section_title)
	item_nodes.append(item_section_title)

	for spec in item_card_specs:
		var item_tooltip := str(spec.get("tooltip", _get_item_list_tooltip(spec.get("items", []), str(spec["empty"]), str(spec["title"]))))
		var item_card = Panel.new()
		item_card.name = "%sCard" % str(spec["name"]).trim_suffix("Label")
		item_card.position = Vector2(int(spec["x"]), int(spec["y"]))
		item_card.size = Vector2(290, int(spec["h"]))
		var item_style = StyleBoxFlat.new()
		item_style.bg_color = Color(0.12, 0.14, 0.16, 0.86)
		item_style.border_color = spec["border"]
		item_style.set_border_width_all(1)
		item_style.corner_radius_top_left = 8
		item_style.corner_radius_top_right = 8
		item_style.corner_radius_bottom_left = 8
		item_style.corner_radius_bottom_right = 8
		item_card.add_theme_stylebox_override("panel", item_style)
		item_card.mouse_filter = Control.MOUSE_FILTER_STOP
		item_card.tooltip_text = item_tooltip
		battle.add_child(item_card)
		item_nodes.append(item_card)

		var item_title = Label.new()
		item_title.text = str(spec["title"])
		item_title.tooltip_text = ""
		item_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_title.position = Vector2(int(spec["x"]) + 10, int(spec["y"]) + 6)
		item_title.custom_minimum_size = Vector2(118, 14)
		item_title.add_theme_font_size_override("font_size", 10)
		item_title.modulate = Color(spec["border"].r, spec["border"].g, spec["border"].b, 0.78)
		item_title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		item_title.add_theme_constant_override("outline_size", 1)
		battle.add_child(item_title)
		item_nodes.append(item_title)

		var item_body = Label.new()
		item_body.name = str(spec["name"])
		item_body.text = _summarize_text_rows(spec["rows"], str(spec["empty"]), int(spec["lines"]), int(spec["per_line"]))
		item_body.tooltip_text = ""
		item_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_body.position = Vector2(int(spec["x"]) + 10, int(spec["y"]) + 21)
		item_body.custom_minimum_size = Vector2(270, int(spec["h"]) - 24)
		item_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_body.add_theme_font_size_override("font_size", 8)
		item_body.clip_text = true
		item_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		item_body.modulate = spec["color"] if not spec["rows"].is_empty() else Color(0.52, 0.52, 0.52)
		battle.add_child(item_body)
		item_nodes.append(item_body)

	_update_heirloom_cashout_preview(battle)

	# 连招信息
	var split_line = ColorRect.new()
	split_line.color = Color(1, 1, 1, 0.10)
	split_line.position = Vector2(38, 424)
	split_line.custom_minimum_size = Vector2(280, 1)
	battle.add_child(split_line)

	var layout_title = Label.new()
	layout_title.text = "布局详情"
	layout_title.position = Vector2(34, 408)
	layout_title.custom_minimum_size = Vector2(272, 22)
	layout_title.add_theme_font_size_override("font_size", 18)
	layout_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout_title.modulate = Color(0.9, 1, 0.9)
	layout_title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	layout_title.add_theme_constant_override("outline_size", 1)
	battle.add_child(layout_title)

	var combo_y = 432
	var combo_db_ref = _get_combo_database()

	var equipped_combo_rows: Array[String] = []
	var equipped_combo_tooltips: Array[String] = []
	for cid in GameState.get_equipped_combos():
		var cd = combo_db_ref.get_combo_by_id(cid)
		if cd:
			var seq_text: String = ComboData.sequence_to_string(cd.sequence)
			var upgrade_text: String = _get_layout_display_upgrade_text(cd)
			var actual_effect_value := _get_layout_display_effect_value(cd, str(cd.effect_type), int(cd.effect_value))
			var row = _format_layout_combo_row(
				seq_text,
				cd.name,
				cd.description,
				cd.effect_type,
				actual_effect_value,
				int(cd.cooldown),
				upgrade_text
			)
			equipped_combo_tooltips.append(_format_layout_combo_tooltip(
				"携带布局",
				seq_text,
				cd.name,
				cd.description,
				cd.effect_type,
				actual_effect_value,
				int(cd.cooldown),
				upgrade_text
			))
			equipped_combo_rows.append(row)
		else:
			var cc = combo_db_ref.get_combat_combo_by_id(cid)
			if cc:
				var seq_text: String = combo_db_ref.combat_combo_sequence_to_display(cc.sequence)
				var actual_cost := maxi(int(cc.energy_cost) - GameState.get_combo_energy_reduction(str(cc.id)), 2)
				var row = "%s %s｜%s" % [
					seq_text,
					cc.name,
					_get_combat_combo_brief(cc, actual_cost)
				]
				equipped_combo_tooltips.append(_get_combat_combo_tooltip(cc, seq_text, actual_cost, true))
				equipped_combo_rows.append(row)

	var excl_combo_rows: Array[String] = []
	var excl_combo_tooltips: Array[String] = []
	var excl_combos = ComboData.get_exclusive_combos(class_names[GameState.player_class])
	for combo in excl_combos:
		var seq_text: String = ComboData.sequence_to_string(combo.sequence)
		var upgrade_text := _get_layout_display_upgrade_text(combo)
		var actual_effect_value := _get_layout_display_effect_value(combo, str(combo.effect_type), int(combo.effect_value))
		excl_combo_rows.append(_format_layout_combo_row(
			seq_text,
			combo.display_name,
			combo.description,
			combo.effect_type,
			actual_effect_value,
			int(combo.cooldown),
			upgrade_text
		))
		excl_combo_tooltips.append(_format_layout_combo_tooltip(
			"角色专属",
			seq_text,
			combo.display_name,
			combo.description,
			combo.effect_type,
			actual_effect_value,
			int(combo.cooldown),
			upgrade_text
		))

	var weapon_combo_rows: Array[String] = []
	var weapon_combo_tooltips: Array[String] = []
	for item in GameState.equipment_slot:
		if item.has("exclusive_combo") and item.exclusive_combo != "":
			var wc = combo_db_ref.get_combo_by_id(item.exclusive_combo)
			if wc:
				var seq_ws: String = combo_db_ref.sequence_to_display(wc.sequence) if wc.get("sequence") != null else ""
				var upgrade_text := _get_layout_display_upgrade_text(wc)
				var actual_effect_value := _get_layout_display_effect_value(wc, str(wc.effect_type), int(wc.effect_value))
				weapon_combo_rows.append(_format_layout_combo_row(
					seq_ws,
					wc.name,
					wc.description,
					wc.effect_type,
					actual_effect_value,
					int(wc.cooldown),
					upgrade_text
				))
				weapon_combo_tooltips.append(_format_layout_combo_tooltip(
					"武器专属",
					seq_ws,
					wc.name,
					wc.description,
					wc.effect_type,
					actual_effect_value,
					int(wc.cooldown),
					upgrade_text
				))
	var equipped_tooltip_text := "携带布局\n（无）" if equipped_combo_tooltips.is_empty() else "\n——\n".join(equipped_combo_tooltips)
	var excl_tooltip_text := "角色专属\n（无）" if excl_combo_tooltips.is_empty() else "\n——\n".join(excl_combo_tooltips)
	var weapon_tooltip_text := "武器专属\n（无）" if weapon_combo_tooltips.is_empty() else "\n——\n".join(weapon_combo_tooltips)

	var card_specs = [
		{
			"title": "携带布局",
			"name": "EquippedCombosLabel",
			"rows": equipped_combo_rows,
			"tooltip": equipped_tooltip_text,
			"color": Color(0.9, 0.8, 0.5),
			"border": Color(0.72, 0.56, 0.24, 1.0),
			"y": combo_y,
			"h": 120,
			"lines": 0
		},
		{
			"title": "角色专属",
			"name": "ClassExclusiveLabel",
			"rows": excl_combo_rows,
			"tooltip": excl_tooltip_text,
			"color": Color(0.64, 0.85, 1.0),
			"border": Color(0.34, 0.58, 0.92, 1.0),
			"y": combo_y + 126,
			"h": 58,
			"lines": 0
		},
		{
			"title": "武器专属",
			"name": "WeaponExclusiveLabel",
			"rows": weapon_combo_rows,
			"tooltip": weapon_tooltip_text,
			"color": Color(0.9, 0.68, 0.92),
			"border": Color(0.66, 0.42, 0.74, 1.0),
			"y": combo_y + 190,
			"h": 78,
			"lines": 0
		}
	]

	for spec in card_specs:
		var card = Panel.new()
		card.name = "%sCard" % str(spec["name"]).replace("Label", "")
		card.position = Vector2(22, int(spec["y"]))
		card.size = Vector2(296, int(spec["h"]))
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.14, 0.16, 0.86)
		card_style.border_color = spec["border"]
		card_style.set_border_width_all(1)
		card_style.corner_radius_top_left = 8
		card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_left = 8
		card_style.corner_radius_bottom_right = 8
		card.add_theme_stylebox_override("panel", card_style)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.tooltip_text = str(spec.get("tooltip", ""))
		battle.add_child(card)

		var title = Label.new()
		title.text = str(spec["title"])
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title.position = Vector2(32, int(spec["y"]) + 6)
		title.custom_minimum_size = Vector2(86, 14)
		title.add_theme_font_size_override("font_size", 11)
		title.modulate = spec["border"]
		title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		title.add_theme_constant_override("outline_size", 1)
		battle.add_child(title)

		var body = Label.new()
		body.name = str(spec["name"])
		body.text = _summarize_text_rows(spec["rows"], "（无）", int(spec["lines"]), 1)
		body.tooltip_text = ""
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.position = Vector2(32, int(spec["y"]) + 22)
		body.custom_minimum_size = Vector2(274, int(spec["h"]) - 28)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 7)
		body.clip_text = true
		body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		body.modulate = spec["color"] if not spec["rows"].is_empty() else Color(0.52, 0.52, 0.52)
		battle.add_child(body)

	# ===== 右侧：敌人信息面板 =====
	var enemy_panel = ColorRect.new()
	enemy_panel.color = Color(0.2, 0.12, 0.12, 0.85)
	enemy_panel.position = Vector2(945, 72)
	enemy_panel.custom_minimum_size = Vector2(320, 350)
	enemy_panel.offset_right = 1265
	enemy_panel.offset_bottom = 422
	battle.add_child(enemy_panel)

	var enemy_hp_title = Label.new()
	enemy_hp_title.text = ""
	enemy_hp_title.position = Vector2(1054, 80)
	enemy_hp_title.custom_minimum_size = Vector2(100, 16)
	enemy_hp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_hp_title.add_theme_font_size_override("font_size", 11)
	enemy_hp_title.modulate = Color(0.92, 0.82, 0.82)
	enemy_hp_title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	enemy_hp_title.add_theme_constant_override("outline_size", 1)
	battle.add_child(enemy_hp_title)

	var enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.name = "EnemyHPBar"
	enemy_hp_bar.min_value = 0
	enemy_hp_bar.max_value = battle_enemy_max_hp
	enemy_hp_bar.value = battle_enemy_hp
	enemy_hp_bar.position = Vector2(958, 98)
	enemy_hp_bar.custom_minimum_size = Vector2(284, 20)
	enemy_hp_bar.show_percentage = false
	enemy_hp_bar.modulate = Color(0.72, 0.96, 0.72, 1.0)
	battle.add_child(enemy_hp_bar)

	var enemy_hp = Label.new()
	enemy_hp.name = "EnemyHP"
	enemy_hp.text = "%d / %d" % [battle_enemy_hp, battle_enemy_max_hp]
	enemy_hp.position = Vector2(955, 94)
	enemy_hp.custom_minimum_size = Vector2(290, 30)
	enemy_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_hp.add_theme_font_size_override("font_size", 15)
	enemy_hp.modulate = Color(0.94, 1, 0.94)
	enemy_hp.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	enemy_hp.add_theme_constant_override("outline_size", 1)
	battle.add_child(enemy_hp)

	var enemy_atk_card = Panel.new()
	enemy_atk_card.position = Vector2(1057, 122)
	enemy_atk_card.size = Vector2(86, 28)
	var enemy_atk_style = StyleBoxFlat.new()
	enemy_atk_style.bg_color = Color(0.22, 0.10, 0.10, 0.88)
	enemy_atk_style.border_color = Color(0.86, 0.44, 0.44, 1.0)
	enemy_atk_style.set_border_width_all(1)
	enemy_atk_style.corner_radius_top_left = 7
	enemy_atk_style.corner_radius_top_right = 7
	enemy_atk_style.corner_radius_bottom_left = 7
	enemy_atk_style.corner_radius_bottom_right = 7
	enemy_atk_card.add_theme_stylebox_override("panel", enemy_atk_style)
	battle.add_child(enemy_atk_card)

	var enemy_atk = Label.new()
	enemy_atk.name = "EnemyAtk"
	enemy_atk.text = "⚔ %d" % battle_enemy_atk
	enemy_atk.position = Vector2(1057, 126)
	enemy_atk.custom_minimum_size = Vector2(86, 20)
	enemy_atk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_atk.add_theme_font_size_override("font_size", 14)
	enemy_atk.modulate = Color(1, 0.6, 0.6)
	enemy_atk.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	enemy_atk.add_theme_constant_override("outline_size", 1)
	battle.add_child(enemy_atk)

	var enemy_group = Label.new()
	enemy_group.name = "EnemyGroupLabel"
	enemy_group.text = _get_enemy_group_status_text()
	enemy_group.position = Vector2(958, 400)
	enemy_group.custom_minimum_size = Vector2(284, 20)
	enemy_group.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_group.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	enemy_group.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_group.add_theme_font_size_override("font_size", 11)
	enemy_group.modulate = Color(1.0, 0.78, 0.52, 0.92)
	enemy_group.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	enemy_group.add_theme_constant_override("outline_size", 1)
	enemy_group.visible = not battle_support_enemies.is_empty()
	enemy_group.z_index = 25
	battle.add_child(enemy_group)

	var enemy_portrait_panel = Panel.new()
	enemy_portrait_panel.name = "EnemyPortraitPanel"
	enemy_portrait_panel.position = Vector2(992, 162)
	enemy_portrait_panel.size = Vector2(240, 238)
	var enemy_style = StyleBoxFlat.new()
	enemy_style.bg_color = Color(0.16, 0.08, 0.08, 0.85)
	enemy_style.border_color = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lerp(Color(1, 0.4, 0.4, 1.0), 0.45)
	enemy_style.set_border_width_all(2)
	enemy_style.corner_radius_top_left = 8
	enemy_style.corner_radius_top_right = 8
	enemy_style.corner_radius_bottom_left = 8
	enemy_style.corner_radius_bottom_right = 8
	enemy_portrait_panel.add_theme_stylebox_override("panel", enemy_style)
	enemy_portrait_panel.set_meta("base_style", enemy_style.duplicate())
	enemy_portrait_panel.set_meta("momentum_owner", "enemy")
	battle.add_child(enemy_portrait_panel)

	var enemy_portrait = TextureRect.new()
	enemy_portrait.name = "EnemyPortrait"
	enemy_portrait.texture = _load_enemy_portrait(enemy_data)
	enemy_portrait.position = Vector2(1002, 172)
	enemy_portrait.custom_minimum_size = Vector2(220, 218)
	enemy_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_portrait.modulate = Color(1, 1, 1, 0.98)
	battle.add_child(enemy_portrait)

	var enemy_momentum_field = MomentumField.new()
	enemy_momentum_field.name = "EnemyMomentumField"
	enemy_momentum_field.position = Vector2(1002, 172)
	enemy_momentum_field.custom_minimum_size = Vector2(220, 218)
	enemy_momentum_field.size = Vector2(220, 218)
	enemy_momentum_field.z_index = 18
	enemy_momentum_field.setup(era_theme, "enemy")
	battle.add_child(enemy_momentum_field)

	for item_node in item_nodes:
		battle.move_child(item_node, battle.get_child_count() - 1)

	# ===== 中央：战斗区域 =====
	var center_panel = ColorRect.new()
	center_panel.color = Color(0.16, 0.16, 0.20, 0.18)
	center_panel.position = Vector2(350, 72)
	center_panel.custom_minimum_size = Vector2(580, 632)
	center_panel.offset_right = 930
	center_panel.offset_bottom = 704
	battle.add_child(center_panel)

	_update_momentum_field(battle)
	_show_momentum_enemy_intent(battle, enemy_ai)

	var bottom_action_band = ColorRect.new()
	bottom_action_band.color = Color(0.12, 0.12, 0.15, 0.92)
	bottom_action_band.position = Vector2(350, 488)
	bottom_action_band.custom_minimum_size = Vector2(580, 216)
	battle.add_child(bottom_action_band)

	var band_top_line = ColorRect.new()
	band_top_line.color = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	band_top_line.position = Vector2(350, 488)
	band_top_line.custom_minimum_size = Vector2(580, 3)
	battle.add_child(band_top_line)

	var band_mid_line = ColorRect.new()
	band_mid_line.color = Color(1, 1, 1, 0.08)
	band_mid_line.position = Vector2(370, 540)
	band_mid_line.custom_minimum_size = Vector2(540, 1)
	battle.add_child(band_mid_line)

	var action_title = Label.new()
	action_title.text = ""
	action_title.position = Vector2(602, 452)
	action_title.custom_minimum_size = Vector2(80, 16)
	action_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_title.add_theme_font_size_override("font_size", 11)
	action_title.modulate = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	action_title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	action_title.add_theme_constant_override("outline_size", 1)
	battle.add_child(action_title)

	var announce_panel = Panel.new()
	announce_panel.position = Vector2(398, 82)
	announce_panel.size = Vector2(484, 32)
	var announce_style = StyleBoxFlat.new()
	announce_style.bg_color = Color(0.14, 0.14, 0.18, 0.90)
	announce_style.border_color = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	announce_style.set_border_width_all(1)
	announce_style.corner_radius_top_left = 10
	announce_style.corner_radius_top_right = 10
	announce_style.corner_radius_bottom_left = 10
	announce_style.corner_radius_bottom_right = 10
	announce_panel.add_theme_stylebox_override("panel", announce_style)
	battle.add_child(announce_panel)

	var announce_title = Label.new()
	announce_title.text = ""
	announce_title.position = Vector2(430, 86)
	announce_title.custom_minimum_size = Vector2(72, 14)
	announce_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announce_title.add_theme_font_size_override("font_size", 11)
	announce_title.modulate = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	announce_title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	announce_title.add_theme_constant_override("outline_size", 1)
	battle.add_child(announce_title)

	var stage_panel = Panel.new()
	stage_panel.name = "BattleStagePanel"
	stage_panel.position = Vector2(400, 126)
	stage_panel.size = Vector2(480, 38)
	var stage_style = StyleBoxFlat.new()
	stage_style.bg_color = Color(0.12, 0.12, 0.16, 0.92)
	stage_style.border_color = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lightened(0.08)
	stage_style.set_border_width_all(1)
	stage_style.corner_radius_top_left = 12
	stage_style.corner_radius_top_right = 12
	stage_style.corner_radius_bottom_left = 12
	stage_style.corner_radius_bottom_right = 12
	stage_panel.add_theme_stylebox_override("panel", stage_style)
	stage_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_panel.visible = false
	stage_panel.modulate.a = 0.0
	battle.add_child(stage_panel)

	var stage_label = Label.new()
	stage_label.name = "BattleStageLabel"
	stage_label.text = ""
	stage_label.position = Vector2(420, 131)
	stage_label.custom_minimum_size = Vector2(440, 24)
	stage_label.add_theme_font_size_override("font_size", 20)
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage_label.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.25))
	stage_label.add_theme_constant_override("outline_size", 2)
	stage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_label.visible = false
	stage_label.modulate.a = 0.0
	stage_label.z_index = 91
	battle.add_child(stage_label)

	# 回合信息
	var move_info = Label.new()
	move_info.name = "MoveInfo"
	move_info.text = ""
	move_info.position = Vector2(432, 90)
	move_info.custom_minimum_size = Vector2(416, 20)
	move_info.add_theme_font_size_override("font_size", 12)
	move_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_info.modulate = Color(0.96, 0.94, 0.78, 0.92)
	move_info.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	move_info.add_theme_constant_override("outline_size", 1)
	move_info.visible = false
	move_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle.add_child(move_info)

	var danger_panel = Panel.new()
	danger_panel.name = "DangerForecastPanel"
	danger_panel.position = Vector2(998, 354)
	danger_panel.size = Vector2(228, 40)
	danger_panel.z_index = 28
	var danger_style = StyleBoxFlat.new()
	danger_style.bg_color = Color(0.12, 0.07, 0.06, 0.86)
	danger_style.border_color = era_theme.get("bad", Color(0.90, 0.52, 0.44, 1.0))
	danger_style.set_border_width_all(1)
	danger_style.corner_radius_top_left = 10
	danger_style.corner_radius_top_right = 10
	danger_style.corner_radius_bottom_left = 10
	danger_style.corner_radius_bottom_right = 10
	danger_panel.add_theme_stylebox_override("panel", danger_style)
	danger_panel.visible = false
	battle.add_child(danger_panel)

	var danger_level_bar = ColorRect.new()
	danger_level_bar.name = "DangerForecastLevelBar"
	danger_level_bar.position = Vector2(1010, 388)
	danger_level_bar.custom_minimum_size = Vector2(204, 3)
	danger_level_bar.color = era_theme.get("bad", Color(0.90, 0.52, 0.44, 1.0))
	danger_level_bar.z_index = 29
	danger_level_bar.visible = false
	battle.add_child(danger_level_bar)

	var boss_danger_label = Label.new()
	boss_danger_label.name = "DangerForecastLabel"
	boss_danger_label.text = ""
	boss_danger_label.position = Vector2(1010, 358)
	boss_danger_label.custom_minimum_size = Vector2(204, 28)
	boss_danger_label.add_theme_font_size_override("font_size", 11)
	boss_danger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_danger_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_danger_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boss_danger_label.modulate = era_theme.get("bad", Color(0.90, 0.52, 0.44, 1.0)).lerp(Color(1.0, 0.92, 0.82, 1.0), 0.25)
	boss_danger_label.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.25))
	boss_danger_label.add_theme_constant_override("outline_size", 1)
	boss_danger_label.visible = false
	boss_danger_label.z_index = 30
	battle.add_child(boss_danger_label)
	_update_boss_warning_label(battle, enemy_ai)

	_create_duel_momentum_rail(battle, era_theme)

	var result_panel = Panel.new()
	result_panel.name = "BattleSummaryPanel"
	result_panel.position = Vector2(390, 498)
	result_panel.size = Vector2(500, 86)
	var result_style = StyleBoxFlat.new()
	result_style.bg_color = Color(0.10, 0.11, 0.14, 0.82)
	result_style.border_color = Color(1, 1, 1, 0.08)
	result_style.set_border_width_all(1)
	result_style.corner_radius_top_left = 10
	result_style.corner_radius_top_right = 10
	result_style.corner_radius_bottom_left = 10
	result_style.corner_radius_bottom_right = 10
	result_panel.add_theme_stylebox_override("panel", result_style)
	battle.add_child(result_panel)

	var result_title = Label.new()
	result_title.name = "BattleSummaryTitle"
	result_title.text = "判词"
	result_title.position = Vector2(410, 506)
	result_title.size = Vector2(46, 18)
	result_title.custom_minimum_size = result_title.size
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 10)
	result_title.modulate = Color(0.82, 0.82, 0.88)
	result_title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	result_title.add_theme_constant_override("outline_size", 1)
	battle.add_child(result_title)

	# 战斗结果
	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = "静候"
	result_label.position = Vector2(456, 501)
	result_label.size = Vector2(414, 30)
	result_label.custom_minimum_size = result_label.size
	result_label.add_theme_font_size_override("font_size", 12)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.clip_text = true
	result_label.modulate = Color(0.9, 0.9, 0.8)
	result_label.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	result_label.add_theme_constant_override("outline_size", 1)
	var era_item_start_text = _get_era_item_battle_start_summary(prebattle_shield, prebattle_cheat)
	if era_item_start_text != "":
		result_label.text = era_item_start_text
	battle.add_child(result_label)

	var battle_flash = ColorRect.new()
	battle_flash.name = "BattleFlash"
	battle_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_flash.color = Color(1, 1, 1, 0)
	battle_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_flash.visible = false
	battle_flash.z_index = 80
	battle.add_child(battle_flash)

	var impact_label = Label.new()
	impact_label.name = "BattleImpactLabel"
	impact_label.text = ""
	impact_label.position = Vector2(276, 170)
	impact_label.custom_minimum_size = Vector2(728, 128)
	impact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	impact_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	impact_label.add_theme_font_size_override("font_size", 64)
	impact_label.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.01, 1.0))
	impact_label.add_theme_constant_override("outline_size", 5)
	impact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	impact_label.visible = false
	impact_label.z_index = 90
	battle.add_child(impact_label)

	_create_support_enemy_status_ui(battle, era_theme)

	var battle_sfx = AudioStreamPlayer.new()
	battle_sfx.name = "BattleSfxPlayer"
	battle_sfx.volume_db = -9.0
	battle.add_child(battle_sfx)

	var battle_sfx_overlay = AudioStreamPlayer.new()
	battle_sfx_overlay.name = "BattleSfxOverlayPlayer"
	battle_sfx_overlay.volume_db = -12.0
	battle.add_child(battle_sfx_overlay)

	# ===== 出招历史面板 =====
	# 玩家最近3回合
	var player_hist_panel = ColorRect.new()
	player_hist_panel.color = Color(0.15, 0.2, 0.15, 0.38)
	player_hist_panel.position = Vector2(418, 536)
	player_hist_panel.size = Vector2(170, 40)
	battle.add_child(player_hist_panel)

	var player_hist_title = Label.new()
	player_hist_title.text = "己"
	player_hist_title.position = Vector2(428, 543)
	player_hist_title.add_theme_font_size_override("font_size", 10)
	player_hist_title.modulate = Color(0.7, 0.9, 0.7, 0.72)
	player_hist_title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	player_hist_title.add_theme_constant_override("outline_size", 1)
	battle.add_child(player_hist_title)

	for i in range(3):
		var slot = Panel.new()
		slot.position = Vector2(456 + i * 40, 548)
		slot.size = Vector2(32, 24)
		var slot_style = StyleBoxFlat.new()
		slot_style.bg_color = Color(0.11, 0.16, 0.12, 0.62)
		slot_style.border_color = Color(0.42, 0.64, 0.46, 0.52)
		slot_style.set_border_width_all(1)
		slot_style.corner_radius_top_left = 8
		slot_style.corner_radius_top_right = 8
		slot_style.corner_radius_bottom_left = 8
		slot_style.corner_radius_bottom_right = 8
		slot.add_theme_stylebox_override("panel", slot_style)
		battle.add_child(slot)

		var slot_label = Label.new()
		slot_label.name = "PlayerHistory%d" % i
		slot_label.text = "·"
		slot_label.position = Vector2(456 + i * 40, 548)
		slot_label.custom_minimum_size = Vector2(32, 22)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 18)
		slot_label.modulate = Color(0.8, 1, 0.8, 0.72)
		battle.add_child(slot_label)

	# 敌人最近3回合
	var enemy_hist_panel = ColorRect.new()
	enemy_hist_panel.color = Color(0.2, 0.15, 0.15, 0.38)
	enemy_hist_panel.position = Vector2(692, 536)
	enemy_hist_panel.size = Vector2(170, 40)
	battle.add_child(enemy_hist_panel)

	var enemy_hist_title = Label.new()
	enemy_hist_title.text = "敌"
	enemy_hist_title.position = Vector2(702, 543)
	enemy_hist_title.add_theme_font_size_override("font_size", 10)
	enemy_hist_title.modulate = Color(0.9, 0.7, 0.7, 0.72)
	enemy_hist_title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	enemy_hist_title.add_theme_constant_override("outline_size", 1)
	battle.add_child(enemy_hist_title)

	for i in range(3):
		var enemy_slot = Panel.new()
		enemy_slot.position = Vector2(730 + i * 40, 548)
		enemy_slot.size = Vector2(32, 24)
		var enemy_slot_style = StyleBoxFlat.new()
		enemy_slot_style.bg_color = Color(0.18, 0.11, 0.11, 0.62)
		enemy_slot_style.border_color = Color(0.72, 0.42, 0.42, 0.52)
		enemy_slot_style.set_border_width_all(1)
		enemy_slot_style.corner_radius_top_left = 8
		enemy_slot_style.corner_radius_top_right = 8
		enemy_slot_style.corner_radius_bottom_left = 8
		enemy_slot_style.corner_radius_bottom_right = 8
		enemy_slot.add_theme_stylebox_override("panel", enemy_slot_style)
		battle.add_child(enemy_slot)

		var enemy_slot_label = Label.new()
		enemy_slot_label.name = "EnemyHistory%d" % i
		enemy_slot_label.text = "·"
		enemy_slot_label.position = Vector2(730 + i * 40, 548)
		enemy_slot_label.custom_minimum_size = Vector2(32, 22)
		enemy_slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enemy_slot_label.add_theme_font_size_override("font_size", 18)
		enemy_slot_label.modulate = Color(1, 0.8, 0.8, 0.72)
		battle.add_child(enemy_slot_label)

	var layout_momentum_panel = Panel.new()
	layout_momentum_panel.name = "LayoutMomentumPanel"
	layout_momentum_panel.position = Vector2(398, 558)
	layout_momentum_panel.size = Vector2(484, 24)
	var layout_momentum_style = StyleBoxFlat.new()
	layout_momentum_style.bg_color = Color(0.10, 0.09, 0.07, 0.76)
	layout_momentum_style.border_color = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lerp(Color(1.0, 0.82, 0.30, 1.0), 0.34)
	layout_momentum_style.set_border_width_all(1)
	layout_momentum_style.corner_radius_top_left = 9
	layout_momentum_style.corner_radius_top_right = 9
	layout_momentum_style.corner_radius_bottom_left = 9
	layout_momentum_style.corner_radius_bottom_right = 9
	layout_momentum_panel.add_theme_stylebox_override("panel", layout_momentum_style)
	layout_momentum_panel.visible = false
	battle.add_child(layout_momentum_panel)

	var layout_momentum_label = Label.new()
	layout_momentum_label.name = "LayoutMomentumLabel"
	layout_momentum_label.text = _get_layout_momentum_text()
	layout_momentum_label.position = Vector2(414, 561)
	layout_momentum_label.size = Vector2(452, 18)
	layout_momentum_label.custom_minimum_size = layout_momentum_label.size
	layout_momentum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout_momentum_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layout_momentum_label.add_theme_font_size_override("font_size", 12)
	layout_momentum_label.modulate = Color(1.0, 0.86, 0.44, 0.92)
	layout_momentum_label.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	layout_momentum_label.add_theme_constant_override("outline_size", 1)
	layout_momentum_label.clip_text = true
	layout_momentum_label.visible = false
	battle.add_child(layout_momentum_label)

	var move_row_panel = Panel.new()
	move_row_panel.position = Vector2(378, 588)
	move_row_panel.size = Vector2(524, 70)
	var move_row_style = StyleBoxFlat.new()
	move_row_style.bg_color = Color(0.14, 0.14, 0.18, 0.88)
	move_row_style.border_color = Color(1, 1, 1, 0.08)
	move_row_style.set_border_width_all(1)
	move_row_style.corner_radius_top_left = 10
	move_row_style.corner_radius_top_right = 10
	move_row_style.corner_radius_bottom_left = 10
	move_row_style.corner_radius_bottom_right = 10
	move_row_panel.add_theme_stylebox_override("panel", move_row_style)
	battle.add_child(move_row_panel)

	var move_row_title = Label.new()
	move_row_title.text = ""
	move_row_title.position = Vector2(623, 592)
	move_row_title.custom_minimum_size = Vector2(40, 16)
	move_row_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_row_title.add_theme_font_size_override("font_size", 11)
	move_row_title.modulate = Color(0.82, 0.82, 0.88)
	battle.add_child(move_row_title)

	# ===== 出招按钮 =====
	var btn_y = 596
	var btn_w = 138
	var btn_h = 56
	var btn_start_x = 397
	var btn_gap = 170

	var move_specs = [
		{
			"idx": 0,
			"key": "Q",
			"title": MoveSymbols.move_name(0),
				"subtitle": "机势",
				"icon": "tian",
				"bg": Color(0.16, 0.21, 0.29, 0.92),
			"border": Color(0.52, 0.74, 0.96, 1.0),
			"text": Color(0.86, 0.94, 1.0, 1.0),
			"x": btn_start_x
		},
		{
			"idx": 1,
			"key": "W",
			"title": MoveSymbols.move_name(1),
				"subtitle": "争先",
				"icon": "ren",
				"bg": Color(0.28, 0.18, 0.12, 0.92),
			"border": Color(1.0, 0.72, 0.48, 1.0),
			"text": Color(1.0, 0.94, 0.82, 1.0),
			"x": btn_start_x + btn_gap
		},
		{
			"idx": 2,
			"key": "E",
			"title": MoveSymbols.move_name(2),
				"subtitle": "守成",
				"icon": "di",
				"bg": Color(0.16, 0.24, 0.16, 0.92),
			"border": Color(0.62, 0.88, 0.64, 1.0),
			"text": Color(0.90, 1.0, 0.90, 1.0),
			"x": btn_start_x + btn_gap * 2
		}
	]

	for spec in move_specs:
		var move_idx := int(spec["idx"])
		var card = Panel.new()
		card.name = "BattleMoveCard%d" % move_idx
		card.position = Vector2(int(spec["x"]), btn_y)
		card.size = Vector2(btn_w, btn_h)
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = spec["bg"]
		card_style.border_color = spec["border"]
		card_style.set_border_width_all(2)
		card_style.corner_radius_top_left = 12
		card_style.corner_radius_top_right = 12
		card_style.corner_radius_bottom_left = 12
		card_style.corner_radius_bottom_right = 12
		card.add_theme_stylebox_override("panel", card_style)
		battle.add_child(card)

		var move_icon_texture = _load_texture_resource(ArtRegistry.get_combat_icon_path(str(spec["icon"])))
		if move_icon_texture != null:
			var move_icon = TextureRect.new()
			move_icon.name = "BattleMoveIcon%d" % int(spec["idx"])
			move_icon.texture = move_icon_texture
			move_icon.position = Vector2(int(spec["x"]) + 10, btn_y + 12)
			move_icon.custom_minimum_size = Vector2(26, 26)
			move_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			move_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			move_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			move_icon.modulate = Color(1, 1, 1, 0.84)
			battle.add_child(move_icon)

		var btn = Button.new()
		btn.name = "BattleMoveButton%d" % move_idx
		btn.text = ""
		btn.custom_minimum_size = Vector2(btn_w, btn_h)
		btn.position = Vector2(int(spec["x"]), btn_y)
		btn.flat = true
		btn.modulate = Color(1, 1, 1, 0.02)
		btn.set_meta("battle_move_button", true)
		btn.set_meta("move_idx", move_idx)
		btn.set_meta("base_subtitle", str(spec["subtitle"]))
		btn.mouse_entered.connect(func():
			if not btn.disabled:
				btn.set_meta("read_state", _get_move_read_state(move_idx, enemy_ai))
				_apply_battle_move_button_state(btn, "hover")
				_set_battle_broadcast(battle, _get_player_move_pressure_hint(move_idx, enemy_ai))
		)
		btn.mouse_exited.connect(func():
			if not btn.disabled:
				btn.set_meta("read_state", "")
				_apply_battle_move_button_state(btn, "normal")
				_update_combo_linchpin_feedback(battle)
				_set_battle_broadcast(battle, _get_pre_turn_broadcast(enemy_ai))
		)
		btn.button_down.connect(func():
			if not btn.disabled:
				_apply_battle_move_button_state(btn, "pressed")
		)
		btn.button_up.connect(func():
			if not btn.disabled:
				var state := "hover" if btn.get_global_rect().has_point(btn.get_global_mouse_position()) else "normal"
				btn.set_meta("read_state", _get_move_read_state(move_idx, enemy_ai) if state == "hover" else "")
				_apply_battle_move_button_state(btn, state)
				if state == "normal":
					_update_combo_linchpin_feedback(battle)
		)
		btn.pressed.connect(func():
			_submit_battle_move(move_idx, battle, enemy_ai)
		)
		battle.add_child(btn)

		var title = Label.new()
		title.name = "BattleMoveTitle%d" % int(spec["idx"])
		title.text = str(spec["title"])
		title.position = Vector2(int(spec["x"]), btn_y + 5)
		title.custom_minimum_size = Vector2(btn_w, 28)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 30)
		title.modulate = spec["text"]
		title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		title.add_theme_constant_override("outline_size", 1)
		battle.add_child(title)

		var subtitle = Label.new()
		subtitle.name = "BattleMoveSubtitle%d" % int(spec["idx"])
		subtitle.text = str(spec["subtitle"])
		subtitle.position = Vector2(int(spec["x"]), btn_y + 34)
		subtitle.custom_minimum_size = Vector2(btn_w, 16)
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.add_theme_font_size_override("font_size", 11)
		subtitle.modulate = Color(1, 1, 1, 0.72)
		subtitle.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		subtitle.add_theme_constant_override("outline_size", 1)
		battle.add_child(subtitle)

		var key_hint = Label.new()
		key_hint.name = "BattleMoveKey%d" % int(spec["idx"])
		key_hint.text = str(spec["key"])
		key_hint.position = Vector2(int(spec["x"]) + 49, btn_y + btn_h - 15)
		key_hint.custom_minimum_size = Vector2(40, 14)
		key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_hint.add_theme_font_size_override("font_size", 12)
		key_hint.modulate = Color(0.82, 0.82, 0.82)
		key_hint.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
		key_hint.add_theme_constant_override("outline_size", 1)
		battle.add_child(key_hint)
		_apply_battle_move_button_state(btn, "normal")

	var utility_row_panel = Panel.new()
	utility_row_panel.name = "ComboResourcePanel"
	utility_row_panel.position = BATTLE_UTILITY_ROW_POS
	utility_row_panel.size = BATTLE_UTILITY_ROW_SIZE
	var utility_style = StyleBoxFlat.new()
	utility_style.bg_color = Color(0.10, 0.10, 0.13, 0.92)
	utility_style.border_color = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lerp(Color.WHITE, 0.75)
	utility_style.set_border_width_all(2)
	utility_style.corner_radius_top_left = 8
	utility_style.corner_radius_top_right = 8
	utility_style.corner_radius_bottom_left = 8
	utility_style.corner_radius_bottom_right = 8
	utility_row_panel.add_theme_stylebox_override("panel", utility_style)
	battle.add_child(utility_row_panel)

	var cheat_btn = Button.new()
	cheat_btn.name = "CheatButton"
	cheat_btn.text = GameState.get_cheat_label_text("🔍 机括")
	cheat_btn.size = BATTLE_CHEAT_BUTTON_SIZE
	cheat_btn.custom_minimum_size = BATTLE_CHEAT_BUTTON_SIZE
	cheat_btn.position = BATTLE_CHEAT_BUTTON_POS
	cheat_btn.add_theme_font_size_override("font_size", 12)
	cheat_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cheat_style = StyleBoxFlat.new()
	cheat_style.bg_color = Color(0.17, 0.15, 0.11, 0.96)
	cheat_style.border_color = Color(0.84, 0.72, 0.38, 1.0)
	cheat_style.set_border_width_all(1)
	cheat_style.corner_radius_top_left = 8
	cheat_style.corner_radius_top_right = 8
	cheat_style.corner_radius_bottom_left = 8
	cheat_style.corner_radius_bottom_right = 8
	var cheat_hover_style = cheat_style.duplicate()
	cheat_hover_style.bg_color = Color(0.22, 0.19, 0.12, 0.98)
	var cheat_disabled_style = cheat_style.duplicate()
	cheat_disabled_style.bg_color = Color(0.13, 0.13, 0.13, 0.92)
	cheat_disabled_style.border_color = Color(0.32, 0.32, 0.32, 1.0)
	cheat_btn.add_theme_stylebox_override("normal", cheat_style)
	cheat_btn.add_theme_stylebox_override("hover", cheat_hover_style)
	cheat_btn.add_theme_stylebox_override("pressed", cheat_hover_style)
	cheat_btn.add_theme_stylebox_override("disabled", cheat_disabled_style)
	cheat_btn.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	cheat_btn.add_theme_constant_override("outline_size", 1)
	cheat_btn.disabled = GameState.cheat_points <= 0
	ArtRegistry.apply_button_icon(cheat_btn, "cheat", false, "机括：读招，反抓或回环。")
	_setup_battle_action_button(cheat_btn, "cheat")
	cheat_btn.pressed.connect(func():
		_pulse_battle_action_button_afterglow(cheat_btn)
		_use_cheat(battle, enemy_ai)
	)
	battle.add_child(cheat_btn)

	# 连招能量显示
	# 连招进度追踪（显示哪些连招接近完成）
	var combo_progress_label = Label.new()
	combo_progress_label.name = "ComboProgress"
	combo_progress_label.text = _get_combo_progress_text()
	combo_progress_label.position = BATTLE_UTILITY_ROW_POS + Vector2(14, 5)
	combo_progress_label.size = Vector2(338, 22)
	combo_progress_label.custom_minimum_size = combo_progress_label.size
	combo_progress_label.add_theme_font_size_override("font_size", 13)
	combo_progress_label.modulate = Color(1.0, 0.86, 0.28)
	combo_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_progress_label.clip_text = true
	combo_progress_label.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	combo_progress_label.add_theme_constant_override("outline_size", 1)
	battle.add_child(combo_progress_label)

	# 连招按钮容器
	var combo_btn_container = HBoxContainer.new()
	combo_btn_container.name = "ComboButtons"
	combo_btn_container.position = Vector2(354, 670)
	combo_btn_container.add_theme_constant_override("separation", 10)
	battle.add_child(combo_btn_container)

	_update_combo_buttons(combo_btn_container, battle, enemy_ai)
	_apply_combo_resource_heat_state(battle, "auto")

	# 底部提示
	var bottom_hint = Label.new()
	bottom_hint.text = ""
	bottom_hint.position = Vector2(350, 472)
	bottom_hint.custom_minimum_size = Vector2(580, 20)
	bottom_hint.add_theme_font_size_override("font_size", 11)
	bottom_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_hint.modulate = Color(0.4, 0.4, 0.4)
	bottom_hint.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	bottom_hint.add_theme_constant_override("outline_size", 1)
	battle.add_child(bottom_hint)

	return battle

func _update_combo_buttons(container: HBoxContainer, battle: Control, enemy_ai: EnemyAI):
	"""更新连招按钮（三类连招）"""
	for child in container.get_children():
		child.queue_free()

	var allowed_combo_ids: Array[String] = []
	for cid in GameState.get_equipped_combos():
		if not cid in allowed_combo_ids:
			allowed_combo_ids.append(cid)
	var cn: Array[String] = ["医生", "黑客", "商人", "农民", "流浪者"]
	var ec = ComboData.get_exclusive_combos(cn[GameState.player_class])
	for c in ec:
		if not c.combo_id in allowed_combo_ids:
			allowed_combo_ids.append(c.combo_id)
	for item in GameState.equipment_slot:
		if item.has("exclusive_combo") and item.exclusive_combo != "":
			if not item.exclusive_combo in allowed_combo_ids:
				allowed_combo_ids.append(item.exclusive_combo)

	var combo_db = _get_combo_database()
	var combat_combos = combo_db.get_combat_combos()
	for combo in combat_combos:
		if not combo.id in allowed_combo_ids:
			continue
		var reduction = GameState.get_combo_energy_reduction(combo.id)
		var actual_cost = maxi(combo.energy_cost - reduction, 2)
		var can_use = GameState.has_enough_combo_energy(actual_cost)
		var btn = Button.new()
		btn.name = "CombatCombo_%s" % str(combo.id)
		var seq_str = combo_db.combat_combo_sequence_to_display(combo.sequence)
		var brief := _get_combat_combo_brief(combo, actual_cost)
		btn.text = "%s\n%s｜%s" % [combo.name, seq_str, brief]
		btn.disabled = not can_use
		btn.custom_minimum_size = Vector2(176, 46)
		btn.tooltip_text = _get_combat_combo_tooltip(combo, seq_str, actual_cost, can_use)
		btn.add_theme_font_size_override("font_size", 9)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		ArtRegistry.apply_button_icon(btn, "combo", false, btn.tooltip_text)
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.18, 0.16, 0.12, 0.94) if can_use else Color(0.13, 0.13, 0.13, 0.92)
		normal_style.border_color = Color(0.86, 0.74, 0.42, 1.0) if can_use else Color(0.34, 0.34, 0.34, 1.0)
		normal_style.set_border_width_all(1)
		normal_style.corner_radius_top_left = 8
		normal_style.corner_radius_top_right = 8
		normal_style.corner_radius_bottom_left = 8
		normal_style.corner_radius_bottom_right = 8
		var hover_style = normal_style.duplicate()
		hover_style.bg_color = Color(0.24, 0.20, 0.14, 0.98) if can_use else Color(0.15, 0.15, 0.15, 0.94)
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", hover_style)
		_setup_battle_action_button(btn, "combo")
		var combo_id := str(combo.id)
		btn.pressed.connect(func():
			_pulse_battle_action_button_afterglow(btn)
			_on_combo_button_pressed(combo_id, battle, enemy_ai)
		)
		container.add_child(btn)

func _on_combo_button_pressed(combo_id: String, battle: Control, enemy_ai: EnemyAI):
	"""连招按钮点击"""
	var combo_db = _get_combo_database()
	var combat_combo = combo_db.get_combat_combo_by_id(combo_id)
	if not combat_combo:
		return
	var reduction = GameState.get_combo_energy_reduction(combo_id)
	var actual_cost = maxi(combat_combo.energy_cost - reduction, 2)
	if not GameState.consume_combo_energy(actual_cost):
		return
	_pulse_combo_resource_feedback(battle, "cooldown")
	# 执行连招伤害
	var player_atk = GameState.get_total_attack()
	var dmg_mult = GameState.get_combo_damage_multiplier(combo_id)
	var total_damage = 0
	for i in range(combat_combo.attack_count):
		var dmg = int(player_atk * combat_combo.base_damage / 100.0 * dmg_mult)
		if combat_combo.special_effect == "crit":
			dmg = int(dmg * 1.5)
		total_damage += dmg
		battle_enemy_hp = maxi(battle_enemy_hp - dmg, 0)
	_play_player_battle_animation(battle, "attack")
	_play_enemy_battle_animation(battle, "hurt")
	_show_battle_actor_popup(battle, "enemy", "-%d" % total_damage, Color(1.0, 0.42, 0.20, 1.0), combat_combo.special_effect == "crit")
	if GameState.has_combo_effect(combo_id, "burn"):
		GameState.apply_combo_buff("enemy_burn", 2, 2)
	if GameState.has_combo_effect(combo_id, "break_momentum"):
		GameState.apply_combo_buff("break_momentum", _battle_round_count, 2)
	# BOSS锁血检查
	var combo_result_label = battle.get_node_or_null("ResultLabel")
	_clamp_boss_phase(combo_result_label)
	# 特殊效果
	if combat_combo.special_effect == "knockback":
		battle_enemy_atk = maxi(battle_enemy_atk - 1, 1)
		# 更新UI
		var result_label = battle.get_node_or_null("ResultLabel")
		if result_label:
			var extra_effect_text = ""
			if GameState.has_combo_effect(combo_id, "burn"):
				extra_effect_text += " +灼烧"
			if GameState.has_combo_effect(combo_id, "break_momentum"):
				extra_effect_text += " +破势"
			result_label.text = _get_era_combo_complete_text(ComboDatabase.get_era_combo_name(combat_combo.name), total_damage, extra_effect_text)
			_show_battle_impact(battle, "主动布局\n%s" % ComboDatabase.get_era_combo_name(combat_combo.name), "combo", 10)
		_update_battle_ui(battle)
		# 检查胜利
		if battle_enemy_hp <= 0 and not _battle_ending:
			_battle_ending = true
			_set_duel_momentum_rail_visible(battle, false)
			if result_label:
				result_label.text += "\n%s" % _get_era_battle_victory_text()
				_show_battle_impact(battle, "击溃", "victory", 16)
				_play_enemy_battle_animation(battle, "death", true)
				var settlement_before := _capture_battle_settlement_state()
				var gold_reward = GameState.get_battle_gold_reward()
				if GameState.has_greedy_gloves():
					gold_reward = int(gold_reward * GameState.get_gold_reward_multiplier())
				var bonus_gold = GameState.get_combo_buff("bonus_gold")
				if bonus_gold > 0:
					gold_reward += bonus_gold
				GameState.player_gold += gold_reward
				var hp_before_victory = GameState.player_hp
				GameState.on_battle_won()
				_append_era_item_victory_text(result_label, hp_before_victory)
				_apply_difficult_battle_victory_growth(result_label)
				var material_drop = 1
				if is_current_battle_boss: material_drop = 3
				elif GameState.current_floor >= 5: material_drop = 2
				material_drop += GameState.get_era_material_bonus(is_current_battle_boss, _get_battle_reward_type())
				if GameState.selected_era_id == "qin" and GameState.selected_route_name == "近攻线" and not is_current_battle_boss:
					var spoils_gold := 4 + GameState.get_major_layer_index(GameState.current_floor) * 2
					gold_reward += spoils_gold
					material_drop += 1
					result_label.text += "\n【近攻缴获】军需+%d金，材料+3金" % spoils_gold
				var bonus_material = GameState.get_combo_buff("bonus_material")
				if bonus_material > 0:
					material_drop += bonus_material
				gold_reward += material_drop * 3
				GameState.player_gold += material_drop * 3
				_append_battle_reward_summary(result_label, gold_reward, 0)
				_clear_heart_armor_temp_shield()
				GameState.unequip_all_after_battle()
				var reward_info := await _handle_battle_victory_rewards(battle)
				var settlement_after := _capture_battle_settlement_state()
				await _show_battle_settlement_detail(battle, settlement_before, settlement_after, reward_info)
				_advance_floor()

func _clamp_boss_phase(result_label: Label = null) -> void:
	"""BOSS锁血：一阶段HP不低于50%，触发时进入二阶段"""
	if not is_current_battle_boss or current_enemy_ai == null:
		return
	if current_enemy_ai.boss_phase != 1:
		return
	var phase2_hp = int(ceil(float(battle_enemy_max_hp) * GameState.get_era_boss_phase_ratio()))
	if battle_enemy_hp <= phase2_hp:
		battle_enemy_hp = phase2_hp
		current_enemy_ai.set_boss_phase(2)
		if current_ui is Control:
			_update_boss_warning_label(current_ui, current_enemy_ai)
		if result_label:
			result_label.text += "\n%s" % GameState.get_era_boss_phase_text()
			result_label.text += "\n%s" % _get_era_boss_warning_text()
		_apply_era_boss_phase_bonus(result_label)
		if current_ui:
			var boss_skill = current_ui.get_node_or_null("BossSkillLabel")
			if boss_skill:
				boss_skill.text = "✦ 二阶段：%s\n%s" % [GameState.get_era_boss_skill_name(), GameState.get_era_boss_phase_text()]
			_show_battle_impact(current_ui, "灾主变阵\n二阶段", "phase", 14)
			_pulse_boss_pressure_feedback(current_ui)

const MOVE_SYMBOLS: Array[String] = MoveSymbols.MOVE_NAMES
var _player_move_history: Array[int] = []
var _enemy_move_history: Array[int] = []

func _create_duel_momentum_rail(battle: Control, era_theme: Dictionary) -> void:
	var panel := Panel.new()
	panel.name = "DuelMomentumRail"
	panel.position = Vector2(398, 82)
	panel.size = Vector2(484, 32)
	panel.z_index = 22
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.085, 0.10, 0.68)
	style.border_color = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lerp(Color.WHITE, 0.22)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	battle.add_child(panel)

	var title := Label.new()
	title.name = "DuelMomentumTitle"
	title.text = "势轨"
	title.position = Vector2(414, 89)
	title.size = Vector2(48, 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	title.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	title.add_theme_constant_override("outline_size", 1)
	title.z_index = 23
	battle.add_child(title)

	var track := ColorRect.new()
	track.name = "DuelMomentumTrack"
	track.position = Vector2(478, 96)
	track.size = Vector2(380, 8)
	track.color = Color(1, 1, 1, 0.12)
	track.z_index = 23
	battle.add_child(track)

	var player_fill := ColorRect.new()
	player_fill.name = "DuelMomentumPlayerFill"
	player_fill.position = Vector2(642, 96)
	player_fill.size = Vector2(0, 8)
	player_fill.color = era_theme.get("good", Color(0.38, 0.82, 0.62, 1.0))
	player_fill.z_index = 24
	battle.add_child(player_fill)

	var enemy_fill := ColorRect.new()
	enemy_fill.name = "DuelMomentumEnemyFill"
	enemy_fill.position = Vector2(642, 96)
	enemy_fill.size = Vector2(0, 8)
	enemy_fill.color = era_theme.get("bad", Color(0.92, 0.34, 0.28, 1.0))
	enemy_fill.z_index = 24
	battle.add_child(enemy_fill)

	var center_tick := ColorRect.new()
	center_tick.name = "DuelMomentumCenterTick"
	center_tick.position = Vector2(640, 90)
	center_tick.size = Vector2(4, 20)
	center_tick.color = era_theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	center_tick.z_index = 25
	battle.add_child(center_tick)

	var marker := ColorRect.new()
	marker.name = "DuelMomentumMarker"
	marker.position = Vector2(638, 92)
	marker.size = Vector2(8, 16)
	marker.color = Color(1.0, 0.94, 0.64, 1.0)
	marker.z_index = 26
	battle.add_child(marker)

	var text := Label.new()
	text.name = "DuelMomentumText"
	text.position = Vector2(814, 88)
	text.size = Vector2(58, 22)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 11)
	text.modulate = Color(0.92, 0.90, 0.78, 0.94)
	text.add_theme_color_override("font_outline_color", era_theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	text.add_theme_constant_override("outline_size", 1)
	text.z_index = 23
	text.visible = false
	battle.add_child(text)

	var hint := Label.new()
	hint.name = "DuelMomentumHint"
	hint.position = Vector2(478, 105)
	hint.size = Vector2(328, 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.modulate = Color(0.78, 0.76, 0.64, 0.86)
	hint.z_index = 23
	hint.visible = false
	battle.add_child(hint)
	_update_duel_momentum_rail(battle, "开局对峙")

func _get_duel_momentum_rail_nodes(battle: Control) -> Array[CanvasItem]:
	var nodes: Array[CanvasItem] = []
	if battle == null:
		return nodes
	for node_name in [
		"DuelMomentumRail",
		"DuelMomentumTitle",
		"DuelMomentumTrack",
		"DuelMomentumPlayerFill",
		"DuelMomentumEnemyFill",
		"DuelMomentumCenterTick",
		"DuelMomentumMarker",
		"DuelMomentumText",
		"DuelMomentumHint",
		"DangerForecastPanel",
		"DangerForecastLevelBar",
		"DangerForecastLabel"
	]:
		var node := battle.get_node_or_null(node_name) as CanvasItem
		if node != null:
			nodes.append(node)
	return nodes

func _set_duel_momentum_rail_visible(battle: Control, visible: bool) -> void:
	for node in _get_duel_momentum_rail_nodes(battle):
		if node.name in ["DuelMomentumText", "DuelMomentumHint"]:
			node.visible = false
		else:
			node.visible = visible
	if not visible:
		_update_portrait_momentum_highlight(battle, 0)

func _is_battle_overlay_active(battle: Control) -> bool:
	return battle != null and (
		battle.get_node_or_null("LevelUpOverlay") != null
		or battle.get_node_or_null("BattleSettlementOverlay") != null
	)

func _restore_duel_momentum_rail_if_battle_active(battle: Control) -> void:
	if battle == null or not is_instance_valid(battle):
		return
	if _battle_ending or _is_battle_overlay_active(battle):
		return
	_set_duel_momentum_rail_visible(battle, true)
	_update_duel_momentum_rail(battle)

func _update_duel_momentum_rail(battle: Control, reason: String = "") -> void:
	if battle == null:
		return
	if _battle_ending or _is_battle_overlay_active(battle):
		_set_duel_momentum_rail_visible(battle, false)
		return
	_set_duel_momentum_rail_visible(battle, true)
	var track := battle.get_node_or_null("DuelMomentumTrack") as ColorRect
	var player_fill := battle.get_node_or_null("DuelMomentumPlayerFill") as ColorRect
	var enemy_fill := battle.get_node_or_null("DuelMomentumEnemyFill") as ColorRect
	var marker := battle.get_node_or_null("DuelMomentumMarker") as ColorRect
	var text := battle.get_node_or_null("DuelMomentumText") as Label
	var hint := battle.get_node_or_null("DuelMomentumHint") as Label
	if track == null or player_fill == null or enemy_fill == null or marker == null:
		return
	var clamped_score: int = clamp(_battle_momentum_score, -3, 3)
	var center_x := track.position.x + track.size.x * 0.5
	var half_width := track.size.x * 0.5
	var offset := float(clamped_score) / 3.0 * half_width
	if clamped_score > 0:
		player_fill.visible = true
		player_fill.position = Vector2(center_x, track.position.y)
		player_fill.size = Vector2(absf(offset), track.size.y)
		enemy_fill.visible = false
	elif clamped_score < 0:
		enemy_fill.visible = true
		enemy_fill.position = Vector2(center_x + offset, track.position.y)
		enemy_fill.size = Vector2(absf(offset), track.size.y)
		player_fill.visible = false
	else:
		player_fill.visible = false
		enemy_fill.visible = false
	marker.position = Vector2(center_x + offset - marker.size.x * 0.5, marker.position.y)
	if text != null:
		text.text = ""
		text.visible = false
	if hint != null:
		hint.text = ""
		hint.visible = false
	_update_portrait_momentum_highlight(battle, clamped_score)
	_update_boss_warning_label(battle, current_enemy_ai)

func _update_portrait_momentum_highlight(battle: Control, clamped_score: int) -> void:
	if battle == null:
		return
	_apply_portrait_momentum_highlight(
		battle.get_node_or_null("PlayerPortraitPanel") as Panel,
		maxi(clamped_score, 0),
		Color(0.60, 1.0, 0.72, 1.0)
	)
	_apply_portrait_momentum_highlight(
		battle.get_node_or_null("EnemyPortraitPanel") as Panel,
		maxi(-clamped_score, 0),
		Color(1.0, 0.34, 0.26, 1.0)
	)

func _apply_portrait_momentum_highlight(panel: Panel, score: int, glow_color: Color) -> void:
	if panel == null:
		return
	var base_style := panel.get_meta("base_style", null) as StyleBoxFlat
	if base_style == null:
		base_style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if base_style == null:
		return
	var strength := clampf(float(score) / 3.0, 0.0, 1.0)
	var style := base_style.duplicate() as StyleBoxFlat
	style.border_color = Color(base_style.border_color).lerp(glow_color, 0.25 + strength * 0.75)
	style.bg_color = Color(base_style.bg_color).lerp(Color(glow_color.r * 0.18, glow_color.g * 0.18, glow_color.b * 0.18, 0.94), strength * 0.55)
	style.set_border_width_all(2 + int(round(strength * 4.0)))
	style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.10 + strength * 0.42)
	style.shadow_size = int(round(strength * 18.0))
	style.shadow_offset = Vector2.ZERO
	panel.add_theme_stylebox_override("panel", style)
	panel.modulate = Color(1.0, 1.0, 1.0, 0.88 + strength * 0.12)

func _shift_duel_momentum(battle: Control, amount: int, reason: String) -> void:
	if battle == null or amount == 0:
		_update_duel_momentum_rail(battle, reason)
		return
	_battle_momentum_score = clamp(_battle_momentum_score + amount, -3, 3)
	_update_duel_momentum_rail(battle, reason)

func _get_duel_momentum_hint() -> String:
	if _battle_momentum_score >= 2:
		return "主动在手，适合兑现"
	if _battle_momentum_score <= -2:
		return "对面压来，先稳一拍"
	if _battle_momentum_score > 0:
		return "略占先，防被读"
	if _battle_momentum_score < 0:
		return "略失势，可换手"
	return "双方未分势"

func _get_momentum_field(battle: Control) -> MomentumField:
	if battle == null:
		return null
	var field := battle.get_node_or_null("PlayerMomentumField") as MomentumField
	if field != null:
		return field
	return battle.get_node_or_null("MomentumField") as MomentumField

func _get_enemy_momentum_field(battle: Control) -> MomentumField:
	if battle == null:
		return null
	return battle.get_node_or_null("EnemyMomentumField") as MomentumField

func _get_momentum_fields(battle: Control) -> Array[MomentumField]:
	var fields: Array[MomentumField] = []
	var player_field := _get_momentum_field(battle)
	var enemy_field := _get_enemy_momentum_field(battle)
	if player_field != null:
		fields.append(player_field)
	if enemy_field != null and enemy_field != player_field:
		fields.append(enemy_field)
	return fields

func _update_momentum_field(battle: Control) -> void:
	var fields := _get_momentum_fields(battle)
	if fields.is_empty():
		return
	var pending_force := GameState.field_pending_spend_attack + GameState.field_pending_blood_attack + GameState.field_pending_merchant_attack
	var state := {
		"player_hp_ratio": float(GameState.player_hp) / float(maxi(GameState.player_max_hp, 1)),
		"enemy_hp_ratio": float(battle_enemy_hp) / float(maxi(battle_enemy_max_hp, 1)),
		"shield": GameState.player_shield,
		"pending_force": pending_force
	}
	for field in fields:
		field.refresh_state(state)

func _show_momentum_reveal(battle: Control, player_move: int, enemy_move: int) -> void:
	var fields := _get_momentum_fields(battle)
	if fields.is_empty():
		return
	for field in fields:
		field.show_reveal(player_move, enemy_move)
	_play_battle_sfx(battle, "momentum_reveal")

func _show_momentum_outcome(battle: Control, turn_resolution: Dictionary) -> void:
	var fields := _get_momentum_fields(battle)
	if fields.is_empty():
		return
	var impact := {
		"damage": int(turn_resolution.get("damage_dealt", 0)),
		"actual_damage": int(turn_resolution.get("actual_damage", 0)),
		"shield_damage": int(turn_resolution.get("damage_to_shield", 0))
	}
	for field in fields:
		field.show_outcome(
			bool(turn_resolution.get("player_wins", false)),
			bool(turn_resolution.get("is_draw", false)),
			impact
		)
	if bool(turn_resolution.get("is_draw", false)):
		_play_battle_sfx(battle, "momentum_draw")
		_update_duel_momentum_rail(battle, "对住，势未偏")
	elif bool(turn_resolution.get("player_wins", false)):
		_play_battle_sfx(battle, "momentum_win")
		_shift_duel_momentum(battle, 1, "抢中一手，势向我")
	else:
		_play_battle_sfx(battle, "momentum_loss")
		_shift_duel_momentum(battle, -1, "失一手，对面压来")
	_update_momentum_field(battle)

func _show_momentum_trigger(battle: Control, trigger_id: String) -> void:
	var field := _get_momentum_field(battle)
	if field == null or trigger_id == "":
		return
	field.show_trigger(trigger_id)
	_play_battle_sfx(battle, "momentum_%s" % trigger_id)
	_update_momentum_field(battle)

func _show_momentum_enemy_intent(battle: Control, enemy_ai: EnemyAI) -> void:
	var field := _get_enemy_momentum_field(battle)
	if field == null:
		field = _get_momentum_field(battle)
	if field != null:
		field.show_enemy_intent(_get_momentum_enemy_intent_id(enemy_ai))
	_update_boss_warning_label(battle, enemy_ai)

func _get_momentum_enemy_intent_id(enemy_ai: EnemyAI) -> String:
	if enemy_ai == null:
		return ""
	if enemy_ai.ai_type == EnemyAI.Type.BOSS_PHASE:
		return "boss"
	match enemy_ai.ai_type:
		EnemyAI.Type.BASIC_FIXED:
			match enemy_ai.fixed_move:
				0, 1:
					return "attack"
				2:
					return "guard"
		EnemyAI.Type.ELITE_CYCLE:
			match enemy_ai.dynamic_subtype:
				1:
					return "guard"
				2, 4:
					return "read"
				_:
					return "attack"
		EnemyAI.Type.ADVANCED_DYNAMIC:
			match enemy_ai.dynamic_subtype:
				EnemyAI.DynamicSubtype.MIND_READER, EnemyAI.DynamicSubtype.MIMIC, EnemyAI.DynamicSubtype.SEQUENCE_MIMIC:
					return "read"
				EnemyAI.DynamicSubtype.STATE_BASED:
					var hp_percent := float(battle_enemy_hp) / float(maxi(battle_enemy_max_hp, 1))
					return "guard" if hp_percent > 0.6 else "attack"
				_:
					return "attack"
	return ""

func _get_momentum_trigger_id(label: String) -> String:
	match label:
		"盾刃":
			return "shield_blade"
		"连营":
			return "camp_banner"
		"反制":
			return "counter_sigil"
		"破财":
			return "broken_coin"
		"血契":
			return "blood_contract"
	return ""

func _show_battle_impact(battle: Control, text: String, impact_type: String = "hit", shake: int = 0) -> void:
	if battle == null:
		return
	_play_battle_sfx(battle, impact_type)
	_show_battle_effect_sprite(battle, impact_type)
	_show_battle_impact_popup(battle, text, impact_type)
	var impact_label = battle.get_node_or_null("BattleImpactLabel") as Label
	if impact_label and text.strip_edges() != "":
		var token := int(impact_label.get_meta("impact_token", 0)) + 1
		impact_label.set_meta("impact_token", token)
		impact_label.text = text
		impact_label.modulate = _get_battle_impact_color(impact_type)
		impact_label.modulate.a = 1.0
		impact_label.scale = Vector2(0.62, 0.62)
		impact_label.visible = true
		var label_tween = create_tween()
		label_tween.set_parallel(true)
		label_tween.tween_property(impact_label, "scale", Vector2(1.18, 1.18), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		label_tween.tween_property(impact_label, "modulate:a", 0.0, 0.38).set_delay(0.82)
		label_tween.chain().tween_callback(func():
			if is_instance_valid(impact_label) and int(impact_label.get_meta("impact_token", 0)) == token:
				impact_label.visible = false
				impact_label.modulate.a = 1.0
		)

	var flash = battle.get_node_or_null("BattleFlash") as ColorRect
	if flash:
		flash.color = _get_battle_flash_color(impact_type)
		flash.visible = true
		var flash_tween = create_tween()
		flash_tween.tween_property(flash, "color:a", 0.0, 0.34)
		flash_tween.tween_callback(func():
			if is_instance_valid(flash):
				flash.visible = false
		)

	if shake > 0:
		var origin := battle.position
		var shake_tween = create_tween()
		shake_tween.tween_property(battle, "position", origin + Vector2(shake, 0), 0.025)
		shake_tween.tween_property(battle, "position", origin + Vector2(-shake, 0), 0.035)
		shake_tween.tween_property(battle, "position", origin + Vector2(0, shake * 0.45), 0.025)
		shake_tween.tween_property(battle, "position", origin, 0.035)

func _show_battle_impact_popup(battle: Control, text: String, impact_type: String) -> void:
	var value_text := _extract_battle_popup_text(text)
	if value_text == "":
		return
	match impact_type:
		"hit", "crit", "cheat_burst", "heavy_hit", "read":
			_show_battle_actor_popup(battle, "enemy", value_text, Color(1.0, 0.42, 0.20, 1.0), impact_type in ["crit", "heavy_hit", "read"])
		"hurt":
			_show_battle_actor_popup(battle, "player", value_text, Color(1.0, 0.28, 0.24, 1.0), false)
		"break":
			_show_battle_actor_popup(battle, "player", value_text, Color(0.64, 0.90, 1.0, 1.0), true)
		"support_hit", "support_break":
			return
		_:
			return

func _extract_battle_popup_text(text: String) -> String:
	if text == "":
		return ""
	for raw_line in text.split("\n", false):
		var line := str(raw_line).strip_edges()
		if line.begins_with("-") or line.begins_with("+"):
			return line
	return ""

func _show_battle_actor_popup(battle: Control, actor: String, value_text: String, color: Color, heavy: bool = false) -> void:
	if battle == null or value_text == "":
		return
	var popup := Label.new()
	popup.text = value_text
	popup.position = Vector2(1018, 174) if actor == "enemy" else Vector2(92, 174)
	popup.custom_minimum_size = Vector2(170, 48)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 42 if heavy else 32)
	popup.add_theme_color_override("font_outline_color", Color(0.025, 0.018, 0.012, 1.0))
	popup.add_theme_constant_override("outline_size", 5 if heavy else 4)
	popup.modulate = color
	popup.scale = Vector2(0.64, 0.64)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_index = 94
	battle.add_child(popup)
	var drift := Vector2(0, -46)
	var side_kick := Vector2(-18, 0) if actor == "enemy" else Vector2(18, 0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position", popup.position + drift + side_kick, 0.86).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector2(1.18, 1.18) if heavy else Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 0.34).set_delay(0.62)
	tween.chain().tween_callback(func():
		if is_instance_valid(popup):
			popup.queue_free()
	)

func _show_battle_effect_sprite(battle: Control, impact_type: String) -> void:
	var effect_path := _get_battle_effect_path(impact_type)
	if effect_path == "":
		return
	var effect_texture := _load_texture_resource(effect_path)
	if effect_texture == null:
		return
	var spec := _get_battle_effect_spec(impact_type)
	var effect := TextureRect.new()
	effect.texture = effect_texture
	effect.position = spec.get("position", Vector2(552, 176))
	effect.custom_minimum_size = spec.get("size", Vector2(176, 176))
	effect.size = effect.custom_minimum_size
	effect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	effect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.pivot_offset = effect.size * 0.5
	effect.scale = spec.get("start_scale", Vector2(0.74, 0.74))
	effect.modulate = spec.get("color", Color.WHITE)
	effect.z_index = int(spec.get("z_index", 86))
	battle.add_child(effect)
	var target_scale: Vector2 = spec.get("target_scale", Vector2(1.18, 1.18))
	var duration := float(spec.get("duration", 0.34))
	var fade_delay := float(spec.get("fade_delay", 0.08))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", target_scale, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "modulate:a", 0.0, maxf(0.08, duration - fade_delay)).set_delay(fade_delay)
	tween.chain().tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _get_battle_effect_path(impact_type: String) -> String:
	match impact_type:
		"combo", "combo_damage", "combo_guard", "combo_control", "combo_recover", "combo_growth", "combo_clean", "combo_guarded", "combo_bloody", "combo_read", "finisher", "heavy_hit", "read":
			return ArtRegistry.get_effect_path("combo_flash")
		"crit":
			return ArtRegistry.get_effect_path("hit_slash")
		"break":
			return ArtRegistry.get_effect_path("shield_break")
		"support_hit", "support_break":
			return ArtRegistry.get_effect_path("shield_break" if impact_type == "support_break" else "hit_spark")
		"phase":
			return ArtRegistry.get_effect_path("boss_phase_flash")
		"victory":
			return ArtRegistry.get_effect_path("victory_stamp")
		"defeat":
			return ArtRegistry.get_effect_path("defeat_stamp")
		"draw":
			return ArtRegistry.get_effect_path("draw_stamp")
		"hurt":
			return ArtRegistry.get_effect_path("hit_slash")
		"hit", "cheat_burst":
			return ArtRegistry.get_effect_path("hit_spark")
		"cheat_guard":
			return ArtRegistry.get_effect_path("draw_stamp")
		_:
			return ""

func _get_battle_effect_spec(impact_type: String) -> Dictionary:
	match impact_type:
		"victory", "defeat", "draw":
			return {
				"position": Vector2(504, 154),
				"size": Vector2(272, 196),
				"start_scale": Vector2(0.68, 0.68),
				"target_scale": Vector2(1.08, 1.08),
				"duration": 0.82,
				"fade_delay": 0.52,
				"z_index": 92,
			}
		"combo", "combo_damage", "combo_guard", "combo_control", "combo_recover", "combo_growth", "combo_clean", "combo_guarded", "combo_bloody", "combo_read", "heavy_hit", "read":
			return {
				"position": Vector2(488, 146),
				"size": Vector2(304, 216),
				"start_scale": Vector2(0.56, 0.56),
				"target_scale": Vector2(1.24, 1.24),
				"duration": 0.70,
				"fade_delay": 0.34,
				"z_index": 88,
			}
		"finisher":
			return {
				"position": Vector2(448, 116),
				"size": Vector2(384, 276),
				"start_scale": Vector2(0.48, 0.48),
				"target_scale": Vector2(1.34, 1.34),
				"duration": 0.82,
				"fade_delay": 0.42,
				"z_index": 89,
			}
		"phase":
			return {
				"position": Vector2(962, 124),
				"size": Vector2(300, 300),
				"start_scale": Vector2(0.62, 0.62),
				"target_scale": Vector2(1.18, 1.18),
				"duration": 0.76,
				"fade_delay": 0.40,
				"z_index": 88,
			}
		"support_hit", "support_break":
			return {
				"position": Vector2(688, 184),
				"size": Vector2(214, 130),
				"start_scale": Vector2(0.62, 0.62),
				"target_scale": Vector2(1.12, 1.12),
				"duration": 0.52,
				"fade_delay": 0.22,
				"z_index": 88,
			}
		"break", "hurt":
			return {
				"position": Vector2(78, 188),
				"size": Vector2(190, 150),
				"start_scale": Vector2(0.72, 0.72),
				"target_scale": Vector2(1.18, 1.18),
				"duration": 0.58,
				"fade_delay": 0.26,
				"z_index": 88,
			}
		"hit", "crit", "cheat_burst":
			return {
				"position": Vector2(984, 188),
				"size": Vector2(206, 158),
				"start_scale": Vector2(0.72, 0.72),
				"target_scale": Vector2(1.20, 1.20),
				"duration": 0.58,
				"fade_delay": 0.26,
				"z_index": 88,
			}
		"cheat_guard":
			return {
				"position": Vector2(504, 154),
				"size": Vector2(246, 178),
				"start_scale": Vector2(0.72, 0.72),
				"target_scale": Vector2(1.04, 1.04),
				"duration": 0.68,
				"fade_delay": 0.36,
				"z_index": 90,
			}
		_:
			return {
				"position": Vector2(552, 176),
				"size": Vector2(176, 176),
				"start_scale": Vector2(0.74, 0.74),
				"target_scale": Vector2(1.12, 1.12),
				"duration": 0.54,
				"fade_delay": 0.24,
				"z_index": 86,
			}

func _play_battle_sfx(battle: Control, impact_type: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if battle == null or AudioServer.is_bus_mute(0):
		return
	var player = battle.get_node_or_null("BattleSfxPlayer") as AudioStreamPlayer
	var overlay_player = battle.get_node_or_null("BattleSfxOverlayPlayer") as AudioStreamPlayer
	if player == null:
		return
	var profile := _get_battle_sfx_profile(impact_type)
	_play_battle_sfx_voice(player, profile)
	var overlay_profile := _get_battle_sfx_overlay_profile(impact_type)
	if overlay_player != null and not overlay_profile.is_empty():
		_play_battle_sfx_voice(overlay_player, overlay_profile)

func _play_battle_sfx_voice(player: AudioStreamPlayer, profile: Dictionary) -> void:
	if player == null or profile.is_empty():
		return
	var duration := float(profile.get("duration", 0.08))
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = maxf(0.18, duration + 0.06)
	player.stream = generator
	player.volume_db = float(profile.get("volume_db", -9.0))
	player.play()
	var playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var freq_a := float(profile.get("freq_a", 520.0))
	var freq_b := float(profile.get("freq_b", 0.0))
	var amp := float(profile.get("amp", 0.28))
	var frame_count := int(generator.mix_rate * duration)
	for i in range(frame_count):
		var t := float(i) / generator.mix_rate
		var progress := float(i) / maxf(float(frame_count), 1.0)
		var envelope := pow(1.0 - progress, float(profile.get("decay", 1.8)))
		var sweep := lerpf(freq_a, float(profile.get("freq_end", freq_a)), progress)
		var sample := sin(TAU * sweep * t)
		if freq_b > 0.0:
			sample += sin(TAU * freq_b * t) * 0.55
		if bool(profile.get("metal", false)):
			sample += sin(TAU * 1820.0 * t) * 0.32
			sample += sin(TAU * 3170.0 * t) * 0.18
			if progress < 0.18:
				sample += randf_range(-1.0, 1.0) * 0.62
		if bool(profile.get("crack", false)):
			var shard_gate := 1.0 if fmod(progress * 34.0, 1.0) < 0.38 else 0.0
			sample += randf_range(-1.0, 1.0) * 0.72 * shard_gate
			sample += sin(TAU * 2450.0 * t) * 0.28 * shard_gate
		if bool(profile.get("charge", false)):
			var charge_env := sin(progress * PI)
			var lift := pow(progress, 0.62)
			sample += sin(TAU * lerpf(420.0, 2380.0, lift) * t) * charge_env * 0.38
			sample += sin(TAU * lerpf(760.0, 3180.0, lift) * t) * charge_env * 0.16
			sample += randf_range(-1.0, 1.0) * charge_env * 0.22
		if bool(profile.get("oracle", false)):
			var oracle_env := sin(progress * PI)
			var step: float = floor(progress * 5.0) / 5.0
			sample += sin(TAU * lerpf(620.0, 1860.0, step) * t) * oracle_env * 0.26
			sample += sin(TAU * lerpf(1240.0, 3120.0, progress) * t) * oracle_env * 0.12
			if fmod(progress * 18.0, 1.0) < 0.18:
				sample += sin(TAU * 4020.0 * t) * oracle_env * 0.10
		if bool(profile.get("burst", false)):
			var burst_env := pow(1.0 - progress, 2.2)
			sample += sin(TAU * 96.0 * t) * burst_env * 0.74
			sample += sin(TAU * 1640.0 * t) * burst_env * 0.28
			sample += sin(TAU * 2920.0 * t) * burst_env * 0.13
			sample += randf_range(-1.0, 1.0) * burst_env * 0.46
		if bool(profile.get("seal_cut", false)):
			var cut_env := pow(1.0 - progress, 1.65)
			sample += sin(TAU * 84.0 * t) * cut_env * 0.86
			sample += sin(TAU * 246.0 * t) * cut_env * 0.26
			if progress < 0.24:
				sample += randf_range(-1.0, 1.0) * cut_env * 0.32
			if progress > 0.18 and progress < 0.52:
				var ring_env := sin((progress - 0.18) / 0.34 * PI)
				sample += sin(TAU * 1760.0 * t) * ring_env * 0.28
				sample += sin(TAU * 2640.0 * t) * ring_env * 0.12
		if bool(profile.get("rewind", false)):
			var fall := pow(progress, 0.72)
			var ring_env := pow(1.0 - progress, 0.35)
			sample += sin(TAU * lerpf(1680.0, 360.0, fall) * t) * ring_env * 0.26
			sample += sin(TAU * lerpf(940.0, 220.0, fall) * t) * ring_env * 0.18
			if fmod(progress * 9.0, 1.0) < 0.42:
				sample *= 0.58
		if bool(profile.get("sparkle", false)):
			var sparkle_gate := 1.0 if fmod(progress * 42.0, 1.0) < 0.28 else 0.0
			sample += sin(TAU * 2860.0 * t) * sparkle_gate * 0.22
			sample += sin(TAU * 3680.0 * t) * sparkle_gate * 0.14
		if bool(profile.get("thud", false)):
			var thud_env := pow(1.0 - progress, 1.8)
			sample += sin(TAU * 72.0 * t) * thud_env * 0.54
			sample += sin(TAU * 124.0 * t) * thud_env * 0.28
		if bool(profile.get("alarm", false)):
			var pulse := 1.0 if fmod(progress * 7.0, 1.0) < 0.48 else 0.0
			sample += sin(TAU * 1180.0 * t) * pulse * 0.20
			sample += sin(TAU * 1480.0 * t) * pulse * 0.12
		if bool(profile.get("choir", false)):
			var choir_env := sin(progress * PI)
			sample += sin(TAU * 520.0 * t) * choir_env * 0.18
			sample += sin(TAU * 780.0 * t) * choir_env * 0.10
		if bool(profile.get("miracle", false)):
			var lift := pow(progress, 0.62)
			if progress < 0.58:
				var charge_env := sin(progress / 0.58 * PI)
				sample += sin(TAU * lerpf(420.0, 2380.0, lift) * t) * charge_env * 0.36
				sample += randf_range(-1.0, 1.0) * charge_env * 0.22
			else:
				var burst_progress := (progress - 0.58) / 0.42
				var burst_env := pow(1.0 - burst_progress, 2.2)
				sample += sin(TAU * 96.0 * t) * burst_env * 0.70
				sample += sin(TAU * 1640.0 * t) * burst_env * 0.24
				sample += randf_range(-1.0, 1.0) * burst_env * 0.42
		if bool(profile.get("collapse", false)):
			var fall := pow(progress, 0.74)
			sample += sin(TAU * lerpf(220.0, 62.0, fall) * t) * 0.44
			sample += sin(TAU * lerpf(92.0, 38.0, fall) * t) * 0.32
			if progress > 0.48 and progress < 0.70:
				var thud_env := sin((progress - 0.48) / 0.22 * PI)
				sample += sin(TAU * 54.0 * t) * thud_env * 0.58
			if progress > 0.70:
				var seal_env := pow((progress - 0.70) / 0.30, 0.8) * pow(1.0 - progress, 0.55)
				sample += sin(TAU * 660.0 * t) * seal_env * 0.26
		if bool(profile.get("noise", false)):
			sample += randf_range(-1.0, 1.0) * 0.35
		sample *= amp * envelope
		playback.push_frame(Vector2(sample, sample))

func _get_battle_sfx_profile(impact_type: String) -> Dictionary:
	match impact_type:
		"momentum_reveal":
			return {"freq_a": 420.0, "freq_end": 620.0, "freq_b": 840.0, "duration": 0.08, "amp": 0.16, "volume_db": -14.0, "sparkle": true, "decay": 1.7}
		"momentum_win":
			return {"freq_a": 240.0, "freq_end": 760.0, "freq_b": 1260.0, "duration": 0.16, "amp": 0.24, "volume_db": -10.0, "charge": true, "decay": 0.95}
		"momentum_loss":
			return {"freq_a": 260.0, "freq_end": 82.0, "freq_b": 124.0, "duration": 0.18, "amp": 0.30, "volume_db": -8.4, "thud": true, "decay": 1.4}
		"momentum_draw":
			return {"freq_a": 320.0, "freq_end": 260.0, "freq_b": 344.0, "duration": 0.12, "amp": 0.22, "volume_db": -11.2, "rewind": true, "decay": 0.9}
		"momentum_shield_blade":
			return {"freq_a": 180.0, "freq_end": 740.0, "freq_b": 1720.0, "duration": 0.18, "amp": 0.32, "volume_db": -7.2, "metal": true, "seal_cut": true, "decay": 1.5}
		"momentum_afterlife_lamp":
			return {"freq_a": 420.0, "freq_end": 980.0, "freq_b": 1480.0, "duration": 0.22, "amp": 0.22, "volume_db": -10.2, "choir": true, "sparkle": true, "decay": 0.75}
		"momentum_broken_coin":
			return {"freq_a": 720.0, "freq_end": 360.0, "freq_b": 1440.0, "duration": 0.16, "amp": 0.26, "volume_db": -8.8, "metal": true, "sparkle": true, "decay": 2.3}
		"momentum_camp_banner":
			return {"freq_a": 210.0, "freq_end": 520.0, "freq_b": 980.0, "duration": 0.20, "amp": 0.28, "volume_db": -8.4, "burst": true, "decay": 1.25}
		"momentum_blood_contract":
			return {"freq_a": 112.0, "freq_end": 340.0, "freq_b": 720.0, "duration": 0.22, "amp": 0.30, "volume_db": -8.0, "thud": true, "alarm": true, "decay": 1.2}
		"momentum_counter_sigil":
			return {"freq_a": 520.0, "freq_end": 220.0, "freq_b": 1040.0, "duration": 0.18, "amp": 0.24, "volume_db": -9.2, "rewind": true, "metal": true, "decay": 0.82}
		"finisher":
			return {"freq_a": 146.0, "freq_end": 54.0, "freq_b": 1760.0, "duration": 0.24, "amp": 0.46, "volume_db": -4.4, "metal": true, "seal_cut": true, "burst": true, "decay": 1.35}
		"heavy_hit":
			return {"freq_a": 168.0, "freq_end": 64.0, "freq_b": 1240.0, "duration": 0.18, "amp": 0.42, "volume_db": -4.8, "metal": true, "thud": true, "burst": true, "decay": 2.0}
		"read":
			return {"freq_a": 760.0, "freq_end": 260.0, "freq_b": 1520.0, "duration": 0.15, "amp": 0.34, "volume_db": -6.0, "sparkle": true, "metal": true, "decay": 2.1}
		"combo", "combo_damage", "combo_guard", "combo_control", "combo_recover", "combo_growth", "combo_clean", "combo_guarded", "combo_bloody", "combo_read":
			return {"freq_a": 620.0, "freq_b": 930.0, "duration": 0.12, "amp": 0.24, "volume_db": -8.5, "sparkle": true}
		"crit":
			return {"freq_a": 210.0, "freq_end": 82.0, "freq_b": 980.0, "duration": 0.17, "amp": 0.40, "volume_db": -5.0, "metal": true, "thud": true, "decay": 2.4}
		"break":
			return {"freq_a": 420.0, "freq_end": 116.0, "freq_b": 1960.0, "duration": 0.15, "amp": 0.32, "volume_db": -6.2, "crack": true, "thud": true, "decay": 1.3}
		"support_hit", "support_break":
			return {"freq_a": 360.0, "freq_end": 128.0, "freq_b": 1440.0, "duration": 0.12, "amp": 0.28, "volume_db": -7.0, "crack": impact_type == "support_break", "thud": true, "decay": 1.5}
		"cheat":
			return {"freq_a": 520.0, "freq_end": 1480.0, "freq_b": 2600.0, "duration": 0.24, "amp": 0.30, "volume_db": -7.0, "oracle": true, "sparkle": true, "decay": 0.72}
		"cheat_charge":
			return {"freq_a": 480.0, "freq_end": 2860.0, "duration": 0.26, "amp": 0.30, "volume_db": -7.2, "oracle": true, "charge": true, "decay": 0.30}
		"cheat_burst":
			return {"freq_a": 84.0, "freq_b": 1760.0, "duration": 0.20, "amp": 0.44, "volume_db": -4.6, "seal_cut": true, "burst": true, "decay": 1.05}
		"cheat_guard":
			return {"freq_a": 740.0, "freq_end": 280.0, "freq_b": 1180.0, "duration": 0.24, "amp": 0.26, "volume_db": -8.0, "rewind": true, "sparkle": true, "decay": 0.62}
		"hurt":
			return {"freq_a": 118.0, "freq_b": 236.0, "duration": 0.12, "amp": 0.34, "volume_db": -6.8, "thud": true, "decay": 1.5}
		"phase":
			return {"freq_a": 188.0, "freq_b": 376.0, "duration": 0.22, "amp": 0.28, "volume_db": -6.5, "alarm": true, "decay": 1.1}
		"victory":
			return {"freq_a": 260.0, "freq_end": 58.0, "freq_b": 92.0, "duration": 0.34, "amp": 0.34, "volume_db": -5.8, "collapse": true, "choir": true, "decay": 0.72}
		"defeat":
			return {"freq_a": 95.0, "freq_b": 142.0, "duration": 0.18, "amp": 0.33, "volume_db": -6.5, "noise": true}
		"draw":
			return {"freq_a": 360.0, "freq_b": 420.0, "duration": 0.07, "amp": 0.18, "volume_db": -12.0}
		_:
			return {"freq_a": 540.0, "freq_end": 240.0, "freq_b": 1180.0, "duration": 0.10, "amp": 0.26, "volume_db": -7.3, "metal": true, "decay": 2.0}

func _get_battle_sfx_overlay_profile(impact_type: String) -> Dictionary:
	match impact_type:
		"momentum_win", "momentum_shield_blade", "momentum_broken_coin", "momentum_camp_banner", "momentum_counter_sigil":
			return {"freq_a": 1360.0, "freq_end": 2260.0, "freq_b": 2840.0, "duration": 0.10, "amp": 0.10, "volume_db": -15.0, "sparkle": true, "decay": 1.6}
		"momentum_loss", "momentum_blood_contract":
			return {"freq_a": 660.0, "freq_end": 180.0, "duration": 0.12, "amp": 0.10, "volume_db": -15.0, "noise": true, "decay": 1.5}
		"momentum_afterlife_lamp":
			return {"freq_a": 880.0, "freq_end": 1620.0, "freq_b": 2360.0, "duration": 0.14, "amp": 0.10, "volume_db": -15.5, "choir": true, "sparkle": true, "decay": 1.1}
		"finisher":
			return {"freq_a": 1620.0, "freq_end": 860.0, "freq_b": 3060.0, "duration": 0.16, "amp": 0.18, "volume_db": -9.8, "metal": true, "sparkle": true, "decay": 2.4}
		"combo", "combo_damage", "combo_guard", "combo_control", "combo_recover", "combo_growth", "combo_clean", "combo_guarded", "combo_bloody", "combo_read", "read":
			return {"freq_a": 1180.0, "freq_b": 1760.0, "duration": 0.08, "amp": 0.14, "volume_db": -12.0, "sparkle": true, "decay": 2.4}
		"heavy_hit":
			return {"freq_a": 1420.0, "freq_b": 2460.0, "duration": 0.10, "amp": 0.18, "volume_db": -9.8, "metal": true, "sparkle": true, "decay": 2.2}
		"crit":
			return {"freq_a": 1480.0, "freq_end": 920.0, "freq_b": 2680.0, "duration": 0.12, "amp": 0.18, "volume_db": -10.0, "metal": true, "sparkle": true, "decay": 2.8}
		"break":
			return {"freq_a": 1680.0, "freq_end": 620.0, "freq_b": 2860.0, "duration": 0.10, "amp": 0.16, "volume_db": -10.5, "crack": true, "decay": 2.0}
		"support_hit", "support_break":
			return {"freq_a": 1240.0, "freq_end": 520.0, "freq_b": 2360.0, "duration": 0.08, "amp": 0.11, "volume_db": -12.5, "crack": impact_type == "support_break", "decay": 2.0}
		"cheat_charge":
			return {"freq_a": 1560.0, "freq_end": 3320.0, "duration": 0.12, "amp": 0.11, "volume_db": -13.5, "oracle": true, "sparkle": true, "decay": 0.8}
		"cheat_burst":
			return {"freq_a": 1820.0, "freq_end": 920.0, "freq_b": 3160.0, "duration": 0.12, "amp": 0.16, "volume_db": -10.5, "metal": true, "sparkle": true, "decay": 2.2}
		"cheat_guard":
			return {"freq_a": 1240.0, "freq_end": 420.0, "duration": 0.16, "amp": 0.12, "volume_db": -13.0, "rewind": true, "decay": 0.9}
		"hurt":
			return {"freq_a": 680.0, "freq_end": 240.0, "duration": 0.09, "amp": 0.12, "volume_db": -12.5, "noise": true, "decay": 2.0}
		"phase":
			return {"freq_a": 880.0, "freq_b": 1320.0, "duration": 0.18, "amp": 0.14, "volume_db": -12.0, "alarm": true, "decay": 1.4}
		"victory":
			return {"freq_a": 780.0, "freq_b": 1180.0, "duration": 0.16, "amp": 0.14, "volume_db": -12.0, "choir": true, "sparkle": true, "decay": 1.5}
		_:
			return {}

func _get_battle_impact_color(impact_type: String) -> Color:
	match impact_type:
		"finisher":
			return Color(1.0, 0.92, 0.42, 1.0)
		"breakthrough":
			return Color(0.88, 1.0, 0.58, 1.0)
		"combo":
			return Color(1.0, 0.84, 0.28, 1.0)
		"combo_damage":
			return Color(1.0, 0.62, 0.18, 1.0)
		"combo_guard":
			return Color(0.72, 0.92, 1.0, 1.0)
		"combo_control":
			return Color(0.68, 0.96, 1.0, 1.0)
		"combo_recover":
			return Color(0.66, 1.0, 0.74, 1.0)
		"combo_growth":
			return Color(0.88, 1.0, 0.42, 1.0)
		"combo_clean":
			return Color(1.0, 0.90, 0.30, 1.0)
		"combo_guarded":
			return Color(0.70, 0.90, 1.0, 1.0)
		"combo_bloody":
			return Color(1.0, 0.38, 0.26, 1.0)
		"combo_read":
			return Color(1.0, 0.66, 0.22, 1.0)
		"heirloom":
			return Color(0.62, 0.96, 0.74, 1.0)
		"item":
			return Color(0.68, 0.86, 1.0, 1.0)
		"read":
			return Color(1.0, 0.90, 0.44, 1.0)
		"heavy_hit":
			return Color(1.0, 0.62, 0.18, 1.0)
		"clutch":
			return Color(1.0, 0.56, 0.26, 1.0)
		"danger":
			return Color(1.0, 0.42, 0.34, 1.0)
		"crit":
			return Color(1.0, 0.22, 0.10, 1.0)
		"break":
			return Color(0.72, 0.92, 1.0, 1.0)
		"support_hit", "support_break":
			return Color(1.0, 0.68, 0.36, 1.0)
		"cheat", "cheat_charge", "cheat_burst", "cheat_guard":
			return Color(0.72, 1.0, 0.92, 1.0)
		"hurt":
			return Color(1.0, 0.34, 0.28, 1.0)
		"phase":
			return Color(0.92, 0.72, 1.0, 1.0)
		"victory":
			return Color(0.98, 0.86, 0.30, 1.0)
		"defeat":
			return Color(0.62, 0.10, 0.08, 1.0)
		"draw":
			return Color(0.74, 0.86, 1.0, 1.0)
		_:
			return Color(0.90, 1.0, 0.72, 1.0)

func _get_battle_flash_color(impact_type: String) -> Color:
	match impact_type:
		"finisher":
			return Color(1.0, 0.82, 0.08, 0.44)
		"combo_damage":
			return Color(1.0, 0.34, 0.06, 0.32)
		"combo_guard":
			return Color(0.38, 0.72, 1.0, 0.30)
		"combo_control":
			return Color(0.44, 0.92, 1.0, 0.32)
		"combo_recover":
			return Color(0.30, 1.0, 0.54, 0.28)
		"combo_growth":
			return Color(0.82, 1.0, 0.18, 0.30)
		"combo_clean":
			return Color(1.0, 0.82, 0.10, 0.38)
		"combo_guarded":
			return Color(0.40, 0.72, 1.0, 0.28)
		"combo_bloody":
			return Color(1.0, 0.10, 0.04, 0.34)
		"combo_read":
			return Color(1.0, 0.48, 0.06, 0.34)
		"combo", "read":
			return Color(1.0, 0.72, 0.08, 0.32)
		"heavy_hit":
			return Color(1.0, 0.46, 0.04, 0.42)
		"crit":
			return Color(1.0, 0.12, 0.04, 0.38)
		"break":
			return Color(0.64, 0.92, 1.0, 0.34)
		"support_hit", "support_break":
			return Color(1.0, 0.48, 0.12, 0.28)
		"cheat", "cheat_charge", "cheat_burst":
			return Color(0.28, 1.0, 0.72, 0.36)
		"cheat_guard":
			return Color(0.38, 0.86, 1.0, 0.22)
		"hurt", "defeat":
			return Color(0.80, 0.02, 0.02, 0.34)
		"phase":
			return Color(0.56, 0.10, 0.86, 0.35)
		"victory":
			return Color(1.0, 0.86, 0.18, 0.38)
		"draw":
			return Color(0.55, 0.70, 1.0, 0.18)
		_:
			return Color(1.0, 1.0, 1.0, 0.18)

func _get_combo_impact_text(triggered_combos: Array[Dictionary]) -> String:
	if triggered_combos.is_empty():
		return ""
	var names: Array[String] = []
	for entry in triggered_combos:
		var combo = entry.get("combo")
		if combo != null:
			var combo_name := _get_combo_name(combo)
			var upgrade_level := GameState.get_combo_upgrade_level(_get_combo_id(combo))
			names.append("%s Lv.%d" % [combo_name, upgrade_level] if upgrade_level > 0 else combo_name)
	if names.is_empty():
		return ""
	var peak_level := _get_combo_feedback_peak_level(triggered_combos)
	var title := "终式" if _triggered_combos_have_finisher(triggered_combos) or peak_level >= 4 else "强化" if peak_level > 0 else "成局"
	return "%s\n%s" % [title, " / ".join(names)]

func _get_compact_combo_completion_text(triggered_combos: Array[Dictionary]) -> String:
	var names: Array[String] = []
	for entry in triggered_combos:
		var combo = entry.get("combo")
		if combo == null:
			continue
		var combo_name := _get_combo_name(combo)
		var level := GameState.get_combo_upgrade_level(_get_combo_id(combo))
		names.append("%s Lv.%d" % [combo_name, level] if level > 0 else combo_name)
	if names.is_empty():
		return ""
	var prefix := "终式" if _triggered_combos_have_finisher(triggered_combos) else "兑现"
	return "%s｜%s" % [prefix, " / ".join(names.slice(0, 2))]

func _get_combo_feedback_peak_level(triggered_combos: Array[Dictionary]) -> int:
	var peak_level := 0
	for entry in triggered_combos:
		var combo = entry.get("combo")
		if combo == null:
			continue
		peak_level = maxi(peak_level, GameState.get_combo_upgrade_level(_get_combo_id(combo)))
	return peak_level

func _triggered_combos_have_finisher(triggered_combos: Array[Dictionary]) -> bool:
	for entry in triggered_combos:
		var combo = entry.get("combo")
		if combo != null and _is_finisher_combo(combo):
			return true
	return false

func _get_combo_process_feedback(triggered_combos: Array[Dictionary]) -> Dictionary:
	var best := {
		"kind": "normal",
		"label": "三拍成局",
		"priority": 0
	}
	for entry in triggered_combos:
		var combo = entry.get("combo")
		if combo == null:
			continue
		var length := int(entry.get("length", combo.sequence.size()))
		var state := _get_combo_process_state(length)
		if int(state.get("priority", 0)) > int(best.get("priority", 0)):
			best = state
	return best

func _get_combo_process_state(length: int) -> Dictionary:
	var state := {
		"kind": "normal",
		"label": "三拍成局",
		"priority": 0
	}
	if length <= 0 or _player_move_history.is_empty() or _enemy_move_history.is_empty():
		return state
	var count := mini(length, mini(_player_move_history.size(), _enemy_move_history.size()))
	var start := _player_move_history.size() - count
	var wins := 0
	var draws := 0
	var losses := 0
	var enemy_repeated := false
	for i in range(start, _player_move_history.size()):
		var player_move := int(_player_move_history[i])
		var enemy_move := int(_enemy_move_history[i])
		if _player_beats_enemy_move(player_move, enemy_move):
			wins += 1
		elif player_move == enemy_move:
			draws += 1
		else:
			losses += 1
		if i > start and int(_enemy_move_history[i]) == int(_enemy_move_history[i - 1]):
			enemy_repeated = true
	if wins == count and count > 0:
		return {"kind": "clean", "label": "全胜成势", "priority": 4}
	if losses > 0:
		return {"kind": "bloody", "label": "险中成势", "priority": 3}
	if enemy_repeated:
		return {"kind": "read", "label": "破绽已露", "priority": 2}
	if draws > 0:
		return {"kind": "guarded", "label": "平局守势", "priority": 1}
	return state

func _get_combo_completion_impact_type(triggered_combos: Array[Dictionary]) -> String:
	var peak_level := _get_combo_feedback_peak_level(triggered_combos)
	if _triggered_combos_have_finisher(triggered_combos) or peak_level >= 4:
		return "finisher"
	var process := _get_combo_process_feedback(triggered_combos)
	match str(process.get("kind", "normal")):
		"clean":
			return "combo_clean"
		"guarded":
			return "combo_guarded"
		"bloody":
			return "combo_bloody"
		"read":
			return "combo_read"
	return "combo_%s" % _get_combo_completion_family(triggered_combos)

func _get_combo_completion_family(triggered_combos: Array[Dictionary]) -> String:
	var families: Dictionary = {}
	for entry in triggered_combos:
		var combo = entry.get("combo")
		if combo == null:
			continue
		var family := _get_combo_effect_family(str(combo.effect_type))
		families[family] = int(families.get(family, 0)) + 1
	if families.is_empty():
		return "damage"
	for priority in ["control", "guard", "recover", "growth", "damage"]:
		if families.has(priority):
			return priority
	return "damage"

func _get_combo_effect_family(effect_type: String) -> String:
	match effect_type:
		"shield_reflect", "shield_reflect_adv", "shield_all", "shield_duration", "shield_to_damage", "armor_delayed", "invincible":
			return "guard"
		"enemy_cooldown", "stun_damage":
			return "control"
		"heal", "heal_shield", "regen", "desperate":
			return "recover"
		"attack_buff", "crit_buff", "ignore_armor", "life_steal_50", "reflect_3x", "auto_crit", "pierce_buff", "bonus_gold":
			return "growth"
		_:
			return "damage"

func _get_combo_completion_palette(triggered_combos: Array[Dictionary], impact_type: String) -> Dictionary:
	if impact_type == "finisher":
		return {
			"bg": Color(0.13, 0.08, 0.02, 0.90),
			"border": Color(1.0, 0.88, 0.25, 0.96),
			"title": Color(1.0, 0.94, 0.42, 1.0),
			"body": Color(1.0, 0.90, 0.64, 1.0),
			"hint": Color(1.0, 0.72, 0.24, 0.90),
			"ring": Color(1.0, 0.86, 0.18, 0.45)
		}
	var process := _get_combo_process_feedback(triggered_combos)
	match str(process.get("kind", "normal")):
		"clean":
			return {
				"bg": Color(0.16, 0.10, 0.02, 0.90),
				"border": Color(1.0, 0.84, 0.24, 0.94),
				"title": Color(1.0, 0.94, 0.38, 1.0),
				"body": Color(1.0, 0.88, 0.58, 1.0),
				"hint": Color(1.0, 0.74, 0.22, 0.92),
				"ring": Color(1.0, 0.78, 0.16, 0.42)
			}
		"guarded":
			return {
				"bg": Color(0.04, 0.09, 0.16, 0.88),
				"border": Color(0.58, 0.84, 1.0, 0.90),
				"title": Color(0.76, 0.94, 1.0, 1.0),
				"body": Color(0.86, 0.94, 1.0, 1.0),
				"hint": Color(0.64, 0.82, 1.0, 0.90),
				"ring": Color(0.44, 0.76, 1.0, 0.38)
			}
		"bloody":
			return {
				"bg": Color(0.16, 0.035, 0.025, 0.90),
				"border": Color(1.0, 0.36, 0.20, 0.94),
				"title": Color(1.0, 0.52, 0.34, 1.0),
				"body": Color(1.0, 0.78, 0.68, 1.0),
				"hint": Color(1.0, 0.46, 0.30, 0.92),
				"ring": Color(1.0, 0.20, 0.08, 0.34)
			}
		"read":
			return {
				"bg": Color(0.14, 0.075, 0.025, 0.88),
				"border": Color(1.0, 0.58, 0.18, 0.92),
				"title": Color(1.0, 0.72, 0.28, 1.0),
				"body": Color(1.0, 0.86, 0.66, 1.0),
				"hint": Color(1.0, 0.58, 0.22, 0.90),
				"ring": Color(1.0, 0.48, 0.12, 0.36)
			}
	match _get_combo_completion_family(triggered_combos):
		"guard":
			return {
				"bg": Color(0.04, 0.10, 0.14, 0.86),
				"border": Color(0.58, 0.86, 1.0, 0.86),
				"title": Color(0.76, 0.94, 1.0, 1.0),
				"body": Color(0.86, 0.94, 1.0, 1.0),
				"hint": Color(0.62, 0.82, 1.0, 0.88),
				"ring": Color(0.48, 0.82, 1.0, 0.38)
			}
		"control":
			return {
				"bg": Color(0.06, 0.06, 0.15, 0.86),
				"border": Color(0.54, 0.92, 1.0, 0.90),
				"title": Color(0.70, 1.0, 0.98, 1.0),
				"body": Color(0.88, 0.84, 1.0, 1.0),
				"hint": Color(0.70, 0.76, 1.0, 0.88),
				"ring": Color(0.50, 0.84, 1.0, 0.36)
			}
		"recover":
			return {
				"bg": Color(0.04, 0.13, 0.09, 0.86),
				"border": Color(0.48, 1.0, 0.70, 0.86),
				"title": Color(0.70, 1.0, 0.78, 1.0),
				"body": Color(0.86, 1.0, 0.88, 1.0),
				"hint": Color(0.58, 1.0, 0.72, 0.88),
				"ring": Color(0.36, 1.0, 0.62, 0.34)
			}
		"growth":
			return {
				"bg": Color(0.10, 0.11, 0.03, 0.86),
				"border": Color(0.92, 0.96, 0.34, 0.88),
				"title": Color(0.92, 1.0, 0.48, 1.0),
				"body": Color(0.96, 0.94, 0.68, 1.0),
				"hint": Color(0.74, 1.0, 0.46, 0.88),
				"ring": Color(0.90, 1.0, 0.30, 0.34)
			}
		_:
			return {
				"bg": Color(0.12, 0.07, 0.03, 0.86),
				"border": Color(1.0, 0.58, 0.20, 0.88),
				"title": Color(1.0, 0.76, 0.30, 1.0),
				"body": Color(1.0, 0.88, 0.70, 1.0),
				"hint": Color(1.0, 0.64, 0.28, 0.88),
				"ring": Color(1.0, 0.48, 0.16, 0.34)
			}

func _show_combo_completion_feedback(battle: Control, triggered_combos: Array[Dictionary]) -> void:
	var combo_impact_text := _get_combo_impact_text(triggered_combos)
	if battle == null or combo_impact_text == "":
		return
	var peak_level := _get_combo_feedback_peak_level(triggered_combos)
	var impact_type := _get_combo_completion_impact_type(triggered_combos)
	var palette := _get_combo_completion_palette(triggered_combos, impact_type)
	var shake := clampi(9 + peak_level * 2, 9, 18)
	_show_battle_impact(battle, "", impact_type, shake)
	_show_combo_completion_strip(battle, triggered_combos, peak_level, palette)
	_show_combo_completion_rings(battle, peak_level, impact_type, palette)

func _show_combo_completion_strip(battle: Control, triggered_combos: Array[Dictionary], peak_level: int, palette: Dictionary) -> void:
	if battle == null:
		return
	var label := battle.get_node_or_null("ComboProgress") as Label
	var panel := battle.get_node_or_null("ComboResourcePanel") as Panel
	if label == null:
		return
	var strip_text := "%s｜%s" % [_get_compact_combo_completion_text(triggered_combos), _get_combo_completion_hint(triggered_combos, peak_level)]
	label.text = _trim_battle_summary_part(strip_text, 34)
	label.modulate = palette.get("title", Color(1.0, 0.92, 0.42, 1.0))
	label.scale = Vector2(1.0, 1.0)
	if panel != null:
		var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style != null:
			style.bg_color = palette.get("bg", Color(0.18, 0.12, 0.06, 0.92))
			style.border_color = palette.get("border", Color(1.0, 0.78, 0.28, 1.0))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(1.08 + peak_level * 0.01, 1.08 + peak_level * 0.01), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if panel != null:
		tween.tween_property(panel, "modulate", Color(1.10, 1.04, 0.86, 1.0), 0.10)
	tween.chain().tween_property(label, "scale", Vector2.ONE, 0.18)
	if panel != null:
		tween.parallel().tween_property(panel, "modulate", Color.WHITE, 0.24)

func _get_combo_completion_hint(triggered_combos: Array[Dictionary], peak_level: int) -> String:
	var process := _get_combo_process_feedback(triggered_combos)
	var prefix := str(process.get("label", "三拍成局"))
	if peak_level > 0:
		prefix = "%s｜强化" % prefix
	match _get_combo_completion_family(triggered_combos):
		"guard":
			return "%s｜守" % prefix
		"control":
			return "%s｜控" % prefix
		"recover":
			return "%s｜稳" % prefix
		"growth":
			return "%s｜滚" % prefix
		_:
			return "%s｜杀" % prefix

func _show_combo_completion_rings(battle: Control, peak_level: int, impact_type: String, palette: Dictionary) -> void:
	if battle == null:
		return
	var ring_count := 2 if peak_level <= 0 else mini(4, 2 + peak_level)
	for i in range(ring_count):
		var size := 164 + i * 44 + peak_level * 18
		var ring := Panel.new()
		ring.name = "ComboCompletionRing%d" % i
		ring.position = Vector2(640 - size * 0.5, 214 - size * 0.5)
		ring.custom_minimum_size = Vector2(size, size)
		ring.size = ring.custom_minimum_size
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.z_index = 87
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0)
		style.border_color = palette.get("ring", Color(1.0, 0.68, 0.18, 0.30))
		style.set_border_width_all(2 + mini(peak_level, 3))
		var radius := int(size * 0.5)
		style.corner_radius_top_left = radius
		style.corner_radius_top_right = radius
		style.corner_radius_bottom_left = radius
		style.corner_radius_bottom_right = radius
		ring.add_theme_stylebox_override("panel", style)
		ring.pivot_offset = ring.size * 0.5
		ring.scale = Vector2(0.56, 0.56)
		battle.add_child(ring)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ring, "scale", Vector2(1.16 + peak_level * 0.06, 1.16 + peak_level * 0.06), 0.54 + i * 0.04).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(ring, "modulate:a", 0.0, 0.36).set_delay(0.18 + i * 0.04)
		tween.chain().tween_callback(func():
			if is_instance_valid(ring):
				ring.queue_free()
		)

func _get_combo_progress_text() -> String:
	"""根据当前出手序列，只提示玩家下一拍真正有关的布局路线。"""
	if combo_sequence.is_empty():
		return "暗势｜未起"
	var combo_db = _get_combo_database()
	if not combo_db:
		return ""
	var states := _get_combo_route_hint_states()
	if states.is_empty():
		return "暗势｜断"

	var finish_parts: Array[String] = []
	var next_map: Dictionary = {}
	for state in states:
		var matched := int(state.get("matched", 0))
		var sequence: Array = state.get("sequence", [])
		if matched <= 0 or matched >= sequence.size():
			continue
		var next_move := int(sequence[matched])
		var combo_name := str(state.get("name", ""))
		if matched == sequence.size() - 1:
			finish_parts.append("%s→%s" % [MoveSymbols.move_name(next_move), combo_name])
		elif matched == 1:
			if not next_map.has(next_move):
				next_map[next_move] = []
			var names: Array = next_map[next_move]
			if names.size() < 2:
				names.append(combo_name)
			next_map[next_move] = names

	if not finish_parts.is_empty():
		return "暗势｜临门｜%s" % " / ".join(finish_parts.slice(0, 2))

	var next_parts: Array[String] = []
	for move in [0, 1, 2]:
		if not next_map.has(move):
			continue
		var names: Array = next_map[move]
		next_parts.append("%s %s" % [MoveSymbols.move_name(move), "、".join(names)])
	if not next_parts.is_empty():
		return "暗势｜%s" % " / ".join(next_parts.slice(0, 2))
	return "暗势｜蓄"

func _get_layout_momentum_text(prefix: String = "") -> String:
	var cleaned_prefix := prefix.strip_edges()
	if combo_sequence.is_empty():
		return "暗势｜未起"
	var states := _get_combo_route_hint_states()
	if states.is_empty():
		return "%s｜暗势断" % cleaned_prefix if cleaned_prefix != "" else "暗势｜断"
	var best_state: Dictionary = states[0]
	for state in states:
		if int(state.get("matched", 0)) > int(best_state.get("matched", 0)):
			best_state = state
	var matched := int(best_state.get("matched", 0))
	var sequence: Array = best_state.get("sequence", [])
	var total := int(sequence.size())
	var combo_name := str(best_state.get("name", "布局"))
	var stage := "临门" if matched >= total - 1 else "%d/%d" % [matched, total]
	var text := "暗势｜%s｜%s" % [combo_name, stage]
	if cleaned_prefix != "":
		text = "%s｜%s" % [cleaned_prefix, text]
	return text

func _set_layout_momentum_text(battle: Control, text: String, mode: String = "normal") -> void:
	if battle == null:
		return
	var panel := battle.get_node_or_null("ComboResourcePanel") as Panel
	var label := battle.get_node_or_null("ComboProgress") as Label
	if label == null:
		panel = battle.get_node_or_null("LayoutMomentumPanel") as Panel
		label = battle.get_node_or_null("LayoutMomentumLabel") as Label
	if label == null:
		return
	label.text = _trim_battle_summary_part(text.strip_edges(), 34)
	var style: StyleBoxFlat = null
	if panel != null:
		style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	match mode:
		"complete":
			label.modulate = Color(1.0, 0.92, 0.40, 1.0)
			if style != null:
				style.bg_color = Color(0.18, 0.12, 0.06, 0.92)
				style.border_color = Color(1.0, 0.78, 0.28, 1.0)
		"pressure":
			label.modulate = Color(1.0, 0.74, 0.46, 1.0)
			if style != null:
				style.bg_color = Color(0.16, 0.09, 0.07, 0.86)
				style.border_color = Color(0.92, 0.46, 0.30, 0.96)
		"advance":
			label.modulate = Color(1.0, 0.86, 0.36, 1.0)
			if style != null:
				style.bg_color = Color(0.13, 0.10, 0.06, 0.84)
				style.border_color = Color(0.94, 0.66, 0.24, 0.96)
		_:
			label.modulate = Color(1.0, 0.86, 0.44, 0.92)
			if style != null:
				style.bg_color = Color(0.10, 0.09, 0.07, 0.76)
				style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0)).lerp(Color(1.0, 0.82, 0.30, 1.0), 0.34)
	label.scale = Vector2(1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.045, 1.045), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.14)

func _update_layout_momentum_display(battle: Control, prefix: String = "", pressure: bool = false) -> void:
	var text := _get_layout_momentum_text(prefix)
	var mode := "pressure" if pressure else "advance" if text.contains("成势") or text.contains("终式") else "normal"
	_set_layout_momentum_text(battle, text, mode)

func _apply_layout_completion_momentum(triggered_combos: Array[Dictionary], battle: Control) -> String:
	if triggered_combos.is_empty():
		return ""
	var max_length := 0
	for entry in triggered_combos:
		max_length = maxi(max_length, int(entry.get("length", 0)))
	var pull := 2 if max_length >= 4 else 1
	if battle != null:
		_shift_duel_momentum(battle, pull, "暗势兑现，反夺一拍")
		_set_layout_momentum_text(battle, "兑现｜明势+%d" % pull, "complete")
	return "【暗势兑现：明势+%d】" % pull

func _get_combo_route_hint_states() -> Array[Dictionary]:
	var combo_db = _get_combo_database()
	if combo_db == null:
		return []
	var allowed_combo_ids := _collect_allowed_combo_ids()
	var best_matched := 0
	var states: Array[Dictionary] = []
	for combo in combo_db.get_all_combos():
		var combo_id := str(combo.id)
		if not combo_id in allowed_combo_ids:
			continue
		if GameState.is_combo_on_cooldown(combo_id):
			continue
		if not _is_combo_hint_condition_ready(combo):
			continue
		var sequence: Array = combo.sequence
		if sequence.size() < 3:
			continue
		var matched := _get_combo_prefix_match_from_history(sequence, combo_sequence)
		if matched <= 0 or matched >= sequence.size():
			continue
		if matched > best_matched:
			best_matched = matched
			states.clear()
		if matched == best_matched:
			states.append({
				"id": combo_id,
				"name": _get_combo_name(combo),
				"sequence": sequence,
				"matched": matched
			})
	return states

func _get_combo_prefix_match_from_history(sequence: Array, history: Array[int]) -> int:
	if sequence.is_empty() or history.is_empty():
		return 0
	var max_len = mini(sequence.size(), history.size())
	for length in range(max_len, 0, -1):
		var start := history.size() - length
		var matched := true
		for i in range(length):
			if int(history[start + i]) != int(sequence[i]):
				matched = false
				break
		if matched:
			return length
	return 0

func _is_combo_hint_condition_ready(combo) -> bool:
	var combo_id := str(combo.id)
	var effect_type := str(combo.effect_type)
	if effect_type == "desperate" or combo_id == "desperate_counter":
		return GameState.can_trigger_desperate()
	if effect_type == "shield_to_damage" or combo_id == "iron_fortress":
		return GameState.can_trigger_iron_fortress()
	if effect_type == "consume_item_damage" or combo_id == "supply_bombard":
		return GameState.can_trigger_supply_bombard()
	return true

func _get_combo_heat_state() -> Dictionary:
	var state := {
		"near_ready_count": 0,
		"ready_count": 0,
		"near_ready_names": PackedStringArray(),
		"ready_names": PackedStringArray()
	}
	var combo_db = _get_combo_database()
	if combo_db == null:
		return state
	var allowed_combo_ids := _collect_allowed_combo_ids()
	var combat_combos = combo_db.get_combat_combos()
	for combo in combat_combos:
		if not combo.id in allowed_combo_ids:
			continue
		var reduction = GameState.get_combo_energy_reduction(combo.id)
		var actual_cost = maxi(combo.energy_cost - reduction, 2)
		if GameState.has_enough_combo_energy(actual_cost):
			state["ready_count"] = int(state["ready_count"]) + 1
			(state["ready_names"] as PackedStringArray).append(ComboDatabase.get_era_combo_name(combo.name))
	for route_state in _get_combo_route_hint_states():
		var seq: Array = route_state.get("sequence", [])
		var matched := int(route_state.get("matched", 0))
		if matched == seq.size() - 1:
			state["near_ready_count"] = int(state["near_ready_count"]) + 1
			(state["near_ready_names"] as PackedStringArray).append(str(route_state.get("name", "")))
	return state

func _apply_combo_resource_heat_state(battle: Control, mode: String = "auto") -> void:
	if battle == null:
		return
	var panel := battle.get_node_or_null("ComboResourcePanel") as Panel
	var progress_label := battle.get_node_or_null("ComboProgress") as Label
	if panel == null or progress_label == null:
		return
	var state := _get_combo_heat_state()
	var near_ready_count := int(state.get("near_ready_count", 0))
	var ready_count := int(state.get("ready_count", 0))
	var resolved_mode := mode
	if resolved_mode == "auto":
		if ready_count > 0:
			resolved_mode = "ready"
		elif near_ready_count > 0:
			resolved_mode = "warming"
		else:
			resolved_mode = "normal"
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	match resolved_mode:
		"pressure":
			style.bg_color = Color(0.18, 0.10, 0.14, 0.98)
			style.border_color = Color(0.96, 0.68, 0.90, 1.0)
			panel.scale = Vector2(1.03, 1.03)
			progress_label.modulate = Color(1.0, 0.82, 0.96, 1.0)
			progress_label.text = "⚠ 二阶段高压：重排节奏"
		"cooldown":
			style.bg_color = Color(0.11, 0.10, 0.12, 0.94)
			style.border_color = Color(0.56, 0.50, 0.42, 0.92)
			panel.scale = Vector2(0.99, 0.99)
			progress_label.modulate = Color(0.88, 0.80, 0.58, 1.0)
		"ready":
			style.bg_color = Color(0.18, 0.14, 0.08, 0.98)
			style.border_color = Color(1.0, 0.84, 0.34, 1.0)
			panel.scale = Vector2(1.02, 1.02)
			progress_label.modulate = Color(1.0, 0.90, 0.28, 1.0)
			if ready_count > 0:
				progress_label.text = "⚡ 可释放：%s" % " / ".join(state["ready_names"])
		"warming":
			style.bg_color = Color(0.14, 0.12, 0.10, 0.96)
			style.border_color = Color(0.92, 0.66, 0.28, 0.96)
			panel.scale = Vector2(1.01, 1.01)
			progress_label.modulate = Color(1.0, 0.84, 0.36, 1.0)
			if near_ready_count > 0:
				progress_label.text = _get_combo_progress_text()
		_:
			style.bg_color = Color(0.10, 0.10, 0.13, 0.92)
			style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0)).lerp(Color.WHITE, 0.75)
			panel.scale = Vector2.ONE
			progress_label.modulate = Color(1.0, 0.86, 0.28)

func _pulse_combo_resource_feedback(battle: Control, mode: String) -> void:
	if battle == null:
		return
	_apply_combo_resource_heat_state(battle, mode)
	var panel := battle.get_node_or_null("ComboResourcePanel") as Panel
	if panel == null:
		return
	var tween := create_tween()
	tween.tween_property(panel, "scale", panel.scale * 1.02, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.12)
	tween.tween_callback(func():
		if is_instance_valid(battle):
			_apply_combo_resource_heat_state(battle, "auto")
	)

func _pulse_boss_pressure_feedback(battle: Control) -> void:
	if battle == null:
		return
	_show_battle_stage_text(battle, "高压：二阶段规则已切换", "phase")
	_pulse_combo_resource_feedback(battle, "pressure")
	var boss_skill := battle.get_node_or_null("BossSkillLabel") as Label
	if boss_skill != null:
		boss_skill.scale = Vector2(1.0, 1.0)
		boss_skill.modulate = Color(1.0, 0.84, 0.96, 1.0)
		var tween := create_tween()
		tween.tween_property(boss_skill, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(boss_skill, "scale", Vector2(1.0, 1.0), 0.14)
		tween.parallel().tween_property(boss_skill, "modulate", Color(0.96, 0.88, 1.0, 1.0), 0.18)

func _get_history_text(history: Array[int]) -> String:
	if history.is_empty():
		return "---"
	var text = ""
	var start = maxi(0, history.size() - 3)
	for i in range(start, history.size()):
		text += MOVE_SYMBOLS[history[i]]
		if i < history.size() - 1:
			text += " "
	return text

func _combo_matches_recent(sequence: Array, move_history: Array[int]) -> bool:
	if sequence.size() < 3 or move_history.size() < sequence.size():
		return false
	var start_idx := move_history.size() - sequence.size()
	for i in range(sequence.size()):
		if int(sequence[i]) != int(move_history[start_idx + i]):
			return false
	return true

func _queue_combo_candidate(candidates: Array[Dictionary], added_ids: Dictionary, combo, is_equipment: bool) -> void:
	var combo_id := _get_combo_id(combo)
	if combo_id == "" or combo_id in added_ids:
		return
	candidates.append({
		"combo": combo,
		"is_equipment": is_equipment,
		"length": combo.sequence.size()
	})
	added_ids[combo_id] = true

func _gather_triggered_combos(move_history: Array[int], allowed_combo_ids: Array[String], combo_db: ComboDatabase) -> Array[Dictionary]:
	var triggered: Array[Dictionary] = []
	var added_ids: Dictionary = {}
	var candidates: Array[Dictionary] = []
	if combo_db == null:
		return triggered

	for combo in combo_db.get_all_combos():
		if not str(combo.id) in allowed_combo_ids:
			continue
		var combo_id = str(combo.id)
		if combo_id in added_ids:
			continue
		if GameState.is_combo_on_cooldown(combo_id):
			continue
		if not _combo_matches_recent(combo.sequence, move_history):
			continue
		var can_trigger = true
		var effect_type := str(combo.effect_type)
		if effect_type == "desperate" and not GameState.can_trigger_desperate():
			can_trigger = false
		elif effect_type == "shield_to_damage" and not GameState.can_trigger_iron_fortress():
			can_trigger = false
		elif effect_type == "consume_item_damage" and not GameState.can_trigger_supply_bombard():
			can_trigger = false
		elif combo_id in ["bloodthirsty_slash", "reflect_aura", "absolute_hit"]:
			can_trigger = false
		elif not combo.is_unlocked and not combo_id in ["desperate_counter", "iron_fortress", "supply_bombard"]:
			can_trigger = false
		if can_trigger:
			_queue_combo_candidate(candidates, added_ids, combo, false)

	var class_names_arr: Array[String] = ["医生", "黑客", "商人", "农民", "流浪者"]
	for cc in ComboData.get_exclusive_combos(class_names_arr[GameState.player_class]):
		var combo_id = str(cc.combo_id)
		if combo_id in added_ids or GameState.is_combo_on_cooldown(combo_id):
			continue
		if _combo_matches_recent(cc.sequence, move_history):
			_queue_combo_candidate(candidates, added_ids, cc, false)

	for item in GameState.equipment_slot:
		if not item.has("exclusive_combo") or item.exclusive_combo == "":
			continue
		var wc = ComboData.get_combo_by_id(item.exclusive_combo)
		if wc == null:
			continue
		var combo_id = str(wc.combo_id)
		if combo_id in added_ids or GameState.is_combo_on_cooldown(combo_id):
			continue
		if _combo_matches_recent(wc.sequence, move_history):
			_queue_combo_candidate(candidates, added_ids, wc, true)

	var longest_match := 0
	for entry in candidates:
		longest_match = maxi(longest_match, int(entry.get("length", 0)))
	for entry in candidates:
		if int(entry.get("length", 0)) == longest_match:
			triggered.append({"combo": entry.get("combo"), "is_equipment": bool(entry.get("is_equipment", false)), "length": int(entry.get("length", 0))})

	return triggered

func _get_combo_repeat_count(combo_id: String) -> int:
	return int(_battle_combo_repeat_counts.get(combo_id, 0))

func _get_adapted_combo_effect_amount(combo_info, effect_type: String) -> int:
	var combo_id := _get_combo_id(combo_info)
	var base_value := GameState.get_combo_effect_amount(combo_id, int(combo_info.effect_value), effect_type)
	var repeat_count := _get_combo_repeat_count(combo_id)
	if repeat_count <= 0:
		return base_value
	var scalable_effects := {
		"damage": true,
		"damage_first": true,
		"damage_pierce": true,
		"damage_all": true,
		"shield_reflect": true,
		"shield_reflect_adv": true,
		"shield_all": true,
		"shield_duration": true,
		"attack_buff": true,
		"heal": true,
		"consume_item_damage": true,
		"pierce_buff": true,
		"heal_shield": true,
		"stun_damage": true,
		"ignore_armor_damage": true,
		"bonus_gold": true,
		"armor_delayed": true,
		"regen": true
	}
	if not scalable_effects.has(effect_type):
		return base_value
	var scale := 0.72 if repeat_count == 1 else 0.50
	return maxi(1, int(ceil(float(base_value) * scale)))

func _register_combo_adaptation(combo_id: String, battle: Control) -> String:
	if combo_id == "":
		return ""
	var repeat_count := int(_battle_combo_repeat_counts.get(combo_id, 0))
	_battle_combo_repeat_counts[combo_id] = repeat_count + 1
	if repeat_count <= 0:
		return ""
	var extra_cooldown := mini(repeat_count, 2)
	if GameState.combo_cooldowns.has(combo_id):
		GameState.combo_cooldowns[combo_id] = int(GameState.combo_cooldowns.get(combo_id, 0)) + extra_cooldown
	if battle != null:
		_show_battle_impact(battle, "识旧势\n冷却+%d" % extra_cooldown, "read", 8)
		_show_momentum_enemy_intent(battle, current_enemy_ai)
		_pulse_combo_resource_feedback(battle, "cooldown")
	return "【敌识旧势：冷却+%d】" % extra_cooldown

func _get_combo_effect_type(combo_info) -> String:
	if combo_info == null:
		return ""
	var value = combo_info.get("effect_type")
	return str(value) if value != null else ""

func _get_combo_tactic_family(combo_info) -> String:
	match _get_combo_effect_type(combo_info):
		"damage", "damage_first", "damage_pierce", "damage_all", "stun_damage", "ignore_armor_damage", "consume_item_damage", "shield_to_damage":
			return "attack"
		"shield_reflect", "shield_reflect_adv", "shield_all", "shield_duration", "armor_delayed", "reflect_3x", "desperate", "invincible":
			return "defense"
		"heal", "heal_shield", "regen", "life_steal_50":
			return "sustain"
		"attack_buff", "pierce_buff", "crit_buff", "crit_boost", "auto_crit", "ignore_armor", "bonus_gold", "enemy_cooldown":
			return "setup"
	return ""

func _get_combo_family_label(family: String) -> String:
	match family:
		"attack":
			return "锋芒"
		"defense":
			return "守势"
		"sustain":
			return "续命"
		"setup":
			return "蓄势"
	return "旧势"

func _get_enemy_tactic_threshold(enemy_ai: EnemyAI) -> int:
	if enemy_ai == null:
		return 3
	match enemy_ai.ai_type:
		EnemyAI.Type.BASIC_FIXED:
			return 3
		EnemyAI.Type.ELITE_CYCLE:
			return 2 if enemy_ai.dynamic_subtype in [2, 4] else 3
		EnemyAI.Type.ADVANCED_DYNAMIC:
			return 2
		EnemyAI.Type.BOSS_PHASE:
			return 2 if enemy_ai.boss_phase >= 2 else 3
	return 3

func _apply_enemy_tactic_pressure(combo_info, battle: Control) -> String:
	var family := _get_combo_tactic_family(combo_info)
	if family == "":
		return ""
	if family == _battle_last_combo_family:
		_battle_combo_family_streak += 1
	else:
		_battle_last_combo_family = family
		_battle_combo_family_streak = 1
	var threshold: int = _get_enemy_tactic_threshold(current_enemy_ai)
	if _battle_combo_family_streak < threshold:
		return ""
	var strength: int = clamp(_battle_combo_family_streak - threshold + 1, 1, 2)
	var family_label: String = _get_combo_family_label(family)
	var result_text := ""
	match family:
		"defense":
			if GameState.player_shield > 0:
				var shield_loss: int = mini(GameState.player_shield, strength)
				GameState.reduce_shield(shield_loss)
				result_text = "【敌读%s：护甲-%d】" % [family_label, shield_loss]
				if battle != null:
					_show_battle_actor_popup(battle, "player", "-%d甲" % shield_loss, Color(0.64, 0.90, 1.0, 1.0), false)
			else:
				result_text = "【敌读%s】" % family_label
		"attack":
			if battle_enemy_hp < battle_enemy_max_hp:
				var heal: int = mini(strength, battle_enemy_max_hp - battle_enemy_hp)
				battle_enemy_hp += heal
				result_text = "【敌卸%s：回稳+%d】" % [family_label, heal]
			else:
				result_text = _apply_combo_cooldown_pressure("敌卸锋芒")
		"sustain":
			var damage_result = GameState.apply_damage(strength, false)
			var shield_absorbed := int(damage_result.get("shield_absorbed", 0))
			var actual_damage := int(damage_result.get("actual_damage", 0))
			if actual_damage > 0:
				result_text = "【敌追%s：命数-%d】" % [family_label, actual_damage]
				if battle != null:
					_show_battle_actor_popup(battle, "player", "-%d" % actual_damage, Color(1.0, 0.34, 0.25, 1.0), false)
			elif shield_absorbed > 0:
				result_text = "【敌追%s：护甲-%d】" % [family_label, shield_absorbed]
				if battle != null:
					_show_battle_actor_popup(battle, "player", "-%d甲" % shield_absorbed, Color(0.64, 0.90, 1.0, 1.0), false)
			else:
				result_text = "【敌追%s】" % family_label
		"setup":
			result_text = _apply_combo_cooldown_pressure("敌断蓄势")
	if result_text != "" and battle != null:
		_show_battle_impact(battle, "读%s" % family_label, "read", 7)
		_show_momentum_enemy_intent(battle, current_enemy_ai)
		_shift_duel_momentum(battle, -1, "%s被读，对面进" % family_label)
	return result_text

func _apply_tactic_rotation_reward(combo_info, battle: Control) -> String:
	var family := _get_combo_tactic_family(combo_info)
	if family == "" or _battle_last_combo_family == "" or family == _battle_last_combo_family:
		return ""
	var threshold: int = _get_enemy_tactic_threshold(current_enemy_ai)
	if _battle_combo_family_streak < maxi(1, threshold - 1):
		return ""
	var old_label := _get_combo_family_label(_battle_last_combo_family)
	var new_label := _get_combo_family_label(family)
	var result_text := ""
	match family:
		"attack":
			if battle_enemy_hp > 0:
				battle_enemy_hp = maxi(battle_enemy_hp - 1, 0)
				result_text = "【换势:%s转%s 主敌-1】" % [old_label, new_label]
				if battle != null:
					_show_battle_impact(battle, "换势\n-1", "read", 7)
					_play_enemy_battle_animation(battle, "hurt")
		"defense":
			var shield_text := _gain_player_shield(1, battle, "换势得甲")
			result_text = "【换势:%s转%s %s】" % [old_label, new_label, shield_text]
		"sustain":
			if GameState.player_hp < GameState.player_max_hp:
				var heal_text := _heal_player_in_battle(1, battle, "换势回命")
				result_text = "【换势:%s转%s %s】" % [old_label, new_label, heal_text]
			else:
				var sustain_shield := _gain_player_shield(1, battle, "换势得甲")
				result_text = "【换势:%s转%s %s】" % [old_label, new_label, sustain_shield]
		"setup":
			GameState.add_cheat_point()
			result_text = "【换势:%s转%s 机括+1】" % [old_label, new_label]
	if result_text != "" and battle != null:
		_show_momentum_trigger(battle, "read")
		_shift_duel_momentum(battle, 1, "%s转%s，换势成功" % [old_label, new_label])
	if result_text != "":
		var ledger_text := _apply_trade_ledger_rotation_bonus(battle)
		if ledger_text != "":
			result_text += ledger_text
	return result_text

func _apply_single_combo_effect(combo_info, is_equipment_combo: bool, battle: Control = null) -> Dictionary:
	var combo_id := _get_combo_id(combo_info)
	var result := {
		"text": "",
		"consumes_sequence": false,
		"id": combo_id,
		"effect_type": ""
	}
	if combo_info == null:
		return result
	var effect_type = str(combo_info.effect_type)
	result["effect_type"] = effect_type
	match effect_type:
		"damage", "damage_first", "damage_pierce", "damage_all":
			var dmg = _get_adapted_combo_effect_amount(combo_info, effect_type)
			if effect_type == "damage_pierce":
				var pierce_result := _damage_support_first(dmg, battle, "穿透")
				result["text"] = "【%s】穿透攻击：%s! " % [_get_combo_name(combo_info), str(pierce_result.get("text", ""))]
			elif effect_type == "damage_all":
				var all_result := _damage_all_enemies(dmg, battle, "全体")
				result["text"] = "【%s】全体攻击：%s! " % [_get_combo_name(combo_info), str(all_result.get("text", ""))]
			else:
				result["text"] = "【%s】造成%d伤害! " % [_get_combo_name(combo_info), dmg]
				_damage_main_enemy(dmg)
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"shield_reflect", "shield_reflect_adv", "shield_all":
			var shield_val = _get_adapted_combo_effect_amount(combo_info, effect_type)
			var shield_text := _gain_player_shield(shield_val, battle, "护甲")
			result["text"] = "【%s】%s! " % [_get_combo_name(combo_info), shield_text] if effect_type == "shield_all" else "【%s】%s，反弹伤害! " % [_get_combo_name(combo_info), shield_text]
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"attack_buff":
			var attack_buff_val = _get_adapted_combo_effect_amount(combo_info, effect_type)
			GameState.apply_combo_buff("attack", attack_buff_val, attack_buff_val)
			result["text"] = "【%s】下%d回合攻击+%d! " % [_get_combo_name(combo_info), attack_buff_val, attack_buff_val]
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"enemy_cooldown":
			_damage_support_first(1, battle, "干扰")
			_support_assist_suppressed_this_turn = true
			_show_support_suppress_feedback(battle)
			result["text"] = "【%s】干扰敌人! " % _get_combo_name(combo_info)
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"shield_duration":
			var sd_val = _get_adapted_combo_effect_amount(combo_info, effect_type)
			var shield_text := _gain_player_shield(sd_val, battle, "护甲")
			GameState.apply_combo_buff("shield_duration", sd_val, sd_val)
			result["text"] = "【%s】%s，持续%d回合! " % [_get_combo_name(combo_info), shield_text, sd_val]
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"heal":
			var heal_val = _get_adapted_combo_effect_amount(combo_info, effect_type)
			var heal_text := _heal_player_in_battle(heal_val, null, "恢复")
			result["text"] = "【%s】%s! " % [_get_combo_name(combo_info), heal_text]
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"crit_buff":
			result["text"] = "【%s】暴击率+50%%! " % _get_combo_name(combo_info)
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"ignore_armor":
			result["text"] = "【%s】无视护甲! " % _get_combo_name(combo_info)
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"life_steal_50":
			result["text"] = "【%s】伤害50%%吸血! " % _get_combo_name(combo_info)
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"reflect_3x":
			var reflect_multiplier := GameState.get_combo_effect_amount(_get_combo_id(combo_info), int(combo_info.effect_value), effect_type)
			result["text"] = "【%s】反弹%d倍伤害! " % [_get_combo_name(combo_info), reflect_multiplier]
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"auto_crit":
			result["text"] = "【%s】必中暴击! " % _get_combo_name(combo_info)
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"desperate":
			if GameState.can_trigger_desperate():
				var desperate_shield := 3
				var critical_hp := maxi(1, int(ceil(float(GameState.player_max_hp) * 0.15)))
				if GameState.player_hp <= critical_hp:
					desperate_shield = 6
					GameState.apply_combo_buff("attack", 1, 1)
					result["text"] = "【%s】命悬一线!伤害×2+%d护甲+1攻击 " % [_get_combo_name(combo_info), desperate_shield]
				else:
					result["text"] = "【%s】绝地反击!伤害×2+%d护甲 " % [_get_combo_name(combo_info), desperate_shield]
				result["text"] += _gain_player_shield(desperate_shield, battle, "护甲")
			else:
				result["text"] = "【%s】条件不满足 " % _get_combo_name(combo_info)
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"shield_to_damage":
			if GameState.can_trigger_iron_fortress():
				var shield_dmg = GameState.player_shield
				var shield_result := _damage_support_first(shield_dmg, battle, "护甲反击")
				result["text"] = "【%s】护甲反击：%s! " % [_get_combo_name(combo_info), str(shield_result.get("text", ""))]
			else:
				result["text"] = "【%s】条件不满足 " % _get_combo_name(combo_info)
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"consume_item_damage":
			if GameState.can_trigger_supply_bombard():
				if GameState.backpack.size() > 0:
					GameState.remove_from_backpack(0)
					var item_dmg = _get_adapted_combo_effect_amount(combo_info, effect_type)
					var gold_pressure = mini(int(GameState.player_gold / 20), 3)
					if gold_pressure > 0:
						item_dmg += gold_pressure
					var item_result := _damage_support_first(item_dmg, battle, "投掷")
					result["text"] = "【%s】消耗物品：%s! " % [_get_combo_name(combo_info), str(item_result.get("text", ""))]
					if gold_pressure > 0:
						result["text"] += "金币加压+%d! " % gold_pressure
				else:
					result["text"] = "【%s】背包为空 " % _get_combo_name(combo_info)
			else:
				result["text"] = "【%s】条件不满足 " % _get_combo_name(combo_info)
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"invincible":
			result["text"] = "【%s】下回合无敌! " % _get_combo_name(combo_info)
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"pierce_buff":
			var pierce_atk = _get_adapted_combo_effect_amount(combo_info, effect_type)
			GameState.apply_combo_buff("attack", pierce_atk, 1)
			var pierce_value = 2 if GameState.has_combo_effect(_get_combo_id(combo_info), "qin_guardbreak") else 1
			GameState.apply_combo_buff("pierce", pierce_value, 1)
			result["text"] = "【%s】攻击+%d，无视%d护甲! " % [_get_combo_name(combo_info), pierce_atk, pierce_value]
			if GameState.has_combo_effect(_get_combo_id(combo_info), "qin_battle_armor"):
				result["text"] += "%s! " % _gain_player_shield(2, battle, "得甲")
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"heal_shield":
			var restore_val = _get_adapted_combo_effect_amount(combo_info, effect_type)
			if GameState.player_hp < GameState.player_max_hp:
				result["text"] = "【%s】%s! " % [_get_combo_name(combo_info), _heal_player_in_battle(restore_val, null, "恢复")]
			else:
				result["text"] = "【%s】满血转%s! " % [_get_combo_name(combo_info), _gain_player_shield(2, battle, "护甲")]
			if GameState.has_combo_effect(_get_combo_id(combo_info), "china_cheat_restore"):
				GameState.add_cheat_point()
				result["text"] += "机括+1! "
			if GameState.has_combo_effect(_get_combo_id(combo_info), "china_attack_rally"):
				GameState.apply_combo_buff("attack", 2, 1)
				result["text"] += "攻击+2! "
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"stun_damage":
			var stun_dmg = _get_adapted_combo_effect_amount(combo_info, effect_type)
			_damage_support_first(stun_dmg, battle, "眩晕")
			GameState.apply_combo_buff("enemy_stun", 1, 2)
			_support_assist_suppressed_this_turn = true
			_show_support_suppress_feedback(battle)
			result["text"] = "【%s】造成%d伤害+眩晕，副阵停手! " % [_get_combo_name(combo_info), stun_dmg]
			if _get_combo_id(combo_info) == "virus_implant":
				result["text"] += "%s! " % _gain_player_shield(1, battle, "护甲")
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"ignore_armor_damage":
			var ia_dmg = _get_adapted_combo_effect_amount(combo_info, effect_type)
			var ia_result := _damage_support_first(ia_dmg, battle, "破阵")
			result["text"] = "【%s】无视护甲：%s! " % [_get_combo_name(combo_info), str(ia_result.get("text", ""))]
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"bonus_gold":
			var gold_val = _get_adapted_combo_effect_amount(combo_info, effect_type)
			if GameState.has_combo_effect(_get_combo_id(combo_info), "song_gold_bonus"):
				gold_val += 4
			GameState.apply_combo_buff("bonus_gold", gold_val, 99)
			result["text"] = "【%s】胜利额外+%d金币! " % [_get_combo_name(combo_info), gold_val]
			if GameState.has_combo_effect(_get_combo_id(combo_info), "song_material_rebate"):
				GameState.apply_combo_buff("bonus_material", 2, 99)
				result["text"] += "战后+6金币! "
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"crit_boost":
			GameState.apply_combo_buff("crit_boost", combo_info.effect_value, 1)
			result["text"] = "【%s】暴击率+%%40! " % _get_combo_name(combo_info)
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"armor_delayed":
			var armor_total = _get_adapted_combo_effect_amount(combo_info, effect_type)
			var armor_now = 5
			var armor_next = armor_total - armor_now
			var shield_text := _gain_player_shield(armor_now, battle, "护甲")
			GameState.apply_combo_buff("shield_delayed", armor_next, 1)
			result["text"] = "【%s】%s，下回合+%d! " % [_get_combo_name(combo_info), shield_text, armor_next]
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		"regen":
			var regen_total = _get_adapted_combo_effect_amount(combo_info, effect_type)
			var regen_tick = maxi(int(round(float(regen_total) / 3.0)), 1)
			GameState.apply_combo_buff("regen", regen_tick, 3)
			result["text"] = "【%s】每回合恢复%d命，持续3回合! " % [_get_combo_name(combo_info), regen_tick]
			GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
			result["consumes_sequence"] = true
		_:
			result["text"] = "【%s】触发! " % _get_combo_name(combo_info)
			if not is_equipment_combo:
				GameState.trigger_combo(_get_combo_id(combo_info), combo_info.cooldown)
				result["consumes_sequence"] = true

	if bool(result["consumes_sequence"]):
		var adaptation_text := _register_combo_adaptation(combo_id, battle)
		if adaptation_text != "":
			result["text"] += adaptation_text

	if combo_id != "":
		if GameState.has_combo_effect(combo_id, "burn"):
			GameState.apply_combo_buff("enemy_burn", 2, 2)
			result["text"] += "【灼烧】"
		if GameState.has_combo_effect(combo_id, "break_momentum"):
			GameState.apply_combo_buff("break_momentum", _battle_round_count, 2)
			result["text"] += "【破势】"
	return result

func _triggered_combo_has_effect(triggered_combos: Array[Dictionary], effect_type: String) -> bool:
	for entry in triggered_combos:
		var combo = entry.get("combo")
		if combo != null and str(combo.effect_type) == effect_type:
			return true
	return false

func _get_reflect_aura_multiplier(triggered_combos: Array[Dictionary]) -> int:
	for entry in triggered_combos:
		var combo = entry.get("combo")
		if combo == null or str(combo.effect_type) != "reflect_3x":
			continue
		return GameState.get_combo_effect_amount(_get_combo_id(combo), int(combo.effect_value), "reflect_3x")
	return 1

func _is_break_momentum_active() -> bool:
	var armed_round := GameState.get_combo_buff("break_momentum")
	return armed_round > 0 and _battle_round_count > armed_round

func _enemy_repeated_last_move() -> bool:
	return _enemy_move_history.size() >= 2 and int(_enemy_move_history[-1]) == int(_enemy_move_history[-2])

func _apply_break_momentum_resolution(result_text: String, result: Dictionary, battle: Control) -> String:
	if not _is_break_momentum_active():
		return result_text
	var parts: Array[String] = []
	if _enemy_repeated_last_move() and battle_enemy_hp > 0:
		var repeat_damage := 2
		battle_enemy_hp = maxi(battle_enemy_hp - repeat_damage, 0)
		result["damage_dealt"] = int(result.get("damage_dealt", 0)) + repeat_damage
		parts.append("抓旧手-%d" % repeat_damage)
		if battle != null:
			_show_battle_impact(battle, "破势\n-%d" % repeat_damage, "read", 9)
			_show_battle_actor_popup(battle, "enemy", "-%d" % repeat_damage, Color(1.0, 0.58, 0.22, 1.0), true)
	if bool(result.get("is_draw", false)):
		var shield_text := _gain_player_shield(2, battle, "破势")
		if shield_text != "":
			parts.append(shield_text)
	if parts.is_empty():
		return result_text
	return "%s 【破势:%s】" % [result_text, " / ".join(parts)]

func _update_history_display(battle: Control) -> void:
	var player_recent: Array[int] = []
	var player_start = maxi(0, _player_move_history.size() - 3)
	for i in range(player_start, _player_move_history.size()):
		player_recent.append(_player_move_history[i])
	while player_recent.size() < 3:
		player_recent.push_front(-1)
	for i in range(3):
		var slot = battle.get_node_or_null("PlayerHistory%d" % i)
		if slot:
			slot.text = MoveSymbols.move_name(player_recent[i]) if player_recent[i] >= 0 else "·"

	var enemy_recent: Array[int] = []
	var enemy_start = maxi(0, _enemy_move_history.size() - 3)
	for i in range(enemy_start, _enemy_move_history.size()):
		enemy_recent.append(_enemy_move_history[i])
	while enemy_recent.size() < 3:
		enemy_recent.push_front(-1)
	for i in range(3):
		var enemy_slot = battle.get_node_or_null("EnemyHistory%d" % i)
		if enemy_slot:
			enemy_slot.text = MoveSymbols.move_name(enemy_recent[i]) if enemy_recent[i] >= 0 else "·"

	var cp = battle.get_node_or_null("ComboProgress")
	if cp:
		var next_text := _get_combo_progress_text()
		if cp.text != next_text and next_text != "":
			cp.text = next_text
			_pulse_combo_progress(cp)
		else:
			cp.text = next_text
	_update_layout_momentum_display(battle)
	_apply_combo_resource_heat_state(battle, "auto")

func _pulse_combo_progress(label: CanvasItem) -> void:
	if label == null:
		return
	label.scale = Vector2(1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.14, 1.14), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.12)

const BATTLE_PHASE_REVEAL_DELAY := 0.22
const BATTLE_PHASE_COMBO_DELAY := 0.34
const BATTLE_PHASE_RESOLVE_DELAY := 0.42
const BATTLE_PHASE_STATUS_DELAY := 0.30
const BATTLE_COMBO_HIT_GAP := 0.22
const BATTLE_COMBO_FOLLOWUP_GAP := 0.16

func _await_battle_phase(duration: float) -> void:
	if duration <= 0.0:
		return
	await get_tree().create_timer(duration).timeout

func _set_battle_turn_lock(battle: Control, locked: bool) -> void:
	if battle == null:
		return
	battle.set_meta("turn_locked", locked)
	if locked:
		_disable_battle_buttons(battle)
	else:
		battle.set_meta("battle_input_move_idx", -1)
		_enable_battle_buttons(battle)

func _is_battle_turn_locked(battle: Control) -> bool:
	if battle == null or not battle.has_meta("turn_locked"):
		return false
	return bool(battle.get_meta("turn_locked"))

func _append_result_text(current_text: String, addition: String) -> String:
	if addition == "":
		return current_text
	if current_text == "":
		return addition
	return "%s\n%s" % [current_text, addition]

func _reset_field_turn_state() -> void:
	_field_shield_blade_triggers = 0
	_field_combo_trigger_count = 0
	_field_camp_followup_done = false
	_poison_relic_triggered_this_turn = false
	_support_assist_suppressed_this_turn = false

func _start_equipment_turn_state(battle: Control) -> String:
	var text := ""
	if _heart_armor_temp_shield > 0:
		_clear_heart_armor_temp_shield()
	if GameState.has_item("heart_armor"):
		var gain := GameState.get_equipment_scaled_int("heart_armor", 2)
		GameState.player_shield += gain
		_heart_armor_temp_shield += gain
		text = "护心甲+%d" % gain
		if battle != null:
			_show_battle_actor_popup(battle, "player", "+%d" % gain, Color(0.50, 0.82, 1.0, 1.0), false)
	return text

func _clear_heart_armor_temp_shield() -> void:
	if _heart_armor_temp_shield <= 0:
		return
	var removed := mini(GameState.player_shield, _heart_armor_temp_shield)
	GameState.player_shield = maxi(GameState.player_shield - removed, 0)
	_heart_armor_temp_shield = 0

func _deal_field_damage(amount: int, battle: Control, label: String) -> String:
	var damage := maxi(amount, 0)
	if damage <= 0 or battle_enemy_hp <= 0:
		return ""
	battle_enemy_hp = maxi(battle_enemy_hp - damage, 0)
	if battle != null:
		_show_battle_impact(battle, "%s\n-%d" % [label, damage], _get_bonus_result_impact_type(label, damage), _get_bonus_result_shake(label, damage))
		_show_battle_actor_popup(battle, "enemy", "-%d" % damage, Color(1.0, 0.62, 0.25, 1.0), true)
		_play_enemy_battle_animation(battle, "hurt")
		_show_momentum_trigger(battle, _get_momentum_trigger_id(label))
	return "【%s-%d】" % [label, damage]

func _get_alive_support_indices() -> Array[int]:
	var result: Array[int] = []
	for i in range(battle_support_enemies.size()):
		if int((battle_support_enemies[i] as Dictionary).get("hp", 0)) > 0:
			result.append(i)
	return result

func _get_support_hp_total() -> int:
	var total := 0
	for raw_support in battle_support_enemies:
		var support := raw_support as Dictionary
		total += maxi(int(support.get("hp", 0)), 0)
	return total

func _get_support_card_base_position(index: int) -> Vector2:
	return Vector2(664 + index * 122, 216)

func _get_support_card_center_position(index: int) -> Vector2:
	return _get_support_card_base_position(index) + Vector2(56, 37)

func _get_enemy_formation_title_text() -> String:
	if battle_support_enemies.is_empty():
		return ""
	return "敌方编队 1v%d" % (1 + battle_support_enemies.size())

func _get_enemy_formation_mode_text() -> String:
	if battle_support_enemies.is_empty():
		return ""
	var alive_count := _get_alive_support_indices().size()
	var support_text := "副阵%d/%d" % [alive_count, battle_support_enemies.size()]
	return "主将 + %s｜协攻 %d" % [support_text, _get_support_assist_damage()]

func _get_support_enemy_count_text() -> String:
	if battle_support_enemies.is_empty():
		return ""
	var alive_count := _get_alive_support_indices().size()
	return "副阵 %d/%d｜协攻 %d" % [alive_count, battle_support_enemies.size(), _get_support_assist_damage()]

func _update_support_enemy_ui(battle: Control) -> void:
	if battle == null:
		return
	var visible := not battle_support_enemies.is_empty()
	var group_label = battle.get_node_or_null("EnemyGroupLabel") as Label
	if group_label:
		group_label.text = _get_enemy_group_status_text()
		group_label.visible = visible
	for node_name in ["EnemyFormationPanel", "EnemyFormationTitle"]:
		var node = battle.get_node_or_null(node_name)
		if node is CanvasItem:
			(node as CanvasItem).visible = visible
	var formation_title = battle.get_node_or_null("EnemyFormationTitle") as Label
	if formation_title:
		formation_title.text = _get_enemy_formation_title_text()
	var formation_mode = battle.get_node_or_null("EnemyFormationMode") as Label
	if formation_mode:
		formation_mode.text = _get_enemy_formation_mode_text()
		formation_mode.visible = visible
	for i in range(2):
		var has_support := i < battle_support_enemies.size()
		var support: Dictionary = battle_support_enemies[i] if has_support else {}
		var hp := int(support.get("hp", 0))
		var max_hp := maxi(int(support.get("max_hp", 0)), 1)
		var alive := has_support and hp > 0
		var base_color := Color(1, 1, 1, 1) if alive else Color(0.54, 0.48, 0.44, 0.62)
		var card = battle.get_node_or_null("SupportCard%d" % i) as Panel
		if card:
			card.visible = has_support
			card.modulate = base_color
			if alive:
				card.scale = Vector2.ONE
		var name_label = battle.get_node_or_null("SupportName%d" % i) as Label
		if name_label:
			name_label.visible = has_support
			name_label.text = str(support.get("name", "副阵")) if alive else "%s退" % str(support.get("name", "副阵"))
			name_label.modulate = Color(1.0, 0.82, 0.58, 0.96) if alive else Color(0.70, 0.62, 0.54, 0.72)
		var hp_bar = battle.get_node_or_null("SupportHPBar%d" % i) as ProgressBar
		if hp_bar:
			hp_bar.visible = has_support
			hp_bar.max_value = max_hp
			hp_bar.value = maxi(hp, 0)
			hp_bar.modulate = Color(0.98, 0.58, 0.46, 1.0) if alive else Color(0.42, 0.38, 0.36, 0.72)
		var hp_label = battle.get_node_or_null("SupportHP%d" % i) as Label
		if hp_label:
			hp_label.visible = has_support
			hp_label.text = "%d/%d" % [maxi(hp, 0), max_hp] if alive else "退场"
		var assist_label = battle.get_node_or_null("SupportAssist%d" % i) as Label
		if assist_label:
			assist_label.visible = has_support
			assist_label.text = "协攻 %d" % int(support.get("assist", 0)) if alive else "已压制"
			assist_label.modulate = Color(1.0, 0.70, 0.44, 0.95) if alive else Color(0.62, 0.56, 0.50, 0.68)

func _show_support_enemy_popup(battle: Control, index: int, value_text: String, color: Color, heavy: bool = false) -> void:
	if battle == null or value_text == "":
		return
	var popup := Label.new()
	popup.text = value_text
	popup.position = _get_support_card_base_position(index) + Vector2(8, -20)
	popup.custom_minimum_size = Vector2(88, 36)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 26 if heavy else 21)
	popup.add_theme_color_override("font_outline_color", Color(0.025, 0.018, 0.012, 1.0))
	popup.add_theme_constant_override("outline_size", 4 if heavy else 3)
	popup.modulate = color
	popup.scale = Vector2(0.70, 0.70)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_index = 94
	battle.add_child(popup)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position", popup.position + Vector2(0, -34), 0.78).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector2(1.10, 1.10) if heavy else Vector2(0.94, 0.94), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 0.30).set_delay(0.56)
	tween.chain().tween_callback(func():
		if is_instance_valid(popup):
			popup.queue_free()
	)

func _play_support_enemy_feedback(battle: Control, index: int, action: String, value: int = 0) -> void:
	if battle == null:
		return
	var card = battle.get_node_or_null("SupportCard%d" % index) as Panel
	if card == null:
		return
	var base_pos := _get_support_card_base_position(index)
	card.position = base_pos
	match action:
		"hurt":
			_show_support_enemy_popup(battle, index, "-%d" % value, Color(1.0, 0.58, 0.32, 1.0), value >= 4)
			card.modulate = Color(1.0, 0.52, 0.38, 1.0)
			var tween := create_tween()
			tween.tween_property(card, "position", base_pos + Vector2(-8, 0), 0.035)
			tween.tween_property(card, "position", base_pos + Vector2(7, 0), 0.035)
			tween.tween_property(card, "position", base_pos, 0.05)
			tween.parallel().tween_property(card, "modulate", Color.WHITE, 0.20)
		"defeat":
			_show_support_enemy_popup(battle, index, "退场", Color(0.95, 0.80, 0.58, 1.0), true)
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(card, "scale", Vector2(0.88, 0.88), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(card, "modulate", Color(0.54, 0.48, 0.44, 0.62), 0.22)
		"assist":
			_show_support_enemy_popup(battle, index, "协攻", Color(1.0, 0.64, 0.34, 1.0), false)
			var tween := create_tween()
			tween.tween_property(card, "position", base_pos + Vector2(-16, 0), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "position", base_pos, 0.13)
		"suppress":
			_show_support_enemy_popup(battle, index, "停手", Color(0.58, 0.82, 1.0, 1.0), false)
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(card, "modulate", Color(0.60, 0.76, 1.0, 0.78), 0.14)
			tween.chain().tween_property(card, "modulate", Color.WHITE, 0.22)

func _show_support_suppress_feedback(battle: Control) -> void:
	if battle == null:
		return
	for idx in _get_alive_support_indices():
		_play_support_enemy_feedback(battle, int(idx), "suppress", 0)

func _has_alive_support_enemies() -> bool:
	return not _get_alive_support_indices().is_empty()

func _damage_main_enemy(amount: int) -> int:
	var damage := maxi(amount, 0)
	if damage <= 0 or battle_enemy_hp <= 0:
		return 0
	var before := battle_enemy_hp
	battle_enemy_hp = maxi(battle_enemy_hp - damage, 0)
	return before - battle_enemy_hp

func _damage_support_enemy(index: int, amount: int) -> int:
	if index < 0 or index >= battle_support_enemies.size():
		return 0
	var damage := maxi(amount, 0)
	if damage <= 0:
		return 0
	var support := battle_support_enemies[index]
	var before := int(support.get("hp", 0))
	if before <= 0:
		return 0
	support["hp"] = maxi(before - damage, 0)
	battle_support_enemies[index] = support
	return before - int(support.get("hp", 0))

func _damage_support_first(amount: int, battle: Control, label: String = "破阵") -> Dictionary:
	var damage := maxi(amount, 0)
	var result := {"main": 0, "support": 0, "text": ""}
	if damage <= 0:
		return result
	var alive := _get_alive_support_indices()
	if not alive.is_empty():
		var target_idx := int(alive[0])
		var dealt := _damage_support_enemy(target_idx, damage)
		result["support"] = dealt
		result["text"] = "%s副阵%d" % [label, dealt]
		if battle != null and dealt > 0:
			_show_battle_impact(battle, "%s\n副阵-%d" % [label, dealt], "support_break", 8)
			var defeated := int((battle_support_enemies[target_idx] as Dictionary).get("hp", 0)) <= 0
			_play_support_enemy_feedback(battle, target_idx, "defeat" if defeated else "hurt", dealt)
			_update_support_enemy_ui(battle)
		return result
	var main_dealt := _damage_main_enemy(damage)
	result["main"] = main_dealt
	result["text"] = "%s主敌%d" % [label, main_dealt]
	return result

func _damage_all_enemies(amount: int, battle: Control, label: String = "全体") -> Dictionary:
	var damage := maxi(amount, 0)
	var result := {"main": 0, "support": 0, "text": ""}
	if damage <= 0:
		return result
	var main_dealt := _damage_main_enemy(damage)
	var support_total := 0
	for i in _get_alive_support_indices():
		var target_idx := int(i)
		var dealt := _damage_support_enemy(target_idx, damage)
		support_total += dealt
		if battle != null and dealt > 0:
			var defeated := int((battle_support_enemies[target_idx] as Dictionary).get("hp", 0)) <= 0
			_play_support_enemy_feedback(battle, target_idx, "defeat" if defeated else "hurt", dealt)
	result["main"] = main_dealt
	result["support"] = support_total
	var parts: Array[String] = []
	if main_dealt > 0:
		parts.append("主敌-%d" % main_dealt)
	if support_total > 0:
		parts.append("副阵合计-%d" % support_total)
	result["text"] = "%s%s" % [label, "｜".join(parts)]
	if battle != null and support_total > 0:
		_show_battle_impact(battle, "%s\n副阵-%d" % [label, support_total], "support_hit", 8)
		_update_support_enemy_ui(battle)
	return result

func _get_enemy_group_status_text() -> String:
	if battle_support_enemies.is_empty():
		return "主敌"
	return _get_support_enemy_count_text()

func _get_support_assist_damage() -> int:
	if _support_assist_suppressed_this_turn or GameState.get_combo_buff("enemy_stun") > 0:
		return 0
	var total := 0
	for idx in _get_alive_support_indices():
		total += int((battle_support_enemies[int(idx)] as Dictionary).get("assist", 0))
	return total

func _apply_support_assist_damage(battle: Control, turn_result: Dictionary = {}) -> String:
	var assist_damage := _get_support_assist_damage()
	if assist_damage <= 0:
		return ""
	var damage_result = GameState.apply_damage(assist_damage, false)
	var shield_absorbed := int(damage_result.get("shield_absorbed", 0))
	var actual_damage := int(damage_result.get("actual_damage", 0))
	if not turn_result.is_empty():
		turn_result["damage_to_shield"] = int(turn_result.get("damage_to_shield", 0)) + shield_absorbed
		turn_result["actual_damage"] = int(turn_result.get("actual_damage", 0)) + actual_damage
	if battle != null:
		for idx in _get_alive_support_indices():
			_play_support_enemy_feedback(battle, int(idx), "assist", int((battle_support_enemies[int(idx)] as Dictionary).get("assist", 0)))
		_show_battle_impact(battle, "副阵协攻\n-%d" % assist_damage, "hurt", 9)
		if actual_damage > 0:
			_show_battle_actor_popup(battle, "player", "-%d" % actual_damage, Color(1.0, 0.34, 0.25, 1.0), false)
		elif shield_absorbed > 0:
			_show_battle_actor_popup(battle, "player", "-%d甲" % shield_absorbed, Color(0.64, 0.90, 1.0, 1.0), false)
	var parts: Array[String] = []
	if shield_absorbed > 0:
		parts.append("护甲-%d" % shield_absorbed)
	if actual_damage > 0:
		parts.append("命数-%d" % actual_damage)
	return "【副阵协攻%s】" % ("｜".join(parts) if not parts.is_empty() else "被抵消")

func _get_bonus_result_impact_type(label: String, amount: int) -> String:
	if amount >= 4:
		return "heavy_hit"
	if amount >= 3:
		return "read" if label in ["盾刃", "反制", "连营"] else "combo"
	return "combo"

func _get_bonus_result_shake(label: String, amount: int) -> int:
	var base := 8
	if amount >= 4:
		base = 14
	elif amount >= 3:
		base = 11
	if label in ["血契", "破财"]:
		base += 2
	return base

func _gain_player_shield(amount: int, battle: Control, source_text: String = "护甲") -> String:
	var gain := maxi(amount, 0)
	if gain <= 0:
		return ""
	var actual_gain := gain
	var overflow_gain := 0
	if GameState.player_class == 3:
		var cap := GameState.get_farmer_shield_soft_cap()
		var room := maxi(cap - GameState.player_shield, 0)
		actual_gain = mini(gain, room)
		overflow_gain = gain - actual_gain
	if actual_gain > 0:
		GameState.player_shield += actual_gain
	var text := "%s+%d" % [source_text, actual_gain] if actual_gain > 0 else "垒势已满"
	if overflow_gain > 0:
		var pressure_damage := maxi(1, int(ceil(float(overflow_gain) * 0.5)))
		var pressure_text := _deal_field_damage(pressure_damage, battle, "垒势")
		text += " 溢甲%d转反压" % overflow_gain
		if pressure_text != "":
			text += " %s" % pressure_text
	if battle != null and source_text.contains("余命"):
		_show_momentum_trigger(battle, "afterlife_lamp")
	elif battle != null and source_text.contains("反制"):
		_show_momentum_trigger(battle, "counter_sigil")
	if actual_gain > 0 and GameState.has_heirloom("shield_blade") and _field_shield_blade_triggers < 3:
		_field_shield_blade_triggers += 1
		var shield_synergy := GameState.get_heirloom_item_synergy_bonus("shield_blade")
		var blade_damage := maxi(1, int(ceil(float(actual_gain) * 0.5))) + shield_synergy
		if shield_synergy > 0 and actual_gain >= 4:
			blade_damage += 1
		var blade_text := _deal_field_damage(blade_damage, battle, "盾刃")
		if blade_text != "":
			text += " %s" % blade_text
	return text

func _gain_heart_armor_combo_shield(battle: Control) -> String:
	if not GameState.has_item("heart_armor"):
		return ""
	var gain := GameState.get_equipment_scaled_int("heart_armor", 1)
	GameState.player_shield += gain
	_heart_armor_temp_shield += gain
	if battle != null:
		_show_battle_actor_popup(battle, "player", "+%d" % gain, Color(0.50, 0.82, 1.0, 1.0), false)
	return "护心甲+%d" % gain

func _heal_player_in_battle(amount: int, battle: Control, source_text: String = "恢复") -> String:
	var heal := maxi(int(round(float(amount) * GameState.get_heal_multiplier())), 0)
	if heal <= 0:
		return ""
	var before_hp := GameState.player_hp
	var overflow := maxi(before_hp + heal - GameState.player_max_hp, 0)
	GameState.player_hp = mini(before_hp + heal, GameState.player_max_hp)
	var actual_heal := GameState.player_hp - before_hp
	var text := "%s+%d" % [source_text, actual_heal]
	if GameState.has_heirloom("afterlife_lamp") and (overflow > 0 or actual_heal == 0):
		var lamp_synergy := GameState.get_heirloom_item_synergy_bonus("afterlife_lamp")
		var overflow_shield := maxi(overflow, 1) + lamp_synergy
		if lamp_synergy > 0 and overflow >= 3:
			overflow_shield += 1
		var shield_text := _gain_player_shield(overflow_shield, battle, "余命护甲")
		if shield_text != "":
			text += " %s" % shield_text
	return text

func _apply_field_combo_trigger(battle: Control) -> String:
	_field_combo_trigger_count += 1
	var text_parts: Array[String] = []
	var armor_text := _gain_heart_armor_combo_shield(battle)
	if armor_text != "":
		text_parts.append(armor_text)
	var poison_text := _apply_poison_relics_on_combo(battle)
	if poison_text != "":
		text_parts.append(poison_text)
	if not GameState.has_heirloom("camp_banner"):
		return " ".join(text_parts)
	if _field_combo_trigger_count < 2 or _field_camp_followup_done:
		return " ".join(text_parts)
	_field_camp_followup_done = true
	var followup := _deal_field_damage(3 + GameState.get_heirloom_item_synergy_bonus("camp_banner"), battle, "连营")
	if followup != "":
		text_parts.append(followup)
	return " ".join(text_parts)

func _apply_field_attack_bonus_to_hit() -> Dictionary:
	return GameState.consume_field_attack_bonus()

func _apply_counter_sigil_on_draw(battle: Control) -> String:
	if not GameState.has_heirloom("counter_sigil"):
		return ""
	var synergy_bonus := GameState.get_heirloom_item_synergy_bonus("counter_sigil")
	var shield_text := _gain_player_shield(1 + synergy_bonus, battle, "反制护甲")
	var damage_text := _deal_field_damage(1 + synergy_bonus, battle, "反制")
	return "%s %s" % [shield_text, damage_text]

func _add_enemy_poison(amount: int, battle: Control, source_text: String = "中毒") -> String:
	var stacks := maxi(amount, 0)
	if stacks <= 0 or battle_enemy_hp <= 0:
		return ""
	_battle_enemy_poison = mini(_battle_enemy_poison + stacks, 99)
	if battle != null:
		_show_battle_actor_popup(battle, "enemy", "毒+%d" % stacks, Color(0.58, 1.0, 0.42, 1.0), true)
	return "%s+%d" % [source_text, stacks]

func _apply_poison_from_enemy_damage(amount: int, battle: Control) -> String:
	if amount <= 0 or not GameState.has_item("poison_coating"):
		return ""
	return _add_enemy_poison(1, battle, "淬毒")

func _apply_poison_from_player_life_loss(amount: int, battle: Control) -> String:
	var parts: Array[String] = []
	if amount <= 0:
		return ""
	if GameState.has_item("poison_coating"):
		var coating := _add_enemy_poison(1, battle, "淬毒")
		if coating != "":
			parts.append(coating)
	if GameState.has_item("flesh_toxin"):
		var toxin := _add_enemy_poison(amount, battle, "血肉毒")
		if toxin != "":
			parts.append(toxin)
	return " ".join(parts)

func _apply_poison_relics_on_combo(battle: Control) -> String:
	if _poison_relic_triggered_this_turn or _battle_enemy_poison <= 0 or battle_enemy_hp <= 0:
		return ""
	var parts: Array[String] = []
	_poison_relic_triggered_this_turn = true
	if GameState.has_item("plague_source"):
		var before := _battle_enemy_poison
		_battle_enemy_poison = mini(_battle_enemy_poison * 2, 99)
		parts.append("瘟疫+%d" % (_battle_enemy_poison - before))
	if GameState.has_item("flesh_talisman"):
		var damage := _battle_enemy_poison
		battle_enemy_hp = maxi(battle_enemy_hp - damage, 0)
		parts.append("血肉符纸-%d" % damage)
		if battle != null:
			_show_battle_actor_popup(battle, "enemy", "-%d" % damage, Color(0.58, 1.0, 0.42, 1.0), true)
	return " ".join(parts)

func _apply_enemy_poison_tick(result_text: String, battle: Control) -> String:
	if _battle_enemy_poison <= 0 or battle_enemy_hp <= 0:
		return result_text
	var damage := _battle_enemy_poison
	battle_enemy_hp = maxi(battle_enemy_hp - damage, 0)
	result_text += " 【中毒-%d】" % damage
	_battle_enemy_poison = maxi(_battle_enemy_poison - 1, 0)
	if battle != null:
		_show_battle_actor_popup(battle, "enemy", "-%d" % damage, Color(0.58, 1.0, 0.42, 1.0), true)
		_show_battle_impact(battle, "中毒\n-%d" % damage, "status", 7)
	return result_text

func _apply_thorn_armor_reflect(shield_loss: int, battle: Control) -> String:
	if shield_loss <= 0 or not GameState.has_thorn_armor() or battle_enemy_hp <= 0:
		return ""
	var damage := maxi(1, int(round(float(shield_loss) * GameState.get_thorn_armor_multiplier())))
	battle_enemy_hp = maxi(battle_enemy_hp - damage, 0)
	if battle != null:
		_show_battle_actor_popup(battle, "enemy", "-%d" % damage, Color(0.94, 0.58, 0.28, 1.0), true)
	return "【反甲%d】" % damage

func _push_battle_summary_line(summary_lines: Array[String], line: String) -> Array[String]:
	var cleaned := str(line).strip_edges()
	if cleaned == "":
		return summary_lines
	if cleaned in summary_lines:
		return summary_lines
	summary_lines.append(cleaned)
	while summary_lines.size() > 3:
		summary_lines.pop_front()
	return summary_lines

func _format_battle_summary_lines(summary_lines: Array[String]) -> String:
	var verdict := ""
	var trigger := ""
	var result := ""
	var causality := ""
	for raw_line in summary_lines:
		var line := _clean_battle_summary_line(raw_line)
		if line == "":
			continue
		if line.begins_with("试探："):
			verdict = line.trim_prefix("试探：")
		elif line.begins_with("判定："):
			verdict = line.trim_prefix("判定：")
		elif line.begins_with("触发："):
			trigger = line.trim_prefix("触发：")
		elif line.begins_with("布局："):
			trigger = line.trim_prefix("布局：")
		elif line.begins_with("结果："):
			result = line.trim_prefix("结果：")
		elif line.begins_with("余效："):
			result = line.trim_prefix("余效：")
		elif line.begins_with("因果："):
			causality = line.trim_prefix("因果：")
		elif verdict == "":
			verdict = line
		elif trigger == "":
			trigger = line
		else:
			result = line
	if verdict == "":
		verdict = "静候"
	var main := _compact_battle_verdict_line(verdict)
	if causality != "":
		return "%s\n%s" % [
			_trim_battle_summary_part(main, 16),
			_trim_battle_summary_part(causality, 30)
		]
	var secondary := _compact_battle_secondary_line(trigger, result)
	if secondary == "":
		return main
	return _trim_battle_summary_part("%s  %s" % [main, secondary], 18)

func _compact_battle_verdict_line(verdict: String) -> String:
	var cleaned := verdict.strip_edges()
	if cleaned == "":
		return "静候"
	var pieces := cleaned.split("｜", false)
	var head := str(pieces[0]).strip_edges()
	var tail: Array[String] = []
	for i in range(1, pieces.size()):
		var piece := str(pieces[i]).strip_edges()
		if piece == "":
			continue
		if piece.contains("-") or piece.contains("+") or piece in ["暴击", "命中", "失手"]:
			tail.append(piece)
	if tail.is_empty():
		return _trim_battle_summary_part(head, 6)
	return _trim_battle_summary_part("%s %s" % [head, _compact_battle_tail(tail)], 12)

func _compact_battle_secondary_line(trigger: String, result: String) -> String:
	for raw_text in [trigger, result]:
		var compact := _compact_battle_detail_piece(str(raw_text))
		if compact != "":
			return compact
	return ""

func _compact_battle_tail(parts: Array[String]) -> String:
	for raw_part in parts:
		var part := str(raw_part).strip_edges()
		if part.contains("-"):
			part = part.replace("受创", "命")
			part = part.replace("碎甲", "甲")
			return part
	for raw_part in parts:
		var part := str(raw_part).strip_edges()
		if part.contains("+"):
			part = part.replace("机括", "机")
			return part
	for raw_part in parts:
		var part := str(raw_part).strip_edges()
		if part != "命中":
			return part
	return str(parts[0]).strip_edges() if not parts.is_empty() else ""

func _compact_battle_detail_piece(text: String) -> String:
	var cleaned := text.strip_edges()
	if cleaned == "":
		return ""
	var pieces := cleaned.split("｜", false)
	for raw_piece in pieces:
		var piece := str(raw_piece).strip_edges()
		if piece == "" or piece.begins_with("局势:"):
			continue
		piece = piece.replace("布局:", "")
		piece = piece.replace("传家宝:", "")
		piece = piece.replace("器物:", "")
		piece = piece.replace("终式:", "终式 ")
		return _trim_battle_summary_part(piece, 6)
	return ""

func _clean_battle_summary_line(line: String) -> String:
	var cleaned := str(line).strip_edges()
	cleaned = cleaned.replace("布局成型\n", "")
	cleaned = cleaned.replace("主动布局\n", "")
	cleaned = cleaned.replace(" / ", "｜")
	cleaned = cleaned.replace("：：", "：")
	cleaned = cleaned.replace("裁决｜", "判定：")
	cleaned = cleaned.replace("得失｜", "触发：")
	cleaned = cleaned.replace("余波｜", "结果：")
	return cleaned

func _extract_first_bracket_payload(text: String, prefix: String) -> String:
	var marker := "【%s" % prefix
	var start := text.find(marker)
	if start < 0:
		return ""
	var end := text.find("】", start)
	if end < 0:
		return ""
	return text.substr(start + 1, end - start - 1)

func _extract_causal_feedback(text: String) -> String:
	var source := str(text)
	var switch_payload := _extract_first_bracket_payload(source, "换势:")
	if switch_payload != "":
		return _format_switch_causal_feedback(switch_payload.trim_prefix("换势:"))
	var repeat_payload := _extract_first_bracket_payload(source, "敌识旧势")
	if repeat_payload != "":
		return "旧势重复 → 被识破 → %s" % _get_payload_result_text(repeat_payload, "冷却受压")
	for spec in [
		{"prefix": "敌读", "cause": "连用", "action": "被读"},
		{"prefix": "敌卸", "cause": "连用", "action": "被卸"},
		{"prefix": "敌追", "cause": "连用", "action": "被追"}
	]:
		var payload := _extract_first_bracket_payload(source, str(spec["prefix"]))
		if payload != "":
			var family := _get_payload_family_text(payload, str(spec["prefix"]))
			var result := _get_payload_result_text(payload, "失去节奏")
			return "%s%s → %s → %s" % [family, str(spec["cause"]), str(spec["action"]), result]
	if source.contains("敌断蓄势"):
		return "蓄势连用 → 被断 → 冷却受压"
	var stack_payload := _extract_first_bracket_payload(source, "垒势-")
	if source.contains("溢甲") and stack_payload != "":
		return "护甲已满 → 溢甲反压 → %s" % stack_payload.replace("垒势", "")
	return ""

func _format_switch_causal_feedback(payload: String) -> String:
	var cleaned := payload.strip_edges()
	var transition := cleaned
	var result := "得势"
	var split_idx := cleaned.find(" ")
	if split_idx >= 0:
		transition = cleaned.left(split_idx).strip_edges()
		result = cleaned.substr(split_idx + 1).strip_edges()
	var old_label := transition
	var new_label := ""
	var turn_idx := transition.find("转")
	if turn_idx >= 0:
		old_label = transition.left(turn_idx)
		new_label = transition.substr(turn_idx + 1)
	if new_label == "":
		return "敌已盯住 → 主动换势 → %s" % result
	return "%s被盯 → 转%s → %s" % [old_label, new_label, result]

func _get_payload_family_text(payload: String, prefix: String) -> String:
	var cleaned := payload.trim_prefix(prefix)
	var colon_idx := cleaned.find("：")
	if colon_idx >= 0:
		return cleaned.left(colon_idx)
	return cleaned

func _get_payload_result_text(payload: String, fallback: String) -> String:
	var colon_idx := payload.find("：")
	if colon_idx >= 0:
		var result := payload.substr(colon_idx + 1).strip_edges()
		return result if result != "" else fallback
	return fallback

func _set_battle_round_summary(battle: Control, summary_lines: Array[String]) -> void:
	if battle == null:
		return
	var result_panel := battle.get_node_or_null("BattleSummaryPanel") as Panel
	var result_title := battle.get_node_or_null("BattleSummaryTitle") as Label
	var result_label := battle.get_node_or_null("ResultLabel") as Label
	if result_label == null:
		return
	if summary_lines.is_empty():
		result_label.text = "静候"
		return
	var source := _get_summary_trigger_source(summary_lines)
	var source_colors := _get_summary_source_colors(source)
	result_label.text = _format_battle_summary_lines(summary_lines)
	result_label.modulate.a = 0.78
	result_label.scale = Vector2(0.995, 0.995)
	if result_panel != null:
		result_panel.modulate.a = 0.84
		var panel_style := result_panel.get_theme_stylebox("panel")
		if panel_style is StyleBoxFlat:
			var flat := panel_style as StyleBoxFlat
			flat.border_color = source_colors.get("border", Color(1, 1, 1, 0.08))
	if result_title != null:
		result_title.modulate = source_colors.get("title", Color(0.82, 0.82, 0.88, 0.88))
		result_title.modulate.a = 0.70
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(result_label, "modulate:a", 0.98, 0.10)
	tween.tween_property(result_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if result_panel != null:
		tween.tween_property(result_panel, "modulate:a", 1.0, 0.12)
	if result_title != null:
		tween.tween_property(result_title, "modulate:a", 0.88, 0.12)

func _show_battle_stage_text(battle: Control, text: String, stage_type: String = "neutral") -> void:
	if battle == null:
		return
	var stage_label := battle.get_node_or_null("BattleStageLabel") as Label
	var stage_panel := battle.get_node_or_null("BattleStagePanel") as Panel
	if stage_label == null or stage_panel == null:
		return
	var theme_color := _get_battle_impact_color(stage_type)
	stage_label.text = text.strip_edges()
	stage_label.modulate = theme_color
	stage_label.visible = stage_label.text != ""
	stage_panel.visible = stage_label.visible
	if not stage_label.visible:
		return
	var hold_time := 0.16
	var fade_out_time := 0.12
	match stage_type:
		"finisher":
			hold_time = 0.34
			fade_out_time = 0.20
		"breakthrough":
			hold_time = 0.28
			fade_out_time = 0.18
		"combo":
			hold_time = 0.24
			fade_out_time = 0.16
		"danger", "break", "crit":
			hold_time = 0.22
			fade_out_time = 0.16
		"phase":
			hold_time = 0.16
			fade_out_time = 0.12
		_:
			hold_time = 0.18
			fade_out_time = 0.14
	stage_label.scale = Vector2(0.94, 0.94)
	stage_label.modulate.a = 0.0
	stage_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(stage_label, "scale", Vector2(1.02, 1.02), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(stage_label, "modulate:a", 1.0, 0.08)
	tween.tween_property(stage_panel, "modulate:a", 1.0, 0.08)
	tween.tween_interval(hold_time)
	tween.tween_property(stage_label, "modulate:a", 0.0, fade_out_time)
	tween.parallel().tween_property(stage_panel, "modulate:a", 0.0, fade_out_time)
	tween.tween_callback(func():
		if is_instance_valid(stage_label):
			stage_label.visible = false
		if is_instance_valid(stage_panel):
			stage_panel.visible = false
	)

func _set_battle_broadcast(battle: Control, text: String) -> void:
	if battle == null:
		return
	var move_info := battle.get_node_or_null("MoveInfo") as Label
	if move_info == null:
		return
	move_info.text = text.strip_edges()
	move_info.scale = Vector2(0.996, 0.996)
	move_info.modulate.a = 0.72
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(move_info, "modulate:a", 0.96, 0.08)
	tween.tween_property(move_info, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(move_info, "modulate:a", 0.88, 0.20)

func _record_battle_history(player_move: int, enemy_move: int, enemy_ai: EnemyAI) -> void:
	combo_sequence.append(player_move)
	enemy_ai.add_player_history(player_move)
	_player_move_history.append(player_move)
	_enemy_move_history.append(enemy_move)
	if _player_move_history.size() > 20:
		_player_move_history.pop_front()
	if _enemy_move_history.size() > 20:
		_enemy_move_history.pop_front()

func _get_enemy_turn_move(player_move: int, enemy_ai: EnemyAI) -> int:
	var predicted_move = -1
	if enemy_ai.ai_type == 3 and enemy_ai.boss_phase == 2:
		predicted_move = player_move
	elif _enemy_pressures_layout_linchpin(enemy_ai):
		predicted_move = _predict_combo_linchpin_move()
	return enemy_ai.get_next_move(battle_enemy_hp, battle_enemy_max_hp, predicted_move)

func _enemy_pressures_layout_linchpin(enemy_ai: EnemyAI) -> bool:
	if enemy_ai == null:
		return false
	if enemy_ai.ai_type == EnemyAI.Type.ELITE_CYCLE and enemy_ai.dynamic_subtype == 4:
		return true
	if enemy_ai.ai_type == EnemyAI.Type.ADVANCED_DYNAMIC and enemy_ai.dynamic_subtype == EnemyAI.DynamicSubtype.SEQUENCE_MIMIC:
		return true
	return false

func _predict_combo_linchpin_move() -> int:
	var state := _get_combo_linchpin_state()
	var moves: Array = state.get("moves", [])
	if moves.size() != 1:
		return -1
	return int(moves[0])

func _get_pre_turn_broadcast(enemy_ai: EnemyAI) -> String:
	var parts: Array[String] = []
	var intent := _get_enemy_intent_hint(enemy_ai)
	if intent != "":
		parts.append(intent)
	var preheat := _get_battle_preheat_hint()
	if preheat != "":
		parts.append(preheat)
	var self_pressure := _get_self_pressure_hint()
	if self_pressure != "":
		parts.append(self_pressure)
	return " ｜ ".join(parts) if not parts.is_empty() else "选择出招，试探对面"

func _get_battle_preheat_hint() -> String:
	if GameState.player_hp <= max(2, int(ceil(float(GameState.player_max_hp) * 0.30))):
		return "命线将断"
	var tactic_hint := _get_enemy_tactic_memory_hint()
	if tactic_hint != "":
		return tactic_hint
	if GameState.has_heirloom("camp_banner") and _field_combo_trigger_count >= 1 and not _field_camp_followup_done:
		return "阵势将续"
	if GameState.player_shield >= 4:
		return "护甲已成势"
	if GameState.has_heirloom("broken_coin") and GameState.field_pending_spend_attack >= 8:
		return "财势待发"
	if GameState.player_class == 2 and GameState.field_pending_merchant_attack >= 3:
		return "商势待发"
	return ""

func _get_boss_danger_preview(enemy_ai: EnemyAI) -> String:
	if not is_current_battle_boss or enemy_ai == null:
		return ""
	if enemy_ai.ai_type != EnemyAI.Type.BOSS_PHASE:
		return ""
	if enemy_ai.boss_phase >= 2:
		var adaptation := _get_boss_adaptation_preview()
		match GameState.selected_era_id:
			"song":
				return "危险预告｜守势延压：下一回合会拆布局；若僵持，灾主回稳%s" % (" ｜ %s" % adaptation if adaptation != "" else "")
			"china":
				return "危险预告｜百代叠律：%s%s" % [_get_next_china_boss_law_preview(), " ｜ %s" % adaptation if adaptation != "" else ""]
			_:
				return "危险预告｜军令压阵：失手追命；每三回合灾主攻击再抬高%s" % (" ｜ %s" % adaptation if adaptation != "" else "")
	var next_move := enemy_ai.boss_cycle[enemy_ai.boss_cycle_index] if enemy_ai.boss_cycle_index < enemy_ai.boss_cycle.size() else 0
	match GameState.selected_era_id:
		"song":
			return "危险预告｜下回合旧势将出%s，先想好是换手还是忍一拍" % MoveSymbols.move_name(next_move)
		"china":
			return "危险预告｜下回合旧势将出%s，别让这一手把命数和节奏一起带走" % MoveSymbols.move_name(next_move)
		_:
			return "危险预告｜下回合旧势将出%s，慢一拍就会被军令压住" % MoveSymbols.move_name(next_move)

func _get_enemy_danger_base_text(enemy_ai: EnemyAI) -> String:
	if enemy_ai == null:
		return "意图未明"
	if enemy_ai.ai_type == EnemyAI.Type.BOSS_PHASE:
		var boss_text := _get_boss_danger_preview(enemy_ai)
		if boss_text != "":
			return boss_text.replace("危险预告｜", "")
	var predicted_move := _peek_predictable_enemy_move(enemy_ai)
	if predicted_move >= 0:
		return "将出%s" % MoveSymbols.move_name(predicted_move)
	var intent_id := _get_momentum_enemy_intent_id(enemy_ai)
	match intent_id:
		"attack":
			return "重手将近"
		"guard":
			return "守住反看"
		"read":
			return "盯你的旧手"
		"trap":
			return "诱你顺势"
		"boss":
			return "旧势推进"
	var intent := _get_enemy_intent_hint(enemy_ai)
	if intent == "":
		return "试探未明"
	return intent

func _get_momentum_pressure_text() -> String:
	if _battle_momentum_score <= -2:
		return "对方得势"
	if _battle_momentum_score < 0:
		return "对方先手"
	if _battle_momentum_score >= 2:
		return "我方压住"
	if _battle_momentum_score > 0:
		return "我方占先"
	return "势均"

func _get_danger_forecast_payload(enemy_ai: EnemyAI) -> Dictionary:
	var tier := 1
	if enemy_ai != null and enemy_ai.ai_type == EnemyAI.Type.BOSS_PHASE:
		tier += 1
	if GameState.player_hp <= max(2, int(ceil(float(GameState.player_max_hp) * 0.30))):
		tier += 1
	if _battle_momentum_score <= -2:
		tier += 2
	elif _battle_momentum_score < 0:
		tier += 1
	elif _battle_momentum_score >= 2:
		tier -= 1
	tier = clampi(tier, 0, 3)
	var tier_names := ["可破", "试探", "压迫", "杀机"]
	var tier_colors := [
		Color(0.56, 0.86, 0.64, 1.0),
		Color(0.92, 0.78, 0.42, 1.0),
		Color(1.0, 0.54, 0.26, 1.0),
		Color(1.0, 0.24, 0.18, 1.0)
	]
	return {
		"tier": tier,
		"title": tier_names[tier],
		"color": tier_colors[tier],
		"body": "%s｜%s" % [_get_enemy_danger_base_text(enemy_ai), _get_momentum_pressure_text()]
	}

func _get_next_china_boss_law_preview() -> String:
	var next_step := (_boss_phase2_turn_count % 3) + 1
	match next_step:
		1:
			return "下一律追命，失手会被旧律补刀"
		2:
			return "下一律压阵，会拖慢一道布局冷却"
		3:
			return "下一律回稳，会回命并点燃终局余烬"
	return "旧律将变"

func _update_boss_warning_label(battle: Control, enemy_ai: EnemyAI) -> void:
	if battle == null:
		return
	var danger_panel := battle.get_node_or_null("DangerForecastPanel") as Panel
	var danger_level_bar := battle.get_node_or_null("DangerForecastLevelBar") as ColorRect
	var boss_danger_label := battle.get_node_or_null("DangerForecastLabel") as Label
	if danger_panel == null or danger_level_bar == null or boss_danger_label == null:
		return
	if _battle_ending or _is_battle_overlay_active(battle):
		danger_panel.visible = false
		danger_level_bar.visible = false
		boss_danger_label.visible = false
		return
	var payload := _get_danger_forecast_payload(enemy_ai)
	var tier := int(payload.get("tier", 0))
	var color: Color = payload.get("color", Color(0.92, 0.78, 0.42, 1.0))
	var body := str(payload.get("body", ""))
	danger_panel.visible = body != ""
	danger_level_bar.visible = body != ""
	boss_danger_label.visible = body != ""
	boss_danger_label.text = "危险·%s\n%s" % [str(payload.get("title", "试探")), body]
	boss_danger_label.modulate = color.lerp(Color.WHITE, 0.18)
	danger_level_bar.color = color
	danger_level_bar.custom_minimum_size = Vector2(54.0 + 54.0 * float(tier + 1), 3)
	var style := danger_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		var updated_style := style.duplicate() as StyleBoxFlat
		updated_style.border_color = color
		updated_style.bg_color = Color(color.r * 0.16, color.g * 0.10, color.b * 0.08, 0.88)
		danger_panel.add_theme_stylebox_override("panel", updated_style)

func _get_enemy_intent_hint(enemy_ai: EnemyAI) -> String:
	if enemy_ai == null:
		return "对面未明"
	if enemy_ai.ai_type == EnemyAI.Type.BOSS_PHASE:
		if enemy_ai.boss_phase >= 2:
			match GameState.selected_era_id:
				"song":
					return "灾主拖慢阵势，逼你在冷却里失误"
				"china":
					return "灾主叠旧律，每一拍压力都不同"
				_:
					return "灾主压速决，拖久会越来越痛"
		return "灾主按旧势推进"
	match enemy_ai.ai_type:
		EnemyAI.Type.BASIC_FIXED:
			return "动作很直，像会守着%s" % MoveSymbols.move_name(enemy_ai.fixed_move)
		EnemyAI.Type.ELITE_CYCLE:
			match enemy_ai.dynamic_subtype:
				0:
					return "两拍一换，节奏很浅"
				1:
					return "会重复同一手，再突然变招"
				2:
					return "对方在等你重复旧手"
				3:
					return "对方不愿重复同一手"
				4:
					if _predict_combo_linchpin_move() >= 0:
						return "对方盯住你的成局手"
					return "对方在等你布局露头"
				_:
					return "有节拍，像在循环换势"
		EnemyAI.Type.ADVANCED_DYNAMIC:
			match enemy_ai.dynamic_subtype:
				EnemyAI.DynamicSubtype.MIND_READER:
					return "对方在读你的常用手"
				EnemyAI.DynamicSubtype.STATE_BASED:
					var hp_percent := float(battle_enemy_hp) / float(maxi(battle_enemy_max_hp, 1))
					if hp_percent > 0.6:
						return "血线厚，两拍压前"
					if hp_percent > 0.3:
						return "开始摇摆，不好判断"
					return "血线低，准备变招反咬"
				EnemyAI.DynamicSubtype.MIMIC:
					return "盯着你上一手反制"
				EnemyAI.DynamicSubtype.RANDOM_SMART:
					return "乱中有节，不会一直重复"
				EnemyAI.DynamicSubtype.SEQUENCE_MIMIC:
					if _predict_combo_linchpin_move() >= 0:
						return "对方正盯你的临门布局"
					return "像在诱你顺着上一手走"
	return "对面未明"

func _get_self_pressure_hint() -> String:
	var hp_ratio := float(GameState.player_hp) / float(maxi(GameState.player_max_hp, 1))
	if hp_ratio <= 0.30:
		return "你已在低命线，贪一手会很重"
	if combo_sequence.size() >= 2:
		return "布局已起，下一手会决定是否兑现"
	if GameState.cheat_points > 0:
		return "机括在手，可以留作关键回合"
	return "先读对面，再决定抢攻或稳住"

func _get_enemy_tactic_memory_hint() -> String:
	if _battle_last_combo_family == "" or _battle_combo_family_streak <= 0:
		return ""
	var threshold := _get_enemy_tactic_threshold(current_enemy_ai)
	if _battle_combo_family_streak < maxi(1, threshold - 1):
		return ""
	return "敌已盯住%s" % _get_combo_family_label(_battle_last_combo_family)

func _get_turn_momentum_hint(player_wins: bool, is_draw: bool, enemy_ai: EnemyAI) -> String:
	if GameState.player_hp <= 0 or battle_enemy_hp <= 0:
		return ""
	var hp_ratio := float(GameState.player_hp) / float(maxi(GameState.player_max_hp, 1))
	if hp_ratio <= 0.30 and GameState.player_shield <= 0:
		return "局势:命线危险，抢攻代价很重"
	if is_current_battle_boss and enemy_ai != null and enemy_ai.ai_type == EnemyAI.Type.BOSS_PHASE:
		if enemy_ai.boss_phase >= 2:
			match GameState.selected_era_id:
				"song":
					return "局势:灾主拖阵，冷却会变成破绽"
				"china":
					return "局势:旧律轮转，下一拍压力会换面"
				_:
					return "局势:军令加压，拖久会更痛"
		return "局势:旧势未尽，二命还在后面"
	if player_wins:
		if enemy_ai != null and enemy_ai.ai_type == EnemyAI.Type.ADVANCED_DYNAMIC:
			return "局势:你抢到先手，对面会换节奏"
		if combo_sequence.size() >= 2:
			return "局势:节奏在手，布局快到兑现点"
		return "局势:主动权回到你手里"
	if is_draw:
		if combo_sequence.size() >= 2:
			return "局势:节奏没断，下一拍很关键"
		return "局势:双方还在藏招"
	if GameState.player_shield > 0:
		return "局势:护甲还在，局面没崩"
	if GameState.cheat_points > 0:
		return "局势:机括还在，关键手仍能改命"
	return "局势:敌拿主动，血线开始被逼"

func _get_player_move_pressure_hint(player_move: int, enemy_ai: EnemyAI) -> String:
	var move_name := MoveSymbols.move_name(player_move)
	var intent := _get_enemy_intent_hint(enemy_ai)
	var move_tone := ""
	match player_move:
		0:
			move_tone = "偏试探，适合不想立刻交底"
		1:
			move_tone = "偏抢先，适合主动压节奏"
		2:
			move_tone = "偏守成，适合保布局和血线"
	var combo_pressure := _get_move_combo_pressure_hint(player_move)
	var read_pressure := _get_move_read_pressure_hint(player_move, enemy_ai)
	var parts: Array[String] = [move_tone]
	if combo_pressure != "":
		parts.append(combo_pressure)
	if read_pressure != "":
		parts.append(read_pressure)
	parts.append("敌%s" % intent)
	return "试探%s：%s" % [move_name, "；".join(parts)]

func _get_move_read_pressure_hint(player_move: int, enemy_ai: EnemyAI) -> String:
	var predicted_enemy := _peek_predictable_enemy_move(enemy_ai)
	if predicted_enemy >= 0:
		if _player_beats_enemy_move(player_move, predicted_enemy):
			return "预感:可压%s" % MoveSymbols.move_name(predicted_enemy)
		if player_move == predicted_enemy:
			return "预感:会对住"
		return "预感:可能被%s压" % MoveSymbols.move_name(predicted_enemy)
	if enemy_ai == null:
		return ""
	if enemy_ai.ai_type == EnemyAI.Type.BOSS_PHASE and enemy_ai.boss_phase >= 2:
		return "预感:灾主会反读"
	if _enemy_pressures_layout_linchpin(enemy_ai) and _predict_combo_linchpin_move() >= 0:
		return "预感:它在抓成局手"
	match enemy_ai.ai_type:
		EnemyAI.Type.ADVANCED_DYNAMIC:
			match enemy_ai.dynamic_subtype:
				EnemyAI.DynamicSubtype.MIND_READER:
					return "预感:旧手越多越危险"
				EnemyAI.DynamicSubtype.MIMIC:
					return "预感:上一手会被盯住"
				EnemyAI.DynamicSubtype.RANDOM_SMART:
					return "预感:难读，别押单手"
				EnemyAI.DynamicSubtype.SEQUENCE_MIMIC:
					return "预感:顺着走可能中套"
		EnemyAI.Type.ELITE_CYCLE:
			if enemy_ai.dynamic_subtype == 3:
				return "预感:不会轻易重复"
	return ""

func _get_move_read_state(player_move: int, enemy_ai: EnemyAI) -> String:
	var predicted_enemy := _peek_predictable_enemy_move(enemy_ai)
	if predicted_enemy >= 0:
		if _player_beats_enemy_move(player_move, predicted_enemy):
			return "advantage"
		if player_move == predicted_enemy:
			return "draw"
		return "risk"
	if enemy_ai == null:
		return ""
	if enemy_ai.ai_type == EnemyAI.Type.BOSS_PHASE and enemy_ai.boss_phase >= 2:
		return "anti_read"
	if enemy_ai.ai_type == EnemyAI.Type.ADVANCED_DYNAMIC:
		return "uncertain"
	if enemy_ai.ai_type == EnemyAI.Type.ELITE_CYCLE and enemy_ai.dynamic_subtype == 3:
		return "uncertain"
	return ""

func _peek_predictable_enemy_move(enemy_ai: EnemyAI) -> int:
	if enemy_ai == null:
		return -1
	match enemy_ai.ai_type:
		EnemyAI.Type.BASIC_FIXED:
			return enemy_ai.fixed_move
		EnemyAI.Type.ELITE_CYCLE:
			if enemy_ai.dynamic_subtype == 2:
				if enemy_ai.player_history.size() >= 2:
					var last := int(enemy_ai.player_history[enemy_ai.player_history.size() - 1])
					var prev := int(enemy_ai.player_history[enemy_ai.player_history.size() - 2])
					if last == prev:
						return (last + 2) % 3
				return 2
			if enemy_ai.dynamic_subtype == 4 and _predict_combo_linchpin_move() >= 0:
				return -1
			if enemy_ai.dynamic_subtype == 3 or enemy_ai.cycle_pattern.is_empty():
				return -1
			return int(enemy_ai.cycle_pattern[enemy_ai.cycle_index])
		EnemyAI.Type.BOSS_PHASE:
			if enemy_ai.boss_phase == 1 and enemy_ai.boss_cycle_index < enemy_ai.boss_cycle.size():
				return int(enemy_ai.boss_cycle[enemy_ai.boss_cycle_index])
	return -1

func _player_beats_enemy_move(player_move: int, enemy_move: int) -> bool:
	return (player_move == 0 and enemy_move == 1) or (player_move == 1 and enemy_move == 2) or (player_move == 2 and enemy_move == 0)

func _get_move_combo_pressure_hint(player_move: int) -> String:
	var projected := combo_sequence.duplicate()
	projected.append(player_move)
	var combo_db = _get_combo_database()
	if combo_db == null:
		return ""
	var allowed_combo_ids := _collect_allowed_combo_ids()
	var best_name := ""
	var best_matched := 0
	var best_size := 0
	for combo in combo_db.get_all_combos():
		if not str(combo.id) in allowed_combo_ids:
			continue
		var seq: Array = combo.sequence
		if seq.size() < 3 or seq.size() > projected.size():
			continue
		var matched := 0
		for i in range(min(projected.size(), seq.size())):
			if projected[projected.size() - 1 - i] == seq[seq.size() - 1 - i]:
				matched += 1
			else:
				break
		if matched > best_matched:
			best_matched = matched
			best_size = seq.size()
			best_name = _get_combo_name(combo)
	if best_matched >= 2 and best_size > 0:
		return "%s %d/%d" % [best_name, best_matched, best_size]
	return ""

func _get_psychological_resolution_line(player_move: int, enemy_move: int, turn_resolution: Dictionary) -> String:
	var player_wins := bool(turn_resolution.get("player_wins", false))
	var is_draw := bool(turn_resolution.get("is_draw", false))
	var low_hp: bool = GameState.player_hp <= max(2, int(ceil(float(GameState.player_max_hp) * 0.30)))
	if is_draw:
		if low_hp:
			return "试探：你在危险线上把这一手硬逼成了平局"
		if combo_sequence.size() >= 2:
			return "试探：双方都没交底，但你把布局节奏保住了"
		return "试探：双方互相试探，这一手谁也没让出破绽"
	if player_wins:
		if low_hp:
			return "试探：你顶着命线抢回了这一手，局面开始倒向你"
		if _enemy_move_history.size() >= 2 and _enemy_move_history[-1] == _enemy_move_history[-2]:
			return "试探：你抓住了敌人的旧手，顺势把它压穿了"
		if _player_move_history.size() >= 2 and _player_move_history[-1] != _player_move_history[-2]:
			return "试探：你临阵换手成功，这一下先机被你抢到"
		return "试探：你读中了这一手，对面这一拍被你吃死了"
	if _player_move_history.size() >= 2 and _player_move_history[-1] == _player_move_history[-2]:
		return "试探：你露了旧手，对面顺着节奏把你反抓了"
	if low_hp:
		return "试探：你这一手没扛住，对面已经开始追你的命线"
	return "试探：你这一拍判断慢了，主动权被对面拿走了"

func _update_read_streak(turn_resolution: Dictionary, psych_text: String) -> int:
	if bool(turn_resolution.get("player_wins", false)) and (psych_text.contains("读中") or psych_text.contains("抓住") or psych_text.contains("压穿") or psych_text.contains("旧手")):
		_battle_read_streak += 1
	else:
		_battle_read_streak = 0
	return _battle_read_streak

func _append_unique_trigger_tag(target: Array[String], tag: String) -> void:
	var cleaned := tag.strip_edges()
	if cleaned == "" or cleaned in target:
		return
	target.append(cleaned)

func _extract_trigger_summary(triggered_combos: Array[Dictionary], text: String) -> String:
	var layout_tags: Array[String] = []
	var heirloom_tags: Array[String] = []
	var item_tags: Array[String] = []
	for entry in triggered_combos:
		var combo = entry.get("combo")
		if combo == null:
			continue
		var combo_name := _get_combo_name(combo)
		if bool(entry.get("is_equipment", false)):
			_append_unique_trigger_tag(item_tags, combo_name)
		else:
			_append_unique_trigger_tag(layout_tags, combo_name)
	var trigger_text := str(text)
	var heirloom_map := {
		"连营": "连营旗",
		"破财+": "破财印",
		"血契+": "血契符",
		"盾刃": "盾刃",
		"余命护甲": "余命灯",
		"反制护甲": "反制令",
		"反制-": "反制令"
	}
	for key in heirloom_map.keys():
		if trigger_text.contains(key):
			_append_unique_trigger_tag(heirloom_tags, str(heirloom_map[key]))
	var item_map := {
		"护心镜": "护心镜",
		"反伤光环": "护心镜",
		"贪婪+50%金币": "贪婪手套",
		"嗜血": "妖刀联动",
		"绝对命中": "精确系统"
	}
	for key in item_map.keys():
		if trigger_text.contains(key):
			_append_unique_trigger_tag(item_tags, str(item_map[key]))
	var parts: Array[String] = []
	if not layout_tags.is_empty():
		parts.append("布局:%s" % "、".join(layout_tags))
	if not heirloom_tags.is_empty():
		parts.append("传家宝:%s" % "、".join(heirloom_tags))
	if not item_tags.is_empty():
		parts.append("器物:%s" % "、".join(item_tags))
	return "｜".join(parts)

func _get_trigger_stage_type(trigger_summary: String) -> String:
	var text := trigger_summary.strip_edges()
	if text.contains("终式:"):
		return "finisher"
	var has_layout := text.contains("布局:")
	var has_heirloom := text.contains("传家宝:")
	var has_item := text.contains("器物:")
	if has_layout:
		return "combo"
	if has_heirloom and not has_item:
		return "heirloom"
	if has_item and not has_heirloom:
		return "item"
	if has_heirloom or has_item:
		return "combo"
	return "combo"

func _get_finisher_summary(triggered_combos: Array[Dictionary]) -> String:
	var finishers: Array[String] = []
	for entry in triggered_combos:
		var combo = entry.get("combo")
		if combo == null:
			continue
		if _is_finisher_combo(combo):
			_append_unique_trigger_tag(finishers, ComboDatabase.get_era_combo_name(_get_combo_name(combo)))
	if finishers.is_empty():
		return ""
	return "终式:%s" % "、".join(finishers)

func _is_finisher_combo(combo) -> bool:
	if combo == null:
		return false
	var combo_id := _get_combo_id(combo)
	if combo_id in ["formation_breaker", "mountain_reversal", "lockstep_snare", "renewal_cycle", "trade_tide", "last_lamp_reversal", "arsenal_unload"]:
		return true
	var sequence = combo.sequence if combo.get("sequence") != null else []
	return sequence.size() >= 4

func _merge_finisher_trigger_summary(finisher_summary: String, trigger_summary: String) -> String:
	if finisher_summary == "":
		return trigger_summary
	var parts: Array[String] = [finisher_summary]
	for raw_part in trigger_summary.split("｜", false):
		var part := str(raw_part).strip_edges()
		if part == "" or part.begins_with("布局:"):
			continue
		parts.append(part)
	return "｜".join(parts)

func _get_build_breakthrough_signal(player_wins: bool, is_draw: bool, status_text: String) -> String:
	var status := status_text.strip_edges()
	var signal_text := ""
	if GameState.player_shield >= 7 or status.contains("盾刃") or status.contains("护甲反击"):
		signal_text = "护甲成势"
	elif GameState.player_hp <= maxi(2, int(ceil(float(GameState.player_max_hp) * 0.25))) and (player_wins or is_draw):
		signal_text = "残灯未灭"
	elif GameState.field_pending_spend_attack >= 6 or GameState.player_gold >= 25 or status.contains("破财") or status.contains("金币"):
		signal_text = "商路兑现"
	elif status.contains("眩晕") or status.contains("冷却") or status.contains("压阵"):
		signal_text = "节奏已夺"
	elif player_wins and GameState.get_total_attack() >= 5:
		signal_text = "杀机已成"
	elif status.contains("恢复") or status.contains("回春") or status.contains("余命"):
		signal_text = "命数回稳"
	return _consume_build_breakthrough_signal(signal_text)

func _consume_build_breakthrough_signal(signal_text: String) -> String:
	var cleaned := signal_text.strip_edges()
	if cleaned == "":
		return ""
	if bool(_battle_build_signals_seen.get(cleaned, false)):
		return ""
	_battle_build_signals_seen[cleaned] = true
	return cleaned

func _build_result_summary_parts(passive_trigger_summary: String, compact_status: String, preheat_hint: String, _build_signal: String, momentum_hint: String = "") -> Array[String]:
	var parts: Array[String] = []
	if passive_trigger_summary != "":
		parts.append(passive_trigger_summary)
	if compact_status != "":
		parts.append(_trim_battle_summary_part(compact_status, 24))
	if preheat_hint != "":
		parts.append(preheat_hint)
	if momentum_hint != "":
		parts.append(_trim_battle_summary_part(momentum_hint, 22))
	return parts

func _trim_battle_summary_part(text: String, max_chars: int) -> String:
	var cleaned := text.strip_edges()
	if cleaned.length() <= max_chars:
		return cleaned
	return "%s..." % cleaned.left(maxi(max_chars - 3, 1))

func _get_summary_trigger_source(summary_lines: Array[String]) -> String:
	for raw_line in summary_lines:
		var line := _clean_battle_summary_line(raw_line)
		if not line.begins_with("触发："):
			continue
		return _get_trigger_stage_type(line.trim_prefix("触发："))
	return "neutral"

func _get_summary_source_colors(source: String) -> Dictionary:
	match source:
		"heirloom":
			return {
				"border": Color(0.54, 0.90, 0.70, 0.86),
				"title": Color(0.80, 0.96, 0.86, 0.92)
			}
		"item":
			return {
				"border": Color(0.64, 0.82, 1.0, 0.86),
				"title": Color(0.84, 0.92, 1.0, 0.92)
			}
		"combo":
			return {
				"border": Color(0.96, 0.78, 0.30, 0.88),
				"title": Color(0.96, 0.88, 0.74, 0.94)
			}
		_:
			return {
				"border": Color(1, 1, 1, 0.08),
				"title": Color(0.82, 0.82, 0.88, 0.88)
			}

func _get_verdict_stage_type(psych_text: String, turn_resolution: Dictionary) -> String:
	var text := psych_text.strip_edges()
	if bool(turn_resolution.get("is_draw", false)):
		if text.contains("危险线") or text.contains("硬逼成了平局"):
			return "clutch"
		return "draw"
	if bool(turn_resolution.get("player_wins", false)):
		if text.contains("顶着命线") or text.contains("抢回了这一手"):
			return "clutch"
		if text.contains("压穿") or text.contains("抓住了敌人的旧手"):
			return "read"
		if text.contains("先机") or text.contains("换手成功"):
			return "read"
		return "hit"
	if text.contains("对面已经开始追你的命线"):
		return "danger"
	if text.contains("反抓了") or text.contains("主动权被对面拿走了"):
		return "danger"
	return "break"

func _get_verdict_prefix(psych_text: String, turn_resolution: Dictionary) -> String:
	match _get_verdict_stage_type(psych_text, turn_resolution):
		"clutch":
			return "险抢"
		"read":
			return "读中"
		"draw":
			return "对住"
		"danger":
			return "失势"
		"break":
			return "被压"
		_:
			return "命中"

func _run_battle_reveal_phase(player_move: int, enemy_move: int, battle: Control) -> void:
	var symbols = MoveSymbols.MOVE_NAMES
	_set_battle_broadcast(battle, "亮招：你出%s，敌出%s" % [symbols[player_move], symbols[enemy_move]])
	_show_battle_stage_text(battle, "亮招：%s 对 %s" % [symbols[player_move], symbols[enemy_move]], "phase")
	_show_momentum_reveal(battle, player_move, enemy_move)
	_update_history_display(battle)

func _run_battle_combo_phase(triggered_combos: Array[Dictionary], battle: Control) -> Dictionary:
	var result_text: String = await _apply_triggered_combo_phase(triggered_combos, battle)
	var summary_line := ""
	var causal_line := ""
	if result_text != "":
		var layout_momentum_text := _apply_layout_completion_momentum(triggered_combos, battle)
		if layout_momentum_text != "":
			result_text += " %s" % layout_momentum_text
		var trigger_summary := _extract_trigger_summary(triggered_combos, result_text)
		var causal_summary := _extract_causal_feedback(result_text)
		var finisher_summary := _get_finisher_summary(triggered_combos)
		if finisher_summary != "":
			trigger_summary = _merge_finisher_trigger_summary(finisher_summary, trigger_summary)
		summary_line = "触发：%s" % (trigger_summary if trigger_summary != "" else "布局起势")
		if causal_summary != "":
			causal_line = "因果：%s" % causal_summary
		_set_battle_broadcast(battle, "终式兑现：%s" % finisher_summary if finisher_summary != "" else summary_line)
		_show_battle_stage_text(
			battle,
			"终式兑现\n%s" % finisher_summary if finisher_summary != "" else "触发分层\n%s" % (trigger_summary if trigger_summary != "" else "布局起势"),
			"finisher" if finisher_summary != "" else _get_trigger_stage_type(trigger_summary)
		)
	_update_battle_ui(battle)
	_update_history_display(battle)
	return {
		"result_text": result_text,
		"summary_line": summary_line,
		"causal_line": causal_line
	}

func _run_battle_resolution_phase(result_text: String, player_move: int, enemy_move: int, triggered_combos: Array[Dictionary], is_crit: bool, force_crit: bool, battle: Control) -> Dictionary:
	var turn_resolution := _resolve_turn_exchange(player_move, enemy_move, triggered_combos, is_crit, force_crit, battle)
	result_text = _append_result_text(result_text, str(turn_resolution.get("text", "")))
	_update_battle_ui(battle)
	_update_history_display(battle)
	_show_momentum_outcome(battle, turn_resolution)
	var layout_prefix := "对住" if bool(turn_resolution.get("is_draw", false)) else "抢一手" if bool(turn_resolution.get("player_wins", false)) else "失一手"
	_update_layout_momentum_display(battle, layout_prefix, not bool(turn_resolution.get("player_wins", false)) and not bool(turn_resolution.get("is_draw", false)))
	var summary_line := ""
	var psych_line := _get_psychological_resolution_line(player_move, enemy_move, turn_resolution)
	var psych_text := psych_line.replace("试探：", "")
	var read_streak := _update_read_streak(turn_resolution, psych_text)
	var verdict_type := _get_verdict_stage_type(psych_text, turn_resolution)
	var verdict_prefix := _get_verdict_prefix(psych_text, turn_resolution)
	if bool(turn_resolution.get("is_draw", false)):
		summary_line = "判定：%s｜机括+1" % verdict_prefix
		_set_battle_broadcast(battle, psych_line)
		_show_battle_stage_text(battle, "%s\n%s" % [verdict_prefix, "势均力敌"], verdict_type)
	elif bool(turn_resolution.get("player_wins", false)):
		var damage_dealt := int(turn_resolution.get("damage_dealt", 0))
		var crit_tag := "暴击" if bool(turn_resolution.get("is_crit", false)) else "命中"
		summary_line = "判定：%s｜%s｜-%d" % [verdict_prefix, crit_tag, damage_dealt]
		_set_battle_broadcast(battle, "%s：%s %d" % [psych_line, crit_tag, damage_dealt])
		_show_battle_stage_text(
			battle,
			"%s\n%s -%d" % ["连读" if read_streak >= 2 else verdict_prefix, crit_tag, damage_dealt],
			"crit" if bool(turn_resolution.get("is_crit", false)) else verdict_type
		)
		if read_streak >= 2:
			_show_battle_impact(battle, "连读\n-%d" % damage_dealt, "read", 10)
	else:
		var actual_damage := int(turn_resolution.get("actual_damage", 0))
		var shield_damage := int(turn_resolution.get("damage_to_shield", 0))
		if actual_damage > 0 and shield_damage > 0:
			summary_line = "判定：%s｜受创-%d｜碎甲-%d" % [verdict_prefix, actual_damage, shield_damage]
		elif actual_damage > 0:
			summary_line = "判定：%s｜受创-%d" % [verdict_prefix, actual_damage]
		elif shield_damage > 0:
			summary_line = "判定：%s｜碎甲-%d" % [verdict_prefix, shield_damage]
		else:
			summary_line = "判定：%s｜失手" % verdict_prefix
		_set_battle_broadcast(battle, summary_line)
		_show_battle_stage_text(
			battle,
			"%s\n%s" % [verdict_prefix, "受压" if actual_damage > 0 else "失机"],
			verdict_type if actual_damage <= 0 else "hurt"
		)
	return {
		"result_text": result_text,
		"is_draw": bool(turn_resolution.get("is_draw", false)),
		"player_wins": bool(turn_resolution.get("player_wins", false)),
		"summary_line": summary_line
	}

func _run_battle_status_phase(result_text: String, player_wins: bool, is_draw: bool, battle: Control, enemy_ai: EnemyAI) -> Dictionary:
	var text_before_status := result_text
	result_text = _apply_end_of_turn_status_phase(result_text, player_wins, is_draw, battle)
	_update_battle_ui(battle)
	_update_history_display(battle)
	var status_text := result_text.replace(text_before_status, "").strip_edges()
	var summary_line := ""
	var compact_status := _compact_battle_status_text(status_text)
	var preheat_hint := _get_battle_preheat_hint()
	var build_signal := _get_build_breakthrough_signal(player_wins, is_draw, status_text)
	var passive_trigger_summary := _extract_trigger_summary([], status_text)
	var causal_summary := _extract_causal_feedback(status_text)
	var momentum_hint := _get_turn_momentum_hint(player_wins, is_draw, enemy_ai)
	var result_parts := _build_result_summary_parts(passive_trigger_summary, compact_status, preheat_hint, build_signal, momentum_hint)
	if not result_parts.is_empty():
		summary_line = "结果：%s" % "｜".join(result_parts)
		_set_battle_broadcast(battle, "回合结果：%s" % "｜".join(result_parts))
		_show_battle_stage_text(
			battle,
			_get_result_stage_text(result_parts, build_signal),
			"breakthrough" if build_signal != "" else "combo"
		)
	return {
		"result_text": result_text,
		"summary_line": summary_line,
		"causal_line": "因果：%s" % causal_summary if causal_summary != "" else ""
	}

func _get_result_stage_text(result_parts: Array[String], build_signal: String = "") -> String:
	var visible_parts: Array[String] = []
	for part in result_parts:
		var cleaned := str(part).strip_edges()
		if cleaned == "" or cleaned.begins_with("局势:"):
			continue
		visible_parts.append(cleaned)
	if visible_parts.is_empty():
		for part in result_parts:
			var cleaned := str(part).strip_edges()
			if cleaned != "":
				visible_parts.append(cleaned)
				break
	var prefix := "回合结果"
	if build_signal != "":
		prefix = "结果加重"
	return "%s\n%s" % [prefix, "｜".join(visible_parts)]

func _finalize_battle_turn_state(battle: Control) -> void:
	GameState.reduce_cooldowns()
	GameState.process_combo_buffs()
	_clamp_boss_phase(battle.get_node_or_null("ResultLabel"))

func _collect_allowed_combo_ids() -> Array[String]:
	var allowed_combo_ids: Array[String] = []
	for cid in GameState.get_equipped_combos():
		if not cid in allowed_combo_ids:
			allowed_combo_ids.append(cid)
	var class_names_local: Array[String] = ["医生", "黑客", "商人", "农民", "流浪者"]
	var excl_combos = ComboData.get_exclusive_combos(class_names_local[GameState.player_class])
	for c in excl_combos:
		if not c.combo_id in allowed_combo_ids:
			allowed_combo_ids.append(c.combo_id)
	for item in GameState.equipment_slot:
		if item.has("exclusive_combo") and item.exclusive_combo != "":
			if not item.exclusive_combo in allowed_combo_ids:
				allowed_combo_ids.append(item.exclusive_combo)
	for status_combo_id in ["desperate_counter", "iron_fortress", "supply_bombard"]:
		if not status_combo_id in allowed_combo_ids:
			allowed_combo_ids.append(status_combo_id)
	return allowed_combo_ids

func _resolve_triggered_combos(allowed_combo_ids: Array[String]) -> Array[Dictionary]:
	var triggered_combos: Array[Dictionary] = []
	var combo_db = _get_combo_database()
	if combo_db == null or combo_sequence.size() < 3:
		return triggered_combos
	var recent_start := maxi(0, combo_sequence.size() - 4)
	var recent_moves := combo_sequence.slice(recent_start)
	DebugLog.log("[Combo] 序列匹配: 最近动作 = ", recent_moves, " 总序列 = ", combo_sequence)
	DebugLog.log("[Combo] 允许的连招ID: ", allowed_combo_ids)
	triggered_combos = _gather_triggered_combos(combo_sequence, allowed_combo_ids, combo_db)
	for entry in triggered_combos:
		var matched_combo = entry.get("combo")
		if matched_combo != null:
			DebugLog.log("[Combo] ✅ 匹配连招: ", _get_combo_name(matched_combo), " (", _get_combo_id(matched_combo), ")")
	return triggered_combos

func _roll_turn_crit(triggered_combos: Array[Dictionary]) -> Dictionary:
	var result := {
		"is_crit": false,
		"force_crit": false
	}
	var crit_boost_val = GameState.get_combo_buff("crit_boost")
	if _triggered_combo_has_effect(triggered_combos, "auto_crit"):
		result["force_crit"] = true
		result["is_crit"] = true
		DebugLog.log("[Battle] 绝对命中：强制暴击")
	elif GameState.get_crit_chance() > 0 or crit_boost_val > 0:
		var total_crit_chance = GameState.get_crit_chance() + crit_boost_val
		result["is_crit"] = randf() < total_crit_chance
	return result

func _show_combo_main_damage_feedback(battle: Control, combo_info, damage: int) -> void:
	if battle == null or damage <= 0:
		return
	var combo_name := _get_combo_name(combo_info)
	var impact_type := "heavy_hit" if damage >= 5 else "hit"
	_play_player_battle_animation(battle, "attack")
	_play_enemy_battle_animation(battle, "hurt")
	_show_battle_impact(battle, "%s\n-%d" % [combo_name, damage], impact_type, 12 if damage >= 5 else 8)

func _show_combo_player_gain_feedback(battle: Control, hp_before: int, shield_before: int) -> bool:
	if battle == null:
		return false
	var showed := false
	if GameState.player_hp > hp_before:
		var heal_delta := GameState.player_hp - hp_before
		_play_player_battle_animation(battle, "heal")
		_show_battle_actor_popup(battle, "player", "+%d" % heal_delta, Color(0.44, 1.0, 0.50, 1.0), false)
		showed = true
	if GameState.player_shield > shield_before:
		var shield_delta := GameState.player_shield - shield_before
		_show_battle_actor_popup(battle, "player", "+%d甲" % shield_delta, Color(0.50, 0.82, 1.0, 1.0), false)
		showed = true
	return showed

func _apply_triggered_combo_phase(triggered_combos: Array[Dictionary], battle: Control) -> String:
	var result_text := ""
	if triggered_combos.is_empty():
		return result_text
	var enemy_hp_before_combo := battle_enemy_hp
	var should_clear_sequence = false
	var combo_impact_text := _get_combo_impact_text(triggered_combos)
	if combo_impact_text != "":
		_show_combo_completion_feedback(battle, triggered_combos)
		await _await_battle_phase(BATTLE_COMBO_FOLLOWUP_GAP)
	for entry in triggered_combos:
		var combo_info = entry.get("combo")
		var enemy_hp_before_step := battle_enemy_hp
		var player_hp_before_step := GameState.player_hp
		var player_shield_before_step := GameState.player_shield
		var support_hp_before_step := _get_support_hp_total()
		var combo_result = _apply_single_combo_effect(combo_info, bool(entry.get("is_equipment", false)), battle)
		result_text += str(combo_result.get("text", ""))
		var support_delta := support_hp_before_step - _get_support_hp_total()
		var main_delta := enemy_hp_before_step - battle_enemy_hp
		var step_visible := support_delta > 0 or main_delta > 0
		if support_delta > 0 and main_delta > 0:
			_update_battle_ui(battle)
			await _await_battle_phase(BATTLE_COMBO_HIT_GAP)
		if main_delta > 0:
			_show_combo_main_damage_feedback(battle, combo_info, main_delta)
		if _show_combo_player_gain_feedback(battle, player_hp_before_step, player_shield_before_step):
			step_visible = true
		if step_visible:
			_update_battle_ui(battle)
			_update_history_display(battle)
			await _await_battle_phase(BATTLE_COMBO_HIT_GAP)
		var field_enemy_hp_before := battle_enemy_hp
		var field_player_hp_before := GameState.player_hp
		var field_player_shield_before := GameState.player_shield
		var field_support_hp_before := _get_support_hp_total()
		var field_followup := _apply_field_combo_trigger(battle)
		if field_followup != "":
			result_text += field_followup
		var rotation_reward := ""
		var tactic_pressure := ""
		if bool(combo_result.get("consumes_sequence", false)):
			rotation_reward = _apply_tactic_rotation_reward(combo_info, battle)
			if rotation_reward != "":
				result_text += " %s" % rotation_reward
			tactic_pressure = _apply_enemy_tactic_pressure(combo_info, battle)
			if tactic_pressure != "":
				result_text += " %s" % tactic_pressure
		var field_visible := (
			field_followup != ""
			or rotation_reward != ""
			or tactic_pressure != ""
			or field_enemy_hp_before != battle_enemy_hp
			or field_player_hp_before != GameState.player_hp
			or field_player_shield_before != GameState.player_shield
			or field_support_hp_before != _get_support_hp_total()
		)
		if field_visible:
			_update_battle_ui(battle)
			_update_history_display(battle)
			await _await_battle_phase(BATTLE_COMBO_HIT_GAP)
		if bool(combo_result.get("consumes_sequence", false)):
			should_clear_sequence = true
	if should_clear_sequence:
		combo_sequence.clear()
	if battle_enemy_hp < enemy_hp_before_combo:
		var combo_damage_delta := enemy_hp_before_combo - battle_enemy_hp
		var poison_text := _apply_poison_from_enemy_damage(combo_damage_delta, battle)
		if poison_text != "":
			result_text += " 【%s】" % poison_text
			_update_battle_ui(battle)
			await _await_battle_phase(BATTLE_COMBO_FOLLOWUP_GAP)
	return result_text.strip_edges()

func _resolve_turn_exchange(player_move: int, enemy_move: int, triggered_combos: Array[Dictionary], is_crit: bool, force_crit: bool, battle: Control) -> Dictionary:
	var result := {
		"text": "",
		"is_draw": false,
		"player_wins": false,
		"is_crit": false,
		"damage_dealt": 0,
		"actual_damage": 0,
		"damage_to_shield": 0
	}
	var total_attack = GameState.get_total_attack()
	var combo_buff_attack = GameState.get_combo_buff("attack")
	if combo_buff_attack > 0:
		total_attack += combo_buff_attack
		DebugLog.log("[Battle] Attack buff active: +", combo_buff_attack)
	result["is_draw"] = player_move == enemy_move
	if not bool(result["is_draw"]):
		result["player_wins"] = (player_move == 0 and enemy_move == 1) or \
				(player_move == 1 and enemy_move == 2) or \
				(player_move == 2 and enemy_move == 0)
	var result_text := ""
	if bool(result["is_draw"]):
		result_text += "🤝 平局!"
		_show_battle_impact(battle, "势均力敌", "draw", 4)
		GameState.add_cheat_point()
		if GameState.arm_draw_protection():
			result_text += " 【平局保护已就绪】"
		var counter_text := _apply_counter_sigil_on_draw(battle)
		if counter_text.strip_edges() != "":
			result_text += " 【%s】" % counter_text.strip_edges()
	elif bool(result["player_wins"]):
		var base_damage = total_attack
		if _triggered_combo_has_effect(triggered_combos, "desperate"):
			base_damage = base_damage * 2
			DebugLog.log("[Battle] 绝地反击：伤害×2 = ", base_damage)
		var damage_dealt := 0
		if is_crit or force_crit:
			base_damage = int(base_damage * 1.5)
			damage_dealt = base_damage
			result["is_crit"] = true
			result_text += "✅ 暴击!"
			_show_battle_impact(battle, "暴击\n-%d" % damage_dealt, "crit", 12)
		else:
			damage_dealt = base_damage
			result_text += "✅ 命中!"
			_show_battle_impact(battle, "命中\n-%d" % damage_dealt, "hit", 7)
		var field_attack_bonus := _apply_field_attack_bonus_to_hit()
		var field_bonus_total := int(field_attack_bonus.get("total", 0))
		if field_bonus_total > 0:
			damage_dealt += field_bonus_total
			base_damage += field_bonus_total
			var field_parts: Array[String] = []
			if int(field_attack_bonus.get("spend", 0)) > 0:
				field_parts.append("破财+%d" % int(field_attack_bonus.get("spend", 0)))
			if int(field_attack_bonus.get("blood", 0)) > 0:
				field_parts.append("血契+%d" % int(field_attack_bonus.get("blood", 0)))
			if int(field_attack_bonus.get("merchant", 0)) > 0:
				field_parts.append("商势+%d" % int(field_attack_bonus.get("merchant", 0)))
			result_text += " 【%s】" % " / ".join(field_parts)
			var dominant_bonus_label := "商势" if int(field_attack_bonus.get("merchant", 0)) >= maxi(int(field_attack_bonus.get("spend", 0)), int(field_attack_bonus.get("blood", 0))) else "破财" if int(field_attack_bonus.get("spend", 0)) >= int(field_attack_bonus.get("blood", 0)) else "血契"
			_show_battle_impact(
				battle,
				"%s\n+%d" % ["蓄势" if field_bonus_total < 4 else "重势", field_bonus_total],
				_get_bonus_result_impact_type(dominant_bonus_label, field_bonus_total),
				_get_bonus_result_shake(dominant_bonus_label, field_bonus_total)
			)
			if bool(field_attack_bonus.get("blood_break", false)):
				result_text += " (%s)" % _heal_player_in_battle(1, battle, "偷取")
			if int(field_attack_bonus.get("blood", 0)) > 0:
				_show_momentum_trigger(battle, "blood_contract")
			elif int(field_attack_bonus.get("spend", 0)) > 0:
				_show_momentum_trigger(battle, "broken_coin")
		var tiger_damage := _get_tiger_tally_pressure_damage()
		if tiger_damage > 0:
			damage_dealt += tiger_damage
			base_damage += tiger_damage
			result_text += " 【虎符压阵-%d】" % tiger_damage
			_show_battle_impact(battle, "虎符压阵\n-%d" % tiger_damage, "heavy_hit", 9)
			_shift_duel_momentum(battle, 1, "虎符压阵，势向我")
		result["damage_dealt"] = damage_dealt
		battle_enemy_hp = maxi(battle_enemy_hp - damage_dealt, 0)
		var poison_text := _apply_poison_from_enemy_damage(damage_dealt, battle)
		if poison_text != "":
			result_text += " 【%s】" % poison_text
		_play_player_battle_animation(battle, "attack")
		_clamp_boss_phase(battle.get_node_or_null("ResultLabel") if battle != null else null)
		_play_enemy_battle_animation(battle, "hurt")
		if _triggered_combo_has_effect(triggered_combos, "life_steal_50"):
			var blood_heal = int(damage_dealt * 0.5)
			result_text += " (%s)" % _heal_player_in_battle(blood_heal, battle, "嗜血")
			if blood_heal > 0:
				_play_player_battle_animation(battle, "heal")
				_show_battle_actor_popup(battle, "player", "+%d" % blood_heal, Color(0.44, 1.0, 0.50, 1.0), false)
		var life_steal = GameState.get_life_steal(damage_dealt)
		if life_steal > 0:
			result_text += " (%s)" % _heal_player_in_battle(life_steal, battle, "偷取")
			_play_player_battle_animation(battle, "heal")
			_show_battle_actor_popup(battle, "player", "+%d" % life_steal, Color(0.44, 1.0, 0.50, 1.0), false)
	else:
		var stun_val = GameState.get_combo_buff("enemy_stun")
		if stun_val > 0:
			result_text += "💫 敌人眩晕跳过! "
		else:
			result_text += "❌ 失误!"
			var damage = battle_enemy_atk
			var slow_val = GameState.get_combo_buff("enemy_slow")
			if slow_val > 0:
				damage = maxi(damage - slow_val, 1)
				result_text += " 【减速-%d攻】" % slow_val
			var damage_taken_mult = GameState.get_damage_taken_multiplier()
			if damage_taken_mult > 1.0:
				damage = int(damage * damage_taken_mult)
				result_text += " 【贪婪+50%伤】"
			if GameState.consume_draw_protection():
				result_text += " 【平局保护免疫%d伤害】" % damage
				damage = 0
			var damage_result = GameState.apply_damage(damage, false)
			var damage_to_shield = damage_result.shield_absorbed
			var actual_damage = damage_result.actual_damage
			result["damage_to_shield"] = damage_to_shield
			result["actual_damage"] = actual_damage
			if actual_damage > 0:
				var blood_bonus := GameState.grant_blood_contract_bonus(actual_damage)
				if blood_bonus > 0:
					result_text += " 【血契+%d】" % blood_bonus
				var poison_text := _apply_poison_from_player_life_loss(actual_damage, battle)
				if poison_text != "":
					result_text += " 【%s】" % poison_text
			if actual_damage > 0:
				_play_enemy_battle_animation(battle, "attack")
				_play_player_battle_animation(battle, "death" if GameState.player_hp <= 0 else "hurt", GameState.player_hp <= 0)
			if damage_to_shield > 0 and GameState.has_shield_reflect():
				var reflect_amount = int(round(float(damage_to_shield) * GameState.get_shield_reflect_multiplier()))
				var aura_multiplier := _get_reflect_aura_multiplier(triggered_combos)
				if aura_multiplier > 1:
					reflect_amount *= aura_multiplier
					result_text += " 【反伤光环×%d:%d】" % [aura_multiplier, reflect_amount]
				else:
					result_text += " 【护心镜反弹%d】" % reflect_amount
				battle_enemy_hp = maxi(battle_enemy_hp - reflect_amount, 0)
			if damage_to_shield > 0:
				var thorn_text := _apply_thorn_armor_reflect(damage_to_shield, battle)
				if thorn_text != "":
					result_text += " %s" % thorn_text
			if damage_to_shield > 0:
				if damage_result.shield_broken:
					result_text += " (碎甲%d!)" % damage_to_shield
				else:
					result_text += " (护甲-%d)" % damage_to_shield
			if actual_damage > 0:
				result_text += " 命数-%d" % actual_damage
				_show_battle_impact(battle, "受创\n-%d" % actual_damage, "hurt", 10)
			elif damage_to_shield > 0:
				_show_battle_impact(battle, "碎甲\n-%d" % damage_to_shield, "break", 8)
			var support_assist_text := _apply_support_assist_damage(battle, result)
			if support_assist_text != "":
				result_text += " %s" % support_assist_text
	result_text = _apply_break_momentum_resolution(result_text, result, battle)
	result["text"] = result_text.strip_edges()
	return result

func _apply_end_of_turn_status_phase(result_text: String, player_wins: bool, is_draw: bool, battle: Control) -> String:
	result_text = _apply_era_boss_turn_pressure(player_wins, is_draw, result_text)
	result_text = _apply_era_enemy_turn_pressure(player_wins, is_draw, result_text)
	var burn_val = GameState.get_combo_buff("enemy_burn")
	if burn_val > 0 and battle_enemy_hp > 0:
		battle_enemy_hp = maxi(battle_enemy_hp - burn_val, 0)
		result_text += " 🔥灼烧-%d" % burn_val
	result_text = _apply_enemy_poison_tick(result_text, battle)
	if _era_enemy_china_burn_active and GameState.player_hp > 0 and not _battle_ending:
		var enemy_burn_result = GameState.apply_damage(1, false)
		if int(enemy_burn_result.get("actual_damage", 0)) > 0:
			result_text += " 【残烬-1命】"
		elif int(enemy_burn_result.get("shield_absorbed", 0)) > 0:
			result_text += " 【残烬灼盾1】"
		_era_enemy_china_burn_active = false
	if _era_boss_china_burn_active and GameState.player_hp > 0 and not _battle_ending:
		var china_burn_result = GameState.apply_damage(1, false)
		if int(china_burn_result.get("actual_damage", 0)) > 0:
			result_text += " 【终局余烬-1命】"
		elif int(china_burn_result.get("shield_absorbed", 0)) > 0:
			result_text += " 【终局余烬灼盾1】"
	var regen_val = GameState.get_combo_buff("regen")
	if regen_val > 0:
		result_text += " 【%s】" % _heal_player_in_battle(regen_val, battle, "回春")
		_play_player_battle_animation(battle, "heal")
		_show_battle_actor_popup(battle, "player", "+%d" % regen_val, Color(0.44, 1.0, 0.50, 1.0), false)
	var delayed_shield = GameState.get_combo_buff("shield_delayed")
	if delayed_shield > 0:
		result_text += " 【%s】" % _gain_player_shield(delayed_shield, battle, "迟甲")
	return result_text

func _resolve_battle_outcome(battle: Control, result_text: String) -> bool:
	if battle_enemy_hp <= 0:
		_battle_ending = true
		_set_duel_momentum_rail_visible(battle, false)
		_set_battle_broadcast(battle, "敌阵已溃，战局拿下")
		battle.get_node("ResultLabel").text = _append_result_text(battle.get_node("ResultLabel").text, "🎉 战斗胜利!")
		_show_battle_impact(battle, "击溃", "victory", 16)
		_play_enemy_battle_animation(battle, "death", true)
		var settlement_before := _capture_battle_settlement_state()
		var gold_reward = GameState.get_battle_gold_reward()
		if GameState.has_greedy_gloves():
			gold_reward = int(gold_reward * GameState.get_gold_reward_multiplier())
			result_text += " 【贪婪+50%金币】"
		var bonus_gold = GameState.get_combo_buff("bonus_gold")
		if bonus_gold > 0:
			gold_reward += bonus_gold
		GameState.player_gold += gold_reward
		var hp_before_victory = GameState.player_hp
		GameState.on_battle_won()
		_append_era_item_victory_text(battle.get_node("ResultLabel"), hp_before_victory)
		_apply_difficult_battle_victory_growth(battle.get_node("ResultLabel"))
		var material_drop = 1
		if is_current_battle_boss:
			material_drop = 3
		elif GameState.current_floor >= 5:
			material_drop = 2
		var reward_extra_parts: Array[String] = []
		var bonus_material = GameState.get_combo_buff("bonus_material")
		if bonus_material > 0:
			material_drop += bonus_material
			result_text += " 【商路回金+%d】" % (bonus_material * 3)
		if GameState.selected_era_id == "qin" and GameState.selected_route_name == "近攻线" and not is_current_battle_boss:
			var spoils_gold := 4 + GameState.get_major_layer_index(GameState.current_floor) * 2
			gold_reward += spoils_gold
			material_drop += 1
			result_text += " 【近攻缴获+%d金】" % spoils_gold
			reward_extra_parts.append("材料+3")
		if GameState.selected_era_id == "qin" and _get_battle_reward_type() == "elite":
			material_drop += 1
			result_text += " 【军阵缴获+3金】"
		elif GameState.selected_era_id == "china" and current_enemy_data != null and current_enemy_data.ai_type >= 2:
			GameState.add_cheat_point()
			result_text += " 【终局回响+1机括】"
			reward_extra_parts.append("机括+1")
		gold_reward += material_drop * 3
		GameState.player_gold += material_drop * 3
		_append_battle_reward_summary(battle.get_node("ResultLabel"), gold_reward, 0, reward_extra_parts)
		_clear_heart_armor_temp_shield()
		GameState.unequip_all_after_battle()
		var reward_info := await _handle_battle_victory_rewards(battle)
		var settlement_after := _capture_battle_settlement_state()
		await _show_battle_settlement_detail(battle, settlement_before, settlement_after, reward_info)
		_advance_floor()
		return true
	if GameState.player_hp <= 0:
		if GameState.try_resurrection():
			_set_battle_broadcast(battle, "命线未断，强行复起")
			battle.get_node("ResultLabel").text = _append_result_text(battle.get_node("ResultLabel").text, "✨ 医生复起！恢复%d命" % GameState.resurrection_hp)
			_update_battle_ui(battle)
			return false
		_battle_ending = true
		_set_duel_momentum_rail_visible(battle, false)
		_set_battle_broadcast(battle, "命线崩解，此局失守")
		battle.get_node("ResultLabel").text = _append_result_text(battle.get_node("ResultLabel").text, "💀 战斗失败!")
		_show_battle_impact(battle, "势尽", "defeat", 18)
		_play_player_battle_animation(battle, "death", true)
		var defeat_timer = get_tree().create_timer(1.5)
		defeat_timer.timeout.connect(func(): _show_game_over(false))
		return true
	return false

func _process_battle_turn(player_move: int, battle: Control, enemy_ai: EnemyAI, forced_enemy_move: int = -1, opener_summary: String = "", force_crit_override: bool = false):
	# 检查战斗结束锁，防止多次触发
	if _battle_ending:
		DebugLog.log("Battle already ending, ignoring input")
		return
	if _is_battle_turn_locked(battle):
		DebugLog.log("Battle turn already in progress, ignoring input")
		return
	battle.set_meta("battle_input_move_idx", player_move)
	_set_battle_turn_lock(battle, true)
	_apply_battle_move_input_feedback(battle, player_move)
	await get_tree().process_frame

	DebugLog.log("Battle turn - Player: ", player_move)
	_battle_round_count += 1
	_reset_field_turn_state()
	var equipment_start_text := _start_equipment_turn_state(battle)

	var enemy_move := forced_enemy_move if forced_enemy_move >= 0 else _get_enemy_turn_move(player_move, enemy_ai)
	_record_battle_history(player_move, enemy_move, enemy_ai)

	var allowed_combo_ids := _collect_allowed_combo_ids()
	var triggered_combos := _resolve_triggered_combos(allowed_combo_ids)
	var crit_result := _roll_turn_crit(triggered_combos)
	var is_crit := bool(crit_result.get("is_crit", false))
	var force_crit := bool(crit_result.get("force_crit", false)) or force_crit_override
	var summary_lines: Array[String] = []
	var era_item_start_text = _get_era_item_battle_start_summary(0, 0)
	if era_item_start_text != "":
		summary_lines = _push_battle_summary_line(summary_lines, "结果：%s" % era_item_start_text)
	if equipment_start_text != "":
		summary_lines = _push_battle_summary_line(summary_lines, "触发：%s" % equipment_start_text)
	if opener_summary != "":
		summary_lines = _push_battle_summary_line(summary_lines, "触发：%s" % opener_summary)
	_set_battle_round_summary(battle, summary_lines)

	_run_battle_reveal_phase(player_move, enemy_move, battle)
	await _await_battle_phase(BATTLE_PHASE_REVEAL_DELAY)

	var combo_phase := await _run_battle_combo_phase(triggered_combos, battle)
	var result_text := str(combo_phase.get("result_text", ""))
	summary_lines = _push_battle_summary_line(summary_lines, str(combo_phase.get("summary_line", "")))
	summary_lines = _push_battle_summary_line(summary_lines, str(combo_phase.get("causal_line", "")))
	_set_battle_round_summary(battle, summary_lines)
	if result_text != "":
		await _await_battle_phase(BATTLE_PHASE_COMBO_DELAY)
	var resolution_phase := _run_battle_resolution_phase(result_text, player_move, enemy_move, triggered_combos, is_crit, force_crit, battle)
	result_text = str(resolution_phase.get("result_text", ""))
	var is_draw := bool(resolution_phase.get("is_draw", false))
	var player_wins := bool(resolution_phase.get("player_wins", false))
	summary_lines = _push_battle_summary_line(summary_lines, str(resolution_phase.get("summary_line", "")))
	_set_battle_round_summary(battle, summary_lines)
	await _await_battle_phase(BATTLE_PHASE_RESOLVE_DELAY)

	var status_phase := _run_battle_status_phase(result_text, player_wins, is_draw, battle, enemy_ai)
	result_text = str(status_phase.get("result_text", ""))
	summary_lines = _push_battle_summary_line(summary_lines, str(status_phase.get("summary_line", "")))
	summary_lines = _push_battle_summary_line(summary_lines, str(status_phase.get("causal_line", "")))
	_set_battle_round_summary(battle, summary_lines)
	await _await_battle_phase(BATTLE_PHASE_STATUS_DELAY)

	_finalize_battle_turn_state(battle)
	_update_boss_warning_label(battle, enemy_ai)

	if await _resolve_battle_outcome(battle, result_text):
		return

	_set_battle_broadcast(battle, _get_pre_turn_broadcast(enemy_ai))
	_show_momentum_enemy_intent(battle, enemy_ai)
	_set_battle_turn_lock(battle, false)

func _update_battle_ui(battle: Control):
	var enemy_hp_bar = battle.get_node_or_null("EnemyHPBar")
	if enemy_hp_bar:
		enemy_hp_bar.max_value = battle_enemy_max_hp
		enemy_hp_bar.value = battle_enemy_hp
	battle.get_node("EnemyHP").text = "%d / %d" % [battle_enemy_hp, battle_enemy_max_hp]

	var player_hp_bar = battle.get_node_or_null("PlayerHPBar")
	if player_hp_bar:
		player_hp_bar.max_value = GameState.player_max_hp
		player_hp_bar.value = GameState.player_hp
	battle.get_node("PlayerHP").text = "%d / %d" % [GameState.player_hp, GameState.player_max_hp]

	battle.get_node("PlayerAtk").text = "⚔ %d" % GameState.get_total_attack()
	var enemy_atk_label = battle.get_node_or_null("EnemyAtk")
	if enemy_atk_label:
		enemy_atk_label.text = "⚔ %d" % battle_enemy_atk
	var enemy_group_label = battle.get_node_or_null("EnemyGroupLabel")
	if enemy_group_label:
		enemy_group_label.text = _get_enemy_group_status_text()
		enemy_group_label.visible = not battle_support_enemies.is_empty()
	_update_support_enemy_ui(battle)

	var shield_label = battle.get_node_or_null("PlayerShield")
	if shield_label:
		shield_label.text = "🛡 %d" % GameState.player_shield
		shield_label.visible = GameState.player_shield > 0

	var cheat_label = battle.get_node_or_null("CheatLabel")
	if cheat_label:
		cheat_label.text = GameState.get_cheat_label_text("🔍")

	var cheat_btn = battle.get_node_or_null("CheatButton")
	if cheat_btn:
		cheat_btn.position = BATTLE_CHEAT_BUTTON_POS
		cheat_btn.size = BATTLE_CHEAT_BUTTON_SIZE
		cheat_btn.custom_minimum_size = BATTLE_CHEAT_BUTTON_SIZE
		cheat_btn.text = GameState.get_cheat_label_text("🔍 机括")
		cheat_btn.icon = _load_texture_resource(ArtRegistry.get_combat_icon_path("cheat"))
		cheat_btn.expand_icon = true
		cheat_btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		cheat_btn.disabled = GameState.cheat_points <= 0
		_apply_battle_action_button_state(cheat_btn, "disabled" if cheat_btn.disabled else "normal")

	var protection_label = battle.get_node_or_null("DrawProtectionLabel")
	if protection_label:
		protection_label.text = GameState.get_draw_protection_status_text()
		protection_label.visible = protection_label.text != ""

	var materials_label = battle.get_node_or_null("MaterialsLabel")
	if materials_label:
		materials_label.visible = false
		materials_label.text = ""

	var heirloom_label = battle.get_node_or_null("HeirloomLabel")
	if heirloom_label:
		var heirloom_data := GameState.get_heirloom_data(GameState.selected_heirloom_id)
		if heirloom_data.is_empty():
			heirloom_label.text = "（未携带）"
			heirloom_label.tooltip_text = "未携带传家宝"
		else:
			var cashout_preview := _get_heirloom_cashout_preview()
			var status_text := str(cashout_preview.get("text", GameState.get_heirloom_status_text()))
			heirloom_label.text = "%s\n%s" % [
				str(heirloom_data.get("name", "传家宝")),
				status_text
			]
			var tooltip := GameState.get_heirloom_detail_text()
			if not cashout_preview.is_empty():
				tooltip += "\n预告：%s" % str(cashout_preview.get("hint", status_text))
			heirloom_label.tooltip_text = tooltip
	_update_heirloom_cashout_preview(battle)

	var items_label = battle.get_node_or_null("ItemsLabel")
	if items_label:
		var equipped_names: Array[String] = []
		var equipped_item_dicts: Array = []
		for item in GameState.equipment_slot:
			if GameState.is_era_item(item):
				continue
			equipped_names.append(_get_battle_item_row_text(item))
			equipped_item_dicts.append(item)
		items_label.text = _summarize_text_rows(equipped_names, "（空）", 0, 2)
		items_label.tooltip_text = _get_item_list_tooltip(equipped_item_dicts, "装备栏为空", "装备栏")

	var backpack_label = battle.get_node_or_null("BackpackLabel")
	if backpack_label:
		var backpack_names: Array[String] = []
		for item in GameState.backpack:
			backpack_names.append(_get_battle_item_row_text(item))
		backpack_label.text = _summarize_text_rows(backpack_names, "（空）", 0, 2)
		backpack_label.tooltip_text = _get_item_list_tooltip(GameState.backpack, "背包为空", "背包栏")

	var era_items_label = battle.get_node_or_null("EraItemsLabel")
	if era_items_label:
		var era_names: Array[String] = []
		var era_item_dicts: Array = []
		for item in GameState.equipment_slot:
			if GameState.is_era_item(item):
				era_names.append(_get_battle_item_row_text(item))
				era_item_dicts.append(item)
		era_items_label.text = _summarize_text_rows(era_names, "（无）", 0, 2)
		era_items_label.tooltip_text = _get_item_list_tooltip(era_item_dicts, "暂无时代秘器物", "时代秘器物")

	var energy_label = battle.get_node_or_null("ComboEnergyLabel")
	if energy_label:
		energy_label.text = "⚡ %d/%d" % [GameState.get_combo_energy(), GameState.get_max_combo_energy()]

	var energy_display = battle.get_node_or_null("ComboEnergyDisplay")
	if energy_display:
		energy_display.text = "⚡ 布势气机: %d/%d" % [GameState.get_combo_energy(), GameState.get_max_combo_energy()]

	# 刷新连招按钮
	var combo_container = battle.get_node_or_null("ComboButtons")
	if combo_container:
		_update_combo_buttons(combo_container, battle, current_enemy_ai)
	_apply_combo_resource_heat_state(battle, "auto")
	_update_combo_linchpin_feedback(battle)
	_update_momentum_field(battle)

func _get_heirloom_cashout_preview() -> Dictionary:
	if GameState.has_heirloom("broken_coin") and GameState.field_pending_spend_attack >= 6:
		var amount := int(GameState.field_pending_spend_attack)
		return {
			"kind": "broken_coin_hot" if amount >= 10 else "broken_coin_warm",
			"text": "待兑现：命中 +%d" % amount,
			"hint": "破财印已蓄到 %d/14，下一次命中会把这段伤害一起打出去。" % amount,
			"color": Color(1.0, 0.78, 0.28, 1.0) if amount >= 10 else Color(1.0, 0.86, 0.48, 1.0),
			"border": Color(1.0, 0.62, 0.18, 1.0) if amount >= 10 else Color(0.96, 0.76, 0.32, 1.0),
			"bg": Color(0.24, 0.15, 0.07, 0.94) if amount >= 10 else Color(0.19, 0.15, 0.08, 0.91)
		}
	if GameState.has_heirloom("blood_contract") and GameState.field_pending_blood_attack >= 5:
		var amount := int(GameState.field_pending_blood_attack)
		return {
			"kind": "blood_contract_hot" if amount >= 8 else "blood_contract_warm",
			"text": "待兑现：命中 +%d" % amount,
			"hint": "血契符已蓄到 %d/10，下一次命中会把受创反压回去。" % amount,
			"color": Color(1.0, 0.48, 0.38, 1.0) if amount >= 8 else Color(1.0, 0.62, 0.48, 1.0),
			"border": Color(1.0, 0.35, 0.22, 1.0) if amount >= 8 else Color(0.94, 0.46, 0.34, 1.0),
			"bg": Color(0.24, 0.07, 0.06, 0.94) if amount >= 8 else Color(0.18, 0.08, 0.07, 0.91)
		}
	return {}

func _update_heirloom_cashout_preview(battle: Control) -> void:
	if battle == null:
		return
	var heirloom_card := battle.get_node_or_null("HeirloomCard") as Panel
	var heirloom_label := battle.get_node_or_null("HeirloomLabel") as Label
	if heirloom_card == null and heirloom_label == null:
		return
	var preview := _get_heirloom_cashout_preview()
	var state := str(preview.get("kind", "idle"))
	if heirloom_card != null:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.14, 0.16, 0.86)
		style.border_color = Color(0.88, 0.68, 0.32, 1.0)
		style.set_border_width_all(1)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		if not preview.is_empty():
			style.bg_color = preview.get("bg", style.bg_color)
			style.border_color = preview.get("border", style.border_color)
			style.set_border_width_all(2)
		heirloom_card.add_theme_stylebox_override("panel", style)
	if heirloom_label != null:
		if preview.is_empty():
			heirloom_label.modulate = Color(1.0, 0.86, 0.52, 1.0) if GameState.selected_heirloom_id != "" else Color(0.52, 0.52, 0.52)
		else:
			heirloom_label.modulate = preview.get("color", Color(1.0, 0.86, 0.52, 1.0))
	if heirloom_card != null and str(heirloom_card.get_meta("cashout_state", "")) != state:
		heirloom_card.set_meta("cashout_state", state)
		if not preview.is_empty():
			_pulse_heirloom_cashout_card(heirloom_card, heirloom_label)

func _pulse_heirloom_cashout_card(heirloom_card: Panel, heirloom_label: Label) -> void:
	if heirloom_card == null or not is_instance_valid(heirloom_card):
		return
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(heirloom_card, "modulate", Color(1.0, 0.92, 0.68, 1.0), 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(heirloom_card, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if heirloom_label != null and is_instance_valid(heirloom_label):
		var label_tween := create_tween()
		label_tween.set_loops(3)
		label_tween.tween_property(heirloom_label, "scale", Vector2(1.025, 1.025), 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		label_tween.tween_property(heirloom_label, "scale", Vector2.ONE, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _use_cheat(battle: Control, enemy_ai: EnemyAI):
	if GameState.cheat_points <= 0:
		return
	if battle.get_node_or_null("CheatPanel") != null:
		return
	_disable_battle_buttons(battle)

	var cheat_panel = Panel.new()
	cheat_panel.name = "CheatPanel"
	cheat_panel.position = BATTLE_CHEAT_PANEL_POS
	cheat_panel.custom_minimum_size = BATTLE_CHEAT_PANEL_SIZE
	cheat_panel.size = BATTLE_CHEAT_PANEL_SIZE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.13, 0.12, 0.14, 0.97)
	panel_style.border_color = Color(0.84, 0.72, 0.38, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	panel_style.shadow_color = Color(0, 0, 0, 0.34)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(0, 6)
	cheat_panel.add_theme_stylebox_override("panel", panel_style)

	var cheat_title = Label.new()
	cheat_title.name = "CheatPanelTitle"
	cheat_title.text = "🔍 机括读招\n%s" % _get_cheat_read_preview(enemy_ai)
	cheat_title.position = Vector2(0, 18)
	cheat_title.add_theme_font_size_override("font_size", 19)
	cheat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cheat_title.custom_minimum_size = Vector2(BATTLE_CHEAT_PANEL_SIZE.x, 60)
	cheat_panel.add_child(cheat_title)

	var cheat_hint = Label.new()
	cheat_hint.name = "CheatPanelHint"
	cheat_hint.text = "反抓：克制敌手，临时攻势+1\n回环：对住敌手，换取护甲"
	cheat_hint.position = Vector2(32, 82)
	cheat_hint.custom_minimum_size = Vector2(BATTLE_CHEAT_PANEL_SIZE.x - 64, 40)
	cheat_hint.add_theme_font_size_override("font_size", 13)
	cheat_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cheat_hint.modulate = Color(0.86, 0.82, 0.70, 1.0)
	cheat_panel.add_child(cheat_hint)

	var win_btn = Button.new()
	win_btn.name = "CheatWinButton"
	win_btn.text = "反抓\n看破后克制"
	win_btn.size = BATTLE_CHEAT_ACTION_BUTTON_SIZE
	win_btn.custom_minimum_size = BATTLE_CHEAT_ACTION_BUTTON_SIZE
	win_btn.position = Vector2(52, 142)
	win_btn.add_theme_font_size_override("font_size", 13)
	ArtRegistry.apply_button_icon(win_btn, "attack", false, "机括：看破敌手后反抓，本回合攻势+1。")
	win_btn.pressed.connect(func(): _apply_cheat("win", cheat_panel, battle, enemy_ai))
	cheat_panel.add_child(win_btn)

	var draw_btn = Button.new()
	draw_btn.name = "CheatDrawButton"
	draw_btn.text = "回环\n对住并得甲"
	draw_btn.size = BATTLE_CHEAT_ACTION_BUTTON_SIZE
	draw_btn.custom_minimum_size = BATTLE_CHEAT_ACTION_BUTTON_SIZE
	draw_btn.position = Vector2(BATTLE_CHEAT_PANEL_SIZE.x - 52 - BATTLE_CHEAT_ACTION_BUTTON_SIZE.x, 142)
	draw_btn.add_theme_font_size_override("font_size", 13)
	ArtRegistry.apply_button_icon(draw_btn, "shield", false, "机括：对住敌手，用护甲把风险收回来。")
	draw_btn.pressed.connect(func(): _apply_cheat("draw", cheat_panel, battle, enemy_ai))
	cheat_panel.add_child(draw_btn)

	battle.add_child(cheat_panel)

func _get_cheat_read_preview(enemy_ai: EnemyAI) -> String:
	var predicted_move := _peek_predictable_enemy_move(enemy_ai)
	if predicted_move >= 0:
		return "敌意露出：大概率出%s" % MoveSymbols.move_name(predicted_move)
	if enemy_ai == null:
		return "敌意未明：只能临场拆招"
	if enemy_ai.ai_type == EnemyAI.Type.ADVANCED_DYNAMIC:
		match enemy_ai.dynamic_subtype:
			EnemyAI.DynamicSubtype.MIND_READER:
				return "敌意摇摆：它在抓你的常用手"
			EnemyAI.DynamicSubtype.MIMIC:
				return "敌意紧盯：它在等你上一手"
			EnemyAI.DynamicSubtype.RANDOM_SMART:
				return "敌意混乱：可反抓，但别贪后续"
			EnemyAI.DynamicSubtype.SEQUENCE_MIMIC:
				return "敌意设套：它想诱你顺势走"
	if enemy_ai.ai_type == EnemyAI.Type.BOSS_PHASE and enemy_ai.boss_phase >= 2:
		return "敌意反读：交机括是在抢回主动"
	return "敌意未明：以机括临场反抓"

func _get_cheat_resolved_read_text(enemy_move: int) -> String:
	if enemy_move < 0:
		return "敌手"
	return "敌手%s" % MoveSymbols.move_name(enemy_move)

func _apply_cheat_counterread_bonus() -> String:
	var existing_attack_bonus := GameState.get_combo_buff("attack")
	if existing_attack_bonus <= 0:
		GameState.apply_combo_buff("attack", 1, 1)
		return "反抓+1攻"
	return "反抓续势"

func _apply_cheat(result: String, panel: Panel, battle: Control, enemy_ai: EnemyAI):
	panel.queue_free()
	if not GameState.consume_cheat_point():
		_enable_battle_buttons(battle)
		_update_battle_ui(battle)
		return
	_pulse_combo_resource_feedback(battle, "cooldown")
	_show_battle_impact(battle, "机括开眼", "cheat_charge", 6)
	var unity_text := _apply_unity_seal_cheat_momentum(battle, result)

	var enemy_move := enemy_ai.get_next_move(battle_enemy_hp, battle_enemy_max_hp, -1) if enemy_ai != null else randi() % 3
	var read_text := _get_cheat_resolved_read_text(enemy_move)
	var player_move := enemy_move
	if result == "win":
		player_move = _get_player_winning_move(enemy_move)
		_set_battle_broadcast(battle, "机括反读：看破%s，反手抓回主动" % read_text)
		GameState.add_combo_energy(1)
		var bonus_text := _apply_cheat_counterread_bonus()
		_show_battle_impact(battle, "反抓\n+1攻", "cheat_burst", 14)
		var opener_parts: Array[String] = ["机括反读", "看破%s" % read_text, bonus_text, "布势+1"]
		if unity_text != "":
			opener_parts.append(unity_text)
		await _process_battle_turn(player_move, battle, enemy_ai, enemy_move, "｜".join(opener_parts), true)
	else:
		_set_battle_broadcast(battle, "机括回环：看破%s，选择对住" % read_text)
		var guard_text := _gain_player_shield(2, battle, "机括守势")
		if guard_text != "":
			_show_battle_impact(battle, guard_text, "cheat_guard", 8)
		_show_battle_impact(battle, "天机回环", "cheat_guard", 8)
		var opener_parts: Array[String] = ["机括回环", "对住%s" % read_text, (guard_text if guard_text != "" else "守势")]
		if unity_text != "":
			opener_parts.append(unity_text)
		await _process_battle_turn(player_move, battle, enemy_ai, enemy_move, "｜".join(opener_parts), false)

func _get_player_winning_move(enemy_move: int) -> int:
	match enemy_move:
		0:
			return 2
		1:
			return 0
		2:
			return 1
	return 0

func _advance_floor():
	DebugLog.log("Advancing from floor ", GameState.current_floor)
	_advance_map_floor()

func _show_rest_point():
	"""显示休息点场景"""
	DebugLog.log("Showing rest point")
	_change_state(State.REST_POINT)
	_switch_scene_music("rest")
	GameState.save_progress("rest")

	var rest_point = load("res://scenes/ui/rest_point.tscn").instantiate()
	rest_point.name = "RestPoint"

	# 连接信号
	rest_point.continue_to_next_floor.connect(_on_rest_point_continue)

	_add_ui(rest_point)
	DebugLog.log("Rest point displayed")

func _on_rest_point_continue():
	"""休息点继续下一层（战斗后休息点）"""
	DebugLog.log("Continuing from rest point (post-battle) to next floor")
	_advance_floor_after_rest_point()

func _on_rest_point_continue_from_map():
	"""休息点继续下一层（从地图休息节点进入）"""
	DebugLog.log("Continuing from rest point (from map node) to next floor")
	_advance_map_floor()

func _advance_floor_after_rest_point():
	"""从战斗后休息点进入下一层"""
	DebugLog.log("Advancing after rest point to next floor")
	_advance_map_floor()

func _advance_map_floor() -> void:
	var previous_floor := GameState.current_floor
	var selected_node_index := _get_selected_map_node_index(previous_floor)

	if GameState.current_floor < GameState.map_data.size():
		for node in GameState.map_data[GameState.current_floor]:
			node.accessible = false

	GameState.current_floor += 1
	_award_major_layer_legacy_points(previous_floor)
	combo_sequence.clear()
	_dispose_current_enemy_ai()
	current_enemy_data = null

	if GameState.current_floor >= GameState.max_floors:
		_show_victory()
		return

	_open_connected_next_floor(previous_floor, selected_node_index)

	_show_map()

func _award_major_layer_legacy_points(previous_floor: int) -> int:
	var completed_floor := previous_floor + 1
	if completed_floor <= 0 or completed_floor >= GameState.max_floors:
		return 0
	if completed_floor % GameState.FLOORS_PER_MAJOR_LAYER != 0:
		return 0
	var completed_layer := int(completed_floor / GameState.FLOORS_PER_MAJOR_LAYER)
	var amount: int = GameState.get_era_legacy_layer_reward(completed_layer)
	return GameState.award_memory_cores(amount, "major_layer_%d_clear" % completed_layer)

func _get_selected_map_node_index(floor_idx: int) -> int:
	if floor_idx < 0 or floor_idx >= GameState.map_data.size():
		return -1
	var floor_nodes: Array = GameState.map_data[floor_idx]
	for i in range(floor_nodes.size()):
		if bool((floor_nodes[i] as Dictionary).get("visited", false)):
			return i
	return -1

func _open_connected_next_floor(previous_floor: int, selected_node_index: int) -> void:
	if GameState.current_floor >= GameState.map_data.size():
		return
	for node in GameState.map_data[GameState.current_floor]:
		node.accessible = false
	var next_indices: Array = []
	if previous_floor >= 0 and previous_floor < GameState.map_data.size():
		var previous_nodes: Array = GameState.map_data[previous_floor]
		if selected_node_index >= 0 and selected_node_index < previous_nodes.size():
			next_indices = (previous_nodes[selected_node_index] as Dictionary).get("next_indices", [])
	if next_indices.is_empty():
		for i in range(GameState.map_data[GameState.current_floor].size()):
			next_indices.append(i)
	for raw_idx in next_indices:
		var idx := int(raw_idx)
		if idx >= 0 and idx < GameState.map_data[GameState.current_floor].size():
			GameState.map_data[GameState.current_floor][idx].accessible = true

func _show_victory():
	_show_game_over(true)

func _show_game_over(win: bool):
	_change_state(State.GAME_OVER)
	var gameover_ui = Control.new()
	gameover_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	GameState.complete_run(win)
	var summary = GameState.get_run_summary()

	var bg = ColorRect.new()
	bg.color = GameState.get_era_theme().get("bg", Color(0.12, 0.12, 0.18)).darkened(0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_ui.add_child(bg)
	var top_band = ColorRect.new()
	top_band.color = GameState.get_era_theme().get("panel", Color(0.2, 0.16, 0.12, 0.9))
	top_band.position = Vector2(170, 96)
	top_band.custom_minimum_size = Vector2(940, 10)
	gameover_ui.add_child(top_band)
	gameover_ui.add_child(_create_era_seal(Vector2(580, 110), Vector2(120, 36)))

	var label = Label.new()
	label.text = _get_era_end_title(win)
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 56)
	label.custom_minimum_size = Vector2(1280, 62)
	label.modulate = Color(1, 0.9, 0.6) if win else Color(1, 0.4, 0.4)
	gameover_ui.add_child(label)

	var verdict = Label.new()
	verdict.text = "通关结算" if win else "死亡结算"
	verdict.position = Vector2(0, 124)
	verdict.custom_minimum_size = Vector2(1280, 30)
	verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	verdict.add_theme_font_size_override("font_size", 22)
	verdict.modulate = Color(0.82, 0.78, 0.66) if win else Color(0.98, 0.66, 0.54)
	gameover_ui.add_child(verdict)

	var summary_panel = PanelContainer.new()
	summary_panel.position = Vector2(170, 168)
	summary_panel.custom_minimum_size = Vector2(940, 340)
	var summary_style := StyleBoxFlat.new()
	summary_style.bg_color = GameState.get_era_theme().get("panel", Color(0.18, 0.16, 0.12, 0.94)).darkened(0.04)
	summary_style.border_color = GameState.get_era_theme().get("accent", Color(0.84, 0.68, 0.38, 1.0))
	summary_style.set_border_width_all(1)
	summary_style.corner_radius_top_left = 18
	summary_style.corner_radius_top_right = 18
	summary_style.corner_radius_bottom_left = 18
	summary_style.corner_radius_bottom_right = 18
	summary_style.content_margin_left = 24
	summary_style.content_margin_right = 24
	summary_style.content_margin_top = 22
	summary_style.content_margin_bottom = 22
	summary_panel.add_theme_stylebox_override("panel", summary_style)
	gameover_ui.add_child(summary_panel)

	var summary_box = VBoxContainer.new()
	summary_box.custom_minimum_size = Vector2(892, 296)
	summary_box.add_theme_constant_override("separation", 12)
	summary_panel.add_child(summary_box)

	var headline = Label.new()
	var class_label_text = summary.get("class_name", "未知职业")
	var player_class_script = load("res://resources/player_class_data.gd")
	if player_class_script != null:
		class_label_text = player_class_script.get_class_display_name(GameState.player_class)
	headline.text = "%s｜抵达第%d层｜命数 %d/%d｜攻击 %d｜%s" % [
		class_label_text,
		summary.get("floor_reached", 1),
		summary.get("hp", 0),
		summary.get("max_hp", 0),
		summary.get("attack", 0),
		GameState.get_major_layer_status_text()
	]
	headline.add_theme_font_size_override("font_size", 22)
	headline.modulate = Color(0.9, 0.9, 0.85)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_box.add_child(headline)

	var card_grid = GridContainer.new()
	card_grid.columns = 2
	card_grid.custom_minimum_size = Vector2(892, 220)
	card_grid.add_theme_constant_override("h_separation", 14)
	card_grid.add_theme_constant_override("v_separation", 14)
	summary_box.add_child(card_grid)

	card_grid.add_child(_create_end_summary_card("结局", _get_end_result_detail(win, summary), Color(0.95, 0.78, 0.42) if win else Color(1.0, 0.48, 0.38)))
	card_grid.add_child(_create_end_summary_card("资源", _get_end_resource_detail(summary), Color(0.9, 0.82, 0.46)))
	card_grid.add_child(_create_end_summary_card("成长", _get_end_level_detail(), Color(0.55, 0.86, 1.0)))
	card_grid.add_child(_create_end_summary_card("强化", _get_end_upgrade_detail(), Color(0.78, 0.72, 1.0)))

	if not win:
		var fail_line = Label.new()
		fail_line.text = _get_compact_failure_summary(summary)
		fail_line.add_theme_font_size_override("font_size", 18)
		fail_line.modulate = Color(1.0, 0.68, 0.50)
		fail_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fail_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		summary_box.add_child(fail_line)

	var button_row = HBoxContainer.new()
	button_row.position = Vector2(400, 548)
	button_row.add_theme_constant_override("separation", 30)
	gameover_ui.add_child(button_row)

	var retry_btn = Button.new()
	retry_btn.text = "再来一局"
	retry_btn.custom_minimum_size = Vector2(180, 56)
	retry_btn.add_theme_font_size_override("font_size", 22)
	retry_btn.modulate = Color(0.74, 0.96, 0.74)
	ArtRegistry.apply_button_icon(retry_btn, "start", false, "再来一局")
	retry_btn.pressed.connect(_show_character_select)
	button_row.add_child(retry_btn)

	var menu_btn = Button.new()
	menu_btn.text = "返回菜单"
	menu_btn.custom_minimum_size = Vector2(180, 56)
	menu_btn.add_theme_font_size_override("font_size", 22)
	menu_btn.modulate = Color(0.82, 0.84, 0.9)
	ArtRegistry.apply_button_icon(menu_btn, "back", false, "返回菜单")
	menu_btn.pressed.connect(_show_main_menu)
	button_row.add_child(menu_btn)

	_dispose_combo_database_cache()
	_add_ui(gameover_ui)

func _create_end_summary_card(title: String, body: String, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(438, 104)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.075, 0.065, 0.74)
	style.border_color = accent
	style.set_border_width_all(1)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(406, 80)
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.modulate = accent.lightened(0.08)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)

	var body_label := Label.new()
	body_label.text = body
	body_label.add_theme_font_size_override("font_size", 16)
	body_label.modulate = Color(0.88, 0.86, 0.78, 1.0)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_label.custom_minimum_size = Vector2(406, 48)
	box.add_child(body_label)
	return card

func _get_end_result_detail(win: bool, summary: Dictionary) -> String:
	if win:
		return "通关｜完成 %s｜抵达第%d层" % [
			str(GameState.get_current_era_definition().get("name", "秦")),
			int(summary.get("floor_reached", 1))
		]
	return "死亡｜止步 %s｜抵达第%d层" % [
		GameState.get_major_layer_status_text(),
		int(summary.get("floor_reached", 1))
	]

func _get_end_resource_detail(summary: Dictionary) -> String:
	return "结余金币 %d｜传承点 %d\n传承点可用于局外升级" % [
		int(summary.get("gold", 0)),
		int(summary.get("legacy_points", GameState.memory_cores))
	]

func _get_end_level_detail() -> String:
	var gained_levels := maxi(GameState.player_level - 1, 0)
	var stat_parts: Array[String] = []
	if GameState.bonus_hp_from_level > 0:
		stat_parts.append("命数+%d" % GameState.bonus_hp_from_level)
	if GameState.bonus_atk_from_level > 0:
		stat_parts.append("攻击+%d" % GameState.bonus_atk_from_level)
	var stat_text := "未用提振 %d" % GameState.unspent_attribute_points
	if not stat_parts.is_empty():
		stat_text = "｜".join(stat_parts)
	return "Lv.%d｜升级 %d 次\n%s" % [GameState.player_level, gained_levels, stat_text]

func _get_end_upgrade_detail() -> String:
	var lines: Array[String] = []
	var combo_text := _get_end_combo_upgrade_text()
	var equipment_text := _get_end_equipment_upgrade_text()
	if combo_text != "":
		lines.append(combo_text)
	if equipment_text != "":
		lines.append(equipment_text)
	if lines.is_empty():
		return "本局未形成强化\n优先在营寨补核心布局或器物"
	return "\n".join(lines)

func _get_end_combo_upgrade_text() -> String:
	var upgraded: Array[String] = []
	var combo_db = _get_combo_database()
	for combo_id in GameState.combo_upgrades.keys():
		var level := GameState.get_combo_upgrade_level(str(combo_id))
		if level <= 0:
			continue
		var combo_info = combo_db.get_combo_by_id(str(combo_id))
		var combo_name := str(combo_id)
		if combo_info:
			combo_name = _get_combo_name(combo_info)
		upgraded.append("%s Lv.%d" % [combo_name, level])
	if upgraded.is_empty():
		return ""
	return "布局：" + _join_limited_summary(upgraded, 3)

func _get_end_equipment_upgrade_text() -> String:
	var upgraded: Array[String] = []
	for item_id in GameState.equipment_upgrades.keys():
		var data: Dictionary = GameState.equipment_upgrades.get(item_id, {})
		var parts: Array[String] = []
		var level := int(data.get("level", 0))
		var quality := int(data.get("quality", 0))
		var special := bool(data.get("special_unlocked", false))
		if level > 0:
			parts.append("锻%d" % level)
		if quality > 0:
			var quality_names := ["白", "蓝", "红"]
			parts.append("品%s" % quality_names[clamp(quality, 0, quality_names.size() - 1)])
		if special:
			parts.append("特效")
		if parts.is_empty():
			continue
		var item_data: Dictionary = GameState.ITEMS.get(str(item_id), {})
		var item_name := str(item_id)
		if not item_data.is_empty():
			item_name = GameState.get_item_display_name(item_data)
		upgraded.append("%s %s" % [item_name, "/".join(parts)])
	if upgraded.is_empty():
		return ""
	return "器物：" + _join_limited_summary(upgraded, 2)

func _join_limited_summary(items: Array[String], limit: int) -> String:
	if items.size() <= limit:
		return "，".join(items)
	var shown := items.slice(0, limit)
	return "%s 等%d项" % ["，".join(shown), items.size()]

func _get_compact_failure_summary(summary: Dictionary) -> String:
	var reason := "命数归零"
	var advice := "下一局多留一手护甲或回复。"
	if is_current_battle_boss:
		reason = "Boss二命压制"
		advice = "进Boss前留机括，优先保血线。"
	elif GameState.equipment_slot.is_empty():
		reason = "器物不足"
		advice = "路线里多进商队/营寨，先补核心器物。"
	elif GameState.get_equipped_combos().is_empty():
		reason = "布局空缺"
		advice = "开局至少带一个稳定输出布局。"
	elif int(summary.get("hp", 0)) <= 0 and GameState.player_shield <= 0:
		reason = "防线被击穿"
		advice = "看到高压节点时，优先叠甲再抢攻。"
	return "败因：%s｜%s" % [reason, advice]

func _generate_map():
	DebugLog.log("Generating historical route map...")
	GameState.map_data = HistoryMapBuilder.new().generate(GameState.selected_era_id, GameState.max_floors)
	GameState.current_floor = 0
	GameState.selected_route_name = ""
	GameState.route_switch_count = 0
	DebugLog.log("Historical map generated: ", GameState.map_data.size(), " floors")

func _change_state(new_state):
	DebugLog.log("State: ", current_state, " -> ", new_state)
	current_state = new_state
	if current_ui:
		var old_ui := current_ui
		current_ui = null
		if is_instance_valid(old_ui):
			_dispose_ui_runtime_cache(old_ui)
			if old_ui.get_parent() == self:
				old_ui.queue_free()
			else:
				old_ui.free()

func _add_ui(ui):
	DebugLog.log("_add_ui called with: ", ui)
	if current_ui != null and current_ui != ui:
		var old_ui := current_ui
		current_ui = null
		if is_instance_valid(old_ui):
			_dispose_ui_runtime_cache(old_ui)
			if old_ui.get_parent() == self:
				old_ui.queue_free()
			else:
				old_ui.free()
	current_ui = ui

	# 设置根节点大小为游戏窗口大小
	if ui is Control:
		DebugLog.log("Setting size for Control")
		ui.custom_minimum_size = Vector2(1280, 720)
		# 重要：设置offset让Control有实际大小
		ui.offset_right = 1280
		ui.offset_bottom = 720

	DebugLog.log("Adding child...")
	add_child(ui)
	DebugLog.log("Added UI: ", ui.name, " size: ", ui.size)

func _dispose_ui_runtime_cache(ui: Node) -> void:
	if ui != null and is_instance_valid(ui) and ui.has_method("dispose_runtime_cache"):
		ui.dispose_runtime_cache()
