extends SceneTree

const OUT_DIR := "res://docs/screenshots/sprint08_7_2_interaction_diagnosis"
const AIRLOCK_SCENE := "res://scenes/training/Training_02_AirlockProcedure.tscn"
const POWER_SCENE := "res://scenes/training/Training_03_PowerRepair.tscn"
const LIFE_SCENE := "res://scenes/training/Training_04_LifeSupport.tscn"
const OLD_BASE_SCENE := "res://scenes/base/OldBaseCore_ArtSlice.tscn"
const GREENHOUSE_SCENE := "res://scenes/base/OldGreenhouseScene.tscn"

var scene_instance: Node

func _initialize() -> void:
	print("capture_sprint08_7_2_interaction_diagnosis start")
	DisplayServer.window_set_size(Vector2i(1600, 900))
	call_deferred("_run")

func _run() -> void:
	_prepare_output()

	await _load_and_wait(AIRLOCK_SCENE)
	_call_if_available("_close_briefing")
	_set_training_player_position(Vector2(286, 242))
	_call_if_available("_update_room_prompt")
	_call_if_available("_try_interact")
	await create_timer(0.35).timeout
	await _capture("01_airlock_interaction_in_progress.png")
	await create_timer(1.35).timeout
	await _capture("02_airlock_step_completed_feedback.png")

	await _load_and_wait(POWER_SCENE)
	_call_if_available("_close_briefing")
	_set_training_player_position(Vector2(330, 150))
	var module_data_value: Variant = scene_instance.get("module_data")
	if typeof(module_data_value) == TYPE_DICTIONARY:
		var module_data: Dictionary = module_data_value
		var state: Dictionary = module_data.get("state", {}) as Dictionary
		state["HasRepairTool"] = true
		state["PowerPanelInspected"] = true
		scene_instance.set("module_data", module_data)
		scene_instance.set("step_index", 2)
	_call_if_available("_update_hud")
	_call_if_available("_try_interact")
	await create_timer(0.45).timeout
	await _capture("03_power_panel_repair_in_progress.png")
	await create_timer(1.9).timeout
	await _capture("04_power_panel_completed_state.png")

	await _load_and_wait(LIFE_SCENE)
	_call_if_available("_close_briefing")
	_set_training_player_position(Vector2(96, 238))
	_call_if_available("_try_interact")
	await create_timer(0.4).timeout
	await _capture("05_life_support_diagnosis_in_progress.png")

	await _load_old_base_week_report_ready()
	if scene_instance.has_method("_send_week_report"):
		scene_instance.call("_send_week_report")
	await create_timer(0.45).timeout
	await _capture("07_report_transmission_in_progress.png")
	await create_timer(3.4).timeout
	await _capture("08_report_sent_completed_state.png")

	await _load_greenhouse_ready()
	if scene_instance.has_method("_show_plant_diagnosis"):
		scene_instance.call("_show_plant_diagnosis", "water_low")
	await create_timer(0.2).timeout
	await _capture("01_plant_diagnosis_water_low.png")
	scene_instance.call("_show_plant_diagnosis", "light_low")
	await create_timer(0.2).timeout
	await _capture("02_plant_diagnosis_light_low.png")
	scene_instance.call("_show_plant_diagnosis", "temp_high")
	await create_timer(0.2).timeout
	await _capture("03_plant_diagnosis_temp_high.png")
	scene_instance.call("_show_plant_diagnosis", "temp_low")
	await create_timer(0.2).timeout
	await _capture("04_plant_diagnosis_temp_low.png")
	scene_instance.call("_show_plant_diagnosis", "stable")
	await create_timer(0.2).timeout
	await _capture("05_plant_diagnosis_stable.png")
	scene_instance.call("_show_plant_diagnosis", "critical")
	await create_timer(0.2).timeout
	await _capture("06_plant_diagnosis_in_progress.png")
	await _capture("06_player_selects_maintenance_action.png")
	if scene_instance.has_method("_choose_plant_maintenance"):
		scene_instance.call("_choose_plant_maintenance", "调整补光")
	await create_timer(0.25).timeout
	await _capture("07_correct_action_feedback.png")

	await _load_greenhouse_ready()
	scene_instance.call("_show_plant_diagnosis", "water_low")
	await create_timer(0.2).timeout
	scene_instance.call("_choose_plant_maintenance", "降低舱内温度")
	await create_timer(0.25).timeout
	await _capture("08_incorrect_action_feedback.png")

	await _load_greenhouse_ready()
	scene_instance.call("_open_plant_diagnosis_after_feedback", "critical")
	await create_timer(1.55).timeout
	await _capture("09_last_plant_rescue_uses_diagnosis_view.png")

	await _load_greenhouse_ready()
	scene_instance.call("_show_plant_diagnosis", "stable")
	await create_timer(0.2).timeout
	await _capture("10_day06_recovery_uses_stable_visual.png")

	print("capture_sprint08_7_2_interaction_diagnosis done")
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

func _load_old_base_week_report_ready() -> void:
	await _load_and_wait(OLD_BASE_SCENE)
	var state: Dictionary = _base_state()
	state["CurrentDay"] = 7
	state["DayNumber"] = 7
	state["DayStarted"] = true
	state["DailyConsoleChecked"] = true
	state["DailyPowerChecked"] = true
	state["DailyLifeSupportChecked"] = true
	state["DailyPlantChecked"] = true
	state["DailyInspectionsComplete"] = true
	state["DailyReportPreviewed"] = true
	scene_instance.set("state", state)
	scene_instance.set("player_pos", Vector2(1080, 620))
	scene_instance.call("_update_target")
	scene_instance.call("_update_objective")

func _load_greenhouse_ready() -> void:
	await _load_and_wait(GREENHOUSE_SCENE)
	var state: Dictionary = _base_state()
	state["BaseEntered"] = true
	state["BasePowerRestored"] = true
	state["MinimalLifeSupportStable"] = true
	state["GreenhouseUnlocked"] = true
	state["LastPlantDiscovered"] = true
	state["LastPlantObserved"] = true
	state["PlantMonitorChecked"] = true
	scene_instance.set("state", state)
	scene_instance.set("player_pos", Vector2(860, 545))
	scene_instance.call("_update_target")
	scene_instance.call("_update_objective")

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

func _base_state() -> Dictionary:
	return {
		"BaseEntered": true,
		"AIGreetingPlayed": true,
		"BasePowerRestored": true,
		"PowerPanelChecked": true,
		"PowerPanelRepaired": true,
		"MinimalLifeSupportStable": true,
		"GreenhouseUnlocked": true,
		"LastPlantStatus": "Stable",
		"LastPlantStable": true,
		"CurrentDay": 2,
		"DayNumber": 2,
		"DayStarted": false,
		"DayCompleted": false,
		"WeekOneCompleted": false,
	}
