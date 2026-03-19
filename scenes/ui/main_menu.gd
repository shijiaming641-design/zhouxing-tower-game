class_name MainMenu
extends Control

## 主菜单场景

signal start_game_pressed

@onready var start_button: Button = $VBoxContainer/StartButton

func _ready():
	print("MainMenu _ready")
	if start_button:
		print("StartButton found, connecting signal")
		start_button.pressed.connect(_on_start_pressed)
	else:
		print("ERROR: StartButton not found!")

func _on_start_pressed():
	print("Start button pressed!")
	start_game_pressed.emit()
