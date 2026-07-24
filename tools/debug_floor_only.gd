extends SceneTree

const OUT_DIR := "res://docs/screenshots/debug_clean"
const TrainingModuleSceneScript := preload("res://scripts/training/training_module_scene.gd")

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(800, 600)
	var blockout = TrainingModuleSceneScript.TrainingHubBlockout.new()
	blockout.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(blockout)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var texture := root.get_texture()
	var image := texture.get_image()
	image.save_png("%s/floor_only.png" % OUT_DIR)
	print("saved")
	quit()
