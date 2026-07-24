extends SceneTree

## TR-002 follow-up (2026-07-24): User reports getting stuck walking toward
## the top "配电房" (door_power) door, "还有很远的距离" (still a good
## distance from the wall) -- i.e. NOT stopping right at the wall's inner
## edge (y=96 design), which would be expected/correct while that door is
## locked. Walks straight from the default player_start toward door_power's
## target center and prints exactly which blocker (if any) stops them and
## how far that is from the real wall edge, to tell apart "correctly
## blocked by the terminal, which now sits directly in the path" from a
## genuine open-floor collision bug.
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"

var _done := false

func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(45.0).timeout
	if not _done:
		push_error("Verification script exceeded 45s guard; force quitting.")
		quit(1)

func _run() -> void:
	root.size = Vector2i(1600, 900)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout

	var player: Control = scene.get("player")
	var module_data: Dictionary = scene.get("module_data")
	var blockers: Array = module_data.get("blockers", [])
	var door_gap_blockers: Array = module_data.get("door_gap_blockers", [])
	var areas: Dictionary = scene.get("areas")
	print("player_start (design)=", module_data.get("player_start", Vector2(350, 320)))
	print("power_distribution_room unlocked=", areas.get("power_distribution_room", {}).get("unlocked", false))
	for b: Rect2 in blockers:
		print("static blocker: ", b)
	for entry: Dictionary in door_gap_blockers:
		print("door_gap_blocker door_to=", entry.get("door_to"), " rect=", entry.get("rect"))

	# Walk from the default spawn straight toward door_power's target center
	# (326,18)-(108,96) -> center (380,66)), same "recompute direction every
	# frame" pattern as the known-working terminal_directional_check script.
	var door_power_target_center_design := Vector2(380.0, 66.0)
	for step in range(400):
		var player_center: Vector2 = player.position + player.size * 0.5
		var target_room: Vector2 = scene.call("_room_point", door_power_target_center_design)
		var to_target: Vector2 = target_room - player_center
		if to_target.length() < 4.0:
			break
		var dir: Vector2 = to_target.normalized()
		Input.action_press("ui_left", max(0.0, -dir.x))
		Input.action_press("ui_right", max(0.0, dir.x))
		Input.action_press("ui_up", max(0.0, -dir.y))
		Input.action_press("ui_down", max(0.0, dir.y))
		await process_frame
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		Input.action_release("ui_up")
		Input.action_release("ui_down")

	var final_design: Vector2 = scene.call("_design_point_from_room", player.position)
	var final_design_end: Vector2 = scene.call("_design_point_from_room", player.position + player.size)
	var final_rect := Rect2(final_design, final_design_end - final_design)
	print("FINAL player rect (design)=", final_rect, " top.y=", final_rect.position.y, " (wall inner edge is y=96)")
	for b: Rect2 in blockers:
		if final_rect.grow(6.0).intersects(b):
			print("  near/touching static blocker: ", b)
	for entry: Dictionary in door_gap_blockers:
		var r: Rect2 = entry.get("rect")
		if final_rect.grow(6.0).intersects(r):
			print("  near/touching door_gap_blocker door_to=", entry.get("door_to"), " rect=", r)

	_done = true
	quit()
