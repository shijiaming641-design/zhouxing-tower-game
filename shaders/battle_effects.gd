extends Node2D
## 战斗特效系统 - 为猜拳战斗添加视觉反馈
## 
## 使用方法：
## 1. 将此脚本挂载为 battle_scene 的子节点
## 2. 调用 show_hit_effect(position) 显示命中特效
## 3. 调用 show_damage_number(position, value) 显示伤害数字
## 4. 调用 trigger_screen_shake() 触发屏幕震动

const MOVE_SYMBOLS = ["○", "△", "□"]
const MOVE_COLORS = {
	0: Color("#FFD700"),  # 圆 - 金色
	1: Color("#00CED1"),  # 三角 - 青色
	2: Color("#FF69B4"),  # 方 - 粉色
}

# 命中特效节点
var hit_particles: GPUParticles2D
# 伤害数字节点池
var damage_label_scene: PackedScene
var active_damage_labels: Array = []

func _ready() -> void:
	_setup_hit_effects()

func _setup_hit_effects() -> void:
	# 创建命中粒子效果
	hit_particles = GPUParticles2D.new()
	hit_particles.amount = 30
	hit_particles.lifetime = 0.5
	hit_particles.explosiveness = 0.8
	hit_particles.randomness = 0.5
	hit_particles.local_coords = true
	hit_particles.visibility_rect = Rect2(-50, -50, 100, 100)
	
	var spread = CylinderShape2D.new()
	spread.radius = 30.0
	spread.height = 5.0
	
	var collision = CollisionShape2D.new()
	collision.shape = spread
	
	# 粒子材质
	var particle_mat = ParticleProcessMaterial.new()
	particle_mat.direction = Vector3(0, -1, 0)
	particle_mat.spread = 180.0
	particle_mat.initial_velocity_min = 100.0
	particle_mat.initial_velocity_max = 200.0
	particle_mat.gravity = Vector3(0, 400, 0)
	particle_mat.scale_min = 2.0
	particle_mat.scale_max = 6.0
	particle_mat.color = Color.WHITE
	
	hit_particles.process_material = particle_mat
	hit_particles.add_child(collision)
	hit_particles.one_shot = true
	hit_particles.emitting = false
	hit_particles.visible = false
	
	add_child(hit_particles)

func show_hit_effect(global_pos: Vector2) -> void:
	"""在指定位置显示命中粒子效果"""
	hit_particles.position = global_pos
	hit_particles.visible = true
	hit_particles.emitting = true
	
	# 0.6秒后隐藏
	await get_tree().create_timer(0.6).timeout
	hit_particles.emitting = false
	hit_particles.visible = false

func show_damage_number(global_pos: Vector2, damage: int, is_player_damage: bool = true) -> void:
	"""显示飘字伤害数字"""
	var label = Label.new()
	label.text = "-" + str(damage)
	label.global_position = global_pos + Vector2(randf_range(-20, 20), -30)
	label.modulate = Color.RED if is_player_damage else Color.GREEN
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", global_pos.y - 80, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	
	add_child(label)
	
	# 动画结束后删除
	await get_tree().create_timer(0.8).timeout
	label.queue_free()

func show_win_effect(global_pos: Vector2, move_type: int) -> void:
	"""显示胜利特效（玩家出招克制时）"""
	show_hit_effect(global_pos)
	
	# 创建大型发光符号
	var symbol = Label.new()
	symbol.text = MOVE_SYMBOLS[move_type]
	symbol.global_position = global_pos
	symbol.modulate = MOVE_COLORS.get(move_type, Color.WHITE)
	symbol.add_theme_font_size_override("font_size", 72)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(symbol, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(symbol, "modulate:a", 0.0, 0.5)
	
	add_child(symbol)
	await get_tree().create_timer(0.5).timeout
	symbol.queue_free()

func trigger_screen_shake(amplitude: float = 8.0) -> void:
	"""触发父节点的屏幕震动（需要父节点有对应实现）"""
	if has_node("../ScreenShake"):
		($("../ScreenShake") as Node).trigger_shake(amplitude, 0.3)
	else:
		# 备选：直接震动当前节点
		var orig_pos = position
		var tween = create_tween()
		for i in range(6):
			var offset = Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude))
			tween.tween_property(self, "position", orig_pos + offset, 0.05)
		tween.tween_property(self, "position", orig_pos, 0.05)
