extends SceneTree

const PATHS := [
	"res://assets/art/training_hub_v2/walls/wall_corner_outer_rot_0.png",
	"res://assets/art/training_hub_v2/walls/wall_corner_outer_rot_90.png",
	"res://assets/art/training_hub_v2/walls/wall_corner_outer_rot_180.png",
	"res://assets/art/training_hub_v2/walls/wall_corner_outer_rot_270.png",
]

func _initialize() -> void:
	for path in PATHS:
		var tex: Texture2D = load(path)
		var image: Image = tex.get_image()
		if image.is_compressed():
			image.decompress()
		var w := image.get_width()
		var h := image.get_height()
		print("=== ", path, " size=", w, "x", h, " ===")
		# Sample all 4 edges at a handful of points, report any pixel whose
		# value/lightness is notably higher (whiter) than typical interior
		# tone, or whose saturation/hue looks anomalous.
		var edge_points: Array = []
		for i in range(0, w, max(1, w / 10)):
			edge_points.append(Vector2i(i, 0))
			edge_points.append(Vector2i(i, h - 1))
		for j in range(0, h, max(1, h / 10)):
			edge_points.append(Vector2i(0, j))
			edge_points.append(Vector2i(w - 1, j))
		for p in edge_points:
			var c := image.get_pixel(p.x, p.y)
			if c.v > 0.55 or (c.s < 0.15 and c.v > 0.4):
				print("  bright/white edge px at ", p, " -> ", c, " v=", c.v, " s=", c.s)
	quit()
