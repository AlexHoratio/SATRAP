extends Node2D

signal move_happened

var pieces_map = {}
var move_queue = []
var move_interval = 0.00 # why is this a thing?
var move_timer = 0

var piece_movement_time_scale = 1

var grid_cell_size = Vector2(16, 16)
var grid_size = Vector2(96, 48)
var grid_color = Color("0e633bff")
var grid_thickness = 1

func _ready():
	pass
	
func _process(delta):
	queue_redraw()
	
	if Input.is_action_just_pressed("left_click"):
		var click_tile = get_tile_at_coord(get_global_mouse_position() - position)
		
		if is_tile_free(click_tile) and is_tile_permitted(click_tile):
			var current_selection = get_tree().get_meta("construction").current_selection
			
			var building = load("res://Prefabs/Entities/" + current_selection + ".tscn").instantiate()
			add_child(building)
			assign_piece_to_map(click_tile, building)
			building.global_position = get_global_position_of_coord(click_tile)
	
	move_timer += delta
	if move_timer > move_interval:
		move_timer -= move_interval
		if move_queue.size() > 0:
			var piece = move_queue.pop_front()
			
			if piece != null:
				if weakref(piece).get_ref():
					piece.move()
	
func _draw():
	for vertical_line in grid_size.y + 1:
		draw_line(Vector2(0, vertical_line * grid_cell_size.y), Vector2(grid_size.x * grid_cell_size.x, vertical_line * grid_cell_size.y), grid_color, grid_thickness)
	for horizontal_line in grid_size.x + 1:
		draw_line(Vector2(horizontal_line * grid_cell_size.x, 0), Vector2(horizontal_line * grid_cell_size.x, grid_size.y * grid_cell_size.y), grid_color, grid_thickness)
	
	var click_tile = get_tile_at_coord(get_global_mouse_position() - position)
	
	if is_tile_free(click_tile) and is_tile_permitted(click_tile):
		draw_rect(Rect2(get_global_position_of_coord(click_tile) - position - Vector2(0.5, 0.5) * grid_cell_size, grid_cell_size), Color("#FFFFFF44"), true)
	

func get_piece_from_map(coord: Vector2):
	if pieces_map.has(coord):
		return pieces_map[coord]
	else:
		return null
		
func queue_move(piece) -> void:
	move_queue.append(piece)
		
func assign_piece_to_map(coord: Vector2, piece) -> void:
	assert(not(pieces_map.has(coord)) or pieces_map[coord] == null)
	
	pieces_map[coord] = piece
	
func move_piece_to(piece, destination):
	for coord in pieces_map.keys():
		if pieces_map[coord] == piece:
			pieces_map[coord] = null
		
	pieces_map[destination] = piece

func move_piece_from_to(from, to, piece=null, suppress_attack = false) -> void:
	if not(pieces_map.has(from)):
		print_debug("Error! Moving from unoccupied place!")
		return
	
	if pieces_map[from] == null:
		print_debug("Error! Moving from null tile!")
		return
		
	if !is_tile_permitted(to):
		print_debug("Error! Moving to nonpermitted tile!")
		return
		
	if !weakref(piece).get_ref():
		print_debug("Error! Piece was null!")
		return
		
	# check if move is still valid (and it's not a dodge move)
	if piece.has_node("Behaviour") and not(suppress_attack):
		var valid_moves = piece.get_node("Behaviour").get_valid_moves()
		if not((to - from) in valid_moves):
			print_debug("Error! On second thought, move was not valid!")
			return
			
	if piece.being_attacked:
		print_debug("Oops! Piece tried to move while being attacked!")
		return
			
	if !is_tile_free(to):
		if suppress_attack:
			print_debug("Error! Tried to move into non-free tile, but attack suppressed!")
			return
			
		if pieces_map[to].has_node("Behaviour"):
			if pieces_map[to].team == piece.team:
				print_debug("Error! Tried to move onto ally piece! Team: " + str(piece.team))
				return
				
			pieces_map[to].being_attacked = true
				
			var dodge = randf() < pieces_map[to].dodge and pieces_map[to].can_dodge()
			var resist = randf() < pieces_map[to].resist
			if ((pieces_map[to].health > piece.strength or pieces_map[to].shield != 0) and not(dodge)) or resist:
				var tween = get_tree().create_tween()
				var attack_destination = global_position + (grid_cell_size.x * (to + Vector2(0.5, 0.5)))
				
				var c = Vector2(-0.75, 0).rotated(piece.global_position.angle_to_point(attack_destination))
				attack_destination.x += grid_cell_size.x * c.x
				attack_destination.y += grid_cell_size.y * c.y
				
				tween.tween_property(piece, "global_position", attack_destination, 0.25*piece_movement_time_scale).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
				tween.tween_callback(attack_piece.bind(piece, pieces_map[to], resist))
				
				return
				
			if dodge:
				pieces_map[to].dodge_move()
			else:
				pieces_map[to].get_node("Behaviour").take(false, piece)
				
	pieces_map[to] = piece
	
	if pieces_map[from] == piece:
		pieces_map[from] = null
	
	piece.occupying_tile = to
	
	emit_signal("move_happened", from, to)

	
func attack_piece(attacker, enemy_piece, resisted=false) -> void:
	enemy_piece.being_attacked = false
	
	if weakref(enemy_piece).get_ref():
		enemy_piece.damage(attacker.strength, attacker)
		
func done_moving(piece) -> void:
	if piece != null:
		if weakref(piece).get_ref():
			if piece.has_node("Behaviour"):
				piece.get_node("Behaviour").moving = false
	
func replace_piece_at(coord, piece_name, team) -> void:
	if pieces_map.has(coord):
		if pieces_map[coord] != null:
			pieces_map[coord] = null
	
	get_parent().add_pieces_from_dict({coord: {"piece_name": piece_name}}, "white" if team == 0 else "black")
	
func is_tile_free(coord) -> bool:
	if !pieces_map.has(coord):
		return true
	
	if pieces_map[coord] == null:
		return true
		
	return false
	
func is_tile_permitted(coord) -> bool:
	if coord.x < 0 or coord.x >= grid_size.x:
		return false
	if coord.y < 0 or coord.y >= grid_size.y:
		return false
		
	return true

func get_tile_at_coord(coord: Vector2) -> Vector2:
	coord.x /= float(grid_cell_size.x) 
	coord.y /= float(grid_cell_size.y) 
	coord = coord.floor()
	
	if coord.x < grid_size.x and coord.y < grid_size.y and coord.x >= 0 and coord.y >= 0:
		return coord
	else:
		return Vector2(-1, -1)
	
func get_global_position_of_coord(coord: Vector2) -> Vector2:
	var global_pos = (coord + Vector2(0.5, 0.5))
	global_pos.x *= grid_cell_size.x
	global_pos.y *= grid_cell_size.y
	
	global_pos += global_position
	
	return global_pos
