extends SceneTree

const WallCornerRot0 := preload("res://assets/art/training_hub_v2/walls/wall_corner_outer_rot_0.png")

func _initialize() -> void:
	var image: Image = WallCornerRot0.get_image()
	if image.is_compressed():
		image.decompress()
	print("--- bottom edge depth probe: x=128, y=255 down to 245 ---")
	for y in range(255, 244, -1):
		var c := image.get_pixel(128, y)
		print("y=", y, " -> ", c, " v=", c.v, " s=", c.s)
	quit()
