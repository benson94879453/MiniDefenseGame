extends CharacterBody2D
class_name BasePosition

@export var max_health: float = 100.0 # 可以在編輯器中設定主基地血量
var current_health: float

func _ready() -> void:
	# 【關鍵】在遊戲開始時，自動為自己貼上 "Attackable" 的標籤
	add_to_group("Attackable") 
	current_health = max_health

func take_damage(amount: float) -> void:
	current_health -= amount
	# TODO: 未來可以加上主基地受擊發紅的特效或音效
	print("主基地受到傷害！剩餘血量：", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	# TODO: 未來這裡要呼叫 GameManager 觸發 Game Over 結算畫面
	print("主基地被摧毀，Game Over！")
	queue_free()
