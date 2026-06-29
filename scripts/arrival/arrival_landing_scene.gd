extends Node2D

const TILE := 56
const SAVE_PATH := "user://arrival_prototype_save.json"
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const GameStateManagerScript := preload("res://scripts/game_state_manager.gd")
const TimeManagerScript := preload("res://scripts/time_manager.gd")
const CameraManagerScript := preload("res://scripts/camera_manager.gd")
const UIManagerScript := preload("res://scripts/ui_manager.gd")
const EventManagerScript := preload("res://scripts/event_manager.gd")
const AudioFeedbackScript := preload("res://scripts/audio_feedback.gd")
const AudioManagerScript := preload("res://scripts/audio_manager.gd")
const LightingManagerScript := preload("res://scripts/lighting_manager.gd")

var player_pos := Vector2(260, 560)
var player_facing := Vector2.RIGHT
var player_moving := false
var player_input_enabled := true
var walk_phase := 0.0
var camera_zoom := 1.0
var observe_hold := 0.0
var observe_triggered := false
var entered_airlock := false
var hud_alpha := 1.0
var prompt_text := ""

var player_node: Node2D
var camera: Camera2D
var moon_tile_map: TileMapLayer
var game_state_manager: Node
var time_manager: Node
var camera_manager: Node
var ui_manager: Node
var event_manager: Node
var audio_feedback: Node
var audio_manager: Node
var lighting_manager: Node

var observe_rect := Rect2(Vector2(470, 380), Vector2(250, 220))
var airlock_rect := Rect2(Vector2(1260, 450), Vector2(110, 130))
var world_rect := Rect2(Vector2(40, 120), Vector2(1460, 700))

func _ready() -> void:
	_setup_input_map()
	_setup_managers()
	_setup_tile_map()
	_setup_player()
	_setup_ui()
	_setup_lights()
	game_state_manager.call("change_state", GameStateManagerScript.LANDING)
	queue_redraw()

func _setup_input_map() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E])
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

func _setup_managers() -> void:
	game_state_manager = GameStateManagerScript.new()
	game_state_manager.name = "GameStateManager"
	add_child(game_state_manager)
	time_manager = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	add_child(time_manager)
	time_manager.call("set_time", 1, 7, 42)
	camera_manager = CameraManagerScript.new()
	camera_manager.name = "CameraManager"
	add_child(camera_manager)
	ui_manager = UIManagerScript.new()
	ui_manager.name = "UIManager"
	add_child(ui_manager)
	event_manager = EventManagerScript.new()
	event_manager.name = "EventManager"
	add_child(event_manager)
	audio_feedback = AudioFeedbackScript.new()
	audio_feedback.name = "AudioFeedback"
	add_child(audio_feedback)
	audio_manager = AudioManagerScript.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)
	audio_manager.call("set_backend", audio_feedback)
	lighting_manager = LightingManagerScript.new()
	lighting_manager.name = "LightingManager"
	add_child(lighting_manager)

func _setup_tile_map() -> void:
	moon_tile_map = TileMapLayer.new()
	moon_tile_map.name = "Ground"
	moon_tile_map.tile_set = _create_moon_tile_set()
	add_child(moon_tile_map)
	for x in range(0, 28):
		for y in range(0, 16):
			moon_tile_map.set_cell(Vector2i(x, y), 0, Vector2i((x + y) % 4, 0))

func _create_moon_tile_set() -> TileSet:
	var image := Image.create(TILE * 4, TILE, false, Image.FORMAT_RGBA8)
	for tile_x in range(4):
		for px in range(TILE):
			for py in range(TILE):
				var base: float = 0.09 + float(tile_x) * 0.025
				var grain: float = float((px * 17 + py * 9 + tile_x * 11) % 13) * 0.003
				var shade: float = clamp(base + grain, 0.05, 0.22)
				image.set_pixel(tile_x * TILE + px, py, Color(shade * 0.88, shade * 0.92, shade + 0.04, 1.0))
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	for tile_x in range(4):
		source.create_tile(Vector2i(tile_x, 0))
	var tile_set := TileSet.new()
	tile_set.add_source(source, 0)
	return tile_set

func _setup_player() -> void:
	player_node = PLAYER_SCENE.instantiate()
	player_node.name = "Player"
	player_node.z_index = 30
	add_child(player_node)
	camera = Camera2D.new()
	camera.name = "GameCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	add_child(camera)
	camera_manager.call("configure", camera)
	_sync_player_visual()

