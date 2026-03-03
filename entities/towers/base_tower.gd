extends Node2D
class_name BaseTower

@onready var range_area: Area2D = $RangeArea
@onready var attack_timer: Timer = $AttackTimer

var data: TowerData # 儲存這座塔的靈魂資料
var current_target: Node2D = null

func setup(new_data: TowerData) -> void:
	data = new_data
	
	# 根據資料設定屬性
	attack_timer.wait_time = 1.0 / data.attack_speed
	
	# 設定偵測範圍 (假設一格 64 像素)
	var shape = CircleShape2D.new()
	shape.radius = data.attack_range * 64.0
	$RangeArea/CollisionShape2D.shape = shape
	
	attack_timer.start()

# 由 Timer 的 timeout 訊號觸發
func _on_attack_timer_timeout() -> void:
	find_target()
	if current_target:
		shoot()

func find_target() -> void:
	var enemies = range_area.get_overlapping_bodies()
	if enemies.is_empty():
		current_target = null
		return
		
	# MVP 簡單尋敵：打陣列裡的第一個 (可以擴展成打血最少、離終點最近)
	current_target = enemies[0]

func shoot() -> void:
	# 防呆：確保這座塔有設定子彈場景
	if data.projectile_scene == null:
		return	
	# 1. 生成子彈實體
	var proj = data.projectile_scene.instantiate()	
	# 2. 把子彈加到世界中 (最好放在一個專門裝子彈的 Node2D 底下保持整潔)
	# 這裡先簡單加在塔的父節點(例如 Towers)同層級
	get_parent().add_child(proj) 	
	# 3. 設定子彈的初始位置在塔的中心 (或槍口)
	proj.global_position = self.global_position
	# 4. 把目標和傷害值交接給子彈！(這就是核心)
	proj.setup(current_target, data.damage)
