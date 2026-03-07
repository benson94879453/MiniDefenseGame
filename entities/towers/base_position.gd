extends CharacterBody2D
class_name BasePosition

signal base_destroyed

@export var max_health: float = 100.0
var _current_health: float

func _ready() -> void:
	add_to_group("Attackable")
	add_to_group("Base")
	_current_health = max_health
	
	if not base_destroyed.is_connected(GameManager.game_over):
		base_destroyed.connect(GameManager.game_over)

func take_damage(amount: float) -> void:
	_current_health -= amount
	if _current_health <= 0:
		die()

func die() -> void:
	base_destroyed.emit()
	queue_free()

