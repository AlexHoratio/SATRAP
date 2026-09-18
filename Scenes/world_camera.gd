extends Camera2D

var camera_speed = 500

func _ready():
	pass
	
func _process(delta):
	var movement_vector = Vector2(0, 0)
	
	if Input.is_action_pressed("left"):
		movement_vector.x -= 1
	if Input.is_action_pressed("right"):
		movement_vector.x += 1
	if Input.is_action_pressed("up"):
		movement_vector.y -= 1
	if Input.is_action_pressed("down"):
		movement_vector.y += 1
		
	if movement_vector != Vector2(0, 0):
		get_tree().get_meta("inspect_window").forget_building()
		get_tree().get_meta("action_window").forget_building()
		
	position += movement_vector * camera_speed * delta
