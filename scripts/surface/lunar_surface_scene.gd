extends Node2D

## 月面地表种子场景（阶段1）。见 docs/design/LUNAR_SURFACE_MAP.md。
## 核心闭环：气闸出舱 → 月面行走消耗宇航服氧/电 → 实时"可达半径 / 安全返航"
## 提示 → 走回气闸补给（重置预算）→ 若在外面氧气耗尽则触发救援
## （救援无人车：掉物[本版占位]/基地醒来/健康四项设 30/扣基地电量，走 PenaltyManager）。
##
## 全程程序化搭建（月面 TileSet 在代码里生成，无需美术资源），复用
## arrival_landing_scene 的 TileMapLayer + Camera 范式、训练地图的 PlayerController 用法。
## 数值都抽成常量便于阶段1 试玩标定。原型阶段的占位/简化处都标了 [SEED]。

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PlayerControllerScript := preload("res://scripts/controllers/player_controller_2d.gd")

const TILE := 64
const PLAYER_SIZE := Vector2(44, 60)
const PLAYER_SPEED := 200.0

# 近区世界范围（[SEED] 起步小尺寸，靠氧电预算标定；后期往外扩不改这里的结构）。
const REGION_TILES := Vector2i(48, 36)             # 48x36 tile ≈ 3072x2304 px
const AIRLOCK_SPAWN := Vector2(200, 200)           # 气闸/返航锚点世界坐标

# 氧电预算（[SEED] 占位速率，待试玩标定）。
const SECONDS_PER_SURFACE_MINUTE := 1.2            # 现实秒 → 一"月面分钟"
const RESCUE_OXYGEN_THRESHOLD := 0.5               # 氧气降到此值触发救援
const RETURN_SAFETY_MARGIN := 1.35                 # 返航所需氧气的安全系数
const ANCHOR_RESUPPLY_RADIUS := 90.0               # 距锚点多近算"在气闸，可补给"

var tile_map: TileMapLayer
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

func _ready() -> void:
	world_bounds = Rect2(Vector2.ZERO, Vector2(REGION_TILES.x * TILE, REGION_TILES.y * TILE))
	_ensure_input_actions()
	_setup_tile_map()
	_setup_anchor()
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

## -- Build --

func _setup_tile_map() -> void:
	tile_map = TileMapLayer.new()
	tile_map.name = "MoonSurface"
	tile_map.tile_set = _create_moon_tile_set()
	tile_map.z_index = -5
	add_child(tile_map)
	for x in range(REGION_TILES.x):
		for y in range(REGION_TILES.y):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(abs(x * 3 + y) % 6, 0))

func _create_moon_tile_set() -> TileSet:
	# Procedural greyscale regolith tiles (6 variants) -- no art asset needed.
	var image := Image.create(TILE * 6, TILE, false, Image.FORMAT_RGBA8)
	for tile_x in range(6):
		for px in range(TILE):
			for py in range(TILE):
				var base: float = 0.10 + float(tile_x) * 0.010
				var grain: float = float((px * 17 + py * 9 + tile_x * 23) % 19) * 0.0030
				var crater: float = 0.0
				var local := Vector2(float(px - 32), float(py - 30))
				if local.length() < 11.0 + float(tile_x % 3) * 3.0:
					crater = -0.020
				var shade: float = clamp(base + grain + crater, 0.06, 0.22)
				image.set_pixel(tile_x * TILE + px, py, Color(shade * 0.9, shade * 0.92, shade + 0.03, 1.0))
	var texture := ImageTexture.create_from_image(image)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	for tile_x in range(6):
		source.create_tile(Vector2i(tile_x, 0))
	var tile_set := TileSet.new()
	tile_set.add_source(source, 0)
	return tile_set

func _setup_anchor() -> void:
	# Airlock / return anchor: a simple marked pad at the spawn point.
	var pad := ColorRect.new()
	pad.color = Color("#3d5a74")
	pad.size = Vector2(120, 90)
	pad.position = AIRLOCK_SPAWN - pad.size * 0.5
	pad.z_index = -2
	add_child(pad)
	var label := Label.new()
	label.text = "气闸 / 返航补给"
	label.modulate = Color("#cfe3f2")
	label.position = AIRLOCK_SPAWN + Vector2(-60, -70)
	label.z_index = 40
	add_child(label)

func _setup_player() -> void:
	player_node = PLAYER_SCENE.instantiate()
	player_node.name = "Player"
	player_node.z_index = 30
	player_node.position = AIRLOCK_SPAWN
	add_child(player_node)
	player_controller = PlayerControllerScript.new()
	player_controller.configure(player_node.position, PLAYER_SIZE, PLAYER_SPEED, world_bounds, true, _movement_time_manager())
	player_controller.terrain_type = "exterior"
	player_controller.movement_context = "mission"

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "SurfaceCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.zoom = Vector2(1.4, 1.4)
	add_child(camera)
	camera.position = player_node.position

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
	var result: Dictionary = player_controller.move_with_actions(delta, "ui_left", "ui_right", "ui_up", "ui_down")
	player_node.position = result.get("position", player_node.position)
	if camera != null:
		camera.position = player_node.position
	return player_node.position.distance_to(before) > 0.01

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
	var dist := player_node.position.distance_to(AIRLOCK_SPAWN)
	# 单位距离耗氧 ≈ (每分钟耗氧) / (每分钟走的距离)。用一个占位常量，待标定。
	var oxygen_per_px := 0.006
	return dist * oxygen_per_px

func _is_safe_to_continue() -> bool:
	var suit := _suit_manager()
	if suit == null:
		return true
	var o2: float = float(suit.get("suit_oxygen"))
	return o2 >= _oxygen_needed_to_return() * RETURN_SAFETY_MARGIN

## -- Resupply at anchor --

func _check_resupply() -> void:
	if player_node.position.distance_to(AIRLOCK_SPAWN) > ANCHOR_RESUPPLY_RADIUS:
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
	if player_node.position.distance_to(AIRLOCK_SPAWN) <= ANCHOR_RESUPPLY_RADIUS:
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
	status_label.text = "月面 EVA · 近基地区\n氧气：%d / %d\n电力：%d / %d\n距气闸：%d m" % [
		int(o2), int(o2_cap), int(power), int(power_cap),
		int(player_node.position.distance_to(AIRLOCK_SPAWN) / TILE),
	]
	if player_node.position.distance_to(AIRLOCK_SPAWN) <= ANCHOR_RESUPPLY_RADIUS:
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
