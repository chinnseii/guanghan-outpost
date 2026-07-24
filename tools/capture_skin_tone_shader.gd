extends SceneTree

## Verifies the new skin-tone shader (player_visual.gd's SpriteLayer +
## CharacterAppearanceCatalog's SKIN_MASK_REGISTRY/SKIN_PALETTE): switching
## skin_tone (light/medium/dark) should only recolor face/ears/hands, never
## the suit/hair/backpack. Renders the same appearance (female longhair) at
## all 3 skin tones, then samples actual pixel colors at a face-area point
## and a suit-area point to confirm quantitatively, not just visually.
## Isolated player.tscn instantiate, no save file interaction.
const OUT_DIR := "res://docs/screenshots/skin_tone_shader"
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

	var skin_tones := ["light", "medium", "dark"]
	for hairstyle in ["long", "ponytail", "short"]:
		for skin_tone in skin_tones:
			visual.call("set_character_appearance", "female", skin_tone, "black", hairstyle)
			await process_frame
			visual.call("setup", Vector2.DOWN, false, 100.0, false, 0.0)
			await process_frame
			await process_frame
			print("hairstyle=", hairstyle, " skin_tone=", skin_tone, " appearance_key=", visual.get("appearance_key"), " is_fallback=", visual.get("appearance_is_fallback"))
			await _capture_and_sample("female_black_%s_%s.png" % [hairstyle, skin_tone])

	# Also test a second hairstyle/gender combo (male buzz) to confirm the
	# mask lookup generalizes correctly, not just for the one tested above.
	for skin_tone in skin_tones:
		visual.call("set_character_appearance", "male", skin_tone, "black", "buzz")
		await process_frame
		visual.call("setup", Vector2.DOWN, false, 100.0, false, 0.0)
		await process_frame
		await process_frame
		print("skin_tone=", skin_tone, " appearance_key=", visual.get("appearance_key"))
		await _capture_and_sample("male_black_buzz_%s.png" % skin_tone)

	_done = true
	quit()

func _capture_and_sample(file_name: String) -> void:
	await process_frame
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		push_error("Viewport texture unavailable. Run WITHOUT --headless.")
		return
	var image := texture.get_image()
	var zoomed := image.get_region(Rect2i(760, 420, 80, 80))
	zoomed.resize(320, 320, Image.INTERPOLATE_NEAREST)
	zoomed.save_png("%s/zoom_%s" % [OUT_DIR, file_name])
	# Full-res sample points, relative to character origin at (800,500):
	# face is roughly 30-40px above origin (head area), suit/torso is
	# roughly 10-20px above origin. Sample a small patch and report.
	var face_sample := image.get_pixel(800, 464)
	var torso_sample := image.get_pixel(800, 486)
	print("  face pixel @ (800,464): ", face_sample, "  torso pixel @ (800,486): ", torso_sample)
	print("capture ", file_name)
