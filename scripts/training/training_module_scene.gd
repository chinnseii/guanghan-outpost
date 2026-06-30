extends Control

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

class TrainingRoomBlockout:
	extends Control

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#07111b"), true)
		var room := Rect2(Vector2(24, 24), size - Vector2(48, 48))
		draw_rect(room, Color("#18232e"), true)
		for x in range(int(room.position.x), int(room.end.x), 48):
			draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), Color("#2f3f4c", 0.55), 1.0)
		for y in range(int(room.position.y), int(room.end.y), 48):
			draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color("#2f3f4c", 0.55), 1.0)
		draw_rect(room, Color("#5d6f7d"), false, 4.0)
		draw_rect(Rect2(room.position + Vector2(10, 10), room.size - Vector2(20, 20)), Color("#2a3844"), false, 2.0)
		draw_rect(Rect2(Vector2(room.position.x, room.position.y), Vector2(room.size.x, 26)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.position.x, room.end.y - 26), Vector2(room.size.x, 26)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.position.x, room.position.y), Vector2(26, room.size.y)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.end.x - 26, room.position.y), Vector2(26, room.size.y)), Color("#25313c"), true)
		for light_x in [150, size.x * 0.5, size.x - 210]:
			var light_rect := Rect2(Vector2(light_x, room.position.y + 14), Vector2(96, 8))
			draw_rect(light_rect, Color("#87d9ff", 0.45), true)
			draw_rect(light_rect.grow(4), Color("#87d9ff", 0.12), true)
		var panel_color := Color("#344653")
		draw_rect(Rect2(Vector2(room.position.x + 64, room.end.y - 72), Vector2(96, 34)), panel_color, true)
		draw_rect(Rect2(Vector2(room.end.x - 180, room.position.y + 72), Vector2(94, 42)), panel_color, true)
		draw_rect(Rect2(Vector2(room.end.x - 182, room.position.y + 74), Vector2(90, 6)), Color("#67b7e8", 0.55), true)

