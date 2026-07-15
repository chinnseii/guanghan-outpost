extends SceneTree

## Verifies the redesigned main-menu nav items (icon + label + shortcut,
## accent-bar state system). Run only against an isolated sandbox project
## copy (separate project.godot config/name).
const OUT_DIR := "res://docs/screenshots/main_menu"
const SCENE := "res://scenes/main.tscn"

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
	await _capture("03_nav_default_state.png")

	var start_button: Button = scene.get_node("UI/Root/MainMenu/Box/StartButton")
	start_button.grab_focus()
	await process_frame
	await create_timer(0.25).timeout
	await _capture("04_nav_focus_state.png")

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
