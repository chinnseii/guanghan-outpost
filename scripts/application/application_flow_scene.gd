extends Control

const PROFILE_PATH := "user://saves/application_profile.json"
const PlayerProfileDataScript := preload("res://scripts/data/player_profile_data.gd")

const EDUCATION_DESCRIPTIONS := {
	"植物科学": "更容易发现植物叶片异常、营养缺乏与根系问题。",
	"农业工程": "更容易理解温室设备、水循环与种植系统状态。",
	"机械工程": "更容易判断设备损坏原因、维修风险与结构故障。",
	"生命支持工程": "更容易理解氧气、水、电力、温度之间的关系。",
	"材料科学": "更容易识别结构老化、密封材料损耗与辐射损伤。",
	"医学": "更容易发现自身或未来居民的健康风险。",
}

const STEP_TITLES := {
	"identity": "01 基础信息",
	"education": "02 教育背景",
	"appearance": "03 外观与标识",
	"review": "04 提交申请",
	"notice": "录取通知",
	"choice": "最终选择",
}

var profile: Resource
var step := "identity"
var review_lines: Array[String] = []
var review_index := 0
var review_timer := 0.0
var is_reviewing := false

var content: VBoxContainer
var footer: HBoxContainer
var status_label: Label
var name_edit: LineEdit
var birth_spin: SpinBox
var gender_options: OptionButton
var education_options: OptionButton
var education_description: Label
var suit_marking_edit: LineEdit
var appearance_options: Dictionary = {}

func _ready() -> void:
	profile = PlayerProfileDataScript.new()
	_load_profile()
	step = String(profile.get("current_application_step"))
	_build_shell()
	_show_step(step)

func _process(delta: float) -> void:
	if not is_reviewing:
		return
	review_timer += delta
	if review_timer < 0.55:
		return
	review_timer = 0.0
	if review_index < review_lines.size():
		status_label.text += "\n" + review_lines[review_index]
		review_index += 1
	else:
		is_reviewing = false
		profile.set("candidate_file_status", "初审通过")
		profile.set("current_application_step", "notice")
		_save_profile()
		_show_step("notice")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	if event.is_action_pressed("save_game"):
		_capture_current_fields()
		_save_profile()
	if event.is_action_pressed("load_game"):
		_load_profile()
		_show_step(String(profile.get("current_application_step")))

func _build_shell() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#071019")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var root := VBoxContainer.new()
	root.name = "ApplicationShell"
	root.position = Vector2(72, 42)
	root.size = Vector2(1456, 820)
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	root.add_child(header)
	var agency := Label.new()
	agency.text = "国家深空生命科学中心\nNATIONAL DEEP SPACE LIFE SCIENCE CENTER"
	agency.modulate = Color("#d8e7f2")
	agency.custom_minimum_size = Vector2(420, 58)
	agency.add_theme_font_size_override("font_size", 16)
	header.add_child(agency)
	var title := Label.new()
	title.text = "广寒计划常驻开拓者申请系统\nPROJECT GUANGHAN · PERMANENT PIONEER APPLICATION SYSTEM"
	title.modulate = Color("#eaf4ff")
	title.custom_minimum_size = Vector2(660, 58)
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)
	var system_info := Label.new()
	system_info.text = "系统编号  GHO-AS-2068-0421\n当前时间  2068-04-12   07:15:32"
	system_info.modulate = Color("#8fa3b2")
	system_info.add_theme_font_size_override("font_size", 14)
	header.add_child(system_info)
	root.add_child(HSeparator.new())
	_add_step_bar(root)
	content = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	root.add_child(content)
	footer = HBoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)

