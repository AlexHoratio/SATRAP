extends Node2D
## The Satrapy map: grid, buildings, hostiles, world input.

signal context_requested(target: Node, screen_pos: Vector2)

const TILE := 32
const CENTER := Vector2(1000, 700)
const MAP_RADIUS := 1900.0

var buildings := {}  # Vector2i -> Building
var hostiles := []  # Array[Hostile]
var hovered: Node = null
var ghost_valid := false
var ghost_pos := Vector2i(0, 0)

func _ready() -> void:
	add_to_group("world")
	generate(Game.start_id)
	var cam := get_node_or_null("../Camera2D")
	if cam:
		cam.position = CENTER
		cam.zoom = Vector2(1, 1)

# ----------------------------------------------------------------- generate

func generate(start_id: String) -> void:
	var start: Dictionary = Data.STARTS.get(start_id, Data.STARTS["local_revol"])
	clear_all()
	# admin at center
	var admin_pos := Vector2i(31, 21)  # 1000,672 snapped -> center-ish
	place_building("admin", admin_pos, true)
	# ring of essentials
	var ring1 := [
		["civil", Vector2i(-2, 0)], ["civil", Vector2i(2, 0)],
		["farm", Vector2i(0, -2)], ["farm", Vector2i(-2, 2)], ["farm", Vector2i(2, 2)], ["farm", Vector2i(0, 2)],
		["factory", Vector2i(1, -1)], ["barracks", Vector2i(-1, 1)],
		["temple", Vector2i(3, -2)], ["temple", Vector2i(-3, -2)],
		["civil", Vector2i(1, 2)], ["farm", Vector2i(-1, -2)],
	]
	var temples := 0
	for r in ring1:
		var b = place_building(r[0], admin_pos + r[1], true)
		if b and r[0] == "temple":
			temples += 1
			b.assigned = "imagist" if temples == 1 else "fragmentist"
	# extra farms to make food viable
	for extra in [Vector2i(2, -2), Vector2i(-2, -1), Vector2i(4, 1)]:
		place_building("farm", admin_pos + extra, true)
	# villages
	for i in range(2):
		var ang := TAU * i / 2.0 + randf_range(0.3, 0.9)
		var pos := snap_tile(CENTER + Vector2(cos(ang), sin(ang)) * randf_range(1200, 1500))
		place_building("village", pos, true)
	# gates
	for i in range(2):
		var ang := TAU * (i + 0.5) / 2.0 + randf_range(-0.4, 0.4)
		var pos := snap_tile(CENTER + Vector2(cos(ang), sin(ang)) * randf_range(1500, 1750))
		place_building("gate", pos, true)
	# ruins per start condition
	if start.ruin_chance > 0:
		var candidates := []
		for p in buildings.keys():
			var b = buildings[p]
			if b.building_id not in ["admin", "gate", "village"]:
				candidates.append(p)
		candidates.shuffle()
		var ruin_count := int(candidates.size() * start.ruin_chance)
		for i in range(ruin_count):
			var p: Vector2i = candidates[i]
			var b = buildings[p]
			b.destroy()

func snap_tile(p: Vector2) -> Vector2i:
	return Vector2i(int(p.x / TILE), int(p.y / TILE))

func tile_center(p: Vector2i) -> Vector2:
	return (Vector2(p) + Vector2(0.5, 0.5)) * TILE

func in_bounds(p: Vector2i) -> bool:
	return tile_center(p).distance_to(CENTER) <= MAP_RADIUS

# ----------------------------------------------------------------- buildings

func place_building(bid: String, p: Vector2i, free := false) -> Building:
	if buildings.has(p):
		return null
	if bid == "hostile_placeholder":
		return null
	var node = Node2D.new()
	node.set_script(load("res://Prefabs/Entities/building.gd"))
	node.building_id = bid
	add_child(node)
	node.set_id(bid, p)
	buildings[p] = node
	return node

func remove_building(b: Node) -> void:
	for p in buildings.keys():
		if buildings[p] == b:
			buildings.erase(p)
			break
	b.queue_free()

func building_at(gpos: Vector2) -> Node:
	var p := snap_tile(gpos)
	if buildings.has(p):
		var b = buildings[p]
		if b.global_position.distance_to(gpos) <= TILE * 0.8:
			return b
	return null

func can_place(p: Vector2i) -> bool:
	if not in_bounds(p) or buildings.has(p):
		return false
	# must be near an existing structure (3 tiles)
	for other_p in buildings.keys():
		var b = buildings[other_p]
		if b.is_ruin and b.building_id != "ruin":
			continue
		if tile_center(p).distance_to(b.global_position) <= TILE * 3.0:
			return true
	return false

