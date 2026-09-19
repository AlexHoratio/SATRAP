extends Node2D

var tile_size = Vector2(93, 93)
var line_color = Color(0.0, 1.0, 0.0, 0.259)

func _ready():
	get_tree().set_meta("world", self)
	generate_world()

func _process(delta):
	queue_redraw()
	
func _draw():
	return
	var screen_size = Vector2(1440, 1080)
	
	var number_of_horizontal_lines = floor(screen_size.y / tile_size.y) + 4
	var number_of_vertical_lines = floor(screen_size.x / tile_size.x) + 4
	
	var camera_offset = get_node("../Camera2D").position
	var thickness = 4.0
	
	for y in number_of_horizontal_lines:
		var y_pos = tile_size.y * (y - number_of_horizontal_lines/2) + floor(camera_offset.y/tile_size.y) * tile_size.y
		draw_line(Vector2(camera_offset.x - screen_size.x/2.0, y_pos), Vector2(camera_offset.x + screen_size.x/2.0, y_pos), line_color, thickness)
	
	for x in number_of_vertical_lines:
		var x_pos = tile_size.x * (x - number_of_vertical_lines/2) + floor(camera_offset.x/tile_size.x) * tile_size.x
		draw_line(Vector2(x_pos, camera_offset.y - screen_size.y/2.0), Vector2(x_pos, camera_offset.y + screen_size.y/2.0), line_color, thickness)
	
func generate_world() -> void:
	var admin = load("res://Prefabs/Entities/admin.tscn").instantiate()
	admin.position = Vector2(720, 540).snapped(tile_size)
	var tile_offsets = [
		Vector2(-1, 0),
		Vector2(-1, 1),
		Vector2(-1, -1),
		Vector2(0, -1), 
		Vector2(0, 1),
		Vector2(1, 1),
		Vector2(1, 0),
		Vector2(1, -1)
	]
	admin.occupied_tiles.append(admin.position)
	for i in tile_offsets:
		i.x *= tile_size.x
		i.y *= tile_size.y
		admin.occupied_tiles.append(admin.position + i)
		
	$buildings.add_child(admin)
	
	
	for i in range(1 + randi()%2):
		var radius = 1200
		var min_radius = 800
		var village = load("res://Prefabs/Entities/village.tscn").instantiate()
		var building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
		building_position = building_position.snapped(tile_size)
		
		var position_occupied = true
		while position_occupied:
			building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
			building_position = building_position.snapped(tile_size)
			position_occupied = false
			for building in get_tree().get_nodes_in_group("buildings"):
				if building_position in building.occupied_tiles:
					position_occupied = true
					
		tile_offsets = [
			Vector2(-1, 0),
			Vector2(-1, 1),
			Vector2(-1, -1),
			Vector2(0, -1), 
			Vector2(0, 1),
			Vector2(1, 1),
			Vector2(1, 0),
			Vector2(1, -1)
		]
		village.occupied_tiles.append(village.position)
		for j in tile_offsets:
			j.x *= tile_size.x
			j.y *= tile_size.y
			village.occupied_tiles.append(village.position + j)
		
		village.position = building_position
		$buildings.add_child(village)
	
	
	for i in range(20):
		var radius = 650
		var civil = load("res://Prefabs/Entities/civil.tscn").instantiate()
		var building_position = Vector2(720, 540) + Vector2(radius * randf(), 0).rotated(2 * PI * randf())
		building_position = building_position.snapped(tile_size)
		
		var position_occupied = true
		while position_occupied:
			building_position = Vector2(720, 540) + Vector2(radius * randf(), 0).rotated(2 * PI * randf())
			building_position = building_position.snapped(tile_size)
			position_occupied = false
			for building in get_tree().get_nodes_in_group("buildings"):
				if building_position in building.occupied_tiles:
					position_occupied = true
		
		civil.position = building_position
		$buildings.add_child(civil)
	
	for i in range(1):
		var radius = 500
		var min_radius = 0
		var temple = load("res://Prefabs/Entities/temple.tscn").instantiate()
		var building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
		building_position = building_position.snapped(tile_size)
		
		var position_occupied = true
		while position_occupied:
			building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
			building_position = building_position.snapped(tile_size)
			position_occupied = false
			for building in get_tree().get_nodes_in_group("buildings"):
				if building_position in building.occupied_tiles:
					position_occupied = true
		
		temple.position = building_position
		$buildings.add_child(temple)
	
	for i in range(1):
		var radius = 500
		var min_radius = 0
		var factory = load("res://Prefabs/Entities/factory.tscn").instantiate()
		var building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
		building_position = building_position.snapped(tile_size)
		
		var position_occupied = true
		while position_occupied:
			building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
			building_position = building_position.snapped(tile_size)
			position_occupied = false
			for building in get_tree().get_nodes_in_group("buildings"):
				if building_position in building.occupied_tiles:
					position_occupied = true
		
		factory.position = building_position
		$buildings.add_child(factory)
	
	for i in range(2):
		var radius = 500
		var min_radius = 0
		var farm = load("res://Prefabs/Entities/farm.tscn").instantiate()
		var building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
		building_position = building_position.snapped(tile_size)
		
		var position_occupied = true
		while position_occupied:
			building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
			building_position = building_position.snapped(tile_size)
			position_occupied = false
			for building in get_tree().get_nodes_in_group("buildings"):
				if building_position in building.occupied_tiles:
					position_occupied = true
		
		farm.position = building_position
		$buildings.add_child(farm)
	
	for i in range(1):
		var radius = 500
		var min_radius = 0
		var barracks = load("res://Prefabs/Entities/barracks.tscn").instantiate()
		var building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
		building_position = building_position.snapped(tile_size)
		
		var position_occupied = true
		while position_occupied:
			building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
			building_position = building_position.snapped(tile_size)
			position_occupied = false
			for building in get_tree().get_nodes_in_group("buildings"):
				if building_position in building.occupied_tiles:
					position_occupied = true
		
		barracks.position = building_position
		$buildings.add_child(barracks)
	
	for i in range(1):
		var radius = 1600
		var min_radius = 1500
		var circulatory_gate = load("res://Prefabs/Entities/circulatory_gate.tscn").instantiate()
		var building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
		building_position = building_position.snapped(tile_size)
		
		var position_occupied = true
		while position_occupied:
			building_position = Vector2(720, 540) + Vector2(min_radius + (radius - min_radius) * randf(), 0).rotated(2 * PI * randf())
			building_position = building_position.snapped(tile_size)
			position_occupied = false
			for building in get_tree().get_nodes_in_group("buildings"):
				if building_position in building.occupied_tiles:
					position_occupied = true
		
		circulatory_gate.position = building_position
		$buildings.add_child(circulatory_gate)
