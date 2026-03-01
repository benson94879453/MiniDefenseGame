extends Button

signal mouse_button_left_press
signal mouse_button_right_press

@onready var slot_background: ColorRect = %SlotBackground
@onready var center_container: CenterContainer = %CenterContainer

var slot_index: int
var contained_item_icon: SlotItem

func _ready() -> void:
	button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
	reset_color()

func reset_color():
	slot_background.color = Color(0.5, 0.5, 0.5, 0.8)

# 僅負責視覺上的放入
func insert(new_item_icon: SlotItem):
	contained_item_icon = new_item_icon
	slot_background.color = Color(0.7, 0.7, 0.7, 0.8)
	center_container.add_child(contained_item_icon)

func clear_box():
	if contained_item_icon:
		contained_item_icon.queue_free()
		contained_item_icon = null
	reset_color()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_button_left_press.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			mouse_button_right_press.emit()

# 僅負責視覺上的拔除
func take_item():
	var take_item_ = contained_item_icon
	center_container.remove_child(contained_item_icon)
	contained_item_icon = null
	reset_color()
	return take_item_

func is_empty():
	return !contained_item_icon
