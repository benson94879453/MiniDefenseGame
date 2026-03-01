extends Resource

class_name ItemData

# @export 將這些屬性暴露在編輯器中，方便企劃直接填寫資料
@export var id: int                # 道具唯一編號 (例如：1 是蘋果)
@export var name: String           # 道具名稱
@export var texture: Texture2D     # 道具的圖示
@export var max_stack: int = 64    # 最大堆疊數量
@export var description: String = "" # 道具描述
