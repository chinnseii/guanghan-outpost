extends SceneTree

const OUT_DIR := "res://docs/screenshots/debug_clean"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(800, 600)
	var rect := ColorRect.new()
	rect.color = Color("#18212b")
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(rect)
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.save_png("%s/blank_screen.png" % OUT_DIR)
	print("saved")
	quit()
