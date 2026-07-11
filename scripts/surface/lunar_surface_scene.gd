extends Node2D

## 月面地表世界容器 LunarSurfaceWorld（分块世界的容器层）。见 docs/design/LUNAR_SURFACE_MAP.md。
##
## 玩家体验上，月面外部是一张【视觉连续】的空间；工程上按 Chunk 分块组织。本轮世界
## 里只挂载并激活一个 Chunk：NearBaseChunk（近基地区）。未来在相邻坐标接入
## SolarFieldChunk / CraterChunk / RuinsExteriorChunk / IceFieldChunk 等，本轮不实现。
##
## 职责分层：
## - 世界容器（本文件）：玩家、相机、HUD、世界级输入（右键点击移动）、氧气/电力预算、
##   气闸补给、遇险救援、世界级场景切换，以及"挂载当前激活 Chunk"。
## - Chunk（near_base_chunk.gd）：只负责该块地表的地面、锚点、地标、边界、出口占位。
## - 时间/氧气/电力/存档：仍由现有 autoload Manager 负责，本容器只调用不接管。
##
## 核心闭环（不变）：气闸出舱 → 月面行走消耗宇航服氧/电 → 实时"可达半径 / 安全返航"
## 提示 → 走回气闸补给（重置预算）→ 若在外面氧气耗尽则触发救援
## （救援无人车：健康四项设 30 / 扣基地电量，走 PenaltyManager）。
## 数值都抽成常量便于阶段1 试玩标定；原型阶段的占位/简化处标了 [SEED]。

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PlayerControllerScript := preload("res://scripts/controllers/player_controller_2d.gd")
## 本轮唯一激活的 Chunk。未来多 Chunk 时，这里换成"当前激活 Chunk 列表/查表"，
## 世界容器负责按玩家位置决定挂载哪几块（本轮不实现加载/卸载）。
const ACTIVE_CHUNK_SCENE := preload("res://scenes/surface/chunks/NearBaseChunk.tscn")

const TILE := 64
const PLAYER_SIZE := Vector2(44, 60)
const PLAYER_SPEED := 200.0

const CLICK_ARRIVE_DIST := 6.0                     # 右键点击移动到达判定距离

# 氧电预算（[SEED] 占位速率，待试玩标定）。
const SECONDS_PER_SURFACE_MINUTE := 1.2            # 现实秒 → 一"月面分钟"
const RESCUE_OXYGEN_THRESHOLD := 0.5               # 氧气降到此值触发救援
const RETURN_SAFETY_MARGIN := 1.35                 # 返航所需氧气的安全系数
const ANCHOR_RESUPPLY_RADIUS := 90.0               # 距锚点多近算"在气闸，可补给"

## 当前激活 Chunk，以及从它读到的世界参数（世界坐标）。
var _active_chunk: Node2D
var _anchor_point: Vector2                          # 气闸/返航锚点（补给 + 救援判定基准）
var _spawn_point: Vector2                           # 玩家出生点（气闸外侧）

var player_node: Node2D
var player_controller
var camera: Camera2D
var world_bounds: Rect2

# HUD
var hud_layer: CanvasLayer
var status_label: Label
var return_label: Label
var toast_label: Label

var _surface_minute_accum := 0.0
var _rescued := false
var _last_o2 := 100.0
var _move_target := Vector2.ZERO
var _has_move_target := false

func _ready() -> void:
	_ensure_input_actions()
	_mount_active_chunk()
	_setup_player()
	_setup_camera()
	_setup_hud()
	_prepare_suit_for_eva()
	_push_player_state()

func _process(delta: float) -> void:
	if _rescued:
		return
	var moved := _move_player(delta)
	_update_budget(delta, moved)
	_check_resupply()
	_check_rescue()
	_update_hud()

## -- Chunk mount --

## 实例化并挂载当前激活 Chunk，从它读取世界边界 / 锚点 / 出生点。本轮只挂一块、
## 常驻，不做加载卸载。未来多 Chunk：这里改为挂载相邻若干块并按坐标拼接。
func _mount_active_chunk() -> void:
	_active_chunk = ACTIVE_CHUNK_SCENE.instantiate()
	_active_chunk.name = "ActiveChunk"
	add_child(_active_chunk)
	world_bounds = _active_chunk.get_bounds()
	_anchor_point = _active_chunk.get_anchor_point()
	_spawn_point = _active_chunk.get_spawn_point()

## -- Build (player / camera / HUD) --

