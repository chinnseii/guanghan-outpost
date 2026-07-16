extends SceneTree

## Regression capture for the "black screen after review sequence" bug:
## review_fade_rect (added directly to aui_canvas, z_index=100, opaque at
## fade-end) was never freed after _show_step("notice"), permanently
## covering every page after the review sequence finished. This script runs
## the FULL autoplay past the fade (unlike capture_aui_04_02_review_sequence.gd,
## which only sampled up to t=9.6s and never exercised the real transition)
## and confirms the notice page is actually visible afterward.
## Run only against an isolated sandbox project copy (separate project.godot
## config/name so user:// never touches the real project's save directory).
const OUT_DIR := "res://docs/screenshots/aui_04_02_review_sequence"
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

	scene.call("_show_step", "review")
	await process_frame
	await create_timer(0.2).timeout
	scene.call("_start_review_sequence")
	await process_frame

	# Full autoplay: 9.5s steps + 1.0s hold + 0.5s fade = 11.0s, then margin.
	await create_timer(12.0).timeout
	await _capture("05_review_after_fade_notice_page.png")

	var step_now := String(scene.get("step"))
	print("current step after autoplay: ", step_now)
	if step_now != "notice":
		push_error("REGRESSION: scene did not reach the notice step after the review sequence.")

	var fade_rects := scene.find_children("EarthGhostRoot", "", true, false)
	print("earth ghost roots found on notice page: ", fade_rects.size())

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
