class_name WeaponType
extends Resource

# Data for weapons equipped by Units
# Can be small arms, tank guns, hellfire missiles, etc

@export var name: String
@export var range: float = 10.0
@export var soft_damage: float = 10.0
@export var hard_damage: float = 10.0
@export var armor_piercing: float = 0.0
@export var cooldown_turns: int = 1

# Used if shot takes multiple turns to reach target. Ex: mortars/artillery
@export var turns_to_target: int = 0