func try_place(bid: String, p: Vector2i) -> bool:
	var d: Dictionary = Data.BUILDINGS[bid]
	if d.get("cost", 0) > 0 and Game.res.money < d["cost"]:
		Game.log_msg("Not enough Money for " + d["name"] + " (need " + str(d["cost"]) + ").", 1)
		return false
	if not can_place(p):
		return false
	var b := place_building(bid, p)
	if not b:
		return false
	Game.res.money -= int(d["cost"])
	Game.log_msg("Constructed: " + d["name"] + ". (-" + str(d["cost"]) + " Bull)", 0)
	Game.emit_signal("state_changed")
	Game.autosave()
	return true

# ------------------------------------------------------------------ hostiles

func spawn_hostile(kind: String, gpos: Vector2 = Vector2.ZERO) -> Hostile:
	if gpos == Vector2.ZERO:
		var ang := randf() * TAU
		var r := randf_range(1100, 1600)
		gpos = CENTER + Vector2(cos(ang), sin(ang)) * r
		gpos = tile_center(snap_tile(gpos))
	var h := Node2D.new()
	h.set_script(load("res://Prefabs/Entities/hostile.gd"))
	h.kind = kind
	add_child(h)
	h.global_position = gpos
	hostiles.append(h)
	Game.log_msg("HOSTILE SIGHTED: " + Data.HOSTILES[kind].name + ".", 2)
	return h

func remove_hostile(h: Node) -> void:
	hostiles.erase(h)
	h.queue_free()

func kill_hostile_of_kind(kind: String, msg: String) -> void:
	for i in hostiles.size() - 1:
		if hostiles[i].kind == kind:
			var h: Hostile = hostiles[i]
			remove_hostile(h)
			Game.log_msg(msg, 0)
			Game.totals.hostiles_killed += 1
			return
	Game.log_msg("No " + kind + " available to target.", 1)

func kill_hostiles_of_kind(kind: String, msg: String) -> void:
	var count := 0
	for i in hostiles.size() - 1:
		if hostiles[i].kind == kind:
			remove_hostile(hostiles[i])
			count += 1
	if count > 0:
		Game.log_msg(msg + " (" + str(count) + " dealt with).", 0)
	else:
		Game.log_msg(msg + " — none found.", 1)

# ----------------------------------------------------------------- month tick

func month_tick() -> void:
	# hostiles: auto-defence first
	for i in hostiles.size() - 1:
		var h: Hostile = hostiles[i]
		if h.kind == "wildlife":
			for b in buildings.values():
				if not b.is_ruin and b.building_id == "autodefence" and b.global_position.distance_to(h.global_position) <= 96.0:
					remove_hostile(h)
					Game.totals.hostiles_killed += 1
					Game.log_msg("Automated defences destroyed a " + Data.HOSTILES["wildlife"].name + ".", 1)
					break
	# hostiles move & raid
	for h in hostiles.duplicate():
		if not is_instance_valid(h):
			continue
		var target: Node = null
		var best := 1e9
		for b in buildings.values():
			var d2: float = b.global_position.distance_to(h.global_position)
			if d2 < best:
				best = d2
				target = b
		if target == null:
			continue
		if best > TILE * 1.5:
			var dir: Vector2 = (target.global_position - h.global_position).normalized()
			h.global_position += dir * TILE * 3.0
			h.global_position = tile_center(snap_tile(h.global_position))
		else:
			target.take_damage(30, Data.HOSTILES[h.kind].name)
	# gates
	for b in buildings.values():
		if b.is_ruin or b.building_id != "gate" or b.garrisoned:
			continue
		if randf() < 0.35:
			var ang := randf() * TAU
			var gp := tile_center(snap_tile(b.global_position + Vector2(cos(ang), sin(ang)) * 64))
			spawn_hostile("mechanoid", gp)
			Game.log_msg("A Mechanoid emerges from the " + Data.BUILDINGS["gate"].name + ".", 2)
	# hostile spawn pressure
	var year := Game.month / 12 + 1
	var chance := 0.30 + year * 0.06
	if randf() < chance:
		var roll := randf()
		var kind := "humanoid" if roll < 0.45 else ("wildlife" if roll < 0.8 else "mechanoid")
		if year > 2:
			kind = "mechanoid" if roll > 0.55 else kind
		spawn_hostile(kind)
	# refresh achievements
	Game.check_achievements()

