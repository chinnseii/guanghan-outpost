extends SceneTree

const OUT_DIR := "res://docs/screenshots/sprint08_6_acceptance"

const MAIN_SCENE := "res://scenes/main.tscn"
const APPLICATION_SCENE := "res://scenes/application/ApplicationStartScene.tscn"
const TRAINING_START_SCENE := "res://scenes/training/TrainingStartScene.tscn"
const FINAL_ASSESSMENT_SCENE := "res://scenes/training/FinalAssessmentScene.tscn"
const MISSION_NOTICE_SCENE := "res://scenes/training/MissionAssignmentNoticeScene.tscn"
const ARRIVAL_SCENE := "res://scenes/arrival/ArrivalCinematicScene.tscn"
const AIRLOCK_SCENE := "res://scenes/base/BaseAirlockEntryScene.tscn"
const OLD_BASE_SCENE := "res://scenes/base/OldBaseCore_ArtSlice.tscn"
const GREENHOUSE_SCENE := "res://scenes/base/OldGreenhouseScene.tscn"
const WEEK_END_SCENE := "res://scenes/base/WeekRoutineEndScene.tscn"
const PHASE02_SCENE := "res://scenes/base/Phase02PlaceholderScene.tscn"

var scene_instance: Node

func _initialize() -> void:
	print("capture_sprint08_6_acceptance start")
	DisplayServer.window_set_size(Vector2i(1600, 900))
	call_deferred("_run")

