extends Control

signal closed

var dragging = false
var drag_origin = Vector2(0, 0)
var mouse_origin = Vector2(0, 0)

var construction_particle = null

func _ready():
	pass
	
func _process(delta):
	
	if dragging:
		global_position = drag_origin + (get_global_mouse_position() - mouse_origin)
	
	if Input.is_action_just_pressed("esc"):
		close()
	
	for building in $ascii_patch/buildings.get_children():
		var space_x = 97
		var target_x = 4 + $ascii_patch.size.x/2.0 - ($ascii_patch/buildings.get_child_count() * (space_x/2.0)) + (building.get_index() * space_x)
		building.position.x = target_x

func close() -> void:
	emit_signal("closed")
	queue_free()
	
func create_new(building_id) -> void:
	var construction_particle = load("res://Prefabs/construction_particle.tscn").instantiate()
	construction_particle.building_id = building_id
	get_tree().get_meta("world").add_child(construction_particle)
	
func _on_x_pressed():
	close()

func _on_drag_button_down():
	dragging = true
	drag_origin = global_position
	mouse_origin = get_global_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_drag_button_up():
	dragging = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_outpost_pressed():
	if construction_particle == null:
		create_new("outpost")

func _on_civil_pressed():
	if construction_particle == null:
		create_new("civil")

func _on_farm_pressed():
	if construction_particle == null:
		create_new("farm")

func _on_factory_pressed():
	if construction_particle == null:
		create_new("factory")

func _on_barracks_pressed():
	if construction_particle == null:
		create_new("barracks")

func _on_temple_pressed():
	if construction_particle == null:
		create_new("temple")
