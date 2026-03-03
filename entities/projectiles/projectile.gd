extends Area2D
class_name Projectile

var target: Node2D      # 子彈要追蹤的目標
var damage: float       # 子彈攜帶的傷害值
var speed: float = 400.0 # 子彈飛行速度

# 這個函數由「塔」在發射子彈時呼叫，用來把資料傳遞給子彈
func setup(new_target: Node2D, new_damage: float) -> void:
	target = new_target
	damage = new_damage

func _physics_process(delta: float) -> void:
	# 防呆：如果子彈還在飛，但怪物已經被其他塔打死了，子彈就自我毀滅
	if not is_instance_valid(target):
		queue_free()
		return
		
	# 追蹤邏輯：朝著目標移動
	var direction = global_position.direction_to(target.global_position)
	global_position += direction * speed * delta

# 當子彈撞到東西時 (記得在編輯器把 Area2D 的 body_entered 訊號連到這裡)
func _on_body_entered(body: Node2D) -> void:
	# 如果撞到的是有「受傷功能」的怪物
	if body.has_method("take_damage"):
		body.take_damage(damage) # 由子彈對怪物造成傷害！
		queue_free()             # 子彈命中後銷毀自己
