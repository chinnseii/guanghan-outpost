class_name TrainingModuleScreenPresenter
extends RefCounted

const GuanghanPopupModal := preload("res://scripts/ui/popup_modal.gd")

var left_panel: PanelContainer
var objective_label: Label
var hud_label: Label
var hint_label: Label
var diagnosis_panel: VBoxContainer
var log_label: Label
var training_area: Control
var footer_buttons: HBoxContainer
var footer_save_button: Button
var footer_main_button: Button

var popup: GuanghanPopupModal
var suit_status_scrim: ColorRect
var suit_status_modal: PanelContainer
var suit_status_text_label: Label
var suit_status_confirm_button: Button
var suit_status_panel_visible := false

var minimal_hud: PanelContainer
var minimal_title_label: Label
var minimal_objective_label: Label
var minimal_time_label: Label
var briefing_scrim: ColorRect
var briefing_modal: PanelContainer
var briefing_confirm_button: Button
var pause_panel: PanelContainer
var pause_resume_button: Button
var pause_tasks_button: Button
var pause_main_button: Button
var interaction_panel: PanelContainer
var interaction_label: Label
var interaction_bar: ProgressBar
var prompt_label: Label

func build_screen(owner: Node, module_data: Dictionary, module_id: String, callbacks: Dictionary) -> void:
	var background := ColorRect.new()
	background.color = Color("#06101a")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	owner.add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 36
	root.offset_top = 24
	root.offset_right = -36
	root.offset_bottom = -32
	root.add_theme_constant_override("separation", 10)
	owner.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	root.add_child(header)
	_add_header_label(header, "国家深空生命科学中心训练控制系统", Vector2(620, 46), 24, Color("#eaf4ff"))
	_add_header_label(header, String(module_data.get("subtitle", "TRAINING MODULE")), Vector2(420, 46), 13, Color("#6f8493"))
	_add_header_label(header, "训练编号  GHT-2068-0421", Vector2(280, 46), 14, Color("#8fa3b2"))

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)

	left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(420, 0)
	left_panel.visible = false
	row.add_child(left_panel)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	left_panel.add_child(left)

	var title := Label.new()
	title.text = String(module_data.get("title", "训练模块"))
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 24)
	left.add_child(title)

	_add_panel_section_label(left, "当前目标")
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.modulate = Color("#d8e7f2")
	objective_label.add_theme_font_size_override("font_size", 18)
	left.add_child(objective_label)

	_add_panel_section_label(left, "系统状态")
	hud_label = Label.new()
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_label.modulate = Color("#9fb4c4")
	hud_label.add_theme_font_size_override("font_size", 15)
	left.add_child(hud_label)

	_add_panel_section_label(left, "操作步骤")
	hint_label = Label.new()
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.modulate = Color("#86c7ff")
	hint_label.add_theme_font_size_override("font_size", 16)
	left.add_child(hint_label)

	diagnosis_panel = VBoxContainer.new()
	diagnosis_panel.visible = false
	diagnosis_panel.add_theme_constant_override("separation", 8)
	left.add_child(diagnosis_panel)

	_add_panel_section_label(left, "输入提示")
	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.modulate = Color("#d8e7f2")
	log_label.add_theme_font_size_override("font_size", 15)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(log_label)

	var area_panel := PanelContainer.new()
	area_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(area_panel)
	training_area = Control.new()
	training_area.custom_minimum_size = Vector2(760, 520)
	area_panel.add_child(training_area)

	footer_buttons = HBoxContainer.new()
	footer_buttons.alignment = BoxContainer.ALIGNMENT_END
	footer_buttons.custom_minimum_size = Vector2(0, 48)
	footer_buttons.add_theme_constant_override("separation", 12)
	footer_buttons.visible = false
	root.add_child(footer_buttons)
	footer_save_button = add_footer_button("保存训练进度", _callback(callbacks, "save_progress"))
	footer_main_button = add_footer_button("返回主菜单", _callback(callbacks, "return_main"))

