extends Resource
class_name Inventory

signal inventory_update

@export var slots: Array[Slot]

func remove_slot(slot: Slot):
	var index = slots.find(slot)
	if index < 0: return
	
	# 【修復】：換上一個全新的空白格子，這樣原本拿在手上的資料才不會被清空
	slots[index] = Slot.new()
	inventory_update.emit()
	
func update_slot(index: int, new_slot_data: Slot) -> void:
	if index >= 0 and index < slots.size():
		# 將新道具的資料「拷貝」到這格裡面
		slots[index].item = new_slot_data.item
		slots[index].count = new_slot_data.count
		inventory_update.emit()

func insert_slot(slot_index: int, slot: Slot):
	slots[slot_index] = slot
	inventory_update.emit()
