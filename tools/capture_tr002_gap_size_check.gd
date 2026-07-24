extends SceneTree

## TR-002 gap-size sanity check (2026-07-22): User screenshots show visible
## floor-looking gaps between the player and (1) door_power's recessed
## opening, (2) the terminal approaching from the west. This checks whether
## those gaps are simply the NORMAL, correct consequence of the player's
## own hitbox width/height creating clearance around any blocker (AABB
## collision keeps the box's EDGE off the blocker, so a ~59x76 hitbox
## naturally leaves ~30-38px of visible "empty" floor even when technically
## touching), or whether the stop distance is unexpectedly larger than that.
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
	print("player.size (design-space equivalent, since size doesn't scale with room)=", player.size)
	print("== theory: AABB collision keeps the hitbox's OWN edge off the blocker, so the")
	print("   visible gap between the player's feet-anchor and a blocker is roughly half")
	print("   the hitbox's width (approaching horizontally) or full height (approaching")
	print("   vertically, since the anchor is at the BOTTOM of the hitbox) ==")

	var door_gap_entries: Array = module_data.get("door_gap_blockers", [])
	var power_gap: Rect2
	for entry: Dictionary in door_gap_entries:
		if entry["door_to"] == "power_distribution_room":
			power_gap = entry["rect"]
	print("door_power gap rect (design)=", power_gap)

	var spawn_room: Vector2 = scene.call("_room_point", Vector2(359, 356))

	# Case 1: walk straight up toward door_power's real target center (not
	# just the gap rect) -- matches the User's first screenshot (walking
	# north up the corridor toward the locked door).
	var target_nodes: Dictionary = scene.get("target_nodes")
	var door_power_node: Control = target_nodes["door_power"]
	var door_power_real_center: Vector2 = door_power_node.position + door_power_node.size * 0.5
	player.position = spawn_room
	scene.call("_sync_player_visual")
	await process_frame
	await _walk_toward(scene, player, door_power_real_center)
	var stop1_design: Vector2 = scene.call("_design_point_from_room", player.position)
	var stop1_bottom_design: Vector2 = scene.call("_design_point_from_room", player.position + Vector2(0, player.size.y))
	print("case1 (walk to door_power's real center): stopped design top=", stop1_design, " design bottom(feet-ish)=", stop1_bottom_design)
	print("  gap between feet-ish bottom and the wall/gap's own edge (y=96 design)=", stop1_bottom_design.y - 96.0, " (expected ~0 if AABB is snug, since the hitbox bottom is what touches the wall)")

	# Case 2: approach the terminal from the WEST (matches User's second
	# screenshot).
	var terminal_blocker: Rect2 = module_data.get("blockers", [])[0]
	var west_start_design: Vector2 = Vector2(terminal_blocker.position.x - 150.0, terminal_blocker.position.y + terminal_blocker.size.y * 0.5)
	var west_start_room: Vector2 = scene.call("_room_point", west_start_design)
	var terminal_center_room: Vector2 = scene.call("_room_point", terminal_blocker.position + terminal_blocker.size * 0.5)
	player.position = west_start_room
	scene.call("_sync_player_visual")
	await process_frame
	await _walk_toward(scene, player, terminal_center_room)
	var stop2_design: Vector2 = scene.call("_design_point_from_room", player.position)
	var stop2_right_design: Vector2 = scene.call("_design_point_from_room", player.position + Vector2(player.size.x, 0))
	print("case2 (walk toward terminal from the west): stopped design top-left=", stop2_design, " design right-edge=", stop2_right_design)
	print("  gap between hitbox's right edge and terminal blocker's left edge (x=", terminal_blocker.position.x, ")=", terminal_blocker.position.x - stop2_right_design.x, " (expected ~0 if AABB is snug)")

	_done = true
	quit()

func _walk_toward(scene: Node, player: Control, target: Vector2, max_steps: int = 500) -> void:
	for i in range(max_steps):
		var player_center: Vector2 = player.position + player.size * 0.5
		var to_target: Vector2 = target - player_center
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
