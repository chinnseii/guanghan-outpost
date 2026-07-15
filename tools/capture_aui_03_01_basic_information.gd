extends SceneTree

## AUI-03-01 acceptance capture. Run WITHOUT --headless, and only against an
## isolated sandbox project copy (separate project.godot config/name so
## user:// never touches the real project's save directory): this scene
## writes user://saves/application_profile.json on every step.
##
## Verifies the single-canvas uniform-scale + letterbox/pillarbox approach
## across several window sizes, not just the 1920x1080 design resolution.
const OUT_DIR := "res://docs/screenshots/aui_03_01_basic_information"
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

func _set_window(w: int, h: int) -> void:
	root.size = Vector2i(w, h)
	await process_frame
	await create_timer(0.15).timeout

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var scene := (load(SCENE) as PackedScene).instantiate()

	await _set_window(1920, 1080)
	root.add_child(scene)
	await process_frame
	await create_timer(0.2).timeout
	await _capture("01_1920x1080_initial_0_of_3.png")

	await _set_window(1600, 900)
	await _capture("02_1600x900_initial_0_of_3.png")

	await _set_window(1440, 900)
	await _capture("03_1440x900_non_16_9_letterboxed.png")

	await _set_window(1600, 900)
	var name_edit: LineEdit = scene.get("name_edit")
	var gender_options: OptionButton = scene.get("gender_options")
	var birth_options: OptionButton = scene.get("birth_options")
	if name_edit == null or gender_options == null or birth_options == null:
		push_error("Expected identity fields not found on scene.")
		_done = true
		quit(1)
		return
	name_edit.text = "林晓"
	gender_options.select(1)
	var birth_index := -1
	for i in range(birth_options.get_item_count()):
		if birth_options.get_item_text(i) == "2000":
			birth_index = i
			break
	if birth_index >= 0:
		birth_options.select(birth_index)
	scene.call("_refresh_identity_state")
	await process_frame
	await create_timer(0.2).timeout
	await _capture("04_1600x900_complete_3_of_3_next_enabled.png")

	await _set_window(1920, 1080)
	# Reset fields back to empty for a clean dropdown-only demonstration.
	name_edit.text = ""
	gender_options.select(0)
	birth_options.select(0)
	scene.call("_refresh_identity_state")
	await process_frame
	var gender_popup: PopupMenu = gender_options.get_popup()
	var gender_rect: Rect2 = gender_options.get_global_rect()
	gender_popup.popup(Rect2i(
		Vector2i(int(gender_rect.position.x), int(gender_rect.position.y + gender_rect.size.y)),
		Vector2i.ZERO
	))
	await process_frame
	await create_timer(0.2).timeout
	await _capture("05_gender_dropdown_expanded.png")
	gender_popup.hide()

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
