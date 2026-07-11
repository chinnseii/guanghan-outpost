extends Node2D

## 近基地月面 Chunk（分块世界的第一块，也是本轮唯一激活的一块）。
##
## 职责边界（刻意收窄）：这个脚本只负责"近基地这一块地表里有什么"——地面显示、
## 气闸/返航锚点、近区固定地标、Chunk 边界、以及未来遗址入口的占位标记，外加把
## 这些位置抽成集中配置（chunk_id / origin / size / spawn / landmark / exit）。
##
## 它【不】负责：全局时间、氧气/电力结算、存档总流程、世界级场景切换、玩家/相机。
## 这些仍由世界容器 lunar_surface_scene.gd（LunarSurfaceWorld）和现有 autoload
## Manager 负责。世界容器实例化本 Chunk 后，通过 get_bounds()/get_spawn_point()/
## get_anchor_point() 等只读方法拿位置，不反向依赖世界容器。
##
## ── 坐标契约 / Coordinate contract ──────────────────────────────────────────
## - CHUNK_ORIGIN 是本 Chunk 的世界原点（world-space origin）。Chunk 的世界位置
##   只由 CHUNK_ORIGIN 这个【数据】负责。
## - 静态内容以局部偏移 authoring：ANCHOR_LOCAL 相对 CHUNK_ORIGIN；SPAWN_OFFSET
##   相对锚点；地标/出口用 anchor_offset（相对锚点）。任何一处世界坐标都 =
##   CHUNK_ORIGIN + 局部偏移链算出来，绝不依赖 Node2D 的 transform。
## - 公开的空间 getter 一律返回 world-space 值（get_bounds / get_anchor_point /
##   get_spawn_point / get_landmark_points / get_exit_points），且返回的是【副本】，
##   不把内部 const 引用暴露给调用方。（若未来要暴露未转换的原始 metadata，方法名
##   必须显式含 "defs" 或 "local" 以示区别。）
## - 本 Chunk 的 Node2D 始终停在世界原点 (0,0)，【不要】再用节点 transform 承担
##   origin 偏移，否则会和 CHUNK_ORIGIN 叠加成双重偏移。未来第二块设
##   CHUNK_ORIGIN=(12288,0) 时，Node2D 仍在 (0,0)，全部 bounds/anchor/spawn/
##   landmark/exit 由脚本统一加 origin。
## ────────────────────────────────────────────────────────────────────────────

const TILE := 64

## -- Chunk 配置（集中在此，避免散落硬编码世界绝对坐标） --
const CHUNK_ID := "near_base"
const CHUNK_ORIGIN := Vector2.ZERO
## 近区尺度按玩法标定：满氧安全返航半径 R≈100/(oxygen_per_px 0.012 × 安全系数 1.35)
## ≈6173px≈96 格。取 192×192 格（12288×12288px），锚点居中 → 墙约在 R 处，让"氧气
## 预算"而不是"世界边界"成为实际限制，同时不为尚未实现的月球车预留大片空白。
const CHUNK_TILES := Vector2i(192, 192)

## 锚点（气闸/返航补给点）相对 CHUNK_ORIGIN；出生点相对锚点（气闸外侧一点，玩家
## "刚出舱站在月面"，既不在锚点正中央、也绝不在地图边缘）。
const ANCHOR_LOCAL := Vector2(CHUNK_TILES.x * TILE / 2.0, CHUNK_TILES.y * TILE / 2.0)
const SPAWN_OFFSET := Vector2(0, 130)

