extends Node2D
class_name WaveManager

@export var enemy_data: EnemyData
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var target_node: Node2D 
@export var enemy_container: Node2D 
@export var spawn_position: Vector2 = Vector2(50, 50)

@onready var _spawn_timer: Timer = Timer.new()

func _ready() -> void:
	if not target_node:
		push_warning("WaveManager: Target node (Base) not assigned!")
	
	add_child(_spawn_timer)
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if enemy_scene and target_node:
		_spawn_enemy()

func _spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	
	if enemy_container:
		enemy_container.add_child(enemy)
	else:
		get_tree().current_scene.add_child(enemy)
		
	if enemy.has_method("setup") and enemy_data:
		enemy.setup(enemy_data)
	else:
		push_warning("WaveManager: Enemy lacks setup() or enemy_data is null.")
	
	if enemy.has_method("set_target"):
		enemy.set_target(target_node.global_position)

