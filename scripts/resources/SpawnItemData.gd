extends ItemData
class_name SpawnItemData

## 要生成的實體場景 (例如 base_enemy.tscn 或 base_tower.tscn)
@export var entity_scene: PackedScene

## 要注入實體的資料 (例如 first_enemy.tres)
## 宣告為 Resource 以保持泛用性，可接受 EnemyData、TowerData 等任何資源
@export var payload_data: Resource
