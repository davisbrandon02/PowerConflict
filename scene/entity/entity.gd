class_name Entity
extends Node

# Anything that is on the map that can be interacted with in some way
# Examples: Units, buildings, trees (can be blown up, napalmed, etc)
@export var entity_name: String
@export var health: float = 10.0
@export var max_health: float = 10.0
var current_position: Vector2i # Set by map manager

func get_health_percentage() -> float:
	return float(health) / float(max_health)

func damage(weapon: WeaponType):
	health -= weapon.soft_damage
	health -= weapon.hard_damage
	%HealthBar.max_value = max_health
	%HealthBar.value = health

# Absolutely only ever called by the MapManager
func set_current_position(pos: Vector2i):
	current_position = pos

func get_current_position():
	return current_position
