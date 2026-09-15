extends Control

var final_size = Vector2(0, 0)

var current_building = null

func _ready():
	get_tree().set_meta("action_window", self)
	visible = false
	
func _process(delta):
	$ascii_patch.size.y = lerp($ascii_patch.size.y, final_size.y, 15*delta)
	
	if visible:
		if get_global_mouse_position().distance_to($ascii_patch.global_position + $ascii_patch.size/2.0) > 300:
			forget_building()
	
func click_building(building) -> void:
	current_building = building
	visible = true
	global_position = get_global_mouse_position()
	get_tree().get_meta("inspect_window").forget_building()
	$ascii_patch.size.y = 0
	
	var building_name = ""
	var stat_details = ""
	
	match building.building_name:
		"Civilian":
			building_name = "Civilian Building"
			stat_details = "> [url href=destroy underline=hover]Destroy it![/url]"
		"Administration":
			building_name = "Administration"
			stat_details = "> ???"
		"Village":
			building_name = "Village"
			stat_details = "> ???"
		_:
			building_name = "???"
			stat_details = "I have never seen that before in my life."
	
	$ascii_patch/building_name.text = building_name
	$ascii_patch/details.text = stat_details
	
	update_final_size()
	
func forget_building() -> void:
	current_building = null
	visible = false
	
func update_final_size() -> void:
	
	final_size.x = 32.0 + $ascii_patch/building_name.get_theme_font("font").get_string_size($ascii_patch/building_name.text, 0, -1, 16).x
	$ascii_patch/details.size.x = final_size.x - 32
	
	final_size.y = 52.0 + $ascii_patch/details.get_theme_font("normal_font").get_multiline_string_size($ascii_patch/details.get_parsed_text(), 0, final_size.x - 32, 13, -1, TextServer.BREAK_WORD_BOUND | 192 | TextServer.BREAK_ADAPTIVE).y
	
	$ascii_patch.size.x = final_size.x


func _on_details_meta_clicked(meta):
	match meta:
		"destroy":
			current_building.queue_free()
			forget_building()
