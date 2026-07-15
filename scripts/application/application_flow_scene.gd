extends Control

const PROFILE_PATH := "user://saves/application_profile.json"
const PlayerProfileDataScript := preload("res://scripts/data/player_profile_data.gd")
const ApplicationArtPanelScript := preload("res://scripts/application/application_art_panel.gd")
const SuitPreviewControlScript := preload("res://scripts/application/suit_preview_control.gd")
const IconInstitution := preload("res://assets/ui/common/icons/atlas/icon_institution.tres")
const IconAssistant := preload("res://assets/ui/common/icons/atlas/icon_assistant.tres")
const IconEarth := preload("res://assets/ui/common/icons/atlas/icon_earth.tres")
const IconMoon := preload("res://assets/ui/common/icons/atlas/icon_moon.tres")
const IconOutpost := preload("res://assets/ui/common/icons/atlas/icon_outpost.tres")
const IconTerminal := preload("res://assets/ui/common/icons/atlas/icon_terminal.tres")
const IconLock := preload("res://assets/ui/common/icons/atlas/icon_lock.tres")
const IconArrowRight := preload("res://assets/ui/common/icons/atlas/icon_arrow_right.tres")
const IconStatusIncomplete := preload("res://assets/ui/common/icons/atlas/icon_status_incomplete.tres")
const IconStatusComplete := preload("res://assets/ui/common/icons/atlas/icon_status_complete.tres")
const IconSectionMarker := preload("res://assets/ui/common/icons/atlas/icon_section_marker.tres")

## AUI-03-01 approved layout constants (basic_information_hifi_spec).
const AUI_PAGE_MARGIN := 24
const AUI_HEADER_HEIGHT := 96
const AUI_STEP_NAV_HEIGHT := 64
const AUI_PAGE_HEADING_HEIGHT := 80
const AUI_BODY_HEIGHT := 636
const AUI_FOOTER_HEIGHT := 124
const AUI_SECTION_GAP := 8
const AUI_COLUMN_GAP := 20
const AUI_PANEL_PADDING := 24
const AUI_FIELD_ROW_HEIGHT := 48
const AUI_FIELD_ROW_GAP := 12
const AUI_BUTTON_HEIGHT := 50
const AUI_PANEL_RADIUS := 4
const AUI_INPUT_RADIUS := 3
const AUI_BORDER_WIDTH := 1
const AUI_FOCUS_BORDER_WIDTH := 2

const AUI_COLOR_PAGE_BG := Color("#06121a")
const AUI_COLOR_PANEL_BG := Color("#0e181f")
const AUI_COLOR_PANEL_BORDER := Color("#223c4d")
const AUI_COLOR_FIELD_BG := Color("#0a1823")
const AUI_COLOR_FIELD_BORDER := Color("#405d70")
const AUI_COLOR_FIELD_FOCUS_BORDER := Color("#8aaabd")
const AUI_COLOR_READONLY_BG := Color("#101c25")
const AUI_COLOR_READONLY_BORDER := Color("#2e4555")
const AUI_COLOR_ACTIVE_ACCENT := Color("#6f9bae")
const AUI_COLOR_TEXT_PRIMARY := Color("#e6edf2")
const AUI_COLOR_TEXT_INPUT := Color("#dce4e8")
const AUI_COLOR_TEXT_SECONDARY := Color("#8fa1aa")
const AUI_COLOR_TEXT_MUTED := Color("#637681")
const AUI_COLOR_TEXT_READONLY := Color("#8fa2ac")
const AUI_COLOR_SUCCESS := Color("#659578")
const AUI_COLOR_WARNING := Color("#bd8b3d")

const EDUCATION_OPTIONS := [
	"植物科学",
	"机械工程",
	"材料科学",
	"医学",
]

const EDUCATION_DESCRIPTIONS := {
	"植物科学": "核心风险：生命会不会生长\n\n熟悉植物状态、水 / 光 / 温度对植物的影响、温室环境风险、植物恢复周期与作物生长问题。\n\n信息优势：在植物诊断、旧温室、作物生长、水循环与植物供水、补光与温度判断中获得额外专业提示。",
	"机械工程": "核心风险：系统会不会运转\n\n熟悉电力系统、太阳能阵列、制氧模块、温控设备、水泵与设备故障链。\n\n信息优势：在太阳能板维修、供电恢复、制氧模块维修、温控系统维修、水循环设备维修中获得额外专业提示。",
	"材料科学": "核心风险：基地会不会漏\n\n熟悉舱压、密封材料、结构老化、舱体接缝、气闸 / 对接口微漏、月尘磨蚀、辐射与温差损伤。\n\n信息优势：在气闸密封、飞船对接口检查、旧基地舱压异常、密封圈老化、结构裂纹判断中获得额外专业提示。",
	"医学": "核心风险：人会不会撑不住\n\n熟悉精力、饱腹、营养、心理、氧气不足对人体的影响、低温 / 高温风险与长期单人驻留风险。\n\n信息优势：在健康状态判断、恢复顺序建议、低氧 / 低温环境风险、高强度维修前提醒、睡眠恢复效率判断中获得额外专业提示。",
}

