extends Node2D

const SAVE_PATH := "user://arrival_prototype_save.json"
const GameStateManagerScript := preload("res://scripts/game_state_manager.gd")
const TimeManagerScript := preload("res://scripts/time_manager.gd")
const EventManagerScript := preload("res://scripts/event_manager.gd")
const AudioFeedbackScript := preload("res://scripts/audio_feedback.gd")
const AudioManagerScript := preload("res://scripts/audio_manager.gd")
const BASE_AIRLOCK_SCENE := "res://scenes/base/BaseAirlockEntryScene.tscn"

var player_x := 920.0
var player_facing := 1.0
var player_moving := false
var player_input_enabled := true
var debug_visible := false
var observe_hold := 0.0
var observe_triggered := false
var hud_alpha := 0.34
var dialogue_alpha := 0.0
var dialogue_text := ""
var prompt_text := "停下，望向地球"
var entry_prompt_delay := 0.0
var walk_phase := 0.0
var camera_lock_time := 0.0

var game_state_manager: Node
var time_manager: Node
var event_manager: Node
var audio_feedback: Node
var audio_manager: Node
var camera: Camera2D

func _ready() -> void:
	_setup_input_map()
	_setup_managers()
	_setup_camera()
	_setup_ui()
	game_state_manager.call("change_state", GameStateManagerScript.LANDING)
	observe_triggered = false
	queue_redraw()

func _setup_input_map() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E, KEY_ENTER])
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
	game_state_manager = GameStateManagerScript.new()
	game_state_manager.name = "GameStateManager"
	add_child(game_state_manager)
	time_manager = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	add_child(time_manager)
	time_manager.call("set_time", 1, 7, 42)
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

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "CinematicCamera"
	camera.enabled = true
	camera.position = Vector2(800, 450)
	camera.zoom = Vector2.ONE
	add_child(camera)

func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	canvas.layer = 20
	add_child(canvas)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)
	var hud := Label.new()
	hud.name = "MinimalHUD"
	hud.position = Vector2(28, 726)
	hud.size = Vector2(300, 118)
	hud.modulate = Color("#c7d8e4", 0.34)
	hud.add_theme_font_size_override("font_size", 16)
	root.add_child(hud)
	var dialogue := Label.new()
	dialogue.name = "DialogueLine"
	dialogue.position = Vector2(360, 642)
	dialogue.size = Vector2(880, 92)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue.modulate = Color("#dcecff", 0.0)
	dialogue.add_theme_font_size_override("font_size", 23)
	root.add_child(dialogue)
	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.position = Vector2(520, 770)
	prompt.size = Vector2(560, 44)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.modulate = Color("#e7d2a0", 0.82)
	prompt.add_theme_font_size_override("font_size", 18)
	root.add_child(prompt)
	var debug := Label.new()
	debug.name = "Debug"
	debug.position = Vector2(1180, 24)
	debug.size = Vector2(390, 160)
	debug.modulate = Color("#d8e7f2", 0.78)
	debug.add_theme_font_size_override("font_size", 14)
	root.add_child(debug)

func _process(delta: float) -> void:
	_process_movement(delta)
	_process_observe(delta)
	_update_camera(delta)
	_update_ui()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and observe_triggered and _entry_prompt_ready():
		_save_cinematic()
		get_tree().change_scene_to_file(BASE_AIRLOCK_SCENE)
	if event.is_action_pressed("save_game"):
		_save_cinematic()
	if event.is_action_pressed("load_game"):
		_load_cinematic()
	if event.is_action_pressed("toggle_debug"):
		debug_visible = not debug_visible

func _process_movement(delta: float) -> void:
	var axis := 0.0
	if player_input_enabled:
		axis = Input.get_axis("move_left", "move_right")
	player_moving = abs(axis) > 0.01
	if player_moving:
		player_facing = sign(axis)
		walk_phase += delta * 8.0
		player_x = clamp(player_x + axis * 92.0 * delta, 780.0, 1120.0)

