class_name Unit
extends Entity

# In-battle stuff
@export var face_dir: Vector2 = Vector2.RIGHT
var active: bool = false

# Order tracking
var current_order: TacticalOrder = null

# Used by AIService
enum UNIT_TYPE {
	INFANTRY,
	LOADED_MECH,
	MECH,
}
@export var unit_type: UNIT_TYPE = UNIT_TYPE.INFANTRY

# Represents an acting unit on the map (takes actions through the ActionQueue)
@export var movement_range: float = 10.0  # How far this unit can move in one turn
@export var sight: float = 15  # How far this unit can see
@export var defense: float = 10.0 # General ability to withstand damage, take cover, etc
@export var armor: float = 1.0 # Armor worn by unit. Must be penetrated to deal effective damage.
@export var weapons: Array[WeaponType] # Weapons able to be used by the unit. Can have two weapons (one PDW and one "punch" weapon, ex: AK-47 and RPG-7)
@export var initiative: float = 1.0 # Determines who goes first in turn order. Highest initiative is earliest

# Amount of units to show in the squad
@export var individual_count: int = 1 # Amount of individual unit sprites to show for this unit type
@export var individual_scene: PackedScene

# Team side logic
@export var side: int = 0

# Take damage from a Weapon. If armor is penetrated, take hard damage.
func damage(weapon: WeaponType):
	if weapon.armor_piercing >= armor:
		health -= weapon.hard_damage
	else:
		health -= weapon.soft_damage - armor

# Set direction unit is facing
# Can determine side/rear shots and flanks (mostly on armored vehicles)
func set_face_dir(dir: Vector2):
	if dir in [Vector2.RIGHT, Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		face_dir = face_dir
	
	for ind:Individual in %Individuals.get_children():
		ind.face(dir)

# Set sprites to proper facing direction and proper amount ded
func set_individual_sprites():
	var sprites_alive = get_individual_count()
	
	for ind:Individual in %Individuals.get_children():
		ind.visible = false
	
	for i in range(sprites_alive):
		%Individuals.get_child(i).visible = true


func get_individual_count():
	var percent_health = get_health_percentage()
	var sprites_alive = floor(individual_count * percent_health)
	return sprites_alive

# Movement and combat methods for AI
func get_movement_range() -> float:
	return movement_range

func attack(target: Unit) -> void:
	if weapons.size() > 0 and target:
		print("COMBAT: %s attacking %s with %s" % [entity_name, target.entity_name, weapons[0].name])
		target.damage(weapons[0])

func set_fortified(fortified: bool) -> void:
	# Simple fortification - you can expand this later
	if fortified:
		print("UNIT: %s is fortifying position" % entity_name)
		# defense *= 1.5  // You might want to implement actual defense bonuses
	else:
		print("UNIT: %s is leaving fortified position" % entity_name)
		# defense /= 1.5

# Turn related
func set_active(val: bool):
	%Active.visible = val
	active = val

func start_turn(player_controlled: bool):
	if player_controlled:
		pass
	else:
		# Decide what to do via AIService
		pass

func end_turn():
	pass
