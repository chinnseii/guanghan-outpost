extends Node
class_name TrainingManager

const SAVE_PATH := "user://saves/training_progress.json"

const START_SCENE := "res://scenes/training/TrainingStartScene.tscn"
const MODULE_01 := "res://scenes/training/Training_01_SuitControl.tscn"
const MODULE_02 := "res://scenes/training/Training_02_AirlockProcedure.tscn"
const MODULE_03 := "res://scenes/training/Training_03_PowerRepair.tscn"
const MODULE_04 := "res://scenes/training/Training_04_LifeSupport.tscn"
const MODULE_05 := "res://scenes/training/Training_05_PlantDiagnosis.tscn"
const FINAL_ASSESSMENT := "res://scenes/training/FinalAssessmentScene.tscn"
const MISSION_NOTICE := "res://scenes/training/MissionAssignmentNoticeScene.tscn"
const BLACK_SCREEN := "res://scenes/training/AssignmentBlackScreenScene.tscn"

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
		"CurrentSceneAfterTraining": START_SCENE,
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
	return data

static func save_progress(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

static func reset_progress() -> void:
	save_progress(default_data())

static func start_training() -> void:
	var data := load_progress()
	data["TrainingStarted"] = true
	data["CurrentTrainingModule"] = "suit_control"
	data["CurrentSceneAfterTraining"] = MODULE_01
	save_progress(data)

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

static func accept_assignment() -> void:
	var data := load_progress()
	data["MissionAssignmentAccepted"] = true
	data["CurrentTrainingModule"] = "assignment_black_screen"
	data["CurrentSceneAfterTraining"] = BLACK_SCREEN
	save_progress(data)

static func continue_scene_path() -> String:
	var data := load_progress()
	if bool(data.get("MissionAssignmentAccepted", false)):
		return BLACK_SCREEN
	if bool(data.get("FinalAssessmentCompleted", false)):
		return MISSION_NOTICE
	if bool(data.get("TrainingStarted", false)):
		return String(data.get("CurrentSceneAfterTraining", START_SCENE))
	return "res://scenes/application/ApplicationStartScene.tscn"

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
