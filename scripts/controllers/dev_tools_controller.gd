extends Node

## DevToolsController (P4-02): owns the local-only Dev menu and all `_debug_*` actions
## extracted from main.gd. Dev-only: never part of the formal player flow. Created and
## held by main.gd, which injects itself as `_host` (for logging / main-menu refresh /
## the few shared formal callbacks that must stay in main) and the UI parent for the panel.
## It reaches formal systems only through `/root/*Manager` autoload lookups (the debug tools
## inherently operate on the live autoloads). It owns NO canonical game/save/training state.

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")
const CharacterAppearanceCatalogScript := preload("res://scripts/data/character_appearance_catalog.gd")

var _appearance_cycle_index := 0

var _host: Node = null
var _menu_parent: Node = null
var _panel: PanelContainer = null
var _menu_visible := false
var _dev_box: VBoxContainer = null
var _dev_groups: Dictionary = {}

func setup(host: Node, menu_parent: Node) -> void:
	_host = host
	_menu_parent = menu_parent

## Forwarder so the moved _debug_* bodies keep calling add_log() unchanged.
func add_log(text: String) -> void:
	if _host != null and _host.has_method("add_log"):
		_host.add_log(text)

## Forwarder for the few dev buttons that refresh the main menu.
func _refresh_main_menu() -> void:
	if _host != null and _host.has_method("_refresh_main_menu"):
		_host.call("_refresh_main_menu")

func toggle_menu() -> void:
	set_menu_visible(not _menu_visible)

func set_menu_visible(value: bool) -> void:
	_menu_visible = value
	if _panel != null:
		_panel.visible = value

## Route a dev button into a collapsible section chosen by its label prefix,
## so the (100+) dev entries are grouped and foldable instead of one long list
## that runs off-screen. Sections are created in first-appearance order.
func _dev_add(button: Button) -> void:
	if _dev_box == null:
		return
	_dev_group_content(_dev_group_name_for(button.text)).add_child(button)

func _dev_group_name_for(label: String) -> String:
	var prefix := label
	var colon := label.find(":")
	if colon >= 0:
		prefix = label.substr(0, colon).strip_edges()
	match prefix:
		"Dev Only":
			return "场景跳转 / Scenes"
		"Time Debug":
			return "时间 / Time"
		"Health Debug", "Health Action":
			return "健康 / Health"
		"Base Debug":
			return "基地状态 / Base"
		"Air Debug":
			return "空气 / Air"
		"Power Debug":
			return "电力 / Power"
		"Water Debug":
			return "水 / Water"
		"Plant Debug":
			return "植物 / Plant"
		"Inventory Debug":
			return "物品 / Inventory"
		"Backpack Debug", "Storage Debug", "Backpack/Storage Debug":
			return "背包·仓库 / Backpack & Storage"
		"Supply Debug":
			return "补给 / Supply"
	return prefix

func _dev_group_content(group_name: String) -> VBoxContainer:
	if _dev_groups.has(group_name):
		return _dev_groups[group_name]
	var header := Button.new()
	header.text = "▶ " + group_name
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_theme_font_size_override("font_size", 15)
	_dev_box.add_child(header)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	content.visible = false
	_dev_box.add_child(content)
	header.pressed.connect(func():
		content.visible = not content.visible
		header.text = ("▼ " if content.visible else "▶ ") + group_name
	)
	_dev_groups[group_name] = content
	return content

