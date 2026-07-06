extends Node

## EVA suit system v1: wear/remove flow, the suit's own independent
## oxygen/power reserves, a speed penalty that eases with upgrades, and a
## maintenance-slot refill/recharge loop that draws on the base's real
## water/power. Explicitly out of scope this round (see the dev spec):
## part-level suit damage, multiple suits, random suit failures, combat
## modules, and any speed multiplier above 1.0.

signal suit_changed

const SAVE_PATH := "user://saves/suit_state.json"

const SUIT_LEVEL_NAMES := {
	1: "初代舱外服",
	2: "关节助力改良",
	3: "平衡负载结构",
	4: "低阻力外勤服",
	5: "完整外勤升级",
}

const SUIT_LEVEL_SPEED := {
	1: 0.80,
	2: 0.85,
	3: 0.90,
	4: 0.95,
	5: 1.00,
}

const MAX_SUIT_LEVEL := 5

## Per-hour suit oxygen/power drain while worn, by activity intensity.
const ACTIVITY_RATES := {
	"indoor_worn": {"oxygen": 3.0, "power": 2.0},
	"eva_normal": {"oxygen": 8.0, "power": 6.0},
	"eva_heavy": {"oxygen": 12.0, "power": 10.0},
}
const DEFAULT_ACTIVITY := "eva_normal"

const MIN_EVA_OXYGEN := 20.0
const MIN_EVA_POWER := 20.0

## Every point of suit_oxygen refilled costs this much base water/power;
## every point of suit_power recharged costs this much base power. A fully
## drained suit (0/0) costs ~1.0 W water + 5.0 E power to fully service
## (100 * 0.01 + 100 * 0.02 + 100 * 0.03), matching the design target of
## "noticeable but not punishing".
const OXYGEN_REFILL_WATER_PER_POINT := 0.01
const OXYGEN_REFILL_POWER_PER_POINT := 0.02
const POWER_RECHARGE_PER_POINT := 0.03

var is_suit_worn: bool = false
## ready = serviced, can be worn / worn = currently worn / carried = taken
## off but not yet racked in the service station (reserved for a future,
## more granular flow -- v1's only transition is the atomic
## remove_suit_to_service_station(), which goes straight from worn to
## servicing) / servicing = in the maintenance slot, refilling.
var suit_storage_state: String = "ready"
var suit_level: int = 1
var suit_oxygen: float = 100.0
var suit_oxygen_capacity: float = 100.0
var suit_power: float = 100.0
var suit_power_capacity: float = 100.0
var suit_speed_multiplier: float = 0.8
var wear_time_minutes: int = 15
var remove_to_station_time_minutes: int = 15
## Decorative/display-only in v1 (see the 宇航服整备室 training-room spec) --
## nothing currently reads these to gate anything; they exist so the status
## panel can show a complete picture (oxygen/power/seal/comm/speed).
var suit_seal_status: String = "normal"
var suit_comm_status: String = "online"

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	is_suit_worn = false
	suit_storage_state = "ready"
	suit_level = 1
	suit_oxygen = 100.0
	suit_oxygen_capacity = 100.0
	suit_power = 100.0
	suit_power_capacity = 100.0
	update_suit_speed_multiplier()
	wear_time_minutes = 15
	remove_to_station_time_minutes = 15
	suit_seal_status = "normal"
	suit_comm_status = "online"
	_save_state()
	suit_changed.emit()

## -- Wear / remove flow

func wear_suit() -> bool:
	if suit_storage_state != "ready":
		return false
	_advance_time(wear_time_minutes, "wear_spacesuit")
	is_suit_worn = true
	suit_storage_state = "worn"
	_save_state()
	suit_changed.emit()
	return true

## Training-only variant of wear_suit(): advances TrainingTimeManager
## instead of the real TimeManager, per the 宇航服整备室 training-room spec
## (training must never touch the official mission clock). Same gating and
## side effects on is_suit_worn/suit_storage_state as wear_suit() -- this is
## the same shared SuitManager/suit state used by the real mission, not a
## separate training copy (see the design doc for why: keeping one shared
## instance was judged simpler than a parallel TrainingSuitState, as long as
## the mission resets SuitManager before Day 01 -- reset_to_arrival() already
## does this whenever TrainingManager.reset_progress() or the real mission
## start flow calls it).
func wear_suit_training() -> bool:
	if is_suit_worn:
		return false
	if suit_storage_state != "ready":
		return false
	var training_time_manager := _training_time_manager()
	if training_time_manager == null or not training_time_manager.has_method("advance_training_time"):
		return false
	training_time_manager.call("advance_training_time", wear_time_minutes, "training_wear_spacesuit")
	is_suit_worn = true
	suit_storage_state = "worn"
	_save_state()
	suit_changed.emit()
	return true

