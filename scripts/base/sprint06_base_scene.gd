extends Node2D

const SAVE_PATH := "user://saves/sprint06_progress.json"
const PLAYER_SPEED := 230.0

const SCENE_AIRLOCK := "res://scenes/base/BaseAirlockEntryScene.tscn"
const SCENE_INTERIOR := "res://scenes/base/OldBaseInteriorScene.tscn"
const SCENE_GREENHOUSE := "res://scenes/base/OldGreenhouseScene.tscn"
const SCENE_DAY_END := "res://scenes/base/Day01EndScene.tscn"
const SCENE_DAY02_START := "res://scenes/base/Day02StartScene.tscn"
const SCENE_DAY02_END := "res://scenes/base/Day02EndScene.tscn"
const SCENE_WEEK_START := "res://scenes/base/WeekRoutineStartScene.tscn"
const SCENE_WEEK_END := "res://scenes/base/WeekRoutineEndScene.tscn"
const HUD_SAFE_POSITION := Vector2(24, 96)
const HUD_SAFE_SIZE := Vector2(360, 464)
const HUD_SAFE_WORLD_MIN_X := 140.0

@export var scene_kind := "interior"

var state: Dictionary = {}
var player_pos := Vector2(250, 500)
var player_moving := false
var input_enabled := true
var message_text := ""
var prompt_text := ""
var objective_text := ""
var current_target := ""
var ai_text := ""
var sequence_running := false
var scene_title_alpha := 0.0

var hud_label: Label
var message_label: Label
var prompt_label: Label
var ai_label: Label
var fade_rect: ColorRect
var prop_root: Node2D
var player_overlay: BasePlayerOverlay

var interior_targets := {
	"console": Rect2(Vector2(700, 330), Vector2(180, 92)),
	"power_panel": Rect2(Vector2(430, 236), Vector2(134, 128)),
	"power_console": Rect2(Vector2(440, 420), Vector2(150, 86)),
	"life_console": Rect2(Vector2(1000, 330), Vector2(170, 96)),
	"report_terminal": Rect2(Vector2(1030, 545), Vector2(170, 82)),
	"greenhouse_door": Rect2(Vector2(1300, 290), Vector2(98, 190)),
	"rest_point": Rect2(Vector2(260, 620), Vector2(160, 90)),
}

var greenhouse_targets := {
	"last_plant": Rect2(Vector2(720, 330), Vector2(170, 180)),
	"monitor": Rect2(Vector2(980, 300), Vector2(150, 90)),
	"scanner": Rect2(Vector2(990, 430), Vector2(132, 92)),
	"grow_light": Rect2(Vector2(610, 172), Vector2(360, 54)),
	"water_panel": Rect2(Vector2(470, 520), Vector2(150, 90)),
	"exit": Rect2(Vector2(1340, 580), Vector2(130, 120)),
}

func _ready() -> void:
	_setup_input()
	_load_state()
	_setup_ui()
	_setup_scene_defaults()
	_setup_modular_props()
	_setup_player_overlay()
	call_deferred("_start_scene")

func _setup_input() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E, KEY_ENTER])
	_add_key_action("save_game", [KEY_F5])
	_add_key_action("load_game", [KEY_F9])

func _add_key_action(action_name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key: int in keys:
		var exists := false
		for event: InputEvent in InputMap.action_get_events(action_name):
			if event is InputEventKey and (event as InputEventKey).keycode == key:
				exists = true
		if not exists:
			var input_event := InputEventKey.new()
			input_event.keycode = key
			InputMap.action_add_event(action_name, input_event)

func _setup_modular_props() -> void:
	prop_root = Node2D.new()
	prop_root.name = "ModularProps"
	prop_root.z_index = 1
	add_child(prop_root)
	match scene_kind:
		"interior":
			_setup_old_base_props()
		"greenhouse":
			_setup_greenhouse_props()
		"solar_array":
			_setup_solar_array_props()

func _setup_player_overlay() -> void:
	player_overlay = BasePlayerOverlay.new()
	player_overlay.name = "PlayerOverlay"
	player_overlay.source_scene = self
	player_overlay.z_index = 8
	add_child(player_overlay)

func _spawn_prop(scene_path: String, pos: Vector2, size := Vector2.ZERO, active_value := false, damaged_value := false, label := "") -> Node2D:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return Node2D.new()
	var node: Node2D = packed.instantiate()
	node.position = pos
	if size != Vector2.ZERO:
		node.set("prop_size", size)
	node.set("active", active_value)
	node.set("damaged", damaged_value)
	if not label.is_empty():
		node.set("prop_label", label)
	prop_root.add_child(node)
	return node

func _setup_old_base_props() -> void:
	_spawn_prop("res://scenes/props/old_base/OldBaseWallFrame.tscn", Vector2(90, 170))
	_spawn_prop("res://scenes/props/old_base/OldBaseFloorTiles.tscn", Vector2(116, 196))
	_spawn_prop("res://scenes/props/old_base/OldWallModule.tscn", Vector2(190, 185), Vector2(170, 56))
	_spawn_prop("res://scenes/props/old_base/OldWallModule.tscn", Vector2(1035, 185), Vector2(190, 56), false, false, "LIFE SUPPORT BAY")
	_spawn_prop("res://scenes/props/old_base/WallLightPanel.tscn", Vector2(310, 190), Vector2(140, 10), bool(state.get("BasePowerRestored", false)))
	_spawn_prop("res://scenes/props/old_base/WallLightPanel.tscn", Vector2(780, 190), Vector2(140, 10), bool(state.get("BasePowerRestored", false)))
	_spawn_prop("res://scenes/props/old_base/WallLightPanel.tscn", Vector2(1250, 190), Vector2(140, 10), bool(state.get("BasePowerRestored", false)))
	_spawn_prop("res://scenes/props/old_base/CentralConsole.tscn", interior_targets["console"].position, interior_targets["console"].size, bool(state.get("BasePowerRestored", false)))
	_spawn_prop("res://scenes/props/old_base/OldPowerPanel.tscn", interior_targets["power_panel"].position, interior_targets["power_panel"].size, bool(state.get("PowerPanelRepaired", false)), not bool(state.get("PowerPanelRepaired", false)))
	_spawn_prop("res://scenes/props/old_base/PowerRestartConsole.tscn", interior_targets["power_console"].position, interior_targets["power_console"].size, bool(state.get("BasePowerRestored", false)))
	_spawn_prop("res://scenes/props/old_base/LifeSupportConsole.tscn", interior_targets["life_console"].position, interior_targets["life_console"].size, bool(state.get("MinimalLifeSupportStable", false)))
	_spawn_prop("res://scenes/props/old_base/GreenhouseDoor.tscn", interior_targets["greenhouse_door"].position, interior_targets["greenhouse_door"].size, bool(state.get("GreenhouseUnlocked", false)))
	_spawn_prop("res://scenes/props/old_base/StorageLocker.tscn", Vector2(210, 310), Vector2(130, 210))
	_spawn_prop("res://scenes/props/old_base/MaintenanceNote.tscn", Vector2(1040, 596), Vector2(210, 54))
	_spawn_prop("res://scenes/props/old_base/OldLogMarker.tscn", Vector2(640, 612), Vector2(148, 58))
	_spawn_prop("res://scenes/props/old_base/FloorDustMarks.tscn", Vector2(405, 612), Vector2(740, 110))

func _setup_greenhouse_props() -> void:
	for i in range(6):
		var scene_path: String = "res://scenes/props/greenhouse/HydroponicRackDead.tscn" if i % 2 == 0 else "res://scenes/props/greenhouse/HydroponicRackEmpty.tscn"
		_spawn_prop(scene_path, Vector2(170 + i * 190, 250), Vector2(130, 270))
	var stable := bool(state.get("LastPlantStable", false))
	var grow_light_scene := "res://scenes/props/greenhouse/GrowLightOn.tscn" if stable else "res://scenes/props/greenhouse/GrowLightOff.tscn"
	var monitor_scene := "res://scenes/props/greenhouse/PlantMonitorStable.tscn" if stable else "res://scenes/props/greenhouse/PlantMonitorCritical.tscn"
	var plant_scene := "res://scenes/props/greenhouse/LastPlantStable.tscn" if stable else "res://scenes/props/greenhouse/LastPlantCritical.tscn"
	_spawn_prop(grow_light_scene, greenhouse_targets["grow_light"].position, greenhouse_targets["grow_light"].size, stable)
	_spawn_prop("res://scenes/props/greenhouse/CentralPlantChamber.tscn", greenhouse_targets["last_plant"].position - Vector2(20, 30), Vector2(210, 230), stable)
	_spawn_prop(plant_scene, greenhouse_targets["last_plant"].position + Vector2(35, 65), Vector2(110, 130), stable, not stable)
	_spawn_prop(monitor_scene, greenhouse_targets["monitor"].position, greenhouse_targets["monitor"].size, stable)
	_spawn_prop("res://scenes/props/greenhouse/WaterCyclePanel.tscn", greenhouse_targets["water_panel"].position, greenhouse_targets["water_panel"].size, bool(state.get("PartialWaterCycleRestored", false)), not bool(state.get("PartialWaterCycleRestored", false)))
	_spawn_prop("res://scenes/props/old_base/GreenhouseDoor.tscn", greenhouse_targets["exit"].position, greenhouse_targets["exit"].size, bool(state.get("LastPlantStable", false)), false, "居住舱")

func _setup_solar_array_props() -> void:
	_spawn_prop("res://scenes/props/solar_array/EarthSkyElement.tscn", Vector2(1040, 96), Vector2(78, 78))
	_spawn_prop("res://scenes/props/solar_array/DistantBaseLight.tscn", Vector2(210, 250), Vector2(210, 86))
	for i in range(5):
		var path: String = "res://scenes/props/solar_array/SolarPanelIntact.tscn"
		if i == 1:
			path = "res://scenes/props/solar_array/SolarPanelDusty.tscn"
		elif i == 3:
			path = "res://scenes/props/solar_array/SolarPanelTilted.tscn"
		elif i == 4:
			path = "res://scenes/props/solar_array/SolarPanelDamaged.tscn"
		_spawn_prop(path, Vector2(250 + i * 235, 430 + (i % 2) * 34), Vector2(260, 122), false, i == 1 or i == 3)
		_spawn_prop("res://scenes/props/solar_array/SolarSupportFrame.tscn", Vector2(295 + i * 235, 548 + (i % 2) * 34), Vector2(150, 92))
	_spawn_prop("res://scenes/props/solar_array/SolarCableDisconnected.tscn", Vector2(850, 610), Vector2(190, 86))
	_spawn_prop("res://scenes/props/solar_array/RepairMarker.tscn", Vector2(900, 545), Vector2(82, 82))
	_spawn_prop("res://scenes/props/solar_array/LunarFootprintDecal.tscn", Vector2(640, 690), Vector2(180, 70))
	for i in range(7):
		_spawn_prop("res://scenes/props/solar_array/LunarRockSmall.tscn", Vector2(150 + i * 185, 680 + sin(float(i)) * 44), Vector2(70, 42))

func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	canvas.layer = 20
	add_child(canvas)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)

	hud_label = Label.new()
	hud_label.position = HUD_SAFE_POSITION
	hud_label.size = HUD_SAFE_SIZE
	hud_label.modulate = Color("#d8e7f2", 0.92)
	hud_label.clip_text = true
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_label.add_theme_font_size_override("font_size", 15)
	root.add_child(hud_label)

	message_label = Label.new()
	message_label.position = Vector2(465, 650)
	message_label.size = Vector2(670, 130)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.modulate = Color("#eaf4ff", 0.95)
	message_label.add_theme_font_size_override("font_size", 22)
	root.add_child(message_label)

	prompt_label = Label.new()
	prompt_label.position = Vector2(520, 810)
	prompt_label.size = Vector2(560, 44)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.modulate = Color("#f0c766", 0.86)
	prompt_label.add_theme_font_size_override("font_size", 18)
	root.add_child(prompt_label)

	ai_label = Label.new()
	ai_label.position = Vector2(430, 72)
	ai_label.size = Vector2(740, 86)
	ai_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ai_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ai_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ai_label.modulate = Color("#cfe3f2", 0.92)
	ai_label.add_theme_font_size_override("font_size", 23)
	root.add_child(ai_label)

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = -1
	root.add_child(fade_rect)

