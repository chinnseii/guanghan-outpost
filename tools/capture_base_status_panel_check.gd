extends SceneTree

const OUT_DIR := "res://docs/screenshots/prop_bridge_check"
const OLD_BASE_SCENE := "res://scenes/base/OldBaseInteriorScene.tscn"

var scene_instance: Node

func _initialize() -> void:
	print("capture_base_status_panel_check start")
	DisplayServer.window_set_size(Vector2i(1600, 900))
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	scene_instance = (load(OLD_BASE_SCENE) as PackedScene).instantiate()
	root.add_child(scene_instance)
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	scene_instance.call("_toggle_base_status_panel")
	await process_frame
	await process_frame
	await _capture("41_base_status_panel_open.png")
	print("capture_base_status_panel_check done")
	quit()

func _capture(file_name: String) -> void:
	await process_frame
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		push_error("Viewport texture is unavailable. Run without --headless.")
		return
	var image := texture.get_image()
	var err := image.save_png("%s/%s" % [OUT_DIR, file_name])
	print("capture ", file_name, " err=", err)
