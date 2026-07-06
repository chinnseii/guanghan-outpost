extends RefCounted

class_name GuanghanFaultDatabase

static func _faults() -> Dictionary:
	return {
	"FA-PO-001": {
		"display_name": "太阳能板积尘",
		"system": "power",
		"severity": 1,
		"symptom_text": "月昼期间发电效率下降。电池状态与线路读数正常。",
		"hidden_hint": "电池和线路没有异常，优先检查阵列表面。",
		"repair_options": [
			_option("clean_panel", "清理太阳能板表面", "执行面板除尘与表面检查。", true, 30, {}, 0, {}, {}),
			_option("replace_electronics", "更换电子控制件", "尝试更换面板控制电路。", false, 0, {}, 30, {"MT-EL-001": 1}, {}),
			_option("check_battery", "检查电池组", "转入电池组巡检。", false, 0, {}, 30, {}, {}),
		],
		"on_repair_success": {"power": {"energy_delta": 2.0}},
		"unresolved_effect": {"power": {"daily_generation_penalty": 0.08}},
	},
	"FA-PO-002": {
		"display_name": "太阳能阵列接线松动",
		"system": "power",
		"severity": 2,
		"symptom_text": "月昼期间发电读数波动，面板表面无明显遮挡。",
		"hidden_hint": "发电不是持续偏低，而是间歇波动，优先检查线路连接。",
		"repair_options": [
			_option("fix_line_insulation", "固定接线并补强绝缘", "重新固定阵列接线，补强受损绝缘层。", true, 60, {"MT-IN-001": 1}, 0, {}, {}),
			_option("clean_panel", "清理太阳能板表面", "执行常规除尘。", false, 0, {}, 30, {}, {}),
			_option("replace_filter", "更换过滤材料", "误判为空气过滤耗材问题。", false, 0, {}, 30, {"MT-FI-001": 1}, {}),
		],
		"on_repair_success": {"power": {"energy_delta": 4.0}},
		"unresolved_effect": {"power": {"generation_fluctuation": 0.12}},
	},
	"FA-PO-003": {
		"display_name": "电池控制器故障",
		"system": "power",
		"severity": 3,
		"symptom_text": "电池容量读数正常，但充放电效率异常，负载切换时波动明显。",
		"hidden_hint": "面板和电池本体都不像根因，控制器更可疑。",
		"repair_options": [
			_option("replace_controller", "更换控制电子件并补强绝缘", "更换电池控制器关键件并检查绝缘。", true, 120, {"MT-EL-001": 1, "MT-IN-001": 1}, 0, {}, {}),
			_option("clean_panel", "清理太阳能板表面", "对阵列表面执行除尘。", false, 0, {}, 60, {}, {}),
			_option("force_high_load", "强制高负载充放电测试", "尝试用高负载重置控制器。", false, 0, {}, 60, {}, {"power": {"energy_delta": -10.0}}),
		],
		"on_repair_success": {"power": {"energy_delta": 8.0}},
		"unresolved_effect": {"power": {"storage_efficiency_penalty": 0.18}},
	},
	"FA-AIR-001": {
		"display_name": "CO2 过滤器堵塞",
		"system": "air",
		"severity": 2,
		"symptom_text": "二氧化碳浓度上升。舱压稳定，氧气生成正常。",
		"hidden_hint": "压力和氧气正常时，CO2 上升更像过滤链路问题。",
		"repair_options": [
			_option("replace_filter", "更换 CO2 过滤材料", "拆换过滤材料并复位过滤模块。", true, 60, {"MT-FI-001": 1}, 0, {}, {}),
			_option("increase_oxygen", "提高制氧输出", "通过提高制氧量尝试压制 CO2。", false, 0, {}, 30, {}, {"power": {"energy_delta": -3.0}}),
			_option("add_inert_gas", "补充惰性气体", "误将空气比例异常判断为惰性气体不足。", false, 0, {}, 30, {"CN-IG-001": 1}, {}),
		],
		"on_repair_success": {"air": {"co2_percent": -0.12}},
		"unresolved_effect": {"air": {"co2_rise_rate": 0.1}},
	},
	"FA-AIR-002": {
		"display_name": "制氧模块效率下降",
		"system": "air",
		"severity": 2,
		"symptom_text": "氧气缓慢下降。CO2 过滤正常，水与电力消耗上升。",
		"hidden_hint": "氧气下降伴随水电消耗上升，优先检查电解制氧链路。",
		"repair_options": [
			_option("clean_electrolyzer", "清理电解槽并更换电子件", "清理制氧模块电解槽，更换异常电子件。", true, 60, {"MT-EL-001": 1}, 0, {}, {}),
			_option("replace_filter", "更换过滤材料", "将制氧下降误判为空气过滤问题。", false, 0, {}, 30, {"MT-FI-001": 1}, {}),
			_option("add_inert_gas", "补充惰性气体", "尝试通过惰性气体调整舱内比例。", false, 0, {}, 30, {"CN-IG-001": 1}, {}),
		],
		"on_repair_success": {"air": {"o2_percent": 0.4}},
		"unresolved_effect": {"air": {"oxygen_efficiency_penalty": 0.12}},
	},
	"FA-AIR-003": {
		"display_name": "空气循环风机卡滞",
		"system": "air",
		"severity": 2,
		"symptom_text": "局部 CO2 偏高，植物舱读数异常。舱压保持正常。",
		"hidden_hint": "局部异常而不是全舱异常，优先检查空气循环。",
		"repair_options": [
			_option("inspect_fan", "检修循环风机", "拆检风机轴承与控制件。", true, 60, {"MT-EL-001": 1}, 0, {}, {}),
			_option("add_oxygen", "提高氧气输出", "试图用更多氧气覆盖局部异常。", false, 0, {}, 30, {}, {"power": {"energy_delta": -3.0}, "water": {"water_delta": -1.0}}),
			_option("patch_seal", "修补舱体密封", "误判为舱体泄漏。", false, 0, {}, 30, {"MT-SE-001": 1}, {}),
		],
		"on_repair_success": {"air": {"co2_percent": -0.06}},
		"unresolved_effect": {"air": {"circulation_penalty": 0.15}},
	},
	"FA-SEAL-001": {
		"display_name": "舱体微裂纹",
		"system": "seal",
		"severity": 2,
		"symptom_text": "舱压缓慢下降，氧气与 CO2 比例没有明显异常。",
		"hidden_hint": "气体比例正常但压力下降，优先检查密封结构。",
		"repair_options": [
			_option("seal_crack", "封补微裂纹", "定位微裂纹并使用密封材料封补。", true, 60, {"MT-SE-001": 1}, 0, {}, {}),
			_option("increase_oxygen", "提高制氧输出", "尝试以制氧抵消压力下降。", false, 0, {}, 30, {}, {"power": {"energy_delta": -3.0}, "water": {"water_delta": -1.0}}),
			_option("replace_filter", "更换 CO2 过滤材料", "误判为空气过滤链路异常。", false, 0, {}, 30, {"MT-FI-001": 1}, {}),
		],
		"on_repair_success": {"base": {"pressure": 2.0}},
		"unresolved_effect": {"base": {"pressure_leak_rate": 0.1}},
	},
	"FA-SEAL-002": {
		"display_name": "气闸密封老化",
		"system": "seal",
		"severity": 3,
		"symptom_text": "每次出舱/返舱后，压力损失都会比预期更高。",
		"hidden_hint": "异常和气闸循环强相关，优先检查气闸密封圈。",
		"repair_options": [
			_option("replace_airlock_seal", "更换气闸密封件", "更换气闸内外门密封材料。", true, 120, {"MT-SE-001": 2}, 0, {}, {}),
			_option("repair_fan", "检修空气循环风机", "误判为循环风机卡滞。", false, 0, {}, 60, {"MT-EL-001": 1}, {}),
			_option("add_inert_gas", "补充惰性气体", "尝试提高惰性气体储备以稳定压力。", false, 0, {}, 60, {"CN-IG-001": 1}, {"base": {"pressure": -1.0}}),
		],
		"on_repair_success": {"base": {"pressure": 3.0}},
		"unresolved_effect": {"base": {"airlock_pressure_loss": 0.18}},
	},
	"FA-THERM-001": {
		"display_name": "温度传感器偏移",
		"system": "thermal",
		"severity": 1,
		"symptom_text": "显示温度出现波动，电力与舱压读数正常。",
		"hidden_hint": "只有显示值波动，其他系统没有同步变化。",
		"repair_options": [
			_option("recalibrate_sensor", "重新校准温度传感器", "执行传感器归零与比对校准。", true, 30, {}, 0, {}, {}),
			_option("add_insulation", "补强隔热材料", "误判为舱体隔热不足。", false, 0, {}, 30, {"MT-IN-001": 1}, {}),
			_option("increase_heat", "提高温控输出", "提高热控功率尝试压制波动。", false, 0, {}, 30, {}, {"power": {"energy_delta": -3.0}}),
		],
		"on_repair_success": {},
		"unresolved_effect": {"thermal": {"sensor_noise": 0.1}},
	},
	"FA-THERM-002": {
		"display_name": "加热单元线路损伤",
		"system": "thermal",
		"severity": 2,
		"symptom_text": "月夜温度持续下降。耗电正常，但加热效果偏弱。",
		"hidden_hint": "耗电正常却发热不足，优先检查线路与隔热。",
		"repair_options": [
			_option("repair_heating_line", "修复加热线路与隔热层", "更换受损隔热材料并检查加热线路。", true, 60, {"MT-IN-001": 1}, 0, {}, {}),
			_option("patch_seal", "封补舱体密封", "误判为舱体漏气导致降温。", false, 0, {}, 30, {"MT-SE-001": 1}, {}),
			_option("replace_filter", "更换过滤材料", "误判为空气过滤导致热交换异常。", false, 0, {}, 30, {"MT-FI-001": 1}, {}),
		],
		"on_repair_success": {"base": {"temperature": 1.2}},
		"unresolved_effect": {"base": {"temperature": -0.6}},
	},
	"FA-THERM-003": {
		"display_name": "散热器卡滞",
		"system": "thermal",
		"severity": 2,
		"symptom_text": "月昼温度偏高，热控耗电上升。",
		"hidden_hint": "高温和热控负载同时出现，优先检查散热器。",
		"repair_options": [
			_option("clean_radiator", "清理并复位散热器", "清理散热器尘积，替换小型金属固定件。", true, 60, {"MT-ME-001": 1}, 0, {}, {}),
			_option("increase_heat", "提高加热功率", "误判为热控输出不足。", false, 0, {}, 30, {}, {"power": {"energy_delta": -3.0}, "base": {"temperature": 0.6}}),
			_option("replace_filter", "更换过滤材料", "误判为空气过滤问题。", false, 0, {}, 30, {"MT-FI-001": 1}, {}),
		],
		"on_repair_success": {"base": {"temperature": -0.8}},
		"unresolved_effect": {"base": {"temperature": 0.8}},
	},
	"FA-WATER-001": {
		"display_name": "水循环过滤器堵塞",
		"system": "water",
		"severity": 2,
		"symptom_text": "水回收率下降，净水消耗异常增加。",
		"hidden_hint": "供水链路还在运行，但回收效率下降。",
		"repair_options": [
			_option("replace_water_filter", "更换水循环过滤材料", "拆换水循环过滤材料并低流量测试。", true, 60, {"MT-FI-001": 1}, 0, {}, {}),
			_option("patch_pipe", "修补管线密封", "误判为管线漏水。", false, 0, {}, 30, {"MT-SE-001": 1}, {}),
			_option("replace_electronics", "更换电子控制件", "误判为泵控电路故障。", false, 0, {}, 30, {"MT-EL-001": 1}, {}),
		],
		"on_repair_success": {"water": {"water_delta": 1.0}},
		"unresolved_effect": {"water": {"recycling_penalty": 0.12}},
	},
	"FA-WATER-002": {
		"display_name": "冰矿处理器加热故障",
		"system": "water",
		"severity": 2,
		"symptom_text": "冰矿储量充足，但转化为可用水的效率下降。",
		"hidden_hint": "原料不缺，问题在处理器加热链路。",
		"repair_options": [
			_option("repair_heater", "修复处理器加热单元", "替换隔热材料并复位加热模块。", true, 60, {"MT-IN-001": 1}, 0, {}, {}),
			_option("replace_filter", "更换过滤材料", "误判为过滤链路堵塞。", false, 0, {}, 30, {"MT-FI-001": 1}, {}),
			_option("replace_metal", "更换结构金属件", "误判为机械结构磨损。", false, 0, {}, 30, {"MT-ME-001": 1}, {}),
		],
		"on_repair_success": {},
		"unresolved_effect": {"water": {"ice_processing_penalty": 0.12}},
	},
	"FA-WATER-003": {
		"display_name": "水管微漏",
		"system": "water",
		"severity": 3,
		"symptom_text": "可用水异常下降，舱压保持正常。",
		"hidden_hint": "水减少但舱压正常，优先检查水管而不是舱体。",
		"repair_options": [
			_option("seal_pipe", "封补水管并更换固定件", "定位水管微漏，使用密封材料和金属件修复。", true, 120, {"MT-SE-001": 1, "MT-ME-001": 1}, 0, {}, {}),
			_option("replace_filter", "更换过滤材料", "误判为水循环过滤器堵塞。", false, 0, {}, 60, {"MT-FI-001": 1}, {}),
			_option("lower_oxygen_power", "降低制氧功率", "误判为制氧耗水异常，尝试降低制氧。", false, 0, {}, 60, {}, {"air": {"o2_percent": -0.4}}),
		],
		"on_repair_success": {"water": {"water_delta": 2.0}},
		"unresolved_effect": {"water": {"water_delta": -2.0}},
	},
	"FA-GH-001": {
		"display_name": "灌溉喷头堵塞",
		"system": "greenhouse",
		"severity": 2,
		"symptom_text": "水储量正常，但植物出现缺水应激。",
		"hidden_hint": "水有储备却到不了植物，优先检查灌溉末端。",
		"repair_options": [
			_option("clean_nozzle", "清理灌溉喷头", "更换喷头过滤材料并低流量复测。", true, 60, {"MT-FI-001": 1}, 0, {}, {}),
			_option("raise_circulation", "提高水循环功率", "通过加压尝试冲开堵塞。", false, 0, {}, 30, {}, {"power": {"energy_delta": -3.0}}),
			_option("increase_light", "提高补光输出", "误判为补光不足导致植物萎蔫。", false, 0, {}, 30, {}, {"power": {"energy_delta": -3.0}}),
		],
		"on_repair_success": {},
		"unresolved_effect": {"greenhouse": {"water_stress": 0.15}},
	},
	"FA-GH-002": {
		"display_name": "补光灯线路故障",
		"system": "greenhouse",
		"severity": 2,
		"symptom_text": "夜间补光设置正常，但植物仍显示缺光症状。",
		"hidden_hint": "设置正常但实际不足，优先检查补光灯线路。",
		"repair_options": [
			_option("repair_light_wiring", "修复补光灯线路", "更换补光灯控制电子件并复测输出。", true, 60, {"MT-EL-001": 1}, 0, {}, {}),
			_option("increase_water", "提高水循环", "误判为水分不足。", false, 0, {}, 30, {}, {"power": {"energy_delta": -3.0}, "water": {"water_delta": -1.0}}),
			_option("replace_substrate", "更换温室基质", "误判为根区基质问题。", false, 0, {}, 30, {"MT-GL-001": 1}, {}),
		],
		"on_repair_success": {},
		"unresolved_effect": {"greenhouse": {"light_stress": 0.15}},
	},
}

static func _option(
	option_id: String,
	display_name: String,
	description: String,
	is_correct: bool,
	time_cost_minutes: int,
	required_items: Dictionary,
	wrong_time_cost_minutes: int,
	wrong_item_loss: Dictionary,
	wrong_extra_effect: Dictionary
) -> Dictionary:
	return {
		"option_id": option_id,
		"display_name": display_name,
		"description": description,
		"is_correct": is_correct,
		"time_cost_minutes": time_cost_minutes,
		"required_items": required_items,
		"wrong_time_cost_minutes": wrong_time_cost_minutes,
		"wrong_item_loss": wrong_item_loss,
		"wrong_extra_effect": wrong_extra_effect,
	}

static func has_fault(fault_id: String) -> bool:
	var faults: Dictionary = _faults()
	return faults.has(fault_id)

static func get_fault(fault_id: String) -> Dictionary:
	var faults: Dictionary = _faults()
	if not faults.has(fault_id):
		return {}
	var fault: Dictionary = faults[fault_id] as Dictionary
	var result: Dictionary = fault.duplicate(true)
	result["fault_id"] = fault_id
	result["is_active"] = true
	return result

static func get_all_fault_ids() -> Array:
	var faults: Dictionary = _faults()
	return faults.keys()
