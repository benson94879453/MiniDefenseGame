extends Resource
class_name EnemyData

@export var id: int                # 怪物編號
@export var name: String           # 怪物名稱
@export var texture: Texture2D     # 怪物外觀
@export var max_health: float = 50.0
@export var speed: float = 50.0   # 移動速度
@export var reward_item: ItemData  # (擴充準備) 打死可能掉落的物品或金錢
@export var reward_amount: int = 1
@export var collision_radius: float = 16.0
@export var attack_power: float = 10.0 # 敵人攻擊力
@export var attack_speed: float = 1.0  # 攻擊間隔(秒)
@export var threat_level: int = 0      # 威脅等級，數值越高 Z-index 越大（視覺上顯示在最前方）
