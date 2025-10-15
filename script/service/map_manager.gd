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
		current_map[pos].unit = new_unit
		
		# Destroy the old unit
		u.queue_free()

# Set a unit's position on the map directly and update tracking
func set_unit_pos(unit: Unit, new_pos: Vector2i) -> bool:
	# Check if target position is occupied by another living unit
	if current_map.has(new_pos) and current_map[new_pos].unit != null and current_map[new_pos].unit != unit:
		if current_map[new_pos].unit.health > 0:
			print("MAP: Cannot move %s to %s - tile occupied by %s" % [unit.entity_name, new_pos, current_map[new_pos].unit.entity_name])
			return false
	
	# Clear the old position
	var old_pos = unit.get_current_position()
	if current_map.has(old_pos) and current_map[old_pos].unit == unit:
		current_map[old_pos].unit = null
	
	# Set the new position
	unit.set_current_position(new_pos)
	
	# Update the unit's visual position
	var world_pos = %OverlayLayer.map_to_local(new_pos)
	unit.position = world_pos
	
	# Update the map tracking
	if current_map.has(new_pos):
		current_map[new_pos].unit = unit
	else:
		# Create new tile if it doesn't exist (shouldn't happen normally)
		var map_tile = MapTile.new()
		map_tile.pos = new_pos
		map_tile.unit = unit
		current_map[new_pos] = map_tile
	
	print("MAP: Moved %s from %s to %s" % [unit.entity_name, old_pos, new_pos])
	return true

func get_map_pos(pos: Vector2):
	return %OverlayLayer.local_to_map(pos)

# Represents what is currently on a tile
class MapTile:
	var pos: Vector2i
	var ground: GroundType
	var obstacle: Obstacle
	var unit: Unit
