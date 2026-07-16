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

const IconDialogClose := preload("res://assets/ui/common/icons/add/atlas/icon_dialog_close.tres")
const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

## Schematic (not pixel-accurate) positions for the M-key map overview modal,
## normalized 0..1 within the diagram Control. Mirrors the hub's own door
## layout from _hub_area_config() (配电房 top / 宇航服整备室 left / 空气系统
## 控制室 right / 训练温室 bottom, around the central 训练中控室), plus 气闸舱
## placed near 宇航服整备室 since that's the only room it connects from.
const MAP_OVERVIEW_NODES := [
	{"area_id": "hub", "label": "训练中控室", "pos": Vector2(0.5, 0.5)},
	{"area_id": "power_distribution_room", "label": "配电房", "pos": Vector2(0.5, 0.12)},
	{"area_id": "suit_prep_room", "label": "宇航服整备室", "pos": Vector2(0.12, 0.5)},
	{"area_id": "airlock_simulation_room", "label": "气闸舱", "pos": Vector2(0.12, 0.85)},
	{"area_id": "air_system_control_room", "label": "空气系统控制室", "pos": Vector2(0.88, 0.5)},
	{"area_id": "greenhouse_room", "label": "训练温室", "pos": Vector2(0.5, 0.88)},
]
const PlayerControllerScript := preload("res://scripts/controllers/player_controller_2d.gd")
const InteractionAreaScript := preload("res://scripts/controllers/interaction_area_2d.gd")
const TrainingModuleSceneScript := preload("res://scripts/training/training_module_scene.gd")

const LOCKED_HINT := "该训练区尚未解锁。请先完成当前训练目标。"
const SUIT_REQUIRED_HINT := "该区域需要穿戴宇航服。"
const ROOM_DESIGN_SIZE := Vector2(760, 520)

