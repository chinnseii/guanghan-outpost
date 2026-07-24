extends SceneTree

func _initialize() -> void:
	var path := "res://docs/screenshots/debug_clean/floor_only.png"
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	print("size=", image.get_width(), "x", image.get_height())

	# Scan for near-white pixels across the whole image, report bounding
	# extents per contiguous row so we know exactly what's producing them.
	var w := image.get_width()
	var h := image.get_height()
	var rows_with_white: Dictionary = {}
	for y in range(h):
		var min_x := -1
		var max_x := -1
		for x in range(w):
			var c := image.get_pixel(x, y)
			if c.v > 0.7 and c.s < 0.25:
				if min_x == -1:
					min_x = x
				max_x = x
		if min_x != -1:
			rows_with_white[y] = [min_x, max_x, max_x - min_x + 1]

	for y in rows_with_white.keys():
		var info = rows_with_white[y]
		if info[2] > 20:
			print("y=", y, " x_range=[", info[0], ",", info[1], "] span=", info[2])
	quit()
