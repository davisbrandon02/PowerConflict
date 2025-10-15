class_name Individual
extends Node2D

# Represents the sprites of individual units on the map
# Don't actually have any game logic, just handles sprites

var current_face_direction: Vector2 = Vector2.RIGHT
@onready var face_mapping: Dictionary = {
	Vector2.DOWN: %DownSprite,
	Vector2.UP: %UpSprite,
	Vector2.LEFT: %LeftSprite,
	Vector2.RIGHT: %RihtSprite,
}

# Face certain direction
func face(direction: Vector2):
	for sprite in %Sprites.get_children():
		sprite.visible = false
		
	if direction in face_mapping.keys():
		face_mapping[direction].visible = true
