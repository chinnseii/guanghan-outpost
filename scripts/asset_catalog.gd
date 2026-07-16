extends RefCounted

const PLAYER_TEXTURE_PATHS := {
	"astronaut_walk": "res://assets/sprites/player/astronaut_walk.png",
}

## Character appearance registry (2026-07-17): each appearance_id is a
## COMPLETE character walk-cycle sheet (not a hair-only overlay -- per the
## designer's own handoff, different appearances' bodies/hair must never be
## mixed). All three share the same contract: 6 cols (frames 00-05) x 4 rows
## (down/left/right/up), 8 FPS -- only native frame_size differs per pack, so
## player_visual.gd derives its on-screen DISPLAY_SIZE from whichever
## frame_size this returns rather than assuming a fixed constant.
const DEFAULT_PLAYER_APPEARANCE := "female_light_black_longhair"
const PLAYER_APPEARANCE_TEXTURE_PATHS := {
	"female_light_black_longhair": "res://assets/sprites/player/astronaut_walk.png",
	"female_light_black_ponytail": "res://assets/characters/player_preview/female/light/black/walk_cycle_ponytail.png",
	"female_light_black_shorthair": "res://assets/characters/player_preview/female/light/black/walk_cycle_shorthair.png",
}
const PLAYER_APPEARANCE_FRAME_SIZE := {
	"female_light_black_longhair": Vector2(128, 128),
	"female_light_black_ponytail": Vector2(256, 256),
	"female_light_black_shorthair": Vector2(256, 256),
}

const FACILITY_TEXTURE_PATHS := {
	"bed": "res://assets/sprites/facilities/bed.png",
	"storage": "res://assets/sprites/facilities/storage.png",
	"console": "res://assets/sprites/facilities/console.png",
	"robot_charger": "res://assets/sprites/facilities/robot_charger.png",
	"airlock_door": "res://assets/sprites/facilities/airlock_door.png",
	"life_support_tank": "res://assets/sprites/facilities/life_support_tank.png",
	"greenhouse_bed": "res://assets/sprites/facilities/greenhouse_bed.png",
	"solar_panel": "res://assets/sprites/facilities/solar_panel.png",
}

const ROBOT_TEXTURE_PATHS := {
	"sample": "res://assets/sprites/robots/yutu_sample.png",
	"maintenance": "res://assets/sprites/robots/maintenance_bot.png",
	"haul": "res://assets/sprites/robots/hauler_bot.png",
}

const COLLECTABLE_TEXTURE_PATHS := {
	"regolith": "res://assets/sprites/collectables/regolith_node.png",
	"ice": "res://assets/sprites/collectables/ice_node.png",
	"meteor": "res://assets/sprites/collectables/meteor_node.png",
	"sample": "res://assets/sprites/collectables/sample_node.png",
	"supply_pod": "res://assets/sprites/collectables/supply_pod.png",
}

const STATUS_COLORS := {
	"ready": Color("#7dff9d"),
	"charging": Color("#72f2ff"),
	"oxygen": Color("#98d5ff"),
	"water": Color("#9fd7ff"),
	"highlight": Color("#e7c66b"),
	"warning": Color("#ff8a6b"),
	"danger": Color("#ff5a5a"),
	"dust": Color("#d1a15b"),
	"cargo": Color("#d68b52"),
	"inactive": Color("#8792a0"),
}

static func player_texture_path(name: String) -> String:
	return String(PLAYER_TEXTURE_PATHS.get(name, ""))

static func player_appearance_texture_path(appearance_id: String) -> String:
	if PLAYER_APPEARANCE_TEXTURE_PATHS.has(appearance_id):
		return String(PLAYER_APPEARANCE_TEXTURE_PATHS[appearance_id])
	return String(PLAYER_APPEARANCE_TEXTURE_PATHS[DEFAULT_PLAYER_APPEARANCE])

static func player_appearance_frame_size(appearance_id: String) -> Vector2:
	if PLAYER_APPEARANCE_FRAME_SIZE.has(appearance_id):
		return PLAYER_APPEARANCE_FRAME_SIZE[appearance_id]
	return PLAYER_APPEARANCE_FRAME_SIZE[DEFAULT_PLAYER_APPEARANCE]

static func facility_texture_path(name: String) -> String:
	return String(FACILITY_TEXTURE_PATHS.get(name, ""))

static func robot_texture_path(name: String) -> String:
	return String(ROBOT_TEXTURE_PATHS.get(name, ""))

static func collectable_texture_path(name: String) -> String:
	return String(COLLECTABLE_TEXTURE_PATHS.get(name, ""))

static func status_color(name: String, fallback: Color = Color.WHITE) -> Color:
	return STATUS_COLORS.get(name, fallback)

static func load_png_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if FileAccess.file_exists("%s.import" % path):
		var imported: Resource = ResourceLoader.load(path)
		if imported is Texture2D:
			return imported as Texture2D
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)
