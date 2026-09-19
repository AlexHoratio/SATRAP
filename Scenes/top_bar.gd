extends Control

var dragging = false
var drag_origin = Vector2(0, 0)
var mouse_origin = Vector2(0, 0)

func _ready():
	pass

func _process(delta):
	if dragging:
		global_position.y = clamp(drag_origin.y + (get_global_mouse_position().y - mouse_origin.y), 0, 967)

func _on_drag_button_down():
	dragging = true
	drag_origin = global_position
	mouse_origin = get_global_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_drag_button_up():
	dragging = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