func build_training_overlays(owner: Node, module_data: Dictionary, module_id: String, completed: bool, callbacks: Dictionary) -> void:
	minimal_hud = PanelContainer.new()
	minimal_hud.position = Vector2(60, 84)
	minimal_hud.custom_minimum_size = Vector2(390, 118)
	owner.add_child(minimal_hud)
	var hud_box := VBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 6)
	minimal_hud.add_child(hud_box)
	minimal_title_label = Label.new()
	minimal_title_label.modulate = Color("#eaf4ff")
	minimal_title_label.add_theme_font_size_override("font_size", 17)
	hud_box.add_child(minimal_title_label)
	minimal_objective_label = Label.new()
	minimal_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	minimal_objective_label.modulate = Color("#f0c766")
	minimal_objective_label.add_theme_font_size_override("font_size", 15)
	hud_box.add_child(minimal_objective_label)
	minimal_time_label = Label.new()
	minimal_time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	minimal_time_label.modulate = Color("#9fb4c4")
	minimal_time_label.add_theme_font_size_override("font_size", 13)
	hud_box.add_child(minimal_time_label)
	var key_hint := Label.new()
	key_hint.text = "Tab 查看任务    Esc 暂停"
	key_hint.modulate = Color("#7f93a3")
	key_hint.add_theme_font_size_override("font_size", 12)
	hud_box.add_child(key_hint)
	_build_briefing_modal(owner, module_data, completed, callbacks)
	_build_pause_panel(owner, callbacks)
	_build_interaction_panel(owner)
	_build_diagnosis_modal(owner)
	_build_suit_status_panel(owner, module_id, callbacks)

func update_hud(view_model: Dictionary) -> void:
	if objective_label != null:
		objective_label.text = String(view_model.get("objective_text", ""))
	if minimal_title_label != null:
		minimal_title_label.text = String(view_model.get("minimal_title", ""))
	if minimal_objective_label != null:
		minimal_objective_label.text = String(view_model.get("minimal_objective", ""))
	if minimal_time_label != null:
		minimal_time_label.text = String(view_model.get("minimal_time", ""))
	if hud_label != null:
		hud_label.text = String(view_model.get("hud_text", ""))
	if hint_label != null:
		hint_label.text = String(view_model.get("hint_text", ""))

func set_log_text(text: String) -> void:
	if log_label != null:
		log_label.text = text

func append_log(line: String) -> void:
	if log_label != null and not line.is_empty():
		log_label.text += line + "\n"

func set_briefing_visible(value: bool) -> void:
	if briefing_scrim != null:
		briefing_scrim.visible = value
	if briefing_modal != null:
		briefing_modal.visible = value

func show_entry_blocked_dialog(return_callback: Callable) -> void:
	set_briefing_visible(true)
	if briefing_modal == null:
		return
	_clear_container(briefing_modal)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	briefing_modal.add_child(box)
	var title := Label.new()
	title.text = "无法进入训练"
	title.modulate = Color("#ff6b6b")
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color("#c6d5df")
	body.add_theme_font_size_override("font_size", 16)
	body.text = "未检测到宇航服穿戴状态。无法进入月面真空模拟环境。\n\n请先完成宇航服穿戴，再进入本训练模块。"
	box.add_child(body)
	var button := Button.new()
	button.text = "返回主菜单"
	button.custom_minimum_size = Vector2(0, 44)
	if return_callback.is_valid():
		button.pressed.connect(return_callback)
	box.add_child(button)

func set_pause_visible(value: bool) -> void:
	if pause_panel != null:
		pause_panel.visible = value

func set_suit_status_panel_visible(value: bool) -> void:
	suit_status_panel_visible = value
	if suit_status_scrim != null:
		suit_status_scrim.visible = value
	if suit_status_modal != null:
		suit_status_modal.visible = value

func toggle_suit_status_panel(suit_data: Dictionary, module_id: String) -> void:
	set_suit_status_panel_visible(not suit_status_panel_visible)
	if suit_status_panel_visible:
		refresh_suit_status_panel(suit_data, module_id)

func refresh_suit_status_panel(suit_data: Dictionary, module_id: String) -> void:
	if suit_status_text_label == null:
		return
	if not bool(suit_data.get("available", true)):
		suit_status_text_label.text = "宇航服数据不可用。"
		return
	var text := "宇航服状态\n\n氧气储备：%.0f%%\n电力储备：%.0f%%\n移动倍率：%.2f" % [
		float(suit_data.get("oxygen", 0.0)),
		float(suit_data.get("power", 0.0)),
		float(suit_data.get("speed_multiplier", 0.8)),
	]
	if module_id == "power_repair":
		text += "\n\n当前环境：真空模拟\n外勤任务：太阳能阵列维修"
	else:
		text += "\n\n初代宇航服会降低行动速度。后续升级可将移动倍率提升至 1.00。"
	suit_status_text_label.text = text

