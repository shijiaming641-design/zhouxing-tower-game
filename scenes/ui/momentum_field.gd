class_name MomentumField
extends Control

var field_theme: Dictionary = {}
var player_domain := 0.48
var enemy_domain := 0.48
var center_bias := 0.0
var player_ring := 0.35
var enemy_ring := 0.35
var pulse := 0.0
var pulse_side := 0
var crack_strength := 0.0
var mark_type := ""
var mark_alpha := 0.0
var intent_type := ""
var intent_alpha := 0.0
var time_passed := 0.0
var focus_side := "duel"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func setup(era_theme: Dictionary, side: String = "duel") -> void:
	field_theme = era_theme
	focus_side = side
	queue_redraw()

func refresh_state(state: Dictionary) -> void:
	var player_hp_ratio := float(state.get("player_hp_ratio", 1.0))
	var enemy_hp_ratio := float(state.get("enemy_hp_ratio", 1.0))
	var shield := int(state.get("shield", 0))
	var pending_force := int(state.get("pending_force", 0))
	var enemy_pressure := float(1.0 - enemy_hp_ratio)
	var player_pressure := float(1.0 - player_hp_ratio)
	player_ring = clamp(0.26 + float(shield) * 0.035 + float(pending_force) * 0.018 + enemy_pressure * 0.16, 0.24, 0.88)
	enemy_ring = clamp(0.28 + player_pressure * 0.22 + enemy_hp_ratio * 0.08, 0.22, 0.78)
	player_domain = lerpf(player_domain, clamp(0.42 + player_ring * 0.16 - player_pressure * 0.08, 0.30, 0.68), 0.34)
	enemy_domain = lerpf(enemy_domain, clamp(0.42 + enemy_ring * 0.13 - enemy_pressure * 0.06, 0.30, 0.68), 0.34)
	queue_redraw()

func show_reveal(player_move: int, enemy_move: int) -> void:
	pulse = 0.56
	pulse_side = 0
	crack_strength = 0.22 if player_move == enemy_move else 0.12
	mark_type = "reveal"
	mark_alpha = 0.46
	queue_redraw()

func show_outcome(player_wins: bool, is_draw: bool, impact: Dictionary = {}) -> void:
	if is_draw:
		center_bias = lerpf(center_bias, 0.0, 0.55)
		crack_strength = 0.74
		pulse_side = 0
		mark_type = "draw"
	elif player_wins:
		center_bias = clamp(center_bias + 0.14 + float(impact.get("damage", 0)) * 0.012, -0.42, 0.42)
		player_domain = clamp(player_domain + 0.06, 0.28, 0.74)
		enemy_domain = clamp(enemy_domain - 0.03, 0.24, 0.70)
		crack_strength = 0.34
		pulse_side = 1
		mark_type = "player_win"
	else:
		center_bias = clamp(center_bias - 0.14 - float(impact.get("actual_damage", 0)) * 0.018, -0.42, 0.42)
		enemy_domain = clamp(enemy_domain + 0.06, 0.28, 0.74)
		player_domain = clamp(player_domain - 0.03, 0.24, 0.70)
		crack_strength = 0.42
		pulse_side = -1
		mark_type = "enemy_win"
	pulse = 0.88
	mark_alpha = 0.86
	queue_redraw()

func show_trigger(trigger_id: String) -> void:
	mark_type = trigger_id
	mark_alpha = 0.96
	pulse = maxf(pulse, 0.72)
	match trigger_id:
		"shield_blade", "afterlife_lamp", "counter_sigil":
			pulse_side = 1
			player_domain = clamp(player_domain + 0.05, 0.28, 0.76)
		"broken_coin", "blood_contract", "camp_banner":
			pulse_side = 1
			center_bias = clamp(center_bias + 0.06, -0.42, 0.42)
		_:
			pulse_side = 0
	queue_redraw()