class AirlockChamberRoomBlockout:
	extends Control

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#07111b"), true)
		var room := Rect2(Vector2(24, 24), size - Vector2(48, 48))
		draw_rect(room, Color("#17212b"), true)
		for x in range(int(room.position.x), int(room.end.x), 48):
			draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), Color("#2f3f4c", 0.52), 1.0)
		for y in range(int(room.position.y), int(room.end.y), 48):
			draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color("#2f3f4c", 0.52), 1.0)
		draw_rect(room, Color("#7f93a4"), false, 4.0)
		draw_rect(room.grow(-16), Color("#3a4d5a"), false, 2.0)
		draw_rect(Rect2(Vector2(room.position.x, room.position.y), Vector2(room.size.x, 30)), Color("#263543"), true)
		draw_rect(Rect2(Vector2(room.position.x, room.end.y - 30), Vector2(room.size.x, 30)), Color("#263543"), true)
		draw_rect(Rect2(Vector2(room.position.x, room.position.y), Vector2(30, room.size.y)), Color("#263543"), true)
		draw_rect(Rect2(Vector2(room.end.x - 30, room.position.y), Vector2(30, room.size.y)), Color("#263543"), true)
		draw_rect(Rect2(Vector2(room.position.x + 112, room.position.y + 124), Vector2(18, 150)), Color("#405261"), true)
		draw_rect(Rect2(Vector2(room.end.x - 130, room.position.y + 124), Vector2(18, 150)), Color("#405261"), true)
		draw_line(Vector2(room.position.x + 130, room.position.y + 270), Vector2(room.end.x - 130, room.position.y + 270), Color("#638195", 0.35), 2.0)
		for light_x in [room.position.x + 170, room.size.x * 0.5, room.end.x - 230]:
			var light_rect := Rect2(Vector2(light_x, room.position.y + 16), Vector2(86, 8))
			draw_rect(light_rect, Color("#87d9ff", 0.36), true)
			draw_rect(light_rect.grow(4), Color("#87d9ff", 0.09), true)
		draw_string(ThemeDB.fallback_font, room.position + Vector2(18, 32), "气闸舱", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#8fa3b2"))

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
var _popup: GuanghanPopupModal
var suit_status_scrim: ColorRect
var suit_status_modal: PanelContainer
var suit_status_text_label: Label
var suit_status_panel_visible := false
var map_overview_scrim: ColorRect
var map_overview_modal: PanelContainer
var map_overview_diagram: Control
var map_overview_visible := false
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
## Always-visible transient message strip (locked-door hints, unlock
## notices, suit warnings). hint_label/log_label live inside left_panel,
## which is hidden unless the Tab mission panel is open -- messages written
## only there were invisible during normal play (user-reported: clicking
## 确认穿戴 seemed to do nothing because the failure message went to the
## hidden panel).
var toast_label: Label
var toast_timer := 0.0
var player_speed := 280.0
var player_controller: RefCounted
var show_trigger_debug := false

# -- Multi-area state --
var areas: Dictionary = {}
var current_area_id := "hub"
var module_data: Dictionary = {}
var step_index := 0
var completed := false
var last_training_area_size := Vector2.ZERO
var training_door_spawn_points: Dictionary = {}

func _ready() -> void:
	_ensure_input_actions()
	_release_stale_movement_input()
	areas = _build_all_areas()
	_route_initial_area()
	_register_training_doors()
	_build_screen()
	_load_area(current_area_id, module_data.get("player_start", Vector2(350, 320)))
	_update_hud()
	_sync_overlay_visibility()

## Choice/confirm modal open? Gameplay (movement, E-interact, door
## crossings) must pause while one is up -- otherwise the player can walk
## around underneath the dialog and even wander through an open door
## mid-choice, leaving the modal orphaned over a different room
## (user-reported as the pressure dialog "closing" confusingly after a
## wrong choice).
func _gameplay_modal_open() -> bool:
	return (_popup != null and _popup.is_open()) or suit_status_panel_visible

func _process(delta: float) -> void:
	_rebuild_room_if_resized()
	_update_toast(delta)
	if briefing_visible or pause_visible or interaction_running or map_overview_visible or _gameplay_modal_open():
		_update_room_prompt()
		return
	_move_player(delta)
	if not completed:
		_check_wait_step(delta)
		_check_auto_steps()
	_check_door_crossing()
	_update_room_prompt()

func _show_toast(message: String, duration: float = 3.5) -> void:
	if toast_label == null:
		return
	toast_label.text = message
	toast_label.visible = true
	toast_timer = duration

func _update_toast(delta: float) -> void:
	if toast_label == null or not toast_label.visible:
		return
	toast_timer -= delta
	if toast_timer <= 0.0:
		toast_label.visible = false

## Tab (mission_panel) is intercepted in _input(), NOT _unhandled_input():
## Tab doubles as Godot's built-in ui_focus_next action, so if any visible
## Button ever holds keyboard focus (e.g. the footer's 保存训练进度 after a
## mouse click), the GUI layer consumes Tab for focus traversal before
## _unhandled_input would see it -- user-reported as "Tab 无法呼出，焦点在
## 保存训练进度和返回主菜单之间切换". _input() runs before GUI handling, so
## marking the event handled here wins regardless of focus state. (All
## buttons in this scene are also FOCUS_NONE now, belt and suspenders --
## focus on a button would additionally make Enter, which doubles as the
## "interact" action, trigger that button.)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mission_panel"):
		_toggle_mission_panel()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("show_map"):
		_toggle_map_overview()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not briefing_visible and not pause_visible and not interaction_running and not map_overview_visible and not _gameplay_modal_open():
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
	if not InputMap.has_action("show_map"):
		InputMap.add_action("show_map")
		var map_event := InputEventKey.new()
		map_event.physical_keycode = KEY_M
		InputMap.action_add_event("show_map", map_event)

## Same rationale as training_module_scene.gd's own copy of this function:
## Godot's input action "pressed" state is global, not per-scene, so a key
## held down when this scene loads (e.g. Enter on the previous screen's
## button) can otherwise read as a stuck movement/interact input.
func _release_stale_movement_input() -> void:
	for action in ["ui_up", "ui_down", "ui_left", "ui_right", "interact", "mission_panel", "show_map", "ui_cancel", "ui_accept"]:
		if InputMap.has_action(action):
			Input.action_release(action)

## -- Area data / routing --

func _build_all_areas() -> Dictionary:
	var progress := TrainingManagerScript.read_progress()
	var built := {
		"hub": _hub_area_config(),
		"suit_prep_room": _suit_prep_area_config(),
		"airlock_simulation_room": _airlock_chamber_area_config(),
		"power_distribution_room": _power_distribution_area_config(),
		"air_system_control_room": _air_system_area_config(),
		"greenhouse_room": _greenhouse_area_config(),
	}
	for area_id in built.keys():
		var area: Dictionary = built[area_id]
		area["state"] = {}
		area["step_index"] = 0
		area["unlocked"] = _compute_unlocked(area_id, progress)
		# Rooms whose module was already completed (this session or a prior
		# save) start with their step list exhausted -- otherwise a returning
		# player would be asked to redo the task, and steps with one-shot
		# side effects (e.g. wear_suit_confirm when the suit is already worn)
		# would just fail. Mid-room partial progress is deliberately NOT
		# persisted; rooms are short enough that restarting an incomplete
		# room's steps from zero is fine.
		if _module_completed(String(area.get("module_id", "")), progress):
			area["step_index"] = (area.get("steps", []) as Array).size()
	return built

func _module_completed(module_id: String, progress: Dictionary) -> bool:
	match module_id:
		"suit_control":
			return bool(progress.get("SuitControlCompleted", false))
		"airlock_procedure":
			return bool(progress.get("AirlockProcedureCompleted", false))
		"power_distribution":
			return bool(progress.get("PowerDistributionCompleted", false))
		"life_support":
			return bool(progress.get("LifeSupportCompleted", false))
		"plant_diagnosis":
			return bool(progress.get("PlantDiagnosisCompleted", false))
	return false

## Door lock state is derived every time this scene loads from
## TrainingManager's existing 6 completion flags -- no new persisted schema,
## matching the same "scene-local derived cache, TrainingManager stays the
## single source of truth" pattern already used elsewhere in this project
## (e.g. sprint06_base_scene.gd's GreenhouseDoor reading a state flag).
func _compute_unlocked(area_id: String, progress: Dictionary) -> bool:
	var current_module := String(progress.get("CurrentTrainingModule", ""))
	match area_id:
		"hub", "suit_prep_room":
			return true
		"airlock_simulation_room":
			return bool(progress.get("SuitControlCompleted", false))
		"power_distribution_room":
			return bool(progress.get("PowerRepairCompleted", false)) or _module_order_at_or_after(current_module, "power_distribution")
		"air_system_control_room":
			return bool(progress.get("PowerDistributionCompleted", false)) or _module_order_at_or_after(current_module, "life_support")
		"greenhouse_room":
			return bool(progress.get("LifeSupportCompleted", false)) or _module_order_at_or_after(current_module, "plant_diagnosis")
	return false

func _register_training_doors() -> void:
	var door_manager: Node = _door_state_manager()
	if door_manager == null or not door_manager.has_method("register_door"):
		return
	training_door_spawn_points.clear()
	for area_key in areas.keys():
		var source_area_id := String(area_key)
		var area: Dictionary = areas.get(source_area_id, {})
		var targets: Array = area.get("targets", [])
		for target_value in targets:
			if typeof(target_value) != TYPE_DICTIONARY:
				continue
			var target: Dictionary = target_value
			if not target.has("door_to"):
				continue
			var target_area_id := String(target.get("door_to", ""))
			if target_area_id.is_empty():
				continue
			var door_id := _training_door_id_for_target(source_area_id, target)
			var spawn_id := _training_spawn_id_for_target(source_area_id, target)
			training_door_spawn_points[spawn_id] = _training_spawn_from_target(target)
			door_manager.call("register_door", {
				"door_id": door_id,
				"door_name": String(target.get("label", door_id)),
				"door_type_id": _training_door_type_id_for_target(target),
				"area_a": source_area_id,
				"area_b": target_area_id,
				"spawn_from_a_to_b": spawn_id,
				"spawn_from_b_to_a": "",
				"is_open": false,
				"is_locked": _training_target_area_locked(target_area_id),
				"is_powered": true,
				"is_sealed": true,
				"is_docking_connected": true,
			})

func _door_state_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("DoorStateManager")

func _training_door_id_for_target(source_area_id: String, target: Dictionary) -> String:
	var explicit_id := String(target.get("door_id", ""))
	if not explicit_id.is_empty():
		return explicit_id
	return "door_training_%s_%s" % [source_area_id, String(target.get("id", "door"))]

func _training_spawn_id_for_target(source_area_id: String, target: Dictionary) -> String:
	var explicit_id := String(target.get("target_spawn_id", ""))
	if not explicit_id.is_empty():
		return explicit_id
	return "spawn_training_%s_to_%s_%s" % [
		source_area_id,
		String(target.get("door_to", "unknown")),
		String(target.get("id", "door")),
	]

func _training_spawn_from_target(target: Dictionary) -> Vector2:
	var spawn_value: Variant = target.get("door_spawn", Vector2(350, 320))
	var spawn_point: Vector2 = Vector2(350, 320)
	if spawn_value is Vector2:
		spawn_point = spawn_value as Vector2
	return spawn_point

func _training_door_type_id_for_target(target: Dictionary) -> String:
	var explicit_type := String(target.get("door_type_id", ""))
	if not explicit_type.is_empty():
		return explicit_type
	var target_id := String(target.get("id", ""))
	var target_label := String(target.get("label", ""))
	var target_area_id := String(target.get("door_to", ""))
	if target_id.contains("outer"):
		return "airlock_outer_door"
	if target_id.contains("inner") or target_id.contains("airlock") or target_area_id == "airlock_simulation_room":
		return "airlock_inner_door"
	if target_area_id == "greenhouse_room" or target_label.contains("温室"):
		return "greenhouse_hatch"
	return "indoor_sliding_door"

func _training_target_area_locked(target_area_id: String) -> bool:
	var area: Dictionary = areas.get(target_area_id, {})
	if area.is_empty():
		return true
	return not bool(area.get("unlocked", false))

func _sync_training_door_locks() -> void:
	var door_manager: Node = _door_state_manager()
	if door_manager == null or not door_manager.has_method("set_door_locked"):
		return
	for area_key in areas.keys():
		var source_area_id := String(area_key)
		var area: Dictionary = areas.get(source_area_id, {})
		var targets: Array = area.get("targets", [])
		for target_value in targets:
			if typeof(target_value) != TYPE_DICTIONARY:
				continue
			var target: Dictionary = target_value
			if not target.has("door_to"):
				continue
			var door_id := _training_door_id_for_target(source_area_id, target)
			var target_area_id := String(target.get("door_to", ""))
			door_manager.call("set_door_locked", door_id, _training_target_area_locked(target_area_id))

func _module_order_at_or_after(current_module: String, expected_module: String) -> bool:
	var order := ["suit_control", "airlock_procedure", "power_repair", "power_distribution", "life_support", "plant_diagnosis", "final_assessment", "mission_assignment"]
	var current_index := order.find(current_module)
	var expected_index := order.find(expected_module)
	return current_index >= 0 and expected_index >= 0 and current_index >= expected_index

## Decides which room to open the hub scene into. Two genuinely-external
## arrivals reach this scene: (1) fresh from TrainingStartScene at the very
## beginning, and (2) returning from SolarArrayTrainingField.tscn once
## training 03 is complete -- the player must walk back through the airlock,
## per the spec ("训练03完成后，玩家需要通过气闸返回室内"), so that specific case
## spawns in the airlock, not directly in the next task room, and fires the
## one-time "太阳能阵列基础输出已恢复" toast. Dev-menu jumps reuse the same
## CurrentTrainingModule-based routing for tester convenience.
func _route_initial_area() -> void:
	var progress := TrainingManagerScript.read_progress()
	var power_repair_done := bool(progress.get("PowerRepairCompleted", false))
	var toast_shown := bool(progress.get("PowerRepairUnlockToastShown", false))
	if power_repair_done and not toast_shown:
		current_area_id = "airlock_simulation_room"
		_apply_airlock_return_flow()
		call_deferred("_notify", "太阳能阵列基础输出已恢复。请按气闸规程返回舱内。")
		return
	match String(progress.get("CurrentTrainingModule", "suit_control")):
		"suit_control":
			current_area_id = "hub"
		"airlock_procedure":
			current_area_id = "airlock_simulation_room"
		"power_distribution":
			# Saved after the EVA return but before racking the suit? Send them
			# back to the suit prep room to return it first (re-arm the gate).
			var resume_suit_manager := _suit_manager()
			if resume_suit_manager != null and bool(resume_suit_manager.get("is_suit_worn")):
				current_area_id = "suit_prep_room"
				var prep_state: Dictionary = areas["suit_prep_room"].get("state", {})
				prep_state["SuitReturnPending"] = true
				areas["suit_prep_room"]["state"] = prep_state
			else:
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

func _apply_airlock_return_flow() -> void:
	var area: Dictionary = areas.get("airlock_simulation_room", {})
	area["module_id"] = "airlock_return"
	area["player_start"] = Vector2(170, 300)
	area["hud"] = "气闸舱：关闭外舱门，执行增压后返回训练中控室。"
	area["state"] = {}
	area["step_index"] = 0
	area["steps"] = _airlock_return_steps()
	# In the return flow the inner door must stay sealed until the
	# repressurization procedure completes (its final E-interact step does
	# the room switch itself) -- strip the walk-through passage the outbound
	# config puts on it.
	for target: Dictionary in area.get("targets", []):
		if String(target.get("id", "")) == "inner_door":
			target.erase("door_to")
	areas["airlock_simulation_room"] = area

func _restore_airlock_inner_door_walkthrough() -> void:
	var area: Dictionary = areas.get("airlock_simulation_room", {})
	var state: Dictionary = area.get("state", {})
	state["InnerDoorClosed"] = false
	state["InnerDoorUnlocked"] = true
	state["InnerDoorOpenedAfterEva"] = true
	area["state"] = state
	for target: Dictionary in area.get("targets", []):
		if String(target.get("id", "")) == "inner_door":
			target["door_to"] = "suit_prep_room"
			target["door_spawn"] = Vector2(90, 300)
			target["door_press"] = "ui_right"
			target["door_blocked_by_state"] = "InnerDoorClosed"
	areas["airlock_simulation_room"] = area

func _airlock_return_steps() -> Array:
	return [
		{"type": "interact", "target": "outer_door", "objective": "关闭外舱门", "line": "外舱门已关闭。", "state_key": "OuterDoorClosedAfterEva"},
		{"type": "pressure_choice", "target": "console", "objective": "执行气闸舱压力恢复", "line": "舱压恢复完成。\n舱压状态：稳定。", "options": ["充压", "降压"], "correct": "充压", "wrong_hint": "内舱门仍处于安全互锁状态。\n请根据当前所在环境与目标舱段的压力差重新判断操作。", "wrong_closes_modal": true, "wrong_center_text": "请重新判断：充压 或 降压", "wrong_time_minutes": 15, "wrong_time_reason": "training_airlock_pressure_wrong", "modal_text": "舱压控制台\n\n外舱门：关闭\n内舱门：安全互锁\n目标舱段：常压训练区\n\n请选择舱压操作。", "feedback_text": "压力恢复中", "time_minutes": 15, "time_reason": "training_airlock_pressurize", "state_updates": {"PressureStable": true, "InnerDoorUnlocked": true, "PressureStatus": "稳定", "AirlockPressureState": "充压"}, "requires": {"OuterDoorClosedAfterEva": true}, "blocked_hint": "请先关闭外舱门。"},
		{"type": "interact", "target": "inner_door", "objective": "打开内舱门", "line": "内舱门已解锁。\n返舱气闸流程完成。", "state_key": "InnerDoorOpenedAfterEva", "requires": {"PressureStable": true, "AirlockPressureState": "充压"}, "blocked_hint": "内舱门需在充压状态下开启。请先在舱压控制台执行充压。", "on_complete": "airlock_return"},
	]

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
		"blockout": "TrainingHubBlockout",
		"player_start": Vector2(350, 330),
		"hud": "训练中控室：室内枢纽\n连接宇航服整备室 / 配电房 / 空气系统控制室 / 训练温室。",
		"targets": [
			{"id": "terminal", "kind": "terminal", "label": "训练状态终端", "position": Vector2(330, 210), "size": Vector2(100, 80), "info": true, "prop_scene_path": "res://scenes/props/training/HubConsole.tscn"},
			{"id": "door_suit", "kind": "door", "label": "宇航服整备室", "position": Vector2(30, 210), "size": Vector2(64, 140), "door_to": "suit_prep_room", "door_spawn": Vector2(560, 300), "prop_scene_path": "res://scenes/props/training/HubDoorVertical.tscn"},
			{"id": "door_power", "kind": "door", "label": "配电房", "position": Vector2(326, 18), "size": Vector2(108, 96), "door_to": "power_distribution_room", "door_spawn": Vector2(350, 340), "prop_scene_path": "res://scenes/props/training/HubDoorHorizontal.tscn"},
			{"id": "door_air", "kind": "door", "label": "空气系统控制室", "position": Vector2(666, 210), "size": Vector2(64, 140), "door_to": "air_system_control_room", "door_spawn": Vector2(120, 300), "prop_scene_path": "res://scenes/props/training/HubDoorVertical.tscn"},
			{"id": "door_greenhouse", "kind": "door", "label": "训练温室", "position": Vector2(330, 446), "size": Vector2(100, 54), "door_to": "greenhouse_room", "door_spawn": Vector2(350, 116), "prop_scene_path": "res://scenes/props/training/HubDoorHorizontal.tscn"},
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
		"player_start": Vector2(560, 300),
		"hud": "宇航服整备室：穿戴 / 归位。",
		"targets": [
			{"id": "door_airlock", "kind": "door", "label": "气闸舱", "position": Vector2(30, 210), "size": Vector2(64, 140), "door_to": "airlock_simulation_room", "door_spawn": Vector2(580, 300)},
			{"id": "suit_rack", "kind": "tool_station", "label": "宇航服整备架", "position": Vector2(250, 132), "size": Vector2(150, 96)},
			{"id": "suit_check_terminal", "kind": "terminal", "label": "整备状态终端", "position": Vector2(520, 126), "size": Vector2(124, 82), "info": true},
			{"id": "locker_a", "kind": "locker", "label": "备用氧气柜", "position": Vector2(130, 392), "size": Vector2(118, 62)},
			{"id": "locker_b", "kind": "locker", "label": "训练工具柜", "position": Vector2(560, 392), "size": Vector2(118, 62)},
			{"id": "door_hub", "kind": "door", "label": "训练中控室", "position": Vector2(666, 236), "size": Vector2(64, 128), "door_to": "hub", "door_spawn": Vector2(90, 300), "door_blocked_by_state": "SuitReturnPending"},
		],
		"steps": [
			{"type": "move", "target": "suit_rack", "objective": "移动到宇航服整备架", "line": "已抵达宇航服整备架。"},
			{"type": "wear_suit_confirm", "target": "suit_rack", "objective": "按 E 穿戴宇航服", "line": "宇航服已穿戴。"},
			{"type": "suit_status_panel", "target": "suit_rack", "objective": "按 Tab 查看宇航服状态面板", "line": "宇航服状态已确认。", "on_complete": "suit_control"},
		],
	}

func _airlock_chamber_area_config() -> Dictionary:
	return {
		"title": "气闸舱",
		"subtitle": "AIRLOCK CHAMBER",
		"module_id": "airlock_procedure",
		"requires_suit": true,
		"terrain_type": "indoor",
		"blockout": "AirlockChamberRoomBlockout",
		"player_start": Vector2(650, 300),
		"hud": "气闸舱：关闭内舱门，执行降压与气体回收后，从外舱门进入太阳能阵列训练场。",
		"targets": [
			{"id": "outer_door", "kind": "door", "label": "外舱门", "position": Vector2(30, 236), "size": Vector2(64, 128), "color": Color("#3d4e62")},
			{"id": "pressure_display", "kind": "status_display", "label": "舱压状态：未启动", "position": Vector2(312, 82), "size": Vector2(136, 72), "color": Color("#244563")},
			{"id": "console", "kind": "pressure_console", "label": "舱压控制台", "position": Vector2(300, 214), "size": Vector2(160, 98), "color": Color("#31536f")},
			# While the inner door hasn't been closed yet it doubles as a
			# walk-through passage back inside (user-requested UX: approach ->
			# "E 关闭内舱门" prompt appears; keep walking INTO the door ->
			# return to 训练中控室). door_press requires the player to be
			# actively pushing east into the door, so spawning next to it /
			# brushing past it never teleports by accident; door_blocked_by_state
			# seals the passage the moment the close-door step completes.
			# _apply_airlock_return_flow() strips door_to in the return flow,
			# where the inner door must stay shut until repressurization.
			{"id": "inner_door", "kind": "door", "label": "内舱门", "position": Vector2(666, 236), "size": Vector2(64, 128), "color": Color("#3d4e62"), "door_to": "suit_prep_room", "door_spawn": Vector2(90, 300), "door_blocked_by_state": "InnerDoorClosed", "door_press": "ui_right"},
		],
		"steps": [
			{"type": "interact", "target": "inner_door", "objective": "关闭内舱门", "line": "内舱门已关闭。", "state_key": "InnerDoorClosed"},
			{"type": "pressure_choice", "target": "console", "objective": "操作舱压控制台", "line": "气体回收完成。\n舱压状态：低压稳定。", "options": ["充压", "降压"], "correct": "降压", "wrong_hint": "当前目标是前往舱外环境。\n需要先执行降压与气体回收。", "wrong_closes_modal": true, "wrong_center_text": "请重新判断：充压 或 降压", "wrong_time_minutes": 15, "wrong_time_reason": "training_airlock_pressure_wrong", "time_minutes": 15, "time_reason": "training_airlock_depressurize", "state_updates": {"PressureStable": true, "OuterDoorUnlocked": true, "PressureStatus": "低压稳定", "AirlockPressureState": "低压"}, "requires": {"InnerDoorClosed": true}, "blocked_hint": "请先关闭内舱门。"},
			{"type": "interact", "target": "outer_door", "objective": "打开外舱门", "line": "外舱门已开启。\n正在进入太阳能阵列训练场。", "state_key": "OuterDoorOpen", "requires": {"InnerDoorClosed": true, "PressureStable": true, "AirlockPressureState": "低压"}, "blocked_hint": "外舱门需在低压状态下开启。请先在舱压控制台执行降压。", "on_complete": "airlock_procedure"},
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
		"hud": "当前电力：42%\n消耗速度：2.8E/小时\n充电速度：1.1E/小时\n预计充满：无法达到满电",
		"targets": [
			{"id": "door_hub", "kind": "door", "label": "训练中控室", "position": Vector2(330, 446), "size": Vector2(100, 54), "door_to": "hub", "door_spawn": Vector2(350, 116)},
			{"id": "battery_pack", "kind": "power_panel", "label": "电池组", "position": Vector2(120, 252), "size": Vector2(110, 90), "color": Color("#3b2d32")},
			{"id": "console", "kind": "power_console", "label": "配电控制台", "position": Vector2(320, 236), "size": Vector2(120, 90)},
			{"id": "power_display", "kind": "life_status", "label": "电力显示", "position": Vector2(324, 82), "size": Vector2(150, 82), "color": Color("#5a2430")},
			{"id": "light", "kind": "test_light", "label": "供电测试灯", "position": Vector2(250, 270), "size": Vector2(54, 54)},
		],
		"steps": [
			{"type": "info_confirm", "target": "console", "objective": "查看配电状态", "confirm_text": "查看电池组", "modal_text": "配电控制台\n\n控制台读数：\n当前电力：42%\n消耗速度：2.8E/小时\n充电速度：1.1E/小时\n预计充满：无法达到满电\n\n系统提示：电池组异常。\n\n请前往电池组进一步检查。", "line": "配电控制台读数：电池组异常，需前往电池组检查。", "state_updates": {"SolarInputDetected": true, "PowerStatus": "不稳定", "PowerConsoleInspected": true}},
			{"type": "power_battery_choice", "target": "battery_pack", "objective": "检查电池组", "line": "电池组接口重新固定。\n充电速度恢复到 3.4E/小时。", "options": ["更换整组电池", "清理并重新固定电池组接口", "降低配电控制台负载"], "correct": "清理并重新固定电池组接口", "wrong_hint": "读数没有改善。\n请重新核对充电速度与电池组接口状态。", "wrong_closes_modal": true, "wrong_time_minutes": 15, "wrong_time_reason": "training_battery_wrong", "state_updates": {"BatteryPackInspected": true, "PowerPanelRepaired": true, "StorageModuleConnected": true, "PowerStatus": "恢复中", "ChargeRateStable": true}, "requires": {"PowerConsoleInspected": true}, "blocked_hint": "请先在配电控制台查看供电读数。", "time_minutes": 30, "time_reason": "training_battery_pack_reseat"},
			{"type": "wait", "target": "power_display", "objective": "等待供电读数稳定", "line": "电力显示板恢复稳定。\n当前电力：43%\n消耗速度：1.2E/小时\n充电速度：3.4E/小时\n预计充满：约 18 小时。", "duration": 1.2, "state_updates": {"PowerRestored": true, "PowerStatus": "稳定", "TestLightOn": true}},
			{"type": "interact", "target": "light", "objective": "确认供电测试灯", "line": "供电测试灯已点亮。\n配电房供电恢复训练完成。", "state_key": "PowerDistributionConfirmed", "requires": {"PowerRestored": true}, "blocked_hint": "供电读数尚未稳定。", "on_complete": "power_distribution"},
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
		"player_start": Vector2(120, 300),
		"hud": "氧气状态：偏低\n温度状态：偏低\n生命支持状态：未稳定",
		"targets": [
			{"id": "door_hub", "kind": "door", "label": "训练中控室", "position": Vector2(30, 236), "size": Vector2(64, 128), "door_to": "hub", "door_spawn": Vector2(660, 300)},
			{"id": "core", "kind": "status_display", "label": "生命支持状态", "position": Vector2(318, 96), "size": Vector2(164, 72), "color": Color("#66552a")},
			{"id": "console", "kind": "life_console", "label": "生命支持控制台", "position": Vector2(340, 214), "size": Vector2(126, 88), "color": Color("#31536f")},
			{"id": "oxygen_terminal", "kind": "life_console", "label": "制氧终端", "position": Vector2(130, 248), "size": Vector2(126, 88), "color": Color("#244563")},
			{"id": "temperature_terminal", "kind": "life_console", "label": "温控终端", "position": Vector2(560, 248), "size": Vector2(126, 88), "color": Color("#244563")},
		],
		"steps": [
			{"type": "life_support_read", "target": "console", "objective": "读取生命支持数据", "confirm_text": "确认", "oxygen_value": "18.2%", "temperature_value": "15.6℃", "oxygen_doctor_hint": "过低", "temperature_doctor_hint": "过低", "line": "生命支持控制台读数：\n氧气浓度：18.2%\n舱内温度：15.6℃\n空气循环：基础运行。", "state_updates": {"LifeSupportConsoleOpened": true, "LifeSupportStatusRead": true, "OxygenStatus": "18.2%", "TemperatureStatus": "15.6℃", "LifeSupportStatus": "未稳定"}},
			{"type": "life_control", "target": "oxygen_terminal", "objective": "调整制氧终端", "line": "制氧输出已上调。\n氧气浓度回升至 20.8%。", "options": ["增加制氧", "减少制氧"], "correct": "增加制氧", "wrong_hint": "控制台读数未改善。\n请重新判断氧气浓度与安全目标的关系。", "wrong_closes_modal": true, "wrong_center_text": "呼吸越发困难", "wrong_center_color": "#ffffff", "state_updates": {"OxygenAdjusted": true, "OxygenStatus": "20.8%"}, "requires": {"LifeSupportStatusRead": true}, "blocked_hint": "请先读取生命支持控制台数据。"},
			{"type": "life_control", "target": "temperature_terminal", "objective": "调整温控终端", "line": "温控输出已上调。\n舱内温度回升至 19.2℃。", "options": ["升温", "降温"], "correct": "升温", "wrong_hint": "控制台读数未改善。\n请重新判断舱内温度与舒适训练区间的关系。", "wrong_closes_modal": true, "wrong_center_text": "越发寒冷", "wrong_center_color": "#ffffff", "state_updates": {"TemperatureAdjusted": true, "TemperatureStatus": "19.2℃"}, "requires": {"OxygenAdjusted": true}, "blocked_hint": "请先调整制氧终端。"},
			{"type": "wait", "target": "core", "objective": "等待生命支持稳定", "line": "生命支持状态：稳定。", "duration": 1.6, "state_updates": {"LifeSupportStable": true, "LifeSupportStatus": "稳定"}},
			{"type": "interact", "target": "core", "objective": "确认生命支持稳定", "line": "氧气与温度已回到可维持范围。\n训练仓空气系统恢复训练完成。", "state_key": "LifeSupportConfirmed", "requires": {"LifeSupportStable": true}, "blocked_hint": "生命支持状态尚未稳定。", "on_complete": "life_support"},
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
			{"id": "door_hub", "kind": "door", "label": "训练中控室", "position": Vector2(330, 20), "size": Vector2(100, 54), "door_to": "hub", "door_spawn": Vector2(350, 396)},
			{"id": "plant", "kind": "plant_chamber", "label": "训练植物", "position": Vector2(350, 260), "size": Vector2(96, 96), "color": Color("#2d5b3f")},
			{"id": "water_status", "kind": "life_status", "label": "水循环状态", "position": Vector2(292, 390), "size": Vector2(150, 70), "color": Color("#244563")},
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
		player.position = _room_point(spawn_point)
	if player_controller != null:
		player_controller.sync_position(player.position)
	_push_player_state_area()
	_update_hud()

## Reports the current room to PlayerStateManager (the state registry other
## systems query). All hub rooms are indoor/pressurized/with-air; the
## airlock is typed "airlock". The solar array field is a separate scene and
## reports its own (exterior) area there. PlayerStateManager never advances
## time or gates anything itself -- this is a state snapshot only.
func _push_player_state_area() -> void:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return
	var psm := tree.root.get_node_or_null("PlayerStateManager")
	if psm == null:
		return
	if psm.has_method("set_context"):
		psm.call("set_context", "training")
	if psm.has_method("set_current_area_by_values"):
		var area_type := "airlock" if current_area_id == "airlock_simulation_room" else \
			"greenhouse" if current_area_id == "greenhouse_room" else \
			"power_room" if current_area_id == "power_distribution_room" else "interior"
		psm.call("set_current_area_by_values",
			current_area_id,
			String(module_data.get("title", "")),
			area_type,
			true,   # hub rooms all have air
			true)   # and are pressurized

func _switch_room(target_area_id: String, spawn_point: Vector2) -> void:
	areas[current_area_id]["step_index"] = step_index
	areas[current_area_id]["state"] = module_data.get("state", {})
	_load_area(target_area_id, spawn_point)

func _try_enter_area(target_area_id: String, spawn_point: Vector2) -> bool:
	var area: Dictionary = areas.get(target_area_id, {})
	if area.is_empty():
		return false
	if not bool(area.get("unlocked", false)):
		hint_label.text = LOCKED_HINT
		_show_toast(LOCKED_HINT)
		return false
	if bool(area.get("requires_suit", false)):
		var suit_manager := _suit_manager()
		if suit_manager == null or not bool(suit_manager.get("is_suit_worn")):
			hint_label.text = SUIT_REQUIRED_HINT
			_show_toast(SUIT_REQUIRED_HINT)
			return false
	_switch_room(target_area_id, spawn_point)
	return true

func _try_pass_training_door(target: Dictionary) -> void:
	var target_area_id := String(target.get("door_to", ""))
	if target_area_id.is_empty():
		return
	if not _training_target_can_be_entered_now(target_area_id):
		return
	var door_manager: Node = _door_state_manager()
	if door_manager == null or not door_manager.has_method("try_pass_door"):
		_try_enter_area(target_area_id, _training_spawn_from_target(target))
		return
	var door_id := _training_door_id_for_target(current_area_id, target)
	if door_manager.has_method("set_door_locked"):
		door_manager.call("set_door_locked", door_id, _training_target_area_locked(target_area_id))
	var result_value: Variant = door_manager.call("try_pass_door", door_id, current_area_id)
	var result: Dictionary = {}
	if typeof(result_value) == TYPE_DICTIONARY:
		result = result_value as Dictionary
	if not bool(result.get("success", false)):
		var message := String(result.get("message", "舱门无法通过。"))
		hint_label.text = message
		_show_toast(message)
		return
	var resolved_area_id := String(result.get("target_area_id", target_area_id))
	var spawn_id := String(result.get("target_spawn_id", ""))
	var spawn_point := _training_spawn_from_target(target)
	if not spawn_id.is_empty() and training_door_spawn_points.has(spawn_id):
		var spawn_value: Variant = training_door_spawn_points[spawn_id]
		if spawn_value is Vector2:
			spawn_point = spawn_value as Vector2
	_try_enter_area(resolved_area_id, spawn_point)
	if door_manager.has_method("close_door_after_pass"):
		door_manager.call("close_door_after_pass", door_id)

func _training_target_can_be_entered_now(target_area_id: String) -> bool:
	var area: Dictionary = areas.get(target_area_id, {})
	if area.is_empty():
		return false
	if not bool(area.get("unlocked", false)):
		hint_label.text = LOCKED_HINT
		_show_toast(LOCKED_HINT)
		return false
	if bool(area.get("requires_suit", false)):
		var suit_manager := _suit_manager()
		if suit_manager == null or not bool(suit_manager.get("is_suit_worn")):
			hint_label.text = SUIT_REQUIRED_HINT
			_show_toast(SUIT_REQUIRED_HINT)
			return false
	return true

func _check_door_crossing() -> void:
	var state: Dictionary = module_data.get("state", {})
	for target: Dictionary in module_data.get("targets", []):
		if not target.has("door_to"):
			continue
		# Optional per-door gates (both used by the airlock's inner door):
		# door_blocked_by_state seals the passage while a state flag is true
		# (the door has been physically closed); door_press requires the
		# player to be actively pushing toward the door, so a spawn point or
		# task target overlapping the door rect can't trigger an accidental
		# crossing.
		var blocked_key := String(target.get("door_blocked_by_state", ""))
		if not blocked_key.is_empty() and bool(state.get(blocked_key, false)):
			continue
		var press_action := String(target.get("door_press", ""))
		if not press_action.is_empty() and not Input.is_action_pressed(press_action):
			continue
		if _is_inside_target_area(String(target["id"])):
			_try_pass_training_door(target)
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
	if _try_interact_suit_wear_fallback():
		return
	var step := _current_step()
	if step.is_empty():
		return
	var step_type := String(step.get("type", "interact"))
	if step_type == "diagnosis":
		_show_toast("请在诊断弹窗中选择诊断结果。")
		return
	if step_type == "suit_status_panel":
		_show_toast("请按 Tab 查看宇航服状态面板。")
		return
	var target := String(step.get("target", ""))
	if step_type == "move":
		if _is_inside_target_area(target):
			_complete_step()
		else:
			_show_toast(String(step.get("hint", "请移动至目标区域。")))
		return
	if not _is_near(target):
		# Pressing E on a target the current step doesn't point at gave no
		# visible feedback at all (hint_label lives in the hidden Tab panel)
		# -- user-reported as "外舱门无法打开" after a wrong 舱压 choice left
		# the console step still pending. Give a contextual explanation when
		# the player is at a recognizable flow-locked target, else the
		# generic move-first message.
		var wrong_order := _wrong_order_toast()
		hint_label.text = wrong_order if not wrong_order.is_empty() else "请先移动至目标区域。"
		_show_toast(hint_label.text)
		return
	if _blocked_by_order(step):
		hint_label.text = String(step.get("blocked_hint", "流程顺序错误。请按当前目标执行。"))
		_show_toast(hint_label.text)
		return
	if step_type == "plant_control":
		_show_plant_control_options(step.get("options", []), String(step.get("correct", "")))
		return
	if step_type == "pressure_choice":
		_show_pressure_control_options(step.get("options", []), String(step.get("correct", "")))
		return
	if step_type == "life_control":
		_show_life_control_options(step.get("options", []), String(step.get("correct", "")))
		return
	if step_type == "power_battery_choice":
		_show_power_battery_options(step.get("options", []), String(step.get("correct", "")))
		return
	if step_type == "wear_suit_confirm":
		_show_wear_suit_confirm_dialog()
		return
	if step_type == "info_confirm":
		_show_info_confirm_modal(step)
		return
	if step_type == "life_support_read":
		_show_life_support_read_modal(step)
		return
	_begin_step_interaction_feedback(step)

## Contextual explanation for pressing E at a target that isn't the current
## step's -- mirrors training_module_scene.gd's _wrong_order_hint() idea,
## scoped to the airlock room where the sequencing confusion actually bites
## (user tried the outer door while the console step was still pending).
func _wrong_order_toast() -> String:
	if current_area_id != "airlock_simulation_room":
		return ""
	var state: Dictionary = module_data.get("state", {})
	if target_nodes.has("outer_door") and _is_near("outer_door"):
		if not bool(state.get("InnerDoorClosed", false)) and String(module_data.get("module_id", "")) != "airlock_return":
			return "流程顺序错误。请先关闭内舱门。"
		if not bool(state.get("PressureStable", false)):
			return "舱压尚未处理完成。外舱门保持锁定。请先操作舱压控制台。"
	if target_nodes.has("console") and _is_near("console") and not bool(state.get("InnerDoorClosed", false)) and String(module_data.get("module_id", "")) != "airlock_return":
		return "流程顺序错误。请先关闭内舱门。"
	return ""

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
	# Post-EVA suit return: available once the solar-array (power_repair) EVA
	# is done and the player is back at the rack still wearing the suit. This
	# replaces the old "all six modules done" gate -- the suit now comes off
	# right after coming back inside, not at the very end of training.
	if not bool(TrainingManagerScript.read_progress().get("PowerRepairCompleted", false)):
		return false
	if not _is_near("suit_rack"):
		return false
	var suit_manager := _suit_manager()
	if suit_manager == null or not bool(suit_manager.get("is_suit_worn")):
		return false
	_show_return_suit_confirm_dialog()
	return true

## Soft-lock guard: if suit_control's steps are already exhausted (module
## completed, this session or restored from save) but the suit ISN'T worn --
## e.g. an odd/edited save, or the player somehow took it off -- the normal
## step flow would never offer the wear dialog again, and the airlock's
## requires_suit gate would then block training 02/03 forever. Re-offer the
## wear dialog at the rack in that state. _complete_step() no-ops safely on
## an exhausted step list, so reusing the same dialog is fine.
func _try_interact_suit_wear_fallback() -> bool:
	if current_area_id != "suit_prep_room":
		return false
	if not _current_step().is_empty():
		return false
	# Only re-offer the wear dialog BEFORE the EVA (the suit is only needed to
	# pass the airlock out to the solar array). Once power_repair is done the
	# suit's job is over, so a stray "not worn" state here must not re-arm it
	# (otherwise the post-EVA return would immediately offer to put it back on).
	if bool(TrainingManagerScript.read_progress().get("PowerRepairCompleted", false)):
		return false
	if not _is_near("suit_rack"):
		return false
	var suit_manager := _suit_manager()
	if suit_manager == null or bool(suit_manager.get("is_suit_worn")):
		return false
	_show_wear_suit_confirm_dialog()
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
	_add_log(_step_line_with_professional_hint(step))
	step_index += 1
	areas[current_area_id]["step_index"] = step_index
	wait_timer = 0.0
	if String(step.get("type", "")) in ["diagnosis", "plant_control", "pressure_choice", "life_control", "power_battery_choice", "info_confirm", "life_support_read"]:
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
			_notify("气闸舱已解锁。")
		"airlock_procedure":
			TrainingManagerScript.mark_module_completed("airlock_procedure", "power_repair")
			TrainingManagerScript.set_current_module("power_repair")
			get_tree().change_scene_to_file(TrainingManagerScript.MODULE_03)
			return
		"airlock_return":
			var progress := TrainingManagerScript.read_progress()
			progress["PowerRepairCompleted"] = true
			progress["PowerRepairUnlockToastShown"] = true
			progress["CurrentTrainingModule"] = "power_distribution"
			progress["CurrentSceneAfterTraining"] = TrainingManagerScript.TRAINING_BASE_MAP
			TrainingManagerScript.save_progress(progress)
			areas["power_distribution_room"]["unlocked"] = true
			_restore_airlock_inner_door_walkthrough()
			_register_training_doors()
			_sync_training_door_locks()
			# The suit now comes off HERE, right after the EVA return, instead
			# of at the very end of training. Arm the suit-return gate: the suit
			# prep room's hub door stays sealed until the suit is racked.
			var prep_state: Dictionary = areas["suit_prep_room"].get("state", {})
			prep_state["SuitReturnPending"] = true
			areas["suit_prep_room"]["state"] = prep_state
			_notify("气闸返回流程完成。请将宇航服脱下并放回宇航服整备架。")
			_switch_room("suit_prep_room", Vector2(90, 300))
			return
		"power_distribution":
			TrainingManagerScript.mark_module_completed("power_distribution", "life_support")
			areas["air_system_control_room"]["unlocked"] = true
			_notify("供电系统已恢复。空气系统控制室已解锁。")
		"life_support":
			TrainingManagerScript.mark_module_completed("life_support", "plant_diagnosis")
			areas["greenhouse_room"]["unlocked"] = true
			_notify("训练仓空气系统已恢复。训练温室已解锁。")
		"plant_diagnosis":
			# Training ENDS here now. The suit was already returned right after
			# the EVA, so there is no closing suit-return leg -- go straight to
			# the mission assignment notice.
			TrainingManagerScript.mark_module_completed("plant_diagnosis", "final_assessment")
			_notify("训练科目已全部完成。")
			_complete_training_and_show_assignment_notice()
			return
	_sync_training_door_locks()
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
	if step_type == "plant_control" or step_type == "pressure_choice" or step_type == "life_control" or step_type == "power_battery_choice":
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

func _academic_background_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("AcademicBackgroundManager")

func _penalty_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PenaltyManager")

func _task_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TaskManager")

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
	var progress := TrainingManagerScript.read_progress()
	# Post-EVA suit-return interstitial depends on the runtime suit-worn state
	# (not a persisted module flag), so it stays a scene-specific step rather
	# than a catalogued task. It slots in right after the power_repair EVA.
	if bool(progress.get("PowerRepairCompleted", false)):
		var suit_manager := _suit_manager()
		if suit_manager != null and bool(suit_manager.get("is_suit_worn")):
			return "返回宇航服整备室，将宇航服脱下并放回宇航服整备架。"
	# The module objectives come from the unified TaskManager -- a single query
	# point, derived from these same TrainingManager flags (no second truth).
	var task_manager := _task_manager()
	if task_manager != null and task_manager.has_method("get_current_objective"):
		return String(task_manager.call("get_current_objective", "training"))
	# Fallback (TaskManager absent): original per-flag derivation.
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
	return "训练科目已全部完成。"

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
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.pressed.connect(func():
		var suit_manager := _suit_manager()
		var success := false
		if suit_manager != null and suit_manager.has_method("wear_suit_training"):
			success = suit_manager.call("wear_suit_training")
		_hide_training_diagnosis_modal()
		if success:
			_notify("宇航服已穿戴。")
			_complete_step()
		else:
			hint_label.text = "宇航服当前无法穿戴。"
			_show_toast("宇航服当前无法穿戴。请检查宇航服是否已在维护位就绪。")
	)
	_popup.add_action_control(confirm)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(0, 42)
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.pressed.connect(func():
		hint_label.text = "已取消穿戴。"
		_hide_training_diagnosis_modal()
	)
	_popup.add_action_control(cancel)
	_sync_overlay_visibility()

func _show_return_suit_confirm_dialog() -> void:
	_open_diagnosis_modal("宇航服归位\n\n脱下宇航服并放回维护位。\n维护系统将恢复宇航服氧气、电力与状态。\n\n训练模式下无需等待完整维护流程。\n是否确认？")
	var confirm := Button.new()
	confirm.text = "确认归位"
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.pressed.connect(func():
		var suit_manager := _suit_manager()
		var success := false
		if suit_manager != null and suit_manager.has_method("remove_suit_to_service_station_training"):
			success = suit_manager.call("remove_suit_to_service_station_training")
		_hide_training_diagnosis_modal()
		if success:
			# Post-EVA return: take the suit off and unseal the hub door.
			# Training CONTINUES (配电房 is next) -- it no longer ends here.
			if areas.has("suit_prep_room"):
				var prep_state: Dictionary = areas["suit_prep_room"].get("state", {})
				prep_state["SuitReturnPending"] = false
				areas["suit_prep_room"]["state"] = prep_state
			if current_area_id == "suit_prep_room":
				module_data["state"]["SuitReturnPending"] = false
			_notify("宇航服已归位。请前往配电房，恢复供电。")
			_update_hud()
		else:
			hint_label.text = "宇航服当前无法归位。"
			_show_toast("宇航服当前无法归位。")
	)
	_popup.add_action_control(confirm)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(0, 42)
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.pressed.connect(func():
		hint_label.text = "已取消宇航服归位。"
		_hide_training_diagnosis_modal()
	)
	_popup.add_action_control(cancel)
	_sync_overlay_visibility()

func _complete_training_and_show_assignment_notice() -> void:
	TrainingManagerScript.mark_module_completed("final_assessment", "mission_assignment")
	get_tree().change_scene_to_file(TrainingManagerScript.MISSION_NOTICE)

func _show_diagnosis_options(options: Array, correct: String) -> void:
	_open_diagnosis_modal("传感器读数\n补光输出：低于维持阈值\n水循环：最低运行\n根区温度：正常\n生命信号：弱\n\n请选择诊断结论。")
	for option in options:
		var button := Button.new()
		button.text = String(option)
		button.custom_minimum_size = Vector2(0, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func():
			if button.text == correct:
				_hide_training_diagnosis_modal()
				_complete_step()
			else:
				_handle_wrong_choice(_current_step())
		)
		_popup.add_action_control(button)

func _show_plant_control_options(options: Array, correct: String) -> void:
	_open_diagnosis_modal("植物控制台\n\n根据植物舱诊断结果选择一项维护动作。\n\n可用操作\n调节温度：用于根区温度异常。\n浇水：用于水分不足。\n补光：用于光照不足。")
	for option in options:
		var button := Button.new()
		button.text = String(option)
		button.custom_minimum_size = Vector2(0, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func():
			if button.text == correct:
				_hide_training_diagnosis_modal()
				_complete_step()
			else:
				_handle_wrong_choice(_current_step())
		)
		_popup.add_action_control(button)

func _show_life_control_options(options: Array, correct: String) -> void:
	var step := _current_step()
	var text := String(step.get("modal_text", "生命支持调节终端\n\n根据控制台读数选择一项调整动作。"))
	_open_diagnosis_modal(text)
	for option in options:
		var button := Button.new()
		button.text = String(option)
		button.custom_minimum_size = Vector2(0, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func():
			if button.text == correct:
				_hide_training_diagnosis_modal()
				_complete_step()
			else:
				_handle_wrong_choice(_current_step())
		)
		_popup.add_action_control(button)

func _show_power_battery_options(options: Array, correct: String) -> void:
	var text := "电池组检查\n\n控制台记录：\n当前电力：42%\n消耗速度：2.8E/小时\n充电速度：1.1E/小时\n预计充满：无法达到满电\n\n现场观察：\n电池组外壳完整；接口附近有月尘附着；主线负载未见突增。\n\n请选择处理方向。"
	if _has_academic_background_tag("materials"):
		text += "\n\n材料科学提示：\n外壳没有裂纹，异常更像接口接触不良。\n应选择『清理并重新固定电池组接口』。"
	else:
		text += "\n\n提示：\n外壳完整、主线负载正常，异常集中在接口月尘附着。\n应选择『清理并重新固定电池组接口』。"
	_open_diagnosis_modal(text)
	for option in options:
		var button := Button.new()
		button.text = String(option)
		button.custom_minimum_size = Vector2(0, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func():
			if button.text == correct:
				_hide_training_diagnosis_modal()
				_complete_step()
			else:
				_handle_wrong_choice(_current_step())
		)
		_popup.add_action_control(button)

func _show_pressure_control_options(options: Array, correct: String) -> void:
	var step := _current_step()
	var text := String(step.get("modal_text", "舱压控制台\n\n当前流程：舱外训练准备。\n请选择舱压操作。"))
	var professional_hint := _airlock_pressure_professional_hint()
	if not professional_hint.is_empty():
		text += "\n\n" + professional_hint
	_open_diagnosis_modal(text)
	for option in options:
		var button := Button.new()
		button.text = String(option)
		button.custom_minimum_size = Vector2(0, 42)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func():
			if button.text == correct:
				_confirm_pressure_choice()
			else:
				_handle_wrong_choice(_current_step())
		)
		_popup.add_action_control(button)

func _confirm_pressure_choice() -> void:
	var step := _current_step()
	var feedback_text := String(step.get("feedback_text", "气体回收中"))
	_hide_training_diagnosis_modal()
	await _show_fading_center_notice(feedback_text)
	_complete_step()

func _show_fading_center_notice(text: String, base_color: Color = Color("#9fd7ff")) -> void:
	var notice := Label.new()
	notice.text = text
	notice.modulate = Color(base_color.r, base_color.g, base_color.b, 1.0)
	notice.add_theme_font_size_override("font_size", 24)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.set_anchors_preset(Control.PRESET_CENTER)
	notice.offset_left = -180
	notice.offset_top = -30
	notice.offset_right = 180
	notice.offset_bottom = 30
	add_child(notice)
	var elapsed := 0.0
	var duration := 1.8
	while elapsed < duration:
		await get_tree().process_frame
		var delta := get_process_delta_time()
		elapsed += delta
		notice.modulate.a = clamp(1.0 - elapsed / duration, 0.0, 1.0)
	notice.queue_free()

## Unified wrong-choice handler for the option modals. Default behaviour
## (no wrong_closes_modal flag) keeps the original in-modal "［操作反馈］"
## feedback (植物诊断 / 诊断结论 still work this way). Steps that opt in with
## wrong_closes_modal=true instead: close the modal, optionally burn training
## minutes as a penalty, optionally show a fading centered notice, and leave
## step_index unchanged so the player has to walk back and re-interact.
func _handle_wrong_choice(step: Dictionary) -> void:
	if not bool(step.get("wrong_closes_modal", false)):
		_show_modal_wrong_feedback(String(step.get("wrong_hint", "操作不匹配。请重新判断。")))
		return
	_hide_training_diagnosis_modal()
	var hint := String(step.get("wrong_hint", ""))
	if not hint.is_empty():
		hint_label.text = hint
		_show_toast(hint)
	var penalty := int(step.get("wrong_time_minutes", 0))
	if penalty > 0:
		var reason := String(step.get("wrong_time_reason", "training_wrong_choice"))
		# Route the time penalty through the central PenaltyManager (silent --
		# the training map already shows its own center notice + toast, so we
		# don't want a second penalty notice). Fall back to a direct training-
		# clock advance if the penalty system isn't present.
		var penalty_manager := _penalty_manager()
		if penalty_manager != null and penalty_manager.has_method("apply_penalty"):
			penalty_manager.call("apply_penalty", {
				"penalty_id": String(step.get("wrong_penalty_id", "training_wrong_choice")),
				"display_name": "训练操作失误",
				"context": "training",
				"reason": reason,
				"time_minutes": penalty,
				"silent": true,
			})
		else:
			var manager := _training_time_manager()
			if manager != null and manager.has_method("advance_training_time"):
				manager.call("advance_training_time", penalty, reason)
		_update_hud()
	var center_text := String(step.get("wrong_center_text", ""))
	if not center_text.is_empty():
		var color := Color(String(step.get("wrong_center_color", "#9fd7ff")))
		await _show_fading_center_notice(center_text, color)

## Generic "read a console -> modal with a single 确认 button -> complete the
## step" interaction (used by the 配电控制台 battery-abnormal notice). The
## step keeps its own state_updates; the confirm button just runs the normal
## _complete_step() so those still fire.
func _show_info_confirm_modal(step: Dictionary) -> void:
	_open_diagnosis_modal(String(step.get("modal_text", String(step.get("line", "")))))
	var confirm := Button.new()
	confirm.text = String(step.get("confirm_text", "确认"))
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.pressed.connect(func():
		_hide_training_diagnosis_modal()
		_complete_step()
	)
	_popup.add_action_control(confirm)
	_sync_overlay_visibility()

## 生命支持控制台 read-out modal: shows the concrete O2 / temperature values,
## marked either as a neutral "异常" (non-doctor) or with a doctor's 过高/过低
## read (medical background). Single 确认 button closes it and completes step.
func _show_life_support_read_modal(step: Dictionary) -> void:
	var oxygen_value := String(step.get("oxygen_value", "18.2%"))
	var temperature_value := String(step.get("temperature_value", "15.6℃"))
	var is_doctor := _has_academic_background_tag("medical")
	var oxygen_mark := String(step.get("oxygen_doctor_hint", "过低")) if is_doctor else "异常"
	var temperature_mark := String(step.get("temperature_doctor_hint", "过低")) if is_doctor else "异常"
	var text := "生命支持控制台\n\n氧气浓度：%s（%s）\n舱内温度：%s（%s）\n空气循环：基础运行\n\n请根据读数判断需要调整的方向。" % [
		oxygen_value, oxygen_mark, temperature_value, temperature_mark,
	]
	_open_diagnosis_modal(text)
	var confirm := Button.new()
	confirm.text = String(step.get("confirm_text", "确认"))
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.pressed.connect(func():
		_hide_training_diagnosis_modal()
		_complete_step()
	)
	_popup.add_action_control(confirm)
	_sync_overlay_visibility()

func _airlock_pressure_professional_hint() -> String:
	var manager := _academic_background_manager()
	if manager == null:
		return ""
	if manager.has_method("has_background_tag") and bool(manager.call("has_background_tag", "mechanical")):
		var step := _current_step()
		if String(step.get("correct", "")) == "充压":
			return "机械工程提示：\n返舱后应先关闭外舱门，再执行充压，使气闸舱恢复到可开启内舱门状态。"
		return "机械工程提示：\n前往舱外前应先执行降压，并回收舱内气体。"
	return ""

func _has_academic_background_tag(tag: String) -> bool:
	var manager := _academic_background_manager()
	if manager == null or not manager.has_method("has_background_tag"):
		return false
	return bool(manager.call("has_background_tag", tag))

func _step_line_with_professional_hint(step: Dictionary) -> String:
	var line := String(step.get("line", ""))
	var required_tag := String(step.get("professional_hint_tag", ""))
	if required_tag.is_empty():
		return line
	var professional_hint := String(step.get("professional_hint", ""))
	if professional_hint.is_empty():
		return line
	var manager := _academic_background_manager()
	if manager == null:
		return line
	if manager.has_method("has_background_tag") and bool(manager.call("has_background_tag", required_tag)):
		return line + "\n\n" + professional_hint
	return line

## Wrong-choice feedback: appended INSIDE the popup (user-reported: writing it
## to hint_label only was invisible during normal play, so a wrong 舱压 choice
## looked like the game silently ignoring the click). Delegates to the shared
## popup component, which keeps its own base-text for the "［操作反馈］" append.
func _show_modal_wrong_feedback(hint: String) -> void:
	hint_label.text = hint
	if _popup != null:
		_popup.append_feedback(hint)

func _open_diagnosis_modal(text: String) -> void:
	if diagnosis_panel != null:
		diagnosis_panel.visible = false
	if _popup != null:
		_popup.open({"text": text})

func _hide_training_diagnosis_modal() -> void:
	if _popup != null:
		_popup.close()
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
	if suit_status_panel_visible:
		_confirm_suit_status_review()
		return
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
	_confirm_suit_status_review()

func _confirm_suit_status_review() -> void:
	suit_status_panel_visible = false
	if suit_status_scrim != null:
		suit_status_scrim.visible = false
	if suit_status_modal != null:
		suit_status_modal.visible = false
	if String(_current_step().get("type", "")) == "suit_status_panel":
		_complete_step()
	else:
		_sync_overlay_visibility()

func _set_mission_panel_visible(value: bool) -> void:
	mission_panel_visible = value
	if log_label != null:
		log_label.text = "Tab：关闭任务面板\nE / Enter：与当前目标交互\nEsc：暂停"
	_sync_overlay_visibility()

func _toggle_pause_menu() -> void:
	if briefing_visible:
		_close_briefing()
		return
	if map_overview_visible:
		_set_map_overview_visible(false)
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
	var diagnosis_open := diagnosis_panel_open or (_popup != null and _popup.is_open())
	var suit_status_open := suit_status_modal != null and suit_status_modal.visible
	if briefing_scrim != null:
		briefing_scrim.visible = briefing_visible
	if briefing_modal != null:
		briefing_modal.visible = briefing_visible
	if left_panel != null:
		left_panel.visible = mission_panel_visible or diagnosis_panel_open
	if map_overview_scrim != null:
		map_overview_scrim.visible = map_overview_visible
	if map_overview_modal != null:
		map_overview_modal.visible = map_overview_visible
	if minimal_hud != null:
		minimal_hud.visible = not briefing_visible and not mission_panel_visible and not pause_visible and not map_overview_visible and not diagnosis_open and not suit_status_open
	if prompt_label != null and (briefing_visible or mission_panel_visible or pause_visible or map_overview_visible or diagnosis_open or suit_status_open):
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
	if current_area_id == "suit_prep_room" and step.is_empty() and bool(TrainingManagerScript.read_progress().get("PowerRepairCompleted", false)):
		var suit_manager := _suit_manager()
		if suit_manager != null and bool(suit_manager.get("is_suit_worn")):
			hint_label.text = "舱外维修已完成。\n请靠近宇航服整备架，按 E 归还宇航服。"
	if String(step.get("type", "")) == "diagnosis":
		_show_diagnosis_options(step.get("options", []), String(step.get("correct", "")))
	_sync_overlay_visibility()

func _add_log(line: String) -> void:
	if line.is_empty() or log_label == null:
		return
	log_label.text += line + "\n"

## Player-facing notice: both the (Tab-panel) log and the always-visible
## toast strip.
func _notify(message: String) -> void:
	_add_log(message)
	_show_toast(message)

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
	_add_button(footer, "保存训练进度", func(): TrainingManagerScript.set_current_module(_current_module_for_save()))
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
	key_hint.text = "Tab 查看任务    M 查看地图    Esc 暂停"
	key_hint.modulate = Color("#7f93a3")
	key_hint.add_theme_font_size_override("font_size", 12)
	hud_box.add_child(key_hint)

	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_label.offset_left = -420
	toast_label.offset_right = 420
	toast_label.offset_top = -96
	toast_label.offset_bottom = -48
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.modulate = Color("#f0c766")
	toast_label.add_theme_font_size_override("font_size", 18)
	toast_label.visible = false
	add_child(toast_label)

	_build_briefing_modal()
	_build_pause_panel()
	_build_interaction_panel()
	_build_diagnosis_modal()
	_build_suit_status_panel()
	_build_map_overview_modal()

func _build_briefing_modal() -> void:
	briefing_scrim = ColorRect.new()
	briefing_scrim.color = Color("#02070d", 0.78)
	briefing_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	briefing_scrim.visible = true
	add_child(briefing_scrim)

	briefing_modal = PanelContainer.new()
	briefing_modal.set_anchors_preset(Control.PRESET_CENTER)
	briefing_modal.offset_left = -400
	briefing_modal.offset_top = -260
	briefing_modal.offset_right = 400
	briefing_modal.offset_bottom = 260
	briefing_modal.visible = true
	add_child(briefing_modal)
	var modal_style := StyleBoxFlat.new()
	modal_style.bg_color = Color("#111c26")
	modal_style.border_color = Color("#2c4356")
	modal_style.set_border_width_all(1)
	modal_style.set_corner_radius_all(8)
	modal_style.content_margin_left = 28
	modal_style.content_margin_right = 28
	modal_style.content_margin_top = 22
	modal_style.content_margin_bottom = 22
	briefing_modal.add_theme_stylebox_override("panel", modal_style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	briefing_modal.add_child(box)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 14)
	box.add_child(header_row)

	var title_col := VBoxContainer.new()
	title_col.add_theme_constant_override("separation", 4)
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_row.add_child(title_col)
	var title := Label.new()
	title.text = "训练小型地图"
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 22)
	title_col.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "候选人训练基地"
	subtitle.modulate = Color("#5fa8dd")
	subtitle.add_theme_font_size_override("font_size", 15)
	title_col.add_child(subtitle)

	var close_button := Button.new()
	close_button.icon = IconDialogClose
	close_button.add_theme_constant_override("icon_max_width", 16)
	close_button.custom_minimum_size = Vector2(28, 28)
	close_button.flat = true
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	header_row.add_child(close_button)

	box.add_child(HSeparator.new())

	var info_list := VBoxContainer.new()
	info_list.add_theme_constant_override("separation", 14)
	box.add_child(info_list)
	_add_briefing_info_row(info_list, "grid", "所有训练房间围绕训练中控室展开。")
	_add_briefing_info_row(info_list, "info", "靠近目标后按 E / Enter 交互，走到门口即可进入已解锁的训练区。")
	_add_briefing_info_row(info_list, "map", "按 M 可随时查看地图。")

	box.add_child(HSeparator.new())

	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 16)
	box.add_child(footer_row)

	var cancel_button := Button.new()
	cancel_button.text = "取消"
	cancel_button.custom_minimum_size = Vector2(140, 48)
	cancel_button.focus_mode = Control.FOCUS_NONE
	cancel_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_style_briefing_button(cancel_button, false)
	footer_row.add_child(cancel_button)

	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_row.add_child(footer_spacer)

	var button := Button.new()
	button.text = "确认，开始训练"
	button.custom_minimum_size = Vector2(220, 48)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func(): _close_briefing())
	_style_briefing_button(button, true)
	footer_row.add_child(button)

	briefing_visible = true

## One icon+text row in the briefing modal's info list. `kind` selects a
## small primitive glyph (grid / info / map) built without new icon assets.
func _add_briefing_info_row(parent: VBoxContainer, kind: String, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(32, 32)
	icon_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color("#16232f")
	icon_style.border_color = Color("#33475a")
	icon_style.set_border_width_all(1)
	icon_style.set_corner_radius_all(4 if kind == "map" else 6)
	icon_frame.add_theme_stylebox_override("panel", icon_style)
	row.add_child(icon_frame)

	match kind:
		"grid":
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 3)
			grid.add_theme_constant_override("v_separation", 3)
			var grid_wrap := CenterContainer.new()
			grid_wrap.add_child(grid)
			icon_frame.add_child(grid_wrap)
			for _i in range(4):
				var cell := ColorRect.new()
				cell.custom_minimum_size = Vector2(8, 8)
				cell.color = Color("#5fa8dd")
				grid.add_child(cell)
		"info":
			var info_label := Label.new()
			info_label.text = "i"
			info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			info_label.modulate = Color("#5fa8dd")
			info_label.add_theme_font_size_override("font_size", 16)
			icon_frame.add_child(info_label)
		"map":
			var map_label := Label.new()
			map_label.text = "M"
			map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			map_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			map_label.modulate = Color("#c6d5df")
			map_label.add_theme_font_size_override("font_size", 12)
			icon_frame.add_child(map_label)

	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color("#c6d5df")
	label.add_theme_font_size_override("font_size", 16)
	row.add_child(label)

func _style_briefing_button(button: Button, primary: bool) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	if primary:
		style.bg_color = Color("#1c3a52")
		style.border_color = Color("#4f8eb8")
	else:
		style.bg_color = Color("#16232f")
		style.border_color = Color("#33475a")
	for theme_state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(theme_state, style)

## -- Map overview (M key) --

func _toggle_map_overview() -> void:
	if briefing_visible or pause_visible or interaction_running or _gameplay_modal_open():
		return
	_set_map_overview_visible(not map_overview_visible)

func _set_map_overview_visible(value: bool) -> void:
	map_overview_visible = value
	if value:
		_refresh_map_overview()
	_sync_overlay_visibility()

func _build_map_overview_modal() -> void:
	map_overview_scrim = ColorRect.new()
	map_overview_scrim.color = Color("#02070d", 0.78)
	map_overview_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_overview_scrim.visible = false
	add_child(map_overview_scrim)

	map_overview_modal = PanelContainer.new()
	map_overview_modal.set_anchors_preset(Control.PRESET_CENTER)
	map_overview_modal.offset_left = -340
	map_overview_modal.offset_top = -280
	map_overview_modal.offset_right = 340
	map_overview_modal.offset_bottom = 280
	map_overview_modal.visible = false
	add_child(map_overview_modal)
	var modal_style := StyleBoxFlat.new()
	modal_style.bg_color = Color("#111c26")
	modal_style.border_color = Color("#2c4356")
	modal_style.set_border_width_all(1)
	modal_style.set_corner_radius_all(8)
	modal_style.content_margin_left = 24
	modal_style.content_margin_right = 24
	modal_style.content_margin_top = 20
	modal_style.content_margin_bottom = 20
	map_overview_modal.add_theme_stylebox_override("panel", modal_style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	map_overview_modal.add_child(box)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	box.add_child(header_row)
	var title_col := VBoxContainer.new()
	title_col.add_theme_constant_override("separation", 2)
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title_col)
	var title := Label.new()
	title.text = "训练基地地图"
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 20)
	title_col.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "BASE MAP OVERVIEW"
	subtitle.modulate = Color("#6f8493")
	subtitle.add_theme_font_size_override("font_size", 12)
	title_col.add_child(subtitle)
	var close_button := Button.new()
	close_button.icon = IconDialogClose
	close_button.add_theme_constant_override("icon_max_width", 16)
	close_button.custom_minimum_size = Vector2(28, 28)
	close_button.flat = true
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close_button.pressed.connect(func(): _set_map_overview_visible(false))
	header_row.add_child(close_button)

	box.add_child(HSeparator.new())

	map_overview_diagram = Control.new()
	map_overview_diagram.custom_minimum_size = Vector2(0, 340)
	map_overview_diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(map_overview_diagram)

	box.add_child(HSeparator.new())

	var legend_row := HBoxContainer.new()
	legend_row.alignment = BoxContainer.ALIGNMENT_CENTER
	legend_row.add_theme_constant_override("separation", 24)
	box.add_child(legend_row)
	_add_map_legend_item(legend_row, Color("#4f8eb8"), "当前位置")
	_add_map_legend_item(legend_row, Color("#3d5266"), "已解锁")
	_add_map_legend_item(legend_row, Color("#242f38"), "未解锁")

