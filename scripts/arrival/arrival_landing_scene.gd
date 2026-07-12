extends Node2D

const TILE := 64
const SAVE_PATH := "user://arrival_prototype_save.json"
const BASE_AIRLOCK_SCENE := "res://scenes/base/BaseAirlockEntryScene.tscn"
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const GameStateManagerScript := preload("res://scripts/game_state_manager.gd")
const TimeManagerScript := preload("res://scripts/time_manager.gd")
const CameraManagerScript := preload("res://scripts/camera_manager.gd")
const UIManagerScript := preload("res://scripts/ui_manager.gd")
const EventManagerScript := preload("res://scripts/event_manager.gd")
const AudioFeedbackScript := preload("res://scripts/audio_feedback.gd")
const AudioManagerScript := preload("res://scripts/audio_manager.gd")
const LightingManagerScript := preload("res://scripts/lighting_manager.gd")

var player_pos := Vector2(760, 1040)
var player_facing := Vector2.RIGHT
var player_moving := false
var player_input_enabled := true
var debug_visible := true
var walk_phase := 0.0
var camera_zoom := 0.88
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

var observe_rect := Rect2(Vector2(660, 720), Vector2(360, 240))
var airlock_rect := Rect2(Vector2(1760, 480), Vector2(145, 150))
var world_rect := Rect2(Vector2(80, 360), Vector2(2060, 960))

func _ready() -> void:
	_setup_input_map()
	_setup_managers()
	_setup_sky_layer()
	_setup_tile_map()
	_setup_player()
	_setup_ui()
	_setup_lights()
	game_state_manager.call("change_state", GameStateManagerScript.LANDING)
	observe_triggered = false
	queue_redraw()

func _setup_input_map() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("save_game", [KEY_F5])
	_add_key_action("load_game", [KEY_F9])
	_add_key_action("toggle_debug", [KEY_F3])

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
	# P3-05 legacy isolation: ARRIVAL PROTOTYPE-local child nodes, NOT the formal `/root/*`
	# autoloads. This scene is a self-contained prototype: it reaches these only through the
	# member variables below and never accesses any formal autoload or Full Save. Node names
	# are prefixed "ArrivalPrototype…" so the local real-time clock (`scripts/time_manager.gd`)
	# is not mistaken for the formal `/root/TimeManager` (`scripts/managers/TimeManager.gd`).
	game_state_manager = GameStateManagerScript.new()
	game_state_manager.name = "ArrivalPrototypeGameStateManager"
	add_child(game_state_manager)
	time_manager = TimeManagerScript.new()
	time_manager.name = "ArrivalPrototypeTimeManager"
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

func _setup_sky_layer() -> void:
	var sky := CanvasLayer.new()
	sky.name = "SkyLayer"
	sky.layer = -20
	add_child(sky)
	var bg := ColorRect.new()
	bg.name = "ColdSky"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("#07090f")
	sky.add_child(bg)
	var earth := TextureRect.new()
	earth.name = "EarthInSky"
	earth.texture = _create_earth_texture()
	earth.position = Vector2(740, 72)
	earth.size = Vector2(132, 132)
	earth.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	earth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.add_child(earth)
	var earth_hint := Label.new()
	earth_hint.name = "EarthHint"
	earth_hint.text = "EARTH"
	earth_hint.position = Vector2(784, 198)
	earth_hint.modulate = Color("#93b9d5", 0.55)
	earth_hint.add_theme_font_size_override("font_size", 11)
	sky.add_child(earth_hint)

func _create_earth_texture() -> Texture2D:
	var size := 160
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	for x in range(size):
		for y in range(size):
			var p := Vector2(float(x), float(y))
			var distance := p.distance_to(center)
			if distance > 70.0:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var shade: float = clamp(1.0 - distance / 100.0, 0.35, 1.0)
			var ocean := Color(0.08 * shade, 0.42 * shade, 0.78 * shade, 1.0)
			var cloud_mask := int(x * 3 + y * 5 + int(sin(float(x) * 0.11) * 18.0)) % 41
			var land_mask := int(x * 7 - y * 2 + 80) % 67
			var color := ocean
			if land_mask < 8 and distance < 62.0:
				color = Color(0.18 * shade, 0.62 * shade, 0.34 * shade, 1.0)
			if cloud_mask < 7:
				color = color.lerp(Color(0.88, 0.96, 1.0, 1.0), 0.62)
			if distance > 64.0:
				color.a = clamp((70.0 - distance) / 6.0, 0.0, 1.0)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

