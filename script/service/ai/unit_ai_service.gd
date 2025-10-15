class_name UnitAIService
extends Node2D

# Executes tactical orders at the unit level - THE BRUTAL SERGEANT
@export var tactical_ai: TacticalAIService
@export var map_manager: MapManager
@export var pathfinding_service: PathfindingService
@export var action_manager: ActionManager

var unit_memory: Dictionary = {}  # unit_id -> remembered threats/positions

func execute_unit_turn(unit: Unit) -> void:
	print("UNIT AI: %s beginning combat operations" % unit.entity_name)
	
	var current_order = tactical_ai.current_orders.get(unit.get_instance_id())
	
	if current_order:
		execute_order(unit, current_order)
	else:
		execute_autonomous_behavior(unit)
	
	# AI turn complete - immediately notify ActionManager
	print("UNIT AI: %s combat operations complete" % unit.entity_name)
	action_manager.end_current_turn()

func execute_order(unit: Unit, order: TacticalOrder) -> void:
	print("UNIT AI: %s executing ORDER: %s (Aggression: %.1f)" % [unit.entity_name, order.get_order_description(), order.aggression_level])
	
	match order.order_type:
		TacticalOrder.OrderType.ADVANCE:
			execute_advance_order(unit, order)
		TacticalOrder.OrderType.ASSAULT:
			execute_assault_order(unit, order)
		TacticalOrder.OrderType.DEFEND:
			execute_defend_order(unit, order)
		TacticalOrder.OrderType.FLANK:
			execute_flank_order(unit, order)
		TacticalOrder.OrderType.SUPPRESS:
			execute_suppress_order(unit, order)
		TacticalOrder.OrderType.RETREAT:
			execute_retreat_order(unit, order)
		TacticalOrder.OrderType.RECON:
			execute_recon_order(unit, order)
		TacticalOrder.OrderType.DRONE_STRIKE:
			execute_drone_strike_order(unit, order)
		TacticalOrder.OrderType.AMBUSH:
			execute_ambush_order(unit, order)

func execute_advance_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		# CONTACT! Switch to aggressive advance under fire
		print("UNIT AI: %s made contact during advance - engaging aggressively" % unit.entity_name)
		var closest_enemy = get_closest_enemy(unit, visible_enemies)
		
		if can_attack_enemy(unit, closest_enemy):
			attack_enemy(unit, closest_enemy)
			# Continue advancing after attack if possible
			if unit.weapons.size() > 1:  # Has multiple weapons/actions
				var next_pos = get_next_move_toward(unit, order.primary_target)
				if is_position_safe(unit, next_pos, visible_enemies):
					move_unit_to(unit, next_pos)
		else:
			# Bound forward using cover
			var advance_pos = find_bounding_position(unit, order.primary_target, visible_enemies)
			move_unit_to(unit, advance_pos)
	else:
		# Steady advance toward objective
		var next_pos = get_next_move_toward(unit, order.primary_target)
		move_unit_to(unit, next_pos)

func execute_assault_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		# MAXIMUM AGGRESSION - prioritize eliminating threats
		print("UNIT AI: %s conducting assault - maximum aggression" % unit.entity_name)
		var target_enemy = order.target_unit if order.target_unit else get_most_dangerous_enemy(unit, visible_enemies)
		
		if can_attack_enemy(unit, target_enemy):
			attack_enemy(unit, target_enemy)
			# Assault units push forward relentlessly
			if unit.health > unit.max_health * 0.3:  # Only if not critically damaged
				var assault_pos = get_close_assault_position(unit, target_enemy.get_current_position())
				move_unit_to(unit, assault_pos)
		else:
			# Close distance at all costs
			var assault_pos = get_danger_close_position(unit, target_enemy.get_current_position())
			move_unit_to(unit, assault_pos)
	else:
		# Move rapidly toward assault objective
		var next_pos = get_next_move_toward(unit, order.primary_target)
		move_unit_to(unit, next_pos)
		# Set up for anticipated contact
		unit.set_fortified(false)  # Stay mobile for assault

func execute_defend_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		print("UNIT AI: %s defending position - engaging threats" % unit.entity_name)
		# Defenders prioritize survival while eliminating threats
		var enemies_in_range = get_enemies_in_weapon_range(unit, visible_enemies)
		
		if enemies_in_range.size() > 0:
			# Engage most dangerous target first
			var target = get_most_dangerous_enemy(unit, enemies_in_range)
			attack_enemy(unit, target)
		else:
			# Hold position and fortify
			unit.set_fortified(true)
	else:
		# Prepare defensive position
		unit.set_fortified(true)
		print("UNIT AI: %s fortifying defensive position" % unit.entity_name)

