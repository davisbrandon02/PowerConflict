class_name Obstacle
extends Entity

@export var obstacle_name: String

# Physical obstacle on the map
@export var attack_multiplier: float = 1.0
@export var defense_multiplier: float = 1.0

# Movement and sight properties
@export var ground_accessible: bool = true
@export var sea_accessible: bool = false
@export var air_accessible: bool = true
@export var obstructs_ground_view: bool = false
@export var obstructs_air_view: bool = false