func _setup_player() -> void:
	player_node = PLAYER_SCENE.instantiate()
	player_node.name = "Player"
	player_node.z_index = 30
	player_node.position = _spawn_point
	add_child(player_node)
	player_controller = PlayerControllerScript.new()
	player_controller.configure(player_node.position, PLAYER_SIZE, PLAYER_SPEED, world_bounds, true, _movement_time_manager())
	player_controller.terrain_type = "exterior"
	player_controller.movement_context = "mission"

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "SurfaceCamera"
	camera.enabled = true
	camera.zoom = Vector2(1.0, 1.0)  # 视野开阔（越小看得越远）
	# Parent the camera to the player and give it a drag box: the player sprite
	# visibly moves within the centre of the screen before the camera pans. A
	# hard-locked follow cam on featureless regolith read as "can't move".
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	camera.drag_left_margin = 0.28
	camera.drag_right_margin = 0.28
	camera.drag_top_margin = 0.28
	camera.drag_bottom_margin = 0.28
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	player_node.add_child(camera)

func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	status_label = Label.new()
	status_label.position = Vector2(24, 20)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.modulate = Color("#cfe3f2")
	hud_layer.add_child(status_label)
	return_label = Label.new()
	return_label.position = Vector2(24, 96)
	return_label.add_theme_font_size_override("font_size", 18)
	hud_layer.add_child(return_label)
	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_CENTER)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.offset_left = -260
	toast_label.offset_right = 260
	toast_label.offset_top = -20
	toast_label.offset_bottom = 20
	toast_label.add_theme_font_size_override("font_size", 22)
	toast_label.modulate = Color(1, 1, 1, 0)
	hud_layer.add_child(toast_label)

## -- Movement + camera follow --

func _move_player(delta: float) -> bool:
	if player_controller == null:
		return false
	player_controller.bounds = world_bounds
	player_controller.speed = PLAYER_SPEED
	player_controller.sync_position(player_node.position)
	var before := player_node.position
	# Keyboard (WASD / arrows) takes priority and cancels any click-to-move.
	var keyboard_dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down"))
	if keyboard_dir != Vector2.ZERO:
		_has_move_target = false
		player_controller.move_in_direction(keyboard_dir, delta)
	elif _has_move_target:
		var to_target := _move_target - player_node.position
		if to_target.length() <= CLICK_ARRIVE_DIST:
			_has_move_target = false
		else:
			player_controller.move_in_direction(to_target.normalized(), delta)
	player_node.position = player_controller.position
	# Camera follows automatically (parented to the player, with a drag box).
	return player_node.position.distance_to(before) > 0.01

## Right-click to walk toward the clicked world position (cancelled by keyboard).
## Target is clamped to the active chunk bounds, so a click never sends the
## player past the current chunk edge. [SEED] Straight-line move: there are no
## obstacles yet; once terrain/props gain collision this must be replaced by a
## real pathfinding/steering step (see KNOWN LIMITS in the change report).
func _input(event: InputEvent) -> void:
	if _rescued:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_move_target = _clamp_to_region(get_global_mouse_position())
		_has_move_target = true

func _clamp_to_region(world_point: Vector2) -> Vector2:
	var margin := 24.0
	return Vector2(
		clamp(world_point.x, world_bounds.position.x + margin, world_bounds.end.x - margin),
		clamp(world_point.y, world_bounds.position.y + margin, world_bounds.end.y - margin))

## -- Oxygen / power budget --

func _update_budget(delta: float, moved: bool) -> void:
	var suit := _suit_manager()
	if suit == null:
		return
	_surface_minute_accum += delta / SECONDS_PER_SURFACE_MINUTE
	while _surface_minute_accum >= 1.0:
		_surface_minute_accum -= 1.0
		if suit.has_method("consume_suit_resources"):
			suit.call("consume_suit_resources", 1, "eva_move" if moved else "eva_idle")

## 距锚点距离 → 返航所需氧气估算（[SEED] 线性近似，用消耗速率反推）。
func _oxygen_needed_to_return() -> float:
	var dist := player_node.position.distance_to(_anchor_point)
	# 单位距离返航耗氧（[SEED] 占位，待标定）。调大 → "该返航"警告更早触发。
	# 满氧安全半径 ≈ 100/(此值×安全系数)≈6173px≈96 格，与近基地 Chunk 尺度匹配。
	var oxygen_per_px := 0.012
	return dist * oxygen_per_px

func _is_safe_to_continue() -> bool:
	var suit := _suit_manager()
	if suit == null:
		return true
	var o2: float = float(suit.get("suit_oxygen"))
	return o2 >= _oxygen_needed_to_return() * RETURN_SAFETY_MARGIN

## -- Resupply at anchor --

func _check_resupply() -> void:
	if player_node.position.distance_to(_anchor_point) > ANCHOR_RESUPPLY_RADIUS:
		return
	var suit := _suit_manager()
	if suit == null:
		return
	var o2: float = float(suit.get("suit_oxygen"))
	var cap: float = float(suit.get("suit_oxygen_capacity"))
	if o2 < cap and suit.has_method("service_suit_full"):
		suit.call("service_suit_full")
		_show_toast("已在气闸补给：氧气/电力已补满。", Color("#9fd7ff"))

## -- Rescue on oxygen depletion --

