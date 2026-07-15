extends Control

const PROFILE_PATH := "user://saves/application_profile.json"
const PlayerProfileDataScript := preload("res://scripts/data/player_profile_data.gd")
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

## AUI-03-02: real pre-placed profession icons (square variants only this
## round; circle variants are reserved for a later right-side "专业档案" task).
const IconProfessionPlantScience := preload("res://assets/ui/common/icons/professions/atlas/icon_profession_plant_science_square.tres")
const IconProfessionMechanicalEngineering := preload("res://assets/ui/common/icons/professions/atlas/icon_profession_mechanical_engineering_square.tres")
const IconProfessionMaterialsScience := preload("res://assets/ui/common/icons/professions/atlas/icon_profession_materials_science_square.tres")
const IconProfessionMedicine := preload("res://assets/ui/common/icons/professions/atlas/icon_profession_medicine_square.tres")

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
const AUI_PANEL_RADIUS := 4
const AUI_INPUT_RADIUS := 3
const AUI_BORDER_WIDTH := 1
const AUI_FOCUS_BORDER_WIDTH := 2

const AUI_COLOR_PAGE_BG := Color("#06121a")
const AUI_COLOR_PANEL_BG := Color("#0e181f")
const AUI_COLOR_PANEL_BORDER := Color("#223c4d")
const AUI_COLOR_FIELD_BG := Color("#0a1823")
const AUI_COLOR_FIELD_BORDER := Color("#405d70")
const AUI_COLOR_FIELD_FOCUS_BORDER := Color("#7f97a3")
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

## AUI-03-02: right-side "专业档案" content per profession id. focus_highlight/
## focus_body/domain_body are derived directly from the existing
## EDUCATION_DESCRIPTIONS copy (核心风险 -> focus, 信息优势 list -> domain) so
## the lore stays consistent instead of inventing new copy. hint_body is the
## shared generic sentence already used in the approved reference mockup.
const PROFESSION_PROFILE_CONTENT := {
	"plant_science": {
		"focus_highlight": "作物生长异常与生态循环失衡",
		"focus_body": "熟悉植物状态、水 / 光 / 温度对植物的影响、温室环境风险、植物恢复周期与作物生长问题。",
		"domain_body": "植物诊断、旧温室、作物生长、水循环与植物供水、补光与温度判断。",
	},
	"mechanical_engineering": {
		"focus_highlight": "设备故障链与系统运转风险",
		"focus_body": "熟悉电力系统、太阳能阵列、制氧模块、温控设备、水泵与设备故障链。",
		"domain_body": "太阳能板维修、供电恢复、制氧模块维修、温控系统维修、水循环设备维修。",
	},
	"materials_science": {
		"focus_highlight": "结构老化与舱体密封失效",
		"focus_body": "熟悉舱压、密封材料、结构老化、舱体接缝、气闸 / 对接口微漏、月尘磨蚀、辐射与温差损伤。",
		"domain_body": "气闸密封、飞船对接口检查、旧基地舱压异常、密封圈老化、结构裂纹判断。",
	},
	"medicine": {
		"focus_highlight": "生命支持与健康承受风险",
		"focus_body": "熟悉精力、饱腹、营养、心理、氧气不足对人体的影响、低温 / 高温风险与长期单人驻留风险。",
		"domain_body": "健康状态判断、恢复顺序建议、低氧 / 低温环境风险、高强度维修前提醒、睡眠恢复效率判断。",
	},
}
const PROFESSION_PROFILE_HINT_BODY := "在相关任务中，可获得额外的专业判断提示与线索，帮助你识别异常、定位问题并做出更准确决策。"

## Real region names read directly from each detail atlas's own JSON metadata
## (professions/details/<id>/sprite.godot.json or sprite.json) -- not guessed.
const PROFESSION_PROFILE_COVERAGE := {
	"plant_science": [
		{"icon": "res://assets/ui/common/icons/professions/details/plant_science/atlas/icon_domain_plant_growth.tres", "label": "作物生长"},
		{"icon": "res://assets/ui/common/icons/professions/details/plant_science/atlas/icon_domain_plant_light.tres", "label": "光照与补光"},
		{"icon": "res://assets/ui/common/icons/professions/details/plant_science/atlas/icon_domain_plant_water.tres", "label": "水循环与供水"},
		{"icon": "res://assets/ui/common/icons/professions/details/plant_science/atlas/icon_domain_plant_greenhouse.tres", "label": "旧温室诊断"},
		{"icon": "res://assets/ui/common/icons/professions/details/plant_science/atlas/icon_domain_plant_ecology_risk.tres", "label": "环境风险预判"},
	],
	"mechanical_engineering": [
		{"icon": "res://assets/ui/common/icons/professions/details/mechanical_engineering/atlas/icon_domain_mechanical_repair.tres", "label": "设备维修"},
		{"icon": "res://assets/ui/common/icons/professions/details/mechanical_engineering/atlas/icon_domain_mechanical_fault.tres", "label": "故障分析"},
		{"icon": "res://assets/ui/common/icons/professions/details/mechanical_engineering/atlas/icon_domain_mechanical_structure.tres", "label": "机械结构"},
		{"icon": "res://assets/ui/common/icons/professions/details/mechanical_engineering/atlas/icon_domain_mechanical_maintenance.tres", "label": "维护风险"},
		{"icon": "res://assets/ui/common/icons/professions/details/mechanical_engineering/atlas/icon_domain_mechanical_hatch.tres", "label": "舱体机构"},
	],
	"materials_science": [
		{"icon": "res://assets/ui/common/icons/professions/details/materials_science/atlas/icon_domain_material_fatigue.tres", "label": "材料疲劳"},
		{"icon": "res://assets/ui/common/icons/professions/details/materials_science/atlas/icon_domain_material_corrosion.tres", "label": "腐蚀风险"},
		{"icon": "res://assets/ui/common/icons/professions/details/materials_science/atlas/icon_domain_material_seal.tres", "label": "密封状态"},
		{"icon": "res://assets/ui/common/icons/professions/details/materials_science/atlas/icon_domain_material_durability.tres", "label": "结构耐久"},
		{"icon": "res://assets/ui/common/icons/professions/details/materials_science/atlas/icon_domain_material_extreme_environment.tres", "label": "极端环境影响"},
	],
	"medicine": [
		{"icon": "res://assets/ui/common/icons/professions/details/medicine/atlas/icon_domain_medicine_monitoring.tres", "label": "健康监测"},
		{"icon": "res://assets/ui/common/icons/professions/details/medicine/atlas/icon_domain_medicine_trauma.tres", "label": "创伤处理"},
		{"icon": "res://assets/ui/common/icons/professions/details/medicine/atlas/icon_domain_medicine_exposure.tres", "label": "环境暴露"},
		{"icon": "res://assets/ui/common/icons/professions/details/medicine/atlas/icon_domain_medicine_life_support.tres", "label": "生命支持"},
		{"icon": "res://assets/ui/common/icons/professions/details/medicine/atlas/icon_domain_medicine_risk.tres", "label": "健康风险判断"},
	],
}

const PROFESSION_PROFILE_CIRCLE_ICON_PATHS := {
	"plant_science": "res://assets/ui/common/icons/professions/atlas/icon_profession_plant_science_circle.tres",
	"mechanical_engineering": "res://assets/ui/common/icons/professions/atlas/icon_profession_mechanical_engineering_circle.tres",
	"materials_science": "res://assets/ui/common/icons/professions/atlas/icon_profession_materials_science_circle.tres",
	"medicine": "res://assets/ui/common/icons/professions/atlas/icon_profession_medicine_circle.tres",
}

