extends SceneTree

## Verifies the title background video plays through ONCE and fades to the
## fixed static image, instead of looping. Run only against an isolated
## sandbox project copy (separate project.godot config/name).
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

	var wrapper := scene.get_node("UI/Root/MainMenu/TitleBackground")
	var player: VideoStreamPlayer = wrapper.get_node("BackgroundVideo")
	print("video duration (stream length not directly exposed); waiting through full playback")

	# Video is ~12s. Wait past that plus the 1.5s fade plus margin, then check.
	await create_timer(14.5).timeout
	var player_still_present := is_instance_valid(player)
	print("player still present after 14.5s: ", player_still_present)
	await _capture("07_video_bg_after_fade_to_still.png")

	var still := wrapper.get_node_or_null("TitleBackgroundImage")
	print("still image node present: ", still != null)

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
