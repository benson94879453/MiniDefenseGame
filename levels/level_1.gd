extends Node2D

@onready var tilemap_layer: TileMapLayer = $NavigationRegion2D/TileMapLayer

func _ready() -> void:
	# Initialize the map manager grid with the obstacles/paths from the tilemap
	if tilemap_layer:
		MapManager.init_from_tilemap(tilemap_layer)
