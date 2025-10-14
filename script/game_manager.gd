class_name GameManager
extends Node2D

@export var map_manager: MapManager
@export var test_map: PackedScene

# Initialize all services in order
func _ready() -> void:
	# Load map
	map_manager.load_map(test_map)
	
	# Initialize pathfinding
