extends SceneTree

const OUT_DIR := "res://docs/screenshots/training_hub_art"
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
	var crate_blocker: Rect2 = blockers[1]
	print("crate_blocker (design space)=", crate_blocker)
	var crate_center_design: Vector2 = crate_blocker.position + crate_blocker.size * 0.5
	var crate_center_room: Vector2 = scene.call("_room_point", crate_center_design)
	var spawn_room: Vector2 = scene.call("_room_point", Vector2(359, 356))
	player.position = spawn_room
	scene.call("_sync_player_visual")
	await process_frame
	for step in range(400):
		var player_center: Vector2 = player.position + player.size * 0.5
		var to_target: Vector2 = crate_center_room - player_center
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
	print("final_design_rect=", final_rect, " overlaps_crate=", final_rect.intersects(crate_blocker), " (must be false)")
	await _capture("10_hub_crate_check.png")

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
