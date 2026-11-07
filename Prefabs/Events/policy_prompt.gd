extends Control

signal close

func _ready():
	pass

func next() -> void:
	emit_signal("close")
