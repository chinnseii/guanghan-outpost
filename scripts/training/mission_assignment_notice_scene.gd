extends Control

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

var notice_panel: VBoxContainer

func _ready() -> void:
	var progress := TrainingManagerScript.load_progress()
	if not bool(progress.get("FinalAssessmentCompleted", false)):
		get_tree().change_scene_to_file(TrainingManagerScript.START_SCENE)
		return
	_build_notice()

func _build_notice() -> void:
	var background := ColorRect.new()
	background.color = Color("#07111b")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 120
	root.offset_top = 70
	root.offset_right = -120
	root.offset_bottom = -70
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var heading := Label.new()
	heading.text = "广寒计划任务派遣通知书"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.modulate = Color("#eaf4ff")
	heading.add_theme_font_size_override("font_size", 34)
	root.add_child(heading)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(panel)
	notice_panel = VBoxContainer.new()
	notice_panel.add_theme_constant_override("separation", 16)
	panel.add_child(notice_panel)

	var body := Label.new()
	body.text = "致 %s：\n\n你已完成国家深空生命科学中心训练序列，\n并通过最终考核。\n\n经广寒计划任务委员会确认，\n你将被派往月球 · 广寒前哨，\n执行长期驻留与生命支持建设任务。\n\n任务地点：月球 · 广寒前哨\n任务类型：长期驻留 / 生命支持建设\n任务身份：常驻开拓者\n\n广寒前哨已经等待新的开拓者很久了。" % TrainingManagerScript.player_name()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color("#d8e7f2")
	body.add_theme_font_size_override("font_size", 21)
	notice_panel.add_child(body)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	_add_button(footer, "暂缓派遣", _decline_assignment)
	var accept := Button.new()
	accept.text = "接受月面派遣"
	accept.custom_minimum_size = Vector2(240, 46)
	accept.modulate = Color("#9ac7e8")
	accept.pressed.connect(_accept_assignment)
	footer.add_child(accept)

func _decline_assignment() -> void:
	_clear_container(notice_panel)
	var label := Label.new()
	label.text = "派遣已暂缓。\n\n候选人档案将保留。\n广寒计划仍将等待你的确认。"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color("#d8e7f2")
	label.add_theme_font_size_override("font_size", 24)
	notice_panel.add_child(label)
	var button := Button.new()
	button.text = "返回主菜单"
	button.custom_minimum_size = Vector2(220, 44)
	button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	notice_panel.add_child(button)

func _accept_assignment() -> void:
	TrainingManagerScript.accept_assignment()
	get_tree().change_scene_to_file(TrainingManagerScript.BLACK_SCREEN)

func _add_button(parent: HBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 46)
	button.pressed.connect(callback)
	parent.add_child(button)

func _clear_container(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
