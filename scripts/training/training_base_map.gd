extends Control

## Training hub map: one persistent scene containing multiple walkable rooms
## (训练中控室 hub + 宇航服整备室 + 模拟气闸舱 + 配电房 + 空气系统控制室 + 训练温室),
## connected by doors instead of change_scene_to_file(). This is a brand-new,
## dedicated script -- it does NOT extend or modify training_module_scene.gd,
## which continues to serve SolarArrayTrainingField.tscn (module_id
## "power_repair", left completely untouched) and FinalAssessmentScene.tscn.
## Visual building blocks (room blockouts, target icons, player sprite) are
## reused from that script via its preloaded nested classes, since those are
## self-contained Control subclasses with no dependency on its per-module
## engine -- see TrainingModuleSceneScript.* references below.
##
## Only ONE room is ever "live" at a time (this is a room-panel-swap design,
## not true concurrent multi-room simulation): walking through a door calls
## _switch_room(), which stashes the current room's step/state progress into
## areas[], rebuilds the target training_area content for the destination
## room, and repositions the player there. This lets almost the entire
## per-room task engine (steps/targets/dialogs/_complete_step()/etc.) be a
## close structural mirror of training_module_scene.gd's existing single-
## active-module engine, just re-entered on door-crossing instead of scene
## load.
##
## 太阳能阵列训练场 (training 03) is deliberately NOT one of the rooms in this
## scene -- it stays its own separate scene (SolarArrayTrainingField.tscn),
## reached via a real change_scene_to_file() at the airlock's outer door.
## Its entry gate / repair container / fault-diagnosis logic is already
## complex and hardened; folding it into this hub's engine would be high
## risk for no functional benefit, and the user's own spec explicitly
## permits keeping it a separate scene ("如果开发成本更低，优先使用单场景多区域"
## / "太阳能阵列训练场也可以作为同场景下的外部区域，或单独场景").

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")
const PlayerControllerScript := preload("res://scripts/controllers/player_controller_2d.gd")
const InteractionAreaScript := preload("res://scripts/controllers/interaction_area_2d.gd")
const TrainingModuleSceneScript := preload("res://scripts/training/training_module_scene.gd")

const LOCKED_HINT := "该训练区尚未解锁。请先完成当前训练目标。"
const SUIT_REQUIRED_HINT := "该区域需要穿戴宇航服。"

# -- Static UI chrome (mirrors training_module_scene.gd's layout) --
var objective_label: Label
var hud_label: Label
var hint_label: Label
var log_label: Label
var diagnosis_panel: VBoxContainer
var left_panel: PanelContainer
var minimal_hud: PanelContainer
var minimal_title_label: Label
var minimal_objective_label: Label
var minimal_time_label: Label
var briefing_scrim: ColorRect
var briefing_modal: PanelContainer
var pause_panel: PanelContainer
var interaction_panel: PanelContainer
var interaction_label: Label
var interaction_bar: ProgressBar
var diagnosis_modal_scrim: ColorRect
var diagnosis_modal: PanelContainer
var diagnosis_modal_image: TextureRect
var diagnosis_modal_text: Label
var diagnosis_modal_actions: VBoxContainer
var suit_status_scrim: ColorRect
var suit_status_modal: PanelContainer
var suit_status_text_label: Label
var suit_status_panel_visible := false
var footer_buttons: HBoxContainer
var training_area: Control
var floor_node: Control
var player: Control
var target_nodes: Dictionary = {}
var prompt_label: Label

var mission_panel_visible := false
var briefing_visible := true
var pause_visible := false
var interaction_running := false
var interaction_target_id := ""
var wait_timer := 0.0
var player_speed := 280.0
var player_controller: RefCounted
var show_trigger_debug := false

# -- Multi-area state --
var areas: Dictionary = {}
var current_area_id := "hub"
var module_data: Dictionary = {}
var step_index := 0
var completed := false

func _ready() -> void:
	_ensure_input_actions()
	_release_stale_movement_input()
	areas = _build_all_areas()
	_route_initial_area()
	_build_screen()
	_load_area(current_area_id, module_data.get("player_start", Vector2(350, 320)))
	_update_hud()
	_sync_overlay_visibility()

func _process(delta: float) -> void:
	if briefing_visible or pause_visible or interaction_running:
		_update_room_prompt()
		return
	_move_player(delta)
	if not completed:
		_check_wait_step(delta)
		_check_auto_steps()
		_check_door_crossing()
	_update_room_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mission_panel"):
		_toggle_mission_panel()
	if event.is_action_pressed("interact") and not briefing_visible and not pause_visible and not interaction_running:
		_try_interact()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		show_trigger_debug = not show_trigger_debug
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause_menu()

func _ensure_input_actions() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E
		InputMap.action_add_event("interact", event)
	var enter_event := InputEventKey.new()
	enter_event.physical_keycode = KEY_ENTER
	if not InputMap.action_has_event("interact", enter_event):
		InputMap.action_add_event("interact", enter_event)
	if not InputMap.has_action("mission_panel"):
		InputMap.add_action("mission_panel")
		var panel_event := InputEventKey.new()
		panel_event.physical_keycode = KEY_TAB
		InputMap.action_add_event("mission_panel", panel_event)

## Same rationale as training_module_scene.gd's own copy of this function:
## Godot's input action "pressed" state is global, not per-scene, so a key
## held down when this scene loads (e.g. Enter on the previous screen's
## button) can otherwise read as a stuck movement/interact input.
func _release_stale_movement_input() -> void:
	for action in ["ui_up", "ui_down", "ui_left", "ui_right", "interact", "mission_panel", "ui_cancel", "ui_accept"]:
		if InputMap.has_action(action):
			Input.action_release(action)

## -- Area data / routing --

func _build_all_areas() -> Dictionary:
	var progress := TrainingManagerScript._read_progress_data()
	var built := {
		"hub": _hub_area_config(),
		"suit_prep_room": _suit_prep_area_config(),
		"airlock_simulation_room": _airlock_area_config(),
		"power_distribution_room": _power_distribution_area_config(),
		"air_system_control_room": _air_system_area_config(),
		"greenhouse_room": _greenhouse_area_config(),
	}
	for area_id in built.keys():
		var area: Dictionary = built[area_id]
		area["state"] = {}
		area["step_index"] = 0
		area["unlocked"] = _compute_unlocked(area_id, progress)
	return built

## Door lock state is derived every time this scene loads from
## TrainingManager's existing 6 completion flags -- no new persisted schema,
## matching the same "scene-local derived cache, TrainingManager stays the
## single source of truth" pattern already used elsewhere in this project
## (e.g. sprint06_base_scene.gd's GreenhouseDoor reading a state flag).
func _compute_unlocked(area_id: String, progress: Dictionary) -> bool:
	match area_id:
		"hub", "suit_prep_room":
			return true
		"airlock_simulation_room":
			return bool(progress.get("SuitControlCompleted", false))
		"power_distribution_room":
			return bool(progress.get("PowerRepairCompleted", false))
		"air_system_control_room":
			return bool(progress.get("PowerDistributionCompleted", false))
		"greenhouse_room":
			return bool(progress.get("LifeSupportCompleted", false))
	return false

