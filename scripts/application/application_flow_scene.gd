extends Control

const PROFILE_PATH := "user://saves/application_profile.json"
const PlayerProfileDataScript := preload("res://scripts/data/player_profile_data.gd")
const ApplicationArtPanelScript := preload("res://scripts/application/application_art_panel.gd")
const SuitPreviewControlScript := preload("res://scripts/application/suit_preview_control.gd")

const EDUCATION_OPTIONS := [
	"植物科学",
	"农业工程",
	"机械工程",
	"生命支持工程",
	"材料科学",
	"医学",
]

const EDUCATION_DESCRIPTIONS := {
	"植物科学": "更容易发现植物叶片异常、营养缺乏与根系问题。",
	"农业工程": "更容易理解温室设备、水循环与种植系统状态。",
	"机械工程": "更容易判断设备损坏原因、维修风险与结构故障。",
	"生命支持工程": "更容易理解氧气、水、电力、温度之间的关系。",
	"材料科学": "更容易识别结构老化、密封材料损耗与辐射损伤。",
	"医学": "更容易发现自身或未来居民的健康风险。",
}

const STEP_LABELS := {
	"identity": ["01 基础信息", "BASIC INFORMATION"],
	"education": ["02 教育背景", "EDUCATION BACKGROUND"],
	"appearance": ["03 外观与标识", "APPEARANCE & MARKING"],
	"review": ["04 提交申请", "SUBMIT APPLICATION"],
}

var profile: Resource
var step := "identity"
var review_lines: Array[String] = []
var review_index := 0
var review_timer := 0.0
var review_complete_hold := 0.0
var is_reviewing := false

var page_body: VBoxContainer
var content_scroll: ScrollContainer
var footer: HBoxContainer
var status_label: Label
var name_edit: LineEdit
var birth_spin: SpinBox
var gender_options: OptionButton
var education_buttons: Dictionary = {}
var education_detail_title: Label
var education_detail_body: Label
var suit_marking_edit: LineEdit
var name_initials_edit: LineEdit
var appearance_options: Dictionary = {}
var confirmation_checks: Array[CheckBox] = []
var submit_button: Button

func _ready() -> void:
	profile = PlayerProfileDataScript.new()
	_load_profile()
	_normalize_profile_defaults()
	step = String(profile.get("current_application_step"))
	_build_shell()
	_show_step(step)

func _process(delta: float) -> void:
	if not is_reviewing:
		return
	if review_index >= review_lines.size():
		review_complete_hold += delta
		if review_complete_hold < 1.25:
			return
		is_reviewing = false
		profile.set("candidate_file_status", "已通过资格初审")
		profile.set("current_application_step", "notice")
		_save_profile()
		_show_step("notice")
		return
	review_timer += delta
	if review_timer < 0.58:
		return
	review_timer = 0.0
	status_label.text += "\n" + review_lines[review_index]
	review_index += 1

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
	background.color = Color("#06101a")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.name = "ApplicationShell"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 36
	root.offset_top = 24
	root.offset_right = -36
	root.offset_bottom = -32
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	root.add_child(header)
	_add_header_label(header, "国家深空生命科学中心\nNATIONAL DEEP SPACE LIFE SCIENCE CENTER", Vector2(280, 58), 15, Color("#d8e7f2"))
	_add_header_label(header, "广寒计划常驻开拓者申请系统\nPROJECT GUANGHAN · PERMANENT PIONEER APPLICATION SYSTEM", Vector2(520, 58), 22, Color("#edf7ff"))
	_add_header_label(header, "系统编号  GHO-AS-2068-0421\n当前时间  2068-04-12   07:15:32", Vector2(240, 58), 14, Color("#8fa3b2"))

	root.add_child(HSeparator.new())
	_add_step_bar(root)

	content_scroll = ScrollContainer.new()
	content_scroll.name = "ContentArea"
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content_scroll)

	page_body = VBoxContainer.new()
	page_body.name = "PageBody"
	page_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_body.add_theme_constant_override("separation", 12)
	content_scroll.add_child(page_body)

	footer = HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.custom_minimum_size = Vector2(0, 48)
	footer.size_flags_vertical = Control.SIZE_SHRINK_END
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)

