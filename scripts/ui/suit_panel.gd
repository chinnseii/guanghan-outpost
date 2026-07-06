extends PanelContainer

## Wide-and-short by design: the existing 3x2 panel grid (Water/Air/Base at
## y=180, Inventory/Power/Plant at y=500, each 300 tall) already fills the
## full 400-1590 x 180-800 HUD area on the 1600x900 viewport. The only
## remaining room is the y=800-900 strip, so this panel spans that strip
## horizontally instead of adding a 7th grid cell.
var _status_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(1170, 78)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1a1006", 0.96)
	style.border_color = Color("#a87f3f", 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_top = 10
	style.content_margin_right = 18
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_status_label = Label.new()
	_status_label.modulate = Color("#f2e6cf")
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)
	refresh()

func refresh() -> void:
	var manager := _suit_manager()
	if _status_label == null:
		return
	if manager == null or not manager.has_method("panel_status_text"):
		_status_label.text = "宇航服数据不可用。"
		return
	_status_label.text = String(manager.call("panel_status_text"))

func _suit_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SuitManager")