func _run() -> void:
	_prepare_output()

	_write_training_progress({})
	_write_application_profile("identity", "待提交", false)
	_write_base_state(_base_state({}))
	await _load_and_wait(MAIN_SCENE, null)
	await _capture("01_main_menu_normal_path.png")

	_write_application_profile("review", "待提交", false)
	await _load_and_wait(APPLICATION_SCENE, null)
	if scene_instance.has_method("_start_review_sequence"):
		scene_instance.call("_start_review_sequence")
	await create_timer(1.25).timeout
	await _capture("02_application_submitted.png")

	_write_application_profile("notice", "已通过资格初审", true)
	await _load_and_wait(APPLICATION_SCENE, null)
	await _capture("03_qualification_review.png")

	_write_application_profile("training_start", "训练序列中", true)
	_write_training_progress({
		"TrainingStarted": true,
		"CurrentTrainingModule": "airlock_procedure",
		"CompletedModules": ["suit_control"],
	})
	await _load_and_wait(TRAINING_START_SCENE, null)
	await _capture("04_training_module_transition.png")

	_write_training_progress({
		"TrainingStarted": true,
		"CurrentTrainingModule": "final_assessment",
		"CompletedModules": ["suit_control", "airlock_procedure", "power_repair", "life_support", "plant_diagnosis"],
		"FinalAssessmentCompleted": true,
	})
	await _load_and_wait(FINAL_ASSESSMENT_SCENE, Vector2(940, 575))
	await _capture("05_training_complete.png")

	_write_training_progress({
		"TrainingStarted": true,
		"CurrentTrainingModule": "mission_assignment",
		"CompletedModules": ["suit_control", "airlock_procedure", "power_repair", "life_support", "plant_diagnosis", "final_assessment"],
		"FinalAssessmentCompleted": true,
	})
	await _load_and_wait(MISSION_NOTICE_SCENE, null)
	await _capture("06_mission_assignment_notice.png")

	_write_training_progress({
		"TrainingStarted": true,
		"FinalAssessmentCompleted": true,
		"MissionAssignmentAccepted": true,
		"OpeningFlowStage": "AwaitingArrivalCinematic",
		"CurrentTrainingModule": "assignment_black_screen",
	})
	await _load_and_wait(ARRIVAL_SCENE, null)
	_set_if_available("observe_triggered", true)
	_set_if_available("dialogue_text", "那里，是地球。\n距离：384,400公里。\n预计通信延迟：1.3秒。")
	_set_if_available("dialogue_alpha", 1.0)
	_set_if_available("entry_prompt_delay", 4.2)
	_set_if_available("hud_alpha", 0.06)
	if scene_instance.has_method("_update_ui"):
		scene_instance.call("_update_ui")
	await create_timer(0.35).timeout
	await _capture("07_lunar_arrival_earth_view.png")

	_write_base_state(_base_state({
		"BaseEntered": false,
		"BasePowerRestored": false,
		"MinimalLifeSupportStable": false,
		"GreenhouseUnlocked": false,
	}))
	await _load_and_wait(AIRLOCK_SCENE, null)
	await create_timer(0.75).timeout
	await _capture("08_old_base_entry.png")

	_write_base_state(_base_state({
		"BaseEntered": true,
		"AIGreetingPlayed": true,
		"BasePowerRestored": true,
		"MinimalLifeSupportStable": true,
		"GreenhouseUnlocked": true,
		"LastPlantDiscovered": true,
		"LastPlantObserved": true,
		"PlantMonitorChecked": true,
		"LastPlantDiagnosed": false,
		"GrowLightRestored": false,
		"PartialWaterCycleRestored": false,
		"LastPlantStable": false,
		"LastPlantStatus": "Critical",
	}))
	await _load_and_wait(GREENHOUSE_SCENE, Vector2(820, 515))
	_set_if_available("message_text", "植物生命信号：Critical。\n恢复幅度：无。\n建议：诊断补光与水循环状态。")
	await _capture("09_last_plant_critical.png")

	_write_base_state(_base_state({
		"BaseEntered": true,
		"AIGreetingPlayed": true,
		"BasePowerRestored": true,
		"MinimalLifeSupportStable": true,
		"GreenhouseUnlocked": true,
		"LastPlantDiscovered": true,
		"LastPlantObserved": true,
		"PlantMonitorChecked": true,
		"LastPlantDiagnosed": true,
		"GrowLightRestored": true,
		"PartialWaterCycleRestored": true,
		"LastPlantStable": true,
		"LastPlantStatus": "Stable",
	}))
	await _load_and_wait(GREENHOUSE_SCENE, Vector2(820, 515))
	_set_if_available("message_text", "植物生命信号：Stable。\n恢复幅度：有限。\n继续观察。")
	await _capture("10_last_plant_stable.png")

	_write_base_state(_day02_state({
		"Day02ReportSent": true,
		"ArchiveEntry_Day02Report": true,
	}))
	await _load_and_wait(OLD_BASE_SCENE, Vector2(1120, 620))
	await _capture("11_day02_report_sent.png")

	_write_base_state(_week_state(3, {}))
	await _load_and_wait(OLD_BASE_SCENE, Vector2(520, 690))
	await _capture("12_day03_week_routine_start.png")

	_write_base_state(_week_state(6, {
		"DailyConsoleChecked": true,
		"DailyPowerChecked": true,
		"DailyLifeSupportChecked": true,
		"DailyPlantChecked": true,
		"DailySpecialChecked": true,
		"DailyRecordUpdated": true,
	}))
	await _load_and_wait(GREENHOUSE_SCENE, Vector2(805, 510))
	_set_if_available("message_text", "植物生命信号出现微弱恢复。\n建议：继续维持补光与水循环。")
	await _capture("13_day06_plant_recovery_signal.png")

	_write_base_state(_week_state(7, {
		"DailyConsoleChecked": true,
		"DailyPowerChecked": true,
		"DailyLifeSupportChecked": true,
		"DailyWaterChecked": true,
		"DailyPlantChecked": true,
		"DailySpecialChecked": true,
		"DailyRecordUpdated": true,
		"DailyInspectionsComplete": true,
		"DailyReportPreviewed": true,
		"DailyReportSent": true,
		"WeekOneReportSent": true,
		"Archive_WeekOne_Report": true,
		"WeekOneCompleted": false,
	}))
	await _load_and_wait(OLD_BASE_SCENE, Vector2(335, 690))
	await _capture("14_day07_weekly_report_sent.png")

	_write_base_state(_week_state(7, {
		"DailyConsoleChecked": true,
		"DailyPowerChecked": true,
		"DailyLifeSupportChecked": true,
		"DailyWaterChecked": true,
		"DailyPlantChecked": true,
		"DailySpecialChecked": true,
		"DailyRecordUpdated": true,
		"DailyInspectionsComplete": true,
		"DailyReportPreviewed": true,
		"DailyReportSent": true,
		"WeekOneReportSent": true,
		"Archive_WeekOne_Report": true,
		"WeekOneCompleted": false,
	}))
	await _load_and_wait(WEEK_END_SCENE, Vector2(760, 570))
	if scene_instance.has_method("_finish_week_day"):
		scene_instance.call("_finish_week_day")
	await create_timer(3.65).timeout
	await _capture("15_first_week_end_text.png")

	_write_base_state(_week_state(7, {
		"DailyReportSent": true,
		"WeekOneReportSent": true,
		"Archive_WeekOne_Report": true,
		"WeekOneCompleted": true,
	}))
	await _load_and_wait(PHASE02_SCENE, null)
	await _capture("16_phase02_placeholder.png")

	print("capture_sprint08_6_acceptance done")
	quit()

func _load_and_wait(scene_path: String, player_position: Variant) -> void:
	if scene_instance != null:
		scene_instance.queue_free()
		await process_frame
	var packed := load(scene_path) as PackedScene
	scene_instance = packed.instantiate()
	root.add_child(scene_instance)
	await process_frame
	await process_frame
	if typeof(player_position) == TYPE_VECTOR2:
		scene_instance.set("player_pos", player_position)
	if scene_instance.has_method("_update_objective"):
		scene_instance.call("_update_objective")
	await create_timer(0.35).timeout
	await process_frame

func _set_if_available(property_name: StringName, value: Variant) -> void:
	if scene_instance == null:
		return
	scene_instance.set(property_name, value)

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

