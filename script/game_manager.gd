class_name GameManager
extends Node2D

@export var player_side: int = 0
@export var map_manager: MapManager
@export var test_map: PackedScene
@export var action_manager: ActionManager

func _ready() -> void:
	# Load map
	map_manager.load_map(test_map)
	
	# Initialize services
	initialize_services()
	
	# Start the first turn
	start_visual_battle()

func initialize_services():
	# Make sure all service references are connected
	print("GAME MANAGER: Initializing AI battle systems...")
	
	# Ensure the action manager has all its AI dependencies
	if action_manager:
		# Connect AI services
		if has_node("TacticalAIService"):
			action_manager.tactical_ai = get_node("TacticalAIService")
			print("GAME MANAGER: Connected TacticalAIService")
		
		if has_node("UnitAIService"):
			action_manager.unit_ai = get_node("UnitAIService")
			# Also connect action_manager to UnitAIService
			action_manager.unit_ai.action_manager = action_manager
			print("GAME MANAGER: Connected UnitAIService")
		
		action_manager.game_manager = self
		print("GAME MANAGER: AI services connected to ActionManager")
	else:
		print("GAME MANAGER: Warning - ActionManager missing!")
	
	# Connect PathfindingService to UnitAIService
	if has_node("UnitAIService") and has_node("PathfindingService"):
		var unit_ai = get_node("UnitAIService")
		var pathfinding = get_node("PathfindingService")
		unit_ai.pathfinding_service = pathfinding
		print("GAME MANAGER: Connected PathfindingService to UnitAIService")

func start_visual_battle():
	print("=== VISUAL BATTLE STARTING ===")
	print("GAME MANAGER: Brutal AI commander coming online...")
	
	# Make sure pathfinding is ready
	if has_node("PathfindingService"):
		get_node("PathfindingService").rebuild_navigation_graph()
	
	# Start the first turn
	action_manager.next_turn()
	
	print("GAME MANAGER: Visual battle ready - AI will take their turns automatically!")

# Temporary debug function
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):  # Space bar
		print("=== DEBUG INFO ===")
		print("ActionManager: ", action_manager)
		print("TacticalAI: ", action_manager.tactical_ai if action_manager else "No ActionManager")
		print("UnitAI: ", action_manager.unit_ai if action_manager else "No ActionManager")
		print("Units on map: ", map_manager.units.get_child_count())
		for unit in map_manager.units.get_children():
			print(" - ", unit.entity_name, " at ", unit.current_position, " side: ", unit.side)
