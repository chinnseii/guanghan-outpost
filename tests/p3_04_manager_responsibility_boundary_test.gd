extends SceneTree

const SAVE_PATHS := [
	"user://saves/time_state.json",
	"user://saves/training_time_state.json",
	"user://saves/health_state.json",
	"user://saves/base_status_state.json",
	"user://saves/power_system_state.json",
	"user://saves/water_system_state.json",
	"user://saves/air_system_state.json",
	"user://saves/inventory_state.json",
	"user://saves/backpack_state.json",
	"user://saves/storage_state.json",
	"user://saves/suit_state.json",
	"user://saves/supply_state.json",
	"user://saves/plant_growth_state.json",
	"user://saves/training_progress.json",
]

var checks := 0
var failed := 0
var file_backups: Dictionary = {}

func _init() -> void:
	await process_frame
	_backup_files()
	_run()
	_restore_files()
	print("[P3-04] checks=%d passed=%d failed=%d" % [checks, checks - failed, failed])
	if failed > 0:
		quit(1)
	else:
		print("[P3-04] ALL PASS")
		quit(0)

func _run() -> void:
	_check_inventory_backpack_storage_boundaries()
	_check_time_boundaries()
	_check_mirror_boundaries()
	_check_door_boundaries()
	_check_static_no_direct_cross_writes()

func _check_inventory_backpack_storage_boundaries() -> void:
	var inventory := _manager("InventoryManager")
	var backpack := _manager("BackpackManager")
	var storage := _manager("StorageManager")
	inventory.call("deserialize", {
		"stack_items": {"MT-ME-001": 3},
		"durable_items": {},
		"last_durable_instance_id": "",
		"next_durable_instance_number": 1,
	})
	backpack.call("deserialize", {
		"backpack_level": 1,
		"backpack_capacity_slots": 2,
		"slots": [{"item_id": "MT-ME-001", "quantity": 5, "instance_id": ""}, null],
		"last_durable_instance_id": "",
		"next_durable_instance_number": 1,
	})
	storage.call("deserialize", {
		"storage_level": 1,
		"storage_capacity_slots": 2,
		"slots": [null, null],
		"last_durable_instance_id": "",
		"next_durable_instance_number": 1,
	})
	var before_total := _slot_total("MT-ME-001")
	var to_storage: Dictionary = backpack.call("transfer_slot_to_storage", 0)
	_expect(int(to_storage.get("accepted", 0)) == 5, "Backpack -> Storage transfer accepts moved quantity")
	_expect(String(to_storage.get("source", "")) == "backpack" and String(to_storage.get("destination", "")) == "storage", "Backpack transfer result names both owners")
	_expect(backpack.call("get_item_count", "MT-ME-001") == 0 and storage.call("get_item_count", "MT-ME-001") == 5, "Backpack -> Storage moves only slot owners")
	_expect(_slot_total("MT-ME-001") == before_total, "Backpack -> Storage does not duplicate slot quantity")
	_expect(inventory.call("get_item_count", "MT-ME-001") == 3, "Inventory quantity ledger is unchanged by slot transfer")
	var to_backpack: Dictionary = storage.call("transfer_slot_to_backpack", 0, 2)
	_expect(int(to_backpack.get("accepted", 0)) == 2, "Storage -> Backpack partial transfer accepts requested quantity")
	_expect(String(to_backpack.get("source", "")) == "storage" and String(to_backpack.get("destination", "")) == "backpack", "Storage transfer result names both owners")
	_expect(backpack.call("get_item_count", "MT-ME-001") == 2 and storage.call("get_item_count", "MT-ME-001") == 3, "Storage -> Backpack moves only slot owners")
	_expect(_slot_total("MT-ME-001") == before_total, "Storage -> Backpack does not duplicate slot quantity")
	var restored_backpack: Dictionary = backpack.call("serialize")
	var restored_storage: Dictionary = storage.call("serialize")
	backpack.call("deserialize", restored_backpack)
	storage.call("deserialize", restored_storage)
	_expect(_slot_total("MT-ME-001") == before_total, "Slot ledgers remain consistent after serialize/restore")
	backpack.call("deserialize", {
		"backpack_level": 1,
		"backpack_capacity_slots": 1,
		"slots": [{"item_id": "FO-CR-001", "quantity": 1, "instance_id": ""}],
		"last_durable_instance_id": "",
		"next_durable_instance_number": 1,
	})
	storage.call("deserialize", {
		"storage_level": 1,
		"storage_capacity_slots": 1,
		"slots": [{"item_id": "MT-EL-001", "quantity": 1, "instance_id": ""}],
		"last_durable_instance_id": "",
		"next_durable_instance_number": 1,
	})
	var full_result: Dictionary = backpack.call("transfer_slot_to_storage", 0)
	_expect(int(full_result.get("accepted", 0)) == 0 and bool(full_result.get("rolled_back", false)), "Full target rolls back Backpack -> Storage transfer")
	_expect(backpack.call("get_item_count", "FO-CR-001") == 1 and storage.call("get_item_count", "MT-EL-001") == 1, "Rollback preserves both ledgers")
	backpack.call("deserialize", {
		"backpack_level": 1,
		"backpack_capacity_slots": 2,
		"slots": [{"item_id": "FO-CR-001", "quantity": 2, "instance_id": ""}, null],
		"last_durable_instance_id": "",
		"next_durable_instance_number": 1,
	})
	storage.call("deserialize", {
		"storage_level": 1,
		"storage_capacity_slots": 2,
		"slots": [{"item_id": "FO-CR-001", "quantity": 2, "instance_id": ""}, null],
		"last_durable_instance_id": "",
		"next_durable_instance_number": 1,
	})
	backpack.call("remove_item", "FO-CR-001", 1)
	_expect(backpack.call("get_item_count", "FO-CR-001") == 1 and storage.call("get_item_count", "FO-CR-001") == 2, "Backpack consumption source is explicit")
	storage.call("remove_item", "FO-CR-001", 1)
	_expect(backpack.call("get_item_count", "FO-CR-001") == 1 and storage.call("get_item_count", "FO-CR-001") == 1, "Storage consumption source is explicit")

