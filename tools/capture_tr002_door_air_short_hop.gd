extends SceneTree

## door_air's full-room walk test (spawn -> door, straight line) stopped ~80px
## short even though a direct footprint probe confirmed the target center is
## genuinely open. Likely the straight-line path from spawn grazes a wall
## bump partway there and the naive _walk_to() chaser gets stuck sliding
## along it (the already-documented walk-simulation artifact, just more
## pronounced with this wall shape). This starts the player already close to
## the door (bypassing the long diagonal) to confirm the door itself, and the
## final approach to it, genuinely works once you're actually near it.

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

	var areas: Dictionary = scene.get("areas")
	for gated_id in ["power_distribution_room", "air_system_control_room", "greenhouse_room"]:
		if areas.has(gated_id):
			(areas[gated_id] as Dictionary)["unlocked"] = true

	var player: Control = scene.get("player")
	var module_data: Dictionary = scene.get("module_data")
	var target_dict: Dictionary = {}
	for t: Dictionary in module_data.get("targets", []):
		if String(t["id"]) == "door_air":
			target_dict = t
			break
	var target_center: Vector2 = Vector2(target_dict["position"]) + Vector2(target_dict["size"]) * 0.5

	# Start close to (west of) the door, matching a player who's already
	# walked along the east wall corridor rather than beelining diagonally
	# from the room's south spawn.
	player.position = scene.call("_room_point", Vector2(590.0, 255.0))
	scene.call("_sync_player_visual")
	await process_frame

	var area_before: String = scene.get("current_area_id")
	await _walk_to(player, scene, target_center)
	await process_frame
	var area_after: String = scene.get("current_area_id")
	print("door_air short-hop: area_before=", area_before, " area_after=", area_after, " crossed=", area_before != area_after)
	if is_instance_valid(player):
		var final_design: Vector2 = scene.call("_design_point_from_room", player.position + player.size * 0.5)
		print("  final feet design (if not crossed)=", final_design, " target_center=", target_center)

	quit()

func _walk_to(player: Control, scene: Node, target_design: Vector2) -> void:
	for step in range(400):
		if not is_instance_valid(player):
			return
		var player_center: Vector2 = player.position + player.size * 0.5
		var target_room: Vector2 = scene.call("_room_point", target_design)
		var to_target: Vector2 = target_room - player_center
		if to_target.length() < 4.0:
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
