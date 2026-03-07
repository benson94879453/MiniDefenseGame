extends Area2D
class_name Projectile

@onready var sprite: Sprite2D = %Sprite2D
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D

var _target: Node2D
var _damage: float
var _speed: float = 400.0
var _pierce_count: int = 0
var _hit_targets: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	screen_notifier.screen_exited.connect(_on_screen_exited)

func setup(target: Node2D, damage: float, speed: float = 400.0, pierce_count: int = 0, source: Node2D = null) -> void:
	_target = target
	_damage = damage
	_speed = speed
	_pierce_count = pierce_count
	
	if source:
		_hit_targets.append(source)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		queue_free()
		return

	var direction: Vector2 = global_position.direction_to(_target.global_position)
	global_position += direction * _speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body in _hit_targets:
		return

	if body.has_method("take_damage"):
		body.take_damage(_damage)
		_hit_targets.append(body)

		if _pierce_count <= 0:
			queue_free()
		else:
			_pierce_count -= 1

func _on_screen_exited() -> void:
	queue_free()
