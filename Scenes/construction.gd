extends NinePatchRect

var hovering = false
var open = false

var current_selection = "railway"

func _ready():
	get_tree().set_meta("construction", self)
	
func _process(delta):
	$ColorRect.modulate.a = lerp($ColorRect.modulate.a, 1.0 if hovering else 0.0, 0.86)

func change_selection(new: String) -> void:
	current_selection = new
	$unit_menu/g9patch/current_selection.text = "Current Selection:\n" + current_selection.capitalize()

func _on_button_mouse_entered():
	hovering = true

func _on_button_mouse_exited():
	hovering = false

func _on_button_pressed():
	open = !open
	$unit_menu.visible = open
