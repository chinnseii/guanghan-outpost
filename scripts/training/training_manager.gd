extends Node
class_name TrainingManager

const SAVE_PATH := "user://saves/training_progress.json"
const APPLICATION_PROFILE_PATH := "user://saves/application_profile.json"

const START_SCENE := "res://scenes/training/TrainingStartScene.tscn"
const MODULE_01 := "res://scenes/training/Training_01_SuitControl.tscn"
const MODULE_02 := "res://scenes/training/Training_02_AirlockProcedure.tscn"
const MODULE_03 := "res://scenes/training/Training_03_PowerRepair.tscn"
const MODULE_04 := "res://scenes/training/Training_04_LifeSupport.tscn"
const MODULE_05 := "res://scenes/training/Training_05_PlantDiagnosis.tscn"
const FINAL_ASSESSMENT := "res://scenes/training/FinalAssessmentScene.tscn"
const MISSION_NOTICE := "res://scenes/training/MissionAssignmentNoticeScene.tscn"
const BLACK_SCREEN := "res://scenes/training/AssignmentBlackScreenScene.tscn"
const ARRIVAL_CINEMATIC := "res://scenes/arrival/ArrivalCinematicScene.tscn"
const BASE_AIRLOCK := "res://scenes/base/BaseAirlockEntryScene.tscn"
const OLD_BASE_INTERIOR := "res://scenes/base/OldBaseInteriorScene.tscn"
const OLD_GREENHOUSE := "res://scenes/base/OldGreenhouseScene.tscn"
const DAY01_END := "res://scenes/base/Day01EndScene.tscn"
const DAY02_START := "res://scenes/base/Day02StartScene.tscn"
const DAY02_END := "res://scenes/base/Day02EndScene.tscn"
const WEEK_ROUTINE_START := "res://scenes/base/WeekRoutineStartScene.tscn"
const WEEK_ROUTINE_END := "res://scenes/base/WeekRoutineEndScene.tscn"
const PHASE02_PLACEHOLDER := "res://scenes/base/Phase02PlaceholderScene.tscn"
const SPRINT06_SAVE_PATH := "user://saves/sprint06_progress.json"

const MODULE_SCENES := {
	"suit_control": MODULE_01,
	"airlock_procedure": MODULE_02,
	"power_repair": MODULE_03,
	"life_support": MODULE_04,
	"plant_diagnosis": MODULE_05,
	"final_assessment": FINAL_ASSESSMENT,
	"mission_assignment": MISSION_NOTICE,
	"assignment_black_screen": BLACK_SCREEN,
}

static func default_data() -> Dictionary:
	return {
		"TrainingStarted": false,
		"CurrentTrainingModule": "start",
		"SuitControlCompleted": false,
		"AirlockProcedureCompleted": false,
		"PowerRepairCompleted": false,
		"LifeSupportCompleted": false,
		"PlantDiagnosisCompleted": false,
		"CompletedTrainingModules": [],
		"FinalAssessmentCompleted": false,
		"MissionAssignmentAccepted": false,
		"OpeningFlowStage": "",
		"CurrentSceneAfterTraining": START_SCENE,
		"TimeState": {},
		"HealthState": {},
		"BaseStatusState": {},
		"PlantGrowthState": {},
	}

static func load_progress() -> Dictionary:
	var data := default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return data
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return data
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return data
	var saved: Dictionary = parsed
	for key in saved.keys():
		data[key] = saved[key]
	var manager := _time_manager()
	if manager != null and manager.has_method("deserialize") and data.get("TimeState", {}) is Dictionary:
		manager.call("deserialize", data.get("TimeState", {}))
	var health_manager := _health_manager()
	if health_manager != null and health_manager.has_method("deserialize") and data.get("HealthState", {}) is Dictionary:
		health_manager.call("deserialize", data.get("HealthState", {}))
	var base_status_manager := _base_status_manager()
	if base_status_manager != null and base_status_manager.has_method("deserialize") and data.get("BaseStatusState", {}) is Dictionary:
		base_status_manager.call("deserialize", data.get("BaseStatusState", {}))
	var plant_growth_manager := _plant_growth_manager()
	if plant_growth_manager != null and plant_growth_manager.has_method("deserialize") and data.get("PlantGrowthState", {}) is Dictionary:
		plant_growth_manager.call("deserialize", data.get("PlantGrowthState", {}))
	return data

static func save_progress(data: Dictionary) -> void:
	var manager := _time_manager()
	if manager != null and manager.has_method("serialize"):
		data["TimeState"] = manager.call("serialize")
	var health_manager := _health_manager()
	if health_manager != null and health_manager.has_method("serialize"):
		data["HealthState"] = health_manager.call("serialize")
	var base_status_manager := _base_status_manager()
	if base_status_manager != null and base_status_manager.has_method("serialize"):
		data["BaseStatusState"] = base_status_manager.call("serialize")
	var plant_growth_manager := _plant_growth_manager()
	if plant_growth_manager != null and plant_growth_manager.has_method("serialize"):
		data["PlantGrowthState"] = plant_growth_manager.call("serialize")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

static func reset_progress() -> void:
	var manager := _time_manager()
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
	var health_manager := _health_manager()
	if health_manager != null and health_manager.has_method("reset_to_arrival"):
		health_manager.call("reset_to_arrival")
	var base_status_manager := _base_status_manager()
	if base_status_manager != null and base_status_manager.has_method("reset_to_arrival"):
		base_status_manager.call("reset_to_arrival")
	var plant_growth_manager := _plant_growth_manager()
	if plant_growth_manager != null and plant_growth_manager.has_method("reset_to_arrival"):
		plant_growth_manager.call("reset_to_arrival")
	save_progress(default_data())