const ICON_PROFILE_FOCUS_PATH := "res://assets/ui/common/icons/professions/details/common/atlas/icon_profile_focus.tres"
const ICON_PROFILE_DOMAIN_PATH := "res://assets/ui/common/icons/professions/details/common/atlas/icon_profile_domain.tres"
const ICON_PROFILE_HINT_PATH := "res://assets/ui/common/icons/professions/details/common/atlas/icon_profile_hint.tres"

## AUI-03-02: profession selection card data (left side of the 02 Academic
## Background page). `id` matches the existing academic-background id scheme
## used by _academic_background_id_from_name()/AcademicBackgroundManager.
const PROFESSION_CARD_DATA := [
	{"id": "plant_science", "name": "植物科学", "name_en": "PLANT SCIENCE", "keywords": ["作物诊断", "温室维护", "水循环"], "recommended": true},
	{"id": "mechanical_engineering", "name": "机械工程", "name_en": "MECHANICAL ENGINEERING", "keywords": ["设备维修", "故障分析", "机械维护"], "recommended": false},
	{"id": "materials_science", "name": "材料科学", "name_en": "MATERIALS SCIENCE", "keywords": ["材料检测", "结构老化", "密封可靠"], "recommended": false},
	{"id": "medicine", "name": "医学", "name_en": "MEDICINE", "keywords": ["健康监测", "创伤处理", "生命支持"], "recommended": false},
]

## Per-profession identity accent color, used on the left card list's keyword
## row so each profession reads at a glance (art-director round: "专业关键词
## 使用职业识别色"). Plant=green, mechanical=blue-gray, materials=silver-gray,
## medicine=cyan-blue.
const PROFESSION_ACCENT_COLORS := {
	"plant_science": Color("#7fc998"),
	"mechanical_engineering": Color("#8ea3b8"),
	"materials_science": Color("#b7c0c7"),
	"medicine": Color("#7fd3d9"),
}

## AUI-03-03: button-based appearance/marking option sets. `id` matches the
## real asset directory/region-name vocabulary under assets/characters/
## (player_preview/<gender>/<skin>/<hair_color>/sprite.png, region=<hair_style>;
## suits/sprite.png, region=suit_level_01_<suit_color>) so selection state
## maps directly to a real asset path with no separate lookup table.
const SKIN_TONE_OPTIONS := [
	{"id": "light", "label": "浅色", "swatch": Color("#e3c3a0")},
	{"id": "medium", "label": "中等暖色", "swatch": Color("#c3875a")},
	{"id": "dark", "label": "深色", "swatch": Color("#7a4a30")},
]
const HAIR_COLOR_OPTIONS := [
	{"id": "black", "label": "黑色", "swatch": Color("#1c1c1e")},
	{"id": "blond", "label": "金色", "swatch": Color("#d8b563")},
	{"id": "auburn", "label": "红棕色", "swatch": Color("#7a3b23")},
]
const SUIT_COLOR_OPTIONS := [
	{"id": "red", "label": "红色", "swatch": Color("#b5332b")},
	{"id": "yellow", "label": "黄色", "swatch": Color("#d9a52c")},
	{"id": "blue", "label": "蓝色", "swatch": Color("#2560a8")},
]
const HAIR_STYLE_OPTIONS_MALE := [
	{"id": "buzz", "label": "寸头"},
	{"id": "short", "label": "短发"},
	{"id": "long", "label": "长发"},
]
const HAIR_STYLE_OPTIONS_FEMALE := [
	{"id": "short", "label": "短发"},
	{"id": "ponytail", "label": "马尾"},
	{"id": "long", "label": "长发"},
]

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
var footer: HBoxContainer
var aui_canvas: Control
var _aui_canvas_last_available := Vector2(-1, -1)
var status_label: Label
var name_edit: LineEdit
var birth_options: OptionButton
var gender_options: OptionButton
var pending_academic_background_id := ""
var profession_cards: Dictionary = {}
var profession_next_button: Button
var profession_locked_ids: Array[String] = []
var profession_profile_icon: TextureRect
var profession_profile_name: Label
var profession_profile_name_en: Label
var profession_focus_highlight: Label
var profession_focus_body: Label
var profession_domain_body: Label
var profession_hint_body: Label
var profession_coverage_row: HBoxContainer
var profession_profile_empty_note: Label
var pending_skin_id := ""
var pending_hair_style_id := ""
var pending_hair_color_id := ""
var pending_suit_color_id := ""
var appearance_choice_buttons: Dictionary = {}
var appearance_portrait_rect: TextureRect
var appearance_suit_rect: TextureRect
var appearance_portrait_summary: Label
var appearance_suit_summary: Label
var appearance_next_button: Button
var appearance_status_icon: TextureRect
var appearance_ratio_label: Label
var appearance_progress_label: Label
var appearance_validation_label: Label
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
	_update_aui_canvas_scale()
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
	mouse_filter = Control.MOUSE_FILTER_PASS
	var background := ColorRect.new()
	background.color = AUI_COLOR_PAGE_BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# Single authoritative scaling: the whole application UI lives on one fixed
	# 1920x1080 logical canvas, uniformly scaled + letterboxed/pillarboxed to
	# fit the actual viewport. Nothing inside the canvas re-measures itself
	# against the real window size, and nothing else in this scene rescales
	# independently -- this is the only place scale is computed.
	aui_canvas = Control.new()
	aui_canvas.name = "AUICanvas"
	aui_canvas.size = Vector2(1920, 1080)
	aui_canvas.pivot_offset = Vector2.ZERO
	add_child(aui_canvas)

	var root := VBoxContainer.new()
	root.name = "ApplicationShell"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = AUI_PAGE_MARGIN
	root.offset_top = AUI_PAGE_MARGIN
	root.offset_right = -AUI_PAGE_MARGIN
	root.offset_bottom = -AUI_PAGE_MARGIN
	root.add_theme_constant_override("separation", AUI_SECTION_GAP)
	aui_canvas.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, AUI_HEADER_HEIGHT)
	header.add_theme_constant_override("separation", 18)
	root.add_child(header)

	# Left zone: institution logo + bilingual name. Fixed, does not drift with title length.
	var left_zone := HBoxContainer.new()
	left_zone.add_theme_constant_override("separation", 18)
	left_zone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(left_zone)
	var institution_icon := _add_icon(left_zone, IconInstitution, Vector2(64, 64))
	institution_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_add_header_label(left_zone, "国家深空生命科学中心", Vector2(210, 0), 16, AUI_COLOR_TEXT_INPUT)
	_add_header_label(left_zone, "NATIONAL DEEP SPACE\nLIFE SCIENCE CENTER", Vector2(170, 0), 12, AUI_COLOR_TEXT_SECONDARY)

	# Center zone: system title. Expands to fill remaining space, stays centered.
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(title_box)
	var title := Label.new()
	title.text = "广寒计划常驻开拓者申请系统"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color("#e0e7eb")
	title.add_theme_font_size_override("font_size", 22)
	title_box.add_child(title)
	var title_sub := Label.new()
	title_sub.text = "PROJECT GUANGHAN · PERMANENT PIONEER APPLICATION SYSTEM"
	title_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_sub.modulate = Color("#9baab3")
	title_sub.add_theme_font_size_override("font_size", 14)
	title_box.add_child(title_sub)

	# Right zone: system code, time, assistant icon. Fixed, kept clear of the page edge.
	var right_zone := MarginContainer.new()
	right_zone.add_theme_constant_override("margin_right", 6)
	header.add_child(right_zone)
	var meta_cluster := HBoxContainer.new()
	meta_cluster.add_theme_constant_override("separation", 12)
	meta_cluster.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_cluster.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_zone.add_child(meta_cluster)
	var meta_box := VBoxContainer.new()
	meta_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meta_cluster.add_child(meta_box)
	_add_meta_row(meta_box, "系统编号", "GHO-AS-2068-0421")
	_add_meta_row(meta_box, "当前时间", "2068-04-12  07:15:32")
	var assistant_icon := _add_icon(meta_cluster, IconAssistant, Vector2(53, 53))
	assistant_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	assistant_icon.modulate = Color(0.82, 0.85, 0.88)

	_add_step_bar(root)

	# The whole 1920x1080 canvas is what gets scaled to fit the window -- page
	# content is never wrapped in a ScrollContainer. At the 1920x1080 design
	# resolution, and at any smaller uniformly-scaled size, the fixed-height
	# chrome (header/step-nav/footer) plus the body's own budget always sum to
	# exactly 1080, so nothing overflows the canvas by construction.
	page_body = VBoxContainer.new()
	page_body.name = "PageBody"
	page_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_body.add_theme_constant_override("separation", 4)
	root.add_child(page_body)

	footer = HBoxContainer.new()
	footer.name = "Footer"
	footer.custom_minimum_size = Vector2(0, AUI_FOOTER_HEIGHT)
	footer.size_flags_vertical = Control.SIZE_SHRINK_END
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)

	_update_aui_canvas_scale()
	if not resized.is_connected(_update_aui_canvas_scale):
		resized.connect(_update_aui_canvas_scale)