func _check_rescue() -> void:
	var suit := _suit_manager()
	if suit == null:
		return
	var o2: float = float(suit.get("suit_oxygen"))
	if o2 > RESCUE_OXYGEN_THRESHOLD:
		return
	if player_node.position.distance_to(_anchor_point) <= ANCHOR_RESUPPLY_RADIUS:
		return  # 在气闸边就地补给，不触发救援
	_trigger_rescue()

func _trigger_rescue() -> void:
	if _rescued:
		return
	_rescued = true
	# 救援无人车：健康四项设 30（用当前值反推 delta）、扣基地电量。走 PenaltyManager。
	# [SEED] 背包掉物 + 掉落点回收留作下一增量，这里先不动背包。
	var health_deltas := _deltas_to_reach_30()
	var penalty := _penalty_manager()
	if penalty != null and penalty.has_method("apply_penalty"):
		penalty.call("apply_penalty", {
			"penalty_id": "eva_oxygen_depleted_rescue",
			"display_name": "月面遇险 · 救援无人车回收",
			"context": "mission",
			"reason": "eva_oxygen_depleted",
			"health_deltas": health_deltas,
			"notice_text": "氧气耗尽，救援无人车已将你带回基地。",
		})
	_apply_base_power_rescue_cost()
	_show_toast("氧气耗尽。救援无人车已将你带回基地。", Color("#ff8a8a"))
	# [SEED] 回到主菜单（dev）。正式流程应回基地医疗位并让物资留在掉落点。
	await get_tree().create_timer(2.2).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _deltas_to_reach_30() -> Dictionary:
	var health := _health_manager()
	var deltas := {}
	if health == null:
		return deltas
	for stat_name in ["energy", "fullness", "nutrition", "morale"]:
		var current: float = float(health.get(stat_name))
		deltas[stat_name] = 30.0 - current
	return deltas

func _apply_base_power_rescue_cost() -> void:
	# 派救援无人车消耗基地电量。
	var power := _power_system_manager()
	if power != null and power.has_method("consume_energy"):
		power.call("consume_energy", 6.0)

## -- Suit / HUD --

func _prepare_suit_for_eva() -> void:
	# [SEED] dev 便利：进场若未穿服则穿上并补满，确保能立刻测试地表。
	var suit := _suit_manager()
	if suit == null:
		return
	if not bool(suit.get("is_suit_worn")) and suit.has_method("wear_suit"):
		suit.call("wear_suit")
	if suit.has_method("service_suit_full"):
		suit.call("service_suit_full")

func _update_hud() -> void:
	var suit := _suit_manager()
	if suit == null:
		status_label.text = "宇航服系统不可用。"
		return
	var o2: float = float(suit.get("suit_oxygen"))
	var o2_cap: float = float(suit.get("suit_oxygen_capacity"))
	var power: float = float(suit.get("suit_power"))
	var power_cap: float = float(suit.get("suit_power_capacity"))
	status_label.text = "月面 EVA · 近基地区（WASD/方向键移动 · 右键点击移动）\n氧气：%d / %d\n电力：%d / %d\n距气闸：%d m" % [
		int(o2), int(o2_cap), int(power), int(power_cap),
		int(player_node.position.distance_to(_anchor_point) / TILE),
	]
	if player_node.position.distance_to(_anchor_point) <= ANCHOR_RESUPPLY_RADIUS:
		return_label.text = "● 在气闸补给区"
		return_label.modulate = Color("#9fd7ff")
	elif _is_safe_to_continue():
		return_label.text = "● 可继续外出（氧气足够安全返航）"
		return_label.modulate = Color("#8fd37a")
	else:
		return_label.text = "▲ 该返航了：氧气仅够安全返回气闸"
		return_label.modulate = Color("#ffce6b")

func _show_toast(text: String, color: Color) -> void:
	if toast_label == null:
		return
	toast_label.text = text
	toast_label.modulate = Color(color.r, color.g, color.b, 1.0)
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(toast_label, "modulate:a", 0.0, 1.0)

func _push_player_state() -> void:
	var player_state := _player_state_manager()
	if player_state == null:
		return
	if player_state.has_method("set_context"):
		player_state.call("set_context", "mission")
	if player_state.has_method("set_current_area_by_values"):
		player_state.call("set_current_area_by_values", "lunar_surface_near_base", "近基地月面", "exterior", false, false)

## -- Manager accessors --

func _suit_manager() -> Node:
	return get_node_or_null("/root/SuitManager")

func _health_manager() -> Node:
	return get_node_or_null("/root/HealthManager")

func _penalty_manager() -> Node:
	return get_node_or_null("/root/PenaltyManager")

func _power_system_manager() -> Node:
	return get_node_or_null("/root/PowerSystemManager")

func _player_state_manager() -> Node:
	return get_node_or_null("/root/PlayerStateManager")

func _movement_time_manager() -> Node:
	return get_node_or_null("/root/MovementTimeManager")

func _ensure_input_actions() -> void:
	for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
