extends Control

@onready var bag_slot_container: GridContainer = %BagSlotContainer
@onready var hot_bar_container: HBoxContainer = %HotBarContainer

# 畫面上所有的 UI 格子 (包含快捷列與背包網格)
@onready var all_ui_slots: Array = hot_bar_container.get_children() \
+ bag_slot_container.get_children()

# 玩家的背包資料帳本
@onready var inventory_data: Inventory = preload("res://player/player_inventory.tres")

# 用來像工廠一樣無限複製「道具圖示」的場景藍圖
@onready var item_icon_scene = preload("res://ui/slot_item.tscn")

func _ready() -> void:
	bag_update()

# 核心邏輯：盤點與更新畫面
func bag_update():
	# 防呆檢查：如果資料庫的格子數，跟畫面上的格子數不一樣，立刻停止執行
	if inventory_data.slots.size() != all_ui_slots.size():
		return
		
	# 開始一格一格巡視
	for i in range(all_ui_slots.size()):
		
		# current_slot_data 是「資料」，current_ui_box 是「介面」
		var current_slot_data: Slot = inventory_data.slots[i]
		var current_ui_box = all_ui_slots[i]
	
		# 狀況 A：如果這格沒有資料，或資料裡面是空的
		if not current_slot_data or not current_slot_data.item:
			current_ui_box.clear_box() # 呼叫我們剛剛寫好的清空函式
			continue # 直接跳到下一格
		
		# 狀況 B：這格有道具資料
		var item_icon: SlotItem = current_ui_box.contained_item_icon
		
		# 如果 UI 框裡還沒有實體模型，就馬上生成一個放進去
		if not item_icon:
			item_icon = item_icon_scene.instantiate()
			current_ui_box.insert(item_icon)
		
		# 把最新的資料交給模型，並請它自己更新畫面(圖片跟數量)
		item_icon.slot_data = current_slot_data
		item_icon.slot_item_update()