func _setup_scene_defaults() -> void:
	match scene_kind:
		"airlock":
			player_pos = Vector2(250, 520)
			objective_text = "进入基地气闸"
			message_label.position = Vector2(460, 610)
			message_label.size = Vector2(680, 92)
		"greenhouse":
			player_pos = Vector2(220, 625)
		"day_end":
			player_pos = Vector2(760, 570)
			scene_title_alpha = 1.0
		"day02_start":
			player_pos = Vector2(760, 570)
			objective_text = "查看早间状态简报"
		"day02_end":
			player_pos = Vector2(760, 570)
			objective_text = "休息"
		"week_start":
			player_pos = Vector2(760, 570)
			objective_text = "查看早间状态简报"
		"week_end":
			player_pos = Vector2(760, 570)
			objective_text = "休息"
		"solar_array":
			player_pos = Vector2(180, 620)
			objective_text = "观察外部太阳能阵列"
		_:
			player_pos = Vector2(230, 560)

func _start_scene() -> void:
	if scene_kind == "day_end" or scene_kind == "day02_start" or scene_kind == "day02_end" or scene_kind == "week_start" or scene_kind == "week_end":
		_fade_scene_title()
	if scene_kind == "airlock":
		_start_airlock_sequence()
	elif scene_kind == "day02_start":
		_start_day02_sequence()
	elif scene_kind == "week_start":
		_start_week_day_sequence()
	elif scene_kind == "interior" and not bool(state.get("AIGreetingPlayed", false)):
		_show_first_ai_line()
	_update_objective()

func _process(delta: float) -> void:
	if input_enabled and scene_kind != "airlock":
		_move_player(delta)
	_update_target()
	_update_objective()
	_update_ui()
	queue_redraw()
	player_overlay.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and input_enabled:
		_interact()
	if event.is_action_pressed("save_game"):
		_save_state()
	if event.is_action_pressed("load_game"):
		_load_state()

