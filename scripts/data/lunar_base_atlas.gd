extends RefCounted
class_name LunarBaseAtlas

## Shared reader for assets/material/lunar_base_modular_atlas.png + .json (116
## regions, Smart Sprite Sheet Packer schema: frames."<name>.png".frame.{x,y,w,h}).
## Frame rects below are copied directly from the JSON for the subset TR-002's
## training hub reconstruction actually uses -- add more entries here (from
## the same JSON) rather than hardcoding a Rect2i elsewhere if another room
## needs a different region later.

const AtlasTexture_ := preload("res://assets/material/lunar_base_modular_atlas.png")

const FRAMES := {
	"floor_plate_plain": Rect2i(145, 824, 115, 115),
	"floor_plate_seamed": Rect2i(145, 689, 115, 115),
	"floor_plate_quad": Rect2i(808, 965, 107, 115),
	"floor_plate_cracked": Rect2i(153, 1534, 113, 117),
	"floor_plate_damaged": Rect2i(403, 1549, 77, 141),
	"floor_grate_square": Rect2i(415, 828, 113, 117),
	"floor_vent_rectangular": Rect2i(153, 1671, 113, 115),
	"wall_segment_horizontal": Rect2i(177, 1443, 101, 55),
	"wall_segment_short": Rect2i(308, 1075, 105, 51),
	"wall_corner_inner_top_left": Rect2i(280, 786, 115, 67),
	"wall_corner_inner_top_right": Rect2i(825, 658, 113, 99),
	"wall_corner_inner_bottom_left": Rect2i(699, 1352, 89, 121),
	"wall_corner_inner_bottom_right": Rect2i(1062, 1078, 105, 89),
	"wall_corner_outer_left": Rect2i(165, 974, 123, 85),
	"wall_corner_outer_top_right": Rect2i(692, 752, 113, 89),
	"wall_corner_outer_bottom_left": Rect2i(310, 1365, 87, 73),
	"wall_connector_t": Rect2i(584, 1170, 101, 71),
	"wall_cap_end": Rect2i(417, 1392, 85, 137),
	"pipe_straight_long": Rect2i(1290, 304, 178, 125),
	"pipe_elbow_short": Rect2i(559, 324, 176, 57),
	"pipe_elbow_long": Rect2i(559, 206, 125, 69),
	"pipe_corner_large": Rect2i(10, 433, 184, 125),
	"pipe_support_vertical": Rect2i(951, 1176, 89, 156),
	"pipe_support_tall": Rect2i(286, 1575, 75, 145),
	"pipe_junction_t": Rect2i(286, 1740, 75, 127),
	"equipment_pipe_valve": Rect2i(832, 1176, 99, 154),
	"equipment_pipe_endcap": Rect2i(474, 1710, 71, 137),
	"equipment_pump_vertical": Rect2i(820, 1350, 89, 141),
	"equipment_power_cabinet": Rect2i(1656, 1128, 151, 160),
	"console_command_center": Rect2i(1631, 10, 220, 164),
	"console_status_panel": Rect2i(825, 777, 109, 168),
	"console_terminal_compact": Rect2i(1518, 194, 178, 158),
	"grow_light_dual": Rect2i(941, 330, 166, 42),
	"grow_light_pair": Rect2i(941, 594, 164, 44),
	"ui_icon_power": Rect2i(1081, 951, 107, 107),
	"ui_icon_plant": Rect2i(330, 1155, 107, 105),
}

static func region(name: String) -> AtlasTexture:
	var r: Rect2i = FRAMES[name]
	var tex := AtlasTexture.new()
	tex.atlas = AtlasTexture_
	tex.region = Rect2(r.position, r.size)
	tex.filter_clip = true
	return tex
