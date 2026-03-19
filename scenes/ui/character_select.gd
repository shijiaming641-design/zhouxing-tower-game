class_name CharacterSelect
extends Control

## 角色选择场景

signal character_selected(class_id: int)
signal back_pressed

@onready var back_button: Button = $BackButton

func _ready():
	print("CharacterSelect _ready")
	# 连接5个角色按钮
	for i in range(5):
		var btn: Button = get_node_or_null("Char%d" % i)
		if btn:
			btn.pressed.connect(_on_class_selected.bind(i))
			print("Connected button Char", i)
		else:
			print("ERROR: Button Char", i, " not found!")
	
	back_button.pressed.connect(_on_back_pressed)

func _on_class_selected(class_id: int):
	print("Character selected from UI: ", class_id)
	character_selected.emit(class_id)

func _on_back_pressed():
	print("Back pressed")
	back_pressed.emit()
