extends RefCounted
class_name CharacterAppearanceCatalog

## Character appearance system (2026-07-17): resolves a player's chosen
## gender/hair_color/hairstyle into a walk-cycle sprite sheet, with skin_tone
## applied SEPARATELY and orthogonally via the Round 13 skin-mask shader
## (see SKIN_MASK_REGISTRY/SKIN_PALETTE below and player_visual.gd's
## _apply_skin_tone()) -- skin_tone is intentionally NOT part of
## WALK_CYCLE_REGISTRY's key. It used to be, through Round 13, which caused a
## real bug: any skin_tone other than each gender's one "reference" art tier
## (light for female, medium for male) failed to find a registry match and
## fell all the way back to a DIFFERENT hair_color/hairstyle too (see
## FALLBACK_APPEARANCE_BY_GENDER) -- so picking, say, female + dark skin
## silently discarded the player's chosen hairstyle/color as well, and the
## face/hand recoloring the mask system already correctly ports across
## rendered as a barely-noticeable detail on top of an otherwise-wrong
## character. The fix: the registry only needs to know gender/hair_color/
## hairstyle (skin tone never changes which SHEET is used, only how the
## shader recolors it), so every registered combo now supports all 3 skin
## tones for free -- no additional walk-cycle art needed per skin tone.
##
## The attribute vocabulary here deliberately MIRRORS the ids already chosen
## by the AUI-03-03 character-creation flow (scripts/application/
## application_flow_scene.gd's SKIN_TONE_OPTIONS / HAIR_COLOR_OPTIONS /
## HAIR_STYLE_OPTIONS_MALE / HAIR_STYLE_OPTIONS_FEMALE, and PlayerProfileData's
## gender_display) rather than inventing a separate one -- a profile captured
## at character creation maps onto this catalog with zero translation beyond
## gender_display's "男"/"女" -> "female"/"male" (see gender_id_from_display()).
##
## Extensibility: WALK_CYCLE_REGISTRY is intentionally sparse -- gender/
## hair_color/hairstyle combinations with no walk-cycle art yet (only a
## static character-creation preview portrait exists for them, at
## assets/characters/player_preview/<gender>/<skin>/<hair_color>/sprite.png)
## gracefully resolve() to a per-gender fallback instead of erroring.
## Adding a new combo once its art is ready is a ONE-LINE addition (drop the
## file at the conventional path, add one registry entry) -- no other script
## needs to change.

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
## "light/warm/deep" was explicitly declined by the user multiple times) --
## bridged to the delivered palette's own "light/warm/deep" ids only inside
## SKIN_TONE_TO_PALETTE_KEY below.
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
## Keyed "<gender>_<hair_color>_<hairstyle>" -- NOT skin_tone, see the
## top-of-file note. Each sheet was authored at one specific skin tone
## (female packs at "light", male packs at "medium"), but the shader's
## skin-mask system recolors face/hands to whatever skin_tone the character
## actually has, independent of which tier the base art happened to be drawn
## at -- so these sheets serve all 3 skin tones already.
const WALK_CYCLE_REGISTRY := {
	"female_black_long": {
		"path": "res://assets/characters/player_preview/female/light/black/walk_cycle_long.png",
		"frame_size": Vector2(128, 128),
	},
	"female_black_ponytail": {
		"path": "res://assets/characters/player_preview/female/light/black/walk_cycle_ponytail.png",
		"frame_size": Vector2(256, 256),
	},
	"female_black_short": {
		"path": "res://assets/characters/player_preview/female/light/black/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"male_black_buzz": {
		"path": "res://assets/characters/player_preview/male/medium/black/walk_cycle_buzz.png",
		"frame_size": Vector2(256, 256),
	},
	"female_blonde_long": {
		"path": "res://assets/characters/player_preview/female/light/blonde/walk_cycle_long.png",
		"frame_size": Vector2(256, 256),
	},
	"female_blonde_ponytail": {
		"path": "res://assets/characters/player_preview/female/light/blonde/walk_cycle_ponytail.png",
		"frame_size": Vector2(256, 256),
	},
	"female_blonde_short": {
		"path": "res://assets/characters/player_preview/female/light/blonde/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"female_auburn_long": {
		"path": "res://assets/characters/player_preview/female/light/auburn/walk_cycle_long.png",
		"frame_size": Vector2(256, 256),
	},
	"female_auburn_ponytail": {
		"path": "res://assets/characters/player_preview/female/light/auburn/walk_cycle_ponytail.png",
		"frame_size": Vector2(256, 256),
	},
	"female_auburn_short": {
		"path": "res://assets/characters/player_preview/female/light/auburn/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"male_blonde_buzz": {
		"path": "res://assets/characters/player_preview/male/medium/blonde/walk_cycle_buzz.png",
		"frame_size": Vector2(256, 256),
	},
	"male_auburn_buzz": {
		"path": "res://assets/characters/player_preview/male/medium/auburn/walk_cycle_buzz.png",
		"frame_size": Vector2(256, 256),
	},
	"male_black_short": {
		"path": "res://assets/characters/player_preview/male/medium/black/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"male_blonde_short": {
		"path": "res://assets/characters/player_preview/male/medium/blonde/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"male_auburn_short": {
		"path": "res://assets/characters/player_preview/male/medium/auburn/walk_cycle_short.png",
		"frame_size": Vector2(256, 256),
	},
	"male_black_long": {
		"path": "res://assets/characters/player_preview/male/medium/black/walk_cycle_long.png",
		"frame_size": Vector2(256, 256),
	},
	"male_blonde_long": {
		"path": "res://assets/characters/player_preview/male/medium/blonde/walk_cycle_long.png",
		"frame_size": Vector2(256, 256),
	},
	"male_auburn_long": {
		"path": "res://assets/characters/player_preview/male/medium/auburn/walk_cycle_long.png",
		"frame_size": Vector2(256, 256),
	},
}

