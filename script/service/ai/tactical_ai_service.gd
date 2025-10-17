class_name TacticalAIService
extends Node2D

# The AI General - makes high-level decisions for each team
@export var game_manager: GameManager
@export var map_manager: MapManager

var current_orders: Dictionary = {}  # unit_id -> TacticalOrder
var team_objectives: Dictionary = {}  # team_id -> Array[Vector2i]
var turn_count: int = 0

func _ready():
	print("Tactical AI Service initialized - AI General ready for command")

func plan_team_strategy(team_id: int) -> void:
	print("Tactical AI: Planning strategy for team %d" % team_id)
	turn_count += 1
	
	var team_units = get_team_units(team_id)
	var enemy_units = get_enemy_units(team_id)
	
	# Update objectives based on current situation
	update_team_objectives(team_id, team_units, enemy_units)
	
	# Assign orders to each unit
	for unit in team_units:
		var order = create_unit_order(unit, team_units, enemy_units)
		current_orders[unit.get_instance_id()] = order
		print("Tactical AI: %s assigned %s" % [unit.entity_name, order.get_order_description()])

func create_unit_order(unit: Unit, friendly_units: Array[Unit], enemy_units: Array[Unit]) -> TacticalOrder:
	var visible_enemies = get_visible_enemies(unit)
	
	# Determine unit role based on type
	var role = get_unit_role(unit)
	
	# Situation assessment
	if visible_enemies.size() > 0:
		return handle_combat_situation(unit, visible_enemies, friendly_units, role)
	else:
		return handle_non_combat_situation(unit, enemy_units, friendly_units, role)

func get_unit_role(unit: Unit) -> String:
	match unit.unit_type:
		Unit.UNIT_TYPE.INFANTRY:
			return "assault"
		Unit.UNIT_TYPE.LOADED_MECH:
			return "support" 
		Unit.UNIT_TYPE.MECH:
			return "heavy_assault"
	return "general"

func handle_combat_situation(unit: Unit, visible_enemies: Array[Unit], friendly_units: Array[Unit], role: String) -> TacticalOrder:
	var closest_enemy = get_closest_enemy(unit, visible_enemies)
	var enemy_pos = closest_enemy.get_current_position()
	
	# Assess threat level
	var threat_level = assess_threat_level(unit, visible_enemies)
	var has_support = has_nearby_support(unit, friendly_units)
	
	match role:
		"assault":
			if threat_level > 0.7 and not has_support:
				var fallback_pos = find_fallback_position(unit, visible_enemies)
				return TacticalOrder.new(TacticalOrder.OrderType.RETREAT, fallback_pos, 0.2)
			else:
				return TacticalOrder.new(TacticalOrder.OrderType.ASSAULT, enemy_pos, 0.8)
		
		"support":
			var suppression_pos = find_suppression_position(unit, enemy_pos)
			return TacticalOrder.new(TacticalOrder.OrderType.SUPPRESS, suppression_pos, 0.6)
		
		"heavy_assault":
			var advance_pos = calculate_advance_position(unit, enemy_pos)
			return TacticalOrder.new(TacticalOrder.OrderType.ADVANCE, advance_pos, 0.9)
	
	return TacticalOrder.new(TacticalOrder.OrderType.DEFEND, unit.get_current_position(), 0.5)

func handle_non_combat_situation(unit: Unit, enemy_units: Array[Unit], friendly_units: Array[Unit], role: String) -> TacticalOrder:
	var primary_objective = get_primary_objective(unit.side)
	
	match role:
		"assault":
			var advance_pos = get_advance_position_toward_objective(unit, primary_objective)
			return TacticalOrder.new(TacticalOrder.OrderType.ADVANCE, advance_pos, 0.4)
		
		"support":
			var defend_pos = find_defensive_position(unit, primary_objective)
			return TacticalOrder.new(TacticalOrder.OrderType.DEFEND, defend_pos, 0.3)
		
		"heavy_assault":
			var recon_pos = get_recon_position(unit, enemy_units)
			return TacticalOrder.new(TacticalOrder.OrderType.RECON, recon_pos, 0.6)
	
	return TacticalOrder.new(TacticalOrder.OrderType.ADVANCE, primary_objective, 0.5)

# Helper methods
func get_team_units(team_id: int) -> Array[Unit]:
	var units: Array[Unit] = []
	for unit:Unit in map_manager.units.get_children():
		if unit.side == team_id and unit.health > 0:
			units.append(unit)
	return units

func get_enemy_units(team_id: int) -> Array[Unit]:
	var units: Array[Unit] = []
	for unit in map_manager.units.get_children():
		if unit.side != team_id and unit.health > 0:
			units.append(unit)
	return units

func get_visible_enemies(unit: Unit) -> Array[Unit]:
	return map_manager.get_visible_enemies(unit)

func get_closest_enemy(unit: Unit, enemies: Array[Unit]) -> Unit:
	var closest = null
	var min_distance = INF
	for enemy in enemies:
		var distance = unit.get_current_position().distance_to(enemy.get_current_position())
		if distance < min_distance:
			min_distance = distance
			closest = enemy
	return closest

func assess_threat_level(unit: Unit, enemies: Array[Unit]) -> float:
	var total_threat = 0.0
	for enemy in enemies:
		var distance = unit.get_current_position().distance_to(enemy.get_current_position())
		var threat = 1.0 / (distance + 1.0)
		total_threat += threat
	return min(total_threat / 3.0, 1.0)

func has_nearby_support(unit: Unit, friendly_units: Array[Unit]) -> bool:
	for friendly in friendly_units:
		if friendly != unit:
			var distance = unit.get_current_position().distance_to(friendly.get_current_position())
			if distance <= unit.sight:
				return true
	return false

func update_team_objectives(team_id: int, friendly_units: Array[Unit], enemy_units: Array[Unit]):
	if enemy_units.size() > 0:
		var avg_enemy_pos = Vector2i.ZERO
		for enemy in enemy_units:
			avg_enemy_pos += enemy.get_current_position()
		avg_enemy_pos /= enemy_units.size()
		team_objectives[team_id] = [avg_enemy_pos]
	else:
		team_objectives[team_id] = [Vector2i(15, 15)]

func get_primary_objective(team_id: int) -> Vector2i:
	if team_objectives.has(team_id) and team_objectives[team_id].size() > 0:
		return team_objectives[team_id][0]
	return Vector2i(15, 15)

# Position finding methods
func find_fallback_position(unit: Unit, enemies: Array[Unit]) -> Vector2i:
	return unit.get_current_position() + Vector2i(-2, -2)

func find_suppression_position(unit: Unit, enemy_pos: Vector2i) -> Vector2i:
	return enemy_pos + Vector2i(2, 2)

func calculate_advance_position(unit: Unit, enemy_pos: Vector2i) -> Vector2i:
	return enemy_pos + Vector2i(-3, -3)

func get_advance_position_toward_objective(unit: Unit, objective: Vector2i) -> Vector2i:
	var direction_vec = Vector2(objective - unit.get_current_position()).normalized()
	var direction = Vector2i(direction_vec * 4)
	return unit.get_current_position() + direction

func find_defensive_position(unit: Unit, objective: Vector2i) -> Vector2i:
	return objective + Vector2i(2, 0)

func get_recon_position(unit: Unit, enemy_units: Array[Unit]) -> Vector2i:
	if enemy_units.size() > 0:
		var enemy_pos = enemy_units[0].get_current_position()
		var direction_vec = Vector2(enemy_pos - unit.get_current_position()).normalized()
		return unit.get_current_position() + Vector2i(direction_vec * 5)
	return unit.get_current_position() + Vector2i(8, 0)
