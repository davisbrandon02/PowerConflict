class_name ActionManager
extends Node2D

var turns_since_start: int = 0
@export var game_manager: GameManager
@export var ui_manager: UIManager
@export var tactical_ai: TacticalAIService
@export var unit_ai: UnitAIService
var queue: Array[Unit] = []
var current_unit: Unit = null

func queue_next():
	if current_unit:
		# End the current unit's turn
		current_unit.set_active(false)
		print("ACTION MANAGER: %s turn ended" % current_unit.entity_name)
		current_unit = null
	
	if queue.size() == 0:
		print("ACTION MANAGER: Queue empty - turn complete")
		end_turn()
		return
	
	# Start the next unit's turn
	current_unit = queue[0]
	queue.pop_front()
	
	print("ACTION MANAGER: %s turn starting" % current_unit.entity_name)
	current_unit.set_active(true)
	
	if is_unit_player_controlled(current_unit):
		# Check if player already gave this unit an order
		if current_unit.current_order:
			# Player already gave order - execute it automatically
			print("PLAYER TURN: %s executing %s" % [current_unit.entity_name, current_unit.current_order.get_order_description()])
			execute_player_order(current_unit, current_unit.current_order)
		else:
			# No order yet - show controls and wait for player input
			print("PLAYER TURN: %s ready for commands" % current_unit.entity_name)
			ui_manager.show_unit_controls(current_unit)
	else:
		# AI unit's turn - use UnitAIService
		print("AI TURN: %s beginning combat operations" % current_unit.entity_name)
		unit_ai.execute_unit_turn(current_unit)

func execute_player_order(unit: Unit, order: TacticalOrder):
	# Use the same UnitAIService to execute player orders for consistency
	match order.order_type:
		TacticalOrder.OrderType.ADVANCE:
			unit_ai.execute_advance_order(unit, order)
		TacticalOrder.OrderType.ASSAULT:
			unit_ai.execute_assault_order(unit, order)
		TacticalOrder.OrderType.DEFEND:
			unit_ai.execute_defend_order(unit, order)
		# ... etc for other order types
		_:
			print("PLAYER ORDER: Unknown order type for %s" % unit.entity_name)
			end_current_turn()

func refresh_action_queue():
	queue.clear()
	for unit:Unit in %Units.get_children():
		if unit.health > 0:
			queue.append(unit)
	print("ACTION MANAGER: Queue refreshed with %d units" % queue.size())

func next_turn():
	print("=== TURN %d STARTING ===" % (turns_since_start + 1))
	turns_since_start += 1
	
	# Clear expired orders from all units
	clear_expired_orders()
	
	# First, have tactical AI plan strategy for all AI teams
	var ai_teams = get_ai_teams()
	for team in ai_teams:
		tactical_ai.plan_team_strategy(team)
	
	# Then build the action queue
	refresh_action_queue()
	sort_queue()
	
	# Start the first unit's turn via queue_next
	queue_next()

func clear_expired_orders():
	for unit:Unit in %Units.get_children():
		if unit.current_order and unit.current_order.is_expired(turns_since_start):
			print("ORDER: Cleared expired order for %s" % unit.entity_name)
			unit.current_order = null

func add_to_queue(unit: Unit):
	queue.append(unit)

func sort_queue():
	queue.sort_custom(func(a, b): return a.initiative > b.initiative)

func is_unit_player_controlled(unit: Unit):
	return unit.side == game_manager.player_side

func get_ai_teams() -> Array[int]:
	var teams: Array[int] = []  # Explicitly type the array
	for unit: Unit in %Units.get_children():
		if unit.health > 0 and not is_unit_player_controlled(unit):
			if not unit.side in teams:
				teams.append(unit.side)
	return teams

# Call this when a unit finishes their turn (player confirms end turn or AI finishes)
func end_current_turn():
	# Clear the order if it was executed
	if current_unit and current_unit.current_order:
		current_unit.current_order = null
	queue_next()

# Handle turn completion and start next turn automatically
func end_turn():
	print("=== TURN %d COMPLETE ===" % turns_since_start)
	# Start the next turn automatically
	next_turn()

# Call this from UI when player wants to skip to next unit manually
func skip_to_next_unit():
	if current_unit and is_unit_player_controlled(current_unit):
		print("PLAYER: Skipping %s turn" % current_unit.entity_name)
		end_current_turn()

# Call this when player gives an order to a unit
func set_player_order(unit: Unit, order: TacticalOrder):
	unit.current_order = order
	print("PLAYER ORDER: %s assigned %s" % [unit.entity_name, order.get_order_description()])
