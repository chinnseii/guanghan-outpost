extends SceneTree

## AUI-03-02 acceptance capture (profession selection cards + right-side
## professional profile). Run only against an isolated sandbox project copy
## (separate project.godot config/name so user:// never touches the real
## project's save directory): this scene writes user://saves/application_profile.json
## on every step.
const OUT_DIR := "res://docs/screenshots/aui_03_02_profession_cards"
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

	scene.call("_show_step", "education")
	await process_frame
	await create_timer(0.2).timeout

	var professions := [
		["plant_science", "01_plant_science_selected.png"],
		["mechanical_engineering", "02_mechanical_engineering_selected.png"],
		["materials_science", "03_materials_science_selected.png"],
		["medicine", "04_medicine_selected.png"],
	]
	for entry in professions:
		scene.call("_select_profession", entry[0])
		await process_frame
		await create_timer(0.2).timeout
		await _capture(String(entry[1]))

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
