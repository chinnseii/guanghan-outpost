extends SceneTree

const OUT_DIR := "res://docs/screenshots/prop_bridge_check"
const PLANT_SCENE := "res://scenes/training/Training_05_PlantDiagnosis.tscn"

var scene_instance: Node

func _initialize() -> void:
	print("capture_plant_diagnosis_prop_bridge_check start")
	DisplayServer.window_set_size(Vector2i(1600, 900))
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await _load_and_wait()
	scene_instance.call("_close_briefing")
	await process_frame
	await process_frame
	await _capture("11_plant_diagnosis_initial.png")

	var state: Dictionary = scene_instance.get("module_data").get("state", {})
	state["PlantObserved"] = true
	state["DiagnosisSelected"] = true
	state["CorrectDiagnosis"] = "LightInsufficient"
	state["GrowLightAdjusted"] = true
	state["GrowLightStatus"] = "正常"
	state["PlantStatus"] = "稳定中"
	await process_frame
	await process_frame
	await _capture("12_plant_diagnosis_stabilizing.png")

	state["PlantStable"] = true
	state["PlantStatus"] = "稳定"
	await process_frame
	await process_frame
	await _capture("13_plant_diagnosis_stable.png")

	print("capture_plant_diagnosis_prop_bridge_check done")
	quit()

func _load_and_wait() -> void:
	var packed := load(PLANT_SCENE) as PackedScene
	scene_instance = packed.instantiate()
	root.add_child(scene_instance)
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	await process_frame

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
