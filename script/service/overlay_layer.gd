class_name OverlayLayer
extends TileMapLayer

# This handles rendering overlays.
# Ex. Movement and attack overlays

@export var map_manager: MapManager

# Set the tile overlay for the active unit
func set_overlay_for_active_unit(unit: Unit):
	if map_manager.current_map.has(unit.get_current_position()):
		pass

# Completely clear the map of overlay tiles
func clear_overlay():
	pass