class TrainingTargetVisual:
	extends Control

	var kind := "marker"
	var label_text := ""
	var active := false
	var highlighted := false
	var locked := false
	var show_trigger_debug := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		match kind:
			"marker":
				_draw_marker()
			"terminal":
				_draw_terminal()
			"exit":
				_draw_exit()
			_:
				_draw_generic()
		_draw_debug_label()

	func _draw_marker() -> void:
		var c := Color("#f0c766") if highlighted else Color("#4fb7f0")
		var fill_alpha := 0.28 if highlighted else 0.12
		draw_rect(Rect2(Vector2.ZERO, size), Color("#12324a", fill_alpha), true)
		if show_trigger_debug:
			draw_rect(Rect2(Vector2.ZERO, size), Color("#f0c766", 0.08), true)
			draw_rect(Rect2(Vector2.ZERO, size), Color("#f0c766", 0.9), false, 1.0)
		for x in range(0, int(size.x), 14):
			draw_line(Vector2(x, 0), Vector2(min(x + 7, size.x), 0), c, 2.0)
			draw_line(Vector2(x, size.y), Vector2(min(x + 7, size.x), size.y), c, 2.0)
		for y in range(0, int(size.y), 14):
			draw_line(Vector2(0, y), Vector2(0, min(y + 7, size.y)), c, 2.0)
			draw_line(Vector2(size.x, y), Vector2(size.x, min(y + 7, size.y)), c, 2.0)
		draw_arc(size * 0.5, 22.0, 0.0, TAU, 32, Color("#8fd8ff", 0.8), 2.0)
		draw_line(size * 0.5 + Vector2(-16, 0), size * 0.5 + Vector2(16, 0), Color("#8fd8ff", 0.7), 1.0)
		draw_line(size * 0.5 + Vector2(0, -16), size * 0.5 + Vector2(0, 16), Color("#8fd8ff", 0.7), 1.0)

	func _draw_terminal() -> void:
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.12), true)
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.55), false, 2.0)
		draw_rect(Rect2(Vector2(12, 30), Vector2(size.x - 24, size.y - 38)), Color("#2c3740"), true)
		draw_rect(Rect2(Vector2(22, 8), Vector2(size.x - 44, 36)), Color("#1a2b38"), true)
		draw_rect(Rect2(Vector2(28, 14), Vector2(size.x - 56, 22)), Color("#236fa8"), true)
		draw_rect(Rect2(Vector2(34, 19), Vector2(size.x - 68, 3)), Color("#89d8ff", 0.8), true)
		draw_rect(Rect2(Vector2(34, 27), Vector2(size.x - 82, 3)), Color("#89d8ff", 0.55), true)
		draw_rect(Rect2(Vector2(30, 54), Vector2(18, 10)), Color("#f0c766"), true)
		draw_rect(Rect2(Vector2(56, 54), Vector2(18, 10)), Color("#6fa7c8"), true)
		draw_rect(Rect2(Vector2(82, 54), Vector2(18, 10)), Color("#8fa3b2"), true)

	func _draw_exit() -> void:
		var edge := Color("#f0c766", 0.7) if highlighted and not locked else Color("#89d8ff", 0.28)
		draw_rect(Rect2(Vector2(14, 0), Vector2(size.x - 28, size.y)), Color("#34414c"), true)
		draw_rect(Rect2(Vector2(24, 10), Vector2(size.x - 48, size.y - 20)), Color("#1d2832"), true)
		draw_line(Vector2(size.x * 0.5, 12), Vector2(size.x * 0.5, size.y - 12), Color("#d8e7f2", 0.55), 2.0)
		draw_rect(Rect2(Vector2(4, 18), Vector2(10, size.y - 36)), edge, true)
		draw_rect(Rect2(Vector2(size.x - 14, 18), Vector2(10, size.y - 36)), edge, true)
		draw_rect(Rect2(Vector2(28, size.y - 20), Vector2(size.x - 56, 4)), Color("#f0c766", 0.55 if highlighted and not locked else 0.18), true)
		if locked:
			draw_string(ThemeDB.fallback_font, Vector2(28, size.y * 0.5), "LOCK", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8fa3b2"))

	func _draw_generic() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#2a3a45"), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color("#6f8493"), false, 2.0)

	func _draw_debug_label() -> void:
		if label_text.is_empty():
			return
		var font := ThemeDB.fallback_font
		var font_size := 13
		draw_string(font, Vector2(8, -6), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#d8e7f2"))
		if active:
			draw_string(font, Vector2(8, size.y + 18), "E 交互", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#f0c766"))

class TraineeVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center + Vector2(0, -12), 10, Color("#e6eef4"))
		draw_circle(center + Vector2(0, -12), 7, Color("#1b2834"))
		draw_rect(Rect2(center + Vector2(-9, -3), Vector2(18, 23)), Color("#d8e0e6"), true)
		draw_rect(Rect2(center + Vector2(-6, 3), Vector2(12, 8)), Color("#7fa7bd"), true)
		draw_line(center + Vector2(-11, 1), center + Vector2(-18, 17), Color("#d8e0e6"), 4.0)
		draw_line(center + Vector2(11, 1), center + Vector2(18, 17), Color("#d8e0e6"), 4.0)
		draw_line(center + Vector2(-5, 20), center + Vector2(-8, 32), Color("#d8e0e6"), 4.0)
		draw_line(center + Vector2(5, 20), center + Vector2(8, 32), Color("#d8e0e6"), 4.0)
		draw_rect(Rect2(center + Vector2(-15, 4), Vector2(5, 12)), Color("#9aa8b4"), true)

@export var module_id := "suit_control"

var module_data: Dictionary = {}
var step_index := 0
var player: Control
var training_area: Control
var objective_label: Label
var hud_label: Label
var hint_label: Label
var log_label: Label
var diagnosis_panel: VBoxContainer
var target_nodes: Dictionary = {}
var prompt_label: Label
var completed := false
var show_trigger_debug := false
var player_speed := 280.0

func _ready() -> void:
	_ensure_input_actions()
	module_data = _module_config(module_id)
	TrainingManagerScript.set_current_module(module_id)
	_build_screen()
	_update_hud()

func _process(delta: float) -> void:
	_move_player(delta)
	if not completed:
		_check_auto_steps()
	_update_room_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not completed:
		_try_interact()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		show_trigger_debug = not show_trigger_debug
		_update_trigger_debug()
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _ensure_input_actions() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E
		InputMap.action_add_event("interact", event)

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("#06101a")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 36
	root.offset_top = 24
	root.offset_right = -36
	root.offset_bottom = -32
	root.add_theme_constant_override("separation", 10)
	add_child(root)

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

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(420, 0)
	row.add_child(left_panel)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	left_panel.add_child(left)

	var title := Label.new()
	title.text = String(module_data.get("title", "训练模块"))
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 24)
	left.add_child(title)

	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.modulate = Color("#d8e7f2")
	objective_label.add_theme_font_size_override("font_size", 18)
	left.add_child(objective_label)

	hud_label = Label.new()
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_label.modulate = Color("#9fb4c4")
	hud_label.add_theme_font_size_override("font_size", 15)
	left.add_child(hud_label)

	hint_label = Label.new()
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.modulate = Color("#86c7ff")
	hint_label.add_theme_font_size_override("font_size", 16)
	left.add_child(hint_label)

	diagnosis_panel = VBoxContainer.new()
	diagnosis_panel.visible = false
	diagnosis_panel.add_theme_constant_override("separation", 8)
	left.add_child(diagnosis_panel)

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
	_build_training_area()

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.custom_minimum_size = Vector2(0, 48)
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	_add_button(footer, "保存训练进度", func(): TrainingManagerScript.set_current_module(module_id))
	_add_button(footer, "返回主菜单", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))

