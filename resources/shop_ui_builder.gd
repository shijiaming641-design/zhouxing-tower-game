class_name ShopUiBuilder
extends RefCounted

var game_state: Node
var shop_flow: ShopFlow
var theme: Dictionary

func _init(state: Node, flow: ShopFlow) -> void:
	game_state = state
	shop_flow = flow
	theme = game_state.get_era_theme()

func build(config: Dictionary) -> Control:
	var shop := Control.new()
	shop.name = "ShopScene"
	shop.set_anchors_preset(Control.PRESET_FULL_RECT)

	_add_background(shop, config)
	_add_title(shop, config)
	_add_resources(shop, config)
	_add_shop_items(shop, config)
	_add_refresh_button(shop, config)
	_add_storage_frames(shop)
	_add_navigation(shop, config)
	return shop

func _apply_button_icon(button: Button, action_key: String, icon_only: bool = false, tooltip: String = "") -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var registry := tree.root.get_node_or_null("/root/ArtRegistry")
	if registry != null and registry.has_method("apply_button_icon"):
		registry.apply_button_icon(button, action_key, icon_only, tooltip)

func _load_registry_texture(method_name: String, key: String) -> Texture2D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var registry := tree.root.get_node_or_null("/root/ArtRegistry")
	if registry == null or not registry.has_method(method_name):
		return null
	var path := str(registry.call(method_name, key))
	if path == "" or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D

func _load_item_icon_from_registry(item: Dictionary) -> Texture2D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var registry := tree.root.get_node_or_null("/root/ArtRegistry")
	if registry == null or not registry.has_method("get_item_icon_path"):
		return null
	var path := str(registry.call("get_item_icon_path", str(item.get("id", "")), str(item.get("type", ""))))
	if path == "" or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D

func _add_background(shop: Control, config: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.color = theme.get("bg", Color(0.12, 0.12, 0.18))
	bg.offset_right = 1280
	bg.offset_bottom = 720
	shop.add_child(bg)

	var panel_texture: Texture2D = config.get("shop_panel_texture", null)
	if panel_texture != null:
		var shop_frame := TextureRect.new()
		shop_frame.name = "EraShopPanel"
		shop_frame.texture = panel_texture
		shop_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		shop_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shop_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		shop_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shop_frame.modulate = Color(1, 1, 1, 0.55)
		shop.add_child(shop_frame)

	var title_back := ColorRect.new()
	title_back.color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.9))
	title_back.color.a = 0.24
	title_back.position = Vector2(318, 14)
	title_back.custom_minimum_size = Vector2(644, 42)
	shop.add_child(title_back)

	var shop_band := ColorRect.new()
	shop_band.color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.9))
	shop_band.position = Vector2(140, 62)
	shop_band.custom_minimum_size = Vector2(1000, 8)
	shop.add_child(shop_band)

	var bottom_band := ColorRect.new()
	bottom_band.color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	bottom_band.position = Vector2(180, 684)
	bottom_band.custom_minimum_size = Vector2(920, 3)
	shop.add_child(bottom_band)

	var seal_factory: Callable = config.get("seal_factory", Callable())
	if seal_factory.is_valid():
		shop.add_child(seal_factory.call(Vector2(160, 76), Vector2(120, 36)))

func _add_title(shop: Control, config: Dictionary) -> void:
	var discount_text := ""
	if float(game_state.shop_discount) < 1.0:
		discount_text = " 【%.0f折】" % (float(game_state.shop_discount) * 10.0)

	var era_price_note := ""
	match str(game_state.selected_era_id):
		"qin":
			era_price_note = " 时代价严"
		"song":
			era_price_note = " 市易繁荣"
		"china":
			era_price_note = " 百代重税"

	var shop_title_factory: Callable = config.get("shop_title_factory", Callable())
	var title_text := "行商"
	if shop_title_factory.is_valid():
		title_text = str(shop_title_factory.call(discount_text, int(game_state.current_floor) + 1))

	var title := Label.new()
	title.text = "%s%s" % [title_text, era_price_note]
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 10
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = theme.get("title", Color(1, 0.9, 0.6))
	title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	title.add_theme_constant_override("outline_size", 1)
	shop.add_child(title)

