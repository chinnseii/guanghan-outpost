extends Node2D

const TILE := 56
const MAP_W := 22
const MAP_H := 13
const MAP_ORIGIN := Vector2(50, 70)
const PLAYER_SPEED := 190.0
const SAVE_SLOTS := 3
const SAVE_DIR := "user://saves"
const DEMO_PROGRESS_PATHS := [
	"user://saves/application_profile.json",
	"user://saves/training_progress.json",
	"user://saves/sprint06_progress.json",
	"user://saves/time_state.json",
	"user://saves/health_state.json",
]

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const MODULE_SCENE := preload("res://scenes/module_visual.tscn")
const COLLECTABLE_SCENE := preload("res://scenes/collectable_visual.tscn")
const ROBOT_SCENE := preload("res://scenes/robot.tscn")
const SaveManagerScript := preload("res://scripts/save_manager.gd")
const AudioFeedbackScript := preload("res://scripts/audio_feedback.gd")
const RobotTaskManagerScript := preload("res://scripts/robot_task_manager.gd")
const GameStateManagerScript := preload("res://scripts/game_state_manager.gd")
const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")
const TimeManagerScript := preload("res://scripts/time_manager.gd")
const CameraManagerScript := preload("res://scripts/camera_manager.gd")
const UIManagerScript := preload("res://scripts/ui_manager.gd")
const EventManagerScript := preload("res://scripts/event_manager.gd")
const AudioManagerScript := preload("res://scripts/audio_manager.gd")

class TitleScreenBackground:
	extends Control

	func _draw() -> void:
		var rect: Rect2 = Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#020711"), true)
		for i in range(86):
			var x: float = fposmod(float(i * 197), max(size.x, 1.0))
			var y: float = fposmod(float(i * 89), max(size.y * 0.7, 1.0))
			var alpha: float = 0.22 + float(i % 5) * 0.08
			draw_circle(Vector2(x, y), 1.0 + float(i % 3) * 0.45, Color("#d8e7f2", alpha))
		var earth_center: Vector2 = Vector2(size.x * 0.73, size.y * 0.28)
		var earth_radius: float = min(size.x, size.y) * 0.095
		draw_circle(earth_center, earth_radius * 1.2, Color("#73b7ff", 0.06))
		draw_circle(earth_center, earth_radius, Color("#214c75"))
		draw_circle(earth_center + Vector2(-earth_radius * 0.22, -earth_radius * 0.1), earth_radius * 0.55, Color("#8ec7ff", 0.68))
		draw_arc(earth_center + Vector2(-earth_radius * 0.15, earth_radius * 0.08), earth_radius * 0.72, 3.4, 6.0, 48, Color("#e8f3ff", 0.62), 5.0)
		draw_circle(earth_center + Vector2(earth_radius * 0.38, -earth_radius * 0.22), earth_radius * 0.28, Color("#02101c", 0.28))
		draw_circle(earth_center + Vector2(earth_radius * 0.26, -earth_radius * 0.12), earth_radius * 0.16, Color("#cfe9ff", 0.28))
		var horizon_y: float = size.y * 0.7
		var points := PackedVector2Array()
		points.append(Vector2(0, size.y))
		for i in range(17):
			var x: float = size.x * float(i) / 16.0
			var ridge: float = sin(float(i) * 1.17) * 24.0 + sin(float(i) * 2.31) * 10.0
			points.append(Vector2(x, horizon_y + ridge))
		points.append(Vector2(size.x, size.y))
		draw_colored_polygon(points, Color("#151c24"))
		for i in range(11):
			var x: float = size.x * (0.52 + float(i) * 0.035)
			var base_y: float = horizon_y + 18.0 + sin(float(i)) * 10.0
			draw_rect(Rect2(Vector2(x, base_y - 28.0), Vector2(18.0, 28.0)), Color("#2b333b"), true)
			draw_rect(Rect2(Vector2(x + 5.0, base_y - 16.0), Vector2(7.0, 6.0)), Color("#f0c766", 0.72), true)
			draw_line(Vector2(x + 9.0, base_y - 30.0), Vector2(x + 9.0, base_y - 58.0), Color("#5d6f7d", 0.6), 1.0)
			draw_circle(Vector2(x + 9.0, base_y - 58.0), 2.0, Color("#d66a4f", 0.75))
		draw_rect(Rect2(Vector2.ZERO, size), Color("#00050c", 0.28), true)
		draw_rect(rect.grow(-22), Color("#31414d", 0.35), false, 1.0)

var day := 1
var is_moon_night := false
var game_over := false
var supply_waiting := false
var supply_order: Dictionary = {}
var next_supply_request_day := 1
var supply_travel_days := 3
var current_save_slot := 1
var pending_main_menu := true
var dev_menu_visible := false

var player_pos := Vector2(300, 420)
var player_radius := 14.0
var player_facing := Vector2.DOWN
var player_moving := false
var walk_phase := 0.0
var was_inside := false
var eva_warning_cooldown := 0.0
var step_audio_cooldown := 0.0
var interact_target: Dictionary = {}

var selected_crop := "potato"
var selected_tool := "sampler"
var build_mode := false
var selected_build := ""
var unlocked_techs: Array[String] = []
var completed_missions: Array[String] = []
var log_lines: Array[String] = []
var tutorial_flags := {}
var last_guidance_tip := ""
var task_log_expanded := false
var task_history: Array[String] = []
var intro_overlay_seen := false
var objective_tracking := false
var tracked_objective_index := 0
var feedback_text := ""
var feedback_timer := 0.0
var map_marker_text := ""
var map_marker_pos := Vector2(INF, INF)
var map_marker_timer := 0.0
var robot_task := "idle"
var robot_queue: Array[String] = []
var robot_pos := Vector2.ZERO
var robot_target := Vector2.ZERO
var robot_active := false
var robot_path_pulse := 0.0
var robot_battery := 100.0
var robot_charging := false
var robot_failure_note := ""
var backpack := {
	"regolith": 0.0,
	"ice": 0.0,
	"samples": 0.0,
	"parts": 0.0,
	"food": 0.0,
	"water": 0.0,
	"oxygen": 0.0,
	"power": 0.0,
}
var backpack_capacity := 12.0
var solar_storm_days := 0
var micrometeor_alert_days := 0
var low_o2_warning_cooldown := 0.0
var camera_zoom := 1.0
var ui_scale := 1.0

var solar_dust := 0.12
var oxygen_wear := 0.08
var next_module_uid := 1
var next_collectable_uid := 1

var resources := {
	"power": 76.0,
	"oxygen": 82.0,
	"water": 68.0,
	"food": 50.0,
	"parts": 8.0,
	"integrity": 88.0,
	"regolith": 0.0,
	"ice": 0.0,
	"samples": 0.0,
	"co2": 34.0,
	"humidity": 52.0,
	"pressure": 100.0,
	"suit_o2": 100.0,
	"suit_integrity": 100.0,
	"suit_dust": 0.0,
}

var resource_names := {
	"power": "电力",
	"oxygen": "氧气",
	"water": "水",
	"food": "食物",
	"parts": "维修件",
	"integrity": "完整度",
	"regolith": "月壤",
	"ice": "水冰",
	"samples": "样本",
	"co2": "二氧化碳",
	"humidity": "湿度",
	"pressure": "舱压",
	"suit_o2": "宇航服氧气",
	"suit_integrity": "宇航服耐久",
	"suit_dust": "月尘污染",
}

var tool_defs := {
	"sampler": {"name": "采样铲", "hint": "采集月壤、冰样本和陨石碎片"},
	"brush": {"name": "除尘刷", "hint": "清理太阳能阵列月尘"},
	"repair": {"name": "维修枪", "hint": "维护生命维持设备"},
}

var crop_defs := {
	"potato": {"name": "土豆", "days": 4, "water": 5.0, "oxygen": 2.0, "food": 22.0, "note": "可靠主粮"},
	"algae": {"name": "藻类", "days": 2, "water": 3.0, "oxygen": 10.0, "food": 7.0, "note": "产氧强，口感差"},
	"mushroom": {"name": "菌菇", "days": 3, "water": 2.0, "oxygen": 0.0, "food": 13.0, "note": "低光照也能生产"},
}

var module_defs := {
	"hab": {
		"name": "居住舱",
		"size": Vector2i(3, 2),
		"cost": {"parts": 0.0, "power": 0.0},
		"color": Color("#596575"),
		"hint": "广寒前哨核心舱",
	},
	"greenhouse": {
		"name": "小型温室",
		"size": Vector2i(4, 2),
		"cost": {"parts": 4.0, "power": 8.0},
		"color": Color("#244638"),
		"hint": "E：播种/查看作物",
	},
	"solar": {
		"name": "太阳能阵列",
		"size": Vector2i(4, 2),
		"cost": {"parts": 3.0, "power": 4.0},
		"color": Color("#263b57"),
		"hint": "E：清理月尘",
	},
	"battery": {
		"name": "电池舱",
		"size": Vector2i(2, 2),
		"cost": {"parts": 3.0, "power": 6.0},
		"color": Color("#363d55"),
		"hint": "储能模块：提高电力上限",
	},
	"life_support": {
		"name": "制氧与水回收",
		"size": Vector2i(3, 2),
		"cost": {"parts": 5.0, "power": 8.0},
		"color": Color("#30384a"),
		"hint": "E：维修设备",
	},
	"workshop": {
		"name": "维修工作台",
		"size": Vector2i(2, 2),
		"cost": {"parts": 5.0, "power": 5.0},
		"color": Color("#514937"),
		"hint": "E：制造 1 个维修件",
	},
	"airlock": {
		"name": "气闸舱",
		"size": Vector2i(2, 2),
		"cost": {"parts": 4.0, "power": 6.0},
		"color": Color("#4a5364"),
		"hint": "E：气闸循环，补满宇航服氧气",
	},
	"regolith_plant": {
		"name": "月壤提氧机",
		"size": Vector2i(3, 2),
		"cost": {"parts": 6.0, "power": 10.0},
		"color": Color("#4b4650"),
		"hint": "E：消耗月壤和电力提取氧气",
	},
	"ice_processor": {
		"name": "冰矿处理器",
		"size": Vector2i(3, 2),
		"cost": {"parts": 5.0, "power": 8.0},
		"color": Color("#355566"),
		"hint": "E：消耗水冰和电力产水",
	},
	"supply": {
		"name": "补给降落区",
		"size": Vector2i(4, 3),
		"cost": {"parts": 0.0, "power": 0.0},
		"color": Color("#3d3530"),
		"hint": "E：申请/领取地球补给",
	},
}

var supply_defs := {
	"survival": {
		"name": "生存包",
		"mass": 300,
		"desc": "食物 + 水 + 氧气",
		"payload": {"food": 28.0, "water": 20.0, "oxygen": 22.0},
	},
	"build": {
		"name": "建设包",
		"mass": 300,
		"desc": "维修件 + 电池 + 除尘耗材",
		"payload": {"parts": 7.0, "power": 18.0, "dust": -0.12},
	},
	"farm": {
		"name": "农业包",
		"mass": 300,
		"desc": "水培耗材 + 温室备件",
		"payload": {"water": 10.0, "parts": 3.0},
	},
}

var tech_defs := {
	"change_samples": {
		"name": "嫦娥样本数据库",
		"cost": {"samples": 2.0, "regolith": 4.0},
		"desc": "样本分析与月壤农业参数库：采样收益提高，作物收获额外 +15%。",
	},
	"queqiao_relay": {
		"name": "鹊桥中继",
		"cost": {"samples": 1.0, "parts": 4.0},
		"desc": "通信链路升级：补给运输缩短 1 天，并降低发射延迟概率。",
	},
	"yutu_robot": {
		"name": "玉兔机器人",
		"cost": {"parts": 6.0, "regolith": 6.0},
		"desc": "自动巡视：每天少量采样，并缓慢清理太阳能板月尘。",
	},
	"closed_ecology": {
		"name": "闭环生态控制",
		"cost": {"samples": 3.0, "water": 8.0, "co2": 10.0},
		"desc": "温室湿度和 CO2 调节更稳定，前哨员健康下降减缓。",
	},
	"precision_landing": {
		"name": "精确着陆雷达",
		"cost": {"samples": 2.0, "parts": 5.0},
		"desc": "补给舱落点偏差降低，鹊桥链路可辅助修正弹道。",
	},
	"robot_assist": {
		"name": "机器人协作协议",
		"cost": {"parts": 5.0, "samples": 2.0},
		"desc": "玉兔和维护机器人分担重复劳动，降低前哨员压力。",
	},
}

var mission_defs := {
	"survive_7": {"name": "稳住第一周", "desc": "生存到第 7 天。"},
	"first_greenhouse": {"name": "第一座温室", "desc": "建造或保有 1 座温室。"},
	"local_oxygen": {"name": "原位制氧", "desc": "让基地氧气储备达到 100。"},
	"supply_recovery": {"name": "出舱取货", "desc": "成功回收 1 个偏差落点补给舱。"},
	"operator_stable": {"name": "前哨员稳定", "desc": "健康和精神状态都保持在 60 以上。"},
}

var modules: Array[Dictionary] = []
var collectables: Array[Dictionary] = []
var operator := {}
var moon_tile_map: TileMapLayer
var interior_tile_map: TileMapLayer
var moon_tile_source_id := 0
var interior_tile_source_id := 0
var entity_root: Node2D
var camera: Camera2D
var save_manager: Node
var audio_feedback: Node
var game_state_manager: Node
var time_manager: Node
var camera_manager: Node
var ui_manager: Node
var event_manager: Node
var audio_manager: Node
var robot_task_manager: Node
var module_nodes: Dictionary = {}
var collectable_nodes: Dictionary = {}
var player_node: Node2D
var robot_node: Node2D

func _ready() -> void:
	_setup_input_map()
	_reset_game_state()
	_setup_moon_tile_map()
	_setup_interior_tile_map()
	_setup_entity_root()
	_setup_audio()
	_setup_ui()
	_setup_main_menu()
	add_log("任务简报：你是广寒前哨唯一常驻前哨员。先看左上角当前目标。")
	add_log("第一天目标：看控制台、气闸补氧、出舱采集、回储物柜入库、种植、申请补给。")
	_sync_scene_instances()
	_update_ui()

func _setup_input_map() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("advance_day", [KEY_N])
	_add_key_action("toggle_build", [KEY_B])
	_add_key_action("cancel", [KEY_ESCAPE])
	_add_key_action("save_game", [KEY_F5])
	_add_key_action("load_game", [KEY_F9])
	_add_key_action("new_game", [KEY_F10])
	_add_key_action("camera_zoom_in", [KEY_Z])
	_add_key_action("camera_zoom_out", [KEY_X])
	_add_key_action("ui_scale_down", [KEY_BRACKETLEFT])
	_add_key_action("ui_scale_up", [KEY_BRACKETRIGHT])
	_add_key_action("toggle_objective_tracking", [KEY_T])
	_add_key_action("cycle_objective_target", [KEY_Y])

