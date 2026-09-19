extends Control

signal cancelled

var id_to_sprite_path = {
	"civil": "res://Graphics/Entities/Trace/civil3.png",
	"outpost": "res://Graphics/Entities/Trace/outpost.png",
	"farm": "res://Graphics/Entities/Trace/farm.png",
	"factory": "res://Graphics/Entities/Trace/factory.png",
	"barracks": "res://Graphics/Entities/Trace/barracks.png",
	"temple": "res://Graphics/Entities/Trace/temple.png",
}

var id_to_building_path = {
	"civil": "res://Prefabs/Entities/civil.tscn",
	"outpost": "res://Prefabs/Entities/outpost.tscn",
	"farm": "res://Prefabs/Entities/farm.tscn",
	"factory": "res://Prefabs/Entities/factory.tscn",
	"barracks": "res://Prefabs/Entities/barracks.tscn",
	"temple": "res://Prefabs/Entities/temple.tscn",
}

var building_id = "civil"

var hovering_blocked_tile = false

var tile_size = Vector2(93, 93)

func _ready():
	$TextureRect.texture = load(id_to_sprite_path[building_id])

func _process(delta):
	global_position = snapped(get_global_mouse_position(), tile_size) - tile_size/2.0
		
	$TextureRect.modulate = Color.RED if hovering_blocked_tile else Color.WHITE
	
func _input(event):
	check_blocked()
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_RIGHT:
				emit_signal("cancelled")
				queue_free()
			elif event.button_index == MOUSE_BUTTON_LEFT and !hovering_blocked_tile:
				var new_building = load(id_to_building_path[building_id]).instantiate()
				new_building.position = global_position + tile_size/2.0
				get_node("../buildings").add_child(new_building)
				
				if !Input.is_action_pressed("shift"):
					queue_free()
				
func check_blocked() -> void:
	hovering_blocked_tile = false
	var blocked_positions = []
	
	for building in get_tree().get_nodes_in_group("buildings"):
		for blocked_pos in building.occupied_tiles:
			blocked_positions.append(blocked_pos)
			
	if (global_position + tile_size/2.0) in blocked_positions:
		hovering_blocked_tile = true
