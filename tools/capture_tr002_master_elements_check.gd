extends SceneTree

## TR-002_MASTER_ELEMENTS_TRIAL verification (2026-07-24): confirms the new
## split terminal art (TerminalBack/TerminalFrontOccluder, swapped in via
## TrainingHubBakedReferenceBlockout) is positioned correctly and that the
## static z-index sandwich (TerminalBack=1, player_visual=2 scoped to this
## blockout, TerminalFrontOccluder=3) produces real occlusion: player drawn
## in front of the console body when approaching from the south, and the
## front lip drawn in front of the player's feet at the collision boundary.
## Collision itself is untouched this round (README explicitly forbids
## deriving it from the PNG outline) -- this script only checks visuals.
const OUT_DIR := "res://docs/screenshots/training_hub_art"
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"

var _done := false

func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(60.0).timeout
	if not _done:
		push_error("Verification script exceeded 60s guard; force quitting.")
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
	var terminal_blocker: Rect2 = blockers[0]
	print("terminal_blocker (design space)=", terminal_blocker)

	# Full-room baseline shot (no special positioning).
	await _capture("10_master_elements_full_room.png")

	# South approach: walk straight up until blocked, so the player's feet
	# sit right at the blocker's south edge -- this is where
	# TerminalFrontOccluder should cover the feet without hiding the body.
	# NOTE (2026-07-24): offsets must clear the wall bands' door-gap
	# blockers (active while that door is locked, true by default this
	# early) -- a start rect overlapping one of those is already-invalid
	# and _resolve_blockers can never escape it (every candidate, including
	# holding still, gets rejected back to the same stuck position). +70
	# keeps the full player rect clear of both the bottom wall (y>=424) and
	# top wall (y<96) bands. Uses the same "recompute direction toward a
	# target every frame" loop as the known-working
	# capture_tr002_terminal_directional_check.gd, not a naive constant
	# single-direction hold.
	var south_start_design: Vector2 = Vector2(terminal_blocker.get_center().x, terminal_blocker.end.y + 70.0)
	var south_target_design: Vector2 = Vector2(terminal_blocker.get_center().x, terminal_blocker.position.y - 10.0)
	player.position = scene.call("_room_point", south_start_design)
	scene.call("_sync_player_visual")
	await process_frame
	await _walk_to(player, scene, south_target_design)
	await _capture("10_master_elements_south_approach.png")

	# North approach: walk down from above the terminal until blocked --
	# player should render in front of TerminalBack (the screen/body), not
	# get hidden behind it.
	var north_start_design: Vector2 = Vector2(terminal_blocker.get_center().x, terminal_blocker.position.y - 70.0)
	var north_target_design: Vector2 = Vector2(terminal_blocker.get_center().x, terminal_blocker.end.y + 10.0)
	player.position = scene.call("_room_point", north_start_design)
	scene.call("_sync_player_visual")
	await process_frame
	await _walk_to(player, scene, north_target_design)
	await _capture("10_master_elements_north_approach.png")

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