func build_menu() -> void:
	var panel := PanelContainer.new()
	panel.name = "DevMenu"
	panel.visible = false
	panel.position = Vector2(1010, 96)
	_menu_parent.add_child(panel)
	_panel = panel
	var outer := VBoxContainer.new()
	outer.name = "Outer"
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)
	var title := Label.new()
	title.text = "开发菜单 / DEV MENU"
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color("#eaf4ff")
	outer.add_child(title)
	var note := Label.new()
	note.text = "仅用于本地测试。F12 显示/隐藏。列表可滚动。"
	note.modulate = Color("#9fb4c4")
	outer.add_child(note)
	# The dev entries outgrew a fixed panel and the bottom items fell off the
	# screen (unselectable). Put the button list in a height-capped, vertically
	# scrollable container so any number of entries stays reachable.
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.custom_minimum_size = Vector2(410, 700)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	_dev_box = box
	_dev_groups = {}
	_dev_add(_make_dev_button("Dev Only: Reset Demo Progress", Callable(_host, "_reset_demo_progress_from_dev")))
	_dev_add(_make_dev_button("Dev Only: Start Survival Sandbox", Callable(_host, "_start_new_game")))
	_dev_add(_make_dev_button("Dev Only: Arrival Cinematic", func(): get_tree().change_scene_to_file("res://scenes/arrival/ArrivalCinematicScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Arrival Landing", func(): get_tree().change_scene_to_file("res://scenes/arrival/ArrivalLandingScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Lunar Surface (EVA seed)", func(): get_tree().change_scene_to_file("res://scenes/surface/LunarSurfaceScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Base Airlock Entry", func(): get_tree().change_scene_to_file("res://scenes/base/BaseAirlockEntryScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Old Base Interior", func(): get_tree().change_scene_to_file("res://scenes/base/OldBaseInteriorScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Old Base Art Slice", func(): get_tree().change_scene_to_file("res://scenes/base/OldBaseCore_ArtSlice.tscn")))
	_dev_add(_make_dev_button("Dev Only: Old Greenhouse", func(): get_tree().change_scene_to_file("res://scenes/base/OldGreenhouseScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Day 01 End", func(): get_tree().change_scene_to_file("res://scenes/base/Day01EndScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Day 02 Start", func(): get_tree().change_scene_to_file("res://scenes/base/Day02StartScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Day 02 End", func(): get_tree().change_scene_to_file("res://scenes/base/Day02EndScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Week Routine Start", func(): get_tree().change_scene_to_file("res://scenes/base/WeekRoutineStartScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Week Routine End", func(): get_tree().change_scene_to_file("res://scenes/base/WeekRoutineEndScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Day 07 Report Test", Callable(_host, "_start_day07_report_test")))
	_dev_add(_make_dev_button("Dev Only: Solar Array Exterior", func(): get_tree().change_scene_to_file("res://scenes/base/SolarArrayExteriorScene.tscn")))
	_dev_add(_make_dev_button("Time Debug: +15 分钟", func(): _debug_advance_time(15, "debug_plus_15")))
	_dev_add(_make_dev_button("Time Debug: +1 小时", func(): _debug_advance_time(60, "debug_plus_1h")))
	_dev_add(_make_dev_button("Time Debug: +6 小时", func(): _debug_advance_time(360, "debug_plus_6h")))
	_dev_add(_make_dev_button("Time Debug: 跳到月昼", _debug_jump_to_daylight))
	_dev_add(_make_dev_button("Time Debug: 跳到月夜", _debug_jump_to_night))
	_dev_add(_make_dev_button("Time Debug: 重置 Day 01", Callable(_host, "_debug_reset_time")))
	_dev_add(_make_dev_button("Health Debug: Energy -20", func(): _debug_adjust_health("energy", -20.0)))
	_dev_add(_make_dev_button("Health Debug: Energy +20", func(): _debug_adjust_health("energy", 20.0)))
	_dev_add(_make_dev_button("Health Debug: Fullness -20", func(): _debug_adjust_health("fullness", -20.0)))
	_dev_add(_make_dev_button("Health Debug: Fullness +20", func(): _debug_adjust_health("fullness", 20.0)))
	_dev_add(_make_dev_button("Health Debug: Nutrition -20", func(): _debug_adjust_health("nutrition", -20.0)))
	_dev_add(_make_dev_button("Health Debug: Nutrition +20", func(): _debug_adjust_health("nutrition", 20.0)))
	_dev_add(_make_dev_button("Health Debug: Morale -20", func(): _debug_adjust_health("morale", -20.0)))
	_dev_add(_make_dev_button("Health Debug: Morale +20", func(): _debug_adjust_health("morale", 20.0)))
	_dev_add(_make_dev_button("Health Debug: Reset Healthy", _debug_reset_health))
	_dev_add(_make_dev_button("Health Debug: Set Danger", _debug_set_health_danger))
	_dev_add(_make_dev_button("Health Action: Sleep", func(): _debug_health_action("sleep_standard")))
	_dev_add(_make_dev_button("Health Action: Eat", func(): _debug_health_action("eat")))
	_dev_add(_make_dev_button("Health Action: Nutrition Drink", func(): _debug_health_action("nutrition_drink")))
	_dev_add(_make_dev_button("Health Action: Short Entertainment", func(): _debug_health_action("entertainment_short")))
	_dev_add(_make_dev_button("Health Action: Light Repair", func(): _debug_health_action("repair_light")))
	_dev_add(_make_dev_button("Health Action: Short Explore", func(): _debug_health_action("explore_short")))
	_dev_add(_make_dev_button("Base Debug: Pressure -10", func(): _debug_adjust_base_status("pressure", -10.0)))
	_dev_add(_make_dev_button("Base Debug: Pressure +10", func(): _debug_adjust_base_status("pressure", 10.0)))
	_dev_add(_make_dev_button("Base Debug: Temperature -2", func(): _debug_adjust_base_status("temperature", -2.0)))
	_dev_add(_make_dev_button("Base Debug: Temperature +2", func(): _debug_adjust_base_status("temperature", 2.0)))
	_dev_add(_make_dev_button("Base Debug: Power System Critical/Basic/Stable", func(): _debug_cycle_base_system("power_system_status")))
	_dev_add(_make_dev_button("Base Debug: Thermal Control Critical/Basic/Stable", func(): _debug_cycle_base_system("thermal_control_status")))
	_dev_add(_make_dev_button("Base Debug: Seal Critical/Basic/Stable", func(): _debug_cycle_base_system("seal_status")))
	_dev_add(_make_dev_button("Base Debug: Reset to Day 01", _debug_reset_base_status))
	_dev_add(_make_dev_button("Base Debug: Set Minimum Stable", _debug_set_base_status_minimum_stable))
	_dev_add(_make_dev_button("Air Debug: O2 -2", func(): _debug_adjust_air("o2_percent", -2.0)))
	_dev_add(_make_dev_button("Air Debug: O2 +2", func(): _debug_adjust_air("o2_percent", 2.0)))
	_dev_add(_make_dev_button("Air Debug: CO2 -0.2", func(): _debug_adjust_air("co2_percent", -0.2)))
	_dev_add(_make_dev_button("Air Debug: CO2 +0.2", func(): _debug_adjust_air("co2_percent", 0.2)))
	_dev_add(_make_dev_button("Air Debug: Inert Reserve -10", func(): _debug_adjust_air("inert_gas_reserve", -10.0)))
	_dev_add(_make_dev_button("Air Debug: Inert Reserve +10", func(): _debug_adjust_air("inert_gas_reserve", 10.0)))
	_dev_add(_make_dev_button("Air Debug: Oxygen Generator Critical/Basic/Stable", func(): _debug_cycle_air_system("oxygen_generator_status")))
	_dev_add(_make_dev_button("Air Debug: CO2 Filter Critical/Basic/Stable", func(): _debug_cycle_air_system("co2_filter_status")))
	_dev_add(_make_dev_button("Air Debug: Air Circulation Critical/Basic/Stable", func(): _debug_cycle_air_system("air_circulation_status")))
	_dev_add(_make_dev_button("Air Debug: Cycle Supply Target", _debug_cycle_air_supply_target))
	_dev_add(_make_dev_button("Air Debug: Reset to Day 01", _debug_reset_air_system))
	_dev_add(_make_dev_button("Air Debug: Set Minimum Stable", _debug_set_air_minimum_stable))
	_dev_add(_make_dev_button("Power Debug: Energy -20", func(): _debug_adjust_power_energy(-20.0)))
	_dev_add(_make_dev_button("Power Debug: Energy +20", func(): _debug_adjust_power_energy(20.0)))
	_dev_add(_make_dev_button("Power Debug: Add Solar Panel", _debug_add_solar_panel))
	_dev_add(_make_dev_button("Power Debug: Add Battery Module", _debug_add_battery_module))
	_dev_add(_make_dev_button("Power Debug: Cycle Solar Array Critical/Basic/Stable", _debug_cycle_solar_array_status))
	_dev_add(_make_dev_button("Power Debug: Cycle Storage Efficiency Tech", _debug_cycle_storage_efficiency))
	_dev_add(_make_dev_button("Power Debug: Cycle Charging Efficiency Tech", _debug_cycle_charging_efficiency))
	_dev_add(_make_dev_button("Power Debug: Mode - Extreme Saving", func(): _debug_set_power_mode("extreme_saving")))
	_dev_add(_make_dev_button("Power Debug: Mode - Standard", func(): _debug_set_power_mode("standard")))
	_dev_add(_make_dev_button("Power Debug: Mode - Standard + Night Light 2", func(): _debug_set_power_mode("standard_night_light")))
	_dev_add(_make_dev_button("Power Debug: Mode - High Load Greenhouse", func(): _debug_set_power_mode("high_load_greenhouse")))
	_dev_add(_make_dev_button("Power Debug: Reset to Day 01", _debug_reset_power_system))
	_dev_add(_make_dev_button("Power Debug: Set Minimum Stable", _debug_set_power_minimum_stable))
	_dev_add(_make_dev_button("Water Debug: Water -10", func(): _debug_adjust_water(-10.0)))
	_dev_add(_make_dev_button("Water Debug: Water +10", func(): _debug_adjust_water(10.0)))
	_dev_add(_make_dev_button("Water Debug: Ice -10", func(): _debug_adjust_ice(-10.0)))
	_dev_add(_make_dev_button("Water Debug: Ice +10", func(): _debug_adjust_ice(10.0)))
	_dev_add(_make_dev_button("Water Debug: Add Water Tank Module", _debug_add_water_tank_module))
	_dev_add(_make_dev_button("Water Debug: Add Ice Storage Module", _debug_add_ice_storage_module))
	_dev_add(_make_dev_button("Water Debug: Cycle Recycling Level 0-4", _debug_cycle_water_recycling_level))
	_dev_add(_make_dev_button("Water Debug: Process 20 Ice", _debug_process_ice_batch))
	_dev_add(_make_dev_button("Water Debug: Process All Ice", _debug_process_all_ice))
	_dev_add(_make_dev_button("Water Debug: Reset to Day 01", _debug_reset_water_system))
	_dev_add(_make_dev_button("Water Debug: Set Minimum Stable", _debug_set_water_minimum_stable))
	_dev_add(_make_dev_button("Plant Debug: Sow Lettuce", func(): _debug_sow_plant("lettuce")))
	_dev_add(_make_dev_button("Plant Debug: Sow Potato", func(): _debug_sow_plant("potato")))
	_dev_add(_make_dev_button("Plant Debug: Sow Wheat", func(): _debug_sow_plant("wheat")))
	_dev_add(_make_dev_button("Plant Debug: Sow Tomato", func(): _debug_sow_plant("tomato")))
	_dev_add(_make_dev_button("Plant Debug: Sow Soybean", func(): _debug_sow_plant("soybean")))
	_dev_add(_make_dev_button("Plant Debug: Advance Growth +1 Day", func(): _debug_advance_time(1440, "debug_plant_plus_1d")))
	_dev_add(_make_dev_button("Plant Debug: Advance Growth +3 Days", func(): _debug_advance_time(4320, "debug_plant_plus_3d")))
	_dev_add(_make_dev_button("Plant Debug: Cycle Water Level 0-4", _debug_cycle_plant_water_level))
	_dev_add(_make_dev_button("Plant Debug: Cycle Greenhouse Light Level 0-4", _debug_cycle_plant_light_level))
	_dev_add(_make_dev_button("Plant Debug: Force Mature Current Crop", _debug_force_mature_plant))
	_dev_add(_make_dev_button("Plant Debug: Harvest Current Crop", _debug_harvest_plant))
	_dev_add(_make_dev_button("Plant Debug: Clear Greenhouse Crops", _debug_clear_plants))
	_dev_add(_make_dev_button("Inventory Debug: Add Sample Foods", _debug_add_sample_foods))
	_dev_add(_make_dev_button("Inventory Debug: Add Sample Seeds", _debug_add_sample_seeds))
	_dev_add(_make_dev_button("Inventory Debug: Add Sample Consumables", _debug_add_sample_consumables))
	_dev_add(_make_dev_button("Inventory Debug: Add Sample Materials", _debug_add_sample_materials))
	_dev_add(_make_dev_button("Inventory Debug: Add Durable Drill", _debug_add_durable_drill))
	_dev_add(_make_dev_button("Inventory Debug: Eat Lettuce", _debug_eat_lettuce))
	_dev_add(_make_dev_button("Inventory Debug: Eat Nutrition Pack", _debug_eat_nutrition_pack))
	_dev_add(_make_dev_button("Inventory Debug: Use Last Durable Item", _debug_use_last_durable_item))
	_dev_add(_make_dev_button("Inventory Debug: Reset to Day 01", _debug_reset_inventory))
	_dev_add(_make_dev_button("Backpack Debug: Add Materials + Food", _debug_backpack_add_samples))
	_dev_add(_make_dev_button("Backpack Debug: Deposit All to Storage", _debug_backpack_deposit_all))
	_dev_add(_make_dev_button("Backpack Debug: Add Ice + Deposit to Water", _debug_backpack_ice_to_water))
	_dev_add(_make_dev_button("Storage Debug: Add Foods + Materials", _debug_storage_add_samples))
	_dev_add(_make_dev_button("Storage Debug: Eat First Food", _debug_storage_eat_first_food))
	_dev_add(_make_dev_button("Backpack/Storage Debug: Reset", _debug_reset_backpack_storage))
	_dev_add(_make_dev_button("Supply Debug: Show Status", _debug_supply_status))
	_dev_add(_make_dev_button("Supply Debug: Draft Starter Order", _debug_supply_draft_starter))
	_dev_add(_make_dev_button("Supply Debug: Confirm Order", _debug_supply_confirm))
	_dev_add(_make_dev_button("Supply Debug: Jump Deadline", _debug_supply_jump_deadline))
	_dev_add(_make_dev_button("Supply Debug: Jump Arrival", _debug_supply_jump_arrival))
	_dev_add(_make_dev_button("Supply Debug: Reset", _debug_supply_reset))
	_dev_add(_make_dev_button("Repair Debug: Show Status", _debug_repair_status))
	_dev_add(_make_dev_button("Repair Debug: Seed Materials", _debug_repair_seed_materials))
	_dev_add(_make_dev_button("Repair Debug: Add Sample Faults", _debug_repair_add_sample_faults))
	_dev_add(_make_dev_button("Repair Debug: Diagnose First", _debug_repair_diagnose_first))
	_dev_add(_make_dev_button("Repair Debug: Attempt First Correct", _debug_repair_attempt_first_correct))
	_dev_add(_make_dev_button("Repair Debug: Attempt First Wrong", _debug_repair_attempt_first_wrong))
	_dev_add(_make_dev_button("Repair Debug: Reset", _debug_repair_reset))
	_dev_add(_make_dev_button("Dev Only: Training Start", func(): get_tree().change_scene_to_file("res://scenes/training/TrainingStartScene.tscn")))
	_dev_add(_make_dev_button("Dev Only: Training Module 01", func():
		TrainingManagerScript.dev_force_unlock_up_to("suit_control")
		TrainingManagerScript.set_current_module("suit_control")
		get_tree().change_scene_to_file(TrainingManagerScript.TRAINING_BASE_MAP)
	))
	_dev_add(_make_dev_button("Dev Only: Training Module 02", func():
		TrainingManagerScript.dev_force_unlock_up_to("airlock_procedure")
		TrainingManagerScript.set_current_module("airlock_procedure")
		get_tree().change_scene_to_file(TrainingManagerScript.TRAINING_BASE_MAP)
	))
	_dev_add(_make_dev_button("Dev Only: Training Module 03", func():
		TrainingManagerScript.set_current_module("power_repair")
		get_tree().change_scene_to_file(TrainingManagerScript.MODULE_03)
	))
	_dev_add(_make_dev_button("Dev Only: Training Module 04", func():
		TrainingManagerScript.dev_force_unlock_up_to("power_distribution")
		TrainingManagerScript.set_current_module("power_distribution")
		get_tree().change_scene_to_file(TrainingManagerScript.TRAINING_BASE_MAP)
	))
	_dev_add(_make_dev_button("Dev Only: Training Module 05", func():
		TrainingManagerScript.dev_force_unlock_up_to("life_support")
		TrainingManagerScript.set_current_module("life_support")
		get_tree().change_scene_to_file(TrainingManagerScript.TRAINING_BASE_MAP)
	))
	_dev_add(_make_dev_button("Dev Only: Training Module 06", func():
		TrainingManagerScript.dev_force_unlock_up_to("plant_diagnosis")
		TrainingManagerScript.set_current_module("plant_diagnosis")
		get_tree().change_scene_to_file(TrainingManagerScript.TRAINING_BASE_MAP)
	))
	_dev_add(_make_dev_button("Dev Only: Training Base Map (Hub)", func():
		TrainingManagerScript.set_current_module("suit_control")
		get_tree().change_scene_to_file(TrainingManagerScript.TRAINING_BASE_MAP)
	))
	_dev_add(_make_dev_button("Dev Only: Final Assessment", func():
		TrainingManagerScript.set_current_module("final_assessment")
		get_tree().change_scene_to_file("res://scenes/training/FinalAssessmentScene.tscn")
	))
	_dev_add(_make_dev_button("Dev Only: Mission Assignment Notice", func():
		TrainingManagerScript.mark_module_completed("final_assessment", "mission_assignment")
		get_tree().change_scene_to_file("res://scenes/training/MissionAssignmentNoticeScene.tscn")
	))
	_dev_add(_make_dev_button("Dev Only: Reset Training Progress", func():
		TrainingManagerScript.reset_progress()
		add_log("Training progress reset.")
		_refresh_main_menu()
	))
	_dev_add(_make_dev_button("Training Time Debug: Show Status", _debug_training_time_status))
	_dev_add(_make_dev_button("Training Time Debug: Start (480 min)", _debug_training_time_start))
	_dev_add(_make_dev_button("Training Time Debug: Advance +30", func(): _debug_training_time_advance(30)))
	_dev_add(_make_dev_button("Training Time Debug: Advance +360 (Sleep)", func(): _debug_training_time_advance(360)))
	_dev_add(_make_dev_button("Training Time Debug: Pause", _debug_training_time_pause))
	_dev_add(_make_dev_button("Training Time Debug: Resume", _debug_training_time_resume))
	_dev_add(_make_dev_button("Training Time Debug: Force Timeout", _debug_training_time_force_timeout))
	_dev_add(_make_dev_button("Suit Debug: Wear Suit", _debug_suit_wear))
	_dev_add(_make_dev_button("Suit Debug: Remove to Service Station", _debug_suit_remove))
	_dev_add(_make_dev_button("Suit Debug: Simulate EVA Action (60 min)", func(): _debug_suit_simulate_eva(60, "eva_normal")))
	_dev_add(_make_dev_button("Suit Debug: Simulate Heavy EVA (60 min)", func(): _debug_suit_simulate_eva(60, "eva_heavy")))
	_dev_add(_make_dev_button("Suit Debug: Empty Oxygen/Power", _debug_suit_empty_reserves))
	_dev_add(_make_dev_button("Suit Debug: Service Suit (Full)", _debug_suit_service_full))
	_dev_add(_make_dev_button("Suit Debug: Upgrade Speed", _debug_suit_upgrade))
	_dev_add(_make_dev_button("Suit Debug: Show Status", _debug_suit_status))
	_dev_add(_make_dev_button("Suit Debug: Reset", _debug_suit_reset))
	_dev_add(_make_dev_button("Movement Debug: Show Status", _debug_movement_status))
	_dev_add(_make_dev_button("Movement Debug: Simulate 10 Tiles (indoor)", func(): _debug_movement_simulate(10, "indoor", "mission")))
	_dev_add(_make_dev_button("Movement Debug: Simulate 30 Tiles (lunar_flat)", func(): _debug_movement_simulate(30, "lunar_flat", "mission")))
	_dev_add(_make_dev_button("Movement Debug: Simulate 30 Tiles (lunar_rough)", func(): _debug_movement_simulate(30, "lunar_rough", "mission")))
	_dev_add(_make_dev_button("Movement Debug: Reset", _debug_movement_reset))
	_dev_add(_make_dev_button("Dev Only: Clear Save", Callable(_host, "_clear_current_save")))
	_dev_add(_make_dev_button("Dev Only: Cycle Player Appearance", _debug_cycle_player_appearance))

func _make_dev_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 36)
	button.pressed.connect(callback)
	return button

func _debug_advance_time(minutes: int, reason: String) -> void:
	var manager := get_node_or_null("/root/TimeManager")
	if manager != null and manager.has_method("advance_time"):
		manager.call("advance_time", minutes, reason)
		add_log("Time debug: %s" % String(manager.call("compact_hud_text")))

func _debug_jump_to_daylight() -> void:
	var manager := get_node_or_null("/root/TimeManager")
	if manager != null and manager.has_method("advance_to_daylight_start"):
		manager.call("advance_to_daylight_start")
		add_log("Time debug: jumped to daylight.")

func _debug_jump_to_night() -> void:
	var manager := get_node_or_null("/root/TimeManager")
	if manager != null and manager.has_method("advance_to_night_start"):
		manager.call("advance_to_night_start")
		add_log("Time debug: jumped to night.")

func _debug_adjust_health(stat_name: String, delta: float) -> void:
	var manager := get_node_or_null("/root/HealthManager")
	if manager != null and manager.has_method("adjust_stat"):
		manager.call("adjust_stat", stat_name, delta)
		add_log("Health debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_reset_health() -> void:
	var manager := get_node_or_null("/root/HealthManager")
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
		add_log("Health debug: reset.\n%s" % String(manager.call("debug_values_text")))

func _debug_set_health_danger() -> void:
	var manager := get_node_or_null("/root/HealthManager")
	if manager != null and manager.has_method("set_danger_state"):
		manager.call("set_danger_state")
		add_log("Health debug: danger state.\n%s" % String(manager.call("debug_values_text")))

func _debug_health_action(action_id: String) -> void:
	var time_manager := get_node_or_null("/root/TimeManager")
	if time_manager != null and time_manager.has_method("action_minutes") and time_manager.has_method("advance_time"):
		var minutes := int(time_manager.call("action_minutes", action_id))
		time_manager.call("advance_time", minutes, action_id)
	var health_manager := get_node_or_null("/root/HealthManager")
	if health_manager != null and health_manager.has_method("detail_text"):
		add_log("Health action %s:\n%s" % [action_id, String(health_manager.call("detail_text", true))])

func _debug_adjust_base_status(stat_name: String, delta: float) -> void:
	var manager := get_node_or_null("/root/BaseStatusManager")
	if manager != null and manager.has_method("adjust_stat"):
		manager.call("adjust_stat", stat_name, delta)
		add_log("Base status debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_cycle_base_system(system_name: String) -> void:
	var manager := get_node_or_null("/root/BaseStatusManager")
	if manager == null or not manager.has_method("debug_set_system_status"):
		return
	# SystemStatus enum order is Offline, Critical, Basic, Stable; cycle Critical -> Basic -> Stable -> Critical.
	var current := int(manager.get(system_name))
	var next_status := "critical"
	if current == 1:
		next_status = "basic"
	elif current == 2:
		next_status = "stable"
	manager.call("debug_set_system_status", system_name, next_status)
	add_log("Base status debug (%s -> %s):\n%s" % [system_name, next_status, String(manager.call("debug_values_text"))])

func _debug_reset_base_status() -> void:
	var manager := get_node_or_null("/root/BaseStatusManager")
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
		add_log("Base status debug: reset to Day 01.\n%s" % String(manager.call("debug_values_text")))

func _debug_set_base_status_minimum_stable() -> void:
	var manager := get_node_or_null("/root/BaseStatusManager")
	if manager != null and manager.has_method("set_minimum_stable_state"):
		manager.call("set_minimum_stable_state")
		add_log("Base status debug: minimum stable state.\n%s" % String(manager.call("debug_values_text")))

func _debug_adjust_air(stat_name: String, delta: float) -> void:
	var manager := get_node_or_null("/root/AirSystemManager")
	if manager != null and manager.has_method("adjust_stat"):
		manager.call("adjust_stat", stat_name, delta)
		add_log("Air system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_cycle_air_system(system_name: String) -> void:
	var manager := get_node_or_null("/root/AirSystemManager")
	if manager == null or not manager.has_method("debug_set_system_status"):
		return
	# SystemStatus enum order is Offline, Critical, Basic, Stable; cycle Critical -> Basic -> Stable -> Critical.
	var current := int(manager.get(system_name))
	var next_status := "critical"
	if current == 1:
		next_status = "basic"
	elif current == 2:
		next_status = "stable"
	manager.call("debug_set_system_status", system_name, next_status)
	add_log("Air system debug (%s -> %s):\n%s" % [system_name, next_status, String(manager.call("debug_values_text"))])

func _debug_cycle_air_supply_target() -> void:
	var manager := get_node_or_null("/root/AirSystemManager")
	if manager != null and manager.has_method("debug_cycle_supply_target"):
		manager.call("debug_cycle_supply_target")
		add_log("Air system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_reset_air_system() -> void:
	var manager := get_node_or_null("/root/AirSystemManager")
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
		add_log("Air system debug: reset to Day 01.\n%s" % String(manager.call("debug_values_text")))

func _debug_set_air_minimum_stable() -> void:
	var manager := get_node_or_null("/root/AirSystemManager")
	if manager != null and manager.has_method("set_minimum_stable_state"):
		manager.call("set_minimum_stable_state")
		add_log("Air system debug: minimum stable state.\n%s" % String(manager.call("debug_values_text")))

func _debug_adjust_power_energy(delta: float) -> void:
	var manager := get_node_or_null("/root/PowerSystemManager")
	if manager != null and manager.has_method("debug_adjust_energy"):
		manager.call("debug_adjust_energy", delta)
		add_log("Power system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_add_solar_panel() -> void:
	var manager := get_node_or_null("/root/PowerSystemManager")
	if manager != null and manager.has_method("debug_add_solar_panel"):
		manager.call("debug_add_solar_panel")
		add_log("Power system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_add_battery_module() -> void:
	var manager := get_node_or_null("/root/PowerSystemManager")
	if manager != null and manager.has_method("debug_add_battery_module"):
		manager.call("debug_add_battery_module")
		add_log("Power system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_cycle_solar_array_status() -> void:
	var manager := get_node_or_null("/root/PowerSystemManager")
	if manager != null and manager.has_method("debug_cycle_solar_array_status"):
		manager.call("debug_cycle_solar_array_status")
		add_log("Power system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_cycle_storage_efficiency() -> void:
	var manager := get_node_or_null("/root/PowerSystemManager")
	if manager != null and manager.has_method("debug_cycle_storage_efficiency"):
		manager.call("debug_cycle_storage_efficiency")
		add_log("Power system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_cycle_charging_efficiency() -> void:
	var manager := get_node_or_null("/root/PowerSystemManager")
	if manager != null and manager.has_method("debug_cycle_charging_efficiency"):
		manager.call("debug_cycle_charging_efficiency")
		add_log("Power system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_set_power_mode(mode_id: String) -> void:
	var manager := get_node_or_null("/root/PowerSystemManager")
	if manager != null and manager.has_method("debug_set_power_mode"):
		manager.call("debug_set_power_mode", mode_id)
		add_log("Power system debug: mode %s.\n%s" % [mode_id, String(manager.call("debug_values_text"))])

func _debug_reset_power_system() -> void:
	var manager := get_node_or_null("/root/PowerSystemManager")
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
		add_log("Power system debug: reset to Day 01.\n%s" % String(manager.call("debug_values_text")))

func _debug_set_power_minimum_stable() -> void:
	var manager := get_node_or_null("/root/PowerSystemManager")
	if manager != null and manager.has_method("set_minimum_stable_state"):
		manager.call("set_minimum_stable_state")
		add_log("Power system debug: minimum stable state.\n%s" % String(manager.call("debug_values_text")))

func _debug_adjust_water(delta: float) -> void:
	var manager := get_node_or_null("/root/WaterSystemManager")
	if manager != null and manager.has_method("debug_adjust_water"):
		manager.call("debug_adjust_water", delta)
		add_log("Water system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_adjust_ice(delta: float) -> void:
	var manager := get_node_or_null("/root/WaterSystemManager")
	if manager != null and manager.has_method("debug_adjust_ice"):
		manager.call("debug_adjust_ice", delta)
		add_log("Water system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_add_water_tank_module() -> void:
	var manager := get_node_or_null("/root/WaterSystemManager")
	if manager != null and manager.has_method("debug_add_water_tank_module"):
		manager.call("debug_add_water_tank_module")
		add_log("Water system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_add_ice_storage_module() -> void:
	var manager := get_node_or_null("/root/WaterSystemManager")
	if manager != null and manager.has_method("debug_add_ice_storage_module"):
		manager.call("debug_add_ice_storage_module")
		add_log("Water system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_cycle_water_recycling_level() -> void:
	var manager := get_node_or_null("/root/WaterSystemManager")
	if manager != null and manager.has_method("debug_cycle_recycling_level"):
		manager.call("debug_cycle_recycling_level")
		add_log("Water system debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_process_ice_batch() -> void:
	var manager := get_node_or_null("/root/WaterSystemManager")
	if manager != null and manager.has_method("debug_process_ice_batch"):
		manager.call("debug_process_ice_batch")
		add_log("Water system debug: processed ice batch.\n%s" % String(manager.call("debug_values_text")))

func _debug_process_all_ice() -> void:
	var manager := get_node_or_null("/root/WaterSystemManager")
	if manager != null and manager.has_method("debug_process_all_ice"):
		manager.call("debug_process_all_ice")
		add_log("Water system debug: processed all available ice.\n%s" % String(manager.call("debug_values_text")))

func _debug_reset_water_system() -> void:
	var manager := get_node_or_null("/root/WaterSystemManager")
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
		add_log("Water system debug: reset to Day 01.\n%s" % String(manager.call("debug_values_text")))

func _debug_set_water_minimum_stable() -> void:
	var manager := get_node_or_null("/root/WaterSystemManager")
	if manager != null and manager.has_method("set_minimum_stable_state"):
		manager.call("set_minimum_stable_state")
		add_log("Water system debug: minimum stable state.\n%s" % String(manager.call("debug_values_text")))

func _debug_sow_plant(crop_id: String) -> void:
	var manager := get_node_or_null("/root/PlantGrowthManager")
	if manager != null and manager.has_method("debug_sow"):
		manager.call("debug_sow", crop_id)
		add_log("Plant debug: sowed %s.\n%s" % [crop_id, String(manager.call("debug_values_text"))])

func _debug_cycle_plant_water_level() -> void:
	var manager := get_node_or_null("/root/PlantGrowthManager")
	if manager != null and manager.has_method("debug_cycle_water_level"):
		manager.call("debug_cycle_water_level")
		add_log("Plant debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_cycle_plant_light_level() -> void:
	var manager := get_node_or_null("/root/PlantGrowthManager")
	if manager != null and manager.has_method("debug_cycle_light_system_level"):
		manager.call("debug_cycle_light_system_level")
		add_log("Plant debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_force_mature_plant() -> void:
	var manager := get_node_or_null("/root/PlantGrowthManager")
	if manager != null and manager.has_method("debug_force_mature_current"):
		manager.call("debug_force_mature_current")
		add_log("Plant debug: forced current crop to Mature.\n%s" % String(manager.call("debug_values_text")))

func _debug_harvest_plant() -> void:
	var manager := get_node_or_null("/root/PlantGrowthManager")
	if manager != null and manager.has_method("debug_harvest_current"):
		manager.call("debug_harvest_current")
		add_log("Plant debug: harvested current crop.\n%s" % String(manager.call("debug_values_text")))

func _debug_clear_plants() -> void:
	var manager := get_node_or_null("/root/PlantGrowthManager")
	if manager != null and manager.has_method("clear_all_plants"):
		manager.call("clear_all_plants")
		add_log("Plant debug: cleared all greenhouse crops.")

func _debug_add_sample_foods() -> void:
	var manager := get_node_or_null("/root/InventoryManager")
	if manager != null and manager.has_method("debug_add_sample_foods"):
		manager.call("debug_add_sample_foods")
		add_log("Inventory debug: added sample foods.\n%s" % String(manager.call("debug_values_text")))

func _debug_add_sample_seeds() -> void:
	var manager := get_node_or_null("/root/InventoryManager")
	if manager != null and manager.has_method("debug_add_sample_seeds"):
		manager.call("debug_add_sample_seeds")
		add_log("Inventory debug: added sample seeds.\n%s" % String(manager.call("debug_values_text")))

func _debug_add_sample_consumables() -> void:
	var manager := get_node_or_null("/root/InventoryManager")
	if manager != null and manager.has_method("debug_add_sample_consumables"):
		manager.call("debug_add_sample_consumables")
		add_log("Inventory debug: added sample consumables.\n%s" % String(manager.call("debug_values_text")))

func _debug_add_sample_materials() -> void:
	var manager := get_node_or_null("/root/InventoryManager")
	if manager != null and manager.has_method("debug_add_sample_materials"):
		manager.call("debug_add_sample_materials")
		add_log("Inventory debug: added sample materials.\n%s" % String(manager.call("debug_values_text")))

func _debug_add_durable_drill() -> void:
	var manager := get_node_or_null("/root/InventoryManager")
	if manager != null and manager.has_method("debug_add_durable_drill"):
		manager.call("debug_add_durable_drill")
		add_log("Inventory debug: added durable drill.\n%s" % String(manager.call("debug_values_text")))

func _debug_eat_lettuce() -> void:
	var manager := get_node_or_null("/root/InventoryManager")
	if manager != null and manager.has_method("debug_eat_lettuce"):
		manager.call("debug_eat_lettuce")
		add_log("Inventory debug: ate lettuce.\n%s" % String(manager.call("debug_values_text")))

func _debug_eat_nutrition_pack() -> void:
	var manager := get_node_or_null("/root/InventoryManager")
	if manager != null and manager.has_method("debug_eat_nutrition_pack"):
		manager.call("debug_eat_nutrition_pack")
		add_log("Inventory debug: ate nutrition pack.\n%s" % String(manager.call("debug_values_text")))

func _debug_use_last_durable_item() -> void:
	var manager := get_node_or_null("/root/InventoryManager")
	if manager != null and manager.has_method("debug_use_last_durable_item"):
		manager.call("debug_use_last_durable_item")
		add_log("Inventory debug: used last durable item.\n%s" % String(manager.call("debug_values_text")))

func _debug_reset_inventory() -> void:
	var manager := get_node_or_null("/root/InventoryManager")
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
		add_log("Inventory debug: reset to Day 01.\n%s" % String(manager.call("debug_values_text")))

func _debug_backpack_add_samples() -> void:
	var manager := get_node_or_null("/root/BackpackManager")
	if manager == null:
		return
	if manager.has_method("debug_add_sample_materials"):
		manager.call("debug_add_sample_materials")
	if manager.has_method("debug_add_sample_foods"):
		manager.call("debug_add_sample_foods")
	add_log("Backpack debug: added sample items.\n%s" % String(manager.call("debug_values_text")))

func _debug_backpack_deposit_all() -> void:
	var manager := get_node_or_null("/root/BackpackManager")
	if manager != null and manager.has_method("deposit_all_to_storage"):
		manager.call("deposit_all_to_storage")
		add_log("Backpack debug: deposited carried items to storage.\n%s" % String(manager.call("debug_values_text")))

func _debug_backpack_ice_to_water() -> void:
	var manager := get_node_or_null("/root/BackpackManager")
	if manager == null:
		return
	if manager.has_method("debug_add_lunar_ice"):
		manager.call("debug_add_lunar_ice")
	if manager.has_method("deposit_ice_to_water_system"):
		manager.call("deposit_ice_to_water_system")
	add_log("Backpack debug: transferred lunar ice to water system.\n%s" % String(manager.call("debug_values_text")))

func _debug_storage_add_samples() -> void:
	var manager := get_node_or_null("/root/StorageManager")
	if manager == null:
		return
	if manager.has_method("debug_add_sample_foods"):
		manager.call("debug_add_sample_foods")
	if manager.has_method("debug_add_sample_materials"):
		manager.call("debug_add_sample_materials")
	add_log("Storage debug: added sample items.\n%s" % String(manager.call("debug_values_text")))

func _debug_storage_eat_first_food() -> void:
	var manager := get_node_or_null("/root/StorageManager")
	if manager != null and manager.has_method("eat_first_food"):
		manager.call("eat_first_food")
		add_log("Storage debug: ate first available food.\n%s" % String(manager.call("debug_values_text")))

func _debug_reset_backpack_storage() -> void:
	var backpack_manager := get_node_or_null("/root/BackpackManager")
	if backpack_manager != null and backpack_manager.has_method("reset_to_arrival"):
		backpack_manager.call("reset_to_arrival")
	var storage_manager := get_node_or_null("/root/StorageManager")
	if storage_manager != null and storage_manager.has_method("reset_to_arrival"):
		storage_manager.call("reset_to_arrival")
	add_log("Backpack/Storage debug: reset to Day 01.")

func _debug_supply_status() -> void:
	var manager := get_node_or_null("/root/SupplyManager")
	if manager != null and manager.has_method("debug_values_text"):
		add_log("Supply debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_supply_draft_starter() -> void:
	var manager := get_node_or_null("/root/SupplyManager")
	if manager != null and manager.has_method("debug_select_starter_supply"):
		manager.call("debug_select_starter_supply")
		add_log("Supply debug: drafted starter order.\n%s" % String(manager.call("debug_values_text")))

func _debug_supply_confirm() -> void:
	var manager := get_node_or_null("/root/SupplyManager")
	if manager != null and manager.has_method("confirm_supply_order"):
		var ok := bool(manager.call("confirm_supply_order"))
		add_log("Supply debug: confirm %s.\n%s" % ["ok" if ok else "failed", String(manager.call("debug_values_text"))])

func _debug_supply_jump_deadline() -> void:
	var manager := get_node_or_null("/root/SupplyManager")
	if manager != null and manager.has_method("debug_jump_to_deadline"):
		manager.call("debug_jump_to_deadline")
		add_log("Supply debug: jumped to deadline.\n%s" % String(manager.call("debug_values_text")))

func _debug_supply_jump_arrival() -> void:
	var manager := get_node_or_null("/root/SupplyManager")
	if manager != null and manager.has_method("debug_jump_to_arrival"):
		manager.call("debug_jump_to_arrival")
		add_log("Supply debug: jumped to arrival.\n%s" % String(manager.call("debug_values_text")))

func _debug_supply_reset() -> void:
	var manager := get_node_or_null("/root/SupplyManager")
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
		add_log("Supply debug: reset.\n%s" % String(manager.call("debug_values_text")))

func _debug_repair_status() -> void:
	var manager := get_node_or_null("/root/RepairManager")
	if manager != null and manager.has_method("debug_values_text"):
		add_log("Repair debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_repair_seed_materials() -> void:
	var manager := get_node_or_null("/root/RepairManager")
	if manager != null and manager.has_method("debug_seed_repair_materials"):
		manager.call("debug_seed_repair_materials")
		add_log("Repair debug: seeded materials.\n%s" % String(manager.call("debug_values_text")))

func _debug_repair_add_sample_faults() -> void:
	var manager := get_node_or_null("/root/RepairManager")
	if manager != null and manager.has_method("debug_add_sample_faults"):
		manager.call("debug_add_sample_faults")
		add_log("Repair debug: sample faults added.\n%s" % String(manager.call("debug_values_text")))

func _debug_repair_diagnose_first() -> void:
	var manager := get_node_or_null("/root/RepairManager")
	if manager != null and manager.has_method("debug_diagnose_first"):
		manager.call("debug_diagnose_first")
		add_log("Repair debug: diagnosed first active fault.\n%s" % String(manager.call("debug_values_text")))

func _debug_repair_attempt_first_correct() -> void:
	var manager := get_node_or_null("/root/RepairManager")
	if manager != null and manager.has_method("debug_attempt_first_correct"):
		manager.call("debug_attempt_first_correct")
		add_log("Repair debug: attempted first correct repair.\n%s" % String(manager.call("debug_values_text")))

func _debug_repair_attempt_first_wrong() -> void:
	var manager := get_node_or_null("/root/RepairManager")
	if manager != null and manager.has_method("debug_attempt_first_wrong"):
		manager.call("debug_attempt_first_wrong")
		add_log("Repair debug: attempted first wrong repair.\n%s" % String(manager.call("debug_values_text")))

func _debug_repair_reset() -> void:
	var manager := get_node_or_null("/root/RepairManager")
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
		add_log("Repair debug: reset.\n%s" % String(manager.call("debug_values_text")))

func _debug_training_time_status() -> void:
	var manager := get_node_or_null("/root/TrainingTimeManager")
	if manager != null and manager.has_method("debug_values_text"):
		add_log("Training time debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_training_time_start() -> void:
	var manager := get_node_or_null("/root/TrainingTimeManager")
	if manager != null and manager.has_method("start_training_time"):
		manager.call("start_training_time")
		add_log("Training time debug: started (480 min archive limit).\n%s" % String(manager.call("debug_values_text")))

func _debug_training_time_advance(minutes: int) -> void:
	var manager := get_node_or_null("/root/TrainingTimeManager")
	if manager != null and manager.has_method("debug_advance"):
		manager.call("debug_advance", minutes, "debug_advance_%d" % minutes)
		add_log("Training time debug: advanced +%d min.\n%s" % [minutes, String(manager.call("debug_values_text"))])

func _debug_training_time_pause() -> void:
	var manager := get_node_or_null("/root/TrainingTimeManager")
	if manager != null and manager.has_method("pause_training_time"):
		manager.call("pause_training_time")
		add_log("Training time debug: paused.\n%s" % String(manager.call("debug_values_text")))

func _debug_training_time_resume() -> void:
	var manager := get_node_or_null("/root/TrainingTimeManager")
	if manager != null and manager.has_method("resume_training_time"):
		manager.call("resume_training_time")
		add_log("Training time debug: resumed.\n%s" % String(manager.call("debug_values_text")))

func _debug_training_time_force_timeout() -> void:
	var manager := get_node_or_null("/root/TrainingTimeManager")
	if manager != null and manager.has_method("debug_force_timeout"):
		manager.call("debug_force_timeout")
		add_log("Training time debug: forced timeout.\n%s" % String(manager.call("debug_values_text")))

func _debug_suit_wear() -> void:
	var manager := get_node_or_null("/root/SuitManager")
	if manager == null or not manager.has_method("wear_suit"):
		return
	var ok: bool = manager.call("wear_suit")
	add_log("Suit debug: wear_suit() -> %s\n%s" % [ok, String(manager.call("debug_values_text"))])

func _debug_suit_remove() -> void:
	var manager := get_node_or_null("/root/SuitManager")
	if manager == null or not manager.has_method("remove_suit_to_service_station"):
		return
	var ok: bool = manager.call("remove_suit_to_service_station")
	add_log("Suit debug: remove_suit_to_service_station() -> %s\n%s" % [ok, String(manager.call("debug_values_text"))])

func _debug_suit_simulate_eva(base_minutes: int, activity_type: String) -> void:
	var manager := get_node_or_null("/root/SuitManager")
	if manager == null or not manager.has_method("debug_simulate_eva_action"):
		return
	var ok: bool = manager.call("debug_simulate_eva_action", base_minutes, activity_type)
	add_log("Suit debug: simulate %s (%d min base) -> %s\n%s" % [activity_type, base_minutes, ok, String(manager.call("debug_values_text"))])

func _debug_suit_empty_reserves() -> void:
	var manager := get_node_or_null("/root/SuitManager")
	if manager != null and manager.has_method("debug_empty_suit_reserves"):
		manager.call("debug_empty_suit_reserves")
		add_log("Suit debug: emptied oxygen/power.\n%s" % String(manager.call("debug_values_text")))

func _debug_suit_service_full() -> void:
	var manager := get_node_or_null("/root/SuitManager")
	if manager == null or not manager.has_method("service_suit_full"):
		return
	var ok: bool = manager.call("service_suit_full")
	add_log("Suit debug: service_suit_full() -> %s\n%s" % [ok, String(manager.call("debug_values_text"))])

func _debug_suit_upgrade() -> void:
	var manager := get_node_or_null("/root/SuitManager")
	if manager == null or not manager.has_method("upgrade_suit_speed"):
		return
	var ok: bool = manager.call("upgrade_suit_speed")
	add_log("Suit debug: upgrade_suit_speed() -> %s\n%s" % [ok, String(manager.call("debug_values_text"))])

func _debug_suit_status() -> void:
	var manager := get_node_or_null("/root/SuitManager")
	if manager != null and manager.has_method("debug_values_text"):
		add_log("Suit debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_suit_reset() -> void:
	var manager := get_node_or_null("/root/SuitManager")
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
		add_log("Suit debug: reset.\n%s" % String(manager.call("debug_values_text")))

func _debug_movement_status() -> void:
	var manager := get_node_or_null("/root/MovementTimeManager")
	if manager != null and manager.has_method("debug_values_text"):
		add_log("Movement debug:\n%s" % String(manager.call("debug_values_text")))

func _debug_movement_simulate(tile_count: int, terrain_type: String, context: String) -> void:
	var manager := get_node_or_null("/root/MovementTimeManager")
	if manager == null or not manager.has_method("debug_simulate_move"):
		return
	manager.call("debug_simulate_move", tile_count, terrain_type, context)
	add_log("Movement debug: simulated %d tiles on %s (%s).\n%s" % [tile_count, terrain_type, context, String(manager.call("debug_values_text"))])

func _debug_cycle_player_appearance() -> void:
	var player_node: Node = null
	if _host != null:
		player_node = _host.get("player_node")
	if player_node == null or not is_instance_valid(player_node) or not player_node.has_method("set_appearance_by_key"):
		add_log("Appearance debug: no active player_node (start the sandbox first).")
		return
	# Reads the live registry instead of a hand-maintained list, so newly
	# registered combos show up here automatically with no code change.
	var keys: Array = CharacterAppearanceCatalogScript.all_registered_keys()
	if keys.is_empty():
		return
	_appearance_cycle_index = (_appearance_cycle_index + 1) % keys.size()
	var appearance_id: String = keys[_appearance_cycle_index]
	player_node.call("set_appearance_by_key", appearance_id)
	add_log("Player appearance -> %s" % appearance_id)

func _debug_movement_reset() -> void:
	var manager := get_node_or_null("/root/MovementTimeManager")
	if manager != null and manager.has_method("debug_reset"):
		manager.call("debug_reset")
		add_log("Movement debug: reset.\n%s" % String(manager.call("debug_values_text")))

