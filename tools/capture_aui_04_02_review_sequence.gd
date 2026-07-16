extends SceneTree

## AUI-04-02 acceptance capture (automated post-submit review sequence).
## Run only against an isolated sandbox project copy (separate
## project.godot config/name so user:// never touches the real project's
## save directory): this scene writes user://saves/application_profile.json
## on every step.
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
	await _capture("01_review_t0_session_start.png")

	# t ~= 3s: a couple of quick steps done, 身份校验 likely active/done.
	await create_timer(3.0).timeout
	await _capture("02_review_t3_in_progress.png")

	# t ~= 6s: 学术背景匹配 should be active with animated dots.
	await create_timer(3.0).timeout
	await _capture("03_review_t6_academic_matching.png")

	# t ~= 9.6s: all steps done, completion block should be visible.
	await create_timer(3.6).timeout
	await _capture("04_review_t9_6_completion.png")

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