## Decides which room to open the hub scene into. Two genuinely-external
## arrivals reach this scene: (1) fresh from TrainingStartScene at the very
## beginning, and (2) returning from SolarArrayTrainingField.tscn once
## training 03 is complete -- the player must walk back through the airlock,
## per the spec ("训练03完成后，玩家需要通过气闸返回室内"), so that specific case
## spawns in the airlock, not directly in the next task room, and fires the
## one-time "太阳能阵列基础输出已恢复" toast. Dev-menu jumps reuse the same
## CurrentTrainingModule-based routing for tester convenience.
func _route_initial_area() -> void:
	var progress := TrainingManagerScript._read_progress_data()
	var power_repair_done := bool(progress.get("PowerRepairCompleted", false))
	var toast_shown := bool(progress.get("PowerRepairUnlockToastShown", false))
	if power_repair_done and not toast_shown:
		current_area_id = "airlock_simulation_room"
		areas["airlock_simulation_room"]["player_start"] = Vector2(600, 340)
		progress["PowerRepairUnlockToastShown"] = true
		TrainingManagerScript.save_progress(progress)
		call_deferred("_add_log", "太阳能阵列基础输出已恢复。请返回基地，进入配电房。")
		return
	match String(progress.get("CurrentTrainingModule", "suit_control")):
		"suit_control":
			current_area_id = "hub"
		"airlock_procedure":
			current_area_id = "airlock_simulation_room"
		"power_distribution":
			current_area_id = "power_distribution_room"
		"life_support":
			current_area_id = "air_system_control_room"
		"plant_diagnosis", "final_assessment":
			current_area_id = "greenhouse_room" if String(progress.get("CurrentTrainingModule", "")) == "plant_diagnosis" else "suit_prep_room"
		_:
			current_area_id = "hub"
	# Defense in depth: this routing bypasses _try_enter_area()'s normal
	# suit-worn gate (it's placing the player directly into a room based on
	# saved progress, not walking them through a door), so re-check it here
	# too -- if the destination room requires the suit and it isn't worn
	# (shouldn't happen in the normal state machine, but a save file could
	# in principle be edited/corrupted), fall back to the always-safe
	# suit_prep_room instead of silently spawning them somewhere they
	# shouldn't be able to reach unsuited.
	var destination: Dictionary = areas.get(current_area_id, {})
	if bool(destination.get("requires_suit", false)):
		var suit_manager := _suit_manager()
		if suit_manager == null or not bool(suit_manager.get("is_suit_worn")):
			current_area_id = "suit_prep_room"

## -- Room content configs --
## Ported from training_module_scene.gd's per-module _*_config() functions
## (content only, not the engine) -- exact targets/steps/state_updates/
## requires/blocked_hint values preserved from the source module wherever
## practical, with per-room exit steps changed from "interact -> whole-scene
## change_scene_to_file" to "walk through a door -> _switch_room() or, for
## the airlock's outer door, a real scene transition to the solar array
## scene". Purely cosmetic per-target status-text/floor-glow polish from the
## original engine is intentionally not reproduced here (small map, not an
## exploration/graphics showcase) -- see docs/handoff note for this scoping
## call.

func _hub_area_config() -> Dictionary:
	return {
		"title": "训练中控室",
		"subtitle": "TRAINING CONTROL ROOM",
		"module_id": "",
		"requires_suit": false,
		"terrain_type": "indoor",
		"blockout": "TrainingRoomBlockout",
		"player_start": Vector2(350, 330),
		"hud": "训练中控室：室内枢纽\n连接宇航服整备室 / 配电房 / 空气系统控制室 / 训练温室。",
		"targets": [
			{"id": "terminal", "kind": "terminal", "label": "训练状态终端", "position": Vector2(330, 210), "size": Vector2(100, 80), "info": true},
			{"id": "door_suit", "kind": "door", "label": "宇航服整备室", "position": Vector2(30, 210), "size": Vector2(64, 140), "door_to": "suit_prep_room", "door_spawn": Vector2(560, 300)},
			{"id": "door_power", "kind": "door", "label": "配电房", "position": Vector2(330, 20), "size": Vector2(100, 54), "door_to": "power_distribution_room", "door_spawn": Vector2(350, 400)},
			{"id": "door_air", "kind": "door", "label": "空气系统控制室", "position": Vector2(666, 210), "size": Vector2(64, 140), "door_to": "air_system_control_room", "door_spawn": Vector2(660, 300)},
			{"id": "door_greenhouse", "kind": "door", "label": "训练温室", "position": Vector2(330, 446), "size": Vector2(100, 54), "door_to": "greenhouse_room", "door_spawn": Vector2(350, 320)},
		],
		"steps": [],
	}

func _suit_prep_area_config() -> Dictionary:
	return {
		"title": "宇航服整备室",
		"subtitle": "SPACESUIT PREPARATION",
		"module_id": "suit_control",
		"requires_suit": false,
		"terrain_type": "indoor",
		"blockout": "TrainingRoomBlockout",
		"player_start": Vector2(350, 330),
		"hud": "宇航服整备室：穿戴 / 归位。",
		"targets": [
			{"id": "suit_rack", "kind": "tool_station", "label": "宇航服整备架", "position": Vector2(320, 160), "size": Vector2(132, 92)},
			{"id": "door_hub", "kind": "door", "label": "训练中控室", "position": Vector2(666, 210), "size": Vector2(64, 140), "door_to": "hub", "door_spawn": Vector2(90, 300)},
			{"id": "door_airlock", "kind": "door", "label": "模拟气闸舱", "position": Vector2(30, 210), "size": Vector2(64, 140), "door_to": "airlock_simulation_room", "door_spawn": Vector2(150, 340)},
		],
		"steps": [
			{"type": "move", "target": "suit_rack", "objective": "移动到宇航服整备架", "line": "已抵达宇航服整备架。"},
			{"type": "wear_suit_confirm", "target": "suit_rack", "objective": "按 E 穿戴宇航服", "line": "宇航服已穿戴。"},
			{"type": "suit_status_panel", "target": "suit_rack", "objective": "按 Tab 查看宇航服状态面板", "line": "宇航服状态已确认。", "on_complete": "suit_control"},
		],
	}

func _airlock_area_config() -> Dictionary:
	return {
		"title": "模拟气闸舱",
		"subtitle": "AIRLOCK PROCEDURE",
		"module_id": "airlock_procedure",
		"requires_suit": true,
		"terrain_type": "indoor",
		"blockout": "AirlockRoomBlockout",
		"player_start": Vector2(150, 340),
		"hud": "模拟气闸舱：室内与外部真空模拟的边界。",
		"targets": [
			{"id": "door_suit", "kind": "door", "label": "宇航服整备室", "position": Vector2(20, 250), "size": Vector2(50, 140), "door_to": "suit_prep_room", "door_spawn": Vector2(560, 300)},
			{"id": "chamber", "label": "气闸室", "position": Vector2(210, 250), "size": Vector2(176, 214), "color": Color("#223d52")},
			{"id": "inner_door", "kind": "door", "label": "内舱门", "position": Vector2(90, 260), "size": Vector2(54, 116), "color": Color("#3d4e62")},
			{"id": "console", "kind": "pressure_console", "label": "舱压控制台", "position": Vector2(410, 150), "size": Vector2(126, 88), "color": Color("#31536f")},
			{"id": "pressure_display", "kind": "status_display", "label": "舱压状态", "position": Vector2(500, 100), "size": Vector2(132, 72), "color": Color("#244563")},
			{"id": "outer_door", "kind": "door", "label": "外舱门", "position": Vector2(610, 260), "size": Vector2(54, 116), "color": Color("#3d4e62")},
		],
		"steps": [
			{"type": "move", "target": "chamber", "objective": "进入气闸室", "line": "进入气闸室。", "state_key": "PlayerInsideAirlock"},
			{"type": "interact", "target": "inner_door", "objective": "关闭内舱门", "line": "内舱门已关闭。", "state_key": "InnerDoorClosed"},
			{"type": "interact", "target": "console", "objective": "启动舱压模拟", "line": "舱压模拟开始。", "state_key": "PressureSimulationStarted", "requires": {"InnerDoorClosed": true}, "blocked_hint": "请先关闭内舱门。"},
			{"type": "wait", "target": "pressure_display", "objective": "等待舱压稳定", "line": "舱压稳定。\n外舱门已解锁。", "duration": 1.6, "state_updates": {"PressureStable": true, "OuterDoorUnlocked": true}},
			{"type": "interact", "target": "outer_door", "objective": "打开外舱门，前往太阳能阵列训练场", "line": "外门已开启。\n模拟月面环境接入。", "state_key": "OuterDoorOpen", "requires": {"InnerDoorClosed": true, "PressureStable": true}, "blocked_hint": "舱压尚未稳定。外舱门保持锁定。", "on_complete": "airlock_procedure"},
		],
	}

