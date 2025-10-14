class_name MapManager
extends Node2D

# Handles loading, rendering, and logic for maps and tiles

# Represents the current map. Vector2i>MapTile
var current_map: Dictionary = {}

# Load a map (a Node2D with child TileMapLayers)
func load_map(map: PackedScene):
	# Clear current_map
	current_map.clear()
	
	# Load ground tiles
	var init: Node2D = map.instantiate()
	var ground_layer: TileMapLayer = init.get_child(0)
	var obstacle_layer: TileMapLayer = init.get_child(1)
	
	add_child(init)
	
	for cell_coords in ground_layer.get_used_cells():
		# Create MapTile object
		var map_tile: MapTile = MapTile.new()
		current_map[cell_coords] = map_tile
		
		# Get the tile's source ID to assign ground type
		var source_id = ground_layer.get_cell_source_id(cell_coords)
		var ground_type: GroundType = GroundType.get_by_source_id(source_id)
		map_tile.ground = ground_type
	
	# Simply move the obstacles on the map into the entities list
	
	# Destroy the obstacle layer on the map since they are now represented by physical entities
	
	# Move placed units (later will load dynamically)
	# Update placed units current_position
	
	

# Represents what is currently on a tile
class MapTile:
	var ground: GroundType
	var obstacle: Obstacle
	var unit: Array[Unit]
