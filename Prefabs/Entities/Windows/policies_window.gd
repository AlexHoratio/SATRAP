extends Control

signal closed
signal open_policy
signal policy_adopted

var dragging = false
var drag_origin = Vector2(0, 0)
var mouse_origin = Vector2(0, 0)

func _ready():
	generate_policy_list()

func _process(delta):
	if dragging:
		global_position = drag_origin + (get_global_mouse_position() - mouse_origin)
	
	if Input.is_action_just_pressed("esc"):
		close()
		
	arrange_policy_list(delta)
		
func generate_policy_list() -> void:
	Policies.update_available_policies() 
	
	for entry in $ascii_patch/policy_list.get_children():
		entry.queue_free()
	
	for policy_id in Policies.available_policies:
		var policy_entry = load("res://Prefabs/Entities/Windows/policy_entry.tscn").instantiate()
		policy_entry.adopt.connect(policy_opened.bind(policy_id))
		policy_entry.policy_id = policy_id
		policy_entry.policy_name = Policies.policy_information[policy_id]["name"]
		policy_entry.policy_desc = Policies.policy_information[policy_id]["desc"]
		$ascii_patch/policy_list.add_child(policy_entry)
		
func arrange_policy_list(delta: float) -> void:
	pass
		
func policy_opened(policy_id) -> void:
	emit_signal("open_policy")
	get_tree().get_meta("event_manager").open_event("standardize_currency")
	close()
		
func close() -> void:
	emit_signal("closed")
	queue_free()
	
func _on_x_pressed():
	close()

func _on_drag_button_down():
	dragging = true
	drag_origin = global_position
	mouse_origin = get_global_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_drag_button_up():
	dragging = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