func _process_observe(delta: float) -> void:
	if observe_triggered:
		hud_alpha = move_toward(hud_alpha, 0.12, delta * 0.22)
		entry_prompt_delay = max(0.0, entry_prompt_delay - delta)
		if entry_prompt_delay > 1.0:
			dialogue_alpha = 1.0
		else:
			dialogue_alpha = move_toward(dialogue_alpha, 0.0, delta * 1.35)
		return
	if player_moving:
		observe_hold = 0.0
	else:
		observe_hold += delta
	if observe_hold >= 5.0:
		_trigger_observe_earth()

func _trigger_observe_earth() -> void:
	observe_triggered = true
	hud_alpha = 0.08
	dialogue_alpha = 1.0
	entry_prompt_delay = 4.2
	camera_lock_time = 3.2
	dialogue_text = "那里，是地球。\n距离：384,400公里。\n预计通信延迟：1.3秒。"
	event_manager.call("trigger", "observe_earth", {"scene": "ArrivalCinematicScene"}, true)
	audio_manager.call("play_ui", 480.0, 0.08, 0.05)

func _update_camera(delta: float) -> void:
	if camera_lock_time > 0.0:
		camera_lock_time = max(0.0, camera_lock_time - delta)
		camera.position = camera.position.lerp(Vector2(820, 430), delta * 1.6)
	else:
		var target := Vector2(800 + (player_x - 920.0) * 0.06, 450)
		camera.position = camera.position.lerp(target, delta * 1.8)

func _update_ui() -> void:
	var clock_text := String(time_manager.call("clock_text"))
	var hud: Label = $UI/Root/MinimalHUD
	hud.modulate.a = hud_alpha
	hud.text = "O2: 98%%\nSuit: Stable\nComm Delay: 1.3s\nDay 01\nTime %s" % clock_text.substr(4)
	var dialogue: Label = $UI/Root/DialogueLine
	dialogue.text = dialogue_text
	dialogue.modulate.a = dialogue_alpha
	var prompt: Label = $UI/Root/Prompt
	if observe_triggered:
		prompt_text = "E / Enter 前往基地气闸" if _entry_prompt_ready() else ""
	else:
		var left: float = max(0.0, 5.0 - observe_hold)
		prompt_text = "停下，望向地球 %.1fs" % left
	prompt.text = prompt_text
	var debug: Label = $UI/Root/Debug
	debug.visible = debug_visible
	debug.text = "Debug F3\nScene: ArrivalCinematicScene\nState: %s\nPlayer X: %.0f\nTime: %s\nObserveEarthEvent: %s" % [
		String(game_state_manager.get("current_state")),
		player_x,
		clock_text,
		"true" if observe_triggered else "false"
	]

func _entry_prompt_ready() -> bool:
	return entry_prompt_delay <= 0.0 and dialogue_alpha <= 0.08

func _draw() -> void:
	_draw_sky()
	_draw_distant_layer()
	_draw_midground()
	_draw_foreground()

func _draw_sky() -> void:
	draw_rect(Rect2(Vector2(-80, -80), Vector2(1760, 620)), Color("#03050a"))
	for i in range(72):
		var x := float((i * 137) % 1600)
		var y := float(28 + (i * 53) % 360)
		var alpha := 0.22 + float(i % 5) * 0.08
		draw_circle(Vector2(x, y), 1.0 + float(i % 2), Color("#d9e8ff", alpha))
	_draw_earth(Vector2(860, 146), 50.0)

