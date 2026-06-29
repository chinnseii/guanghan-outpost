extends Node2D

const GameStateManagerScript := preload("res://scripts/game_state_manager.gd")
const TimeManagerScript := preload("res://scripts/time_manager.gd")

var game_state_manager: Node
var time_manager: Node

func _ready() -> void:
	game_state_manager = GameStateManagerScript.new()
	add_child(game_state_manager)
	game_state_manager.call("change_state", GameStateManagerScript.BASE_INTERIOR)
	time_manager = TimeManagerScript.new()
	add_child(time_manager)
	time_manager.call("set_time", 1, 7, 48)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2(0, 0), Vector2(1600, 900)), Color("#111820"))
	draw_rect(Rect2(Vector2(430, 210), Vector2(740, 420)), Color("#2b3440"))
	draw_rect(Rect2(Vector2(470, 250), Vector2(660, 340)), Color("#d8e0eb"))
	draw_rect(Rect2(Vector2(710, 565), Vector2(180, 34)), Color("#e7b85d"))
	draw_string(ThemeDB.fallback_font, Vector2(520, 330), "BaseInterior_Test / 旧基地入口测试", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#15191f"))
	draw_string(ThemeDB.fallback_font, Vector2(520, 382), "你已经从月面气闸进入旧基地。", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#263242"))
	draw_string(ThemeDB.fallback_font, Vector2(520, 430), "这里后续会承载：生活痕迹、生命支持、最后一株植物。", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#263242"))
