class_name ShopScene
extends Control

## 商店场景

signal item_purchased(item_type: String)
signal next_floor_pressed
signal back_pressed

@onready var title_label: Label = $TitleLabel
@onready var gold_label: Label = $GoldLabel
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	var floor_num: int = GameState.current_floor + 1
	title_label.text = "商店 - 第%d层" % floor_num
	gold_label.text = "💰 金币: %d" % GameState.player_gold
	
	var class_data: Dictionary = PlayerClassData.get_class_data(GameState.player_class)
	var hp_bar: String = ""
	for i in range(GameState.player_max_hp):
		hp_bar += "❤️" if i < GameState.player_hp else "🖤"
	status_label.text = "%s %s" % [class_data.name, hp_bar]

func _on_heal_pressed() -> void:
	_try_purchase(15, "heal")

func _on_attack_pressed() -> void:
	_try_purchase(25, "attack")

func _on_maxhp_pressed() -> void:
	_try_purchase(30, "maxhp")

func _try_purchase(cost: int, item_type: String) -> void:
	if GameState.player_gold >= cost:
		GameState.change_gold(-cost)
		
		match item_type:
			"heal":
				GameState.player_hp = mini(GameState.player_hp + 5, GameState.player_max_hp)
				EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
			"attack":
				GameState.player_attack += 1
			"maxhp":
				GameState.player_max_hp += 3
				GameState.player_hp += 3
				EventBus.player_hp_changed.emit(GameState.player_hp, GameState.player_max_hp)
		
		_update_display()
		item_purchased.emit(item_type)
	else:
		# 金币不足提示
		status_label.text = "金币不足！"
		await get_tree().create_timer(1.0).timeout
		_update_display()

func _on_next_pressed() -> void:
	next_floor_pressed.emit()

func _on_back_pressed() -> void:
	back_pressed.emit()
