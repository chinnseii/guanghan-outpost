extends SceneTree

## TR-002 follow-up (2026-07-24), second attempt: the smart "recompute
## direction toward target" walk reached the door_power wall/gap cleanly
## (see capture_tr002_door_power_approach_check.gd's result: final y=96.1,
## correctly blocked by the LOCKED door, not a bug). That test auto-slides
## around obstacles. A real player holding a single direction key does NOT
## auto-detour -- if standing directly under the terminal's x-column and
## just holding "up", they'd stop dead at the terminal's south edge (y=270)
## and need to manually sidestep, which could read as "stuck, and the real
## wall is still very far away" (270 -> 96 is 174px of untouched floor).
## This test reproduces exactly that: start directly below the terminal,
## hold pure "up" only, no correction.
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"
const OUT_DIR := "res://docs/screenshots/training_hub_art"

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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
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

	# Start directly under the terminal's x-column, well south of it.
	var start_design := Vector2(380.0, 356.0)
	player.position = scene.call("_room_point", start_design)
	scene.call("_sync_player_visual")
	await process_frame

	for step in range(300):
		Input.action_press("ui_up", 1.0)
		await process_frame
		Input.action_release("ui_up")

	var final_design: Vector2 = scene.call("_design_point_from_room", player.position)
	var final_design_end: Vector2 = scene.call("_design_point_from_room", player.position + player.size)
	var final_rect := Rect2(final_design, final_design_end - final_design)
	print("FINAL player rect (design)=", final_rect, " top.y=", final_rect.position.y, " (wall inner edge is y=96)")
	for b: Rect2 in blockers:
		if final_rect.grow(6.0).intersects(b):
			print("  near/touching static blocker: ", b)

	await _capture("12_door_power_straight_up_blocked_by_terminal.png")

	# Now sidestep clear of the terminal's x-range (326-433) and continue up
	# to the wall, using the same reliable "recompute direction toward a
	# target" pattern as the known-working directional-check scripts
	# (a fixed-frame-count blind key-hold under-shot here).
	await _walk_to(player, scene, Vector2(200.0, 270.0))
	await _walk_to(player, scene, Vector2(200.0, 100.0))
	await _capture("12_door_power_after_sidestep_reaches_wall.png")

	_done = true
	quit()

func _walk_to(player: Control, scene: Node, target_design: Vector2) -> void:
	for step in range(300):
		var player_center: Vector2 = player.position + player.size * 0.5
		var target_room: Vector2 = scene.call("_room_point", target_design)
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

func _capture(file_name: String) -> void:
	await process_frame
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		push_error("Viewport texture unavailable. Run WITHOUT --headless.")
		return
	var image := texture.get_image()
	var err := image.save_png("%s/%s" % [OUT_DIR, file_name])
	print("capture ", file_name, " err=", err)