func _check_time_boundaries() -> void:
	var time := _manager("TimeManager")
	var training_time := _manager("TrainingTimeManager")
	var movement := _manager("MovementTimeManager")
	var suit := _manager("SuitManager")
	time.call("deserialize", {
		"total_minutes": 100,
		"current_day": 1,
		"hour": 8,
		"minute": 20,
		"lunar_phase": "night_late",
		"minutes_until_phase_change": 100,
	})
	training_time.call("deserialize", {
		"archive_limit_minutes": 480,
		"elapsed_minutes": 10,
		"remaining_minutes": 470,
		"training_time_active": true,
		"training_time_paused": false,
		"time_log": [],
	})
	movement.call("reset_to_arrival")
	movement.call("on_player_moved_tiles", 10, "indoor", "mission")
	_expect(int(time.get("total_minutes")) == 101 and int(training_time.get("elapsed_minutes")) == 10, "Mission movement advances TimeManager only")
	movement.call("reset_to_arrival")
	movement.call("on_player_moved_tiles", 10, "indoor", "training")
	_expect(int(time.get("total_minutes")) == 101 and int(training_time.get("elapsed_minutes")) == 11, "Training movement advances TrainingTimeManager only")
	suit.call("deserialize", {
		"is_suit_worn": false,
		"suit_storage_state": "ready",
		"suit_level": 1,
		"suit_oxygen": 100.0,
		"suit_oxygen_capacity": 100.0,
		"suit_power": 100.0,
		"suit_power_capacity": 100.0,
		"suit_speed_multiplier": 0.8,
	})
	var formal_before := int(time.get("total_minutes"))
	var training_before := int(training_time.get("elapsed_minutes"))
	var worn_training: bool = suit.call("wear_suit_training")
	_expect(worn_training and int(training_time.get("elapsed_minutes")) == training_before + 15 and int(time.get("total_minutes")) == formal_before, "Training suit wear uses TrainingTimeManager")
	suit.call("deserialize", {
		"is_suit_worn": false,
		"suit_storage_state": "ready",
		"suit_level": 1,
		"suit_oxygen": 100.0,
		"suit_oxygen_capacity": 100.0,
		"suit_power": 100.0,
		"suit_power_capacity": 100.0,
		"suit_speed_multiplier": 0.8,
	})
	formal_before = int(time.get("total_minutes"))
	training_before = int(training_time.get("elapsed_minutes"))
	var worn_mission: bool = suit.call("wear_suit")
	_expect(worn_mission and int(time.get("total_minutes")) == formal_before + 15 and int(training_time.get("elapsed_minutes")) == training_before, "Mission suit wear uses TimeManager")
	var repair_source := _read_text("res://scripts/managers/RepairManager.gd")
	_expect(repair_source.contains("context == \"training\"") and repair_source.contains("_advance_training_time") and repair_source.contains("_advance_time"), "RepairManager keeps explicit training/formal clock branches")