func _build_training_area() -> void:
	target_nodes.clear()
	var floor: Control
	if module_id == "suit_control":
		floor = TrainingRoomBlockout.new()
	else:
		var flat_floor := ColorRect.new()
		flat_floor.color = Color("#0b1721")
		floor = flat_floor
	floor.set_anchors_preset(Control.PRESET_FULL_RECT)
	training_area.add_child(floor)

	for target: Dictionary in module_data.get("targets", []):
		if module_id == "suit_control":
			target = _suit_room_target(target)
		var node: Control
		if module_id == "suit_control":
			var visual := TrainingTargetVisual.new()
			visual.kind = String(target.get("kind", target.get("id", "target")))
			visual.label_text = String(target.get("label", ""))
			node = visual
		else:
			var block := ColorRect.new()
			block.color = target.get("color", Color("#23455f"))
			node = block
		node.name = String(target.get("id", "target"))
		node.position = target.get("position", Vector2(100, 100))
		node.size = target.get("size", Vector2(108, 70))
		training_area.add_child(node)
		target_nodes[node.name] = node
		if module_id != "suit_control":
			var label := Label.new()
			label.text = String(target.get("label", node.name))
			label.position = Vector2(8, 8)
			label.modulate = Color("#eaf4ff")
			label.add_theme_font_size_override("font_size", 13)
			node.add_child(label)

	if module_id == "suit_control":
		player = TraineeVisual.new()
	else:
		var player_block := ColorRect.new()
		player_block.color = Color("#d8e7f2")
		player = player_block
	player.name = "Candidate"
	player.position = module_data.get("player_start", Vector2(62, 420))
	player.size = module_data.get("player_size", Vector2(26, 34))
	training_area.add_child(player)

	prompt_label = Label.new()
	prompt_label.modulate = Color("#f0c766")
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.visible = false
	training_area.add_child(prompt_label)

