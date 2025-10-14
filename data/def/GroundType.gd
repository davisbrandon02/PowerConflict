class_name GroundType
extends Resource

@export var name: String
@export var ground_accessible: bool = true
@export var sea_accessible: bool = false
@export var air_accessible: bool = true
@export var obstructs_view: bool = false

# By source ID
static var db = {
	0: load("res://data/map/ground/grass.tres"),
	1: load("res://data/map/ground/sand.tres"),
}

static func get_by_source_id(source_id: int):
	if db.has(source_id):
		return db[source_id]
	return null
