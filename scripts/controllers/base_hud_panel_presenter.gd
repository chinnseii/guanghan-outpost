extends RefCounted

## BaseHudPanelPresenter (P4-04): owns the sprint06 base-scene HUD/status-panel UI construction
## and the status-panel toggle/refresh, extracted from sprint06_base_scene.gd. UI-only: it builds
## nodes into the scene's tree, holds their references, and toggles/refreshes the status panels.
## It owns NO gameplay/save/checkpoint state, performs NO Manager writes, NO scene navigation, and
## NO Full Save. The scene creates it, calls build_ui(self), then re-exposes the flow-updated label
## nodes to its own vars (so the scene's HUD text/flow updates are unchanged) and delegates panel
## toggles + refresh here. The status panel widgets do their own Manager reads inside refresh().

const HUD_SAFE_POSITION := Vector2(24, 96)
const HUD_SAFE_SIZE := Vector2(360, 464)

const BaseStatusPanelScript := preload("res://scripts/ui/base_status_panel.gd")
const PlantGrowthPanelScript := preload("res://scripts/ui/plant_growth_panel.gd")
const AirSystemPanelScript := preload("res://scripts/ui/air_system_panel.gd")
const PowerSystemPanelScript := preload("res://scripts/ui/power_system_panel.gd")
const WaterSystemPanelScript := preload("res://scripts/ui/water_system_panel.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory_panel.gd")
const BackpackStoragePanelScript := preload("res://scripts/ui/backpack_storage_panel.gd")
const SuitPanelScript := preload("res://scripts/ui/suit_panel.gd")

## UI nodes built by build_ui() and exposed to the scene (which re-points its own vars at them).
var ui_root: Control
var hud_label: Label
var message_label: Label
var prompt_label: Label
var ai_label: Label
var time_hud_panel: PanelContainer
var time_hud_label: Label
var fade_rect: ColorRect
var interaction_panel: PanelContainer
var interaction_label: Label
var interaction_bar: ProgressBar
var base_status_panel: PanelContainer
var plant_growth_panel: PanelContainer
var air_system_panel: PanelContainer
var power_system_panel: PanelContainer
var water_system_panel: PanelContainer
var inventory_panel: PanelContainer
var backpack_storage_panel: PanelContainer
var suit_panel: PanelContainer

func build_ui(host: Node) -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UIOverlay"
	canvas.layer = 20
	host.add_child(canvas)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)
	ui_root = root

	hud_label = Label.new()
	hud_label.position = HUD_SAFE_POSITION
	hud_label.size = HUD_SAFE_SIZE
	hud_label.modulate = Color("#d8e7f2", 0.92)
	hud_label.clip_text = true
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_label.add_theme_font_size_override("font_size", 15)
	root.add_child(hud_label)

	message_label = Label.new()
	message_label.position = Vector2(465, 650)
	message_label.size = Vector2(670, 130)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.modulate = Color("#eaf4ff", 0.95)
	message_label.add_theme_font_size_override("font_size", 22)
	root.add_child(message_label)

	prompt_label = Label.new()
	prompt_label.position = Vector2(520, 810)
	prompt_label.size = Vector2(560, 44)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.modulate = Color("#f0c766", 0.86)
	prompt_label.add_theme_font_size_override("font_size", 18)
	root.add_child(prompt_label)

	ai_label = Label.new()
	ai_label.position = Vector2(430, 72)
	ai_label.size = Vector2(740, 86)
	ai_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ai_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ai_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ai_label.modulate = Color("#cfe3f2", 0.92)
	ai_label.add_theme_font_size_override("font_size", 23)
	root.add_child(ai_label)

	time_hud_panel = PanelContainer.new()
	time_hud_panel.position = Vector2(1250, 20)
	time_hud_panel.custom_minimum_size = Vector2(326, 108)
	root.add_child(time_hud_panel)
	time_hud_label = Label.new()
	time_hud_label.modulate = Color("#9fb4c4", 0.95)
	time_hud_label.add_theme_font_size_override("font_size", 14)
	time_hud_panel.add_child(time_hud_label)

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = -1
	root.add_child(fade_rect)
	_setup_interaction_feedback_ui(root)
	_setup_base_status_panel(root)
	_setup_plant_growth_panel(root)
	_setup_air_system_panel(root)
	_setup_power_system_panel(root)
	_setup_water_system_panel(root)
	_setup_inventory_panel(root)
	_setup_backpack_storage_panel(root)
	_setup_suit_panel(root)

