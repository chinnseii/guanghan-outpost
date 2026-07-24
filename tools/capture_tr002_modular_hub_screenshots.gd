extends SceneTree

## TR-002 modular-pack acceptance screenshots (2026-07-21,
## user/TR-002_3Q_TOPDOWN_MODULAR_ASSET_PACK). Produces the handoff doc's
## required set with NO debug overlay (unlike
## capture_tr002_blockout_verification.gd, which is a movement/hitbox
## self-test and deliberately draws annotation boxes): (1) one full clean
## room view, (2) one shot near each door + the terminal, (3) confirmation
## that door_suit (unlocked, per _compute_unlocked()'s "hub"/"suit_prep_room"
## always-true default) and door_power/door_air/door_greenhouse (locked,
## since a fresh save has no training progress) show different door_light_*
## colors from real game state, not a forced/faked flag.
## Run only against an isolated sandbox project copy (separate project.godot
## config/name) so user:// never touches the real project's save directory.
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
		push_error("Screenshot script exceeded 45s guard; force quitting.")
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

	print("== TR-002 modular hub screenshots ==")
	for door_id in DOOR_IDS:
		var target: Control = target_nodes[door_id]
		var locked: bool = bool(target.get("locked"))
		print(door_id, " locked=", locked)

	await _capture("04_hub_full_view_clean.png")

	for door_id in DOOR_IDS:
		await _walk_toward(scene, player, target_nodes[door_id], spawn_pos)
		await _capture("05_hub_%s.png" % door_id)
	await _walk_toward(scene, player, target_nodes["terminal"], spawn_pos)
	await _capture("05_hub_terminal.png")

	_done = true
	quit()

func _walk_toward(scene: Node, player: Control, target: Control, spawn_pos: Vector2) -> void:
	player.position = spawn_pos
	scene.call("_sync_player_visual")
	await process_frame
	var target_id := String(target.name)
	for i in range(1200):
		if bool(scene.call("_is_near", target_id)):
			break
		var target_center: Vector2 = target.position + target.size * 0.5
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
