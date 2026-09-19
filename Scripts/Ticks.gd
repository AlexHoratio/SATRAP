extends Node

signal tick

var pop_conversion_weights = {
	"avantists": {
		"imagists": 0.5,
		"fragmentists": 0.5,
		"other": 1.5,
	},
	"imagists": {
		"avantists": 0.1,
		"fragmentists": 0.5,
		"other": 1.0,
	},
	"fragmentists": {
		"avantists": 1.0,
		"imagists": 0.5,
		"other": 0.5,
	},
	"other": {
		"avantists": 1.0,
		"imagists": 1.0,
		"fragmentists": 1.0
	}
}

var resources = {
	"money": 150,
	"food": 100,
	"basic_civ_goods": 0,
	"luxury_civ_goods": 0,
	"basic_military_equip": 0,
	"specialist_military_equip": 0
}

var res_change_per_second = {
	"money": 0,
	"food": 0,
	"basic_civ_goods": 0,
	"luxury_civ_goods": 0,
	"basic_military_equip": 0,
	"specialist_military_equip": 0
}

var local_interests = {
	"avantists": 100,
	"imagists": 0,
	"fragmentists": 0,
	"other": 0
}

var pop_cap = 0

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
	calculate_res_change_per_second()
	
	calculate_pop_cap()
	calculate_pop_conversions()
	
	
func calculate_res_change_per_second() -> void:
	pass
	
func get_date_string():
	var days = floor(tick_id / 6.0)
	
	return Time.get_date_dict_from_unix_time(days * 86400)

func toggle_pause() -> void:
	game_paused = !game_paused

func increment_speed() -> void:
	speed_multiplier += 0.5
	
	if speed_multiplier > 4.0:
		speed_multiplier = 1.0

func calculate_pop_cap() -> void:
	pop_cap = 0
	for building in get_tree().get_nodes_in_group("buildings"):
		if building.building_name == "Civilian":
			pop_cap += 25
			
func get_pop_total() -> int:
	var total = 0
	
	for key in local_interests.keys():
		total += local_interests[key]
		
	return total

func calculate_pop_conversions() -> void:
	
	for from in pop_conversion_weights.keys():
		for to in pop_conversion_weights[from].keys():
			var amnt = clamp(int(abs(randfn(0, pop_conversion_weights[from][to]))), 0, local_interests[from])
			
			local_interests[from] -= amnt
			local_interests[to] += amnt