# -------------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var gpos := get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Game.construction_mode != "":
				var p := snap_tile(gpos)
				if try_place(Game.construction_mode, p):
					if Game.construction_mode in Data.BUILDINGS:
						pass  # keep build mode active for rapid building
			else:
				var b := building_at(gpos)
				select(b)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var b := building_at(gpos)
			var h: Node = null
			for x in hostiles:
				if x.global_position.distance_to(gpos) <= TILE * 0.9:
					h = x
					break
			var target := b if b != null else h
			if target:
				var sp := get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
				emit_signal("context_requested", target, sp)
			select(b)
	# construction ghost cancel
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		Game.construction_mode = ""
		Game.emit_signal("construction_mode_changed", "")
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and Game.construction_mode != "":
			Game.construction_mode = ""
			Game.emit_signal("construction_mode_changed", "")

func select(b: Node) -> void:
	Game.selected_building = b
	Game.emit_signal("state_changed")

# ----------------------------------------------------------------- hover/draw

func _process(_delta: float) -> void:
	# hover detection
	var gpos := get_global_mouse_position()
	var new_hover: Node = null
	for b in buildings.values():
		if b.global_position.distance_to(gpos) <= TILE * 0.8:
			new_hover = b
			break
	if new_hover == null:
		for h in hostiles:
			if h.global_position.distance_to(gpos) <= TILE * 0.9:
				new_hover = h
				break
	if new_hover != hovered:
		if hovered and hovered.has_method("set_hover"):
			hovered.set_hover(false)
		if hovered is Building:
			hovered.hovering = false
		if hovered is Hostile:
			hovered.hovering = false
		hovered = new_hover
		if hovered is Building:
			hovered.hovering = true
		if hovered is Hostile:
			hovered.hovering = true
	# tooltip
	if Game.ui:
		if hovered:
			Game.ui.tooltip_set(hovered.info_text())
		elif Game.construction_mode != "":
			Game.ui.tooltip_set("> " + Data.BUILDINGS[Game.construction_mode].name.to_upper() + "\n" + Data.BUILDINGS[Game.construction_mode].desc + "\n\nLMB: place  |  RMB/ESC: cancel")
		else:
			Game.ui.tooltip_set("")
	# ghost
	var p := snap_tile(gpos)
	if Game.construction_mode != "" and p != ghost_pos:
		ghost_pos = p
		ghost_valid = can_place(p)
		queue_redraw()
	elif Game.construction_mode != "":
		queue_redraw()

func _draw() -> void:
	# grid
	var line := Color(0, 0.55, 0.2, 0.25)
	var half := MAP_RADIUS
	var start_x := int((CENTER.x - half) / TILE)
	var end_x := int((CENTER.x + half) / TILE)
	var start_y := int((CENTER.y - half) / TILE)
	var end_y := int((CENTER.y + half) / TILE)
	for x in range(start_x, end_x + 1):
		if x % 4 == 0:
			draw_line(Vector2(x * TILE, (start_y) * TILE), Vector2(x * TILE, (end_y + 1) * TILE), line, 1.0)
	for y in range(start_y, end_y + 1):
		if y % 4 == 0:
			draw_line(Vector2(start_x * TILE, y * TILE), Vector2((end_x + 1) * TILE, y * TILE), line, 1.0)
	# construction ghost
	if Game.construction_mode != "":
		var c := Color(0, 1, 0.3, 0.4) if ghost_valid else Color(1, 0.2, 0.1, 0.5)
		draw_rect(Rect2(ghost_pos * TILE, Vector2i(TILE, TILE)), c, true)
		draw_rect(Rect2(ghost_pos * TILE, Vector2i(TILE, TILE)), Color(0, 1, 0.3, 0.9), false, 1.0)
	# map boundary
	var bpts := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		bpts.append(CENTER + Vector2(cos(a), sin(a)) * MAP_RADIUS)
	draw_polyline(bpts, Color(0.9, 0.25, 0.18, 0.5))

func clear_all() -> void:
	for b in buildings.values():
		b.queue_free()
	buildings.clear()
	for h in hostiles:
		h.queue_free()
	hostiles.clear()

# ----------------------------------------------------------------- save/load

func load_layout(b_list: Array, h_list: Array) -> void:
	clear_all()
	for bd in b_list:
		var p := Vector2i(bd["pos"][0], bd["pos"][1])
		var b := place_building(bd["id"], p, true)
		if b:
			b.assigned = bd.get("assigned", "")
			b.garrisoned = bd.get("garrisoned", false)
			b.stationed = bd.get("stationed", false)
			b.hp = bd.get("hp", 100)
			b.is_ruin = bd.get("is_ruin", false)
			b.training_progress = bd.get("training_progress", 0.0)
			if b.is_ruin:
				b.destroy()
	for hd in h_list:
		spawn_hostile(hd["kind"], Vector2(hd["pos"][0], hd["pos"][1]) * TILE + Vector2(16, 16))
