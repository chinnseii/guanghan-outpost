extends Node
class_name GuanghanPenaltyManager

## Central penalty dispatcher. Other systems detect that a penalty is due and
## call apply_penalty(); this manager fans the penalty's effects out to the
## time / health / inventory / earth-supply systems. It does NOT detect
## trigger conditions or compute gameplay itself -- like PlayerStateManager,
## it is a routing layer, not a rules engine.
##
## Time and health penalties auto-route by context: a "training" penalty burns
## the training clock (and is expected to carry only training-safe effects),
## a "mission" penalty burns the real TimeManager. Context comes from the
## descriptor, else from PlayerStateManager.get_context(), else "mission".

signal penalty_applied(record: Dictionary)

const PenaltyDatabaseScript := preload("res://scripts/data/PenaltyDatabase.gd")
const MAX_HISTORY := 20

var history: Array = []
var last_notice: String = ""

## penalty: a String preset id (PenaltyDatabase) or an inline descriptor Dict.
## overrides: fields merged over the resolved descriptor (context/reason/silent/
## time_minutes/... ) so callers can tweak a preset per call.
func apply_penalty(penalty: Variant, overrides: Dictionary = {}) -> Dictionary:
	var descriptor := _resolve_descriptor(penalty)
	if descriptor.is_empty():
		last_notice = "未知惩罚：%s" % str(penalty)
		return {"applied": false, "blocked_reason": last_notice, "effects_applied": []}
	for key in overrides.keys():
		descriptor[key] = overrides[key]

	var effects: Array = []
	_apply_time(descriptor, effects)
	_apply_health(descriptor, effects)
	_apply_energy_cost(descriptor, effects)
	_apply_remove_items(descriptor, effects)
	_apply_supply(descriptor, effects)

	var record := {
		"penalty_id": String(descriptor.get("penalty_id", "")),
		"display_name": String(descriptor.get("display_name", "")),
		"severity": String(descriptor.get("severity", PenaltyDatabaseScript.DEFAULT_SEVERITY)),
		"reason": String(descriptor.get("reason", "")),
		"context": _resolve_context(descriptor),
		"notice_text": String(descriptor.get("notice_text", "")),
		"effects_applied": effects,
	}
	if not bool(descriptor.get("silent", false)):
		last_notice = _compose_notice(record)
		_record(record)
	penalty_applied.emit(record)
	return {"applied": true, "effects_applied": effects, "blocked_reason": ""}

func get_history() -> Array:
	return history.duplicate(true)

func get_last_notice() -> String:
	return last_notice

func clear_history() -> void:
	history.clear()

## -- Resolution --

func _resolve_descriptor(penalty: Variant) -> Dictionary:
	if penalty is Dictionary:
		return (penalty as Dictionary).duplicate(true)
	if penalty is String:
		return PenaltyDatabaseScript.get_penalty(String(penalty))
	return {}

func _resolve_context(descriptor: Dictionary) -> String:
	var context := String(descriptor.get("context", ""))
	if not context.is_empty():
		return context
	var player_state := get_node_or_null("/root/PlayerStateManager")
	if player_state != null and player_state.has_method("get_context"):
		return String(player_state.call("get_context"))
	return "mission"

## -- Effect dispatchers (each guarded; a missing target system is a no-op) --

func _apply_time(descriptor: Dictionary, effects: Array) -> void:
	var minutes := int(descriptor.get("time_minutes", 0))
	if minutes <= 0:
		return
	var reason := String(descriptor.get("reason", "penalty"))
	if _resolve_context(descriptor) == "training":
		var training_time := get_node_or_null("/root/TrainingTimeManager")
		if training_time != null and training_time.has_method("advance_training_time"):
			training_time.call("advance_training_time", minutes, reason)
			effects.append("time_training:+%d" % minutes)
			return
	var time_manager := get_node_or_null("/root/TimeManager")
	if time_manager != null and time_manager.has_method("advance_time"):
		time_manager.call("advance_time", minutes, reason)
		effects.append("time_mission:+%d" % minutes)

func _apply_health(descriptor: Dictionary, effects: Array) -> void:
	var deltas: Dictionary = descriptor.get("health_deltas", {})
	if deltas.is_empty():
		return
	var health := get_node_or_null("/root/HealthManager")
	if health == null or not health.has_method("adjust_stat"):
		return
	for stat_name in deltas.keys():
		var delta := float(deltas[stat_name])
		if delta == 0.0:
			continue
		health.call("adjust_stat", String(stat_name), delta)
		effects.append("%s:%s" % [String(stat_name), delta])