func _add_resources(shop: Control, config: Dictionary) -> void:
	var gold_label := Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "💰 %d" % int(game_state.player_gold)
	gold_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	gold_label.offset_left = 20
	gold_label.offset_top = 15
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_label.modulate = Color(1, 0.85, 0.4)
	shop.add_child(gold_label)

func _add_shop_items(shop: Control, config: Dictionary) -> void:
	var shop_items: Array = _dedupe_shop_items(config.get("shop_items", []))

	var shop_title := Label.new()
	shop_title.text = "今日特供"
	shop_title.position = Vector2(490, 80)
	shop_title.add_theme_font_size_override("font_size", 22)
	shop_title.modulate = theme.get("title", Color(0.9, 0.86, 0.72))
	shop_title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	shop_title.add_theme_constant_override("outline_size", 1)
	shop.add_child(shop_title)

	var notice_label := Label.new()
	notice_label.name = "ShopNotice"
	notice_label.text = ""
	notice_label.position = Vector2(360, 48)
	notice_label.custom_minimum_size = Vector2(560, 28)
	notice_label.add_theme_font_size_override("font_size", 16)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.modulate = theme.get("title", Color(0.95, 0.86, 0.68))
	shop.add_child(notice_label)

	var icon_factory: Callable = config.get("item_icon_factory", Callable())
	var buy_item_callback: Callable = config.get("buy_item_callback", Callable())
	var start_x := 190
	var spacing := 300

	for i in range(shop_items.size()):
		var item_id := str(shop_items[i])
		if not game_state.ITEMS.has(item_id):
			continue
		var item: Dictionary = game_state.ITEMS[item_id]
		var btn := _create_shop_item_button(item_id, item, icon_factory)
		btn.position = Vector2(start_x + i * spacing, 118)
		if buy_item_callback.is_valid():
			btn.pressed.connect(func(id := item_id): buy_item_callback.call(id, shop))
		shop.add_child(btn)

	if shop_items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "商店已售罄！"
		empty_label.position = Vector2(540, 200)
		empty_label.add_theme_font_size_override("font_size", 24)
		empty_label.modulate = Color(0.5, 0.5, 0.4)
		shop.add_child(empty_label)

func _create_shop_item_button(item_id: String, item: Dictionary, icon_factory: Callable) -> Button:
	var btn := Button.new()
	btn.name = "ShopItem_%s" % item_id
	btn.custom_minimum_size = Vector2(252, 172)
	btn.add_theme_font_size_override("font_size", 14)
	btn.clip_contents = true
	if icon_factory.is_valid():
		btn.icon = icon_factory.call(item)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var price := shop_flow.get_item_price(item)
	var can_afford := int(game_state.player_gold) >= price
	var has_room: bool = game_state.backpack.size() < game_state.get_current_backpack_limit()
	var can_buy: bool = can_afford and has_room

	var item_style := _create_shop_item_style(item, can_buy)
	var item_hover: StyleBoxFlat = item_style.duplicate()
	item_hover.bg_color = item_style.bg_color.lightened(0.08) if can_buy else item_style.bg_color
	item_hover.border_color = item_style.border_color.lightened(0.12) if can_buy else item_style.border_color
	btn.add_theme_stylebox_override("normal", item_style)
	btn.add_theme_stylebox_override("hover", item_hover)
	btn.add_theme_stylebox_override("pressed", item_style)
	btn.add_theme_stylebox_override("focus", item_hover)
	btn.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	btn.add_theme_constant_override("outline_size", 1)

	var rarity := str(item.get("rarity", "white"))
	match rarity:
		"blue":
			btn.modulate = Color(0.66, 0.76, 1.0) if can_buy else Color(0.44, 0.46, 0.56)
		"red":
			btn.modulate = Color(1.0, 0.66, 0.56) if can_buy else Color(0.56, 0.42, 0.40)
		_:
			btn.modulate = Color(0.92, 0.90, 0.82) if can_buy else Color(0.48, 0.48, 0.46)

	var rarity_text := "⚪"
	match rarity:
		"blue":
			rarity_text = "🔵"
		"red":
			rarity_text = "🔴"

	var price_text := "💰%d" % price
	if float(game_state.shop_discount) < 1.0:
		price_text += " (原价%d)" % int(item.get("cost", 0))

	var display_name := str(game_state.get_item_display_name(item))
	var display_desc := _get_shop_item_card_line(item)
	btn.tooltip_text = _get_shop_item_tooltip(item, price, can_afford, has_room)
	btn.text = ""
	btn.icon = null
	_add_shop_item_button_content(btn, item, rarity_text, display_name, price_text, display_desc, icon_factory, can_buy)
	if not can_buy:
		btn.disabled = true
		var locked := Label.new()
		locked.text = "金币不足" if not can_afford else "背包已满"
		locked.position = Vector2(76, 142)
		locked.custom_minimum_size = Vector2(100, 20)
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked.add_theme_font_size_override("font_size", 14)
		locked.modulate = Color(1.0, 0.46, 0.38, 1.0)
		btn.add_child(locked)
	return btn