func _power_distribution_area_config() -> Dictionary:
	return {
		"title": "配电房",
		"subtitle": "POWER DISTRIBUTION ROOM",
		"module_id": "power_distribution",
		"requires_suit": false,
		"terrain_type": "indoor",
		"blockout": "PowerRepairRoomBlockout",
		"player_start": Vector2(350, 400),
		"hud": "太阳能输入：已恢复\n储能模块：未接入\n配电主线：不稳定",
		"targets": [
			{"id": "door_hub", "kind": "door", "label": "训练中控室", "position": Vector2(30, 430), "size": Vector2(90, 60), "door_to": "hub", "door_spawn": Vector2(350, 120)},
			{"id": "panel", "kind": "power_panel", "label": "储能接入面板", "position": Vector2(150, 180), "size": Vector2(120, 90)},
			{"id": "console", "kind": "power_console", "label": "配电控制台", "position": Vector2(420, 180), "size": Vector2(120, 90)},
			{"id": "light", "kind": "test_light", "label": "供电测试灯", "position": Vector2(420, 320), "size": Vector2(90, 60)},
		],
		"steps": [
			{"type": "interact", "target": "panel", "objective": "查看供电系统异常", "line": "太阳能输入已恢复。\n配电主线电压不稳定。\n储能模块未接入主供电回路。", "state_updates": {"SolarInputDetected": true, "PowerPanelInspected": true, "PowerStatus": "不稳定"}},
			{"type": "interact", "target": "panel", "objective": "接入储能模块", "line": "正在接入储能模块……\n储能模块已接入主供电回路。", "time_minutes": 30, "time_reason": "training_connect_storage_module", "state_updates": {"PowerPanelRepaired": true, "StorageModuleConnected": true, "PowerStatus": "待重启"}, "requires": {"PowerPanelInspected": true}, "blocked_hint": "请先查看供电系统异常。"},
			{"type": "interact", "target": "console", "objective": "重启配电系统", "line": "配电系统正在重启。\n主线电压稳定。\n训练供电状态：Basic -> Stable。", "time_minutes": 30, "time_reason": "training_restart_power_distribution", "state_updates": {"PowerRestored": true, "PowerStatus": "稳定", "TestLightOn": true}, "requires": {"PowerPanelRepaired": true}, "blocked_hint": "储能模块尚未接入。无法重启配电系统。"},
			{"type": "interact", "target": "light", "objective": "确认供电稳定", "line": "测试灯已点亮。\n配电房供电恢复训练完成。", "state_key": "PowerDistributionConfirmed", "requires": {"PowerRestored": true}, "blocked_hint": "供电尚未稳定。", "on_complete": "power_distribution"},
		],
	}

func _air_system_area_config() -> Dictionary:
	return {
		"title": "空气系统控制室",
		"subtitle": "AIR SYSTEM RESTORATION",
		"display_title": "训练仓空气系统",
		"module_id": "life_support",
		"requires_suit": false,
		"terrain_type": "indoor",
		"blockout": "LifeSupportRoomBlockout",
		"player_start": Vector2(350, 400),
		"hud": "氧气模拟值：偏低\n水循环状态：稳定\n电力模拟值：稳定\n温度模拟值：偏低\n生命支持状态：未稳定",
		"targets": [
			{"id": "door_hub", "kind": "door", "label": "训练中控室", "position": Vector2(30, 430), "size": Vector2(90, 60), "door_to": "hub", "door_spawn": Vector2(660, 120)},
			{"id": "console", "kind": "life_console", "label": "生命支持控制台", "position": Vector2(340, 180), "size": Vector2(126, 88), "color": Color("#31536f")},
			{"id": "oxygen", "kind": "life_status", "label": "氧气状态", "position": Vector2(130, 130), "size": Vector2(96, 72), "color": Color("#244563")},
			{"id": "water", "kind": "life_status", "label": "水循环状态", "position": Vector2(130, 260), "size": Vector2(96, 72), "color": Color("#244563")},
			{"id": "power", "kind": "life_status", "label": "电力显示", "position": Vector2(560, 260), "size": Vector2(96, 72), "color": Color("#244563")},
			{"id": "temperature", "kind": "life_status", "label": "温度状态", "position": Vector2(560, 130), "size": Vector2(96, 72), "color": Color("#244563")},
			{"id": "core", "kind": "life_core", "label": "生命支持核心", "position": Vector2(620, 200), "size": Vector2(96, 88), "color": Color("#31536f")},
			{"id": "vent", "kind": "ventilation", "label": "通风单元", "position": Vector2(360, 330), "size": Vector2(96, 72), "color": Color("#31536f")},
		],
		"steps": [
			{"type": "interact", "target": "console", "objective": "打开生命支持控制台", "line": "生命支持控制台已打开。", "state_updates": {"LifeSupportConsoleOpened": true}},
			{"type": "interact", "target": "oxygen", "objective": "读取生命支持状态", "line": "检测到氧气偏低。\n检测到温度偏低。\n电力与水循环状态稳定。", "state_updates": {"LifeSupportStatusRead": true, "OxygenStatus": "偏低", "WaterStatus": "稳定", "PowerStatus": "稳定", "TemperatureStatus": "偏低", "LifeSupportStatus": "未稳定"}, "requires": {"LifeSupportConsoleOpened": true}, "blocked_hint": "请先打开生命支持控制台。"},
			{"type": "interact", "target": "console", "objective": "启动稳定程序", "line": "稳定程序启动。\n正在调整氧气输出与温控系统。", "state_updates": {"StabilizationStarted": true, "LifeSupportStatus": "稳定中"}, "requires": {"LifeSupportStatusRead": true}, "blocked_hint": "请先读取当前生命支持状态。"},
			{"type": "wait", "target": "core", "objective": "等待系统稳定", "line": "生命支持状态：稳定。", "duration": 1.6, "state_updates": {"LifeSupportStable": true, "OxygenStatus": "稳定", "WaterStatus": "稳定", "PowerStatus": "稳定", "TemperatureStatus": "稳定", "LifeSupportStatus": "稳定"}},
			{"type": "interact", "target": "vent", "objective": "确认生命支持稳定", "line": "氧气、水、电力与温度均已稳定。\n训练仓空气系统恢复训练完成。", "state_key": "LifeSupportConfirmed", "requires": {"LifeSupportStable": true}, "blocked_hint": "生命支持状态尚未稳定。", "on_complete": "life_support"},
		],
	}

