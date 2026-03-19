class_name HealthComponent
extends Node

## 生命值组件 - 可复用的生命值管理

signal health_changed(new_health: int, max_health: int)
signal died
signal damage_taken(amount: int)

@export var max_health: int = 10:
	set(value):
		max_health = value
		current_health = mini(current_health, max_health)
		health_changed.emit(current_health, max_health)

var current_health: int = 0

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	damage_taken.emit(amount)
	
	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	if amount <= 0:
		return
	
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func set_health(value: int) -> void:
	current_health = clampi(value, 0, max_health)
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0

func get_health_percent() -> float:
	return float(current_health) / float(max_health)
