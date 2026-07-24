extends SceneTree

## TR-002 blocker coordinate-space bug fix verification (2026-07-22): the
## previous round's blockers/door_gap_blockers (authored in the fixed
## 760x520 design space) were compared directly against player.position,
## which lives in the REAL scaled training_area space -- confirmed broken
## by User's actual gameplay screenshot (stuck mid-floor, nowhere near a
## real wall). This script cross-checks against the REAL, already-correctly
## -scaled target_nodes Control positions (door/terminal), not just internal
## self-consistency, so it can't repeat the same blind spot the previous
## round's own verification script had (which only ever compared the buggy
## blockers against player.position using the SAME missing conversion, so
## it never caught the mismatch against the true rendered art).
## Run only against an isolated sandbox project copy (separate
## project.godot config/name) so user:// never touches the real project's
## save directory.
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
	# Deliberately NOT 1520x1080 (a size close to the design canvas's own
	# 2x) -- pick a size where room-space and design-space clearly diverge,
	# so this test can't accidentally "pass by coincidence" the way the
	# previous round's own verification silently did.
	root.size = Vector2i(1600, 900)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout

	var player: Control = scene.get("player")
	var target_nodes: Dictionary = scene.get("target_nodes")
	var training_area: Control = scene.get("training_area")
	# Recomputed fresh via the scene's own _room_point() every time a walk
	# resets position (NOT a one-time cached snapshot) -- an early cached
	# snapshot risks being taken before training_area's layout settles to
	# its true size, which would silently reintroduce a stale/unscaled
	# position on every subsequent reset.
	var spawn_pos: Vector2 = scene.call("_room_point", Vector2(359, 356))
	print("== room-space sanity ==")
	print("training_area.size=", training_area.size, " (design canvas is 760x520 -- these should clearly differ)")
	print("fresh _room_point(raw player_start)=", spawn_pos, " vs player.position=", player.position)
	print("real terminal target_node rect (room space, ALREADY correctly scaled)=", Rect2(target_nodes["terminal"].position, target_nodes["terminal"].size))
	print("real door_power target_node rect (room space)=", Rect2(target_nodes["door_power"].position, target_nodes["door_power"].size))

	print("== 1. Walk straight at the REAL terminal node's center -- must stop before entering it ==")
	var terminal_node: Control = target_nodes["terminal"]
	var terminal_real_center: Vector2 = terminal_node.position + terminal_node.size * 0.5
	var final_pos := await _walk_toward(scene, player, terminal_real_center, spawn_pos)
	var player_rect := Rect2(final_pos, player.size)
	var overlaps_real_terminal_area: bool = player_rect.intersects(Rect2(terminal_node.position, terminal_node.size))
	print("final=", final_pos, " overlaps the terminal's own (124x112) interact rect region=", overlaps_real_terminal_area, " (expected true -- that rect is bigger than the solid blocker, approach is fine; the real check is that the player visibly stopped BEFORE reaching terminal_real_center, not on top of it)")
	print("distance from final position's center to terminal_real_center=", player_rect.get_center().distance_to(terminal_real_center), " (must be > 0 -- if 0 or tiny, the blocker did nothing)")

	print("== 2. Walk toward each LOCKED-by-default real door node's center -- must stop at the real wall, not mid-floor ==")
	# door_suit deliberately excluded: it's unlocked by default (hub/
	# suit_prep_room are always accessible per _compute_unlocked()), so a
	# genuine walk all the way to its real center correctly triggers the
	# pre-existing, unmodified room-switch code and frees this test scene's
	# nodes -- already exercised safely via the direct _resolve_blockers()
	# unit check in the prior collision round, not repeated here.
	for door_id in ["door_power", "door_air", "door_greenhouse"]:
		var node: Control = target_nodes[door_id]
		var real_center: Vector2 = node.position + node.size * 0.5
		var stopped_at := await _walk_toward(scene, player, real_center, spawn_pos)
		var dist_to_door: float = stopped_at.distance_to(real_center)
		print(door_id, " real_center=", real_center, " stopped_at=", stopped_at, " distance=", dist_to_door, " (must be small -ish, at most a couple hundred px -- NOT ~1000+ which would mean the blocker is nowhere near the real door)")

	print("== 3. Wall thickness re-check (2026-07-22 fix: 56 -> 96) -- push straight into a plain wall stretch away from any door and confirm the stop point is on the FLOOR side of the true measured wall depth ==")
	for check in [
		{"label": "top (away from door_power/corner)", "design_target": Vector2(270.0, -80.0), "axis": "y", "min_design_value": 96.0},
		{"label": "bottom (away from door_greenhouse/corner)", "design_target": Vector2(250.0, 600.0), "axis": "y", "max_design_value": 424.0},
		{"label": "right (away from door_air/corner)", "design_target": Vector2(840.0, 150.0), "axis": "x", "max_design_value": 664.0},
	]:
		var room_target: Vector2 = scene.call("_room_point", check["design_target"])
		var stopped_at := await _walk_toward(scene, player, room_target, scene.call("_room_point", Vector2(359, 356)))
		var stopped_design: Vector2 = scene.call("_design_point_from_room", stopped_at)
		var ok: bool
		if check.has("min_design_value"):
			ok = stopped_design.y >= check["min_design_value"] - 2.0
		else:
			ok = stopped_design.x <= check["max_design_value"] + 2.0 if check["axis"] == "x" else stopped_design.y <= check["max_design_value"] + 2.0
		print(check["label"], " stopped at design-space=", stopped_design, " stayed on floor side of measured wall=", ok)

	player.position = spawn_pos
	scene.call("_sync_player_visual")
	await process_frame
	await _capture("08_hub_blocker_space_fix_full_view.png")

	_done = true
	quit()

func _walk_toward(scene: Node, player: Control, target: Vector2, start_pos: Vector2, max_steps: int = 500) -> Vector2:
	player.position = start_pos
	scene.call("_sync_player_visual")
	await process_frame
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
