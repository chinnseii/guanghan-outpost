extends Control

const PROFILE_PATH := "user://saves/application_profile.json"
const PlayerProfileDataScript := preload("res://scripts/data/player_profile_data.gd")

const EDUCATION_DESCRIPTIONS := {
	"Plant Science": "Better prepared to notice abnormal leaves, nutrient deficiency, and root-system issues.",
	"Agricultural Engineering": "Better prepared to read greenhouse equipment, water loops, and cultivation-system state.",
	"Mechanical Engineering": "Better prepared to reason about equipment damage, repair risk, and structural faults.",
	"Life Support Engineering": "Better prepared to understand oxygen, water, power, and temperature relationships.",
	"Materials Science": "Better prepared to identify structural aging, seal wear, and radiation damage.",
	"Medicine": "Better prepared to notice health risks in yourself or future residents.",
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
	background.color = Color("#e8ebed")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var root := VBoxContainer.new()
	root.name = "ApplicationShell"
	root.position = Vector2(150, 58)
	root.size = Vector2(1300, 790)
	root.add_theme_constant_override("separation", 18)
	add_child(root)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	root.add_child(header)
	var agency := Label.new()
	agency.text = "国家深空生命科学中心\nNATIONAL DEEP SPACE LIFE SCIENCE CENTER"
	agency.modulate = Color("#25313a")
	agency.add_theme_font_size_override("font_size", 18)
	header.add_child(agency)
	var title := Label.new()
	title.text = "广寒计划\nPROJECT GUANGHAN"
	title.modulate = Color("#111820")
	title.add_theme_font_size_override("font_size", 36)
	header.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "常驻开拓者申请系统\nPERMANENT PIONEER APPLICATION SYSTEM"
	subtitle.modulate = Color("#4a5862")
	subtitle.add_theme_font_size_override("font_size", 17)
	header.add_child(subtitle)
	var line := HSeparator.new()
	root.add_child(line)
	content = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	root.add_child(content)
	footer = HBoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override("separation", 10)
	root.add_child(footer)

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
	_add_section_title("Basic Identity")
	_add_body("This file records only application identity. It does not create RPG attributes or profession bonuses.")
	name_edit = _add_line_edit("Name", String(profile.get("player_name")))
	birth_spin = SpinBox.new()
	birth_spin.min_value = 1960
	birth_spin.max_value = 2030
	birth_spin.value = int(profile.get("birth_year"))
	_add_field("Birth year", birth_spin)
	gender_options = _add_options("Gender display", ["Male", "Female", "Do not display", "Custom"], String(profile.get("gender_display")))
	_add_footer_button("Back to Main Menu", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_add_footer_button("Next", func():
		_capture_identity()
		if String(profile.get("player_name")).strip_edges().is_empty():
			_add_body("Name is required before the application can continue.")
			return
		_show_step("education")
	)

func _show_education() -> void:
	_add_section_title("Education Background")
	_add_body("Choose one background. This is information visibility and future diagnostic context, not a numerical buff.")
	education_options = _add_options("Education background", EDUCATION_DESCRIPTIONS.keys(), String(profile.get("education_background")))
	education_options.item_selected.connect(func(_index: int):
		_update_education_description()
	)
	education_description = Label.new()
	education_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	education_description.modulate = Color("#2f3b43")
	education_description.add_theme_font_size_override("font_size", 18)
	content.add_child(education_description)
	_update_education_description()
	_add_footer_button("Back", func():
		_capture_education()
		_show_step("identity")
	)
	_add_footer_button("Next", func():
		_capture_education()
		_show_step("appearance")
	)

func _show_appearance() -> void:
	_add_section_title("Appearance Placeholder")
	_add_body("Most of the mission is conducted in a suit. This page records simple presets only.")
	appearance_options.clear()
	appearance_options["appearance_preset"] = _add_options("Body preset", ["Standard", "Compact", "Tall"], String(profile.get("appearance_preset")))
	appearance_options["skin_preset"] = _add_options("Skin preset", ["Preset A", "Preset B", "Preset C", "Preset D"], String(profile.get("skin_preset")))
	appearance_options["hair_preset"] = _add_options("Hair preset", ["Short", "Tied", "Cropped", "Covered"], String(profile.get("hair_preset")))
	appearance_options["hair_color_preset"] = _add_options("Hair color", ["Black", "Brown", "Dark brown", "Grey"], String(profile.get("hair_color_preset")))
	appearance_options["suit_marking_color"] = _add_options("Suit marking color", ["Blue", "White", "Amber", "Red"], String(profile.get("suit_marking_color")))
	suit_marking_edit = _add_line_edit("Arm patch / name initials", String(profile.get("suit_marking")))
	_add_footer_button("Back", func():
		_capture_appearance()
		_show_step("education")
	)
	_add_footer_button("Review Application", func():
		_capture_appearance()
		_show_step("review")
	)

func _show_review() -> void:
	_add_section_title("Submit Application")
	_add_body("你即将提交广寒计划常驻开拓者申请。\n\n一旦通过审核，你将进入国家深空生命科学中心训练序列。\n\n训练完成后，你可能被派往月球广寒前哨，执行长期驻留任务。")
	_add_body(_profile_summary())
	_add_footer_button("Return to Edit", func(): _show_step("identity"))
	_add_footer_button("Submit Application", func():
		_start_review_sequence()
	)

func _start_review_sequence() -> void:
	profile.set("application_submitted", true)
	profile.set("current_application_step", "review")
	_save_profile()
	_clear_container(content)
	_clear_container(footer)
	_add_section_title("Application Review")
	status_label = Label.new()
	status_label.text = "申请已提交"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	_add_footer_button("Continue", func(): _show_step("choice"))

func _show_choice() -> void:
	_add_section_title("Final Choice")
	_add_body("The application has been approved. The mission still requires your explicit acceptance.")
	_add_footer_button("Withdraw Application", func():
		profile.set("application_accepted", false)
		profile.set("current_application_step", "withdrawn")
		_save_profile()
		_show_step("withdrawn")
	)
	_add_footer_button("Accept Mission", func():
		profile.set("application_accepted", true)
		profile.set("current_application_step", "accepted")
		_save_profile()
		get_tree().change_scene_to_file("res://scenes/application/BlackScreenSequence.tscn")
	)

func _show_withdrawn() -> void:
	_add_section_title("Application Withdrawn")
	_add_body("申请已撤回。\n\n广寒计划仍将继续等待下一位开拓者。")
	_add_footer_button("Return to Main Menu", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))

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
	return "Name: %s\nBirth year: %d\nGender display: %s\nEducation: %s\nSuit marking: %s / %s" % [
		String(profile.get("player_name")),
		int(profile.get("birth_year")),
		String(profile.get("gender_display")),
		String(profile.get("education_background")),
		String(profile.get("suit_marking")),
		String(profile.get("suit_marking_color")),
	]

func _add_section_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color("#111820")
	label.add_theme_font_size_override("font_size", 28)
	content.add_child(label)

func _add_body(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color("#2f3b43")
	label.add_theme_font_size_override("font_size", 18)
	content.add_child(label)

func _add_field(label_text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(220, 36)
	label.add_theme_font_size_override("font_size", 17)
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