func _add_key_action(action_name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key: int in keys:
		var event := InputEventKey.new()
		event.keycode = key
		InputMap.action_add_event(action_name, event)

func _reset_game_state() -> void:
	day = 1
	is_moon_night = false
	game_over = false
	supply_waiting = false
	supply_order = {}
	next_supply_request_day = 1
	supply_travel_days = 3
	current_save_slot = clamp(current_save_slot, 1, SAVE_SLOTS)
	player_pos = Vector2(300, 420)
	player_facing = Vector2.DOWN
	player_moving = false
	was_inside = false
	eva_warning_cooldown = 0.0
	step_audio_cooldown = 0.0
	walk_phase = 0.0
	interact_target = {}
	selected_crop = "potato"
	selected_tool = "sampler"
	build_mode = false
	selected_build = ""
	unlocked_techs.clear()
	completed_missions.clear()
	tutorial_flags = _default_tutorial_flags()
	last_guidance_tip = ""
	task_log_expanded = false
	task_history.clear()
	intro_overlay_seen = false
	objective_tracking = false
	tracked_objective_index = 0
	feedback_text = ""
	feedback_timer = 0.0
	map_marker_text = ""
	map_marker_pos = Vector2(INF, INF)
	map_marker_timer = 0.0
	robot_task = "idle"
	robot_queue.clear()
	robot_pos = _cell_to_world(Vector2i(10, 6))
	robot_target = robot_pos
	robot_active = false
	robot_path_pulse = 0.0
	robot_battery = 100.0
	robot_charging = false
	robot_failure_note = ""
	backpack = _default_backpack()
	solar_storm_days = 0
	micrometeor_alert_days = 0
	low_o2_warning_cooldown = 0.0
	camera_zoom = 1.0
	ui_scale = 1.0
	if is_instance_valid(time_manager) and time_manager.has_method("set_time"):
		time_manager.call("set_time", day, 7, 42)
	if is_instance_valid(game_state_manager) and game_state_manager.has_method("change_state"):
		game_state_manager.call("change_state", GameStateManagerScript.MAIN_MENU)
	solar_dust = 0.12
	oxygen_wear = 0.08
	next_module_uid = 1
	next_collectable_uid = 1
	resources = _default_resources()
	modules.clear()
	collectables.clear()
	operator = _default_operator()
	log_lines.clear()
	_setup_starting_base()
	_setup_collectables()
	if has_node("UI/Root/SupplyPanel"):
		$UI/Root/SupplyPanel.visible = false
	_sync_scene_instances()

func _default_operator() -> Dictionary:
	return {"name": "林舟", "health": 92.0, "morale": 78.0, "fatigue": 12.0}

func _default_resources() -> Dictionary:
	return {
		"power": 76.0,
		"oxygen": 82.0,
		"water": 68.0,
		"food": 50.0,
		"parts": 8.0,
		"integrity": 88.0,
		"regolith": 0.0,
		"ice": 0.0,
		"samples": 0.0,
		"co2": 34.0,
		"humidity": 52.0,
		"pressure": 100.0,
		"suit_o2": 100.0,
		"suit_integrity": 100.0,
		"suit_dust": 0.0,
	}

func _default_backpack() -> Dictionary:
	return {
		"regolith": 0.0,
		"ice": 0.0,
		"samples": 0.0,
		"parts": 0.0,
		"food": 0.0,
		"water": 0.0,
		"oxygen": 0.0,
		"power": 0.0,
	}

func _default_tutorial_flags() -> Dictionary:
	return {
		"console": false,
		"airlock": false,
		"collected": false,
		"stored": false,
		"planted": false,
		"supply": false,
		"advanced_day": false,
	}

func _setup_starting_base() -> void:
	modules.clear()
	_add_module("solar", Vector2i(2, 1), true)
	_add_module("hab", Vector2i(4, 5), true)
	_add_module("airlock", Vector2i(7, 5), true)
	_add_module("life_support", Vector2i(9, 5), true)
	_add_module("greenhouse", Vector2i(12, 5), true)
	_add_module("supply", Vector2i(17, 7), true)
	var hab_module: Dictionary = modules[1]
	player_pos = _module_rect(hab_module).position + Vector2(84, 58)

func _process(delta: float) -> void:
	if game_over or pending_main_menu:
		return
	eva_warning_cooldown = max(0.0, eva_warning_cooldown - delta)
	low_o2_warning_cooldown = max(0.0, low_o2_warning_cooldown - delta)
	step_audio_cooldown = max(0.0, step_audio_cooldown - delta)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_moving = input.length() > 0.01
	var target_pos := player_pos + input * PLAYER_SPEED * delta
	if _can_player_move_to(target_pos):
		player_pos = target_pos
	if player_moving:
		player_facing = input.normalized()
		walk_phase += delta * 10.0
		if step_audio_cooldown <= 0.0:
			_play_audio_event("step")
			step_audio_cooldown = 0.32
	player_pos.x = clamp(player_pos.x, MAP_ORIGIN.x + 5.0, MAP_ORIGIN.x + MAP_W * TILE - 5.0)
	player_pos.y = clamp(player_pos.y, MAP_ORIGIN.y + 5.0, MAP_ORIGIN.y + MAP_H * TILE - 5.0)
	_process_suit_oxygen(delta)
	_process_robot_queue(delta)
	_find_interaction()
	_sync_scene_instances()
	_update_camera()
	_update_edge_hint()
	_update_completion_toast()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F12:
		_toggle_dev_menu()
		return
	if pending_main_menu:
		return
	if event.is_action_pressed("save_game"):
		_save_game()
	if event.is_action_pressed("load_game"):
		_load_game()
	if event.is_action_pressed("new_game"):
		_start_new_game()
	if event.is_action_pressed("camera_zoom_in"):
		_adjust_camera_zoom(0.1)
	if event.is_action_pressed("camera_zoom_out"):
		_adjust_camera_zoom(-0.1)
	if event.is_action_pressed("ui_scale_down"):
		_adjust_ui_scale(-0.1)
	if event.is_action_pressed("ui_scale_up"):
		_adjust_ui_scale(0.1)
	if event.is_action_pressed("toggle_objective_tracking"):
		_toggle_objective_tracking()
	if event.is_action_pressed("cycle_objective_target"):
		_cycle_objective_target()
	if event.is_action_pressed("toggle_build") and not game_over:
		_toggle_build_mode()
	if event.is_action_pressed("cancel") and not game_over:
		build_mode = false
		selected_build = ""
		_hide_info_panels()
		_update_ui()
	if event.is_action_pressed("interact") and not game_over:
		_interact()
	if event.is_action_pressed("advance_day") and not game_over:
		_advance_day()

func _draw() -> void:
	_draw_robot_path()
	_draw_map_marker()
	_draw_tutorial_arrow()
	_draw_build_ghost()

func _update_camera() -> void:
	if not is_instance_valid(camera):
		return
	var target := player_pos
	if objective_tracking:
		var objective_pos := _active_objective_target_pos()
		if objective_pos.x != INF:
			target = objective_pos
	if is_instance_valid(camera_manager) and camera_manager.has_method("update_camera"):
		camera_manager.call("update_camera", camera, target, camera_zoom)
	else:
		camera.position = target

func _process_robot_queue(delta: float) -> void:
	robot_path_pulse += delta
	feedback_timer = max(0.0, feedback_timer - delta)
	map_marker_timer = max(0.0, map_marker_timer - delta)
	if robot_charging:
		_process_robot_charging(delta)
		return
	if not robot_active:
		_try_start_robot_task()
		return
	robot_battery = max(0.0, robot_battery - delta * 4.5)
	if robot_battery <= 12.0:
		_start_robot_charging(true)
		return
	var to_target: Vector2 = robot_target - robot_pos
	if to_target.length() <= 4.0:
		robot_active = false
		_complete_robot_task(robot_task)
		return
	robot_pos += to_target.normalized() * 120.0 * delta

func _try_start_robot_task() -> void:
	if robot_charging:
		return
	if robot_queue.is_empty():
		robot_task = "idle"
		return
	if not _can_run_robot():
		return
	if robot_battery <= 18.0:
		robot_task = String(robot_queue[0])
		_start_robot_charging(false)
		return
	var next_task := String(robot_queue[0])
	var skip_reason := _robot_task_skip_reason(next_task)
	if not skip_reason.is_empty():
		robot_queue.pop_front()
		_skip_robot_task(next_task, skip_reason)
		return
	robot_task = String(robot_queue.pop_front())
	_set_robot_target_for_task(robot_task)
	add_log("%s 启动：%s。" % [_robot_type_name(robot_task), _robot_task_name(robot_task)])
	_play_audio_event("robot")

func _start_robot_charging(requeue_current: bool) -> void:
	if requeue_current and not ["idle", "charging"].has(robot_task):
		robot_queue.insert(0, robot_task)
		add_log("机器人电量低：暂停 %s，返回充电桩。" % _robot_task_name(robot_task))
	else:
		add_log("机器人电量低：返回充电桩等待充电。")
	robot_task = "charging"
	robot_charging = true
	robot_active = true
	robot_target = _robot_home_pos()
	_play_audio_event("robot")

func _process_robot_charging(delta: float) -> void:
	var home: Vector2 = _robot_home_pos()
	robot_target = home
	var to_home: Vector2 = home - robot_pos
	if to_home.length() > 4.0:
		robot_pos += to_home.normalized() * 135.0 * delta
		robot_battery = max(0.0, robot_battery - delta * 2.0)
		return
	robot_active = false
	if resources["power"] <= 0.1:
		robot_task = "charging"
		return
	var charge_amount: float = min(100.0 - robot_battery, delta * 24.0)
	var power_cost: float = charge_amount * 0.06
	if resources["power"] < power_cost:
		charge_amount = resources["power"] / 0.06
		power_cost = resources["power"]
	resources["power"] = max(0.0, resources["power"] - power_cost)
	robot_battery = min(100.0, robot_battery + charge_amount)
	if robot_battery >= 96.0:
		robot_charging = false
		robot_task = String(robot_queue[0]) if not robot_queue.is_empty() else "idle"
		add_log("机器人充电完成：电量 %.0f%%。" % robot_battery)
		_play_audio_event("robot")
	_update_ui()

func _set_robot_target_for_task(task: String) -> void:
	robot_active = true
	match task:
		"sample":
			var sample_target: Dictionary = _nearest_collectable_item(["regolith", "ice", "sample"])
			robot_target = sample_target["pos"] if not sample_target.is_empty() else robot_pos
		"maintenance":
			robot_target = _nearest_module_pos(["solar", "regolith_plant", "ice_processor"])
		"haul":
			var haul_target: Dictionary = _nearest_collectable_item(["supply_pod"])
			robot_target = haul_target["pos"] if not haul_target.is_empty() else robot_pos
		_:
			robot_target = _robot_home_pos()

func _robot_home_pos() -> Vector2:
	var charger_pos: Vector2 = _facility_target_pos("workshop", "robot_charger")
	if charger_pos.x != INF:
		return charger_pos
	return _cell_to_world(Vector2i(10, 6))

func _complete_robot_task(task: String) -> void:
	match task:
		"sample":
			if not _complete_robot_sample_task():
				return
		"maintenance":
			solar_dust = max(0.0, solar_dust - 0.06)
			resources["integrity"] = min(100.0, resources["integrity"] + 1.2)
			add_log("维护机器人巡检完成：月尘降低，基地完整度 +1.2。")
			_show_task_feedback("维护巡检完成", robot_pos)
			_play_audio_event("tool")
		"haul":
			if _robot_haul_supply():
				add_log("搬运机器人完成：从补给舱转运一批货物。")
				_show_task_feedback("搬运补给完成", robot_pos)
				_play_audio_event("cargo")
			else:
				_skip_robot_task(task, "搬运机器人没有找到可搬运补给舱或剩余货物，任务已跳过。")
				return
	robot_task = String(robot_queue[0]) if not robot_queue.is_empty() else "idle"
	_update_ui()

func _complete_robot_sample_task() -> bool:
	var target: Dictionary = _collectable_item_near(robot_target, ["regolith", "ice", "sample"], 34.0)
	if target.is_empty():
		var replacement: Dictionary = _nearest_collectable_item(["regolith", "ice", "sample"])
		if replacement.is_empty():
			_skip_robot_task("sample", "玉兔采样没有找到可用资源点，任务已跳过。")
			return false
		robot_target = replacement["pos"]
		robot_active = true
		robot_task = "sample"
		robot_failure_note = "玉兔采样目标已耗尽，已重新选择最近资源点。"
		add_log(robot_failure_note)
		_play_audio_event("robot")
		return false
	var item_type := String(target["type"])
	var amount := float(target.get("amount", 1.0))
	target["depleted"] = true
	match item_type:
		"ice":
			resources["ice"] += max(0.6, amount)
			add_log("玉兔采样完成：水冰 +%.1f。" % max(0.6, amount))
		"sample":
			resources["samples"] += max(0.5, amount)
			add_log("玉兔采样完成：科研样本 +%.1f。" % max(0.5, amount))
		_:
			resources["regolith"] += max(0.8, amount)
			add_log("玉兔采样完成：月壤 +%.1f。" % max(0.8, amount))
	robot_failure_note = ""
	_sync_scene_instances()
	_show_task_feedback("玉兔采样完成", robot_pos)
	_play_audio_event("tool")
	return true

func _skip_robot_task(task: String, reason: String) -> void:
	robot_failure_note = reason
	robot_task = String(robot_queue[0]) if not robot_queue.is_empty() else "idle"
	robot_active = false
	robot_target = robot_pos
	add_log("%s：%s" % [_robot_task_name(task), reason])
	_play_audio_event("robot")
	_update_ui()

func _robot_task_skip_reason(task: String) -> String:
	match task:
		"haul":
			if _nearest_collectable_item(["supply_pod"]).is_empty():
				return "没有落地补给舱，搬运任务自动跳过。"
			if not _has_supply_cargo_remaining():
				return "补给舱货物已经搬空，搬运任务自动跳过。"
		"sample":
			if _nearest_collectable_item(["regolith", "ice", "sample"]).is_empty():
				return "没有可用月壤、水冰或科研样本点，玉兔采样自动跳过。"
		"maintenance":
			if not _has_robot_maintenance_work():
				return "没有需要维护的外部设备，维护巡检自动跳过。"
	return ""

func _has_robot_maintenance_work() -> bool:
	return solar_dust >= 0.08 or _leaking_module_count() > 0 or resources["integrity"] < 96.0

func _has_supply_cargo_remaining() -> bool:
	if supply_order.is_empty() or not supply_order.has("cargo_remaining"):
		return false
	var cargo: Dictionary = supply_order["cargo_remaining"]
	for key: String in cargo.keys():
		if float(cargo[key]) > 0.0:
			return true
	return false

func _collectable_item_near(pos: Vector2, types: Array[String], radius: float) -> Dictionary:
	var best: Dictionary = {}
	var best_dist := radius
	for item: Dictionary in collectables:
		if bool(item["depleted"]):
			continue
		if not types.has(String(item["type"])):
			continue
		var item_pos: Vector2 = item["pos"]
		var dist := pos.distance_to(item_pos)
		if dist <= best_dist:
			best_dist = dist
			best = item
	return best

func _nearest_collectable_item(types: Array[String]) -> Dictionary:
	var best: Dictionary = {}
	var best_dist: float = INF
	for item: Dictionary in collectables:
		if bool(item["depleted"]):
			continue
		if not types.has(String(item["type"])):
			continue
		var pos: Vector2 = item["pos"]
		var dist: float = robot_pos.distance_to(pos)
		if dist < best_dist:
			best_dist = dist
			best = item
	return best

func _nearest_collectable_from(origin: Vector2, types: Array[String]) -> Dictionary:
	var best: Dictionary = {}
	var best_dist: float = INF
	for item: Dictionary in collectables:
		if bool(item["depleted"]):
			continue
		if not types.has(String(item["type"])):
			continue
		var pos: Vector2 = item["pos"]
		var dist: float = origin.distance_to(pos)
		if dist < best_dist:
			best_dist = dist
			best = item
	return best

func _nearest_collectable_pos(types: Array[String]) -> Vector2:
	var target: Dictionary = _nearest_collectable_item(types)
	return target["pos"] if not target.is_empty() else robot_pos

func _nearest_module_pos(types: Array[String]) -> Vector2:
	var best: Vector2 = robot_pos
	var best_dist: float = INF
	for module: Dictionary in modules:
		if not types.has(String(module["type"])):
			continue
		var pos: Vector2 = _module_rect(module).get_center()
		var dist: float = robot_pos.distance_to(pos)
		if dist < best_dist:
			best_dist = dist
			best = pos
	return best

func _adjust_camera_zoom(delta: float) -> void:
	camera_zoom = clamp(camera_zoom + delta, 0.7, 1.6)
	_apply_camera_zoom()
	add_log("地图缩放：%d%%。" % int(camera_zoom * 100))
	_update_ui()

func _apply_camera_zoom() -> void:
	if is_instance_valid(camera_manager) and camera_manager.has_method("apply_zoom"):
		camera_zoom = float(camera_manager.call("apply_zoom", camera, camera_zoom))
	elif is_instance_valid(camera):
		camera.zoom = Vector2(camera_zoom, camera_zoom)

func _adjust_ui_scale(delta: float) -> void:
	ui_scale = clamp(ui_scale + delta, 0.8, 1.3)
	_apply_ui_scale()
	add_log("UI 缩放：%d%%。" % int(ui_scale * 100))
	_update_ui()

func _apply_ui_scale() -> void:
	if has_node("UI/Root"):
		var root: Control = $UI/Root
		root.scale = Vector2(ui_scale, ui_scale)
		root.position = Vector2.ZERO

func _setup_entity_root() -> void:
	entity_root = Node2D.new()
	entity_root.name = "Entities"
	add_child(entity_root)
	camera = Camera2D.new()
	camera.name = "PlayerCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)
	if is_instance_valid(camera_manager) and camera_manager.has_method("configure"):
		camera_manager.call("configure", camera)
	player_node = PLAYER_SCENE.instantiate()
	player_node.name = "Player"
	player_node.z_index = 30
	entity_root.add_child(player_node)
	robot_node = ROBOT_SCENE.instantiate()
	robot_node.name = "Robot"
	robot_node.z_index = 24
	entity_root.add_child(robot_node)
	_apply_camera_zoom()
	_sync_scene_instances()

func _setup_audio() -> void:
	game_state_manager = GameStateManagerScript.new()
	game_state_manager.name = "GameStateManager"
	add_child(game_state_manager)
	time_manager = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	add_child(time_manager)
	time_manager.call("set_time", day, 7, 42)
	camera_manager = CameraManagerScript.new()
	camera_manager.name = "CameraManager"
	add_child(camera_manager)
	if is_instance_valid(camera):
		camera_manager.call("configure", camera)
	ui_manager = UIManagerScript.new()
	ui_manager.name = "UIManager"
	add_child(ui_manager)
	event_manager = EventManagerScript.new()
	event_manager.name = "EventManager"
	add_child(event_manager)
	audio_manager = AudioManagerScript.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)
	save_manager = SaveManagerScript.new()
	save_manager.name = "SaveManager"
	add_child(save_manager)
	audio_feedback = AudioFeedbackScript.new()
	audio_feedback.name = "AudioFeedback"
	add_child(audio_feedback)
	audio_manager.call("set_backend", audio_feedback)
	robot_task_manager = RobotTaskManagerScript.new()
	robot_task_manager.name = "RobotTaskManager"
	add_child(robot_task_manager)
	game_state_manager.call("change_state", GameStateManagerScript.MAIN_MENU)
	event_manager.call("trigger", "foundation_boot", {}, true)

func _play_ui_tone(frequency: float = 660.0, duration: float = 0.08, volume: float = 0.08) -> void:
	if is_instance_valid(audio_manager) and audio_manager.has_method("play_ui"):
		audio_manager.call("play_ui", frequency, duration, volume)
		return
	if is_instance_valid(audio_feedback) and audio_feedback.has_method("play_tone"):
		audio_feedback.call("play_tone", frequency, duration, volume)

func _play_audio_event(event_name: String) -> void:
	if is_instance_valid(audio_manager) and audio_manager.has_method("play_event"):
		audio_manager.call("play_event", event_name)
		return
	if is_instance_valid(audio_feedback) and audio_feedback.has_method("play_event"):
		audio_feedback.call("play_event", event_name)
	else:
		_play_ui_tone()

func _set_guidance_tip(text: String) -> void:
	last_guidance_tip = text
	_update_ui()

func _clear_guidance_tip() -> void:
	last_guidance_tip = ""

func _sync_scene_instances() -> void:
	if not is_instance_valid(entity_root):
		return
	if is_instance_valid(player_node):
		player_node.position = player_pos
		if player_node.has_method("setup"):
			player_node.call("setup", player_facing, _is_player_inside_pressurized_module(), resources["suit_o2"], player_moving, walk_phase)
	if is_instance_valid(robot_node):
		robot_node.position = robot_pos
		if robot_node.has_method("setup"):
			robot_node.call("setup", robot_task, robot_active, robot_battery, robot_charging)
	for module: Dictionary in modules:
		var uid := int(module["uid"])
		if not module_nodes.has(uid) or not is_instance_valid(module_nodes[uid]):
			var node := MODULE_SCENE.instantiate()
			node.z_index = 5
			entity_root.add_child(node)
			module_nodes[uid] = node
		var module_node: Node2D = module_nodes[uid]
		module_node.position = _module_rect(module).position
		if module_node.has_method("setup"):
			var visual_data: Dictionary = module.duplicate(true)
			visual_data["doors"] = _module_door_sides(module)
			visual_data["active_facility"] = ""
			if interact_target.get("kind", "") == "facility" and int(interact_target.get("module_uid", -1)) == uid:
				visual_data["active_facility"] = String(interact_target.get("facility", ""))
			module_node.call("setup", visual_data, module_defs[module["type"]], interact_target == module)
	for uid in module_nodes.keys():
		var still_exists := false
		for module: Dictionary in modules:
			if int(module["uid"]) == int(uid):
				still_exists = true
				break
		if not still_exists and is_instance_valid(module_nodes[uid]):
			module_nodes[uid].queue_free()
			module_nodes.erase(uid)
	for item: Dictionary in collectables:
		var uid := int(item["uid"])
		if not collectable_nodes.has(uid) or not is_instance_valid(collectable_nodes[uid]):
			var node := COLLECTABLE_SCENE.instantiate()
			node.z_index = 8
			entity_root.add_child(node)
			collectable_nodes[uid] = node
		var item_node: Node2D = collectable_nodes[uid]
		item_node.position = item["pos"]
		if item_node.has_method("setup"):
			item_node.call("setup", item, interact_target == item)
	for uid in collectable_nodes.keys():
		var still_exists := false
		for item: Dictionary in collectables:
			if int(item["uid"]) == int(uid):
				still_exists = true
				break
		if not still_exists and is_instance_valid(collectable_nodes[uid]):
			collectable_nodes[uid].queue_free()
			collectable_nodes.erase(uid)

func _setup_moon_tile_map() -> void:
	if is_instance_valid(moon_tile_map):
		moon_tile_map.queue_free()
	moon_tile_map = TileMapLayer.new()
	moon_tile_map.name = "MoonSurfaceTileMap"
	moon_tile_map.position = MAP_ORIGIN
	moon_tile_map.z_index = -20
	moon_tile_map.tile_set = _create_moon_tile_set()
	add_child(moon_tile_map)
	_paint_moon_surface_tiles()

func _setup_interior_tile_map() -> void:
	if is_instance_valid(interior_tile_map):
		interior_tile_map.queue_free()
	interior_tile_map = TileMapLayer.new()
	interior_tile_map.name = "InteriorFloorTileMap"
	interior_tile_map.position = MAP_ORIGIN
	interior_tile_map.z_index = -10
	interior_tile_map.tile_set = _create_interior_tile_set()
	add_child(interior_tile_map)
	_paint_interior_tiles()

func _create_moon_tile_set() -> TileSet:
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	var image: Image = Image.create(TILE * 4, TILE, false, Image.FORMAT_RGBA8)
	for tile_x in range(4):
		for px in range(TILE):
			for py in range(TILE):
				var base: float = 0.12 + float(tile_x) * 0.02
				var grain: float = float((px * 13 + py * 7 + tile_x * 19) % 11) * 0.003
				var crater: float = _tile_crater_shadow(tile_x, px, py)
				var shade: float = clamp(base + grain + crater, 0.04, 0.28)
				var cool: float = shade + 0.035
				image.set_pixel(tile_x * TILE + px, py, Color(shade * 0.86, shade * 0.90, cool, 1.0))
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	for tile_x in range(4):
		source.create_tile(Vector2i(tile_x, 0))
	moon_tile_source_id = tile_set.add_source(source)
	return tile_set

func _create_interior_tile_set() -> TileSet:
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	var image: Image = Image.create(TILE * 3, TILE, false, Image.FORMAT_RGBA8)
	for tile_x in range(3):
		for px in range(TILE):
			for py in range(TILE):
				var seam := 0.09 if px < 2 or py < 2 else 0.0
				var stripe := 0.045 if (px + tile_x * 9) % 16 < 3 else 0.0
				var base := 0.34 + float(tile_x) * 0.035 + seam + stripe
				image.set_pixel(tile_x * TILE + px, py, Color(base, base + 0.035, base + 0.055, 1.0))
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	for tile_x in range(3):
		source.create_tile(Vector2i(tile_x, 0))
	interior_tile_source_id = tile_set.add_source(source)
	return tile_set

func _tile_crater_shadow(tile_x: int, px: int, py: int) -> float:
	if tile_x == 0:
		return 0.0
	var center := Vector2(18 + tile_x * 3, 23 + tile_x * 2)
	var dist := Vector2(px, py).distance_to(center)
	if tile_x == 1 and dist < 13.0:
		return -0.055 + dist * 0.002
	if tile_x == 2 and dist < 18.0:
		return -0.04 + dist * 0.0015
	if tile_x == 3 and (px + py) % 17 < 2:
		return 0.035
	return 0.0

func _paint_moon_surface_tiles() -> void:
	moon_tile_map.clear()
	for x in range(MAP_W):
		for y in range(MAP_H):
			var atlas_x := int((x * 17 + y * 11) % 4)
			moon_tile_map.set_cell(Vector2i(x, y), moon_tile_source_id, Vector2i(atlas_x, 0))

func _paint_interior_tiles() -> void:
	if not is_instance_valid(interior_tile_map):
		return
	interior_tile_map.clear()
	for module: Dictionary in modules:
		if not _module_has_interior(module["type"]):
			continue
		var def: Dictionary = module_defs[module["type"]]
		var cell: Vector2i = module["cell"]
		var size: Vector2i = def["size"]
		for x in range(size.x):
			for y in range(size.y):
				var atlas_x := int((x + y + int(module["uid"])) % 3)
				interior_tile_map.set_cell(cell + Vector2i(x, y), interior_tile_source_id, Vector2i(atlas_x, 0))

func _draw_collectables() -> void:
	for item: Dictionary in collectables:
		if item["depleted"]:
			continue
		var pos: Vector2 = item["pos"]
		var color := Color("#b8b2a2")
		if item["type"] == "ice":
			color = Color("#9fd7ff")
		elif item["type"] == "meteor":
			color = Color("#d1a15b")
		elif item["type"] == "sample":
			color = Color("#c9c3a5")
		if interact_target == item:
			draw_circle(pos, 20, Color("#e7c66b"))
		draw_circle(pos, 13, color)
		draw_circle(pos + Vector2(-4, -4), 4, Color(1, 1, 1, 0.28))

func _draw_modules() -> void:
	for module: Dictionary in modules:
		var rect := _module_rect(module)
		var def: Dictionary = module_defs[module["type"]]
		var fill: Color = def["color"]
		if interact_target == module:
			draw_rect(rect.grow(5), Color("#e7c66b"), false, 3)
		if module.get("leaking", false):
			draw_rect(rect.grow(7), Color("#ff5a5a"), false, 4)
		draw_rect(rect, fill)
		draw_rect(rect, Color("#a7b3c5"), false, 2)
		_draw_module_details(module, rect)

func _draw_module_details(module: Dictionary, rect: Rect2) -> void:
	var module_type: String = module["type"]
	if module_type == "greenhouse":
		_draw_greenhouse(module, rect)
	elif module_type == "solar":
		_draw_solar(rect)
	elif module_type == "battery":
		for i in range(2):
			draw_rect(Rect2(rect.position + Vector2(20 + i * 38, 28), Vector2(24, 42)), Color("#a8c7ff"))
	elif module_type == "hab":
		draw_circle(rect.get_center(), min(rect.size.x, rect.size.y) * 0.35, Color("#717d8f"))
	elif module_type == "life_support":
		draw_circle(rect.get_center() + Vector2(-22, 0), 18, Color("#98d5ff"))
		draw_circle(rect.get_center() + Vector2(22, 0), 18, Color("#b8f0d0"))
	elif module_type == "workshop":
		draw_rect(Rect2(rect.position + Vector2(24, 28), Vector2(48, 34)), Color("#c0a36c"))
	elif module_type == "airlock":
		draw_rect(Rect2(rect.position + Vector2(22, 18), Vector2(52, 58)), Color("#8892a3"), false, 4)
		draw_line(rect.position + Vector2(48, 20), rect.position + Vector2(48, 74), Color("#d8e0eb"), 2)
	elif module_type == "regolith_plant":
		draw_circle(rect.get_center() + Vector2(-26, 0), 18, Color("#b3a18e"))
		draw_line(rect.get_center() + Vector2(-8, 0), rect.get_center() + Vector2(32, -18), Color("#d8e0eb"), 3)
		draw_circle(rect.get_center() + Vector2(36, -20), 8, Color("#98d5ff"))
	elif module_type == "ice_processor":
		draw_circle(rect.get_center() + Vector2(-20, 0), 18, Color("#9fd7ff"))
		draw_rect(Rect2(rect.get_center() + Vector2(8, -18), Vector2(34, 36)), Color("#b8f0ff"), false, 3)
	elif module_type == "supply":
		draw_circle(rect.get_center(), 32, Color("#a76f45"))
		draw_rect(Rect2(rect.position + Vector2(68, 35), Vector2(54, 74)), Color("#d0d6df"), false, 3)

func _draw_greenhouse(module: Dictionary, rect: Rect2) -> void:
	var slots := 2
	for i in range(slots):
		var bed: Rect2 = Rect2(rect.position + Vector2(22 + i * 72, 28), Vector2(52, 48))
		draw_rect(bed, Color("#223026"))
		draw_rect(bed, Color("#74b77a"), false, 2)
		if module["crop"] != "":
			var crop_def: Dictionary = crop_defs[module["crop"]]
			var growth: float = min(1.0, float(module["age"] + 1) / float(crop_def["days"]))
			draw_circle(bed.get_center(), 7 + 13 * growth, Color("#71d46f"))

func _draw_solar(rect: Rect2) -> void:
	for i in range(4):
		var panel: Rect2 = Rect2(rect.position + Vector2(14 + i * 40, 18), Vector2(30, 58))
		draw_rect(panel, Color("#365f95"))
		draw_rect(panel, Color("#94bdeb"), false, 1)
	var dust_alpha: float = clamp(solar_dust, 0.0, 0.7)
	draw_rect(rect, Color(0.72, 0.72, 0.66, dust_alpha))

