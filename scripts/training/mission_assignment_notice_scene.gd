extends Control

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")
const OpeningFlowManagerScript := preload("res://scripts/training/opening_flow_manager.gd")

var notice_panel: VBoxContainer

func _ready() -> void:
	var progress := TrainingManagerScript.load_progress()
	if not bool(progress.get("FinalAssessmentCompleted", false)):
		call_deferred("_return_to_training_start")
		return
	_build_notice()

func _build_notice() -> void:
	var background := ColorRect.new()
	background.color = Color("#06101a")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 26
	frame.offset_top = 24
	frame.offset_right = -26
	frame.offset_bottom = -24
	add_child(frame)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("#081520", 0.96)
	frame_style.border_color = Color("#34576e", 0.8)
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(4)
	frame_style.content_margin_left = 66
	frame_style.content_margin_top = 20
	frame_style.content_margin_right = 66
	frame_style.content_margin_bottom = 22
	frame.add_theme_stylebox_override("panel", frame_style)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	frame.add_child(root)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 16)
	root.add_child(top_bar)
	var org := Label.new()
	org.text = "国家深空生命科学中心训练控制系统"
	org.modulate = Color("#cfe3f2")
	org.add_theme_font_size_override("font_size", 17)
	top_bar.add_child(org)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)
	var training_id := Label.new()
	training_id.text = "训练编号  GHT-2068-0421"
	training_id.modulate = Color("#8fa3b2")
	training_id.add_theme_font_size_override("font_size", 15)
	top_bar.add_child(training_id)

	var title := Label.new()
	title.text = "广寒计划任务派遣通知书"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 36)
	root.add_child(title)

	root.add_child(_metadata_strip())
	notice_panel = VBoxContainer.new()
	notice_panel.add_theme_constant_override("separation", 18)
	root.add_child(notice_panel)
	_build_notice_body()

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 18)
	root.add_child(footer)
	_add_button(footer, "返回主菜单", _return_to_main_menu, false)
	_add_button(footer, "接受月面派遣", _accept_assignment, true)

func _metadata_strip() -> PanelContainer:
	var strip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0d1d2a", 0.92)
	style.border_color = Color("#29485e", 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 24
	style.content_margin_top = 16
	style.content_margin_right = 24
	style.content_margin_bottom = 16
	strip.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	strip.add_child(row)
	var items := [
		["文书编号", "GHO-MA-2068-0412"],
		["候选人", TrainingManagerScript.player_name()],
		["档案状态", "已通过最终考核"],
		["签发单位", "广寒计划任务委员会"],
		["签发日期", "2068-04-12"],
	]
	for item in items:
		row.add_child(_metadata_item(String(item[0]), String(item[1])))
	return strip

func _metadata_item(label_text: String, value_text: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(210, 70)
	box.add_theme_constant_override("separation", 7)
	var label := Label.new()
	label.text = label_text
	label.modulate = Color("#7192aa")
	label.add_theme_font_size_override("font_size", 14)
	box.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.modulate = Color("#d8e7f2")
	value.add_theme_font_size_override("font_size", 18)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(value)
	return box

func _build_notice_body() -> void:
	_clear_container(notice_panel)
	var document := PanelContainer.new()
	document.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0b1721", 0.94)
	style.border_color = Color("#2f5368", 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 46
	style.content_margin_top = 30
	style.content_margin_right = 46
	style.content_margin_bottom = 28
	document.add_theme_stylebox_override("panel", style)
	notice_panel.add_child(document)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 22)
	document.add_child(body)

	var salutation := Label.new()
	salutation.text = "致 %s：" % TrainingManagerScript.player_name()
	salutation.modulate = Color("#f0c766")
	salutation.add_theme_font_size_override("font_size", 25)
	body.add_child(salutation)

	var paragraphs := Label.new()
	paragraphs.text = "你已完成国家深空生命科学中心训练序列，并通过最终考核。\n\n经广寒计划任务委员会确认，\n你将被派往月球 · 广寒前哨，\n执行长期驻留与生命支持建设任务。"
	paragraphs.modulate = Color("#d8e7f2")
	paragraphs.add_theme_font_size_override("font_size", 21)
	paragraphs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(paragraphs)

	var rule := HSeparator.new()
	body.add_child(rule)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 24)
	body.add_child(cards)
	cards.add_child(_mission_card("任务地点", "月球 · 广寒前哨"))
	cards.add_child(_mission_card("任务类型", "长期驻留 / 生命支持建设"))
	cards.add_child(_mission_card("任务身份", "常驻开拓者"))

	var closing := Label.new()
	closing.text = "广寒前哨已经等待新的开拓者很久了。"
	closing.modulate = Color("#d8e7f2")
	closing.add_theme_font_size_override("font_size", 20)
	body.add_child(closing)

func _mission_card(title: String, value: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0e2030", 0.8)
	style.border_color = Color("#33546a", 0.76)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 22
	style.content_margin_top = 15
	style.content_margin_right = 22
	style.content_margin_bottom = 15
	card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var title_label := Label.new()
	title_label.text = title
	title_label.modulate = Color("#6fa7d8")
	title_label.add_theme_font_size_override("font_size", 18)
	box.add_child(title_label)
	var value_label := Label.new()
	value_label.text = value
	value_label.modulate = Color("#eaf4ff")
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(value_label)
	return card

func _decline_assignment() -> void:
	_clear_container(notice_panel)
	var document := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0b1721", 0.94)
	style.border_color = Color("#2f5368", 0.7)
	style.set_border_width_all(1)
	style.content_margin_left = 46
	style.content_margin_top = 34
	style.content_margin_right = 46
	style.content_margin_bottom = 34
	document.add_theme_stylebox_override("panel", style)
	notice_panel.add_child(document)
	var label := Label.new()
	label.text = "派遣已暂缓。\n\n候选人档案将保留。\n广寒计划仍将等待你的确认。"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color("#d8e7f2")
	label.add_theme_font_size_override("font_size", 24)
	document.add_child(label)

func _accept_assignment() -> void:
	OpeningFlowManagerScript.accept_moon_assignment(get_tree())

func _return_to_training_start() -> void:
	get_tree().change_scene_to_file(TrainingManagerScript.START_SCENE)

func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _add_button(parent: HBoxContainer, text: String, callback: Callable, primary := false) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(240, 48)
	if primary:
		button.modulate = Color("#9ac7e8")
	button.pressed.connect(callback)
	parent.add_child(button)

func _clear_container(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
