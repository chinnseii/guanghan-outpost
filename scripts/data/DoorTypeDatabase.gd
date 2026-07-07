extends RefCounted

const DEFAULT_TYPE_ID := "indoor_sliding_door"

const DOOR_TYPES := {
	"indoor_sliding_door": {
		"display_name": "室内滑门",
		"default_asset_id": "DOOR-A01",
		"requires_suit_to_pass": false,
		"requires_power": true,
		"has_seal": false,
		"can_lock": true,
		"is_airlock_door": false,
		"requires_docking_connected": false,
	},
	"airtight_hatch": {
		"display_name": "气密舱门",
		"default_asset_id": "HATCH-B01",
		"requires_suit_to_pass": false,
		"requires_power": true,
		"has_seal": true,
		"can_lock": true,
		"is_airlock_door": false,
		"requires_docking_connected": false,
	},
	"greenhouse_hatch": {
		"display_name": "温室气密舱门",
		"default_asset_id": "HATCH-B02",
		"requires_suit_to_pass": false,
		"requires_power": true,
		"has_seal": true,
		"can_lock": true,
		"is_airlock_door": false,
		"requires_docking_connected": false,
	},
	"airlock_inner_door": {
		"display_name": "气闸内门",
		"default_asset_id": "AIRLOCK-C01",
		"requires_suit_to_pass": false,
		"requires_power": true,
		"has_seal": true,
		"can_lock": true,
		"is_airlock_door": true,
		"requires_docking_connected": false,
	},
	"airlock_outer_door": {
		"display_name": "气闸外门",
		"default_asset_id": "AIRLOCK-C02",
		"requires_suit_to_pass": true,
		"requires_power": true,
		"has_seal": true,
		"can_lock": true,
		"is_airlock_door": true,
		"requires_docking_connected": false,
	},
	"docking_hatch": {
		"display_name": "对接舱门",
		"default_asset_id": "DOCK-D01",
		"requires_suit_to_pass": false,
		"requires_power": true,
		"has_seal": true,
		"can_lock": true,
		"is_airlock_door": false,
		"requires_docking_connected": true,
	},
	"cargo_elevator_door": {
		"display_name": "货运电梯门",
		"default_asset_id": "ELEV-E01",
		"requires_suit_to_pass": false,
		"requires_power": true,
		"has_seal": false,
		"can_lock": true,
		"is_airlock_door": false,
		"requires_docking_connected": false,
	},
	"bulkhead_door": {
		"display_name": "大型舱段隔离门",
		"default_asset_id": "BULK-F01",
		"requires_suit_to_pass": false,
		"requires_power": true,
		"has_seal": true,
		"can_lock": true,
		"is_airlock_door": false,
		"requires_docking_connected": false,
	},
}

static func get_type(type_id: String) -> Dictionary:
	if not DOOR_TYPES.has(type_id):
		return (DOOR_TYPES[DEFAULT_TYPE_ID] as Dictionary).duplicate(true)
	return (DOOR_TYPES[type_id] as Dictionary).duplicate(true)

static func has_type(type_id: String) -> bool:
	return DOOR_TYPES.has(type_id)

static func get_display_name(type_id: String) -> String:
	var data: Dictionary = get_type(type_id)
	return String(data.get("display_name", "未知舱门类型"))

static func get_default_asset_id(type_id: String) -> String:
	var data: Dictionary = get_type(type_id)
	return String(data.get("default_asset_id", "DOOR-A01"))

static func requires_suit_to_pass(type_id: String) -> bool:
	var data: Dictionary = get_type(type_id)
	return bool(data.get("requires_suit_to_pass", false))

static func requires_power(type_id: String) -> bool:
	var data: Dictionary = get_type(type_id)
	return bool(data.get("requires_power", true))

static func has_seal(type_id: String) -> bool:
	var data: Dictionary = get_type(type_id)
	return bool(data.get("has_seal", false))

static func can_lock(type_id: String) -> bool:
	var data: Dictionary = get_type(type_id)
	return bool(data.get("can_lock", true))

static func is_airlock_door(type_id: String) -> bool:
	var data: Dictionary = get_type(type_id)
	return bool(data.get("is_airlock_door", false))

static func requires_docking_connected(type_id: String) -> bool:
	var data: Dictionary = get_type(type_id)
	return bool(data.get("requires_docking_connected", false))
