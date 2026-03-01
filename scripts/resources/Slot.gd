extends Resource

class_name Slot

# 這一格實際裝了什麼道具 (存入上面的 ItemData 資源)
@export var item: ItemData = null
# 這一格的道具數量
@export var count: int = 0

func clear() -> void:
	item = null
	count = 0
	
func is_same_item(other_slot: Slot) -> bool:
	# 如果其中一方是空的，就不可能「相同」
	if not item or not other_slot.item:
		return false
	# 透過道具的唯一編號 (id) 來判斷是否為同一種物品
	return item.id == other_slot.item.id
