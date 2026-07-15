extends SceneTree

## AUI-03-04 acceptance capture (Submit Application page). Run only against
## an isolated sandbox project copy (separate project.godot config/name so
## user:// never touches the real project's save directory): this scene
## writes user://saves/application_profile.json on every step.
const OUT_DIR := "res://docs/screenshots/aui_03_04_review"
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

	# Populate representative profile data so the summary column isn't blank.
	var profile = scene.get("profile")
	profile.set("player_name", "林晓")
	profile.set("gender_display", "男")
	profile.set("birth_year", 2000)
	profile.set("education_background", "植物科学")
	profile.set("selected_academic_background_id", "plant_science")
	profile.set("suit_marking", "GH-01")
	profile.set("suit_marking_color", "蓝色")
	profile.set("candidate_file_status", "待提交")

	scene.call("_show_step", "review")
	await process_frame
	await create_timer(0.2).timeout
	await _capture("01_review_default_0_of_3.png")

	# Check all 3 confirmation rows to show the Selected state + enabled submit.
	var confirmation_checks: Array = scene.get("confirmation_checks")
	for row in confirmation_checks:
		(row as Button).emit_signal("pressed")
	await process_frame
	await create_timer(0.2).timeout
	await _capture("02_review_all_confirmed_3_of_3.png")

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
