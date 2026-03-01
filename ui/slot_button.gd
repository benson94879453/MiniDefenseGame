extends Button

@onready var slot_background: ColorRect = %SlotBackground
@onready var center_container: CenterContainer = %CenterContainer

# 這個按鈕肚子裡裝著的「實體圖示」節點 (取代原本冗長的 slot_button_slot_item)
var contained_item_icon: SlotItem

func _ready() -> void:
	reset_color()

# 恢復沒有道具時的暗色背景
func reset_color():
	slot_background.color = Color(0.5, 0.5, 0.5, 0.8)

# 將生成的道具圖示塞進這個方格中
func insert(new_item_icon: SlotItem):
	contained_item_icon = new_item_icon
	slot_background.color = Color(0.7, 0.7, 0.7, 0.8)
	center_container.add_child(contained_item_icon)

# [新增優化] 負責清空這格 UI，把肚子裡的圖示刪除並恢復顏色
func clear_box():
	if contained_item_icon:
		contained_item_icon.queue_free() # 刪除圖示節點
		contained_item_icon = null       # 把變數清空
	reset_color()
