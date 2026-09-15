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

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if has_node("Button"):
			if $Button.get_global_rect().has_point(get_global_mouse_position()):
				if event.button_index == MOUSE_BUTTON_LEFT:
					get_tree().get_meta("inspect_window").click_building(self)
					get_tree().get_meta("tooltip").add_text("")
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					get_tree().get_meta("action_window").click_building(self)
					get_tree().get_meta("tooltip").add_text("")

func _on_mouse_entered() -> void:
	hovering = true
	get_tree().get_meta("tooltip").add_text(building_name)
	
func _on_mouse_exited() -> void:
	hovering = false
	get_tree().get_meta("tooltip").add_text("")
	get_tree().get_meta("inspect_window").forget_building()
