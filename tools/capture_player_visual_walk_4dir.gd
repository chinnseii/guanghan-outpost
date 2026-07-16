extends SceneTree

## Verifies the new "female_light_black_longhair_walk_4dir" production sprite
## (6 frames x 4 directions, prescaled 512->128 per cell) wired into
## player_visual.gd: correct per-direction row crop, correct 6-frame cycle
## timing (8 FPS via WALK_PHASE_PER_FRAME), and clean (non-aliased) rendering
## at this character's normal on-screen scale. Same isolated approach as
## Round 1's capture_player_visual_walk_cycle.gd -- instantiates
## scenes/player.tscn directly, no save file interaction.
const OUT_DIR := "res://docs/screenshots/player_visual_walk_4dir"
const SCENE := "res://scenes/player.tscn"

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
	root.size = Vector2i(1600, 900)

	var background := ColorRect.new()
	background.color = Color("#0e1a24")
	background.size = Vector2(1600, 900)
	root.add_child(background)

	var visual := (load(SCENE) as PackedScene).instantiate()
	visual.position = Vector2(800, 500)
	root.add_child(visual)
	await process_frame

	visual.call("setup", Vector2.DOWN, false, 100.0, false, 0.0)
	await process_frame
	await _capture("00_idle_down.png")

	var directions := {
		"down": Vector2.DOWN,
		"left": Vector2.LEFT,
		"right": Vector2.RIGHT,
		"up": Vector2.UP,
	}
	for dir_name in directions.keys():
		var dir_vec: Vector2 = directions[dir_name]
		for i in range(6):
			visual.call("setup", dir_vec, false, 100.0, true, float(i) * 1.25)
			await process_frame
			await _capture("%s_frame_%d.png" % [dir_name, i])

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
	var zoomed := image.get_region(Rect2i(700, 400, 200, 200))
	zoomed.save_png("%s/zoom_%s" % [OUT_DIR, file_name])
	print("capture ", file_name)
