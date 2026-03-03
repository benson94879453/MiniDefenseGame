extends CharacterBody2D
class_name BaseEnemy

@onready var sprite: Sprite2D = $Sprite2D

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
