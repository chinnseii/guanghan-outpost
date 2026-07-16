extends SceneTree

## TR-002 acceptance capture per the follow-up art-fix instructions:
## 1. full panorama, no UI
## 2. terminal interaction highlight
## 3. left door (宇航服整备室) unlocked state
## 4. top door (配电房) warning/locked state
## 5. bottom door (训练温室) unlocked/green state
## Door lock states are forced by writing directly into the scene's `areas`
## dict (the actual source `_door_locked()` reads every frame), not by
## poking `.locked` on the target node directly -- that gets recomputed and
## overwritten by `_update_room_prompt()` on the very next frame.
## Run only against an isolated sandbox project copy (separate
## project.godot config/name so user:// never touches the real project's
## save directory).
const OUT_DIR := "res://docs/screenshots/training_hub_art"
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"

var _done := false

func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(30.0).timeout
	if not _done:
		push_error("Capture script exceeded 30s guard; force quitting.")
		quit(1)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1920, 1080)
	var scene := (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout

	var minimal_hud: Control = scene.get("minimal_hud")
	if minimal_hud != null:
		minimal_hud.visible = false
	await process_frame
	await _capture("01_hub_panorama_no_ui.png")
	if minimal_hud != null:
		minimal_hud.visible = true

	var target_nodes: Dictionary = scene.get("target_nodes")
	var areas: Dictionary = scene.get("areas")

	# node.highlighted/.active are recomputed from real game state every
	# _process() tick (via _update_room_prompt()'s target_id/interaction_running
	# check), so poking them directly gets overwritten on the next frame --
	# drive the actual underlying flags instead, same fix as the door-lock
	# capture below.
	scene.set("interaction_running", true)
	scene.set("interaction_target_id", "terminal")
	await process_frame
	await create_timer(0.15).timeout
	await _capture("02_terminal_highlight.png")
	scene.set("interaction_running", false)
	scene.set("interaction_target_id", "")

	await process_frame
	await _capture("03_door_suit_unlocked.png")

	if areas.has("power_distribution_room"):
		areas["power_distribution_room"]["unlocked"] = false
	await process_frame
	await create_timer(0.15).timeout
	await _capture("04_door_power_locked.png")

	if areas.has("greenhouse_room"):
		areas["greenhouse_room"]["unlocked"] = true
	await process_frame
	await create_timer(0.15).timeout
	await _capture("05_door_greenhouse_unlocked.png")

	_done = true
	quit()

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
