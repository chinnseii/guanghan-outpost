extends SceneTree

const OUT_DIR := "res://docs/screenshots/debug_clean"

static func _is_magenta(c: Color) -> bool:
	return c.a > 0.0 and c.r > 0.35 and c.b > 0.35 and c.g < minf(c.r, c.b) - 0.08

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var path := "res://assets/art/training_hub_v2/tiles/floor_plate_plain_01.png"
	var tex: Texture2D = load(path)
	print("tex class: ", tex.get_class())
	var image: Image = tex.get_image()
	print("image format: ", image.get_format(), " compressed: ", image.is_compressed(), " size: ", image.get_size())
	if image.is_compressed():
		image.decompress()
		print("after decompress, format: ", image.get_format())
	var w := image.get_width()
	var h := image.get_height()
	var bad_count := 0
	var samples: Array = []
	for y in range(h):
		for x in range(w):
			var c := image.get_pixel(x, y)
			if _is_magenta(c):
				bad_count += 1
				if samples.size() < 10:
					samples.append([x, y, c])
	print("bad_count: ", bad_count)
	for s in samples:
		print("  sample: ", s)
	# Now clean and save both original and cleaned for direct comparison.
	image.save_png("%s/before.png" % OUT_DIR)
	for s in samples:
		pass
	var bad_pixels: Array[Vector2i] = []
	for y in range(h):
		for x in range(w):
			if _is_magenta(image.get_pixel(x, y)):
				bad_pixels.append(Vector2i(x, y))
	for pos in bad_pixels:
		image.set_pixel(pos.x, pos.y, _nearest_clean(image, pos.x, pos.y, w, h))
	image.save_png("%s/after.png" % OUT_DIR)
	var remaining := 0
	for y in range(h):
		for x in range(w):
			if _is_magenta(image.get_pixel(x, y)):
				remaining += 1
	print("remaining bad after clean: ", remaining)
	quit()

static func _nearest_clean(image: Image, x: int, y: int, w: int, h: int) -> Color:
	for radius in range(1, 7):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var nx := x + dx
				var ny := y + dy
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var c := image.get_pixel(nx, ny)
				if c.a > 0.0 and not _is_magenta(c):
					return c
	return Color("#26313c")
