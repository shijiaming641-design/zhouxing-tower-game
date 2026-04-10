extends CanvasLayer
## 全局后处理效果层 - 添加暗角和颜色校正
## 挂载在主场景上，自动应用于所有canvas_item渲染

var material_overlay: ColorRect

func _ready() -> void:
	# 创建后处理覆盖层
	material_overlay = ColorRect.new()
	material_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	material_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	material_overlay.color = Color.TRANSPARENT
	
	var shader_material = ShaderMaterial.new()
	var shader = load("res://shaders/vignette.gdshader")
	if shader:
		shader_material.shader = shader
		shader_material.set_shader_parameter("vignette_strength", 0.4)
		shader_material.set_shader_parameter("vignette_radius", 0.7)
		shader_material.set_shader_parameter("scene_brightness", 1.0)
		shader_material.set_shader_parameter("scene_saturation", 1.0)
	material_overlay.material = shader_material
	
	add_child(material_overlay)

func set_scene_tone(tone: String) -> void:
	"""根据场景类型调整色调"""
	if not material_overlay.material:
		return
	var params = material_overlay.material as ShaderMaterial
	
	match tone:
		"battle":
			# 战斗：略微偏冷，增加对比度
			params.set_shader_parameter("scene_brightness", 0.95)
			params.set_shader_parameter("scene_saturation", 1.1)
			params.set_shader_parameter("vignette_strength", 0.5)
		"shop":
			# 商店：温暖色调
			params.set_shader_parameter("scene_brightness", 1.05)
			params.set_shader_parameter("scene_saturation", 0.9)
			params.set_shader_parameter("vignette_strength", 0.3)
		"event":
			# 事件：柔和暖色
			params.set_shader_parameter("scene_brightness", 1.1)
			params.set_shader_parameter("scene_saturation", 0.85)
			params.set_shader_parameter("vignette_strength", 0.2)
		"map":
			# 地图：中性偏暗
			params.set_shader_parameter("scene_brightness", 0.9)
			params.set_shader_parameter("scene_saturation", 1.0)
			params.set_shader_parameter("vignette_strength", 0.35)
		_:
			# 默认
			params.set_shader_parameter("scene_brightness", 1.0)
			params.set_shader_parameter("scene_saturation", 1.0)
			params.set_shader_parameter("vignette_strength", 0.3)
