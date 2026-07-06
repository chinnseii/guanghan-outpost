extends SceneTree

const OUT_DIR := "res://docs/screenshots/layout_polish_review"
const AIRLOCK_SCENE := "res://scenes/training/Training_02_AirlockProcedure.tscn"
const FINAL_SCENE := "res://scenes/training/FinalAssessmentScene.tscn"
const MISSION_NOTICE := "res://scenes/training/MissionAssignmentNoticeScene.tscn"

var scene_instance: Node

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 900))
	call_deferred("_run")

func _run() -> void:
	_prepare_output()

	await _load_and_wait(FINAL_SCENE)
	_call_if_available("_close_briefing")
	scene_instance.set("completed", false)
	scene_instance.set("step_index", 0)
	var final_player: Variant = scene_instance.get("player")
	if final_player is Control:
		(final_player as Control).position = Vector2(610, 476)
	_call_if_available("_update_hud")
	_call_if_available("_update_room_prompt")
	await _capture("01_final_assessment_relayout.png")

	if scene_instance.has_method("_show_diagnosis_options"):
		scene_instance.call("_show_diagnosis_options", ["缺水", "光照不足", "根区温度异常"], "光照不足")
	await create_timer(0.2).timeout
	await _capture("02_training_plant_detail_popup.png")

	await _load_and_wait(AIRLOCK_SCENE)
	_call_if_available("_close_briefing")
	var airlock_state: Dictionary = (scene_instance.get("module_data") as Dictionary).get("state", {})
	airlock_state["PressureStable"] = true
	airlock_state["OuterDoorOpen"] = false
	airlock_state["Module02Completed"] = true
	var module_data: Dictionary = scene_instance.get("module_data")
	module_data["state"] = airlock_state
	scene_instance.set("module_data", module_data)
	scene_instance.set("completed", true)
	var player: Variant = scene_instance.get("player")
	if player is Control:
		(player as Control).position = Vector2(560, 272)
	_call_if_available("_update_hud")
	_call_if_available("_update_room_prompt")
	await _capture("03_airlock_after_exterior_locked.png")

	_write_training_progress()
	await _load_and_wait(MISSION_NOTICE)
	await _capture("04_mission_assignment_notice_relayout.png")

	print("capture_layout_polish_review done")
	quit()

func _load_and_wait(scene_path: String) -> void:
	if scene_instance != null:
		scene_instance.queue_free()
		await process_frame
	var packed := load(scene_path) as PackedScene
	scene_instance = packed.instantiate()
	root.add_child(scene_instance)
	await process_frame
	await process_frame
	await create_timer(0.35).timeout

func _call_if_available(method_name: StringName, args: Array = []) -> void:
	if scene_instance != null and scene_instance.has_method(method_name):
		scene_instance.callv(method_name, args)

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

func _prepare_output() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

func _write_training_progress() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var data := {
		"TrainingStarted": true,
		"FinalAssessmentCompleted": true,
		"CurrentModule": "mission_assignment",
		"CompletedModules": ["suit_control", "airlock_procedure", "power_repair", "life_support", "plant_diagnosis", "final_assessment"],
	}
	var file := FileAccess.open("user://saves/training_progress.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
