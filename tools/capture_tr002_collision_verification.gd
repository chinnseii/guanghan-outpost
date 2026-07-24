extends SceneTree

## TR-002 collision spec verification (2026-07-22, collision-spec message):
## confirms (1) the hub's real player_controller.bounds now reflects the new
## per-room "movement_margin" (56, not the project-wide default 36), (2) the
## terminal's new "blockers" rect actually stops the player from walking
## into the console's solid footprint, and (3) all 4 doors are still
## reachable/crossable under the tighter margin. Run only against an
## isolated sandbox project copy (separate project.godot config/name) so
## user:// never touches the real project's save directory.
const OUT_DIR := "res://docs/screenshots/training_hub_art"
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"
const DOOR_IDS := ["door_suit", "door_power", "door_air", "door_greenhouse"]

var _done := false

func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(45.0).timeout
	if not _done:
		push_error("Verification script exceeded 45s guard; force quitting.")
		quit(1)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1920, 1080)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout

	var player: Control = scene.get("player")
	var target_nodes: Dictionary = scene.get("target_nodes")
	var spawn_pos: Vector2 = player.position

	print("== TR-002 collision verification ==")
	var controller = scene.get("player_controller")
	print("real player_controller.bounds=", controller.bounds if controller != null else "NULL (not yet created)")
	var module_data: Dictionary = scene.get("module_data")
	print("module_data.movement_margin=", module_data.get("movement_margin", "MISSING"))
	print("module_data.blockers=", module_data.get("blockers", "MISSING"))

	print("== door reachability under new margin ==")
	for door_id in DOOR_IDS:
		var result := await _walk_toward(scene, player, target_nodes[door_id], spawn_pos, door_id)
		print(door_id, " -> ", result)

	print("== terminal blocker test (walk straight at the console) ==")
	var blockers: Array = module_data.get("blockers", [])
	var blocker_rect: Rect2 = blockers[0] if blockers.size() > 0 else Rect2()
	player.position = spawn_pos
	scene.call("_sync_player_visual")
	await process_frame
	var target_center := blocker_rect.position + blocker_rect.size * 0.5
	var closest_dist := INF
	var ever_overlapped := false
	for i in range(600):
		var player_center: Vector2 = player.position + player.size * 0.5
		var to_target: Vector2 = target_center - player_center
		var dir: Vector2 = to_target.normalized() if to_target.length() > 0.001 else Vector2.ZERO
		Input.action_press("ui_left", max(0.0, -dir.x))
		Input.action_press("ui_right", max(0.0, dir.x))
		Input.action_press("ui_up", max(0.0, -dir.y))
		Input.action_press("ui_down", max(0.0, dir.y))
		await process_frame
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		Input.action_release("ui_up")
		Input.action_release("ui_down")
		var player_rect := Rect2(player.position, player.size)
		if player_rect.intersects(blocker_rect):
			ever_overlapped = true
		closest_dist = min(closest_dist, player_rect.get_center().distance_to(target_center))
	print("blocker_rect=", blocker_rect)
	print("final player position=", player.position, " player size=", player.size)
	print("ever_overlapped_blocker(should be false)=", ever_overlapped)
	print("closest_center_distance=", closest_dist)

	player.position = spawn_pos
	scene.call("_sync_player_visual")
	await process_frame
	await _capture("06_hub_collision_full_view.png")

	_done = true
	quit()

func _walk_toward(scene: Node, player: Control, target: Control, spawn_pos: Vector2, target_id: String) -> Dictionary:
	player.position = spawn_pos
	scene.call("_sync_player_visual")
	await process_frame
	var start_pos := player.position
	var reached_near := false
	for i in range(1200):
		var target_center: Vector2 = target.position + target.size * 0.5
		var player_center: Vector2 = player.position + player.size * 0.5
		var to_target: Vector2 = target_center - player_center
		if bool(scene.call("_is_near", target_id)):
			reached_near = true
			break
		var dir: Vector2 = to_target.normalized() if to_target.length() > 0.001 else Vector2.ZERO
		Input.action_press("ui_left", max(0.0, -dir.x))
		Input.action_press("ui_right", max(0.0, dir.x))
		Input.action_press("ui_up", max(0.0, -dir.y))
		Input.action_press("ui_down", max(0.0, dir.y))
		await process_frame
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		Input.action_release("ui_up")
		Input.action_release("ui_down")
	return {
		"reached_near": reached_near,
		"moved_distance": start_pos.distance_to(player.position),
		"final_position": player.position,
	}

func _capture(file_name: String) -> void:
	await process_frame
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		push_error("Viewport texture unavailable. Run WITHOUT --headless.")
		return
	var image := texture.get_image()
	var err := image.save_png("%s/%s" % [OUT_DIR, file_name])
	print("capture ", file_name, " err=", err)