func show_enemy_intent(intent_id: String) -> void:
	intent_type = intent_id
	intent_alpha = 0.62
	match intent_id:
		"attack":
			enemy_domain = clamp(enemy_domain + 0.05, 0.28, 0.76)
			pulse_side = -1
		"guard":
			enemy_ring = clamp(enemy_ring + 0.08, 0.22, 0.86)
			pulse_side = -1
		"read":
			crack_strength = maxf(crack_strength, 0.20)
			pulse_side = 0
		"boss":
			enemy_domain = clamp(enemy_domain + 0.08, 0.30, 0.80)
			center_bias = clamp(center_bias - 0.05, -0.42, 0.42)
			pulse_side = -1
		_:
			pulse_side = 0
	pulse = maxf(pulse, 0.30)
	queue_redraw()

func _process(delta: float) -> void:
	time_passed += delta
	if pulse > 0.0:
		pulse = maxf(0.0, pulse - delta * 1.45)
	if mark_alpha > 0.0:
		mark_alpha = maxf(0.0, mark_alpha - delta * 0.72)
	if crack_strength > 0.0:
		crack_strength = maxf(0.0, crack_strength - delta * 0.52)
	if intent_alpha > 0.0:
		intent_alpha = maxf(0.0, intent_alpha - delta * 0.34)
	center_bias = lerpf(center_bias, 0.0, delta * 0.22)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var player_color: Color = field_theme.get("good", Color(0.38, 0.82, 0.62, 1.0))
	var enemy_color: Color = field_theme.get("bad", Color(0.92, 0.34, 0.28, 1.0))
	var accent: Color = field_theme.get("accent", Color(0.86, 0.68, 0.36, 1.0))
	var panel: Color = field_theme.get("panel", Color(0.08, 0.08, 0.10, 1.0))
	draw_rect(rect, _with_alpha(panel, 0.08), true)
	if focus_side in ["duel", "enemy"]:
		_draw_domain(false, enemy_color)
	if focus_side in ["duel", "player"]:
		_draw_domain(true, player_color)
	if focus_side == "duel":
		_draw_boundary(accent, player_color, enemy_color)
	_draw_rings(player_color, enemy_color, accent)
	if focus_side in ["duel", "enemy"]:
		_draw_enemy_intent(accent, enemy_color)
	_draw_trigger_mark(accent, player_color, enemy_color)

func _draw_domain(is_player: bool, base_color: Color) -> void:
	var w := size.x
	var h := size.y
	var center_x := w * (0.5 + center_bias * 0.28)
	var thickness := player_domain if is_player else enemy_domain
	var reach := w * (0.18 + thickness * 0.30)
	var points := PackedVector2Array()
	if is_player:
		points.append(Vector2(0, h * 0.12))
		for i in range(8):
			var y := h * (0.12 + float(i) / 7.0 * 0.76)
			var wave := sin(time_passed * 1.4 + float(i) * 0.82) * 10.0
			points.append(Vector2(center_x - w * 0.08 + reach * 0.45 + wave, y))
		points.append(Vector2(0, h * 0.88))
	else:
		points.append(Vector2(w, h * 0.12))
		for i in range(8):
			var y := h * (0.12 + float(i) / 7.0 * 0.76)
			var wave := cos(time_passed * 1.2 + float(i) * 0.76) * 10.0
			points.append(Vector2(center_x + w * 0.08 - reach * 0.45 + wave, y))
		points.append(Vector2(w, h * 0.88))
	draw_colored_polygon(points, _with_alpha(base_color, 0.11 + thickness * 0.10))
	var side_center := Vector2(w * 0.24, h * 0.54) if is_player else Vector2(w * 0.76, h * 0.46)
	for i in range(5):
		var offset := Vector2(cos(time_passed * 0.8 + i) * 24.0, sin(time_passed * 0.7 + i * 1.7) * 18.0)
		var radius := 34.0 + float(i) * 13.0 + thickness * 16.0
		draw_circle(side_center + offset, radius, _with_alpha(base_color, 0.018 + thickness * 0.018))