func _greenhouse_area_config() -> Dictionary:
	return {
		"title": "训练温室",
		"subtitle": "PLANT DIAGNOSIS",
		"module_id": "plant_diagnosis",
		"requires_suit": false,
		"terrain_type": "indoor",
		"blockout": "PlantDiagnosisRoomBlockout",
		"player_start": Vector2(350, 400),
		"hud": "氧气模拟值：98%\n电力模拟值：稳定\n生命支持状态：稳定\n植物状态：异常",
		"targets": [
			{"id": "door_hub", "kind": "door", "label": "训练中控室", "position": Vector2(30, 430), "size": Vector2(90, 60), "door_to": "hub", "door_spawn": Vector2(350, 480)},
			{"id": "plant", "kind": "plant_chamber", "label": "训练植物", "position": Vector2(350, 260), "size": Vector2(96, 96), "color": Color("#2d5b3f")},
			{"id": "light_console", "kind": "plant_console", "label": "植物控制台", "position": Vector2(600, 260), "size": Vector2(120, 88), "color": Color("#31536f")},
			{"id": "grow_light", "kind": "grow_light", "label": "生长灯", "position": Vector2(560, 130), "size": Vector2(120, 40), "color": Color("#4b4f37")},
		],
		"steps": [
			{"type": "interact", "target": "plant", "objective": "查看训练植物", "line": "植物舱诊断视图已打开。", "state_updates": {"PlantObserved": true, "PlantStatus": "异常"}},
			{"type": "diagnosis", "objective": "选择诊断结果", "line": "诊断确认：光照不足。", "options": ["缺水", "光照不足", "根区温度异常"], "correct": "光照不足", "wrong_hint": "诊断结果不匹配。\n请重新查看植物舱状态。", "state_updates": {"DiagnosisSelected": true, "CorrectDiagnosis": "LightInsufficient"}, "requires": {"PlantObserved": true}, "blocked_hint": "诊断信息不足。请先查看训练植物。"},
			{"type": "plant_control", "target": "light_console", "objective": "调整植物控制台", "line": "补光方案已调整。\n植物状态正在恢复。", "options": ["调节温度", "浇水", "补光"], "correct": "补光", "wrong_hint": "该操作无法解决当前异常。\n请根据植物舱诊断结果选择维护动作。", "state_updates": {"GrowLightAdjusted": true, "PlantStatus": "稳定中", "GrowLightStatus": "正常"}, "requires": {"DiagnosisSelected": true}, "blocked_hint": "请先确认植物异常原因。"},
			{"type": "wait", "target": "plant", "objective": "确认植物状态稳定", "line": "植物状态趋于稳定。\n补光输出：正常。", "duration": 1.5, "state_updates": {"PlantStable": true, "PlantStatus": "稳定"}, "on_complete": "plant_diagnosis"},
		],
	}

## -- Room switching / door gating --

func _load_area(area_id: String, spawn_point: Vector2) -> void:
	current_area_id = area_id
	module_data = areas[area_id]
	step_index = int(module_data.get("step_index", 0))
	module_data["state"] = (module_data.get("state", {}) as Dictionary)
	completed = false
	_build_training_area()
	if player != null:
		player.position = spawn_point
	if player_controller != null:
		player_controller.sync_position(spawn_point)
	_update_hud()

func _switch_room(target_area_id: String, spawn_point: Vector2) -> void:
	areas[current_area_id]["step_index"] = step_index
	areas[current_area_id]["state"] = module_data.get("state", {})
	_load_area(target_area_id, spawn_point)

func _try_enter_area(target_area_id: String, spawn_point: Vector2) -> void:
	var area: Dictionary = areas.get(target_area_id, {})
	if area.is_empty():
		return
	if not bool(area.get("unlocked", false)):
		hint_label.text = LOCKED_HINT
		return
	if bool(area.get("requires_suit", false)):
		var suit_manager := _suit_manager()
		if suit_manager == null or not bool(suit_manager.get("is_suit_worn")):
			hint_label.text = SUIT_REQUIRED_HINT
			return
	_switch_room(target_area_id, spawn_point)

func _check_door_crossing() -> void:
	for target: Dictionary in module_data.get("targets", []):
		if not target.has("door_to"):
			continue
		if _is_inside_target_area(String(target["id"])):
			_try_enter_area(String(target["door_to"]), target.get("door_spawn", Vector2(350, 320)))
			return

## -- Movement --

func _move_player(delta: float) -> void:
	var margin := 36.0
	var movement_bounds := Rect2(Vector2(margin, margin), training_area.size - Vector2(margin * 2.0, margin * 2.0))
	_ensure_player_controller(movement_bounds)
	player_controller.bounds = movement_bounds
	player_controller.size = player.size
	player_controller.speed = player_speed
	player_controller.set_time_manager(_time_manager())
	# Hub rooms are always indoor and must advance TrainingTimeManager, never
	# the real TimeManager -- matches training_module_scene.gd's own rule.
	player_controller.set_movement_time_manager(_movement_time_manager())
	player_controller.terrain_type = String(module_data.get("terrain_type", "indoor"))
	player_controller.movement_context = "training"
	player_controller.sync_position(player.position)
	var result: Dictionary = player_controller.move_with_actions(delta, "ui_left", "ui_right", "ui_up", "ui_down")
	player.position = result.get("position", player.position)

func _ensure_player_controller(movement_bounds: Rect2) -> void:
	if player_controller != null:
		return
	player_controller = PlayerControllerScript.new()
	player_controller.configure(player.position, player.size, player_speed, movement_bounds, false, _time_manager())

func _check_auto_steps() -> void:
	var step := _current_step()
	if step.is_empty() or String(step.get("type", "")) != "move":
		return
	if _is_inside_target_area(String(step.get("target", ""))):
		_complete_step()

func _check_wait_step(delta: float) -> void:
	var step := _current_step()
	if step.is_empty() or String(step.get("type", "")) != "wait":
		return
	wait_timer += delta
	if wait_timer >= float(step.get("duration", 1.5)):
		wait_timer = 0.0
		_complete_step()

## -- Interaction / step engine (structural mirror of
## training_module_scene.gd's single-active-module engine, scoped to
## whichever room is currently loaded) --

func _try_interact() -> void:
	if _try_interact_info_target():
		return
	if _try_interact_suit_return():
		return
	var step := _current_step()
	if step.is_empty():
		return
	var step_type := String(step.get("type", "interact"))
	if step_type == "diagnosis":
		hint_label.text = "请在诊断弹窗中选择诊断结果。"
		return
	if step_type == "suit_status_panel":
		hint_label.text = "请按 Tab 查看宇航服状态面板。"
		return
	var target := String(step.get("target", ""))
	if step_type == "move":
		if _is_inside_target_area(target):
			_complete_step()
		else:
			hint_label.text = String(step.get("hint", "请移动至目标区域。"))
		return
	if not _is_near(target):
		hint_label.text = "请先移动至目标区域。"
		return
	if _blocked_by_order(step):
		hint_label.text = String(step.get("blocked_hint", "流程顺序错误。请按当前目标执行。"))
		return
	if step_type == "plant_control":
		_show_plant_control_options(step.get("options", []), String(step.get("correct", "")))
		return
	if step_type == "wear_suit_confirm":
		_show_wear_suit_confirm_dialog()
		return
	_begin_step_interaction_feedback(step)

## Hub's "训练状态终端" is informational only -- shows current objective +
## archive time, does not consume/advance any step.
func _try_interact_info_target() -> bool:
	for target: Dictionary in module_data.get("targets", []):
		if not bool(target.get("info", false)):
			continue
		if _is_near(String(target["id"])):
			hint_label.text = "%s\n\n%s" % [_global_objective_text(), _time_hud_text()]
			return true
	return false

## suit_prep_room's normal 3-step wear-suit sequence is already exhausted by
## the time all 6 training modules are done, so the "return the suit"
## closing action (spec: 训练06完成后...返回宇航服整备室...宇航服归位后进入最终结算)
## is handled as this separate, always-checked case rather than a 4th step
## in that steps array, since it only becomes available much later, after
## the player has walked away and come back through several other rooms.
func _try_interact_suit_return() -> bool:
	if current_area_id != "suit_prep_room":
		return false
	if not _current_step().is_empty():
		return false
	if not _all_required_modules_completed():
		return false
	if not _is_near("suit_rack"):
		return false
	var suit_manager := _suit_manager()
	if suit_manager == null or not bool(suit_manager.get("is_suit_worn")):
		return false
	_show_return_suit_confirm_dialog()
	return true

func _blocked_by_order(step: Dictionary) -> bool:
	var requires: Dictionary = step.get("requires", {})
	var state: Dictionary = module_data.get("state", {})
	for key in requires.keys():
		if state.get(key, null) != requires[key]:
			return true
	return false

func _is_near(target_id: String) -> bool:
	if not target_nodes.has(target_id):
		return false
	var target: Control = target_nodes[target_id]
	var player_center := InteractionAreaScript.center_point_from_top_left(player.position, player.size)
	var target_rect := Rect2(target.position, target.size)
	return InteractionAreaScript.is_point_near_rect(player_center, target_rect, 95.0)

