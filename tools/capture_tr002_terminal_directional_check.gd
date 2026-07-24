extends SceneTree

## TR-002 terminal directional collision check (2026-07-22): User screenshot
## showed the player's feet visibly standing ON the terminal art -- this
## script drives the player toward the terminal's real center from 8
## compass directions and prints the EXACT resolved hitbox vs the blocker
## rect each time, to find which direction(s), if any, actually let the
## hitbox overlap (not just a visual sprite-vs-hitbox illusion). Run only
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
	print("player.size=", player.size)

	var terminal_center_design: Vector2 = terminal_blocker.position + terminal_blocker.size * 0.5
	var terminal_center_room: Vector2 = scene.call("_room_point", terminal_center_design)

	for i in range(8):
		var angle: float = TAU / 8.0 * i
		var approach_design: Vector2 = terminal_center_design + Vector2(cos(angle), sin(angle)) * 160.0
		var approach_room: Vector2 = scene.call("_room_point", approach_design)
		player.position = approach_room
		scene.call("_sync_player_visual")
		await process_frame
		for step in range(300):
			var player_center: Vector2 = player.position + player.size * 0.5
			var to_target: Vector2 = terminal_center_room - player_center
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
		var final_room: Vector2 = player.position
		var final_design: Vector2 = scene.call("_design_point_from_room", final_room)
		var final_design_end: Vector2 = scene.call("_design_point_from_room", final_room + player.size)
		var final_design_rect := Rect2(final_design, final_design_end - final_design)
		var overlaps: bool = final_design_rect.intersects(terminal_blocker)
		print("angle=", rad_to_deg(angle), " final_design_rect=", final_design_rect, " overlaps_blocker=", overlaps, " (must be false)")
		if i == 0:
			await _capture("09_terminal_dir_check_angle0_east.png")
		if i == 4:
			await _capture("09_terminal_dir_check_angle180_west.png")
		# North approach (i=6 -> angle=270deg -> offset direction (0,-1),
		# i.e. starting above the terminal and walking down onto it) --
		# screenshot showed this direction specifically overlapping.
		if i == 6:
			await _capture("09_terminal_dir_check_from_north.png")

	_done = true
	quit()

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
