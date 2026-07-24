extends Node
class_name GuanghanWorldStateManager

## Persists the procedural-chunk-world prototype's world identity and player
## deltas (see docs/design/LUNAR_SURFACE_MAP.md's approved hand-authored
## surface for the OTHER, currently-shipping surface system -- this manager
## is for the separate, additive chunk-generation prototype; see plan
## abstract-hopping-moonbeam.md). Follows the same per-manager save pattern
## as every other manager (BackpackManager.gd is the reference): own
## SAVE_PATH, serialize()/deserialize(), load_state() in _ready() guarded by
## FullSaveOrchestrator.should_skip_manager_local_restore(), _save_state()
## called at the end of every mutating method.
##
## world_seed is generated with a real RandomNumberGenerator exactly once,
## the first time this manager ever loads with no existing save file -- this
## is the ONE place in the whole procedural-world feature allowed to use
## non-deterministic randomness. Every chunk's actual content is then a pure
## function of (world_seed, chunk_x, chunk_y) via WorldGenerator.gd.

const FullSaveOrchestratorScript := preload("res://scripts/systems/full_save_orchestrator.gd")

const SAVE_PATH := "user://saves/world_state.json"

var world_seed: int = 0
var player_position: Vector2 = Vector2.ZERO
## Dictionary-as-set: chunk_key ("x_y") -> true.
var discovered_chunks: Dictionary = {}
## chunk_key ("x_y") -> {depleted_node_ids: Array[String], structures: Array[Dictionary],
## removed_structures: Array[String], events_triggered: Array[String]}.
var modified_chunks: Dictionary = {}

func _ready() -> void:
	load_state()

func chunk_key(chunk_x: int, chunk_y: int) -> String:
	return "%d_%d" % [chunk_x, chunk_y]

func get_world_seed() -> int:
	return world_seed

## Returns a COPY with every expected sub-key present -- callers never get a
## live reference to the internal modified_chunks entry (same discipline as
## near_base_chunk.gd's world-space getters).
func get_modifications_for_chunk(key: String) -> Dictionary:
	var raw: Variant = modified_chunks.get(key, {})
	var entry: Dictionary = (raw as Dictionary).duplicate(true) if raw is Dictionary else {}
	entry["depleted_node_ids"] = entry.get("depleted_node_ids", [])
	entry["structures"] = entry.get("structures", [])
	entry["removed_structures"] = entry.get("removed_structures", [])
	entry["events_triggered"] = entry.get("events_triggered", [])
	return entry

func mark_chunk_discovered(key: String) -> void:
	if discovered_chunks.has(key):
		return
	discovered_chunks[key] = true
	_save_state()

func record_node_depleted(key: String, node_id: String) -> void:
	var entry: Dictionary = modified_chunks.get(key, {})
	var ids: Array = entry.get("depleted_node_ids", [])
	if not ids.has(node_id):
		ids.append(node_id)
	entry["depleted_node_ids"] = ids
	modified_chunks[key] = entry
	_save_state()

func record_structure_placed(key: String, structure: Dictionary) -> void:
	var entry: Dictionary = modified_chunks.get(key, {})
	var structures: Array = entry.get("structures", [])
	structures.append(structure.duplicate(true))
	entry["structures"] = structures
	modified_chunks[key] = entry
	_save_state()

## Called only on chunk-boundary crossings (see ChunkManager.update()) or an
## explicit checkpoint -- NEVER per-frame, since this synchronously writes a
## JSON file to disk.
func set_player_position(pos: Vector2) -> void:
	player_position = pos
	_save_state()

func serialize() -> Dictionary:
	return {
		"world_seed": world_seed,
		"player_position": {"x": player_position.x, "y": player_position.y},
		"discovered_chunks": discovered_chunks.keys(),
		"modified_chunks": modified_chunks.duplicate(true),
	}

func deserialize(data: Dictionary) -> void:
	world_seed = int(data.get("world_seed", world_seed))
	var pos: Dictionary = data.get("player_position", {})
	player_position = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
	discovered_chunks = {}
	for key in data.get("discovered_chunks", []):
		discovered_chunks[String(key)] = true
	var raw_modified: Variant = data.get("modified_chunks", {})
	modified_chunks = (raw_modified as Dictionary).duplicate(true) if raw_modified is Dictionary else {}

func load_state() -> void:
	if FullSaveOrchestratorScript.should_skip_manager_local_restore():
		return
	if not FileAccess.file_exists(SAVE_PATH):
		_generate_new_world_seed()
		_save_state()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_generate_new_world_seed()
		_save_state()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_generate_new_world_seed()
		_save_state()
		return
	deserialize(parsed as Dictionary)

func _generate_new_world_seed() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	world_seed = rng.randi()

func _save_state() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(serialize(), "\t"))