func _draw_build_ghost() -> void:
	if not build_mode or selected_build == "":
		return
	var cell: Vector2i = _player_build_cell()
	var def: Dictionary = module_defs[selected_build]
	var size: Vector2i = def["size"]
	var rect: Rect2 = Rect2(_cell_to_world(cell), Vector2(size.x * TILE - 2, size.y * TILE - 2))
	var can_build := _can_place(selected_build, cell) and _is_connected_placement(selected_build, cell)
	var color := Color(0.3, 0.9, 0.5, 0.38) if can_build else Color(1.0, 0.25, 0.25, 0.38)
	draw_rect(rect, color)
	draw_rect(rect, Color("#f2f0da"), false, 2)

func _draw_robot_path() -> void:
	if not robot_active:
		return
	var color := Color(0.45, 0.95, 1.0, 0.55 + 0.25 * abs(sin(robot_path_pulse * 5.0)))
	var start: Vector2 = robot_pos
	var end: Vector2 = robot_target
	var distance: float = start.distance_to(end)
	if distance < 8.0:
		return
	var direction: Vector2 = (end - start).normalized()
	var segment := 18.0
	var gap := 10.0
	var traveled := fmod(robot_path_pulse * 32.0, segment + gap)
	while traveled < distance:
		var a: Vector2 = start + direction * traveled
		var b: Vector2 = start + direction * min(distance, traveled + segment)
		draw_line(a, b, color, 3)
		traveled += segment + gap
	draw_circle(end, 12.0 + 3.0 * abs(sin(robot_path_pulse * 4.0)), Color(0.45, 0.95, 1.0, 0.22))

func _draw_tutorial_arrow() -> void:
	var target: Vector2 = _tutorial_target_pos()
	if target.x == INF:
		return
	var pulse: float = abs(sin(Time.get_ticks_msec() / 260.0))
	var arrow_tip: Vector2 = target + Vector2(0, -34 - pulse * 8.0)
	var arrow_tail: Vector2 = arrow_tip + Vector2(0, -38)
	var color := Color(1.0, 0.82, 0.25, 0.75)
	if player_pos.distance_to(target) > 180.0:
		draw_line(player_pos, target, Color(1.0, 0.82, 0.25, 0.18), 4)
	draw_line(arrow_tail, arrow_tip, color, 5)
	draw_line(arrow_tip, arrow_tip + Vector2(-10, -12), color, 5)
	draw_line(arrow_tip, arrow_tip + Vector2(10, -12), color, 5)
	draw_circle(target, 24.0 + 5.0 * pulse, Color(1.0, 0.82, 0.25, 0.2))
	draw_arc(target, 32.0 + 4.0 * pulse, 0.0, TAU, 32, Color(1.0, 0.82, 0.25, 0.7), 3)

func _draw_player() -> void:
	var foot_offset := sin(walk_phase) * 3.0
	var side := Vector2(-player_facing.y, player_facing.x)
	draw_circle(player_pos - side * 7 + Vector2(0, foot_offset), 5, Color("#303846"))
	draw_circle(player_pos + side * 7 - Vector2(0, foot_offset), 5, Color("#303846"))
	draw_circle(player_pos, player_radius + 4, Color("#1b222d"))
	draw_circle(player_pos, player_radius, Color("#f2f0da"))
	draw_circle(player_pos + player_facing * 6, 5, Color("#7fb8ff"))
	draw_line(player_pos, player_pos + player_facing * 22, Color("#e7c66b"), 2)

func _find_interaction() -> void:
	interact_target = {}
	for module: Dictionary in modules:
		var facility := _facility_at_player(module)
		if not facility.is_empty():
			interact_target = facility
			return
		var rect := _module_rect(module).grow(24)
		if rect.has_point(player_pos):
			interact_target = module
			return
	for item: Dictionary in collectables:
		if item["depleted"]:
			continue
		var pos: Vector2 = item["pos"]
		if player_pos.distance_to(pos) <= 34.0:
			interact_target = item
			return

func _facility_at_player(module: Dictionary) -> Dictionary:
	if not _module_has_interior(module["type"]):
		return {}
	if not _module_rect(module).has_point(player_pos):
		return {}
	var local := player_pos - _module_rect(module).position
	var module_type: String = module["type"]
	var zones: Array[Dictionary] = []
	if module_type == "hab":
		zones = [
			{"facility": "bed", "rect": Rect2(Vector2(18, 18), Vector2(62, 76))},
			{"facility": "storage", "rect": Rect2(Vector2(92, 16), Vector2(42, 68))},
			{"facility": "console", "rect": Rect2(Vector2(84, 48), Vector2(54, 44))},
		]
	elif module_type == "life_support":
		zones = [
			{"facility": "console", "rect": Rect2(Vector2(18, 48), Vector2(70, 42))},
		]
	elif module_type == "workshop":
		zones = [
			{"facility": "storage", "rect": Rect2(Vector2(18, 52), Vector2(50, 42))},
			{"facility": "robot_charger", "rect": Rect2(Vector2(54, 14), Vector2(48, 64))},
		]
	for zone: Dictionary in zones:
		var rect: Rect2 = zone["rect"]
		if rect.grow(14).has_point(local):
			return {
				"kind": "facility",
				"facility": zone["facility"],
				"module_uid": module["uid"],
				"module_type": module_type,
			}
	return {}

func _process_suit_oxygen(delta: float) -> void:
	var inside := _is_player_inside_pressurized_module()
	if inside:
		if not was_inside:
			resources["suit_o2"] = min(100.0, resources["suit_o2"] + 25.0)
			resources["pressure"] = min(100.0, resources["pressure"] + 0.5)
			add_log("返舱完成：舱压稳定，宇航服开始复压检查。")
		resources["suit_o2"] = min(100.0, resources["suit_o2"] + delta * 10.0)
	else:
		var storm_multiplier := 1.8 if solar_storm_days > 0 else 1.0
		var meteor_multiplier := 1.6 if micrometeor_alert_days > 0 else 1.0
		resources["suit_o2"] = max(0.0, resources["suit_o2"] - delta * 1.8 * storm_multiplier)
		resources["suit_dust"] = min(100.0, resources["suit_dust"] + delta * (0.18 + solar_dust * 0.25) * storm_multiplier)
		resources["suit_integrity"] = max(0.0, resources["suit_integrity"] - delta * 0.035 * meteor_multiplier)
		if resources["suit_o2"] <= 0.0:
			resources["oxygen"] = max(0.0, resources["oxygen"] - delta * 2.5)
		if resources["suit_integrity"] <= 0.0:
			resources["oxygen"] = max(0.0, resources["oxygen"] - delta * 1.8)
		if resources["suit_o2"] <= 25.0 and low_o2_warning_cooldown <= 0.0:
			add_log("低氧倒计时：宇航服氧气 %.0f%%，请立即返舱或进气闸补氧。" % resources["suit_o2"])
			low_o2_warning_cooldown = 8.0
	was_inside = inside

func _is_player_inside_pressurized_module() -> bool:
	for module: Dictionary in modules:
		if not _is_pressurized_module(module["type"]):
			continue
		if module.get("leaking", false):
			continue
		if _module_rect(module).has_point(player_pos):
			return true
	return false

func _interact() -> void:
	if build_mode and selected_build != "":
		_try_build_selected()
		return
	if interact_target.is_empty():
		add_log("附近没有可操作目标。")
		return
	if interact_target.has("kind") and interact_target["kind"] == "collectable":
		_collect_surface_item(interact_target)
		_update_ui()
		return
	if interact_target.has("kind") and interact_target["kind"] == "facility":
		_use_facility(interact_target)
		_update_ui()
		return
	if interact_target.get("leaking", false):
		_repair_module_leak(interact_target)
		_update_ui()
		return
	match String(interact_target["type"]):
		"greenhouse":
			_use_greenhouse(interact_target)
		"solar":
			if selected_tool == "repair" and resources["integrity"] < 70.0:
				_repair_external_equipment(interact_target)
			else:
				_clean_solar()
		"life_support":
			_repair_life_support()
		"supply":
			_collect_supply()
		"workshop":
			_use_workshop()
		"airlock":
			_cycle_airlock()
		"regolith_plant":
			if selected_tool == "repair" and resources["integrity"] < 70.0:
				_repair_external_equipment(interact_target)
			else:
				_use_regolith_plant()
		"ice_processor":
			if selected_tool == "repair" and resources["integrity"] < 70.0:
				_repair_external_equipment(interact_target)
			else:
				_use_ice_processor()
		_:
			var def: Dictionary = module_defs[interact_target["type"]]
			add_log("%s 运转正常。" % def["name"])
	_update_ui()

func _use_facility(facility: Dictionary) -> void:
	match String(facility["facility"]):
		"bed":
			_use_bed()
		"console":
			_use_console()
		"storage":
			_use_storage()
		"robot_charger":
			_use_robot_charger()
		_:
			add_log("该舱内设施还没有接入操作。")

func _use_bed() -> void:
	var old_fatigue := float(operator.get("fatigue", 0.0))
	operator["fatigue"] = max(0.0, old_fatigue - 35.0)
	operator["health"] = min(100.0, float(operator.get("health", 100.0)) + 4.0)
	operator["morale"] = min(100.0, float(operator.get("morale", 100.0)) + 3.0)
	resources["food"] = max(0.0, resources["food"] - 1.0)
	resources["water"] = max(0.0, resources["water"] - 1.0)
	tutorial_flags["rested"] = true
	_play_ui_tone(520.0, 0.12, 0.07)
	add_log("在床铺休整一轮：疲劳 %.0f -> %.0f，消耗食物 1、水 1。" % [old_fatigue, operator["fatigue"]])

func _use_console() -> void:
	var counts: Dictionary = _module_counts()
	var pod_count := _active_collectable_count("supply_pod")
	var leak_count := _leaking_module_count()
	tutorial_flags["console"] = true
	_clear_guidance_tip()
	_play_ui_tone(840.0, 0.08, 0.07)
	add_log("控制台：电力 %.0f，氧 %.0f，水 %.0f，舱压 %.0f%%，模块 %d，漏气 %d，补给信标 %d。" % [
		resources["power"], resources["oxygen"], resources["water"], resources["pressure"], modules.size(), leak_count, pod_count
	])
	add_log("控制台：机器人队列=%s，背包 %.0f/%.0f。" % [_robot_queue_text(), _backpack_load(), backpack_capacity])
	_show_info_panel("ConsolePanel", _console_panel_text())

func _use_storage() -> void:
	if _backpack_load() <= 0.0:
		add_log("储物柜：出舱背包为空。可出舱采集后回到这里入库。")
		_set_guidance_tip("背包为空：先出舱采集月壤、水冰或样本，再回储物柜入库。")
		_play_ui_tone(420.0, 0.06, 0.05)
		_show_info_panel("BackpackPanel", _backpack_panel_text())
		return
	for key: String in backpack.keys():
		resources[key] += float(backpack[key])
		backpack[key] = 0.0
	tutorial_flags["stored"] = true
	_clear_guidance_tip()
	_play_ui_tone(680.0, 0.1, 0.07)
	add_log("储物柜：出舱背包已入库。基地库存已更新。")
	_show_info_panel("BackpackPanel", _backpack_panel_text())

func _use_robot_charger() -> void:
	if not _can_run_robot():
		add_log("机器人充电桩待机：需要先解锁玉兔机器人或机器人协作协议。")
		_play_ui_tone(260.0, 0.08, 0.06)
		return
	var order := ["sample", "maintenance", "haul"]
	var next_index := robot_queue.size() % order.size()
	var queued_task: String = order[next_index]
	if robot_queue.size() >= 4:
		add_log("机器人任务队列已满。等待当前队列执行后再派发新任务。")
		return
	robot_queue.append(queued_task)
	if not robot_active:
		robot_task = String(robot_queue[0])
	_play_audio_event("robot")
	add_log("机器人充电桩：任务已入队 -> %s。队列：%s。" % [_robot_task_name(queued_task), _robot_queue_text()])
	_show_info_panel("RobotPanel", _robot_panel_text())

func _use_greenhouse(module: Dictionary) -> void:
	if module["crop"] == "":
		var crop_def: Dictionary = crop_defs[selected_crop]
		if resources["water"] < crop_def["water"]:
			add_log("水不足，无法种植 %s。" % crop_def["name"])
			return
		resources["water"] -= crop_def["water"]
		module["crop"] = selected_crop
		module["age"] = 0
		tutorial_flags["planted"] = true
		_clear_guidance_tip()
		add_log("在温室种下 %s。%s。" % [crop_def["name"], crop_def["note"]])
	else:
		var crop_def: Dictionary = crop_defs[module["crop"]]
		add_log("%s 生长进度 %d/%d 天。" % [crop_def["name"], module["age"], crop_def["days"]])

func _clean_solar() -> void:
	if selected_tool != "brush":
		add_log("需要先选择除尘刷。")
		return
	if resources["parts"] < 1:
		add_log("缺少维修件，无法进行除尘维护。")
		return
	resources["parts"] -= 1
	solar_dust = max(0.0, solar_dust - 0.28)
	resources["suit_dust"] = min(100.0, resources["suit_dust"] + 3.0)
	_play_audio_event("tool")
	add_log("清理太阳能阵列。月尘覆盖降至 %d%%。" % int(solar_dust * 100))

func _repair_life_support() -> void:
	if selected_tool != "repair":
		add_log("需要先选择维修枪。")
		return
	if resources["parts"] < 1:
		add_log("维修件不足，生命维持系统只能继续带病运行。")
		return
	resources["parts"] -= 1
	resources["integrity"] = min(100.0, resources["integrity"] + 12.0)
	oxygen_wear = max(0.0, oxygen_wear - 0.12)
	_play_audio_event("tool")
	add_log("完成一次生命维持系统维护。")

func _repair_module_leak(module: Dictionary) -> void:
	if selected_tool != "repair":
		add_log("该舱段正在漏气，需要先选择维修枪。")
		return
	if resources["parts"] < 2:
		add_log("封堵漏气需要 2 个维修件。")
		return
	resources["parts"] -= 2
	module["leaking"] = false
	resources["integrity"] = min(100.0, resources["integrity"] + 6.0)
	var def: Dictionary = module_defs[module["type"]]
	_play_audio_event("tool")
	add_log("已封堵 %s 漏点，舱压恢复稳定。" % def["name"])

func _repair_external_equipment(module: Dictionary) -> void:
	if selected_tool != "repair":
		add_log("外部设备维护需要先选择维修枪。")
		return
	if resources["parts"] < 1:
		add_log("缺少维修件，无法维护外部设备。")
		return
	resources["parts"] -= 1
	resources["integrity"] = min(100.0, resources["integrity"] + 8.0)
	resources["suit_dust"] = min(100.0, resources["suit_dust"] + 4.0)
	var def: Dictionary = module_defs[module["type"]]
	_play_audio_event("tool")
	add_log("完成 %s 外部维护：完整度 +8，宇航服月尘污染上升。" % def["name"])

func _use_workshop() -> void:
	if resources["power"] < 4:
		add_log("电力不足，维修工作台无法打印零件。")
		return
	resources["power"] -= 4
	resources["parts"] = min(99.0, resources["parts"] + 1)
	add_log("维修工作台打印了 1 个维修件。")

func _cycle_airlock() -> void:
	var dust_cost: float = ceil(resources["suit_dust"] / 35.0)
	var power_cost: float = 2.0 + dust_cost
	var oxygen_cost: float = 1.0 + floor(dust_cost / 2.0)
	if resources["power"] < power_cost or resources["oxygen"] < oxygen_cost:
		add_log("气闸循环需要电力 %.0f、氧气 %.0f。月尘污染越高，维护成本越高。" % [power_cost, oxygen_cost])
		return
	resources["power"] -= power_cost
	resources["oxygen"] -= oxygen_cost
	resources["suit_o2"] = 100.0
	resources["suit_dust"] = max(0.0, resources["suit_dust"] - 55.0)
	resources["suit_integrity"] = min(100.0, resources["suit_integrity"] + 8.0)
	resources["pressure"] = min(100.0, resources["pressure"] + 3.0)
	tutorial_flags["airlock"] = true
	_clear_guidance_tip()
	_play_audio_event("airlock")
	add_log("气闸循环完成：消耗电力 %.0f、氧气 %.0f，宇航服补氧、复压、除尘。" % [power_cost, oxygen_cost])

func _use_regolith_plant() -> void:
	if resources["regolith"] < 2 or resources["power"] < 6:
		add_log("月壤提氧需要月壤 2、电力 6。")
		return
	resources["regolith"] -= 2
	resources["power"] -= 6
	resources["oxygen"] += 12
	resources["co2"] = max(0.0, resources["co2"] - 2.0)
	add_log("月壤提氧完成：氧气 +12。")

func _use_ice_processor() -> void:
	if resources["ice"] < 1 or resources["power"] < 4:
		add_log("冰矿处理需要水冰 1、电力 4。")
		return
	resources["ice"] -= 1
	resources["power"] -= 4
	resources["water"] += 8
	resources["humidity"] = min(100.0, resources["humidity"] + 4.0)
	add_log("冰矿处理完成：水 +8，温室湿度上升。")

func _collect_supply() -> void:
	if supply_waiting:
		var pos := _dict_to_vector2(supply_order.get("landing_pos", _vector2_to_dict(_cell_to_world(Vector2i(17, 7)))))
		add_log("补给舱等待回收。信标坐标：%.0f, %.0f；请检查航天服氧气后出舱取货。" % [pos.x, pos.y])
		_show_info_panel("SupplyCargoPanel", _supply_panel_text())
		return
	if not supply_order.is_empty():
		add_log("补给 %s 在途，预计第 %d 天抵达。" % [supply_order["name"], supply_order["arrival_day"]])
		_show_info_panel("SupplyCargoPanel", _supply_panel_text())
		return
	if day < next_supply_request_day:
		add_log("补给申请窗口未开放。下一次窗口：第 %d 天。" % next_supply_request_day)
		return
	$UI/Root/SupplyPanel.visible = true
	_show_info_panel("SupplyCargoPanel", _supply_panel_text())
	add_log("地球通信窗口开放：请选择下一批补给货单。")

func _toggle_build_mode() -> void:
	build_mode = not build_mode
	if build_mode and selected_build == "":
		selected_build = "solar"
	add_log("建造模式：%s。" % ("开启" if build_mode else "关闭"))
	_update_ui()

func _select_build(module_type: String) -> void:
	selected_build = module_type
	build_mode = true
	var def: Dictionary = module_defs[module_type]
	add_log("已选择建造：%s。靠近空地按 E 放置。" % def["name"])
	_update_ui()

func _select_tool(tool_name: String) -> void:
	selected_tool = tool_name
	build_mode = false
	selected_build = ""
	add_log("已切换工具：%s。" % tool_defs[tool_name]["name"])
	_update_ui()

func _research_tech(tech_id: String) -> void:
	if _has_tech(tech_id):
		add_log("%s 已经解锁。" % tech_defs[tech_id]["name"])
		return
	var tech: Dictionary = tech_defs[tech_id]
	var cost: Dictionary = tech["cost"]
	for key: String in cost.keys():
		if resources.get(key, 0.0) < float(cost[key]):
			add_log("研究 %s 资源不足：需要 %s %.0f。" % [tech["name"], resource_names.get(key, key), float(cost[key])])
			return
	for key: String in cost.keys():
		resources[key] -= float(cost[key])
	unlocked_techs.append(tech_id)
	add_log("科技解锁：%s。%s" % [tech["name"], tech["desc"]])
	_update_ui()

func _has_tech(tech_id: String) -> bool:
	return unlocked_techs.has(tech_id)

func _can_run_robot() -> bool:
	if is_instance_valid(robot_task_manager) and robot_task_manager.has_method("can_run_robot"):
		return bool(robot_task_manager.call("can_run_robot", unlocked_techs))
	return _has_tech("robot_assist") or _has_tech("yutu_robot")

func _process_tech_daily_effects() -> void:
	if _has_tech("yutu_robot"):
		solar_dust = max(0.0, solar_dust - 0.04)
		resources["regolith"] += 0.35
		if day % 3 == 0:
			resources["samples"] += 0.5
			add_log("玉兔机器人完成巡视：科研样本 +0.5。")
	if robot_queue.is_empty() and not robot_active:
		robot_task = "idle"

func _robot_haul_supply() -> bool:
	if supply_order.is_empty() or not supply_order.has("cargo_remaining"):
		return false
	var cargo: Dictionary = supply_order["cargo_remaining"]
	if cargo.is_empty():
		return false
	var capacity := 6.0
	var moved := 0.0
	for key: String in cargo.keys():
		if moved >= capacity:
			break
		var amount := float(cargo[key])
		if key == "dust":
			solar_dust = max(0.0, solar_dust + amount)
			cargo[key] = 0.0
			continue
		if amount <= 0.0:
			continue
		var take: float = min(amount, capacity - moved)
		resources[key] += take
		cargo[key] = amount - take
		moved += take
	_clean_empty_cargo(cargo)
	if cargo.is_empty():
		_mark_supply_pod_depleted()
	return moved > 0.0

func _mark_supply_pod_depleted() -> void:
	for item: Dictionary in collectables:
		if item["type"] == "supply_pod" and not item["depleted"]:
			item["depleted"] = true
			break
	supply_order.clear()
	supply_waiting = false
	_complete_mission("supply_recovery")
	_sync_scene_instances()

func _robot_task_name(task: String) -> String:
	if is_instance_valid(robot_task_manager) and robot_task_manager.has_method("task_name"):
		return String(robot_task_manager.call("task_name", task))
	match task:
		"sample":
			return "玉兔采样"
		"maintenance":
			return "维护巡检"
		"haul":
			return "搬运补给"
		"charging":
			return "返回充电"
		_:
			return "待机"

func _robot_type_name(task: String) -> String:
	if is_instance_valid(robot_task_manager) and robot_task_manager.has_method("task_robot_type"):
		return String(robot_task_manager.call("task_robot_type", task))
	match task:
		"sample":
			return "玉兔采样车"
		"maintenance":
			return "维护机器人"
		"haul":
			return "搬运机器人"
		"charging":
			return "充电桩"
		_:
			return "机器人"

func _robot_queue_text() -> String:
	if robot_queue.is_empty():
		return "空"
	var parts: Array[String] = []
	for task: String in robot_queue:
		parts.append(_robot_task_name(task))
	return _join_strings(parts, " > ")

func _robot_status_text() -> String:
	if robot_charging:
		return "充电中" if robot_pos.distance_to(_robot_home_pos()) <= 5.0 else "返回充电桩"
	if robot_active:
		return "执行中"
	if not robot_queue.is_empty():
		return "待执行"
	return "待机"

func _robot_target_text() -> String:
	if robot_charging:
		return "充电桩 %.0f, %.0f" % [_robot_home_pos().x, _robot_home_pos().y]
	if robot_active:
		return "%.0f, %.0f" % [robot_target.x, robot_target.y]
	if not robot_queue.is_empty():
		return "等待启动：%s" % _robot_task_name(String(robot_queue[0]))
	return "无"

