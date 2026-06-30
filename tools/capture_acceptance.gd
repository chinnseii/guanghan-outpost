extends SceneTree

const OUT_DIR := "res://docs/screenshots/sprint07_acceptance"
const BASE_AIRLOCK_SCENE := "res://scenes/base/BaseAirlockEntryScene.tscn"
const OLD_BASE_INTERIOR_SCENE := "res://scenes/base/OldBaseInteriorScene.tscn"
const OLD_GREENHOUSE_SCENE := "res://scenes/base/OldGreenhouseScene.tscn"
const DAY01_END_SCENE := "res://scenes/base/Day01EndScene.tscn"
const DAY02_START_SCENE := "res://scenes/base/Day02StartScene.tscn"
const DAY02_END_SCENE := "res://scenes/base/Day02EndScene.tscn"

var scene_instance: Node

func _initialize() -> void:
	print("capture_acceptance start")
	DisplayServer.window_set_size(Vector2i(1600, 900))
	call_deferred("_run")

func _run() -> void:
	_prepare_output()
	_write_sprint06_state(_day02_base_state({}))
	await _load_and_wait(DAY02_START_SCENE)
	await create_timer(1.4).timeout
	await _capture("01_day02_start.png")

	_write_sprint06_state(_day02_base_state({
		"Day02Started": true,
	}))
	await _load_and_wait(OLD_BASE_INTERIOR_SCENE)
	await _capture("02_day02_old_base_checklist.png")

	_write_sprint06_state(_day02_base_state({
		"Day02Started": true,
		"Day02ConsoleChecked": true,
		"Day02PowerChecked": true,
		"Day02LifeSupportChecked": true,
	}))
	await _load_and_wait(OLD_GREENHOUSE_SCENE)
	await _capture("03_day02_greenhouse_inspection.png")

	_write_sprint06_state(_day02_base_state({
		"Day02Started": true,
		"Day02ConsoleChecked": true,
		"Day02PowerChecked": true,
		"Day02LifeSupportChecked": true,
		"Day02WaterChecked": true,
		"Day02LastPlantChecked": true,
		"Day02InspectionsComplete": true,
	}))
	await _load_and_wait(OLD_BASE_INTERIOR_SCENE)
	await _capture("04_day02_report_ready.png")

	_write_sprint06_state(_day02_base_state({
		"Day02Started": true,
		"Day02ConsoleChecked": true,
		"Day02PowerChecked": true,
		"Day02LifeSupportChecked": true,
		"Day02WaterChecked": true,
		"Day02LastPlantChecked": true,
		"Day02InspectionsComplete": true,
		"Day02ReportPreviewed": true,
		"Day02ReportSent": true,
	}))
	await _load_and_wait(DAY02_END_SCENE)
	await _capture("05_day02_end_room.png")

	print("capture_acceptance done")
	quit()

func _load_and_wait(scene_path: String) -> void:
	if scene_instance != null:
		scene_instance.queue_free()
		await process_frame
	var packed := load(scene_path)
	scene_instance = packed.instantiate()
	root.add_child(scene_instance)
	await process_frame
	await process_frame
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

func _write_sprint06_state(overrides: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var data := {
		"BaseEntered": false,
		"AIGreetingPlayed": false,
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
		"DayNumber": 1,
		"Day02Started": false,
		"Day02ConsoleChecked": false,
		"Day02PowerChecked": false,
		"Day02LifeSupportChecked": false,
		"Day02WaterChecked": false,
		"Day02LastPlantChecked": false,
		"Day02InspectionsComplete": false,
		"Day02ReportPreviewed": false,
		"Day02ReportSent": false,
		"ArchiveEntry_Day02Report": false,
		"Day02Completed": false,
	}
	for key in overrides.keys():
		data[key] = overrides[key]
	var file := FileAccess.open("user://saves/sprint06_progress.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _day02_base_state(overrides: Dictionary) -> Dictionary:
	var data := {
		"BaseEntered": true,
		"AIGreetingPlayed": true,
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
		"LastPlantStatus": "Stable",
		"Day01Completed": true,
		"DayNumber": 2,
	}
	for key in overrides.keys():
		data[key] = overrides[key]
	return data
