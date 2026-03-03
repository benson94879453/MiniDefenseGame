extends ItemData
class_name TowerData

@export var tower_scene: PackedScene 
@export var projectile_scene: PackedScene # 新增這行：這座塔專用的子彈實體

@export var build_cost: int = 50     
@export var damage: float = 10.0     # 塔依然保留基礎傷害，當作「參數」傳給子彈
@export var attack_range: float = 3.0 
@export var attack_speed: float = 1.0
