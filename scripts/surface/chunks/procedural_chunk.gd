extends Node2D

## Generic procedurally-generated chunk (prototype). Companion to
## near_base_chunk.gd, but reusable/data-driven rather than a single
## hand-authored instance: the SAME scene is instantiated once per grid
## coordinate by ChunkManager.gd, with world_seed/chunk_x/chunk_y set on the
## instance before add_child(). See plan abstract-hopping-moonbeam.md and
## scripts/world/WorldGenerator.gd for the generation contract this consumes.
##
## Unlike near_base_chunk.gd (a singleton chunk that deliberately keeps its
## Node2D transform at (0,0) to avoid ever double-offsetting a fixed
## CHUNK_ORIGIN authored once in source), this scene is instantiated many
## times at different coordinates, so setting this node's own `position` to
## chunk_origin at spawn time is the simpler, idiomatic choice here -- child
## visuals are authored in plain local chunk-space (0,0 .. CHUNK_PX,CHUNK_PX).
## The world-space contract getters (get_bounds() etc.) still compute their
## own values from chunk_origin independently, for callers that need
## world-space without caring about this node's transform.
##
## Generation-layer / player-delta-layer separation (the core requirement):
## WorldGenerator.generate_chunk()'s output is recomputed fresh every time
## this chunk is mounted and is NEVER written to disk anywhere. Only
## WorldStateManager.modified_chunks (depleted node ids, placed structure
## stubs) is persisted -- so unloading/reloading this chunk always
## reproduces identical base content, with only the player's own changes
## surviving on top of it.

const WorldGeneratorScript := preload("res://scripts/world/WorldGenerator.gd")

const TILE := 64
const CHUNK_TILES := Vector2i(48, 48)
const CHUNK_PX := float(CHUNK_TILES.x) * float(TILE)

const TERRAIN_COLORS := {
	"flat": Color("#2a3138"),
	"rocky": Color("#23282d"),
	"crater": Color("#1a1e22"),
}
const RESOURCE_COLORS := {
	"ore": Color("#6b5a4a"),
	"moon_rock": Color("#9a9a8c"),
}
const RESOURCE_LABELS := {
	"ore": "矿石",
	"moon_rock": "月岩",
}
const HARVEST_ITEM_ID := "MT-OR-001"

## Set by ChunkManager before add_child() so _ready() sees them.
var world_seed: int = 0
var chunk_x: int = 0
var chunk_y: int = 0

var chunk_origin: Vector2 = Vector2.ZERO
var _chunk_key: String = ""
## node_id -> {type, local_position, yield_amount, marker, label}
var _active_nodes: Dictionary = {}

func _ready() -> void:
	chunk_origin = Vector2(float(chunk_x) * CHUNK_PX, float(chunk_y) * CHUNK_PX)
	position = chunk_origin
	_chunk_key = "%d_%d" % [chunk_x, chunk_y]
	var base_data := WorldGeneratorScript.generate_chunk(world_seed, chunk_x, chunk_y, CHUNK_PX)
	var world_state := _world_state_manager()
	var delta: Dictionary = world_state.get_modifications_for_chunk(_chunk_key) if world_state != null else {}
	_build_terrain(base_data.get("terrain_cells", []))
	_build_resource_nodes(base_data.get("resource_nodes", []), delta.get("depleted_node_ids", []))
	_build_structures(delta.get("structures", []))
	if world_state != null:
		world_state.mark_chunk_discovered(_chunk_key)

## -- Read-only world-space contract (copies, same discipline as near_base_chunk.gd) --

func get_bounds() -> Rect2:
	return Rect2(chunk_origin, Vector2(CHUNK_PX, CHUNK_PX))

func get_chunk_key() -> String:
	return _chunk_key

## Returns world-space copies of every currently-active (non-depleted)
## resource node: {id, type, world_position, yield_amount}.
func get_active_resource_nodes() -> Array:
	var out: Array = []
	for node_id in _active_nodes.keys():
		var n: Dictionary = _active_nodes[node_id]
		out.append({
			"id": node_id,
			"type": n["type"],
			"world_position": chunk_origin + (n["local_position"] as Vector2),
			"yield_amount": n["yield_amount"],
		})
	return out

