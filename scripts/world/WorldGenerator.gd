extends RefCounted

## Deterministic chunk content generator for the procedural-world prototype
## (see docs/design/LUNAR_SURFACE_MAP.md's approved hand-authored surface for
## the OTHER, currently-shipping surface system -- this is a separate,
## additive prototype, not a replacement; see plan
## abstract-hopping-moonbeam.md). Every chunk's content is a pure function of
## (world_seed, chunk_x, chunk_y) -- same inputs always produce the same
## output, regardless of call order or how many times it's called, so a
## chunk can be freely unloaded and regenerated without drifting from what
## the player already saw.
##
## Hard invariants (do not violate when extending this file):
## 1. Only ever draw randomness from the RandomNumberGenerator instance
##    this file creates -- never call global randi()/randf().
## 2. Never branch on anything external (wall clock, other managers, call
##    count) -- only on values already drawn from that rng.
## 3. Any rejection-sampling retry limit must be a fixed constant (or a
##    value drawn once from the rng), never an unbounded "until it fits"
##    loop that could behave differently between runs.
## 4. Per-node yield_amount is decided HERE, at generation time, and stored
##    in the returned dict -- never re-rolled when the node is later
##    harvested (harvesting itself must not consume randomness).
## 5. Every generated object gets a stable id derived only from
##    (chunk_x, chunk_y, generation-order index) -- WorldStateManager keys
##    its persisted deltas (e.g. depleted_node_ids) off these ids.

const TERRAIN_GRID := 4  ## sub-cells per chunk edge, coarse placeholder for real noise-based terrain later.
const TERRAIN_KINDS := ["flat", "flat", "flat", "rocky", "rocky", "crater"]  ## weighted via repetition.
const MAX_RESOURCE_NODES := 5
const RESOURCE_NODE_CHANCE := 0.7  ## per candidate slot, independent of MAX_RESOURCE_NODES.
const MIN_NODE_SPACING := 220.0  ## px; rejection-sampling keeps nodes from overlapping.
const PLACEMENT_RETRY_LIMIT := 12  ## fixed cap -- never loop "until it fits".
const RESOURCE_TYPES := ["ore", "moon_rock"]

## Combines world_seed with chunk coordinates into one positive integer seed.
## Explicit integer mixing (not GDScript's hash()) so the result is an
## auditable, stable contract we control -- hash()'s exact output isn't
## documented as stable across engine versions.
##
## Uses Murmur3's fmix32 finalizer (a small, well-known, good-avalanche
## 32-bit mixer -- deliberately kept to constants well under 2^32 so no
## 64-bit signed-literal wraparound reasoning is needed), folded once per
## input, with zigzag encoding first so negative coordinates don't collapse
## onto the same bit patterns as positive ones. A first attempt here (a
## naive "multiply by a constant and XOR the raw coordinate" mix) measurably
## collided across many coordinate pairs in a -5..5 sweep -- small XOR
## operands don't diffuse into the high bits before the final mask, so
## strong mixing is a real correctness requirement, not paranoia. Verified
## collision-free across -20..20 x -20..20 in tools/debug_world_generator_determinism.gd.
static func _zigzag(n: int) -> int:
	return ((n << 1) ^ (n >> 63)) & 0xffffffff

static func _fmix32(seed: int) -> int:
	var h := seed & 0xffffffff
	h ^= h >> 16
	h = (h * 0x85ebca6b) & 0xffffffff
	h ^= h >> 13
	h = (h * 0xc2b2ae35) & 0xffffffff
	h ^= h >> 16
	return h & 0xffffffff

static func _mix(world_seed: int, chunk_x: int, chunk_y: int) -> int:
	var state := _fmix32(world_seed)
	state = _fmix32(state ^ _zigzag(chunk_x))
	state = _fmix32(state ^ (_zigzag(chunk_y) * 0x27d4eb2f + 1))
	return state & 0x7fffffff

static func chunk_rng(world_seed: int, chunk_x: int, chunk_y: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _mix(world_seed, chunk_x, chunk_y)
	return rng

## Single entry point. chunk_px is the chunk's edge length in world pixels
## (caller-supplied so this file has no dependency on any particular
## chunk-size constant living elsewhere).
static func generate_chunk(world_seed: int, chunk_x: int, chunk_y: int, chunk_px: float) -> Dictionary:
	var rng := chunk_rng(world_seed, chunk_x, chunk_y)
	var terrain_cells := _generate_terrain(rng)
	var resource_nodes := _generate_resources(rng, chunk_x, chunk_y, chunk_px)
	return {
		"chunk_x": chunk_x,
		"chunk_y": chunk_y,
		"terrain_cells": terrain_cells,
		"resource_nodes": resource_nodes,
	}

static func _generate_terrain(rng: RandomNumberGenerator) -> Array:
	var cells: Array = []
	for cell_y in range(TERRAIN_GRID):
		for cell_x in range(TERRAIN_GRID):
			var kind: String = TERRAIN_KINDS[rng.randi_range(0, TERRAIN_KINDS.size() - 1)]
			cells.append({"cell_x": cell_x, "cell_y": cell_y, "kind": kind})
	return cells

static func _generate_resources(rng: RandomNumberGenerator, chunk_x: int, chunk_y: int, chunk_px: float) -> Array:
	var nodes: Array = []
	var placed_positions: Array[Vector2] = []
	var index := 0
	var margin := 60.0
	for _slot in range(MAX_RESOURCE_NODES):
		if rng.randf() > RESOURCE_NODE_CHANCE:
			continue
		var placed := false
		for _attempt in range(PLACEMENT_RETRY_LIMIT):
			var candidate := Vector2(
				rng.randf_range(margin, chunk_px - margin),
				rng.randf_range(margin, chunk_px - margin)
			)
			if _far_enough(candidate, placed_positions):
				placed_positions.append(candidate)
				var node_type: String = RESOURCE_TYPES[rng.randi_range(0, RESOURCE_TYPES.size() - 1)]
				var yield_amount := rng.randi_range(1, 3)
				nodes.append({
					"id": "ore_%d_%d_%02d" % [chunk_x, chunk_y, index],
					"type": node_type,
					"local_position": candidate,
					"yield_amount": yield_amount,
				})
				index += 1
				placed = true
				break
		# If placement failed after PLACEMENT_RETRY_LIMIT attempts, this slot
		# is simply skipped (deterministic: same seed always skips the same
		# slots), not retried indefinitely.
		if not placed:
			continue
	return nodes

static func _far_enough(candidate: Vector2, existing: Array[Vector2]) -> bool:
	for pos in existing:
		if candidate.distance_to(pos) < MIN_NODE_SPACING:
			return false
	return true
