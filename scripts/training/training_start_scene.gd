extends Control

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

func _ready() -> void:
	_build_screen()

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("#07111b")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 120
	root.offset_top = 90
	root.offset_right = -120
	root.offset_bottom = -80
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	var title := Label.new()
	title.text = "国家深空生命科学中心训练控制系统"
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 32)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "NATIONAL TRAINING SEQUENCE"
	subtitle.modulate = Color("#6f8493")
	subtitle.add_theme_font_size_override("font_size", 14)
	root.add_child(subtitle)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	panel.add_child(body)

	var text := Label.new()
	text.text = "国家训练序列启动。\n\n候选人档案已同步。\n训练编号：GHT-2068-0421\n\n本训练将验证你在月面长期驻留任务中的基础操作能力。"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.modulate = Color("#d8e7f2")
	text.add_theme_font_size_override("font_size", 22)
	body.add_child(text)

	var modules := Label.new()
	modules.text = "训练路径：宇航服基础控制 → 气闸流程 → 供电维修 → 生命支持 → 植物状态诊断 → 最终考核"
	modules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modules.modulate = Color("#9fb4c4")
	modules.add_theme_font_size_override("font_size", 17)
	body.add_child(modules)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	_add_button(footer, "返回主菜单", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_add_button(footer, "开始训练", func():
		TrainingManagerScript.start_training()
		get_tree().change_scene_to_file(TrainingManagerScript.MODULE_01)
	)

func _add_button(parent: HBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 46)
	button.pressed.connect(callback)
	parent.add_child(button)
