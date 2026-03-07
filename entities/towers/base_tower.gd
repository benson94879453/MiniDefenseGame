extends CharacterBody2D 
class_name BaseTower

@onready var range_area: Area2D = %RangeArea
@onready var attack_timer: Timer = %AttackTimer

var data: TowerData
var _current_target: Node2D = null
var _current_health: float

func _ready() -> void:
	add_to_group("Attackable")
	if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)

func setup(new_data: TowerData) -> void:
	data = new_data
	_current_health = data.health

	if data.attack_speed > 0:
		attack_timer.wait_time = 1.0 / data.attack_speed

	var shape = CircleShape2D.new()
	shape.radius = data.attack_range * 64.0
	$RangeArea/CollisionShape2D.shape = shape

	attack_timer.start()

func take_damage(amount: float) -> void:
	_current_health -= amount
	if _current_health <= 0:
		die()

func die() -> void:
	queue_free()

func _on_attack_timer_timeout() -> void:
	_find_target()
	if _current_target:
		_shoot()

func _find_target() -> void:
	var bodies = range_area.get_overlapping_bodies()
	if bodies.is_empty():
		_current_target = null
		return

	for body in bodies:
		if body.is_in_group("Enemy"):
			_current_target = body
			return
			
	_current_target = null

func _shoot() -> void:
	if not data or not data.projectile_scene:
		return

	var proj = data.projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position

	var proj_speed: float = 400.0
	var proj_pierce: int = 0

	if data.projectile_data:
		proj_speed = data.projectile_data.speed
		proj_pierce = data.projectile_data.pierce_count
		if data.projectile_data.texture and proj.has_node("Sprite2D"):
			proj.get_node("Sprite2D").texture = data.projectile_data.texture

	if proj.has_method("setup"):
		proj.setup(_current_target, data.damage, proj_speed, proj_pierce, self)
