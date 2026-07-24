extends RefCounted

## Maintains a window of loaded ProceduralChunk instances around the
## player's current chunk coordinate (prototype scope -- see plan
## abstract-hopping-moonbeam.md). Not an autoload: owned by whatever world
## container scene needs it (one instance per world container). Unloading a
## chunk only ever queue_free()s its node -- it never touches
## WorldStateManager's saved deltas, which live independently, so eviction
## can never lose player progress.

const ProceduralChunkScene := preload("res://scenes/surface/chunks/ProceduralChunk.tscn")
const ProceduralChunkScript := preload("res://scripts/surface/chunks/procedural_chunk.gd")

## Chebyshev radius 2 around the player's chunk -> a 5x5 window, which
## covers the requested "3x3 guaranteed + prefetch the next ring" behavior
## in one simple always-maintained window (a priority-ordered lazy prefetch
## of just ring 2 is a possible later refinement, not needed to validate
## the core load/unload loop).
const LOAD_RADIUS := 2

var _loaded_chunks: Dictionary = {}  ## "x_y" -> ProceduralChunk instance
var _current_coord: Vector2i = Vector2i(999999, 999999)  ## forces the first update() to always mount
var _world_seed: int = 0

func set_world_seed(seed_value: int) -> void:
	_world_seed = seed_value

## Call whenever the player moves (cheap to call every frame -- it only does
## real mount/unmount work when the player's computed chunk coordinate
## actually changes). host is the Node2D that owns chunk instances as
## children (typically the world container scene's root).
func update(player_world_pos: Vector2, host: Node2D) -> void:
	var chunk_px: float = ProceduralChunkScript.CHUNK_PX
	var coord := Vector2i(floori(player_world_pos.x / chunk_px), floori(player_world_pos.y / chunk_px))
	if coord == _current_coord:
		return
	_current_coord = coord
	var wanted: Dictionary = {}
	for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var c := coord + Vector2i(dx, dy)
			wanted["%d_%d" % [c.x, c.y]] = c
	for key in wanted.keys():
		if not _loaded_chunks.has(key):
			_mount_chunk(wanted[key], host)
	for key in _loaded_chunks.keys().duplicate():
		if not wanted.has(key):
			var chunk_node: Node2D = _loaded_chunks[key]
			if is_instance_valid(chunk_node):
				chunk_node.queue_free()
			_loaded_chunks.erase(key)

func current_chunk_coord() -> Vector2i:
	return _current_coord

func loaded_chunk_keys() -> Array:
	return _loaded_chunks.keys()

## Returns every active resource node across all currently-loaded chunks, as
## world-space copies (see procedural_chunk.gd.get_active_resource_nodes()),
## each tagged with "chunk_key" so a caller can route a harvest request back
## to the owning chunk instance via harvest_node() below.
func get_all_active_resource_nodes() -> Array:
	var out: Array = []
	for key in _loaded_chunks.keys():
		var chunk_node = _loaded_chunks[key]
		if not is_instance_valid(chunk_node):
			continue
		for node_data in chunk_node.get_active_resource_nodes():
			var tagged: Dictionary = (node_data as Dictionary).duplicate()
			tagged["chunk_key"] = key
			out.append(tagged)
	return out

## Routes a harvest request to whichever loaded chunk owns node_id.
func harvest_node(chunk_key: String, node_id: String) -> Dictionary:
	if not _loaded_chunks.has(chunk_key):
		return {"success": false, "reason": "chunk_not_loaded"}
	var chunk_node = _loaded_chunks[chunk_key]
	if not is_instance_valid(chunk_node):
		return {"success": false, "reason": "chunk_not_loaded"}
	return chunk_node.harvest_node(node_id)

## Places a placeholder structure stub in whichever loaded chunk contains
## world_pos. Returns false if world_pos isn't inside any loaded chunk.
func place_structure_at(world_pos: Vector2) -> bool:
	for key in _loaded_chunks.keys():
		var chunk_node = _loaded_chunks[key]
		if not is_instance_valid(chunk_node):
			continue
		var bounds: Rect2 = chunk_node.get_bounds()
		if bounds.has_point(world_pos):
			chunk_node.place_structure_stub(world_pos - bounds.position)
			return true
	return false

func _mount_chunk(coord: Vector2i, host: Node2D) -> void:
	var chunk: Node2D = ProceduralChunkScene.instantiate()
	chunk.world_seed = _world_seed
	chunk.chunk_x = coord.x
	chunk.chunk_y = coord.y
	host.add_child(chunk)
	_loaded_chunks["%d_%d" % [coord.x, coord.y]] = chunk