func sync_overlay_visibility(view_model: Dictionary) -> void:
	var briefing_visible := bool(view_model.get("briefing_visible", false))
	var mission_panel_visible := bool(view_model.get("mission_panel_visible", false))
	var pause_visible := bool(view_model.get("pause_visible", false))
	var diagnosis_panel_open := diagnosis_panel != null and diagnosis_panel.visible
	var diagnosis_open := diagnosis_panel_open or is_popup_open()
	var suit_status_open := suit_status_modal != null and suit_status_modal.visible
	set_briefing_visible(briefing_visible)
	if left_panel != null:
		left_panel.visible = mission_panel_visible or diagnosis_panel_open
	if minimal_hud != null:
		minimal_hud.visible = not briefing_visible and not mission_panel_visible and not pause_visible and not diagnosis_open and not suit_status_open
	if prompt_label != null and (briefing_visible or mission_panel_visible or pause_visible or diagnosis_open or suit_status_open):
		prompt_label.visible = false

func set_interaction_running(start_text: String) -> void:
	if interaction_panel != null:
		interaction_panel.visible = true
	if interaction_label != null:
		interaction_label.text = start_text
	if interaction_bar != null:
		interaction_bar.value = 0.0

func set_interaction_progress(value: float) -> void:
	if interaction_bar != null:
		interaction_bar.value = clamp(value, 0.0, 1.0)

func finish_interaction(done_text: String) -> void:
	if interaction_label != null:
		interaction_label.text = done_text
	if interaction_bar != null:
		interaction_bar.value = 1.0

func hide_interaction() -> void:
	if interaction_panel != null:
		interaction_panel.visible = false

func add_footer_button(text: String, callback: Callable) -> Button:
	if footer_buttons == null:
		return null
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(190, 42)
	button.focus_mode = Control.FOCUS_NONE
	if callback.is_valid():
		button.pressed.connect(callback)
	footer_buttons.add_child(button)
	return button

func clear_footer_buttons() -> void:
	_clear_container(footer_buttons)

func open_popup(config: Dictionary) -> void:
	if popup != null:
		popup.open(config)

func add_popup_action_control(control: Control) -> void:
	if popup != null:
		popup.add_action_control(control)

func close_popup() -> void:
	if popup != null:
		popup.close()

func is_popup_open() -> bool:
	return popup != null and popup.is_open()

func set_popup_body_text(text: String) -> void:
	if popup != null:
		popup.set_body_text(text)

func set_room_prompt(text: String, position: Vector2, visible: bool) -> void:
	if prompt_label == null:
		return
	prompt_label.text = text
	prompt_label.position = position
	prompt_label.visible = visible

func _build_diagnosis_modal(owner: Node) -> void:
	popup = GuanghanPopupModal.new()
	owner.add_child(popup)

