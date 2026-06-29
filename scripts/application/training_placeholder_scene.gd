extends Control

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("#101820")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var box := VBoxContainer.new()
	box.position = Vector2(420, 220)
	box.size = Vector2(760, 460)
	box.add_theme_constant_override("separation", 18)
	add_child(box)
	var title := Label.new()
	title.text = "国家训练序列即将开始"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	box.add_child(title)
	var body := Label.new()
	body.text = "当前版本训练模块尚未开放。\n\n这是 Sprint 04 的占位入口。"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 22)
	box.add_child(body)
	var arrival := Button.new()
	arrival.text = "Dev Only: 进入月球抵达原型"
	arrival.custom_minimum_size = Vector2(0, 46)
	arrival.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/arrival/ArrivalCinematicScene.tscn")
	)
	box.add_child(arrival)
	var back := Button.new()
	back.text = "返回主菜单"
	back.custom_minimum_size = Vector2(0, 46)
	back.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	box.add_child(back)
