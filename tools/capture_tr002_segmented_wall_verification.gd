extends SceneTree

## TR-002 scene collision round 2 verification (2026-07-22): confirms the
## segmented wall blockers keep the player out of every wall/void area
## (not just a single rectangular clamp), the terminal blocker still can't
## be entered from any direction, and each door's gap is solid while locked
## but actually walkable once unlocked (Trigger vs Blocker split). Run only
## against an isolated sandbox project copy (separate project.godot
## config/name) so user:// never touches the real project's save directory.
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
	root.size = Vector2i(1920, 1080)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout

	var player: Control = scene.get("player")
	var spawn_pos: Vector2 = player.position
	var module_data: Dictionary = scene.get("module_data")
	var wall_blockers: Array = module_data.get("blockers", [])
	var gap_entries: Array = module_data.get("door_gap_blockers", [])

	print("== 1. Perimeter walk: push into each wall from inside ==")
	# Aim points well past each wall (outside the room entirely) from a
	# safe interior point near that wall, away from any door gap, and
	# confirm the player never enters a wall-segment rect.
	var wall_probe_targets := {
		"top (away from door_power)": Vector2(150.0, -50.0),
		"bottom (away from door_greenhouse)": Vector2(600.0, 570.0),
		"left (away from door_suit)": Vector2(-50.0, 150.0),
		"right (away from door_air)": Vector2(810.0, 400.0),
	}
	var all_perimeter_ok := true
	for label in wall_probe_targets.keys():
		var ok := await _walk_and_check_no_overlap(scene, player, spawn_pos, wall_probe_targets[label], wall_blockers)
		print(label, " -> never entered a wall segment: ", ok)
		all_perimeter_ok = all_perimeter_ok and ok
	print("perimeter overall pass=", all_perimeter_ok)

	print("== 2. Terminal loop: approach from 8 directions ==")
	var terminal_blocker: Rect2 = wall_blockers[0]
	var terminal_center: Vector2 = terminal_blocker.position + terminal_blocker.size * 0.5
	var all_terminal_ok := true
	for i in range(8):
		var angle: float = TAU / 8.0 * i
		var approach_from: Vector2 = terminal_center + Vector2(cos(angle), sin(angle)) * 220.0
		player.position = approach_from
		scene.call("_sync_player_visual")
		await process_frame
		var ok := await _walk_and_check_no_overlap(scene, player, approach_from, terminal_center, [terminal_blocker])
		print("angle ", rad_to_deg(angle), " -> never entered terminal blocker: ", ok)
		all_terminal_ok = all_terminal_ok and ok
	print("terminal loop overall pass=", all_terminal_ok)

	print("== 3a. Door LOCKED: genuine walk must stop at the gap (real _process(), safe -- a locked door never switches rooms) ==")
	for entry: Dictionary in gap_entries:
		var door_to: String = entry["door_to"]
		var gap_rect: Rect2 = entry["rect"]
		var gap_center: Vector2 = gap_rect.position + gap_rect.size * 0.5
		var areas: Dictionary = scene.get("areas")
		var was_unlocked: bool = bool(areas.get(door_to, {}).get("unlocked", false))

		areas[door_to]["unlocked"] = false
		player.position = spawn_pos
		scene.call("_sync_player_visual")
		await process_frame
		var locked_final := await _walk_toward(scene, player, gap_center)
		var locked_entered_gap: bool = Rect2(locked_final, player.size).intersects(gap_rect)
		print(door_to, " LOCKED: final=", locked_final, " entered_gap(should be false)=", locked_entered_gap)
		areas[door_to]["unlocked"] = was_unlocked

	print("== 3b. Door UNLOCKED: direct _resolve_blockers() unit check (deliberately NOT a genuine per-frame walk -- once unlocked, actually reaching the gap correctly triggers the existing, unmodified _check_door_crossing()/room-switch logic, which frees this scene's nodes; that switch path is pre-existing and out of scope here, this only isolates the NEW blocker-gating logic itself) ==")
	for entry: Dictionary in gap_entries:
		var door_to: String = entry["door_to"]
		var gap_rect: Rect2 = entry["rect"]
		var gap_center: Vector2 = gap_rect.position + gap_rect.size * 0.5
		var areas: Dictionary = scene.get("areas")
		var was_unlocked: bool = bool(areas.get(door_to, {}).get("unlocked", false))
		var candidate: Vector2 = gap_center - player.size * 0.5

		areas[door_to]["unlocked"] = false
		var resolved_locked: Vector2 = scene.call("_resolve_blockers", spawn_pos, candidate)
		var locked_kept_out: bool = not Rect2(resolved_locked, player.size).intersects(gap_rect)
		print(door_to, " LOCKED resolver kept player out of gap (should be true)=", locked_kept_out)

		areas[door_to]["unlocked"] = true
		var resolved_unlocked: Vector2 = scene.call("_resolve_blockers", spawn_pos, candidate)
		var unlocked_allowed_in: bool = Rect2(resolved_unlocked, player.size).intersects(gap_rect)
		print(door_to, " UNLOCKED resolver allowed player into gap (should be true)=", unlocked_allowed_in)

		areas[door_to]["unlocked"] = was_unlocked

	player.position = spawn_pos
	scene.call("_sync_player_visual")
	await process_frame
	await _capture("07_hub_segmented_wall_full_view.png")

	_done = true
	quit()

## Drives toward `target` for up to `max_steps` frames, checking every frame
## that the player's rect never intersects any rect in `blockers`. Returns
## true if it never did.
func _walk_and_check_no_overlap(scene: Node, player: Control, start_pos: Vector2, target: Vector2, blockers: Array, max_steps: int = 400) -> bool:
	player.position = start_pos
	scene.call("_sync_player_visual")
	await process_frame
	var never_overlapped := true
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
		var player_rect := Rect2(player.position, player.size)
		for blocker: Rect2 in blockers:
			if player_rect.intersects(blocker):
				never_overlapped = false
	return never_overlapped

func _walk_toward(scene: Node, player: Control, target: Vector2, max_steps: int = 400) -> Vector2:
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
	return player.position

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
