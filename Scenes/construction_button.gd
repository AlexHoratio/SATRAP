extends Control

var hovering = false

func _ready():
	pass
	
func _process(delta):
	$overlay.self_modulate.a = lerp($overlay.self_modulate.a, 1.0 if hovering else 0.0, 0.5)

func _on_button_mouse_entered():
	hovering = true

func _on_button_mouse_exited():
	hovering = false

func _on_button_pressed():
	get_parent().get_parent().get_parent().get_parent().get_parent().change_selection(name)
