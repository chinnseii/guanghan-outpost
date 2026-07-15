extends SceneTree

## Verifies the video-based title background actually decodes and plays.
## Run only against an isolated sandbox project copy.
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

	var player: VideoStreamPlayer = scene.get_node("UI/Root/MainMenu/TitleBackground/BackgroundVideo")
	print("player found=", player != null, " playing=", player.is_playing() if player else "n/a")

	# Let a couple of seconds of real video decode before capturing, to
	# confirm actual frame content (not just a black/blank first frame).
	await create_timer(1.5).timeout
	print("mid-playback is_playing=", player.is_playing(), " stream_position=", player.stream_position)
	await _capture("05_video_bg_frame_A.png")

	await create_timer(1.5).timeout
	await _capture("06_video_bg_frame_B.png")

	_done = true
	quit()

func _capture(file_name: String) -> void:
	for i in range(6):
		await process_frame
	var texture := root.get_texture()
	if texture == null:
		push_error("Viewport texture unavailable. Run WITHOUT --headless.")
		return
	var image := texture.get_image()
	var err := image.save_png("%s/%s" % [OUT_DIR, file_name])
	print("capture ", file_name, " err=", err)