func _suit_room_target(target: Dictionary) -> Dictionary:
	var id := String(target.get("id", ""))
	var room_target := target.duplicate()
	match id:
		"marker":
			room_target["kind"] = "marker"
			room_target["label"] = "标记区域"
			room_target["position"] = Vector2(146, 340)
			room_target["size"] = Vector2(112, 92)
		"terminal":
			room_target["kind"] = "terminal"
			room_target["label"] = "训练终端"
			room_target["position"] = Vector2(330, 92)
			room_target["size"] = Vector2(118, 88)
		"exit":
			room_target["kind"] = "exit"
			room_target["label"] = "训练出口"
			room_target["position"] = Vector2(660, 270)
			room_target["size"] = Vector2(96, 150)
	return room_target

func _move_player(delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	if direction.length() > 1.0:
		direction = direction.normalized()
	player.position += direction * player_speed * delta
	var margin := 36.0 if module_id == "suit_control" else 8.0
	player.position.x = clamp(player.position.x, margin, max(margin, training_area.size.x - player.size.x - margin))
	player.position.y = clamp(player.position.y, margin, max(margin, training_area.size.y - player.size.y - margin))

func _check_auto_steps() -> void:
	var step := _current_step()
	if step.is_empty() or String(step.get("type", "")) != "move":
		return
	if _is_inside_target_area(String(step.get("target", ""))):
		_complete_step()

func _try_interact() -> void:
	var step := _current_step()
	if step.is_empty():
		return
	var step_type := String(step.get("type", "interact"))
	if step_type == "diagnosis":
		hint_label.text = "请在左侧选择诊断结果。"
		return
	var target := String(step.get("target", ""))
	if not _is_near(target):
		hint_label.text = "请先移动至目标区域。"
		return
	if _blocked_by_order(step):
		hint_label.text = String(step.get("blocked_hint", "流程顺序错误。请按当前目标执行。"))
		return
	_complete_step()

func _current_step() -> Dictionary:
	var steps: Array = module_data.get("steps", [])
	if step_index >= steps.size():
		return {}
	return steps[step_index]

func _complete_step() -> void:
	var step := _current_step()
	if step.is_empty():
		return
	if step.has("state_key"):
		module_data["state"][String(step["state_key"])] = step.get("state_value", true)
	_add_log(String(step.get("line", "")))
	step_index += 1
	if String(step.get("type", "")) == "diagnosis":
		diagnosis_panel.visible = false
	if step_index >= (module_data.get("steps", []) as Array).size():
		_finish_module()
	else:
		_update_hud()

func _finish_module() -> void:
	completed = true
	var next_module := String(module_data.get("next_module", "mission_assignment"))
	TrainingManagerScript.mark_module_completed(module_id, next_module)
	if module_id == "suit_control":
		get_tree().change_scene_to_file(String(module_data.get("next_scene", TrainingManagerScript.START_SCENE)))
		return
	hint_label.text = "模块完成。"
	_update_hud()
	var button := Button.new()
	button.text = String(module_data.get("next_button", "进入下一阶段"))
	button.custom_minimum_size = Vector2(0, 42)
	button.pressed.connect(func():
		get_tree().change_scene_to_file(String(module_data.get("next_scene", TrainingManagerScript.START_SCENE)))
	)
	diagnosis_panel.visible = true
	diagnosis_panel.add_child(button)

func _blocked_by_order(step: Dictionary) -> bool:
	var requires: Dictionary = step.get("requires", {})
	var state: Dictionary = module_data.get("state", {})
	for key in requires.keys():
		if state.get(key, null) != requires[key]:
			return true
	return false

func _is_near(target_id: String) -> bool:
	if not target_nodes.has(target_id):
		return false
	var target: Control = target_nodes[target_id]
	var player_center := player.position + player.size * 0.5
	var target_center := target.position + target.size * 0.5
	return player_center.distance_to(target_center) <= 95.0

func _is_inside_target_area(target_id: String) -> bool:
	if not target_nodes.has(target_id):
		return false
	var target: Control = target_nodes[target_id]
	var target_rect := Rect2(target.position, target.size)
	var player_feet := player.position + Vector2(player.size.x * 0.5, player.size.y)
	return target_rect.has_point(player_feet)

func _update_trigger_debug() -> void:
	for node in target_nodes.values():
		if node is TrainingTargetVisual:
			node.show_trigger_debug = show_trigger_debug and node.kind == "marker"
			node.queue_redraw()

func _update_room_prompt() -> void:
	if prompt_label == null:
		return
	var step := _current_step()
	var target_id := String(step.get("target", "")) if not step.is_empty() else ""
	for node in target_nodes.values():
		if node is TrainingTargetVisual:
			node.highlighted = node.name == target_id
			node.active = false
			node.locked = node.name == "exit" and target_id != "exit"
			node.modulate = Color(1, 1, 1, 1) if node.highlighted else Color(0.72, 0.78, 0.84, 0.72)
			node.show_trigger_debug = show_trigger_debug and node.kind == "marker"
			node.queue_redraw()
	if completed or step.is_empty():
		prompt_label.visible = false
		return
	if not target_nodes.has(target_id):
		prompt_label.visible = false
		return
	var target: Control = target_nodes[target_id]
	var near := _is_near(target_id)
	if target is TrainingTargetVisual:
		target.active = near and String(step.get("type", "")) == "interact"
		target.queue_redraw()
	if near and String(step.get("type", "")) == "interact":
		prompt_label.text = "E 使用训练终端" if target_id == "terminal" else "E 交互"
		prompt_label.position = target.position + Vector2(8, target.size.y + 20)
		prompt_label.visible = true
	else:
		prompt_label.visible = false

func _show_diagnosis_options(options: Array, correct: String) -> void:
	diagnosis_panel.visible = true
	_clear_container(diagnosis_panel)
	for option in options:
		var button := Button.new()
		button.text = String(option)
		button.custom_minimum_size = Vector2(0, 38)
		button.pressed.connect(func():
			if button.text == correct:
				_complete_step()
			else:
				hint_label.text = "诊断结论不足。请重新核对观察信息。"
		)
		diagnosis_panel.add_child(button)

func _update_hud() -> void:
	var step := _current_step()
	var objective := String(step.get("objective", "训练流程已完成。")) if not completed else "训练流程已完成。"
	objective_label.text = "当前目标：%s" % objective
	hud_label.text = String(module_data.get("hud", "氧气模拟值：98%\n电力模拟值：稳定\n生命支持状态：训练环境"))
	if module_id == "suit_control" and not completed:
		hint_label.text = _suit_control_hint(step)
	else:
		hint_label.text = String(step.get("hint", "移动至目标区域，按 E 交互。")) if not completed else "训练记录已保存。"
	if String(step.get("type", "")) == "diagnosis":
		_show_diagnosis_options(step.get("options", []), String(step.get("correct", "")))

func _suit_control_hint(step: Dictionary) -> String:
	match String(step.get("target", "")):
		"marker":
			return "请移动至蓝色标记区域。"
		"terminal":
			return "请靠近训练终端并按 E。"
		"exit":
			return "训练记录完成。请前往训练出口并按 E。"
	return "请按当前目标执行训练流程。"

func _add_log(line: String) -> void:
	if line.is_empty():
		return
	log_label.text += line + "\n"

func _add_header_label(parent: HBoxContainer, text: String, min_size: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = min_size
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func _add_button(parent: HBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(190, 42)
	button.pressed.connect(callback)
	parent.add_child(button)

func _clear_container(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _module_config(id: String) -> Dictionary:
	match id:
		"suit_control":
			return _suit_control_config()
		"airlock_procedure":
			return _airlock_config()
		"power_repair":
			return _power_config()
		"life_support":
			return _life_support_config()
		"plant_diagnosis":
			return _plant_config()
		"final_assessment":
			return _assessment_config()
	return _suit_control_config()

func _base_config() -> Dictionary:
	return {
		"state": {},
		"player_start": Vector2(62, 420),
		"hud": "氧气模拟值：98%\n电力模拟值：稳定\n生命支持状态：训练环境\n提示信息：靠近目标后按 E。",
	}

func _suit_control_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块一：宇航服基础控制",
		"subtitle": "SUIT CONTROL",
		"next_module": "airlock_procedure",
		"next_scene": TrainingManagerScript.MODULE_02,
		"player_start": Vector2(420, 310),
		"player_size": Vector2(42, 54),
		"targets": [
			{"id": "marker", "label": "标记区域", "position": Vector2(150, 330), "color": Color("#244563")},
			{"id": "terminal", "label": "训练终端", "position": Vector2(440, 180), "color": Color("#31536f")},
			{"id": "exit", "label": "训练出口", "position": Vector2(690, 390), "color": Color("#274f43")},
		],
		"steps": [
			{"type": "move", "target": "marker", "objective": "移动至标记区域", "line": "请移动至标记区域。"},
			{"type": "interact", "target": "terminal", "objective": "与训练终端交互", "line": "请与训练终端交互。"},
			{"type": "interact", "target": "terminal", "objective": "查看宇航服状态", "line": "正在读取宇航服状态。\n状态稳定。"},
			{"type": "interact", "target": "exit", "objective": "返回训练出口", "line": "模块完成。"},
		],
	})
	return data

func _airlock_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块二：气闸流程",
		"subtitle": "AIRLOCK PROCEDURE",
		"next_module": "power_repair",
		"next_scene": TrainingManagerScript.MODULE_03,
		"targets": [
			{"id": "chamber", "label": "气闸室", "position": Vector2(210, 250), "color": Color("#223d52")},
			{"id": "inner_door", "label": "内舱门", "position": Vector2(80, 250), "color": Color("#3d4e62")},
			{"id": "console", "label": "舱压控制台", "position": Vector2(410, 150), "color": Color("#31536f")},
			{"id": "outer_door", "label": "外舱门", "position": Vector2(610, 250), "color": Color("#3d4e62")},
			{"id": "exit", "label": "流程出口", "position": Vector2(710, 410), "color": Color("#274f43")},
		],
		"steps": [
			{"type": "move", "target": "chamber", "objective": "进入气闸室", "line": "进入气闸室。"},
			{"type": "interact", "target": "inner_door", "objective": "关闭内舱门", "line": "关闭内舱门。", "state_key": "InnerDoorClosed"},
			{"type": "interact", "target": "console", "objective": "启动舱压模拟", "line": "舱压模拟开始。\n舱压稳定。", "state_key": "PressureStable", "requires": {"InnerDoorClosed": true}},
			{"type": "interact", "target": "outer_door", "objective": "打开外舱门", "line": "外舱门已解锁。", "state_key": "OuterDoorUnlocked", "requires": {"InnerDoorClosed": true, "PressureStable": true}, "blocked_hint": "流程顺序错误。请先关闭内舱门并等待舱压稳定。"},
			{"type": "interact", "target": "exit", "objective": "退出气闸", "line": "流程完成。"},
		],
	})
	return data

