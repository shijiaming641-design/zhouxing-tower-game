extends Node

const CHARACTER_PORTRAITS := {
	0: ["res://assets/characters/doctor/doctor_portrait.png", "res://assets/characters/doctor_portrait.png"],
	1: ["res://assets/characters/artisan/artisan_portrait.png", "res://assets/characters/hacker_portrait.png"],
	2: ["res://assets/characters/merchant/merchant_portrait.png", "res://assets/characters/merchant_portrait.png"],
	3: ["res://assets/characters/farmer/farmer_portrait.png", "res://assets/characters/farmer_portrait.png"],
	4: ["res://assets/characters/wanderer/wanderer_portrait.png", "res://assets/characters/wanderer_portrait.png"],
}

const CHARACTER_BATTLE := {
	0: ["res://assets/characters/doctor/doctor_battle.png", "res://assets/characters/doctor_battle.png"],
	1: ["res://assets/characters/artisan/artisan_battle.png", "res://assets/characters/hacker_battle.png"],
	2: ["res://assets/characters/merchant/merchant_battle.png", "res://assets/characters/merchant_battle.png"],
	3: ["res://assets/characters/farmer/farmer_battle.png", "res://assets/characters/farmer_battle.png"],
	4: ["res://assets/characters/wanderer/wanderer_battle.png", "res://assets/characters/wanderer_battle.png"],
}

const CHARACTER_SELECT := {
	0: ["res://assets/characters/doctor/doctor_select.png", "res://assets/characters/doctor_select.png"],
	1: ["res://assets/characters/artisan/artisan_select.png", "res://assets/characters/hacker_select.png"],
	2: ["res://assets/characters/merchant/merchant_select.png", "res://assets/characters/merchant_select.png"],
	3: ["res://assets/characters/farmer/farmer_select.png", "res://assets/characters/farmer_select.png"],
	4: ["res://assets/characters/wanderer/wanderer_select.png", "res://assets/characters/wanderer_select.png"],
}

const CHARACTER_ICONS := {
	0: "res://assets/characters/doctor/doctor_icon.png",
	1: "res://assets/characters/artisan/artisan_icon.png",
	2: "res://assets/characters/merchant/merchant_icon.png",
	3: "res://assets/characters/farmer/farmer_icon.png",
	4: "res://assets/characters/wanderer/wanderer_icon.png",
}

const CHARACTER_PASSIVE_ICONS := {
	0: "res://assets/characters/doctor/doctor_passive_icon.png",
	1: "res://assets/characters/artisan/artisan_passive_icon.png",
	2: "res://assets/characters/merchant/merchant_passive_icon.png",
	3: "res://assets/characters/farmer/farmer_passive_icon.png",
	4: "res://assets/characters/wanderer/wanderer_passive_icon.png",
}

const ENEMY_PORTRAITS := {
	"basic_tian": ["res://assets/enemies/basic/enemy_basic_tian.png", "res://assets/enemies/enemy_basic_tian.png"],
	"basic_ren": ["res://assets/enemies/basic/enemy_basic_ren.png", "res://assets/enemies/enemy_basic_ren.png"],
	"basic_di": ["res://assets/enemies/basic/enemy_basic_di.png", "res://assets/enemies/enemy_basic_di.png"],
	"basic_soldier": ["res://assets/enemies/basic/enemy_basic_soldier.png", "res://assets/enemies/enemy_basic_soldier.png"],
	"basic_trainee": ["res://assets/enemies/basic/enemy_basic_trainee.png", "res://assets/enemies/enemy_basic_trainee.png"],
	"basic_guard": ["res://assets/enemies/basic/enemy_basic_guard.png", "res://assets/enemies/enemy_basic_guard.png"],
	"elite_switch": ["res://assets/enemies/elite/enemy_elite_switch.png", "res://assets/enemies/enemy_elite_switch.png"],
	"elite_guardian": ["res://assets/enemies/elite/enemy_elite_guardian.png", "res://assets/enemies/enemy_elite_guardian.png"],
	"elite_counter": ["res://assets/enemies/elite/enemy_elite_counter.png", "res://assets/enemies/enemy_elite_counter.png"],
	"elite_dual": ["res://assets/enemies/elite/enemy_elite_dual.png", "res://assets/enemies/enemy_elite_dual.png"],
	"elite_tactician": ["res://assets/enemies/elite/enemy_elite_tactician.png", "res://assets/enemies/enemy_elite_tactician.png"],
	"advanced_mind": ["res://assets/enemies/advanced/enemy_advanced_mind.png", "res://assets/enemies/enemy_advanced_mind.png"],
	"advanced_assault": ["res://assets/enemies/advanced/enemy_advanced_assault.png", "res://assets/enemies/enemy_advanced_assault.png"],
	"advanced_mimic": ["res://assets/enemies/advanced/enemy_advanced_mimic.png", "res://assets/enemies/enemy_advanced_mimic.png"],
	"advanced_sage": ["res://assets/enemies/advanced/enemy_advanced_sage.png", "res://assets/enemies/enemy_advanced_sage.png"],
	"advanced_master": ["res://assets/enemies/advanced/enemy_advanced_master.png", "res://assets/enemies/enemy_advanced_master.png"],
	"boss_qin": ["res://assets/enemies/boss/enemy_boss_qin.png", "res://assets/enemies/enemy_boss_qin.png"],
	"boss_song": ["res://assets/enemies/boss/enemy_boss_song.png", "res://assets/enemies/enemy_boss_song.png"],
	"boss_china": ["res://assets/enemies/boss/enemy_boss_china.png", "res://assets/enemies/enemy_boss_china.png"],
}

