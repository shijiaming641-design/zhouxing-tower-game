class_name MapScene
extends Control

## 地图场景 - 爬塔地图导航（从下往上爬塔布局）

signal node_selected(node_index: int)
signal back_to_menu_pressed

const NODE_WIDTH: int = 120
const NODE_HEIGHT: int = 45
const NODE_SPACING_X: int = 10
const NODE_SPACING_Y: int = 60
const START_Y: int = 180  # 从底部开始显示
const MARGIN_X: int = 100  # 左右边距

@onready var title_label: Label = $TitleLabel
@onready var status_label: Label = $StatusLabel
@onready var map_container: Control = $ScrollContainer/MapContainer
@onready var back_button: Button = $BackButton
@onready var scroll_container: ScrollContainer = $ScrollContainer

func _ready() -> void:
	print("MapScene _ready called")
	_update_display()
	_create_tree_map()  # 爬塔布局
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	back_to_menu_pressed.emit()

func _update_display() -> void:
	# 显示当前层
	var floor_num: int = GameState.current_floor + 1
	title_label.text = "🗼 第 %d / %d 层" % [floor_num, GameState.max_floors]
	
	var class_data: Dictionary = PlayerClassData.get_class_data(GameState.player_class)
	var hp_bar: String = ""
	for i in range(GameState.player_max_hp):
		hp_bar += "❤️" if i < GameState.player_hp else "🖤"
	
	# 添加难度指示
	var difficulty_text = _get_difficulty_hint()
	status_label.text = "%s %s 💰%d %s" % [class_data.name, hp_bar, GameState.player_gold, difficulty_text]

func _get_difficulty_hint() -> String:
	"""根据当前层数返回难度提示"""
	var diff = GameState.current_floor
	match diff:
		0: return "🌱 初入地牢"
		1: return "🌿 简单"
		2: return "🌲 适中"
		3: return "🔥 困难"
		4: return "💀 凶险"
		5,6: return "😈 极难"
		7,8: return "👹 地狱"
		_: return "⚰️ 死亡"

func _create_tree_map() -> void:
	"""创建爬塔地图布局（从下往上）"""
	print("Creating tower climbing map layout...")
	print("  GameState.map_data size: ", GameState.map_data.size())
	print("  GameState.current_floor: ", GameState.current_floor)
	
	# 清除旧节点
	for child in map_container.get_children():
		child.queue_free()
	
	if GameState.map_data.is_empty():
		print("ERROR: Map data is empty!")
		return
	
	# 从下往上绘制所有层
	# floor 0 在底部（起点），floor 15 在顶部（BOSS）
	var screen_width: int = 1280
	
	# 调试：打印第一层节点状态
	if GameState.map_data.size() > 0:
		print("Floor 0 nodes:")
		for i in range(GameState.map_data[0].size()):
			var node = GameState.map_data[0][i]
			var has_accessible = node.has("accessible")
			var accessible_val = node.get("accessible")
			print("  Node ", i, ": type=", node.get("type", -1), " has_accessible=", has_accessible, " accessible=", accessible_val, " visited=", node.get("visited", "MISSING"))
	
	for floor_idx in range(GameState.map_data.size()):
		var floor_data: Array = GameState.map_data[floor_idx]
		# floor_idx = 0 在底部 (START_Y), floor_idx = 15 在顶部
		var y_pos: int = START_Y + floor_idx * NODE_SPACING_Y
		
		# 计算当前层的宽度
		var node_count: int = floor_data.size()
		var total_width: float = node_count * NODE_WIDTH + (node_count - 1) * NODE_SPACING_X
		var start_x: float = (screen_width - total_width) / 2
		
		# 绘制层级标签
		var floor_label = Label.new()
		var floor_display = floor_idx + 1
		if floor_idx == 0:
			floor_label.text = "↓ 起点"
		elif floor_idx == GameState.max_floors - 1:
			floor_label.text = "↑ 塔尖 BOSS 💀"
		else:
			floor_label.text = "层 %d" % floor_display
		floor_label.position = Vector2(20, y_pos)
		floor_label.add_theme_font_size_override("font_size", 14)
		floor_label.modulate = Color(0.6, 0.6, 0.6)
		map_container.add_child(floor_label)
		
		# 绘制该层的所有节点
		for node_idx in range(node_count):
			var node: Dictionary = floor_data[node_idx]
			var btn: Button = _create_node_button(node, node_idx, floor_idx)
			btn.position = Vector2(start_x + node_idx * (NODE_WIDTH + NODE_SPACING_X), y_pos)
			map_container.add_child(btn)
	
	# 设置容器大小以容纳所有层
	var total_height = START_Y * 2 + GameState.max_floors * NODE_SPACING_Y
	map_container.custom_minimum_size = Vector2(1280, total_height)
	
	# 滚动到当前层
	await get_tree().process_frame
	scroll_container.scroll_vertical = GameState.current_floor * NODE_SPACING_Y - 100

func _create_node_button(node: Dictionary, index: int, floor_idx: int) -> Button:
	var btn := Button.new()
	btn.name = "Node_%d_%d" % [floor_idx, index]
	
	var type_names: Array[String] = ["⚔️", "🏪", "⛺", "❓", "💀"]
	var full_names: Array[String] = ["⚔️战斗", "🏪商店", "⛺休息", "❓事件", "💀BOSS"]
	btn.text = type_names[node.type]
	btn.tooltip_text = full_names[node.type]  # 悬停显示完整名称
	btn.custom_minimum_size = Vector2(NODE_WIDTH, NODE_HEIGHT)
	
	# 样式设置
	var is_current_floor: bool = (floor_idx == GameState.current_floor)
	# 安全检查：确保 accessible 键存在，默认值为 false
	var is_accessible: bool = false
	if node.has("accessible"):
		is_accessible = bool(node.get("accessible"))
	
	if is_accessible:
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_node_clicked.bind(floor_idx, index))
		
		# 颜色设置
		btn.modulate = _get_node_color(node.type)
		
		# 当前层添加边框效果
		if is_current_floor:
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_color_override("font_pressed_color", Color.YELLOW)
		else:
			# 非当前层但可访问（上下层）
			btn.modulate = btn.modulate.darkened(0.3)
	else:
		btn.disabled = true
		if node.visited:
			btn.modulate = Color(0.2, 0.2, 0.2)  # 已访问
		else:
			btn.modulate = Color(0.15, 0.15, 0.15)  # 不可访问
	
	# BOSS 层特殊显示
	if node.type == 4:
		btn.custom_minimum_size = Vector2(NODE_WIDTH + 20, NODE_HEIGHT)
		btn.add_theme_font_size_override("font_size", 18)
	
	return btn

func _get_node_color(node_type: int) -> Color:
	match node_type:
		0: return Color(1, 0.5, 0.5)     # 战斗 - 红色
		1: return Color(0.5, 0.8, 1)    # 商店 - 蓝色
		2: return Color(0.5, 1, 0.5)    # 休息 - 绿色
		3: return Color(1, 1, 0.5)      # 事件 - 黄色
		4: return Color(1, 0.2, 0.2)    # BOSS - 深红色
		_: return Color.WHITE

func _on_node_clicked(floor_idx: int, node_index: int) -> void:
	# 确保只能点击当前层的节点
	if floor_idx != GameState.current_floor:
		print("Can only select nodes on current floor!")
		return
	
	print("Node clicked: floor ", floor_idx, " index ", node_index)
	node_selected.emit(node_index)

func refresh_map() -> void:
	_update_display()
	_create_tree_map()