func _is_inside_target_area(target_id: String) -> bool:
	if not target_nodes.has(target_id):
		return false
	var target: Control = target_nodes[target_id]
	var target_rect := Rect2(target.position, target.size)
	var player_feet := InteractionAreaScript.feet_point_from_top_left(player.position, player.size)
	return InteractionAreaScript.is_point_inside_rect(player_feet, target_rect)

func _current_step() -> Dictionary:
	var steps: Array = module_data.get("steps", [])
	if step_index >= steps.size():
		return {}
	return steps[step_index]

func _complete_step() -> void:
	var step := _current_step()
	if step.is_empty():
		return
	if step.has("state_key"):
		module_data["state"][String(step["state_key"])] = step.get("state_value", true)
	if step.has("state_updates"):
		var updates: Dictionary = step.get("state_updates", {})
		for key in updates.keys():
			module_data["state"][String(key)] = updates[key]
	_advance_time_for_step(step)
	_add_log(String(step.get("line", "")))
	step_index += 1
	areas[current_area_id]["step_index"] = step_index
	wait_timer = 0.0
	if String(step.get("type", "")) in ["diagnosis", "plant_control"]:
		if diagnosis_panel != null:
			diagnosis_panel.visible = false
		_hide_training_diagnosis_modal()
	var on_complete := String(step.get("on_complete", ""))
	if not on_complete.is_empty():
		_on_area_task_complete(on_complete)
		return
	_update_hud()

## Fires once, when a room's task step list is fully finished -- mirrors
## training_module_scene.gd's _finish_module(), but scoped to this room and
## triggering the door/lock unlock for the NEXT room instead of a whole-
## scene change_scene_to_file() (except the airlock -> solar array boundary,
## which really is a separate scene).
func _on_area_task_complete(module_id: String) -> void:
	match module_id:
		"suit_control":
			TrainingManagerScript.mark_module_completed("suit_control", "airlock_procedure")
			areas["airlock_simulation_room"]["unlocked"] = true
			_add_log("模拟气闸舱已解锁。")
		"airlock_procedure":
			TrainingManagerScript.mark_module_completed("airlock_procedure", "power_repair")
			TrainingManagerScript.set_current_module("power_repair")
			get_tree().change_scene_to_file(TrainingManagerScript.MODULE_03)
			return
		"power_distribution":
			TrainingManagerScript.mark_module_completed("power_distribution", "life_support")
			areas["air_system_control_room"]["unlocked"] = true
			_add_log("供电系统已恢复。空气系统控制室已解锁。")
		"life_support":
			TrainingManagerScript.mark_module_completed("life_support", "plant_diagnosis")
			areas["greenhouse_room"]["unlocked"] = true
			_add_log("训练仓空气系统已恢复。训练温室已解锁。")
		"plant_diagnosis":
			TrainingManagerScript.mark_module_completed("plant_diagnosis", "final_assessment")
			_add_log("训练模块六完成。请返回宇航服整备室，执行宇航服归位与维护。")
	_update_hud()

func _begin_step_interaction_feedback(step: Dictionary) -> void:
	if interaction_running:
		return
	interaction_running = true
	interaction_target_id = String(step.get("target", ""))
	var duration := 1.2
	if interaction_panel != null:
		interaction_panel.visible = true
	if interaction_label != null:
		interaction_label.text = "正在执行操作……"
	if interaction_bar != null:
		interaction_bar.value = 0.0
	var elapsed := 0.0
	while elapsed < duration:
		await get_tree().process_frame
		var delta := get_process_delta_time()
		elapsed += delta
		if interaction_bar != null:
			interaction_bar.value = clamp(elapsed / duration, 0.0, 1.0)
		_update_room_prompt()
	if interaction_label != null:
		interaction_label.text = "操作完成。"
	if interaction_bar != null:
		interaction_bar.value = 1.0
	await get_tree().create_timer(0.2).timeout
	if interaction_panel != null:
		interaction_panel.visible = false
	interaction_target_id = ""
	interaction_running = false
	_complete_step()

## -- Time / manager helpers --

func _advance_time_for_step(step: Dictionary) -> void:
	var manager := _training_time_manager()
	if manager == null or not manager.has_method("advance_training_time"):
		return
	var minutes := int(step.get("time_minutes", _default_time_minutes_for_step(step)))
	if minutes <= 0:
		return
	manager.call("advance_training_time", minutes, String(step.get("time_reason", "training_action")))

func _default_time_minutes_for_step(step: Dictionary) -> int:
	var step_type := String(step.get("type", "interact"))
	var objective := String(step.get("objective", ""))
	if step_type == "move" or String(step.get("target", "")) == "exit":
		return 0
	if step_type == "diagnosis":
		return 15
	if step_type == "plant_control":
		return 30
	if objective.contains("维修") or objective.contains("恢复") or objective.contains("重启") or objective.contains("启动"):
		return 30
	if objective.contains("检查") or objective.contains("读取") or objective.contains("确认"):
		return 30
	return 0

func _time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TimeManager")

func _training_time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TrainingTimeManager")

func _movement_time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("MovementTimeManager")

func _suit_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SuitManager")

func _health_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HealthManager")

func _time_hud_text() -> String:
	var manager := _training_time_manager()
	if manager == null or not manager.has_method("get_remaining_time_text"):
		return ""
	return "训练归档时限：剩余 %s" % String(manager.call("get_remaining_time_text"))

func _health_hud_text() -> String:
	var manager := _health_manager()
	if manager == null or not manager.has_method("compact_hud_text"):
		return ""
	return String(manager.call("compact_hud_text"))

func _resident_status_hud_text() -> String:
	var lines: Array[String] = []
	var time_text := _time_hud_text()
	var health_text := _health_hud_text()
	if not time_text.is_empty():
		lines.append(time_text)
	if not health_text.is_empty():
		lines.append(health_text)
	return "\n".join(lines)

## -- Global (hub-visible) objective text, derived from training flags --

func _global_objective_text() -> String:
	var progress := TrainingManagerScript._read_progress_data()
	if not bool(progress.get("SuitControlCompleted", false)):
		return "前往宇航服整备室，穿戴宇航服。"
	if not bool(progress.get("AirlockProcedureCompleted", false)):
		return "前往模拟气闸舱，执行气闸流程。"
	if not bool(progress.get("PowerRepairCompleted", false)):
		return "通过气闸前往太阳能阵列训练场，完成维修。"
	if not bool(progress.get("PowerDistributionCompleted", false)):
		return "前往配电房，恢复供电。"
	if not bool(progress.get("LifeSupportCompleted", false)):
		return "前往空气系统控制室，恢复训练仓空气。"
	if not bool(progress.get("PlantDiagnosisCompleted", false)):
		return "前往训练温室，完成植物诊断。"
	return "返回宇航服整备室，将宇航服脱下并放回维护位。"

## -- Suit-return closing sequence (宇航服整备室 collects both training 01's
## opening flow above and this closing gate once all 6 modules are done) --

func _all_required_modules_completed() -> bool:
	return TrainingManagerScript.are_required_modules_completed()

## -- Dialog helpers (adapted from training_module_scene.gd's
## _show_wear_suit_confirm_dialog()/_show_diagnosis_options()/
## _show_plant_control_options(), same diagnosis_modal_* infrastructure) --

