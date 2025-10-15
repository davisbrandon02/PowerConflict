class_name PathfindingService
extends Node2D

# References
@export var map_manager: MapManager

# A* pathfinding data
var astar: AStar2D
var point_ids: Dictionary  # Vector2i -> point_id

func _ready() -> void:
	print("Pathfinding Service initialized")
	rebuild_navigation_graph()

func rebuild_navigation_graph() -> void:
	print("Pathfinding: Rebuilding navigation graph...")
	astar = AStar2D.new()
	point_ids.clear()
	
	# Add all walkable positions as points
	var point_id = 0
	for cell_pos in map_manager.current_map.keys():
		var tile = map_manager.current_map[cell_pos]
		if is_position_walkable(cell_pos, Unit.UNIT_TYPE.INFANTRY):  # Default to infantry
			astar.add_point(point_id, Vector2(cell_pos))
			point_ids[cell_pos] = point_id
			point_id += 1
	
	# Connect adjacent walkable positions
	for cell_pos in point_ids.keys():
		var current_id = point_ids[cell_pos]
		
		# Check all 4 directions
		var directions = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
		for direction in directions:
			var neighbor_pos = cell_pos + direction
			if point_ids.has(neighbor_pos):
				var neighbor_id = point_ids[neighbor_pos]
				# Only connect if not already connected (AStar2D is bidirectional)
				if not astar.are_points_connected(current_id, neighbor_id):
					astar.connect_points(current_id, neighbor_id)
	
	print("Pathfinding: Graph built with ", point_ids.size(), " nodes")

# Main pathfinding function
func find_path(start: Vector2i, end: Vector2i, unit_type: Unit.UNIT_TYPE) -> Array[Vector2i]:
	if not is_position_walkable(end, unit_type):
		# Target is unwalkable, find nearest walkable position
		var fallback_target = find_nearest_walkable_position(end, unit_type)
		if fallback_target == start:
			return []  # No path possible
		return find_path(start, fallback_target, unit_type)
	
	if not point_ids.has(start) or not point_ids.has(end):
		return []
	
	var start_id = point_ids[start]
	var end_id = point_ids[end]
	
	var path_positions = astar.get_point_path(start_id, end_id)
	
	# Convert from Vector2 to Vector2i
	var path = []
	for pos in path_positions:
		path.append(Vector2i(pos))
	
	return path

# Get just the next step toward target (for AI decision making)
func get_next_step_toward(start: Vector2i, end: Vector2i, unit_type: Unit.UNIT_TYPE) -> Vector2i:
	var full_path = find_path(start, end, unit_type)
	if full_path.size() > 1:
		return full_path[1]  # [0] is start position, [1] is next step
	return start  # Can't move or already at target

# Check if a position is walkable for a given unit type
func is_position_walkable(pos: Vector2i, unit_type: Unit.UNIT_TYPE) -> bool:
	if not map_manager.current_map.has(pos):
		return false
	
	var tile = map_manager.current_map[pos]
	
	# Check ground accessibility
	if not is_ground_accessible(tile.ground, unit_type):
		return false
	
	# Check obstacle accessibility (but allow passing through obstacles if ground is accessible)
	if tile.obstacle:
		if not is_obstacle_passable(tile.obstacle, unit_type):
			return false
	
	# IMPORTANT: Don't check for other units here - allow pathing through them
	# The AI will handle final position validation in move_unit_to()
	
	return true

func is_ground_accessible(ground: GroundType, unit_type: Unit.UNIT_TYPE) -> bool:
	if not ground:
		return false
	
	match unit_type:
		Unit.UNIT_TYPE.INFANTRY:
			return ground.ground_accessible
		Unit.UNIT_TYPE.LOADED_MECH:
			return ground.ground_accessible
		Unit.UNIT_TYPE.MECH:
			return ground.ground_accessible or ground.air_accessible
	return false

func is_obstacle_passable(obstacle: Obstacle, unit_type: Unit.UNIT_TYPE) -> bool:
	if not obstacle:
		return true
	
	match unit_type:
		Unit.UNIT_TYPE.INFANTRY:
			return obstacle.ground_accessible
		Unit.UNIT_TYPE.LOADED_MECH:
			return obstacle.ground_accessible
		Unit.UNIT_TYPE.MECH:
			return obstacle.ground_accessible or obstacle.air_accessible
	return false

# Find nearest walkable position to an unwalkable target
func find_nearest_walkable_position(target: Vector2i, unit_type: Unit.UNIT_TYPE) -> Vector2i:
	if is_position_walkable(target, unit_type):
		return target
	
	# Search in expanding rings around target
	var search_radius = 1
	var max_search_radius = 10
	
	while search_radius <= max_search_radius:
		for x in range(-search_radius, search_radius + 1):
			for y in range(-search_radius, search_radius + 1):
				# Only check perimeter of current search radius
				if abs(x) == search_radius or abs(y) == search_radius:
					var check_pos = target + Vector2i(x, y)
					if is_position_walkable(check_pos, unit_type):
						return check_pos
		search_radius += 1
	
	# Fallback: return start position (no walkable position found)
	return target

