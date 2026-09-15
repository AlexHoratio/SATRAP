extends Node2D
class_name Building
## A single-tile building in the Satrapy grid.

var building_id := "civil"
var pos := Vector2i(0, 0)
var hp := 100
var assigned := ""          # factory assignment / temple denomination / barracks unit
var garrisoned := false     # gates
var stationed := false      # outposts / barracks
var is_ruin := false
var training_progress := 0.0
var hovering := false
var selected := false
var base_sprite_scale := Vector2(1, 1)
var _sprite: Sprite2D = null
var _radius_poly: Polygon2D = null

const TILE := 32

static func def() -> Dictionary:
	return Data.BUILDINGS

func _ready() -> void:
	add_to_group("buildings")
	var d: Dictionary = Data.BUILDINGS[building_id]
	var spr := Sprite2D.new()
	_sprite = spr
	if d.get("sprite"):
		spr.texture = load(d["sprite"])
	else:
		spr.texture = Glyphs.make(Data.BUILDING_GLYPHS.get(building_id, "?"))
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spr)
	# button hit area
	var btn := Button.new()
	btn.self_modulate.a = 0.0
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.position = Vector2(-18, -18)
	btn.size = Vector2(36, 36)
	add_child(btn)

func set_id(new_id: String, p: Vector2i) -> void:
	building_id = new_id
	pos = p
	global_position = (Vector2(p) + Vector2(0.5, 0.5)) * TILE
	if is_inside_tree() and _sprite:
		var d: Dictionary = Data.BUILDINGS[building_id]
		if d.get("sprite"):
			_sprite.texture = load(d["sprite"])
		else:
			_sprite.texture = Glyphs.make(Data.BUILDING_GLYPHS.get(building_id, "?"))
		show_radius()
	queue_redraw()

func _process(_delta: float) -> void:
	if _sprite:
		var target := base_sprite_scale * (1.15 if hovering or selected else 1.0)
		_sprite.scale = _sprite.scale.lerp(target, 0.3)

func _draw() -> void:
	if hovering or selected:
		var c := Color(0, 1, 0.3, 0.9) if selected else Color(0, 1, 0.3, 0.35)
		draw_rect(Rect2(-TILE / 2.0, -TILE / 2.0, TILE, TILE), c, true)
	# hp bar
	if hp < 100 and not is_ruin:
		var frac := hp / 100.0
		draw_rect(Rect2(-12, -24, 24, 3), Color(0.2, 0, 0))
		draw_rect(Rect2(-12, -24, 24 * frac, 3), Color(0.9, 0.3, 0.2))
	# status pips
	if stationed or garrisoned:
		draw_circle(Vector2(12, -14), 3.0, Color(0.9, 0.8, 0.2))

func show_radius() -> void:
	if _radius_poly:
		_radius_poly.queue_free()
		_radius_poly = null
	var d: Dictionary = Data.BUILDINGS[building_id]
	var rad: float = float(d.get("garrison_radius", 0))
	if d.get("radius"):
		rad = d["radius"]
	if rad > 0 and (stationed or garrisoned or building_id in ["power_station", "autodefence"]):
		_radius_poly = Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append(Vector2(cos(a), sin(a)) * rad)
		_radius_poly.polygon = pts
		_radius_poly.color = Color(0, 0.9, 0.3, 0.12)
		_radius_poly.z_index = -10
		add_child(_radius_poly)

func take_damage(n: int, source: String) -> void:
	if is_ruin:
		return
	hp -= n
	if hp <= 0:
		hp = 0
		destroy()
		return
	queue_redraw()
	Game.log_msg(Data.BUILDINGS[building_id].name + " damaged by " + source + ". (" + str(hp) + "/100)", 1)

func destroy() -> void:
	is_ruin = true
	hp = 0
	if building_id != "ruin":
		var old_id := building_id
		set_id("ruin", pos)
		Game.log_msg("The " + Data.BUILDINGS[old_id].name + " has been destroyed and lies in ruins.", 2)
		if old_id == "admin":
			Game.check_game_over()
	queue_redraw()

func repair_cost() -> int:
	return 30

func info_text() -> String:
	var d: Dictionary = Data.BUILDINGS[building_id]
	var t: String = "> " + d["name"].to_upper() + "
