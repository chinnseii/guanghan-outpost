extends RefCounted

## Static crop reference data for Plant Growth System v1.
## Water/light requirement levels use the same 0-4 scale as
## PlantGrowthManager.water_cycle_level / effective light level.

const CROPS := {
	"lettuce": {
		"display_name": "生菜",
		"growth_days": 3.0,
		"water_requirement": 1,
		"light_requirement": 2,
		"min_temperature": 16.0,
		"max_temperature": 24.0,
		"harvest_fullness": 18.0,
		"harvest_nutrition": 8.0,
		"harvest_morale": 6.0,
		"repeat_harvest": false,
		"reharvest_interval_days": 0.0,
		"max_extra_harvests": 0,
		"risk_note": "温度过高时容易停止生长。",
	},
	"potato": {
		"display_name": "土豆",
		"growth_days": 6.0,
		"water_requirement": 2,
		"light_requirement": 2,
		"min_temperature": 14.0,
		"max_temperature": 24.0,
		"harvest_fullness": 45.0,
		"harvest_nutrition": 10.0,
		"harvest_morale": 3.0,
		"repeat_harvest": false,
		"reharvest_interval_days": 0.0,
		"max_extra_harvests": 0,
		"risk_note": "周期中等，适合作为月夜前储备主粮。",
	},
	"wheat": {
		"display_name": "小麦",
		"growth_days": 8.0,
		"water_requirement": 1,
		"light_requirement": 4,
		"min_temperature": 15.0,
		"max_temperature": 26.0,
		"harvest_fullness": 35.0,
		"harvest_nutrition": 8.0,
		"harvest_morale": 2.0,
		"repeat_harvest": false,
		"reharvest_interval_days": 0.0,
		"max_extra_harvests": 0,
		"risk_note": "光照需求高，月夜或电力不足时不适合大量种植。",
	},
	"tomato": {
		"display_name": "番茄",
		"growth_days": 7.0,
		"water_requirement": 3,
		"light_requirement": 4,
		"min_temperature": 18.0,
		"max_temperature": 26.0,
		"harvest_fullness": 22.0,
		"harvest_nutrition": 18.0,
		"harvest_morale": 10.0,
		"repeat_harvest": true,
		"reharvest_interval_days": 3.0,
		"max_extra_harvests": 3,
		"risk_note": "对水、光、温度都较敏感。",
	},
	"soybean": {
		"display_name": "大豆",
		"growth_days": 9.0,
		"water_requirement": 2,
		"light_requirement": 3,
		"min_temperature": 18.0,
		"max_temperature": 27.0,
		"harvest_fullness": 30.0,
		"harvest_nutrition": 30.0,
		"harvest_morale": 4.0,
		"repeat_harvest": false,
		"reharvest_interval_days": 0.0,
		"max_extra_harvests": 0,
		"risk_note": "周期长，适合基地稳定后规划。",
	},
}

static func has_crop(crop_id: String) -> bool:
	return CROPS.has(crop_id)

static func get_crop(crop_id: String) -> Dictionary:
	return CROPS.get(crop_id, {})

static func crop_ids() -> Array:
	return CROPS.keys()