func _setup_interaction_feedback_ui(root: Control) -> void:
	interaction_panel = PanelContainer.new()
	interaction_panel.position = Vector2(500, 724)
	interaction_panel.custom_minimum_size = Vector2(600, 76)
	interaction_panel.visible = false
	root.add_child(interaction_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	interaction_panel.add_child(box)
	interaction_label = Label.new()
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.modulate = Color("#eaf4ff")
	interaction_label.add_theme_font_size_override("font_size", 16)
	box.add_child(interaction_label)
	interaction_bar = ProgressBar.new()
	interaction_bar.min_value = 0.0
	interaction_bar.max_value = 1.0
	interaction_bar.value = 0.0
	interaction_bar.show_percentage = false
	interaction_bar.custom_minimum_size = Vector2(0, 12)
	box.add_child(interaction_bar)

func _setup_base_status_panel(root: Control) -> void:
	base_status_panel = BaseStatusPanelScript.new()
	base_status_panel.position = Vector2(1170, 180)
	base_status_panel.visible = false
	root.add_child(base_status_panel)

func _toggle_base_status_panel() -> void:
	if base_status_panel == null:
		return
	base_status_panel.visible = not base_status_panel.visible
	if base_status_panel.visible and base_status_panel.has_method("refresh"):
		base_status_panel.call("refresh")

func _setup_plant_growth_panel(root: Control) -> void:
	plant_growth_panel = PlantGrowthPanelScript.new()
	plant_growth_panel.position = Vector2(1170, 500)
	plant_growth_panel.visible = false
	root.add_child(plant_growth_panel)

func _toggle_plant_growth_panel(is_greenhouse: bool) -> void:
	if plant_growth_panel == null or not is_greenhouse:
		return
	plant_growth_panel.visible = not plant_growth_panel.visible
	if plant_growth_panel.visible and plant_growth_panel.has_method("refresh"):
		plant_growth_panel.call("refresh")

func _setup_air_system_panel(root: Control) -> void:
	air_system_panel = AirSystemPanelScript.new()
	air_system_panel.position = Vector2(740, 180)
	air_system_panel.visible = false
	root.add_child(air_system_panel)

func _toggle_air_system_panel() -> void:
	if air_system_panel == null:
		return
	air_system_panel.visible = not air_system_panel.visible
	if air_system_panel.visible and air_system_panel.has_method("refresh"):
		air_system_panel.call("refresh")

func _setup_power_system_panel(root: Control) -> void:
	power_system_panel = PowerSystemPanelScript.new()
	power_system_panel.position = Vector2(740, 500)
	power_system_panel.visible = false
	root.add_child(power_system_panel)

func _toggle_power_system_panel() -> void:
	if power_system_panel == null:
		return
	power_system_panel.visible = not power_system_panel.visible
	if power_system_panel.visible and power_system_panel.has_method("refresh"):
		power_system_panel.call("refresh")

## Narrower than the other status panels (330 vs 420) so it fits the gap
## between the HUD safe zone and the air panel at x=740 without overlapping.
func _setup_water_system_panel(root: Control) -> void:
	water_system_panel = WaterSystemPanelScript.new()
	water_system_panel.position = Vector2(400, 180)
	water_system_panel.visible = false
	root.add_child(water_system_panel)

func _toggle_water_system_panel() -> void:
	if water_system_panel == null:
		return
	water_system_panel.visible = not water_system_panel.visible
	if water_system_panel.visible and water_system_panel.has_method("refresh"):
		water_system_panel.call("refresh")

## Same narrow (330-wide) column as the water panel, directly below it —
## completes a 3x2 grid: Water/Air/Base on top, Inventory/Power/Plant below.
## (Fixed a merge collision here: an earlier combined commit had this
## function instantiating BackpackStoragePanelScript instead of
## InventoryPanelScript, silently making the actual inventory panel
## unreachable from the B key. Restored to the original inventory panel and
## gave BackpackStoragePanel its own slot below.)
func _setup_inventory_panel(root: Control) -> void:
	inventory_panel = InventoryPanelScript.new()
	inventory_panel.position = Vector2(400, 500)
	inventory_panel.visible = false
	root.add_child(inventory_panel)

func _toggle_inventory_panel() -> void:
	if inventory_panel == null:
		return
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible and inventory_panel.has_method("refresh"):
		inventory_panel.call("refresh")

## Backpack/Storage is a bigger modal-style panel (520x430) rather than
## another corner-grid cell, so it's roughly centered on the 1600x900
## viewport instead of squeezed into the grid.
func _setup_backpack_storage_panel(root: Control) -> void:
	backpack_storage_panel = BackpackStoragePanelScript.new()
	backpack_storage_panel.position = Vector2(540, 235)
	backpack_storage_panel.visible = false
	root.add_child(backpack_storage_panel)

func _toggle_backpack_storage_panel() -> void:
	if backpack_storage_panel == null:
		return
	backpack_storage_panel.visible = not backpack_storage_panel.visible
	if backpack_storage_panel.visible and backpack_storage_panel.has_method("refresh"):
		backpack_storage_panel.call("refresh")

## Wide-and-short strip in the one remaining gap below the 3x2 grid
## (y=800-900 across the full grid width) — see suit_panel.gd for why.
func _setup_suit_panel(root: Control) -> void:
	suit_panel = SuitPanelScript.new()
	suit_panel.position = Vector2(400, 810)
	suit_panel.visible = false
	root.add_child(suit_panel)

func _toggle_suit_panel() -> void:
	if suit_panel == null:
		return
	suit_panel.visible = not suit_panel.visible
	if suit_panel.visible and suit_panel.has_method("refresh"):
		suit_panel.call("refresh")


## Refresh whichever status panels are currently open (called from the scene's _update_ui).
func refresh_open_panels() -> void:
	for panel in [base_status_panel, plant_growth_panel, air_system_panel, power_system_panel, water_system_panel, inventory_panel, backpack_storage_panel, suit_panel]:
		if panel != null and panel.visible and panel.has_method("refresh"):
			panel.call("refresh")
