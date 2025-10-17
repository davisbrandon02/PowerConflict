class_name UnitAIService
extends Node2D

@export var tactical_ai: TacticalAIService
@export var map_manager: MapManager
@export var action_manager: ActionManager

func execute_unit_turn(unit: Unit) -> void:
	print("UNIT AI: %s (%s) beginning combat operations" % [unit.entity_name, unit.current_position])
	
	var current_order = tactical_ai.current_orders.get(unit.get_instance_id())
	
	if current_order:
		execute_order(unit, current_order)
	else:
		execute_autonomous_behavior(unit)
	
	print("UNIT AI: %s combat operations complete" % unit.entity_name)
	# DON'T call end_current_turn() here - let the ActionManager handle it
	# The ActionManager should detect when AP is 0 and end the turn automatically

# Execute player orders (same as AI orders but for player units)
func execute_player_order(unit: Unit, order: TacticalOrder):
	print("UNIT AI: %s executing PLAYER ORDER: %s" % [unit.entity_name, order.get_order_description()])
	execute_order(unit, order)

func execute_order(unit: Unit, order: TacticalOrder) -> void:
	print("UNIT AI: %s executing ORDER: %s" % [unit.entity_name, order.get_order_description()])
	
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

func execute_advance_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = map_manager.get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		var closest_enemy = get_closest_enemy(unit, visible_enemies)
		if can_attack_enemy(unit, closest_enemy):
			action_manager.execute_ai_action(unit, ActionManager.ActionType.FIRE_NORMAL, closest_enemy.get_current_position())
		else:
			var move_pos = get_next_move_toward(unit, closest_enemy.get_current_position())
			if map_manager.can_move_to_pos(unit, move_pos):
				action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, move_pos)
	else:
		var move_pos = get_next_move_toward(unit, order.primary_target)
		if map_manager.can_move_to_pos(unit, move_pos):
			action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, move_pos)

func execute_assault_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = map_manager.get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		var target_enemy = order.target_unit if order.target_unit else get_most_dangerous_enemy(unit, visible_enemies)
		
		if can_attack_enemy(unit, target_enemy):
			action_manager.execute_ai_action(unit, ActionManager.ActionType.FIRE_NORMAL, target_enemy.get_current_position())
			if unit.current_ap >= 2:
				var assault_pos = get_close_assault_position(unit, target_enemy.get_current_position())
				if map_manager.can_move_to_pos(unit, assault_pos):
					action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, assault_pos)
		else:
			var assault_pos = get_danger_close_position(unit, target_enemy.get_current_position())
			if map_manager.can_move_to_pos(unit, assault_pos):
				action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, assault_pos)
	else:
		var move_pos = get_next_move_toward(unit, order.primary_target)
		if map_manager.can_move_to_pos(unit, move_pos):
			action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, move_pos)

func execute_defend_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = map_manager.get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		var enemies_in_range = get_enemies_in_weapon_range(unit, visible_enemies)
		if enemies_in_range.size() > 0:
			var target = get_most_dangerous_enemy(unit, enemies_in_range)
			action_manager.execute_ai_action(unit, ActionManager.ActionType.FIRE_NORMAL, target.get_current_position())
	else:
		unit.set_fortified(true)

func execute_flank_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = map_manager.get_visible_enemies(unit)
	
	if visible_enemies.size() > 0 and not is_unit_flanking(unit, visible_enemies[0]):
		var next_pos = get_next_move_toward(unit, order.primary_target)
		if is_position_concealed(unit, next_pos) and map_manager.can_move_to_pos(unit, next_pos):
			action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, next_pos)
		else:
			var alt_route = find_concealed_flank_route(unit, order.primary_target)
			if map_manager.can_move_to_pos(unit, alt_route):
				action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, alt_route)
	else:
		if visible_enemies.size() > 0:
			var flanked_enemy = visible_enemies[0]
			action_manager.execute_ai_action(unit, ActionManager.ActionType.FIRE_NORMAL, flanked_enemy.get_current_position())

func execute_suppress_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = map_manager.get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		var suppression_target = order.target_unit if order.target_unit else get_best_suppression_target(unit, visible_enemies)
		if can_attack_enemy(unit, suppression_target):
			action_manager.execute_ai_action(unit, ActionManager.ActionType.FIRE_NORMAL, suppression_target.get_current_position())
	else:
		var next_pos = get_next_move_toward(unit, order.primary_target)
		if map_manager.can_move_to_pos(unit, next_pos):
			action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, next_pos)

func execute_retreat_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = map_manager.get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		var closest_enemy = get_closest_enemy(unit, visible_enemies)
		if can_attack_enemy(unit, closest_enemy) and unit.health > unit.max_health * 0.4:
			action_manager.execute_ai_action(unit, ActionManager.ActionType.FIRE_NORMAL, closest_enemy.get_current_position())
	
	var next_pos = get_next_move_toward(unit, order.primary_target)
	if is_position_safe(unit, next_pos, visible_enemies) and map_manager.can_move_to_pos(unit, next_pos):
		action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, next_pos)

func execute_recon_order(unit: Unit, order: TacticalOrder) -> void:
	var visible_enemies = map_manager.get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		var retreat_pos = find_evasion_position(unit, visible_enemies)
		if map_manager.can_move_to_pos(unit, retreat_pos):
			action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, retreat_pos)
	else:
		var next_pos = get_next_move_toward(unit, order.primary_target)
		if map_manager.can_move_to_pos(unit, next_pos):
			action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, next_pos)

