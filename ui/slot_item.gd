extends Control
class_name SlotItem

@onready var item_texture: TextureRect = %ItemTexture
@onready var amount_label: Label = %AmountLabel

# 這個 UI 負責顯示的「資料來源」 (取代原本很雷的 slot_)
var slot_data: Slot	

# 根據資料，更新圖片與數字
func slot_item_update():
	# 防呆檢查：如果沒有綁定資料，或資料裡面沒有物品，就提早退出
	if not slot_data or not slot_data.item:
		return
		
	# 顯示對應的物品圖片
	item_texture.visible = true
	item_texture.texture = slot_data.item.texture
	
	# 如果數量大於 1，才顯示右下角的數字標籤
	if slot_data.count > 1:
		amount_label.visible = true
		amount_label.text = str(slot_data.count)
	else:
		amount_label.visible = false