const ITEM_ICONS := {
	"long_sword": "res://assets/items/icons/item_sword.png",
	"demon_blade": "res://assets/items/icons/item_sword.png",
	"bounty_blade": "res://assets/items/icons/item_sword.png",
	"regicide": "res://assets/items/icons/item_sword.png",
	"blood_tyrant": "res://assets/items/icons/item_amulet.png",
	"wooden_shield": "res://assets/items/icons/item_shield.png",
	"life_crystal": "res://assets/items/icons/item_crystal.png",
	"heart_mirror": "res://assets/items/icons/item_mirror.png",
	"vampire_cross": "res://assets/items/icons/item_amulet.png",
	"precision_guidance": "res://assets/items/icons/item_amulet.png",
	"precision_auxiliary": "res://assets/items/icons/item_amulet.png",
	"precision_calculation": "res://assets/items/icons/item_mirror.png",
	"ai_system": "res://assets/items/icons/item_amulet.png",
	"explorer_notes": "res://assets/items/icons/item_potion.png",
	"greedy_gloves": "res://assets/items/icons/item_amulet.png",
	"tiger_tally": "res://assets/items/era_sets/qin/qin_item_tiger_tally.png",
	"trade_ledger": "res://assets/items/era_sets/song/song_item_trade_ledger.png",
	"unity_seal": "res://assets/items/era_sets/china/china_item_mountain_seal.png",
}

const SYSTEM_ICONS := {
	"settings": "res://assets/icons/system/icon_settings.png",
	"rules": "res://assets/icons/system/icon_rules.png",
	"sound": "res://assets/icons/system/icon_sound.png",
	"back": "res://assets/icons/system/icon_back.png",
}

const COMBAT_ICONS := {
	"tian": "res://assets/icons/combat/icon_tian.png",
	"di": "res://assets/icons/combat/icon_di.png",
	"ren": "res://assets/icons/combat/icon_ren.png",
	"attack": "res://assets/icons/combat/icon_attack.png",
	"shield": "res://assets/icons/combat/icon_shield.png",
	"cheat": "res://assets/icons/combat/icon_cheat.png",
}

const REFERENCE_UI := {
	"title_back": "res://assets/reference/title_back_common.png",
	"divider_line": "res://assets/reference/divider_line_common.png",
	"corner_stud": "res://assets/reference/corner_stud_common.png",
	"chapter_box": "res://assets/reference/chapter_box_common.png",
	"bottom_bar": "res://assets/reference/bottom_bar_common.png",
	"chip": "res://assets/reference/chip_common.png",
	"card": "res://assets/reference/card_common.png",
	"button_frame": "res://assets/reference/button_frame_common.png",
	"manifest": "res://assets/reference/asset_manifest.md",
}