func _add_header_label(parent: HBoxContainer, text: String, min_size: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = min_size
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func _add_step_bar(root: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	for key in ["identity", "education", "appearance", "review"]:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(270, 58)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(panel)
		var box := VBoxContainer.new()
		panel.add_child(box)
		var labels: Array = STEP_LABELS[key]
		var main := Label.new()
		main.text = String(labels[0])
		main.modulate = Color("#d8e7f2")
		main.add_theme_font_size_override("font_size", 18)
		box.add_child(main)
		var sub := Label.new()
		sub.text = String(labels[1])
		sub.modulate = Color("#6f8493")
		sub.add_theme_font_size_override("font_size", 12)
		box.add_child(sub)

func _show_step(next_step: String) -> void:
	step = next_step
	profile.set("current_application_step", step)
	_clear_container(page_body)
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
		"withdrawn":
			_show_withdrawn()
		_:
			_show_identity()
	_save_profile()

func _show_identity() -> void:
	_add_page_title("01 基础信息", "BASIC INFORMATION")
	var columns := _add_columns(0.47)
	var left: VBoxContainer = columns[0]
	var right: VBoxContainer = columns[1]
	_add_panel_title(left, "基础信息填写")
	_add_body_to(left, "请填写任务档案显示信息。无需填写真实证件信息。")
	name_edit = _add_line_edit_to(left, "姓名", String(profile.get("player_name")))
	birth_spin = SpinBox.new()
	birth_spin.min_value = 1960
	birth_spin.max_value = 2030
	birth_spin.value = int(profile.get("birth_year"))
	_add_field_to(left, "出生年份", birth_spin)
	gender_options = _add_options_to(left, "性别", ["男", "女"], String(profile.get("gender_display")))
	_add_panel_title(left, "系统生成信息")
	_add_readonly_field_to(left, "申请编号", String(profile.get("application_id")))
	_add_readonly_field_to(left, "候选人档案状态", String(profile.get("candidate_file_status")))
	_add_readonly_field_to(left, "任务身份", String(profile.get("mission_identity")))
	_add_note_to(left, "性别仅影响视觉体型预设，不影响数值、能力或玩法加成。")

	_add_panel_title(right, "广寒计划任务信息")
	_add_project_info(right)
	var art := ApplicationArtPanelScript.new()
	art.panel_kind = "project"
	right.add_child(art)
	_add_note_to(right, "广寒计划是人类迈向深空常驻的第一步。")

	_add_footer_button("返回", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_add_footer_button("下一步", func():
		_capture_identity()
		if String(profile.get("player_name")).strip_edges().is_empty():
			_add_note_to(left, "姓名不能为空。")
			return
		_show_step("education")
	)

func _show_education() -> void:
	_add_page_title("02 教育背景", "EDUCATION BACKGROUND")
	_add_body("教育背景不会提供数值加成。\n它将影响你未来看到的提示、诊断信息与可见信息。")
	var columns := _add_columns(0.38)
	var left: VBoxContainer = columns[0]
	var right: VBoxContainer = columns[1]
	_add_panel_title(left, "选择教育背景")
	education_buttons.clear()
	for option in EDUCATION_OPTIONS:
		var button := Button.new()
		button.text = option
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(_select_education.bind(String(option)))
		left.add_child(button)
		education_buttons[option] = button
	_add_panel_title(right, "背景说明")
	education_detail_title = Label.new()
	education_detail_title.modulate = Color("#eaf4ff")
	education_detail_title.add_theme_font_size_override("font_size", 24)
	right.add_child(education_detail_title)
	education_detail_body = Label.new()
	education_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	education_detail_body.modulate = Color("#d8e7f2")
	education_detail_body.add_theme_font_size_override("font_size", 18)
	right.add_child(education_detail_body)
	_add_body_to(right, "未来作用：影响提示、诊断信息与可见信息，不改变能力数值。")
	var art := ApplicationArtPanelScript.new()
	art.panel_kind = "education"
	right.add_child(art)
	if String(profile.get("education_background")).is_empty():
		profile.set("education_background", EDUCATION_OPTIONS[0])
	_update_education_detail()
	_add_footer_button("返回", func():
		_show_step("identity")
	)
	_add_footer_button("下一步", func():
		_show_step("appearance")
	)

func _show_appearance() -> void:
	_add_page_title("03 外观与标识", "APPEARANCE & MARKING")
	_add_body("外观仅用于角色显示与任务档案，不影响能力。")
	appearance_options.clear()
	var columns := _add_columns(0.48)
	var left: VBoxContainer = columns[0]
	var right: VBoxContainer = columns[1]
	_add_panel_title(left, "外观记录")
	appearance_options["appearance_preset"] = _add_options_to(left, "身形预设", _body_options_for_gender(), String(profile.get("appearance_preset")))
	appearance_options["skin_preset"] = _add_options_to(left, "肤色预设", ["预设 A", "预设 B", "预设 C", "预设 D"], String(profile.get("skin_preset")))
	appearance_options["hair_preset"] = _add_options_to(left, "发型预设", ["短发", "束发", "寸发", "头盔内衬"], String(profile.get("hair_preset")))
	appearance_options["hair_color_preset"] = _add_options_to(left, "发色预设", ["黑色", "棕色", "深棕色", "灰色"], String(profile.get("hair_color_preset")))
	appearance_options["suit_marking_color"] = _add_options_to(left, "宇航服标识色", ["蓝色", "白色", "琥珀", "红色", "绿色"], String(profile.get("suit_marking_color")))
	suit_marking_edit = _add_line_edit_to(left, "臂章编号", String(profile.get("suit_marking")))
	name_initials_edit = _add_line_edit_to(left, "姓名缩写", _name_initials())
	_add_note_to(left, "性别只影响视觉体型预设，不影响属性、能力或玩法加成。")

	_add_panel_title(right, "开拓者预览")
	var subtitle := Label.new()
	subtitle.text = "任务装备显示"
	subtitle.modulate = Color("#8fa3b2")
	subtitle.add_theme_font_size_override("font_size", 15)
	right.add_child(subtitle)
	var preview_row := HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 20)
	right.add_child(preview_row)
	var front := SuitPreviewControlScript.new()
	front.front = true
	front.marking_color = _marking_color()
	front.patch_id = String(profile.get("suit_marking"))
	front.suit_id = _suit_id()
	preview_row.add_child(front)
	var back := SuitPreviewControlScript.new()
	back.front = false
	back.marking_color = _marking_color()
	back.patch_id = String(profile.get("suit_marking"))
	back.suit_id = _suit_id()
	preview_row.add_child(back)
	_add_body_to(right, "宇航服编号：%s\n臂章编号：%s\n姓名缩写：%s\n标识色：%s" % [
		_suit_id(),
		String(profile.get("suit_marking")),
		_name_initials(),
		String(profile.get("suit_marking_color")),
	])
	_add_note_to(right, "外观仅用于角色显示与任务档案，不影响能力。")
	_add_footer_button("返回", func():
		_capture_appearance()
		_show_step("education")
	)
	_add_footer_button("提交预览", func():
		_capture_appearance()
		_show_step("review")
	)

func _show_review() -> void:
	_add_page_title("04 提交申请", "SUBMIT APPLICATION")
	confirmation_checks.clear()
	submit_button = null
	var columns := _add_columns(0.52)
	var left: VBoxContainer = columns[0]
	var right: VBoxContainer = columns[1]
	_add_panel_title(left, "提交确认")
	_add_body_to(left, "你即将提交广寒计划常驻开拓者申请。\n\n一旦通过审核，你将进入国家深空生命科学中心训练序列。\n\n训练完成并通过最终考核后，\n你可能被派往月球广寒前哨，\n执行长期驻留与生命支持建设任务。")
	_add_panel_title(left, "确认事项")
	_add_confirmation_check(left, "我理解这是一项长期任务。")
	_add_confirmation_check(left, "我理解任务地点位于月球。")
	_add_confirmation_check(left, "我理解广寒前哨仍处于早期建设阶段。")
	_add_panel_title(right, "候选人摘要")
	_add_body_to(right, _profile_summary())
	_add_footer_button("返回修改", func(): _show_step("identity"))
	submit_button = Button.new()
	submit_button.text = "提交申请"
	submit_button.custom_minimum_size = Vector2(200, 42)
	submit_button.disabled = true
	submit_button.pressed.connect(func():
		_start_review_sequence()
	)
	footer.add_child(submit_button)
	_update_submit_enabled()

func _start_review_sequence() -> void:
	profile.set("application_submitted", true)
	profile.set("candidate_file_status", "审核中")
	profile.set("current_application_step", "review")
	_save_profile()
	_clear_container(page_body)
	_clear_container(footer)
	_add_page_title("审核流程", "APPLICATION REVIEW")
	var panel := _add_panel(page_body)
	status_label = Label.new()
	status_label.text = "申请已提交"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color("#d8e7f2")
	status_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(status_label)
	var review_status := VBoxContainer.new()
	review_status.add_theme_constant_override("separation", 8)
	panel.add_child(review_status)
	_add_note_to(review_status, "资料归档：完成")
	_add_note_to(review_status, "身份校验：完成")
	_add_note_to(review_status, "教育背景匹配：进行中")
	_add_note_to(review_status, "训练序列分配：等待")
	review_lines = [
		"正在进行资格审核",
		"正在匹配教育背景",
		"正在生成训练计划",
		"正在建立候选人档案",
		"审核完成",
	]
	review_index = 0
	review_timer = 0.0
	review_complete_hold = 0.0
	is_reviewing = true

func _show_notice() -> void:
	profile.set("candidate_file_status", "已通过资格初审")
	_add_page_title("资格初审结果", "PRELIMINARY ELIGIBILITY REVIEW")
	var panel := _add_panel(page_body)
	panel.custom_minimum_size = Vector2(980, 540)
	var title := Label.new()
	title.text = "国家深空生命科学中心\n资格初审结果"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 28)
	panel.add_child(title)
	_add_note_to(panel, "文书编号：GHO-REV-2068-0421    签发日期：2068-04-12")
	_add_note_to(panel, "候选人：%s    档案状态：%s    签发单位：广寒计划常驻开拓者选拔委员会" % [
		_display_name(),
		String(profile.get("candidate_file_status")),
	])
	_add_body_to(panel, "致 %s：\n\n经广寒计划常驻开拓者选拔委员会初步审核，\n你的申请已通过资格初审。\n\n你将进入国家深空生命科学中心训练序列。\n\n训练完成并通过最终考核后，\n你才可能被正式派往月球广寒前哨，\n执行长期驻留与生命支持建设任务。\n\n广寒计划不是一次普通申请。\n这只是第一步。" % _display_name())
	_add_footer_button("返回主菜单", func():
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	var training := Button.new()
	training.text = "进入训练序列"
	training.custom_minimum_size = Vector2(240, 46)
	training.modulate = Color("#9ac7e8")
	training.pressed.connect(func():
		profile.set("current_application_step", "training_start")
		profile.set("candidate_file_status", "训练序列中")
		_save_profile()
		get_tree().change_scene_to_file("res://scenes/training/TrainingStartScene.tscn")
	)
	footer.add_child(training)

func _show_withdrawn() -> void:
	_add_page_title("申请已撤回", "APPLICATION WITHDRAWN")
	var panel := _add_panel(page_body)
	_add_body_to(panel, "申请已撤回。\n\n广寒计划仍将继续等待下一位开拓者。")
	_add_footer_button("返回主菜单", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))

func _capture_current_fields() -> void:
	match step:
		"identity":
			_capture_identity()
		"education":
			pass
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

func _capture_appearance() -> void:
	for key: String in appearance_options.keys():
		var options: OptionButton = appearance_options[key]
		profile.set(key, options.get_item_text(options.selected))
	if suit_marking_edit != null:
		profile.set("suit_marking", suit_marking_edit.text.strip_edges())
	if name_initials_edit != null:
		profile.set("name_initials", name_initials_edit.text.strip_edges())
	_save_profile()

func _update_education_detail() -> void:
	var selected := String(profile.get("education_background"))
	if selected.is_empty():
		selected = EDUCATION_OPTIONS[0]
		profile.set("education_background", selected)
	if education_detail_title != null:
		education_detail_title.text = selected
	if education_detail_body != null:
		education_detail_body.text = String(EDUCATION_DESCRIPTIONS.get(selected, ""))
	for option in education_buttons.keys():
		var button: Button = education_buttons[option]
		button.modulate = Color("#9ac7e8") if String(option) == selected else Color.WHITE

func _select_education(selected: String) -> void:
	profile.set("education_background", selected)
	_update_education_detail()
	_save_profile()

func _profile_summary() -> String:
	return "姓名：%s\n申请编号：%s\n候选人档案状态：%s\n任务身份：%s\n出生年份：%d\n性别：%s\n教育背景：%s\n宇航服标识：%s / %s" % [
		_display_name(),
		String(profile.get("application_id")),
		String(profile.get("candidate_file_status")),
		String(profile.get("mission_identity")),
		int(profile.get("birth_year")),
		String(profile.get("gender_display")),
		String(profile.get("education_background")),
		String(profile.get("suit_marking")),
		String(profile.get("suit_marking_color")),
	]

func _display_name() -> String:
	var value := String(profile.get("player_name")).strip_edges()
	return value if not value.is_empty() else "候选人"

func _name_initials() -> String:
	var value := String(profile.get("name_initials")).strip_edges()
	return value if not value.is_empty() else "C.S.W."

func _suit_id() -> String:
	return String(profile.get("application_id")).replace("GHO-APP-", "GH-")

func _body_options_for_gender() -> Array[String]:
	if String(profile.get("gender_display")) == "女":
		return ["女 / 标准", "女 / 紧凑", "女 / 高挑"]
	return ["男 / 标准", "男 / 紧凑", "男 / 高挑"]

func _marking_color() -> Color:
	match String(profile.get("suit_marking_color")):
		"白色":
			return Color("#dfe8ef")
		"琥珀":
			return Color("#d6a83e")
		"红色":
			return Color("#b84a3d")
		"绿色":
			return Color("#4f8a62")
		_:
			return Color("#236fa8")

func _add_page_title(title: String, subtitle: String) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	page_body.add_child(box)
	var main := Label.new()
	main.text = title
	main.modulate = Color("#eaf4ff")
	main.add_theme_font_size_override("font_size", 28)
	box.add_child(main)
	var sub := Label.new()
	sub.text = subtitle
	sub.modulate = Color("#6f8493")
	sub.add_theme_font_size_override("font_size", 13)
	box.add_child(sub)

func _add_columns(left_ratio: float) -> Array[VBoxContainer]:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_body.add_child(row)
	var left := _add_panel(row)
	var right := _add_panel(row)
	left.custom_minimum_size = Vector2(1100.0 * left_ratio, 430)
	right.custom_minimum_size = Vector2(1100.0 * (1.0 - left_ratio), 430)
	return [left, right]

func _add_panel(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	return box

func _add_panel_title(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color("#eaf4ff")
	label.add_theme_font_size_override("font_size", 20)
	parent.add_child(label)

func _add_project_info(parent: VBoxContainer) -> void:
	_add_body_to(parent, "任务名称：广寒计划\n任务类型：长期驻留 / 生命支持建设\n任务地点：月球 · 广寒前哨\n通信距离：384,400 公里\n预计通信延迟：1.3 秒")

func _add_body(text: String) -> void:
	_add_body_to(page_body, text)

func _add_body_to(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color("#d8e7f2")
	label.add_theme_font_size_override("font_size", 17)
	parent.add_child(label)

func _add_note_to(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color("#8fa3b2")
	label.add_theme_font_size_override("font_size", 14)
	parent.add_child(label)

func _add_field_to(parent: VBoxContainer, label_text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(190, 36)
	label.modulate = Color("#d8e7f2")
	label.add_theme_font_size_override("font_size", 16)
	row.add_child(label)
	control.custom_minimum_size = Vector2(360, 36)
	row.add_child(control)

func _add_line_edit_to(parent: VBoxContainer, label_text: String, value: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = value
	_add_field_to(parent, label_text, edit)
	return edit

func _add_readonly_field_to(parent: VBoxContainer, label_text: String, value: String) -> void:
	var edit := LineEdit.new()
	edit.text = value
	edit.editable = false
	_add_field_to(parent, label_text, edit)

func _add_options_to(parent: VBoxContainer, label_text: String, options: Array, selected_value: String) -> OptionButton:
	var button := OptionButton.new()
	var selected_index := 0
	for i in range(options.size()):
		var option_text := String(options[i])
		button.add_item(option_text)
		if option_text == selected_value:
			selected_index = i
	button.select(selected_index)
	_add_field_to(parent, label_text, button)
	return button

func _add_footer_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 42)
	button.pressed.connect(callback)
	footer.add_child(button)

func _add_confirmation_check(parent: VBoxContainer, text: String) -> void:
	var check := CheckBox.new()
	check.text = text
	check.custom_minimum_size = Vector2(0, 40)
	check.add_theme_icon_override("unchecked", _make_checkbox_icon(false))
	check.add_theme_icon_override("checked", _make_checkbox_icon(true))
	check.add_theme_font_size_override("font_size", 16)
	check.add_theme_color_override("font_color", Color("#d8e7f2"))
	check.add_theme_color_override("font_hover_color", Color("#eaf4ff"))
	check.add_theme_color_override("font_pressed_color", Color("#eaf4ff"))
	check.add_theme_color_override("font_focus_color", Color("#eaf4ff"))
	_style_confirmation_check(check)
	check.toggled.connect(func(_pressed: bool):
		_style_confirmation_check(check)
		_update_submit_enabled()
	)
	parent.add_child(check)
	confirmation_checks.append(check)

func _style_confirmation_check(check: CheckBox) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#12324a") if check.button_pressed else Color("#0a1823")
	box.border_color = Color("#5fb8ff") if check.button_pressed else Color("#5d829a")
	box.set_border_width_all(1)
	box.corner_radius_top_left = 4
	box.corner_radius_top_right = 4
	box.corner_radius_bottom_left = 4
	box.corner_radius_bottom_right = 4
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	check.add_theme_stylebox_override("normal", box)
	check.add_theme_stylebox_override("hover", box)
	check.add_theme_stylebox_override("pressed", box)
	check.add_theme_stylebox_override("hover_pressed", box)
	check.add_theme_stylebox_override("focus", box)

func _make_checkbox_icon(checked: bool) -> Texture2D:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var border := Color("#5fb8ff") if checked else Color("#8db4cb")
	var fill := Color("#174466") if checked else Color("#0f2533")
	for y in range(3, 21):
		for x in range(3, 21):
			if x <= 4 or x >= 19 or y <= 4 or y >= 19:
				image.set_pixel(x, y, border)
			else:
				image.set_pixel(x, y, fill)
	if checked:
		var mark := Color("#eaf7ff")
		var points := [
			Vector2i(8, 12), Vector2i(9, 13), Vector2i(10, 14),
			Vector2i(11, 15), Vector2i(12, 14), Vector2i(13, 13),
			Vector2i(14, 12), Vector2i(15, 11), Vector2i(16, 10),
		]
		for point in points:
			image.set_pixelv(point, mark)
			image.set_pixel(point.x, point.y + 1, mark)
	return ImageTexture.create_from_image(image)

func _update_submit_enabled() -> void:
	if submit_button == null:
		return
	for check in confirmation_checks:
		if not check.button_pressed:
			submit_button.disabled = true
			return
	submit_button.disabled = false

func _clear_container(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _normalize_profile_defaults() -> void:
	if String(profile.get("gender_display")) != "女":
		profile.set("gender_display", "男")
	if String(profile.get("candidate_file_status")).is_empty() or String(profile.get("candidate_file_status")) == "待建立":
		profile.set("candidate_file_status", "待提交")
	if String(profile.get("candidate_file_status")) == "已通过初步评估":
		var current_step := String(profile.get("current_application_step"))
		if current_step == "notice" or current_step == "training_start":
			profile.set("candidate_file_status", "已通过资格初审")
		else:
			profile.set("candidate_file_status", "待提交")
	if String(profile.get("education_background")).is_empty():
		profile.set("education_background", EDUCATION_OPTIONS[0])

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