func _add_step_bar(root: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	for key in ["identity", "education", "appearance", "review"]:
		var label := Label.new()
		label.text = String(STEP_TITLES[key])
		label.custom_minimum_size = Vector2(250, 42)
		label.modulate = Color("#8fa3b2")
		label.add_theme_font_size_override("font_size", 18)
		row.add_child(label)

func _show_step(next_step: String) -> void:
	step = next_step
	profile.set("current_application_step", step)
	_clear_container(content)
	_clear_container(footer)
	match step:
		"identity":
			_show_identity()
		"education":
			_show_education()
		"appearance":
			_show_appearance()
		"review":
			_show_review()
		"notice":
			_show_notice()
		"choice":
			_show_choice()
		"withdrawn":
			_show_withdrawn()
		_:
			_show_identity()
	_save_profile()

func _show_identity() -> void:
	_add_section_title("01 基础信息 / BASIC INFORMATION")
	_add_body("所有信息将用于资格审核与任务匹配。请勿输入真实世界敏感证件信息。")
	name_edit = _add_line_edit("姓名 / FULL NAME", String(profile.get("player_name")))
	birth_spin = SpinBox.new()
	birth_spin.min_value = 1960
	birth_spin.max_value = 2030
	birth_spin.value = int(profile.get("birth_year"))
	_add_field("出生年份 / YEAR OF BIRTH", birth_spin)
	gender_options = _add_options("性别 / GENDER", ["男", "女"], String(profile.get("gender_display")))
	_add_subsection("系统生成信息 / SYSTEM GENERATED INFORMATION")
	_add_readonly_field("申请编号 / APPLICATION ID", String(profile.get("application_id")))
	_add_readonly_field("候选人档案状态 / CANDIDATE FILE STATUS", String(profile.get("candidate_file_status")))
	_add_readonly_field("任务身份 / MISSION IDENTITY", String(profile.get("mission_identity")))
	_add_note("性别仅影响视觉体型预设，不影响数值、能力或玩法加成。")
	_add_footer_button("返回 / BACK", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_add_footer_button("下一步 / NEXT STEP", func():
		_capture_identity()
		if String(profile.get("player_name")).strip_edges().is_empty():
			_add_note("姓名不能为空。")
			return
		_show_step("education")
	)

func _show_education() -> void:
	_add_section_title("02 教育背景 / EDUCATION BACKGROUND")
	_add_body("选择一个教育背景。它只作为未来提示、诊断信息与可见信息的基础，不提供数值 Buff。")
	education_options = _add_options("教育背景 / BACKGROUND", EDUCATION_DESCRIPTIONS.keys(), String(profile.get("education_background")))
	education_options.item_selected.connect(func(_index: int):
		_update_education_description()
	)
	education_description = Label.new()
	education_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	education_description.modulate = Color("#d8e7f2")
	education_description.add_theme_font_size_override("font_size", 18)
	content.add_child(education_description)
	_update_education_description()
	_add_note("这里不会显示 +20% 之类的能力加成。")
	_add_footer_button("返回 / BACK", func():
		_capture_education()
		_show_step("identity")
	)
	_add_footer_button("下一步 / NEXT STEP", func():
		_capture_education()
		_show_step("appearance")
	)

func _show_appearance() -> void:
	_add_section_title("03 外观与标识 / APPEARANCE & MARKING")
	_add_body("外观仅用于角色显示与任务档案，不影响能力。")
	appearance_options.clear()
	var body_row := HBoxContainer.new()
	body_row.add_theme_constant_override("separation", 18)
	content.add_child(body_row)
	var fields := VBoxContainer.new()
	fields.custom_minimum_size = Vector2(610, 360)
	fields.add_theme_constant_override("separation", 10)
	body_row.add_child(fields)
	var old_content := content
	content = fields
	appearance_options["appearance_preset"] = _add_options("身形预设 / BODY PRESET", _body_options_for_gender(), String(profile.get("appearance_preset")))
	appearance_options["skin_preset"] = _add_options("肤色预设 / SKIN TONE", ["Preset A", "Preset B", "Preset C", "Preset D"], String(profile.get("skin_preset")))
	appearance_options["hair_preset"] = _add_options("发型预设 / HAIRSTYLE", ["Short", "Tied", "Cropped", "Covered"], String(profile.get("hair_preset")))
	appearance_options["hair_color_preset"] = _add_options("发色预设 / HAIR COLOR", ["Black", "Brown", "Dark brown", "Grey"], String(profile.get("hair_color_preset")))
	appearance_options["suit_marking_color"] = _add_options("宇航服标识色 / SUIT MARKING COLOR", ["Blue", "White", "Amber", "Red", "Green"], String(profile.get("suit_marking_color")))
	suit_marking_edit = _add_line_edit("臂章编号 / 姓名缩写", String(profile.get("suit_marking")))
	content = old_content
	_add_suit_preview(body_row)
	_add_note("Gender affects visual body preset only. It does not affect stats, abilities, or gameplay bonuses.")
	_add_footer_button("返回 / BACK", func():
		_capture_appearance()
		_show_step("education")
	)
	_add_footer_button("提交预览 / REVIEW APPLICATION", func():
		_capture_appearance()
		_show_step("review")
	)

func _show_review() -> void:
	_add_section_title("04 提交申请 / SUBMIT APPLICATION")
	_add_body("你即将提交广寒计划常驻开拓者申请。\n\n一旦通过审核，你将进入国家深空生命科学中心训练序列。\n\n训练完成后，你可能被派往月球广寒前哨，执行长期驻留任务。")
	_add_body(_profile_summary())
	_add_footer_button("返回修改 / RETURN TO EDIT", func(): _show_step("identity"))
	_add_footer_button("提交申请 / SUBMIT APPLICATION", func():
		_start_review_sequence()
	)

func _start_review_sequence() -> void:
	profile.set("application_submitted", true)
	profile.set("candidate_file_status", "审核中")
	profile.set("current_application_step", "review")
	_save_profile()
	_clear_container(content)
	_clear_container(footer)
	_add_section_title("Application Review")
	status_label = Label.new()
	status_label.text = "申请已提交"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color("#d8e7f2")
	status_label.add_theme_font_size_override("font_size", 20)
	content.add_child(status_label)
	review_lines = [
		"正在进行资格审核",
		"正在匹配教育背景",
		"正在生成训练计划",
		"正在调取广寒前哨任务档案",
	]
	review_index = 0
	review_timer = 0.0
	is_reviewing = true

func _show_notice() -> void:
	_add_section_title("广寒计划录取通知书")
	_add_body("国家深空生命科学中心\n广寒计划录取通知书")
	_add_body("致 %s：\n\n经广寒计划常驻开拓者选拔委员会审核，\n你已通过初步评估。\n\n你将进入国家深空生命科学中心训练序列。\n\n训练完成并通过最终考核后，\n你将被派往月球广寒前哨，\n执行长期驻留与生命支持建设任务。" % String(profile.get("player_name")))
	_add_footer_button("继续 / CONTINUE", func(): _show_step("choice"))

func _show_choice() -> void:
	_add_section_title("最终选择 / FINAL CHOICE")
	_add_body("申请已经通过。任务仍需要你亲自确认接受。")
	_add_footer_button("放弃申请 / WITHDRAW", func():
		profile.set("application_accepted", false)
		profile.set("candidate_file_status", "已撤回")
		profile.set("current_application_step", "withdrawn")
		_save_profile()
		_show_step("withdrawn")
	)
	_add_footer_button("接受使命 / ACCEPT MISSION", func():
		profile.set("application_accepted", true)
		profile.set("candidate_file_status", "任务已接受")
		profile.set("current_application_step", "accepted")
		_save_profile()
		get_tree().change_scene_to_file("res://scenes/application/BlackScreenSequence.tscn")
	)

func _show_withdrawn() -> void:
	_add_section_title("申请已撤回")
	_add_body("申请已撤回。\n\n广寒计划仍将继续等待下一位开拓者。")
	_add_footer_button("返回主菜单 / MAIN MENU", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))

func _capture_current_fields() -> void:
	match step:
		"identity":
			_capture_identity()
		"education":
			_capture_education()
		"appearance":
			_capture_appearance()

func _capture_identity() -> void:
	if name_edit != null:
		profile.set("player_name", name_edit.text.strip_edges())
	if birth_spin != null:
		profile.set("birth_year", int(birth_spin.value))
	if gender_options != null:
		profile.set("gender_display", gender_options.get_item_text(gender_options.selected))
	_save_profile()

func _capture_education() -> void:
	if education_options != null:
		profile.set("education_background", education_options.get_item_text(education_options.selected))
	_save_profile()

func _capture_appearance() -> void:
	for key: String in appearance_options.keys():
		var options: OptionButton = appearance_options[key]
		profile.set(key, options.get_item_text(options.selected))
	if suit_marking_edit != null:
		profile.set("suit_marking", suit_marking_edit.text.strip_edges())
	_save_profile()

func _update_education_description() -> void:
	if education_options == null or education_description == null:
		return
	var selected := education_options.get_item_text(education_options.selected)
	education_description.text = String(EDUCATION_DESCRIPTIONS.get(selected, ""))

func _profile_summary() -> String:
	return "Name: %s\nApplication ID: %s\nCandidate status: %s\nMission identity: %s\nBirth year: %d\nGender display: %s\nEducation: %s\nSuit marking: %s / %s" % [
		String(profile.get("player_name")),
		String(profile.get("application_id")),
		String(profile.get("candidate_file_status")),
		String(profile.get("mission_identity")),
		int(profile.get("birth_year")),
		String(profile.get("gender_display")),
		String(profile.get("education_background")),
		String(profile.get("suit_marking")),
		String(profile.get("suit_marking_color")),
	]

func _body_options_for_gender() -> Array[String]:
	if String(profile.get("gender_display")) == "女":
		return ["Female Standard", "Female Compact", "Female Tall"]
	return ["Male Standard", "Male Compact", "Male Tall"]

func _add_suit_preview(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 360)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := Label.new()
	title.text = "开拓者预览\nPIONEER PREVIEW"
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	var preview_row := HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 18)
	box.add_child(preview_row)
	preview_row.add_child(_make_suit_card("正面 / FRONT", true))
	preview_row.add_child(_make_suit_card("背面 / BACK", false))
	var meta := Label.new()
	meta.text = "Suit ID: %s\nName initials / patch: %s\nMarking color: %s" % [
		String(profile.get("application_id")).replace("GHO-APP-", "GH-"),
		String(profile.get("suit_marking")),
		String(profile.get("suit_marking_color")),
	]
	meta.modulate = Color("#d8e7f2")
	meta.add_theme_font_size_override("font_size", 15)
	box.add_child(meta)
	var note := Label.new()
	note.text = "外观仅用于角色显示与任务档案，不影响能力。"
	note.modulate = Color("#8fa3b2")
	note.add_theme_font_size_override("font_size", 14)
	box.add_child(note)