func _setup_tile_map() -> void:
	moon_tile_map = TileMapLayer.new()
	moon_tile_map.name = "MoonSurface"
	moon_tile_map.position = Vector2(0, 320)
	moon_tile_map.tile_set = _create_moon_tile_set()
	moon_tile_map.z_index = -5
	add_child(moon_tile_map)
	for x in range(-2, 36):
		for y in range(0, 18):
			moon_tile_map.set_cell(Vector2i(x, y), 0, Vector2i(abs(x * 3 + y) % 6, 0))

func _create_moon_tile_set() -> TileSet:
	var image := Image.create(TILE * 6, TILE, false, Image.FORMAT_RGBA8)
	for tile_x in range(6):
		for px in range(TILE):
			for py in range(TILE):
				var base: float = 0.055 + float(tile_x) * 0.008
				var grain: float = float((px * 17 + py * 9 + tile_x * 23) % 19) * 0.0022
				var crater: float = 0.0
				var local := Vector2(float(px - 32), float(py - 30))
				if local.length() < 12.0 + float(tile_x % 3) * 3.0:
					crater = -0.012
				var shade: float = clamp(base + grain + crater, 0.035, 0.14)
				image.set_pixel(tile_x * TILE + px, py, Color(shade * 0.86, shade * 0.90, shade + 0.035, 1.0))
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	for tile_x in range(6):
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
	camera.position_smoothing_speed = 4.5
	camera.zoom = Vector2(camera_zoom, camera_zoom)
	add_child(camera)
	camera_manager.call("configure", camera)
	_sync_player_visual()

func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	canvas.layer = 20
	add_child(canvas)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)
	ui_manager.call("bind_root", root)
	var hud := Label.new()
	hud.name = "MinimalHUD"
	hud.position = Vector2(24, 704)
	hud.size = Vector2(330, 126)
	hud.modulate = Color("#d8e7f2")
	hud.add_theme_font_size_override("font_size", 18)
	root.add_child(hud)
	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.position = Vector2(520, 770)
	prompt.size = Vector2(560, 44)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	root.add_child(prompt)
	var dialogue := Label.new()
	dialogue.name = "Dialogue"
	dialogue.visible = false
	dialogue.position = Vector2(400, 100)
	dialogue.size = Vector2(800, 128)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.modulate = Color("#dbe9f5")
	dialogue.add_theme_font_size_override("font_size", 23)
	root.add_child(dialogue)
	var debug := Label.new()
	debug.name = "Debug"
	debug.position = Vector2(1180, 24)
	debug.size = Vector2(390, 160)
	debug.modulate = Color("#d8e7f2", 0.78)
	debug.add_theme_font_size_override("font_size", 14)
	root.add_child(debug)

func _setup_lights() -> void:
	var global := CanvasModulate.new()
	global.name = "GlobalMoonLight"
	global.color = Color("#aeb8c8")
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
	if event.is_action_pressed("toggle_debug"):
		debug_visible = not debug_visible

func _process_movement(delta: float) -> void:
	var input := Vector2.ZERO
	if player_input_enabled:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_moving = input.length() > 0.01
	if player_moving:
		player_facing = input.normalized()
		walk_phase += delta * 10.0
		var next_pos := player_pos + player_facing * 165.0 * delta
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
		hud_alpha = move_toward(hud_alpha, 1.0, delta * 0.35)
		return
	if observe_rect.has_point(player_pos) and not player_moving:
		observe_hold += delta
	else:
		observe_hold = 0.0
	if observe_hold >= 5.0:
		_trigger_observe_earth()

