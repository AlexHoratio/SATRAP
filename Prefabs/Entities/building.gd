extends Node2D
class_name Building

@export var building_name = "???"

var occupied_tiles = []

var hovering = false
var base_sprite_scale = Vector2(1, 1)

func _ready():
	if not(position in occupied_tiles):
		occupied_tiles.append(position)
	
	if has_node("Button"):
		$Button.mouse_entered.connect(_on_mouse_entered)
		$Button.mouse_exited.connect(_on_mouse_exited)
		
	if has_node("Sprite2D"):
		base_sprite_scale = $Sprite2D.scale
		
func _process(delta):
	
	if has_node("Sprite2D"):
		$Sprite2D.scale = lerp($Sprite2D.scale, (base_sprite_scale * 1.1) if hovering else base_sprite_scale, 20 * delta)

		
func _on_mouse_entered() -> void:
	hovering = true
	get_tree().get_meta("tooltip").add_text(building_name)
	
func _on_mouse_exited() -> void:
	hovering = false
	get_tree().get_meta("tooltip").add_text("")