func _robot_panel_text() -> String:
	var note := robot_failure_note if not robot_failure_note.is_empty() else "无"
	return "状态：%s\n类型：%s\n当前：%s\n电量：%.0f%%\n目标：%s\n队列：%s\n最近问题：%s\n\n取消：停止当前任务并清空移动目标。\n优先：把指定任务提到队首；若队列里没有，会新增一个。" % [
		_robot_status_text(),
		_robot_type_name(robot_task),
		_robot_task_name(robot_task),
		robot_battery,
		_robot_target_text(),
		_robot_queue_text(),
		note,
	]

func _cancel_robot_task() -> void:
	if robot_active and not robot_charging and robot_task != "idle":
		add_log("机器人任务已取消：%s。" % _robot_task_name(robot_task))
	elif robot_charging:
		add_log("机器人正在充电，已取消排队任务。")
	robot_queue.clear()
	robot_active = false
	robot_charging = false
	robot_task = "idle"
	robot_target = robot_pos
	_play_audio_event("robot")
	_show_info_panel("RobotPanel", _robot_panel_text())
	_update_ui()

func _prioritize_robot_task(task: String) -> void:
	var removed := false
	for i in range(robot_queue.size() - 1, -1, -1):
		if robot_queue[i] == task:
			robot_queue.remove_at(i)
			removed = true
	robot_queue.insert(0, task)
	if robot_queue.size() > 4:
		robot_queue.pop_back()
	add_log("机器人优先级调整：%s 已置顶%s。" % [_robot_task_name(task), "" if removed else "（新增任务）"])
	if not robot_active and not robot_charging:
		robot_task = task
	_play_audio_event("robot")
	_show_info_panel("RobotPanel", _robot_panel_text())
	_update_ui()

func _facility_name(facility: String) -> String:
	match facility:
		"bed":
			return "床铺"
		"console":
			return "控制台"
		"storage":
			return "储物柜"
		"robot_charger":
			return "机器人充电桩"
		_:
			return "舱内设施"

func _facility_hint(facility: String) -> String:
	match facility:
		"bed":
			return "按 E 休整，恢复疲劳、健康和精神，消耗少量食物与水。"
		"console":
			return "按 E 查看基地状态、任务和机器人任务。"
		"storage":
			return "按 E 将出舱背包资源入库。"
		"robot_charger":
			return "按 E 切换机器人任务：待机/采样/巡检/搬运。"
		_:
			return "按 E 操作。"

func _try_build_selected() -> void:
	var cell: Vector2i = _player_build_cell()
	if _candidate_overlaps_player(selected_build, cell):
		add_log("建造位置太近：请退后一步，把模块放在前方空地。")
		_set_guidance_tip("建造失败：你站得太近。退后一步，让预览格不要压住角色。")
		return
	if not _can_place(selected_build, cell):
		add_log("这里空间不足或超出基地网格，无法建造。")
		_set_guidance_tip("建造失败：预览区域需要完全空出来，不能压住已有模块或地图边界。")
		return
	if not _is_connected_placement(selected_build, cell):
		add_log("新模块必须贴近已有基地舱段或能源节点。")
		_set_guidance_tip("建造失败：新模块必须贴着已有基地模块放置。")
		return
	var def: Dictionary = module_defs[selected_build]
	var cost: Dictionary = def["cost"]
	if resources["parts"] < cost["parts"] or resources["power"] < cost["power"]:
		add_log("资源不足：需要维修件 %.0f、电力 %.0f。" % [cost["parts"], cost["power"]])
		_set_guidance_tip("建造失败：资源不足。先采集、搬运补给，或等待维修工作台产出维修件。")
		return
	resources["parts"] -= cost["parts"]
	resources["power"] -= cost["power"]
	_add_module(selected_build, cell, false)
	_clear_guidance_tip()
	add_log("建成 %s。基地自给能力提升。" % def["name"])
	_update_ui()

func _add_module(module_type: String, cell: Vector2i, fixed: bool) -> void:
	var module := {
		"uid": next_module_uid,
		"type": module_type,
		"cell": cell,
		"fixed": fixed,
		"crop": "",
		"age": 0,
		"leaking": false,
	}
	next_module_uid += 1
	modules.append(module)
	_paint_interior_tiles()
	_sync_scene_instances()

func _setup_collectables() -> void:
	collectables.clear()
	_add_collectable("regolith", Vector2(155, 525), 4.0)
	_add_collectable("regolith", Vector2(730, 520), 4.0)
	_add_collectable("ice", Vector2(1010, 170), 3.0)
	_add_collectable("meteor", Vector2(860, 130), 2.0)
	_add_collectable("sample", Vector2(515, 140), 1.0)

func _add_collectable(item_type: String, pos: Vector2, amount: float) -> void:
	collectables.append({
		"uid": next_collectable_uid,
		"kind": "collectable",
		"type": item_type,
		"pos": pos,
		"amount": amount,
		"depleted": false,
	})
	next_collectable_uid += 1
	_sync_scene_instances()

func _collect_surface_item(item: Dictionary) -> void:
	if item["type"] == "supply_pod":
		if not supply_waiting:
			add_log("补给舱信标异常：当前没有待回收补给。")
			return
		_recover_supply_cargo(item)
		_sync_scene_instances()
		return
	if selected_tool != "sampler":
		add_log("需要先选择采样铲。")
		_set_guidance_tip("采集失败：先点击底部工具栏的采样铲，再靠近资源点按 E。")
		return
	var amount: float = item["amount"]
	if _has_tech("change_samples"):
		amount += 1.0
	match String(item["type"]):
		"regolith":
			if not _add_to_backpack("regolith", amount):
				return
			add_log("采集月壤 +%.0f，已装入出舱背包。" % amount)
		"ice":
			if not _add_to_backpack("ice", amount):
				return
			resources["suit_dust"] = min(100.0, resources["suit_dust"] + 2.0)
			add_log("采集水冰样本 +%.0f，已装入出舱背包。" % amount)
		"meteor":
			if not _add_to_backpack("parts", amount):
				return
			if not _add_to_backpack("samples", 1.0):
				return
			add_log("回收陨石金属：维修件 +%.0f，科研样本 +1，已装入背包。" % amount)
		"sample":
			if not _add_to_backpack("samples", amount):
				return
			add_log("采集特殊月壤样本 +%.0f，已装入出舱背包。" % amount)
	item["depleted"] = true
	_play_audio_event("tool")
	_sync_scene_instances()

func _recover_supply_cargo(item: Dictionary) -> void:
	if supply_order.is_empty():
		supply_waiting = false
		item["depleted"] = true
		return
	if not supply_order.has("cargo_remaining"):
		var kind: String = supply_order["kind"]
		var def: Dictionary = supply_defs[kind]
		supply_order["cargo_remaining"] = _copy_dictionary(def["payload"])
	var remaining: Dictionary = supply_order["cargo_remaining"]
	if remaining.is_empty():
		_finish_supply_recovery(item)
		return
	var free_space := backpack_capacity - _backpack_load()
	if free_space <= 0.0:
		add_log("背包已满，无法继续搬运补给。先回储物柜入库。")
		_set_guidance_tip("背包已满：跟随箭头回舱内储物柜，按 E 入库后再搬。")
		_play_ui_tone(220.0, 0.08, 0.06)
		_show_info_panel("SupplyCargoPanel", _supply_panel_text())
		return
	var moved := 0.0
	var moved_parts: Array[String] = []
	for key: String in remaining.keys():
		if moved >= free_space:
			break
		var amount := float(remaining[key])
		if key == "dust":
			solar_dust = max(0.0, solar_dust + amount)
			remaining[key] = 0.0
			moved_parts.append("除尘耗材")
			continue
		if amount <= 0.0:
			continue
		var take: float = min(amount, free_space - moved)
		if take <= 0.0:
			continue
		if _add_to_backpack(key, take):
			remaining[key] = amount - take
			moved += take
			moved_parts.append("%s %.0f" % [resource_names.get(key, key), take])
	_clean_empty_cargo(remaining)
	resources["suit_dust"] = min(100.0, resources["suit_dust"] + 4.0)
	_play_audio_event("cargo")
	if moved_parts.is_empty():
		add_log("补给舱没有可搬运货物。")
	else:
		add_log("搬运补给：%s。背包 %.0f/%.0f。" % [_join_strings(moved_parts, " / "), _backpack_load(), backpack_capacity])
	_show_info_panel("SupplyCargoPanel", _supply_panel_text())
	if remaining.is_empty():
		_finish_supply_recovery(item)

func _finish_supply_recovery(item: Dictionary) -> void:
	var kind: String = supply_order.get("kind", "")
	var def: Dictionary = supply_defs.get(kind, {})
	add_log("补给舱回收完成：%s。" % def.get("desc", "货物已全部搬空"))
	supply_order.clear()
	supply_waiting = false
	item["depleted"] = true
	_complete_mission("supply_recovery")
	_update_ui()

func _clean_empty_cargo(cargo: Dictionary) -> void:
	var keys_to_remove: Array[String] = []
	for key: String in cargo.keys():
		if float(cargo[key]) <= 0.01:
			keys_to_remove.append(key)
	for key: String in keys_to_remove:
		cargo.erase(key)

func _add_to_backpack(key: String, amount: float) -> bool:
	if _backpack_load() + amount > backpack_capacity:
		add_log("出舱背包容量不足：%.0f/%.0f。请回储物柜入库。" % [_backpack_load(), backpack_capacity])
		_set_guidance_tip("背包容量不足：先回储物柜入库，再继续采集或搬运。")
		_play_ui_tone(220.0, 0.08, 0.06)
		return false
	backpack[key] = float(backpack.get(key, 0.0)) + amount
	tutorial_flags["collected"] = true
	_clear_guidance_tip()
	return true

func _backpack_load() -> float:
	var total := 0.0
	for key: String in backpack.keys():
		total += float(backpack[key])
	return total

func _backpack_summary() -> String:
	var parts: Array[String] = []
	for key: String in backpack.keys():
		if float(backpack[key]) > 0.0:
			parts.append("%s %.0f" % [resource_names.get(key, key), float(backpack[key])])
	if parts.is_empty():
		return "空"
	return _join_strings(parts, " / ")

func _advance_day() -> void:
	day += 1
	if is_instance_valid(time_manager) and time_manager.has_method("advance_day"):
		time_manager.call("advance_day", 7, 42)
		day = int(time_manager.get("day"))
	tutorial_flags["advanced_day"] = true
	_clear_guidance_tip()
	if solar_storm_days > 0:
		solar_storm_days -= 1
		solar_dust = min(0.8, solar_dust + 0.08)
		add_log("太阳风暴影响中：舱外行动风险提高，太阳能板月尘污染上升。")
	if micrometeor_alert_days > 0:
		micrometeor_alert_days -= 1
		add_log("微陨石预警仍在：舱外设备和宇航服耐久风险提高。")
	is_moon_night = day >= 14 and day < 22
	var counts: Dictionary = _module_counts()
	var power_cap: float = 120.0 + float(counts["battery"]) * 35.0
	var solar_gain: float = float(counts["solar"]) * 22.0 * (1.0 - solar_dust)
	if is_moon_night:
		solar_gain = 0.0
	var base_power_use: float = 16.0 + float(counts["greenhouse"]) * 2.0 + float(counts["life_support"]) * 2.5
	if is_moon_night:
		base_power_use += 14.0 + float(counts["greenhouse"]) * 3.0
	var operator_food: float = 3.0
	var operator_water: float = max(1.4, 2.4 - float(counts["life_support"]) * 0.35)
	var operator_oxygen: float = max(1.6, 3.0 - float(counts["life_support"]) * 0.35)
	var operator_co2: float = 3.2
	resources["power"] += solar_gain - base_power_use
	resources["oxygen"] -= operator_oxygen + oxygen_wear * 8.0
	resources["co2"] += operator_co2
	resources["water"] -= operator_water
	resources["food"] -= operator_food
	resources["integrity"] -= 1.0 + solar_dust * 1.8 + float(modules.size()) * 0.04
	resources["pressure"] += float(counts["life_support"]) * 1.5 - 0.8
	resources["humidity"] += float(counts["greenhouse"]) * 2.2 - float(counts["life_support"]) * 1.4
	var leaking_count := _leaking_module_count()
	if leaking_count > 0:
		resources["oxygen"] -= float(leaking_count) * 8.0
		resources["integrity"] -= float(leaking_count) * 2.0
		resources["pressure"] -= float(leaking_count) * 9.0
		add_log("警报：%d 个舱段漏气，氧气正在流失。" % leaking_count)
	if counts["workshop"] > 0:
		resources["parts"] = min(99.0, resources["parts"] + 0.25 * float(counts["workshop"]))
	if counts["regolith_plant"] > 0 and resources["regolith"] >= 1 and resources["power"] >= 3:
		resources["regolith"] -= 1
		resources["power"] -= 3
		resources["oxygen"] += 5.0 * float(counts["regolith_plant"])
	if counts["ice_processor"] > 0 and resources["ice"] >= 0.5 and resources["power"] >= 2:
		resources["ice"] -= 0.5
		resources["power"] -= 2
		resources["water"] += 3.0 * float(counts["ice_processor"])
		resources["humidity"] += 1.5
	_process_operator_day(counts)
	_process_tech_daily_effects()
	solar_dust = min(0.65, solar_dust + randf_range(0.02, 0.06))
	oxygen_wear = min(0.45, oxygen_wear + randf_range(0.01, 0.04))
	_process_crop_day()
	_process_supply_window()
	_process_random_event()
	for key: String in ["power", "oxygen", "water", "food", "integrity", "co2", "humidity", "pressure", "suit_o2", "suit_integrity", "suit_dust"]:
		resources[key] = clamp(resources[key], 0.0, power_cap if key == "power" else 120.0)
	add_log("第 %d 天开始。%s" % [day, "月夜中，太阳能归零。" if is_moon_night else "月昼，太阳能可用。"])
	_record_task_history("strategy:day:%d" % day, "长期目标：%s" % _strategic_next_goal())
	_check_missions()
	_check_game_state()
	_update_ui()
	queue_redraw()

func _process_operator_day(counts: Dictionary) -> void:
	var pressure_penalty: float = 0.0 if resources["pressure"] >= 70.0 else 3.0
	var co2_penalty: float = 0.0 if resources["co2"] <= 85.0 else 2.5
	var supply_penalty: float = 0.0
	if resources["food"] < 18.0 or resources["water"] < 18.0 or resources["oxygen"] < 18.0:
		supply_penalty = 2.0
	var ecology_bonus: float = 1.0 if _has_tech("closed_ecology") else 0.0
	var robot_bonus: float = 1.2 if _has_tech("robot_assist") else 0.0
	var health_delta: float = -0.7 - pressure_penalty - co2_penalty - supply_penalty + ecology_bonus
	var morale_delta: float = -0.5 - supply_penalty + robot_bonus
	var fatigue_delta: float = 1.4 + supply_penalty - robot_bonus
	if counts["greenhouse"] > 0:
		resources["humidity"] = clamp(resources["humidity"] + 0.3, 0.0, 100.0)
	if _has_tech("yutu_robot"):
		resources["integrity"] = min(100.0, resources["integrity"] + 0.4)
	operator["health"] = clamp(float(operator.get("health", 100.0)) + health_delta, 0.0, 100.0)
	operator["morale"] = clamp(float(operator.get("morale", 100.0)) + morale_delta, 0.0, 100.0)
	operator["fatigue"] = clamp(float(operator.get("fatigue", 0.0)) + fatigue_delta, 0.0, 100.0)
	if float(operator["fatigue"]) > 70.0:
		operator["health"] = max(0.0, float(operator["health"]) - 1.0)
		operator["morale"] = max(0.0, float(operator["morale"]) - 1.0)
	if float(operator["health"]) < 45.0:
		resources["integrity"] -= 1.5
	if float(operator["morale"]) < 40.0:
		resources["power"] -= 2.0

func _process_crop_day() -> void:
	for module: Dictionary in modules:
		if module["type"] != "greenhouse" or module["crop"] == "":
			continue
		var humidity_ok: bool = resources["humidity"] >= 35.0 and resources["humidity"] <= 85.0
		var co2_available: bool = resources["co2"] >= 3.0
		if not humidity_ok:
			add_log("温室湿度异常，%s 生长放缓。" % crop_defs[module["crop"]]["name"])
		if not co2_available:
			add_log("二氧化碳不足，%s 光合作用受限。" % crop_defs[module["crop"]]["name"])
		if humidity_ok and co2_available:
			module["age"] += 1
			resources["co2"] = max(0.0, resources["co2"] - 3.0)
			resources["humidity"] = max(0.0, resources["humidity"] - 1.0)
		var crop_def: Dictionary = crop_defs[module["crop"]]
		resources["oxygen"] += crop_def["oxygen"] if not is_moon_night else crop_def["oxygen"] * 0.35
		if module["age"] >= crop_def["days"]:
			var food_gain: float = crop_def["food"]
			if _has_tech("change_samples"):
				food_gain *= 1.15
			resources["food"] += food_gain
			add_log("%s 成熟收获：食物 +%d。" % [crop_def["name"], int(food_gain)])
			module["crop"] = ""
			module["age"] = 0

func _check_missions() -> void:
	var counts := _module_counts()
	if day >= 7:
		_complete_mission("survive_7")
	if int(counts["greenhouse"]) >= 1:
		_complete_mission("first_greenhouse")
	if resources["oxygen"] >= 100.0:
		_complete_mission("local_oxygen")
	if float(operator.get("health", 0.0)) >= 60.0 and float(operator.get("morale", 0.0)) >= 60.0:
		_complete_mission("operator_stable")

func _complete_mission(mission_id: String) -> void:
	if completed_missions.has(mission_id):
		return
	if not mission_defs.has(mission_id):
		return
	completed_missions.append(mission_id)
	resources["samples"] += 0.5
	resources["parts"] += 1.0
	var mission: Dictionary = mission_defs[mission_id]
	add_log("任务完成：%s。奖励：样本 +0.5，维修件 +1。" % mission["name"])
	_record_task_history("mission:%s" % mission_id, "阶段目标完成：%s" % String(mission["name"]))

func _process_supply_window() -> void:
	if not supply_order.is_empty() and day >= int(supply_order["arrival_day"]) and not bool(supply_order.get("landed", false)):
		supply_waiting = true
		supply_order["landed"] = true
		var landing_pos := _random_supply_landing_pos()
		supply_order["landing_pos"] = _vector2_to_dict(landing_pos)
		var kind: String = supply_order["kind"]
		var def: Dictionary = supply_defs[kind]
		supply_order["cargo_remaining"] = _copy_dictionary(def["payload"])
		_add_collectable("supply_pod", landing_pos, 1.0)
		add_log("%s 已着陆，但落点出现偏差。信标坐标：%.0f, %.0f；需要出舱取货。" % [supply_order["name"], landing_pos.x, landing_pos.y])
		_sync_scene_instances()
	if day >= next_supply_request_day and supply_order.is_empty() and not supply_waiting:
		add_log("地球通信窗口开放：可在补给降落区申请下一批补给。")

func _process_random_event() -> void:
	if day == 5:
		add_log("月尘静电附着增强，太阳能效率开始下降。")
	if day == 11:
		add_log("地面控制提醒：月夜将在第 14 天开始，请提前储电。")
	if randf() < 0.08 and solar_storm_days <= 0:
		solar_storm_days = 1
		add_log("太阳风暴预警：未来 1 天尽量减少出舱，气闸除尘成本会上升。")
	if randf() < 0.08 and micrometeor_alert_days <= 0:
		micrometeor_alert_days = 1
		add_log("微陨石短时警报：建议暂停外部维修和远距离采集。")
	var impact_chance := 0.18 if micrometeor_alert_days > 0 else 0.12
	if randf() < impact_chance:
		var hit_module := _pick_pressurized_module()
		if not hit_module.is_empty() and not hit_module.get("leaking", false):
			hit_module["leaking"] = true
			resources["integrity"] -= 4.0
			var def: Dictionary = module_defs[hit_module["type"]]
			add_log("微陨石击中 %s，舱段开始漏气。" % def["name"])
		else:
			resources["integrity"] -= 5.0
			add_log("微小冲击触发舱体巡检，设备完整度下降。")

func _choose_supply(kind: String) -> void:
	if day < next_supply_request_day or not supply_order.is_empty() or supply_waiting:
		return
	var def: Dictionary = supply_defs[kind]
	var delay: int = supply_travel_days
	if _has_tech("queqiao_relay"):
		delay = max(1, delay - 1)
	var delay_chance: float = 0.06 if _has_tech("queqiao_relay") else 0.15
	if randf() < delay_chance:
		delay += 1
		add_log("地面发射排程拥堵，本批补给延迟 1 天。")
	supply_order = {
		"kind": kind,
		"name": def["name"],
		"arrival_day": day + delay,
		"requested_day": day,
		"landed": false,
	}
	next_supply_request_day = day + 7
	tutorial_flags["supply"] = true
	_clear_guidance_tip()
	add_log("已申请 %s（%s），预计第 %d 天抵达。" % [def["name"], def["desc"], supply_order["arrival_day"]])
	$UI/Root/SupplyPanel.visible = false
	_update_ui()

func _receive_supply() -> void:
	if supply_order.is_empty():
		supply_waiting = false
		return
	var kind: String = supply_order["kind"]
	var def: Dictionary = supply_defs[kind]
	var payload: Dictionary = def["payload"]
	for key: String in payload.keys():
		if key == "dust":
			solar_dust = max(0.0, solar_dust + float(payload[key]))
		else:
			resources[key] += float(payload[key])
	resources["suit_dust"] = min(100.0, resources["suit_dust"] + 6.0)
	_play_ui_tone(720.0, 0.12, 0.08)
	add_log("接收 %s：%s。" % [def["name"], def["desc"]])
	supply_order.clear()
	supply_waiting = false
	_update_ui()

func _random_supply_landing_pos() -> Vector2:
	var base := _cell_to_world(Vector2i(17, 7)) + Vector2(96, 72)
	var deviation := 150.0
	if _has_tech("precision_landing"):
		deviation = 70.0
	if _has_tech("queqiao_relay"):
		deviation *= 0.8
	var offset := Vector2(randf_range(-deviation, deviation), randf_range(-deviation * 0.7, deviation * 0.7))
	var pos := base + offset
	pos.x = clamp(pos.x, MAP_ORIGIN.x + 30.0, MAP_ORIGIN.x + MAP_W * TILE - 30.0)
	pos.y = clamp(pos.y, MAP_ORIGIN.y + 30.0, MAP_ORIGIN.y + MAP_H * TILE - 30.0)
	return pos

