extends SceneTree

const OUT_DIR := "res://docs/screenshots/sprint08_week_completion_evidence"
const OLD_BASE_INTERIOR_SCENE := "res://scenes/base/OldBaseInteriorScene.tscn"
const WEEK_ROUTINE_END_SCENE := "res://scenes/base/WeekRoutineEndScene.tscn"

var scene_instance: Node

func _initialize() -> void:
	print("capture_sprint08_week_completion_evidence start")
	DisplayServer.window_set_size(Vector2i(1600, 900))
	call_deferred("_run")

func _run() -> void:
	_prepare_output()

	_write_state(_day07_state({
		"DailyReportPreviewed": true,
		"DailyReportSent": false,
		"WeekOneReportSent": false,
		"WeekOneCompleted": false,
	}))
	await _load_and_wait(OLD_BASE_INTERIOR_SCENE, Vector2(140, 730))
	await _capture("01_day07_before_weekly_report.png")
	_log_scene_flags("before_report")

	scene_instance.call("_send_week_report")
	await create_timer(4.6).timeout
	if scene_instance.has_method("_update_objective"):
		scene_instance.call("_update_objective")
	await process_frame
	await _capture("02_day07_after_weekly_report_return_rest.png")
	_log_scene_flags("after_report")

	_write_state(_day07_state({
		"DailyReportPreviewed": true,
		"DailyReportSent": true,
		"WeekOneReportSent": true,
		"Archive_WeekOne_Report": true,
		"WeekOneCompleted": false,
	}))
	await _load_and_wait(WEEK_ROUTINE_END_SCENE, Vector2(760, 570))
	await _capture("03_week_routine_end_scene_rest_point.png")
	_log_scene_flags("at_rest_point_before_rest")

	scene_instance.call("_finish_week_day")
	await create_timer(3.55).timeout
	await process_frame
	await _capture("04_after_rest_first_week_end.png")
	_log_scene_flags("after_rest_week_completed")

	await create_timer(1.65).timeout
	await process_frame
	await _capture("05_after_rest_minimum_stable_text.png")
	_log_scene_flags("after_rest_stable_text")

	print("capture_sprint08_week_completion_evidence done")
	quit()

func _load_and_wait(scene_path: String, player_position: Vector2) -> void:
	if scene_instance != null:
		scene_instance.queue_free()
		await process_frame
	var packed := load(scene_path) as PackedScene
	scene_instance = packed.instantiate()
	root.add_child(scene_instance)
	await process_frame
	await process_frame
	scene_instance.set("player_pos", player_position)
	if scene_instance.has_method("_update_objective"):
		scene_instance.call("_update_objective")
	await create_timer(0.25).timeout
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

func _prepare_output() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

func _write_state(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open("user://saves/sprint06_progress.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _log_scene_flags(label: String) -> void:
	var state: Dictionary = scene_instance.get("state")
	print("EVIDENCE ", label,
		" objective=", scene_instance.get("objective_text"),
		" scene_kind=", scene_instance.get("scene_kind"),
		" DailyReportSent=", state.get("DailyReportSent", false),
		" WeekOneReportSent=", state.get("WeekOneReportSent", false),
		" WeekOneCompleted=", state.get("WeekOneCompleted", false),
		" DayCompleted=", state.get("DayCompleted", false))

func _day07_state(overrides: Dictionary) -> Dictionary:
	var data := {
		"BaseEntered": true,
		"AIGreetingPlayed": true,
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
		"Day02ReportSent": true,
		"Day02Completed": true,
		"CurrentDay": 7,
		"DayNumber": 7,
		"DayStarted": true,
		"DayCompleted": false,
		"DailyConsoleChecked": true,
		"DailyPowerChecked": true,
		"DailyLifeSupportChecked": true,
		"DailyWaterChecked": false,
		"DailyPlantChecked": true,
		"DailySpecialChecked": false,
		"DailyRecordUpdated": false,
		"DailyInspectionsComplete": false,
		"DailyReportPreviewed": true,
		"DailyReportSent": false,
		"Day03Completed": true,
		"Day04Completed": true,
		"Day05Completed": true,
		"Day06Completed": true,
		"Day07Completed": false,
		"Archive_Day03_Report": true,
		"Archive_Day04_Report": true,
		"Archive_Day05_Report": true,
		"Archive_Day06_Report": true,
		"Archive_WeekOne_Report": false,
		"WeekOneReportSent": false,
		"WeekOneCompleted": false,
	}
	for key in overrides.keys():
		data[key] = overrides[key]
	return data
