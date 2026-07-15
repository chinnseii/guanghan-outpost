extends SceneTree

## AUI-03-03 acceptance capture (Appearance & Marking page). Run only against
## an isolated sandbox project copy (separate project.godot config/name so
## user:// never touches the real project's save directory): this scene
## writes user://saves/application_profile.json on every step.
const OUT_DIR := "res://docs/screenshots/aui_03_03_appearance_marking"
const SCENE := "res://scenes/application/ApplicationStartScene.tscn"

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
	await create_timer(0.2).timeout

	# Male candidate for a deterministic default-state full-page capture.
	scene.get("profile").set("gender_display", "男")
	scene.call("_show_step", "appearance")
	await process_frame
	await create_timer(0.2).timeout
	await _capture("01_full_page_default_state.png")

	# Male example: medium warm skin, black short hair, blue Level 01 suit.
	scene.call("_select_appearance_choice", "skin", "medium")
	scene.call("_select_appearance_choice", "hair_style", "short")
	scene.call("_select_appearance_choice", "hair_color", "black")
	scene.call("_select_appearance_choice", "suit_color", "blue")
	await process_frame
	await create_timer(0.2).timeout
	await _capture("02_male_medium_black_short_blue.png")

	# Female example: medium warm skin, auburn ponytail, red Level 01 suit.
	scene.get("profile").set("gender_display", "女")
	scene.call("_show_step", "appearance")
	await process_frame
	await create_timer(0.2).timeout
	scene.call("_select_appearance_choice", "skin", "medium")
	scene.call("_select_appearance_choice", "hair_style", "ponytail")
	scene.call("_select_appearance_choice", "hair_color", "auburn")
	scene.call("_select_appearance_choice", "suit_color", "red")
	await process_frame
	await create_timer(0.2).timeout
	await _capture("03_female_medium_auburn_ponytail_red.png")

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