func remove_suit_to_service_station() -> bool:
	if not is_suit_worn:
		return false
	_advance_time(remove_to_station_time_minutes, "remove_suit_to_service_station")
	is_suit_worn = false
	suit_storage_state = "servicing"
	_save_state()
	suit_changed.emit()
	return true

## -- EVA gating

## Suit must be worn, maintained (not mid-service), and have at least the
## minimum oxygen/power reserve to start an ordinary EVA. Does not itself
## block or kill the player if oxygen/power hits 0 mid-EVA -- that's for
## whatever excursion system calls this to react to (per the spec: SuitManager
## only reports numbers and state, it doesn't decide emergency-return logic).
func can_start_eva() -> bool:
	return is_suit_worn and suit_oxygen >= MIN_EVA_OXYGEN and suit_power >= MIN_EVA_POWER

func is_suit_ready() -> bool:
	return suit_storage_state == "ready"

## -- Resource drain while worn

func consume_suit_resources(minutes: int, activity_type: String = DEFAULT_ACTIVITY) -> void:
	if not is_suit_worn:
		return
	if minutes <= 0:
		return
	var rates: Dictionary = ACTIVITY_RATES.get(activity_type, ACTIVITY_RATES[DEFAULT_ACTIVITY])
	var oxygen_rate: float = float(rates.get("oxygen", 8.0))
	var power_rate: float = float(rates.get("power", 6.0))
	var oxygen_cost: float = float(minutes) / 60.0 * oxygen_rate
	var power_cost: float = float(minutes) / 60.0 * power_rate
	suit_oxygen = max(suit_oxygen - oxygen_cost, 0.0)
	suit_power = max(suit_power - power_cost, 0.0)
	_save_state()
	suit_changed.emit()

## Fixed-amount drain for a single costed action (e.g. a training
## inspection/repair step), as opposed to consume_suit_resources()'s
## per-hour rate. Same "no-op if not worn" guard, but returns false in that
## case so a caller building a training result dict can tell the
## deduction didn't happen (consume_suit_resources() is void and used in a
## fire-and-forget context, so it didn't need this).
func consume_suit_resource_fixed(oxygen_cost: float, power_cost: float, reason: String = "") -> bool:
	if not is_suit_worn:
		return false
	suit_oxygen = max(suit_oxygen - oxygen_cost, 0.0)
	suit_power = max(suit_power - power_cost, 0.0)
	_save_state()
	suit_changed.emit()
	return true

## -- Speed multiplier / upgrades

func get_suit_speed_multiplier() -> float:
	return suit_speed_multiplier

## actual_minutes = base_minutes / suit_speed_multiplier, per the spec --
## call this before advancing time/consuming suit resources for a suit-worn
## action, so both use the same real-world-slower duration.
func get_actual_minutes(base_minutes: int) -> int:
	if suit_speed_multiplier <= 0.0:
		return base_minutes
	return int(ceil(float(base_minutes) / suit_speed_multiplier))

func upgrade_suit_speed() -> bool:
	if suit_level >= MAX_SUIT_LEVEL:
		return false
	suit_level += 1
	update_suit_speed_multiplier()
	_save_state()
	suit_changed.emit()
	return true

func update_suit_speed_multiplier() -> void:
	suit_speed_multiplier = float(SUIT_LEVEL_SPEED.get(suit_level, 0.8))
	suit_speed_multiplier = min(suit_speed_multiplier, 1.0)

func get_suit_level_name() -> String:
	return String(SUIT_LEVEL_NAMES.get(suit_level, "初代舱外服"))

## -- Maintenance slot: refill oxygen, recharge power, full service