func _move_player(delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	if direction.length() > 1.0:
		direction = direction.normalized()
	player_moving = direction.length() > 0.01
	player_pos += direction * PLAYER_SPEED * delta
	player_pos.x = clamp(player_pos.x, _world_left_limit(), 1510.0)
	player_pos.y = clamp(player_pos.y, 190.0, 770.0)

func _world_left_limit() -> float:
	if scene_kind == "interior" and (_is_week_routine_active() or _is_day02_active()):
		return HUD_SAFE_WORLD_MIN_X
	if scene_kind == "week_start" or scene_kind == "week_end":
		return HUD_SAFE_WORLD_MIN_X
	return 90.0

func _update_target() -> void:
	current_target = ""
	if scene_kind == "interior":
		for key in interior_targets.keys():
			if _near(interior_targets[key]):
				current_target = key
				break
	elif scene_kind == "greenhouse":
		for key in greenhouse_targets.keys():
			if _near(greenhouse_targets[key]):
				current_target = key
				break
	elif scene_kind == "day_end" and player_pos.distance_to(Vector2(760, 570)) < 96.0:
		current_target = "sleep"
	elif scene_kind == "day02_end" and player_pos.distance_to(Vector2(760, 570)) < 96.0:
		current_target = "sleep"
	elif scene_kind == "week_end" and player_pos.distance_to(Vector2(760, 570)) < 96.0:
		current_target = "sleep"

func _near(rect: Rect2) -> bool:
	return rect.grow(44).has_point(player_pos)

func _fade_scene_title() -> void:
	await get_tree().create_timer(1.6).timeout
	var tween := create_tween()
	tween.tween_property(self, "scene_title_alpha", 0.0, 0.5)

func _is_day02_active() -> bool:
	return bool(state.get("Day02Started", false)) and not bool(state.get("Day02Completed", false))

func _current_day() -> int:
	return int(state.get("CurrentDay", state.get("DayNumber", 2)))

func _is_week_routine_active() -> bool:
	var day := _current_day()
	return day >= 3 and day <= 7 and bool(state.get("DayStarted", false)) and not bool(state.get("DayCompleted", false)) and not bool(state.get("WeekOneCompleted", false))

func _daily_required_keys() -> Array[String]:
	var day := _current_day()
	match day:
		3:
			return ["DailyConsoleChecked", "DailyPowerChecked", "DailyLifeSupportChecked", "DailyPlantChecked"]
		4:
			return ["DailyConsoleChecked", "DailyWaterChecked", "DailySpecialChecked", "DailyPlantChecked"]
		5:
			return ["DailyConsoleChecked", "DailyPowerChecked", "DailySpecialChecked", "DailyPlantChecked"]
		6:
			return ["DailyConsoleChecked", "DailySpecialChecked", "DailyPlantChecked", "DailyRecordUpdated"]
		7:
			return ["DailyConsoleChecked", "DailyPowerChecked", "DailyLifeSupportChecked", "DailyPlantChecked"]
	return ["DailyConsoleChecked"]

func _daily_checks_complete() -> bool:
	for key: String in _daily_required_keys():
		if not bool(state.get(key, false)):
			return false
	return true

func _complete_daily_check(key: String, text: String) -> void:
	if key != "DailyConsoleChecked" and not bool(state.get("DailyConsoleChecked", false)):
		_message("请先查看中央控制台，确认今日巡检项目。")
		return
	if bool(state.get(key, false)):
		_message(text)
		return
	state[key] = true
	_message(text)
	if _daily_checks_complete() and not bool(state.get("DailyInspectionsComplete", false)):
		state["DailyInspectionsComplete"] = true
		ai_text = "今日巡检完成。\n建议整理并发送对地驻留报告。"
	_save_state()

func _reset_daily_flags(day: int) -> void:
	state["CurrentDay"] = day
	state["DayNumber"] = day
	state["DayStarted"] = true
	state["DayCompleted"] = false
	state["DailyConsoleChecked"] = false
	state["DailyPowerChecked"] = false
	state["DailyLifeSupportChecked"] = false
	state["DailyWaterChecked"] = false
	state["DailyPlantChecked"] = false
	state["DailySpecialChecked"] = false
	state["DailyRecordUpdated"] = false
	state["DailyInspectionsComplete"] = false
	state["DailyReportPreviewed"] = false
	state["DailyReportSent"] = false

func _day_label() -> String:
	return "Day %02d" % _current_day()

func _daily_report_label() -> String:
	return "第一周驻留报告" if _current_day() == 7 else "%s 对地报告" % _day_label()

func _daily_checklist_text() -> String:
	var day := _current_day()
	var text := _task_line("查看中央控制台", "DailyConsoleChecked")
	match day:
		3:
			text += "\n" + _task_line("检查供电面板", "DailyPowerChecked")
			text += "\n" + _task_line("检查生命支持", "DailyLifeSupportChecked")
			text += "\n" + _task_line("检查最后一株植物", "DailyPlantChecked")
		4:
			text += "\n" + _task_line("检查水循环状态", "DailyWaterChecked")
			text += "\n" + _task_line("检查温室供水", "DailySpecialChecked")
			text += "\n" + _task_line("检查最后一株植物", "DailyPlantChecked")
		5:
			text += "\n" + _task_line("检查供电面板", "DailyPowerChecked")
			text += "\n" + _task_line("检查当前负载", "DailySpecialChecked")
			text += "\n" + _task_line("检查最后一株植物", "DailyPlantChecked")
		6:
			text += "\n" + _task_line("进入旧温室", "DailySpecialChecked")
			text += "\n" + _task_line("近距观察最后一株植物", "DailyPlantChecked")
			text += "\n" + _task_line("更新植物状态记录", "DailyRecordUpdated")
		7:
			text += "\n" + _task_line("复核供电状态", "DailyPowerChecked")
			text += "\n" + _task_line("复核生命支持状态", "DailyLifeSupportChecked")
			text += "\n" + _task_line("复核温室生命信号", "DailyPlantChecked")
	text += "\n" + _task_line("发送%s" % _daily_report_label(), "DailyReportSent")
	return text

func _day02_inspections_complete() -> bool:
	return bool(state.get("Day02PowerChecked", false)) \
		and bool(state.get("Day02LifeSupportChecked", false)) \
		and bool(state.get("Day02WaterChecked", false)) \
		and bool(state.get("Day02LastPlantChecked", false))

func _complete_day02_check(key: String, text: String) -> void:
	if not bool(state.get("Day02ConsoleChecked", false)):
		_message("请先查看中央控制台，生成今日巡检列表。")
		return
	if bool(state.get(key, false)):
		_message(text)
		return
	state[key] = true
	_message(text)
	if _day02_inspections_complete() and not bool(state.get("Day02InspectionsComplete", false)):
		state["Day02InspectionsComplete"] = true
		ai_text = "今日巡检完成。\n建议整理并发送对地驻留报告。"
	_save_state()

func _update_objective() -> void:
	if scene_kind == "airlock":
		return
	if scene_kind == "day02_start":
		objective_text = "查看早间状态简报"
		return
	if scene_kind == "day02_end":
		objective_text = "休息"
		return
	if scene_kind == "week_start":
		objective_text = "查看早间状态简报"
		return
	if scene_kind == "week_end":
		objective_text = "休息"
		return
	if _is_day02_active():
		if not bool(state.get("Day02ConsoleChecked", false)):
			objective_text = "查看中央控制台"
		elif not _day02_inspections_complete():
			objective_text = "执行今日巡检"
		elif not bool(state.get("Day02ReportSent", false)):
			objective_text = "发送 Day 02 对地报告"
		else:
			objective_text = "返回居住舱休息"
		return
	if _is_week_routine_active():
		if not bool(state.get("DailyConsoleChecked", false)):
			objective_text = "查看中央控制台"
		elif not _daily_checks_complete():
			objective_text = "执行今日巡检"
		elif not bool(state.get("DailyReportSent", false)):
			objective_text = "发送%s" % _daily_report_label()
		else:
			objective_text = "返回居住舱休息"
		return
	if scene_kind == "interior":
		if not bool(state.get("CentralConsoleChecked", false)):
			objective_text = "查看中央控制台"
		elif not bool(state.get("PowerPanelChecked", false)):
			objective_text = "检查旧供电面板"
		elif not bool(state.get("PowerPanelRepaired", false)):
			objective_text = "执行基础维修"
		elif not bool(state.get("BasePowerRestored", false)):
			objective_text = "重启基础供电"
		elif not bool(state.get("LifeSupportConsoleChecked", false)):
			objective_text = "打开生命支持控制台"
		elif not bool(state.get("MinimalLifeSupportStable", false)):
			objective_text = "启动最低生命支持程序"
		elif not bool(state.get("GreenhouseUnlocked", false)):
			state["GreenhouseUnlocked"] = true
			_save_state()
			objective_text = "进入旧温室"
		else:
			objective_text = "进入旧温室"
	elif scene_kind == "greenhouse":
		if not bool(state.get("LastPlantDiscovered", false)):
			objective_text = "检查中央植物舱"
		elif not bool(state.get("LastPlantObserved", false)):
			objective_text = "观察最后一株植物"
		elif not bool(state.get("PlantMonitorChecked", false)):
			objective_text = "查看植物监测屏"
		elif not bool(state.get("LastPlantDiagnosed", false)):
			objective_text = "使用诊断终端"
		elif not bool(state.get("GrowLightRestored", false)):
			objective_text = "恢复补光"
		elif not bool(state.get("PartialWaterCycleRestored", false)):
			objective_text = "恢复最低水循环"
		elif not bool(state.get("LastPlantStable", false)):
			objective_text = "等待植物生命信号稳定"
		else:
			objective_text = "返回居住舱休息"
	elif scene_kind == "day_end":
		objective_text = "休息"

func _interact() -> void:
	if sequence_running:
		return
	if scene_kind == "interior":
		if _is_week_routine_active():
			_interact_week_interior()
		elif _is_day02_active():
			_interact_day02_interior()
		else:
			_interact_interior()
	elif scene_kind == "greenhouse":
		if _is_week_routine_active():
			_interact_week_greenhouse()
		elif _is_day02_active():
			_interact_day02_greenhouse()
		else:
			_interact_greenhouse()
	elif scene_kind == "day_end":
		if current_target == "sleep":
			_finish_day_one()
	elif scene_kind == "day02_end":
		if current_target == "sleep":
			_finish_day_two()
	elif scene_kind == "week_end":
		if current_target == "sleep":
			_finish_week_day()

func _interact_day02_interior() -> void:
	match current_target:
		"console":
			state["Day02ConsoleChecked"] = true
			state["DayNumber"] = 2
			_message("广寒前哨 D02 状态摘要：\n\n主供电：基础供电维持\n生命支持：最低稳定\n水循环：部分恢复\n温室系统：局部运行\n植物生命信号：稳定\n\n今日建议：\n执行基础巡检。\n完成对地驻留报告。")
		"power_panel":
			_complete_day02_check("Day02PowerChecked", "供电面板状态：\n\n备用线路：运行中\n主供电回路：未完全恢复\n当前输出：基础供电\n风险等级：可控\n\n当前供电足以维持旧基地最低运行。\n不建议扩展负载。")
		"life_console":
			_complete_day02_check("Day02LifeSupportChecked", "生命支持状态：\n\n氧气：稳定\n温度：可维持\n空气循环：低速运行\n过滤组件：需要持续观察\n\n当前环境适合短期驻留。\n长期驻留仍需进一步恢复系统。")
		"greenhouse_door":
			if bool(state.get("Day02ConsoleChecked", false)):
				_transition_to(SCENE_GREENHOUSE)
			else:
				_message("请先查看中央控制台，确认今日巡检项目。")
		"report_terminal":
			if not _day02_inspections_complete():
				_message("对地报告尚未解锁。\n请先完成供电、生命支持、水循环和最后一株植物巡检。")
			elif not bool(state.get("Day02ReportPreviewed", false)):
				state["Day02ReportPreviewed"] = true
				_message("广寒前哨 D02 驻留报告\n\n基础供电：维持\n生命支持：最低稳定\n水循环：低流量运行\n温室生命信号：稳定\n人员状态：可继续驻留\n\n备注：旧温室仍存在一株存活植物。\n已完成补光与最低水循环恢复。\n建议下一阶段优先恢复温室系统。\n\n再次按 E / Enter 发送报告。")
			elif not bool(state.get("Day02ReportSent", false)):
				_send_day02_report()
		"rest_point":
			if bool(state.get("Day02ReportSent", false)):
				_transition_to(SCENE_DAY02_END)
			else:
				_message("今日驻留报告尚未发送。")
		_:
			pass
	_save_state()

func _interact_day02_greenhouse() -> void:
	match current_target:
		"last_plant":
			_complete_day02_check("Day02LastPlantChecked", "植物生命信号：稳定\n补光输出：低功率稳定\n水循环供给：最低维持\n叶片反应：缓慢恢复\n\n生命信号仍然微弱。\n但比昨日稳定。")
		"water_panel":
			_complete_day02_check("Day02WaterChecked", "水循环状态：\n\n主循环：未恢复\n备用循环：低流量运行\n温室供水：最低维持\n建议：等待补给或进一步维修\n\n当前水循环只能维持最低需求。\n请避免扩大种植规模。")
		"monitor":
			_message("植物监测屏：\n\n生命信号：Stable\n根区温度：可维持\n补光：低功率稳定\n水循环：最低运行")
		"scanner":
			_message("诊断终端：\n\n未发现新的急性异常。\n建议每日重复观察叶片与根区状态。")
		"grow_light":
			_message("补光灯保持低功率运行。\n输出仍限制在安全范围内。")
		"exit":
			_transition_to(SCENE_INTERIOR)
		_:
			pass
	_save_state()

func _interact_week_interior() -> void:
	var day := _current_day()
	match current_target:
		"console":
			_complete_daily_check("DailyConsoleChecked", _weekly_console_text())
		"power_panel":
			if day == 3 or day == 5 or day == 7:
				_complete_daily_check("DailyPowerChecked", _weekly_power_text())
			else:
				_message("今日重点不是供电面板。\n当前供电仍维持基础运行。")
		"power_console":
			if day == 5:
				_complete_daily_check("DailySpecialChecked", "供电负载：\n\n基础照明：运行中\n生命支持：运行中\n温室补光：低功率运行\n剩余可用负载：有限\n\n建议：恢复外部太阳能阵列前，不要扩展温室。")
			else:
				_message("供电重启控制台保持待机。\n今日不需要重启供电。")
		"life_console":
			if day == 3 or day == 7:
				_complete_daily_check("DailyLifeSupportChecked", _weekly_life_text())
			else:
				_message("生命支持维持最低稳定。\n今日未检测到新的急性异常。")
		"greenhouse_door":
			if not bool(state.get("DailyConsoleChecked", false)):
				_message("请先查看中央控制台，确认今日巡检项目。")
			else:
				if day == 6:
					state["DailySpecialChecked"] = true
					_save_state()
				_transition_to(SCENE_GREENHOUSE)
		"report_terminal":
			if not _daily_checks_complete():
				_message("对地报告尚未解锁。\n请先完成今日巡检。")
			elif not bool(state.get("DailyReportPreviewed", false)):
				state["DailyReportPreviewed"] = true
				_message(_weekly_report_text() + "\n\n再次按 E / Enter 发送报告。")
			elif not bool(state.get("DailyReportSent", false)):
				_send_week_report()
		"rest_point":
			if bool(state.get("DailyReportSent", false)):
				_transition_to(SCENE_WEEK_END)
			else:
				_message("今日驻留报告尚未发送。")
		_:
			pass
	_save_state()

func _interact_week_greenhouse() -> void:
	var day := _current_day()
	match current_target:
		"last_plant":
			_complete_daily_check("DailyPlantChecked", _weekly_plant_text())
		"water_panel":
			if day == 4:
				if not bool(state.get("DailyWaterChecked", false)):
					_complete_daily_check("DailyWaterChecked", "水循环状态：\n\n主循环：未恢复\n备用循环：低流量运行\n温室供水：最低维持\n风险等级：需要持续观察")
				else:
					_complete_daily_check("DailySpecialChecked", "温室供水：\n\n当前供给：最低维持\n水分供给：可维持最后一株植物\n建议：下一阶段优先恢复水循环能力。")
			else:
				_message("备用水循环保持低流量运行。\n今日未执行新的水路调整。")
		"scanner":
			if day == 6:
				_complete_daily_check("DailyRecordUpdated", "植物状态记录已更新。\n\n新生组织迹象：微弱。\n建议继续维持当前环境。")
			else:
				_message("诊断终端：\n未发现新的急性异常。")
		"monitor":
			if day == 7:
				_complete_daily_check("DailyPlantChecked", _weekly_plant_text())
			else:
				_message("植物监测屏：\n\n生命信号：Stable\n补光：低功率稳定\n水循环：最低运行")
		"grow_light":
			_message("补光灯保持低功率运行。\n输出仍限制在安全范围内。")
		"exit":
			_transition_to(SCENE_INTERIOR)
		_:
			pass
	_save_state()

func _interact_interior() -> void:
	match current_target:
		"console":
			state["CentralConsoleChecked"] = true
			_message("广寒前哨状态摘要：\n\n主供电：低功率维持\n生命支持：最低运行\n温室系统：离线\n水循环：未稳定\n外部通信：延迟链路可用\n\n建议操作：\n恢复基础供电。\n\n日志片段 17-A：\n温室补光效率继续下降。\n备用水循环还能维持一段时间。\n如果下一位开拓者抵达，\n请先检查中央植物舱。")
		"power_panel":
			if not bool(state.get("CentralConsoleChecked", false)):
				_message("请先查看中央控制台。")
			elif not bool(state.get("PowerPanelChecked", false)):
				state["PowerPanelChecked"] = true
				_message("检测到旧供电面板断路。\n备用线路仍可用。\n可执行基础恢复。")
			elif not bool(state.get("PowerPanelRepaired", false)):
				_run_delayed_message("正在接入备用线路……", "备用线路已接入。", {"PowerPanelRepaired": true})
		"power_console":
			if not bool(state.get("PowerPanelRepaired", false)):
				_message("旧供电面板尚未恢复。")
			elif not bool(state.get("BasePowerRestored", false)):
				state["BasePowerRestored"] = true
				_message("基础供电已恢复。")
		"life_console":
			if not bool(state.get("BasePowerRestored", false)):
				_message("生命支持控制台供电不足。")
			elif not bool(state.get("LifeSupportConsoleChecked", false)):
				state["LifeSupportConsoleChecked"] = true
				_message("氧气状态：安全但偏低\n温度状态：偏低\n水循环状态：未稳定\n电力状态：基础供电")
			elif not bool(state.get("MinimalLifeSupportStable", false)):
				_run_delayed_message("最低生命支持程序启动。\n正在恢复空气循环。\n正在提升基础温度。\n水循环仍未完全稳定。", "生命支持状态：最低稳定\n氧气状态：稳定\n温度状态：可维持\n水循环状态：部分恢复\n\n温室门已解锁。", {"MinimalLifeSupportStable": true, "GreenhouseUnlocked": true})
		"greenhouse_door":
			if bool(state.get("GreenhouseUnlocked", false)):
				_transition_to(SCENE_GREENHOUSE)
			else:
				_message("温室门锁定。\n需要基础供电与生命支持稳定。")
		"rest_point":
			if bool(state.get("LastPlantStable", false)):
				_transition_to(SCENE_DAY_END)
			else:
				_message("现在还不能休息。\n温室仍需要检查。")
		_:
			pass
	_save_state()

func _interact_greenhouse() -> void:
	if not bool(state.get("LastPlantDiscovered", false)) and current_target == "last_plant":
		_discover_last_plant()
		return
	match current_target:
		"last_plant":
			if not bool(state.get("LastPlantObserved", false)):
				state["LastPlantObserved"] = true
				_message("叶片颜色偏浅。\n茎部仍有微弱支撑。\n基质表面偏干。")
			elif bool(state.get("LastPlantStable", false)):
				_message("生命信号稳定。\n这一区域仍需要保持安静。")
		"monitor":
			state["PlantMonitorChecked"] = true
			_message("补光输出：不足\n水循环：中断\n根区温度：偏低\n生命信号：极弱")
		"scanner":
			if not bool(state.get("LastPlantObserved", false)) or not bool(state.get("PlantMonitorChecked", false)):
				_message("诊断信息不足。\n请先观察植物并查看监测屏。")
			else:
				state["LastPlantDiagnosed"] = true
				_message("诊断结果：\n补光不足。\n最低水循环中断。\n\n当前目标：恢复补光与水循环。")
		"grow_light":
			if not bool(state.get("LastPlantDiagnosed", false)):
				_message("请先完成植物诊断。")
			elif not bool(state.get("GrowLightRestored", false)):
				_run_delayed_message("正在重启补光灯。\n输出功率限制在安全范围内。", "补光恢复。", {"GrowLightRestored": true})
		"water_panel":
			if not bool(state.get("LastPlantDiagnosed", false)):
				_message("请先完成植物诊断。")
			elif not bool(state.get("PartialWaterCycleRestored", false)):
				_run_delayed_message("正在接入备用水循环。\n流量限制：低。", "最低水循环恢复。", {"PartialWaterCycleRestored": true})
		"exit":
			if bool(state.get("LastPlantStable", false)):
				_transition_to(SCENE_DAY_END)
			else:
				_message("温室生命信号尚未稳定。")
		_:
			pass
	if bool(state.get("GrowLightRestored", false)) and bool(state.get("PartialWaterCycleRestored", false)) and not bool(state.get("LastPlantStable", false)):
		_stabilize_last_plant()
	_save_state()

func _start_airlock_sequence() -> void:
	input_enabled = false
	sequence_running = true
	message_text = ""
	await _append_sequence_line("外舱门已关闭。")
	await _append_sequence_line("舱压建立中。")
	await _append_sequence_line("氧气交换完成。")
	await _append_sequence_line("内舱门已解锁。")
	state["BaseEntered"] = true
	_save_state()
	await get_tree().create_timer(0.55).timeout
	_transition_to(SCENE_INTERIOR)

func _append_sequence_line(line: String) -> void:
	message_text += line if message_text.is_empty() else "\n" + line
	await get_tree().create_timer(0.85).timeout

func _show_first_ai_line() -> void:
	sequence_running = true
	input_enabled = false
	ai_text = "欢迎回来。"
	await get_tree().create_timer(1.8).timeout
	ai_text = "广寒前哨，等待新的开拓者，已经很久了。"
	await get_tree().create_timer(2.4).timeout
	ai_text = ""
	state["AIGreetingPlayed"] = true
	_save_state()
	input_enabled = true
	sequence_running = false

func _start_day02_sequence() -> void:
	sequence_running = true
	input_enabled = false
	state["DayNumber"] = 2
	state["Day02Started"] = true
	state["BasePowerRestored"] = true
	state["MinimalLifeSupportStable"] = true
	state["GreenhouseUnlocked"] = true
	state["LastPlantStable"] = true
	state["LastPlantStatus"] = "Stable"
	_save_state()
	message_text = "第 2 天"
	await get_tree().create_timer(1.15).timeout
	message_text = "广寒前哨 · 旧基地"
	await get_tree().create_timer(1.15).timeout
	message_text = ""
	ai_text = "早间状态简报。\n基础供电维持。\n最低生命支持维持。\n温室生命信号维持稳定。"
	await get_tree().create_timer(2.5).timeout
	ai_text = "建议执行今日巡检。\n\n今日优先级：\n确认供电。\n确认生命支持。\n确认水循环。\n确认最后一株植物状态。"
	await get_tree().create_timer(2.8).timeout
	ai_text = ""
	input_enabled = true
	sequence_running = false
	_transition_to(SCENE_INTERIOR)

func _start_week_day_sequence() -> void:
	sequence_running = true
	input_enabled = false
	var day: int = clamp(_current_day(), 3, 7)
	_reset_daily_flags(day)
	state["BasePowerRestored"] = true
	state["MinimalLifeSupportStable"] = true
	state["GreenhouseUnlocked"] = true
	state["LastPlantStable"] = true
	state["LastPlantStatus"] = "Stable"
	_save_state()
	message_text = "第 %d 天" % day
	await get_tree().create_timer(1.05).timeout
	message_text = "广寒前哨 · 旧基地"
	await get_tree().create_timer(1.05).timeout
	message_text = ""
	ai_text = _weekly_morning_text()
	await get_tree().create_timer(3.0).timeout
	ai_text = ""
	input_enabled = true
	sequence_running = false
	_transition_to(SCENE_INTERIOR)

func _weekly_morning_text() -> String:
	match _current_day():
		3:
			return "早间状态简报。\n基础供电维持。\n最低生命支持维持。\n温室生命信号维持稳定。\n建议继续执行日常巡检。"
		4:
			return "早间状态简报。\n供电维持。\n生命支持维持。\n水循环仍处于低流量运行。\n建议优先检查温室供水。"
		5:
			return "早间状态简报。\n基础供电维持。\n当前负载接近安全上限。\n不建议接入新的高功率设备。"
		6:
			return "早间状态简报。\n温室生命信号维持稳定。\n植物反应数据出现微弱改善。\n建议进行近距观察。"
		7:
			return "早间状态简报。\n第一周驻留周期即将完成。\n建议执行周度状态复核。"
	return "早间状态简报。"

func _weekly_console_text() -> String:
	if _current_day() == 7:
		return "第一周状态复核：\n\n基础供电：维持\n生命支持：最低稳定\n水循环：低流量运行\n温室生命信号：稳定\n人员状态：可继续驻留\n\n结论：广寒前哨已从离线边缘恢复至最低稳定状态。"
	return "广寒前哨 %s 状态摘要：\n\n基础供电：维持\n生命支持：最低稳定\n水循环：低流量运行\n温室生命信号：稳定\n人员状态：可继续驻留\n\n今日重点：\n%s" % [_day_label(), _weekly_focus_text()]

func _weekly_focus_text() -> String:
	match _current_day():
		3:
			return "确认重复巡检本身可以维持基地运行。"
		4:
			return "观察水循环与温室供水。"
		5:
			return "确认供电负载限制。"
		6:
			return "记录最后一株植物的微弱恢复迹象。"
		7:
			return "完成第一周驻留报告。"
	return "执行日常巡检。"

func _weekly_power_text() -> String:
	if _current_day() == 5:
		return "供电面板状态：\n\n基础照明：运行中\n生命支持：运行中\n温室补光：低功率运行\n剩余可用负载：有限\n\n当前供电不足以支持温室扩展。"
	if _current_day() == 7:
		return "供电状态复核：\n\n基础供电：维持\n备用线路：运行中\n扩展负载：不建议接入"
	return "供电面板状态：\n\n备用线路：运行中\n当前输出：基础供电\n风险等级：可控\n\n连续稳定运行：24 小时。"

func _weekly_life_text() -> String:
	if _current_day() == 7:
		return "生命支持状态复核：\n\n氧气：稳定\n温度：可维持\n空气循环：低速运行\n过滤组件：需要持续观察"
	return "生命支持状态：\n\n氧气：稳定\n温度：可维持\n空气循环：低速运行\n当前环境适合短期驻留。"

func _weekly_plant_text() -> String:
	match _current_day():
		4:
			return "植物生命信号：稳定\n水分供给：最低维持\n叶片反应：缓慢恢复"
		6:
			return "叶片颜色略有恢复。\n茎部支撑增强。\n新生组织迹象：微弱。\n\n生命信号仍然微弱。\n但它正在恢复。"
		7:
			return "温室生命信号复核：\n\n生命信号：稳定\n补光输出：低功率稳定\n水循环供给：最低维持"
	return "植物生命信号：稳定\n补光输出：低功率稳定\n水循环供给：最低维持\n叶片反应：缓慢恢复"

func _weekly_report_text() -> String:
	match _current_day():
		3:
			return "广寒前哨 D03 驻留报告\n\n基础供电：维持\n生命支持：最低稳定\n温室生命信号：稳定\n人员状态：可继续驻留\n\n备注：第一轮日常巡检完成。\n系统状态未出现进一步恶化。"
		4:
			return "广寒前哨 D04 驻留报告\n\n基础供电：维持\n生命支持：最低稳定\n水循环：低流量运行\n温室生命信号：稳定\n\n备注：温室供水仍处于最低维持状态。\n建议下一阶段优先恢复水循环能力。"
		5:
			return "广寒前哨 D05 驻留报告\n\n基础供电：维持\n生命支持：最低稳定\n温室补光：低功率运行\n剩余负载：有限\n\n备注：当前供电不足以支持温室扩展。\n建议优先评估外部太阳能阵列。"
		6:
			return "广寒前哨 D06 驻留报告\n\n温室生命信号：稳定\n植物恢复迹象：微弱\n补光输出：低功率稳定\n水循环：最低维持\n\n备注：最后一株植物出现轻微恢复迹象。\n建议继续维持当前环境。"
		7:
			return "广寒前哨 第一周驻留报告\n\n驻留周期：D01-D07\n基础供电：恢复并维持\n生命支持：最低稳定\n水循环：低流量运行\n温室生命信号：稳定\n人员状态：可继续驻留\n\n重点记录：旧温室中最后一株存活植物已稳定。\n广寒前哨具备继续驻留条件。\n但不具备扩展建设条件。\n\n下一阶段建议：\n评估外部太阳能阵列。\n恢复更高等级供电。\n准备温室系统进一步修复。"
	return ""

func _send_day02_report() -> void:
	sequence_running = true
	input_enabled = false
	message_text = "报告已发送。\n通信延迟：1.3 秒。"
	await get_tree().create_timer(1.45).timeout
	message_text = "地面确认收到。"
	await get_tree().create_timer(1.2).timeout
	message_text = "广寒计划地面任务组：\n已记录温室生命信号。\n后续任务建议正在生成。"
	state["Day02ReportSent"] = true
	state["ArchiveEntry_Day02Report"] = true
	_save_state()
	await get_tree().create_timer(1.8).timeout
	input_enabled = true
	sequence_running = false

func _send_week_report() -> void:
	sequence_running = true
	input_enabled = false
	if _current_day() == 7:
		message_text = "第一周驻留报告已发送。\n通信延迟：1.3 秒。"
	else:
		message_text = "%s 驻留报告已发送。\n通信延迟：1.3 秒。" % _day_label()
	await get_tree().create_timer(1.35).timeout
	message_text = "地面确认收到。"
	await get_tree().create_timer(1.1).timeout
	if _current_day() == 7:
		message_text = "广寒计划地面任务组：\n第一周驻留记录已归档。\n下一阶段任务建议正在生成。"
		state["WeekOneReportSent"] = true
		state["Archive_WeekOne_Report"] = true
	else:
		message_text = "广寒计划地面任务组：\n%s 驻留记录已归档。\n后续建议正在生成。" % _day_label()
		state["Archive_Day%02d_Report" % _current_day()] = true
	state["DailyReportSent"] = true
	_save_state()
	await get_tree().create_timer(1.7).timeout
	input_enabled = true
	sequence_running = false

func _discover_last_plant() -> void:
	sequence_running = true
	input_enabled = false
	message_text = "检测到植物生命信号。"
	await get_tree().create_timer(1.2).timeout
	message_text = "生命信号极弱。"
	await get_tree().create_timer(1.2).timeout
	message_text = "这是温室中最后一株存活植物。"
	state["LastPlantDiscovered"] = true
	state["LastPlantStatus"] = "Critical"
	_save_state()
	await get_tree().create_timer(1.5).timeout
	input_enabled = true
	sequence_running = false

func _stabilize_last_plant() -> void:
	sequence_running = true
	input_enabled = false
	message_text = "植物生命信号正在回升。"
	await get_tree().create_timer(1.35).timeout
	message_text = "生命信号稳定。"
	await get_tree().create_timer(1.1).timeout
	message_text = "温室生命支持记录已更新。\n\n它还活着。"
	state["LastPlantStable"] = true
	state["LastPlantStatus"] = "Stable"
	_save_state()
	await get_tree().create_timer(1.8).timeout
	input_enabled = true
	sequence_running = false

func _run_delayed_message(start_text: String, done_text: String, updates: Dictionary) -> void:
	sequence_running = true
	input_enabled = false
	message_text = start_text
	await get_tree().create_timer(1.25).timeout
	for key in updates.keys():
		state[key] = updates[key]
	message_text = done_text
	_save_state()
	await get_tree().create_timer(0.9).timeout
	input_enabled = true
	sequence_running = false

func _finish_day_one() -> void:
	state["Day01Completed"] = true
	_save_state()
	input_enabled = false
	message_text = "Day 01 记录：\n\n基础供电恢复。\n最低生命支持恢复。\n温室生命信号稳定。"
	ai_text = "第一日驻留记录已保存。"
	await get_tree().create_timer(2.2).timeout
	ai_text = "欢迎回家。"
	await get_tree().create_timer(1.6).timeout
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	await tween.finished
	message_text = "第 1 天结束"
	message_label.modulate = Color("#eaf4ff", 1.0)
	await get_tree().create_timer(2.5).timeout
	get_tree().change_scene_to_file(SCENE_DAY02_START)

func _finish_day_two() -> void:
	state["Day02Completed"] = true
	state["DayNumber"] = 2
	state["CurrentDay"] = 3
	_save_state()
	input_enabled = false
	message_text = "Day 02 记录：\n\n基础巡检完成。\n温室生命信号维持稳定。\n对地驻留报告已发送。"
	ai_text = "第二日驻留记录已保存。"
	await get_tree().create_timer(2.2).timeout
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	await tween.finished
	ai_text = ""
	message_text = "第 2 天结束"
	message_label.modulate = Color("#eaf4ff", 1.0)
	await get_tree().create_timer(2.4).timeout
	get_tree().change_scene_to_file(SCENE_WEEK_START)

func _finish_week_day() -> void:
	var day := _current_day()
	state["DayCompleted"] = true
	state["Day%02dCompleted" % day] = true
	state["DayNumber"] = day
	if day == 7:
		state["WeekOneCompleted"] = true
	_save_state()
	input_enabled = false
	message_text = "%s 记录：\n\n今日巡检完成。\n温室生命信号维持稳定。\n对地驻留报告已发送。" % _day_label()
	if day == 7:
		message_text = "第一周记录：\n\n周度复核完成。\n第一周驻留报告已发送。\n广寒前哨恢复至最低稳定状态。"
	ai_text = "%s 驻留记录已保存。" % _day_label()
	await get_tree().create_timer(2.1).timeout
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	await tween.finished
	ai_text = ""
	if day == 7:
		message_text = "第一周结束"
		await get_tree().create_timer(1.5).timeout
		message_text = "广寒前哨已恢复至最低稳定状态。"
		await get_tree().create_timer(1.7).timeout
		message_text = "后续内容开发中"
		await get_tree().create_timer(1.4).timeout
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		message_text = "第 %d 天结束" % day
		await get_tree().create_timer(1.8).timeout
		state["CurrentDay"] = day + 1
		state["DayNumber"] = day + 1
		state["DayStarted"] = false
		state["DayCompleted"] = false
		_save_state()
		get_tree().change_scene_to_file(SCENE_WEEK_START)

func _message(text: String) -> void:
	message_text = text

func _transition_to(scene_path: String) -> void:
	input_enabled = false
	sequence_running = true
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.45)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)

