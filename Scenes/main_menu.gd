extends Control
# SATRAP main menu — start condition selection + continue.

var font: Font
var selected := "local_revol"
var cond_buttons := {}

func _ready() -> void:
	font = load("res://Graphics/Fonts/MorePerfectDOSVGA.ttf")
	_build_conditions()

func _build_conditions() -> void:
	var box := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.0, 0.05, 0.02, 0.9)
	s.border_color = Color(0, 0.6, 0.25)
	s.set_border_width_all(1)
	s.set_content_margin_all(12)
	box.add_theme_stylebox_override("panel", s)
	box.position = Vector2(200, 300)
	box.size = Vector2(1040, 520)
	add_child(box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	box.add_child(vb)
	var title := Label.new()
	title.text = "CHOOSE YOUR PATH TO THE SATRAP'S CHAIR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 1, 0.85))
	vb.add_child(title)

	for sid in Data.STARTS:
		var st: Dictionary = Data.STARTS[sid]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		vb.add_child(row)
		var b := Button.new()
		b.text = st.name.to_upper()
		b.flat = true
		b.custom_minimum_size = Vector2(300, 40)
		b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", Color(0, 0.95, 0.35))
		b.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
		b.add_theme_color_override("font_pressed_color", Color(1, 1, 0.8))
		b.pressed.connect(_select.bind(sid))
		row.add_child(b)
		cond_buttons[sid] = b
		var desc := Label.new()
		desc.text = st.desc
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(640, 0)
		desc.add_theme_font_override("font", font)
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0, 0.7, 0.35))
		row.add_child(desc)

	# continue button (if a save exists)
	if Game.has_save():
		var cont := Button.new()
		cont.text = "> CONTINUE (LOAD SAVE) <"
		cont.flat = true
		cont.add_theme_font_override("font", font)
		cont.add_theme_font_size_override("font_size", 18)
		cont.add_theme_color_override("font_color", Color(1, 1, 0.85))
		cont.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
		cont.pressed.connect(_continue_pressed)
		vb.add_child(cont)
	_highlight()

func _select(sid: String) -> void:
	selected = sid
	_highlight()

func _highlight() -> void:
	for sid in cond_buttons:
		cond_buttons[sid].text = ("> " if sid == selected else "   ") + Data.STARTS[sid].name.to_upper()

func _on_play_pressed() -> void:
	Game.start_game(selected)
	get_tree().change_scene_to_file("res://Scenes/satrap.tscn")

func _continue_pressed() -> void:
	get_tree().set_meta("satrap_continue", true)
	get_tree().change_scene_to_file("res://Scenes/satrap.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
