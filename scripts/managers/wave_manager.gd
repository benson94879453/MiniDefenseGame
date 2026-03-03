extends Node

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@onready var spawn_timer: Timer = Timer.new()

func _ready() -> void:
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		# 這裡先暫時將敵人生成在地圖上的特定節點 (例如 SpawnPoint)
		# 未來再結合 MapManager 與路徑點系統
		get_tree().current_scene.add_child(enemy)
		enemy.global_position = Vector2(0, 0) # 替換為實際生成座標