const STEP_LABELS := {
	"identity": ["01 基础信息", "BASIC INFORMATION"],
	"education": ["02 候选人学术背景", "ACADEMIC BACKGROUND"],
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
var birth_options: OptionButton
var gender_options: OptionButton
var pending_academic_background_id := ""
var education_buttons: Dictionary = {}
var education_detail_title: Label
var education_detail_body: Label
var suit_marking_edit: LineEdit
var name_initials_edit: LineEdit
var appearance_options: Dictionary = {}
var confirmation_checks: Array[CheckBox] = []
var submit_button: Button
var step_bar_entries: Dictionary = {}
var identity_progress_label: Label
var identity_validation_label: Label
var identity_validation_hint_label: Label
var identity_next_button: Button
var identity_status_icon: TextureRect
var identity_ratio_label: Label
var identity_back_button: Button
var identity_field_dots: Dictionary = {}

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
	background.color = AUI_COLOR_PAGE_BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.name = "ApplicationShell"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = AUI_PAGE_MARGIN
	root.offset_top = AUI_PAGE_MARGIN
	root.offset_right = -AUI_PAGE_MARGIN
	root.offset_bottom = -AUI_PAGE_MARGIN
	root.add_theme_constant_override("separation", AUI_SECTION_GAP)
	add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, AUI_HEADER_HEIGHT)
	header.add_theme_constant_override("separation", 18)
	root.add_child(header)
	_add_icon(header, IconInstitution, Vector2(64, 64))
	_add_header_label(header, "国家深空生命科学中心", Vector2(210, 0), 16, AUI_COLOR_TEXT_INPUT)
	_add_header_label(header, "NATIONAL DEEP SPACE\nLIFE SCIENCE CENTER", Vector2(170, 0), 11, AUI_COLOR_TEXT_SECONDARY)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(title_box)
	var title := Label.new()
	title.text = "广寒计划常驻开拓者申请系统"
	title.modulate = Color("#e0e7eb")
	title.add_theme_font_size_override("font_size", 22)
	title_box.add_child(title)
	var title_sub := Label.new()
	title_sub.text = "PROJECT GUANGHAN · PERMANENT PIONEER APPLICATION SYSTEM"
	title_sub.modulate = Color("#9baab3")
	title_sub.add_theme_font_size_override("font_size", 14)
	title_box.add_child(title_sub)
	var meta_cluster := HBoxContainer.new()
	meta_cluster.add_theme_constant_override("separation", 10)
	meta_cluster.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_cluster.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(meta_cluster)
	var meta_box := VBoxContainer.new()
	meta_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meta_cluster.add_child(meta_box)
	_add_meta_row(meta_box, "系统编号", "GHO-AS-2068-0421")
	_add_meta_row(meta_box, "当前时间", "2068-04-12  07:15:32")
	var assistant_icon := _add_icon(meta_cluster, IconAssistant, Vector2(48, 48))
	assistant_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	_add_step_bar(root)

	content_scroll = ScrollContainer.new()
	content_scroll.name = "ContentArea"
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content_scroll)

	page_body = VBoxContainer.new()
	page_body.name = "PageBody"
	page_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_body.add_theme_constant_override("separation", AUI_SECTION_GAP)
	content_scroll.add_child(page_body)

	footer = HBoxContainer.new()
	footer.name = "Footer"
	footer.custom_minimum_size = Vector2(0, AUI_FOOTER_HEIGHT)
	footer.size_flags_vertical = Control.SIZE_SHRINK_END
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)