func execute_flank_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = get_visible_enemies(unit)
	
	if visible_enemies.size() > 0 and not is_unit_flanking(unit, visible_enemies[0]):
		# Still working on flanking maneuver
		var next_pos = get_next_move_toward(unit, order.primary_target)
		if is_position_concealed(unit, next_pos):
			move_unit_to(unit, next_pos)
		else:
			# Use alternative concealed route
			var alt_route = find_concealed_flank_route(unit, order.primary_target)
			move_unit_to(unit, alt_route)
	else:
		# In flanking position - attack!
		if visible_enemies.size() > 0:
			var flanked_enemy = visible_enemies[0]
			print("UNIT AI: %s executing flank attack!" % unit.entity_name)
			attack_enemy(unit, flanked_enemy)

func execute_suppress_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		var suppression_target = order.target_unit if order.target_unit else get_best_suppression_target(unit, visible_enemies)
		if can_attack_enemy(unit, suppression_target):
			print("UNIT AI: %s providing suppressing fire" % unit.entity_name)
			attack_enemy(unit, suppression_target)
			# Suppression fire doesn't move much
	else:
		# Move to suppression position
		var next_pos = get_next_move_toward(unit, order.primary_target)
		move_unit_to(unit, next_pos)

func execute_retreat_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		# Fighting retreat - shoot while moving back
		var closest_enemy = get_closest_enemy(unit, visible_enemies)
		if can_attack_enemy(unit, closest_enemy) and unit.health > unit.max_health * 0.4:
			attack_enemy(unit, closest_enemy)
	
	# Always move toward retreat position
	var next_pos = get_next_move_toward(unit, order.primary_target)
	if is_position_safe(unit, next_pos, visible_enemies):
		move_unit_to(unit, next_pos)
		print("UNIT AI: %s conducting tactical retreat" % unit.entity_name)

func execute_recon_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		# Report contact and avoid engagement
		print("UNIT AI: %s recon unit spotted enemy - reporting and evading" % unit.entity_name)
		var retreat_pos = find_evasion_position(unit, visible_enemies)
		move_unit_to(unit, retreat_pos)
	else:
		# Continue reconnaissance
		var next_pos = get_next_move_toward(unit, order.primary_target)
		move_unit_to(unit, next_pos)

func execute_drone_strike_order(unit: Unit, order: TacticalOrder) -> void:
	# Coordinate with drone assets
	print("UNIT AI: %s coordinating drone strike" % unit.entity_name)
	# This would interface with your drone/system
	# drone_system.request_strike(order.primary_target)

func execute_ambush_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		# Spring ambush!
		print("UNIT AI: %s springing ambush!" % unit.entity_name)
		var ambush_target = get_most_vulnerable_enemy(unit, visible_enemies)
		attack_enemy(unit, ambush_target)
	else:
		# Wait in ambush position
		unit.set_fortified(true)
		print("UNIT AI: %s waiting in ambush position" % unit.entity_name)

func execute_autonomous_behavior(unit: Unit) -> void:
	print("UNIT AI: %s using autonomous combat protocols" % unit.entity_name)
	var visible_enemies = get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		# BRUTAL AUTONOMOUS COMBAT - no mercy
		var closest_enemy = get_closest_enemy(unit, visible_enemies)
		
		if can_attack_enemy(unit, closest_enemy):
			attack_enemy(unit, closest_enemy)
			# Aggressive follow-up - close for kill
			if unit.health > unit.max_health * 0.6:
				var advance_pos = get_aggressive_advance_position(unit, closest_enemy.get_current_position())
				move_unit_to(unit, advance_pos)
		else:
			# Close distance aggressively
			var assault_pos = get_danger_close_position(unit, closest_enemy.get_current_position())
			move_unit_to(unit, assault_pos)
	else:
		# Hunt for enemy - move toward last known positions or objectives
		var hunt_target = get_hunt_position(unit)
		move_unit_to(unit, hunt_target)

# MODERN WARFARE TACTICAL HELPERS
func find_bounding_position(unit: Unit, target: Vector2i, enemies: Array[Unit]) -> Vector2i:
	# Find next cover position toward target while avoiding enemy fire
	var possible_positions = []
	for i in range(-2, 3):
		for j in range(-2, 3):
			var check_pos = unit.get_current_position() + Vector2i(i, j)
			if is_position_accessible(unit, check_pos) and has_cover(check_pos) and is_position_safe(unit, check_pos, enemies):
				possible_positions.append(check_pos)
	
	if possible_positions.size() > 0:
		return get_closest_position_to_target(possible_positions, target)
	return get_next_move_toward(unit, target)

