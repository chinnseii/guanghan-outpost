extends RefCounted
class_name CharacterAppearanceCatalog

## Character appearance system (2026-07-17): resolves a player's chosen
## gender/skin_tone/hair_color/hairstyle into a walk-cycle sprite sheet.
##
## The attribute vocabulary here deliberately MIRRORS the ids already chosen
## by the AUI-03-03 character-creation flow (scripts/application/
## application_flow_scene.gd's SKIN_TONE_OPTIONS / HAIR_COLOR_OPTIONS /
## HAIR_STYLE_OPTIONS_MALE / HAIR_STYLE_OPTIONS_FEMALE, and PlayerProfileData's
## gender_display) rather than inventing a separate one -- a profile captured
## at character creation maps onto this catalog with zero translation beyond
## gender_display's "男"/"女" -> "female"/"male" (see gender_id_from_display()).
##
## Extensibility: WALK_CYCLE_REGISTRY is intentionally sparse -- most
## gender/skin/hair_color/hairstyle combinations have no walk-cycle art yet
## (only a static character-creation preview portrait exists for them, at
## assets/characters/player_preview/<gender>/<skin>/<hair_color>/sprite.png).
## Adding a new combo once its art is ready is a ONE-LINE addition here (drop
## the file at the conventional path below, add one registry entry) -- no
## other script needs to change. Missing combos gracefully resolve() to a
## per-gender fallback instead of erroring or falling through to
## player_visual.gd's hand-drawn placeholder shape.

## Vocabulary unification (2026-07-17, user/FEMALE_HAIR_AND_SKIN_HANDOFF.md):
## hair color is now canonically "blonde" (was "blond") to match the design
## spec exactly, including a matching rename of `application_flow_scene.gd`'s
## HAIR_COLOR_OPTIONS id and the asset folder
## (assets/characters/player_preview/<gender>/<skin>/blonde/). Backward
## compat for profiles saved before this rename: both this catalog's
## load_selected_appearance() and application_flow_scene.gd's
## _normalize_appearance_selection() remap a stored "blond" to "blonde"
## before matching, so old saves don't silently lose their hair color.
## Skin tone deliberately STAYS "light/medium/dark" (the handoff's suggested
## "light/warm/deep" was explicitly declined by the user, and reasserted --
## still declined -- in a later handoff for the male hairstyle packs, which
## suggested tagging them skin_tone="warm"; they're registered as "medium"
## below instead) -- only "light"/"medium" skin art exists so far, so this
## doesn't block anything yet; revisit if/when skin masks (see
## WALK_CYCLE_REGISTRY's frame_size doc comment) ship and need real
## medium/dark skin_tone values to shade against.
## Asset-naming vs. hairstyle-id mismatches (handoffs use fuller/different
## words than the shipped HAIR_STYLE_OPTIONS_MALE ids) are resolved the same
## way each time: keep the shipped id as the registry key, regardless of
## what the source zip/appearance_id calls it. So far: "buzzcut" -> "buzz",
## "shortfringe" -> "short", "longhair" -> "long" (male,
## user/MALE_HAIRSTYLE_PACK_HANDOFF.md). male_medium_black_wavy_walk.zip was
## explicitly excluded per that handoff (superseded by the longhair pack) --
## never imported.
const GENDERS := ["female", "male"]
const SKIN_TONES := ["light", "medium", "dark"]
const HAIR_COLORS := ["black", "blonde", "auburn"]
const HAIRSTYLES_BY_GENDER := {
	"male": ["buzz", "short", "long"],
	"female": ["short", "ponytail", "long"],
}

## path: the walk-cycle sheet, 6 cols (frames 00-05) x 4 rows (down/left/
## right/up), 8 FPS -- the one contract every registered entry must follow.
## frame_size: native cell size of that specific sheet (varies per pack --
## see PLAYER-VISUAL-01 notes in docs/handoff/ACTIVE_TASKS.md for why: some
## packs are pre-scaled offline to avoid GPU-minification aliasing at this
## character's ~56px on-screen height, others are safe to use at native res).
const WALK_CYCLE_REGISTRY := {
	"female_light_black_long": {
		"path": "res://assets/characters/player_preview/female/light/black/walk_cycle_long.png",
		"frame_size": Vector2(128, 128),
	},
	"female_light_black_ponytail": {
		"path": "res://assets/characters/player_preview/female/light/black/walk_cycle_ponytail.png",
		"frame_size": Vector2(256, 256),
	},
	"female_light_black_short": {
		"path": "res://assets/characters/player_preview/female/light/black/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"male_medium_black_buzz": {
		"path": "res://assets/characters/player_preview/male/medium/black/walk_cycle_buzz.png",
		"frame_size": Vector2(256, 256),
	},
	"female_light_blonde_long": {
		"path": "res://assets/characters/player_preview/female/light/blonde/walk_cycle_long.png",
		"frame_size": Vector2(256, 256),
	},
	"female_light_blonde_ponytail": {
		"path": "res://assets/characters/player_preview/female/light/blonde/walk_cycle_ponytail.png",
		"frame_size": Vector2(256, 256),
	},
	"female_light_blonde_short": {
		"path": "res://assets/characters/player_preview/female/light/blonde/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"female_light_auburn_long": {
		"path": "res://assets/characters/player_preview/female/light/auburn/walk_cycle_long.png",
		"frame_size": Vector2(256, 256),
	},
	"female_light_auburn_ponytail": {
		"path": "res://assets/characters/player_preview/female/light/auburn/walk_cycle_ponytail.png",
		"frame_size": Vector2(256, 256),
	},
	"female_light_auburn_short": {
		"path": "res://assets/characters/player_preview/female/light/auburn/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"male_medium_blonde_buzz": {
		"path": "res://assets/characters/player_preview/male/medium/blonde/walk_cycle_buzz.png",
		"frame_size": Vector2(256, 256),
	},
	"male_medium_auburn_buzz": {
		"path": "res://assets/characters/player_preview/male/medium/auburn/walk_cycle_buzz.png",
		"frame_size": Vector2(256, 256),
	},
	"male_medium_black_short": {
		"path": "res://assets/characters/player_preview/male/medium/black/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"male_medium_blonde_short": {
		"path": "res://assets/characters/player_preview/male/medium/blonde/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"male_medium_auburn_short": {
		"path": "res://assets/characters/player_preview/male/medium/auburn/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"male_medium_black_long": {
		"path": "res://assets/characters/player_preview/male/medium/black/walk_cycle_long.png",
		"frame_size": Vector2(256, 256),
	},
	"male_medium_blonde_long": {
		"path": "res://assets/characters/player_preview/male/medium/blonde/walk_cycle_long.png",
		"frame_size": Vector2(256, 256),
	},
	"male_medium_auburn_long": {
		"path": "res://assets/characters/player_preview/male/medium/auburn/walk_cycle_long.png",
		"frame_size": Vector2(256, 256),
	},
}