func _power_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块三：供电维修",
		"subtitle": "POWER REPAIR",
		"next_module": "life_support",
		"next_scene": TrainingManagerScript.MODULE_04,
		"hud": "氧气模拟值：97%\n电力模拟值：下降\n生命支持状态：待供电恢复\n提示信息：先取得工具。",
		"targets": [
			{"id": "tools", "label": "工具台", "position": Vector2(110, 350), "color": Color("#4b4f37")},
			{"id": "panel", "label": "故障供电面板", "position": Vector2(390, 170), "color": Color("#5b3c3c")},
			{"id": "console", "label": "供电控制台", "position": Vector2(620, 220), "color": Color("#31536f")},
			{"id": "light", "label": "测试灯", "position": Vector2(660, 410), "color": Color("#413f31")},
		],
		"steps": [
			{"type": "interact", "target": "tools", "objective": "从工具台取用维修工具", "line": "请从工具台取用维修工具。", "state_key": "HasTool"},
			{"type": "interact", "target": "panel", "objective": "检查损坏的供电面板", "line": "检测到供电面板故障。", "requires": {"HasTool": true}, "blocked_hint": "没有维修工具。请先从工具台取用。"},
			{"type": "interact", "target": "panel", "objective": "执行维修交互", "line": "开始维修。\n维修完成。", "state_key": "PowerPanelRepaired", "requires": {"HasTool": true}},
			{"type": "interact", "target": "console", "objective": "在控制台重启供电", "line": "请重启供电。\n供电恢复。", "state_key": "PowerRestored", "requires": {"PowerPanelRepaired": true}},
			{"type": "interact", "target": "light", "objective": "观察测试灯亮起", "line": "测试灯开启。模块完成。", "requires": {"PowerRestored": true}},
		],
	})
	return data