func _check_mirror_boundaries() -> void:
	var base := _manager("BaseStatusManager")
	var power := _manager("PowerSystemManager")
	var air := _manager("AirSystemManager")
	var suit := _manager("SuitManager")
	var player := _manager("PlayerStateManager")
	power.call("deserialize", {
		"current_energy": 60.0,
		"base_battery_capacity": 120.0,
		"battery_capacity": 120.0,
		"battery_module_count": 2,
		"solar_panel_count": 2,
		"solar_array_status": 1,
		"storage_efficiency": 1.0,
		"charging_efficiency": 1.0,
		"current_power_mode": "standard",
	})
	_expect(abs(float(base.call("get_power_mirror_percent")) - 50.0) < 0.001, "PowerSystem syncs BaseStatus power mirror")
	base.call("set_power_percent", 7.0)
	_expect(abs(float(power.call("get_power_percent")) - 50.0) < 0.001, "BaseStatus mirror write does not overwrite canonical power")
	power.call("deserialize", power.call("serialize"))
	_expect(abs(float(base.call("get_power_mirror_percent")) - 50.0) < 0.001, "Canonical power can resync mirror after mirror-only write")
	var base_before: Dictionary = base.call("serialize")
	var air_state: Dictionary = air.call("serialize")
	air_state["o2_percent"] = 19.0
	air.call("deserialize", air_state)
	_expect((base.call("serialize") as Dictionary) == base_before, "AirSystem oxygen restore does not write BaseStatus summary")
	suit.call("deserialize", {
		"is_suit_worn": true,
		"suit_storage_state": "worn",
		"suit_level": 1,
		"suit_oxygen": 100.0,
		"suit_oxygen_capacity": 100.0,
		"suit_power": 100.0,
		"suit_power_capacity": 100.0,
		"suit_speed_multiplier": 0.8,
	})
	_expect(bool(player.get("is_suit_worn")), "SuitManager syncs PlayerState suit mirror")
	player.call("set_suit_worn", false)
	_expect(bool(suit.get("is_suit_worn")), "PlayerState mirror write does not overwrite canonical suit state")
	suit.call("deserialize", suit.call("serialize"))
	_expect(bool(player.get("is_suit_worn")) == bool(suit.get("is_suit_worn")), "Canonical suit can resync PlayerState mirror")

func _check_door_boundaries() -> void:
	var door_source := _read_text("res://scripts/managers/DoorStateManager.gd")
	var training_map_source := _read_text("res://scripts/training/training_base_map.gd")
	_expect(training_map_source.contains("DoorStateManager") and training_map_source.contains("try_pass_door"), "Training map is connected to DoorStateManager")
	_expect(_base_scripts_with_door_manager_refs().is_empty(), "Formal base scripts are not connected to DoorStateManager")
	_expect(door_source.contains("register_door") and door_source.contains("try_pass_door"), "DoorStateManager remains the registered training-door state owner")

func _check_static_no_direct_cross_writes() -> void:
	var power_source := _read_text("res://scripts/managers/PowerSystemManager.gd")
	var base_source := _read_text("res://scripts/managers/BaseStatusManager.gd")
	var suit_source := _read_text("res://scripts/managers/SuitManager.gd")
	var player_source := _read_text("res://scripts/managers/PlayerStateManager.gd")
	_expect(power_source.contains("sync_power_mirror_from_power_system"), "PowerSystemManager uses mirror-specific BaseStatus API")
	_expect(base_source.contains("sync_power_mirror_from_power_system") and base_source.contains("Compatibility wrapper"), "BaseStatus power API documents mirror ownership")
	_expect(suit_source.contains("sync_suit_worn_mirror_from_suit_manager"), "SuitManager uses mirror-specific PlayerState API")
	_expect(player_source.contains("sync_suit_worn_mirror_from_suit_manager") and player_source.contains("canonical write entry"), "PlayerState suit API documents mirror ownership")

func _slot_total(item_id: String) -> int:
	return int(_manager("BackpackManager").call("get_item_count", item_id)) + int(_manager("StorageManager").call("get_item_count", item_id))

func _manager(name: String) -> Node:
	return root.get_node_or_null(name)

func _backup_files() -> void:
	for path in SAVE_PATHS:
		file_backups[path] = {
			"exists": FileAccess.file_exists(path),
			"text": FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "",
		}

func _restore_files() -> void:
	for path in SAVE_PATHS:
		var backup: Dictionary = file_backups.get(path, {})
		if bool(backup.get("exists", false)):
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string(String(backup.get("text", "")))
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	file_backups.clear()

func _base_scripts_with_door_manager_refs() -> Array[String]:
	var result: Array[String] = []
	for path in _script_paths("res://scripts/base"):
		var source := _read_text(path)
		if source.contains("DoorStateManager"):
			result.append(path)
	return result

func _script_paths(path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry.is_empty():
			break
		if entry.begins_with("."):
			continue
		var child := "%s/%s" % [path, entry]
		if dir.current_is_dir():
			result.append_array(_script_paths(child))
		elif entry.ends_with(".gd"):
			result.append(child)
	dir.list_dir_end()
	return result

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("[P3-04] PASS: %s" % label)
	else:
		failed += 1
		push_error("[P3-04] FAIL: %s" % label)
