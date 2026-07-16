extends SceneTree

## AUI-04-03 acceptance capture (Preliminary Eligibility Review Result page).
## Run only against an isolated sandbox project copy (separate project.godot
## config/name so user:// never touches the real project's save directory):
## this scene writes user://saves/application_profile.json on every step.
const OUT_DIR := "res://docs/screenshots/aui_04_03_notice"
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

	var profile = scene.get("profile")
	profile.set("player_name", "林晓")
	profile.set("gender_display", "男")
	profile.set("application_id", "GHO-APP-2068-0421")

	scene.call("_show_step", "notice")
	await process_frame
	await create_timer(0.2).timeout
	await _capture("01_notice_full_page.png")

	# Crop-based detail views (same frame, no re-render needed).
	await _capture_region("02_notice_left_document_detail.png", Rect2i(24, 195, 928, 735))
	await _capture_region("03_notice_right_summary_progress_detail.png", Rect2i(968, 195, 928, 735))
	await _capture_region("04_notice_earth_ghost_detail.png", Rect2i(330, 380, 620, 540))
	await _capture_scaled("06_notice_1600x900.png", Vector2i(1600, 900))

	# Earth-ghost off/on comparison: toggle the watermark and re-capture.
	var earth_roots := scene.find_children("EarthGhostRoot", "", true, false)
	if earth_roots.size() > 0:
		(earth_roots[0] as Control).visible = false
		await process_frame
		await _capture("05a_notice_earth_ghost_off.png")
		(earth_roots[0] as Control).visible = true
		await process_frame
		await _capture("05b_notice_earth_ghost_on.png")

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

func _capture_region(file_name: String, region: Rect2i) -> void:
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		push_error("Viewport texture unavailable. Run WITHOUT --headless.")
		return
	var image := texture.get_image()
	var cropped := image.get_region(region)
	var err := cropped.save_png("%s/%s" % [OUT_DIR, file_name])
	print("capture ", file_name, " err=", err)

func _capture_scaled(file_name: String, target_size: Vector2i) -> void:
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		push_error("Viewport texture unavailable. Run WITHOUT --headless.")
		return
	var image := texture.get_image()
	image.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var err := image.save_png("%s/%s" % [OUT_DIR, file_name])
	print("capture ", file_name, " err=", err)
