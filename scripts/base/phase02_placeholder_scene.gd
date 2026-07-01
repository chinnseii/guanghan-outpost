extends Control

func _ready() -> void:
	_build_screen()

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("#03070d")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 220
	root.offset_top = 150
	root.offset_right = -220
	root.offset_bottom = -130
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 22)
	add_child(root)

	var title := Label.new()
	title.text = "Phase 02：重建广寒前哨"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 38)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "REBUILD THE OUTPOST"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color("#7f98aa")
	subtitle.add_theme_font_size_override("font_size", 16)
	root.add_child(subtitle)

	var body := Label.new()
	body.text = "第一周驻留记录已归档。\n\n广寒前哨已恢复至最低稳定状态。\n下一阶段任务建议正在生成。\n\n下一阶段任务：外部太阳能阵列评估\n\n当前版本暂不进入 Sprint 09。"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color("#d8e7f2")
	body.add_theme_font_size_override("font_size", 24)
	root.add_child(body)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 16)
	root.add_child(footer)

	var main_menu := Button.new()
	main_menu.text = "返回主菜单"
	main_menu.custom_minimum_size = Vector2(220, 46)
	main_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	footer.add_child(main_menu)