func _trigger_observe_earth() -> void:
	observe_triggered = true
	hud_alpha = 0.32
	event_manager.call("trigger", "observe_earth", {"scene": "ArrivalLandingScene"}, true)
	camera_manager.call("lock_to", player_pos + Vector2(70, -170))
	var dialogue: Label = $UI/Root/Dialogue
	dialogue.text = "那里，是地球。\n距离：384,400公里。\n预计通信延迟：1.3秒。"
	dialogue.visible = true
	audio_manager.call("play_ui", 480.0, 0.08, 0.05)
	await get_tree().create_timer(3.2).timeout
	if is_instance_valid(dialogue):
		dialogue.visible = false
	camera_manager.call("unlock")

func _update_prompt() -> void:
	if airlock_rect.has_point(player_pos):
		prompt_text = "E / Enter 进入基地气闸"
	elif observe_rect.has_point(player_pos) and not observe_triggered:
		var left: float = max(0.0, 5.0 - observe_hold)
		prompt_text = "停下，望向地球 %.1fs" % left
	else:
		prompt_text = ""

func _try_interact() -> void:
	if airlock_rect.has_point(player_pos):
		entered_airlock = true
		game_state_manager.call("change_state", GameStateManagerScript.BASE_INTERIOR)
		event_manager.call("trigger", "entered_airlock", {}, true)
		_save_arrival()
		get_tree().change_scene_to_file(BASE_AIRLOCK_SCENE)

func _update_camera() -> void:
	var composition_target := player_pos + Vector2(140, -105)
	camera_manager.call("update_camera", camera, composition_target, camera_zoom)

func _update_ui() -> void:
	var hud: Label = $UI/Root/MinimalHUD
	hud.modulate.a = hud_alpha
	var clock_text := String(time_manager.call("clock_text"))
	hud.text = "O2: 98%%\nSuit: Stable\nComm Delay: 1.3s\nDay 01\nTime %s" % clock_text.substr(4)
	$UI/Root/Prompt.text = prompt_text
	var debug: Label = $UI/Root/Debug
	debug.visible = debug_visible
	debug.text = "Debug F3\nScene: ArrivalLandingScene\nState: %s\nPlayer: %.0f, %.0f\nTime: %s\nObserveEarthEvent: %s" % [
		String(game_state_manager.get("current_state")),
		player_pos.x,
		player_pos.y,
		String(time_manager.call("clock_text")),
		"true" if observe_triggered else "false"
	]

func _draw() -> void:
	_draw_far_horizon()
	_draw_tracks()
	_draw_transport_ship()
	_draw_distant_base()
	_draw_engineering_objects()
	_draw_airlock()
	_draw_surface_details()
	_draw_light_markers()

func _draw_far_horizon() -> void:
	draw_rect(Rect2(Vector2(-400, 350), Vector2(2900, 100)), Color("#0b0f17", 0.58))
	draw_line(Vector2(-400, 450), Vector2(2500, 450), Color("#202838", 0.65), 3)

func _draw_transport_ship() -> void:
	var base := Vector2(230, 1010)
	draw_circle(base + Vector2(120, 126), 90, Color("#0a0b0c", 0.35))
	draw_rect(Rect2(base, Vector2(360, 150)), Color("#b8b8ad"))
	draw_rect(Rect2(base + Vector2(34, 38), Vector2(124, 58)), Color("#3e4856"))
	draw_rect(Rect2(base + Vector2(235, -30), Vector2(74, 220)), Color("#77796f"))
	draw_rect(Rect2(base + Vector2(92, 145), Vector2(250, 30)), Color("#6f6b5f"))
	draw_line(base + Vector2(320, 160), base + Vector2(505, 210), Color("#b4ad9b"), 12)
	draw_line(base + Vector2(500, 210), base + Vector2(555, 230), Color("#877f6e"), 6)
	draw_circle(base + Vector2(72, 165), 28, Color("#e5863e", 0.48))
	draw_circle(base + Vector2(238, 180), 24, Color("#e5863e", 0.40))
	draw_string(ThemeDB.fallback_font, base + Vector2(74, 88), "TRANSPORT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#1d2430"))

