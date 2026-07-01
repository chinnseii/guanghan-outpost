extends SceneTree

const OUT_DIR := "res://docs/screenshots/sprint08_5_acceptance"
const OLD_BASE_ART_SCENE := "res://scenes/base/OldBaseCore_ArtSlice.tscn"
const WEEK_ROUTINE_END_SCENE := "res://scenes/base/WeekRoutineEndScene.tscn"

var scene_instance: Node

func _initialize() -> void:
	print("capture_sprint08_5_acceptance start")
	DisplayServer.window_set_size(Vector2i(1600, 900))
	call_deferred("_run")

func _run() -> void:
	_prepare_output()

	_write_state(_week_state(3, {}))
	await _load_and_wait(OLD_BASE_ART_SCENE, Vector2(520, 690))
	await _capture("01_old_base_full_room.png")

	_write_state(_week_state(3, {}))
	await _load_and_wait(OLD_BASE_ART_SCENE, Vector2(780, 420))
	await _capture("02_player_near_central_console.png")

	_write_state(_week_state(3, {"DailyConsoleChecked": true}))
	await _load_and_wait(OLD_BASE_ART_SCENE, Vector2(474, 332))
	await _capture("03_player_near_power_panel.png")

	_write_state(_week_state(3, {"DailyConsoleChecked": true, "DailyPowerChecked": true}))
	await _load_and_wait(OLD_BASE_ART_SCENE, Vector2(1080, 405))
	await _capture("04_player_near_life_support_console.png")

	_write_state(_week_state(4, {"DailyConsoleChecked": true, "DailyWaterChecked": false}))
	await _load_and_wait(OLD_BASE_ART_SCENE, Vector2(1350, 430))
	await _capture("05_player_near_greenhouse_door.png")

	_write_state(_week_state(3, {}))
	await _load_and_wait(OLD_BASE_ART_SCENE, Vector2(780, 420))
	await _capture("06_interaction_focus_state.png")

	_write_state(_week_state(3, {
		"DailyConsoleChecked": true,
		"DailyPowerChecked": true,
		"DailyLifeSupportChecked": true,
		"DailyPlantChecked": true,
		"DailyReportPreviewed": true,
		"DailyReportSent": true,
	}))
	await _load_and_wait(OLD_BASE_ART_SCENE, Vector2(330, 690))
	await _capture("07_completed_checklist_state.png")

	_write_state(_week_state(7, {
		"DailyConsoleChecked": true,
		"DailyPowerChecked": true,
		"DailyLifeSupportChecked": true,
		"DailyPlantChecked": true,
		"DailyInspectionsComplete": true,
		"DailyReportPreviewed": true,
		"DailyReportSent": false,
		"WeekOneReportSent": false,
		"WeekOneCompleted": false,
	}))
	await _load_and_wait(OLD_BASE_ART_SCENE, Vector2(1115, 620))
	await _capture("08_day07_report_flow_still_works.png")

	_write_state(_week_state(7, {
		"DailyConsoleChecked": true,
		"DailyPowerChecked": true,
		"DailyLifeSupportChecked": true,
		"DailyPlantChecked": true,
		"DailyInspectionsComplete": true,
		"DailyReportPreviewed": true,
		"DailyReportSent": true,
		"WeekOneReportSent": true,
		"Archive_WeekOne_Report": true,
		"WeekOneCompleted": false,
	}))
	await _load_and_wait(WEEK_ROUTINE_END_SCENE, Vector2(760, 570))
	scene_instance.call("_finish_week_day")
	await create_timer(3.55).timeout
	await process_frame
	await _capture("09_week_end_black_screen_hud_hidden.png")

	print("capture_sprint08_5_acceptance done")
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
	await create_timer(0.35).timeout
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

func _week_state(day: int, overrides: Dictionary) -> Dictionary:
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
	}
	for key in overrides.keys():
		data[key] = overrides[key]
	return data
