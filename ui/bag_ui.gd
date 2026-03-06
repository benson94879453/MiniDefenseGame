extends Control

@onready var bag_slot_container: GridContainer = %BagSlotContainer
@onready var hot_bar_container: HBoxContainer = %HotBarContainer

@onready var all_ui_slots: Array = hot_bar_container.get_children() + bag_slot_container.get_children()
var inventory_data: Inventory = preload("res://player/player_inventory.tres")
@onready var item_icon_scene: PackedScene = preload("res://ui/slot_item.tscn")
@onready var build_preview_scene: PackedScene = preload("res://ui/build_preview.tscn")

var mouse_item: SlotItem = null
var build_preview: BuildPreview = null

func _ready() -> void:
	connect_slot_signals()
	close_bag()
	
	for i in range(all_ui_slots.size()):
		var slot = all_ui_slots[i]
		slot.slot_index = i
		
	# Instantiate build preview
	build_preview = build_preview_scene.instantiate()
	get_tree().root.call_deferred("add_child", build_preview)

func _process(_delta: float) -> void:
	if mouse_item:
		mouse_item.global_position = get_global_mouse_position()
		
		# Show build preview if holding a tower or spawn egg
		if mouse_item.slot_data and (mouse_item.slot_data.item is TowerData or mouse_item.slot_data.item is SpawnItemData):
			if not build_preview.is_active:
				build_preview.activate()
		else:
			if build_preview.is_active:
				build_preview.deactivate()
	else:
		if build_preview and build_preview.is_active:
			build_preview.deactivate()

func _unhandled_input(event: InputEvent) -> void:
	# Check for placing a tower on the grid
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if mouse_item and mouse_item.slot_data and mouse_item.slot_data.item is TowerData:
			# Get true world mouse position
			var world_pos = get_viewport().get_canvas_transform().affine_inverse() * event.position
			var grid_pos = MapManager.world_to_grid(world_pos)
			
			if MapManager.is_buildable(grid_pos):
				# Create tower
				var tower_data = mouse_item.slot_data.item as TowerData
				if tower_data.tower_scene:
					var tower = tower_data.tower_scene.instantiate()
					get_tree().current_scene.add_child(tower)
					MapManager.place_tower(grid_pos, tower)
					
					# Consume item
					consume_mouse_item()
		
		elif mouse_item and mouse_item.slot_data and mouse_item.slot_data.item is SpawnItemData:
			# 生怪蛋放置邏輯
			var world_pos = get_viewport().get_canvas_transform().affine_inverse() * event.position
			var grid_pos = MapManager.world_to_grid(world_pos)
			
			if MapManager.is_buildable(grid_pos):
				var spawn_pos = MapManager.grid_to_world(grid_pos)
				var success = use_item(mouse_item.slot_data.item, spawn_pos)
				if success:
					consume_mouse_item()

func _exit_tree() -> void:
	if is_instance_valid(build_preview):
		build_preview.queue_free()

func connect_slot_signals() -> void:
	for slot_button in all_ui_slots:
		# 【修復小細節】：Godot 4 的 Callable 檢查必須包含 bind，否則每次都會以為沒綁定過
		var callable = mouse_left_slot_button.bind(slot_button)
		if not slot_button.mouse_button_left_press.is_connected(callable):
			slot_button.mouse_button_left_press.connect(callable)
		
		var right_callable = mouse_right_slot_button.bind(slot_button)
		if not slot_button.mouse_button_right_press.is_connected(right_callable):
			slot_button.mouse_button_right_press.connect(right_callable)
			
			
func bag_update() -> void:
	if inventory_data.slots.size() != all_ui_slots.size():
		printerr("錯誤：背包資料長度與 UI 格子數量不符！")
		return
		
	for i in range(all_ui_slots.size()):
		var current_slot_data: Slot = inventory_data.slots[i]
		var current_ui_box = all_ui_slots[i]
	
		if not current_slot_data or not current_slot_data.item:
			current_ui_box.clear_box() 
			continue 
		
		var item_icon: SlotItem = current_ui_box.contained_item_icon
		
		if not item_icon:
			item_icon = item_icon_scene.instantiate()
			current_ui_box.insert(item_icon)
		
		item_icon.slot_data = current_slot_data
		item_icon.slot_item_update()

func set_player_inventory(player_inventory: Inventory) -> void:
	if inventory_data and inventory_data.inventory_update.is_connected(bag_update):
		inventory_data.inventory_update.disconnect(bag_update)
	
	inventory_data = player_inventory
	
	if inventory_data:
		inventory_data.inventory_update.connect(bag_update)
		bag_update()

func open_bag(player_inventory: Inventory) -> void:
	set_player_inventory(player_inventory)
	show()

func close_bag() -> void:
	hide()

