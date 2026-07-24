extends SceneTree

## TR-002_MASTER_ELEMENTS_TRIAL follow-up (2026-07-24): User reported the new
## terminal texture looks misaligned with collision -- feet visibly on the
## console approaching from the north, and an odd stop-short gap
## approaching from the south. Prints the EXACT resolved player rect (design
## space) from both directions against both the existing terminal blocker
## AND the terminal texture's real measured opaque bbox
## (Rect2(Vector2(326,178), Vector2(107,92)), from pixel-diffing the source
## art) to find the true numeric mismatch instead of guessing.
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"
const TEXTURE_BBOX := Rect2(Vector2(326, 178), Vector2(107, 92))

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
	print("DEBUG briefing_visible=", scene.get("briefing_visible"), " pause_visible=", scene.get("pause_visible"), " interaction_running=", scene.get("interaction_running"), " map_overview_visible=", scene.get("map_overview_visible"), " tree.paused=", paused, " process_mode=", scene.process_mode)

	var player: Control = scene.get("player")
	var module_data: Dictionary = scene.get("module_data")
	var blockers: Array = module_data.get("blockers", [])
	var terminal_blocker: Rect2 = blockers[0]
	print("terminal_blocker (design space)=", terminal_blocker, " design bottom=", terminal_blocker.end.y)
	print("terminal texture opaque bbox (design space)=", TEXTURE_BBOX, " bottom=", TEXTURE_BBOX.end.y, " top=", TEXTURE_BBOX.position.y)

	# South approach: start well below, walk straight up (north) -- using the
	# same "recompute direction toward a target every frame" pattern as the
	# known-working capture_tr002_terminal_directional_check.gd, not a naive
	# constant single-direction hold (which mysteriously produced zero net
	# movement over 300 frames when tried here).
	# NOTE: +150 originally landed the player's rect (54 tall) overlapping
	# the bottom wall's door_greenhouse gap blocker (active while that door
	# is locked, which it is by default this early in the curriculum) --
	# an already-invalid starting rect that _resolve_blockers can never
	# escape (every candidate AND old_position itself intersect, so it just
	# keeps returning old_position forever). +80 keeps the full rect clear.
	var south_start_design: Vector2 = Vector2(terminal_blocker.get_center().x, terminal_blocker.end.y + 80.0)
	var south_target_design: Vector2 = Vector2(terminal_blocker.get_center().x, terminal_blocker.position.y - 10.0)
	player.position = scene.call("_room_point", south_start_design)
	scene.call("_sync_player_visual")
	await process_frame
	print("DEBUG south pre-loop player.position=", player.position, " is_action_pressed(ui_up) test=", Input.is_action_pressed("ui_up"))
	for step in range(300):
		var player_center: Vector2 = player.position + player.size * 0.5
		var target_room: Vector2 = scene.call("_room_point", south_target_design)
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
		if step in [0, 5, 20, 60, 150, 299]:
			print("DEBUG south step=", step, " player.position=", player.position, " dir=", dir)
	var south_final_room: Vector2 = player.position
	var south_final_design: Vector2 = scene.call("_design_point_from_room", south_final_room)
	var south_final_design_end: Vector2 = scene.call("_design_point_from_room", south_final_room + player.size)
	var south_feet_design: Vector2 = scene.call("_design_point_from_room", south_final_room + Vector2(player.size.x * 0.5, player.size.y))
	print("SOUTH approach final rect (design)=", Rect2(south_final_design, south_final_design_end - south_final_design), " feet=", south_feet_design)
	print("  gap between feet.y and texture bottom(", TEXTURE_BBOX.end.y, ") = ", south_feet_design.y - TEXTURE_BBOX.end.y)
	print("  gap between rect-top.y and blocker bottom(", terminal_blocker.end.y, ") = ", south_final_design.y - terminal_blocker.end.y)

	# North approach: start well above (clear of the top wall's door_power
	# gap blocker, same overlap bug as the south start above), walk down.
	var north_start_design: Vector2 = Vector2(terminal_blocker.get_center().x, terminal_blocker.position.y - 80.0)
	var north_target_design: Vector2 = Vector2(terminal_blocker.get_center().x, terminal_blocker.end.y + 10.0)
	player.position = scene.call("_room_point", north_start_design)
	scene.call("_sync_player_visual")
	await process_frame
	for step in range(300):
		var player_center: Vector2 = player.position + player.size * 0.5
		var target_room: Vector2 = scene.call("_room_point", north_target_design)
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
	var north_final_room: Vector2 = player.position
	var north_final_design: Vector2 = scene.call("_design_point_from_room", north_final_room)
	var north_final_design_end: Vector2 = scene.call("_design_point_from_room", north_final_room + player.size)
	var north_feet_design: Vector2 = scene.call("_design_point_from_room", north_final_room + Vector2(player.size.x * 0.5, player.size.y))
	print("NORTH approach final rect (design)=", Rect2(north_final_design, north_final_design_end - north_final_design), " feet=", north_feet_design)
	print("  overlap between feet.y and texture top(", TEXTURE_BBOX.position.y, ") = ", TEXTURE_BBOX.position.y - north_feet_design.y, " (positive = feet are north of texture top, i.e. clear; negative = feet already past texture top)")
	print("  rect-bottom.y=", north_final_design_end.y, " vs blocker-top(", terminal_blocker.position.y, ")")

	_done = true
	quit()
