extends RefCounted

## "astronaut_walk" is the pre-appearance-system fixed player texture path.
## Superseded 2026-07-17 by scripts/data/character_appearance_catalog.gd
## (gender/skin/hair_color/hairstyle-driven lookup) -- player_visual.gd no
## longer reads this. Left here (and the underlying file left in place,
## still holding the default female_light_black_long content) rather than
## deleted, since nothing else was confirmed to depend on removing it.
const PLAYER_TEXTURE_PATHS := {
	"astronaut_walk": "res://assets/sprites/player/astronaut_walk.png",
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