## 固定、可识别、可复现的近基地导航地标。anchor_offset = 相对锚点的偏移（authoring
## 方便：都围绕气闸摆），全部落在安全返航半径内。kind 仅用于配色/取名，本轮不驱动
## 任何交互逻辑。对外由 get_landmark_points() 转成 world_position 副本。
const LANDMARK_POINTS := [
	{"id": "airlock", "name": "气闸 / 返航补给", "kind": "airlock", "anchor_offset": Vector2(0, 0)},
	{"id": "solar_near", "name": "太阳能阵列（近区）", "kind": "solar", "anchor_offset": Vector2(-1800, -600)},
	{"id": "comms_antenna", "name": "通信天线", "kind": "comms", "anchor_offset": Vector2(1500, -1400)},
	{"id": "rover_pad", "name": "月球车平台（占位）", "kind": "rover_pad", "anchor_offset": Vector2(2000, 1200)},
	{"id": "repair_point", "name": "维修点", "kind": "repair", "anchor_offset": Vector2(-1400, 1600)},
	{"id": "rille_feature", "name": "月面沟纹地形", "kind": "terrain", "anchor_offset": Vector2(900, 2400)},
]

## 未来遗址入口占位点：仅作为标记 + 数据，本轮不创建遗址内部、不触发场景切换。
## enabled=false，target_scene 留空，世界容器/未来的入口逻辑据此判断"还没开放"。
## anchor_offset 同地标，相对锚点。
const EXIT_POINTS := [
	{"id": "ruins_entrance", "name": "遗址入口（未开放）", "target_scene": "", "enabled": false, "anchor_offset": Vector2(-2600, 200)},
]

func _ready() -> void:
	_build_ground()
	_build_landmarks()
	_build_exit_markers()

## -- 只读接口：供 LunarSurfaceWorld 查询，全部 world-space，返回副本 --

func chunk_size() -> Vector2:
	return Vector2(CHUNK_TILES.x * TILE, CHUNK_TILES.y * TILE)

## Returns this chunk's world-space bounds.
func get_bounds() -> Rect2:
	return Rect2(CHUNK_ORIGIN, chunk_size())

## Returns the airlock / return-anchor position in world-space.
func get_anchor_point() -> Vector2:
	return CHUNK_ORIGIN + ANCHOR_LOCAL

## Returns the player spawn position (just outside the airlock) in world-space.
func get_spawn_point() -> Vector2:
	return CHUNK_ORIGIN + ANCHOR_LOCAL + SPAWN_OFFSET

## Returns navigation landmarks as world-space copies: {id, name, kind, world_position}.
## Copies only -- callers never get a reference to the internal LANDMARK_POINTS const.
func get_landmark_points() -> Array:
	var out: Array = []
	for lm in LANDMARK_POINTS:
		out.append({
			"id": lm["id"],
			"name": lm["name"],
			"kind": lm["kind"],
			"world_position": _content_world_position(lm),
		})
	return out

## Returns exit placeholders as world-space copies: {id, name, target_scene, enabled, world_position}.
func get_exit_points() -> Array:
	var out: Array = []
	for ex in EXIT_POINTS:
		out.append({
			"id": ex["id"],
			"name": ex["name"],
			"target_scene": ex["target_scene"],
			"enabled": ex["enabled"],
			"world_position": _content_world_position(ex),
		})
	return out

## anchor_offset (相对锚点) → world-space。地标与出口共用同一条转换链，保证"世界坐标
## 只由 CHUNK_ORIGIN + 偏移链算出"这条契约唯一。
func _content_world_position(item: Dictionary) -> Vector2:
	return CHUNK_ORIGIN + ANCHOR_LOCAL + item["anchor_offset"]

## -- Build（本 Chunk 自己的视觉内容） --

## 地面 = 一张 256x256 程序化风化层纹理，用 Sprite2D + region + texture_repeat 铺满
## 本 Chunk。成本 O(1)，与 Chunk 尺寸无关（渲染只按视口光栅化）。TileMap 留给未来
## "只在有地形处铺"的局部地貌（山脊/峡谷），不用来铺均匀月壤。
func _build_ground() -> void:
	var ground := Sprite2D.new()
	ground.name = "MoonGround"
	ground.texture = _create_moon_ground_texture()
	ground.centered = false
	ground.position = CHUNK_ORIGIN
	ground.z_index = -5
	ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.region_enabled = true
	ground.region_rect = Rect2(Vector2.ZERO, chunk_size())
	add_child(ground)