func get_danger_close_position(unit: Unit, enemy_pos: Vector2i) -> Vector2i:
	# Get dangerously close for maximum effect
	var direction_vec = Vector2(enemy_pos - unit.get_current_position()).normalized()
	return unit.get_current_position() + Vector2i(direction_vec * 2)

func get_close_assault_position(unit: Unit, enemy_pos: Vector2i) -> Vector2i:
	# Close assault - get within point-blank range
	var direction_vec = Vector2(enemy_pos - unit.get_current_position()).normalized()
	return enemy_pos + Vector2i(-direction_vec)

func is_position_safe(unit: Unit, pos: Vector2i, enemies: Array[Unit]) -> bool:
	for enemy in enemies:
		if pos.distance_to(enemy.get_current_position()) <= get_weapon_range(enemy):
			return false
	return true

func is_position_concealed(unit: Unit, pos: Vector2i) -> bool:
	if map_manager.current_map.has(pos):
		var tile = map_manager.current_map[pos]
		# Position is concealed if it has cover or obstructing terrain
		return (tile.obstacle and tile.obstacle.defense_multiplier > 1.0) or (tile.ground and tile.ground.obstructs_view)
	return false

func get_most_dangerous_enemy(unit: Unit, enemies: Array[Unit]) -> Unit:
	# Prioritize enemies that can do the most damage
	var most_dangerous = null
	var highest_threat = 0.0
	
	for enemy in enemies:
		var threat = calculate_enemy_threat(unit, enemy)
		if threat > highest_threat:
			highest_threat = threat
			most_dangerous = enemy
	
	return most_dangerous

func calculate_enemy_threat(unit: Unit, enemy: Unit) -> float:
	var distance = unit.get_current_position().distance_to(enemy.get_current_position())
	var weapon_threat = 1.0
	if enemy.weapons.size() > 0:
		weapon_threat = (enemy.weapons[0].hard_damage + enemy.weapons[0].soft_damage) / 2.0
	
	# Closer enemies and higher damage enemies are more threatening
	return weapon_threat / (distance + 1.0)

func get_most_vulnerable_enemy(unit: Unit, enemies: Array[Unit]) -> Unit:
	# Find enemy with least health/defense for quick kills
	var most_vulnerable = null
	var lowest_health = INF
	
	for enemy in enemies:
		if enemy.health < lowest_health:
			lowest_health = enemy.health
			most_vulnerable = enemy
	
	return most_vulnerable

func get_enemies_in_weapon_range(unit: Unit, enemies: Array[Unit]) -> Array[Unit]:
	var in_range = []
	for enemy in enemies:
		if can_attack_enemy(unit, enemy):
			in_range.append(enemy)
	return in_range

func is_unit_flanking(unit: Unit, enemy: Unit) -> bool:
	# Simple flank check - different approach direction
	var unit_to_enemy = Vector2(enemy.get_current_position() - unit.get_current_position()).normalized()
	# Check if approach is not primarily from front/back (more from side)
	return abs(unit_to_enemy.x) > 0.3 and abs(unit_to_enemy.y) > 0.3

func find_concealed_flank_route(unit: Unit, target: Vector2i) -> Vector2i:
	# Find alternative route that maintains concealment
	var current_pos = unit.get_current_position()
	var direction_vec = Vector2(target - current_pos).normalized()
	
	# Try perpendicular directions first for flanking
	var flank_dir = Vector2i(Vector2(-direction_vec.y, direction_vec.x))
	return current_pos + flank_dir

func get_best_suppression_target(unit: Unit, enemies: Array[Unit]) -> Unit:
	# Suppress enemies that are most dangerous to allies
	return get_most_dangerous_enemy(unit, enemies)

func find_evasion_position(unit: Unit, enemies: Array[Unit]) -> Vector2i:
	# Move away from all enemies
	var avg_enemy_pos = Vector2i.ZERO
	for enemy in enemies:
		avg_enemy_pos += enemy.get_current_position()
	avg_enemy_pos /= enemies.size()
	
	var escape_vec = Vector2(unit.get_current_position() - avg_enemy_pos).normalized()
	return unit.get_current_position() + Vector2i(escape_vec * 3)