func _apply_energy_cost(descriptor: Dictionary, effects: Array) -> void:
	var amount := float(descriptor.get("energy_cost", 0.0))
	if amount <= 0.0:
		return
	var health := get_node_or_null("/root/HealthManager")
	if health != null and health.has_method("consume_energy"):
		health.call("consume_energy", amount, String(descriptor.get("reason", "penalty")))
		effects.append("energy_cost:%s" % amount)

func _apply_remove_items(descriptor: Dictionary, effects: Array) -> void:
	var items: Array = descriptor.get("remove_items", [])
	for entry_value in items:
		if typeof(entry_value) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_value
		var item_id := String(entry.get("item_id", ""))
		if item_id.is_empty():
			continue
		var amount := int(entry.get("amount", 1))
		var source := String(entry.get("source", "any"))
		var removed := _remove_items_from(source, item_id, amount)
		effects.append("remove_item:%s x%d(%s)" % [item_id, removed, source])

func _remove_items_from(source: String, item_id: String, amount: int) -> int:
	var backpack := get_node_or_null("/root/BackpackManager")
	var storage := get_node_or_null("/root/StorageManager")
	var removed := 0
	if source == "storage":
		removed += _remove_from_manager(storage, item_id, amount)
		return removed
	if source == "backpack":
		removed += _remove_from_manager(backpack, item_id, amount)
		return removed
	# "any": take from the backpack first, then top up the shortfall from storage.
	removed += _remove_from_manager(backpack, item_id, amount)
	if removed < amount:
		removed += _remove_from_manager(storage, item_id, amount - removed)
	return removed

func _remove_from_manager(manager: Node, item_id: String, amount: int) -> int:
	if manager == null or amount <= 0:
		return 0
	var available := amount
	if manager.has_method("get_item_count"):
		available = min(amount, int(manager.call("get_item_count", item_id)))
	if available <= 0:
		return 0
	if manager.has_method("remove_item") and bool(manager.call("remove_item", item_id, available)):
		return available
	return 0

func _apply_supply(descriptor: Dictionary, effects: Array) -> void:
	var effect: Dictionary = descriptor.get("supply_effect", {})
	if effect.is_empty():
		return
	var supply := get_node_or_null("/root/SupplyManager")
	if supply == null:
		return
	var type := String(effect.get("type", ""))
	match type:
		"reduce_weight":
			var weight := float(effect.get("amount", 0.0))
			if weight > 0.0 and supply.has_method("apply_supply_weight_penalty"):
				if bool(supply.call("apply_supply_weight_penalty", weight)):
					effects.append("supply_reduce_weight:%s" % weight)
		"delay":
			var minutes := int(effect.get("minutes", 0))
			if minutes > 0 and supply.has_method("delay_current_supply"):
				if bool(supply.call("delay_current_supply", minutes)):
					effects.append("supply_delay:+%d" % minutes)
		"cancel":
			if supply.has_method("cancel_current_supply"):
				if bool(supply.call("cancel_current_supply")):
					effects.append("supply_cancel")
		"force_item":
			var target_index := int(effect.get("supply_index", 0))
			var item_id := String(effect.get("item_id", ""))
			if not item_id.is_empty() and supply.has_method("set_forced_supply_item"):
				supply.call("set_forced_supply_item", target_index, item_id)
				effects.append("supply_force_item:%s" % item_id)

## -- Bookkeeping --

func _compose_notice(record: Dictionary) -> String:
	var notice := String(record.get("notice_text", ""))
	if not notice.is_empty():
		return notice
	var name := String(record.get("display_name", ""))
	if name.is_empty():
		return "已施加惩罚。"
	return "惩罚：%s" % name

func _record(record: Dictionary) -> void:
	history.append(record)
	while history.size() > MAX_HISTORY:
		history.pop_front()

func debug_values_text() -> String:
	if history.is_empty():
		return "惩罚记录：无"
	var lines: Array[String] = ["惩罚记录（最近）："]
	for record in history:
		lines.append("- [%s] %s %s" % [
			String(record.get("severity", "")),
			String(record.get("display_name", "")),
			str(record.get("effects_applied", [])),
		])
	return "\n".join(lines)
