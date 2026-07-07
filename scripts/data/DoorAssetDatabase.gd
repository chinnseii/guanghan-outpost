extends RefCounted

const DEFAULT_ASSET_ID := "DOOR-A01"

const DOOR_ASSETS := {
	"DOOR-A01": {
		"display_name": "普通室内滑门 A01",
		"texture_path": "res://assets/doors/door_a01.png",
		"open_animation": "door_a01_open",
		"close_animation": "door_a01_close",
		"sound_open": "door_soft_open",
		"sound_close": "door_soft_close",
		"size_tiles": Vector2i(2, 3),
	},
	"HATCH-B01": {
		"display_name": "气密舱门 B01",
		"texture_path": "res://assets/doors/hatch_b01.png",
		"open_animation": "hatch_b01_open",
		"close_animation": "hatch_b01_close",
		"sound_open": "hatch_open",
		"sound_close": "hatch_close",
		"size_tiles": Vector2i(2, 3),
	},
	"HATCH-B02": {
		"display_name": "温室舱门 B02",
		"texture_path": "res://assets/doors/hatch_b02_greenhouse.png",
		"open_animation": "hatch_b02_open",
		"close_animation": "hatch_b02_close",
		"sound_open": "hatch_open",
		"sound_close": "hatch_close",
		"size_tiles": Vector2i(2, 3),
	},
	"AIRLOCK-C01": {
		"display_name": "气闸内门 C01",
		"texture_path": "res://assets/doors/airlock_c01_inner.png",
		"open_animation": "airlock_c01_open",
		"close_animation": "airlock_c01_close",
		"sound_open": "airlock_inner_open",
		"sound_close": "airlock_inner_close",
		"size_tiles": Vector2i(3, 4),
	},
	"AIRLOCK-C02": {
		"display_name": "气闸外门 C02",
		"texture_path": "res://assets/doors/airlock_c02_outer.png",
		"open_animation": "airlock_c02_open",
		"close_animation": "airlock_c02_close",
		"sound_open": "airlock_outer_open",
		"sound_close": "airlock_outer_close",
		"size_tiles": Vector2i(3, 4),
	},
	"DOCK-D01": {
		"display_name": "飞船对接舱门 D01",
		"texture_path": "res://assets/doors/dock_d01.png",
		"open_animation": "dock_d01_open",
		"close_animation": "dock_d01_close",
		"sound_open": "dock_open",
		"sound_close": "dock_close",
		"size_tiles": Vector2i(3, 4),
	},
	"ELEV-E01": {
		"display_name": "货运电梯门 E01",
		"texture_path": "res://assets/doors/elevator_e01.png",
		"open_animation": "elevator_e01_open",
		"close_animation": "elevator_e01_close",
		"sound_open": "elevator_open",
		"sound_close": "elevator_close",
		"size_tiles": Vector2i(3, 3),
	},
	"BULK-F01": {
		"display_name": "大型舱段隔离门 F01",
		"texture_path": "res://assets/doors/bulkhead_f01.png",
		"open_animation": "bulkhead_f01_open",
		"close_animation": "bulkhead_f01_close",
		"sound_open": "bulkhead_open",
		"sound_close": "bulkhead_close",
		"size_tiles": Vector2i(4, 4),
	},
}

static func get_asset(asset_id: String) -> Dictionary:
	if not DOOR_ASSETS.has(asset_id):
		return (DOOR_ASSETS[DEFAULT_ASSET_ID] as Dictionary).duplicate(true)
	return (DOOR_ASSETS[asset_id] as Dictionary).duplicate(true)

static func has_asset(asset_id: String) -> bool:
	return DOOR_ASSETS.has(asset_id)

static func get_display_name(asset_id: String) -> String:
	var data: Dictionary = get_asset(asset_id)
	return String(data.get("display_name", "未知舱门资源"))

static func get_texture_path(asset_id: String) -> String:
	var data: Dictionary = get_asset(asset_id)
	return String(data.get("texture_path", ""))

static func get_open_animation(asset_id: String) -> String:
	var data: Dictionary = get_asset(asset_id)
	return String(data.get("open_animation", ""))

static func get_close_animation(asset_id: String) -> String:
	var data: Dictionary = get_asset(asset_id)
	return String(data.get("close_animation", ""))

static func get_sound_open(asset_id: String) -> String:
	var data: Dictionary = get_asset(asset_id)
	return String(data.get("sound_open", ""))

static func get_sound_close(asset_id: String) -> String:
	var data: Dictionary = get_asset(asset_id)
	return String(data.get("sound_close", ""))

static func get_size_tiles(asset_id: String) -> Vector2i:
	var data: Dictionary = get_asset(asset_id)
	return data.get("size_tiles", Vector2i(2, 3)) as Vector2i
