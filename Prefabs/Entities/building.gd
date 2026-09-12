extends Node2D
class_name Building

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
	pass
		
func _on_mouse_entered() -> void:
	hovering = true
	
func _on_mouse_exited() -> void:
	hovering = false
