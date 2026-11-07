extends Control

signal close

func _ready():
	pass
	
func _process(delta):
	pass


func _on_ignore_tutorial_pressed():
	Saves.tutorial_muted = true
	emit_signal("close")

func _on_accept_tutorial_pressed():
	emit_signal("close")
