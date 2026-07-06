extends PanelContainer

## Uses RichTextLabel (not Label) because item names are wrapped in
## [color=...] BBCode by ItemDatabase.colored_display_name() for the item
## quality system — a plain Label would show the raw tags as text.
var _status_label: RichTextLabel

func _ready() -> void:
	custom_minimum_size = Vector2(330, 300)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#170a1e", 0.96)
	style.border_color = Color("#8a5fa8", 0.9)
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
	_status_label = RichTextLabel.new()
	_status_label.bbcode_enabled = true
	_status_label.fit_content = true
	_status_label.scroll_active = false
	_status_label.add_theme_color_override("default_color", Color("#eadcf2"))
	_status_label.add_theme_font_size_override("normal_font_size", 15)
	box.add_child(_status_label)
	refresh()

func refresh() -> void:
	var manager := _inventory_manager()
	if _status_label == null:
		return
	if manager == null or not manager.has_method("panel_status_text"):
		_status_label.text = "库存数据不可用。"
		return
	_status_label.text = String(manager.call("panel_status_text"))

func _inventory_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("InventoryManager")