## Rebuilds the schematic room diagram every time the modal opens, since
## unlocked/current-room state changes as training progresses. Positions
## are schematic (MAP_OVERVIEW_NODES), not the real per-room pixel layout --
## this is an overview/orientation aid, not a 1:1 rendering of each room's
## own interior blockout.
func _refresh_map_overview() -> void:
	if map_overview_diagram == null:
		return
	_clear_container(map_overview_diagram)
	var diagram_size: Vector2 = map_overview_diagram.size
	if diagram_size.x <= 1.0 or diagram_size.y <= 1.0:
		diagram_size = Vector2(640, 340)
	for node_data in MAP_OVERVIEW_NODES:
		_add_map_overview_node(map_overview_diagram, diagram_size, node_data)

func _add_map_overview_node(parent: Control, diagram_size: Vector2, node_data: Dictionary) -> void:
	var area_id := String(node_data["area_id"])
	var label_text := String(node_data["label"])
	var pos: Vector2 = (node_data["pos"] as Vector2) * diagram_size

	var is_current := area_id == current_area_id
	var is_unlocked := bool((areas.get(area_id, {}) as Dictionary).get("unlocked", false))

	var node_box := PanelContainer.new()
	var node_size := Vector2(136, 56)
	node_box.size = node_size
	node_box.position = pos - node_size * 0.5
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	if is_current:
		style.bg_color = Color("#1c3a52")
		style.border_color = Color("#4f8eb8")
		style.set_border_width_all(2)
	elif is_unlocked:
		style.bg_color = Color("#16232f")
		style.border_color = Color("#3d5266")
		style.set_border_width_all(1)
	else:
		style.bg_color = Color("#0d151c")
		style.border_color = Color("#242f38")
		style.set_border_width_all(1)
	node_box.add_theme_stylebox_override("panel", style)
	parent.add_child(node_box)

	var label_col := VBoxContainer.new()
	label_col.alignment = BoxContainer.ALIGNMENT_CENTER
	node_box.add_child(label_col)
	var room_label := Label.new()
	room_label.text = label_text
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if is_current:
		room_label.modulate = Color("#eaf4ff")
	elif is_unlocked:
		room_label.modulate = Color("#c6d5df")
	else:
		room_label.modulate = Color("#4a5865")
	room_label.add_theme_font_size_override("font_size", 13)
	label_col.add_child(room_label)
	if is_current:
		var current_tag := Label.new()
		current_tag.text = "当前位置"
		current_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		current_tag.modulate = Color("#4f8eb8")
		current_tag.add_theme_font_size_override("font_size", 10)
		label_col.add_child(current_tag)
	elif not is_unlocked:
		var locked_tag := Label.new()
		locked_tag.text = "未解锁"
		locked_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_tag.modulate = Color("#3d4750")
		locked_tag.add_theme_font_size_override("font_size", 10)
		label_col.add_child(locked_tag)

