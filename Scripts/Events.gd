extends Node

var event_decisions = {}

func _ready():
	pass
	
func add_event_decision(event_name, decision_name) -> void:
	event_decisions[event_name] = decision_name
