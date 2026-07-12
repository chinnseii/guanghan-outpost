extends Node

## Player current-state hub: the single place other systems ask "where is
## the player right now, are they suited, what are they holding, what are
## they about to interact with". It is a STATE REGISTRY, not a gameplay
## calculator -- it never computes health, suit oxygen/power, item effects,
## movement time, repair results, or advances any clock. Those stay with
## HealthManager / SuitManager / Inventory+BackpackManager /
## MovementTimeManager / RepairManager / TrainingTimeManager respectively.
## See docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md for the boundary table.
##
## Autoload: /root/PlayerStateManager.

signal player_state_changed

# -- Context: training vs mission. PlayerStateManager never advances time
# itself; it only reports which clock other systems should use (training ->
# TrainingTimeManager, mission -> TimeManager).
var current_context: String = "training"

# -- Current area (set by whatever drives room/scene transitions -- the
# training small map today, a real AreaManager later if one is built).
var current_area_id: String = ""
var current_area_name: String = ""
var current_area_type: String = ""  # interior / airlock / exterior_training / greenhouse / power_room ...
var is_in_pressurized_area: bool = true
var is_in_exterior_area: bool = false
var is_in_airlock: bool = false

# -- Movement / interaction locks. is_busy is an INDEPENDENT axis from
# can_move/can_interact (see set_busy below for why this differs from the
# original spec): the query helpers AND them, so a modal that set
# can_move=false is not silently re-enabled when some unrelated busy action
# finishes.
var can_move: bool = true
var can_interact: bool = true
var is_busy: bool = false

# -- Suit-worn snapshot. SuitManager remains the source of truth; this is a
# cached mirror it pushes on wear/remove so other systems can check suit
# state without reaching into SuitManager.
var is_suit_worn: bool = false

# -- Held item / hotbar. Only the current selection id -- inventory add/
# remove and use-effects stay in Inventory/BackpackManager.
var held_item_id: String = ""
var selected_hotbar_slot: int = -1

# -- Current interaction target (the thing an "E 交互" prompt points at).
var current_interaction_id: String = ""
var current_interaction_type: String = ""
var current_interaction_label: String = ""

## PlayerStateManager is registered after SuitManager in project.godot, so
## SuitManager already exists here -- pull its worn state once at boot in
## case SuitManager's own load_state() ran before this autoload was added
## (its push then no-oped against a not-yet-present PlayerStateManager).
func _ready() -> void:
	sync_suit_state_from_suit_manager()

func _notify() -> void:
	player_state_changed.emit()

## -- Context --

func set_context(context: String) -> void:
	if current_context == context:
		return
	current_context = context
	_notify()

func is_training_context() -> bool:
	return current_context == "training"

func is_mission_context() -> bool:
	return current_context == "mission"

func get_context() -> String:
	return current_context

## -- Area --

func set_current_area(area_data: Dictionary) -> void:
	set_current_area_by_values(
		String(area_data.get("area_id", "")),
		String(area_data.get("area_name", "")),
		String(area_data.get("area_type", "")),
		bool(area_data.get("has_air", true)),
		bool(area_data.get("is_pressurized", true)),
	)

func set_current_area_by_values(area_id: String, area_name: String, area_type: String, has_air: bool, is_pressurized: bool) -> void:
	current_area_id = area_id
	current_area_name = area_name
	current_area_type = area_type
	is_in_pressurized_area = is_pressurized
	is_in_exterior_area = not has_air
	is_in_airlock = area_type == "airlock"
	_notify()

func get_current_area_id() -> String:
	return current_area_id

func get_current_area_name() -> String:
	return current_area_name

func get_current_area_type() -> String:
	return current_area_type

func is_exterior_area() -> bool:
	return is_in_exterior_area

func is_pressurized_area() -> bool:
	return is_in_pressurized_area

func is_airlock_area() -> bool:
	return is_in_airlock

## -- Move / interact / busy locks --

func set_can_move(value: bool) -> void:
	if can_move == value:
		return
	can_move = value
	_notify()

func set_can_interact(value: bool) -> void:
	if can_interact == value:
		return
	can_interact = value
	_notify()

## Unlike the original spec, set_busy only toggles the is_busy axis; it does
## NOT force can_move/can_interact back to true when clearing busy. The query
## helpers below already AND is_busy in, so a busy action fully blocks
## movement/interaction while active, and clearing it restores whatever
## can_move/can_interact a panel or cutscene had independently set -- rather
## than clobbering them true (which was a foot-gun: e.g. an open menu that
## set can_move=false would get re-enabled the moment an unrelated busy
## flag cleared).
func set_busy(value: bool) -> void:
	if is_busy == value:
		return
	is_busy = value
	_notify()

func can_player_move() -> bool:
	return can_move and not is_busy

