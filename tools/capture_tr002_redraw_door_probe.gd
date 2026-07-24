extends SceneTree

## Direct probe (bypasses the known walk-simulation artifact -- see
## ACTIVE_TASKS.md -- by calling _footprint_hits_anything() at exact swept
## coordinates instead of simulating movement) to check whether door_air and
## door_greenhouse's target centers are genuinely open under the NEW
## collision polygon (2026-07-24 final redraw), or whether this is a real
## regression vs. the previously-verified round-1 polygon.

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

	# Force-unlock every gated area so all 4 door openings are testable
	# without needing to actually play through the training progression.
	var areas: Dictionary = scene.get("areas")
	for area_id in ["power_distribution_room", "air_system_control_room", "greenhouse_room"]:
		if areas.has(area_id):
			(areas[area_id] as Dictionary)["unlocked"] = true

	var module_data: Dictionary = scene.get("module_data")
	var targets_by_id := {}
	for t: Dictionary in module_data.get("targets", []):
		targets_by_id[String(t["id"])] = t
	var player: Control = scene.get("player")

	# _footprint_hits_anything() takes a ROOM-SPACE top-left (player.position
	# convention); the footprint itself is derived internally from that via
	# _footprint_rect(), anchored at the bottom (feet). To test "is this
	# design-space FEET point blocked" (matching _is_inside_target_area()'s
	# own feet-point convention), convert feet -> top-left the same way
	# _sync_terminal_occlusion() converts top-left -> feet, just inverted.
	for id in ["door_air", "door_greenhouse", "door_power", "door_suit"]:
		var t: Dictionary = targets_by_id[id]
		var pos: Vector2 = t["position"]
		var size: Vector2 = t["size"]
		var center: Vector2 = pos + size * 0.5
		print("--- ", id, " target rect design=", Rect2(pos, size), " center=", center, " (all gated areas force-unlocked) ---")
		for offset in [Vector2.ZERO, Vector2(-8, 0), Vector2(8, 0), Vector2(0, -8), Vector2(0, 8)]:
			var probe_feet_design: Vector2 = center + offset
			var room_feet: Vector2 = scene.call("_room_point", probe_feet_design)
			var room_top_left: Vector2 = room_feet - Vector2(player.size.x * 0.5, player.size.y)
			var blocked: bool = scene.call("_footprint_hits_anything", room_top_left, module_data.get("blockers", []), module_data.get("collision_polygons", []))
			print("  offset=", offset, " feet_design=", probe_feet_design, " blocked=", blocked)

	quit()
