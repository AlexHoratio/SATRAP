extends Control
# SATRAP main UI — green terminal aesthetic, built programmatically.
# Owns: top bar, right tab panel, log feed, building info box,
# context menu, event popup, ending screen. Tooltip is an existing scene node.

const W := 1440.0
const H := 1080.0
const PANEL_X := W - 448.0
const FONT_PATH := "res://Graphics/Fonts/MorePerfectDOSVGA.ttf"
const GREEN := Color(0, 0.95, 0.35)
const DIM := Color(0, 0.55, 0.25)
const RED := Color(0.95, 0.3, 0.2)
const BG := Color(0.01, 0.04, 0.02)
const PANEL_BG := Color(0.0, 0.06, 0.02, 0.94)

var font: Font
var topbar_hb: HBoxContainer
var tab_buttons := {}            # tab_id -> existing scene Button
var panel: PanelContainer
var panel_title: Label
var panel_body: VBoxContainer    # rebuilt per tab
var log_box: RichTextLabel
var info_box: PanelContainer
var info_body: RichTextLabel
var ctx_layer: CanvasLayer
var event_layer: CanvasLayer
var end_layer: CanvasLayer
var info_title: Label
var event_title: Label
var event_text: RichTextLabel
var event_opts: VBoxContainer
var end_title: Label
var end_text: RichTextLabel
var current_tab := "build"
var current_event := {}

# ------------------------------------------------------------------ setup

func _ready() -> void:
	font = load(FONT_PATH)
	Game.ui = self

	# existing scene nodes
	var cl: CanvasLayer = $CanvasLayer
	var tooltip: Label = cl.get_node("tooltip")
	tab_buttons = {
		"build": cl.get_node("utilities/construction"),
		"policy": cl.get_node("utilities/policies"),
		"research": cl.get_node("utilities/research"),
		"population": cl.get_node("info/population"),
		"resources": cl.get_node("info/resources"),
		"military": cl.get_node("info/military"),
		"advisors": cl.get_node("local_approval"),
	}
	for id in tab_buttons:
		tab_buttons[id].pressed.connect(_on_tab_pressed.bind(id))
		tab_buttons[id].add_theme_color_override("font_color", GREEN)
		tab_buttons[id].add_theme_font_override("font", font)

	# world signals
	var w = get_tree().get_first_node_in_group("world")
	w.context_requested.connect(_on_context_requested)

	# game signals
	Game.state_changed.connect(_on_state_changed)
	Game.log_added.connect(_on_log_added)
	Game.event_requested.connect(_on_event_requested)
	Game.game_ended.connect(_on_game_ended)
	Game.construction_mode_changed.connect(_on_construction_mode)

	_build_top_bar()
	_build_panel()
	_build_info_box()
	_build_ctx_layer()
	_build_event_layer()
	_build_end_layer()
	_seed_log()
	refresh()

	# opening event (new game) or saved state (continue)
	if get_tree().has_meta("satrap_continue"):
		get_tree().remove_meta("satrap_continue")
		Game.load_game()
		refresh()
	elif not Game._ended and Game.pending_events.size() > 0:
		Game.present_pending_event()

# ------------------------------------------------------------------ widgets

func _mk_label(text: String, size := 18, color := GREEN) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _mk_button(text: String, cb: Callable = Callable(), size := 16, color := GREEN) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 0.8))
	b.add_theme_color_override("font_focus_color", GREEN)
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 0.8))
	b.add_theme_color_override("font_disabled_color", DIM)
	b.pressed.connect(cb)
	return b

func _mk_panel(bg := PANEL_BG) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _mk_stylebox(bg))
	return p

func _mk_stylebox(bg: Color, border := GREEN) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_content_margin_all(8)
	return s