func _save_game() -> void:
	if is_instance_valid(save_manager) and save_manager.has_method("ensure_save_dir"):
		save_manager.call("ensure_save_dir")
	else:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var file := FileAccess.open(_save_path(current_save_slot), FileAccess.WRITE)
	if file == null:
		add_log("保存失败：无法写入存档文件。")
		_update_ui()
		return
	var save_data := {
		"version": 1,
		"game_state": game_state_manager.call("serialize") if is_instance_valid(game_state_manager) and game_state_manager.has_method("serialize") else {},
		"time": time_manager.call("serialize") if is_instance_valid(time_manager) and time_manager.has_method("serialize") else {},
		"camera_manager": camera_manager.call("serialize") if is_instance_valid(camera_manager) and camera_manager.has_method("serialize") else {},
		"events": event_manager.call("serialize") if is_instance_valid(event_manager) and event_manager.has_method("serialize") else {},
		"day": day,
		"is_moon_night": is_moon_night,
		"game_over": game_over,
		"supply_waiting": supply_waiting,
		"supply_order": supply_order,
		"next_supply_request_day": next_supply_request_day,
		"supply_travel_days": supply_travel_days,
		"player_pos": _vector2_to_dict(player_pos),
		"player_facing": _vector2_to_dict(player_facing),
		"selected_crop": selected_crop,
		"selected_tool": selected_tool,
		"build_mode": build_mode,
		"selected_build": selected_build,
		"unlocked_techs": unlocked_techs,
		"completed_missions": completed_missions,
		"tutorial_flags": tutorial_flags,
		"task_log_expanded": task_log_expanded,
		"task_history": task_history,
		"intro_overlay_seen": intro_overlay_seen,
		"objective_tracking": objective_tracking,
		"tracked_objective_index": tracked_objective_index,
		"operator": _serialize_operator(),
		"backpack": backpack,
		"robot_task": robot_task,
		"robot_queue": robot_queue,
		"robot_pos": _vector2_to_dict(robot_pos),
		"robot_target": _vector2_to_dict(robot_target),
		"robot_active": robot_active,
		"robot_battery": robot_battery,
		"robot_charging": robot_charging,
		"robot_failure_note": robot_failure_note,
		"solar_storm_days": solar_storm_days,
		"micrometeor_alert_days": micrometeor_alert_days,
		"camera_zoom": camera_zoom,
		"ui_scale": ui_scale,
		"solar_dust": solar_dust,
		"oxygen_wear": oxygen_wear,
		"next_module_uid": next_module_uid,
		"next_collectable_uid": next_collectable_uid,
		"resources": resources,
		"modules": _serialize_modules(),
		"collectables": _serialize_collectables(),
		"log_lines": log_lines,
	}
	file.store_string(JSON.stringify(save_data, "\t"))
	_play_ui_tone(900.0, 0.06, 0.07)
	add_log("已保存到存档槽 %d。" % current_save_slot)
	_refresh_main_menu()
	_update_ui()

func _load_game() -> void:
	if not FileAccess.file_exists(_save_path(current_save_slot)):
		add_log("存档槽 %d 为空。" % current_save_slot)
		_update_ui()
		return
	var file := FileAccess.open(_save_path(current_save_slot), FileAccess.READ)
	if file == null:
		add_log("读取失败：无法打开存档文件。")
		_update_ui()
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		add_log("读取失败：存档格式无效。")
		_update_ui()
		return
	_apply_save_data(parsed)
	pending_main_menu = false
	if has_node("UI/Root/MainMenu"):
		$UI/Root/MainMenu.visible = false
	if has_node("UI/Root/DevMenu"):
		$UI/Root/DevMenu.visible = false
	dev_menu_visible = false
	_set_gameplay_hud_visible(true)
	if is_instance_valid(game_state_manager) and game_state_manager.has_method("change_state"):
		game_state_manager.call("change_state", GameStateManagerScript.MOON_SURFACE)
	_play_ui_tone(760.0, 0.08, 0.07)
	add_log("已读取存档槽 %d。" % current_save_slot)
	_sync_scene_instances()
	_update_ui()
	queue_redraw()

func _start_new_game() -> void:
	_reset_game_state()
	pending_main_menu = false
	if has_node("UI/Root/MainMenu"):
		$UI/Root/MainMenu.visible = false
	if has_node("UI/Root/DevMenu"):
		$UI/Root/DevMenu.visible = false
	dev_menu_visible = false
	_set_gameplay_hud_visible(true)
	if is_instance_valid(game_state_manager) and game_state_manager.has_method("change_state"):
		game_state_manager.call("change_state", GameStateManagerScript.MOON_SURFACE)
	if is_instance_valid(time_manager) and time_manager.has_method("set_time"):
		time_manager.call("set_time", day, 7, 42)
	add_log("新一轮广寒前哨任务开始。")
	add_log("先按左上角当前目标行动：控制台 -> 气闸 -> 出舱采集 -> 储物柜入库。")
	_record_task_history("strategy:day:1", "长期目标：%s" % _strategic_next_goal())
	_update_camera()
	_update_ui()
	queue_redraw()

func _apply_save_data(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	if is_instance_valid(game_state_manager) and game_state_manager.has_method("deserialize"):
		game_state_manager.call("deserialize", data.get("game_state", {"current_state": GameStateManagerScript.MOON_SURFACE}))
	if is_instance_valid(time_manager) and time_manager.has_method("deserialize"):
		time_manager.call("deserialize", data.get("time", {"day": day, "hour": 7, "minute": 42}))
		day = int(time_manager.get("day"))
	if is_instance_valid(camera_manager) and camera_manager.has_method("deserialize"):
		camera_manager.call("deserialize", data.get("camera_manager", {}))
	if is_instance_valid(event_manager) and event_manager.has_method("deserialize"):
		event_manager.call("deserialize", data.get("events", {}))
	is_moon_night = bool(data.get("is_moon_night", false))
	game_over = bool(data.get("game_over", false))
	supply_waiting = bool(data.get("supply_waiting", false))
	supply_order = _copy_dictionary(data.get("supply_order", {}))
	next_supply_request_day = int(data.get("next_supply_request_day", 1))
	supply_travel_days = int(data.get("supply_travel_days", 3))
	player_pos = _dict_to_vector2(data.get("player_pos", _vector2_to_dict(Vector2(300, 420))))
	player_facing = _dict_to_vector2(data.get("player_facing", _vector2_to_dict(Vector2.DOWN)))
	selected_crop = String(data.get("selected_crop", "potato"))
	selected_tool = String(data.get("selected_tool", "sampler"))
	build_mode = bool(data.get("build_mode", false))
	selected_build = String(data.get("selected_build", ""))
	unlocked_techs.clear()
	var saved_techs: Array = data.get("unlocked_techs", [])
	for tech_id in saved_techs:
		unlocked_techs.append(String(tech_id))
	completed_missions.clear()
	var saved_missions: Array = data.get("completed_missions", [])
	for mission_id in saved_missions:
		completed_missions.append(String(mission_id))
	tutorial_flags = _copy_bool_dictionary(data.get("tutorial_flags", _default_tutorial_flags()), _default_tutorial_flags())
	task_log_expanded = bool(data.get("task_log_expanded", false))
	task_history.clear()
	var saved_history: Array = data.get("task_history", [])
	for entry in saved_history:
		task_history.append(String(entry))
	intro_overlay_seen = bool(data.get("intro_overlay_seen", true))
	objective_tracking = bool(data.get("objective_tracking", false))
	tracked_objective_index = int(data.get("tracked_objective_index", 0))
	operator = _deserialize_operator(data.get("operator", data.get("crew", _serialize_operator())))
	backpack = _copy_float_dictionary(data.get("backpack", _default_backpack()), _default_backpack())
	robot_task = String(data.get("robot_task", "idle"))
	robot_queue.clear()
	var saved_queue: Array = data.get("robot_queue", [])
	for task in saved_queue:
		robot_queue.append(String(task))
	if not robot_queue.is_empty():
		robot_task = String(robot_queue[0])
	robot_pos = _dict_to_vector2(data.get("robot_pos", _vector2_to_dict(_cell_to_world(Vector2i(10, 6)))))
	robot_target = _dict_to_vector2(data.get("robot_target", _vector2_to_dict(robot_pos)))
	robot_active = bool(data.get("robot_active", false))
	robot_battery = float(data.get("robot_battery", 100.0))
	robot_charging = bool(data.get("robot_charging", false))
	robot_failure_note = String(data.get("robot_failure_note", ""))
	solar_storm_days = int(data.get("solar_storm_days", 0))
	micrometeor_alert_days = int(data.get("micrometeor_alert_days", 0))
	camera_zoom = float(data.get("camera_zoom", 1.0))
	ui_scale = float(data.get("ui_scale", 1.0))
	_apply_camera_zoom()
	_apply_ui_scale()
	solar_dust = float(data.get("solar_dust", 0.12))
	oxygen_wear = float(data.get("oxygen_wear", 0.08))
	next_module_uid = int(data.get("next_module_uid", 1))
	next_collectable_uid = int(data.get("next_collectable_uid", 1))
	resources = _default_resources()
	var saved_resources: Dictionary = data.get("resources", {})
	for key: String in saved_resources.keys():
		resources[key] = float(saved_resources[key])
	modules = _deserialize_modules(data.get("modules", []))
	collectables = _deserialize_collectables(data.get("collectables", []))
	_paint_interior_tiles()
	log_lines.clear()
	var saved_logs: Array = data.get("log_lines", [])
	for entry in saved_logs:
		log_lines.append(String(entry))
	if has_node("UI/Root/SupplyPanel"):
		$UI/Root/SupplyPanel.visible = false
	_sync_scene_instances()

func _serialize_modules() -> Array:
	var result: Array = []
	for module: Dictionary in modules:
		result.append({
			"uid": int(module["uid"]),
			"type": String(module["type"]),
			"cell": _vector2i_to_dict(module["cell"]),
			"fixed": bool(module["fixed"]),
			"crop": String(module.get("crop", "")),
			"age": int(module.get("age", 0)),
			"leaking": bool(module.get("leaking", false)),
		})
	return result

func _deserialize_modules(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = value
		result.append({
			"uid": int(data.get("uid", 0)),
			"type": String(data.get("type", "hab")),
			"cell": _dict_to_vector2i(data.get("cell", {"x": 0, "y": 0})),
			"fixed": bool(data.get("fixed", false)),
			"crop": String(data.get("crop", "")),
			"age": int(data.get("age", 0)),
			"leaking": bool(data.get("leaking", false)),
		})
	return result

func _serialize_collectables() -> Array:
	var result: Array = []
	for item: Dictionary in collectables:
		result.append({
			"uid": int(item["uid"]),
			"kind": String(item["kind"]),
			"type": String(item["type"]),
			"pos": _vector2_to_dict(item["pos"]),
			"amount": float(item["amount"]),
			"depleted": bool(item["depleted"]),
		})
	return result

func _deserialize_collectables(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = value
		result.append({
			"uid": int(data.get("uid", 0)),
			"kind": String(data.get("kind", "collectable")),
			"type": String(data.get("type", "regolith")),
			"pos": _dict_to_vector2(data.get("pos", {"x": 0.0, "y": 0.0})),
			"amount": float(data.get("amount", 0.0)),
			"depleted": bool(data.get("depleted", false)),
		})
	return result

func _serialize_operator() -> Dictionary:
	return {
		"name": String(operator.get("name", "林舟")),
		"health": float(operator.get("health", 100.0)),
		"morale": float(operator.get("morale", 100.0)),
		"fatigue": float(operator.get("fatigue", 0.0)),
	}

func _deserialize_operator(value) -> Dictionary:
	if typeof(value) == TYPE_ARRAY:
		var legacy_values: Array = value
		if not legacy_values.is_empty() and typeof(legacy_values[0]) == TYPE_DICTIONARY:
			var legacy: Dictionary = legacy_values[0]
			return {
				"name": String(legacy.get("name", "林舟")),
				"health": float(legacy.get("health", 100.0)),
				"morale": float(legacy.get("morale", 100.0)),
				"fatigue": 12.0,
			}
	if typeof(value) != TYPE_DICTIONARY:
		return _default_operator()
	var data: Dictionary = value
	return {
		"name": String(data.get("name", "林舟")),
		"health": float(data.get("health", 100.0)),
		"morale": float(data.get("morale", 100.0)),
		"fatigue": float(data.get("fatigue", 0.0)),
	}

func _save_path(slot: int) -> String:
	if is_instance_valid(save_manager) and save_manager.has_method("save_path"):
		return String(save_manager.call("save_path", slot))
	return "%s/slot_%d.json" % [SAVE_DIR, clamp(slot, 1, SAVE_SLOTS)]

func _select_save_slot(slot: int) -> void:
	current_save_slot = clamp(slot, 1, SAVE_SLOTS)
	add_log("当前存档槽：%d。" % current_save_slot)
	_refresh_main_menu()
	_update_ui()

func _slot_summary(slot: int) -> String:
	if is_instance_valid(save_manager) and save_manager.has_method("slot_summary"):
		return String(save_manager.call("slot_summary", slot))
	var path := _save_path(slot)
	if not FileAccess.file_exists(path):
		return "空槽"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "无法读取"
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "损坏"
	var data: Dictionary = parsed
	var saved_resources: Dictionary = data.get("resources", {})
	return "第 %d 天 | 氧 %.0f | 食 %.0f" % [
		int(data.get("day", 1)),
		float(saved_resources.get("oxygen", 0.0)),
		float(saved_resources.get("food", 0.0)),
	]

func _vector2_to_dict(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}

func _dict_to_vector2(value) -> Vector2:
	if typeof(value) != TYPE_DICTIONARY:
		return Vector2.ZERO
	return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))

func _vector2i_to_dict(value: Vector2i) -> Dictionary:
	return {"x": value.x, "y": value.y}

func _dict_to_vector2i(value) -> Vector2i:
	if typeof(value) != TYPE_DICTIONARY:
		return Vector2i.ZERO
	return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))

func _copy_dictionary(value) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var result := {}
	for key in value.keys():
		result[key] = value[key]
	return result

