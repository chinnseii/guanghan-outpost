extends SceneTree

## Verifies the new multi-appearance system in player_visual.gd: switching
## appearance_id via set_appearance() correctly swaps the whole sheet (not
## just texture path but frame_size/display_size too), and each of the 3
## packs (longhair 128px-prescaled, ponytail/shorthair native 256px) renders
## cleanly at this character's usual on-screen scale with no aliasing.
## Isolated player.tscn instantiate, no save file interaction.
const OUT_DIR := "res://docs/screenshots/player_appearance_variants"
const SCENE := "res://scenes/player.tscn"
const APPEARANCES := [
	"female_light_black_longhair",
	"female_light_black_ponytail",
	"female_light_black_shorthair",
]

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

	for appearance_id in APPEARANCES:
		visual.call("set_appearance", appearance_id)
		await process_frame
		visual.call("setup", Vector2.DOWN, false, 100.0, false, 0.0)
		await process_frame
		await _capture("%s_idle_down.png" % appearance_id)

		visual.call("setup", Vector2.RIGHT, false, 100.0, true, 1.25 * 2)
		await process_frame
		await _capture("%s_walk_right.png" % appearance_id)

		visual.call("setup", Vector2.UP, false, 100.0, true, 1.25 * 4)
		await process_frame
		await _capture("%s_walk_up.png" % appearance_id)

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
	var zoomed := image.get_region(Rect2i(680, 380, 240, 240))
	zoomed.save_png("%s/zoom_%s" % [OUT_DIR, file_name])
	print("capture ", file_name)
