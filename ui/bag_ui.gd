extends Control

@onready var bag_slot_container: GridContainer = %BagSlotContainer
@onready var hot_bar_container: HBoxContainer = %HotBarContainer

# 畫面上所有的 UI 格子 (包含快捷列與背包網格)
@onready var all_ui_slots: Array = hot_bar_container.get_children() \
+ bag_slot_container.get_children()

# 玩家的背包資料帳本
var inventory_data: Inventory = preload("res://player/player_inventory.tres")

# 用來像工廠一樣無限複製「道具圖示」的場景藍圖
@onready var item_icon_scene = preload("res://ui/slot_item.tscn")

var mouse_item: SlotItem = null
func _ready() -> void:
	connect_signal()
	close_bag()

func connect_signal():
	for slot_button in all_ui_slots:
		slot_button.mouse_button_left_press.connect(mouse_left_slot_button.bind(slot_button))
	
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

func set_player_inventory(player_inventory: Inventory):
	inventory_data = player_inventory
	
	if inventory_data:
		bag_update()

func open_bag(player_inventory: Inventory):
	set_player_inventory(player_inventory)
	
	inventory_data.inventory_update.connect(bag_update)
	
	for slot_button in all_ui_slots:
		slot_button.slot_inventory = inventory_data
	show()

func close_bag():
	hide()

func mouse_left_slot_button(slot_button):
	if slot_button.is_empty() and mouse_item:
		pass
	
	elif !slot_button.is_empty() and !mouse_item:
		take_item_from_slot(slot_button)
		
func take_item_from_slot(slot_button):
	mouse_item = slot_button.take_item()
	
	add_child(mouse_item)
	item_follow_mouse()
	
func item_follow_mouse():
	
	if !mouse_item:
		return
	
	mouse_item.global_position = get_global_mouse_position()

func _input(event: InputEvent) -> void: 
	item_follow_mouse()
