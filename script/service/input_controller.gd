class_name ControllerService
extends Node2D

# Class to handle mouse input and keypresses

@export var map_manager: MapManager
@export var ui_manager: UIManager

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse = get_global_mouse_position()
		var map_pos = map_manager.get_map_pos(mouse)
		if map_manager.current_map.has(map_pos):
			# If tile hovered over is within the current map, show its information
			ui_manager.show_tile_information(map_manager.current_map[map_pos])
