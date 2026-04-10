class_name MainMenu
extends Control

## 主菜单场景
## 注意：按钮连接由 Main.gd 处理，此脚本只负责信号定义

signal start_game_pressed
signal continue_game_pressed

@onready var start_button: Button = $StartButton
@onready var continue_button: Button = $ContinueButton
@onready var save_summary_label: Label = $SaveSummaryLabel
@onready var stats_button: Button = $StatsButton
@onready var upgrade_button: Button = $UpgradeButton
@onready var codex_button: Button = $CodexButton

func _ready():
	print("MainMenu _ready")
	# 注意：StartButton 的连接由 Main.gd 处理
	# 这里只确保按钮存在
	if start_button:
		print("StartButton found")
	else:
		print("ERROR: StartButton not found!")

	if continue_button == null:
		print("ERROR: ContinueButton not found!")

func configure_continue_state(has_save: bool, summary_text: String) -> void:
	if continue_button:
		continue_button.disabled = not has_save
	if save_summary_label:
		save_summary_label.text = summary_text

func _on_start_pressed():
	print("Start button pressed!")
	start_game_pressed.emit()

func _on_continue_pressed():
	print("Continue button pressed!")
	continue_game_pressed.emit()
