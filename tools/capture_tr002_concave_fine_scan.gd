extends SceneTree

## Position-based (not path-based) hunt for the "invisible wall depends on
## approach angle" symptom: since _footprint_hits_anything() is a pure
## function of position, a real instance of this bug must show up as an
## isolated blocked patch immediately surrounded by open cells near a concave
## (reflex) vertex of the room_boundary polygon -- the axis-aligned footprint
## rect's corner clipping a non-axis-aligned edge from some positions but not
## adjacent ones. Fine grid scan (3px steps) around each reflex vertex.

const SCENE := "res://scenes/training/TrainingBaseMap.tscn"

const CANDIDATES: Array = [
	["top_door_west_shoulder", Vector2(350, 101.5)],
	["top_door_east_shoulder", Vector2(430.5, 99)],
	["air_door_north_shoulder", Vector2(652, 226.5)],
	["air_door_south_shoulder", Vector2(654, 277)],
	["greenhouse_door_east_shoulder", Vector2(584.5, 408.5)],
	["greenhouse_door_west_shoulder", Vector2(427.5, 431.5)],
	["crate_notch_east", Vector2(338.5, 427)],
	["crate_notch_mid", Vector2(173.5, 406.5)],
	["crate_notch_west", Vector2(131.5, 390.5)],
	["suit_door_south_shoulder", Vector2(101.5, 280.5)],
	["suit_door_north_shoulder", Vector2(110.5, 215.5)],
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame

	var module_data: Dictionary = scene.get("module_data")
	var player: Control = scene.get("player")
	var boundaries: Array = module_data.get("room_boundary_polygons", [])
	var blockers: Array = module_data.get("blockers", [])

	for entry in CANDIDATES:
		var label: String = entry[0]
		var vertex: Vector2 = entry[1]
		print("--- ", label, " around ", vertex, " ---")
		var y := vertex.y - 18.0
		while y <= vertex.y + 18.0:
			var row := ""
			var x := vertex.x - 18.0
			while x <= vertex.x + 18.0:
				var feet_design := Vector2(x, y)
				var room_feet: Vector2 = scene.call("_room_point", feet_design)
				var room_top_left: Vector2 = room_feet - Vector2(player.size.x * 0.5, player.size.y)
				var blocked: bool = scene.call("_footprint_hits_anything", room_top_left, blockers, boundaries)
				row += "#" if blocked else "."
				x += 3.0
			print(row)
			y += 3.0

	quit()