func _add_map_legend_item(parent: HBoxContainer, color: Color, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var swatch := PanelContainer.new()
	swatch.custom_minimum_size = Vector2(12, 12)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var swatch_style := StyleBoxFlat.new()
	swatch_style.bg_color = color
	swatch_style.set_corner_radius_all(3)
	swatch.add_theme_stylebox_override("panel", swatch_style)
	row.add_child(swatch)
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color("#8fa1aa")
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)

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
	resume.focus_mode = Control.FOCUS_NONE
	resume.pressed.connect(func(): _set_pause_visible(false))
	box.add_child(resume)
	var tasks := Button.new()
	tasks.text = "查看任务"
	tasks.custom_minimum_size = Vector2(0, 42)
	tasks.focus_mode = Control.FOCUS_NONE
	tasks.pressed.connect(func():
		_set_pause_visible(false)
		_set_mission_panel_visible(true)
	)
	box.add_child(tasks)
	var main := Button.new()
	main.text = "返回主菜单"
	main.custom_minimum_size = Vector2(0, 42)
	main.focus_mode = Control.FOCUS_NONE
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

## The choice/confirm/info modal is now the shared GuanghanPopupModal component
## (scripts/ui/popup_modal.gd) instead of a hand-built scrim+panel duplicated
## per scene. The scene still owns its own pause / overlay-visibility logic and
## just drives open()/close()/is_open() + append_feedback().
func _build_diagnosis_modal() -> void:
	_popup = GuanghanPopupModal.new()
	add_child(_popup)

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
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.pressed.connect(_on_confirm_suit_status_pressed)
	box.add_child(confirm)