func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	add_child(canvas)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)
	ui_manager.call("bind_root", root)
	var hud := Label.new()
	hud.name = "MinimalHUD"
	hud.position = Vector2(24, 720)
	hud.size = Vector2(360, 120)
	hud.add_theme_font_size_override("font_size", 18)
	root.add_child(hud)
	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.position = Vector2(560, 760)
	prompt.size = Vector2(500, 42)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	root.add_child(prompt)
	var dialogue := Label.new()
	dialogue.name = "Dialogue"
	dialogue.visible = false
	dialogue.position = Vector2(380, 92)
	dialogue.size = Vector2(760, 120)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.add_theme_font_size_override("font_size", 22)
	root.add_child(dialogue)
	var debug := Label.new()
	debug.name = "Debug"
	debug.position = Vector2(1210, 26)
	debug.size = Vector2(360, 150)
	debug.add_theme_font_size_override("font_size", 14)
	root.add_child(debug)

func _setup_lights() -> void:
	var global := CanvasModulate.new()
	global.name = "GlobalMoonLight"
	global.color = Color("#b8c2d0")
	add_child(global)
	lighting_manager.call("bind_global_light", global)

func _process(delta: float) -> void:
	_process_movement(delta)
	_process_observe_earth(delta)
	_update_prompt()
	_update_camera()
	_update_ui()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("save_game"):
		_save_arrival()
	if event.is_action_pressed("load_game"):
		_load_arrival()

func _process_movement(delta: float) -> void:
	var input := Vector2.ZERO
	if player_input_enabled:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_moving = input.length() > 0.01
	if player_moving:
		player_facing = input.normalized()
		walk_phase += delta * 10.0
		var next_pos := player_pos + player_facing * 170.0 * delta
		player_pos = Vector2(
			clamp(next_pos.x, world_rect.position.x, world_rect.end.x),
			clamp(next_pos.y, world_rect.position.y, world_rect.end.y)
		)
	_sync_player_visual()

func _sync_player_visual() -> void:
	if not is_instance_valid(player_node):
		return
	player_node.position = player_pos
	if player_node.has_method("setup"):
		player_node.call("setup", player_facing, false, 98.0, player_moving, walk_phase)

func _process_observe_earth(delta: float) -> void:
	if observe_triggered:
		hud_alpha = move_toward(hud_alpha, 1.0, delta * 0.4)
		return
	if observe_rect.has_point(player_pos) and not player_moving:
		observe_hold += delta
	else:
		observe_hold = 0.0
	if observe_hold >= 5.0:
		_trigger_observe_earth()

func _trigger_observe_earth() -> void:
	observe_triggered = true
	hud_alpha = 0.35
	event_manager.call("trigger", "observe_earth", {"scene": "ArrivalLandingScene"}, true)
	camera_manager.call("lock_to", Vector2(610, 410))
	var dialogue: Label = $UI/Root/Dialogue
	dialogue.text = "那里，是地球。\n距离：384,400公里。\n预计通信延迟：1.3秒。"
	dialogue.visible = true
	audio_manager.call("play_ui", 520.0, 0.12, 0.06)
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(dialogue):
		dialogue.visible = false
	camera_manager.call("unlock")

func _update_prompt() -> void:
	if airlock_rect.has_point(player_pos):
		prompt_text = "E 进入气闸"
	elif observe_rect.has_point(player_pos) and not observe_triggered:
		var left: float = max(0.0, 5.0 - observe_hold)
		prompt_text = "停下凝视地球 %.1fs" % left
	else:
		prompt_text = ""

func _try_interact() -> void:
	if airlock_rect.has_point(player_pos):
		entered_airlock = true
		game_state_manager.call("change_state", GameStateManagerScript.BASE_INTERIOR)
		event_manager.call("trigger", "entered_airlock", {}, true)
		_save_arrival()
		get_tree().change_scene_to_file("res://scenes/base/BaseInterior_Test.tscn")

func _update_camera() -> void:
	camera_manager.call("update_camera", camera, player_pos, camera_zoom)

func _update_ui() -> void:
	var hud: Label = $UI/Root/MinimalHUD
	hud.modulate.a = hud_alpha
	var clock_text := String(time_manager.call("clock_text"))
	hud.text = "O2: 98%%\nSuit: Stable\nComm Delay: 1.3s\nDay 01\nTime %s" % clock_text.substr(4)
	$UI/Root/Prompt.text = prompt_text
	var debug: Label = $UI/Root/Debug
	debug.text = "Scene: ArrivalLandingScene\nState: %s\nPlayer: %.0f, %.0f\nTime: %s\nObserveEarthEvent: %s" % [
		String(game_state_manager.get("current_state")),
		player_pos.x,
		player_pos.y,
		String(time_manager.call("clock_text")),
		"true" if observe_triggered else "false"
	]

func _draw() -> void:
	_draw_tracks()
	_draw_transport_ship()
	_draw_earth()
	_draw_distant_base()
	_draw_engineering_objects()
	_draw_airlock()
	_draw_light_markers()