func _add_meta_row(parent: VBoxContainer, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(64, 0)
	label.modulate = Color("#8898a2")
	label.add_theme_font_size_override("font_size", 12)
	row.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.modulate = Color("#c5d0d6")
	value.add_theme_font_size_override("font_size", 12)
	row.add_child(value)

func _add_header_label(parent: HBoxContainer, text: String, min_size: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = min_size
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func _add_icon(parent: Node, texture: Texture2D, size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(icon)
	return icon

func _add_step_bar(root: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	for key in ["identity", "education", "appearance", "review"]:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, AUI_STEP_NAV_HEIGHT)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(panel)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		panel.add_child(margin)
		var box := VBoxContainer.new()
		margin.add_child(box)
		var labels: Array = STEP_LABELS[key]
		var main := Label.new()
		main.text = String(labels[0])
		main.modulate = Color("#d8e7f2")
		main.add_theme_font_size_override("font_size", 17)
		box.add_child(main)
		var sub := Label.new()
		sub.text = String(labels[1])
		sub.modulate = Color("#6f8493")
		sub.add_theme_font_size_override("font_size", 12)
		box.add_child(sub)
		var indicator := ColorRect.new()
		indicator.custom_minimum_size = Vector2(0, 3)
		box.add_child(indicator)
		step_bar_entries[key] = {
			"panel": panel,
			"main": main,
			"sub": sub,
			"indicator": indicator,
		}
	_refresh_step_bar()

static func is_step_active(current_step: String, candidate_step: String) -> bool:
	return current_step == candidate_step

static func derive_candidate_display_id(application_id: String) -> String:
	var normalized := ""
	for character in application_id:
		if character.unicode_at(0) >= 48 and character.unicode_at(0) <= 57 or character.to_upper() != character.to_lower():
			normalized += character.to_upper()
	if normalized.is_empty():
		return "待生成"
	return "GHC-" + normalized.right(6)

static func basic_information_state(player_name: String, gender: String, birth_year: int) -> Dictionary:
	var name_valid := not player_name.strip_edges().is_empty()
	var gender_valid := gender in ["男", "女"]
	var birth_valid := birth_year >= 1960 and birth_year <= 2030
	var completed := int(name_valid) + int(gender_valid) + int(birth_valid)
	var all_fields_populated := not player_name.strip_edges().is_empty() and not gender.strip_edges().is_empty() and birth_year != 0
	var validation := "已完成" if name_valid and gender_valid and birth_valid else ("需检查" if all_fields_populated else "待完成")
	return {"completed": completed, "valid": name_valid and gender_valid and birth_valid, "validation": validation}

func _refresh_identity_state() -> void:
	if identity_progress_label == null or identity_validation_label == null or identity_next_button == null:
		return
	var gender := "" if gender_options.selected <= 0 else gender_options.get_item_text(gender_options.selected)
	var birth_year := 0 if birth_options.selected <= 0 else int(birth_options.get_item_text(birth_options.selected))
	var state := basic_information_state(name_edit.text, gender, birth_year)
	var completed := int(state["completed"])
	var valid := bool(state["valid"])
	identity_progress_label.text = "必填项完成情况：%d / 3" % completed
	identity_validation_label.text = "资料校验状态：%s" % String(state["validation"])
	identity_next_button.disabled = not valid
	_style_identity_next_button(identity_next_button)
	if identity_status_icon != null:
		identity_status_icon.texture = IconStatusComplete if completed == 3 else IconStatusIncomplete
	if identity_ratio_label != null:
		identity_ratio_label.text = "%d/3" % completed
	if identity_validation_hint_label != null:
		identity_validation_hint_label.text = "已完成，可点击下一步继续。" if valid else "请完成所有必填项后进入下一步。"
	if identity_field_dots.has("姓名"):
		_set_identity_field_dot(identity_field_dots["姓名"], not name_edit.text.strip_edges().is_empty(), "姓名")
	if identity_field_dots.has("性别"):
		_set_identity_field_dot(identity_field_dots["性别"], gender in ["男", "女"], "性别")
	if identity_field_dots.has("出生年份"):
		_set_identity_field_dot(identity_field_dots["出生年份"], birth_year >= 1960 and birth_year <= 2030, "出生年份")

func _set_identity_field_dot(dot_label: Label, filled: bool, field_name: String) -> void:
	dot_label.text = ("● " if filled else "○ ") + field_name
	dot_label.modulate = AUI_COLOR_SUCCESS if filled else AUI_COLOR_TEXT_SECONDARY

func _refresh_step_bar() -> void:
	for key in step_bar_entries.keys():
		var entry: Dictionary = step_bar_entries[key]
		var is_active := is_step_active(step, String(key))
		var panel: PanelContainer = entry["panel"]
		var main: Label = entry["main"]
		var sub: Label = entry["sub"]
		var indicator: ColorRect = entry["indicator"]
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#102b3d") if is_active else Color("#0a1823")
		style.border_color = Color("#6f93a8") if is_active else Color("#29465a")
		style.set_border_width_all(1)
		style.corner_radius_top_left = 2
		style.corner_radius_top_right = 2
		style.corner_radius_bottom_right = 2
		style.corner_radius_bottom_left = 2
		panel.add_theme_stylebox_override("panel", style)
		main.modulate = Color("#edf7ff") if is_active else Color("#d8e7f2")
		sub.modulate = Color("#a7c2d3") if is_active else Color("#6f8493")
		indicator.color = Color("#6f9bb3") if is_active else Color(0, 0, 0, 0)

func _show_step(next_step: String) -> void:
	step = next_step
	profile.set("current_application_step", step)
	_refresh_step_bar()
	_clear_container(page_body)
	_clear_container(footer)
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
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
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_add_identity_page_heading()
	var columns := _add_identity_columns()
	var left: VBoxContainer = columns[0]
	var right: VBoxContainer = columns[1]
	_add_identity_panel_heading(left, "候选人基础资料", "CANDIDATE RECORD")

	var section_a := VBoxContainer.new()
	section_a.add_theme_constant_override("separation", AUI_FIELD_ROW_GAP)
	left.add_child(section_a)
	_add_identity_section_heading(section_a, "A. 候选人填写信息", "CANDIDATE INPUT")
	name_edit = _add_identity_line_edit(section_a, "姓名 *", String(profile.get("player_name")), "请输入姓名")
	_style_identity_editable(name_edit)
	var saved_gender := String(profile.get("gender_display")) if not String(profile.get("player_name")).strip_edges().is_empty() else ""
	gender_options = _add_identity_dropdown(section_a, "性别 *", ["未选择", "男", "女"], saved_gender)
	birth_options = _add_identity_year_dropdown(section_a, String(profile.get("player_name")))
	_style_identity_option(gender_options)
	_style_identity_option(birth_options)
	name_edit.text_changed.connect(func(_value: String): _refresh_identity_state())
	birth_options.item_selected.connect(func(_index: int): _refresh_identity_state())
	gender_options.item_selected.connect(func(_index: int): _refresh_identity_state())

	var section_b := VBoxContainer.new()
	section_b.add_theme_constant_override("separation", 8)
	left.add_child(section_b)
	_add_identity_section_heading(section_b, "B. 系统生成信息", "由系统自动生成，不可编辑  ·  SYSTEM GENERATED (READ ONLY)")
	_add_identity_readonly(section_b, "申请编号", String(profile.get("application_id")))
	_add_identity_readonly(section_b, "候选人编号", derive_candidate_display_id(String(profile.get("application_id"))))
	_add_identity_readonly(section_b, "档案状态", String(profile.get("candidate_file_status")))
	_add_identity_readonly(section_b, "任务身份", String(profile.get("mission_identity")))

	_add_identity_panel_heading(right, "广寒计划任务档案", "MISSION BRIEF")
	_add_identity_mission_info(right)
	_add_mission_link_diagram(right)
	_add_note_to(right, "广寒前哨将建立可持续生命支持系统，推动月球长期有人驻留。")
	_build_identity_footer()
	_refresh_identity_state()

func _add_identity_page_heading() -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, AUI_PAGE_HEADING_HEIGHT)
	row.add_theme_constant_override("separation", 14)
	page_body.add_child(row)
	var index := Label.new()
	index.text = "01"
	index.modulate = AUI_COLOR_ACTIVE_ACCENT
	index.add_theme_font_size_override("font_size", 28)
	row.add_child(index)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "基础信息"
	title.modulate = AUI_COLOR_TEXT_PRIMARY
	title.add_theme_font_size_override("font_size", 28)
	labels.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "BASIC INFORMATION"
	subtitle.modulate = AUI_COLOR_TEXT_SECONDARY
	subtitle.add_theme_font_size_override("font_size", 12)
	labels.add_child(subtitle)
	row.add_child(labels)
	var description := Label.new()
	description.text = "填写候选人任务档案显示信息，用于建立你的申请记录。"
	description.modulate = AUI_COLOR_TEXT_MUTED
	description.add_theme_font_size_override("font_size", 14)
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	description.custom_minimum_size = Vector2(480, 0)
	row.add_child(description)

func _add_identity_columns() -> Array[VBoxContainer]:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, AUI_BODY_HEIGHT)
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_theme_constant_override("separation", AUI_COLUMN_GAP)
	page_body.add_child(row)
	var left_panel := PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 0.52
	_style_identity_panel(left_panel)
	row.add_child(left_panel)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 14)
	left_panel.add_child(left)
	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 0.48
	_style_identity_panel(right_panel)
	row.add_child(right_panel)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right_panel.add_child(right)
	var result: Array[VBoxContainer] = [left, right]
	return result