func _get_shop_item_tooltip(item: Dictionary, price: int, can_afford: bool, has_room: bool) -> String:
	var lines: Array[String] = []
	lines.append("%s｜%s" % [game_state.get_item_display_name(item), _get_item_shop_role_tag(item)])
	lines.append("价格：%d金币｜%s" % [price, _get_shop_item_buy_state_from_flags(price, can_afford, has_room)])
	var attribute_line := _get_item_attribute_line(item)
	if attribute_line != "":
		lines.append("属性：%s" % attribute_line)
	lines.append("详情：%s" % game_state.get_item_display_description(item))
	lines.append(_get_item_shop_impact_line(item))
	return "\n".join(lines)

func _get_shop_item_buy_state_from_flags(price: int, can_afford: bool, has_room: bool) -> String:
	if not has_room:
		return "背包已满"
	if not can_afford:
		return "还差%d金" % maxi(price - int(game_state.player_gold), 0)
	if game_state.equipment_slot.size() < game_state.get_current_equipment_slot_limit():
		return "购买后可直接装备"
	return "购买后进入背包"

func _get_item_buy_state_text(item: Dictionary) -> String:
	var price := shop_flow.get_item_price(item)
	if game_state.backpack.size() >= game_state.get_current_backpack_limit():
		return "背包已满"
	if int(game_state.player_gold) < price:
		return "还差%d金" % (price - int(game_state.player_gold))
	if game_state.equipment_slot.size() < game_state.get_current_equipment_slot_limit():
		return "入手即生效"
	return "先入背包"

func _dedupe_shop_items(shop_items: Array) -> Array[String]:
	var unique_items: Array[String] = []
	for item_id_value in shop_items:
		var item_id := str(item_id_value)
		if item_id == "" or item_id in unique_items:
			continue
		unique_items.append(item_id)
	return unique_items

func _create_shop_item_style(item: Dictionary, can_buy: bool) -> StyleBoxFlat:
	var style := _create_panel_style(14, -0.04)
	var rarity := str(item.get("rarity", "white"))
	if can_buy:
		style.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94)).lightened(0.06)
		match rarity:
			"red":
				style.border_color = Color(1.0, 0.52, 0.38, 1.0)
			"blue":
				style.border_color = Color(0.48, 0.70, 1.0, 1.0)
			_:
				style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0)).lightened(0.12)
		style.set_border_width_all(3)
	else:
		style.bg_color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94)).darkened(0.22)
		style.border_color = Color(0.30, 0.30, 0.32, 1.0)
		style.set_border_width_all(1)
	return style

