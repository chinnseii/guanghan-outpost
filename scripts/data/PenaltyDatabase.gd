extends RefCounted

## Named penalty presets. Pure data (preload, no autoload) -- same style as
## DoorTypeDatabase / ItemDatabase. PenaltyManager.apply_penalty() accepts
## either one of these ids or an inline descriptor Dictionary with the same
## fields, so gameplay code can use a catalogued penalty or build an ad-hoc one.
##
## Descriptor fields (all optional except a way to identify it):
##   penalty_id / display_name / severity ("minor"/"major"/"critical")
##   reason              : String tag forwarded to the time managers
##   context             : "training" / "mission" / "" (empty = auto by
##                         PlayerStateManager.get_context())
##   silent              : bool -- true skips notice/history (ambient drains)
##   time_minutes        : int  -- burned on the context-appropriate clock
##   health_deltas       : { energy/fullness/nutrition/morale : float (<=0) }
##   energy_cost         : float -- HealthManager.consume_energy
##   remove_items        : [ { item_id, amount, source: backpack/storage/any } ]
##   supply_effect       : { type: reduce_weight/delay/cancel/force_item, ... }
##   notice_text / center_notice / center_color : optional UI strings

const DEFAULT_SEVERITY := "minor"

const PENALTIES := {
	# -- Training procedure mistakes (discrete, player-visible) --
	"training_pressure_wrong": {
		"display_name": "气闸操作失误",
		"severity": "minor",
		"context": "training",
		"reason": "training_airlock_pressure_wrong",
		"time_minutes": 15,
	},
	"training_battery_wrong": {
		"display_name": "电池组处理失误",
		"severity": "minor",
		"context": "training",
		"reason": "training_battery_wrong",
		"time_minutes": 15,
	},
	# -- Ambient environmental morale drains (continuous, silent) --
	# Applied per settlement tick by the environment systems; kept here as
	# named reasons so the drain sources are catalogued in one place even
	# though their per-tick magnitude is passed in at call time.
	"ambient_environment_morale": {
		"display_name": "环境压力",
		"severity": "minor",
		"context": "mission",
		"reason": "ambient_environment",
		"silent": true,
	},
}

static func has_penalty(penalty_id: String) -> bool:
	return PENALTIES.has(penalty_id)

static func get_penalty(penalty_id: String) -> Dictionary:
	if not PENALTIES.has(penalty_id):
		return {}
	var data: Dictionary = (PENALTIES[penalty_id] as Dictionary).duplicate(true)
	data["penalty_id"] = penalty_id
	return data

static func get_display_name(penalty_id: String) -> String:
	var data: Dictionary = get_penalty(penalty_id)
	return String(data.get("display_name", penalty_id))

static func get_severity(penalty_id: String) -> String:
	var data: Dictionary = get_penalty(penalty_id)
	return String(data.get("severity", DEFAULT_SEVERITY))

static func all_ids() -> Array:
	return PENALTIES.keys()
