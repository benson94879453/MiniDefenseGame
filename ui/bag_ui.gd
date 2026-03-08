extends Control
class_name BagUI

@onready var _bag_slot_container: GridContainer = %BagSlotContainer
@onready var _hot_bar_container: HBoxContainer = %HotBarContainer
@onready var _all_ui_slots: Array = _hot_bar_container.get_children() + _bag_slot_container.get_children()

var _inventory_data: Inventory = preload("res://player/player_inventory.tres")
@onready var _item_icon_scene: PackedScene = preload("res://ui/slot_item.tscn")
@onready var _build_preview_scene: PackedScene = preload("res://ui/build_preview.tscn")

var _mouse_item: SlotItem = null
var _build_source_slot_index: int = -1
var _build_preview: BuildPreview = null

func _ready() -> void:
	_connect_slot_signals()
	close_bag()
	
	for i in range(_all_ui_slots.size()):
		var slot = _all_ui_slots[i]
		slot.slot_index = i
		
	_build_preview = _build_preview_scene.instantiate()
	get_tree().root.call_deferred("add_child", _build_preview)

func _process(_delta: float) -> void:
	if _mouse_item:
		_mouse_item.global_position = get_global_mouse_position()
		
		if _mouse_item.slot_data and (_mouse_item.slot_data.item is TowerData or _mouse_item.slot_data.item is SpawnItemData):
			if not _build_preview.is_active:
				_build_preview.activate()
				_set_build_mode_active(true)
		else:
			if _build_preview.is_active:
				_build_preview.deactivate()
				_set_build_mode_active(false)
	else:
		if _build_preview and _build_preview.is_active:
			_build_preview.deactivate()
			_set_build_mode_active(false)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
		
	if event.button_index == MOUSE_BUTTON_LEFT:
		if _mouse_item and _mouse_item.slot_data and _mouse_item.slot_data.item is TowerData:
			var world_pos = get_viewport().get_canvas_transform().affine_inverse() * event.position
			var grid_pos = MapManager.world_to_grid(world_pos)
			
			if MapManager.is_buildable(grid_pos):
				var tower_data = _mouse_item.slot_data.item as TowerData
				if tower_data.tower_scene:
					var tower = tower_data.tower_scene.instantiate()
					
					var container = get_tree().current_scene.get_node_or_null("ModePlay/EntitiesContainer")
					if container:
						container.add_child(tower)
					else:
						get_tree().current_scene.add_child(tower)
						
					tower.global_position = MapManager.grid_to_world(grid_pos)
					MapManager.register_tower(grid_pos)
					
					if tower.has_method("setup"):
						tower.setup(tower_data)
					
					_consume_mouse_item()
		
		elif _mouse_item and _mouse_item.slot_data and _mouse_item.slot_data.item is SpawnItemData:
			var world_pos = get_viewport().get_canvas_transform().affine_inverse() * event.position
			var grid_pos = MapManager.world_to_grid(world_pos)
			
			if MapManager.is_buildable(grid_pos):
				var spawn_pos = MapManager.grid_to_world(grid_pos)
				if _use_item(_mouse_item.slot_data.item, spawn_pos):
					_consume_mouse_item()
					
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if _mouse_item and _mouse_item.slot_data and (_mouse_item.slot_data.item is TowerData or _mouse_item.slot_data.item is SpawnItemData):
			_cancel_build()
			get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if is_instance_valid(_build_preview):
		_build_preview.queue_free()

func _connect_slot_signals() -> void:
	for slot_button in _all_ui_slots:
		var left_callable = _mouse_left_slot_button.bind(slot_button)
		if not slot_button.mouse_button_left_press.is_connected(left_callable):
			slot_button.mouse_button_left_press.connect(left_callable)
		
		var right_callable = _mouse_right_slot_button.bind(slot_button)
		if not slot_button.mouse_button_right_press.is_connected(right_callable):
			slot_button.mouse_button_right_press.connect(right_callable)

func _bag_update() -> void:
	if _inventory_data.slots.size() != _all_ui_slots.size():
		printerr("錯誤：背包資料長度與 UI 格子數量不符！")
		return
		
	for i in range(_all_ui_slots.size()):
		var current_slot_data: Slot = _inventory_data.slots[i]
		var current_ui_box = _all_ui_slots[i]
	
		if not current_slot_data or not current_slot_data.item:
			current_ui_box.clear_box() 
			continue 
		
		var item_icon: SlotItem = current_ui_box.contained_item_icon
		if not item_icon:
			item_icon = _item_icon_scene.instantiate()
			current_ui_box.insert(item_icon)
		
		item_icon.slot_data = current_slot_data
		item_icon.slot_item_update()