func _add_shop_item_button_content(btn: Button, item: Dictionary, rarity_text: String, display_name: String, price_text: String, display_desc: String, icon_factory: Callable, can_buy: bool) -> void:
	var frame_texture := _load_registry_texture("get_reference_ui_path", "card")
	if frame_texture != null:
		var frame := TextureRect.new()
		frame.name = "CardFrame"
		frame.texture = frame_texture
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.modulate = Color(1, 1, 1, 0.90) if can_buy else Color(0.55, 0.55, 0.55, 0.58)
		btn.add_child(frame)

	var icon_texture: Texture2D = null
	if icon_factory.is_valid():
		icon_texture = icon_factory.call(item)
	if icon_texture == null:
		icon_texture = _load_item_icon_from_registry(item)
	if icon_texture != null:
		var icon_rect := TextureRect.new()
		icon_rect.name = "ItemIcon"
		icon_rect.texture = icon_texture
		icon_rect.position = Vector2(94, 16)
		icon_rect.custom_minimum_size = Vector2(64, 58)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.modulate = Color(1, 1, 1, 1) if can_buy else Color(0.62, 0.62, 0.62, 0.82)
		btn.add_child(icon_rect)

	var name_label := Label.new()
	name_label.text = "%s %s" % [rarity_text, display_name]
	name_label.position = Vector2(14, 78)
	name_label.custom_minimum_size = Vector2(224, 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	name_label.add_theme_constant_override("outline_size", 1)
	name_label.modulate = theme.get("title", Color(0.96, 0.88, 0.68, 1.0)) if can_buy else Color(0.58, 0.58, 0.56)
	btn.add_child(name_label)

	var price_label := Label.new()
	price_label.text = price_text
	price_label.position = Vector2(58, 106)
	price_label.custom_minimum_size = Vector2(136, 22)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 15)
	price_label.modulate = Color(1.0, 0.84, 0.36, 1.0) if can_buy else Color(0.62, 0.54, 0.38, 0.92)
	btn.add_child(price_label)

	var state_label := Label.new()
	state_label.text = _get_item_shop_whisper(item)
	state_label.position = Vector2(14, 8)
	state_label.custom_minimum_size = Vector2(224, 18)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 12)
	state_label.modulate = Color(0.58, 1.0, 0.48, 1.0) if can_buy else Color(0.66, 0.66, 0.62, 0.88)
	btn.add_child(state_label)

	var desc_label := Label.new()
	desc_label.name = "ItemAttributeLine"
	desc_label.text = display_desc
	desc_label.position = Vector2(18, 130)
	desc_label.custom_minimum_size = Vector2(216, 32)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = theme.get("title", Color(0.84, 0.82, 0.74, 1.0)).darkened(0.04) if can_buy else Color(0.50, 0.50, 0.48)
	btn.add_child(desc_label)

func _get_shop_item_card_line(item: Dictionary) -> String:
	var attribute_line := _get_item_attribute_line(item)
	var role_tag := _get_item_shop_role_tag(item).replace("取向：", "")
	if attribute_line != "":
		return "属性：%s｜%s" % [attribute_line, role_tag]
	return "%s｜%s" % [_get_item_shop_impact_keyword(item), role_tag]

func _get_item_attribute_line(item: Dictionary) -> String:
	var item_id := str(item.get("id", ""))
	var desc := str(game_state.get_item_display_description(item))
	var base_desc := str(item.get("description", ""))
	var direct_parts: Array[String] = []
	for keyword in ["攻击", "伤害", "护甲", "护盾", "命数", "暴击", "吸血", "中毒", "机括", "金币", "恢复"]:
		var extracted := _extract_effect_phrase(base_desc, keyword)
		if extracted != "" and not extracted in direct_parts:
			direct_parts.append(extracted)
	if not direct_parts.is_empty():
		return " / ".join(direct_parts.slice(0, 2))
	match item_id:
		"long_sword", "demon_blade", "bounty_blade", "regicide":
			return "攻击收益"
		"wooden_shield", "heart_mirror", "tiger_tally":
			return "护甲收益"
		"life_crystal", "vampire_cross", "blood_tyrant":
			return "命数/续航"
		"trade_ledger", "greedy_gloves", "broken_coin":
			return "金币收益"
		"precision_guidance", "precision_auxiliary", "precision_calculation", "ai_system":
			return "机括收益"
		"unity_seal", "camp_banner":
			return "连动收益"
	if desc.contains("护甲") or desc.contains("护盾"):
		return "护甲收益"
	if desc.contains("恢复") or desc.contains("命数"):
		return "命数/恢复"
	if desc.contains("金币"):
		return "金币收益"
	if desc.contains("暴击") or desc.contains("攻击") or desc.contains("伤害"):
		return "攻击收益"
	return ""