func _draw_boundary(accent: Color, player_color: Color, enemy_color: Color) -> void:
	var w := size.x
	var h := size.y
	var center_x := w * (0.5 + center_bias * 0.28)
	var last := Vector2(center_x, h * 0.16)
	for i in range(1, 18):
		var t := float(i) / 17.0
		var y := h * (0.16 + t * 0.68)
		var x := center_x + sin(time_passed * 1.8 + t * 8.0) * (7.0 + crack_strength * 14.0)
		var color := accent.lerp(player_color if center_bias > 0.03 else enemy_color if center_bias < -0.03 else accent, 0.34)
		draw_line(last, Vector2(x, y), _with_alpha(color, 0.32 + crack_strength * 0.30), 2.0 + crack_strength * 2.0, true)
		last = Vector2(x, y)
	if crack_strength > 0.0:
		for i in range(5):
			var y2 := h * (0.24 + float(i) * 0.12)
			var dir := -1.0 if i % 2 == 0 else 1.0
			var start := Vector2(center_x, y2)
			var end := start + Vector2(dir * (18.0 + crack_strength * 28.0), 10.0)
			draw_line(start, end, _with_alpha(accent, crack_strength * 0.40), 1.4, true)

func _draw_rings(player_color: Color, enemy_color: Color, accent: Color) -> void:
	var h := size.y
	var player_center := Vector2(size.x * 0.18, h * 0.56)
	var enemy_center := Vector2(size.x * 0.82, h * 0.44)
	if focus_side == "player":
		player_center = Vector2(size.x * 0.50, h * 0.58)
	elif focus_side == "enemy":
		enemy_center = Vector2(size.x * 0.50, h * 0.42)
	var pulse_bonus := pulse * 12.0
	if focus_side in ["duel", "player"]:
		draw_arc(player_center, 42.0 + player_ring * 38.0 + (pulse_bonus if pulse_side >= 0 else 0.0), -1.1, 1.1, 34, _with_alpha(player_color, 0.32 + player_ring * 0.28), 3.0, true)
		draw_arc(player_center, 58.0 + player_ring * 44.0, -0.72, 0.72, 28, _with_alpha(accent, 0.12 + player_ring * 0.12), 1.6, true)
	if focus_side in ["duel", "enemy"]:
		draw_arc(enemy_center, 42.0 + enemy_ring * 36.0 + (pulse_bonus if pulse_side <= 0 else 0.0), PI - 1.1, PI + 1.1, 34, _with_alpha(enemy_color, 0.30 + enemy_ring * 0.24), 3.0, true)
		draw_arc(enemy_center, 58.0 + enemy_ring * 42.0, PI - 0.72, PI + 0.72, 28, _with_alpha(accent, 0.10 + enemy_ring * 0.10), 1.6, true)

func _draw_enemy_intent(accent: Color, enemy_color: Color) -> void:
	if intent_alpha <= 0.0:
		return
	var center := Vector2(size.x * 0.78, size.y * 0.28)
	var color := _with_alpha(enemy_color, intent_alpha)
	match intent_type:
		"attack":
			var tip := center + Vector2(-52.0 - pulse * 18.0, 18)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(28, -12),
				tip,
				center + Vector2(28, 34)
			]), _with_alpha(enemy_color, intent_alpha * 0.22))
			draw_line(center + Vector2(30, 10), tip, color, 3.0, true)
		"guard":
			draw_arc(center, 34.0 + pulse * 10.0, PI * 0.35, PI * 1.65, 36, color, 3.0, true)
			draw_arc(center + Vector2(10, 0), 47.0, PI * 0.42, PI * 1.58, 36, _with_alpha(accent, intent_alpha * 0.34), 1.8, true)
		"read":
			draw_arc(center, 34.0, -0.18, PI + 0.18, 42, _with_alpha(accent, intent_alpha * 0.56), 2.2, true)
			draw_circle(center, 6.0 + sin(time_passed * 5.0) * 1.5, _with_alpha(accent, intent_alpha * 0.42))
		"boss":
			for i in range(3):
				var r := 28.0 + float(i) * 14.0 + pulse * 8.0
				draw_arc(center, r, PI * 0.18, PI * 1.82, 48, _with_alpha(enemy_color.lerp(accent, 0.35), intent_alpha * (0.46 - i * 0.10)), 2.2, true)
		_:
			draw_circle(center, 16.0 + pulse * 12.0, _with_alpha(enemy_color, intent_alpha * 0.16))