func _update_ui() -> void:
	hud_label.text = _hud_text()
	message_label.text = message_text
	prompt_label.text = _prompt_text()
	ai_label.text = ai_text

func _hud_text() -> String:
	var power := "基础供电" if bool(state.get("BasePowerRestored", false)) else "低"
	var life := "最低稳定" if bool(state.get("MinimalLifeSupportStable", false)) else "最低运行"
	var temp := "可维持" if bool(state.get("MinimalLifeSupportStable", false)) else "偏低"
	var oxygen := "稳定" if bool(state.get("MinimalLifeSupportStable", false)) else "安全"
	var plant := String(state.get("LastPlantStatus", "Critical"))
	if scene_kind == "day02_start":
		return _safe_hud_text("广寒前哨 · 居住舱", "Stable", "", objective_text)
	if scene_kind == "day02_end":
		return _safe_hud_text("广寒前哨 · 居住舱", "Stable", "", objective_text)
	if scene_kind == "week_start" or scene_kind == "week_end":
		return _safe_hud_text("广寒前哨 · Day %02d · 居住舱" % _current_day(), "Stable", "", objective_text)
	if _is_day02_active():
		var checklist := _task_line("检查供电面板", "Day02PowerChecked")
		checklist += "\n" + _task_line("检查生命支持控制台", "Day02LifeSupportChecked")
		checklist += "\n" + _task_line("检查水循环状态", "Day02WaterChecked")
		checklist += "\n" + _task_line("检查最后一株植物", "Day02LastPlantChecked")
		checklist += "\n" + _task_line("发送 Day 02 对地报告", "Day02ReportSent")
		var zone := "旧温室" if scene_kind == "greenhouse" else "旧基地"
		return _safe_hud_text("广寒前哨 · Day 02 · %s" % zone, "Stable", checklist, objective_text)
	if _is_week_routine_active():
		var zone := "旧温室" if scene_kind == "greenhouse" else "旧基地"
		return _safe_hud_text("广寒前哨 · %s · %s" % [_day_label(), zone], "Stable", _daily_checklist_text(), objective_text)
	if scene_kind == "greenhouse":
		return _safe_hud_text("广寒前哨 · 旧温室", plant, "", objective_text, power, oxygen, temp, life)
	if scene_kind == "day_end":
		return _safe_hud_text("广寒前哨 · 居住舱", plant, "", objective_text, power, oxygen, temp, life)
	return _safe_hud_text("广寒前哨 · 旧基地", plant, "", objective_text, power, oxygen, temp, life)

