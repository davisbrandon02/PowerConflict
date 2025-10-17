class_name MapManager
extends Node2D

# Handles loading, rendering, and logic for maps and tiles

# Represents the current map. Vector2i>MapTile
var current_map: Dictionary = {}
@export var obstacles: Node2D
@export var units: Node2D

@export var pathfinding_service: PathfindingService

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


func get_map_pos(pos: Vector2):
	return %OverlayLayer.local_to_map(pos)

# Get all enemies visible from a given position and unit type
func get_visible_enemies(from_unit: Unit) -> Array[Unit]:
	var enemies: Array[Unit] = []
	var from_pos = from_unit.get_current_position()
	
	for other_unit: Unit in units.get_children():
		if other_unit == from_unit or other_unit.health <= 0 or other_unit.side == from_unit.side:
			continue
		
		var to_pos = other_unit.get_current_position()  # Store in local variable
		var distance = from_pos.distance_to(to_pos)
		if distance <= from_unit.sight and has_line_of_sight_from_unit(from_unit, from_pos, to_pos):
			enemies.append(other_unit)
	
	return enemies

# Directly set the position of a unit. All unit position setting should pass through this function
func set_unit_pos(unit: Unit, pos: Vector2i):
	# Clear the old position
	var old_pos = unit.get_current_position()
	if current_map.has(old_pos) and current_map[old_pos].unit == unit:
		current_map[old_pos].unit = null
	
	# Set the new position
	unit.set_current_position(pos)
	
	# Update the unit's visual position
	var world_pos = %OverlayLayer.map_to_local(pos)
	unit.position = world_pos
	
	# Update the map tracking
	if current_map.has(pos):
		current_map[pos].unit = unit
	else:
		# Create new tile if it doesn't exist (shouldn't happen normally)
		var map_tile = MapTile.new()
		map_tile.pos = pos
		map_tile.unit = unit
		current_map[pos] = map_tile
	
	print("MAP: Moved %s from %s to %s" % [unit.entity_name, old_pos, pos])
	return true

# Move unit from one position to another
func move_unit(unit: Unit, pos: Vector2i):
	if can_move_to_pos(unit, pos):
		set_unit_pos(unit, pos)

# Check if MapTile is able to be moved to by unit
func can_move_to_pos(unit: Unit, pos: Vector2i):
	if current_map.has(pos):
		var tile: MapTile = current_map[pos]
		
		# Return false if already occupied by a unit
		if tile.unit != null:
			return false
		
		# Return false if blocked by obstacle
		if tile.obstacle != null and !matches_movement_type(unit, tile):
			return false
		
		return true
	return false

# Checks if unit's movement type matches the ground tile
func matches_movement_type(unit: Unit, tile: MapTile):
	if tile.obstacle == null:
		return true
	
	match unit.movement_type:
		Unit.MOVEMENT_TYPE.GROUND:
			return tile.obstacle.ground_accessible
		Unit.MOVEMENT_TYPE.WATER:
			return tile.obstacle.sea_accessible
		Unit.MOVEMENT_TYPE.AIR:
			return tile.obstacle.sea_accessible
		Unit.MOVEMENT_TYPE.AMPHIBIOUS:
			# Both ground and sea accessible
			return tile.obstacle.ground_accessible or tile.obstacle.sea_accessible

# Check line of sight from a unit at a specific position to a target position
func has_line_of_sight_from_unit(from_unit: Unit, from_pos: Vector2i, to_pos: Vector2i) -> bool:
	return pathfinding_service.has_line_of_sight(from_pos, to_pos, from_unit.unit_type)

# Represents what is currently on a tile
class MapTile:
	var pos: Vector2i
	var ground: GroundType
	var obstacle: Obstacle
	var unit: Unit