func _draw_trigger_mark(accent: Color, player_color: Color, enemy_color: Color) -> void:
	if mark_alpha <= 0.0:
		return
	var center := Vector2(size.x * (0.5 + center_bias * 0.28), size.y * 0.50)
	if focus_side == "player":
		center = Vector2(size.x * 0.50, size.y * 0.54)
	elif focus_side == "enemy":
		center = Vector2(size.x * 0.50, size.y * 0.46)
	var color := _with_alpha(accent, mark_alpha)
	match mark_type:
		"shield_blade":
			_draw_shield_mark(center + Vector2(-18, 0), _with_alpha(player_color, mark_alpha))
			draw_line(center + Vector2(-2, 18), center + Vector2(58, -18), _with_alpha(accent, mark_alpha * 0.86), 4.0, true)
		"afterlife_lamp":
			draw_circle(center + Vector2(-26, -4), 16.0, _with_alpha(player_color, mark_alpha * 0.34))
			draw_line(center + Vector2(-26, -22), center + Vector2(-26, 28), _with_alpha(accent, mark_alpha * 0.72), 2.0, true)
		"broken_coin":
			draw_circle(center, 24.0, _with_alpha(accent, mark_alpha * 0.26))
			draw_arc(center, 18.0, 0.0, TAU, 42, color, 3.0, true)
			draw_line(center + Vector2(-12, 0), center + Vector2(12, 0), color, 2.2, true)
		"blood_contract":
			draw_line(center + Vector2(-38, -18), center + Vector2(30, 16), _with_alpha(Color(0.95, 0.12, 0.10), mark_alpha), 4.2, true)
			draw_circle(center + Vector2(-42, -20), 8.0, _with_alpha(Color(0.95, 0.12, 0.10), mark_alpha * 0.52))
		"counter_sigil", "draw":
			draw_rect(Rect2(center - Vector2(23, 23), Vector2(46, 46)), _with_alpha(accent, mark_alpha * 0.24), false, 3.0)
			draw_line(center + Vector2(-30, 0), center + Vector2(30, 0), color, 3.0, true)
		"camp_banner":
			draw_line(center + Vector2(-26, 28), center + Vector2(-26, -28), color, 2.6, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-24, -28), center + Vector2(28, -18), center + Vector2(-24, -6)]), _with_alpha(accent, mark_alpha * 0.44))
			draw_line(center + Vector2(10, -12), center + Vector2(62, -10), _with_alpha(accent, mark_alpha * 0.62), 2.6, true)
		"enemy_win":
			draw_line(center + Vector2(44, -10), center + Vector2(-40, 18), _with_alpha(enemy_color, mark_alpha * 0.82), 4.0, true)
		"player_win":
			draw_line(center + Vector2(-44, 14), center + Vector2(44, -18), _with_alpha(player_color, mark_alpha * 0.82), 4.0, true)
		_:
			draw_circle(center, 18.0 + pulse * 18.0, _with_alpha(accent, mark_alpha * 0.16))

func _draw_shield_mark(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -26),
		center + Vector2(24, -14),
		center + Vector2(18, 18),
		center + Vector2(0, 30),
		center + Vector2(-18, 18),
		center + Vector2(-24, -14),
	])
	draw_colored_polygon(points, _with_alpha(color, color.a * 0.36))
	for i in range(points.size()):
		draw_line(points[i], points[(i + 1) % points.size()], color, 2.0, true)

func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clamp(alpha, 0.0, 1.0))
