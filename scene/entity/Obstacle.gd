class_name Obstacle
extends Entity

# Physical obstacle on the map
var type: ObstacleType

func set_obstacle_type(_type: ObstacleType):
	type = _type
	health = _type.max_health
	max_health = _type.max_health