func _copy_float_dictionary(value, defaults: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	if typeof(value) != TYPE_DICTIONARY:
		return result
	var data: Dictionary = value
	for key: String in data.keys():
		result[key] = float(data[key])
	return result

func _copy_bool_dictionary(value, defaults: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	if typeof(value) != TYPE_DICTIONARY:
		return result
	var data: Dictionary = value
	for key: String in data.keys():
		result[key] = bool(data[key])
	return result

func _check_game_state() -> void:
	var failed: Array[String] = []
	for key: String in ["power", "oxygen", "water", "food", "pressure"]:
		if resources[key] <= 0.0:
			failed.append(resource_names[key])
	if resources["co2"] >= 115.0:
		failed.append("二氧化碳过量")
	if failed.size() > 0:
		game_over = true
		add_log("基地失守：%s 归零。请调整补给和维护优先级后重试。" % _join_strings(failed, ", "))
	if day > 30 and not game_over:
		add_log("30 天生存目标完成。下一步可以扩展机器人劳动力、舱外任务和本地工业链。")

func _next_supply_day() -> int:
	if supply_waiting:
		return day
	if not supply_order.is_empty():
		return int(supply_order["arrival_day"])
	return next_supply_request_day

func _module_counts() -> Dictionary:
	var counts := {
		"hab": 0,
		"greenhouse": 0,
		"solar": 0,
		"battery": 0,
		"life_support": 0,
		"workshop": 0,
		"airlock": 0,
		"regolith_plant": 0,
		"ice_processor": 0,
		"supply": 0,
	}
	for module: Dictionary in modules:
		counts[module["type"]] += 1
	return counts

func _leaking_module_count() -> int:
	var count := 0
	for module: Dictionary in modules:
		if module.get("leaking", false):
			count += 1
	return count

func _pick_pressurized_module() -> Dictionary:
	var candidates: Array[Dictionary] = []
	for module: Dictionary in modules:
		if _is_pressurized_module(module["type"]):
			candidates.append(module)
	if candidates.is_empty():
		return {}
	return candidates[randi() % candidates.size()]

func _is_pressurized_module(module_type: String) -> bool:
	return module_type in ["hab", "greenhouse", "battery", "life_support", "workshop", "airlock"]

func _module_has_interior(module_type: String) -> bool:
	return module_type in ["hab", "greenhouse", "battery", "life_support", "workshop", "airlock"]

func _can_player_move_to(pos: Vector2) -> bool:
	var min_pos := MAP_ORIGIN + Vector2(5, 5)
	var max_pos := MAP_ORIGIN + Vector2(MAP_W * TILE - 5, MAP_H * TILE - 5)
	if pos.x < min_pos.x or pos.y < min_pos.y or pos.x > max_pos.x or pos.y > max_pos.y:
		return false
	var currently_inside := _is_player_inside_pressurized_module()
	var target_inside := _is_pressurized_point(pos)
	if currently_inside and not target_inside and not _eva_precheck_ok():
		return false
	var samples := [
		pos,
		pos + Vector2(player_radius * 0.7, 0),
		pos + Vector2(-player_radius * 0.7, 0),
		pos + Vector2(0, player_radius * 0.7),
		pos + Vector2(0, -player_radius * 0.7),
	]
	for sample: Vector2 in samples:
		if not _is_walkable_point(sample):
			return false
	return true

func _is_pressurized_point(pos: Vector2) -> bool:
	for module: Dictionary in modules:
		if not _is_pressurized_module(module["type"]):
			continue
		if module.get("leaking", false):
			continue
		if _module_rect(module).has_point(pos):
			return true
	return false

func _eva_precheck_ok() -> bool:
	if resources["suit_o2"] >= 35.0 and resources["suit_integrity"] >= 25.0:
		return true
	if eva_warning_cooldown <= 0.0:
		add_log("出舱检查未通过：宇航服氧气至少 35%，耐久至少 25%。请先到气闸复压、补氧、除尘。")
		_set_guidance_tip("不能出舱：先跟随箭头去气闸，按 E 补氧、复压、除尘。")
		eva_warning_cooldown = 3.0
	return false

func _is_walkable_point(pos: Vector2) -> bool:
	for module: Dictionary in modules:
		var rect := _module_rect(module)
		if not rect.has_point(pos):
			continue
		if not _module_has_interior(module["type"]):
			return false
		if _module_inner_rect(module).has_point(pos):
			return not _is_furniture_blocked_point(pos, module)
		return _is_module_door_gap(pos, module)
	return true

func _module_inner_rect(module: Dictionary) -> Rect2:
	return _module_rect(module).grow(-12.0)

func _is_furniture_blocked_point(pos: Vector2, module: Dictionary) -> bool:
	var module_type := String(module["type"])
	var local: Vector2 = pos - _module_rect(module).position
	for rect: Rect2 in _facility_solid_rects(module_type):
		if rect.has_point(local):
			return true
	return false

func _facility_solid_rects(module_type: String) -> Array[Rect2]:
	match module_type:
		"hab":
			return [
				Rect2(Vector2(30, 28), Vector2(22, 12)),
				Rect2(Vector2(30, 62), Vector2(22, 12)),
				Rect2(Vector2(118, 34), Vector2(10, 30)),
				Rect2(Vector2(108, 78), Vector2(16, 10)),
			]
		"life_support":
			return [
				Rect2(Vector2(58, 38), Vector2(52, 20)),
				Rect2(Vector2(34, 78), Vector2(20, 10)),
			]
		"workshop":
			return [
				Rect2(Vector2(34, 36), Vector2(34, 12)),
				Rect2(Vector2(120, 32), Vector2(16, 28)),
				Rect2(Vector2(30, 84), Vector2(18, 8)),
			]
		"airlock":
			return [
				Rect2(Vector2(40, 34), Vector2(8, 32)),
				Rect2(Vector2(100, 34), Vector2(10, 28)),
			]
	return []

func _is_module_door_gap(pos: Vector2, module: Dictionary) -> bool:
	var rect := _module_rect(module)
	var door_half := 20.0
	var edge := 14.0
	var center := rect.get_center()
	var doors: Array[String] = _module_door_sides(module)
	var on_left: bool = doors.has("left") and abs(pos.x - rect.position.x) <= edge and abs(pos.y - center.y) <= door_half
	var on_right: bool = doors.has("right") and abs(pos.x - rect.end.x) <= edge and abs(pos.y - center.y) <= door_half
	var on_top: bool = doors.has("top") and abs(pos.y - rect.position.y) <= edge and abs(pos.x - center.x) <= door_half
	var on_bottom: bool = doors.has("bottom") and abs(pos.y - rect.end.y) <= edge and abs(pos.x - center.x) <= door_half
	return on_left or on_right or on_top or on_bottom

func _module_door_sides(module: Dictionary) -> Array[String]:
	if not _module_has_interior(module["type"]):
		return []
	if module["type"] == "airlock":
		return ["left", "right", "top", "bottom"]
	var sides: Array[String] = []
	var def: Dictionary = module_defs[module["type"]]
	var cell: Vector2i = module["cell"]
	var size: Vector2i = def["size"]
	var current := Rect2i(cell, size)
	for other: Dictionary in modules:
		if int(other["uid"]) == int(module["uid"]):
			continue
		if not _module_has_interior(other["type"]):
			continue
		var other_def: Dictionary = module_defs[other["type"]]
		var other_rect := Rect2i(other["cell"], other_def["size"])
		if current.position.x == other_rect.position.x + other_rect.size.x and _vertical_overlap(current, other_rect):
			sides.append("left")
		if current.position.x + current.size.x == other_rect.position.x and _vertical_overlap(current, other_rect):
			sides.append("right")
		if current.position.y == other_rect.position.y + other_rect.size.y and _horizontal_overlap(current, other_rect):
			sides.append("top")
		if current.position.y + current.size.y == other_rect.position.y and _horizontal_overlap(current, other_rect):
			sides.append("bottom")
	return sides

func _vertical_overlap(a: Rect2i, b: Rect2i) -> bool:
	return a.position.y < b.position.y + b.size.y and b.position.y < a.position.y + a.size.y

func _horizontal_overlap(a: Rect2i, b: Rect2i) -> bool:
	return a.position.x < b.position.x + b.size.x and b.position.x < a.position.x + a.size.x

func _player_build_cell() -> Vector2i:
	var facing: Vector2 = player_facing.normalized() if player_facing.length() > 0.01 else Vector2.DOWN
	var placement_pos: Vector2 = player_pos + facing * TILE
	var local := placement_pos - MAP_ORIGIN
	var x := int(floor(local.x / TILE))
	var y := int(floor(local.y / TILE))
	return Vector2i(clamp(x, 0, MAP_W - 1), clamp(y, 0, MAP_H - 1))

func _cell_to_world(cell: Vector2i) -> Vector2:
	return MAP_ORIGIN + Vector2(cell.x * TILE, cell.y * TILE)

func _module_rect(module: Dictionary) -> Rect2:
	var def: Dictionary = module_defs[module["type"]]
	var cell: Vector2i = module["cell"]
	var size: Vector2i = def["size"]
	return Rect2(_cell_to_world(cell), Vector2(size.x * TILE - 2, size.y * TILE - 2))

func _can_place(module_type: String, cell: Vector2i) -> bool:
	var def: Dictionary = module_defs[module_type]
	var size: Vector2i = def["size"]
	if cell.x < 0 or cell.y < 0 or cell.x + size.x > MAP_W or cell.y + size.y > MAP_H:
		return false
	if _candidate_overlaps_player(module_type, cell):
		return false
	var candidate: Rect2i = Rect2i(cell, size)
	for module: Dictionary in modules:
		var other_def: Dictionary = module_defs[module["type"]]
		var other_cell: Vector2i = module["cell"]
		var other_size: Vector2i = other_def["size"]
		var other: Rect2i = Rect2i(other_cell, other_size)
		if candidate.intersects(other):
			return false
	return true

func _candidate_overlaps_player(module_type: String, cell: Vector2i) -> bool:
	var def: Dictionary = module_defs[module_type]
	var size: Vector2i = def["size"]
	var rect: Rect2 = Rect2(_cell_to_world(cell), Vector2(size.x * TILE - 2, size.y * TILE - 2))
	return rect.grow(player_radius + 6.0).has_point(player_pos)

func _is_connected_placement(module_type: String, cell: Vector2i) -> bool:
	var def: Dictionary = module_defs[module_type]
	var size: Vector2i = def["size"]
	var candidate: Rect2i = Rect2i(cell, size)
	for module: Dictionary in modules:
		var other_def: Dictionary = module_defs[module["type"]]
		var other_cell: Vector2i = module["cell"]
		var other_size: Vector2i = other_def["size"]
		var other: Rect2i = Rect2i(other_cell, other_size)
		if _rects_touch(candidate, other):
			return true
	return false

func _rects_touch(a: Rect2i, b: Rect2i) -> bool:
	var horizontal_touch := (a.position.x + a.size.x == b.position.x or b.position.x + b.size.x == a.position.x)
	var vertical_overlap := a.position.y < b.position.y + b.size.y and b.position.y < a.position.y + a.size.y
	var vertical_touch := (a.position.y + a.size.y == b.position.y or b.position.y + b.size.y == a.position.y)
	var horizontal_overlap := a.position.x < b.position.x + b.size.x and b.position.x < a.position.x + a.size.x
	return (horizontal_touch and vertical_overlap) or (vertical_touch and horizontal_overlap)

func _setup_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	if is_instance_valid(ui_manager) and ui_manager.has_method("bind_root"):
		ui_manager.call("bind_root", root)
	_apply_ui_scale()

	var top := Label.new()
	top.name = "Top"
	top.position = Vector2(18, 12)
	top.size = Vector2(1240, 60)
	top.add_theme_font_size_override("font_size", 20)
	root.add_child(top)

	var hint := Label.new()
	hint.name = "Hint"
	hint.position = Vector2(18, 760)
	hint.size = Vector2(1220, 42)
	hint.add_theme_font_size_override("font_size", 18)
	root.add_child(hint)

	var log := RichTextLabel.new()
	log.name = "Log"
	log.position = Vector2(1300, 20)
	log.size = Vector2(280, 310)
	log.fit_content = false
	log.scroll_following = true
	root.add_child(log)

	var controls := Label.new()
	controls.name = "Controls"
	controls.position = Vector2(1300, 340)
	controls.size = Vector2(280, 104)
	controls.text = "WASD/方向键：移动\nE：交互/采集/建造\nN：下一天  B：建造\nZ/X：地图缩放\n[/]：UI 缩放\nT：追踪  Y：切换目标\nF5/F9/F10：保存/读取/新局"
	root.add_child(controls)

	var guide := RichTextLabel.new()
	guide.name = "Guide"
	guide.position = Vector2(18, 76)
	guide.size = Vector2(360, 182)
	guide.fit_content = false
	guide.scroll_active = false
	guide.add_theme_font_size_override("normal_font_size", 16)
	root.add_child(guide)

	var objective_stack := RichTextLabel.new()
	objective_stack.name = "ObjectiveStack"
	objective_stack.position = Vector2(388, 520)
	objective_stack.size = Vector2(500, 132)
	objective_stack.fit_content = false
	objective_stack.scroll_active = false
	objective_stack.bbcode_enabled = true
	objective_stack.add_theme_font_size_override("normal_font_size", 15)
	root.add_child(objective_stack)

	var tracking_button := Button.new()
	tracking_button.name = "TrackingButton"
	tracking_button.position = Vector2(760, 658)
	tracking_button.size = Vector2(128, 34)
	tracking_button.pressed.connect(_toggle_objective_tracking)
	root.add_child(tracking_button)

	var next_target_button := Button.new()
	next_target_button.name = "NextTargetButton"
	next_target_button.position = Vector2(760, 696)
	next_target_button.size = Vector2(128, 34)
	next_target_button.pressed.connect(_cycle_objective_target)
	root.add_child(next_target_button)

	var task_log := RichTextLabel.new()
	task_log.name = "TaskLog"
	task_log.position = Vector2(18, 268)
	task_log.size = Vector2(360, 250)
	task_log.fit_content = false
	task_log.scroll_active = false
	task_log.bbcode_enabled = true
	task_log.add_theme_font_size_override("normal_font_size", 14)
	root.add_child(task_log)

	var task_toggle := Button.new()
	task_toggle.name = "TaskLogToggle"
	task_toggle.position = Vector2(288, 236)
	task_toggle.size = Vector2(90, 30)
	task_toggle.pressed.connect(_toggle_task_log)
	root.add_child(task_toggle)

	var edge_hint := Label.new()
	edge_hint.name = "EdgeHint"
	edge_hint.visible = false
	edge_hint.size = Vector2(150, 32)
	edge_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	edge_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	edge_hint.add_theme_font_size_override("font_size", 16)
	edge_hint.add_theme_color_override("font_color", Color("#15191f"))
	edge_hint.add_theme_color_override("font_shadow_color", Color(1.0, 0.82, 0.25, 0.7))
	edge_hint.add_theme_constant_override("shadow_offset_x", 0)
	edge_hint.add_theme_constant_override("shadow_offset_y", 0)
	root.add_child(edge_hint)

	var completion_toast := Label.new()
	completion_toast.name = "CompletionToast"
	completion_toast.visible = false
	completion_toast.position = Vector2(520, 120)
	completion_toast.size = Vector2(560, 46)
	completion_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	completion_toast.add_theme_font_size_override("font_size", 22)
	completion_toast.add_theme_color_override("font_color", Color("#15191f"))
	completion_toast.add_theme_color_override("font_shadow_color", Color(1.0, 0.82, 0.25, 0.75))
	completion_toast.add_theme_constant_override("shadow_offset_x", 0)
	completion_toast.add_theme_constant_override("shadow_offset_y", 0)
	root.add_child(completion_toast)

	var supply_status := Label.new()
	supply_status.name = "SupplyStatus"
	supply_status.position = Vector2(1300, 430)
	supply_status.size = Vector2(280, 70)
	supply_status.add_theme_font_size_override("font_size", 16)
	root.add_child(supply_status)

	var life_status := Label.new()
	life_status.name = "LifeStatus"
	life_status.position = Vector2(1300, 500)
	life_status.size = Vector2(280, 72)
	life_status.add_theme_font_size_override("font_size", 16)
	root.add_child(life_status)

	var operator_status := Label.new()
	operator_status.name = "OperatorStatus"
	operator_status.position = Vector2(1300, 580)
	operator_status.size = Vector2(280, 76)
	operator_status.add_theme_font_size_override("font_size", 15)
	root.add_child(operator_status)

	var mission_status := Label.new()
	mission_status.name = "MissionStatus"
	mission_status.position = Vector2(1300, 665)
	mission_status.size = Vector2(280, 64)
	mission_status.add_theme_font_size_override("font_size", 15)
	root.add_child(mission_status)

	var eva_tasks := RichTextLabel.new()
	eva_tasks.name = "EvaTasks"
	eva_tasks.position = Vector2(900, 660)
	eva_tasks.size = Vector2(360, 116)
	eva_tasks.fit_content = false
	eva_tasks.scroll_active = false
	eva_tasks.add_theme_font_size_override("normal_font_size", 14)
	root.add_child(eva_tasks)

	var tech_panel := HBoxContainer.new()
	tech_panel.name = "TechPanel"
	tech_panel.position = Vector2(18, 812)
	tech_panel.size = Vector2(1220, 34)
	root.add_child(tech_panel)
	for tech_id: String in _tech_order():
		var button := Button.new()
		button.text = _tech_button_text(tech_id)
		button.pressed.connect(_research_tech.bind(tech_id))
		tech_panel.add_child(button)

	var crop_panel := HBoxContainer.new()
	crop_panel.name = "CropPanel"
	crop_panel.position = Vector2(18, 852)
	crop_panel.size = Vector2(330, 38)
	root.add_child(crop_panel)
	for crop_name: String in crop_defs.keys():
		var button := Button.new()
		button.text = crop_defs[crop_name]["name"]
		button.pressed.connect(_select_crop.bind(crop_name))
		crop_panel.add_child(button)

	var tool_panel := HBoxContainer.new()
	tool_panel.name = "ToolPanel"
	tool_panel.position = Vector2(260, 852)
	tool_panel.size = Vector2(330, 38)
	root.add_child(tool_panel)
	for tool_name: String in ["sampler", "brush", "repair"]:
		var button := Button.new()
		button.text = tool_defs[tool_name]["name"]
		button.pressed.connect(_select_tool.bind(tool_name))
		tool_panel.add_child(button)

	var build_panel := HBoxContainer.new()
	build_panel.name = "BuildPanel"
	build_panel.position = Vector2(490, 852)
	build_panel.size = Vector2(650, 38)
	root.add_child(build_panel)
	for module_type: String in ["solar", "battery", "greenhouse", "life_support", "workshop", "airlock", "regolith_plant", "ice_processor"]:
		var button := Button.new()
		button.text = module_defs[module_type]["name"]
		button.pressed.connect(_select_build.bind(module_type))
		build_panel.add_child(button)

	var next_day := Button.new()
	next_day.name = "NextDay"
	next_day.text = "进入下一天"
	next_day.position = Vector2(1160, 850)
	next_day.size = Vector2(110, 40)
	next_day.pressed.connect(_advance_day)
	root.add_child(next_day)

	root.add_child(_make_info_panel("ConsolePanel", Vector2(388, 76), Vector2(360, 230), "BASE CONSOLE"))
	root.add_child(_make_info_panel("BackpackPanel", Vector2(388, 316), Vector2(360, 190), "BACKPACK / STORAGE"))
	root.add_child(_make_info_panel("SupplyCargoPanel", Vector2(760, 76), Vector2(360, 230), "SUPPLY CARGO"))
	root.add_child(_make_robot_panel())

	var supply_panel := PanelContainer.new()
	supply_panel.name = "SupplyPanel"
	supply_panel.position = Vector2(520, 180)
	supply_panel.size = Vector2(520, 230)
	supply_panel.visible = false
	root.add_child(supply_panel)
	var box := VBoxContainer.new()
	box.name = "Box"
	supply_panel.add_child(box)
	var title := Label.new()
	title.text = "地球补给申请：选择本次 300kg 货单"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	var b1 := Button.new()
	b1.text = "申请生存包：食物 + 水 + 氧气"
	b1.pressed.connect(func(): _choose_supply("survival"))
	box.add_child(b1)
	var b2 := Button.new()
	b2.text = "申请建设包：维修件 + 电池 + 除尘耗材"
	b2.pressed.connect(func(): _choose_supply("build"))
	box.add_child(b2)
	var b3 := Button.new()
	b3.text = "申请农业包：水培耗材 + 温室备件"
	b3.pressed.connect(func(): _choose_supply("farm"))
	box.add_child(b3)

	var save_panel := HBoxContainer.new()
	save_panel.name = "SavePanel"
	save_panel.position = Vector2(1300, 810)
	save_panel.size = Vector2(280, 38)
	root.add_child(save_panel)
	for slot in range(1, SAVE_SLOTS + 1):
		var slot_button := Button.new()
		slot_button.text = "槽 %d" % slot
		slot_button.pressed.connect(_select_save_slot.bind(slot))
		save_panel.add_child(slot_button)
	var save_button := Button.new()
	save_button.text = "保存"
	save_button.pressed.connect(_save_game)
	save_panel.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "读取"
	load_button.pressed.connect(_load_game)
	save_panel.add_child(load_button)
	var new_button := Button.new()
	new_button.text = "新开局"
	new_button.pressed.connect(_start_new_game)
	save_panel.add_child(new_button)

	var zoom_panel := HBoxContainer.new()
	zoom_panel.name = "ZoomPanel"
	zoom_panel.position = Vector2(1300, 760)
	zoom_panel.size = Vector2(280, 38)
	root.add_child(zoom_panel)
	var map_minus := Button.new()
	map_minus.text = "地图-"
	map_minus.pressed.connect(func(): _adjust_camera_zoom(-0.1))
	zoom_panel.add_child(map_minus)
	var zoom_label := Label.new()
	zoom_label.name = "ZoomLabel"
	zoom_label.custom_minimum_size = Vector2(86, 30)
	zoom_panel.add_child(zoom_label)
	var map_plus := Button.new()
	map_plus.text = "地图+"
	map_plus.pressed.connect(func(): _adjust_camera_zoom(0.1))
	zoom_panel.add_child(map_plus)
	var ui_minus := Button.new()
	ui_minus.text = "UI-"
	ui_minus.pressed.connect(func(): _adjust_ui_scale(-0.1))
	zoom_panel.add_child(ui_minus)
	var ui_plus := Button.new()
	ui_plus.text = "UI+"
	ui_plus.pressed.connect(func(): _adjust_ui_scale(0.1))
	zoom_panel.add_child(ui_plus)

	root.add_child(_make_intro_overlay())

func _make_info_panel(panel_name: String, panel_pos: Vector2, panel_size: Vector2, title_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.position = panel_pos
	panel.size = panel_size
	panel.visible = false
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)
	var text := RichTextLabel.new()
	text.name = "Text"
	text.custom_minimum_size = panel_size - Vector2(24, 54)
	text.fit_content = false
	text.scroll_active = true
	text.add_theme_font_size_override("normal_font_size", 15)
	box.add_child(text)
	return panel

func _make_robot_panel() -> PanelContainer:
	var panel := _make_info_panel("RobotPanel", Vector2(760, 316), Vector2(420, 250), "ROBOT TASKS")
	var box: VBoxContainer = panel.get_node("Box")
	var row := HBoxContainer.new()
	row.name = "Controls"
	row.add_theme_constant_override("separation", 5)
	box.add_child(row)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.pressed.connect(_cancel_robot_task)
	row.add_child(cancel)
	var haul := Button.new()
	haul.text = "搬运优先"
	haul.pressed.connect(_prioritize_robot_task.bind("haul"))
	row.add_child(haul)
	var maintenance := Button.new()
	maintenance.text = "巡检优先"
	maintenance.pressed.connect(_prioritize_robot_task.bind("maintenance"))
	row.add_child(maintenance)
	var sample := Button.new()
	sample.text = "采样优先"
	sample.pressed.connect(_prioritize_robot_task.bind("sample"))
	row.add_child(sample)
	return panel

func _make_intro_overlay() -> Control:
	var overlay := Control.new()
	overlay.name = "IntroOverlay"
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1600, 900)
	overlay.visible = false
	overlay.z_index = 100
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.02, 0.04, 0.06, 0.62)
	dim.position = Vector2.ZERO
	dim.size = Vector2(1600, 900)
	overlay.add_child(dim)
	var highlight := Panel.new()
	highlight.name = "Highlight"
	highlight.position = Vector2(10, 68)
	highlight.size = Vector2(376, 198)
	var highlight_style := StyleBoxFlat.new()
	highlight_style.bg_color = Color(1.0, 0.82, 0.25, 0.08)
	highlight_style.border_color = Color("#e7c66b")
	highlight_style.set_border_width_all(3)
	highlight.add_theme_stylebox_override("panel", highlight_style)
	overlay.add_child(highlight)
	var card := PanelContainer.new()
	card.name = "Card"
	card.position = Vector2(420, 96)
	card.size = Vector2(430, 210)
	overlay.add_child(card)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var title := Label.new()
	title.text = "第一次任务提示"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var text := Label.new()
	text.text = "先看左上角的今日任务卡。黄色高亮会指向当前目标；如果目标离开视野，屏幕边缘会显示方向提示。"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(390, 82)
	box.add_child(text)
	var start := Button.new()
	start.text = "Dev Only: Start Survival Sandbox"
	start.text = "知道了，开始执行"
	start.custom_minimum_size = Vector2(0, 40)
	start.pressed.connect(_dismiss_intro_overlay)
	box.add_child(start)
	return overlay

func _dismiss_intro_overlay() -> void:
	intro_overlay_seen = true
	if has_node("UI/Root/IntroOverlay"):
		$UI/Root/IntroOverlay.visible = false
	_play_ui_tone(740.0, 0.07, 0.07)
	_update_ui()

func _toggle_task_log() -> void:
	task_log_expanded = not task_log_expanded
	_play_ui_tone(620.0, 0.05, 0.06)
	_update_ui()

func _update_task_log_controls() -> void:
	if not has_node("UI/Root/TaskLog") or not has_node("UI/Root/TaskLogToggle"):
		return
	var log: RichTextLabel = $UI/Root/TaskLog
	var toggle: Button = $UI/Root/TaskLogToggle
	if task_log_expanded:
		log.size = Vector2(360, 360)
		toggle.text = "折叠"
	else:
		log.size = Vector2(360, 174)
		toggle.text = "展开"

func _update_intro_overlay() -> void:
	if not has_node("UI/Root/IntroOverlay"):
		return
	$UI/Root/IntroOverlay.visible = (not intro_overlay_seen) and (not pending_main_menu)

func _update_edge_hint() -> void:
	if not has_node("UI/Root/EdgeHint") or not is_instance_valid(camera):
		return
	var hint: Label = $UI/Root/EdgeHint
	var target: Vector2 = _tutorial_target_pos()
	if target.x == INF or pending_main_menu:
		hint.visible = false
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_pos: Vector2 = (target - camera.position) * camera_zoom + viewport_size * 0.5
	var margin := 58.0
	if screen_pos.x >= margin and screen_pos.x <= viewport_size.x - margin and screen_pos.y >= margin and screen_pos.y <= viewport_size.y - margin:
		hint.visible = false
		return
	var center: Vector2 = viewport_size * 0.5
	var direction: Vector2 = (screen_pos - center).normalized()
	if direction.length() <= 0.01:
		hint.visible = false
		return
	var clamped: Vector2 = Vector2(
		clamp(screen_pos.x, margin, viewport_size.x - margin),
		clamp(screen_pos.y, margin, viewport_size.y - margin)
	)
	var local_pos: Vector2 = clamped / max(ui_scale, 0.01)
	hint.position = local_pos - hint.size * 0.5
	hint.text = "%s  %.0fm" % [_direction_label(direction), player_pos.distance_to(target) / float(TILE)]
	hint.visible = true

func _direction_label(direction: Vector2) -> String:
	if abs(direction.x) > abs(direction.y):
		return "目标 >" if direction.x > 0.0 else "< 目标"
	return "目标 v" if direction.y > 0.0 else "^ 目标"

func _toggle_objective_tracking() -> void:
	objective_tracking = not objective_tracking
	tracked_objective_index = _normalized_objective_index(tracked_objective_index)
	_play_ui_tone(700.0 if objective_tracking else 420.0, 0.06, 0.06)
	_update_camera()
	_update_ui()

func _cycle_objective_target() -> void:
	var targets := _objective_targets()
	if targets.is_empty():
		add_log("当前没有可追踪目标。")
		_set_guidance_tip("暂无可追踪目标：先查看当前任务卡，或推进一天刷新任务。")
		_update_ui()
		return
	tracked_objective_index = (tracked_objective_index + 1) % targets.size()
	objective_tracking = true
	var target: Dictionary = targets[tracked_objective_index]
	add_log("追踪目标切换：%s。" % String(target.get("name", "目标")))
	_set_guidance_tip("正在追踪：%s。" % String(target.get("summary", target.get("name", "目标"))))
	_play_ui_tone(820.0, 0.06, 0.06)
	_update_camera()
	_update_ui()

func _normalized_objective_index(index: int) -> int:
	var targets := _objective_targets()
	if targets.is_empty():
		return 0
	if index < 0:
		return 0
	if index >= targets.size():
		return targets.size() - 1
	return index

func _show_task_feedback(text: String, pos: Vector2) -> void:
	feedback_text = text
	feedback_timer = 2.2
	map_marker_text = text
	map_marker_pos = pos
	map_marker_timer = 3.2
	_play_ui_tone(880.0, 0.08, 0.07)
	_update_completion_toast()

func _update_completion_toast() -> void:
	if not has_node("UI/Root/CompletionToast"):
		return
	var toast: Label = $UI/Root/CompletionToast
	toast.visible = feedback_timer > 0.0 and not feedback_text.is_empty()
	toast.text = "完成：%s" % feedback_text

func _draw_map_marker() -> void:
	if map_marker_timer <= 0.0 or map_marker_pos.x == INF:
		return
	var pulse: float = abs(sin(Time.get_ticks_msec() / 150.0))
	draw_circle(map_marker_pos, 18.0 + pulse * 8.0, Color(0.48, 1.0, 0.62, 0.22))
	draw_arc(map_marker_pos, 28.0 + pulse * 5.0, 0.0, TAU, 32, Color("#7dff9d"), 3)
	draw_line(map_marker_pos + Vector2(-14, -22), map_marker_pos + Vector2(14, -22), Color("#7dff9d"), 3)

func _active_objective_target_pos() -> Vector2:
	var targets := _objective_targets()
	if targets.is_empty():
		return Vector2(INF, INF)
	tracked_objective_index = _normalized_objective_index(tracked_objective_index)
	return targets[tracked_objective_index].get("pos", Vector2(INF, INF))

func _objective_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	var tutorial_target := _tutorial_target_pos()
	if tutorial_target.x != INF:
		targets.append({
			"id": "tutorial",
			"name": "新手目标",
			"summary": _current_objective_action(),
			"pos": tutorial_target,
			"kind": "tutorial",
			"tool": "按任务卡行动",
			"priority": 0,
		})
		return targets
	if _backpack_load() > 0.0:
		var storage_pos := _facility_target_pos("hab", "storage")
		targets.append({
			"id": "storage",
			"name": "回储物柜入库",
			"summary": "背包 %.0f/%.0f，先回舱内卸货" % [_backpack_load(), backpack_capacity],
			"pos": storage_pos,
			"kind": "storage",
			"tool": "储物柜 E",
			"priority": 1,
		})
	var supply_target := _nearest_collectable_from(player_pos, ["supply_pod"])
	if not supply_target.is_empty():
		targets.append({
			"id": "supply_pod",
			"name": "回收补给舱",
			"summary": _supply_cargo_summary(),
			"pos": supply_target["pos"],
			"kind": "supply",
			"tool": "靠近补给舱 E",
			"priority": 2,
		})
	var ice_target := _nearest_collectable_from(player_pos, ["ice"])
	if not ice_target.is_empty():
		targets.append({
			"id": "ice",
			"name": "采集水冰",
			"summary": "水冰节点 %d 处" % _active_collectable_count("ice"),
			"pos": ice_target["pos"],
			"kind": "ice",
			"tool": "采样铲",
			"priority": 4,
		})
	if solar_dust >= 0.22:
		var solar_pos := _module_target_pos("solar")
		if solar_pos.x != INF:
			targets.append({
				"id": "solar_clean",
				"name": "清理太阳能板",
				"summary": "月尘 %d%%" % int(solar_dust * 100),
				"pos": solar_pos,
				"kind": "solar",
				"tool": "除尘刷",
				"priority": 3,
			})
	var repair_pos := _external_repair_target_pos()
	if repair_pos.x != INF:
		targets.append({
			"id": "external_repair",
			"name": "维修外部设备",
			"summary": "%d 个维修目标" % _external_repair_count(),
			"pos": repair_pos,
			"kind": "repair",
			"tool": "维修枪",
			"priority": 5,
		})
	targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := int(a.get("priority", 99))
		var pb := int(b.get("priority", 99))
		if pa == pb:
			var da: float = player_pos.distance_to(a.get("pos", player_pos))
			var db: float = player_pos.distance_to(b.get("pos", player_pos))
			return da < db
		return pa < pb
	)
	return targets

