extends SceneTree

## Simulates walking left past the terminal's corners (the user's reported
## screenshot: standing east/south-east of the terminal, unable to move
## left), from several plausible start heights, to confirm the binary-search
## resolver fallback handles diagonal approaches near a plain rect blocker's
## corner, not just the room_boundary's angled door-recess edges.

const SCENE := "res://scenes/training/TrainingBaseMap.tscn"
# Terminal blocker: design (336,204.5)-(96,60.5) -> x:336-432, y:204.5-265.

func _initialize() -> void:
	call_deferred("_run")

func _walk_to(player: Control, scene: Node, target_design: Vector2) -> void:
	var last_pos := Vector2.INF
	var frozen_frames := 0
	for step in range(250):
		if not is_instance_valid(player):
			return
		if player.position.distance_to(last_pos) < 0.01:
			frozen_frames += 1
		else:
			frozen_frames = 0
		last_pos = player.position
		if frozen_frames > 10:
			print("  (froze solid after ", step, " steps)")
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

func _try(start_design: Vector2, target_design: Vector2, label: String) -> void:
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
	await _walk_to(player, scene, target_design)
	var final_design: Vector2 = scene.call("_design_point_from_room", player.position + player.size * 0.5)
	print(label, " start=", start_design, " target=", target_design, " final=", final_design, " dist_to_target=", final_design.distance_to(target_design))
	scene.queue_free()
	await process_frame

func _run() -> void:
	await _try(Vector2(500, 290), Vector2(400, 260), "past_SE_corner_shallow")
	await _try(Vector2(500, 300), Vector2(400, 150), "past_SE_corner_steep")
	await _try(Vector2(500, 230), Vector2(400, 260), "past_E_edge_into_S_gap")
	await _try(Vector2(280, 290), Vector2(360, 260), "past_SW_corner_shallow")
	quit()
