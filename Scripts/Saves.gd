extends Node

var save_loc = "user://satrap_session.save"
var data = ConfigFile.new()

var tutorial_muted = false
var standardize_currency_prompt_fired = false

func _ready():
	data.load(save_loc)
	
func save() -> void:
	data.save(save_loc)
