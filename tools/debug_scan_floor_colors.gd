extends SceneTree

const FloorPlatePlain := preload("res://assets/art/training_hub_v2/tiles/floor_plate_plain_01.png")

func _initialize() -> void:
	var image: Image = FloorPlatePlain.get_image()
	if image.is_compressed():
		image.decompress()
	var w := image.get_width()
	var h := image.get_height()
	print("image size: ", w, "x", h)

	# Tally distinct colors (rounded to reduce noise) to find the
	# dominant background tone vs. any outlier "seam" colors.
	var counts: Dictionary = {}
	for y in range(h):
		for x in range(w):
			var c := image.get_pixel(x, y)
			var key := "%d,%d,%d" % [int(c.r * 255), int(c.g * 255), int(c.b * 255)]
			counts[key] = counts.get(key, 0) + 1

	var entries: Array = []
	for k in counts.keys():
		entries.append([k, counts[k]])
	entries.sort_custom(func(a, b): return a[1] > b[1])

	print("--- top 20 colors by pixel count ---")
	for i in range(min(20, entries.size())):
		print(entries[i][0], " count=", entries[i][1])

	# Specifically look at row/col 0 and edges near tile boundaries (every
	# 32px, since these floors get scaled 256->64, i.e. a 4x downscale;
	# also check the exact edge row/col which is what repeats as the
	# "seam" when tiled).
	print("--- edge sample: top row (y=0), x=0,32,64,96,128,160,192,224,255 ---")
	for x in [0, 32, 64, 96, 128, 160, 192, 224, 255]:
		var c := image.get_pixel(x, 0)
		print("x=", x, " y=0 -> ", c)
	print("--- edge sample: left col (x=0), y=0,32,64,96,128,160,192,224,255 ---")
	for y in [0, 32, 64, 96, 128, 160, 192, 224, 255]:
		var c := image.get_pixel(0, y)
		print("x=0 y=", y, " -> ", c)

	print("--- border depth probe: x=128, y=0..12 ---")
	for y in range(13):
		var c := image.get_pixel(128, y)
		print("y=", y, " -> ", c, " hue_deg=", c.h * 360.0, " sat=", c.s)

	quit()