func _safe_hud_text(title: String, plant: String, checklist: String, objective: String, power: String = "基础供电", oxygen: String = "稳定", temp: String = "可维持", life: String = "最低稳定") -> String:
	var text := "%s\n\n系统状态\n电力：%s\n氧气：%s\n温度：%s\n生命支持：%s\n植物生命信号：%s" % [title, power, oxygen, temp, life, plant]
	if not checklist.is_empty():
		text += "\n\n今日巡检\n%s" % checklist
	text += "\n\n当前目标\n> %s" % objective
	return text

func _task_line(label: String, key: String) -> String:
	return "✓ %s" % label if bool(state.get(key, false)) else "□ %s" % label

func _prompt_text() -> String:
	if not input_enabled:
		return ""
	if _is_day02_active():
		match scene_kind:
			"interior":
				match current_target:
					"console":
						return "E / Enter 查看中央控制台"
					"power_panel":
						return "E / Enter 检查供电面板"
					"life_console":
						return "E / Enter 检查生命支持"
					"greenhouse_door":
						return "E / Enter 进入旧温室"
					"report_terminal":
						return "E / Enter 发送对地报告" if _day02_inspections_complete() else "对地报告待解锁"
					"rest_point":
						return "E / Enter 返回居住舱休息"
			"greenhouse":
				match current_target:
					"last_plant":
						return "E / Enter 检查最后一株植物"
					"water_panel":
						return "E / Enter 检查水循环"
					"monitor":
						return "E / Enter 查看植物监测屏"
					"scanner":
						return "E / Enter 查看诊断终端"
					"grow_light":
						return "E / Enter 查看补光灯"
					"exit":
						return "E / Enter 返回旧基地"
	if _is_week_routine_active():
		match scene_kind:
			"interior":
				match current_target:
					"console":
						return "E / Enter 查看中央控制台"
					"power_panel":
						return "E / Enter 检查供电面板"
					"power_console":
						return "E / Enter 检查当前负载"
					"life_console":
						return "E / Enter 检查生命支持"
					"greenhouse_door":
						return "E / Enter 进入旧温室"
					"report_terminal":
						return "E / Enter 发送%s" % _daily_report_label() if _daily_checks_complete() else "对地报告待解锁"
					"rest_point":
						return "E / Enter 返回居住舱休息"
			"greenhouse":
				match current_target:
					"last_plant":
						return "E / Enter 检查最后一株植物"
					"water_panel":
						return "E / Enter 检查水循环"
					"monitor":
						return "E / Enter 查看植物监测屏"
					"scanner":
						return "E / Enter 更新植物状态记录"
					"grow_light":
						return "E / Enter 查看补光灯"
					"exit":
						return "E / Enter 返回旧基地"
	match scene_kind:
		"interior":
			match current_target:
				"console":
					return "E / Enter 查看中央控制台"
				"power_panel":
					return "E / Enter 检查 / 维修旧供电面板"
				"power_console":
					return "E / Enter 重启供电"
				"life_console":
					return "E / Enter 使用生命支持控制台"
				"greenhouse_door":
					return "E / Enter 进入旧温室"
				"rest_point":
					return "E / Enter 前往居住舱休息"
		"greenhouse":
			match current_target:
				"last_plant":
					return "E / Enter 观察最后一株植物"
				"monitor":
					return "E / Enter 查看植物监测屏"
				"scanner":
					return "E / Enter 使用诊断终端"
				"grow_light":
					return "E / Enter 恢复补光"
				"water_panel":
					return "E / Enter 恢复水循环"
				"exit":
					return "E / Enter 返回居住舱"
		"day_end":
			if current_target == "sleep":
				return "E / Enter 休息"
		"day02_end":
			if current_target == "sleep":
				return "E / Enter 休息"
		"week_end":
			if current_target == "sleep":
				return "E / Enter 休息"
	return ""

