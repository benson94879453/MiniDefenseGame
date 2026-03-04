extends CharacterBody2D
class_name BaseEnemy

@onready var sprite: Sprite2D = %Sprite2D
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var nav_agent: NavigationAgent2D = %NavigationAgent2D

@export var data: EnemyData # 儲存這隻怪物的靈魂資料
var current_health: float

# ======== 新增：攻擊狀態與目標 ========
var is_attacking: bool = false
var target_building: Node2D = null
var attack_cooldown: float = 0.0 # 用來計算攻擊間隔
# ====================================

# 由波次管理器在生成怪物時呼叫，注入資料
func setup(new_data: EnemyData) -> void:
	data = new_data
	# 動態建立碰撞形狀
	var circle = CircleShape2D.new()
	circle.radius = data.collision_radius
	collision_shape.shape = circle
	
	current_health = data.max_health
	
	if data.texture:
		sprite.texture = data.texture

# 承受傷害的核心邏輯
func take_damage(amount: float) -> void:
	current_health -= amount
	# TODO: 未來可以加上受擊閃爍特效
	if current_health <= 0:
		die()

func die() -> void:
	# TODO: 未來這裡會呼叫背包系統，給予玩家 reward_item
	queue_free()
	
func _physics_process(delta: float) -> void:
	if data == null: #防呆
		return
		
	# ======== 狀態 1：正在攻擊擋路的塔 ========
	if is_attacking and is_instance_valid(target_building):
		attack_cooldown -= delta # 減少冷卻時間
		
		if attack_cooldown <= 0.0:
			# 執行攻擊
			if target_building.has_method("take_damage"):
				# 注意：這裡假設 EnemyData 裡面有 attack_power 和 attack_speed
				# 如果還沒加，你可以先寫死數值（例如傳入 10.0），或是去 EnemyData 補上這兩個變數
				var damage = data.attack_power if "attack_power" in data else 10.0
				target_building.take_damage(damage)
				
			# 重置冷卻時間（假設 attack_speed 代表攻擊間隔秒數，例如 1.0 秒打一下）
			attack_cooldown = data.attack_speed if "attack_speed" in data else 1.0
			
		return # 正在攻擊時，直接 return，不要往下走移動邏輯
		
	# 如果塔被打爆了（節點消失），恢復正常移動狀態
	if is_attacking and not is_instance_valid(target_building):
		is_attacking = false
	# ========================================

	# ======== 狀態 2：正常移動 ========
	if nav_agent.is_navigation_finished():
		# 敵人已到達目標（例如：對基地造成傷害）
		# TODO: 這裡未來要加上對基地扣血的邏輯，然後自我銷毀 (queue_free)
		return

	# 1. 獲取路徑上的下一個位置
	var next_path_position: Vector2 = nav_agent.get_next_path_position()

	# 2. 計算移動方向
	var direction: Vector2 = global_position.direction_to(next_path_position)

	# 3. 應用速度 (來自你的 EnemyData)
	velocity = direction * data.speed 

	# 4. 執行移動
	move_and_slide()
	
	# 5. 移動完畢後，檢查有沒有撞到塔
	check_tower_collision()
	# ==================================

# 新增：檢查碰撞並切換為攻擊狀態
func check_tower_collision() -> void:
	# get_slide_collision_count() 會回傳剛剛 move_and_slide() 期間發生的碰撞次數
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# 判斷撞到的是不是防禦塔
		# (利用 has_method 檢查目標有沒有 take_damage 函數來判斷它是不是可被攻擊的塔/基地)
		if collider != null and collider.is_in_group("Attackable"):
			is_attacking = true
			target_building = collider
			attack_cooldown = 0.0 # 撞到的瞬間立刻發動第一擊 (設定冷卻為0)
			break # 撞到一個塔就停下來準備攻擊

func set_target(target_pos: Vector2) -> void:
	# 確保 nav_agent 已經準備好（有時候設定太快節點還沒 ready）
	if not is_inside_tree(): 
		await ready 
	nav_agent.target_position = target_pos
