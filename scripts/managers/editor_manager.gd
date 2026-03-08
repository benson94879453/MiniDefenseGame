extends Node2D
class_name EditorManager

@onready var grid_cursor: ColorRect = $GridCursor
@onready var editor_ui: CanvasLayer = $"../EditorUI"

# 當前編輯中的 LevelData
var current_level_data: LevelData

# 為了方便測試，暫時寫死一個塔的場景路徑
const TEST_TOWER_PATH = "res://entities/towers/base_tower.tscn"

func _ready() -> void:
	# 確保游標大小對齊網格
	if grid_cursor:
		grid_cursor.size = Vector2(MapManager.CELL_SIZE, MapManager.CELL_SIZE)
		
	# 載入當前存檔，如果沒有則開新局
	current_level_data = LevelManager.load_level()
	if not current_level_data:
		print("[EditorManager] 未找到存檔，初始化全新關卡")
		current_level_data = LevelData.new()
		# 初始化基礎網格結構從現存 TileMap 取得
		current_level_data.grid_data = MapManager.export_grid_data()
		
		# 加入一波預設測試波次，以免按 Play 沒東西
		var wave = WaveData.new()
		var spawn = WaveSpawnData.new()
		spawn.enemy_data = load("res://data/enemies/first_enemy.tres")
		spawn.spawn_count = 3
		spawn.spawn_interval = 1.0
		wave.spawns.append(spawn)
		current_level_data.waves.append(wave)
	else:
		# 將已記載的網格資料還原回 MapManager 以供 is_buildable 判斷
		MapManager.grid_data = current_level_data.grid_data.duplicate(true)
		_draw_preview_towers() # 將資料中已有的塔繪製為預覽圖

func _process(_delta: float) -> void:
	if not visible or not process_mode == Node.PROCESS_MODE_ALWAYS:
		return
		
	# 更新游標位置
	var mouse_pos = get_global_mouse_position()
	var grid_pos = MapManager.world_to_grid(mouse_pos)
	
	if grid_cursor:
		grid_cursor.global_position = MapManager.grid_to_world_top_left(grid_pos)
		
		# 游標顏色回饋
		if _can_place_tower_at(grid_pos):
			grid_cursor.color = Color(0, 1, 0, 0.4) # 綠色：可建造
		else:
			grid_cursor.color = Color(1, 0, 0, 0.4) # 紅色：不可建造

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not process_mode == Node.PROCESS_MODE_ALWAYS:
		return
		
	var mouse_pos = get_global_mouse_position()
	var grid_pos = MapManager.world_to_grid(mouse_pos)
	
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		# 左鍵放置塔
		if _can_place_tower_at(grid_pos):
			print("[EditorManager] 放置塔於: ", grid_pos)
			# 1. 登記到 MapManager (更新 is_buildable 狀態)
			MapManager.register_tower(grid_pos)
			# 2. 登記到當前 LevelData
			current_level_data.towers_data[grid_pos] = TEST_TOWER_PATH
			current_level_data.grid_data[grid_pos] = MapManager.CellState.OCCUPIED
			
			_spawn_preview_tower(grid_pos, TEST_TOWER_PATH)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# 右鍵拆除塔
		if current_level_data.towers_data.has(grid_pos):
			print("[EditorManager] 拆除塔於: ", grid_pos)
			MapManager.clear_cell(grid_pos)
			current_level_data.towers_data.erase(grid_pos)
			current_level_data.grid_data.erase(grid_pos) # 恢復為 EMPTY
			_remove_preview_tower(grid_pos)

## 進行建造判定與 A* 尋路防阻塞驗證
func _can_place_tower_at(grid_pos: Vector2i) -> bool:
	if not MapManager.is_buildable(grid_pos):
		return false
		
	# 這裡為了測試，暫時給定固定的出生地與基地座標 (未來應該從 Editor 介面或資料取得)
	# 假設生成點在上方入口，基地在下方
	var dummy_spawns = [MapManager.world_to_grid(Vector2(16, -16))] 
	var dummy_target = MapManager.world_to_grid(Vector2(720, 368))
	
	return MapManager.check_path_valid(grid_pos, dummy_spawns, dummy_target)


# ---- 視覺預覽層 (純顯示，無真實邏輯與碰撞) ----
var _preview_nodes: Dictionary = {}

func _draw_preview_towers():
	for grid_pos in current_level_data.towers_data:
		_spawn_preview_tower(grid_pos, current_level_data.towers_data[grid_pos])

func _spawn_preview_tower(grid_pos: Vector2i, _tower_path: String):
	# 建立一個半透明的 Sprite 作為預覽
	var sprite = Sprite2D.new()
	# 暫時用 Godot Icon，後續可以從 PackedScene 讀取 Texture
	sprite.texture = load("res://icon.svg") 
	sprite.scale = Vector2(0.25, 0.25) # 將 128x128 縮小為 32x32
	sprite.global_position = MapManager.grid_to_world(grid_pos)
	add_child(sprite)
	_preview_nodes[grid_pos] = sprite

func _remove_preview_tower(grid_pos: Vector2i):
	if _preview_nodes.has(grid_pos):
		_preview_nodes[grid_pos].queue_free()
		_preview_nodes.erase(grid_pos)

# 供 UI 呼叫
func save_current_level() -> void:
	LevelManager.save_level(current_level_data)
