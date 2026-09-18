extends Control

var open = false

func _ready():
	pass
	
func _process(delta):
	
	$ascii_patch.position.y = lerp($ascii_patch.position.y, 937.0 if open else 1100.0, 15*delta)
	
	for building in $ascii_patch/buildings.get_children():
		var space_x = 52
		var target_x = $ascii_patch.size.x/2.0 - ($ascii_patch/buildings.get_child_count() * (space_x/2.0)) + (building.get_index() * space_x)
		building.position.x = lerp(building.position.x, target_x, 15*delta)

func toggle_open() -> void:
	open = !open