func _style_identity_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = AUI_COLOR_PANEL_BG
	style.border_color = AUI_COLOR_PANEL_BORDER
	style.set_border_width_all(AUI_BORDER_WIDTH)
	style.corner_radius_top_left = AUI_PANEL_RADIUS
	style.corner_radius_top_right = AUI_PANEL_RADIUS
	style.corner_radius_bottom_left = AUI_PANEL_RADIUS
	style.corner_radius_bottom_right = AUI_PANEL_RADIUS
	style.content_margin_left = AUI_PANEL_PADDING
	style.content_margin_right = AUI_PANEL_PADDING
	style.content_margin_top = AUI_PANEL_PADDING
	style.content_margin_bottom = AUI_PANEL_PADDING
	panel.add_theme_stylebox_override("panel", style)

func _add_identity_panel_heading(parent: VBoxContainer, title_text: String, subtitle_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var title := Label.new()
	title.text = title_text
	title.modulate = Color("#cad5db")
	title.add_theme_font_size_override("font_size", 16)
	row.add_child(title)
	var sub := Label.new()
	sub.text = subtitle_text
	sub.modulate = Color("#7d909a")
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	row.add_child(sub)
	parent.add_child(HSeparator.new())

func _add_identity_section_heading(parent: VBoxContainer, title_text: String, subtitle_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_add_icon(row, IconSectionMarker, Vector2(16, 20))
	var title := Label.new()
	title.text = title_text
	title.modulate = AUI_COLOR_TEXT_PRIMARY
	title.add_theme_font_size_override("font_size", 15)
	row.add_child(title)
	var sub := Label.new()
	sub.text = subtitle_text
	sub.modulate = AUI_COLOR_TEXT_MUTED
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	row.add_child(sub)
	parent.add_child(row)
	parent.add_child(HSeparator.new())

func _add_identity_line_edit(parent: VBoxContainer, label_text: String, value: String, placeholder: String) -> LineEdit:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, AUI_FIELD_ROW_HEIGHT)
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = AUI_COLOR_TEXT_SECONDARY
	label.add_theme_font_size_override("font_size", 15)
	row.add_child(label)
	var edit := LineEdit.new()
	edit.text = value
	edit.placeholder_text = placeholder
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(0, AUI_FIELD_ROW_HEIGHT)
	row.add_child(edit)
	parent.add_child(row)
	return edit

func _add_identity_dropdown(parent: VBoxContainer, label_text: String, options: Array, selected_value: String) -> OptionButton:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, AUI_FIELD_ROW_HEIGHT)
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = AUI_COLOR_TEXT_SECONDARY
	label.add_theme_font_size_override("font_size", 15)
	row.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.custom_minimum_size = Vector2(0, AUI_FIELD_ROW_HEIGHT)
	for item in options:
		option.add_item(String(item))
	var selected_index := options.find(selected_value)
	option.select(selected_index if selected_index > 0 else 0)
	row.add_child(option)
	parent.add_child(row)
	return option

func _add_identity_year_dropdown(parent: VBoxContainer, profile_name: String) -> OptionButton:
	var years: Array = ["请选择出生年份"]
	for year in range(2030, 1959, -1):
		years.append(str(year))
	var selected_year := str(int(profile.get("birth_year"))) if not profile_name.strip_edges().is_empty() else ""
	return _add_identity_dropdown(parent, "出生年份 *", years, selected_year)

func _add_identity_readonly(parent: VBoxContainer, label_text: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 40)
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = AUI_COLOR_TEXT_SECONDARY
	label.add_theme_font_size_override("font_size", 15)
	row.add_child(label)
	var field := PanelContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.mouse_default_cursor_shape = Control.CURSOR_ARROW
	field.focus_mode = Control.FOCUS_NONE
	var field_style := StyleBoxFlat.new()
	field_style.bg_color = AUI_COLOR_READONLY_BG
	field_style.border_color = AUI_COLOR_READONLY_BORDER
	field_style.set_border_width_all(AUI_BORDER_WIDTH)
	field_style.corner_radius_top_left = AUI_INPUT_RADIUS
	field_style.corner_radius_top_right = AUI_INPUT_RADIUS
	field_style.corner_radius_bottom_left = AUI_INPUT_RADIUS
	field_style.corner_radius_bottom_right = AUI_INPUT_RADIUS
	field_style.content_margin_left = 12
	field_style.content_margin_right = 10
	field.add_theme_stylebox_override("panel", field_style)
	var field_row := HBoxContainer.new()
	var text := Label.new()
	text.text = value
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.modulate = AUI_COLOR_TEXT_READONLY
	text.add_theme_font_size_override("font_size", 15)
	field_row.add_child(text)
	_add_icon(field_row, IconLock, Vector2(20, 20))
	field.add_child(field_row)
	row.add_child(field)
	parent.add_child(row)

