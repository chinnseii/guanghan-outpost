extends SceneTree

const OUT_DIR := "res://docs/screenshots/sprint08_hud_safe_area"
const WEEK_ROUTINE_START_SCENE := "res://scenes/base/WeekRoutineStartScene.tscn"
const OLD_BASE_INTERIOR_SCENE := "res://scenes/base/OldBaseInteriorScene.tscn"

var scene_instance: Node

func _initialize() -> void:
	print("capture_sprint08_hud_safe_area start")
	DisplayServer.window_set_size(Vector2i(1600, 900))
	call_deferred("_run")

func _run() -> void:
	_prepare_output()

	_write_state(_week_state({
		"CurrentDay": 3,
		"DayNumber": 3,
		"DayStarted": false,
	}))
	await _load_and_wait(WEEK_ROUTINE_START_SCENE, Vector2(140, 700))
	await _capture("01_day03_start_left_safe.png")

	_write_state(_week_state({
		"CurrentDay": 3,
		"DayNumber": 3,
		"DayStarted": true,
		"DailyConsoleChecked": true,
		"DailyPowerChecked": false,
		"DailyLifeSupportChecked": false,
		"DailyPlantChecked": false,
		"DailyReportSent": false,
	}))
	await _load_and_wait(OLD_BASE_INTERIOR_SCENE, Vector2(140, 730))
	await _capture("02_day03_checklist_no_occlusion.png")

	_write_state(_week_state({
		"CurrentDay": 7,
		"DayNumber": 7,
		"DayStarted": true,
		"DailyConsoleChecked": true,
		"DailyPowerChecked": true,
		"DailyLifeSupportChecked": true,
		"DailyPlantChecked": true,
		"DailyReportPreviewed": true,
		"DailyReportSent": false,
		"WeekOneReportSent": false,
		"WeekOneCompleted": false,
	}))
	await _load_and_wait(OLD_BASE_INTERIOR_SCENE, Vector2(140, 730))
	await _capture("03_day07_weekly_report_no_overlap.png")

	print("capture_sprint08_hud_safe_area done")
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

func _week_state(overrides: Dictionary) -> Dictionary:
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
		"CurrentDay": 3,
		"DayNumber": 3,
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
		"Day03Completed": false,
		"Day04Completed": false,
		"Day05Completed": false,
		"Day06Completed": false,
		"Day07Completed": false,
		"Archive_Day03_Report": false,
		"Archive_Day04_Report": false,
		"Archive_Day05_Report": false,
		"Archive_Day06_Report": false,
		"Archive_WeekOne_Report": false,
		"WeekOneReportSent": false,
		"WeekOneCompleted": false,
	}
	for key in overrides.keys():
		data[key] = overrides[key]
	return data
