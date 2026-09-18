extends Button

var viewer = null

var hovering = false

func _ready():
	pass
	
func _process(delta):
	position = lerp(position, Vector2(638, 1032) if hovering else Vector2(638, 1037), 15 * delta)

func close_viewer() -> void:
	viewer = null

func _on_mouse_entered():
	hovering = true

func _on_mouse_exited():
	hovering = false

func _on_pressed():
	get_node("../../construction_window").toggle_open()