func _life_support_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块四：生命支持系统",
		"subtitle": "LIFE SUPPORT",
		"next_module": "plant_diagnosis",
		"next_scene": TrainingManagerScript.MODULE_05,
		"hud": "氧气状态：偏低\n水循环：稳定\n供电状态：已恢复\n温度状态：偏低",
		"targets": [
			{"id": "console", "label": "生命支持控制台", "position": Vector2(340, 180), "color": Color("#31536f")},
			{"id": "oxygen", "label": "氧气显示", "position": Vector2(130, 130), "color": Color("#244563")},
			{"id": "water", "label": "水循环显示", "position": Vector2(130, 260), "color": Color("#244563")},
			{"id": "temperature", "label": "温度显示", "position": Vector2(560, 130), "color": Color("#244563")},
			{"id": "power", "label": "电力显示", "position": Vector2(560, 260), "color": Color("#244563")},
		],
		"steps": [
			{"type": "interact", "target": "console", "objective": "打开生命支持控制台", "line": "生命支持不是单一设备。\n氧气、水、电力与温度必须同时稳定。"},
			{"type": "interact", "target": "oxygen", "objective": "查看氧气状态", "line": "检测到氧气偏低。"},
			{"type": "interact", "target": "temperature", "objective": "查看温度状态", "line": "检测到温度偏低。"},
			{"type": "interact", "target": "console", "objective": "启动稳定程序", "line": "启动稳定程序。\n生命支持状态：稳定。", "state_key": "LifeSupportStable"},
			{"type": "interact", "target": "power", "objective": "确认电力状态", "line": "电力状态稳定。模块完成。", "requires": {"LifeSupportStable": true}},
		],
	})
	return data

