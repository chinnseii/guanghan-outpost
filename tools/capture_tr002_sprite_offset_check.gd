extends SceneTree

## Visual before/after check for the player_visual.gd sprite-vs-hitbox
## offset fix: positions the player at the exact resolved stop point when
## walking into the terminal from the south, and captures a zoomed screenshot
## so the character's feet can be visually compared against the terminal's
## real edge.

const OUT_DIR := "res://docs/screenshots/training_hub_art"
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1600, 900)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout

	var player: Control = scene.get("player")
	var module_data: Dictionary = scene.get("module_data")
	var blockers: Array = module_data.get("blockers", [])
	var terminal_blocker: Rect2 = blockers[0]

	player.position = scene.call("_room_point", Vector2(terminal_blocker.get_center().x, terminal_blocker.end.y + 90.0))
	scene.call("_sync_player_visual")
	await process_frame
	await _walk_to(player, scene, Vector2(terminal_blocker.get_center().x, terminal_blocker.position.y - 10.0))
	await process_frame
	await process_frame

	var texture := root.get_texture()
	var image := texture.get_image()
	var err := image.save_png("%s/14_sprite_offset_fix_terminal_south.png" % OUT_DIR)
	print("capture err=", err)
	var final_design: Vector2 = scene.call("_design_point_from_room", player.position)
	print("final player top-left design=", final_design, " terminal_blocker=", terminal_blocker)
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
