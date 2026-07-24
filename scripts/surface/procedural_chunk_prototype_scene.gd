extends Node2D

## Standalone verification prototype for the infinite procedural chunk-map
## feature (see plan abstract-hopping-moonbeam.md). Deliberately does NOT
## touch lunar_surface_scene.gd / NearBaseChunk -- this is a separate,
## minimal world container (no EVA oxygen/power budget, no rescue) whose
## only job is to prove the ChunkManager + WorldGenerator + WorldStateManager
## loop: load/unload chunks around the player, regenerate identical content
## from the same seed, and persist harvested resource nodes / placed
## structure stubs across chunk reload and process restart.
##
## Dev-menu only entry point (see dev_tools_controller.gd's
## "Dev Only: Procedural Chunk Prototype" button) -- not reachable from the
## real airlock/base flow.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PlayerControllerScript := preload("res://scripts/controllers/player_controller_2d.gd")
const ChunkManagerScript := preload("res://scripts/world/ChunkManager.gd")

const PLAYER_SIZE := Vector2(44, 60)
const PLAYER_SPEED := 220.0
const INTERACT_RADIUS := 80.0

## The prototype's world is meant to be effectively unlimited -- player
## movement still needs SOME bounds (player_controller_2d.gd clamps to a
## Rect2), so this is a deliberately huge stand-in rather than a real
## boundary. See plan's flagged risk: a real infinite-world bound (or lack
## thereof) is a decision for whenever this integrates with the real EVA
## scene, not this standalone prototype.
const WORLD_BOUNDS := Rect2(Vector2(-10_000_000, -10_000_000), Vector2(20_000_000, 20_000_000))

var player_node: Node2D
var player_controller
var camera: Camera2D
var chunk_manager: ChunkManagerScript

var hud_layer: CanvasLayer
var status_label: Label
var prompt_label: Label
var toast_label: Label

var _last_chunk_coord := Vector2i(999999, 999999)
var _nearest_node: Dictionary = {}  ## {} or {"id","chunk_key","world_position","type"}

func _ready() -> void:
	_ensure_input_actions()
	chunk_manager = ChunkManagerScript.new()
	var world_state := _world_state_manager()
	var start_position := Vector2.ZERO
	if world_state != null:
		chunk_manager.set_world_seed(world_state.get_world_seed())
		var saved_pos: Vector2 = world_state.player_position
		if saved_pos != Vector2.ZERO:
			start_position = saved_pos
	_setup_player(start_position)
	_setup_camera()
	_setup_hud()
	chunk_manager.update(player_node.position, self)
	_last_chunk_coord = chunk_manager.current_chunk_coord()

func _process(delta: float) -> void:
	_move_player(delta)
	chunk_manager.update(player_node.position, self)
	_check_chunk_crossing()
	_update_nearest_node()
	_update_hud()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_harvest_nearest()
	elif event.is_action_pressed("place_structure_debug"):
		chunk_manager.place_structure_at(player_node.position + Vector2(0, 50))
		_show_toast("已放置占位建筑桩。", Color("#9fd7ff"))

func _setup_player(start_position: Vector2) -> void:
	player_node = PLAYER_SCENE.instantiate()
	player_node.name = "Player"
	player_node.z_index = 30
	player_node.position = start_position
	add_child(player_node)
	player_controller = PlayerControllerScript.new()
	player_controller.configure(player_node.position, PLAYER_SIZE, PLAYER_SPEED, WORLD_BOUNDS, true, _movement_time_manager())
	player_controller.terrain_type = "exterior"
	player_controller.movement_context = "mission"

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "PrototypeCamera"
	camera.enabled = true
	camera.zoom = Vector2(1.0, 1.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	player_node.add_child(camera)

func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	status_label = Label.new()
	status_label.position = Vector2(24, 20)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.modulate = Color("#cfe3f2")
	hud_layer.add_child(status_label)
	prompt_label = Label.new()
	prompt_label.position = Vector2(24, 140)
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_label.modulate = Color("#f0c766")
	hud_layer.add_child(prompt_label)
	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_CENTER)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.offset_left = -260
	toast_label.offset_right = 260
	toast_label.offset_top = -20
	toast_label.offset_bottom = 20
	toast_label.add_theme_font_size_override("font_size", 20)
	toast_label.modulate = Color(1, 1, 1, 0)
	hud_layer.add_child(toast_label)

func _move_player(delta: float) -> void:
	player_controller.bounds = WORLD_BOUNDS
	player_controller.speed = PLAYER_SPEED
	player_controller.sync_position(player_node.position)
	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down"))
	if direction != Vector2.ZERO:
		player_controller.move_in_direction(direction, delta)
	player_node.position = player_controller.position

## Persists player_position to WorldStateManager only when the player's
## chunk coordinate actually changes -- never per-frame (see
## WorldStateManager.set_player_position()'s own write-frequency note).
func _check_chunk_crossing() -> void:
	var coord := chunk_manager.current_chunk_coord()
	if coord == _last_chunk_coord:
		return
	_last_chunk_coord = coord
	var world_state := _world_state_manager()
	if world_state != null:
		world_state.set_player_position(player_node.position)

func _update_nearest_node() -> void:
	_nearest_node = {}
	var best_dist := INTERACT_RADIUS
	for node_data in chunk_manager.get_all_active_resource_nodes():
		var world_pos: Vector2 = node_data["world_position"]
		var dist := player_node.position.distance_to(world_pos)
		if dist <= best_dist:
			best_dist = dist
			_nearest_node = node_data

func _try_harvest_nearest() -> void:
	if _nearest_node.is_empty():
		return
	var result: Dictionary = chunk_manager.harvest_node(String(_nearest_node["chunk_key"]), String(_nearest_node["id"]))
	if bool(result.get("success", false)):
		_show_toast("已采集：月岩矿石样本 x%d" % int(result.get("amount", 0)), Color("#9fd7ff"))
	elif String(result.get("reason", "")) == "backpack_full":
		_show_toast("背包已满。", Color("#ff8a8a"))

func _update_hud() -> void:
	var coord := chunk_manager.current_chunk_coord()
	var world_state := _world_state_manager()
	var seed_text := str(world_state.get_world_seed()) if world_state != null else "?"
	status_label.text = "程序化区块原型 (WASD 移动 · E 采集 · F 放置占位建筑)\n世界种子：%s\n当前区块：(%d, %d)\n已加载区块数：%d\n%s" % [
		seed_text, coord.x, coord.y, chunk_manager.loaded_chunk_keys().size(),
		String(", ").join(chunk_manager.loaded_chunk_keys()),
	]
	if _nearest_node.is_empty():
		prompt_label.text = ""
	else:
		prompt_label.text = "按 E 采集：%s" % ("月岩" if String(_nearest_node["type"]) == "moon_rock" else "矿石")

func _show_toast(text: String, color: Color) -> void:
	toast_label.text = text
	toast_label.modulate = Color(color.r, color.g, color.b, 1.0)
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(toast_label, "modulate:a", 0.0, 1.0)

func _world_state_manager() -> Node:
	return get_node_or_null("/root/WorldStateManager")

func _movement_time_manager() -> Node:
	return get_node_or_null("/root/MovementTimeManager")

func _ensure_input_actions() -> void:
	for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var interact_event := InputEventKey.new()
		interact_event.keycode = KEY_E
		InputMap.action_add_event("interact", interact_event)
	if not InputMap.has_action("place_structure_debug"):
		InputMap.add_action("place_structure_debug")
		var build_event := InputEventKey.new()
		build_event.keycode = KEY_F
		InputMap.action_add_event("place_structure_debug", build_event)
