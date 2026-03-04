extends CharacterBody2D
class_name BaseEnemy

@onready var sprite: Sprite2D = %Sprite2D
@onready var nav_agent: NavigationAgent2D = %NavigationAgent2D

var data: EnemyData # 儲存這隻怪物的靈魂資料
var current_health: float

# 由波次管理器在生成怪物時呼叫，注入資料
func setup(new_data: EnemyData) -> void:
	data = new_data
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
	if nav_agent.is_navigation_finished():
		# 敵人已到達目標（例如：對基地造成傷害）
		return

	# 1. 獲取路徑上的下一個位置
	var next_path_position: Vector2 = nav_agent.get_next_path_position()

	# 2. 計算移動方向
	var direction: Vector2 = global_position.direction_to(next_path_position)

	# 3. 應用速度 (來自你的 EnemyData)
	velocity = direction * data.speed 

	# 4. 執行移動
	move_and_slide()

func set_target(target_pos: Vector2) -> void:
	# 確保 nav_agent 已經準備好（有時候設定太快節點還沒 ready）
	if not is_inside_tree(): 
		await ready 
	nav_agent.target_position = target_pos