func _add_identity_mission_info(parent: VBoxContainer) -> void:
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 4)
	parent.add_child(info_box)
	for item in [["任务名称", "广寒计划"], ["任务类型", "长期驻留 / 生命支持建设"], ["派驻地点", "月球 · 广寒前哨"], ["地月距离", "384,400 km"], ["单程通信延迟", "约 1.3 s"], ["任务周期", "长期派驻，训练后确认"], ["当前身份", String(profile.get("mission_identity"))]]:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 22)
		var label := Label.new()
		label.text = String(item[0])
		label.custom_minimum_size = Vector2(150, 0)
		label.modulate = AUI_COLOR_TEXT_SECONDARY
		label.add_theme_font_size_override("font_size", 13)
		row.add_child(label)
		var value := Label.new()
		value.text = String(item[1])
		value.modulate = AUI_COLOR_TEXT_INPUT
		value.add_theme_font_size_override("font_size", 13)
		row.add_child(value)
		info_box.add_child(row)

func _add_mission_link_diagram(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "地球通信与派驻示意图"
	heading.modulate = AUI_COLOR_TEXT_SECONDARY
	heading.add_theme_font_size_override("font_size", 13)
	parent.add_child(heading)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(0, 150)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("#0a1620")
	frame_style.border_color = Color("#1e394b")
	frame_style.set_border_width_all(AUI_BORDER_WIDTH)
	frame_style.corner_radius_top_left = AUI_INPUT_RADIUS
	frame_style.corner_radius_top_right = AUI_INPUT_RADIUS
	frame_style.corner_radius_bottom_left = AUI_INPUT_RADIUS
	frame_style.corner_radius_bottom_right = AUI_INPUT_RADIUS
	frame_style.content_margin_left = 16
	frame_style.content_margin_right = 16
	frame_style.content_margin_top = 10
	frame_style.content_margin_bottom = 10
	frame.add_theme_stylebox_override("panel", frame_style)
	parent.add_child(frame)

	var route := HBoxContainer.new()
	route.alignment = BoxContainer.ALIGNMENT_CENTER
	route.size_flags_vertical = Control.SIZE_EXPAND_FILL
	route.add_theme_constant_override("separation", 14)
	frame.add_child(route)

	var earth_stop := VBoxContainer.new()
	earth_stop.alignment = BoxContainer.ALIGNMENT_CENTER
	earth_stop.add_theme_constant_override("separation", 4)
	_add_icon(earth_stop, IconEarth, Vector2(64, 64))
	_add_diagram_label(earth_stop, "地球", AUI_COLOR_TEXT_INPUT, 14)
	var terminal_row := HBoxContainer.new()
	terminal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	terminal_row.add_theme_constant_override("separation", 4)
	_add_icon(terminal_row, IconTerminal, Vector2(16, 16))
	_add_diagram_label(terminal_row, "当前申请终端", AUI_COLOR_SUCCESS, 11)
	earth_stop.add_child(terminal_row)
	route.add_child(earth_stop)

	var link_a := VBoxContainer.new()
	link_a.custom_minimum_size = Vector2(170, 0)
	link_a.alignment = BoxContainer.ALIGNMENT_CENTER
	link_a.add_theme_constant_override("separation", 4)
	_add_diagram_label(link_a, "384,400 km", AUI_COLOR_TEXT_SECONDARY, 13)
	_add_solid_double_arrow(link_a, 130, Color("#5fb0e0"))
	_add_diagram_label(link_a, "单程约 1.3 s", AUI_COLOR_TEXT_SECONDARY, 12)
	route.add_child(link_a)

	var moon_stop := VBoxContainer.new()
	moon_stop.alignment = BoxContainer.ALIGNMENT_CENTER
	moon_stop.add_theme_constant_override("separation", 4)
	_add_icon(moon_stop, IconMoon, Vector2(48, 48))
	_add_diagram_label(moon_stop, "月球", AUI_COLOR_TEXT_INPUT, 14)
	route.add_child(moon_stop)

	var link_b := VBoxContainer.new()
	link_b.custom_minimum_size = Vector2(50, 0)
	link_b.alignment = BoxContainer.ALIGNMENT_CENTER
	_add_dashed_single_arrow(link_b, 44, AUI_COLOR_TEXT_MUTED)
	route.add_child(link_b)

	var outpost_stop := VBoxContainer.new()
	outpost_stop.alignment = BoxContainer.ALIGNMENT_CENTER
	outpost_stop.add_theme_constant_override("separation", 4)
	_add_icon(outpost_stop, IconOutpost, Vector2(32, 32))
	_add_diagram_label(outpost_stop, "广寒前哨", AUI_COLOR_TEXT_INPUT, 14)
	route.add_child(outpost_stop)

func _add_diagram_label(parent: Container, text: String, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func _make_arrow_glyph(glyph: String, color: Color) -> Label:
	var label := Label.new()
	label.text = glyph
	label.modulate = color
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	return label

func _add_solid_double_arrow(parent: Container, width: int, color: Color) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(width, 14)
	row.add_theme_constant_override("separation", 2)
	row.add_child(_make_arrow_glyph("◀", color))
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 2)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.color = color
	row.add_child(line)
	row.add_child(_make_arrow_glyph("▶", color))
	parent.add_child(row)

func _add_dashed_single_arrow(parent: Container, width: int, color: Color) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(width, 14)
	row.add_theme_constant_override("separation", 4)
	for i in range(4):
		var dash := ColorRect.new()
		dash.custom_minimum_size = Vector2(7, 2)
		dash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dash.color = color
		row.add_child(dash)
	row.add_child(_make_arrow_glyph("▶", color))
	parent.add_child(row)

func _build_identity_footer() -> void:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = AUI_COLOR_PANEL_BG
	style.border_color = AUI_COLOR_PANEL_BORDER
	style.set_border_width_all(AUI_BORDER_WIDTH)
	style.corner_radius_top_left = AUI_PANEL_RADIUS
	style.corner_radius_top_right = AUI_PANEL_RADIUS
	style.corner_radius_bottom_left = AUI_PANEL_RADIUS
	style.corner_radius_bottom_right = AUI_PANEL_RADIUS
	style.content_margin_left = AUI_PANEL_PADDING
	style.content_margin_right = AUI_PANEL_PADDING
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	frame.add_theme_stylebox_override("panel", style)
	footer.add_child(frame)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 24)
	frame.add_child(row)

	# Cluster 1: circular status badge (icon_status_incomplete/complete, swaps) with the X/3 ratio overlaid.
	var badge := Control.new()
	badge.custom_minimum_size = Vector2(44, 44)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(badge)
	identity_status_icon = TextureRect.new()
	identity_status_icon.texture = IconStatusIncomplete
	identity_status_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	identity_status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	identity_status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	identity_status_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	badge.add_child(identity_status_icon)
	identity_ratio_label = Label.new()
	identity_ratio_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	identity_ratio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identity_ratio_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	identity_ratio_label.modulate = AUI_COLOR_TEXT_INPUT
	identity_ratio_label.add_theme_font_size_override("font_size", 14)
	badge.add_child(identity_ratio_label)

	row.add_child(VSeparator.new())

	# Cluster 2: validation status + hint.
	var middle_cluster := VBoxContainer.new()
	middle_cluster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle_cluster.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	middle_cluster.add_theme_constant_override("separation", 4)
	row.add_child(middle_cluster)
	identity_validation_label = Label.new()
	identity_validation_label.modulate = Color("#b9cad6")
	identity_validation_label.add_theme_font_size_override("font_size", 16)
	middle_cluster.add_child(identity_validation_label)
	identity_validation_hint_label = Label.new()
	identity_validation_hint_label.modulate = AUI_COLOR_TEXT_MUTED
	identity_validation_hint_label.add_theme_font_size_override("font_size", 12)
	middle_cluster.add_child(identity_validation_hint_label)

	row.add_child(VSeparator.new())

	# Cluster 3: required-field completion detail with per-field radio dots.
	var completion_cluster := VBoxContainer.new()
	completion_cluster.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	completion_cluster.add_theme_constant_override("separation", 6)
	row.add_child(completion_cluster)
	identity_progress_label = Label.new()
	identity_progress_label.modulate = AUI_COLOR_TEXT_INPUT
	identity_progress_label.add_theme_font_size_override("font_size", 15)
	completion_cluster.add_child(identity_progress_label)
	var dots_row := HBoxContainer.new()
	dots_row.add_theme_constant_override("separation", 16)
	completion_cluster.add_child(dots_row)
	identity_field_dots.clear()
	for field_key in ["姓名", "性别", "出生年份"]:
		var dot_label := Label.new()
		dot_label.text = "○ " + field_key
		dot_label.modulate = AUI_COLOR_TEXT_SECONDARY
		dot_label.add_theme_font_size_override("font_size", 13)
		dots_row.add_child(dot_label)
		identity_field_dots[field_key] = dot_label

	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(footer_spacer)

	# Cluster 4: back, next (return is never placed at the page's far left).
	var right_cluster := HBoxContainer.new()
	right_cluster.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_cluster.add_theme_constant_override("separation", 12)
	row.add_child(right_cluster)
	identity_back_button = Button.new()
	identity_back_button.text = "返回"
	identity_back_button.custom_minimum_size = Vector2(150, AUI_BUTTON_HEIGHT)
	identity_back_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	right_cluster.add_child(identity_back_button)
	identity_next_button = Button.new()
	identity_next_button.text = "下一步"
	identity_next_button.icon = IconArrowRight
	identity_next_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	identity_next_button.custom_minimum_size = Vector2(220, AUI_BUTTON_HEIGHT)
	identity_next_button.pressed.connect(func():
		_capture_identity()
		_show_step("education")
	)
	right_cluster.add_child(identity_next_button)