func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _mk_stylebox(PANEL_BG, DIM))
	bar.position = Vector2(0, 0)
	bar.size = Vector2(W, 40)
	add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	bar.add_child(hb)
	topbar_hb = hb

	hb.add_child(_mk_label("Y1 · JANUARY", 18))
	hb.add_child(_mk_button("|| PAUSE", func(): Game.paused = true, 14))
	hb.add_child(_mk_button("1x", func(): Game.paused = false; Game.speed = 1, 14))
	hb.add_child(_mk_button("2x", func(): Game.paused = false; Game.speed = 2, 14))
	hb.add_child(_mk_button("4x", func(): Game.paused = false; Game.speed = 4, 14))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(spacer)
	var res_label := _mk_label("", 18)
	res_label.name = "TopRes"
	hb.add_child(res_label)

func _build_panel() -> void:
	panel = _mk_panel()
	panel.position = Vector2(PANEL_X, 48)
	panel.size = Vector2(W - PANEL_X - 8, H - 48 - 74)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	panel_title = _mk_label("CONSTRUCTION", 20)
	vb.add_child(panel_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	panel_body = VBoxContainer.new()
	panel_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_body.add_theme_constant_override("separation", 6)
	scroll.add_child(panel_body)

	log_box = RichTextLabel.new()
	log_box.bbcode_enabled = true
	log_box.scroll_following = true
	log_box.selection_enabled = false
	log_box.size_flags_vertical = 0
	log_box.custom_minimum_size = Vector2(0, 130)
	log_box.add_theme_font_override("normal_font", font)
	log_box.add_theme_font_size_override("normal_font_size", 14)
	log_box.add_theme_color_override("default_color", GREEN)
	vb.add_child(log_box)

func _build_info_box() -> void:
	info_box = _mk_panel(Color(0.0, 0.08, 0.03, 0.96))
	info_box.position = Vector2(16, 48)
	info_box.size = Vector2(440, 260)
	info_box.visible = false
	add_child(info_box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	info_box.add_child(vb)
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	info_title = _mk_label("STRUCTURE", 18)
	info_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(info_title)
	hb.add_child(_mk_button("x", _deselect, 16))
	info_body = RichTextLabel.new()
	info_body.bbcode_enabled = true
	info_body.scroll_active = false
	info_body.add_theme_font_override("normal_font", font)
	info_body.add_theme_font_size_override("normal_font_size", 14)
	info_body.add_theme_color_override("default_color", GREEN)
	vb.add_child(info_body)

func _build_ctx_layer() -> void:
	ctx_layer = CanvasLayer.new()
	ctx_layer.layer = 5
	ctx_layer.visible = false
	add_child(ctx_layer)

func _build_event_layer() -> void:
	event_layer = CanvasLayer.new()
	event_layer.layer = 10
	event_layer.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	event_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	event_layer.add_child(center)
	var box := _mk_panel(Color(0.0, 0.07, 0.02, 0.98))
	box.custom_minimum_size = Vector2(680, 0)
	box.name = "EventBox"
	center.add_child(box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	box.add_child(vb)
	event_title = _mk_label("EVENT", 22)
	vb.add_child(event_title)
	event_text = RichTextLabel.new()
	event_text.bbcode_enabled = true
	event_text.add_theme_font_override("normal_font", font)
	event_text.add_theme_font_size_override("normal_font_size", 16)
	event_text.add_theme_color_override("default_color", GREEN)
	vb.add_child(event_text)
	event_opts = VBoxContainer.new()
	event_opts.add_theme_constant_override("separation", 4)
	vb.add_child(event_opts)

func _build_end_layer() -> void:
	end_layer = CanvasLayer.new()
	end_layer.layer = 20
	end_layer.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_layer.add_child(center)
	var box := _mk_panel(Color(0.0, 0.06, 0.02, 0.98))
	box.custom_minimum_size = Vector2(760, 0)
	box.name = "EndBox"
	center.add_child(box)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(720, 0)
	box.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	scroll.add_child(vb)
	end_title = _mk_label("END OF CAMPAIGN", 24)
	vb.add_child(end_title)
	end_text = RichTextLabel.new()
	end_text.bbcode_enabled = true
	end_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end_text.add_theme_font_override("normal_font", font)
	end_text.add_theme_font_size_override("normal_font_size", 16)
	end_text.add_theme_color_override("default_color", GREEN)
	vb.add_child(end_text)
	vb.add_child(_mk_button("> RETURN TO MENU <",
		func(): get_tree().change_scene_to_file("res://Scenes/main_menu.tscn"), 18))

# ------------------------------------------------------------------ refresh

func _on_state_changed() -> void:
	refresh()

func refresh() -> void:
	if not is_inside_tree():
		return
	# clock + pause state
	var year := Game.month / 12 + 1
	var mname: String = Data.MONTH_NAMES[Game.month % 12]
	var first_label: Label = topbar_hb.get_children()[0]
	first_label.text = ("PAUSED  |  " if Game.paused else "") + "Y" + str(year) + " · " + mname.to_upper()
	var rl: Label = topbar_hb.get_children().back()
	rl.text = ("BULL %d   FOOD %d   GOODS %d   LUX %d   B.MIL %d   S.MIL %d" % [
		int(Game.res.money), int(Game.res.food), int(Game.res.basic_goods),
		int(Game.res.luxury_goods), int(Game.res.basic_mil), int(Game.res.special_mil)])
	# tab highlight
	for id in tab_buttons:
		tab_buttons[id].modulate = Color(1, 1, 0.85) if id == current_tab else Color(0.45, 0.9, 0.5)
	# info box (building or hostile)
	var b: Node = Game.selected_building
	if b and is_instance_valid(b) and b.has_method("info_text"):
		info_box.visible = true
		var name_txt := "STRUCTURE"
		if "building_id" in b:
			name_txt = Data.BUILDINGS[b.building_id].name
		elif "kind" in b:
			name_txt = Data.HOSTILES[b.kind].name
		info_title.text = name_txt.to_upper()
		info_body.text = b.info_text()
	else:
		info_box.visible = false
	# tab body
	_rebuild_tab()

# ------------------------------------------------------------------ tabs

func _on_tab_pressed(id: String) -> void:
	current_tab = id
	refresh()

func _rebuild_tab() -> void:
	for c in panel_body.get_children():
		c.queue_free()
	match current_tab:
		"build": _tab_build()
		"policy": _tab_policy()
		"research": _tab_research()
		"population": _tab_population()
		"resources": _tab_resources()
		"military": _tab_military()
		"advisors": _tab_advisors()

func _tab_build() -> void:
	panel_title.text = "CONSTRUCTION"
	var active := Game.construction_mode
	for bid in Data.BUILDINGS:
		var d: Dictionary = Data.BUILDINGS[bid]
		if d.cost == 0:
			continue  # admin / village / gate / ruin are not buildable
		var needs: String = d.get("unlock", "")
		var unlocked: bool = needs == "" or needs in Game.research_done
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		panel_body.add_child(row)
		var name_l := _mk_label(("%-22s" % d.name).strip_edges(), 14,
			GREEN if unlocked else DIM)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_l)
		var cost := _mk_label(str(int(d.cost)) + "B", 14, DIM)
		row.add_child(cost)
		if unlocked:
			var btn_label := "CANCEL" if active == bid else "BUILD"
			row.add_child(_mk_button(btn_label, _toggle_construction.bind(bid), 14,
				Color(1, 1, 0.8) if active == bid else GREEN))
		else:
			row.add_child(_mk_label("[RESEARCH: " + Data.RESEARCH[needs].name.to_upper() + "]", 12, DIM))

func _toggle_construction(bid: String) -> void:
	Game.construction_mode = "" if Game.construction_mode == bid else bid
	Game.emit_signal("construction_mode_changed", Game.construction_mode)
	refresh()

func _tab_policy() -> void:
	panel_title.text = "POLICIES"
	for pid in Data.POLICIES:
		var p: Dictionary = Data.POLICIES[pid]
		var avail := Game.policy_available(pid)
		var active: bool = pid in Game.policies_active
		var name_l := _mk_label(p.name.to_upper(), 14, GREEN if avail else DIM)
		panel_body.add_child(name_l)
		var desc := _mk_label(p.desc, 12, DIM)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel_body.add_child(desc)
		if avail:
			var btn_label := "REPEAL" if active else ("INSTITUTE (-" + str(int(p.cost)) + "B)")
			panel_body.add_child(_mk_button(btn_label, func(): Game.toggle_policy(pid), 14,
				Color(1, 1, 0.8) if active else GREEN))
		else:
			var req := ""
			if p.get("requires_policy", "") != "":
				req = "requires " + Data.POLICIES[p["requires_policy"]].name
			elif p.get("requires_research", "") != "":
				req = "requires " + Data.RESEARCH[p["requires_research"]].name
			panel_body.add_child(_mk_label("LOCKED — " + req.to_upper(), 12, DIM))

func _tab_research() -> void:
	panel_title.text = "RESEARCH"
	if Game.research_active != null:
		var p: Dictionary = Data.RESEARCH[Game.research_active]
		var frac := Game.research_progress / maxf(p.cost, 0.1)
		panel_body.add_child(_mk_label("ACTIVE: " + p.name.to_upper(), 15, Color(1, 1, 0.8)))
		panel_body.add_child(_mk_label(("%d%%  (%.1f / %d months)" % [int(frac * 100), Game.research_progress, p.cost]), 13, DIM))
		panel_body.add_child(HSeparator.new())
	for rid in Data.RESEARCH:
		var r: Dictionary = Data.RESEARCH[rid]
		if rid in Game.research_done:
			panel_body.add_child(_mk_label("[x] " + r.name, 14, DIM))
		elif r.get("hidden", false) and rid not in Game.research_unlocked_hidden:
			continue
		elif not Game.research_available(rid):
			var req: String = r.get("requires", "")
			if req != "":
				panel_body.add_child(_mk_label("[ ] " + r.name + "  (needs " + Data.RESEARCH[req].name + ")", 13, DIM))
		else:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			panel_body.add_child(row)
			var name_l := _mk_label(r.name, 14, GREEN)
			name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name_l)
			row.add_child(_mk_button(str(r.cost) + "mo", _start_research.bind(rid), 14))
	panel_body.add_child(HSeparator.new())
	var done_n := Game.research_done.size()
	panel_body.add_child(_mk_label(str(done_n) + " PROGRAMS COMPLETE", 13, DIM))

func _start_research(rid: String) -> void:
	Game.start_research(rid)

func _tab_population() -> void:
	panel_title.text = "POPULATION"
	var total := Game.total_pop()
	panel_body.add_child(_mk_label("TOTAL: " + str(total) + "   HOUSING: " + str(Game.housing_capacity()), 15, GREEN))
	for f in Data.FACTIONS:
		var n := int(Game.pop[f])
		var pct := int(100.0 * n / maxf(total, 1))
		var bar: String = "#".repeat(int(pct / 4))
		panel_body.add_child(_mk_label(("%-13s %6d  %3d%% %s" % [Data.FACTION_NAMES[f], n, pct, bar]), 13, GREEN))
	panel_body.add_child(HSeparator.new())
	panel_body.add_child(_mk_label("APPROVAL (LOCAL)", 15, GREEN))
	for f in Data.FACTIONS:
		var a := int(Game.approval[f])
		var col := GREEN if a >= 50 else (Color(1, 0.75, 0.3) if a >= 30 else RED)
		var bar: String = "#".repeat(int(maxf(a, 0) / 5))
		panel_body.add_child(_mk_label(("%-13s %3d  %s" % [Data.FACTION_NAMES[f], a, bar]), 13, col))
	panel_body.add_child(HSeparator.new())
	var orv := int(Game.organized_resistance)
	var or_col := RED if orv >= 60 else (Color(1, 0.75, 0.3) if orv >= 30 else GREEN)
	panel_body.add_child(_mk_label("ORGANIZED RESISTANCE: " + str(orv), 15, or_col))
	var or_bar: String = "#".repeat(int(orv / 4))
	panel_body.add_child(_mk_label(or_bar, 13, or_col))

func _tab_resources() -> void:
	panel_title.text = "RESOURCES"
	for r in Data.RESOURCE_NAMES:
		var bar: String = "#".repeat(int(clampf(Game.res[r] / 10.0, 0.0, 40.0)))
		panel_body.add_child(_mk_label(("%-16s %6d  %s" % [Data.RESOURCE_NAMES[r], int(Game.res[r]), bar]), 13, GREEN))
	panel_body.add_child(HSeparator.new())
	panel_body.add_child(_mk_label("QUOTAS PAID TO CARDIAQUE", 15, GREEN))
	panel_body.add_child(_mk_label("  Bull remitted:    " + str(Game.totals.quota_money), 13, DIM))
	panel_body.add_child(_mk_label("  Mil. equip. paid: " + str(Game.totals.quota_mil), 13, DIM))
	panel_body.add_child(HSeparator.new())
	panel_body.add_child(_mk_label("SUSPICION: " + str(int(Game.suspicion)), 13, DIM))
	panel_body.add_child(_mk_label("HIDDEN ASSETS: " + str(Game.hidden_assets), 13, DIM))

func _tab_military() -> void:
	panel_title.text = "MILITARY"
	panel_body.add_child(_mk_label("MILITIA     %d" % int(Game.soldiers.militia), 15, GREEN))
	panel_body.add_child(_mk_label("SPECIALIST  %d" % int(Game.soldiers.specialist), 15, GREEN))
	panel_body.add_child(_mk_label("GENDARME    %d" % int(Game.soldiers.gendarme), 15, GREEN))
	panel_body.add_child(_mk_label("GARRISON (GATES): " + str(Game.garrison_reserve), 13, DIM))
	panel_body.add_child(HSeparator.new())
	for unit in ["militia", "specialist", "gendarme"]:
		var c: Dictionary = Game.training_cost(unit)
		var ctext: String = "TRAIN 1 " + str(unit).to_upper() + "  (-" + str(int(c.basic_mil)) + " B.MIL, -" + str(int(c.special_mil)) + " S.MIL)"
		panel_body.add_child(_mk_button(ctext, _train_unit.bind(unit), 13))
	panel_body.add_child(HSeparator.new())
	panel_body.add_child(_mk_label("HOSTILES KILLED: " + str(Game.totals.hostiles_killed), 13, DIM))

func _train_unit(unit: String) -> void:
	if Game.res.basic_mil < Game.training_cost(unit).basic_mil or Game.res.special_mil < Game.training_cost(unit).special_mil:
		Game.log_msg("Insufficient equipment to train " + unit.to_upper() + ".", 1)
		return
	Game.res.basic_mil -= Game.training_cost(unit).basic_mil
	Game.res.special_mil -= Game.training_cost(unit).special_mil
	Game.soldiers[unit] += 1
	Game.log_msg("Trained 1 " + unit.to_upper() + ".", 0)
	Game.emit_signal("state_changed")
	Game.autosave()
	refresh()

func _tab_advisors() -> void:
	panel_title.text = "ADVISORS"
	for aid in Game.advisor_available_list():
		var a: Dictionary = Data.ADVISORS[aid]
		panel_body.add_child(_mk_label(a.name.to_upper(), 16, Color(1, 1, 0.8)))
		panel_body.add_child(_mk_label(a.title, 12, DIM))
		var line: String = a.lines[randi() % a.lines.size()]
		var l := _mk_label(line, 13, GREEN)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel_body.add_child(l)
		for act in a.actions:
			var cd: int = Game.advisor_cooldowns.get(aid + ":" + act.id, 0)
			var btn := _mk_button(act.label, _advisor_act.bind(aid, act.id), 12)
			if cd > 0:
				btn.disabled = true
				btn.text += "  [" + str(cd) + "mo]"
			panel_body.add_child(btn)
		panel_body.add_child(HSeparator.new())

func _advisor_act(aid: String, act_id: String) -> void:
	Game.perform_advisor_action(aid, act_id)
	refresh()

# ------------------------------------------------------------------ log

func _seed_log() -> void:
	for e in Game.log:
		_append_log(e.t, e.l)

func _on_log_added(text: String, level: int) -> void:
	_append_log(text, level)

var log_history := []

func _append_log(text: String, level: int) -> void:
	var col := GREEN if level == 0 else (Color(1, 0.8, 0.3) if level == 1 else RED)
	log_history.append("[color=%s]%s[/color]\n" % [col.to_html(), text.replace("[", "[lb]")])
	while log_history.size() > 80:
		log_history.pop_front()
	log_box.clear()
	for line in log_history:
		log_box.append_text(line)

# ------------------------------------------------------------------ tooltip

func tooltip_set(text: String) -> void:
	var t: Label = $CanvasLayer/tooltip
	t.text = text

# ------------------------------------------------------------------ info box

func _deselect() -> void:
	Game.selected_building = null
	Game.emit_signal("state_changed")

# ------------------------------------------------------------------ context menu

func _on_context_requested(target: Node, screen_pos: Vector2) -> void:
	for c in ctx_layer.get_children():
		c.queue_free()
	var catcher := Control.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: ctx_layer.visible = false)
	ctx_layer.add_child(catcher)

	var menu := _mk_panel(Color(0.0, 0.08, 0.03, 0.97))
	menu.name = "CtxMenu"
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	menu.add_child(vb)

	if target.has_method("context_options"):
		for opt in target.context_options():
			var b := _mk_button(opt.label, opt.action, 14)
			b.disabled = not opt.enabled
			vb.add_child(b)
	else:
		vb.add_child(_mk_label("(nothing to do here)", 14, DIM))

	# position: measure after adding, clamp to viewport
	var size := menu.get_combined_minimum_size()
	var p := screen_pos + Vector2(4, 4)
	p.x = clampf(p.x, 4.0, W - size.x - 4.0)
	p.y = clampf(p.y, 44.0, H - size.y - 8.0)
	menu.position = p
	ctx_layer.visible = true