func _plant_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块五：植物状态诊断",
		"subtitle": "PLANT DIAGNOSIS",
		"next_module": "final_assessment",
		"next_scene": TrainingManagerScript.FINAL_ASSESSMENT,
		"hud": "植物状态：Warning\n扫描器：待使用\n生长灯：输出不足\n提示信息：观察，再诊断。",
		"targets": [
			{"id": "plant", "label": "训练植物", "position": Vector2(350, 260), "color": Color("#2d5b3f")},
			{"id": "scanner", "label": "植物扫描器", "position": Vector2(160, 350), "color": Color("#31536f")},
			{"id": "grow_light", "label": "生长灯", "position": Vector2(570, 130), "color": Color("#4b4f37")},
		],
		"steps": [
			{"type": "interact", "target": "plant", "objective": "观察训练植物", "line": "植物不会主动报警。\n你需要学会观察。"},
			{"type": "interact", "target": "scanner", "objective": "使用扫描器读取状态", "line": "叶片颜色偏浅。\n生长灯输出不足。"},
			{"type": "diagnosis", "objective": "选择诊断结果", "line": "诊断结论：光照不足。", "options": ["缺水", "光照不足", "根区温度异常"], "correct": "光照不足"},
			{"type": "interact", "target": "grow_light", "objective": "调整补光方案", "line": "请调整补光方案。\n植物状态趋于稳定。", "state_key": "PlantStable"},
			{"type": "interact", "target": "plant", "objective": "确认植物状态稳定", "line": "植物状态：Stable。模块完成。", "requires": {"PlantStable": true}},
		],
	})
	return data