## 256x256 程序化月壤瓦片（颗粒 + 环绕式陨坑，接缝大致无感），无需美术资源。
func _create_moon_ground_texture() -> Texture2D:
	var dim := 256
	var image := Image.create(dim, dim, false, Image.FORMAT_RGBA8)
	for px in range(dim):
		for py in range(dim):
			var g := 0.12 + float((px * 13 + py * 7) % 23) * 0.0018
			image.set_pixel(px, py, Color(g * 0.9, g * 0.92, g + 0.02, 1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	for c in range(12):
		var cx := rng.randi_range(0, dim - 1)
		var cy := rng.randi_range(0, dim - 1)
		var r := rng.randf_range(10.0, 28.0)
		for px in range(dim):
			for py in range(dim):
				var wdx: float = min(abs(px - cx), dim - abs(px - cx))
				var wdy: float = min(abs(py - cy), dim - abs(py - cy))
				var d := sqrt(wdx * wdx + wdy * wdy)
				if d < r:
					var col := image.get_pixel(px, py)
					var g: float = clamp(col.b - 0.02 - 0.03 * (1.0 - d / r), 0.06, 0.24)
					image.set_pixel(px, py, Color(g * 0.9, g * 0.92, g + 0.02, 1.0))
	return ImageTexture.create_from_image(image)

## 固定近基地地标（含气闸锚点）。每个地标一个色块 + 标签，世界坐标经 world-space
## 接口统一算出。不再向巨大空世界随机撒点。
func _build_landmarks() -> void:
	for lm in LANDMARK_POINTS:
		var world_pos: Vector2 = _content_world_position(lm)
		if String(lm["id"]) == "airlock":
			_build_airlock_anchor(world_pos, String(lm["name"]))
		else:
			_build_landmark_marker(world_pos, String(lm["name"]), _landmark_color(String(lm["kind"])))

func _build_airlock_anchor(world_pos: Vector2, label_text: String) -> void:
	var pad := ColorRect.new()
	pad.color = Color("#3d5a74")
	pad.size = Vector2(120, 90)
	pad.position = world_pos - pad.size * 0.5
	pad.z_index = -2
	add_child(pad)
	var label := Label.new()
	label.text = label_text
	label.modulate = Color("#cfe3f2")
	label.position = world_pos + Vector2(-60, -70)
	label.z_index = 40
	add_child(label)

func _build_landmark_marker(world_pos: Vector2, label_text: String, color: Color) -> void:
	var marker := ColorRect.new()
	marker.color = color
	marker.size = Vector2(64, 46)
	marker.position = world_pos - marker.size * 0.5
	marker.z_index = -3
	add_child(marker)
	var label := Label.new()
	label.text = label_text
	label.modulate = Color("#9fb3c4")
	label.add_theme_font_size_override("font_size", 14)
	label.position = world_pos + Vector2(-52, -46)
	label.z_index = 39
	add_child(label)

## 遗址入口占位标记：只画一个"未开放"提示，不加碰撞、不接场景切换。
func _build_exit_markers() -> void:
	for ex in EXIT_POINTS:
		var world_pos: Vector2 = _content_world_position(ex)
		var marker := ColorRect.new()
		marker.color = Color("#5a4a3a")
		marker.size = Vector2(70, 52)
		marker.position = world_pos - marker.size * 0.5
		marker.z_index = -3
		add_child(marker)
		var label := Label.new()
		label.text = String(ex["name"])
		label.modulate = Color("#c8b79a")
		label.add_theme_font_size_override("font_size", 14)
		label.position = world_pos + Vector2(-56, -48)
		label.z_index = 39
		add_child(label)

func _landmark_color(kind: String) -> Color:
	match kind:
		"solar":
			return Color("#2f5566")
		"comms":
			return Color("#4a4f66")
		"rover_pad":
			return Color("#54463a")
		"repair":
			return Color("#5a4352")
		"terrain":
			return Color("#3a3f44")
	return Color("#404652")
