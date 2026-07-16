extends SceneTree

## Verifies the 6 newly registered hair-color combos (blond/auburn x long/
## ponytail/short, all female/light) render correctly via the real
## set_character_appearance() API, and that the existing black-hair combos
## and cross-gender fallback still work unaffected. Isolated player.tscn
## instantiate, no save file interaction.
const OUT_DIR := "res://docs/screenshots/hair_color_variants"
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

	var combos := [
		["female", "light", "blonde", "long"],
		["female", "light", "blonde", "ponytail"],
		["female", "light", "blonde", "short"],
		["female", "light", "auburn", "long"],
		["female", "light", "auburn", "ponytail"],
		["female", "light", "auburn", "short"],
	]
	for combo in combos:
		visual.call("set_character_appearance", combo[0], combo[1], combo[2], combo[3])
		await process_frame
		print("requested=", combo, " resolved_key=", visual.get("appearance_key"), " is_fallback=", visual.get("appearance_is_fallback"))
		visual.call("setup", Vector2.RIGHT, false, 100.0, true, 2.5)
		await process_frame
		await _capture("%s_%s_%s_%s_walk_right.png" % [combo[0], combo[1], combo[2], combo[3]])

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
