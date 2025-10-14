class_name Unit
extends Entity

# In-battle stuff
@export var facing_dir: Vector2 = Vector2.RIGHT

# Represents an acting unit on the map (takes actions through the ActionQueue)
@export var defense: float = 10.0 # General ability to withstand damage, take cover, etc
@export var armor: float = 1.0 # Armor worn by unit. Must be penetrated to deal effective damage.
@export var weapons: Array[WeaponType] # Weapons able to be used by the unit. By default, the first is equipped.

# Amount of units to show in the squad
@export var individual_count: int = 1 # Amount of individual unit sprites to show for this unit type
@export var individual_scene: PackedScene
const INDIVIDUAL_SPAWN_OFFSETS = [ # Spawn individual sprites in order using these offsets.
	
]

func damage(weapon: WeaponType):
	if weapon.armor_piercing >= armor:
		health -= weapon.hard_damage
	else:
		health -= weapon.soft_damage - armor

# Set sprites to proper facing direction and proper amount ded
func set_individual_sprites():
	var percent_health = get_health_percentage()
	var sprites_alive = individual_count * percent_health
