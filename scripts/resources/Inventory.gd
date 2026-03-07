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

## 將指定數量(amount)的道具(item)加入背包，並自動處理堆疊。
## 回傳值：未能放入背包的剩餘數量（如果為 0 代表全部成功放入）。
func add_item(item: ItemData, amount: int) -> int:
	var remaining_amount = amount
	
	# 策略 1：尋找已經有相同道具且數量未滿堆疊上限的格子
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.item == item and slot.count < item.max_stack:
			var add_amount = min(remaining_amount, item.max_stack - slot.count)
			# 不直接呼叫 add_slot_count 以免頻繁觸發 update，先算好再發送
			slot.count += add_amount
			remaining_amount -= add_amount
			if remaining_amount <= 0:
				inventory_update.emit()
				return 0
				
	# 策略 2：如果還有剩餘，尋找完全空白的格子放置
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.item == null:
			var add_amount = min(remaining_amount, item.max_stack)
			var new_slot = Slot.new()
			new_slot.item = item
			new_slot.count = add_amount
			slots[i] = new_slot # 直接覆蓋
			
			remaining_amount -= add_amount
			if remaining_amount <= 0:
				inventory_update.emit()
				return 0

	# 迴圈結束後如果 remaining_amount > 0，代表背包已全滿且堆疊均達到上限
	if remaining_amount < amount:
		# 代表至少有放進去一部份，還是要發送更新訊號
		inventory_update.emit()
		
	return remaining_amount