func _style_identity_editable(edit: LineEdit) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = AUI_COLOR_FIELD_BG
	normal.border_color = AUI_COLOR_FIELD_BORDER
	normal.set_border_width_all(AUI_BORDER_WIDTH)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.corner_radius_top_left = AUI_INPUT_RADIUS
	normal.corner_radius_top_right = AUI_INPUT_RADIUS
	normal.corner_radius_bottom_left = AUI_INPUT_RADIUS
	normal.corner_radius_bottom_right = AUI_INPUT_RADIUS
	var hover := normal.duplicate()
	hover.border_color = Color("#638196")
	var focus := normal.duplicate()
	focus.border_color = AUI_COLOR_FIELD_FOCUS_BORDER
	focus.set_border_width_all(AUI_FOCUS_BORDER_WIDTH)
	var read_only := normal.duplicate()
	read_only.bg_color = AUI_COLOR_READONLY_BG
	read_only.border_color = AUI_COLOR_READONLY_BORDER
	edit.add_theme_stylebox_override("normal", normal)
	edit.add_theme_stylebox_override("hover", hover)
	edit.add_theme_stylebox_override("focus", focus)
	edit.add_theme_stylebox_override("read_only", read_only)
	edit.add_theme_color_override("font_color", AUI_COLOR_TEXT_INPUT)
	edit.add_theme_color_override("font_placeholder_color", AUI_COLOR_TEXT_MUTED)
	edit.add_theme_font_size_override("font_size", 16)