func _update_aui_canvas_scale() -> void:
	if aui_canvas == null:
		return
	var available := size
	if available.x <= 0.0 or available.y <= 0.0:
		return
	if available == _aui_canvas_last_available:
		return
	_aui_canvas_last_available = available
	var scale_factor: float = min(available.x / 1920.0, available.y / 1080.0)
	aui_canvas.scale = Vector2(scale_factor, scale_factor)
	var scaled_size := Vector2(1920.0, 1080.0) * scale_factor
	aui_canvas.position = ((available - scaled_size) / 2.0).round()

func _add_meta_row(parent: VBoxContainer, label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(70, 0)
	label.modulate = Color("#8898a2")
	label.add_theme_font_size_override("font_size", 13)
	row.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.modulate = Color("#c5d0d6")
	value.add_theme_font_size_override("font_size", 13)
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
	_style_identity_next_button(identity_next_button, 20)
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
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 12)
	page_body.add_child(margin)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, AUI_PAGE_HEADING_HEIGHT - 12)
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	var index := Label.new()
	index.text = "01"
	index.modulate = AUI_COLOR_ACTIVE_ACCENT
	index.add_theme_font_size_override("font_size", 28)
	row.add_child(index)
	var labels := VBoxContainer.new()
	labels.add_theme_constant_override("separation", 1)
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
	description.modulate = AUI_COLOR_TEXT_SECONDARY
	description.add_theme_font_size_override("font_size", 14)
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	description.custom_minimum_size = Vector2(360, 0)
	row.add_child(description)
	var heading_spacer := Control.new()
	heading_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading_spacer)

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
	sub.add_theme_font_size_override("font_size", 12)
	row.add_child(sub)
	parent.add_child(HSeparator.new())

func _add_identity_section_heading(parent: VBoxContainer, title_text: String, subtitle_text: String, with_divider: bool = true) -> void:
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
	sub.add_theme_font_size_override("font_size", 12)
	row.add_child(sub)
	parent.add_child(row)
	if with_divider:
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
	var lock_icon := _add_icon(field_row, IconLock, Vector2(20, 20))
	lock_icon.modulate = Color(0.45, 0.5, 0.55)
	field.add_child(field_row)
	row.add_child(field)
	parent.add_child(row)

func _add_identity_mission_info(parent: VBoxContainer) -> void:
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 4)
	parent.add_child(info_box)
	for item in [["任务名称", "广寒计划"], ["任务类型", "长期驻留 / 生命支持建设"], ["派驻地点", "月球 · 广寒前哨"], ["地月距离", "384,400 km"], ["单程通信延迟", "约 1.3 s"], ["任务周期", "长期派驻，训练后确认"], ["当前身份", String(profile.get("mission_identity"))]]:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 24)
		var label := Label.new()
		label.text = String(item[0])
		label.custom_minimum_size = Vector2(150, 0)
		label.modulate = AUI_COLOR_TEXT_SECONDARY
		label.add_theme_font_size_override("font_size", 14)
		row.add_child(label)
		var value := Label.new()
		value.text = String(item[1])
		value.modulate = AUI_COLOR_TEXT_INPUT
		value.add_theme_font_size_override("font_size", 14)
		row.add_child(value)
		info_box.add_child(row)

