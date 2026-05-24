extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var art_registry = root.get_node("/root/ArtRegistry")
	var missing: Array[String] = []
	var era_slots := [
		"main_menu_bg", "character_select_bg", "combo_select_bg", "map_bg", "battle_bg",
		"main_menu_seal", "map_seal", "battle_seal",
		"menu_frame", "battle_frame", "shop_panel", "rest_panel", "overlay_frame"
	]
	for era_id in ["qin", "song", "china"]:
		for slot in era_slots:
			_check_path(art_registry.get_era_ui_path(slot, era_id), "%s:%s" % [era_id, slot], missing)
		for node_type in range(5):
			_check_path(art_registry.get_map_node_icon_path(node_type, era_id), "%s:node:%d" % [era_id, node_type], missing)

	for class_id in range(5):
		_check_path(art_registry.get_character_portrait_path(class_id), "character_portrait:%d" % class_id, missing)
		_check_path(art_registry.get_character_portrait_path(class_id, true), "character_battle:%d" % class_id, missing)
		_check_path(art_registry.get_character_select_path(class_id), "character_select:%d" % class_id, missing)
		_check_path(art_registry.get_character_icon_path(class_id), "character_icon:%d" % class_id, missing)
		_check_path(art_registry.get_character_passive_icon_path(class_id), "character_passive_icon:%d" % class_id, missing)

	for enemy_key in [
		"basic_tian", "basic_ren", "basic_di", "basic_soldier", "basic_trainee", "basic_guard",
		"elite_switch", "elite_guardian", "elite_counter", "elite_dual", "elite_tactician",
		"advanced_mind", "advanced_assault", "advanced_mimic", "advanced_sage", "advanced_master",
		"boss_qin", "boss_song", "boss_china"
	]:
		_check_path(art_registry.get_enemy_portrait_path(enemy_key), "enemy:%s" % enemy_key, missing)

	for item_id in [
		"long_sword", "wooden_shield", "life_crystal", "heart_mirror", "blood_tyrant",
		"tiger_tally", "trade_ledger", "unity_seal"
	]:
		_check_path(art_registry.get_item_icon_path(item_id), "item:%s" % item_id, missing)

	for system_key in ["settings", "rules", "sound", "back"]:
		_check_path(art_registry.get_system_icon_path(system_key), "system:%s" % system_key, missing)

	for combat_key in ["tian", "di", "ren", "attack", "shield", "cheat"]:
		_check_path(art_registry.get_combat_icon_path(combat_key), "combat:%s" % combat_key, missing)

	for ref_key in ["title_back", "divider_line", "corner_stud", "chapter_box", "bottom_bar", "chip", "card", "button_frame", "manifest"]:
		_check_path(art_registry.get_reference_ui_path(ref_key), "reference:%s" % ref_key, missing)

	for action_key in ["start", "continue", "next", "back", "settings", "rules", "sound", "upgrade", "buy", "refresh", "heal", "equip", "craft"]:
		_check_path(art_registry.get_action_icon_path(action_key), "action:%s" % action_key, missing)

	for effect_key in ["combo_flash", "hit_slash", "hit_spark", "boss_phase_flash", "victory_stamp", "defeat_stamp", "draw_stamp", "shield_break"]:
		_check_path(art_registry.get_effect_path(effect_key), "effect:%s" % effect_key, missing)

	if not missing.is_empty():
		push_error("Missing art registry assets:\n%s" % "\n".join(missing))
		quit(1)
		return

	print("art_registry_smoke: ok")
	quit(0)

func _check_path(path: String, label: String, missing: Array[String]) -> void:
	if path == "" or (not ResourceLoader.exists(path) and not FileAccess.file_exists(path)):
		missing.append("%s -> %s" % [label, path])
