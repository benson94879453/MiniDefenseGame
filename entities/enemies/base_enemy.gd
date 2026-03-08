extends Area2D
class_name BaseEnemy

## 子節點參照
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_area: Area2D = $HitboxArea

@export var data: EnemyData 

@export_group("Jitter Settings")
@export var max_path_offset: float = 12.0      # 怪物偏離導航中線的最大距離
@export var speed_jitter_range: float = 0.10   # 速度擾動百分比 (±10%)

var _current_health: float
var _is_attacking: bool = false
var _target_building: Node2D = null
var _current_attack_cd: float = 0.0

var _actual_speed: float = 0.0
var _path_offset_scalar: float = 0.0
var _segment_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("Enemy")
	# HitboxArea 偵測碰觸到建築物（Tower / Base，layer = bit 3）
	hitbox_area.body_entered.connect(_on_hitbox_body_entered)
	hitbox_area.body_exited.connect(_on_hitbox_body_exited)

func setup(new_data: EnemyData) -> void:
	data = new_data
	
	# 設定根節點的碰撞形狀（供 Tower RangeArea 和 Projectile 偵測）
	var circle = CircleShape2D.new()
	circle.radius = data.collision_radius
	collision_shape.shape = circle
	
	# 設定 HitboxArea 的碰撞形狀（供偵測建築物）
	var hitbox_circle = CircleShape2D.new()
	hitbox_circle.radius = data.collision_radius
	$HitboxArea/CollisionShape2D.shape = hitbox_circle
	
	_current_health = data.max_health
	if data.texture:
		sprite.texture = data.texture
	
	# Jitter: 速度擾動與路徑錯位
	var speed_multiplier = 1.0 + randf_range(-speed_jitter_range, speed_jitter_range)
	_actual_speed = data.speed * speed_multiplier
	_path_offset_scalar = randf_range(-max_path_offset, max_path_offset)
	
	# Z-index 排序：高威脅等級的怪物顯示在最上層
	z_index = data.threat_level

func take_damage(amount: float) -> void:
	_current_health -= amount
	if _current_health <= 0:
		die()

func die() -> void:
	_drop_reward()
	queue_free()

func _drop_reward() -> void:
	if data and data.reward_item:
		GameManager.give_reward(data.reward_item, data.reward_amount)
	
var _current_path: Array[Vector2i] = []
var _path_index: int = 0
var _target_world_pos: Vector2 = Vector2.ZERO

func set_target(target_pos: Vector2) -> void:
	if not is_inside_tree(): 
		await ready 
	
	_target_world_pos = target_pos
	# 不再這裡直接取 get_id_path，我們讓 _physics_process 去負責尋路，防禦一開局的 AStarGrid 還沒 Update 完的問題。
	_current_path.clear()

func _physics_process(delta: float) -> void:
	if not data:
		return
		
	if _is_attacking:
		if is_instance_valid(_target_building):
			_process_attack(delta)
			return
		else:
			_is_attacking = false
			_target_building = null
			# 塔被打爆了，重新計算路徑 (假設主堡還在)
			var base = get_tree().get_first_node_in_group("Base")
			if base:
				set_target(base.global_position)
			
	if _current_path.is_empty():
		# 尋路邏輯：若沒路徑，嘗試找路
		if _target_world_pos == Vector2.ZERO:
			return # 還沒被 assign target
		
		var start_grid = MapManager.world_to_grid(global_position)
		var end_grid = MapManager.world_to_grid(_target_world_pos)
		
		# 獲取路徑
		_current_path = MapManager.astargrid.get_id_path(start_grid, end_grid)
		_path_index = 0
		
		if _current_path.is_empty():
			# 真的找不到路徑，直接往目標硬飛過去 (防卡死機制)
			var direction = global_position.direction_to(_target_world_pos)
			global_position += direction * _actual_speed * delta
			if global_position.distance_to(_target_world_pos) < 5.0:
				_on_reach_base()
			return
		else:
			_update_target_and_offset(global_position)
	
	if _path_index >= _current_path.size():
		_on_reach_base()
		return

	var target_with_offset = _target_world_pos + _segment_offset
	var dist_to_target = global_position.distance_to(target_with_offset)
	var move_dist = _actual_speed * delta
	
	if dist_to_target <= move_dist:
		# 抵達當前節點，切換到下一個
		global_position = target_with_offset # 防止累積誤差
		var prev_pure_pos = _target_world_pos
		_path_index += 1
		if _path_index < _current_path.size():
			_update_target_and_offset(prev_pure_pos)
		else:
			_on_reach_base()
			return
	else:
		var direction: Vector2 = global_position.direction_to(target_with_offset)
		global_position += direction * move_dist

func _process_attack(delta: float) -> void:
	_current_attack_cd -= delta
	if _current_attack_cd <= 0.0:
		if _target_building.has_method("take_damage"):
			_target_building.take_damage(data.attack_power)
		_current_attack_cd = data.attack_speed

func _update_target_and_offset(base_start_pos: Vector2) -> void:
	var next_node_world_pos = MapManager.grid_to_world(_current_path[_path_index])
	var seg_dir = base_start_pos.direction_to(next_node_world_pos)
	if seg_dir == Vector2.ZERO:
		seg_dir = Vector2.RIGHT
	var perp = Vector2(-seg_dir.y, seg_dir.x)
	_segment_offset = perp * _path_offset_scalar
	_target_world_pos = next_node_world_pos

## HitboxArea 偵測到碰觸建築物（取代原本 get_slide_collision 的邏輯）
func _on_hitbox_body_entered(body: Node2D) -> void:
	if _is_attacking:
		return
	if body and body.is_in_group("Attackable"):
		_is_attacking = true
		_target_building = body
		_current_attack_cd = 0.0

## 當離開建築物範圍時，若目標剛好是離開的那個，則重置攻擊狀態
func _on_hitbox_body_exited(body: Node2D) -> void:
	if body == _target_building:
		_is_attacking = false
		_target_building = null

func _on_reach_base() -> void:
	var base = get_tree().get_first_node_in_group("Base")
	if base and base.is_in_group("Attackable"):
		_is_attacking = true
		_target_building = base
		_current_attack_cd = 0.0