## Which registered appearance to substitute when the player's exact combo
## isn't in WALK_CYCLE_REGISTRY yet (still being generated).
const FALLBACK_APPEARANCE_BY_GENDER := {
	"female": "female_light_black_long",
	"male": "male_medium_black_buzz",
}

## Where application_flow_scene.gd saves the character-creation profile.
const PROFILE_PATH := "user://saves/application_profile.json"

static func appearance_key(gender: String, skin_tone: String, hair_color: String, hairstyle: String) -> String:
	return "%s_%s_%s_%s" % [gender, skin_tone, hair_color, hairstyle]

static func is_available(gender: String, skin_tone: String, hair_color: String, hairstyle: String) -> bool:
	return WALK_CYCLE_REGISTRY.has(appearance_key(gender, skin_tone, hair_color, hairstyle))

## Returns {"key", "path", "frame_size", "is_fallback"}. "key" is the
## appearance_id actually resolved to -- equal to the requested combo when
## available, otherwise the per-gender fallback (with is_fallback = true).
static func resolve(gender: String, skin_tone: String, hair_color: String, hairstyle: String) -> Dictionary:
	var requested_key := appearance_key(gender, skin_tone, hair_color, hairstyle)
	if WALK_CYCLE_REGISTRY.has(requested_key):
		var entry: Dictionary = WALK_CYCLE_REGISTRY[requested_key]
		return {"key": requested_key, "path": entry["path"], "frame_size": entry["frame_size"], "is_fallback": false}
	var fallback_gender := gender if FALLBACK_APPEARANCE_BY_GENDER.has(gender) else "female"
	var fallback_key: String = FALLBACK_APPEARANCE_BY_GENDER[fallback_gender]
	var fallback_entry: Dictionary = WALK_CYCLE_REGISTRY[fallback_key]
	return {"key": fallback_key, "path": fallback_entry["path"], "frame_size": fallback_entry["frame_size"], "is_fallback": true}

## Converts PlayerProfileData's gender_display ("男"/"女") to this catalog's
## gender id -- the one place that translation happens.
static func gender_id_from_display(gender_display: String) -> String:
	return "female" if gender_display == "女" else "male"

## All currently-registered appearance_ids, for dev/testing tools that want
## to iterate everything actually available (e.g. the Dev Menu's appearance
## cycle button) instead of maintaining a separate hardcoded list that goes
## stale as new combos are registered.
static func all_registered_keys() -> Array:
	return WALK_CYCLE_REGISTRY.keys()

## Reads the character-creation profile (scripts/application/
## application_flow_scene.gd's PROFILE_PATH/_save_profile()) and returns the
## 4 attributes set_character_appearance() needs. Falls back to the default
## appearance's attributes if no profile exists yet (e.g. entering the
## Survival Sandbox directly via the Dev Menu, skipping character creation
## entirely) or if it's malformed.
static func load_selected_appearance() -> Dictionary:
	var defaults := {
		"gender": "female",
		"skin_tone": "light",
		"hair_color": "black",
		"hairstyle": "long",
	}
	if not FileAccess.file_exists(PROFILE_PATH):
		return defaults
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return defaults
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return defaults
	var data: Dictionary = parsed
	var gender_display := String(data.get("GenderDisplay", "女"))
	var hair_color := String(data.get("HairColorPreset", defaults["hair_color"]))
	if hair_color == "blond":
		hair_color = "blonde"
	return {
		"gender": gender_id_from_display(gender_display),
		"skin_tone": String(data.get("SkinPreset", defaults["skin_tone"])),
		"hair_color": hair_color,
		"hairstyle": String(data.get("HairPreset", defaults["hairstyle"])),
	}
