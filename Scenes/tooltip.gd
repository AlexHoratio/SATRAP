extends Label

func _ready():
	get_tree().set_meta("tooltip", self)
	
func _process(delta):
	global_position = get_global_mouse_position() + Vector2(16, 0)

func add_text(new_text = ""):
	text = new_text
