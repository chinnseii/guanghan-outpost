extends Control
class_name GuanghanPopupModal

## Reusable modal popup: a full-screen scrim + a centered panel laid out as
## [ optional image | right column { title, subtitle, body text, actions } ].
## When no image is set the image column hides and the right column fills, so
## the same component serves both text-only dialogs (training_base_map) and the
## image-beside-text plant/solar diagnostics (training_module_scene,
## sprint06_base_scene) that used to each hand-build an identical modal.
##
## The panel auto-sizes to content via a CenterContainer, so callers no longer
## resize offsets by hand -- they just set content_min_size / image_min_size.
##
## A scene adds ONE of these as a child and drives it with open()/close(); the
## scene keeps its own pause / input-block / overlay logic and asks is_open().

signal opened
signal closed

const SCRIM_COLOR := Color("#02070d", 0.78)
const PANEL_BG := Color("#06111a", 0.98)
const PANEL_BORDER := Color("#496c80", 0.95)
const TEXT_COLOR := Color("#cfe3f2")
const TITLE_COLOR := Color("#eaf4ff")
const SUBTITLE_COLOR := Color("#9fb6c9")
const DEFAULT_CONTENT_MIN := Vector2(680, 460)
const DEFAULT_IMAGE_MIN := Vector2(500, 560)
const FEEDBACK_HEADER := "［操作反馈］"

var _scrim: ColorRect
var _panel: PanelContainer
var _image: TextureRect
var _right: VBoxContainer
var _title: Label
var _subtitle: Label
var _text: Label
var _actions: VBoxContainer
var _base_text := ""
var _dismissable := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false

func _build() -> void:
	_scrim = ColorRect.new()
	_scrim.color = SCRIM_COLOR
	_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.gui_input.connect(_on_scrim_gui_input)
	add_child(_scrim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	_panel.add_child(row)

	_image = TextureRect.new()
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.custom_minimum_size = DEFAULT_IMAGE_MIN
	_image.visible = false
	row.add_child(_image)

	_right = VBoxContainer.new()
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right.custom_minimum_size = DEFAULT_CONTENT_MIN
	_right.add_theme_constant_override("separation", 14)
	row.add_child(_right)

	_title = Label.new()
	_title.modulate = TITLE_COLOR
	_title.add_theme_font_size_override("font_size", 22)
	_title.visible = false
	_right.add_child(_title)

	_subtitle = Label.new()
	_subtitle.modulate = SUBTITLE_COLOR
	_subtitle.add_theme_font_size_override("font_size", 14)
	_subtitle.visible = false
	_right.add_child(_subtitle)

	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.modulate = TEXT_COLOR
	_text.add_theme_font_size_override("font_size", 16)
	_right.add_child(_text)

	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", 10)
	_right.add_child(_actions)

## config keys (all optional): text, title, subtitle, image (Texture2D/null),
## image_min_size (Vector2), content_min_size (Vector2), dismissable (bool)
func open(config: Dictionary = {}) -> void:
	_clear_actions()
	var body := String(config.get("text", ""))
	_base_text = body
	_text.text = body
	set_title(String(config.get("title", "")))
	set_subtitle(String(config.get("subtitle", "")))
	set_image(config.get("image", null))
	_image.custom_minimum_size = config.get("image_min_size", DEFAULT_IMAGE_MIN)
	_right.custom_minimum_size = config.get("content_min_size", DEFAULT_CONTENT_MIN)
	_dismissable = bool(config.get("dismissable", false))
	visible = true
	opened.emit()

## Add a pre-built control (e.g. a Button the caller already wired up).
func add_action_control(control: Control) -> void:
	if _actions != null and control != null:
		_actions.add_child(control)

## Convenience: build a standard action button with a callback.
func add_action(label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 42)
	button.focus_mode = Control.FOCUS_NONE
	if callback.is_valid():
		button.pressed.connect(callback)
	add_action_control(button)
	return button

func set_title(text: String) -> void:
	if _title == null:
		return
	_title.text = text
	_title.visible = not text.is_empty()

func set_subtitle(text: String) -> void:
	if _subtitle == null:
		return
	_subtitle.text = text
	_subtitle.visible = not text.is_empty()

func set_image(texture: Variant) -> void:
	if _image == null:
		return
	_image.texture = texture if texture is Texture2D else null
	_image.visible = texture is Texture2D

func set_body_text(text: String) -> void:
	_base_text = text
	if _text != null:
		_text.text = text

## In-modal wrong-choice feedback: keeps the modal open and appends a
## "［操作反馈］" block under the original body (mirrors the old
## _show_modal_wrong_feedback behaviour).
func append_feedback(hint: String) -> void:
	if not is_open() or _text == null:
		return
	_text.text = "%s\n\n%s\n%s" % [_base_text, FEEDBACK_HEADER, hint]

## Hide the popup. Actions are NOT freed here (they are cleared on the next
## open) so this stays safe to call from inside a button's own pressed signal.
func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func is_open() -> bool:
	return visible

func get_body_text() -> String:
	return _text.text if _text != null else ""

func _clear_actions() -> void:
	if _actions == null:
		return
	for child in _actions.get_children():
		child.queue_free()

func _on_scrim_gui_input(event: InputEvent) -> void:
	if not _dismissable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()