static func start_training() -> void:
	var data := load_progress()
	data["TrainingStarted"] = true
	data["CurrentTrainingModule"] = "suit_control"
	data["CurrentSceneAfterTraining"] = MODULE_01
	save_progress(data)
	update_candidate_file_status("训练序列中")

static func set_current_module(module_id: String) -> void:
	var data := load_progress()
	data["TrainingStarted"] = true
	data["CurrentTrainingModule"] = module_id
	data["CurrentSceneAfterTraining"] = String(MODULE_SCENES.get(module_id, START_SCENE))
	save_progress(data)

static func mark_module_completed(module_id: String, next_module_id: String) -> void:
	var data := load_progress()
	data["TrainingStarted"] = true
	match module_id:
		"suit_control":
			data["SuitControlCompleted"] = true
		"airlock_procedure":
			data["AirlockProcedureCompleted"] = true
		"power_repair":
			data["PowerRepairCompleted"] = true
		"life_support":
			data["LifeSupportCompleted"] = true
		"plant_diagnosis":
			data["PlantDiagnosisCompleted"] = true
		"final_assessment":
			data["FinalAssessmentCompleted"] = true
	var completed: Array = data.get("CompletedTrainingModules", [])
	if not completed.has(module_id):
		completed.append(module_id)
	data["CompletedTrainingModules"] = completed
	data["CurrentTrainingModule"] = next_module_id
	data["CurrentSceneAfterTraining"] = String(MODULE_SCENES.get(next_module_id, START_SCENE))
	save_progress(data)
	if module_id == "final_assessment":
		update_candidate_file_status("已通过最终考核")

static func accept_assignment(opening_stage := "AssignmentBlackScreen") -> void:
	var data := load_progress()
	var manager := _time_manager()
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
	data["MissionAssignmentAccepted"] = true
	data["OpeningFlowStage"] = opening_stage
	data["CurrentTrainingModule"] = "assignment_black_screen"
	data["CurrentSceneAfterTraining"] = BLACK_SCREEN
	save_progress(data)
	update_candidate_file_status("已接受月面派遣")

static func update_candidate_file_status(status: String) -> void:
	var data: Dictionary = {}
	if FileAccess.file_exists(APPLICATION_PROFILE_PATH):
		var read_file := FileAccess.open(APPLICATION_PROFILE_PATH, FileAccess.READ)
		if read_file != null:
			var parsed: Variant = JSON.parse_string(read_file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed as Dictionary
	if data.is_empty():
		data = {
			"PlayerName": "",
			"ApplicationID": "GHO-APP-2068-0421",
			"CandidateFileStatus": status,
			"MissionIdentity": "常驻开拓者候选人",
		}
	else:
		data["CandidateFileStatus"] = status
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var write_file := FileAccess.open(APPLICATION_PROFILE_PATH, FileAccess.WRITE)
	if write_file != null:
		write_file.store_string(JSON.stringify(data, "\t"))

static func set_opening_flow_stage(opening_stage: String, scene_path: String) -> void:
	var data := load_progress()
	data["MissionAssignmentAccepted"] = true
	data["OpeningFlowStage"] = opening_stage
	data["CurrentSceneAfterTraining"] = scene_path
	save_progress(data)

static func continue_scene_path() -> String:
	var base_scene := _base_continue_scene_path()
	if not base_scene.is_empty():
		return base_scene
	var data := load_progress()
	if bool(data.get("MissionAssignmentAccepted", false)):
		if String(data.get("OpeningFlowStage", "")) == "AwaitingArrivalCinematic":
			return ARRIVAL_CINEMATIC
		return BLACK_SCREEN
	if bool(data.get("FinalAssessmentCompleted", false)):
		return MISSION_NOTICE
	if bool(data.get("TrainingStarted", false)):
		return String(data.get("CurrentSceneAfterTraining", START_SCENE))
	return "res://scenes/application/ApplicationStartScene.tscn"

static func _base_continue_scene_path() -> String:
	if not FileAccess.file_exists(SPRINT06_SAVE_PATH):
		return ""
	var file := FileAccess.open(SPRINT06_SAVE_PATH, FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	var data: Dictionary = parsed as Dictionary
	if bool(data.get("WeekOneCompleted", false)):
		return PHASE02_PLACEHOLDER
	var current_day := int(data.get("CurrentDay", data.get("DayNumber", 2)))
	if current_day >= 3 and current_day <= 7:
		if bool(data.get("DailyReportSent", false)) or bool(data.get("DayCompleted", false)):
			return WEEK_ROUTINE_END
		if bool(data.get("DayStarted", false)):
			return OLD_BASE_INTERIOR
		return WEEK_ROUTINE_START
	if bool(data.get("Day02Completed", false)) or bool(data.get("Day02ReportSent", false)):
		return DAY02_END
	if bool(data.get("Day02Started", false)):
		return OLD_BASE_INTERIOR
	if bool(data.get("Day01Completed", false)):
		return DAY02_START
	if bool(data.get("LastPlantStable", false)):
		return DAY01_END
	if bool(data.get("GreenhouseUnlocked", false)) or bool(data.get("LastPlantDiscovered", false)) or bool(data.get("LastPlantDiagnosed", false)):
		return OLD_GREENHOUSE
	if bool(data.get("BaseEntered", false)):
		return OLD_BASE_INTERIOR
	return ""

static func player_name() -> String:
	var path := "user://saves/application_profile.json"
	if not FileAccess.file_exists(path):
		return "候选人"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "候选人"
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "候选人"
	var value := String((parsed as Dictionary).get("PlayerName", "")).strip_edges()
	return value if not value.is_empty() else "候选人"

static func _time_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TimeManager")

static func _health_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HealthManager")

static func _base_status_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BaseStatusManager")

static func _plant_growth_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PlantGrowthManager")