func _draw_transport_ship() -> void:
	draw_rect(Rect2(Vector2(70, 410), Vector2(210, 125)), Color("#d8d2c7"))
	draw_rect(Rect2(Vector2(88, 436), Vector2(86, 48)), Color("#4e5966"))
	draw_rect(Rect2(Vector2(200, 398), Vector2(48, 160)), Color("#8c8b82"))
	draw_line(Vector2(245, 535), Vector2(330, 585), Color("#b8b2a2"), 8)
	draw_circle(Vector2(110, 545), 18, Color("#f0a44f", 0.6))
	draw_circle(Vector2(230, 558), 14, Color("#f0a44f", 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(95, 470), "广寒运输船", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#202833"))

func _draw_earth() -> void:
	draw_circle(Vector2(640, 145), 32, Color("#2b7fc6"))
	draw_circle(Vector2(628, 135), 12, Color("#d8f0ff"))
	draw_circle(Vector2(650, 152), 9, Color("#78d68c"))
	draw_arc(Vector2(640, 145), 36.0, 0.0, TAU, 40, Color("#b8e7ff", 0.55), 2)

func _draw_distant_base() -> void:
	var base := Vector2(1120, 340)
	draw_rect(Rect2(base, Vector2(210, 62)), Color("#353942"))
	draw_rect(Rect2(base + Vector2(32, -36), Vector2(54, 38)), Color("#50525a"))
	draw_rect(Rect2(base + Vector2(108, -22), Vector2(70, 24)), Color("#454953"))
	for i in range(5):
		draw_circle(base + Vector2(30 + i * 36, 44), 5, Color("#e7b85d"))
	draw_line(base + Vector2(105, 0), base + Vector2(105, -82), Color("#9a9a92"), 3)
	draw_circle(base + Vector2(105, -88), 4, Color("#ff7a4d"))

func _draw_engineering_objects() -> void:
	draw_rect(Rect2(Vector2(930, 595), Vector2(86, 48)), Color("#6c5c4d"))
	draw_rect(Rect2(Vector2(1050, 620), Vector2(60, 36)), Color("#8b7459"))
	draw_rect(Rect2(Vector2(845, 548), Vector2(120, 24)), Color("#334c62"))
	draw_line(Vector2(760, 650), Vector2(1150, 635), Color("#2a211a"), 5)
	draw_line(Vector2(780, 670), Vector2(1045, 705), Color("#3a2a1c"), 4)
	for i in range(6):
		draw_circle(Vector2(420 + i * 32, 610 + sin(float(i)) * 10.0), 5, Color("#1f242c", 0.45))

func _draw_airlock() -> void:
	draw_rect(airlock_rect, Color("#4b4d4f"))
	draw_rect(airlock_rect.grow(-14), Color("#202833"))
	draw_line(airlock_rect.position + Vector2(18, 18), airlock_rect.end - Vector2(18, 18), Color("#e7b85d"), 4)
	draw_string(ThemeDB.fallback_font, airlock_rect.position + Vector2(12, -10), "旧基地气闸", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#e7b85d"))

func _draw_tracks() -> void:
	for i in range(12):
		var p := Vector2(330 + i * 55, 585 + sin(float(i) * 0.8) * 18.0)
		draw_circle(p, 10, Color("#080a0d", 0.24))

func _draw_light_markers() -> void:
	draw_circle(Vector2(1340, 510), 28, Color("#e7b85d", 0.12))
	draw_circle(Vector2(1185, 385), 45, Color("#e7b85d", 0.10))
	draw_circle(Vector2(210, 535), 40, Color("#f0a44f", 0.10))

func _save_arrival() -> void:
	var data := {
		"current_scene": "res://scenes/arrival/ArrivalLandingScene.tscn",
		"player_pos": {"x": player_pos.x, "y": player_pos.y},
		"player_facing": {"x": player_facing.x, "y": player_facing.y},
		"game_state": game_state_manager.call("serialize"),
		"time": time_manager.call("serialize"),
		"events": event_manager.call("serialize"),
		"observe_triggered": observe_triggered,
		"entered_airlock": entered_airlock,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _load_arrival() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	var pos: Dictionary = data.get("player_pos", {"x": player_pos.x, "y": player_pos.y})
	player_pos = Vector2(float(pos.get("x", player_pos.x)), float(pos.get("y", player_pos.y)))
	var facing: Dictionary = data.get("player_facing", {"x": 1.0, "y": 0.0})
	player_facing = Vector2(float(facing.get("x", 1.0)), float(facing.get("y", 0.0)))
	game_state_manager.call("deserialize", data.get("game_state", {}))
	time_manager.call("deserialize", data.get("time", {}))
	event_manager.call("deserialize", data.get("events", {}))
	observe_triggered = bool(data.get("observe_triggered", event_manager.call("has_fired", "observe_earth")))
	entered_airlock = bool(data.get("entered_airlock", false))
	observe_hold = 0.0
	_sync_player_visual()