## Which registered appearance to substitute when the player's exact
## gender/hair_color/hairstyle combo isn't in WALK_CYCLE_REGISTRY yet (still
## being generated).
const FALLBACK_APPEARANCE_BY_GENDER := {
	"female": "female_black_long",
	"male": "male_black_buzz",
}

## Skin-tone masking (2026-07-17, user/CHARACTER_SKIN_TONE_HANDOFF.md): keyed
## by gender+hairstyle only -- face/hand shape doesn't change with hair
## color or skin_tone, and the mask's R/G/B channels already encode shadow/
## midtone/highlight generically (the actual color comes from SKIN_PALETTE,
## applied separately by whatever skin_tone the character has). Each mask
## shares the same 6-col x 4-row UV grid as its matching walk-cycle sheet, at
## whatever its own native resolution is (doesn't need to match the albedo
## sheet's resolution -- see player_visual.gd's shader comment).
const SKIN_MASK_REGISTRY := {
	"female_long": "res://assets/characters/skin_masks/female_longhair_skin_mask.png",
	"female_ponytail": "res://assets/characters/skin_masks/female_ponytail_skin_mask.png",
	"female_short": "res://assets/characters/skin_masks/female_shorthair_skin_mask.png",
	"male_buzz": "res://assets/characters/skin_masks/male_buzzcut_skin_mask.png",
	"male_short": "res://assets/characters/skin_masks/male_shortfringe_skin_mask.png",
	"male_long": "res://assets/characters/skin_masks/male_longhair_skin_mask.png",
}

## Copied directly from assets/characters/skin_masks/skin_palette.json (kept
## in sync manually rather than read at runtime, to avoid a JSON parse on
## every appearance change) -- keyed by the handoff's own palette ids
## ("light"/"warm"/"deep"), which are NOT the same as this catalog's
## skin_tone values ("light"/"medium"/"dark"); see SKIN_TONE_TO_PALETTE_KEY.
const SKIN_PALETTE := {
	## Midtones are the approved canonical skin colors. Shadow/highlight retain
	## the mask's pixel-art volume while staying on the same hue family.
	"light": {"shadow": Color("#B69C80"), "midtone": Color("#E3C3A0"), "highlight": Color("#FFE0B8")},
	"warm": {"shadow": Color("#9B6C48"), "midtone": Color("#C3875A"), "highlight": Color("#E9A773")},
	"deep": {"shadow": Color("#5E3825"), "midtone": Color("#7A4A30"), "highlight": Color("#9E6240")},
}
## Maps this catalog's canonical skin_tone values to the palette's ids.
## "medium" -> "warm" and "dark" -> "deep" is intentional, not a typo: the
## catalog kept "light/medium/dark" as its own values (see the vocabulary
## comment above), while the delivered palette itself is keyed "light/warm/
## deep" -- this is the one place that mismatch gets bridged.
const SKIN_TONE_TO_PALETTE_KEY := {
	"light": "light",
	"medium": "warm",
	"dark": "deep",
}

## Where application_flow_scene.gd saves the character-creation profile.
const PROFILE_PATH := "user://saves/application_profile.json"

static func skin_mask_path(gender: String, hairstyle: String) -> String:
	return String(SKIN_MASK_REGISTRY.get("%s_%s" % [gender, hairstyle], ""))

## Returns {"shadow", "midtone", "highlight"} Color values for the given
## skin_tone (falls back to "light" for an unrecognized value).
static func skin_palette_colors(skin_tone: String) -> Dictionary:
	var palette_key: String = SKIN_TONE_TO_PALETTE_KEY.get(skin_tone, "light")
	return SKIN_PALETTE.get(palette_key, SKIN_PALETTE["light"])

static func appearance_key(gender: String, hair_color: String, hairstyle: String) -> String:
	return "%s_%s_%s" % [gender, hair_color, hairstyle]

static func is_available(gender: String, hair_color: String, hairstyle: String) -> bool:
	return WALK_CYCLE_REGISTRY.has(appearance_key(gender, hair_color, hairstyle))

## Returns {"key", "path", "frame_size", "is_fallback"}. "key" is the
## appearance_id actually resolved to -- equal to the requested
## gender/hair_color/hairstyle combo when available, otherwise the
## per-gender fallback (with is_fallback = true). skin_tone is NOT a
## parameter here -- see the top-of-file note; it's applied independently by
## the caller via skin_palette_colors().
static func resolve(gender: String, hair_color: String, hairstyle: String) -> Dictionary:
	var requested_key := appearance_key(gender, hair_color, hairstyle)
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
		"suit_marking_color": "blue",
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
		"suit_marking_color": String(data.get("SuitMarkingColor", defaults["suit_marking_color"])),
	}