# ------------------------------------------------------------------ events

func _on_event_requested(ev: Dictionary) -> void:
	current_event = ev
	event_title.text = ev.title.to_upper()
	event_text.text = ev.text
	for c in event_opts.get_children():
		c.queue_free()
	for i in ev.options.size():
		var opt: Dictionary = ev.options[i]
		var b := _mk_button(opt.text, _resolve_event.bind(i), 15)
		b.disabled = not Game.option_eligible(opt)
		event_opts.add_child(b)
	event_layer.visible = true

func _resolve_event(i: int) -> void:
	event_layer.visible = false
	Game.resolve_event(i)

# ------------------------------------------------------------------ ending

func _on_game_ended(over: Dictionary) -> void:
	if over.win:
		end_title.text = "THE FOUR YEARS ARE COMPLETE"
		var lines: Array = over.get("lines", [])
		var body := "SCORE: " + str(over.get("score", 0)) + "/100 — VERDICT: " + str(over.get("verdict", "")).to_upper() + "\n\n"
		for l in lines:
			body += l + "\n"
		end_text.text = body
	else:
		end_title.text = "CAMPAIGN FAILED"
		end_text.text = over.get("letter", "The campaign has ended.")
	end_layer.visible = true

# ------------------------------------------------------------------ misc

func _on_construction_mode(_mode: String) -> void:
	if current_tab == "build":
		refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and ctx_layer.visible:
			ctx_layer.visible = false