func mouse_left_slot_button(slot_button) -> void:
	# 情況 1：點擊空格 且 手上有東西 -> 放下物品
	if slot_button.is_empty() and mouse_item:
		insert_item_in_slot(slot_button)
		
	# 情況 2：點擊有東西的格子 且 手上沒東西 -> 拿起物品
	elif not slot_button.is_empty() and not mouse_item:
		take_item_from_slot(slot_button)
		
	# 情況 3：點擊有東西的格子 且 手上也有東西
	elif not slot_button.is_empty() and mouse_item:
		# 取得兩邊的資料
		var slot_data: Slot = slot_button.contained_item_icon.slot_data
		var hand_data: Slot = mouse_item.slot_data
		
		# 【判斷分支】：利用剛剛寫的 is_same_item 來決定要堆疊還是交換
		if slot_data.is_same_item(hand_data):
			stack_items(slot_button)  # 執行堆疊邏輯
		else:
			swap_item_with_slot(slot_button) # 執行原本的交換邏輯
	
# 【新增】處理堆疊的數學邏輯
func stack_items(slot_button) -> void:
	var slot_data: Slot = slot_button.contained_item_icon.slot_data
	var hand_data: Slot = mouse_item.slot_data
	var max_stack: int = slot_data.item.max_stack # 取得該道具的堆疊上限
	
	# 計算總數
	var total_amount: int = slot_data.count + hand_data.count
	
	if total_amount <= max_stack:
		# 情況 A：完美合併 (未超出上限)
		# 1. 更新資料庫的格子數量
		inventory_data.set_slot_count(slot_button.slot_index, total_amount)
		
		# 2. 銷毀手上的道具節點
		mouse_item.queue_free()
		mouse_item = null
	else:
		# 情況 B：溢出與殘留 (超出上限)
		# 1. 格子被塞滿，資料庫數量設為 max_stack
		inventory_data.set_slot_count(slot_button.slot_index, max_stack)
		
		# 2. 計算手上還剩多少，並更新手上的資料
		hand_data.count = total_amount - max_stack
		
		# 3. 呼叫 UI 節點內建的方法，讓它重新顯示剩下的數字
		mouse_item.slot_item_update()
		
func take_item_from_slot(slot_button) -> void:
	mouse_item = slot_button.take_item() # UI 拿起
	
	if mouse_item:
		add_child(mouse_item)
		mouse_item.global_position = get_global_mouse_position()
		
		# 由總管負責通知資料庫移除這筆資料
		inventory_data.remove_slot(mouse_item.slot_data)

func insert_item_in_slot(slot_button) -> void:
	var item = mouse_item
	remove_child(mouse_item)
	mouse_item = null
	
	slot_button.insert(item) # UI 放下
	
	# 由總管負責通知資料庫寫入這筆資料
	inventory_data.insert_slot(slot_button.slot_index, item.slot_data)

# 【新增】：完美的交換道具邏輯
func swap_item_with_slot(slot_button) -> void:
	# 1. 暫存：記住原本在游標上的資料與圖示
	var original_mouse_data: Slot = mouse_item.slot_data
	
	# 2. 拿出：把格子裡原本的道具拿出來當作暫存
	var temp_item: SlotItem = slot_button.take_item() 
	
	# 3. 放入：把手上的道具從根節點移除，並塞進格子裡
	remove_child(mouse_item)
	slot_button.insert(mouse_item) 
	
	# 4. 接手：讓原本格子裡的道具，變成你手上拿著的東西
	mouse_item = temp_item 
	add_child(mouse_item)
	mouse_item.global_position = get_global_mouse_position() # 瞬間校正位置防閃爍
	
	# 5. 更新資料庫：利用你寫好的 insert_slot 將「原本手上的資料」直接覆蓋到該格中
	# 由於這會觸發 inventory_update 訊號更新畫面，而此時 UI 已經換好了，因此不會有任何衝突！
	inventory_data.insert_slot(slot_button.slot_index, original_mouse_data)

# ==========================================
# 右鍵系統邏輯 (Right-Click Logic)
# ==========================================
func mouse_right_slot_button(slot_button) -> void:
	# 情況 1：點擊有東西的格子 且 手上沒東西 -> 【平分拿起】
	if not slot_button.is_empty() and not mouse_item:
		split_half_from_slot(slot_button)
		
	# 情況 2：手上有東西 且 點擊空格 -> 【放 1 個到空格】
	elif slot_button.is_empty() and mouse_item:
		drop_one_to_slot(slot_button)
		
	# 情況 3：手上有東西 且 點擊有東西的格子
	elif not slot_button.is_empty() and mouse_item:
		var slot_data: Slot = slot_button.contained_item_icon.slot_data
		var hand_data: Slot = mouse_item.slot_data
		
		# 只有在「相同道具」且「未滿堆疊上限」時，才允許【放 1 個進去】
		if slot_data.is_same_item(hand_data) and slot_data.count < slot_data.item.max_stack:
			drop_one_to_slot(slot_button)