func _draw_earth(center: Vector2, radius: float) -> void:
	draw_circle(center, radius + 34.0, Color("#63c9ff", 0.035))
	draw_circle(center, radius + 18.0, Color("#7edbff", 0.075))
	draw_circle(center, radius + 4.0, Color("#c8f4ff", 0.12))
	draw_circle(center, radius, Color("#43adf2"))
	draw_circle(center + Vector2(-10, -7), 14, Color("#f3fbff", 0.78))
	draw_circle(center + Vector2(12, 10), 11, Color("#8ad7a6", 0.70))
	draw_circle(center + Vector2(0, -19), 7, Color("#e8f8ff", 0.60))
	draw_circle(center + Vector2(17, -13), 8, Color("#e7f7ff", 0.28))
	draw_circle(center + Vector2(-22, 18), 14, Color("#0a1a2a", 0.22))
	draw_arc(center, radius + 2.0, 0.6, 5.2, 72, Color("#d3f6ff", 0.26), 1)

func _draw_distant_layer() -> void:
	draw_polygon(
		[Vector2(-100, 420), Vector2(250, 370), Vector2(640, 402), Vector2(1040, 368), Vector2(1730, 410), Vector2(1730, 560), Vector2(-100, 560)],
		[Color("#101620")]
	)
	draw_line(Vector2(-80, 456), Vector2(1680, 426), Color("#263244", 0.68), 3)
	var base := Vector2(1210, 388)
	draw_rect(Rect2(base, Vector2(250, 42)), Color("#161b22"))
	draw_rect(Rect2(base + Vector2(44, -28), Vector2(58, 30)), Color("#1d232c"))
	draw_rect(Rect2(base + Vector2(138, -18), Vector2(74, 20)), Color("#1b2028"))
	for i in range(6):
		var light_pos := base + Vector2(32 + i * 36, 32)
		draw_circle(light_pos, 3, Color("#f3c46e", 0.95))
		draw_circle(light_pos, 11, Color("#e9b763", 0.16))
	draw_circle(base + Vector2(124, 2), 82, Color("#e9b763", 0.085))
	draw_line(base + Vector2(22, 42), base + Vector2(236, 42), Color("#f0c766", 0.18), 2)

func _draw_midground() -> void:
	draw_polygon(
		[Vector2(-100, 510), Vector2(350, 500), Vector2(850, 540), Vector2(1280, 505), Vector2(1730, 526), Vector2(1730, 980), Vector2(-100, 980)],
		[Color("#111722")]
	)
	for i in range(18):
		var x := 80.0 + float((i * 173) % 1480)
		var y := 560.0 + float((i * 61) % 270)
		draw_arc(Vector2(x, y), 22.0 + float(i % 4) * 9.0, 0.2, TAU * 0.8, 20, Color("#202838", 0.35), 2)
	for i in range(16):
		draw_circle(Vector2(460 + i * 48, 705 + sin(float(i) * 0.7) * 15.0), 5, Color("#05070a", 0.28))
	draw_line(Vector2(620, 725), Vector2(1220, 565), Color("#221916"), 4)
	draw_line(Vector2(660, 750), Vector2(1080, 628), Color("#302117"), 3)

func _draw_foreground() -> void:
	_draw_transport_ship()
	_draw_player()
	draw_circle(Vector2(455, 804), 130, Color("#0b0704", 0.20))
	draw_circle(Vector2(604, 802), 84, Color("#e3863e", 0.055))
	for i in range(8):
		draw_circle(Vector2(475 + i * 32, 818 + sin(float(i)) * 12.0), 18.0 + float(i % 3) * 8.0, Color("#b78c62", 0.035))

