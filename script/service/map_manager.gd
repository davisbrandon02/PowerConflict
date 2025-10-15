class_name MapManager
extends Node2D

# Handles loading, rendering, and logic for maps and tiles

# Represents the current map. Vector2i>MapTile
var current_map: Dictionary = {}
@export var obstacles: Node2D
@export var units: Node2D

# Load a map (a Node2D with child TileMapLayers)
func load_map(map: PackedScene):
	# Clear current_map
	current_map.clear()
	
	# Load ground tiles
	var init: Node2D = map.instantiate()
	var ground_layer: TileMapLayer = init.get_child(0)
	
	add_child(init)
	
	for cell_coords in ground_layer.get_used_cells():
		# Create MapTile object
		var map_tile: MapTile = MapTile.new()
		map_tile.pos = cell_coords
		current_map[cell_coords] = map_tile
		
		# Get the tile's source ID to assign ground type
		var source_id = ground_layer.get_cell_source_id(cell_coords)
		var ground_type: GroundType = GroundType.get_by_source_id(source_id)
		map_tile.ground = ground_type
	
	# Simply move the obstacles on the map into the entities list
	for o:Obstacle in init.get_child(1).get_children():
		var new_obstacle:Obstacle = o.duplicate()
		var pos = get_map_pos(o.position)
		obstacles.add_child(new_obstacle)
		new_obstacle.set_current_position(pos)
		current_map[pos].obstacle = new_obstacle
		
		# Destroy the old obstacle
		o.queue_free()
	
	# Move placed units (later will load dynamically)
	for u:Unit in init.get_child(2).get_children():
		var new_unit:Unit = u.duplicate()
		var pos = get_map_pos(u.position)
		units.add_child(new_unit)
		new_unit.set_current_position(pos)
		current_map[pos].units.append(new_unit)
		
		# Destroy the old unit
		u.queue_free()

func get_map_pos(pos: Vector2):
	return %OverlayLayer.local_to_map(pos)

# Represents what is currently on a tile
class MapTile:
	var pos: Vector2i
	var ground: GroundType
	var obstacle: Obstacle
	var units: Array[Unit]