func _add_mission_link_diagram(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "地球通信与派驻示意图"
	heading.modulate = AUI_COLOR_TEXT_SECONDARY
	heading.add_theme_font_size_override("font_size", 13)
	parent.add_child(heading)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(0, 190)
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
	frame_style.content_margin_top = 18
	frame_style.content_margin_bottom = 18
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
	_add_diagram_label(terminal_row, "当前申请终端", AUI_COLOR_SUCCESS, 13)
	earth_stop.add_child(terminal_row)
	route.add_child(earth_stop)

	var link_a := VBoxContainer.new()
	link_a.custom_minimum_size = Vector2(170, 0)
	link_a.alignment = BoxContainer.ALIGNMENT_CENTER
	link_a.add_theme_constant_override("separation", 4)
	_add_diagram_label(link_a, "384,400 km", AUI_COLOR_TEXT_SECONDARY, 14)
	_add_solid_double_arrow(link_a, 130, Color("#5fb0e0"))
	_add_diagram_label(link_a, "单程约 1.3 s", AUI_COLOR_TEXT_SECONDARY, 14)
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
	identity_validation_hint_label.add_theme_font_size_override("font_size", 13)
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
	identity_back_button = _make_step_back_button("返回", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	right_cluster.add_child(identity_back_button)
	identity_next_button = _make_step_next_button("下一步", func():
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
	option.add_theme_stylebox_override("normal", normal)
	option.add_theme_stylebox_override("hover", hover)
	option.add_theme_stylebox_override("focus", focus)
	option.add_theme_color_override("font_color", AUI_COLOR_TEXT_INPUT)
	option.add_theme_font_size_override("font_size", 16)
	option.add_theme_constant_override("arrow_margin", 16)
	var popup := option.get_popup()
	var popup_panel := StyleBoxFlat.new()
	popup_panel.bg_color = AUI_COLOR_FIELD_BG
	popup_panel.border_color = AUI_COLOR_FIELD_BORDER
	popup_panel.set_border_width_all(AUI_BORDER_WIDTH)
	popup.add_theme_stylebox_override("panel", popup_panel)
	popup.add_theme_color_override("font_color", AUI_COLOR_TEXT_SECONDARY)
	popup.add_theme_color_override("font_hover_color", AUI_COLOR_TEXT_INPUT)
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_constant_override("v_separation", 14)
	popup.add_theme_constant_override("item_start_padding", 16)
	popup.add_theme_constant_override("item_end_padding", 16)
	popup.add_theme_color_override("font_selected_color", Color("#b8c68a"))

func _style_identity_next_button(button: Button, icon_right_inset: int = 0) -> void:
	var enabled := StyleBoxFlat.new()
	enabled.bg_color = Color("#213b50")
	enabled.border_color = Color("#607f93")
	enabled.set_border_width_all(AUI_BORDER_WIDTH)
	enabled.corner_radius_top_left = AUI_INPUT_RADIUS
	enabled.corner_radius_top_right = AUI_INPUT_RADIUS
	enabled.corner_radius_bottom_left = AUI_INPUT_RADIUS
	enabled.corner_radius_bottom_right = AUI_INPUT_RADIUS
	if icon_right_inset > 0:
		enabled.content_margin_right = icon_right_inset
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
	if icon_right_inset > 0:
		button.add_theme_color_override("icon_normal_color", AUI_COLOR_TEXT_PRIMARY)
		button.add_theme_color_override("icon_hover_color", AUI_COLOR_TEXT_PRIMARY)
		button.add_theme_color_override("icon_pressed_color", AUI_COLOR_TEXT_PRIMARY)
		button.add_theme_color_override("icon_disabled_color", Color("#57646d"))

## Shared step-navigation button component: every application-flow page's
## "返回"/"下一步" pair is built through these two so they can never drift
## apart in size or style again (previously page 01 and page 02 independently
## grew 150x50/220x50 vs 210x56).
const STEP_BUTTON_SIZE := Vector2(210, 56)

func _make_step_back_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = STEP_BUTTON_SIZE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(callback)
	return button

func _make_step_next_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.icon = IconArrowRight
	button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 22)
	button.add_theme_constant_override("h_separation", 18)
	button.custom_minimum_size = STEP_BUTTON_SIZE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(callback)
	_style_identity_next_button(button, 20)
	return button

func _show_education() -> void:
	_add_page_title("选择专业背景", "SELECT PROFESSIONAL BACKGROUND")
	_add_body("选择你的专业背景，它将影响你在任务中获得的专业判断与信息提示。")
	var columns := _add_columns(0.5)
	var left: VBoxContainer = columns[0]
	var right: VBoxContainer = columns[1]
	_style_identity_panel(left.get_parent() as PanelContainer)
	_style_identity_panel(right.get_parent() as PanelContainer)
	pending_academic_background_id = _selected_academic_background_id()

	_add_identity_panel_heading(left, "候选人专业选择", "PROFESSIONAL SELECTION")
	_add_profession_card_list(left)

	var left_spacer := Control.new()
	left_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(left_spacer)

	left.add_child(HSeparator.new())
	var shared_note := VBoxContainer.new()
	shared_note.add_theme_constant_override("separation", 4)
	left.add_child(shared_note)
	_add_note_to_styled(shared_note, "专业背景仅影响任务中的专业提示与判断线索，不直接改变角色属性、行动耗时或资源消耗。", Color("#7a8792"), 14)
	_add_note_to_styled(shared_note, "该背景将在本次申请提交后锁定，请谨慎选择。", Color("#7a8792"), 14)

	_build_profession_profile_panel(right)
	_refresh_profession_profile()

	_build_education_footer()
	_refresh_profession_next_button()

func _build_education_footer() -> void:
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
	row.add_theme_constant_override("separation", 12)
	frame.add_child(row)

	# Right-clustered action bar, matching page 01's footer exactly: a leading
	# spacer pushes a tight back+next cluster to the right edge, instead of
	# pinning the two buttons to opposite ends of the bar (that spread-out
	# layout read as much larger/more prominent than page 01's compact
	# cluster once the two pages were compared side by side).
	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(footer_spacer)

	var right_cluster := HBoxContainer.new()
	right_cluster.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_cluster.add_theme_constant_override("separation", 12)
	row.add_child(right_cluster)

	var education_back_button := _make_step_back_button("返回", func(): _show_step("identity"))
	right_cluster.add_child(education_back_button)

	profession_next_button = _make_step_next_button("下一步", func():
		_show_step("appearance")
	)
	right_cluster.add_child(profession_next_button)

func _add_note_to_styled(parent: VBoxContainer, text: String, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func _profession_icon(id: String) -> Texture2D:
	match id:
		"plant_science":
			return IconProfessionPlantScience
		"mechanical_engineering":
			return IconProfessionMechanicalEngineering
		"materials_science":
			return IconProfessionMaterialsScience
		"medicine":
			return IconProfessionMedicine
	return null

func _load_icon(path: String) -> Texture2D:
	if path.is_empty():
		return null
	return load(path) as Texture2D

func _profession_card_data(id: String) -> Dictionary:
	for data in PROFESSION_CARD_DATA:
		if String(data["id"]) == id:
			return data
	return {}

func _build_profession_profile_panel(parent: VBoxContainer) -> void:
	_add_identity_panel_heading(parent, "专业档案", "PROFESSIONAL PROFILE")

	# Only two "main" dividers on this panel: the panel heading's own divider
	# above, and the one added later between the info block and coverage.
	# The 职业信息/重点关注/专业领域/任务提示 sub-headers below use vertical
	# whitespace instead of a line each, per the art-director round asking to
	# reduce this panel's line count.
	_add_identity_section_heading(parent, "职业信息", "PROFESSION OVERVIEW", false)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	parent.add_child(header_row)
	profession_profile_icon = TextureRect.new()
	profession_profile_icon.custom_minimum_size = Vector2(48, 48)
	profession_profile_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	profession_profile_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	profession_profile_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	profession_profile_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header_row.add_child(profession_profile_icon)
	var name_box := VBoxContainer.new()
	name_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_box.add_theme_constant_override("separation", 1)
	header_row.add_child(name_box)
	profession_profile_name = Label.new()
	profession_profile_name.modulate = AUI_COLOR_TEXT_PRIMARY
	profession_profile_name.add_theme_font_size_override("font_size", 32)
	name_box.add_child(profession_profile_name)
	profession_profile_name_en = Label.new()
	profession_profile_name_en.modulate = AUI_COLOR_TEXT_SECONDARY
	profession_profile_name_en.add_theme_font_size_override("font_size", 16)
	name_box.add_child(profession_profile_name_en)

	profession_profile_empty_note = Label.new()
	profession_profile_empty_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profession_profile_empty_note.modulate = AUI_COLOR_TEXT_MUTED
	profession_profile_empty_note.add_theme_font_size_override("font_size", 14)
	parent.add_child(profession_profile_empty_note)

	var focus_refs := _build_profile_section(parent, ICON_PROFILE_FOCUS_PATH, "重点关注", "KEY FOCUS")
	profession_focus_highlight = Label.new()
	profession_focus_highlight.modulate = Color("#6fb4ff")
	profession_focus_highlight.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profession_focus_highlight.add_theme_font_size_override("font_size", 15)
	(focus_refs["section"] as VBoxContainer).add_child(profession_focus_highlight)
	(focus_refs["section"] as VBoxContainer).move_child(profession_focus_highlight, 1)
	profession_focus_body = focus_refs["body"]

	parent.add_child(_make_fixed_spacer(20))
	var domain_refs := _build_profile_section(parent, ICON_PROFILE_DOMAIN_PATH, "专业领域", "DOMAIN EXPERTISE")
	profession_domain_body = domain_refs["body"]

	parent.add_child(_make_fixed_spacer(20))
	var hint_refs := _build_profile_section(parent, ICON_PROFILE_HINT_PATH, "任务提示", "MISSION HINT")
	profession_hint_body = hint_refs["body"]

	var profile_spacer := Control.new()
	profile_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(profile_spacer)

	# The one other "main" divider on this panel: marks the boundary between
	# the info block above and the coverage block below.
	parent.add_child(HSeparator.new())
	_add_identity_section_heading(parent, "专业判断覆盖领域", "COVERAGE AREAS", false)
	profession_coverage_row = HBoxContainer.new()
	profession_coverage_row.add_theme_constant_override("separation", 8)
	parent.add_child(profession_coverage_row)
	var coverage_bottom_pad := Control.new()
	coverage_bottom_pad.custom_minimum_size = Vector2(0, 28)
	parent.add_child(coverage_bottom_pad)

func _make_fixed_spacer(height: int) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer

func _build_profile_section(parent: VBoxContainer, icon_path: String, title_text: String, subtitle_text: String) -> Dictionary:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)
	parent.add_child(section)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	section.add_child(header)
	var icon := TextureRect.new()
	icon.texture = _load_icon(icon_path)
	icon.custom_minimum_size = Vector2(28, 28)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header.add_child(icon)
	var title := Label.new()
	title.text = title_text
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.modulate = AUI_COLOR_TEXT_PRIMARY
	title.add_theme_font_size_override("font_size", 15)
	header.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.modulate = AUI_COLOR_TEXT_MUTED
	subtitle.add_theme_font_size_override("font_size", 12)
	header.add_child(subtitle)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = AUI_COLOR_TEXT_SECONDARY
	body.add_theme_font_size_override("font_size", 16)
	section.add_child(body)
	return {"section": section, "body": body}

func _build_coverage_item(icon_path: String, label_text: String) -> VBoxContainer:
	var item := VBoxContainer.new()
	item.custom_minimum_size = Vector2(150, 0)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_theme_constant_override("separation", 12)
	var icon := TextureRect.new()
	icon.texture = _load_icon(icon_path)
	icon.custom_minimum_size = Vector2(40, 40)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.add_child(icon)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = AUI_COLOR_TEXT_SECONDARY
	label.add_theme_font_size_override("font_size", 12)
	item.add_child(label)
	return item

func _refresh_profession_profile() -> void:
	if profession_profile_name == null:
		return
	var id := pending_academic_background_id
	var content: Dictionary = PROFESSION_PROFILE_CONTENT.get(id, {})
	var card_data := _profession_card_data(id)
	var has_selection := not content.is_empty() and not card_data.is_empty()

	profession_profile_empty_note.visible = not has_selection
	if not has_selection:
		profession_profile_empty_note.text = "请选择左侧的专业背景，右侧将显示对应的重点关注、专业领域、任务提示与专业判断覆盖领域。"
		profession_profile_icon.texture = null
		profession_profile_name.text = "未选择专业背景"
		profession_profile_name_en.text = ""
		profession_focus_highlight.text = ""
		profession_focus_body.text = ""
		profession_domain_body.text = ""
		profession_hint_body.text = ""
		_clear_container(profession_coverage_row)
		return

	profession_profile_icon.texture = _load_icon(String(PROFESSION_PROFILE_CIRCLE_ICON_PATHS.get(id, "")))
	profession_profile_name.text = String(card_data["name"])
	profession_profile_name_en.text = String(card_data["name_en"])
	profession_focus_highlight.text = String(content["focus_highlight"])
	profession_focus_body.text = String(content["focus_body"])
	profession_domain_body.text = String(content["domain_body"])
	profession_hint_body.text = PROFESSION_PROFILE_HINT_BODY

	_clear_container(profession_coverage_row)
	var coverage: Array = PROFESSION_PROFILE_COVERAGE.get(id, [])
	for entry in coverage:
		profession_coverage_row.add_child(_build_coverage_item(String(entry["icon"]), String(entry["label"])))

func _add_profession_card_list(parent: VBoxContainer) -> void:
	profession_cards.clear()
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 14)
	parent.add_child(list)
	for i in range(PROFESSION_CARD_DATA.size()):
		var data: Dictionary = PROFESSION_CARD_DATA[i]
		if i > 0:
			list.add_child(HSeparator.new())
		var id: String = data["id"]
		var locked := id in profession_locked_ids
		var card := Button.new()
		card.custom_minimum_size = Vector2(0, 98)
		card.focus_mode = Control.FOCUS_NONE
		card.disabled = locked
		card.mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_POINTING_HAND
		card.pressed.connect(_select_profession.bind(id))
		list.add_child(card)

		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 16)
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 24
		row.offset_right = -24
		row.offset_top = 21
		row.offset_bottom = -21
		card.add_child(row)

		# Icon sits in its own square frame (thicker border) so it reads as a
		# distinct visual anchor rather than a bare floating glyph.
		var icon_frame := PanelContainer.new()
		icon_frame.custom_minimum_size = Vector2(52, 52)
		icon_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_frame_style := StyleBoxFlat.new()
		icon_frame_style.bg_color = Color("#0d1821")
		icon_frame_style.border_color = Color("#324a5c")
		icon_frame_style.set_border_width_all(2)
		icon_frame_style.corner_radius_top_left = AUI_INPUT_RADIUS
		icon_frame_style.corner_radius_top_right = AUI_INPUT_RADIUS
		icon_frame_style.corner_radius_bottom_left = AUI_INPUT_RADIUS
		icon_frame_style.corner_radius_bottom_right = AUI_INPUT_RADIUS
		icon_frame.add_theme_stylebox_override("panel", icon_frame_style)
		row.add_child(icon_frame)
		var icon := TextureRect.new()
		icon.texture = _profession_icon(id)
		icon.custom_minimum_size = Vector2(44, 44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_frame.add_child(icon)

		var text_box := VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_box.add_theme_constant_override("separation", 5)
		row.add_child(text_box)

		var title_row := HBoxContainer.new()
		title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_row.add_theme_constant_override("separation", 8)
		text_box.add_child(title_row)
		var title := Label.new()
		title.text = String(data["name"])
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title.add_theme_font_size_override("font_size", 18)
		title_row.add_child(title)
		if bool(data["recommended"]):
			title_row.add_child(_build_recommended_tag())

		var keyword_row := HBoxContainer.new()
		keyword_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		keyword_row.add_theme_constant_override("separation", 10)
		text_box.add_child(keyword_row)
		var keyword_labels: Array[Label] = []
		var keywords: Array = data["keywords"]
		for k in range(keywords.size()):
			if k > 0:
				var dot := Label.new()
				dot.text = "·"
				dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
				dot.add_theme_font_size_override("font_size", 13)
				keyword_row.add_child(dot)
			var keyword_label := Label.new()
			keyword_label.text = String(keywords[k])
			keyword_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			keyword_label.add_theme_font_size_override("font_size", 13)
			keyword_row.add_child(keyword_label)
			keyword_labels.append(keyword_label)

		# Trailing selector sits in its own fixed-width slot so it reliably
		# ends up 24px from the card's right edge regardless of text width.
		var trailing_slot := Control.new()
		trailing_slot.custom_minimum_size = Vector2(22, 22)
		trailing_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		trailing_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(trailing_slot)
		var trailing := TextureRect.new()
		trailing.set_anchors_preset(Control.PRESET_FULL_RECT)
		trailing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trailing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		trailing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if locked:
			trailing.texture = IconLock
			trailing.modulate = Color(0.5, 0.55, 0.6)
		trailing_slot.add_child(trailing)

		profession_cards[id] = {
			"card": card,
			"title": title,
			"keyword_labels": keyword_labels,
			"trailing": trailing,
			"locked": locked,
		}
	_refresh_profession_cards()

func _build_recommended_tag() -> PanelContainer:
	var tag := PanelContainer.new()
	tag.custom_minimum_size = Vector2(56, 21)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1a2e20")
	style.border_color = Color("#4d8b61")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 9
	style.content_margin_right = 9
	tag.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "推荐"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color("#7fc998")
	label.add_theme_font_size_override("font_size", 11)
	tag.add_child(label)
	return tag

func _select_profession(id: String) -> void:
	if id in profession_locked_ids:
		return
	pending_academic_background_id = id
	_apply_academic_background_selection(id)
	_refresh_profession_cards()
	_refresh_profession_profile()
	_refresh_profession_next_button()

func _refresh_profession_cards() -> void:
	for id in profession_cards.keys():
		var entry: Dictionary = profession_cards[id]
		var card: Button = entry["card"]
		var locked: bool = entry["locked"]
		var selected: bool = not locked and String(id) == pending_academic_background_id
		var title: Label = entry["title"]
		var keyword_labels: Array = entry["keyword_labels"]
		var trailing: TextureRect = entry["trailing"]
		_style_profession_card(card, "locked" if locked else ("selected" if selected else "default"))
		var keyword_color: Color
		if locked:
			title.modulate = Color("#7a8a96")
			keyword_color = Color("#5f6c76")
		else:
			title.modulate = Color("#ffffff") if selected else AUI_COLOR_TEXT_PRIMARY
			keyword_color = Color(PROFESSION_ACCENT_COLORS.get(String(id), AUI_COLOR_TEXT_SECONDARY))
			trailing.texture = _make_profession_selector_icon(selected)
		for keyword_label in keyword_labels:
			(keyword_label as Label).modulate = keyword_color

func _style_profession_card(card: Button, state: String) -> void:
	# Flat divided-list row (no floating box border/bg): rows are separated by
	# HSeparator lines, not by per-row panel boxes. Selected state reads via a
	# left accent bar + faint bg tint; hover via a faint bg tint only.
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#132029")
	match state:
		"selected":
			normal.bg_color = Color("#152a38")
			normal.border_width_left = 3
			normal.border_color = AUI_COLOR_ACTIVE_ACCENT
			hover = normal.duplicate()
		"locked":
			hover = normal.duplicate()
	card.add_theme_stylebox_override("normal", normal)
	card.add_theme_stylebox_override("pressed", normal)
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("disabled", normal)

func _make_profession_selector_icon(selected: bool) -> Texture2D:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var ring := Color("#3a86df") if selected else Color("#5a6472")
	for y in range(24):
		for x in range(24):
			var dx := float(x) - 11.5
			var dy := float(y) - 11.5
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= 11.0 and dist >= 9.0:
				image.set_pixel(x, y, ring)
			elif selected and dist < 9.0:
				image.set_pixel(x, y, ring)
	if selected:
		var mark := Color("#ffffff")
		var points := [Vector2i(7, 12), Vector2i(9, 14), Vector2i(11, 16), Vector2i(13, 14), Vector2i(15, 10), Vector2i(16, 9)]
		for point in points:
			image.set_pixelv(point, mark)
	return ImageTexture.create_from_image(image)

func _refresh_profession_next_button() -> void:
	if profession_next_button == null:
		return
	profession_next_button.disabled = pending_academic_background_id.is_empty()
	_style_identity_next_button(profession_next_button, 20)

func _show_appearance() -> void:
	_add_page_title("03 外观与标识", "APPEARANCE & MARKING")
	_add_body("设置你的个人档案外观与任务身份标识。这些信息仅用于档案展示与任务识别，不影响角色属性。")
	var columns := _add_columns(0.42)
	var left: VBoxContainer = columns[0]
	var right: VBoxContainer = columns[1]
	_style_identity_panel(left.get_parent() as PanelContainer)
	_style_identity_panel(right.get_parent() as PanelContainer)

	appearance_choice_buttons.clear()
	_normalize_appearance_selection()
	_build_appearance_left_panel(left)
	_build_appearance_preview_panel(right)
	_refresh_appearance_preview()
	_build_appearance_footer()
	_refresh_appearance_state()

func _normalize_appearance_selection() -> void:
	pending_skin_id = _match_option_id(String(profile.get("skin_preset")), SKIN_TONE_OPTIONS)
	pending_hair_style_id = _match_option_id(String(profile.get("hair_preset")), _hair_style_options())
	pending_hair_color_id = _match_option_id(String(profile.get("hair_color_preset")), HAIR_COLOR_OPTIONS)
	pending_suit_color_id = _match_option_id(String(profile.get("suit_marking_color")), SUIT_COLOR_OPTIONS)

func _match_option_id(stored_value: String, options: Array) -> String:
	var normalized := stored_value.strip_edges().to_lower()
	for option in options:
		if String(option["id"]) == normalized:
			return normalized
	return ""

func _gender_asset_id() -> String:
	return "female" if String(profile.get("gender_display")) == "女" else "male"

func _hair_style_options() -> Array:
	return HAIR_STYLE_OPTIONS_FEMALE if _gender_asset_id() == "female" else HAIR_STYLE_OPTIONS_MALE

func _option_label(options: Array, id: String) -> String:
	for option in options:
		if String(option["id"]) == id:
			return String(option["label"])
	return "—"

func _build_appearance_left_panel(left: VBoxContainer) -> void:
	_add_identity_panel_heading(left, "个人外观记录", "PERSONAL APPEARANCE")
	_add_identity_readonly(left, "性别 GENDER", "男性" if _gender_asset_id() == "male" else "女性")

	_build_swatch_group(left, "肤色", "SKIN TONE", SKIN_TONE_OPTIONS, "skin", pending_skin_id)
	_build_style_button_group(left, "发型", "HAIR STYLE", _hair_style_options(), "hair_style", pending_hair_style_id)
	_build_swatch_group(left, "发色", "HAIR COLOR", HAIR_COLOR_OPTIONS, "hair_color", pending_hair_color_id)

	_add_identity_section_heading(left, "任务身份信息", "MISSION IDENTIFICATION")
	_build_swatch_group(left, "宇航服标识色", "SUIT ID COLOR", SUIT_COLOR_OPTIONS, "suit_color", pending_suit_color_id)

	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 12)
	left.add_child(level_row)
	var level_label := Label.new()
	level_label.text = "宇航服等级"
	level_label.custom_minimum_size = Vector2(150, 0)
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.modulate = AUI_COLOR_TEXT_SECONDARY
	level_label.add_theme_font_size_override("font_size", 15)
	level_row.add_child(level_label)
	var level_value := Label.new()
	level_value.text = "一级任务宇航服   LEVEL 01"
	level_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_value.modulate = AUI_COLOR_TEXT_PRIMARY
	level_value.add_theme_font_size_override("font_size", 15)
	level_row.add_child(level_value)

	var left_spacer := Control.new()
	left_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(left_spacer)

	left.add_child(HSeparator.new())
	var note_box := VBoxContainer.new()
	note_box.add_theme_constant_override("separation", 4)
	left.add_child(note_box)
	_add_note_to_styled(note_box, "任务宇航服将使用以上识别信息。", Color("#7a8792"), 14)
	_add_note_to_styled(note_box, "个人外观仅用于档案展示，不影响角色属性。", Color("#7a8792"), 14)

