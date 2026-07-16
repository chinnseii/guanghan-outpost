extends SceneTree

## Verifies the TR-002 real art integration for 训练中控室 (hub room):
## floor tile texture, 4 door frame props (2 orientations), console prop,
## and 4 direction-signage plaques. Run only against an isolated sandbox
## project copy (separate project.godot config/name so user:// never
## touches the real project's save directory).
const OUT_DIR := "res://docs/screenshots/training_hub_art"
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"

var _done := false

func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(30.0).timeout
	if not _done:
		push_error("Capture script exceeded 30s guard; force quitting.")
		quit(1)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1920, 1080)
	var scene := (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout

	# Dismiss the briefing modal so the hub room itself is fully visible.
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout
	await _capture("01_hub_full_view.png")

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