func _current_module_for_save() -> String:
	var module_id := String(module_data.get("module_id", ""))
	if module_id == "airlock_return":
		return "power_distribution"
	if not module_id.is_empty():
		return module_id
	return "suit_control"

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
		"AirlockChamberRoomBlockout":
			floor = AirlockChamberRoomBlockout.new()
		"PowerRepairRoomBlockout":
			floor = TrainingModuleSceneScript.PowerRepairRoomBlockout.new()
		"LifeSupportRoomBlockout":
			floor = TrainingModuleSceneScript.LifeSupportRoomBlockout.new()
		"PlantDiagnosisRoomBlockout":
			floor = TrainingModuleSceneScript.PlantDiagnosisRoomBlockout.new()
		"TrainingHubBlockout":
			floor = TrainingModuleSceneScript.TrainingHubBlockout.new()
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
		visual.prop_scene_path = String(target.get("prop_scene_path", ""))
		visual.position = _room_point(target.get("position", Vector2.ZERO))
		visual.size = _room_size(target.get("size", Vector2(96, 72)))
		training_area.add_child(visual)
		target_nodes[String(target["id"])] = visual

	player = TrainingModuleSceneScript.TraineeVisual.new()
	player.size = _room_size(Vector2(42, 54))
	player.position = _room_point(module_data.get("player_start", Vector2(350, 320)))
	training_area.add_child(player)

	prompt_label = Label.new()
	prompt_label.modulate = Color("#f0c766")
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.visible = false
	training_area.add_child(prompt_label)

	player_controller = null
	last_training_area_size = _room_pixel_size()