func _build_swatch_group(parent: VBoxContainer, label_cn: String, label_en: String, options: Array, group_key: String, current_id: String) -> void:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 8)
	parent.add_child(wrap)
	_add_choice_group_heading(wrap, label_cn, label_en)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	wrap.add_child(row)
	var entries: Array = []
	for option in options:
		var id: String = option["id"]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 52)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.add_child(button)

		var content := HBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation", 8)
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 12
		content.offset_right = -10
		button.add_child(content)

		var swatch := PanelContainer.new()
		swatch.custom_minimum_size = Vector2(18, 18)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var swatch_style := StyleBoxFlat.new()
		swatch_style.bg_color = option["swatch"]
		swatch_style.border_color = Color(0, 0, 0, 0.35)
		swatch_style.set_border_width_all(1)
		swatch_style.corner_radius_top_left = 9
		swatch_style.corner_radius_top_right = 9
		swatch_style.corner_radius_bottom_left = 9
		swatch_style.corner_radius_bottom_right = 9
		swatch.add_theme_stylebox_override("panel", swatch_style)
		content.add_child(swatch)

		var label := Label.new()
		label.text = String(option["label"])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		content.add_child(label)

		var check_slot := Control.new()
		check_slot.custom_minimum_size = Vector2(16, 16)
		check_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		check_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(check_slot)
		var check_icon := TextureRect.new()
		check_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		check_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		check_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		check_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_slot.add_child(check_icon)

		button.pressed.connect(_select_appearance_choice.bind(group_key, id))
		entries.append({"id": id, "button": button, "check": check_icon, "label": label})
	appearance_choice_buttons[group_key] = entries
	_refresh_choice_group(group_key, current_id)

