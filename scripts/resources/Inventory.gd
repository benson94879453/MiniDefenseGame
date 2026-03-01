extends Resource

class_name Inventory

signal inventory_update

# 這是一個陣列，裝著所有的 Slot 資料 (例如 36 個格子)
@export var slots: Array[Slot]

func remove_slot(slot: Slot):
	var index = slots.find(slot)
	
	if index < 0: return
	
	inventory_update.emit()

func insert_slot(slot_index: int,slot: Slot):
	slots[slot_index] = slot
	inventory_update.emit()