func _extract_effect_phrase(text: String, keyword: String) -> String:
	var index := text.find(keyword)
	if index < 0:
		return ""
	var end := text.find("，", index)
	if end < 0:
		end = text.find("。", index)
	if end < 0:
		end = text.find("；", index)
	if end < 0:
		end = text.length()
	return text.substr(index, end - index).strip_edges()

func _get_item_shop_impact_keyword(item: Dictionary) -> String:
	var role := _get_item_shop_role_tag(item)
	match role:
		"取向：抢攻":
			return "压血线"
		"取向：稳住":
			return "补容错"
		"取向：续航":
			return "保命线"
		"取向：经营":
			return "滚资源"
		"取向：留后手":
			return "留操作"
		"取向：连动":
			return "放大触发"
	return "补短板"

func _get_item_shop_whisper(item: Dictionary) -> String:
	var rarity := str(item.get("rarity", "white"))
	match rarity:
		"red":
			return "稀世"
		"blue":
			return "良器"
	return "器物"

func _get_item_shop_role_tag(item: Dictionary) -> String:
	var item_id := str(item.get("id", ""))
	var desc := str(game_state.get_item_display_description(item))
	if item_id in ["long_sword", "demon_blade", "bounty_blade", "regicide"] or desc.contains("攻击") or desc.contains("伤害"):
		return "取向：抢攻"
	if item_id in ["wooden_shield", "heart_mirror", "tiger_tally", "counter_sigil"] or desc.contains("护甲") or desc.contains("护盾"):
		return "取向：稳住"
	if item_id in ["life_crystal", "vampire_cross", "blood_tyrant", "afterlife_lamp"] or desc.contains("恢复") or desc.contains("命数"):
		return "取向：续航"
	if item_id in ["trade_ledger", "greedy_gloves", "broken_coin"] or desc.contains("金币"):
		return "取向：经营"
	if item_id in ["precision_guidance", "precision_auxiliary", "precision_calculation", "ai_system", "unity_seal"]:
		return "取向：留后手"
	if item_id in ["camp_banner"]:
		return "取向：连动"
	return "取向：补位"

func _get_item_shop_impact_line(item: Dictionary) -> String:
	var role := _get_item_shop_role_tag(item)
	match role:
		"取向：抢攻":
			return "适合想尽快压低敌人血线。"
		"取向：稳住":
			return "适合敌人压力变大时补容错。"
		"取向：续航":
			return "适合命线吃紧但还想拖后半程。"
		"取向：经营":
			return "适合把这局资源滚起来。"
		"取向：留后手":
			return "适合给关键回合留操作空间。"
		"取向：连动":
			return "适合让多次触发变得更值钱。"
	return "适合补当前最缺的一块。"

func _add_refresh_button(shop: Control, config: Dictionary) -> void:
	var refresh_cost := shop_flow.get_refresh_cost()
	var refresh_btn := Button.new()
	refresh_btn.name = "RefreshBtn"
	refresh_btn.text = "刷新  %d" % refresh_cost
	refresh_btn.custom_minimum_size = Vector2(160, 42)
	refresh_btn.position = Vector2(560, 340)
	refresh_btn.add_theme_font_size_override("font_size", 16)
	refresh_btn.modulate = Color(0.8, 1, 0.8)
	_apply_button_icon(refresh_btn, "refresh", false, "刷新商队")
	if int(game_state.player_gold) < refresh_cost:
		refresh_btn.disabled = true
		refresh_btn.modulate = Color(0.35, 0.35, 0.35)
		refresh_btn.text = "刷新"
		_apply_button_icon(refresh_btn, "refresh", false, "金币不足，无法刷新商队")
	var refresh_callback: Callable = config.get("refresh_callback", Callable())
	if refresh_callback.is_valid():
		refresh_btn.pressed.connect(func(): refresh_callback.call(shop))
	shop.add_child(refresh_btn)