func _build_style_button_group(parent: VBoxContainer, label_cn: String, label_en: String, options: Array, group_key: String, current_id: String) -> void:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 8)
	parent.add_child(wrap)
	_add_choice_group_heading(wrap, label_cn, label_en)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	wrap.add_child(row)
	var entries: Array = []
	for option in options:
		var id: String = option["id"]
		var button := Button.new()
		button.text = String(option["label"])
		button.custom_minimum_size = Vector2(0, 52)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_select_appearance_choice.bind(group_key, id))
		row.add_child(button)
		entries.append({"id": id, "button": button, "check": null, "label": null})
	appearance_choice_buttons[group_key] = entries
	_refresh_choice_group(group_key, current_id)

func _add_choice_group_heading(parent: VBoxContainer, label_cn: String, label_en: String) -> void:
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	parent.add_child(heading)
	var title := Label.new()
	title.text = label_cn
	title.modulate = AUI_COLOR_TEXT_SECONDARY
	title.add_theme_font_size_override("font_size", 15)
	heading.add_child(title)
	var subtitle := Label.new()
	subtitle.text = label_en
	subtitle.modulate = AUI_COLOR_TEXT_MUTED
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	heading.add_child(subtitle)

func _select_appearance_choice(group_key: String, id: String) -> void:
	match group_key:
		"skin":
			pending_skin_id = id
		"hair_style":
			pending_hair_style_id = id
		"hair_color":
			pending_hair_color_id = id
		"suit_color":
			pending_suit_color_id = id
	_refresh_choice_group(group_key, id)
	_refresh_appearance_preview()
	_refresh_appearance_state()