func _room_pixel_size() -> Vector2:
	var available := training_area.size
	if available.x <= 1.0 or available.y <= 1.0:
		available = training_area.custom_minimum_size
	return Vector2(max(available.x, ROOM_DESIGN_SIZE.x), max(available.y, ROOM_DESIGN_SIZE.y))

func _room_scale() -> Vector2:
	var available: Vector2 = _room_pixel_size()
	return Vector2(
		available.x / ROOM_DESIGN_SIZE.x,
		available.y / ROOM_DESIGN_SIZE.y
	)

func _room_point(point: Vector2) -> Vector2:
	return point * _room_scale()

func _room_size(value: Vector2) -> Vector2:
	var scale: Vector2 = _room_scale()
	var uniform: float = min(scale.x, scale.y)
	return value * uniform

func _design_point_from_room(point: Vector2) -> Vector2:
	var scale: Vector2 = _room_scale()
	return Vector2(point.x / max(scale.x, 0.001), point.y / max(scale.y, 0.001))

func _rebuild_room_if_resized() -> void:
	if training_area == null or player == null:
		return
	var current_size: Vector2 = _room_pixel_size()
	if current_size.distance_to(last_training_area_size) < 1.0:
		return
	var design_player_position: Vector2 = _design_point_from_room(player.position)
	_build_training_area()
	if player != null:
		player.position = _room_point(design_player_position)
	if player_controller != null:
		player_controller.sync_position(player.position)

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
				node._sync_prop_node()
		prompt_label.visible = false
		return
	_refresh_floor_state()
	var step := _current_step()
	var target_id := String(step.get("target", "")) if not step.is_empty() else ""
	var state: Dictionary = module_data.get("state", {})
	for node in target_nodes.values():
		if node is TrainingModuleSceneScript.TrainingTargetVisual:
			var node_is_interacting: bool = interaction_running and node.name == interaction_target_id
			node.highlighted = node.name == target_id or node_is_interacting
			node.active = node_is_interacting
			node.locked = _door_locked(node) or _target_flow_locked(String(node.name), state)
			if String(node.name) == "pressure_display":
				var pressure_status := String(state.get("PressureStatus", ""))
				node.status_text = "舱压：" + pressure_status if not pressure_status.is_empty() else ("舱压：低压稳定" if bool(state.get("PressureStable", false)) else "舱压：未启动")
				node.label_text = "舱压状态"
			if current_area_id == "air_system_control_room" and String(node.name) == "core":
				var life_status := String(state.get("LifeSupportStatus", "未稳定"))
				node.status_text = "生命支持：" + life_status
				node.label_text = "生命支持状态"
			if current_area_id == "power_distribution_room":
				match String(node.name):
					"power_display":
						node.label_text = "电力显示"
						if bool(state.get("PowerRestored", false)):
							node.status_text = "电力 43%\n消耗 1.2E/h\n充电 3.4E/h\n满电约 18h"
						else:
							node.status_text = "电力 42%\n消耗 2.8E/h\n充电 1.1E/h\n无法满电"
					"light":
						node.status_text = "测试灯：亮" if bool(state.get("TestLightOn", false)) else "测试灯：灭"
					"battery_pack":
						node.label_text = "电池组"
			node.modulate = Color(1, 1, 1, 1) if node.highlighted else Color(0.64, 0.70, 0.76, 0.56)
			if current_area_id == "air_system_control_room" and String(node.name) == "core" and not node.highlighted and not bool(state.get("LifeSupportStable", false)):
				node.modulate = Color(1.0, 0.83, 0.36, 0.78)
			if current_area_id == "power_distribution_room" and String(node.name) == "power_display" and not node.highlighted:
				node.modulate = Color(0.95, 0.32, 0.36, 0.86) if not bool(state.get("PowerRestored", false)) else Color(0.45, 0.78, 1.0, 0.9)
			node.queue_redraw()
			node._sync_prop_node()
	if target_id.is_empty() or not target_nodes.has(target_id):
		prompt_label.visible = false
		_push_player_state_interaction("", "", "")
		return
	var target: Control = target_nodes[target_id]
	var near := _is_near(target_id)
	var prompt_step_type := String(step.get("type", ""))
	if near and prompt_step_type in ["interact", "plant_control", "pressure_choice", "life_control", "power_battery_choice", "wear_suit_confirm"]:
		prompt_label.text = "E 交互"
		prompt_label.position = target.position + Vector2(8, target.size.y + 20)
		prompt_label.visible = true
		_push_player_state_interaction(target_id, prompt_step_type, "按 E %s" % String(step.get("objective", "交互")))
	else:
		prompt_label.visible = false
		_push_player_state_interaction("", "", "")

