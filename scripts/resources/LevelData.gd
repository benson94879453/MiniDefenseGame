extends Resource
class_name LevelData

@export var map_name: String = "未命名關卡"
@export var initial_gold: int = 100

# 1. 地形與障礙物配置
# 儲存格式: { Vector2i(x, y): int (CellState) }
@export var grid_data: Dictionary = {}

# 2. 防禦塔配置配置
# 儲存格式: { Vector2i(x, y): String (Tower ID/Path) }
@export var towers_data: Dictionary = {}

# 3. 波次設定
@export var waves: Array[WaveData] = []
