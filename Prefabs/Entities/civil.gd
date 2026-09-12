extends Building

func _process(delta: float):
	super(delta)
	
	$Sprite2D.scale = lerp($Sprite2D.scale, (base_sprite_scale * 1.1) if hovering else base_sprite_scale, 20 * delta)

func _on_mouse_entered() -> void:
	super()
	get_tree().get_meta("tooltip").add_text("Civil")
	
func _on_mouse_exited() -> void:
	super()
	get_tree().get_meta("tooltip").add_text("")
