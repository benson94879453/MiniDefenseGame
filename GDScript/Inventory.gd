extends Resource

class_name Inventory

signal inventory_update

# 這是一個陣列，裝著所有的 Slot 資料 (例如 36 個格子)
@export var slots: Array[Slot]

func remove_slot(slot__: Slot):
	var index_ = slots.find(slot__)
	
	
	if index_ < 0: return
	
	slots[index_] = Slot.new()
	
	inventory_update.emit()
