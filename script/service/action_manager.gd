class_name ActionManager
extends Node2D

var turns_since_start: int = 0
@export var game_manager: GameManager
@export var map_manager: MapManager
@export var ui_manager: UIManager
@export var tactical_ai: TacticalAIService
@export var unit_ai: UnitAIService
@export var overlay_layer: OverlayLayer
var queue: Array[Unit] = []
var current_unit: Unit = null

# Simplified action types with AP costs
enum ActionType {
	MOVE_HALF,      # 1 AP - move within half range (blue overlay)
	MOVE_FULL,      # 2 AP - move full range beyond half (yellow overlay)  
	FIRE_NORMAL,    # 1 AP - standard shot with 2/3 accuracy
	FIRE_AIMED      # 2 AP - aimed shot with higher accuracy
}

# AP costs for actions
const ACTION_COSTS = {
	ActionType.MOVE_HALF: 1,
	ActionType.MOVE_FULL: 2,
	ActionType.FIRE_NORMAL: 1,
	ActionType.FIRE_AIMED: 2
}

func queue_next():
	if current_unit:
		# End the current unit's turn and reset AP
		current_unit.set_active(false)
		current_unit.current_ap = current_unit.max_ap  # Reset AP for next turn
		print("ACTION MANAGER: %s turn ended" % current_unit.entity_name)
		current_unit = null
	
	# Clear the overlay
	overlay_layer.clear_overlay()
	
	if queue.size() == 0:
		print("ACTION MANAGER: Queue empty - turn complete")
		end_turn()  # This should NOT call next_turn() recursively
		return
	
	# Start the next unit's turn
	current_unit = queue[0]
	queue.pop_front()
	
	print("ACTION MANAGER: %s turn starting (%d AP available)" % [current_unit.entity_name, current_unit.current_ap])
	current_unit.set_active(true)
	
	if is_unit_player_controlled(current_unit):
		# Wait for player input - DON'T auto-execute
		print("PLAYER TURN: %s ready for commands" % current_unit.entity_name)
		ui_manager.show_unit_controls(current_unit)
		overlay_layer.set_overlay_for_active_unit(current_unit)
		update_available_actions(current_unit)
	else:
		# AI unit's turn
		print("AI TURN: %s beginning combat operations" % current_unit.entity_name)
		unit_ai.execute_unit_turn(current_unit)

# NEW: AI-specific action execution that integrates with AP system
func execute_ai_action(unit: Unit, action: ActionType, target_pos: Vector2i) -> bool:
	# Set the current unit temporarily for AI actions
	var previous_unit = current_unit
	current_unit = unit
	
	# Execute the action (this will deduct AP automatically)
	var success = execute_action(action, target_pos)
	
	# Restore the previous current unit
	current_unit = previous_unit
	return success

# Check what actions are available based on AP and situation
func update_available_actions(unit: Unit) -> Array[ActionType]:
	var available_actions:Array[ActionType] = []
	
	# Movement actions
	if unit.current_ap >= ACTION_COSTS[ActionType.MOVE_HALF]:
		available_actions.append(ActionType.MOVE_HALF)
	if unit.current_ap >= ACTION_COSTS[ActionType.MOVE_FULL]:
		available_actions.append(ActionType.MOVE_FULL)
	
	# Firing actions (if has targets)
	if unit.current_ap >= ACTION_COSTS[ActionType.FIRE_NORMAL] and map_manager.get_visible_enemies(unit).size() > 0:
		available_actions.append(ActionType.FIRE_NORMAL)
	if unit.current_ap >= ACTION_COSTS[ActionType.FIRE_AIMED] and map_manager.get_visible_enemies(unit).size() > 0:
		available_actions.append(ActionType.FIRE_AIMED)
	
	ui_manager.update_action_buttons(available_actions)
	return available_actions

# Execute individual actions with AP cost
func execute_action(action: ActionType, target_pos: Vector2i = Vector2i.ZERO) -> bool:
	# Clear the overlay at start of action execution
	overlay_layer.clear_overlay()
	
	if not current_unit:
		return false
	
	var cost = ACTION_COSTS[action]
	if current_unit.current_ap < cost:
		print("ACTION FAILED: %s needs %d AP but has %d" % [current_unit.entity_name, cost, current_unit.current_ap])
		return false
	
	# Execute the action
	var success = false
	match action:
		ActionType.MOVE_HALF:
			success = execute_half_move(current_unit, target_pos)
		ActionType.MOVE_FULL:
			success = execute_full_move(current_unit, target_pos)
		ActionType.FIRE_NORMAL:
			success = execute_normal_fire(current_unit, target_pos)
		ActionType.FIRE_AIMED:
			success = execute_aimed_fire(current_unit, target_pos)
	
	if success:
		current_unit.current_ap -= cost
		print("ACTION: %s executed %s (%d AP remaining)" % [current_unit.entity_name, get_action_name(action), current_unit.current_ap])
		
		# Update available actions after successful execution
		if is_unit_player_controlled(current_unit):
			update_available_actions(current_unit)
			
		# Auto-end turn if out of AP
		if current_unit.current_ap == 0:
			print("ACTION: %s out of AP - ending turn" % current_unit.entity_name)
			end_current_turn()
	
	return success

