extends Resource

class_name Slot

# 這一格實際裝了什麼道具 (存入上面的 ItemData 資源)
@export var item: ItemData = null
# 這一格的道具數量
@export var count: int = 0

func clear() -> void:
	item = null
	count = 0