const ACTION_ICONS := {
	"start": ["res://assets/icons/action/action_start.png", "res://assets/icons/combat/icon_attack.png"],
	"continue": ["res://assets/icons/action/action_continue.png", "res://assets/icons/combat/icon_ren.png"],
	"next": ["res://assets/icons/action/action_next.png", "res://assets/icons/combat/icon_ren.png"],
	"back": ["res://assets/icons/system/icon_back.png"],
	"settings": ["res://assets/icons/system/icon_settings.png"],
	"rules": ["res://assets/icons/system/icon_rules.png"],
	"sound": ["res://assets/icons/system/icon_sound.png"],
	"stats": "res://assets/icons/system/icon_rules.png",
	"codex": "res://assets/icons/system/icon_rules.png",
	"upgrade": ["res://assets/icons/action/action_upgrade.png", "res://assets/icons/combat/icon_shield.png"],
	"era": "res://assets/reference/chapter_box_common.png",
	"buy": ["res://assets/icons/action/action_buy.png", "res://assets/items/icons/item_amulet.png"],
	"refresh": ["res://assets/icons/action/action_refresh.png", "res://assets/icons/combat/icon_cheat.png"],
	"heal": ["res://assets/icons/action/action_heal.png", "res://assets/items/icons/item_potion.png"],
	"equip": ["res://assets/icons/action/action_equip.png", "res://assets/items/icons/item_sword.png"],
	"combo": "res://assets/icons/combat/icon_tian.png",
	"craft": ["res://assets/icons/action/action_craft.png", "res://assets/items/icons/item_crystal.png"],
	"attack": "res://assets/icons/combat/icon_attack.png",
	"shield": "res://assets/icons/combat/icon_shield.png",
	"cheat": "res://assets/icons/combat/icon_cheat.png",
	"tian": "res://assets/icons/combat/icon_tian.png",
	"ren": "res://assets/icons/combat/icon_ren.png",
	"di": "res://assets/icons/combat/icon_di.png",
}

const EFFECTS := {
	"combo_flash": "res://assets/effects/combo/combo_flash_01.png",
	"hit_slash": "res://assets/effects/hit/hit_slash_01.png",
	"hit_spark": "res://assets/effects/hit/hit_spark_01.png",
	"boss_phase_flash": "res://assets/effects/particles/boss_phase_flash.png",
	"victory_stamp": "res://assets/effects/result/victory_stamp.png",
	"defeat_stamp": "res://assets/effects/result/defeat_stamp.png",
	"draw_stamp": "res://assets/effects/result/draw_stamp.png",
	"shield_break": "res://assets/effects/shield/shield_break_01.png",
}

