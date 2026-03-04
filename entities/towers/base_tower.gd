extends CharacterBody2D 
class_name BaseTower

@onready var range_area: Area2D = %RangeArea
@onready var attack_timer: Timer = %AttackTimer

var data: TowerData # 儲存這座塔的靈魂資料
var current_target: Node2D = null

# ======== 新增：生命值相關 ========
var current_health: float 
# ================================

func _ready() -> void:
	# 【關鍵】讓防禦塔也貼上 "Attackable" 的標籤
	add_to_group("Attackable")
	
func setup(new_data: TowerData) -> void:
	data = new_data
	
	# 初始化血量 (假設你在 TowerData 裡新增的變數叫 health 或 max_health)
	current_health = data.health 
	
	# 根據資料設定屬性
	if data.attack_speed > 0:
		attack_timer.wait_time = 1.0 / data.attack_speed
	
	# 設定偵測範圍 (假設一格 64 像素)
	var shape = CircleShape2D.new()
	shape.radius = data.attack_range * 64.0
	# 這裡建議使用 $RangeArea/CollisionShape2D 確保路徑正確
	$RangeArea/CollisionShape2D.shape = shape
	
	attack_timer.start()

# ======== 新增：受擊與死亡邏輯 ========
func take_damage(amount: float) -> void:
	current_health -= amount
	# TODO: 未來可以加上塔受損的閃爍特效或冒煙特效
	if current_health <= 0:
		die()

func die() -> void:
	# TODO: 未來可以播放塔倒塌的粒子特效和音效
	queue_free()
# ====================================

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
	
	# 2. 把子彈加到世界中
	get_parent().add_child(proj) 	
	
	# 3. 設定子彈的初始位置在塔的中心
	proj.global_position = self.global_position
	
	# 4. 把目標和傷害值交接給子彈
	# 這裡假設你的子彈 setup 已經準備好接收目標與傷害
	proj.setup(current_target, data.damage)
