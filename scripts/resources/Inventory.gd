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

func set_slot_count(index: int, new_count: int) -> void:
	if index >= 0 and index < slots.size():
		slots[index].count = new_count
		inventory_update.emit() # 發出訊號，通知 bag_update 更新畫面
		
# 幫指定的格子增加數量 (丟 1 個進去時使用)
func add_slot_count(index: int, amount: int) -> void:
	if index >= 0 and index < slots.size() and slots[index].item != null:
		slots[index].count += amount
		inventory_update.emit()

# 幫指定的格子扣除數量 (平分拿走時使用)
func sub_slot_count(index: int, amount: int) -> void:
	if index >= 0 and index < slots.size() and slots[index].item != null:
		slots[index].count -= amount
		
		# 防呆：如果扣完之後數量歸零或變負數，直接清空這格
		if slots[index].count <= 0:
			remove_slot(slots[index])
		else:
			inventory_update.emit()
