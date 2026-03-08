extends Node

const CELL_SIZE := 32

enum CellState {
	EMPTY,
	PATH,
	OCCUPIED,
	OBSTACLE
}

# grid_data: Dictionary[Vector2i, int] -> { Vector2i(x, y): CellState }
var grid_data: Dictionary = {}

# Map limits (grid coordinates). For a 1280x720 screen, grid is 40x22.
var map_rect: Rect2i = Rect2i(0, 0, 40, 23)

# 用於路徑驗證與防呆的 AStarGrid2D 實例
var astargrid: AStarGrid2D

func _ready() -> void:
	astargrid = AStarGrid2D.new()
	astargrid.region = map_rect
	astargrid.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	astargrid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE # 允許斜走，但防穿牆
	astargrid.update()

## Initialize grid_data based on a TileMapLayer.
func init_from_tilemap(layer: TileMapLayer) -> void:
	# 先重置所有 AStarGrid 為可行走
	astargrid.fill_solid_region(map_rect, false)
	
	for cell_pos in layer.get_used_cells():
		var source_id = layer.get_cell_source_id(cell_pos)
		# Assuming source_id 0 is the barrier/obstacle
		if source_id == 0:
			grid_data[cell_pos] = CellState.OBSTACLE
			astargrid.set_point_solid(cell_pos, true)

## Convert global world position to grid coordinate
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floor(world_pos.x / float(CELL_SIZE)), floor(world_pos.y / float(CELL_SIZE)))

## Convert grid coordinate back to world position (center of the cell)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE + (CELL_SIZE / 2.0),
		grid_pos.y * CELL_SIZE + (CELL_SIZE / 2.0)
	)

## Convert grid coordinate to the top-left corner world position
func grid_to_world_top_left(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)

## Check if a specific cell is buildable
func is_buildable(grid_pos: Vector2i) -> bool:
	if not map_rect.has_point(grid_pos):
		return false
	var state: int = grid_data.get(grid_pos, CellState.EMPTY)
	return state == CellState.EMPTY

## 確認若在此點建塔，指定的幾組起終點是否仍有路徑相通
func check_path_valid(test_pos: Vector2i, spawns: Array[Vector2i], target: Vector2i) -> bool:
	astargrid.set_point_solid(test_pos, true) # 模擬放塔
	
	var all_valid = true
	for spawn in spawns:
		var path = astargrid.get_id_path(spawn, target)
		if path.is_empty():
			all_valid = false
			break
	
	astargrid.set_point_solid(test_pos, false) # 恢復原狀
	return all_valid

## 註冊並放置在編輯模式的塔 (僅更改資料不處理實體化，實體化由 UI 或 Editor 自己做)
func register_tower(grid_pos: Vector2i) -> bool:
	if not is_buildable(grid_pos):
		return false
	grid_data[grid_pos] = CellState.OCCUPIED
	astargrid.set_point_solid(grid_pos, true) # 同步更新尋路網格
	return true

## 將當前網格狀態匯出成 Dictionary 以供 LevelData 序列化
func export_grid_data() -> Dictionary:
	return grid_data.duplicate(true)

## 從 LevelData 注入資料 (包含地形狀態與實例化已存好的塔)
func import_data(data: LevelData, entities_container: Node2D) -> void:
	grid_data.clear()
	
	# 1. 載入網格狀態 (例如路徑、玩家放置的靜態障礙物)
	if data.grid_data:
		grid_data = data.grid_data.duplicate(true)
		
	# 2. 實例化所有存檔的塔
	if data.towers_data:
		for grid_pos in data.towers_data:
			var tower_path = data.towers_data[grid_pos]
			var tower_scene = load(tower_path) as PackedScene
			if tower_scene:
				var tower_instance = tower_scene.instantiate() as Node2D
				# 確保在生成時動態綁定必要的 Signal (解除手動依賴)
				if tower_instance.has_signal("target_killed"):
					# 這裡如果是 GameManager 處理獎勵，或塔自己處理，可以動態綁定
					pass
				
				tower_instance.global_position = grid_to_world(grid_pos)
				entities_container.add_child(tower_instance)
				grid_data[grid_pos] = CellState.OCCUPIED

## Free a cell (e.g. if tower is sold or destroyed)
func clear_cell(grid_pos: Vector2i) -> void:
	if grid_data.has(grid_pos):
		grid_data.erase(grid_pos)
	astargrid.set_point_solid(grid_pos, false)