func _refresh_choice_group(group_key: String, current_id: String) -> void:
	var entries: Array = appearance_choice_buttons.get(group_key, [])
	for entry in entries:
		var selected: bool = String(entry["id"]) == current_id and not current_id.is_empty()
		_style_appearance_choice_button(entry["button"], selected)
		if entry["check"] != null:
			(entry["check"] as TextureRect).texture = _make_checkbox_icon(true) if selected else null
		if entry["label"] != null:
			(entry["label"] as Label).modulate = Color("#ffffff") if selected else AUI_COLOR_TEXT_PRIMARY
		else:
			(entry["button"] as Button).add_theme_color_override("font_color", Color("#ffffff") if selected else AUI_COLOR_TEXT_PRIMARY)

func _style_appearance_choice_button(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.corner_radius_top_left = AUI_INPUT_RADIUS
	normal.corner_radius_top_right = AUI_INPUT_RADIUS
	normal.corner_radius_bottom_left = AUI_INPUT_RADIUS
	normal.corner_radius_bottom_right = AUI_INPUT_RADIUS
	if selected:
		normal.bg_color = Color("#152a38")
		normal.border_color = AUI_COLOR_ACTIVE_ACCENT
		normal.set_border_width_all(AUI_FOCUS_BORDER_WIDTH)
	else:
		normal.bg_color = AUI_COLOR_FIELD_BG
		normal.border_color = AUI_COLOR_FIELD_BORDER
		normal.set_border_width_all(AUI_BORDER_WIDTH)
	var hover := normal.duplicate()
	if not selected:
		hover.border_color = Color("#638196")
	var disabled := normal.duplicate()
	disabled.bg_color = Color("#0f141b")
	disabled.border_color = Color("#1b222c")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", normal.duplicate())
	button.add_theme_stylebox_override("disabled", disabled)

func _build_appearance_preview_panel(right: VBoxContainer) -> void:
	_add_identity_panel_heading(right, "外观与任务预览", "APPEARANCE & MISSION PREVIEW")
	var preview_row := HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 16)
	preview_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(preview_row)

	var portrait_panel := _build_preview_frame(preview_row, "个人档案影像", "PERSONNEL PORTRAIT")
	appearance_portrait_rect = TextureRect.new()
	appearance_portrait_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	appearance_portrait_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	appearance_portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	appearance_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	(portrait_panel["body"] as VBoxContainer).add_child(appearance_portrait_rect)
	appearance_portrait_summary = Label.new()
	appearance_portrait_summary.modulate = AUI_COLOR_TEXT_SECONDARY
	appearance_portrait_summary.add_theme_font_size_override("font_size", 13)
	(portrait_panel["body"] as VBoxContainer).add_child(appearance_portrait_summary)

	var suit_panel := _build_preview_frame(preview_row, "一级任务宇航服", "LEVEL 01 MISSION SUIT")
	appearance_suit_rect = TextureRect.new()
	appearance_suit_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	appearance_suit_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	appearance_suit_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	appearance_suit_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	(suit_panel["body"] as VBoxContainer).add_child(appearance_suit_rect)
	appearance_suit_summary = Label.new()
	appearance_suit_summary.modulate = AUI_COLOR_TEXT_SECONDARY
	appearance_suit_summary.add_theme_font_size_override("font_size", 13)
	(suit_panel["body"] as VBoxContainer).add_child(appearance_suit_summary)

