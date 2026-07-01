extends SceneTree

const OUT_DIR := "res://docs/screenshots/sprint08_7_1_training_immersion"
const AIRLOCK_SCENE := "res://scenes/training/Training_02_AirlockProcedure.tscn"
const FINAL_ASSESSMENT_SCENE := "res://scenes/training/FinalAssessmentScene.tscn"
const MISSION_NOTICE_SCENE := "res://scenes/training/MissionAssignmentNoticeScene.tscn"
const TRAINING_SAVE := "user://saves/training_progress.json"

var scene_instance: Node

func _initialize() -> void:
	print("capture_sprint08_7_1_training_immersion start")
	DisplayServer.window_set_size(Vector2i(1600, 900))
	call_deferred("_run")

func _run() -> void:
	_prepare_output()
	_clear_training_progress()

	await _load_and_wait(AIRLOCK_SCENE)
	await _capture("01_training_entry_briefing_modal.png")

	_close_briefing_if_available()
	await create_timer(0.2).timeout
	await _capture("02_training_after_briefing_minimal_hud.png")

	_call_if_available("_toggle_mission_panel")
	await create_timer(0.2).timeout
	await _capture("03_training_task_panel_open_tab.png")

	_call_if_available("_toggle_mission_panel")
	await create_timer(0.2).timeout
	await _capture("04_training_task_panel_closed.png")

	_mark_current_training_complete()
	await create_timer(0.2).timeout
	await _capture("05_training_complete_objective_go_to_exit.png")

	_set_training_player_position(Vector2(688, 390))
	_call_if_available("_update_room_prompt")
	await create_timer(0.2).timeout
	await _capture("06_player_near_training_exit_prompt.png")

	_call_if_available("_set_pause_visible", [true])
	await create_timer(0.2).timeout
	await _capture("07_pause_menu_with_return_to_main.png")

	_write_final_assessment_complete()
	await _load_and_wait(FINAL_ASSESSMENT_SCENE)
	_set_training_player_position(Vector2(688, 390))
	_call_if_available("_update_room_prompt")
	await create_timer(0.2).timeout
	await _capture("08_final_assessment_complete_go_to_assignment.png")

	await _load_and_wait(MISSION_NOTICE_SCENE)
	await _capture("09_mission_assignment_reached_from_exit.png")

	print("capture_sprint08_7_1_training_immersion done")
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

func _close_briefing_if_available() -> void:
	_call_if_available("_close_briefing")

func _mark_current_training_complete() -> void:
	if scene_instance == null:
		return
	scene_instance.set("completed", true)
	var module_data_value: Variant = scene_instance.get("module_data")
	var module_data: Dictionary = {}
	if typeof(module_data_value) == TYPE_DICTIONARY:
		module_data = module_data_value
	var steps: Array = module_data.get("steps", []) as Array
	scene_instance.set("step_index", steps.size())
	_call_if_available("_update_hud")
	_call_if_available("_update_room_prompt")

func _set_training_player_position(pos: Vector2) -> void:
	if scene_instance == null:
		return
	var player: Variant = scene_instance.get("player")
	if player is Control:
		player.position = pos

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

func _clear_training_progress() -> void:
	if FileAccess.file_exists(TRAINING_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TRAINING_SAVE))

func _write_final_assessment_complete() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var data := {
		"TrainingStarted": true,
		"CurrentTrainingModule": "mission_assignment",
		"CompletedTrainingModules": [
			"suit_control",
			"airlock_procedure",
			"power_repair",
			"life_support",
			"plant_diagnosis",
			"final_assessment"
		],
		"SuitControlCompleted": true,
		"AirlockProcedureCompleted": true,
		"PowerRepairCompleted": true,
		"LifeSupportCompleted": true,
		"PlantDiagnosisCompleted": true,
		"FinalAssessmentCompleted": true,
		"MissionAssignmentAccepted": false,
		"CurrentSceneAfterTraining": MISSION_NOTICE_SCENE,
	}
	var file := FileAccess.open(TRAINING_SAVE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
