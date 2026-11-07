extends Control

signal adopt

var hovering = false

var policy_id = "standardize_currency"
var policy_name = ">> Standardize Currency "
var policy_desc = "[color=#47ff47]Make everything the same currency. Makes sense right?? Well it better. Because this is a sensible policy that you want to select, probably. "

func _ready():
	$policy_name.text = policy_name
	$desc.text = policy_desc
	
	# adjust size
	
func _process(delta):
	$ColorRect.modulate.a = lerp($ColorRect.modulate.a, 1.0 if hovering else 0.0, 15 * delta)

func _on_button_pressed():
	emit_signal("adopt")


func _on_button_mouse_entered():
	hovering = true

func _on_button_mouse_exited():
	hovering = false