func _write_application_profile(step: String, status: String, submitted: bool) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var data := {
		"PlayerName": "陈圣威",
		"BirthYear": 2000,
		"GenderDisplay": "男",
		"ApplicationId": "GHO-APP-2068-0421",
		"CandidateFileStatus": status,
		"MissionIdentity": "常驻开拓者候选人",
		"EducationBackground": "生命支持工程",
		"AppearancePreset": "标准舱外服",
		"SkinPreset": "预设 A",
		"HairPreset": "短发",
		"HairColorPreset": "黑色",
		"SuitMarking": "GH-01",
		"NameInitials": "C.S.W.",
		"SuitMarkingColor": "琥珀",
		"ApplicationSubmitted": submitted,
		"ApplicationAccepted": submitted,
		"CurrentApplicationStep": step,
		"NextSceneAfterApplication": TRAINING_START_SCENE,
	}
	var file := FileAccess.open("user://saves/application_profile.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _write_training_progress(overrides: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var data := {
		"TrainingStarted": false,
		"CurrentTrainingModule": "start",
		"CompletedModules": [],
		"ModuleScores": {},
		"FinalAssessmentCompleted": false,
		"MissionAssignmentAccepted": false,
		"OpeningFlowStage": "",
		"CurrentSceneAfterTraining": TRAINING_START_SCENE,
	}
	for key: String in overrides.keys():
		data[key] = overrides[key]
	var file := FileAccess.open("user://saves/training_progress.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _write_base_state(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open("user://saves/sprint06_progress.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _base_state(overrides: Dictionary) -> Dictionary:
	var data := {
		"BaseEntered": true,
		"AIGreetingPlayed": true,
		"BasePowerStatus": "Low",
		"LifeSupportStatus": "Minimal",
		"TemperatureStatus": "Low",
		"OxygenStatus": "SafeButLow",
		"GreenhouseAccess": "Locked",
		"LastPlantStatus": "Critical",
		"CentralConsoleChecked": false,
		"PowerPanelChecked": false,
		"PowerPanelRepaired": false,
		"BasePowerRestored": false,
		"LifeSupportConsoleChecked": false,
		"MinimalLifeSupportStable": false,
		"GreenhouseUnlocked": false,
		"LastPlantDiscovered": false,
		"LastPlantObserved": false,
		"PlantMonitorChecked": false,
		"LastPlantDiagnosed": false,
		"GrowLightRestored": false,
		"PartialWaterCycleRestored": false,
		"LastPlantStable": false,
		"Day01Completed": false,
		"Day02Started": false,
		"Day02Completed": false,
		"CurrentDay": 1,
		"DayNumber": 1,
		"WeekOneCompleted": false,
	}
	for key: String in overrides.keys():
		data[key] = overrides[key]
	return data

func _day02_state(overrides: Dictionary) -> Dictionary:
	var data := _base_state({
		"BasePowerStatus": "Basic",
		"LifeSupportStatus": "MinimalStable",
		"TemperatureStatus": "Maintainable",
		"OxygenStatus": "Stable",
		"GreenhouseAccess": "Unlocked",
		"LastPlantStatus": "Stable",
		"CentralConsoleChecked": true,
		"PowerPanelChecked": true,
		"PowerPanelRepaired": true,
		"BasePowerRestored": true,
		"LifeSupportConsoleChecked": true,
		"MinimalLifeSupportStable": true,
		"GreenhouseUnlocked": true,
		"LastPlantDiscovered": true,
		"LastPlantObserved": true,
		"PlantMonitorChecked": true,
		"LastPlantDiagnosed": true,
		"GrowLightRestored": true,
		"PartialWaterCycleRestored": true,
		"LastPlantStable": true,
		"Day01Completed": true,
		"Day02Started": true,
		"Day02ConsoleChecked": true,
		"Day02PowerChecked": true,
		"Day02LifeSupportChecked": true,
		"Day02WaterChecked": true,
		"Day02LastPlantChecked": true,
		"Day02InspectionsComplete": true,
		"Day02ReportPreviewed": true,
		"Day02ReportSent": false,
		"Day02Completed": false,
		"CurrentDay": 2,
		"DayNumber": 2,
	})
	for key: String in overrides.keys():
		data[key] = overrides[key]
	return data

func _week_state(day: int, overrides: Dictionary) -> Dictionary:
	var data := _day02_state({
		"Day02ReportSent": true,
		"Day02Completed": true,
		"CurrentDay": day,
		"DayNumber": day,
		"DayStarted": true,
		"DayCompleted": false,
		"DailyConsoleChecked": false,
		"DailyPowerChecked": false,
		"DailyLifeSupportChecked": false,
		"DailyWaterChecked": false,
		"DailyPlantChecked": false,
		"DailySpecialChecked": false,
		"DailyRecordUpdated": false,
		"DailyInspectionsComplete": false,
		"DailyReportPreviewed": false,
		"DailyReportSent": false,
		"Day03Completed": day > 3,
		"Day04Completed": day > 4,
		"Day05Completed": day > 5,
		"Day06Completed": day > 6,
		"Day07Completed": false,
		"Archive_Day03_Report": day > 3,
		"Archive_Day04_Report": day > 4,
		"Archive_Day05_Report": day > 5,
		"Archive_Day06_Report": day > 6,
		"Archive_WeekOne_Report": false,
		"WeekOneReportSent": false,
		"WeekOneCompleted": false,
	})
	for key: String in overrides.keys():
		data[key] = overrides[key]
	return data