func _style_identity_option(option: OptionButton) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = AUI_COLOR_FIELD_BG
	normal.border_color = AUI_COLOR_FIELD_BORDER
	normal.set_border_width_all(AUI_BORDER_WIDTH)
	normal.corner_radius_top_left = AUI_INPUT_RADIUS
	normal.corner_radius_top_right = AUI_INPUT_RADIUS
	normal.corner_radius_bottom_left = AUI_INPUT_RADIUS
	normal.corner_radius_bottom_right = AUI_INPUT_RADIUS
	var hover := normal.duplicate()
	hover.border_color = Color("#638196")
	var focus := normal.duplicate()
	focus.border_color = AUI_COLOR_FIELD_FOCUS_BORDER
	focus.set_border_width_all(AUI_FOCUS_BORDER_WIDTH)
	option.add_theme_stylebox_override("normal", normal)
	option.add_theme_stylebox_override("hover", hover)
	option.add_theme_stylebox_override("focus", focus)
	option.add_theme_color_override("font_color", AUI_COLOR_TEXT_INPUT)
	option.add_theme_font_size_override("font_size", 16)
	var popup := option.get_popup()
	var popup_panel := StyleBoxFlat.new()
	popup_panel.bg_color = AUI_COLOR_FIELD_BG
	popup_panel.border_color = AUI_COLOR_FIELD_BORDER
	popup_panel.set_border_width_all(AUI_BORDER_WIDTH)
	popup.add_theme_stylebox_override("panel", popup_panel)
	popup.add_theme_color_override("font_color", AUI_COLOR_TEXT_SECONDARY)
	popup.add_theme_color_override("font_hover_color", AUI_COLOR_TEXT_INPUT)
	popup.add_theme_color_override("font_selected_color", Color("#b8c68a"))

func _style_identity_next_button(button: Button) -> void:
	var enabled := StyleBoxFlat.new()
	enabled.bg_color = Color("#213b50")
	enabled.border_color = Color("#607f93")
	enabled.set_border_width_all(AUI_BORDER_WIDTH)
	enabled.corner_radius_top_left = AUI_INPUT_RADIUS
	enabled.corner_radius_top_right = AUI_INPUT_RADIUS
	enabled.corner_radius_bottom_left = AUI_INPUT_RADIUS
	enabled.corner_radius_bottom_right = AUI_INPUT_RADIUS
	var enabled_hover := enabled.duplicate()
	enabled_hover.bg_color = Color("#2b4b62")
	var disabled := enabled.duplicate()
	disabled.bg_color = Color("#151f26")
	disabled.border_color = Color("#26333c")
	button.add_theme_stylebox_override("normal", enabled)
	button.add_theme_stylebox_override("hover", enabled_hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", AUI_COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", Color("#57646d"))

