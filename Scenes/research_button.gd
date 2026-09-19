extends Button

var viewer = null

var hovering = false

func _ready():
	pass
	
func _process(delta):
	position = lerp(position, Vector2(789, 1032) if hovering else Vector2(789, 1037), 15 * delta)

func close_viewer() -> void:
	viewer = null

func _on_mouse_entered():
	hovering = true

func _on_mouse_exited():
	hovering = false

func _on_pressed():
	if viewer == null:
		var research_window = load("res://Prefabs/Entities/Windows/research_window.tscn").instantiate()
		research_window.closed.connect(close_viewer)
		get_parent().add_child(research_window)
		
		viewer = research_window
	else:
		viewer.close()