func _build_suit_status_panel(owner: Node, module_id: String, callbacks: Dictionary) -> void:
	suit_status_scrim = ColorRect.new()
	suit_status_scrim.color = Color("#02070d", 0.78)
	suit_status_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	suit_status_scrim.visible = false
	owner.add_child(suit_status_scrim)

	suit_status_modal = PanelContainer.new()
	suit_status_modal.set_anchors_preset(Control.PRESET_CENTER)
	suit_status_modal.offset_left = -260
	suit_status_modal.offset_top = -190
	suit_status_modal.offset_right = 260
	suit_status_modal.offset_bottom = 190
	suit_status_modal.visible = false
	owner.add_child(suit_status_modal)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#170a1e", 0.97)
	style.border_color = Color("#8a5fa8", 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	suit_status_modal.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	suit_status_modal.add_child(box)
	var title := Label.new()
	title.text = "宇航服状态"
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	suit_status_text_label = Label.new()
	suit_status_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	suit_status_text_label.modulate = Color("#e8d9f5")
	suit_status_text_label.add_theme_font_size_override("font_size", 16)
	box.add_child(suit_status_text_label)
	suit_status_confirm_button = Button.new()
	suit_status_confirm_button.text = "确认外勤状态" if module_id == "power_repair" else "确认状态"
	suit_status_confirm_button.custom_minimum_size = Vector2(0, 42)
	var confirm_callback := _callback(callbacks, "confirm_suit_status")
	if confirm_callback.is_valid():
		suit_status_confirm_button.pressed.connect(confirm_callback)
	box.add_child(suit_status_confirm_button)

func _build_briefing_modal(owner: Node, module_data: Dictionary, completed: bool, callbacks: Dictionary) -> void:
	briefing_scrim = ColorRect.new()
	briefing_scrim.color = Color("#02070d", 0.78)
	briefing_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	briefing_scrim.visible = not completed
	owner.add_child(briefing_scrim)

	briefing_modal = PanelContainer.new()
	briefing_modal.set_anchors_preset(Control.PRESET_CENTER)
	briefing_modal.offset_left = -310
	briefing_modal.offset_top = -190
	briefing_modal.offset_right = 310
	briefing_modal.offset_bottom = 190
	briefing_modal.visible = not completed
	owner.add_child(briefing_modal)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	briefing_modal.add_child(box)
	var title := Label.new()
	title.text = String(module_data.get("title", "训练模块"))
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "训练入口简报"
	subtitle.modulate = Color("#86c7ff")
	subtitle.add_theme_font_size_override("font_size", 16)
	box.add_child(subtitle)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color("#c6d5df")
	body.add_theme_font_size_override("font_size", 16)
	body.text = "本模块将在模拟训练舱内记录你的操作顺序。\n\n靠近当前目标后，按 E / Enter 交互。\n按 Tab 可随时查看完整任务面板。"
	box.add_child(body)
	briefing_confirm_button = Button.new()
	briefing_confirm_button.text = "确认，开始训练"
	briefing_confirm_button.custom_minimum_size = Vector2(0, 44)
	var close_callback := _callback(callbacks, "close_briefing")
	if close_callback.is_valid():
		briefing_confirm_button.pressed.connect(close_callback)
	box.add_child(briefing_confirm_button)

func _build_pause_panel(owner: Node, callbacks: Dictionary) -> void:
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -210
	pause_panel.offset_top = -150
	pause_panel.offset_right = 210
	pause_panel.offset_bottom = 150
	pause_panel.visible = false
	owner.add_child(pause_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	pause_panel.add_child(box)
	var title := Label.new()
	title.text = "训练暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	pause_resume_button = _add_modal_button(box, "继续训练", _callback(callbacks, "resume_training"))
	pause_tasks_button = _add_modal_button(box, "查看任务", _callback(callbacks, "show_tasks"))
	pause_main_button = _add_modal_button(box, "返回主菜单", _callback(callbacks, "return_main"))

func _build_interaction_panel(owner: Node) -> void:
	interaction_panel = PanelContainer.new()
	interaction_panel.position = Vector2(520, 720)
	interaction_panel.custom_minimum_size = Vector2(560, 78)
	interaction_panel.visible = false
	owner.add_child(interaction_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	interaction_panel.add_child(box)
	interaction_label = Label.new()
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.modulate = Color("#eaf4ff")
	interaction_label.add_theme_font_size_override("font_size", 16)
	box.add_child(interaction_label)
	interaction_bar = ProgressBar.new()
	interaction_bar.min_value = 0.0
	interaction_bar.max_value = 1.0
	interaction_bar.value = 0.0
	interaction_bar.show_percentage = false
	interaction_bar.custom_minimum_size = Vector2(0, 12)
	box.add_child(interaction_bar)

func _add_header_label(parent: HBoxContainer, text: String, min_size: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = min_size
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func _add_panel_section_label(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color("#86c7ff")
	label.add_theme_font_size_override("font_size", 13)
	parent.add_child(label)

func _add_modal_button(parent: VBoxContainer, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 42)
	if callback.is_valid():
		button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _clear_container(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.queue_free()

func _callback(callbacks: Dictionary, key: String) -> Callable:
	var callback: Variant = callbacks.get(key, Callable())
	if callback is Callable:
		return callback
	return Callable()