## Mirrors the active E-prompt into PlayerStateManager so HUD/UI can read
## "what is the player about to interact with" without knowing this scene's
## internals. Guarded setters make the per-frame call cheap (no-op unless
## the target actually changed).
func _push_player_state_interaction(interaction_id: String, interaction_type: String, label: String) -> void:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return
	var psm := tree.root.get_node_or_null("PlayerStateManager")
	if psm == null:
		return
	if interaction_id.is_empty():
		if psm.has_method("clear_current_interaction"):
			psm.call("clear_current_interaction")
	elif psm.has_method("set_current_interaction"):
		psm.call("set_current_interaction", interaction_id, interaction_type, label)

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

func _target_flow_locked(node_name: String, state: Dictionary) -> bool:
	if current_area_id != "airlock_simulation_room":
		return false
	var module_id := String(module_data.get("module_id", ""))
	if module_id == "airlock_return":
		if node_name == "inner_door":
			return not bool(state.get("InnerDoorUnlocked", false))
		return false
	if node_name == "outer_door":
		return not bool(state.get("PressureStable", false))
	if node_name == "inner_door":
		# Outbound flow: once the close-door step has run, the inner door is
		# physically shut -- show the 锁定 overlay so the now-disabled
		# walk-back passage reads as sealed rather than silently inert.
		return bool(state.get("InnerDoorClosed", false))
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
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)

## remove_child() first (synchronous) rather than relying on queue_free()
## alone (deferred to end-of-frame): callers that rebuild the same container
## again before that deferred free actually runs (e.g. _build_training_area()
## via _rebuild_room_if_resized(), which fires again once the Control's
## layout size settles a frame or two after _ready()) would otherwise hit a
## node-name collision with the still-present old child and get silently
## auto-renamed to "@Control@N" -- breaking every name-keyed lookup
## (_door_locked(), target_id/interaction_target_id highlight matching).
func _clear_container(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
