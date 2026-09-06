extends Node

signal tick

var tick_id = 0
var tick_speed = 1
var tick_timer = 0

func _process(delta):
	tick_timer += delta
	if tick_timer > tick_speed:
		tick_timer -= tick_speed
		tick_id += 1
		emit_signal("tick")
