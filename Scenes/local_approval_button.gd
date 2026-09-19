extends Button

var viewer = null

var hovering = false

func _ready():
	pass
	
func _process(delta):
	position = lerp(position, Vector2(159, 1032) if hovering else Vector2(159, 1037), 15 * delta)

func close_viewer() -> void:
	viewer = null

func _on_mouse_entered():
	hovering = true

func _on_mouse_exited():
	hovering = false

func _on_pressed():
	if viewer == null:
		var approval_viewer = load("res://Prefabs/Entities/Windows/local_approval_viewer.tscn").instantiate()
		approval_viewer.closed.connect(close_viewer)
		get_parent().add_child(approval_viewer)
		
		viewer = approval_viewer
	else:
		viewer.close()