func refill_suit_oxygen() -> bool:
	var missing_oxygen: float = suit_oxygen_capacity - suit_oxygen
	if missing_oxygen <= 0.0:
		return true
	var water_cost: float = missing_oxygen * OXYGEN_REFILL_WATER_PER_POINT
	var power_cost: float = missing_oxygen * OXYGEN_REFILL_POWER_PER_POINT
	var water_manager := _water_system_manager()
	var power_manager := _power_system_manager()
	if water_manager == null or float(water_manager.get("current_water")) < water_cost:
		return false
	if power_manager == null or float(power_manager.get("current_energy")) < power_cost:
		return false
	if not bool(water_manager.call("consume_water_checked", water_cost, "refill_suit_oxygen")):
		return false
	if not bool(power_manager.call("consume_energy_checked", power_cost, "refill_suit_oxygen")):
		return false
	suit_oxygen = suit_oxygen_capacity
	_save_state()
	suit_changed.emit()
	return true

func recharge_suit_power() -> bool:
	var missing_power: float = suit_power_capacity - suit_power
	if missing_power <= 0.0:
		return true
	var power_cost: float = missing_power * POWER_RECHARGE_PER_POINT
	var power_manager := _power_system_manager()
	if power_manager == null or float(power_manager.get("current_energy")) < power_cost:
		return false
	if not bool(power_manager.call("consume_energy_checked", power_cost, "recharge_suit_power")):
		return false
	suit_power = suit_power_capacity
	_save_state()
	suit_changed.emit()
	return true

## Upfront combined check so service_suit_full() never partially spends --
## checks the total water/power bill before either refill_suit_oxygen() or
## recharge_suit_power() touches anything.
func can_service_suit_full() -> bool:
	var missing_oxygen: float = suit_oxygen_capacity - suit_oxygen
	var missing_power: float = suit_power_capacity - suit_power
	var water_cost: float = missing_oxygen * OXYGEN_REFILL_WATER_PER_POINT
	var power_cost: float = missing_oxygen * OXYGEN_REFILL_POWER_PER_POINT + missing_power * POWER_RECHARGE_PER_POINT
	var water_manager := _water_system_manager()
	var power_manager := _power_system_manager()
	if water_manager == null or float(water_manager.get("current_water")) < water_cost:
		return false
	if power_manager == null or float(power_manager.get("current_energy")) < power_cost:
		return false
	return true

## Full maintenance pass: only actually spends anything if the combined
## check above passes, so a failed service never leaves the suit
## half-refilled or the base half-charged. Does not advance time -- per the
## spec, remove_suit_to_service_station()'s 15 minutes already covers the
## hand-off, and re-adding a service duration would double-charge time for
## no stated gameplay reason this round.
func service_suit_full() -> bool:
	if suit_storage_state != "servicing":
		return false
	if not can_service_suit_full():
		return false
	if not refill_suit_oxygen():
		return false
	if not recharge_suit_power():
		return false
	suit_storage_state = "ready"
	_save_state()
	suit_changed.emit()
	return true

## -- Display

func get_status_label() -> String:
	match suit_storage_state:
		"ready":
			return "已维护"
		"worn":
			return "穿戴中"
		"carried":
			return "已脱下（未挂入维护位）"
		"servicing":
			return "维护中"
	return suit_storage_state

func _seal_label() -> String:
	if suit_seal_status == "normal":
		return "正常"
	return suit_seal_status

func _comm_label() -> String:
	if suit_comm_status == "online":
		return "在线"
	return suit_comm_status

## Snapshot for UI code that wants all five status readouts in one call
## (oxygen/power/seal/comm/speed) instead of reading fields individually --
## used by the 宇航服整备室 training-room's status panel, but generic enough
## for any future suit UI.
func get_suit_status_for_ui() -> Dictionary:
	return {
		"oxygen": suit_oxygen,
		"oxygen_capacity": suit_oxygen_capacity,
		"power": suit_power,
		"power_capacity": suit_power_capacity,
		"seal_status": suit_seal_status,
		"comm_status": suit_comm_status,
		"speed_multiplier": suit_speed_multiplier,
	}

