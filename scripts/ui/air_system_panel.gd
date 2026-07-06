extends PanelContainer

var _status_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(420, 300)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#031a1c", 0.96)
	style.border_color = Color("#3f8f8a", 0.9)
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
	_status_label.modulate = Color("#cdf2ea")
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)
	refresh()

func refresh() -> void:
	var manager := _air_system_manager()
	if _status_label == null:
		return
	if manager == null or not manager.has_method("panel_status_text"):
		_status_label.text = "空气系统数据不可用。"
		return
	_status_label.text = String(manager.call("panel_status_text"))

func _air_system_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("AirSystemManager")