func get_aggressive_advance_position(unit: Unit, enemy_pos: Vector2i) -> Vector2i:
	# Continue pressing the attack
	var direction_vec = Vector2(enemy_pos - unit.get_current_position()).normalized()
	return unit.get_current_position() + Vector2i(direction_vec * 2)

func get_hunt_position(unit: Unit) -> Vector2i:
	# Hunt toward suspected enemy positions or objectives
	if unit_memory.has(unit.get_instance_id()) and unit_memory[unit.get_instance_id()].has("last_known_enemy"):
		return unit_memory[unit.get_instance_id()]["last_known_enemy"]
	return tactical_ai.get_primary_objective(unit.side)

# BASIC COMBAT ACTIONS (interface with your systems)
func attack_enemy(unit: Unit, enemy: Unit) -> void:
	print("UNIT AI: %s ENGAGING %s with lethal force" % [unit.entity_name, enemy.entity_name])
	# This would call your combat system: unit.attack(enemy)

func move_unit_to(unit: Unit, target_pos: Vector2i) -> void:
	# Check if the final position is accessible (including unit occupancy)
	if is_position_accessible(unit, target_pos):
		print("UNIT AI: %s moving to combat position %s" % [unit.entity_name, target_pos])
		# Use MapManager to properly track unit positions
		var success = map_manager.set_unit_pos(unit, target_pos)
		if not success:
			print("UNIT AI: %s failed to move to %s - position occupied" % [unit.entity_name, target_pos])
	else:
		print("UNIT AI: %s cannot move to %s - position not accessible" % [unit.entity_name, target_pos])

func can_attack_enemy(unit: Unit, enemy: Unit) -> bool:
	if not enemy: return false
	var distance = unit.get_current_position().distance_to(enemy.get_current_position())
	return distance <= get_weapon_range(unit)

func get_weapon_range(unit: Unit) -> int:
	if unit.weapons.size() > 0:
		return unit.weapons[0].range
	return 3  # Default close range

func is_position_accessible(unit: Unit, pos: Vector2i) -> bool:
	if not map_manager.current_map.has(pos):
		return false
	
	var tile = map_manager.current_map[pos]
	
	# Check terrain accessibility
	if not is_terrain_accessible(unit, tile):
		return false
	
	# Check if occupied by another LIVING unit (this is the key check)
	if tile.unit and tile.unit != unit and tile.unit.health > 0:
		return false
	
	return true

func is_terrain_accessible(unit: Unit, tile: MapManager.MapTile) -> bool:
	# Check if unit can move through this terrain type
	match unit.unit_type:
		Unit.UNIT_TYPE.INFANTRY, Unit.UNIT_TYPE.LOADED_MECH:
			return tile.ground and tile.ground.ground_accessible
		Unit.UNIT_TYPE.MECH:
			return tile.ground and (tile.ground.ground_accessible or tile.ground.air_accessible)
	return true

func has_cover(pos: Vector2i) -> bool:
	if map_manager.current_map.has(pos):
		var tile = map_manager.current_map[pos]
		return tile.obstacle and tile.obstacle.defense_multiplier > 1.0
	return false

# PATHFINDING HELPERS (to integrate with your PathfindingService)
func get_next_move_toward(unit: Unit, target: Vector2i) -> Vector2i:
	# Use the PathfindingService for actual pathfinding
	if pathfinding_service:
		return pathfinding_service.get_next_step_toward(unit.get_current_position(), target, unit.unit_type)
	
	# Fallback: simple direction-based movement
	var direction = (target - unit.get_current_position()).sign()
	var next_pos = unit.get_current_position() + direction
	
	# Simple obstacle avoidance
	if not is_position_accessible(unit, next_pos):
		# Try alternative directions
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var alt_pos = unit.get_current_position() + dir
			if is_position_accessible(unit, alt_pos):
				return alt_pos
		return unit.get_current_position()  # Can't move
	
	return next_pos

func get_closest_position_to_target(positions: Array[Vector2i], target: Vector2i) -> Vector2i:
	var closest = positions[0]
	var min_distance = target.distance_to(closest)
	for pos in positions:
		var distance = target.distance_to(pos)
		if distance < min_distance:
			min_distance = distance
			closest = pos
	return closest

# DELEGATE TO TACTICAL AI FOR SHARED FUNCTIONS
func get_visible_enemies(unit: Unit) -> Array[Unit]:
	return tactical_ai.get_visible_enemies(unit)

func get_closest_enemy(unit: Unit, enemies: Array[Unit]) -> Unit:
	return tactical_ai.get_closest_enemy(unit, enemies)