func set_player_inventory(player_inventory: Inventory) -> void:
	if _inventory_data and _inventory_data.inventory_update.is_connected(_bag_update):
		_inventory_data.inventory_update.disconnect(_bag_update)
	
	_inventory_data = player_inventory
	if _inventory_data:
		_inventory_data.inventory_update.connect(_bag_update)
		_bag_update()

func open_bag(player_inventory: Inventory) -> void:
	set_player_inventory(player_inventory)
	show()

func close_bag() -> void:
	hide()

func _mouse_left_slot_button(slot_button) -> void:
	if slot_button.is_empty() and _mouse_item:
		_insert_item_in_slot(slot_button)
	elif not slot_button.is_empty() and not _mouse_item:
		_take_item_from_slot(slot_button)
	elif not slot_button.is_empty() and _mouse_item:
		var slot_data: Slot = slot_button.contained_item_icon.slot_data
		var hand_data: Slot = _mouse_item.slot_data
		
		if slot_data.is_same_item(hand_data):
			_stack_items(slot_button)
		else:
			_swap_item_with_slot(slot_button)

func _stack_items(slot_button) -> void:
	var slot_data: Slot = slot_button.contained_item_icon.slot_data
	var hand_data: Slot = _mouse_item.slot_data
	var max_stack: int = slot_data.item.max_stack
	
	var total_amount: int = slot_data.count + hand_data.count
	
	if total_amount <= max_stack:
		_inventory_data.set_slot_count(slot_button.slot_index, total_amount)
		_mouse_item.queue_free()
		_mouse_item = null
		_build_source_slot_index = -1
	else:
		_inventory_data.set_slot_count(slot_button.slot_index, max_stack)
		hand_data.count = total_amount - max_stack
		_mouse_item.slot_item_update()

func _take_item_from_slot(slot_button) -> void:
	_mouse_item = slot_button.take_item()
	_build_source_slot_index = slot_button.slot_index
	
	if _mouse_item:
		add_child(_mouse_item)
		_mouse_item.global_position = get_global_mouse_position()
		_inventory_data.remove_slot(_mouse_item.slot_data)

func _insert_item_in_slot(slot_button) -> void:
	var item = _mouse_item
	remove_child(_mouse_item)
	_mouse_item = null
	_build_source_slot_index = -1
	
	slot_button.insert(item)
	_inventory_data.insert_slot(slot_button.slot_index, item.slot_data)

func _swap_item_with_slot(slot_button) -> void:
	var original_mouse_data: Slot = _mouse_item.slot_data
	var temp_item: SlotItem = slot_button.take_item()
	
	remove_child(_mouse_item)
	slot_button.insert(_mouse_item)
	
	_mouse_item = temp_item
	add_child(_mouse_item)
	_mouse_item.global_position = get_global_mouse_position()
	
	_inventory_data.insert_slot(slot_button.slot_index, original_mouse_data)
	_build_source_slot_index = -1

func _mouse_right_slot_button(slot_button) -> void:
	if not slot_button.is_empty() and not _mouse_item:
		_split_half_from_slot(slot_button)
	elif slot_button.is_empty() and _mouse_item:
		_drop_one_to_slot(slot_button)
	elif not slot_button.is_empty() and _mouse_item:
		var slot_data: Slot = slot_button.contained_item_icon.slot_data
		var hand_data: Slot = _mouse_item.slot_data
		
		if slot_data.is_same_item(hand_data) and slot_data.count < slot_data.item.max_stack:
			_drop_one_to_slot(slot_button)

func _split_half_from_slot(slot_button) -> void:
	var slot_data: Slot = slot_button.contained_item_icon.slot_data
	var total_count: int = slot_data.count
	var hand_count: int = int((total_count + 1) / 2.0) 
	var left_count: int = total_count - hand_count   
	
	if left_count == 0:
		_take_item_from_slot(slot_button)
		return
		
	_mouse_item = _item_icon_scene.instantiate()
	
	var new_hand_data = Slot.new()
	new_hand_data.item = slot_data.item
	new_hand_data.count = hand_count
	_mouse_item.slot_data = new_hand_data
	_build_source_slot_index = slot_button.slot_index
	
	add_child(_mouse_item)
	_mouse_item.global_position = get_global_mouse_position()
	_mouse_item.slot_item_update()
	
	_inventory_data.sub_slot_count(slot_button.slot_index, hand_count)

