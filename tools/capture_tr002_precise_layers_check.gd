extends SceneTree

## TR-002_MASTER_ELEMENTS_TRIAL follow-up (2026-07-24): verifies the
## hand-traced collision polygon, updated terminal blocker, re-traced door
## targets, and dynamic occlusion zones (all authored via the layer-
## annotation tool built this session) actually work as intended:
## 1. Walking toward each of the 4 doors reaches their real trigger rect.
## 2. The polygon wall boundary stops the player at a few sample points.
## 3. The terminal blocker still stops the player.
## 4. Player feet correctly land in "building_front" (north approach) vs
##    "player_front" (south approach), confirmed via which node ends up
##    later in training_area's child order (higher index = drawn on top).
const OUT_DIR := "res://docs/screenshots/training_hub_art"
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"

var _done := false

func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(60.0).timeout
	if not _done:
		push_error("Verification script exceeded 60s guard; force quitting.")
		quit(1)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1600, 900)

	print("=== Door trigger walk tests (each in a fresh scene, since a")
	print("    successful crossing frees the old player/training_area) ===")
	var door_ids := ["door_suit", "door_power", "door_air", "door_greenhouse"]
	for target_id in door_ids:
		var fresh_scene: Node = (load(SCENE) as PackedScene).instantiate()
		root.add_child(fresh_scene)
		await process_frame
		await create_timer(0.3).timeout
		fresh_scene.call("_close_briefing")
		await process_frame
		await create_timer(0.2).timeout

		# Force-unlock every gated area so all 4 doors are walk-testable
		# without needing real training progress (matches the 2026-07-24
		# final-redraw follow-up verification).
		var fresh_areas: Dictionary = fresh_scene.get("areas")
		for gated_id in ["power_distribution_room", "air_system_control_room", "greenhouse_room"]:
			if fresh_areas.has(gated_id):
				(fresh_areas[gated_id] as Dictionary)["unlocked"] = true

		var fresh_player: Control = fresh_scene.get("player")
		var fresh_module_data: Dictionary = fresh_scene.get("module_data")
		var area_before: String = fresh_scene.get("current_area_id")
		var target_dict: Dictionary = {}
		for t: Dictionary in fresh_module_data.get("targets", []):
			if String(t["id"]) == target_id:
				target_dict = t
				break
		var target_center_design: Vector2 = Vector2(target_dict["position"]) + Vector2(target_dict["size"]) * 0.5
		await _walk_to(fresh_player, fresh_scene, target_center_design)
		await process_frame
		var area_after: String = fresh_scene.get("current_area_id")
		var final_design_text := "n/a (crossed, old player freed)"
		if is_instance_valid(fresh_player):
			var final_design: Vector2 = fresh_scene.call("_design_point_from_room", fresh_player.position + fresh_player.size * 0.5)
			final_design_text = str(final_design)
		print(target_id, " target_center_design=", target_center_design, " final_feet_design=", final_design_text, " area_before=", area_before, " area_after=", area_after, " crossed=", area_before != area_after)
		fresh_scene.queue_free()
		await process_frame

	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout

	var player: Control = scene.get("player")
	var module_data: Dictionary = scene.get("module_data")

	print("=== Terminal blocker test ===")
	var blockers: Array = module_data.get("blockers", [])
	var terminal_blocker: Rect2 = blockers[0]
	print("terminal_blocker=", terminal_blocker)
	var term_start: Vector2 = Vector2(terminal_blocker.get_center().x, terminal_blocker.end.y + 90.0)
	player.position = scene.call("_room_point", term_start)
	scene.call("_sync_player_visual")
	await process_frame
	await _walk_to(player, scene, Vector2(terminal_blocker.get_center().x, terminal_blocker.position.y - 10.0))
	var final_design: Vector2 = scene.call("_design_point_from_room", player.position)
	var final_end: Vector2 = scene.call("_design_point_from_room", player.position + player.size)
	print("terminal south-approach final rect=", Rect2(final_design, final_end - final_design), " blocker=", terminal_blocker)

	print("=== Polygon wall boundary spot checks ===")
	# A few points well inside the room, walking outward toward wall midpoints
	# away from any door, to confirm the polygon (not the old rect segments)
	# is what's stopping the player.
	var wall_targets := [Vector2(200.0, 20.0), Vector2(560.0, 500.0), Vector2(40.0, 300.0)]
	for wt in wall_targets:
		player.position = scene.call("_room_point", Vector2(380.0, 300.0))
		scene.call("_sync_player_visual")
		await process_frame
		await _walk_to(player, scene, wt)
		var fd: Vector2 = scene.call("_design_point_from_room", player.position)
		print("wall target=", wt, " final player top-left (design)=", fd)

	print("=== Dynamic occlusion test ===")
	var terminal_blocker2: Rect2 = blockers[0]
	# South approach (normal case): player should end up drawn AFTER terminal.
	player.position = scene.call("_room_point", Vector2(terminal_blocker2.get_center().x, terminal_blocker2.end.y + 90.0))
	scene.call("_sync_player_visual")
	await process_frame
	await _walk_to(player, scene, Vector2(terminal_blocker2.get_center().x, terminal_blocker2.position.y - 10.0))
	await process_frame
	_print_occlusion_state(scene, "south (expect player in front, i.e. player_visual index > terminal index)")

	# North approach: player should end up drawn BEHIND terminal.
	player.position = scene.call("_room_point", Vector2(terminal_blocker2.get_center().x, terminal_blocker2.position.y - 90.0))
	scene.call("_sync_player_visual")
	await process_frame
	await _walk_to(player, scene, Vector2(terminal_blocker2.get_center().x, terminal_blocker2.end.y + 10.0))
	await process_frame
	_print_occlusion_state(scene, "north (expect terminal in front, i.e. terminal index > player_visual index)")

	_done = true
	quit()

func _print_occlusion_state(scene: Node, label: String) -> void:
	var player_visual: Node = scene.get("player_visual")
	var terminal_sprite: Node = scene.get("hub_terminal_sprite")
	if player_visual == null or terminal_sprite == null:
		print(label, " -- player_visual or hub_terminal_sprite is null")
		return
	print(label, " -- player_visual.index=", player_visual.get_index(), " terminal.index=", terminal_sprite.get_index())

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