func _add_storage_frames(shop: Control) -> void:
	var equip_title := Label.new()
	equip_title.name = "EquipTitle"
	equip_title.text = "装备  %d/%d" % [game_state.equipment_slot.size(), game_state.get_current_equipment_slot_limit()]
	equip_title.position = Vector2(50, 424)
	equip_title.add_theme_font_size_override("font_size", 15)
	equip_title.modulate = theme.get("title", Color(0.9, 0.86, 0.72))
	equip_title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	equip_title.add_theme_constant_override("outline_size", 1)
	shop.add_child(equip_title)

	var equip_frame := PanelContainer.new()
	equip_frame.position = Vector2(38, 448)
	equip_frame.custom_minimum_size = Vector2(1204, 62)
	var storage_style := _create_panel_style(12, -0.04)
	equip_frame.add_theme_stylebox_override("panel", storage_style)
	shop.add_child(equip_frame)

	var backpack_title := Label.new()
	backpack_title.name = "BackpackTitle"
	backpack_title.text = "背包  %d/%d" % [game_state.backpack.size(), game_state.get_current_backpack_limit()]
	backpack_title.position = Vector2(50, 526)
	backpack_title.add_theme_font_size_override("font_size", 15)
	backpack_title.modulate = theme.get("title", Color(0.9, 0.86, 0.72))
	backpack_title.add_theme_color_override("font_outline_color", theme.get("bg", Color(0.12, 0.12, 0.18, 1.0)).darkened(0.2))
	backpack_title.add_theme_constant_override("outline_size", 1)
	shop.add_child(backpack_title)

	var backpack_frame := PanelContainer.new()
	backpack_frame.position = Vector2(38, 550)
	backpack_frame.custom_minimum_size = Vector2(1204, 74)
	backpack_frame.add_theme_stylebox_override("panel", storage_style)
	shop.add_child(backpack_frame)

func _add_navigation(shop: Control, config: Dictionary) -> void:
	var btn_y := 662
	var back_btn := Button.new()
	back_btn.name = "BackBtn"
	back_btn.text = "← 返回地图"
	back_btn.custom_minimum_size = Vector2(140, 50)
	back_btn.position = Vector2(200, btn_y)
	back_btn.add_theme_font_size_override("font_size", 16)
	_apply_button_icon(back_btn, "back", false, "返回地图")
	var back_callback: Callable = config.get("back_callback", Callable())
	if back_callback.is_valid():
		back_btn.pressed.connect(func(): back_callback.call())
	shop.add_child(back_btn)

	var next_btn := Button.new()
	next_btn.name = "NextBtn"
	next_btn.text = "下一层 →"
	next_btn.custom_minimum_size = Vector2(140, 50)
	next_btn.position = Vector2(940, btn_y)
	next_btn.add_theme_font_size_override("font_size", 16)
	next_btn.modulate = Color(0.8, 1, 0.8)
	_apply_button_icon(next_btn, "next", false, "进入下一层")
	var next_callback: Callable = config.get("next_callback", Callable())
	if next_callback.is_valid():
		next_btn.pressed.connect(func(): next_callback.call())
	shop.add_child(next_btn)

func _create_panel_style(radius: int, darken_amount: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var panel_color: Color = theme.get("panel", Color(0.18, 0.18, 0.22, 0.94))
	style.bg_color = panel_color.lightened(darken_amount) if darken_amount > 0.0 else panel_color.darkened(absf(darken_amount))
	style.border_color = theme.get("accent", Color(0.84, 0.68, 0.38, 1.0))
	style.set_border_width_all(2)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
