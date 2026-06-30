extends Control

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

var lines := [
	"感谢你的选择。",
	"在你之前。",
	"已经有17位开拓者。",
	"替人类迈出了这一步。",
	"现在。",
	"轮到你了。",
]
var line_index := 0
var timer := 0.0
var label: Label

func _ready() -> void:
	var progress := TrainingManagerScript.load_progress()
	if not bool(progress.get("MissionAssignmentAccepted", false)):
		get_tree().change_scene_to_file(TrainingManagerScript.MISSION_NOTICE)
		return
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	label = Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color("#d8e7f2")
	label.add_theme_font_size_override("font_size", 30)
	add_child(label)

func _process(delta: float) -> void:
	timer += delta
	if timer < 1.15:
		return
	timer = 0.0
	if line_index < lines.size():
		label.text += ("\n\n" if not label.text.is_empty() else "") + lines[line_index]
		line_index += 1
	else:
		get_tree().change_scene_to_file("res://scenes/arrival/ArrivalCinematicScene.tscn")
