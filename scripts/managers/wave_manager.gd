extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0

# 新增：拖入你的基地節點 (Base)
@export var target_node: Node2D 

# 新增：拖入用於存放敵人的容器 (例如 NavigationRegion2D/Enemies)
@export var enemy_container: Node2D 

# 新增：定義生成點 (也可以改用 Marker2D 節點)
@export var spawn_position: Vector2 = Vector2(50, 50)

@onready var spawn_timer: Timer = Timer.new()

func _ready() -> void:
	# 檢查必要組件
	if not target_node:
		push_warning("WaveManager: 尚未指定 target_node (基地)！敵人將失去目標。")
	
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if enemy_scene and target_node:
		spawn_enemy()

func spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	
	# 1. 設定初始位置
	enemy.global_position = spawn_position
	
	# 2. 將敵人加入場景樹
	# 優先加入指定容器，若無則加入當前場景根部
	if enemy_container:
		enemy_container.add_child(enemy)
	else:
		get_tree().current_scene.add_child(enemy)
	
	# 3. 初始化導航目標 (關鍵步驟)
	# 這裡假設你的 base_enemy.gd 已經定義了 nav_agent
	# 我們在敵人進入場景樹後立即設定目標
	if enemy.has_method("set_target"):
		# 推薦在 base_enemy.gd 寫一個 set_target 方法
		enemy.set_target(target_node.global_position)
	elif "nav_agent" in enemy:
		# 或者直接存取屬性 (確保 nav_agent 已經 @onready)
		enemy.nav_agent.target_position = target_node.global_position
