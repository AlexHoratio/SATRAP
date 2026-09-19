extends Control

signal cancelled

var id_to_sprite_path = {
	"civil": "res://Graphics/Entities/Sprites/Civil.png",
	"outpost": "res://Graphics/Entities/Sprites/Outpost.png",
	"railway": "res://Graphics/Entities/railway.png",
}

var id_to_building_path = {
	"civil": "res://Prefabs/Entities/civil.tscn",
	"outpost": "res://Prefabs/Entities/outpost.tscn",
	"railway": "res://Prefabs/Entities/railway.tscn",
}

var building_id = "civil"

var hovering_blocked_tile = false

func _ready():
	$TextureRect.texture = load(id_to_sprite_path[building_id])

func _process(delta):
	global_position = snapped(get_global_mouse_position(), Vector2(32, 32)) - Vector2(16, 16)
		
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
				new_building.position = global_position + Vector2(16, 16)
				get_node("../buildings").add_child(new_building)
				
				if !Input.is_action_pressed("shift"):
					queue_free()
				
func check_blocked() -> void:
	hovering_blocked_tile = false
	var blocked_positions = []
	
	for building in get_tree().get_nodes_in_group("buildings"):
		for blocked_pos in building.occupied_tiles:
			blocked_positions.append(blocked_pos)
			
	if (global_position + Vector2(16, 16)) in blocked_positions:
		hovering_blocked_tile = true
