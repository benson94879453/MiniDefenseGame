extends Resource
class_name EnemyData

@export var id: int                # 怪物編號
@export var name: String           # 怪物名稱
@export var texture: Texture2D     # 怪物外觀
@export var max_health: float = 50.0
@export var speed: float = 100.0   # 移動速度
@export var reward_item: ItemData  # (擴充準備) 打死可能掉落的物品或金錢
@export var reward_amount: int = 1
