extends Node2D
## 屏幕震动效果控制器
## 使用方法：在battle_scene.gd中添加子节点，连接shake_signal

signal shake_signal(amplitude: float, duration: float)

var shake_time: float = 0.0
var shake_duration: float = 0.3
var shake_amplitude: float = 10.0
var current_offset: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if shake_time > 0:
		shake_time -= delta
		# 衰减震动
		var progress = shake_time / shake_duration
		var current_amp = shake_amplitude * progress
		current_offset = Vector2(
			randf_range(-current_amp, current_amp),
			randf_range(-current_amp, current_amp)
		)
		position = current_offset
	else:
		position = Vector2.ZERO
		current_offset = Vector2.ZERO

func trigger_shake(amplitude: float = 10.0, duration: float = 0.3) -> void:
	shake_amplitude = amplitude
	shake_duration = duration
	shake_time = duration
