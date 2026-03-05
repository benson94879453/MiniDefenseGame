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

func _ready() -> void:
	# Optionally, you can initialize basic obstacles or paths here
	pass

## Initialize grid_data based on a TileMapLayer.
func init_from_tilemap(layer: TileMapLayer) -> void:
	# Iterate over all used cells in the TileMapLayer
	for cell_pos in layer.get_used_cells():
		var source_id = layer.get_cell_source_id(cell_pos)
		# Assuming source_id 0 is the barrier/obstacle
		if source_id == 0:
			grid_data[cell_pos] = CellState.OBSTACLE
		elif source_id == 1:
			# source_id 1 is floor, which is empty/buildable
			pass

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
	
	# If cell not recorded, default to EMPTY
	var state: int = grid_data.get(grid_pos, CellState.EMPTY)
	return state == CellState.EMPTY

## Mark a cell as occupied by a tower
func place_tower(grid_pos: Vector2i, tower_node: Node) -> bool:
	if not is_buildable(grid_pos):
		return false
	
	grid_data[grid_pos] = CellState.OCCUPIED
	
	if tower_node is Node2D:
		tower_node.global_position = grid_to_world(grid_pos)
		
	return true

## Register a path cell (e.g. called by the level or path system)
func set_path_cell(grid_pos: Vector2i) -> void:
	grid_data[grid_pos] = CellState.PATH

## Free a cell (e.g. if tower is sold)
func clear_cell(grid_pos: Vector2i) -> void:
	if grid_data.has(grid_pos):
		grid_data.erase(grid_pos)