func _first_leaking_module_pos() -> Vector2:
	for module: Dictionary in modules:
		if bool(module.get("leaking", false)):
			return _module_rect(module).get_center()
	return Vector2(INF, INF)

func _show_info_panel(panel_name: String, text: String) -> void:
	for name: String in ["BackpackPanel", "SupplyCargoPanel", "ConsolePanel", "RobotPanel"]:
		var path := "UI/Root/%s" % name
		if has_node(path):
			var target: CanvasItem = get_node(path)
			target.visible = false
	var panel_path := "UI/Root/%s" % panel_name
	if not has_node(panel_path):
		return
	var panel: PanelContainer = get_node(panel_path)
	panel.visible = true
	var label: RichTextLabel = panel.get_node("Box/Text")
	label.text = text

func _hide_info_panels() -> void:
	for name: String in ["BackpackPanel", "SupplyCargoPanel", "ConsolePanel", "RobotPanel"]:
		var path := "UI/Root/%s" % name
		if has_node(path):
			var target: CanvasItem = get_node(path)
			target.visible = false

func _console_panel_text() -> String:
	return "Base status\nPower %.0f  O2 %.0f  Water %.0f  Food %.0f\nPressure %.0f%%  CO2 %.0f  Humidity %.0f%%\nModules %d  Leaks %d\nRobot: %s %.0f%%\nEVA risk: %s" % [
		resources["power"], resources["oxygen"], resources["water"], resources["food"],
		resources["pressure"], resources["co2"], resources["humidity"],
		modules.size(), _leaking_module_count(), _robot_status_text(), robot_battery, _eva_risk_text()
	]

func _backpack_panel_text() -> String:
	return "Backpack %.0f / %.0f\n%s\n\nStorage action\nPress E at storage cabinet to unload carried cargo into base inventory.\nLarge supply pods require several trips." % [
		_backpack_load(), backpack_capacity, _backpack_summary()
	]

func _supply_panel_text() -> String:
	if supply_order.is_empty():
		return "No active Earth supply order.\nOpen the supply terminal when the request window is available."
	var status := "In transit"
	if supply_waiting:
		status = "Landed: EVA pickup required"
	var remaining := "Cargo not unpacked yet"
	if supply_order.has("cargo_remaining"):
		var cargo: Dictionary = supply_order["cargo_remaining"]
		var parts: Array[String] = []
		for key: String in cargo.keys():
			parts.append("%s %.0f" % [resource_names.get(key, key), float(cargo[key])])
		remaining = _join_strings(parts, " / ") if not parts.is_empty() else "Cargo hold empty"
	return "%s\nOrder: %s\nArrival day: %d\nRemaining: %s\nBackpack %.0f / %.0f" % [
		status,
		supply_order.get("name", "-"),
		int(supply_order.get("arrival_day", day)),
		remaining,
		_backpack_load(),
		backpack_capacity
	]

func _eva_risk_text() -> String:
	var risks: Array[String] = []
	if resources["suit_o2"] <= 35.0:
		risks.append("low O2")
	if solar_storm_days > 0:
		risks.append("solar storm")
	if micrometeor_alert_days > 0:
		risks.append("micrometeor alert")
	if resources["suit_dust"] >= 60.0:
		risks.append("high dust")
	return _join_strings(risks, " / ") if not risks.is_empty() else "nominal"

func _setup_main_menu() -> void:
	var menu := Control.new()
	menu.name = "MainMenu"
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	$UI/Root.add_child(menu)

	var background := TitleScreenBackground.new()
	background.name = "TitleBackground"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(background)

	var agency := Label.new()
	agency.text = "国家深空生命科学中心\nNATIONAL DEEP SPACE\nLIFE SCIENCE CENTER"
	agency.position = Vector2(86, 42)
	agency.size = Vector2(360, 86)
	agency.modulate = Color("#9fb4c4", 0.86)
	agency.add_theme_font_size_override("font_size", 15)
	menu.add_child(agency)

	var version := Label.new()
	version.text = "v0.5-editor-playtest"
	version.position = Vector2(1318, 50)
	version.size = Vector2(250, 28)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.modulate = Color("#9fb4c4", 0.76)
	version.add_theme_font_size_override("font_size", 16)
	menu.add_child(version)

	var box := VBoxContainer.new()
	box.name = "Box"
	box.position = Vector2(132, 176)
	box.size = Vector2(590, 570)
	box.add_theme_constant_override("separation", 10)
	menu.add_child(box)

	var title := Label.new()
	title.text = "广寒前哨"
	title.modulate = Color("#eef5fb")
	title.add_theme_font_size_override("font_size", 76)
	box.add_child(title)

	var english_title := Label.new()
	english_title.text = "GUANGHAN OUTPOST"
	english_title.modulate = Color("#a7bed1")
	english_title.add_theme_font_size_override("font_size", 25)
	box.add_child(english_title)

	var subtitle := Label.new()
	subtitle.text = "让生命，在从未存在生命的地方生长。"
	subtitle.custom_minimum_size = Vector2(0, 70)
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.modulate = Color("#d8e7f2", 0.9)
	subtitle.add_theme_font_size_override("font_size", 22)
	box.add_child(subtitle)

	box.add_child(_make_title_button("开始新驻留", _start_application_flow, true))
	var continue_button := _make_title_button("继续驻留", _continue_mission, _has_continue_mission())
	continue_button.name = "ContinueButton"
	box.add_child(continue_button)
	var dev_separator := HSeparator.new()
	dev_separator.modulate = Color("#3d5060", 0.38)
	box.add_child(dev_separator)
	var dev_entry := _make_title_button("开发入口 / Debug", _toggle_dev_menu, true)
	dev_entry.custom_minimum_size = Vector2(0, 48)
	dev_entry.modulate = Color("#7f98aa", 0.72)
	box.add_child(dev_entry)
	box.add_child(_make_title_button("退出", func(): get_tree().quit(), true))

	var menu_notice := Label.new()
	menu_notice.name = "MenuNotice"
	menu_notice.custom_minimum_size = Vector2(0, 42)
	menu_notice.modulate = Color("#9fb4c4", 0.78)
	menu_notice.add_theme_font_size_override("font_size", 15)
	box.add_child(menu_notice)

	var input_hint := Label.new()
	input_hint.name = "InputHint"
	input_hint.text = "移动：WASD / 方向键    交互：E / Enter    返回 / 取消：Esc    开发菜单：F12"
	input_hint.custom_minimum_size = Vector2(0, 48)
	input_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	input_hint.modulate = Color("#8fa3b2", 0.82)
	input_hint.add_theme_font_size_override("font_size", 15)
	box.add_child(input_hint)

	var footer := Label.new()
	footer.text = "项目代号：广寒计划 | GH-OUTPOST-001"
	footer.position = Vector2(54, 856)
	footer.size = Vector2(520, 24)
	footer.modulate = Color("#6f8493", 0.62)
	footer.add_theme_font_size_override("font_size", 13)
	menu.add_child(footer)

	var dev_hint := Label.new()
	dev_hint.text = "提示：在游戏中按 F12 可打开开发菜单"
	dev_hint.position = Vector2(1180, 856)
	dev_hint.size = Vector2(360, 24)
	dev_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dev_hint.modulate = Color("#86a9c4", 0.72)
	dev_hint.add_theme_font_size_override("font_size", 13)
	menu.add_child(dev_hint)

	_setup_dev_menu()
	_set_gameplay_hud_visible(false)
	_refresh_main_menu()

func _make_title_button(text: String, callback: Callable, enabled: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 62)
	button.disabled = not enabled
	button.add_theme_font_size_override("font_size", 24)
	if enabled:
		button.pressed.connect(callback)
	return button

func _setup_dev_menu() -> void:
	var panel := PanelContainer.new()
	panel.name = "DevMenu"
	panel.visible = false
	panel.position = Vector2(1010, 96)
	panel.size = Vector2(430, 620)
	$UI/Root.add_child(panel)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := Label.new()
	title.text = "开发菜单 / DEV MENU"
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color("#eaf4ff")
	box.add_child(title)
	var note := Label.new()
	note.text = "仅用于本地测试。F12 显示/隐藏。"
	note.modulate = Color("#9fb4c4")
	box.add_child(note)
	box.add_child(_make_dev_button("Dev Only: Reset Demo Progress", _reset_demo_progress_from_dev))
	box.add_child(_make_dev_button("Dev Only: Start Survival Sandbox", _start_new_game))
	box.add_child(_make_dev_button("Dev Only: Arrival Cinematic", func(): get_tree().change_scene_to_file("res://scenes/arrival/ArrivalCinematicScene.tscn")))
	box.add_child(_make_dev_button("Dev Only: Arrival Landing", func(): get_tree().change_scene_to_file("res://scenes/arrival/ArrivalLandingScene.tscn")))
	box.add_child(_make_dev_button("Dev Only: Base Airlock Entry", func(): get_tree().change_scene_to_file("res://scenes/base/BaseAirlockEntryScene.tscn")))
	box.add_child(_make_dev_button("Dev Only: Old Base Interior", func(): get_tree().change_scene_to_file("res://scenes/base/OldBaseInteriorScene.tscn")))
	box.add_child(_make_dev_button("Dev Only: Old Base Art Slice", func(): get_tree().change_scene_to_file("res://scenes/base/OldBaseCore_ArtSlice.tscn")))
	box.add_child(_make_dev_button("Dev Only: Old Greenhouse", func(): get_tree().change_scene_to_file("res://scenes/base/OldGreenhouseScene.tscn")))
	box.add_child(_make_dev_button("Dev Only: Day 01 End", func(): get_tree().change_scene_to_file("res://scenes/base/Day01EndScene.tscn")))
	box.add_child(_make_dev_button("Dev Only: Day 02 Start", func(): get_tree().change_scene_to_file("res://scenes/base/Day02StartScene.tscn")))
	box.add_child(_make_dev_button("Dev Only: Day 02 End", func(): get_tree().change_scene_to_file("res://scenes/base/Day02EndScene.tscn")))
	box.add_child(_make_dev_button("Dev Only: Week Routine Start", func(): get_tree().change_scene_to_file("res://scenes/base/WeekRoutineStartScene.tscn")))
	box.add_child(_make_dev_button("Dev Only: Week Routine End", func(): get_tree().change_scene_to_file("res://scenes/base/WeekRoutineEndScene.tscn")))
	box.add_child(_make_dev_button("Dev Only: Day 07 Report Test", _start_day07_report_test))
	box.add_child(_make_dev_button("Dev Only: Solar Array Exterior", func(): get_tree().change_scene_to_file("res://scenes/base/SolarArrayExteriorScene.tscn")))
	box.add_child(_make_dev_button("Time Debug: +15 分钟", func(): _debug_advance_time(15, "debug_plus_15")))
	box.add_child(_make_dev_button("Time Debug: +1 小时", func(): _debug_advance_time(60, "debug_plus_1h")))
	box.add_child(_make_dev_button("Time Debug: +6 小时", func(): _debug_advance_time(360, "debug_plus_6h")))
	box.add_child(_make_dev_button("Time Debug: 跳到月昼", _debug_jump_to_daylight))
	box.add_child(_make_dev_button("Time Debug: 跳到月夜", _debug_jump_to_night))
	box.add_child(_make_dev_button("Time Debug: 重置 Day 01", _debug_reset_time))
	box.add_child(_make_dev_button("Health Debug: Energy -20", func(): _debug_adjust_health("energy", -20.0)))
	box.add_child(_make_dev_button("Health Debug: Energy +20", func(): _debug_adjust_health("energy", 20.0)))
	box.add_child(_make_dev_button("Health Debug: Fullness -20", func(): _debug_adjust_health("fullness", -20.0)))
	box.add_child(_make_dev_button("Health Debug: Fullness +20", func(): _debug_adjust_health("fullness", 20.0)))
	box.add_child(_make_dev_button("Health Debug: Nutrition -20", func(): _debug_adjust_health("nutrition", -20.0)))
	box.add_child(_make_dev_button("Health Debug: Nutrition +20", func(): _debug_adjust_health("nutrition", 20.0)))
	box.add_child(_make_dev_button("Health Debug: Morale -20", func(): _debug_adjust_health("morale", -20.0)))
	box.add_child(_make_dev_button("Health Debug: Morale +20", func(): _debug_adjust_health("morale", 20.0)))
	box.add_child(_make_dev_button("Health Debug: Reset Healthy", _debug_reset_health))
	box.add_child(_make_dev_button("Health Debug: Set Danger", _debug_set_health_danger))
	box.add_child(_make_dev_button("Health Action: Sleep", func(): _debug_health_action("sleep_standard")))
	box.add_child(_make_dev_button("Health Action: Eat", func(): _debug_health_action("eat")))
	box.add_child(_make_dev_button("Health Action: Nutrition Drink", func(): _debug_health_action("nutrition_drink")))
	box.add_child(_make_dev_button("Health Action: Short Entertainment", func(): _debug_health_action("entertainment_short")))
	box.add_child(_make_dev_button("Health Action: Light Repair", func(): _debug_health_action("repair_light")))
	box.add_child(_make_dev_button("Health Action: Short Explore", func(): _debug_health_action("explore_short")))
	box.add_child(_make_dev_button("Base Debug: Power -10", func(): _debug_adjust_base_status("power", -10.0)))
	box.add_child(_make_dev_button("Base Debug: Power +10", func(): _debug_adjust_base_status("power", 10.0)))
	box.add_child(_make_dev_button("Base Debug: Oxygen -10", func(): _debug_adjust_base_status("oxygen", -10.0)))
	box.add_child(_make_dev_button("Base Debug: Oxygen +10", func(): _debug_adjust_base_status("oxygen", 10.0)))
	box.add_child(_make_dev_button("Base Debug: Pressure -10", func(): _debug_adjust_base_status("pressure", -10.0)))
	box.add_child(_make_dev_button("Base Debug: Pressure +10", func(): _debug_adjust_base_status("pressure", 10.0)))
	box.add_child(_make_dev_button("Base Debug: Temperature -2", func(): _debug_adjust_base_status("temperature", -2.0)))
	box.add_child(_make_dev_button("Base Debug: Temperature +2", func(): _debug_adjust_base_status("temperature", 2.0)))
	box.add_child(_make_dev_button("Base Debug: Power System Critical/Basic/Stable", func(): _debug_cycle_base_system("power_system_status")))
	box.add_child(_make_dev_button("Base Debug: Life Support Critical/Basic/Stable", func(): _debug_cycle_base_system("life_support_status")))
	box.add_child(_make_dev_button("Base Debug: Thermal Control Critical/Basic/Stable", func(): _debug_cycle_base_system("thermal_control_status")))
	box.add_child(_make_dev_button("Base Debug: Seal Critical/Basic/Stable", func(): _debug_cycle_base_system("seal_status")))
	box.add_child(_make_dev_button("Base Debug: Reset to Day 01", _debug_reset_base_status))
	box.add_child(_make_dev_button("Base Debug: Set Minimum Stable", _debug_set_base_status_minimum_stable))
	box.add_child(_make_dev_button("Plant Debug: Sow Lettuce", func(): _debug_sow_plant("lettuce")))
	box.add_child(_make_dev_button("Plant Debug: Sow Potato", func(): _debug_sow_plant("potato")))
	box.add_child(_make_dev_button("Plant Debug: Sow Wheat", func(): _debug_sow_plant("wheat")))
	box.add_child(_make_dev_button("Plant Debug: Sow Tomato", func(): _debug_sow_plant("tomato")))
	box.add_child(_make_dev_button("Plant Debug: Sow Soybean", func(): _debug_sow_plant("soybean")))
	box.add_child(_make_dev_button("Plant Debug: Advance Growth +1 Day", func(): _debug_advance_time(1440, "debug_plant_plus_1d")))
	box.add_child(_make_dev_button("Plant Debug: Advance Growth +3 Days", func(): _debug_advance_time(4320, "debug_plant_plus_3d")))
	box.add_child(_make_dev_button("Plant Debug: Cycle Water Level 0-4", _debug_cycle_plant_water_level))
	box.add_child(_make_dev_button("Plant Debug: Cycle Greenhouse Light Level 0-4", _debug_cycle_plant_light_level))
	box.add_child(_make_dev_button("Plant Debug: Force Mature Current Crop", _debug_force_mature_plant))
	box.add_child(_make_dev_button("Plant Debug: Harvest Current Crop", _debug_harvest_plant))
	box.add_child(_make_dev_button("Plant Debug: Clear Greenhouse Crops", _debug_clear_plants))
	box.add_child(_make_dev_button("Dev Only: Training Start", func(): get_tree().change_scene_to_file("res://scenes/training/TrainingStartScene.tscn")))
	box.add_child(_make_dev_button("Dev Only: Training Module 01", func():
		TrainingManagerScript.set_current_module("suit_control")
		get_tree().change_scene_to_file("res://scenes/training/Training_01_SuitControl.tscn")
	))
	box.add_child(_make_dev_button("Dev Only: Training Module 02", func():
		TrainingManagerScript.set_current_module("airlock_procedure")
		get_tree().change_scene_to_file("res://scenes/training/Training_02_AirlockProcedure.tscn")
	))
	box.add_child(_make_dev_button("Dev Only: Training Module 03", func():
		TrainingManagerScript.set_current_module("power_repair")
		get_tree().change_scene_to_file("res://scenes/training/Training_03_PowerRepair.tscn")
	))
	box.add_child(_make_dev_button("Dev Only: Training Module 04", func():
		TrainingManagerScript.set_current_module("life_support")
		get_tree().change_scene_to_file("res://scenes/training/Training_04_LifeSupport.tscn")
	))
	box.add_child(_make_dev_button("Dev Only: Training Module 05", func():
		TrainingManagerScript.set_current_module("plant_diagnosis")
		get_tree().change_scene_to_file("res://scenes/training/Training_05_PlantDiagnosis.tscn")
	))
	box.add_child(_make_dev_button("Dev Only: Final Assessment", func():
		TrainingManagerScript.set_current_module("final_assessment")
		get_tree().change_scene_to_file("res://scenes/training/FinalAssessmentScene.tscn")
	))
	box.add_child(_make_dev_button("Dev Only: Mission Assignment Notice", func():
		TrainingManagerScript.mark_module_completed("final_assessment", "mission_assignment")
		get_tree().change_scene_to_file("res://scenes/training/MissionAssignmentNoticeScene.tscn")
	))
	box.add_child(_make_dev_button("Dev Only: Reset Training Progress", func():
		TrainingManagerScript.reset_progress()
		add_log("Training progress reset.")
		_refresh_main_menu()
	))
	box.add_child(_make_dev_button("Dev Only: Clear Save", _clear_current_save))

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

func _debug_reset_time() -> void:
	var manager := get_node_or_null("/root/TimeManager")
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
		add_log("Time debug: reset to Day 01 lunar night late.")

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

func _toggle_dev_menu() -> void:
	if not has_node("UI/Root/DevMenu"):
		return
	dev_menu_visible = not dev_menu_visible
	var panel: CanvasItem = $UI/Root/DevMenu
	panel.visible = dev_menu_visible

func _set_gameplay_hud_visible(visible: bool) -> void:
	if is_instance_valid(ui_manager) and ui_manager.has_method("set_hud_visible"):
		ui_manager.call("set_hud_visible", visible)

func _start_application_flow() -> void:
	if _has_demo_progress():
		_show_new_game_confirmation()
		return
	_start_clean_new_stay()

func _start_clean_new_stay() -> void:
	_clear_demo_progress()
	_debug_reset_time()
	get_tree().change_scene_to_file("res://scenes/application/ApplicationStartScene.tscn")

func _continue_mission() -> void:
	var progress := TrainingManagerScript.load_progress()
	if _training_has_progress(progress) or _sprint06_has_progress() or _application_has_progress():
		get_tree().change_scene_to_file(TrainingManagerScript.continue_scene_path())
		return
	var latest_slot := _latest_save_slot()
	if latest_slot > 0:
		current_save_slot = latest_slot
		_load_game()
		return
	add_log("没有可继续的任务档案。")
	_refresh_main_menu()

func _has_continue_mission() -> bool:
	return _training_has_progress(TrainingManagerScript.load_progress()) or _sprint06_has_progress() or _application_has_progress() or _latest_save_slot() > 0

func _has_demo_progress() -> bool:
	if _has_continue_mission():
		return true
	for path: String in DEMO_PROGRESS_PATHS:
		if FileAccess.file_exists(path):
			return true
	return false

func _training_has_progress(progress: Dictionary) -> bool:
	return bool(progress.get("TrainingStarted", false)) or bool(progress.get("FinalAssessmentCompleted", false)) or bool(progress.get("MissionAssignmentAccepted", false))

func _sprint06_has_progress() -> bool:
	return FileAccess.file_exists("user://saves/sprint06_progress.json")

func _application_has_progress() -> bool:
	return FileAccess.file_exists("user://saves/application_profile.json")

func _latest_save_slot() -> int:
	for slot in range(1, SAVE_SLOTS + 1):
		if FileAccess.file_exists(_save_path(slot)):
			return slot
	return 0

func _show_archive_placeholder() -> void:
	_set_title_menu_notice("档案系统将在后续版本开放。")
	add_log("档案页将在后续版本开放。")

func _show_settings_placeholder() -> void:
	_set_title_menu_notice("设置系统将在后续版本开放。")
	add_log("设置页将在后续版本开放。")

func _set_title_menu_notice(text: String) -> void:
	if has_node("UI/Root/MainMenu/Box/MenuNotice"):
		var label: Label = $UI/Root/MainMenu/Box/MenuNotice
		label.text = text

func _clear_current_save() -> void:
	var path := _save_path(current_save_slot)
	if FileAccess.file_exists(path):
		var absolute_path := ProjectSettings.globalize_path(path)
		DirAccess.remove_absolute(absolute_path)
		add_log("Dev: cleared save slot %d." % current_save_slot)
	else:
		add_log("Dev: save slot %d is already empty." % current_save_slot)
	_refresh_main_menu()

func _clear_demo_progress() -> void:
	for path: String in DEMO_PROGRESS_PATHS:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for slot in range(1, SAVE_SLOTS + 1):
		var path := _save_path(slot)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_refresh_main_menu()

func _reset_demo_progress_from_dev() -> void:
	_clear_demo_progress()
	TrainingManagerScript.reset_progress()
	_debug_reset_time()
	add_log("Dev: demo progress reset.")
	_set_title_menu_notice("试玩进度已清除。可以从“开始新驻留”重新开始。")

