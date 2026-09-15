extends Node

signal tick

var resources = {
	"pop": 100,
	"pop_cap": 150,
	"food": 100
}

var local_interests = {
	"avantists": 100,
	"imagists": 0,
	"fragmentists": 0,
	"other": 0
}

var tick_id = 0
var tick_speed = 1
var tick_timer = 0

var game_paused = false
var speed_multiplier = 1.0

func _ready():
	tick.connect(proc_tick)

func _process(delta):
	if !game_paused:
		tick_timer += delta * speed_multiplier
		if tick_timer > tick_speed:
			tick_timer -= tick_speed
			tick_id += 1
			emit_signal("tick")
	
func proc_tick():
	tick_production()
	tick_consumption()
	
func tick_production():
	for building in get_tree().get_nodes_in_group("buildings"):
		pass
		
func tick_consumption():
	var net_food_eat = 0
	for building in get_tree().get_nodes_in_group("buildings"):
		if building.building_name == "Civilian":
			net_food_eat += 0.1
			
	resources["food"] -= net_food_eat
	
func get_date_string():
	var days = floor(tick_id / 6.0)
	
	return Time.get_date_dict_from_unix_time(days * 86400)

func toggle_pause() -> void:
	game_paused = !game_paused

func increment_speed() -> void:
	speed_multiplier += 0.5
	
	if speed_multiplier > 4.0:
		speed_multiplier = 1.0
