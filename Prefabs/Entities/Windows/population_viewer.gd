extends Control

signal closed

var dragging = false
var drag_origin = Vector2(0, 0)
var mouse_origin = Vector2(0, 0)


func _ready():
	Ticks.tick.connect(update_text)
	update_text()
	
func _process(delta):
	if dragging:
		global_position = drag_origin + (get_global_mouse_position() - mouse_origin)
	
	if Input.is_action_just_pressed("esc"):
		close()
		
func update_text() -> void:
	var pop_total = Ticks.get_pop_total()
	
	var props = {
		"a": int(100 * float(Ticks.local_interests["avantists"]) / float(pop_total)),
		"i": int(100 * float(Ticks.local_interests["imagists"]) / float(pop_total)),
		"f": int(100 * float(Ticks.local_interests["fragmentists"]) / float(pop_total)),
		"o": int(100 * float(Ticks.local_interests["other"]) / float(pop_total)),
	}
	
	$ascii_patch/breakdown_r.text = "[color=#0f0]" + str(int(Ticks.local_interests["avantists"])) + " [color=#00ff0055](" + str(props["a"]) + "%)

[color=#0f0]" + str(int(Ticks.local_interests["imagists"])) + " [color=#00ff0055](" + str(props["i"]) + "%)

[color=#0f0]" + str(int(Ticks.local_interests["fragmentists"])) + " [color=#00ff0055](" + str(props["f"]) + "%)

[color=#0f0]" + str(int(Ticks.local_interests["other"])) + " [color=#00ff0055](" + str(props["o"]) + "%)"
	
	var cap_text_colour = "[color=#444]" if Ticks.pop_cap >= pop_total else "[color=#f00]"
	
	$ascii_patch/total_r.text = "[color=#0f0]" + str(int(pop_total)) + " citizens
" + cap_text_colour + str(int(Ticks.pop_cap)) + " capacity"
		
func close() -> void:
	emit_signal("closed")
	queue_free()
	
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
