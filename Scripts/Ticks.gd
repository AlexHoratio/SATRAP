extends Node

signal tick

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