func _draw() -> void:
	match scene_kind:
		"airlock":
			_draw_airlock()
		"greenhouse":
			_draw_greenhouse()
		"day_end":
			_draw_day_end()
		"day02_start", "day02_end":
			_draw_day_end()
		"week_start", "week_end":
			_draw_day_end()
		"solar_array":
			_draw_solar_array()
		_:
			_draw_interior()

func _draw_solar_array() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1600, 900)), Color("#03070d"), true)
	for i in range(80):
		var x := float((i * 97) % 1560 + 20)
		var y := float((i * 53) % 250 + 30)
		draw_circle(Vector2(x, y), 1.0, Color("#d8e7f2", 0.28))
	var horizon := PackedVector2Array([
		Vector2(0, 390), Vector2(180, 332), Vector2(360, 370), Vector2(560, 320),
		Vector2(780, 360), Vector2(980, 312), Vector2(1220, 350), Vector2(1600, 300),
		Vector2(1600, 900), Vector2(0, 900)
	])
	draw_colored_polygon(horizon, Color("#24282b"))
	var surface := PackedVector2Array([
		Vector2(0, 500), Vector2(1600, 430), Vector2(1600, 900), Vector2(0, 900)
	])
	draw_colored_polygon(surface, Color("#343637"))
	for i in range(28):
		var p := Vector2(40 + i * 62, 530 + sin(float(i) * 0.7) * 54)
		draw_ellipse(p, 18, 6, Color("#1c2022", 0.36))
	draw_string(ThemeDB.fallback_font, Vector2(620, 804), "EXTERIOR / SOLAR ARRAY PREP", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#9fb2c0"))

func _draw_interior() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1600, 900)), Color("#071019"), true)
	var room := Rect2(Vector2(90, 170), Vector2(1420, 620))
	draw_rect(room, Color("#171f25"), true)
	for x in range(int(room.position.x), int(room.end.x), 64):
		draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), Color("#2c3840", 0.38), 1)
	for y in range(int(room.position.y), int(room.end.y), 64):
		draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color("#2c3840", 0.38), 1)
	draw_rect(room, Color("#566672"), false, 4)
	var warmth := 0.08 if bool(state.get("BasePowerRestored", false)) else 0.0
	draw_rect(room.grow(-24), Color("#f0c766", warmth), true)
	for light_x in [310, 780, 1250]:
		var light_color := Color("#f0c766", 0.54) if bool(state.get("BasePowerRestored", false)) else Color("#65727a", 0.18)
		draw_rect(Rect2(Vector2(light_x, 190), Vector2(140, 10)), light_color, true)
	_draw_console(interior_targets["console"], bool(state.get("BasePowerRestored", false)), "中央控制台")
	_draw_panel(interior_targets["power_panel"], bool(state.get("PowerPanelRepaired", false)), "旧供电面板")
	_draw_console(interior_targets["power_console"], bool(state.get("BasePowerRestored", false)), "供电重启")
	_draw_console(interior_targets["life_console"], bool(state.get("MinimalLifeSupportStable", false)), "生命支持")
	_draw_console(interior_targets["report_terminal"], bool(state.get("Day02ReportSent", false)), "对地报告")
	_draw_door(interior_targets["greenhouse_door"], bool(state.get("GreenhouseUnlocked", false)), "旧温室")
	_draw_storage_and_life()
	_draw_target_highlight()