const ERA_UI := {
	"qin": {
		"main_menu_bg": "res://assets/backgrounds/main_menu/main_menu_journey.png",
		"character_select_bg": "res://assets/backgrounds/character_select/character_select_hall.png",
		"combo_select_bg": "res://assets/backgrounds/combo_select/combo_select_strategy_tent.png",
		"combo_select_seal": "res://assets/ui/qin/seals/qin_combo_select_seal.png",
		"combo_select_title_plate": "res://assets/ui/qin/frames/qin_combo_select_title_plate.png",
		"combo_select_bottom_plate": "res://assets/ui/qin/frames/qin_combo_select_bottom_plate.png",
		"combo_select_left_frame": "res://assets/ui/qin/frames/qin_combo_select_left_frame.png",
		"combo_select_upper_right_frame": "res://assets/ui/qin/frames/qin_combo_select_upper_right_frame.png",
		"combo_select_lower_right_frame": "res://assets/ui/qin/frames/qin_combo_select_lower_right_frame.png",
		"combo_select_equipped_slot_frame": "res://assets/ui/qin/cards/qin_combo_select_equipped_slot_frame.png",
		"combo_select_combo_item_frame": "res://assets/ui/qin/cards/qin_combo_select_combo_item_frame.png",
		"combo_select_special_item_frame": "res://assets/ui/qin/cards/qin_combo_select_special_item_frame.png",
		"combo_select_back_button": "res://assets/ui/qin/buttons/qin_combo_select_back_button.png",
		"combo_select_start_button": "res://assets/ui/qin/buttons/qin_combo_select_start_button.png",
		"map_bg": "res://assets/ui/qin/backgrounds/qin_map_bg.png",
		"battle_bg": "res://assets/ui/qin/backgrounds/qin_battle_bg.png",
		"main_menu_seal": "res://assets/ui/qin/seals/qin_main_menu_seal.png",
		"map_seal": "res://assets/ui/qin/seals/qin_map_seal.png",
		"battle_seal": "res://assets/ui/qin/seals/qin_battle_seal.png",
		"menu_frame": "res://assets/ui/qin/frames/qin_menu_frame.png",
		"battle_frame": "res://assets/ui/qin/frames/qin_battle_frame.png",
		"shop_panel": "res://assets/ui/qin/frames/qin_shop_panel.png",
		"rest_panel": "res://assets/ui/qin/frames/qin_rest_panel.png",
		"overlay_frame": "res://assets/ui/qin/frames/qin_overlay_frame.png",
	},
	"song": {
		"main_menu_bg": "res://assets/backgrounds/main_menu/main_menu_journey.png",
		"character_select_bg": "res://assets/backgrounds/character_select/character_select_hall.png",
		"combo_select_bg": "res://assets/backgrounds/combo_select/combo_select_strategy_tent.png",
		"combo_select_seal": "res://assets/ui/song/seals/song_combo_select_seal.png",
		"combo_select_title_plate": "res://assets/ui/song/frames/song_combo_select_title_plate.png",
		"combo_select_bottom_plate": "res://assets/ui/song/frames/song_combo_select_bottom_plate.png",
		"combo_select_left_frame": "res://assets/ui/song/frames/song_combo_select_left_frame.png",
		"combo_select_upper_right_frame": "res://assets/ui/song/frames/song_combo_select_upper_right_frame.png",
		"combo_select_lower_right_frame": "res://assets/ui/song/frames/song_combo_select_lower_right_frame.png",
		"combo_select_equipped_slot_frame": "res://assets/ui/song/cards/song_combo_select_equipped_slot_frame.png",
		"combo_select_combo_item_frame": "res://assets/ui/song/cards/song_combo_select_combo_item_frame.png",
		"combo_select_special_item_frame": "res://assets/ui/song/cards/song_combo_select_special_item_frame.png",
		"combo_select_back_button": "res://assets/ui/song/buttons/song_combo_select_back_button.png",
		"combo_select_start_button": "res://assets/ui/song/buttons/song_combo_select_start_button.png",
		"map_bg": "res://assets/ui/song/backgrounds/song_map_bg.png",
		"battle_bg": "res://assets/ui/song/backgrounds/song_battle_bg.png",
		"main_menu_seal": "res://assets/ui/song/seals/song_main_menu_seal.png",
		"map_seal": "res://assets/ui/song/seals/song_map_seal.png",
		"battle_seal": "res://assets/ui/song/seals/song_battle_seal.png",
		"menu_frame": "res://assets/ui/song/frames/song_menu_frame.png",
		"battle_frame": "res://assets/ui/song/frames/song_battle_frame.png",
		"shop_panel": "res://assets/ui/song/frames/song_shop_panel.png",
		"rest_panel": "res://assets/ui/song/frames/song_rest_panel.png",
		"overlay_frame": "res://assets/ui/song/frames/song_overlay_frame.png",
	},
	"china": {
		"main_menu_bg": "res://assets/backgrounds/main_menu/main_menu_journey.png",
		"character_select_bg": "res://assets/backgrounds/character_select/character_select_hall.png",
		"combo_select_bg": "res://assets/backgrounds/combo_select/combo_select_strategy_tent.png",
		"combo_select_seal": "res://assets/ui/china/seals/china_combo_select_seal.png",
		"combo_select_title_plate": "res://assets/ui/china/frames/china_combo_select_title_plate.png",
		"combo_select_bottom_plate": "res://assets/ui/china/frames/china_combo_select_bottom_plate.png",
		"combo_select_left_frame": "res://assets/ui/china/frames/china_combo_select_left_frame.png",
		"combo_select_upper_right_frame": "res://assets/ui/china/frames/china_combo_select_upper_right_frame.png",
		"combo_select_lower_right_frame": "res://assets/ui/china/frames/china_combo_select_lower_right_frame.png",
		"combo_select_equipped_slot_frame": "res://assets/ui/china/cards/china_combo_select_equipped_slot_frame.png",
		"combo_select_combo_item_frame": "res://assets/ui/china/cards/china_combo_select_combo_item_frame.png",
		"combo_select_special_item_frame": "res://assets/ui/china/cards/china_combo_select_special_item_frame.png",
		"combo_select_back_button": "res://assets/ui/china/buttons/china_combo_select_back_button.png",
		"combo_select_start_button": "res://assets/ui/china/buttons/china_combo_select_start_button.png",
		"map_bg": "res://assets/ui/china/backgrounds/china_map_bg.png",
		"battle_bg": "res://assets/ui/china/backgrounds/china_battle_bg.png",
		"main_menu_seal": "res://assets/ui/china/seals/china_main_menu_seal.png",
		"map_seal": "res://assets/ui/china/seals/china_map_seal.png",
		"battle_seal": "res://assets/ui/china/seals/china_battle_seal.png",
		"menu_frame": "res://assets/ui/china/frames/china_menu_frame.png",
		"battle_frame": "res://assets/ui/china/frames/china_battle_frame.png",
		"shop_panel": "res://assets/ui/china/frames/china_shop_panel.png",
		"rest_panel": "res://assets/ui/china/frames/china_rest_panel.png",
		"overlay_frame": "res://assets/ui/china/frames/china_overlay_frame.png",
	},
}

