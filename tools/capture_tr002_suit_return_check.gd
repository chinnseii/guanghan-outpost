extends SceneTree

## User report (2026-07-24): "从宇航服整备室回来之后会被卡住" (getting
## stuck after returning from the suit prep room). Root cause: the new
## hand-traced wall polygon correctly follows the room's real (locally
## deeper) left-wall edge, but suit_prep_room's "door_hub" door_spawn was
## still the OLD (90,300) -- valid under the previous crude ~96px-flat wall
## approximation, but now inside the new polygon's solid wall mass. Fixed by
## moving it to (125,250). This reproduces the exact reported sequence:
## hub -> door_suit -> suit_prep_room -> door_hub back to hub -> confirm the
## player can actually move afterward (not stuck at the spawn point).
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"
var _done := false

func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(40.0).timeout
	if not _done:
		push_error("Verification script exceeded 40s guard; force quitting.")
		quit(1)

func _run() -> void:
	Engine.max_fps = 60
	root.size = Vector2i(1600, 900)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout

	# Step 1: hub -> door_suit -> suit_prep_room.
	var player: Control = scene.get("player")
	var module_data: Dictionary = scene.get("module_data")
	var door_suit: Dictionary = {}
	for t: Dictionary in module_data.get("targets", []):
		if String(t["id"]) == "door_suit":
			door_suit = t
			break
	var target_center: Vector2 = Vector2(door_suit["position"]) + Vector2(door_suit["size"]) * 0.5
	await _walk_to(player, scene, target_center)
	await process_frame
	print("after door_suit: current_area_id=", scene.get("current_area_id"))

	# Step 2: inside suit_prep_room, walk to its own door_hub to return.
	var player2: Control = scene.get("player")
	var module_data2: Dictionary = scene.get("module_data")
	var door_hub: Dictionary = {}
	for t: Dictionary in module_data2.get("targets", []):
		if String(t["id"]) == "door_hub":
			door_hub = t
			break
	var target_center2: Vector2 = Vector2(door_hub["position"]) + Vector2(door_hub["size"]) * 0.5
	await _walk_to(player2, scene, target_center2)
	await process_frame
	print("after door_hub return: current_area_id=", scene.get("current_area_id"))

	# Step 3: confirm the player is NOT stuck at the new spawn -- try walking
	# a short distance in an arbitrary safe direction and confirm real
	# movement happens.
	var player3: Control = scene.get("player")
	if not is_instance_valid(player3):
		print("FAIL: player invalid after returning to hub")
		_done = true
		quit()
		return
	var start_design: Vector2 = scene.call("_design_point_from_room", player3.position)
	print("spawn design position=", start_design)
	await _walk_to(player3, scene, start_design + Vector2(60, 0))
	await process_frame
	var end_design: Vector2 = scene.call("_design_point_from_room", player3.position)
	print("after trying to move +60 x: final design position=", end_design, " moved=", (end_design - start_design).length())

	_done = true
	quit()

func _walk_to(player: Control, scene: Node, target_design: Vector2) -> void:
	for step in range(300):
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
