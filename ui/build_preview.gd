extends Node2D
class_name BuildPreview

@export var valid_color: Color = Color(0, 1, 0, 0.4)
@export var invalid_color: Color = Color(1, 0, 0, 0.4)

@onready var color_rect: ColorRect = $ColorRect

var is_active := false
var current_grid_pos := Vector2i.ZERO
var can_build := false

func _ready() -> void:
	visible = false
	color_rect.size = Vector2(MapManager.CELL_SIZE, MapManager.CELL_SIZE)
	# Center the rect so the position is the center of the cell
	color_rect.position = Vector2(-MapManager.CELL_SIZE / 2.0, -MapManager.CELL_SIZE / 2.0)

func _process(_delta: float) -> void:
	if not is_active:
		return
		
	var mouse_pos = get_global_mouse_position()
	current_grid_pos = MapManager.world_to_grid(mouse_pos)
	
	# Snap to the center of the grid cell
	global_position = MapManager.grid_to_world(current_grid_pos)
	
	# Check buildability
	can_build = MapManager.is_buildable(current_grid_pos)
	
	# Update color based on buildability
	color_rect.color = valid_color if can_build else invalid_color

func activate() -> void:
	is_active = true
	visible = true
	set_process(true)

func deactivate() -> void:
	is_active = false
	visible = false
	set_process(false)