func _show_education() -> void:
	_add_page_title("选择候选人学术背景", "ACADEMIC BACKGROUND")
	_add_body("学术背景不会提供数值加成，但会影响你能看懂哪些专业线索。\n\n不同学术背景会在训练、维修、温室、生命支持和基地结构判断中提供额外专业提示。\n这些提示不会减少耗时、材料消耗或风险，只会帮助你做出更准确的判断。")
	var columns := _add_columns(0.38)
	var left: VBoxContainer = columns[0]
	var right: VBoxContainer = columns[1]
	_add_panel_title(left, "选择候选人学术背景")
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
	_add_body_to(right, "第一版作用：只影响专业提示，不改变移动速度、维修耗时、材料消耗、负重上限、精力消耗、睡眠恢复或健康状态。")
	var art := ApplicationArtPanelScript.new()
	art.panel_kind = "education"
	right.add_child(art)
	pending_academic_background_id = _selected_academic_background_id()
	_update_education_detail()
	_add_footer_button("返回", func():
		_show_step("identity")
	)
	_add_footer_button("确认选择", func():
		_confirm_academic_background_selection()
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
	var plain := SuitPreviewControlScript.new()
	plain.suited = false
	plain.marking_color = _marking_color()
	plain.patch_id = String(profile.get("suit_marking"))
	plain.suit_id = _suit_id()
	preview_row.add_child(plain)
	var suited := SuitPreviewControlScript.new()
	suited.suited = true
	suited.marking_color = _marking_color()
	suited.patch_id = String(profile.get("suit_marking"))
	suited.suit_id = _suit_id()
	preview_row.add_child(suited)
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
	# Candidate summary on the LEFT, submit confirmation on the RIGHT (user
	# request). The confirmation side carries the body text + 确认事项
	# checkboxes, so it stays the wider column -- hence left_ratio 0.48.
	var columns := _add_columns(0.48)
	var left: VBoxContainer = columns[0]
	var right: VBoxContainer = columns[1]
	_add_panel_title(left, "候选人摘要")
	_add_body_to(left, _profile_summary())
	_add_panel_title(right, "提交确认")
	_add_body_to(right, "你即将提交广寒计划常驻开拓者申请。\n\n一旦通过审核，你将进入国家深空生命科学中心训练序列。\n\n训练完成并通过最终考核后，\n你可能被派往月球广寒前哨，\n执行长期驻留与生命支持建设任务。")
	_add_panel_title(right, "确认事项")
	_add_confirmation_check(right, "我理解这是一项长期任务。")
	_add_confirmation_check(right, "我理解任务地点位于月球。")
	_add_confirmation_check(right, "我理解广寒前哨仍处于早期建设阶段。")
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
	_add_note_to(review_status, "学术背景匹配：进行中")
	_add_note_to(review_status, "训练序列分配：等待")
	review_lines = [
		"正在进行资格审核",
		"正在匹配学术背景",
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
	if birth_options != null and birth_options.selected > 0:
		profile.set("birth_year", int(birth_options.get_item_text(birth_options.selected)))
	if gender_options != null and gender_options.selected > 0:
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
	var selected := _academic_background_name_from_id(pending_academic_background_id)
	if education_detail_title != null:
		education_detail_title.text = selected if not selected.is_empty() else "请选择一个候选人学术背景"
	if education_detail_body != null:
		if selected.is_empty():
			education_detail_body.text = "未选择学术背景。\n\n请选择一个候选人学术背景后再确认。学术背景不会提供数值加成，只会影响专业提示。"
		else:
			education_detail_body.text = String(EDUCATION_DESCRIPTIONS.get(selected, ""))
	for option in education_buttons.keys():
		var button: Button = education_buttons[option]
		button.modulate = Color("#9ac7e8") if String(option) == selected else Color.WHITE

func _select_education(selected: String) -> void:
	pending_academic_background_id = _academic_background_id_from_name(selected)
	_update_education_detail()

func _confirm_academic_background_selection() -> void:
	if pending_academic_background_id.is_empty():
		_add_note_to(page_body, "请先选择一个候选人学术背景。")
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = "确认候选人学术背景"
	dialog.dialog_text = "确认候选人学术背景？\n\n该背景将在训练和基地系统中提供专业提示。\n第一版不会提供数值加成。\n\n是否确认？"
	add_child(dialog)
	dialog.confirmed.connect(func():
		_apply_academic_background_selection(pending_academic_background_id)
		dialog.queue_free()
		_show_step("appearance")
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	dialog.popup_centered(Vector2i(520, 300))

func _apply_academic_background_selection(background_id: String) -> void:
	var manager := _academic_background_manager()
	var background_name := _academic_background_name_from_id(background_id)
	if manager != null and manager.has_method("set_background"):
		manager.call("set_background", background_id)
	if background_name.is_empty():
		return
	profile.set("selected_academic_background_id", background_id)
	profile.set("education_background", background_name)
	_save_profile()

func _profile_summary() -> String:
	return "姓名：%s\n申请编号：%s\n候选人档案状态：%s\n任务身份：%s\n出生年份：%d\n性别：%s\n候选人学术背景：%s\n宇航服标识：%s / %s" % [
		_display_name(),
		String(profile.get("application_id")),
		String(profile.get("candidate_file_status")),
		String(profile.get("mission_identity")),
		int(profile.get("birth_year")),
		String(profile.get("gender_display")),
		_academic_background_display_name(),
		String(profile.get("suit_marking")),
		String(profile.get("suit_marking_color")),
	]

func _academic_background_display_name() -> String:
	var name := String(profile.get("education_background"))
	if not name.is_empty():
		return name
	return _academic_background_name_from_id(_selected_academic_background_id())

func _selected_academic_background_id() -> String:
	var selected_id := String(profile.get("selected_academic_background_id"))
	if not selected_id.is_empty():
		return _normalize_academic_background_id(selected_id)
	return _academic_background_id_from_name(String(profile.get("education_background")))

func _academic_background_id_from_name(background_name: String) -> String:
	var manager := _academic_background_manager()
	if manager != null and manager.has_method("normalize_background_id"):
		return String(manager.call("normalize_background_id", background_name))
	match background_name:
		"植物科学":
			return "plant_science"
		"机械工程":
			return "mechanical_engineering"
		"材料科学":
			return "materials_science"
		"医学":
			return "medical"
	return ""

func _academic_background_name_from_id(background_id: String) -> String:
	var normalized := _normalize_academic_background_id(background_id)
	var manager := _academic_background_manager()
	if manager != null and manager.has_method("get_all_backgrounds"):
		for data in manager.call("get_all_backgrounds"):
			if data is Dictionary and String((data as Dictionary).get("id", "")) == normalized:
				return String((data as Dictionary).get("name", ""))
	match normalized:
		"plant_science":
			return "植物科学"
		"mechanical_engineering":
			return "机械工程"
		"materials_science":
			return "材料科学"
		"medical":
			return "医学"
	return ""

func _normalize_academic_background_id(value: String) -> String:
	var manager := _academic_background_manager()
	if manager != null and manager.has_method("normalize_background_id"):
		return String(manager.call("normalize_background_id", value))
	return value

func _academic_background_manager() -> Node:
	return get_tree().root.get_node_or_null("AcademicBackgroundManager")

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
	var selected_academic_id := _selected_academic_background_id()
	if not selected_academic_id.is_empty():
		var background_name := _academic_background_name_from_id(selected_academic_id)
		profile.set("selected_academic_background_id", selected_academic_id)
		profile.set("education_background", background_name)
		var manager := _academic_background_manager()
		if manager != null and manager.has_method("set_background"):
			manager.call("set_background", selected_academic_id, false)

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