func _show_new_game_confirmation() -> void:
	if has_node("UI/Root/NewGameConfirm"):
		$UI/Root/NewGameConfirm.queue_free()
	var panel := PanelContainer.new()
	panel.name = "NewGameConfirm"
	panel.position = Vector2(520, 260)
	panel.size = Vector2(560, 300)
	$UI/Root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := Label.new()
	title.text = "开始新的驻留档案？"
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	var body := Label.new()
	body.text = "检测到已有试玩进度。\n\n开始新的驻留将清除申请、训练、旧基地和第一周进度。\n此操作仅影响本地编辑器试玩存档。"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color("#d8e7f2")
	body.add_theme_font_size_override("font_size", 18)
	box.add_child(body)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(160, 44)
	cancel.pressed.connect(func(): panel.queue_free())
	footer.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "清除进度并开始"
	confirm.custom_minimum_size = Vector2(220, 44)
	confirm.modulate = Color("#9ac7e8")
	confirm.pressed.connect(func():
		panel.queue_free()
		_start_clean_new_stay()
	)
	footer.add_child(confirm)

func _start_day07_report_test() -> void:
	var state := {
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
		"DailyWaterChecked": true,
		"DailyPlantChecked": true,
		"DailySpecialChecked": true,
		"DailyRecordUpdated": true,
		"DailyInspectionsComplete": true,
		"DailyReportPreviewed": true,
		"DailyReportSent": false,
		"WeekOneReportSent": false,
		"WeekOneCompleted": false,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open("user://saves/sprint06_progress.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(state, "\t"))
	get_tree().change_scene_to_file("res://scenes/base/OldBaseCore_ArtSlice.tscn")

func _select_crop(crop_name: String) -> void:
	selected_crop = crop_name
	add_log("已选择作物：%s。" % crop_defs[crop_name]["name"])
	_update_ui()

func _update_ui() -> void:
	if not has_node("UI/Root"):
		return
	_sync_task_history()
	var phase := "月夜" if is_moon_night else "月昼"
	var counts: Dictionary = _module_counts()
	var power_cap: float = 120.0 + float(counts["battery"]) * 35.0
	$UI/Root/Top.text = "广寒前哨 | 第 %d 天 | %s | 电力 %.0f/%.0f  氧气 %.0f  水 %.0f  食物 %.0f  维修件 %.0f  完整度 %.0f%%  月尘 %d%%" % [
		day, phase, resources["power"], power_cap, resources["oxygen"], resources["water"], resources["food"],
		resources["parts"], resources["integrity"], int(solar_dust * 100)
	]
	$UI/Root/SupplyStatus.text = _supply_status_text()
	$UI/Root/LifeStatus.text = "舱压 %.0f%%  CO2 %.0f  湿度 %.0f%%\n宇航服 O2 %.0f%% 耐久 %.0f%% 月尘 %.0f%%  %s" % [
		resources["pressure"], resources["co2"], resources["humidity"],
		resources["suit_o2"], resources["suit_integrity"], resources["suit_dust"],
		"舱内" if _is_player_inside_pressurized_module() else "舱外"
	]
	$UI/Root/OperatorStatus.text = _operator_status_text()
	$UI/Root/MissionStatus.text = _mission_status_text()
	$UI/Root/EvaTasks.text = _eva_tasks_text()
	$UI/Root/Guide.text = _guide_text()
	$UI/Root/ObjectiveStack.text = _objective_stack_text()
	$UI/Root/TrackingButton.text = "追踪目标：开" if objective_tracking else "追踪目标：关"
	if has_node("UI/Root/NextTargetButton"):
		$UI/Root/NextTargetButton.text = "切换目标 Y"
	_update_task_log_controls()
	$UI/Root/TaskLog.text = _task_log_text()
	_update_completion_toast()
	_update_edge_hint()
	_update_intro_overlay()
	if has_node("UI/Root/ZoomPanel/ZoomLabel"):
		$UI/Root/ZoomPanel/ZoomLabel.text = "图%d UI%d" % [int(camera_zoom * 100), int(ui_scale * 100)]
	_update_tech_buttons()
	_refresh_main_menu()
	var hint := "工具：%s | 作物：%s | 背包 %.0f/%.0f：%s | 月壤 %.0f 水冰 %.0f 样本 %.0f。" % [
		tool_defs[selected_tool]["name"], crop_defs[selected_crop]["name"],
		_backpack_load(), backpack_capacity, _backpack_summary(),
		resources["regolith"], resources["ice"], resources["samples"]
	]
	if build_mode and selected_build != "":
		var def: Dictionary = module_defs[selected_build]
		var cost: Dictionary = def["cost"]
		hint = "建造模式：%s | 成本：维修件 %.0f、电力 %.0f | 靠近空地按 E，Esc 取消。" % [def["name"], cost["parts"], cost["power"]]
	elif not interact_target.is_empty():
		if interact_target.has("kind") and interact_target["kind"] == "collectable":
			hint = "月面采集点：按 E 使用 %s。%s" % [tool_defs[selected_tool]["name"], tool_defs[selected_tool]["hint"]]
		elif interact_target.has("kind") and interact_target["kind"] == "facility":
			hint = "%s：%s" % [_facility_name(interact_target["facility"]), _facility_hint(interact_target["facility"])]
		else:
			var def: Dictionary = module_defs[interact_target["type"]]
			if interact_target.get("leaking", false):
				hint = "%s：舱段漏气。切换维修枪并按 E 封堵，消耗 2 维修件。" % def["name"]
			else:
				hint = "%s：%s" % [def["name"], def["hint"]]
	$UI/Root/Hint.text = hint
	$UI/Root/Log.text = _join_strings(log_lines, "\n")
	_refresh_open_info_panels()

func _refresh_open_info_panels() -> void:
	if has_node("UI/Root/RobotPanel") and $UI/Root/RobotPanel.visible:
		var label: RichTextLabel = $UI/Root/RobotPanel.get_node("Box/Text")
		label.text = _robot_panel_text()
	if has_node("UI/Root/ConsolePanel") and $UI/Root/ConsolePanel.visible:
		var label: RichTextLabel = $UI/Root/ConsolePanel.get_node("Box/Text")
		label.text = _console_panel_text()

func _update_tech_buttons() -> void:
	if not has_node("UI/Root/TechPanel"):
		return
	var tech_ids := _tech_order()
	var buttons := $UI/Root/TechPanel.get_children()
	for i in range(min(tech_ids.size(), buttons.size())):
		var button: Button = buttons[i]
		button.text = _tech_button_text(tech_ids[i])
		button.disabled = _has_tech(tech_ids[i])

func _tech_order() -> Array[String]:
	return ["change_samples", "queqiao_relay", "yutu_robot", "closed_ecology", "precision_landing", "robot_assist"]

func _operator_status_text() -> String:
	return "前哨员：%s\n健康 %.0f  精神 %.0f  疲劳 %.0f\n机器人：%s" % [
		operator.get("name", "林舟"),
		float(operator.get("health", 100.0)),
		float(operator.get("morale", 100.0)),
		float(operator.get("fatigue", 0.0)),
		_robot_queue_text() if (_has_tech("robot_assist") or _has_tech("yutu_robot")) else "待解锁"
	]

func _mission_status_text() -> String:
	var active := ""
	for mission_id: String in mission_defs.keys():
		if not completed_missions.has(mission_id):
			var mission: Dictionary = mission_defs[mission_id]
			active = "%s：%s" % [mission["name"], mission["desc"]]
			break
	if active == "":
		active = "阶段任务全部完成。"
	return "任务 %d/%d：%s" % [completed_missions.size(), mission_defs.size(), active]

func _guide_text() -> String:
	var title := "[ 今日任务卡 ]"
	var action := ""
	var reason := ""
	var done := ""
	if not bool(tutorial_flags.get("console", false)):
		action = "1. 去居住舱控制台"
		reason = "先确认电力、氧气、水和补给状态。"
		done = "靠近闪烁屏幕按 E。"
	elif not bool(tutorial_flags.get("airlock", false)):
		action = "2. 去气闸做出舱检查"
		reason = "补满航天服氧气，降低第一次出舱风险。"
		done = "靠近气闸按 E。"
	elif not bool(tutorial_flags.get("collected", false)):
		action = "3. 出舱采集第一批资源"
		reason = "月壤、水冰和样本是制氧、科研和扩建的起点。"
		done = "靠近月面采集点按 E。"
	elif not bool(tutorial_flags.get("stored", false)):
		action = "4. 回储物柜入库"
		reason = "背包物资不算基地库存，必须搬回舱内。"
		done = "靠近储物柜按 E。"
	elif not bool(tutorial_flags.get("planted", false)):
		action = "5. 去温室种下第一批作物"
		reason = "食物会持续消耗，农业越早启动越稳。"
		done = "靠近温室按 E。"
	elif not bool(tutorial_flags.get("supply", false)):
		action = "6. 去补给区申请地球补给"
		reason = "补给有运输时间，提前申请比缺了再等更安全。"
		done = "靠近补给区按 E，优先选择生存包。"
	elif not bool(tutorial_flags.get("advanced_day", false)):
		action = "7. 进入下一天"
		reason = "观察资源结算，开始真正的生存循环。"
		done = "按 N 或右下按钮推进时间。"
	else:
		action = _strategic_next_goal()
		reason = "长期目标：撑过 30 天，扩建能源、温室、生命维持和机器人能力。"
		done = "完成当前最紧急的一项基地运营动作。"
	var warning := ""
	if last_guidance_tip != "":
		warning = "\n提示：%s" % last_guidance_tip
	return "%s\n行动：%s\n原因：%s\n完成：%s%s" % [title, action, reason, done, warning]

func _objective_stack_text() -> String:
	var lines: Array[String] = ["[b]目标栈[/b]"]
	var targets := _objective_targets()
	tracked_objective_index = _normalized_objective_index(tracked_objective_index)
	var tracked_name := "无"
	if not targets.is_empty():
		var tracked: Dictionary = targets[tracked_objective_index]
		tracked_name = "%s  %.1f格" % [String(tracked.get("name", "目标")), _target_distance_tiles(tracked)]
	lines.append("[color=#e7c66b]当前：%s[/color]" % _current_objective_action())
	lines.append("[color=#d8e0eb]出舱：%s[/color]" % _primary_eva_task())
	lines.append("[color=#8fa0b8]长期：%s[/color]" % _strategic_next_goal())
	lines.append("[color=#8fa0b8]追踪：%s | %s（T 开关 / Y 切换）[/color]" % ["开" if objective_tracking else "关", tracked_name])
	return _join_strings(lines, "\n")

func _current_objective_action() -> String:
	var step: Dictionary = _current_tutorial_step()
	if not step.is_empty():
		return String(step["name"])
	return _strategic_next_goal()

func _primary_eva_task() -> String:
	if _active_collectable_count("supply_pod") > 0:
		return "回收补给舱"
	if _active_collectable_count("ice") > 0:
		return "采集水冰"
	if solar_dust >= 0.22:
		return "清理太阳能板"
	if _external_repair_count() > 0:
		return "维修外部设备"
	if solar_storm_days > 0:
		return "太阳风暴中，减少出舱"
	if micrometeor_alert_days > 0:
		return "微陨石预警，暂停远距离维修"
	return "暂无紧急出舱任务"

func _tutorial_steps() -> Array[Dictionary]:
	return [
		{"flag": "console", "name": "查看控制台", "detail": "确认电力、氧气、水和补给状态"},
		{"flag": "airlock", "name": "气闸检查", "detail": "补氧、复压、除尘后再出舱"},
		{"flag": "collected", "name": "采集资源", "detail": "用采样铲采集月壤/水冰/样本"},
		{"flag": "stored", "name": "储物柜入库", "detail": "把背包物资转成基地库存"},
		{"flag": "planted", "name": "温室种植", "detail": "启动第一批食物生产"},
		{"flag": "supply", "name": "申请补给", "detail": "提前向地球申请物资"},
		{"flag": "advanced_day", "name": "进入下一天", "detail": "观察每日结算并继续运营"},
	]

func _sync_task_history() -> void:
	for step: Dictionary in _tutorial_steps():
		var flag := String(step["flag"])
		if bool(tutorial_flags.get(flag, false)):
			_record_task_history("tutorial:%s" % flag, "新手流程完成：%s" % String(step["name"]))

func _record_task_history(marker: String, text: String) -> void:
	var token := "%s|" % marker
	for entry: String in task_history:
		if entry.begins_with(token):
			return
	task_history.append("%s|D%d  %s" % [marker, day, text])
	while task_history.size() > 18:
		task_history.pop_front()
	if marker.begins_with("tutorial:") or marker.begins_with("mission:"):
		_show_task_feedback(text, player_pos)

func _task_history_lines(limit: int) -> Array[String]:
	var lines: Array[String] = []
	var start: int = max(0, task_history.size() - limit)
	for i in range(start, task_history.size()):
		var entry := String(task_history[i])
		var parts := entry.split("|", false, 1)
		lines.append(parts[1] if parts.size() > 1 else entry)
	return lines

func _current_tutorial_step() -> Dictionary:
	for step: Dictionary in _tutorial_steps():
		if not bool(tutorial_flags.get(String(step["flag"]), false)):
			return step
	return {}

func _task_log_text() -> String:
	var lines: Array[String] = ["[b]任务日志[/b]  %s" % ("展开" if task_log_expanded else "简略")]
	var current_found := false
	var steps: Array[Dictionary] = _tutorial_steps()
	if task_log_expanded:
		for step: Dictionary in steps:
			var done := bool(tutorial_flags.get(String(step["flag"]), false))
			var prefix := "[x]"
			var color := "8fa0b8"
			if not done and not current_found:
				prefix = "[>]"
				color = "e7c66b"
				current_found = true
			elif not done:
				prefix = "[ ]"
			lines.append("[color=#%s]%s %s[/color]" % [color, prefix, String(step["name"])])
			if not done and current_found and prefix == "[>]":
				lines.append("[color=#d8e0eb]    %s[/color]" % String(step["detail"]))
	else:
		var current_step: Dictionary = _current_tutorial_step()
		if current_step.is_empty():
			current_found = false
		else:
			current_found = true
			lines.append("[color=#e7c66b][>] %s[/color]" % String(current_step["name"]))
			lines.append("[color=#d8e0eb]    %s[/color]" % String(current_step["detail"]))
	if not current_found:
		lines.append("[color=#7dff9d][x] 新手流程完成[/color]")
		lines.append("[color=#d8e0eb]下一步：%s[/color]" % _strategic_next_goal())
	var history_lines := _task_history_lines(8 if task_log_expanded else 3)
	if not history_lines.is_empty():
		lines.append("")
		lines.append("[b]历史[/b]")
		for line: String in history_lines:
			lines.append("[color=#8fa0b8]%s[/color]" % line)
	return _join_strings(lines, "\n")

func _tutorial_target_pos() -> Vector2:
	if not bool(tutorial_flags.get("console", false)):
		return _facility_target_pos("hab", "console")
	if not bool(tutorial_flags.get("airlock", false)):
		return _module_target_pos("airlock")
	if not bool(tutorial_flags.get("collected", false)):
		return _nearest_collectable_pos(["regolith", "ice", "sample"])
	if not bool(tutorial_flags.get("stored", false)):
		return _facility_target_pos("hab", "storage")
	if not bool(tutorial_flags.get("planted", false)):
		return _module_target_pos("greenhouse")
	if not bool(tutorial_flags.get("supply", false)):
		return _module_target_pos("supply")
	return Vector2(INF, INF)

func _module_target_pos(module_type: String) -> Vector2:
	for module: Dictionary in modules:
		if String(module["type"]) == module_type:
			return _module_rect(module).get_center()
	return Vector2(INF, INF)

func _facility_target_pos(module_type: String, facility: String) -> Vector2:
	for module: Dictionary in modules:
		if String(module["type"]) != module_type:
			continue
		var rect: Rect2 = _module_rect(module)
		match facility:
			"console":
				return rect.position + Vector2(rect.size.x - 34, rect.size.y - 32)
			"storage":
				return rect.position + Vector2(rect.size.x - 34, 46)
			"bed":
				return rect.position + Vector2(48, 48)
			"robot_charger":
				return rect.position + Vector2(rect.size.x - 40, 48)
	return _module_target_pos(module_type)

func _strategic_next_goal() -> String:
	if resources["power"] < 35.0:
		return "电力偏低：清理太阳能板，或建造太阳能/电池。"
	if resources["food"] < 25.0:
		return "食物偏低：去温室种植，优先土豆或藻类。"
	if resources["oxygen"] < 35.0:
		return "氧气偏低：维护生命维持，或用月壤提氧。"
	if _leaking_module_count() > 0:
		return "存在漏气舱段：切换维修枪，优先封堵红框模块。"
	if _active_collectable_count("supply_pod") > 0:
		return "补给已落地：检查宇航服，出舱回收补给舱。"
	if _backpack_load() > 0.0:
		return "背包有物资：回储物柜入库。"
	if day >= 11 and day < 14:
		return "月夜将至：储电、备氧、申请补给。"
	return "基地稳定：采集水冰/月壤，研究科技，继续扩建。"

func _eva_tasks_text() -> String:
	var lines: Array[String] = []
	var targets := _objective_targets()
	var eva_targets: Array[Dictionary] = []
	for target: Dictionary in targets:
		if String(target.get("kind", "")) in ["supply", "ice", "solar", "repair", "storage"]:
			eva_targets.append(target)
	for i in range(min(3, eva_targets.size())):
		var target: Dictionary = eva_targets[i]
		lines.append("%d. %s %s | %.1f格 | %s | %s" % [
			i + 1,
			_eva_task_icon(String(target.get("kind", ""))),
			String(target.get("name", "任务")),
			_target_distance_tiles(target),
			_eva_task_risk_label(target),
			String(target.get("tool", ""))
		])
	if solar_storm_days > 0:
		lines.append("! 太阳风暴：减少出舱，气闸成本上升")
	if micrometeor_alert_days > 0:
		lines.append("! 微陨石：暂停远距离维修")
	if lines.is_empty():
		lines.append("暂无紧急出舱任务。可巡检水冰、太阳能板和补给信标。")
	var suit_line := "宇航服：氧 %.0f%% 耐久 %.0f%% 月尘 %.0f%%" % [
		resources["suit_o2"], resources["suit_integrity"], resources["suit_dust"]
	]
	return "出舱任务 V2：建议顺序\n%s\n%s" % [_join_strings(lines.slice(0, 4), "\n"), suit_line]

func _eva_task_icon(kind: String) -> String:
	match kind:
		"storage":
			return "[入库]"
		"supply":
			return "[补给]"
		"ice":
			return "[水冰]"
		"solar":
			return "[清灰]"
		"repair":
			return "[维修]"
		_:
			return "[目标]"

func _target_distance_tiles(target: Dictionary) -> float:
	var pos: Vector2 = target.get("pos", player_pos)
	return player_pos.distance_to(pos) / float(TILE)

func _eva_task_risk_label(target: Dictionary) -> String:
	var score := 0
	var distance := _target_distance_tiles(target)
	if distance >= 10.0:
		score += 2
	elif distance >= 6.0:
		score += 1
	if resources["suit_o2"] < 45.0:
		score += 2
	elif resources["suit_o2"] < 65.0:
		score += 1
	if resources["suit_integrity"] < 35.0:
		score += 2
	if resources["suit_dust"] >= 60.0:
		score += 1
	if solar_storm_days > 0:
		score += 2
	if micrometeor_alert_days > 0 and String(target.get("kind", "")) == "repair":
		score += 2
	if score >= 5:
		return "高风险"
	if score >= 3:
		return "中风险"
	return "低风险"

func _supply_cargo_summary() -> String:
	if supply_order.is_empty() or not supply_order.has("cargo_remaining"):
		return "无货物"
	var cargo: Dictionary = supply_order["cargo_remaining"]
	if cargo.is_empty():
		return "待确认"
	var parts: Array[String] = []
	for key: String in cargo.keys():
		if key == "dust":
			continue
		if float(cargo[key]) > 0.0:
			parts.append("%s %.0f" % [resource_names.get(key, key), float(cargo[key])])
	if parts.is_empty():
		return "仅剩耗材"
	return _join_strings(parts, " / ")

func _active_collectable_count(item_type: String) -> int:
	var count := 0
	for item: Dictionary in collectables:
		if item["depleted"]:
			continue
		if item["type"] == item_type:
			count += 1
	return count

func _external_repair_count() -> int:
	var count := 0
	for module: Dictionary in modules:
		if module.get("leaking", false):
			count += 1
			continue
		if module["type"] in ["regolith_plant", "ice_processor"] and resources["integrity"] < 70.0:
			count += 1
	return count

func _external_repair_target_pos() -> Vector2:
	for module: Dictionary in modules:
		if bool(module.get("leaking", false)):
			return _module_rect(module).get_center()
	for module: Dictionary in modules:
		if String(module["type"]) in ["regolith_plant", "ice_processor"] and resources["integrity"] < 70.0:
			return _module_rect(module).get_center()
	return Vector2(INF, INF)

func _refresh_main_menu() -> void:
	if not has_node("UI/Root/MainMenu/Box"):
		return
	if has_node("UI/Root/MainMenu/Box/ContinueButton"):
		var button: Button = $UI/Root/MainMenu/Box/ContinueButton
		button.disabled = not _has_continue_mission()

func _tech_button_text(tech_id: String) -> String:
	var tech: Dictionary = tech_defs[tech_id]
	if _has_tech(tech_id):
		return "%s 已解锁" % tech["name"]
	var cost: Dictionary = tech["cost"]
	var parts: Array[String] = []
	for key: String in cost.keys():
		parts.append("%s %.0f" % [resource_names.get(key, key), float(cost[key])])
	return "%s（%s）" % [tech["name"], _join_strings(parts, " / ")]

func _supply_status_text() -> String:
	if supply_waiting:
		var pos := _dict_to_vector2(supply_order.get("landing_pos", _vector2_to_dict(Vector2.ZERO)))
		return "补给状态：%s 已着陆\n剩余：%s\n信标：%.0f, %.0f；分批搬运。" % [supply_order.get("name", "补给舱"), _supply_cargo_summary(), pos.x, pos.y]
	if not supply_order.is_empty():
		var eta: int = max(0, int(supply_order["arrival_day"]) - day)
		return "补给状态：%s 在途\nETA：%d 天（第 %d 天抵达）" % [supply_order["name"], eta, supply_order["arrival_day"]]
	if day >= next_supply_request_day:
		return "补给状态：可申请\n前往降落区按 E 提交货单。"
	return "补给状态：等待通信窗口\n下一次申请：第 %d 天" % next_supply_request_day

func add_log(text: String) -> void:
	log_lines.append("D%d  %s" % [day, text])
	while log_lines.size() > 12:
		log_lines.pop_front()
	if has_node("UI/Root/Log"):
		$UI/Root/Log.text = _join_strings(log_lines, "\n")

func _join_strings(values: Array, separator: String) -> String:
	var result := ""
	for i in range(values.size()):
		if i > 0:
			result += separator
		result += str(values[i])
	return result
