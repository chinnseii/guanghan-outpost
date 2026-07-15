extends SceneTree

## AUI-03-01 acceptance capture. Run WITHOUT --headless and with
## --user-data-dir pointed at an isolated sandbox: this scene writes
## user://saves/application_profile.json on every step, so this script
## must never run against the real project user-data directory.
const OUT_DIR := "res://docs/screenshots/aui_03_01_basic_information"
const SCENE := "res://scenes/application/ApplicationStartScene.tscn"

var _done := false

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(20.0).timeout
	if not _done:
		push_error("Capture script exceeded 20s guard; force quitting.")
		quit(1)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var scene := (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.2).timeout
	await _capture("01_initial_0_of_3.png")

	var gender_options: OptionButton = scene.get("gender_options")
	var name_edit: LineEdit = scene.get("name_edit")
	var birth_options: OptionButton = scene.get("birth_options")
	if gender_options == null or name_edit == null or birth_options == null:
		push_error("Expected identity fields not found on scene (gender_options=%s name_edit=%s birth_options=%s)" % [gender_options, name_edit, birth_options])
		_done = true
		quit(1)
		return

	var gender_popup: PopupMenu = gender_options.get_popup()
	var gender_rect: Rect2 = gender_options.get_global_rect()
	gender_popup.popup(Rect2i(
		Vector2i(int(gender_rect.position.x), int(gender_rect.position.y + gender_rect.size.y)),
		Vector2i.ZERO
	))
	await process_frame
	await create_timer(0.2).timeout
	await _capture("02_gender_dropdown_expanded.png")
	gender_popup.hide()
	await process_frame

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
	await _capture("03_complete_3_of_3_next_enabled.png")

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