# 邏輯 1：平分拿起 (Split Pick-up)
func split_half_from_slot(slot_button) -> void:
	var slot_data: Slot = slot_button.contained_item_icon.slot_data
	var total_count: int = slot_data.count
	
	# 數學計算：拿走一半 (進位)，留下一半
	var hand_count: int = int((total_count + 1) / 2) 
	var left_count: int = total_count - hand_count   
	
	# --- 表現層 (UI) 處理 ---
	if left_count == 0:
		# 如果原本只有 1 個，平分後格子會變空，這等同於「左鍵直接拿走」
		take_item_from_slot(slot_button)
		return
		
	# 如果格子還有剩，我們需要「憑空創造」一個新的圖示給滑鼠
	mouse_item = item_icon_scene.instantiate()
	
	# 創造獨立的新資料 (避免與格子裡的資料記憶體位置重疊)
	var new_hand_data = Slot.new()
	new_hand_data.item = slot_data.item
	new_hand_data.count = hand_count
	mouse_item.slot_data = new_hand_data
	
	# 讓新圖示顯示在畫面上並跟隨滑鼠
	add_child(mouse_item)
	mouse_item.global_position = get_global_mouse_position()
	mouse_item.slot_item_update()
	
	# --- 資料層 (Data) 處理 ---
	# 呼叫剛寫好的後台方法，扣除被拿走的數量 (會自動發出 UI 更新訊號)
	inventory_data.sub_slot_count(slot_button.slot_index, hand_count)


# 邏輯 2：單個放下 (Single Drop)
func drop_one_to_slot(slot_button) -> void:
	var hand_data: Slot = mouse_item.slot_data
	
	# --- 表現層 (UI) 與 資料層 (Data) 處理 ---
	if slot_button.is_empty():
		# 情況 A：丟 1 個到「空格子」
		# 1. 創造格子裡的新圖示與新資料
		var new_icon = item_icon_scene.instantiate()
		var new_slot_data = Slot.new()
		new_slot_data.item = hand_data.item
		new_slot_data.count = 1
		new_icon.slot_data = new_slot_data
		
		# 2. 塞入 UI 節點
		slot_button.insert(new_icon)
		new_icon.slot_item_update()
		
		# 3. 寫入後台資料庫 (覆蓋該空格)
		inventory_data.update_slot(slot_button.slot_index, new_slot_data)
		
	else:
		# 情況 B：丟 1 個到「有相同道具的格子」
		# 直接呼叫剛寫好的後台方法，讓該格數量 + 1 (會自動發出 UI 更新訊號)
		inventory_data.add_slot_count(slot_button.slot_index, 1)

	# --- 處理手上剩下的道具 ---
	hand_data.count -= 1 # 手上扣 1 個
	
	if hand_data.count > 0:
		# 手上還有剩，讓滑鼠上的圖示更新數字
		mouse_item.slot_item_update()
	else:
		# 手上扣到沒了，銷毀滑鼠上的節點，回歸空手狀態
		mouse_item.queue_free()
		mouse_item = null

# ==========================================
# 消耗手上道具 (Consume Held Item)
# ==========================================
func consume_mouse_item() -> void:
	mouse_item.slot_data.count -= 1
	if mouse_item.slot_data.count <= 0:
		mouse_item.queue_free()
		mouse_item = null
		build_preview.deactivate()
	else:
		mouse_item.slot_item_update()

# ==========================================
# 生怪蛋使用邏輯 (Spawn Egg Use Logic)
# ==========================================

## 嘗試使用一個 SpawnItemData 道具，在指定位置生成實體。
## 回傳 true 表示成功生成，false 表示失敗（場景或資料缺失）。
func use_item(item: ItemData, spawn_pos: Vector2) -> bool:
	# 1. 型別檢查：確認這是一個 SpawnItemData
	if not item is SpawnItemData:
		push_warning("use_item: 傳入的道具不是 SpawnItemData，已忽略。")
		return false
	
	var spawn_data := item as SpawnItemData
	
	# 2. 防呆：確保場景已設定
	if spawn_data.entity_scene == null:
		push_warning("use_item: SpawnItemData 的 entity_scene 為 null，無法生成實體。")
		return false
	
	# 3. 實例化場景
	var entity: Node = spawn_data.entity_scene.instantiate()
	
	# 5. 設定位置並加入場景樹
	#    必須先 add_child，@onready 變數才會在 _ready() 中被賦值，
	#    setup() 才能安全地存取 collision_shape 等子節點。
	if entity is Node2D:
		(entity as Node2D).global_position = spawn_pos
	
	get_tree().current_scene.add_child(entity)
	
	# 6. 在節點進入場景樹後才注入資料 (與 WaveManager 的做法一致)
	if spawn_data.payload_data != null and entity.has_method("setup"):
		entity.call("setup", spawn_data.payload_data)
	elif spawn_data.payload_data != null:
		push_warning("use_item: 實體缺少 setup() 函數，payload_data 未注入。")
	
	return true