func _drop_one_to_slot(slot_button) -> void:
	var hand_data: Slot = _mouse_item.slot_data
	
	if slot_button.is_empty():
		var new_icon = _item_icon_scene.instantiate()
		var new_slot_data = Slot.new()
		new_slot_data.item = hand_data.item
		new_slot_data.count = 1
		new_icon.slot_data = new_slot_data
		
		slot_button.insert(new_icon)
		new_icon.slot_item_update()
		_inventory_data.update_slot(slot_button.slot_index, new_slot_data)
	else:
		_inventory_data.add_slot_count(slot_button.slot_index, 1)

	hand_data.count -= 1
	
	if hand_data.count > 0:
		_mouse_item.slot_item_update()
	else:
		_mouse_item.queue_free()
		_mouse_item = null
		_build_source_slot_index = -1

func _consume_mouse_item() -> void:
	_mouse_item.slot_data.count -= 1
	if _mouse_item.slot_data.count <= 0:
		_mouse_item.queue_free()
		_mouse_item = null
		_build_source_slot_index = -1
		
		_exit_build_mode()
	else:
		_mouse_item.slot_item_update()

func _use_item(item: ItemData, spawn_pos: Vector2) -> bool:
	if not item is SpawnItemData:
		return false
	
	var spawn_data := item as SpawnItemData
	if spawn_data.entity_scene == null:
		return false
	
	var entity: Node = spawn_data.entity_scene.instantiate()
	if entity is Node2D:
		(entity as Node2D).global_position = spawn_pos
	
	var enemy_container = get_tree().current_scene.get_node_or_null("ModePlay/EntitiesContainer")
	if enemy_container:
		enemy_container.add_child(entity)
	else:
		get_tree().current_scene.add_child(entity)
	
	if spawn_data.payload_data != null and entity.has_method("setup"):
		entity.call("setup", spawn_data.payload_data)
	
	if entity.has_method("set_target"):
		var base = get_tree().get_first_node_in_group("Base")
		if base:
			entity.set_target(base.global_position)
	
	return true

func _set_build_mode_active(is_active: bool) -> void:
	if is_active:
		modulate.a = 0.3
		mouse_filter = MOUSE_FILTER_IGNORE
		if has_node("PanelContainer"):
			$PanelContainer.mouse_filter = MOUSE_FILTER_IGNORE
		for slot in _all_ui_slots:
			slot.mouse_filter = MOUSE_FILTER_IGNORE
	else:
		modulate.a = 1.0
		mouse_filter = MOUSE_FILTER_STOP
		if has_node("PanelContainer"):
			$PanelContainer.mouse_filter = MOUSE_FILTER_STOP
		for slot in _all_ui_slots:
			slot.mouse_filter = MOUSE_FILTER_STOP

func _cancel_build() -> void:
	if _mouse_item:
		_return_mouse_item_to_inventory()
		_mouse_item.queue_free()
		_mouse_item = null
		_build_source_slot_index = -1
	
	_exit_build_mode()

func _exit_build_mode() -> void:
	if _build_preview and _build_preview.is_active:
		_build_preview.deactivate()
	_set_build_mode_active(false)

func _return_mouse_item_to_inventory() -> void:
	if not _mouse_item or not _mouse_item.slot_data:
		return
	var item = _mouse_item.slot_data.item
	var count = _mouse_item.slot_data.count
	
	if _build_source_slot_index != -1 and _build_source_slot_index < _inventory_data.slots.size():
		var original_slot = _inventory_data.slots[_build_source_slot_index]
		if original_slot == null or original_slot.item == null:
			var new_slot = Slot.new()
			new_slot.item = item
			new_slot.count = count
			_inventory_data.insert_slot(_build_source_slot_index, new_slot)
			return
		elif original_slot.item == item and original_slot.count < item.max_stack:
			var add_amount = min(count, item.max_stack - original_slot.count)
			_inventory_data.add_slot_count(_build_source_slot_index, add_amount)
			count -= add_amount
			if count <= 0: return
	
	for i in range(_inventory_data.slots.size()):
		var slot = _inventory_data.slots[i]
		if slot and slot.item == item and slot.count < item.max_stack:
			var add_amount = min(count, item.max_stack - slot.count)
			_inventory_data.add_slot_count(i, add_amount)
			count -= add_amount
			if count <= 0: return
				
	for i in range(_inventory_data.slots.size()):
		var slot = _inventory_data.slots[i]
		if slot == null or slot.item == null:
			var new_slot = Slot.new()
			new_slot.item = item
			new_slot.count = count
			_inventory_data.insert_slot(i, new_slot)
			return
