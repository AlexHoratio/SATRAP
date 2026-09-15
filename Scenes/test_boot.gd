extends Node
## Headless smoke test: exercises the full menu->game flow, all UI tabs,
## the context menu, event resolution, and both ending screens.
func _ready() -> void:
	Game.start_game("local_revol")
	var satrap: Node = load("res://Scenes/satrap.tscn").instantiate()
	add_child(satrap)
	await get_tree().process_frame
	await get_tree().process_frame
	var w: Node = get_tree().get_first_node_in_group("world")

	# run several months to accumulate log/event activity
	for i in 3:
		Game.do_month()
		if Game.pending_events.size() > 0:
			Game.present_pending_event()
			await get_tree().process_frame
			Game.resolve_event(0)

	# exercise every tab
	for t in ["build", "policy", "research", "population", "resources", "military", "advisors"]:
		satrap._on_tab_pressed(t)
		await get_tree().process_frame

	# exercise the context menu on a building
	if w.buildings.size() > 0:
		var b: Node = w.buildings.values()[0]
		satrap._on_context_requested(b, Vector2(200, 200))
		await get_tree().process_frame
		satrap.ctx_layer.visible = false

	# exercise advisor action + construction toggle
	satrap._toggle_construction("farm")
	satrap._toggle_construction("farm")

	# exercise both ending screens
	satrap._on_game_ended({"win": false, "letter": "TEST LETTER"})
	await get_tree().process_frame
	satrap.end_layer.visible = false
	satrap._on_game_ended({"win": true, "score": 77, "verdict": "competent",
		"lines": ["line one", "line two"]})
	await get_tree().process_frame

	print("BOOT_TEST_OK month=", Game.month, " pending=", Game.pending_events.size())
	get_tree().quit(0)