func can_player_interact() -> bool:
	return can_interact and not is_busy

## -- Suit-worn snapshot (SuitManager pushes these) --

func sync_suit_worn_mirror_from_suit_manager(value: bool) -> void:
	if is_suit_worn == value:
		return
	is_suit_worn = value
	_notify()

## Compatibility wrapper for older callers/tests. SuitManager remains the
## canonical write entry for actual wear/remove gameplay state.
func set_suit_worn(value: bool) -> void:
	sync_suit_worn_mirror_from_suit_manager(value)

func get_is_suit_worn() -> bool:
	return is_suit_worn

func sync_suit_state_from_suit_manager() -> void:
	var suit_manager := _suit_manager()
	if suit_manager != null:
		sync_suit_worn_mirror_from_suit_manager(bool(suit_manager.get("is_suit_worn")))

## -- Area entry rules (suit gate) -- callers (doors / scene transitions)
## check these BEFORE moving the player into an area. PlayerStateManager
## only knows the suit-worn snapshot; the area's own requires_suit flag is
## passed in by the caller.

func can_enter_current_area_rules(area_data: Dictionary) -> bool:
	return can_enter_area_requires_suit(bool(area_data.get("requires_suit", false)))

func can_enter_area_requires_suit(requires_suit: bool) -> bool:
	if requires_suit and not is_suit_worn:
		return false
	return true

## -- Held item / hotbar --

func set_held_item(item_id: String) -> void:
	if held_item_id == item_id:
		return
	held_item_id = item_id
	_notify()

func clear_held_item() -> void:
	set_held_item("")

func get_held_item_id() -> String:
	return held_item_id

func set_selected_hotbar_slot(slot_index: int) -> void:
	if selected_hotbar_slot == slot_index:
		return
	selected_hotbar_slot = slot_index
	_notify()

func get_selected_hotbar_slot() -> int:
	return selected_hotbar_slot

## -- Current interaction target --

func set_current_interaction(interaction_id: String, interaction_type: String, label: String) -> void:
	if current_interaction_id == interaction_id and current_interaction_type == interaction_type and current_interaction_label == label:
		return
	current_interaction_id = interaction_id
	current_interaction_type = interaction_type
	current_interaction_label = label
	_notify()

func clear_current_interaction() -> void:
	if current_interaction_id.is_empty() and current_interaction_type.is_empty() and current_interaction_label.is_empty():
		return
	current_interaction_id = ""
	current_interaction_type = ""
	current_interaction_label = ""
	_notify()

func get_current_interaction_id() -> String:
	return current_interaction_id

func get_current_interaction_type() -> String:
	return current_interaction_type

func get_current_interaction_label() -> String:
	return current_interaction_label

func has_current_interaction() -> bool:
	return not current_interaction_id.is_empty()

## -- Lifecycle / persistence (matches the other managers' convention so
## TrainingManager can bundle/reset it uniformly). Only the durable subset
## is persisted; interaction target and the transient locks are
## re-established on scene entry, per the spec.

func reset_to_arrival() -> void:
	current_context = "training"
	current_area_id = ""
	current_area_name = ""
	current_area_type = ""
	is_in_pressurized_area = true
	is_in_exterior_area = false
	is_in_airlock = false
	can_move = true
	can_interact = true
	is_busy = false
	is_suit_worn = false
	held_item_id = ""
	selected_hotbar_slot = -1
	clear_current_interaction()
	_notify()

func serialize() -> Dictionary:
	return {
		"current_context": current_context,
		"current_area_id": current_area_id,
		"is_suit_worn": is_suit_worn,
		"held_item_id": held_item_id,
		"selected_hotbar_slot": selected_hotbar_slot,
	}

func deserialize(data: Dictionary) -> void:
	current_context = String(data.get("current_context", current_context))
	current_area_id = String(data.get("current_area_id", current_area_id))
	is_suit_worn = bool(data.get("is_suit_worn", is_suit_worn))
	held_item_id = String(data.get("held_item_id", held_item_id))
	selected_hotbar_slot = int(data.get("selected_hotbar_slot", selected_hotbar_slot))
	_notify()

## -- Cross-system lookup --

func _suit_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SuitManager")

## -- Debug --

func debug_values_text() -> String:
	return "\n".join([
		"PlayerStateManager: context=%s area=%s(%s)" % [current_context, current_area_id, current_area_type],
		"pressurized=%s exterior=%s airlock=%s suit=%s" % [is_in_pressurized_area, is_in_exterior_area, is_in_airlock, is_suit_worn],
		"can_move=%s can_interact=%s busy=%s held=%s slot=%d" % [can_move, can_interact, is_busy, held_item_id, selected_hotbar_slot],
		"interaction=%s(%s) label=%s" % [current_interaction_id, current_interaction_type, current_interaction_label],
	])