func _make_suit_card(label_text: String, front: bool) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(200, 220)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color("#8fa3b2")
	card.add_child(label)
	var suit := PanelContainer.new()
	suit.custom_minimum_size = Vector2(190, 185)
	card.add_child(suit)
	var parts := VBoxContainer.new()
	parts.alignment = BoxContainer.ALIGNMENT_CENTER
	suit.add_child(parts)
	var helmet := ColorRect.new()
	helmet.color = Color("#dce6ed")
	helmet.custom_minimum_size = Vector2(54, 42)
	parts.add_child(helmet)
	var visor := ColorRect.new()
	visor.color = Color("#142536") if front else Color("#aeb7bf")
	visor.custom_minimum_size = Vector2(42, 14)
	parts.add_child(visor)
	var torso := ColorRect.new()
	torso.color = Color("#c8d0d6")
	torso.custom_minimum_size = Vector2(76, 82)
	parts.add_child(torso)
	var patch := ColorRect.new()
	patch.color = _marking_color()
	patch.custom_minimum_size = Vector2(28, 10)
	parts.add_child(patch)
	return card

func _marking_color() -> Color:
	match String(profile.get("suit_marking_color")):
		"White":
			return Color("#dfe8ef")
		"Amber":
			return Color("#d6a83e")
		"Red":
			return Color("#b84a3d")
		"Green":
			return Color("#4f8a62")
		_:
			return Color("#236fa8")

