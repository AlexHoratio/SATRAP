extends Node2D
class_name Building

var occupied_tiles = []

func _ready():
	if not(position in occupied_tiles):
		occupied_tiles.append(position)
