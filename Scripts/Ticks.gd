extends Node

signal tick

var resources = {
	"food": 100
}

var tick_id = 0
var tick_speed = 1
var tick_timer = 0

func _ready():
	tick.connect(proc_tick)

func _process(delta):
	tick_timer += delta
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
	