func _draw_storage_and_life() -> void:
	draw_rect(Rect2(Vector2(210, 310), Vector2(130, 210)), Color("#313940"), true)
	draw_rect(Rect2(Vector2(225, 328), Vector2(46, 70)), Color("#202932"), true)
	draw_rect(Rect2(Vector2(280, 328), Vector2(46, 70)), Color("#202932"), true)
	draw_string(ThemeDB.fallback_font, Vector2(208, 550), "旧储物柜 / 03-B / SEED TOOLS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#8fa3b2"))
	draw_rect(Rect2(Vector2(210, 610), Vector2(200, 64)), Color("#273037"), true)
	draw_string(ThemeDB.fallback_font, Vector2(226, 650), "值班表：第17批", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#9fb2c0"))
	draw_string(ThemeDB.fallback_font, Vector2(1220, 228), "GHO-03 / LIFE SUPPORT BAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8fa3b2", 0.82))
	draw_rect(Rect2(Vector2(1040, 596), Vector2(210, 54)), Color("#2a3034"), true)
	draw_string(ThemeDB.fallback_font, Vector2(1054, 630), "维护贴纸：先查温室", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b7a878"))
	draw_rect(Rect2(Vector2(640, 612), Vector2(148, 58)), Color("#202830"), true)
	draw_string(ThemeDB.fallback_font, Vector2(654, 648), "LOG 17-A", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8fa3b2"))
	for i in range(14):
		draw_circle(Vector2(410 + i * 70, 710 + sin(float(i)) * 18), 4, Color("#6b6258", 0.28))
	for i in range(7):
		var p := Vector2(530 + i * 54, 620 + sin(float(i) * 0.7) * 12)
		draw_ellipse(p, 9, 4, Color("#7b6e5d", 0.20))

func _draw_greenhouse() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1600, 900)), Color("#06100d"), true)
	var room := Rect2(Vector2(90, 150), Vector2(1420, 650))
	draw_rect(room, Color("#14201c"), true)
	draw_rect(room, Color("#456055", 0.65), false, 4)
	for i in range(6):
		var shelf := Rect2(Vector2(170 + i * 190, 250), Vector2(130, 270))
		draw_rect(shelf, Color("#25342e"), true)
		draw_rect(shelf, Color("#53665a", 0.45), false, 2)
		for j in range(3):
			var y := shelf.position.y + 50 + j * 70
			draw_line(Vector2(shelf.position.x + 16, y), Vector2(shelf.end.x - 16, y + 12), Color("#766d55", 0.48), 4)
			draw_circle(Vector2(shelf.position.x + 36 + j * 26, y - 10), 9, Color("#3c4a35", 0.28))
	_draw_last_plant(greenhouse_targets["last_plant"])
	_draw_plant_monitor(greenhouse_targets["monitor"])
	_draw_console(greenhouse_targets["scanner"], bool(state.get("LastPlantDiagnosed", false)), "诊断终端")
	_draw_grow_light(greenhouse_targets["grow_light"], bool(state.get("GrowLightRestored", false)))
	_draw_panel(greenhouse_targets["water_panel"], bool(state.get("PartialWaterCycleRestored", false)), "水循环")
	_draw_door(greenhouse_targets["exit"], bool(state.get("LastPlantStable", false)), "居住舱")
	_draw_target_highlight()

