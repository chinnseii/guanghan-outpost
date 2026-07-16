extends SceneTree

## Verifies the redesigned "训练小型地图" briefing modal (icon badge removed,
## TAB row relabeled to M/地图) and the new M-key map overview modal on the
## training base map scene. Run only against an isolated sandbox project
## copy (separate project.godot config/name so user:// never touches the
## real project's save directory).
const OUT_DIR := "res://docs/screenshots/training_briefing_modal"
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
	await _capture("01_briefing_modal_default.png")

	# Dismiss the briefing, then open the new M-key map overview modal.
	scene.call("_close_briefing")
	await process_frame
	scene.call("_set_map_overview_visible", true)
	await process_frame
	await create_timer(0.2).timeout
	await _capture("02_map_overview_modal.png")

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