func _build_preview_frame(parent: HBoxContainer, title_text: String, subtitle_text: String) -> Dictionary:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 1.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0a141c")
	style.border_color = AUI_COLOR_PANEL_BORDER
	style.set_border_width_all(AUI_BORDER_WIDTH)
	style.corner_radius_top_left = AUI_PANEL_RADIUS
	style.corner_radius_top_right = AUI_PANEL_RADIUS
	style.corner_radius_bottom_left = AUI_PANEL_RADIUS
	style.corner_radius_bottom_right = AUI_PANEL_RADIUS
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	frame.add_theme_stylebox_override("panel", style)
	parent.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	frame.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.modulate = AUI_COLOR_TEXT_PRIMARY
	title.add_theme_font_size_override("font_size", 14)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.modulate = AUI_COLOR_TEXT_MUTED
	subtitle.add_theme_font_size_override("font_size", 11)
	box.add_child(subtitle)
	return {"frame": frame, "body": box}

func _refresh_appearance_preview() -> void:
	if appearance_portrait_rect == null:
		return
	var gender_id := _gender_asset_id()
	var skin_id := pending_skin_id if not pending_skin_id.is_empty() else "medium"
	var hair_color_id := pending_hair_color_id if not pending_hair_color_id.is_empty() else "black"
	var style_options := _hair_style_options()
	var hair_style_id := pending_hair_style_id if not pending_hair_style_id.is_empty() else String(style_options[0]["id"])
	var suit_color_id := pending_suit_color_id if not pending_suit_color_id.is_empty() else "blue"

	appearance_portrait_rect.texture = _load_portrait_texture(gender_id, skin_id, hair_color_id, hair_style_id)
	appearance_suit_rect.texture = _load_suit_texture(suit_color_id)

	var gender_cn := "男性" if gender_id == "male" else "女性"
	appearance_portrait_summary.text = "性别：%s\n肤色：%s\n发型：%s\n发色：%s" % [
		gender_cn,
		_option_label(SKIN_TONE_OPTIONS, skin_id),
		_option_label(style_options, hair_style_id),
		_option_label(HAIR_COLOR_OPTIONS, hair_color_id),
	]
	appearance_suit_summary.text = "等级：一级（LEVEL 01）\n标识色：%s\n臂章编号：%s\n姓名缩写：%s" % [
		_option_label(SUIT_COLOR_OPTIONS, suit_color_id),
		String(profile.get("suit_marking")),
		_name_initials(),
	]

func _load_portrait_texture(gender_id: String, skin_id: String, hair_color_id: String, hair_style_id: String) -> Texture2D:
	var dir := "res://assets/characters/player_preview/%s/%s/%s/" % [gender_id, skin_id, hair_color_id]
	return _load_atlas_region(dir + "sprite.png", dir + "sprite.godot.json", dir + "sprite.json", hair_style_id)

func _load_suit_texture(suit_color_id: String) -> Texture2D:
	var dir := "res://assets/characters/suits/"
	return _load_atlas_region(dir + "sprite.png", dir + "sprite.godot.json", "", "suit_level_01_%s" % suit_color_id)

func _load_atlas_region(sprite_path: String, godot_json_path: String, fallback_json_path: String, region_name: String) -> Texture2D:
	if not FileAccess.file_exists(sprite_path):
		return null
	var base := load(sprite_path) as Texture2D
	if base == null:
		return null
	var json_path := godot_json_path
	if not FileAccess.file_exists(json_path) and not fallback_json_path.is_empty():
		json_path = fallback_json_path
	if not FileAccess.file_exists(json_path):
		return null
	var json_text := FileAccess.get_file_as_string(json_path)
	var data = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY:
		return null
	var rect: Rect2
	if data.has("regions"):
		var region: Dictionary = (data["regions"] as Dictionary).get(region_name, {})
		if region.is_empty():
			return null
		rect = Rect2(float(region.get("x", 0)), float(region.get("y", 0)), float(region.get("w", 0)), float(region.get("h", 0)))
	elif data.has("frames"):
		var frame_entry: Dictionary = (data["frames"] as Dictionary).get(region_name + ".png", {})
		var frame_rect: Dictionary = frame_entry.get("frame", {})
		if frame_rect.is_empty():
			return null
		rect = Rect2(float(frame_rect.get("x", 0)), float(frame_rect.get("y", 0)), float(frame_rect.get("w", 0)), float(frame_rect.get("h", 0)))
	else:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = base
	atlas.region = rect
	atlas.filter_clip = true
	return atlas

func _build_appearance_footer() -> void:
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
	row.add_theme_constant_override("separation", 16)
	frame.add_child(row)

	var back_button := _make_step_back_button("返回上一步", func():
		_capture_appearance()
		_show_step("education")
	)
	row.add_child(back_button)

	var info_cluster := HBoxContainer.new()
	info_cluster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_cluster.alignment = BoxContainer.ALIGNMENT_CENTER
	info_cluster.add_theme_constant_override("separation", 24)
	row.add_child(info_cluster)

	var progress_cluster := HBoxContainer.new()
	progress_cluster.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress_cluster.add_theme_constant_override("separation", 10)
	info_cluster.add_child(progress_cluster)
	var badge := Control.new()
	badge.custom_minimum_size = Vector2(32, 32)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress_cluster.add_child(badge)
	appearance_status_icon = TextureRect.new()
	appearance_status_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	appearance_status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	appearance_status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.add_child(appearance_status_icon)
	var progress_text := VBoxContainer.new()
	progress_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress_text.add_theme_constant_override("separation", 2)
	progress_cluster.add_child(progress_text)
	appearance_progress_label = Label.new()
	appearance_progress_label.modulate = AUI_COLOR_TEXT_INPUT
	appearance_progress_label.add_theme_font_size_override("font_size", 14)
	progress_text.add_child(appearance_progress_label)
	appearance_ratio_label = Label.new()
	appearance_ratio_label.modulate = AUI_COLOR_TEXT_MUTED
	appearance_ratio_label.add_theme_font_size_override("font_size", 12)
	progress_text.add_child(appearance_ratio_label)

	info_cluster.add_child(VSeparator.new())

	appearance_validation_label = Label.new()
	appearance_validation_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	appearance_validation_label.modulate = AUI_COLOR_TEXT_SECONDARY
	appearance_validation_label.add_theme_font_size_override("font_size", 14)
	info_cluster.add_child(appearance_validation_label)

	appearance_next_button = _make_step_next_button("下一步", func():
		_capture_appearance()
		_show_step("review")
	)
	row.add_child(appearance_next_button)

func _refresh_appearance_state() -> void:
	if appearance_next_button == null:
		return
	var completed := 0
	if not pending_skin_id.is_empty():
		completed += 1
	if not pending_hair_style_id.is_empty():
		completed += 1
	if not pending_hair_color_id.is_empty():
		completed += 1
	if not pending_suit_color_id.is_empty():
		completed += 1
	var valid := completed == 4
	appearance_progress_label.text = "本页必填完成度"
	appearance_ratio_label.text = "%d / 4" % completed
	appearance_status_icon.texture = IconStatusComplete if valid else IconStatusIncomplete
	appearance_validation_label.text = "资料校验状态：%s" % ("通过" if valid else "未完成")
	appearance_next_button.disabled = not valid
	_style_identity_next_button(appearance_next_button, 20)

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
	if not pending_skin_id.is_empty():
		profile.set("skin_preset", pending_skin_id)
	if not pending_hair_style_id.is_empty():
		profile.set("hair_preset", pending_hair_style_id)
	if not pending_hair_color_id.is_empty():
		profile.set("hair_color_preset", pending_hair_color_id)
	if not pending_suit_color_id.is_empty():
		profile.set("suit_marking_color", pending_suit_color_id)
	_save_profile()

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
