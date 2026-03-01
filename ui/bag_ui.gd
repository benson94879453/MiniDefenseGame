extends Control

# --- 節點引用 (Node References) ---
@onready var bag_slot_container: GridContainer = %BagSlotContainer
@onready var hot_bar_container: HBoxContainer = %HotBarContainer

# --- 資料與設定 (Data & Settings) ---
# 獲取畫面上所有的 UI 格子（包含快捷列與背包網格）
@onready var all_ui_slots: Array = hot_bar_container.get_children() + bag_slot_container.get_children()

# 玩家的背包資料帳本
var inventory_data: Inventory = preload("res://player/player_inventory.tres")

# 用來像工廠一樣生成「道具圖示」的場景藍圖
@onready var item_icon_scene: PackedScene = preload("res://ui/slot_item.tscn")

# 正在跟隨滑鼠移動的道具圖示節點
var mouse_item: SlotItem = null

# --- 核心生命週期 (Lifecycle) ---
func _ready() -> void:
	connect_slot_signals()
	close_bag()
	
	for i in range(all_ui_slots.size()):
		var slot = all_ui_slots[i]
		slot.slot_index = i

func _process(_delta: float) -> void:
	# 優化：將跟隨邏輯移至 _process。
	# 相較於 _input，這能確保道具圖示在每一幀都精確跟隨滑鼠，視覺上更流暢。
	if mouse_item:
		mouse_item.global_position = get_global_mouse_position()

# --- 介面更新邏輯 (UI Logic) ---
## 連接所有格子的信號
func connect_slot_signals() -> void:
	for slot_button in all_ui_slots:
		# 檢查是否已連接，避免重複綁定導致邏輯錯誤
		if not slot_button.mouse_button_left_press.is_connected(mouse_left_slot_button):
			slot_button.mouse_button_left_press.connect(mouse_left_slot_button.bind(slot_button))

## 核心邏輯：盤點並同步資料到 UI 畫面
func bag_update() -> void:
	# 防呆檢查：確保資料與 UI 數量一致
	if inventory_data.slots.size() != all_ui_slots.size():
		printerr("錯誤：背包資料長度與 UI 格子數量不符！")
		return
		
	for i in range(all_ui_slots.size()):
		var current_slot_data: Slot = inventory_data.slots[i]
		var current_ui_box = all_ui_slots[i]
	
		# 狀況 A：如果這格在資料庫中是空的
		if not current_slot_data or not current_slot_data.item:
			# 重要：必須呼叫 clear_box，否則拿走道具後，舊的圖示會殘留在畫面上
			current_ui_box.clear_box() 
			continue 
		
		# 狀況 B：這格有道具資料
		var item_icon: SlotItem = current_ui_box.contained_item_icon
		
		# 如果 UI 框裡還沒有圖示節點，就生成一個
		if not item_icon:
			item_icon = item_icon_scene.instantiate()
			current_ui_box.insert(item_icon)
		
		# 更新圖示顯示（圖片與數量）
		item_icon.slot_data = current_slot_data
		item_icon.slot_item_update()

# --- 背包狀態管理 (State Management) ---
func set_player_inventory(player_inventory: Inventory) -> void:
	# 舊信號中斷連接，防止更換背包資料後產生衝突
	if inventory_data and inventory_data.inventory_update.is_connected(bag_update):
		inventory_data.inventory_update.disconnect(bag_update)
	
	inventory_data = player_inventory
	
	if inventory_data:
		# 重新連接新資料的自動更新信號
		inventory_data.inventory_update.connect(bag_update)
		bag_update()

func open_bag(player_inventory: Inventory) -> void:
	set_player_inventory(player_inventory)
	
	if inventory_data.inventory_update.is_connected(bag_update):
		inventory_data.inventory_update.disconnect(bag_update)
	
	# 同步每個按鈕對應的背包帳本參考
	for slot_button in all_ui_slots:
		slot_button.slot_inventory = inventory_data
	
	show()

func close_bag() -> void:
	hide()

# --- 滑鼠互動邏輯 (Mouse Interaction) ---
func mouse_left_slot_button(slot_button) -> void:
	# 情況 1：點擊空格 且 手上有東西 -> 放下物品
	if slot_button.is_empty() and mouse_item:
		# 這裡即將加入放置邏輯
		insert_item_in_slot(slot_button)
	
	# 情況 2：點擊有東西的格子 且 手上沒東西 -> 拿起物品
	elif not slot_button.is_empty() and not mouse_item:
		take_item_from_slot(slot_button)
		
func take_item_from_slot(slot_button) -> void:
	# 從按鈕節點中提取圖示
	mouse_item = slot_button.take_item()
	
	if mouse_item:
		add_child(mouse_item)
		# 拿起瞬間立即校正位置，防止圖示閃現回原位
		mouse_item.global_position = get_global_mouse_position()

# 移除原本的 _input(event) 內容，因為跟隨邏輯已交給 _process
func insert_item_in_slot(slot_button):
	var item = mouse_item
	
	remove_child(mouse_item)
	
	mouse_item = null
	
	slot_button.insert(item)
