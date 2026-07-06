extends PanelContainer
class_name BaseStatusPanel

var _status_label: Label
var _hint_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(420, 300)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#06111a", 0.96)
	style.border_color = Color("#496c80", 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_top = 16
	style.content_margin_right = 18
	style.content_margin_bottom = 16
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	_status_label = Label.new()
	_status_label.modulate = Color("#cfe3f2")
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)
	_hint_label = Label.new()
	_hint_label.modulate = Color("#f0c766")
	_hint_label.add_theme_font_size_override("font_size", 14)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint_label)
	refresh()

func refresh() -> void:
	var manager := _base_status_manager()
	if _status_label == null:
		return
	if manager == null or not manager.has_method("panel_status_text"):
		_status_label.text = "基地状态数据不可用。"
		_hint_label.text = ""
		_hint_label.visible = false
		return
	_status_label.text = String(manager.call("panel_status_text"))
	var hint := ""
	if manager.has_method("get_specialist_hint"):
		hint = String(manager.call("get_specialist_hint"))
	_hint_label.text = hint
	_hint_label.visible = not hint.is_empty()

func _base_status_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BaseStatusManager")