func _draw_airlock() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1600, 900)), Color("#05080d"), true)
	var chamber := Rect2(Vector2(510, 170), Vector2(580, 500))
	draw_rect(chamber, Color("#19242c"), true)
	draw_rect(chamber, Color("#81929d", 0.75), false, 5)
	var outer_door := Rect2(Vector2(525, 330), Vector2(86, 210))
	var inner_door := Rect2(Vector2(989, 330), Vector2(86, 210))
	draw_rect(outer_door, Color("#2c3740"), true)
	draw_rect(outer_door.grow(-12), Color("#111a22"), true)
	draw_line(Vector2(outer_door.get_center().x, outer_door.position.y + 18), Vector2(outer_door.get_center().x, outer_door.end.y - 18), Color("#8fa3b2", 0.42), 2)
	draw_rect(inner_door, Color("#2c3740"), true)
	draw_rect(inner_door.grow(-12), Color("#111a22"), true)
	draw_line(Vector2(inner_door.get_center().x, inner_door.position.y + 18), Vector2(inner_door.get_center().x, inner_door.end.y - 18), Color("#f0c766", 0.38), 2)
	for x in [650, 790, 930]:
		draw_rect(Rect2(Vector2(x, 220), Vector2(86, 10)), Color("#89d8ff", 0.22), true)
	var status_panel := Rect2(Vector2(690, 572), Vector2(220, 48))
	draw_rect(status_panel, Color("#101820"), true)
	draw_rect(status_panel, Color("#5d6f7d", 0.45), false, 1)
	for i in range(3):
		var active_alpha := 0.74 if message_text.split("\n").size() > i else 0.20
		draw_circle(status_panel.position + Vector2(42 + i * 66, 24), 10, Color("#89d8ff", active_alpha))
	draw_string(ThemeDB.fallback_font, Vector2(666, 735), "BASE AIRLOCK / 广寒前哨旧气闸", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#9fb2c0"))
	draw_string(ThemeDB.fallback_font, outer_door.position + Vector2(-10, -16), "外舱门", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#8fa3b2"))
	draw_string(ThemeDB.fallback_font, inner_door.position + Vector2(-8, -16), "内舱门", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#8fa3b2"))

func _draw_day_end() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1600, 900)), Color("#070c12"), true)
	var room := Rect2(Vector2(210, 160), Vector2(1180, 610))
	draw_rect(room, Color("#1a1d20"), true)
	draw_rect(room, Color("#5d6f7d", 0.5), false, 4)
	draw_rect(Rect2(Vector2(530, 480), Vector2(380, 142)), Color("#2d3032"), true)
	draw_rect(Rect2(Vector2(560, 508), Vector2(310, 76)), Color("#756d60"), true)
	draw_rect(Rect2(Vector2(560, 508), Vector2(120, 76)), Color("#8b8172"), true)
	draw_line(Vector2(695, 510), Vector2(860, 578), Color("#4d504c", 0.42), 3)
	draw_rect(Rect2(Vector2(1070, 238), Vector2(180, 116)), Color("#101720"), true)
	draw_rect(Rect2(Vector2(1084, 252), Vector2(152, 88)), Color("#23313b"), false, 2)
	draw_circle(Vector2(1158, 294), 24, Color("#4faee8", 0.72))
	draw_circle(Vector2(1158, 294), 40, Color("#4faee8", 0.08))
	draw_rect(Rect2(Vector2(360, 420), Vector2(120, 170)), Color("#303840"), true)
	draw_string(ThemeDB.fallback_font, Vector2(370, 620), "旧储物箱：个人物品已封存", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#9fb2c0"))
	draw_rect(Rect2(Vector2(430, 390), Vector2(58, 36)), Color("#6b6258"), true)
	draw_circle(Vector2(458, 388), 8, Color("#8c7f6b"))
	draw_string(ThemeDB.fallback_font, Vector2(380, 384), "旧杯子", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8fa3b2"))
	draw_rect(Rect2(Vector2(968, 496), Vector2(180, 64)), Color("#252c32"), true)
	draw_string(ThemeDB.fallback_font, Vector2(986, 534), "墙面便签：温室优先", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#b7a878"))
	draw_rect(Rect2(Vector2(300, 650), Vector2(180, 46)), Color("#242b31"), true)
	draw_string(ThemeDB.fallback_font, Vector2(318, 681), "CRATE / 17-C", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#8fa3b2"))
	draw_circle(Vector2(610, 468), 48, Color("#f0c766", 0.09))
	draw_rect(Rect2(Vector2(590, 418), Vector2(42, 20)), Color("#f0c766", 0.38), true)
	var title := "广寒前哨 · 居住舱" if scene_kind == "day_end" or scene_kind == "day02_start" or scene_kind == "day02_end" else "广寒前哨 · 旧基地"
	if scene_title_alpha > 0.01:
		draw_string(ThemeDB.fallback_font, Vector2(710, 728), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#eaf4ff", scene_title_alpha))

func _draw_console(rect: Rect2, active: bool, label: String) -> void:
	draw_rect(rect, Color("#303940"), true)
	draw_rect(rect.grow(-12), Color("#101820"), true)
	var screen := Color("#236fa8", 0.8) if active else Color("#40505a", 0.38)
	draw_rect(Rect2(rect.position + Vector2(24, 20), Vector2(rect.size.x - 48, 28)), screen, true)
	draw_rect(Rect2(rect.position + Vector2(26, rect.size.y - 28), Vector2(rect.size.x - 52, 6)), Color("#f0c766", 0.32 if active else 0.12), true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, -8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#c8d8e2"))

func _draw_panel(rect: Rect2, repaired: bool, label: String) -> void:
	draw_rect(rect, Color("#2d3438"), true)
	draw_rect(rect.grow(-10), Color("#111820"), true)
	draw_rect(rect, Color("#d66a4f", 0.58 if not repaired else 0.12), false, 3)
	for i in range(4):
		draw_line(rect.position + Vector2(22 + i * 24, 38), rect.position + Vector2(30 + i * 24, 92), Color("#b45a56", 0.65 if not repaired else 0.14), 2)
	draw_circle(rect.position + Vector2(rect.size.x - 20, 22), 6, Color("#d66a4f", 0.85 if not repaired else 0.18))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(6, -8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#c8d8e2"))

func _draw_door(rect: Rect2, unlocked: bool, label: String) -> void:
	draw_rect(rect, Color("#2c3740"), true)
	draw_rect(rect.grow(-12), Color("#141c24"), true)
	var edge := Color("#9fb2c0", 0.54) if unlocked else Color("#8fa3b2", 0.26)
	draw_rect(rect, edge, false, 3)
	draw_line(Vector2(rect.get_center().x, rect.position.y + 14), Vector2(rect.get_center().x, rect.end.y - 14), Color("#d8e7f2", 0.34), 2)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(-6, -8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#c8d8e2"))
	if not unlocked:
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(18, rect.size.y * 0.55), "锁定", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8fa3b2"))

func _draw_grow_light(rect: Rect2, active: bool) -> void:
	var c := Color("#f0d28c", 0.72) if active else Color("#6f8493", 0.18)
	draw_rect(rect, Color("#2d353a"), true)
	draw_rect(rect.grow(-12), c, true)
	if active:
		draw_circle(Vector2(805, 365), 190, Color("#f0d28c", 0.08))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, -8), "旧补光灯", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#c8d8e2"))

func _draw_plant_monitor(rect: Rect2) -> void:
	var stable := bool(state.get("LastPlantStable", false))
	_draw_console(rect, stable or bool(state.get("LastPlantDiagnosed", false)), "植物监测屏")
	var status := "Stable" if stable else "Critical"
	var status_color := Color("#7dbd75", 0.85) if stable else Color("#d66a4f", 0.88)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(28, 68), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, status_color)
	draw_rect(Rect2(rect.position + Vector2(24, 74), Vector2(rect.size.x - 48, 5)), status_color, true)

func _draw_last_plant(rect: Rect2) -> void:
	var stable := bool(state.get("LastPlantStable", false))
	var glow := Color("#7dbd75", 0.18 if stable else 0.035)
	draw_circle(rect.get_center(), 92, glow)
	draw_rect(rect, Color("#1b2b28") if stable else Color("#16211f"), true)
	draw_rect(rect, Color("#6f8493", 0.5), false, 2)
	draw_rect(Rect2(rect.position + Vector2(36, 124), Vector2(98, 18)), Color("#23333b"), true)
	var stem_color := Color("#73aa70") if stable else Color("#485c40")
	var stem_top := rect.position + Vector2(86, 62 if stable else 74)
	draw_line(rect.position + Vector2(86, 124), stem_top, stem_color, 5)
	draw_circle(rect.position + Vector2(68, 70 if stable else 86), 18 if stable else 14, stem_color)
	draw_circle(rect.position + Vector2(106, 78 if stable else 92), 16 if stable else 13, stem_color.darkened(0.1))
	draw_circle(rect.position + Vector2(84, 52 if stable else 68), 13 if stable else 10, Color("#7dbd75") if stable else Color("#4f6748"))
	if not stable:
		draw_line(rect.position + Vector2(70, 86), rect.position + Vector2(58, 104), Color("#485c40"), 3)
		draw_line(rect.position + Vector2(106, 92), rect.position + Vector2(120, 108), Color("#485c40"), 3)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, -10), "中央植物舱", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#c8d8e2"))

func _draw_target_highlight() -> void:
	var rect := _objective_highlight_rect()
	if rect.size != Vector2.ZERO:
		draw_rect(rect.grow(10), Color("#f0c766", 0.12), true)
		draw_rect(rect.grow(10), Color("#f0c766", 0.62), false, 2)

func _objective_highlight_rect() -> Rect2:
	if scene_kind == "day_end" or scene_kind == "day02_end" or scene_kind == "week_end":
		return Rect2(Vector2(540, 500), Vector2(360, 120))
	if _is_week_routine_active():
		var day := _current_day()
		if scene_kind == "interior":
			if not bool(state.get("DailyConsoleChecked", false)):
				return interior_targets["console"]
			if _daily_checks_complete() and not bool(state.get("DailyReportSent", false)):
				return interior_targets["report_terminal"]
			if not _daily_checks_complete():
				if (day == 3 or day == 5 or day == 7) and not bool(state.get("DailyPowerChecked", false)) and current_target == "power_panel":
					return interior_targets["power_panel"]
				if day == 5 and not bool(state.get("DailySpecialChecked", false)) and current_target == "power_console":
					return interior_targets["power_console"]
				if (day == 3 or day == 7) and not bool(state.get("DailyLifeSupportChecked", false)) and current_target == "life_console":
					return interior_targets["life_console"]
				if current_target == "greenhouse_door" and (day == 4 or day == 6 or not bool(state.get("DailyPlantChecked", false))):
					return interior_targets["greenhouse_door"]
		elif scene_kind == "greenhouse":
			if day == 4 and (not bool(state.get("DailyWaterChecked", false)) or not bool(state.get("DailySpecialChecked", false))) and current_target == "water_panel":
				return greenhouse_targets["water_panel"]
			if not bool(state.get("DailyPlantChecked", false)) and (current_target == "last_plant" or current_target == "monitor"):
				return greenhouse_targets[current_target]
			if day == 6 and not bool(state.get("DailyRecordUpdated", false)) and current_target == "scanner":
				return greenhouse_targets["scanner"]
			if current_target == "exit":
				return greenhouse_targets["exit"]
		return Rect2()
	if _is_day02_active():
		if scene_kind == "interior":
			if not bool(state.get("Day02ConsoleChecked", false)):
				return interior_targets["console"]
			if _day02_inspections_complete() and not bool(state.get("Day02ReportSent", false)):
				return interior_targets["report_terminal"]
			if not _day02_inspections_complete():
				if not bool(state.get("Day02PowerChecked", false)) and current_target == "power_panel":
					return interior_targets["power_panel"]
				if not bool(state.get("Day02LifeSupportChecked", false)) and current_target == "life_console":
					return interior_targets["life_console"]
				if (not bool(state.get("Day02WaterChecked", false)) or not bool(state.get("Day02LastPlantChecked", false))) and current_target == "greenhouse_door":
					return interior_targets["greenhouse_door"]
		elif scene_kind == "greenhouse":
			if not bool(state.get("Day02WaterChecked", false)) and current_target == "water_panel":
				return greenhouse_targets["water_panel"]
			if not bool(state.get("Day02LastPlantChecked", false)) and current_target == "last_plant":
				return greenhouse_targets["last_plant"]
			if current_target == "exit":
				return greenhouse_targets["exit"]
		return Rect2()
	if scene_kind == "interior" and interior_targets.has(current_target):
		return interior_targets[current_target]
	if scene_kind == "greenhouse" and greenhouse_targets.has(current_target):
		return greenhouse_targets[current_target]
	return Rect2()

func _draw_player() -> void:
	if scene_kind == "airlock":
		return
	draw_ellipse(player_pos + Vector2(0, 18), 18, 5, Color("#020305", 0.36))
	draw_rect(Rect2(player_pos + Vector2(-11, -38), Vector2(22, 36)), Color("#d8e0e6"), true)
	draw_rect(Rect2(player_pos + Vector2(-7, -30), Vector2(14, 14)), Color("#7fa7bd"), true)
	draw_circle(player_pos + Vector2(0, -50), 16, Color("#e6eef4"))
	draw_circle(player_pos + Vector2(0, -50), 9, Color("#1b2834"))
	draw_line(player_pos + Vector2(-10, -18), player_pos + Vector2(-18, 4), Color("#d8e0e6"), 4)
	draw_line(player_pos + Vector2(10, -18), player_pos + Vector2(18, 4), Color("#d8e0e6"), 4)
	draw_line(player_pos + Vector2(-5, -2), player_pos + Vector2(-10, 20), Color("#d8e0e6"), 4)
	draw_line(player_pos + Vector2(5, -2), player_pos + Vector2(10, 20), Color("#d8e0e6"), 4)

func _default_state() -> Dictionary:
	return {
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
		"CurrentDay": 2,
		"DayStarted": false,
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

func _load_state() -> void:
	state = _default_state()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var saved: Dictionary = parsed as Dictionary
	for key in saved.keys():
		state[key] = saved[key]

func _save_state() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(state, "\t"))