func _draw_distant_base() -> void:
	var base := Vector2(1680, 480)
	draw_rect(Rect2(base, Vector2(250, 64)), Color("#252b33"))
	draw_rect(Rect2(base + Vector2(38, -42), Vector2(64, 44)), Color("#3c424b"))
	draw_rect(Rect2(base + Vector2(130, -26), Vector2(84, 28)), Color("#343a43"))
	for i in range(6):
		draw_circle(base + Vector2(34 + i * 38, 44), 6, Color("#e7b85d"))
	draw_line(base + Vector2(125, 0), base + Vector2(125, -96), Color("#777a78"), 3)
	draw_circle(base + Vector2(125, -104), 5, Color("#ff7a4d"))
	draw_rect(airlock_rect, Color("#4a4c4d"))
	draw_rect(airlock_rect.grow(-18), Color("#1b222c"))
	draw_circle(airlock_rect.get_center(), 58, Color("#e7b85d", 0.12))

func _draw_engineering_objects() -> void:
	draw_rect(Rect2(Vector2(1080, 800), Vector2(95, 54)), Color("#6c5c4d"))
	draw_rect(Rect2(Vector2(1205, 834), Vector2(72, 40)), Color("#8b7459"))
	draw_rect(Rect2(Vector2(1320, 650), Vector2(140, 26)), Color("#25384b"))
	draw_line(Vector2(940, 960), Vector2(1770, 555), Color("#211a16"), 5)
	draw_line(Vector2(980, 990), Vector2(1275, 860), Color("#312319"), 4)
	for i in range(8):
		var p := Vector2(650 + i * 58, 1015 - sin(float(i) * 0.8) * 20.0)
		draw_circle(p, 7, Color("#05070a", 0.26))

func _draw_airlock() -> void:
	draw_line(airlock_rect.position + Vector2(24, 22), airlock_rect.end - Vector2(24, 22), Color("#e7b85d"), 4)
	draw_string(ThemeDB.fallback_font, airlock_rect.position + Vector2(-12, -18), "AIRLOCK", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#e7b85d", 0.78))

func _draw_tracks() -> void:
	for i in range(20):
		var offset := sin(float(i) * 0.65) * 22.0
		draw_circle(Vector2(560 + i * 52, 1090 + offset), 9, Color("#06080b", 0.25))
		draw_circle(Vector2(560 + i * 52, 1130 + offset), 8, Color("#06080b", 0.22))

func _draw_surface_details() -> void:
	for i in range(26):
		var px := 170 + float((i * 137) % 1900)
		var py := 500 + float((i * 83) % 760)
		var radius := 3.0 + float(i % 4) * 2.0
		draw_circle(Vector2(px, py), radius, Color("#1f2630", 0.56))
	for i in range(10):
		var center := Vector2(300 + i * 185, 585 + float((i * 47) % 510))
		draw_arc(center, 32.0 + float(i % 4) * 12.0, 0.2, TAU * 0.82, 24, Color("#10151d", 0.26), 2)
	draw_circle(Vector2(440, 1155), 120, Color("#0a0807", 0.18))
	draw_circle(Vector2(1580, 610), 70, Color("#e7b85d", 0.06))

func _draw_light_markers() -> void:
	draw_circle(Vector2(1840, 552), 42, Color("#e7b85d", 0.12))
	draw_circle(Vector2(1810, 525), 86, Color("#e7b85d", 0.08))
	draw_circle(Vector2(430, 1165), 90, Color("#f0a44f", 0.08))

## P3-05 legacy isolation: ARRIVAL PROTOTYPE save/load. Writes/reads its own
## `user://arrival_prototype_save.json` only, serializing only this scene's local prototype
## managers/state. It never writes `full_save.json` and never touches formal `/root/*Manager`
## autoloads; FullSaveOrchestrator likewise never reads this file.
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
		"debug_visible": debug_visible,
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
	debug_visible = bool(data.get("debug_visible", debug_visible))
	observe_hold = 0.0
	_sync_player_visual()