func _draw_transport_ship() -> void:
	var base := Vector2(230, 610)
	draw_polygon(
		[base + Vector2(-18, 130), base + Vector2(82, 52), base + Vector2(305, 35), base + Vector2(452, 112), base + Vector2(404, 198), base + Vector2(72, 194)],
		[Color("#8f958f")]
	)
	draw_polygon(
		[base + Vector2(38, 118), base + Vector2(108, 76), base + Vector2(308, 74), base + Vector2(405, 126), base + Vector2(376, 160), base + Vector2(86, 158)],
		[Color("#b6b8ad")]
	)
	draw_rect(Rect2(base + Vector2(88, 82), Vector2(116, 50)), Color("#334151"))
	draw_rect(Rect2(base + Vector2(302, 0), Vector2(78, 224)), Color("#5f6663"))
	draw_line(base + Vector2(88, 158), base + Vector2(388, 158), Color("#555b58"), 3)
	draw_line(base + Vector2(128, 76), base + Vector2(128, 158), Color("#68706c"), 3)
	draw_line(base + Vector2(242, 72), base + Vector2(242, 158), Color("#68706c"), 3)
	draw_line(base + Vector2(382, 170), base + Vector2(590, 220), Color("#b7ad98"), 16)
	draw_line(base + Vector2(590, 220), base + Vector2(680, 240), Color("#7e7667"), 8)
	draw_line(base + Vector2(388, 186), base + Vector2(584, 232), Color("#d0c4ab"), 3)
	draw_line(base + Vector2(404, 122), base + Vector2(404, 224), Color("#4d534f"), 6)
	draw_line(base + Vector2(112, 190), base + Vector2(100, 238), Color("#55534c"), 5)
	draw_line(base + Vector2(318, 198), base + Vector2(342, 244), Color("#55534c"), 5)
	draw_circle(base + Vector2(62, 184), 30, Color("#f09a47", 0.28))
	draw_circle(base + Vector2(250, 196), 24, Color("#f09a47", 0.22))
	draw_circle(base + Vector2(168, 220), 86, Color("#e3863e", 0.045))

func _draw_player() -> void:
	var feet := Vector2(player_x, 748)
	var bob := sin(walk_phase) * 2.0 if player_moving else 0.0
	draw_ellipse(feet + Vector2(0, 13), 16.0, 4.0, Color("#020305", 0.35))
	draw_rect(Rect2(feet + Vector2(-8, -46 + bob), Vector2(16, 32)), Color("#cfd9e1"))
	draw_rect(Rect2(feet + Vector2(-5, -38 + bob), Vector2(10, 18)), Color("#8795a0"))
	draw_rect(Rect2(feet + Vector2(-10, -36 + bob), Vector2(20, 15)), Color("#b8c2ca", 0.9))
	draw_circle(feet + Vector2(0, -56 + bob), 14, Color("#e5edf2"))
	draw_circle(feet + Vector2(0, -56 + bob), 8, Color("#ccd7df"))
	draw_line(feet + Vector2(-5, -62 + bob), feet + Vector2(5, -62 + bob), Color("#8da0ad", 0.65), 2)
	draw_line(feet + Vector2(-8, -23 + bob), feet + Vector2(-15, -5 + bob), Color("#c3cdd4"), 4)
	draw_line(feet + Vector2(8, -23 + bob), feet + Vector2(15, -5 + bob), Color("#c3cdd4"), 4)
	draw_line(feet + Vector2(-5, -14 + bob), feet + Vector2(-10, 4), Color("#c8d1d8"), 4)
	draw_line(feet + Vector2(5, -14 + bob), feet + Vector2(10, 4), Color("#c8d1d8"), 4)

func _save_cinematic() -> void:
	var data := {
		"current_scene": "res://scenes/arrival/ArrivalCinematicScene.tscn",
		"cinematic_player_x": player_x,
		"game_state": game_state_manager.call("serialize"),
		"time": time_manager.call("serialize"),
		"events": event_manager.call("serialize"),
		"observe_triggered": observe_triggered,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _load_cinematic() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	player_x = float(data.get("cinematic_player_x", player_x))
	game_state_manager.call("deserialize", data.get("game_state", {}))
	time_manager.call("deserialize", data.get("time", {}))
	event_manager.call("deserialize", data.get("events", {}))
	observe_triggered = bool(data.get("observe_triggered", event_manager.call("has_fired", "observe_earth")))
	observe_hold = 0.0
	dialogue_alpha = 0.0
	entry_prompt_delay = 0.0
