extends Node2D

var tile_size = Vector2(32, 32)
var line_color = Color(1.0, 1.0, 1.0, 0.137)

func _ready():
	pass

func _process(delta):
	queue_redraw()
	
func _draw():
	var screen_size = Vector2(1440, 1080)
	
	var number_of_horizontal_lines = floor(screen_size.y / tile_size.y) + 4
	var number_of_vertical_lines = floor(screen_size.x / tile_size.x) + 4
	
	var camera_offset = get_node("../Camera2D").position
	
	for y in number_of_horizontal_lines:
		var y_pos = tile_size.y * (y - number_of_horizontal_lines/2) + floor(camera_offset.y/tile_size.y) * tile_size.y
		draw_line(Vector2(camera_offset.x - screen_size.x/2.0, y_pos), Vector2(camera_offset.x + screen_size.x/2.0, y_pos), line_color, 1.0)
	
	for x in number_of_vertical_lines:
		var x_pos = tile_size.x * (x - number_of_vertical_lines/2) + floor(camera_offset.x/tile_size.x) * tile_size.x
		draw_line(Vector2(x_pos, camera_offset.y - screen_size.y/2.0), Vector2(x_pos, camera_offset.y + screen_size.y/2.0), line_color, 1.0)
	
