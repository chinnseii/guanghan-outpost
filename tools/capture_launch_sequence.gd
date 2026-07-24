extends SceneTree

## Verifies LaunchSequenceScene's Round 2 structure (video/scroll-text/video/
## scroll-text/countdown/video/scroll-text/video/scroll-text/video ->
## handoff) actually plays/renders each beat in real time, by loading the
## scene directly (not through the full accept-assignment flow) and
## grabbing a screenshot near each expected beat's midpoint. Run only
## against an isolated sandbox project copy -- OpeningFlowManager's
## set_opening_flow_stage() writes to the training progress save file at
## the very end, so isolation still matters here even though this scene
## doesn't touch user:// on its own otherwise.
const OUT_DIR := "res://docs/screenshots/launch_sequence"
const SCENE := "res://scenes/training/LaunchSequenceScene.tscn"

var _done := false


func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")


func _force_quit_guard() -> void:
	await create_timer(90.0).timeout
	if not _done:
		push_error("Capture script exceeded 90s guard; force quitting.")
		quit(1)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1920, 1080)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame

	await create_timer(2.0).timeout
	await _capture("01_launch01_playing.png")

	await create_timer(6.0).timeout  # ~8s: launch_01 ended, mid scroll 1 ("你回首望向远方...")
	await _capture("02_scroll_look_back.png")

	await create_timer(7.0).timeout  # ~15s: mid launch_02
	await _capture("03_launch02_playing.png")

	await create_timer(7.0).timeout  # ~22s: mid scroll 2 ("耳机传来数秒声" / "10..4")
	await _capture("04_scroll_headset_count.png")

	await create_timer(3.0).timeout  # ~25s: mid big countdown (3,2,1,点火)
	await _capture("05_countdown.png")

	await create_timer(6.0).timeout  # ~31s: mid launch_03
	await _capture("06_launch03_playing.png")

	await create_timer(5.5).timeout  # ~36.5s: mid scroll 3 ("距离发射已经过去了三天...")
	await _capture("07_scroll_three_days.png")

	await create_timer(4.0).timeout  # ~40.5s: mid launch_04
	await _capture("08_launch04_playing.png")

	await create_timer(6.5).timeout  # ~47s: mid scroll 4 ("透过舷窗...")
	await _capture("09_scroll_porthole.png")

	await create_timer(6.0).timeout  # ~53s: mid launch_05
	await _capture("10_launch05_playing.png")

	await create_timer(7.0).timeout  # ~60s: handoff should be complete
	print("current_scene at end: ", root.get_child(root.get_child_count() - 1).name if root.get_child_count() > 0 else "none")
	await _capture("11_after_handoff.png")

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