func panel_status_text() -> String:
	var lines: Array[String] = [
		"宇航服状态：%s · 氧气 %.0f/%.0f · 电力 %.0f/%.0f" % [
			get_status_label(), suit_oxygen, suit_oxygen_capacity, suit_power, suit_power_capacity,
		],
		"密封：%s · 通信：%s · 行动速度倍率：%.2f（%s）" % [
			_seal_label(), _comm_label(), suit_speed_multiplier, get_suit_level_name(),
		],
	]
	if suit_storage_state == "servicing":
		var missing_oxygen: float = suit_oxygen_capacity - suit_oxygen
		var missing_power: float = suit_power_capacity - suit_power
		var water_cost: float = missing_oxygen * OXYGEN_REFILL_WATER_PER_POINT
		var power_cost: float = missing_oxygen * OXYGEN_REFILL_POWER_PER_POINT + missing_power * POWER_RECHARGE_PER_POINT
		lines.append("预计补给消耗：水 %.2f W · 电力 %.2f E" % [water_cost, power_cost])
		if not can_service_suit_full():
			lines.append("基地资源不足，无法完成宇航服维护。")
	return "\n".join(lines)

func compact_hud_text() -> String:
	return "宇航服 %s｜O2 %.0f · E %.0f" % [get_status_label(), suit_oxygen, suit_power]

## -- Cross-system helpers

func _time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TimeManager")

func _water_system_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("WaterSystemManager")

func _power_system_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PowerSystemManager")

func _training_time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TrainingTimeManager")

func _advance_time(minutes: int, reason: String) -> void:
	if minutes <= 0:
		return
	var manager := _time_manager()
	if manager == null or not manager.has_method("advance_time"):
		return
	manager.call("advance_time", minutes, reason)

## -- Debug helpers

func debug_values_text() -> String:
	return "\n".join([
		"SuitManager: worn=%s state=%s level=%d(%s)" % [
			is_suit_worn, suit_storage_state, suit_level, get_suit_level_name(),
		],
		"oxygen=%.1f/%.1f power=%.1f/%.1f speed=%.2f" % [
			suit_oxygen, suit_oxygen_capacity, suit_power, suit_power_capacity, suit_speed_multiplier,
		],
	])

func debug_wear_suit() -> void:
	wear_suit()

func debug_remove_suit() -> void:
	remove_suit_to_service_station()

func debug_service_suit_full() -> void:
	service_suit_full()

func debug_upgrade_suit() -> void:
	upgrade_suit_speed()

func debug_drain_suit(minutes: int = 60, activity_type: String = DEFAULT_ACTIVITY) -> void:
	consume_suit_resources(minutes, activity_type)

func debug_simulate_eva_action(base_minutes: int = 60, activity_type: String = DEFAULT_ACTIVITY) -> bool:
	if not can_start_eva():
		return false
	var actual_minutes := get_actual_minutes(base_minutes)
	_advance_time(actual_minutes, activity_type)
	consume_suit_resources(actual_minutes, activity_type)
	return true

func debug_empty_suit_reserves() -> void:
	suit_oxygen = 0.0
	suit_power = 0.0
	_save_state()
	suit_changed.emit()

## -- Persistence

func serialize() -> Dictionary:
	return {
		"is_suit_worn": is_suit_worn,
		"suit_storage_state": suit_storage_state,
		"suit_level": suit_level,
		"suit_oxygen": suit_oxygen,
		"suit_oxygen_capacity": suit_oxygen_capacity,
		"suit_power": suit_power,
		"suit_power_capacity": suit_power_capacity,
		"suit_speed_multiplier": suit_speed_multiplier,
		"suit_seal_status": suit_seal_status,
		"suit_comm_status": suit_comm_status,
	}

func deserialize(data: Dictionary) -> void:
	is_suit_worn = bool(data.get("is_suit_worn", is_suit_worn))
	suit_storage_state = String(data.get("suit_storage_state", suit_storage_state))
	suit_level = int(data.get("suit_level", suit_level))
	suit_oxygen = float(data.get("suit_oxygen", suit_oxygen))
	suit_oxygen_capacity = float(data.get("suit_oxygen_capacity", suit_oxygen_capacity))
	suit_power = float(data.get("suit_power", suit_power))
	suit_power_capacity = float(data.get("suit_power_capacity", suit_power_capacity))
	suit_speed_multiplier = float(data.get("suit_speed_multiplier", suit_speed_multiplier))
	suit_seal_status = String(data.get("suit_seal_status", suit_seal_status))
	suit_comm_status = String(data.get("suit_comm_status", suit_comm_status))
	suit_changed.emit()

func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	deserialize(parsed as Dictionary)

func save_state() -> void:
	_save_state()

func _save_state() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(serialize(), "\t"))