# Action execution helpers
func execute_half_move(unit: Unit, target_pos: Vector2i) -> bool:
	print("ACTION: %s moving half range to %s" % [unit.entity_name, target_pos])
	
	# Call map manager to move the unit
	map_manager.move_unit(unit, target_pos)
	
	return true

func execute_full_move(unit: Unit, target_pos: Vector2i) -> bool:
	print("ACTION: %s moving full range to %s" % [unit.entity_name, target_pos])
	return true

func execute_normal_fire(unit: Unit, target_pos: Vector2i) -> bool:
	print("ACTION : %s %s executing normal fire at target pos")
	return false
	#if not target_unit:
		#return false
	#print("ACTION: %s normal firing on %s (2/3 accuracy)" % [unit.entity_name, target_unit.entity_name])
	## Standard shot with 2/3 accuracy
	#unit.attack(target_unit, false)  # false for normal shot
	#return true

func execute_aimed_fire(unit: Unit, target_pos: Vector2i) -> bool:
	print("ACTION: %s aimed firing on %s (high accuracy)" % [unit.entity_name, target_pos])
	return false
	#if not target_unit:
		#return false
	## Aimed shot with higher accuracy
	#unit.attack(target_unit, true)  # true for aimed shot
	#return true

# Helper functions
func get_action_name(action: ActionType) -> String:
	var names = {
		ActionType.MOVE_HALF: "Half Move",
		ActionType.MOVE_FULL: "Full Move", 
		ActionType.FIRE_NORMAL: "Normal Fire",
		ActionType.FIRE_AIMED: "Aimed Fire"
	}
	return names.get(action, "Unknown Action")

# End turn when appropriate
func end_current_turn():
	# Clear the order if it was executed
	if current_unit and current_unit.current_order:
		current_unit.current_order = null
	
	queue_next()

# Initialize units with AP in next_turn()
func next_turn():
	print("=== TURN %d STARTING ===" % (turns_since_start + 1))
	turns_since_start += 1
	
	# Reset AP for all units at start of turn
	for unit:Unit in %Units.get_children():
		if unit.health > 0:
			unit.current_ap = unit.max_ap
	
	# Clear expired orders
	clear_expired_orders()
	
	# Plan AI strategy
	var ai_teams = get_ai_teams()
	for team in ai_teams:
		tactical_ai.plan_team_strategy(team)
	
	# Build and start turn - ONLY ONCE PER TURN
	refresh_action_queue()
	sort_queue()
	queue_next()

func clear_expired_orders():
	for unit:Unit in %Units.get_children():
		if unit.current_order and unit.current_order.is_expired(turns_since_start):
			print("ORDER: Cleared expired order for %s" % unit.entity_name)
			unit.current_order = null

func refresh_action_queue():
	queue.clear()
	for unit:Unit in %Units.get_children():
		if unit.health > 0:
			queue.append(unit)
	print("ACTION MANAGER: Queue refreshed with %d units" % queue.size())

func sort_queue():
	queue.sort_custom(func(a, b): return a.initiative > b.initiative)

func is_unit_player_controlled(unit: Unit):
	return unit.side == game_manager.player_side

func get_ai_teams() -> Array[int]:
	var teams: Array[int] = []
	for unit: Unit in %Units.get_children():
		if unit.health > 0 and not is_unit_player_controlled(unit):
			if not unit.side in teams:
				teams.append(unit.side)
	return teams

# Call this from UI when player wants to skip to next unit manually
func skip_to_next_unit():
	if current_unit and is_unit_player_controlled(current_unit):
		print("PLAYER: Skipping %s turn" % current_unit.entity_name)
		end_current_turn()

# Call this when player gives an order to a unit
func set_player_order(unit: Unit, order: TacticalOrder):
	unit.current_order = order
	print("PLAYER ORDER: %s assigned %s" % [unit.entity_name, order.get_order_description()])

# Handle turn completion and start next turn automatically
func end_turn():
	print("=== TURN %d COMPLETE ===" % turns_since_start)
	# DON'T automatically start next turn - wait for player input or game logic
	# Remove this line: next_turn()
	
	# Instead, signal that the turn is complete and wait for next turn trigger
	game_manager.on_turn_complete(turns_since_start)