func execute_autonomous_behavior(unit: Unit) -> void:
	print("UNIT AI: %s using autonomous combat protocols" % unit.entity_name)
	var visible_enemies = map_manager.get_visible_enemies(unit)
	
	if visible_enemies.size() > 0:
		var closest_enemy = get_closest_enemy(unit, visible_enemies)
		
		if can_attack_enemy(unit, closest_enemy):
			action_manager.execute_ai_action(unit, ActionManager.ActionType.FIRE_NORMAL, closest_enemy.get_current_position())
			if unit.health > unit.max_health * 0.6:
				var advance_pos = get_aggressive_advance_position(unit, closest_enemy.get_current_position())
				if map_manager.can_move_to_pos(unit, advance_pos):
					action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, advance_pos)
		else:
			var assault_pos = get_danger_close_position(unit, closest_enemy.get_current_position())
			if map_manager.can_move_to_pos(unit, assault_pos):
				action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, assault_pos)
	else:
		var hunt_target = get_hunt_position(unit)
		if map_manager.can_move_to_pos(unit, hunt_target):
			action_manager.execute_ai_action(unit, ActionManager.ActionType.MOVE_FULL, hunt_target)

# TACTICAL HELPERS
func find_bounding_position(unit: Unit, target: Vector2i, enemies: Array[Unit]) -> Vector2i:
	var possible_positions = []
	for i in range(-2, 3):
		for j in range(-2, 3):
			var check_pos = unit.get_current_position() + Vector2i(i, j)
			if map_manager.can_move_to_pos(unit, check_pos) and has_cover(check_pos) and is_position_safe(unit, check_pos, enemies):
				possible_positions.append(check_pos)
	
	if possible_positions.size() > 0:
		return get_closest_position_to_target(possible_positions, target)
	return get_next_move_toward(unit, target)

func get_danger_close_position(unit: Unit, enemy_pos: Vector2i) -> Vector2i:
	var direction_vec = Vector2(enemy_pos - unit.get_current_position()).normalized()
	return unit.get_current_position() + Vector2i(direction_vec * 2)

func get_close_assault_position(unit: Unit, enemy_pos: Vector2i) -> Vector2i:
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
		return (tile.obstacle and tile.obstacle.defense_multiplier > 1.0) or (tile.ground and tile.ground.obstructs_view)
	return false

func get_most_dangerous_enemy(unit: Unit, enemies: Array[Unit]) -> Unit:
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
	return weapon_threat / (distance + 1.0)

func get_most_vulnerable_enemy(unit: Unit, enemies: Array[Unit]) -> Unit:
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
	var unit_to_enemy = Vector2(enemy.get_current_position() - unit.get_current_position()).normalized()
	return abs(unit_to_enemy.x) > 0.3 and abs(unit_to_enemy.y) > 0.3

func find_concealed_flank_route(unit: Unit, target: Vector2i) -> Vector2i:
	var current_pos = unit.get_current_position()
	var direction_vec = Vector2(target - current_pos).normalized()
	var flank_dir = Vector2i(Vector2(-direction_vec.y, direction_vec.x))
	return current_pos + flank_dir

func get_best_suppression_target(unit: Unit, enemies: Array[Unit]) -> Unit:
	return get_most_dangerous_enemy(unit, enemies)

func find_evasion_position(unit: Unit, enemies: Array[Unit]) -> Vector2i:
	var avg_enemy_pos = Vector2i.ZERO
	for enemy in enemies:
		avg_enemy_pos += enemy.get_current_position()
	avg_enemy_pos /= enemies.size()
	
	var escape_vec = Vector2(unit.get_current_position() - avg_enemy_pos).normalized()
	return unit.get_current_position() + Vector2i(escape_vec * 3)

func get_aggressive_advance_position(unit: Unit, enemy_pos: Vector2i) -> Vector2i:
	var direction_vec = Vector2(enemy_pos - unit.get_current_position()).normalized()
	return unit.get_current_position() + Vector2i(direction_vec * 2)

func get_hunt_position(unit: Unit) -> Vector2i:
	return tactical_ai.get_primary_objective(unit.side)

# COMBAT ACTIONS
func attack_enemy(unit: Unit, enemy: Unit) -> void:
	print("UNIT AI: %s ENGAGING %s" % [unit.entity_name, enemy.entity_name])

func can_attack_enemy(unit: Unit, enemy: Unit) -> bool:
	if not enemy: return false
	var distance = unit.get_current_position().distance_to(enemy.get_current_position())
	return distance <= get_weapon_range(unit)

func get_weapon_range(unit: Unit) -> int:
	if unit.weapons.size() > 0:
		return unit.weapons[0].range
	return 3

func has_cover(pos: Vector2i) -> bool:
	if map_manager.current_map.has(pos):
		var tile = map_manager.current_map[pos]
		return tile.obstacle and tile.obstacle.defense_multiplier > 1.0
	return false

# PATHFINDING HELPERS
func get_next_move_toward(unit: Unit, target: Vector2i) -> Vector2i:
	var direction = (target - unit.get_current_position()).sign()
	var next_pos = unit.get_current_position() + direction
	
	if not map_manager.can_move_to_pos(unit, next_pos):
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var alt_pos = unit.get_current_position() + dir
			if map_manager.can_move_to_pos(unit, alt_pos):
				return alt_pos
		return unit.get_current_position()
	
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

func get_closest_enemy(unit: Unit, enemies: Array[Unit]) -> Unit:
	var closest = null
	var min_distance = INF
	for enemy in enemies:
		var distance = unit.get_current_position().distance_to(enemy.get_current_position())
		if distance < min_distance:
			min_distance = distance
			closest = enemy
	return closest