"
	t += d["desc"] + "\n"
	match building_id:
		"factory":
			t += "\nAssigned production: " + (assigned.to_upper() if assigned else "NONE")
			if assigned:
				t += "  (mult " + str(Game.factory_mult()) + (", +50% power" if Game.power_boosts(self) else "") + ")"
		"temple":
			t += "\nDenomination: " + (assigned.to_upper() if assigned else "UNASSIGNED")
		"barracks":
			t += "\nTraining: " + (assigned.capitalize() if assigned else "UNASSIGNED") + "  (progress " + str(int(training_progress * 100)) + "%)"
			t += "\n" + str(Game.available_soldiers()) + " soldiers available to station."
		"outpost":
			t += "\nTroops stationed: " + ("YES" if stationed else "NO")
		"gate":
			t += "\nGarrison: " + ("SEALED (20 soldiers, attrition +5%/mo, risk of loss)" if garrisoned else "OPEN — Mechanoids may emerge")
		"civil", "village":
			t += "\nHousing capacity: " + str(d["capacity"]) + "  (city total " + str(Game.housing_capacity()) + ")"
	t += "\nIntegrity: " + str(hp) + "/100"
	return t

func context_options() -> Array:
	var opts := []
	match building_id:
		"factory":
			for a in ["basic_goods", "luxury_goods", "basic_mil", "special_mil"]:
				opts.append({"label": "Assign: " + a.to_upper(), "enabled": true, "action": Callable(self, "_assign").bind(a)})
		"temple":
			for a in ["solarite", "imagist", "fragmentist", "non_denominational"]:
				opts.append({"label": "Denomination: " + a.to_upper(), "enabled": true, "action": Callable(self, "_assign").bind(a)})
		"barracks":
			for a in ["militia", "specialist", "gendarme"]:
				opts.append({"label": "Train: " + a.to_upper(), "enabled": true, "action": Callable(self, "_assign").bind(a)})
			opts.append({"label": ("UNSTATION" if stationed else "STATION") + " TROOPS", "enabled": true, "action": Callable(self, "_toggle_station")})
		"outpost":
			opts.append({"label": ("UNSTATION" if stationed else "STATION") + " TROOPS", "enabled": true, "action": Callable(self, "_toggle_station")})
		"gate":
			var can := not garrisoned and Game.available_soldiers() >= 20
			opts.append({"label": ("UNGARRISON" if garrisoned else "GARRISON (20 SOLDIERS)") + " — " + ("OK" if (garrisoned or can) else "NEED 20 SOLDIERS"), "enabled": garrisoned or can, "action": Callable(self, "_toggle_garrison")})
	if not is_ruin and building_id not in ["admin", "village", "gate"]:
		opts.append({"label": "DEMOLISH (+50% refund)", "enabled": true, "action": Callable(self, "_demolish")})
	elif is_ruin:
		opts.append({"label": "CLEAR RUINS (free)", "enabled": true, "action": Callable(self, "_demolish")})
	return opts

func _assign(a: String) -> void:
	assigned = a
	show_radius()
	Game.log_msg(Data.BUILDINGS[building_id].name + ": " + a + ".", 0)
	Game.emit_signal("state_changed")

func _toggle_station() -> void:
	stationed = not stationed
	show_radius()
	Game.log_msg(Data.BUILDINGS[building_id].name + ": troops " + ("stationed." if stationed else "withdrew."), 0)
	Game.emit_signal("state_changed")

func _toggle_garrison() -> void:
	if garrisoned:
		garrisoned = false
		Game.garrison_reserve = maxf(0, Game.garrison_reserve - 20)
		Game.log_msg("The gate garrison has withdrawn. The gate stands open.", 1)
	elif Game.available_soldiers() >= 20:
		garrisoned = true
		Game.garrison_reserve += 20
		Game.log_msg("20 soldiers sealed the Circulatory Gate. Attrition will cost.", 0)
	else:
		Game.log_msg("Not enough available soldiers to garrison the gate.", 1)
	show_radius()
	Game.emit_signal("state_changed")
	Game.autosave()

func _demolish() -> void:
	if building_id in ["admin", "gate"]:
		return
	var d: Dictionary = Data.BUILDINGS[building_id]
	var refund := int(d.get("cost", 0) * 0.5) if not is_ruin else 0
	Game.res.money += refund
	Game.log_msg(Data.BUILDINGS[building_id].name + " demolished. +" + str(refund) + " Bull.", 0)
	var w = Game.world_node()
	if w:
		w.remove_building(self)
	Game.emit_signal("state_changed")
	Game.autosave()
