extends SceneTree

const WorldGeneratorScript := preload("res://scripts/world/WorldGenerator.gd")

func _initialize() -> void:
	var chunk_px := 3072.0
	var a1 := WorldGeneratorScript.generate_chunk(12345, 2, -1, chunk_px)
	var a2 := WorldGeneratorScript.generate_chunk(12345, 2, -1, chunk_px)
	assert(_deep_equal(a1, a2), "same inputs must produce identical output")
	print("PASS: same inputs -> identical output (", a1.resource_nodes.size(), " nodes)")

	var b := WorldGeneratorScript.generate_chunk(99999, 2, -1, chunk_px)
	assert(not _deep_equal(a1, b), "different world_seed must change output")
	print("PASS: different world_seed -> different output")

	var c := WorldGeneratorScript.generate_chunk(12345, -1, 2, chunk_px)
	assert(not _deep_equal(a1, c), "(2,-1) and (-1,2) must not collide")
	print("PASS: (2,-1) != (-1,2)")

	# Sweep a grid of coordinates including negatives; confirm no two chunks
	# accidentally produce the exact same seed (which would mean identical
	# content by coincidence, defeating the point of per-chunk generation).
	var seeds_seen := {}
	var collision := false
	for cx in range(-20, 21):
		for cy in range(-20, 21):
			var s: int = WorldGeneratorScript._mix(12345, cx, cy)
			if seeds_seen.has(s):
				print("COLLISION between ", seeds_seen[s], " and ", Vector2i(cx, cy))
				collision = true
			seeds_seen[s] = Vector2i(cx, cy)
	assert(not collision, "seed collision found in -20..20 x -20..20 sweep")
	print("PASS: no seed collisions in -20..20 x -20..20 sweep (", seeds_seen.size(), " unique seeds)")

	print("ALL DETERMINISM CHECKS PASSED")
	quit()

func _deep_equal(a: Variant, b: Variant) -> bool:
	return JSON.stringify(a) == JSON.stringify(b)