const NODE_ICON_NAMES := ["battle", "shop", "rest", "event", "boss"]

func era_key(era_id: String = "") -> String:
	var id := era_id if era_id != "" else GameState.selected_era_id
	return "china" if id == "china" else ("song" if id == "song" else "qin")

func get_character_portrait_path(class_id: int, battle: bool = false) -> String:
	if battle:
		return _first_existing_path(CHARACTER_BATTLE.get(class_id, CHARACTER_PORTRAITS.get(class_id, "")))
	return _first_existing_path(CHARACTER_PORTRAITS.get(class_id, ""))

func get_character_select_path(class_id: int) -> String:
	return _first_existing_path(CHARACTER_SELECT.get(class_id, CHARACTER_PORTRAITS.get(class_id, "")))

func get_character_icon_path(class_id: int) -> String:
	return _first_existing_path(CHARACTER_ICONS.get(class_id, CHARACTER_PORTRAITS.get(class_id, "")))

func get_character_passive_icon_path(class_id: int) -> String:
	return _first_existing_path(CHARACTER_PASSIVE_ICONS.get(class_id, CHARACTER_ICONS.get(class_id, "")))

func get_enemy_portrait_path(enemy_key: String) -> String:
	return _first_existing_path(ENEMY_PORTRAITS.get(enemy_key, ""))

func get_item_icon_path(item_id: String, item_type: String = "") -> String:
	var path := str(ITEM_ICONS.get(item_id, ""))
	if path != "":
		return path
	match item_type:
		"attack":
			return "res://assets/items/icons/item_sword.png"
		"defense":
			return "res://assets/items/icons/item_shield.png"
		_:
			return "res://assets/items/icons/item_amulet.png"

func get_era_ui_path(slot: String, era_id: String = "") -> String:
	var data: Dictionary = ERA_UI.get(era_key(era_id), {})
	return str(data.get(slot, ""))

func get_system_icon_path(icon_key: String) -> String:
	return str(SYSTEM_ICONS.get(icon_key, ""))

func get_combat_icon_path(icon_key: String) -> String:
	return str(COMBAT_ICONS.get(icon_key, ""))

func get_reference_ui_path(slot: String) -> String:
	return str(REFERENCE_UI.get(slot, ""))

func get_action_icon_path(action_key: String) -> String:
	return _first_existing_path(ACTION_ICONS.get(action_key, ""))

func get_effect_path(effect_key: String) -> String:
	return _first_existing_path(EFFECTS.get(effect_key, ""))

func _first_existing_path(value) -> String:
	if value is Array:
		for path in value:
			var path_string := str(path)
			if path_string != "" and ResourceLoader.exists(path_string):
				return path_string
		return str(value[0]) if not value.is_empty() else ""
	var path_string := str(value)
	return path_string

func load_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D

func apply_button_icon(button: Button, action_key: String, icon_only: bool = false, tooltip: String = "") -> void:
	if button == null:
		return
	var icon_texture := load_texture(get_action_icon_path(action_key))
	if icon_texture == null:
		return
	if tooltip != "":
		button.tooltip_text = tooltip
	elif button.tooltip_text == "" and button.text != "":
		button.tooltip_text = button.text.replace("\n", " ")
	button.icon = icon_texture
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("h_separation", 8)
	if icon_only:
		if button.tooltip_text == "":
			button.tooltip_text = action_key
		button.text = ""
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER

func get_map_node_icon_path(node_type: int, era_id: String = "") -> String:
	if node_type < 0 or node_type >= NODE_ICON_NAMES.size():
		return ""
	var key := era_key(era_id)
	return "res://assets/ui/%s/nodes/%s_node_%s.png" % [key, key, NODE_ICON_NAMES[node_type]]