func _show_wear_suit_confirm_dialog() -> void:
	_open_diagnosis_modal("穿戴宇航服\n\n穿戴将消耗训练时间 15 分钟。\n是否确认？")
	var confirm := Button.new()
	confirm.text = "确认穿戴"
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.pressed.connect(func():
		var suit_manager := _suit_manager()
		var success := false
		if suit_manager != null and suit_manager.has_method("wear_suit_training"):
			success = suit_manager.call("wear_suit_training")
		_hide_training_diagnosis_modal()
		if success:
			_complete_step()
		else:
			hint_label.text = "宇航服当前无法穿戴。"
	)
	diagnosis_modal_actions.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(0, 42)
	cancel.pressed.connect(func():
		hint_label.text = "已取消穿戴。"
		_hide_training_diagnosis_modal()
	)
	diagnosis_modal_actions.add_child(cancel)
	_sync_overlay_visibility()

func _show_return_suit_confirm_dialog() -> void:
	_open_diagnosis_modal("宇航服归位\n\n脱下宇航服并放回维护位。\n维护系统将恢复宇航服氧气、电力与状态。\n\n训练模式下无需等待完整维护流程。\n是否确认？")
	var confirm := Button.new()
	confirm.text = "确认归位"
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.pressed.connect(func():
		var suit_manager := _suit_manager()
		var success := false
		if suit_manager != null and suit_manager.has_method("remove_suit_to_service_station_training"):
			success = suit_manager.call("remove_suit_to_service_station_training")
		_hide_training_diagnosis_modal()
		if success:
			TrainingManagerScript.set_current_module("final_assessment")
			get_tree().change_scene_to_file(TrainingManagerScript.FINAL_ASSESSMENT)
		else:
			hint_label.text = "宇航服当前无法归位。"
	)
	diagnosis_modal_actions.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(0, 42)
	cancel.pressed.connect(func():
		hint_label.text = "已取消宇航服归位。"
		_hide_training_diagnosis_modal()
	)
	diagnosis_modal_actions.add_child(cancel)
	_sync_overlay_visibility()

func _show_diagnosis_options(options: Array, correct: String) -> void:
	_open_diagnosis_modal("传感器读数\n补光输出：低于维持阈值\n水循环：最低运行\n根区温度：正常\n生命信号：弱\n\n请选择诊断结论。")
	for option in options:
		var button := Button.new()
		button.text = String(option)
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(func():
			if button.text == correct:
				_hide_training_diagnosis_modal()
				_complete_step()
			else:
				hint_label.text = String(_current_step().get("wrong_hint", "诊断结论不足。请重新核对观察信息。"))
		)
		diagnosis_modal_actions.add_child(button)

func _show_plant_control_options(options: Array, correct: String) -> void:
	_open_diagnosis_modal("植物控制台\n\n根据植物舱诊断结果选择一项维护动作。\n\n可用操作\n调节温度：用于根区温度异常。\n浇水：用于水分不足。\n补光：用于光照不足。")
	for option in options:
		var button := Button.new()
		button.text = String(option)
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(func():
			if button.text == correct:
				_hide_training_diagnosis_modal()
				_complete_step()
			else:
				hint_label.text = String(_current_step().get("wrong_hint", "维护动作不匹配。请重新核对植物舱诊断结果。"))
		)
		diagnosis_modal_actions.add_child(button)

func _open_diagnosis_modal(text: String) -> void:
	if diagnosis_panel != null:
		diagnosis_panel.visible = false
	if diagnosis_modal_scrim != null:
		diagnosis_modal_scrim.visible = true
	if diagnosis_modal != null:
		diagnosis_modal.visible = true
	if diagnosis_modal_image != null:
		diagnosis_modal_image.texture = null
	if diagnosis_modal_text != null:
		diagnosis_modal_text.text = text
	_clear_container(diagnosis_modal_actions)

func _hide_training_diagnosis_modal() -> void:
	if diagnosis_modal_scrim != null:
		diagnosis_modal_scrim.visible = false
	if diagnosis_modal != null:
		diagnosis_modal.visible = false
	_sync_overlay_visibility()

## -- Suit status panel (Tab, reused pattern from training_module_scene.gd)--

func _toggle_mission_panel() -> void:
	if pause_visible:
		return
	if String(_current_step().get("type", "")) == "suit_status_panel":
		_toggle_suit_status_panel()
		return
	_set_mission_panel_visible(not mission_panel_visible)

func _toggle_suit_status_panel() -> void:
	suit_status_panel_visible = not suit_status_panel_visible
	if suit_status_panel_visible:
		_refresh_suit_status_panel()
	if suit_status_scrim != null:
		suit_status_scrim.visible = suit_status_panel_visible
	if suit_status_modal != null:
		suit_status_modal.visible = suit_status_panel_visible
	_sync_overlay_visibility()

func _refresh_suit_status_panel() -> void:
	if suit_status_text_label == null:
		return
	var suit_manager := _suit_manager()
	if suit_manager == null or not suit_manager.has_method("get_suit_status_for_ui"):
		suit_status_text_label.text = "宇航服数据不可用。"
		return
	var data: Dictionary = suit_manager.call("get_suit_status_for_ui")
	suit_status_text_label.text = "宇航服状态\n\n氧气储备：%.0f%%\n电力储备：%.0f%%\n移动倍率：%.2f" % [
		float(data.get("oxygen", 0.0)), float(data.get("power", 0.0)), float(data.get("speed_multiplier", 0.8)),
	]

func _on_confirm_suit_status_pressed() -> void:
	if String(_current_step().get("type", "")) != "suit_status_panel":
		return
	suit_status_panel_visible = false
	if suit_status_scrim != null:
		suit_status_scrim.visible = false
	if suit_status_modal != null:
		suit_status_modal.visible = false
	_complete_step()

func _set_mission_panel_visible(value: bool) -> void:
	mission_panel_visible = value
	if log_label != null:
		log_label.text = "Tab：关闭任务面板\nE / Enter：与当前目标交互\nEsc：暂停"
	_sync_overlay_visibility()

func _toggle_pause_menu() -> void:
	if briefing_visible:
		_close_briefing()
		return
	_set_pause_visible(not pause_visible)

func _set_pause_visible(value: bool) -> void:
	pause_visible = value
	if pause_panel != null:
		pause_panel.visible = value
	_sync_overlay_visibility()

func _close_briefing() -> void:
	briefing_visible = false
	if briefing_modal != null:
		briefing_modal.visible = false
	_sync_overlay_visibility()

func _sync_overlay_visibility() -> void:
	var diagnosis_panel_open := diagnosis_panel != null and diagnosis_panel.visible
	var diagnosis_open := diagnosis_panel_open or (diagnosis_modal != null and diagnosis_modal.visible)
	var suit_status_open := suit_status_modal != null and suit_status_modal.visible
	if briefing_scrim != null:
		briefing_scrim.visible = briefing_visible
	if briefing_modal != null:
		briefing_modal.visible = briefing_visible
	if left_panel != null:
		left_panel.visible = mission_panel_visible or diagnosis_panel_open
	if minimal_hud != null:
		minimal_hud.visible = not briefing_visible and not mission_panel_visible and not pause_visible and not diagnosis_open and not suit_status_open
	if prompt_label != null and (briefing_visible or mission_panel_visible or pause_visible or diagnosis_open or suit_status_open):
		prompt_label.visible = false

## -- HUD --

func _update_hud() -> void:
	var step := _current_step()
	var objective := String(step.get("objective", "")) if not step.is_empty() else _global_objective_text()
	objective_label.text = "当前目标：%s" % objective
	if minimal_title_label != null:
		minimal_title_label.text = String(module_data.get("display_title", module_data.get("title", "训练基地")))
	if minimal_objective_label != null:
		minimal_objective_label.text = "当前目标：%s" % objective
	if minimal_time_label != null:
		minimal_time_label.text = _resident_status_hud_text().replace("\n", " · ")
	hud_label.text = String(module_data.get("hud", ""))
	var time_text := _resident_status_hud_text()
	if not time_text.is_empty():
		hud_label.text = "%s\n\n%s" % [time_text, hud_label.text]
	hint_label.text = String(step.get("hint", "移动至目标区域，按 E 交互。")) if not step.is_empty() else "按 Tab 查看任务面板。"
	if current_area_id == "suit_prep_room" and step.is_empty() and _all_required_modules_completed():
		var suit_manager := _suit_manager()
		if suit_manager != null and bool(suit_manager.get("is_suit_worn")):
			hint_label.text = "所有训练模块已完成。\n请靠近宇航服整备架，按 E 归还宇航服。"
	if String(step.get("type", "")) == "diagnosis":
		_show_diagnosis_options(step.get("options", []), String(step.get("correct", "")))
	_sync_overlay_visibility()

