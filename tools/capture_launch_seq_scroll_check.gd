extends SceneTree

## Targeted re-check of the "耳机传来数秒声" countdown-lead-in scroll beat
## after its content was regrouped into 3 lines (header / "10，9，8，7，" /
## "6，5，4"). Doesn't re-verify the rest of the sequence -- that was
## already confirmed in prior rounds and is unchanged here. Run only
## against an isolated sandbox.
const OUT_DIR := "res://docs/screenshots/launch_sequence_scroll_check"
const SCENE := "res://scenes/training/LaunchSequenceScene.tscn"

var _done := false


func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_guard")


func _guard() -> void:
	await create_timer(35.0).timeout
	if not _done:
		push_error("guard timeout")
		quit(1)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1920, 1080)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame

	# scroll1 (3 lines, ends ~9.49s) -> launch_02 (~10.13s, ends ~19.62s) ->
	# scroll2 starts ~19.62s from t0.
	await create_timer(20.0).timeout
	await _capture("scroll2_line1_headset.png")
	await create_timer(1.15).timeout
	await _capture("scroll2_line2_10789.png")
	await create_timer(1.15).timeout
	await _capture("scroll2_line3_654.png")

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
