class_name Glyphs
## Generates simple terminal-style glyph textures for buildings without pixel art.

static func make(letters: String, size := 32) -> ImageTexture:
	var img: Image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.06, 0.02, 1.0))
	# border
	var border := Color(0.0, 0.85, 0.3, 1.0)
	for i in size:
		img.set_pixel(i, 0, border)
		img.set_pixel(i, size - 1, border)
		img.set_pixel(0, i, border)
		img.set_pixel(size - 1, i, border)
	# inner dim rect
	var inner := Color(0.0, 0.25, 0.08, 1.0)
	for y in range(3, size - 3):
		for x in range(3, size - 3):
			img.set_pixel(x, y, inner)
	# letter (Godot 4 TextServer API)
	var font: Font = load("res://Graphics/Fonts/MorePerfectDOSVGA.ttf")
	var fs := 18
	var ts: TextServer = TextServerManager.get_primary_interface()
	var sz: Vector2 = font.get_string_size(letters, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pos := Vector2((size - sz.x) / 2.0, (size + sz.y) / 2.0 - 1)
	ts.draw_string(img, pos, letters, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, font, fs, Color(0.2, 1.0, 0.5, 1.0))
	return ImageTexture.create_from_image(img)
