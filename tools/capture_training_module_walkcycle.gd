extends SceneTree

## Verifies the same PLAYER-VISUAL-01 walk-cycle integration in
## training_module_scene.gd (a structurally different code path from
## training_base_map.gd -- no _room_scale() rescaling here), using
## FinalAssessmentScene.tscn (module_id "final_assessment", no suit-worn
## entry gate, unlike power_repair). Isolated sandbox, separate user://.
var _done := false
var _scene: Node = null

func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(30.0).timeout
	if not _done:
		push_error("Capture script exceeded 30s guard; force quitting.")
		quit(1)

func _run() -> void:
	var out_dir := ProjectSettings.globalize_path("res://docs/screenshots/training_module_walkcycle")
	DirAccess.make_dir_recursive_absolute(out_dir)
	root.size = Vector2i(1600, 900)

	var TrainingManagerScript := load("res://scripts/training/training_manager.gd")
	TrainingManagerScript.call("dev_force_unlock_up_to", "life_support")
	TrainingManagerScript.call("set_current_module", "final_assessment")

	_scene = (load("res://scenes/training/FinalAssessmentScene.tscn") as PackedScene).instantiate()
	root.add_child(_scene)
	await process_frame
	await process_frame
	await process_frame

	if _scene.has_method("_close_briefing"):
		_scene.call("_close_briefing")
	await process_frame
	await _capture(out_dir, "01_idle.png")

	Input.action_press("ui_right")
	await _advance_frames(20)
	await _capture(out_dir, "02_walk_right.png")
	Input.action_release("ui_right")
	await _advance_frames(3)

	Input.action_press("ui_down")
	await _advance_frames(20)
	await _capture(out_dir, "03_walk_down.png")
	Input.action_release("ui_down")

	_done = true
	quit()

func _advance_frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _capture(out_dir: String, file_name: String) -> void:
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		push_error("Viewport texture unavailable. Run WITHOUT --headless.")
		return
	var image := texture.get_image()
	var err := image.save_png("%s/%s" % [out_dir, file_name])
	print("capture ", file_name, " err=", err)
