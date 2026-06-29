extends Control

const PROFILE_PATH := "user://saves/application_profile.json"
const DEFAULT_NEXT_SCENE := "res://scenes/application/TrainingPlaceholderScene.tscn"

var lines := [
	"感谢你的选择。",
	"在你之前。",
	"已经有 7 位开拓者。",
	"替人类踏出了这一步。",
	"现在。",
	"轮到你了。",
]
var elapsed := 0.0
var shown_count := 0
var next_scene := DEFAULT_NEXT_SCENE
var text_label: Label

func _ready() -> void:
	_load_next_scene()
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	text_label = Label.new()
	text_label.position = Vector2(470, 275)
	text_label.size = Vector2(660, 360)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.modulate = Color("#dbe4eb")
	text_label.add_theme_font_size_override("font_size", 26)
	add_child(text_label)

func _process(delta: float) -> void:
	elapsed += delta
	var target_count: int = min(lines.size(), int(elapsed / 1.05) + 1)
	if target_count != shown_count:
		shown_count = target_count
		var visible_lines := ""
		for i in range(shown_count):
			visible_lines += lines[i]
			if i < shown_count - 1:
				visible_lines += "\n"
		text_label.text = visible_lines
	if elapsed > float(lines.size()) * 1.05 + 1.5:
		get_tree().change_scene_to_file(next_scene)

func _load_next_scene() -> void:
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	next_scene = String((parsed as Dictionary).get("NextSceneAfterApplication", DEFAULT_NEXT_SCENE))
