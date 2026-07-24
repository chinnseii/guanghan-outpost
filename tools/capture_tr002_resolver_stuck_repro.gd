extends SceneTree

## Directly reproduces the "invisible wall, changes with approach angle"
## mechanism using _resolve_blockers() itself (not movement simulation):
## near a shallow-diagonal wall edge (a door recess "shoulder"), a diagonal
## step whose slope roughly matches the wall's own slope can fail all 3 of
## _resolve_blockers()'s candidates (full diagonal, x-only slide, y-only
## slide) even though slightly-smaller steps in the SAME direction, or
## slightly different nearby positions, are fine -- a full stop despite
## clearly walkable floor nearby.

const SCENE := "res://scenes/training/TrainingBaseMap.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame

	# This repro point sits inside air_system_control_room's door_gap_blocker
	# (which correctly seals the recess while locked) -- force-unlock it so
	# this test isolates the room_boundary geometry itself, not the
	# (working-as-intended) locked-door seal.
	var areas: Dictionary = scene.get("areas")
	if areas.has("air_system_control_room"):
		(areas["air_system_control_room"] as Dictionary)["unlocked"] = true

	var player: Control = scene.get("player")
	# _resolve_blockers() takes ROOM-SPACE top-left points (player.position
	# convention) -- these design points are FEET points (from the grid scan
	# that found this scenario), so convert feet -> top-left the same way
	# _sync_terminal_occlusion() does it in reverse, not a raw _room_point().
	var old_feet_design := Vector2(639, 265)
	var candidate_feet_design := Vector2(645, 271)
	var old_room_top_left: Vector2 = scene.call("_room_point", old_feet_design) - Vector2(player.size.x * 0.5, player.size.y)
	var candidate_room_top_left: Vector2 = scene.call("_room_point", candidate_feet_design) - Vector2(player.size.x * 0.5, player.size.y)

	var result_room: Vector2 = scene.call("_resolve_blockers", old_room_top_left, candidate_room_top_left)
	var result_feet_room: Vector2 = result_room + Vector2(player.size.x * 0.5, player.size.y)
	var result_feet_design: Vector2 = scene.call("_design_point_from_room", result_feet_room)
	print("old_feet_design=", old_feet_design, " candidate_feet_design=", candidate_feet_design)
	print("resolved_feet_design=", result_feet_design)
	print("stuck at old position (full stop)=", result_feet_design.distance_to(old_feet_design) < 0.5)
	quit()