func _add_log(line: String) -> void:
	if line.is_empty() or log_label == null:
		return
	log_label.text += line + "\n"

## -- Screen construction (mirrors training_module_scene.gd's _build_screen()
## layout so the hub doesn't look visually out of place next to the solar
## array scene it neighbors) --

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("#06101a")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 36
	root.offset_top = 24
	root.offset_right = -36
	root.offset_bottom = -32
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	root.add_child(header)
	_add_header_label(header, "国家深空生命科学中心训练控制系统", Vector2(620, 46), 24, Color("#eaf4ff"))
	_add_header_label(header, "TRAINING BASE MAP", Vector2(420, 46), 13, Color("#6f8493"))
	_add_header_label(header, "训练编号  GHT-2068-0421", Vector2(280, 46), 14, Color("#8fa3b2"))

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)

	left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(420, 0)
	left_panel.visible = false
	row.add_child(left_panel)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	left_panel.add_child(left)

	var title := Label.new()
	title.text = "训练小型地图"
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 24)
	left.add_child(title)

	_add_panel_section_label(left, "当前目标")
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.modulate = Color("#d8e7f2")
	objective_label.add_theme_font_size_override("font_size", 18)
	left.add_child(objective_label)

	_add_panel_section_label(left, "系统状态")
	hud_label = Label.new()
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_label.modulate = Color("#9fb4c4")
	hud_label.add_theme_font_size_override("font_size", 15)
	left.add_child(hud_label)

	_add_panel_section_label(left, "操作步骤")
	hint_label = Label.new()
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.modulate = Color("#86c7ff")
	hint_label.add_theme_font_size_override("font_size", 16)
	left.add_child(hint_label)

	diagnosis_panel = VBoxContainer.new()
	diagnosis_panel.visible = false
	diagnosis_panel.add_theme_constant_override("separation", 8)
	left.add_child(diagnosis_panel)

	_add_panel_section_label(left, "输入提示")
	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.modulate = Color("#d8e7f2")
	log_label.add_theme_font_size_override("font_size", 15)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(log_label)

	var area_panel := PanelContainer.new()
	area_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(area_panel)
	training_area = Control.new()
	training_area.custom_minimum_size = Vector2(760, 520)
	area_panel.add_child(training_area)

	var footer := HBoxContainer.new()
	footer_buttons = footer
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.custom_minimum_size = Vector2(0, 48)
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	_add_button(footer, "保存训练进度", func(): TrainingManagerScript.set_current_module(String(module_data.get("module_id", "suit_control"))))
	_add_button(footer, "返回主菜单", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))

	_build_training_overlays()

func _build_training_overlays() -> void:
	minimal_hud = PanelContainer.new()
	minimal_hud.position = Vector2(60, 84)
	minimal_hud.custom_minimum_size = Vector2(390, 118)
	add_child(minimal_hud)
	var hud_box := VBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 6)
	minimal_hud.add_child(hud_box)
	minimal_title_label = Label.new()
	minimal_title_label.modulate = Color("#eaf4ff")
	minimal_title_label.add_theme_font_size_override("font_size", 17)
	hud_box.add_child(minimal_title_label)
	minimal_objective_label = Label.new()
	minimal_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	minimal_objective_label.modulate = Color("#f0c766")
	minimal_objective_label.add_theme_font_size_override("font_size", 15)
	hud_box.add_child(minimal_objective_label)
	minimal_time_label = Label.new()
	minimal_time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	minimal_time_label.modulate = Color("#9fb4c4")
	minimal_time_label.add_theme_font_size_override("font_size", 13)
	hud_box.add_child(minimal_time_label)
	var key_hint := Label.new()
	key_hint.text = "Tab 查看任务    Esc 暂停"
	key_hint.modulate = Color("#7f93a3")
	key_hint.add_theme_font_size_override("font_size", 12)
	hud_box.add_child(key_hint)
	_build_briefing_modal()
	_build_pause_panel()
	_build_interaction_panel()
	_build_diagnosis_modal()
	_build_suit_status_panel()

func _build_briefing_modal() -> void:
	briefing_scrim = ColorRect.new()
	briefing_scrim.color = Color("#02070d", 0.78)
	briefing_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	briefing_scrim.visible = true
	add_child(briefing_scrim)

	briefing_modal = PanelContainer.new()
	briefing_modal.set_anchors_preset(Control.PRESET_CENTER)
	briefing_modal.offset_left = -320
	briefing_modal.offset_top = -190
	briefing_modal.offset_right = 320
	briefing_modal.offset_bottom = 190
	briefing_modal.visible = true
	add_child(briefing_modal)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	briefing_modal.add_child(box)
	var title := Label.new()
	title.text = "训练小型地图"
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "候选人训练基地"
	subtitle.modulate = Color("#86c7ff")
	subtitle.add_theme_font_size_override("font_size", 16)
	box.add_child(subtitle)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color("#c6d5df")
	body.add_theme_font_size_override("font_size", 16)
	body.text = "所有训练房间围绕训练中控室展开。\n\n靠近目标后按 E / Enter 交互，走到门口即可进入已解锁的训练区。\n按 Tab 可随时查看任务面板。"
	box.add_child(body)
	var button := Button.new()
	button.text = "确认，开始训练"
	button.custom_minimum_size = Vector2(0, 44)
	button.pressed.connect(func(): _close_briefing())
	box.add_child(button)
	briefing_visible = true