func _assessment_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "最终考核：综合模拟事故",
		"subtitle": "FINAL ASSESSMENT",
		"next_module": "mission_assignment",
		"next_scene": TrainingManagerScript.MISSION_NOTICE,
		"next_button": "查看任务派遣通知",
		"hud": "模拟事故开始。\n供电下降。\n生命支持不稳定。\n植物舱状态异常。",
		"targets": [
			{"id": "tools", "label": "工具台", "position": Vector2(90, 360), "color": Color("#4b4f37")},
			{"id": "panel", "label": "供电面板", "position": Vector2(290, 180), "color": Color("#5b3c3c")},
			{"id": "power_console", "label": "供电控制台", "position": Vector2(520, 170), "color": Color("#31536f")},
			{"id": "life_console", "label": "生命支持控制台", "position": Vector2(570, 330), "color": Color("#31536f")},
			{"id": "plant", "label": "植物舱", "position": Vector2(300, 360), "color": Color("#2d5b3f")},
			{"id": "terminal", "label": "考核终端", "position": Vector2(700, 420), "color": Color("#274f43")},
		],
		"steps": [
			{"type": "interact", "target": "tools", "objective": "从工具台取得维修工具", "line": "已取得维修工具。", "state_key": "HasTool"},
			{"type": "interact", "target": "panel", "objective": "修复供电面板", "line": "供电面板维修完成。", "state_key": "PowerPanelRepaired", "requires": {"HasTool": true}, "blocked_hint": "流程不完整。请先取得维修工具。"},
			{"type": "interact", "target": "power_console", "objective": "重启供电", "line": "供电恢复。", "state_key": "PowerRestored", "requires": {"PowerPanelRepaired": true}},
			{"type": "interact", "target": "life_console", "objective": "打开生命支持控制台", "line": "生命支持控制台已打开。", "requires": {"PowerRestored": true}, "blocked_hint": "生命支持稳定通常依赖供电状态。"},
			{"type": "interact", "target": "life_console", "objective": "启动稳定程序", "line": "生命支持稳定。", "state_key": "LifeSupportStable", "requires": {"PowerRestored": true}},
			{"type": "interact", "target": "plant", "objective": "扫描植物舱", "line": "植物舱状态异常。叶片颜色偏浅。"},
			{"type": "diagnosis", "objective": "判断植物异常", "line": "诊断结论：光照不足。", "options": ["缺水", "光照不足", "根区温度异常"], "correct": "光照不足"},
			{"type": "interact", "target": "plant", "objective": "调整补光方案", "line": "植物舱状态稳定。", "state_key": "PlantStable"},
			{"type": "interact", "target": "terminal", "objective": "返回考核终端提交结果", "line": "最终考核完成。\n\n供电恢复。\n生命支持稳定。\n植物舱状态稳定。\n\n候选人具备进入月面长期驻留任务训练后阶段的基础资格。", "requires": {"PowerRestored": true, "LifeSupportStable": true, "PlantStable": true}, "blocked_hint": "流程不完整。请检查供电、生命支持与植物舱状态。"},
		],
	})
	return data