func _add_section_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color("#eaf4ff")
	label.add_theme_font_size_override("font_size", 26)
	content.add_child(label)

func _add_subsection(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color("#d8e7f2")
	label.add_theme_font_size_override("font_size", 20)
	content.add_child(label)

func _add_body(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color("#d8e7f2")
	label.add_theme_font_size_override("font_size", 17)
	content.add_child(label)

func _add_note(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color("#8fa3b2")
	label.add_theme_font_size_override("font_size", 15)
	content.add_child(label)

func _add_readonly_field(label_text: String, value: String) -> void:
	var readonly := LineEdit.new()
	readonly.text = value
	readonly.editable = false
	_add_field(label_text, readonly)

func _add_field(label_text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(250, 36)
	label.modulate = Color("#d8e7f2")
	label.add_theme_font_size_override("font_size", 16)
	row.add_child(label)
	control.custom_minimum_size = Vector2(420, 36)
	row.add_child(control)
	content.add_child(row)

func _add_line_edit(label_text: String, value: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = value
	_add_field(label_text, edit)
	return edit

func _add_options(label_text: String, options: Array, selected_value: String) -> OptionButton:
	var button := OptionButton.new()
	var selected_index := 0
	for i in range(options.size()):
		var option_text := String(options[i])
		button.add_item(option_text)
		if option_text == selected_value:
			selected_index = i
	button.select(selected_index)
	_add_field(label_text, button)
	return button

func _add_footer_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 42)
	button.pressed.connect(callback)
	footer.add_child(button)

func _clear_container(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _save_profile() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var data: Dictionary = profile.call("to_dictionary")
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _load_profile() -> void:
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	profile.call("load_dictionary", parsed)
