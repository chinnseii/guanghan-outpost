extends PanelContainer

## RichTextLabel (not Label): item names come back wrapped in [color=...]
## BBCode from the item quality system (ItemDatabase.colored_display_name()
## via ItemContainer.slot_label()) — a plain Label would show raw tags.
var _status_label: RichTextLabel

func _ready() -> void:
	custom_minimum_size = Vector2(520, 430)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#07111a", 0.97)
	style.border_color = Color("#6f8493", 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16
	style.content_margin_top = 14
	style.content_margin_right = 16
	style.content_margin_bottom = 14
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title := Label.new()
	title.text = "背包 / 仓库"
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)
	_status_label = RichTextLabel.new()
	_status_label.bbcode_enabled = true
	_status_label.fit_content = true
	_status_label.scroll_active = false
	_status_label.add_theme_color_override("default_color", Color("#c8d8e2"))
	_status_label.add_theme_font_size_override("normal_font_size", 14)
	_status_label.custom_minimum_size = Vector2(0, 250)
	box.add_child(_status_label)
	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 8)
	buttons.add_theme_constant_override("v_separation", 8)
	box.add_child(buttons)
	_add_button(buttons, "整理背包", _sort_backpack)
	_add_button(buttons, "整理仓库", _sort_storage)
	_add_button(buttons, "全部存入仓库", _deposit_all)
	_add_button(buttons, "月球冰入水系统", _deposit_ice)
	_add_button(buttons, "吃背包食物", _eat_backpack_food)
	_add_button(buttons, "吃仓库食物", _eat_storage_food)
	refresh()

func refresh() -> void:
	if _status_label == null:
		return
	var lines: Array[String] = []
	var backpack := _backpack_manager()
	var storage := _storage_manager()
	if backpack == null or not backpack.has_method("panel_status_text"):
		lines.append("背包数据不可用。")
	else:
		lines.append(String(backpack.call("panel_status_text")))
	if storage == null or not storage.has_method("panel_status_text"):
		lines.append("")
		lines.append("仓库数据不可用。")
	else:
		lines.append("")
		lines.append(String(storage.call("panel_status_text")))
	_status_label.text = "\n".join(lines)

func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 34)
	button.pressed.connect(callback)
	parent.add_child(button)

func _sort_backpack() -> void:
	var manager := _backpack_manager()
	if manager != null and manager.has_method("sort_inventory"):
		manager.call("sort_inventory")
	refresh()

func _sort_storage() -> void:
	var manager := _storage_manager()
	if manager != null and manager.has_method("sort_inventory"):
		manager.call("sort_inventory")
	refresh()

func _deposit_all() -> void:
	var manager := _backpack_manager()
	if manager != null and manager.has_method("deposit_all_to_storage"):
		manager.call("deposit_all_to_storage")
	refresh()

func _deposit_ice() -> void:
	var manager := _backpack_manager()
	if manager != null and manager.has_method("deposit_ice_to_water_system"):
		manager.call("deposit_ice_to_water_system")
	refresh()

func _eat_backpack_food() -> void:
	var manager := _backpack_manager()
	if manager != null and manager.has_method("eat_first_food"):
		manager.call("eat_first_food")
	refresh()

func _eat_storage_food() -> void:
	var manager := _storage_manager()
	if manager != null and manager.has_method("eat_first_food"):
		manager.call("eat_first_food")
	refresh()

func _backpack_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BackpackManager")

func _storage_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("StorageManager")