func _build_pause_panel() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -210
	pause_panel.offset_top = -150
	pause_panel.offset_right = 210
	pause_panel.offset_bottom = 150
	pause_panel.visible = false
	add_child(pause_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	pause_panel.add_child(box)
	var title := Label.new()
	title.text = "训练暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var resume := Button.new()
	resume.text = "继续训练"
	resume.custom_minimum_size = Vector2(0, 42)
	resume.pressed.connect(func(): _set_pause_visible(false))
	box.add_child(resume)
	var tasks := Button.new()
	tasks.text = "查看任务"
	tasks.custom_minimum_size = Vector2(0, 42)
	tasks.pressed.connect(func():
		_set_pause_visible(false)
		_set_mission_panel_visible(true)
	)
	box.add_child(tasks)
	var main := Button.new()
	main.text = "返回主菜单"
	main.custom_minimum_size = Vector2(0, 42)
	main.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	box.add_child(main)

func _build_interaction_panel() -> void:
	interaction_panel = PanelContainer.new()
	interaction_panel.position = Vector2(520, 720)
	interaction_panel.custom_minimum_size = Vector2(560, 78)
	interaction_panel.visible = false
	add_child(interaction_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	interaction_panel.add_child(box)
	interaction_label = Label.new()
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.modulate = Color("#eaf4ff")
	interaction_label.add_theme_font_size_override("font_size", 16)
	box.add_child(interaction_label)
	interaction_bar = ProgressBar.new()
	interaction_bar.min_value = 0.0
	interaction_bar.max_value = 1.0
	interaction_bar.value = 0.0
	interaction_bar.show_percentage = false
	interaction_bar.custom_minimum_size = Vector2(0, 12)
	box.add_child(interaction_bar)

func _build_diagnosis_modal() -> void:
	diagnosis_modal_scrim = ColorRect.new()
	diagnosis_modal_scrim.color = Color("#02070d", 0.78)
	diagnosis_modal_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	diagnosis_modal_scrim.visible = false
	add_child(diagnosis_modal_scrim)

	diagnosis_modal = PanelContainer.new()
	diagnosis_modal.set_anchors_preset(Control.PRESET_CENTER)
	diagnosis_modal.offset_left = -360
	diagnosis_modal.offset_top = -260
	diagnosis_modal.offset_right = 360
	diagnosis_modal.offset_bottom = 260
	diagnosis_modal.visible = false
	add_child(diagnosis_modal)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#06111a", 0.98)
	style.border_color = Color("#496c80", 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	diagnosis_modal.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(680, 460)
	box.add_theme_constant_override("separation", 14)
	diagnosis_modal.add_child(box)
	diagnosis_modal_image = TextureRect.new()
	diagnosis_modal_image.custom_minimum_size = Vector2(0, 0)
	diagnosis_modal_image.visible = false
	box.add_child(diagnosis_modal_image)
	diagnosis_modal_text = Label.new()
	diagnosis_modal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnosis_modal_text.modulate = Color("#cfe3f2")
	diagnosis_modal_text.add_theme_font_size_override("font_size", 16)
	box.add_child(diagnosis_modal_text)
	diagnosis_modal_actions = VBoxContainer.new()
	diagnosis_modal_actions.add_theme_constant_override("separation", 10)
	box.add_child(diagnosis_modal_actions)

func _build_suit_status_panel() -> void:
	suit_status_scrim = ColorRect.new()
	suit_status_scrim.color = Color("#02070d", 0.78)
	suit_status_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	suit_status_scrim.visible = false
	add_child(suit_status_scrim)

	suit_status_modal = PanelContainer.new()
	suit_status_modal.set_anchors_preset(Control.PRESET_CENTER)
	suit_status_modal.offset_left = -260
	suit_status_modal.offset_top = -190
	suit_status_modal.offset_right = 260
	suit_status_modal.offset_bottom = 190
	suit_status_modal.visible = false
	add_child(suit_status_modal)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#170a1e", 0.97)
	style.border_color = Color("#8a5fa8", 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	suit_status_modal.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	suit_status_modal.add_child(box)
	var title := Label.new()
	title.text = "宇航服状态"
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	suit_status_text_label = Label.new()
	suit_status_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	suit_status_text_label.modulate = Color("#e8d9f5")
	suit_status_text_label.add_theme_font_size_override("font_size", 16)
	box.add_child(suit_status_text_label)
	var confirm := Button.new()
	confirm.text = "确认状态"
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.pressed.connect(_on_confirm_suit_status_pressed)
	box.add_child(confirm)

## Rebuilds training_area's contents (floor blockout + targets + player) for
## whichever room is now current_area_id -- called both at _ready() and on
## every _switch_room(). Reuses training_module_scene.gd's nested visual
## classes (room blockouts / TrainingTargetVisual / TraineeVisual) via its
## preloaded script reference -- these are self-contained Control subclasses
## with no dependency on that script's own per-module engine, so referencing
## them here does not couple this script to it.
func _build_training_area() -> void:
	_clear_container(training_area)
	target_nodes.clear()

	var blockout_name := String(module_data.get("blockout", "TrainingRoomBlockout"))
	var floor: Control
	match blockout_name:
		"AirlockRoomBlockout":
			floor = TrainingModuleSceneScript.AirlockRoomBlockout.new()
		"PowerRepairRoomBlockout":
			floor = TrainingModuleSceneScript.PowerRepairRoomBlockout.new()
		"LifeSupportRoomBlockout":
			floor = TrainingModuleSceneScript.LifeSupportRoomBlockout.new()
		"PlantDiagnosisRoomBlockout":
			floor = TrainingModuleSceneScript.PlantDiagnosisRoomBlockout.new()
		_:
			floor = TrainingModuleSceneScript.TrainingRoomBlockout.new()
	floor.set_anchors_preset(Control.PRESET_FULL_RECT)
	training_area.add_child(floor)
	floor_node = floor
	_refresh_floor_state()

	for target: Dictionary in module_data.get("targets", []):
		var visual: Control = TrainingModuleSceneScript.TrainingTargetVisual.new()
		visual.name = String(target["id"])
		visual.kind = String(target.get("kind", "marker"))
		visual.label_text = String(target.get("label", ""))
		visual.position = target.get("position", Vector2.ZERO)
		visual.size = target.get("size", Vector2(96, 72))
		training_area.add_child(visual)
		target_nodes[String(target["id"])] = visual

	player = TrainingModuleSceneScript.TraineeVisual.new()
	player.size = Vector2(42, 54)
	player.position = module_data.get("player_start", Vector2(350, 320))
	training_area.add_child(player)

	prompt_label = Label.new()
	prompt_label.modulate = Color("#f0c766")
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.visible = false
	training_area.add_child(prompt_label)

	player_controller = null

func _refresh_floor_state() -> void:
	if floor_node == null:
		return
	var state: Dictionary = module_data.get("state", {})
	match String(module_data.get("blockout", "")):
		"PowerRepairRoomBlockout":
			floor_node.set("power_on", bool(state.get("PowerRestored", false)))
		"LifeSupportRoomBlockout":
			floor_node.set("stable", bool(state.get("LifeSupportStable", false)))
			floor_node.set("stabilizing", bool(state.get("StabilizationStarted", false)) and not bool(state.get("LifeSupportStable", false)))
		"PlantDiagnosisRoomBlockout":
			floor_node.set("plant_stable", bool(state.get("PlantStable", false)))
			floor_node.set("grow_light_on", bool(state.get("GrowLightAdjusted", false)))
	floor_node.queue_redraw()

func _update_room_prompt() -> void:
	if prompt_label == null:
		return
	if briefing_visible or mission_panel_visible or pause_visible:
		for node in target_nodes.values():
			if node is TrainingModuleSceneScript.TrainingTargetVisual:
				node.highlighted = false
				node.active = false
				node.locked = _door_locked(node)
				node.modulate = Color(0.62, 0.68, 0.74, 0.48)
				node.queue_redraw()
		prompt_label.visible = false
		return
	_refresh_floor_state()
	var step := _current_step()
	var target_id := String(step.get("target", "")) if not step.is_empty() else ""
	for node in target_nodes.values():
		if node is TrainingModuleSceneScript.TrainingTargetVisual:
			var node_is_interacting: bool = interaction_running and node.name == interaction_target_id
			node.highlighted = node.name == target_id or node_is_interacting
			node.active = node_is_interacting
			node.locked = _door_locked(node)
			node.modulate = Color(1, 1, 1, 1) if node.highlighted else Color(0.64, 0.70, 0.76, 0.56)
			node.queue_redraw()
	if target_id.is_empty() or not target_nodes.has(target_id):
		prompt_label.visible = false
		return
	var target: Control = target_nodes[target_id]
	var near := _is_near(target_id)
	var prompt_step_type := String(step.get("type", ""))
	if near and prompt_step_type in ["interact", "plant_control", "wear_suit_confirm"]:
		prompt_label.text = "E 交互"
		prompt_label.position = target.position + Vector2(8, target.size.y + 20)
		prompt_label.visible = true
	else:
		prompt_label.visible = false

## Doors show a "locked" overlay (reusing TrainingTargetVisual's existing
## lock-icon drawing) when the room they lead to isn't unlocked yet.
func _door_locked(node: Control) -> bool:
	for target: Dictionary in module_data.get("targets", []):
		if String(target.get("id", "")) != String(node.name):
			continue
		if not target.has("door_to"):
			return false
		var area: Dictionary = areas.get(String(target["door_to"]), {})
		return not bool(area.get("unlocked", false))
	return false

func _add_header_label(parent: HBoxContainer, text: String, min_size: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = min_size
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func _add_panel_section_label(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color("#86c7ff")
	label.add_theme_font_size_override("font_size", 13)
	parent.add_child(label)

func _add_button(parent: HBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(190, 42)
	button.pressed.connect(callback)
	parent.add_child(button)

func _clear_container(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
