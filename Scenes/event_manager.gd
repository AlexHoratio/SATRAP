extends Node

var current_event = null

func _ready():
	get_tree().set_meta("event_manager", self)
	
	if !Saves.tutorial_muted:
		$proc_intro.start()
	
func close_event() -> void:
	if weakref(current_event).get_ref():
		current_event.queue_free()
		
	current_event = null
	
func proc_policy_prompt() -> void:
	if !Saves.tutorial_muted:
		var policy_prompt = load("res://Prefabs/Events/policy_prompt.tscn").instantiate()
		policy_prompt.close.connect(close_event)
		policy_prompt.close.connect(proc_policy_prompt2)
		get_node("../CanvasLayer/utilities/policies").pressed.connect(policy_prompt.next)
		get_node("../CanvasLayer").add_child(policy_prompt)
		
		current_event = policy_prompt
	
func proc_policy_prompt2() -> void:
	if !Saves.tutorial_muted:
		var policy_prompt = load("res://Prefabs/Events/policy_prompt2.tscn").instantiate()
		policy_prompt.close.connect(close_event)
		get_node("../CanvasLayer/utilities/policies").viewer.open_policy.connect(close_event)
		get_node("../CanvasLayer").add_child(policy_prompt)
		
		current_event = policy_prompt
	
func open_event(event_id) -> void:
	var event = load("res://Prefabs/Events/" + event_id + ".tscn").instantiate()
	event.close.connect(close_event)
	get_node("../CanvasLayer").add_child(event)
	
	current_event = event
	
func _on_proc_intro_timeout():
	var intro_message = load("res://Prefabs/Events/intro_message.tscn").instantiate()
	intro_message.close.connect(close_event)
	intro_message.close.connect(proc_policy_prompt)
	get_node("../CanvasLayer").add_child(intro_message)
	
	current_event = intro_message
