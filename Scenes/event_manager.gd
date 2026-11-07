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
	
func proc_standardize_currency_event() -> void:
	if !Saves.tutorial_muted:
		var standardize_currency_event = load("res://Prefabs/Events/standardize_currency_event.tscn").instantiate()
		standardize_currency_event.close.connect(close_event)
		get_node("../CanvasLayer").add_child(standardize_currency_event)
	
func _on_proc_intro_timeout():
	var intro_message = load("res://Prefabs/Events/intro_message.tscn").instantiate()
	intro_message.close.connect(close_event)
	intro_message.close.connect(proc_standardize_currency_event)
	get_node("../CanvasLayer").add_child(intro_message)
	
	current_event = intro_message