## Attempts to harvest one resource node by id. Deposits into BackpackManager
## and, on success, records the depletion in WorldStateManager so it stays
## gone across chunk unload/reload. Returns
## {"success": bool, "reason": String, "item_id": String, "amount": int}.
func harvest_node(node_id: String) -> Dictionary:
	if not _active_nodes.has(node_id):
		return {"success": false, "reason": "not_found"}
	var n: Dictionary = _active_nodes[node_id]
	var backpack := _backpack_manager()
	if backpack == null:
		return {"success": false, "reason": "no_backpack_manager"}
	var amount := int(n["yield_amount"])
	var result: Dictionary = backpack.call("add_item", HARVEST_ITEM_ID, amount)
	if int(result.get("accepted", 0)) <= 0:
		return {"success": false, "reason": "backpack_full"}
	_active_nodes.erase(node_id)
	if n.get("marker") != null and is_instance_valid(n["marker"]):
		(n["marker"] as Node).queue_free()
	if n.get("label") != null and is_instance_valid(n["label"]):
		(n["label"] as Node).queue_free()
	var world_state := _world_state_manager()
	if world_state != null:
		world_state.call("record_node_depleted", _chunk_key, node_id)
	return {"success": true, "reason": "", "item_id": HARVEST_ITEM_ID, "amount": amount}

## Places a placeholder "structure" stub (this prototype has no real
## building system yet -- see plan's explicit scope note) and persists it
## immediately via WorldStateManager so it survives unload/reload.
## local_pos is in this chunk's local space (0,0 .. CHUNK_PX,CHUNK_PX).
func place_structure_stub(local_pos: Vector2) -> void:
	_spawn_structure_stub(local_pos)
	var world_state := _world_state_manager()
	if world_state != null:
		world_state.call("record_structure_placed", _chunk_key, {"local_x": local_pos.x, "local_y": local_pos.y})

func _build_terrain(cells: Array) -> void:
	var cell_size := CHUNK_PX / float(WorldGeneratorScript.TERRAIN_GRID)
	for cell in cells:
		var rect := ColorRect.new()
		rect.color = TERRAIN_COLORS.get(String(cell["kind"]), TERRAIN_COLORS["flat"])
		rect.size = Vector2(cell_size, cell_size)
		rect.position = Vector2(int(cell["cell_x"]) * cell_size, int(cell["cell_y"]) * cell_size)
		rect.z_index = -6
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)

func _build_resource_nodes(nodes: Array, depleted_ids: Array) -> void:
	for node_data in nodes:
		var node_id := String(node_data["id"])
		if depleted_ids.has(node_id):
			continue
		var local_pos: Vector2 = node_data["local_position"]
		var node_type := String(node_data["type"])
		var marker := ColorRect.new()
		marker.color = RESOURCE_COLORS.get(node_type, RESOURCE_COLORS["ore"])
		marker.size = Vector2(40, 32)
		marker.position = local_pos - marker.size * 0.5
		marker.z_index = -3
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(marker)
		var label := Label.new()
		label.text = String(RESOURCE_LABELS.get(node_type, "矿石"))
		label.modulate = Color("#c9c2b4")
		label.add_theme_font_size_override("font_size", 12)
		label.position = local_pos + Vector2(-24, -44)
		label.z_index = 39
		add_child(label)
		_active_nodes[node_id] = {
			"type": node_type,
			"local_position": local_pos,
			"yield_amount": int(node_data["yield_amount"]),
			"marker": marker,
			"label": label,
		}

func _build_structures(structures: Array) -> void:
	for structure in structures:
		var local_pos := Vector2(float(structure.get("local_x", 0.0)), float(structure.get("local_y", 0.0)))
		_spawn_structure_stub(local_pos)

func _spawn_structure_stub(local_pos: Vector2) -> void:
	var stub := ColorRect.new()
	stub.color = Color("#4a6b5a")
	stub.size = Vector2(56, 56)
	stub.position = local_pos - stub.size * 0.5
	stub.z_index = -2
	add_child(stub)

func _world_state_manager() -> Node:
	return get_node_or_null("/root/WorldStateManager")

func _backpack_manager() -> Node:
	return get_node_or_null("/root/BackpackManager")