# Get movement range for a unit (all reachable positions within movement cost)
func get_movement_range(start: Vector2i, movement_points: int, unit_type: Unit.UNIT_TYPE) -> Array[Vector2i]:
	var reachable_positions = []
	var visited = {}
	var to_visit = [{ "pos": start, "cost": 0 }]
	
	while to_visit.size() > 0:
		var current = to_visit.pop_front()
		var current_pos = current["pos"]
		var current_cost = current["cost"]
		
		if visited.has(current_pos):
			continue
		
		visited[current_pos] = true
		reachable_positions.append(current_pos)
		
		# Check all neighbors
		var directions = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
		for direction in directions:
			var neighbor_pos = current_pos + direction
			var move_cost = current_cost + get_movement_cost(current_pos, neighbor_pos, unit_type)
			
			if (not visited.has(neighbor_pos) and 
				move_cost <= movement_points and 
				is_position_walkable(neighbor_pos, unit_type)):
				
				to_visit.append({ "pos": neighbor_pos, "cost": move_cost })
	
	return reachable_positions

# Calculate movement cost between two adjacent positions
func get_movement_cost(from: Vector2i, to: Vector2i, unit_type: Unit.UNIT_TYPE) -> int:
	# Base cost is 1, can be modified by terrain type
	if not map_manager.current_map.has(to):
		return 999  # Unwalkable
	
	var tile = map_manager.current_map[to]
	var base_cost = 1
	
	# Add terrain cost modifiers
	if tile.ground:
		# Example: rough terrain costs more
		pass
	
	# Add obstacle cost modifiers
	if tile.obstacle:
		# Example: moving through forests costs more
		pass
	
	return base_cost

# Check line of sight between two positions (for AI vision)
func has_line_of_sight(from: Vector2i, to: Vector2i, unit_type: Unit.UNIT_TYPE) -> bool:
	var line_points = get_line_points(from, to)
	
	for i in range(1, line_points.size()):  # Skip first point (viewer's position)
		var point = line_points[i]
		
		if not map_manager.current_map.has(point):
			return false
		
		var tile = map_manager.current_map[point]
		
		# Check ground obstruction
		if tile.ground and tile.ground.obstructs_view:
			return false
		
		# Check obstacle obstruction based on unit type
		if tile.obstacle:
			match unit_type:
				Unit.UNIT_TYPE.INFANTRY, Unit.UNIT_TYPE.LOADED_MECH:
					if tile.obstacle.obstructs_ground_view:
						return false
				Unit.UNIT_TYPE.MECH:
					if tile.obstacle.obstructs_air_view:
						return false
		
		# Stop when we reach target
		if point == to:
			break
	
	return true

# Bresenham's line algorithm for LOS checking
func get_line_points(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var points = []
	var dx = absi(to.x - from.x)
	var dy = -absi(to.y - from.y)
	var sx = 1 if from.x < to.x else -1
	var sy = 1 if from.y < to.y else -1
	var err = dx + dy
	
	var current = from
	while true:
		points.append(current)
		if current == to:
			break
		
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			current.x += sx
		if e2 <= dx:
			err += dx
			current.y += sy
	
	return points

# Update graph when map changes (units move, obstacles destroyed, etc.)
func update_graph_for_position(pos: Vector2i, unit_type: Unit.UNIT_TYPE) -> void:
	if point_ids.has(pos):
		var point_id = point_ids[pos]
		var is_walkable_now = is_position_walkable(pos, unit_type)
		
		# If walkability changed, we need to rebuild connections
		# For simplicity, we'll just rebuild the entire graph when major changes happen
		# In a more optimized version, you'd only update local connections

# Quick path validation for AI
func is_path_possible(start: Vector2i, end: Vector2i, unit_type: Unit.UNIT_TYPE) -> bool:
	return find_path(start, end, unit_type).size() > 0

# Get path length (number of steps)
func get_path_length(start: Vector2i, end: Vector2i, unit_type: Unit.UNIT_TYPE) -> int:
	var path = find_path(start, end, unit_type)
	return path.size() - 1 if path.size() > 0 else 999  # -1 because start is included
	
# Use this for pathfinding (allows moving through units)
func is_position_pathable(pos: Vector2i, unit_type: Unit.UNIT_TYPE) -> bool:
	if not map_manager.current_map.has(pos):
		return false
	
	var tile = map_manager.current_map[pos]
	
	# Check ground accessibility
	if not is_ground_accessible(tile.ground, unit_type):
		return false
	
	# Check obstacle accessibility
	if tile.obstacle:
		if not is_obstacle_passable(tile.obstacle, unit_type):
			return false
	
	return true

# Use this for final destination validation (checks unit occupancy)
func is_position_occupiable(pos: Vector2i, unit_type: Unit.UNIT_TYPE) -> bool:
	if not is_position_pathable(pos, unit_type):
		return false
	
	var tile = map_manager.current_map[pos]
	
	# Final position cannot be occupied by another living unit
	if tile.unit and tile.unit.health > 0:
		return false
	
	return true
