extends SceneTree

## Hunts for "invisible wall depends on approach angle" near each concave
## (reflex) vertex of the current room_boundary polygon -- these are the only
## places an axis-aligned footprint rect can behave this way against a
## non-axis-aligned boundary edge (a straight polygon edge never causes this;
## a concave corner where two differently-angled edges meet can, since the
## rect's corner can clip one edge from one approach direction while staying
## clear from another). For each candidate point (a few px inside the
## boundary from the reflex vertex, toward the room's rough center), tries
## walking to it from 4 different start positions (each approaching along a
## different compass direction) and reports how close each one gets. A big
## spread between the best and worst approach direction's final distance to
## the SAME target is the signature of this bug.

const SCENE := "res://scenes/training/TrainingBaseMap.tscn"
const ROOM_CENTER := Vector2(380, 260)

# (label, reflex vertex design point)
const CANDIDATES: Array = [
	["top_door_west_shoulder", Vector2(350, 101.5)],
	["top_door_east_shoulder", Vector2(430.5, 99)],
	["air_door_north_shoulder", Vector2(652, 226.5)],
	["air_door_south_shoulder", Vector2(654, 277)],
	["greenhouse_door_east_shoulder", Vector2(584.5, 408.5)],
	["greenhouse_door_west_shoulder", Vector2(427.5, 431.5)],
	["crate_notch_east", Vector2(338.5, 427)],
	["crate_notch_mid", Vector2(173.5, 406.5)],
	["crate_notch_west", Vector2(131.5, 390.5)],
	["suit_door_south_shoulder", Vector2(101.5, 280.5)],
	["suit_door_north_shoulder", Vector2(110.5, 215.5)],
]

func _initialize() -> void:
	call_deferred("_run")

func _target_point(vertex: Vector2) -> Vector2:
	var to_center := (ROOM_CENTER - vertex).normalized()
	return vertex + to_center * 14.0

func _run() -> void:
	for entry in CANDIDATES:
		var label: String = entry[0]
		var vertex: Vector2 = entry[1]
		var target := _target_point(vertex)
		var results := []
		for approach_dir: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			var start: Vector2 = target - approach_dir * 60.0
			var final_dist: float = await _try_walk(start, target)
			results.append(final_dist)
		var spread: float = results.max() - results.min()
		print("%-28s target=%s  from(E,W,S,N)=%s  spread=%.1f%s" % [
			label, target, results, spread, "  <<< SUSPECT" if spread > 8.0 else ""
		])

func _try_walk(start_design: Vector2, target_design: Vector2) -> float:
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.15).timeout
	scene.call("_close_briefing")
	await process_frame

	var player: Control = scene.get("player")
	player.position = scene.call("_room_point", start_design)
	scene.call("_sync_player_visual")
	await process_frame

	for step in range(200):
		if not is_instance_valid(player):
			break
		var player_center: Vector2 = player.position + player.size * 0.5
		var target_room: Vector2 = scene.call("_room_point", target_design)
		var to_target: Vector2 = target_room - player_center
		if to_target.length() < 3.0:
			break
		var dir: Vector2 = to_target.normalized()
		Input.action_press("ui_left", max(0.0, -dir.x))
		Input.action_press("ui_right", max(0.0, dir.x))
		Input.action_press("ui_up", max(0.0, -dir.y))
		Input.action_press("ui_down", max(0.0, dir.y))
		await process_frame
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		Input.action_release("ui_up")
		Input.action_release("ui_down")

	var final_design: Vector2 = scene.call("_design_point_from_room", player.position + player.size * 0.5)
	var dist: float = (final_design - target_design).length()
	scene.queue_free()
	await process_frame
	return dist
