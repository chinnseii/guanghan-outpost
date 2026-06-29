extends Node2D

const SAMPLE_TEXTURE_PATH := "res://assets/sprites/robots/yutu_sample.png"
const MAINTENANCE_TEXTURE_PATH := "res://assets/sprites/robots/maintenance_bot.png"
const HAUL_TEXTURE_PATH := "res://assets/sprites/robots/hauler_bot.png"

var task := "idle"
var active := false
var anim_time := 0.0
var battery := 100.0
var charging := false
var sample_texture: Texture2D
var maintenance_texture: Texture2D
var haul_texture: Texture2D

func _ready() -> void:
	sample_texture = _load_png_texture(SAMPLE_TEXTURE_PATH)
	maintenance_texture = _load_png_texture(MAINTENANCE_TEXTURE_PATH)
	haul_texture = _load_png_texture(HAUL_TEXTURE_PATH)

func setup(new_task: String, is_active: bool, new_battery: float = 100.0, is_charging: bool = false) -> void:
	task = new_task
	active = is_active
	battery = new_battery
	charging = is_charging
	queue_redraw()

func _load_png_texture(path: String) -> Texture2D:
	if FileAccess.file_exists("%s.import" % path):
		var imported: Resource = ResourceLoader.load(path)
		if imported is Texture2D:
			return imported as Texture2D
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	var bob: float = sin(anim_time * 5.0) * 2.0 if active else 0.0
	var texture := _texture_for_task()
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2(-24, -18 + bob), Vector2(48, 48)), false)
		_draw_state_light(Vector2(18, -13 + bob))
		_draw_battery_bar(Vector2(-18, 30 + bob))
		return
	var body: Color = Color("#d8e0eb") if active else Color("#7d8796")
	draw_circle(Vector2(0, -8 + bob), 10, Color("#263242"))
	draw_circle(Vector2(0, -8 + bob), 7, body)
	draw_rect(Rect2(Vector2(-15, 0 + bob), Vector2(30, 18)), Color("#2f4059"))
	draw_rect(Rect2(Vector2(-10, 4 + bob), Vector2(20, 10)), body)
	draw_circle(Vector2(-10, 22 + bob), 5, Color("#202833"))
	draw_circle(Vector2(10, 22 + bob), 5, Color("#202833"))
	if task == "haul":
		draw_rect(Rect2(Vector2(18, 4 + bob), Vector2(12, 12)), Color("#d68b52"))
	elif task == "sample":
		draw_line(Vector2(-18, 10 + bob), Vector2(-30, 18 + bob), Color("#e7c66b"), 3)
	elif task == "maintenance":
		draw_line(Vector2(16, 4 + bob), Vector2(28, -8 + bob), Color("#98d5ff"), 3)
	_draw_state_light(Vector2(8, -12 + bob))
	_draw_battery_bar(Vector2(-18, 30 + bob))

func _texture_for_task() -> Texture2D:
	match task:
		"sample":
			return sample_texture
		"maintenance":
			return maintenance_texture
		"haul":
			return haul_texture
		"charging":
			return maintenance_texture
		_:
			return sample_texture

func _draw_state_light(pos: Vector2) -> void:
	var blink: float = 0.45 + 0.55 * abs(sin(anim_time * 6.0))
	var color := Color("#7dff9d")
	if charging:
		color = Color(0.45, 0.95, 1.0, blink)
	elif battery <= 20.0:
		color = Color(1.0, 0.35, 0.25, blink)
	elif not active:
		color = Color("#8792a0")
	draw_circle(pos, 4, color)

func _draw_battery_bar(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(36, 5)), Color("#202833"))
	var fill_width: float = clamp(battery / 100.0, 0.0, 1.0) * 34.0
	var color := Color("#7dff9d") if battery > 30.0 else Color("#ffb84d")
	if battery <= 15.0:
		color = Color("#ff5a5a")
	draw_rect(Rect2(pos + Vector2(1, 1), Vector2(fill_width, 3)), color)
