extends Node2D

const TILE := 48
const MAP_W := 22
const MAP_H := 13
const MAP_ORIGIN := Vector2(50, 70)
const PLAYER_SPEED := 190.0
const SAVE_SLOTS := 3
const SAVE_DIR := "user://saves"

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const MODULE_SCENE := preload("res://scenes/module_visual.tscn")
const COLLECTABLE_SCENE := preload("res://scenes/collectable_visual.tscn")

var day := 1
var is_moon_night := false
var game_over := false
var supply_waiting := false
var supply_order: Dictionary = {}
var next_supply_request_day := 1
var supply_travel_days := 3
var current_save_slot := 1
var pending_main_menu := true

var player_pos := Vector2(300, 420)
var player_radius := 14.0
var player_facing := Vector2.DOWN
var walk_phase := 0.0
var was_inside := false
var eva_warning_cooldown := 0.0
var interact_target: Dictionary = {}

var selected_crop := "potato"
var selected_tool := "sampler"
var build_mode := false
var selected_build := ""
var unlocked_techs: Array[String] = []
var completed_missions: Array[String] = []
var log_lines: Array[String] = []
var robot_task := "idle"
var backpack := {
	"regolith": 0.0,
	"ice": 0.0,
	"samples": 0.0,
	"parts": 0.0,
}
var backpack_capacity := 12.0

var solar_dust := 0.12
var oxygen_wear := 0.08
var next_module_uid := 1
var next_collectable_uid := 1

var resources := {
	"power": 76.0,
	"oxygen": 82.0,
	"water": 68.0,
	"food": 50.0,
	"parts": 8.0,
	"integrity": 88.0,
	"regolith": 0.0,
	"ice": 0.0,
	"samples": 0.0,
	"co2": 34.0,
	"humidity": 52.0,
	"pressure": 100.0,
	"suit_o2": 100.0,
	"suit_integrity": 100.0,
	"suit_dust": 0.0,
}

var resource_names := {
	"power": "电力",
	"oxygen": "氧气",
	"water": "水",
	"food": "食物",
	"parts": "维修件",
	"integrity": "完整度",
	"regolith": "月壤",
	"ice": "水冰",
	"samples": "样本",
	"co2": "二氧化碳",
	"humidity": "湿度",
	"pressure": "舱压",
	"suit_o2": "宇航服氧气",
	"suit_integrity": "宇航服耐久",
	"suit_dust": "月尘污染",
}

var tool_defs := {
	"sampler": {"name": "采样铲", "hint": "采集月壤、冰样本和陨石碎片"},
	"brush": {"name": "除尘刷", "hint": "清理太阳能阵列月尘"},
	"repair": {"name": "维修枪", "hint": "维护生命维持设备"},
}

var crop_defs := {
	"potato": {"name": "土豆", "days": 4, "water": 5.0, "oxygen": 2.0, "food": 22.0, "note": "可靠主粮"},
	"algae": {"name": "藻类", "days": 2, "water": 3.0, "oxygen": 10.0, "food": 7.0, "note": "产氧强，口感差"},
	"mushroom": {"name": "菌菇", "days": 3, "water": 2.0, "oxygen": 0.0, "food": 13.0, "note": "低光照也能生产"},
}

var module_defs := {
	"hab": {
		"name": "居住舱",
		"size": Vector2i(3, 2),
		"cost": {"parts": 0.0, "power": 0.0},
		"color": Color("#596575"),
		"hint": "广寒前哨核心舱",
	},
	"greenhouse": {
		"name": "小型温室",
		"size": Vector2i(4, 2),
		"cost": {"parts": 4.0, "power": 8.0},
		"color": Color("#244638"),
		"hint": "E：播种/查看作物",
	},
	"solar": {
		"name": "太阳能阵列",
		"size": Vector2i(4, 2),
		"cost": {"parts": 3.0, "power": 4.0},
		"color": Color("#263b57"),
		"hint": "E：清理月尘",
	},
	"battery": {
		"name": "电池舱",
		"size": Vector2i(2, 2),
		"cost": {"parts": 3.0, "power": 6.0},
		"color": Color("#363d55"),
		"hint": "储能模块：提高电力上限",
	},
	"life_support": {
		"name": "制氧与水回收",
		"size": Vector2i(3, 2),
		"cost": {"parts": 5.0, "power": 8.0},
		"color": Color("#30384a"),
		"hint": "E：维修设备",
	},
	"workshop": {
		"name": "维修工作台",
		"size": Vector2i(2, 2),
		"cost": {"parts": 5.0, "power": 5.0},
		"color": Color("#514937"),
		"hint": "E：制造 1 个维修件",
	},
	"airlock": {
		"name": "气闸舱",
		"size": Vector2i(2, 2),
		"cost": {"parts": 4.0, "power": 6.0},
		"color": Color("#4a5364"),
		"hint": "E：气闸循环，补满宇航服氧气",
	},
	"regolith_plant": {
		"name": "月壤提氧机",
		"size": Vector2i(3, 2),
		"cost": {"parts": 6.0, "power": 10.0},
		"color": Color("#4b4650"),
		"hint": "E：消耗月壤和电力提取氧气",
	},
	"ice_processor": {
		"name": "冰矿处理器",
		"size": Vector2i(3, 2),
		"cost": {"parts": 5.0, "power": 8.0},
		"color": Color("#355566"),
		"hint": "E：消耗水冰和电力产水",
	},
	"supply": {
		"name": "补给降落区",
		"size": Vector2i(4, 3),
		"cost": {"parts": 0.0, "power": 0.0},
		"color": Color("#3d3530"),
		"hint": "E：申请/领取地球补给",
	},
}

var supply_defs := {
	"survival": {
		"name": "生存包",
		"mass": 300,
		"desc": "食物 + 水 + 氧气",
		"payload": {"food": 28.0, "water": 20.0, "oxygen": 22.0},
	},
	"build": {
		"name": "建设包",
		"mass": 300,
		"desc": "维修件 + 电池 + 除尘耗材",
		"payload": {"parts": 7.0, "power": 18.0, "dust": -0.12},
	},
	"farm": {
		"name": "农业包",
		"mass": 300,
		"desc": "水培耗材 + 温室备件",
		"payload": {"water": 10.0, "parts": 3.0},
	},
}

var tech_defs := {
	"change_samples": {
		"name": "嫦娥样本数据库",
		"cost": {"samples": 2.0, "regolith": 4.0},
		"desc": "样本分析与月壤农业参数库：采样收益提高，作物收获额外 +15%。",
	},
	"queqiao_relay": {
		"name": "鹊桥中继",
		"cost": {"samples": 1.0, "parts": 4.0},
		"desc": "通信链路升级：补给运输缩短 1 天，并降低发射延迟概率。",
	},
	"yutu_robot": {
		"name": "玉兔机器人",
		"cost": {"parts": 6.0, "regolith": 6.0},
		"desc": "自动巡视：每天少量采样，并缓慢清理太阳能板月尘。",
	},
	"closed_ecology": {
		"name": "闭环生态控制",
		"cost": {"samples": 3.0, "water": 8.0, "co2": 10.0},
		"desc": "温室湿度和 CO2 调节更稳定，前哨员健康下降减缓。",
	},
	"precision_landing": {
		"name": "精确着陆雷达",
		"cost": {"samples": 2.0, "parts": 5.0},
		"desc": "补给舱落点偏差降低，鹊桥链路可辅助修正弹道。",
	},
	"robot_assist": {
		"name": "机器人协作协议",
		"cost": {"parts": 5.0, "samples": 2.0},
		"desc": "玉兔和维护机器人分担重复劳动，降低前哨员压力。",
	},
}

var mission_defs := {
	"survive_7": {"name": "稳住第一周", "desc": "生存到第 7 天。"},
	"first_greenhouse": {"name": "第一座温室", "desc": "建造或保有 1 座温室。"},
	"local_oxygen": {"name": "原位制氧", "desc": "让基地氧气储备达到 100。"},
	"supply_recovery": {"name": "出舱取货", "desc": "成功回收 1 个偏差落点补给舱。"},
	"operator_stable": {"name": "前哨员稳定", "desc": "健康和精神状态都保持在 60 以上。"},
}

var modules: Array[Dictionary] = []
var collectables: Array[Dictionary] = []
var operator := {}
var moon_tile_map: TileMapLayer
var interior_tile_map: TileMapLayer
var moon_tile_source_id := 0
var interior_tile_source_id := 0
var entity_root: Node2D
var audio_player: AudioStreamPlayer
var module_nodes: Dictionary = {}
var collectable_nodes: Dictionary = {}
var player_node: Node2D

func _ready() -> void:
	_setup_input_map()
	_reset_game_state()
	_setup_moon_tile_map()
	_setup_interior_tile_map()
	_setup_entity_root()
	_setup_audio()
	_setup_ui()
	_setup_main_menu()
	add_log("广寒前哨上线。玉兔工程车完成自动部署，但系统仍需人工调试。")
	add_log("V0.11：舱内/舱外分层、碰撞、正式模块素材与单人前哨员设定上线。")
	_sync_scene_instances()
	_update_ui()

func _setup_input_map() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("advance_day", [KEY_N])
	_add_key_action("toggle_build", [KEY_B])
	_add_key_action("cancel", [KEY_ESCAPE])
	_add_key_action("save_game", [KEY_F5])
	_add_key_action("load_game", [KEY_F9])
	_add_key_action("new_game", [KEY_F10])

func _add_key_action(action_name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key: int in keys:
		var event := InputEventKey.new()
		event.keycode = key
		InputMap.action_add_event(action_name, event)

func _reset_game_state() -> void:
	day = 1
	is_moon_night = false
	game_over = false
	supply_waiting = false
	supply_order = {}
	next_supply_request_day = 1
	supply_travel_days = 3
	current_save_slot = clamp(current_save_slot, 1, SAVE_SLOTS)
	player_pos = Vector2(300, 420)
	player_facing = Vector2.DOWN
	was_inside = false
	eva_warning_cooldown = 0.0
	walk_phase = 0.0
	interact_target = {}
	selected_crop = "potato"
	selected_tool = "sampler"
	build_mode = false
	selected_build = ""
	unlocked_techs.clear()
	completed_missions.clear()
	robot_task = "idle"
	backpack = _default_backpack()
	solar_dust = 0.12
	oxygen_wear = 0.08
	next_module_uid = 1
	next_collectable_uid = 1
	resources = _default_resources()
	modules.clear()
	collectables.clear()
	operator = _default_operator()
	log_lines.clear()
	_setup_starting_base()
	_setup_collectables()
	if has_node("UI/Root/SupplyPanel"):
		$UI/Root/SupplyPanel.visible = false
	_sync_scene_instances()

func _default_operator() -> Dictionary:
	return {"name": "林舟", "health": 92.0, "morale": 78.0, "fatigue": 12.0}

func _default_resources() -> Dictionary:
	return {
		"power": 76.0,
		"oxygen": 82.0,
		"water": 68.0,
		"food": 50.0,
		"parts": 8.0,
		"integrity": 88.0,
		"regolith": 0.0,
		"ice": 0.0,
		"samples": 0.0,
		"co2": 34.0,
		"humidity": 52.0,
		"pressure": 100.0,
		"suit_o2": 100.0,
		"suit_integrity": 100.0,
		"suit_dust": 0.0,
	}

func _default_backpack() -> Dictionary:
	return {
		"regolith": 0.0,
		"ice": 0.0,
		"samples": 0.0,
		"parts": 0.0,
	}

func _setup_starting_base() -> void:
	modules.clear()
	_add_module("solar", Vector2i(2, 1), true)
	_add_module("hab", Vector2i(4, 5), true)
	_add_module("airlock", Vector2i(7, 5), true)
	_add_module("life_support", Vector2i(9, 5), true)
	_add_module("greenhouse", Vector2i(12, 5), true)
	_add_module("supply", Vector2i(17, 7), true)
	player_pos = _cell_to_world(Vector2i(5, 5)) + Vector2(TILE * 0.5, TILE * 0.5)

func _process(delta: float) -> void:
	if game_over or pending_main_menu:
		return
	eva_warning_cooldown = max(0.0, eva_warning_cooldown - delta)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_pos := player_pos + input * PLAYER_SPEED * delta
	if _can_player_move_to(target_pos):
		player_pos = target_pos
	if input.length() > 0.01:
		player_facing = input.normalized()
		walk_phase += delta * 10.0
	player_pos.x = clamp(player_pos.x, MAP_ORIGIN.x + 5.0, MAP_ORIGIN.x + MAP_W * TILE - 5.0)
	player_pos.y = clamp(player_pos.y, MAP_ORIGIN.y + 5.0, MAP_ORIGIN.y + MAP_H * TILE - 5.0)
	_process_suit_oxygen(delta)
	_find_interaction()
	_sync_scene_instances()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		_save_game()
	if event.is_action_pressed("load_game"):
		_load_game()
	if event.is_action_pressed("new_game"):
		_start_new_game()
	if event.is_action_pressed("toggle_build") and not game_over:
		_toggle_build_mode()
	if event.is_action_pressed("cancel") and not game_over:
		build_mode = false
		selected_build = ""
		_update_ui()
	if event.is_action_pressed("interact") and not game_over:
		_interact()
	if event.is_action_pressed("advance_day") and not game_over:
		_advance_day()

func _draw() -> void:
	_draw_build_ghost()

func _setup_entity_root() -> void:
	entity_root = Node2D.new()
	entity_root.name = "Entities"
	add_child(entity_root)
	player_node = PLAYER_SCENE.instantiate()
	player_node.name = "Player"
	player_node.z_index = 30
	entity_root.add_child(player_node)
	_sync_scene_instances()

func _setup_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "ActionTonePlayer"
	add_child(audio_player)

func _play_ui_tone(frequency: float = 660.0, duration: float = 0.08, volume: float = 0.08) -> void:
	if not is_instance_valid(audio_player):
		return
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = max(0.05, duration + 0.03)
	audio_player.stream = stream
	audio_player.play()
	var playback: AudioStreamGeneratorPlayback = audio_player.get_stream_playback()
	if playback == null:
		return
	var frames := int(stream.mix_rate * duration)
	var phase := 0.0
	var increment := TAU * frequency / stream.mix_rate
	for i in range(frames):
		var fade: float = 1.0 - float(i) / float(max(1, frames))
		var sample := sin(phase) * volume * fade
		playback.push_frame(Vector2(sample, sample))
		phase += increment

func _sync_scene_instances() -> void:
	if not is_instance_valid(entity_root):
		return
	if is_instance_valid(player_node):
		player_node.position = player_pos
		if player_node.has_method("setup"):
			player_node.call("setup", player_facing, _is_player_inside_pressurized_module(), resources["suit_o2"])
	for module: Dictionary in modules:
		var uid := int(module["uid"])
		if not module_nodes.has(uid) or not is_instance_valid(module_nodes[uid]):
			var node := MODULE_SCENE.instantiate()
			node.z_index = 5
			entity_root.add_child(node)
			module_nodes[uid] = node
		var module_node: Node2D = module_nodes[uid]
		module_node.position = _module_rect(module).position
		if module_node.has_method("setup"):
			var visual_data: Dictionary = module.duplicate(true)
			visual_data["doors"] = _module_door_sides(module)
			module_node.call("setup", visual_data, module_defs[module["type"]], interact_target == module)
	for uid in module_nodes.keys():
		var still_exists := false
		for module: Dictionary in modules:
			if int(module["uid"]) == int(uid):
				still_exists = true
				break
		if not still_exists and is_instance_valid(module_nodes[uid]):
			module_nodes[uid].queue_free()
			module_nodes.erase(uid)
	for item: Dictionary in collectables:
		var uid := int(item["uid"])
		if not collectable_nodes.has(uid) or not is_instance_valid(collectable_nodes[uid]):
			var node := COLLECTABLE_SCENE.instantiate()
			node.z_index = 8
			entity_root.add_child(node)
			collectable_nodes[uid] = node
		var item_node: Node2D = collectable_nodes[uid]
		item_node.position = item["pos"]
		if item_node.has_method("setup"):
			item_node.call("setup", item, interact_target == item)
	for uid in collectable_nodes.keys():
		var still_exists := false
		for item: Dictionary in collectables:
			if int(item["uid"]) == int(uid):
				still_exists = true
				break
		if not still_exists and is_instance_valid(collectable_nodes[uid]):
			collectable_nodes[uid].queue_free()
			collectable_nodes.erase(uid)

func _setup_moon_tile_map() -> void:
	if is_instance_valid(moon_tile_map):
		moon_tile_map.queue_free()
	moon_tile_map = TileMapLayer.new()
	moon_tile_map.name = "MoonSurfaceTileMap"
	moon_tile_map.position = MAP_ORIGIN
	moon_tile_map.z_index = -20
	moon_tile_map.tile_set = _create_moon_tile_set()
	add_child(moon_tile_map)
	_paint_moon_surface_tiles()

func _setup_interior_tile_map() -> void:
	if is_instance_valid(interior_tile_map):
		interior_tile_map.queue_free()
	interior_tile_map = TileMapLayer.new()
	interior_tile_map.name = "InteriorFloorTileMap"
	interior_tile_map.position = MAP_ORIGIN
	interior_tile_map.z_index = -10
	interior_tile_map.tile_set = _create_interior_tile_set()
	add_child(interior_tile_map)
	_paint_interior_tiles()

func _create_moon_tile_set() -> TileSet:
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	var image: Image = Image.create(TILE * 4, TILE, false, Image.FORMAT_RGBA8)
	for tile_x in range(4):
		for px in range(TILE):
			for py in range(TILE):
				var base: float = 0.17 + float(tile_x) * 0.025
				var grain: float = float((px * 13 + py * 7 + tile_x * 19) % 11) * 0.004
				var crater: float = _tile_crater_shadow(tile_x, px, py)
				var shade: float = clamp(base + grain + crater, 0.06, 0.34)
				image.set_pixel(tile_x * TILE + px, py, Color(shade, shade, shade + 0.018, 1.0))
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	for tile_x in range(4):
		source.create_tile(Vector2i(tile_x, 0))
	moon_tile_source_id = tile_set.add_source(source)
	return tile_set

func _create_interior_tile_set() -> TileSet:
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	var image: Image = Image.create(TILE * 3, TILE, false, Image.FORMAT_RGBA8)
	for tile_x in range(3):
		for px in range(TILE):
			for py in range(TILE):
				var seam := 0.055 if px < 2 or py < 2 else 0.0
				var stripe := 0.035 if (px + tile_x * 9) % 16 < 3 else 0.0
				var base := 0.24 + float(tile_x) * 0.035 + seam + stripe
				image.set_pixel(tile_x * TILE + px, py, Color(base, base + 0.025, base + 0.045, 1.0))
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	for tile_x in range(3):
		source.create_tile(Vector2i(tile_x, 0))
	interior_tile_source_id = tile_set.add_source(source)
	return tile_set

func _tile_crater_shadow(tile_x: int, px: int, py: int) -> float:
	if tile_x == 0:
		return 0.0
	var center := Vector2(18 + tile_x * 3, 23 + tile_x * 2)
	var dist := Vector2(px, py).distance_to(center)
	if tile_x == 1 and dist < 13.0:
		return -0.055 + dist * 0.002
	if tile_x == 2 and dist < 18.0:
		return -0.04 + dist * 0.0015
	if tile_x == 3 and (px + py) % 17 < 2:
		return 0.035
	return 0.0

func _paint_moon_surface_tiles() -> void:
	moon_tile_map.clear()
	for x in range(MAP_W):
		for y in range(MAP_H):
			var atlas_x := int((x * 17 + y * 11) % 4)
			moon_tile_map.set_cell(Vector2i(x, y), moon_tile_source_id, Vector2i(atlas_x, 0))

func _paint_interior_tiles() -> void:
	if not is_instance_valid(interior_tile_map):
		return
	interior_tile_map.clear()
	for module: Dictionary in modules:
		if not _module_has_interior(module["type"]):
			continue
		var def: Dictionary = module_defs[module["type"]]
		var cell: Vector2i = module["cell"]
		var size: Vector2i = def["size"]
		for x in range(size.x):
			for y in range(size.y):
				var atlas_x := int((x + y + int(module["uid"])) % 3)
				interior_tile_map.set_cell(cell + Vector2i(x, y), interior_tile_source_id, Vector2i(atlas_x, 0))

func _draw_collectables() -> void:
	for item: Dictionary in collectables:
		if item["depleted"]:
			continue
		var pos: Vector2 = item["pos"]
		var color := Color("#b8b2a2")
		if item["type"] == "ice":
			color = Color("#9fd7ff")
		elif item["type"] == "meteor":
			color = Color("#d1a15b")
		elif item["type"] == "sample":
			color = Color("#c9c3a5")
		if interact_target == item:
			draw_circle(pos, 20, Color("#e7c66b"))
		draw_circle(pos, 13, color)
		draw_circle(pos + Vector2(-4, -4), 4, Color(1, 1, 1, 0.28))

func _draw_modules() -> void:
	for module: Dictionary in modules:
		var rect := _module_rect(module)
		var def: Dictionary = module_defs[module["type"]]
		var fill: Color = def["color"]
		if interact_target == module:
			draw_rect(rect.grow(5), Color("#e7c66b"), false, 3)
		if module.get("leaking", false):
			draw_rect(rect.grow(7), Color("#ff5a5a"), false, 4)
		draw_rect(rect, fill)
		draw_rect(rect, Color("#a7b3c5"), false, 2)
		_draw_module_details(module, rect)

func _draw_module_details(module: Dictionary, rect: Rect2) -> void:
	var module_type: String = module["type"]
	if module_type == "greenhouse":
		_draw_greenhouse(module, rect)
	elif module_type == "solar":
		_draw_solar(rect)
	elif module_type == "battery":
		for i in range(2):
			draw_rect(Rect2(rect.position + Vector2(20 + i * 38, 28), Vector2(24, 42)), Color("#a8c7ff"))
	elif module_type == "hab":
		draw_circle(rect.get_center(), min(rect.size.x, rect.size.y) * 0.35, Color("#717d8f"))
	elif module_type == "life_support":
		draw_circle(rect.get_center() + Vector2(-22, 0), 18, Color("#98d5ff"))
		draw_circle(rect.get_center() + Vector2(22, 0), 18, Color("#b8f0d0"))
	elif module_type == "workshop":
		draw_rect(Rect2(rect.position + Vector2(24, 28), Vector2(48, 34)), Color("#c0a36c"))
	elif module_type == "airlock":
		draw_rect(Rect2(rect.position + Vector2(22, 18), Vector2(52, 58)), Color("#8892a3"), false, 4)
		draw_line(rect.position + Vector2(48, 20), rect.position + Vector2(48, 74), Color("#d8e0eb"), 2)
	elif module_type == "regolith_plant":
		draw_circle(rect.get_center() + Vector2(-26, 0), 18, Color("#b3a18e"))
		draw_line(rect.get_center() + Vector2(-8, 0), rect.get_center() + Vector2(32, -18), Color("#d8e0eb"), 3)
		draw_circle(rect.get_center() + Vector2(36, -20), 8, Color("#98d5ff"))
	elif module_type == "ice_processor":
		draw_circle(rect.get_center() + Vector2(-20, 0), 18, Color("#9fd7ff"))
		draw_rect(Rect2(rect.get_center() + Vector2(8, -18), Vector2(34, 36)), Color("#b8f0ff"), false, 3)
	elif module_type == "supply":
		draw_circle(rect.get_center(), 32, Color("#a76f45"))
		draw_rect(Rect2(rect.position + Vector2(68, 35), Vector2(54, 74)), Color("#d0d6df"), false, 3)

func _draw_greenhouse(module: Dictionary, rect: Rect2) -> void:
	var slots := 2
	for i in range(slots):
		var bed: Rect2 = Rect2(rect.position + Vector2(22 + i * 72, 28), Vector2(52, 48))
		draw_rect(bed, Color("#223026"))
		draw_rect(bed, Color("#74b77a"), false, 2)
		if module["crop"] != "":
			var crop_def: Dictionary = crop_defs[module["crop"]]
			var growth: float = min(1.0, float(module["age"] + 1) / float(crop_def["days"]))
			draw_circle(bed.get_center(), 7 + 13 * growth, Color("#71d46f"))

func _draw_solar(rect: Rect2) -> void:
	for i in range(4):
		var panel: Rect2 = Rect2(rect.position + Vector2(14 + i * 40, 18), Vector2(30, 58))
		draw_rect(panel, Color("#365f95"))
		draw_rect(panel, Color("#94bdeb"), false, 1)
	var dust_alpha: float = clamp(solar_dust, 0.0, 0.7)
	draw_rect(rect, Color(0.72, 0.72, 0.66, dust_alpha))

func _draw_build_ghost() -> void:
	if not build_mode or selected_build == "":
		return
	var cell: Vector2i = _player_build_cell()
	var def: Dictionary = module_defs[selected_build]
	var size: Vector2i = def["size"]
	var rect: Rect2 = Rect2(_cell_to_world(cell), Vector2(size.x * TILE - 2, size.y * TILE - 2))
	var can_build := _can_place(selected_build, cell) and _is_connected_placement(selected_build, cell)
	var color := Color(0.3, 0.9, 0.5, 0.38) if can_build else Color(1.0, 0.25, 0.25, 0.38)
	draw_rect(rect, color)
	draw_rect(rect, Color("#f2f0da"), false, 2)

func _draw_player() -> void:
	var foot_offset := sin(walk_phase) * 3.0
	var side := Vector2(-player_facing.y, player_facing.x)
	draw_circle(player_pos - side * 7 + Vector2(0, foot_offset), 5, Color("#303846"))
	draw_circle(player_pos + side * 7 - Vector2(0, foot_offset), 5, Color("#303846"))
	draw_circle(player_pos, player_radius + 4, Color("#1b222d"))
	draw_circle(player_pos, player_radius, Color("#f2f0da"))
	draw_circle(player_pos + player_facing * 6, 5, Color("#7fb8ff"))
	draw_line(player_pos, player_pos + player_facing * 22, Color("#e7c66b"), 2)

func _find_interaction() -> void:
	interact_target = {}
	for module: Dictionary in modules:
		var facility := _facility_at_player(module)
		if not facility.is_empty():
			interact_target = facility
			return
		var rect := _module_rect(module).grow(24)
		if rect.has_point(player_pos):
			interact_target = module
			return
	for item: Dictionary in collectables:
		if item["depleted"]:
			continue
		var pos: Vector2 = item["pos"]
		if player_pos.distance_to(pos) <= 34.0:
			interact_target = item
			return

func _facility_at_player(module: Dictionary) -> Dictionary:
	if not _module_has_interior(module["type"]):
		return {}
	if not _module_rect(module).has_point(player_pos):
		return {}
	var local := player_pos - _module_rect(module).position
	var module_type: String = module["type"]
	var zones: Array[Dictionary] = []
	if module_type == "hab":
		zones = [
			{"facility": "bed", "rect": Rect2(Vector2(18, 18), Vector2(62, 76))},
			{"facility": "storage", "rect": Rect2(Vector2(92, 16), Vector2(42, 68))},
			{"facility": "console", "rect": Rect2(Vector2(84, 48), Vector2(54, 44))},
		]
	elif module_type == "life_support":
		zones = [
			{"facility": "console", "rect": Rect2(Vector2(18, 48), Vector2(70, 42))},
		]
	elif module_type == "workshop":
		zones = [
			{"facility": "storage", "rect": Rect2(Vector2(18, 52), Vector2(50, 42))},
			{"facility": "robot_charger", "rect": Rect2(Vector2(54, 14), Vector2(48, 64))},
		]
	for zone: Dictionary in zones:
		var rect: Rect2 = zone["rect"]
		if rect.grow(14).has_point(local):
			return {
				"kind": "facility",
				"facility": zone["facility"],
				"module_uid": module["uid"],
				"module_type": module_type,
			}
	return {}

func _process_suit_oxygen(delta: float) -> void:
	var inside := _is_player_inside_pressurized_module()
	if inside:
		if not was_inside:
			resources["suit_o2"] = min(100.0, resources["suit_o2"] + 25.0)
			resources["pressure"] = min(100.0, resources["pressure"] + 0.5)
			add_log("返舱完成：舱压稳定，宇航服开始复压检查。")
		resources["suit_o2"] = min(100.0, resources["suit_o2"] + delta * 10.0)
	else:
		resources["suit_o2"] = max(0.0, resources["suit_o2"] - delta * 1.8)
		resources["suit_dust"] = min(100.0, resources["suit_dust"] + delta * (0.18 + solar_dust * 0.25))
		resources["suit_integrity"] = max(0.0, resources["suit_integrity"] - delta * 0.035)
		if resources["suit_o2"] <= 0.0:
			resources["oxygen"] = max(0.0, resources["oxygen"] - delta * 2.5)
		if resources["suit_integrity"] <= 0.0:
			resources["oxygen"] = max(0.0, resources["oxygen"] - delta * 1.8)
	was_inside = inside

func _is_player_inside_pressurized_module() -> bool:
	for module: Dictionary in modules:
		if not _is_pressurized_module(module["type"]):
			continue
		if module.get("leaking", false):
			continue
		if _module_rect(module).has_point(player_pos):
			return true
	return false

func _interact() -> void:
	if build_mode and selected_build != "":
		_try_build_selected()
		return
	if interact_target.is_empty():
		add_log("附近没有可操作目标。")
		return
	if interact_target.has("kind") and interact_target["kind"] == "collectable":
		_collect_surface_item(interact_target)
		_update_ui()
		return
	if interact_target.has("kind") and interact_target["kind"] == "facility":
		_use_facility(interact_target)
		_update_ui()
		return
	if interact_target.get("leaking", false):
		_repair_module_leak(interact_target)
		_update_ui()
		return
	match String(interact_target["type"]):
		"greenhouse":
			_use_greenhouse(interact_target)
		"solar":
			if selected_tool == "repair" and resources["integrity"] < 70.0:
				_repair_external_equipment(interact_target)
			else:
				_clean_solar()
		"life_support":
			_repair_life_support()
		"supply":
			_collect_supply()
		"workshop":
			_use_workshop()
		"airlock":
			_cycle_airlock()
		"regolith_plant":
			if selected_tool == "repair" and resources["integrity"] < 70.0:
				_repair_external_equipment(interact_target)
			else:
				_use_regolith_plant()
		"ice_processor":
			if selected_tool == "repair" and resources["integrity"] < 70.0:
				_repair_external_equipment(interact_target)
			else:
				_use_ice_processor()
		_:
			var def: Dictionary = module_defs[interact_target["type"]]
			add_log("%s 运转正常。" % def["name"])
	_update_ui()

func _use_facility(facility: Dictionary) -> void:
	match String(facility["facility"]):
		"bed":
			_use_bed()
		"console":
			_use_console()
		"storage":
			_use_storage()
		"robot_charger":
			_use_robot_charger()
		_:
			add_log("该舱内设施还没有接入操作。")

func _use_bed() -> void:
	var old_fatigue := float(operator.get("fatigue", 0.0))
	operator["fatigue"] = max(0.0, old_fatigue - 35.0)
	operator["health"] = min(100.0, float(operator.get("health", 100.0)) + 4.0)
	operator["morale"] = min(100.0, float(operator.get("morale", 100.0)) + 3.0)
	resources["food"] = max(0.0, resources["food"] - 1.0)
	resources["water"] = max(0.0, resources["water"] - 1.0)
	_play_ui_tone(520.0, 0.12, 0.07)
	add_log("在床铺休整一轮：疲劳 %.0f -> %.0f，消耗食物 1、水 1。" % [old_fatigue, operator["fatigue"]])

func _use_console() -> void:
	var counts: Dictionary = _module_counts()
	var pod_count := _active_collectable_count("supply_pod")
	var leak_count := _leaking_module_count()
	_play_ui_tone(840.0, 0.08, 0.07)
	add_log("控制台：电力 %.0f，氧 %.0f，水 %.0f，舱压 %.0f%%，模块 %d，漏气 %d，补给信标 %d。" % [
		resources["power"], resources["oxygen"], resources["water"], resources["pressure"], modules.size(), leak_count, pod_count
	])
	add_log("控制台：机器人任务=%s，背包 %.0f/%.0f。" % [_robot_task_name(robot_task), _backpack_load(), backpack_capacity])

func _use_storage() -> void:
	if _backpack_load() <= 0.0:
		add_log("储物柜：出舱背包为空。可出舱采集后回到这里入库。")
		_play_ui_tone(420.0, 0.06, 0.05)
		return
	for key: String in backpack.keys():
		resources[key] += float(backpack[key])
		backpack[key] = 0.0
	_play_ui_tone(680.0, 0.1, 0.07)
	add_log("储物柜：出舱背包已入库。基地库存已更新。")

func _use_robot_charger() -> void:
	if not _has_tech("robot_assist") and not _has_tech("yutu_robot"):
		add_log("机器人充电桩待机：需要先解锁玉兔机器人或机器人协作协议。")
		_play_ui_tone(260.0, 0.08, 0.06)
		return
	var order := ["idle", "sample", "maintenance", "haul"]
	var index := order.find(robot_task)
	robot_task = order[(index + 1) % order.size()]
	_play_ui_tone(960.0, 0.08, 0.07)
	add_log("机器人充电桩：已派发任务 -> %s。" % _robot_task_name(robot_task))

func _use_greenhouse(module: Dictionary) -> void:
	if module["crop"] == "":
		var crop_def: Dictionary = crop_defs[selected_crop]
		if resources["water"] < crop_def["water"]:
			add_log("水不足，无法种植 %s。" % crop_def["name"])
			return
		resources["water"] -= crop_def["water"]
		module["crop"] = selected_crop
		module["age"] = 0
		add_log("在温室种下 %s。%s。" % [crop_def["name"], crop_def["note"]])
	else:
		var crop_def: Dictionary = crop_defs[module["crop"]]
		add_log("%s 生长进度 %d/%d 天。" % [crop_def["name"], module["age"], crop_def["days"]])

func _clean_solar() -> void:
	if selected_tool != "brush":
		add_log("需要先选择除尘刷。")
		return
	if resources["parts"] < 1:
		add_log("缺少维修件，无法进行除尘维护。")
		return
	resources["parts"] -= 1
	solar_dust = max(0.0, solar_dust - 0.28)
	resources["suit_dust"] = min(100.0, resources["suit_dust"] + 3.0)
	_play_ui_tone(740.0, 0.07, 0.07)
	add_log("清理太阳能阵列。月尘覆盖降至 %d%%。" % int(solar_dust * 100))

func _repair_life_support() -> void:
	if selected_tool != "repair":
		add_log("需要先选择维修枪。")
		return
	if resources["parts"] < 1:
		add_log("维修件不足，生命维持系统只能继续带病运行。")
		return
	resources["parts"] -= 1
	resources["integrity"] = min(100.0, resources["integrity"] + 12.0)
	oxygen_wear = max(0.0, oxygen_wear - 0.12)
	_play_ui_tone(620.0, 0.08, 0.08)
	add_log("完成一次生命维持系统维护。")

func _repair_module_leak(module: Dictionary) -> void:
	if selected_tool != "repair":
		add_log("该舱段正在漏气，需要先选择维修枪。")
		return
	if resources["parts"] < 2:
		add_log("封堵漏气需要 2 个维修件。")
		return
	resources["parts"] -= 2
	module["leaking"] = false
	resources["integrity"] = min(100.0, resources["integrity"] + 6.0)
	var def: Dictionary = module_defs[module["type"]]
	_play_ui_tone(520.0, 0.1, 0.08)
	add_log("已封堵 %s 漏点，舱压恢复稳定。" % def["name"])

func _repair_external_equipment(module: Dictionary) -> void:
	if selected_tool != "repair":
		add_log("外部设备维护需要先选择维修枪。")
		return
	if resources["parts"] < 1:
		add_log("缺少维修件，无法维护外部设备。")
		return
	resources["parts"] -= 1
	resources["integrity"] = min(100.0, resources["integrity"] + 8.0)
	resources["suit_dust"] = min(100.0, resources["suit_dust"] + 4.0)
	var def: Dictionary = module_defs[module["type"]]
	_play_ui_tone(560.0, 0.08, 0.08)
	add_log("完成 %s 外部维护：完整度 +8，宇航服月尘污染上升。" % def["name"])

func _use_workshop() -> void:
	if resources["power"] < 4:
		add_log("电力不足，维修工作台无法打印零件。")
		return
	resources["power"] -= 4
	resources["parts"] = min(99.0, resources["parts"] + 1)
	add_log("维修工作台打印了 1 个维修件。")

func _cycle_airlock() -> void:
	if resources["power"] < 2 or resources["oxygen"] < 1:
		add_log("气闸循环需要电力 2、氧气 1。")
		return
	resources["power"] -= 2
	resources["oxygen"] -= 1
	resources["suit_o2"] = 100.0
	resources["suit_dust"] = max(0.0, resources["suit_dust"] - 55.0)
	resources["suit_integrity"] = min(100.0, resources["suit_integrity"] + 8.0)
	resources["pressure"] = min(100.0, resources["pressure"] + 3.0)
	_play_ui_tone(880.0, 0.1, 0.08)
	add_log("气闸循环完成：宇航服补氧、复压、除尘，耐久检查通过。")

func _use_regolith_plant() -> void:
	if resources["regolith"] < 2 or resources["power"] < 6:
		add_log("月壤提氧需要月壤 2、电力 6。")
		return
	resources["regolith"] -= 2
	resources["power"] -= 6
	resources["oxygen"] += 12
	resources["co2"] = max(0.0, resources["co2"] - 2.0)
	add_log("月壤提氧完成：氧气 +12。")

func _use_ice_processor() -> void:
	if resources["ice"] < 1 or resources["power"] < 4:
		add_log("冰矿处理需要水冰 1、电力 4。")
		return
	resources["ice"] -= 1
	resources["power"] -= 4
	resources["water"] += 8
	resources["humidity"] = min(100.0, resources["humidity"] + 4.0)
	add_log("冰矿处理完成：水 +8，温室湿度上升。")

func _collect_supply() -> void:
	if supply_waiting:
		var pos := _dict_to_vector2(supply_order.get("landing_pos", _vector2_to_dict(_cell_to_world(Vector2i(17, 7)))))
		add_log("补给舱等待回收。信标坐标：%.0f, %.0f；请检查航天服氧气后出舱取货。" % [pos.x, pos.y])
		return
	if not supply_order.is_empty():
		add_log("补给 %s 在途，预计第 %d 天抵达。" % [supply_order["name"], supply_order["arrival_day"]])
		return
	if day < next_supply_request_day:
		add_log("补给申请窗口未开放。下一次窗口：第 %d 天。" % next_supply_request_day)
		return
	$UI/Root/SupplyPanel.visible = true
	add_log("地球通信窗口开放：请选择下一批补给货单。")

func _toggle_build_mode() -> void:
	build_mode = not build_mode
	if build_mode and selected_build == "":
		selected_build = "solar"
	add_log("建造模式：%s。" % ("开启" if build_mode else "关闭"))
	_update_ui()

func _select_build(module_type: String) -> void:
	selected_build = module_type
	build_mode = true
	var def: Dictionary = module_defs[module_type]
	add_log("已选择建造：%s。靠近空地按 E 放置。" % def["name"])
	_update_ui()

func _select_tool(tool_name: String) -> void:
	selected_tool = tool_name
	build_mode = false
	selected_build = ""
	add_log("已切换工具：%s。" % tool_defs[tool_name]["name"])
	_update_ui()

func _research_tech(tech_id: String) -> void:
	if _has_tech(tech_id):
		add_log("%s 已经解锁。" % tech_defs[tech_id]["name"])
		return
	var tech: Dictionary = tech_defs[tech_id]
	var cost: Dictionary = tech["cost"]
	for key: String in cost.keys():
		if resources.get(key, 0.0) < float(cost[key]):
			add_log("研究 %s 资源不足：需要 %s %.0f。" % [tech["name"], resource_names.get(key, key), float(cost[key])])
			return
	for key: String in cost.keys():
		resources[key] -= float(cost[key])
	unlocked_techs.append(tech_id)
	add_log("科技解锁：%s。%s" % [tech["name"], tech["desc"]])
	_update_ui()

func _has_tech(tech_id: String) -> bool:
	return unlocked_techs.has(tech_id)

func _process_tech_daily_effects() -> void:
	if _has_tech("yutu_robot"):
		solar_dust = max(0.0, solar_dust - 0.04)
		resources["regolith"] += 0.35
		if day % 3 == 0:
			resources["samples"] += 0.5
			add_log("玉兔机器人完成巡视：科研样本 +0.5。")
	_process_robot_task()

func _process_robot_task() -> void:
	if robot_task == "idle":
		return
	if not _has_tech("robot_assist") and not _has_tech("yutu_robot"):
		return
	if resources["power"] < 3.0:
		add_log("机器人任务暂停：充电桩电力不足。")
		return
	resources["power"] -= 3.0
	match robot_task:
		"sample":
			resources["regolith"] += 0.8
			if day % 4 == 0:
				resources["samples"] += 0.5
			add_log("机器人采样任务完成：月壤 +0.8。")
		"maintenance":
			solar_dust = max(0.0, solar_dust - 0.06)
			resources["integrity"] = min(100.0, resources["integrity"] + 1.2)
			add_log("机器人巡检任务完成：月尘下降，设备完整度小幅恢复。")
		"haul":
			if _active_collectable_count("supply_pod") > 0:
				resources["suit_dust"] = max(0.0, resources["suit_dust"] - 2.0)
				add_log("机器人搬运任务：已标记补给舱路径，玩家回收风险降低。")
			else:
				resources["parts"] += 0.2
				add_log("机器人搬运任务：整理备件，维修件 +0.2。")

func _robot_task_name(task: String) -> String:
	match task:
		"sample":
			return "自动采样"
		"maintenance":
			return "自动巡检"
		"haul":
			return "补给搬运"
		_:
			return "待机"

func _facility_name(facility: String) -> String:
	match facility:
		"bed":
			return "床铺"
		"console":
			return "控制台"
		"storage":
			return "储物柜"
		"robot_charger":
			return "机器人充电桩"
		_:
			return "舱内设施"

func _facility_hint(facility: String) -> String:
	match facility:
		"bed":
			return "按 E 休整，恢复疲劳、健康和精神，消耗少量食物与水。"
		"console":
			return "按 E 查看基地状态、任务和机器人任务。"
		"storage":
			return "按 E 将出舱背包资源入库。"
		"robot_charger":
			return "按 E 切换机器人任务：待机/采样/巡检/搬运。"
		_:
			return "按 E 操作。"

func _try_build_selected() -> void:
	var cell: Vector2i = _player_build_cell()
	if not _can_place(selected_build, cell):
		add_log("这里空间不足或超出基地网格，无法建造。")
		return
	if not _is_connected_placement(selected_build, cell):
		add_log("新模块必须贴近已有基地舱段或能源节点。")
		return
	var def: Dictionary = module_defs[selected_build]
	var cost: Dictionary = def["cost"]
	if resources["parts"] < cost["parts"] or resources["power"] < cost["power"]:
		add_log("资源不足：需要维修件 %.0f、电力 %.0f。" % [cost["parts"], cost["power"]])
		return
	resources["parts"] -= cost["parts"]
	resources["power"] -= cost["power"]
	_add_module(selected_build, cell, false)
	add_log("建成 %s。基地自给能力提升。" % def["name"])
	_update_ui()

func _add_module(module_type: String, cell: Vector2i, fixed: bool) -> void:
	var module := {
		"uid": next_module_uid,
		"type": module_type,
		"cell": cell,
		"fixed": fixed,
		"crop": "",
		"age": 0,
		"leaking": false,
	}
	next_module_uid += 1
	modules.append(module)
	_paint_interior_tiles()
	_sync_scene_instances()

func _setup_collectables() -> void:
	collectables.clear()
	_add_collectable("regolith", Vector2(155, 525), 4.0)
	_add_collectable("regolith", Vector2(730, 520), 4.0)
	_add_collectable("ice", Vector2(1010, 170), 3.0)
	_add_collectable("meteor", Vector2(860, 130), 2.0)
	_add_collectable("sample", Vector2(515, 140), 1.0)

func _add_collectable(item_type: String, pos: Vector2, amount: float) -> void:
	collectables.append({
		"uid": next_collectable_uid,
		"kind": "collectable",
		"type": item_type,
		"pos": pos,
		"amount": amount,
		"depleted": false,
	})
	next_collectable_uid += 1
	_sync_scene_instances()

func _collect_surface_item(item: Dictionary) -> void:
	if item["type"] == "supply_pod":
		if not supply_waiting:
			add_log("补给舱信标异常：当前没有待回收补给。")
			return
		_receive_supply()
		item["depleted"] = true
		_complete_mission("supply_recovery")
		_sync_scene_instances()
		return
	if selected_tool != "sampler":
		add_log("需要先选择采样铲。")
		return
	var amount: float = item["amount"]
	if _has_tech("change_samples"):
		amount += 1.0
	match String(item["type"]):
		"regolith":
			if not _add_to_backpack("regolith", amount):
				return
			add_log("采集月壤 +%.0f，已装入出舱背包。" % amount)
		"ice":
			if not _add_to_backpack("ice", amount):
				return
			resources["suit_dust"] = min(100.0, resources["suit_dust"] + 2.0)
			add_log("采集水冰样本 +%.0f，已装入出舱背包。" % amount)
		"meteor":
			if not _add_to_backpack("parts", amount):
				return
			if not _add_to_backpack("samples", 1.0):
				return
			add_log("回收陨石金属：维修件 +%.0f，科研样本 +1，已装入背包。" % amount)
		"sample":
			if not _add_to_backpack("samples", amount):
				return
			add_log("采集特殊月壤样本 +%.0f，已装入出舱背包。" % amount)
	item["depleted"] = true
	_play_ui_tone(680.0, 0.08, 0.07)
	_sync_scene_instances()

func _add_to_backpack(key: String, amount: float) -> bool:
	if _backpack_load() + amount > backpack_capacity:
		add_log("出舱背包容量不足：%.0f/%.0f。请回储物柜入库。" % [_backpack_load(), backpack_capacity])
		_play_ui_tone(220.0, 0.08, 0.06)
		return false
	backpack[key] = float(backpack.get(key, 0.0)) + amount
	return true

func _backpack_load() -> float:
	var total := 0.0
	for key: String in backpack.keys():
		total += float(backpack[key])
	return total

func _backpack_summary() -> String:
	var parts: Array[String] = []
	for key: String in backpack.keys():
		if float(backpack[key]) > 0.0:
			parts.append("%s %.0f" % [resource_names.get(key, key), float(backpack[key])])
	if parts.is_empty():
		return "空"
	return _join_strings(parts, " / ")

func _advance_day() -> void:
	day += 1
	is_moon_night = day >= 14 and day < 22
	var counts: Dictionary = _module_counts()
	var power_cap: float = 120.0 + float(counts["battery"]) * 35.0
	var solar_gain: float = float(counts["solar"]) * 22.0 * (1.0 - solar_dust)
	if is_moon_night:
		solar_gain = 0.0
	var base_power_use: float = 16.0 + float(counts["greenhouse"]) * 2.0 + float(counts["life_support"]) * 2.5
	if is_moon_night:
		base_power_use += 14.0 + float(counts["greenhouse"]) * 3.0
	var operator_food: float = 3.0
	var operator_water: float = max(1.4, 2.4 - float(counts["life_support"]) * 0.35)
	var operator_oxygen: float = max(1.6, 3.0 - float(counts["life_support"]) * 0.35)
	var operator_co2: float = 3.2
	resources["power"] += solar_gain - base_power_use
	resources["oxygen"] -= operator_oxygen + oxygen_wear * 8.0
	resources["co2"] += operator_co2
	resources["water"] -= operator_water
	resources["food"] -= operator_food
	resources["integrity"] -= 1.0 + solar_dust * 1.8 + float(modules.size()) * 0.04
	resources["pressure"] += float(counts["life_support"]) * 1.5 - 0.8
	resources["humidity"] += float(counts["greenhouse"]) * 2.2 - float(counts["life_support"]) * 1.4
	var leaking_count := _leaking_module_count()
	if leaking_count > 0:
		resources["oxygen"] -= float(leaking_count) * 8.0
		resources["integrity"] -= float(leaking_count) * 2.0
		resources["pressure"] -= float(leaking_count) * 9.0
		add_log("警报：%d 个舱段漏气，氧气正在流失。" % leaking_count)
	if counts["workshop"] > 0:
		resources["parts"] = min(99.0, resources["parts"] + 0.25 * float(counts["workshop"]))
	if counts["regolith_plant"] > 0 and resources["regolith"] >= 1 and resources["power"] >= 3:
		resources["regolith"] -= 1
		resources["power"] -= 3
		resources["oxygen"] += 5.0 * float(counts["regolith_plant"])
	if counts["ice_processor"] > 0 and resources["ice"] >= 0.5 and resources["power"] >= 2:
		resources["ice"] -= 0.5
		resources["power"] -= 2
		resources["water"] += 3.0 * float(counts["ice_processor"])
		resources["humidity"] += 1.5
	_process_operator_day(counts)
	_process_tech_daily_effects()
	solar_dust = min(0.65, solar_dust + randf_range(0.02, 0.06))
	oxygen_wear = min(0.45, oxygen_wear + randf_range(0.01, 0.04))
	_process_crop_day()
	_process_supply_window()
	_process_random_event()
	for key: String in ["power", "oxygen", "water", "food", "integrity", "co2", "humidity", "pressure", "suit_o2", "suit_integrity", "suit_dust"]:
		resources[key] = clamp(resources[key], 0.0, power_cap if key == "power" else 120.0)
	add_log("第 %d 天开始。%s" % [day, "月夜中，太阳能归零。" if is_moon_night else "月昼，太阳能可用。"])
	_check_missions()
	_check_game_state()
	_update_ui()
	queue_redraw()

func _process_operator_day(counts: Dictionary) -> void:
	var pressure_penalty: float = 0.0 if resources["pressure"] >= 70.0 else 3.0
	var co2_penalty: float = 0.0 if resources["co2"] <= 85.0 else 2.5
	var supply_penalty: float = 0.0
	if resources["food"] < 18.0 or resources["water"] < 18.0 or resources["oxygen"] < 18.0:
		supply_penalty = 2.0
	var ecology_bonus: float = 1.0 if _has_tech("closed_ecology") else 0.0
	var robot_bonus: float = 1.2 if _has_tech("robot_assist") else 0.0
	var health_delta: float = -0.7 - pressure_penalty - co2_penalty - supply_penalty + ecology_bonus
	var morale_delta: float = -0.5 - supply_penalty + robot_bonus
	var fatigue_delta: float = 1.4 + supply_penalty - robot_bonus
	if counts["greenhouse"] > 0:
		resources["humidity"] = clamp(resources["humidity"] + 0.3, 0.0, 100.0)
	if _has_tech("yutu_robot"):
		resources["integrity"] = min(100.0, resources["integrity"] + 0.4)
	operator["health"] = clamp(float(operator.get("health", 100.0)) + health_delta, 0.0, 100.0)
	operator["morale"] = clamp(float(operator.get("morale", 100.0)) + morale_delta, 0.0, 100.0)
	operator["fatigue"] = clamp(float(operator.get("fatigue", 0.0)) + fatigue_delta, 0.0, 100.0)
	if float(operator["fatigue"]) > 70.0:
		operator["health"] = max(0.0, float(operator["health"]) - 1.0)
		operator["morale"] = max(0.0, float(operator["morale"]) - 1.0)
	if float(operator["health"]) < 45.0:
		resources["integrity"] -= 1.5
	if float(operator["morale"]) < 40.0:
		resources["power"] -= 2.0

func _process_crop_day() -> void:
	for module: Dictionary in modules:
		if module["type"] != "greenhouse" or module["crop"] == "":
			continue
		var humidity_ok: bool = resources["humidity"] >= 35.0 and resources["humidity"] <= 85.0
		var co2_available: bool = resources["co2"] >= 3.0
		if not humidity_ok:
			add_log("温室湿度异常，%s 生长放缓。" % crop_defs[module["crop"]]["name"])
		if not co2_available:
			add_log("二氧化碳不足，%s 光合作用受限。" % crop_defs[module["crop"]]["name"])
		if humidity_ok and co2_available:
			module["age"] += 1
			resources["co2"] = max(0.0, resources["co2"] - 3.0)
			resources["humidity"] = max(0.0, resources["humidity"] - 1.0)
		var crop_def: Dictionary = crop_defs[module["crop"]]
		resources["oxygen"] += crop_def["oxygen"] if not is_moon_night else crop_def["oxygen"] * 0.35
		if module["age"] >= crop_def["days"]:
			var food_gain: float = crop_def["food"]
			if _has_tech("change_samples"):
				food_gain *= 1.15
			resources["food"] += food_gain
			add_log("%s 成熟收获：食物 +%d。" % [crop_def["name"], int(food_gain)])
			module["crop"] = ""
			module["age"] = 0

func _check_missions() -> void:
	var counts := _module_counts()
	if day >= 7:
		_complete_mission("survive_7")
	if int(counts["greenhouse"]) >= 1:
		_complete_mission("first_greenhouse")
	if resources["oxygen"] >= 100.0:
		_complete_mission("local_oxygen")
	if float(operator.get("health", 0.0)) >= 60.0 and float(operator.get("morale", 0.0)) >= 60.0:
		_complete_mission("operator_stable")

func _complete_mission(mission_id: String) -> void:
	if completed_missions.has(mission_id):
		return
	if not mission_defs.has(mission_id):
		return
	completed_missions.append(mission_id)
	resources["samples"] += 0.5
	resources["parts"] += 1.0
	var mission: Dictionary = mission_defs[mission_id]
	add_log("任务完成：%s。奖励：样本 +0.5，维修件 +1。" % mission["name"])

func _process_supply_window() -> void:
	if not supply_order.is_empty() and day >= int(supply_order["arrival_day"]) and not bool(supply_order.get("landed", false)):
		supply_waiting = true
		supply_order["landed"] = true
		var landing_pos := _random_supply_landing_pos()
		supply_order["landing_pos"] = _vector2_to_dict(landing_pos)
		_add_collectable("supply_pod", landing_pos, 1.0)
		add_log("%s 已着陆，但落点出现偏差。信标坐标：%.0f, %.0f；需要出舱取货。" % [supply_order["name"], landing_pos.x, landing_pos.y])
		_sync_scene_instances()
	if day >= next_supply_request_day and supply_order.is_empty() and not supply_waiting:
		add_log("地球通信窗口开放：可在补给降落区申请下一批补给。")

func _process_random_event() -> void:
	if day == 5:
		add_log("月尘静电附着增强，太阳能效率开始下降。")
	if day == 11:
		add_log("地面控制提醒：月夜将在第 14 天开始，请提前储电。")
	if randf() < 0.12:
		var hit_module := _pick_pressurized_module()
		if not hit_module.is_empty() and not hit_module.get("leaking", false):
			hit_module["leaking"] = true
			resources["integrity"] -= 4.0
			var def: Dictionary = module_defs[hit_module["type"]]
			add_log("微陨石击中 %s，舱段开始漏气。" % def["name"])
		else:
			resources["integrity"] -= 5.0
			add_log("微小冲击触发舱体巡检，设备完整度下降。")

func _choose_supply(kind: String) -> void:
	if day < next_supply_request_day or not supply_order.is_empty() or supply_waiting:
		return
	var def: Dictionary = supply_defs[kind]
	var delay: int = supply_travel_days
	if _has_tech("queqiao_relay"):
		delay = max(1, delay - 1)
	var delay_chance: float = 0.06 if _has_tech("queqiao_relay") else 0.15
	if randf() < delay_chance:
		delay += 1
		add_log("地面发射排程拥堵，本批补给延迟 1 天。")
	supply_order = {
		"kind": kind,
		"name": def["name"],
		"arrival_day": day + delay,
		"requested_day": day,
		"landed": false,
	}
	next_supply_request_day = day + 7
	add_log("已申请 %s（%s），预计第 %d 天抵达。" % [def["name"], def["desc"], supply_order["arrival_day"]])
	$UI/Root/SupplyPanel.visible = false
	_update_ui()

func _receive_supply() -> void:
	if supply_order.is_empty():
		supply_waiting = false
		return
	var kind: String = supply_order["kind"]
	var def: Dictionary = supply_defs[kind]
	var payload: Dictionary = def["payload"]
	for key: String in payload.keys():
		if key == "dust":
			solar_dust = max(0.0, solar_dust + float(payload[key]))
		else:
			resources[key] += float(payload[key])
	resources["suit_dust"] = min(100.0, resources["suit_dust"] + 6.0)
	_play_ui_tone(720.0, 0.12, 0.08)
	add_log("接收 %s：%s。" % [def["name"], def["desc"]])
	supply_order.clear()
	supply_waiting = false
	_update_ui()

func _random_supply_landing_pos() -> Vector2:
	var base := _cell_to_world(Vector2i(17, 7)) + Vector2(96, 72)
	var deviation := 150.0
	if _has_tech("precision_landing"):
		deviation = 70.0
	if _has_tech("queqiao_relay"):
		deviation *= 0.8
	var offset := Vector2(randf_range(-deviation, deviation), randf_range(-deviation * 0.7, deviation * 0.7))
	var pos := base + offset
	pos.x = clamp(pos.x, MAP_ORIGIN.x + 30.0, MAP_ORIGIN.x + MAP_W * TILE - 30.0)
	pos.y = clamp(pos.y, MAP_ORIGIN.y + 30.0, MAP_ORIGIN.y + MAP_H * TILE - 30.0)
	return pos

func _save_game() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var file := FileAccess.open(_save_path(current_save_slot), FileAccess.WRITE)
	if file == null:
		add_log("保存失败：无法写入存档文件。")
		_update_ui()
		return
	var save_data := {
		"version": 1,
		"day": day,
		"is_moon_night": is_moon_night,
		"game_over": game_over,
		"supply_waiting": supply_waiting,
		"supply_order": supply_order,
		"next_supply_request_day": next_supply_request_day,
		"supply_travel_days": supply_travel_days,
		"player_pos": _vector2_to_dict(player_pos),
		"player_facing": _vector2_to_dict(player_facing),
		"selected_crop": selected_crop,
		"selected_tool": selected_tool,
		"build_mode": build_mode,
		"selected_build": selected_build,
		"unlocked_techs": unlocked_techs,
		"completed_missions": completed_missions,
		"operator": _serialize_operator(),
		"backpack": backpack,
		"robot_task": robot_task,
		"solar_dust": solar_dust,
		"oxygen_wear": oxygen_wear,
		"next_module_uid": next_module_uid,
		"next_collectable_uid": next_collectable_uid,
		"resources": resources,
		"modules": _serialize_modules(),
		"collectables": _serialize_collectables(),
		"log_lines": log_lines,
	}
	file.store_string(JSON.stringify(save_data, "\t"))
	_play_ui_tone(900.0, 0.06, 0.07)
	add_log("已保存到存档槽 %d。" % current_save_slot)
	_refresh_main_menu()
	_update_ui()

func _load_game() -> void:
	if not FileAccess.file_exists(_save_path(current_save_slot)):
		add_log("存档槽 %d 为空。" % current_save_slot)
		_update_ui()
		return
	var file := FileAccess.open(_save_path(current_save_slot), FileAccess.READ)
	if file == null:
		add_log("读取失败：无法打开存档文件。")
		_update_ui()
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		add_log("读取失败：存档格式无效。")
		_update_ui()
		return
	_apply_save_data(parsed)
	pending_main_menu = false
	if has_node("UI/Root/MainMenu"):
		$UI/Root/MainMenu.visible = false
	_play_ui_tone(760.0, 0.08, 0.07)
	add_log("已读取存档槽 %d。" % current_save_slot)
	_sync_scene_instances()
	_update_ui()
	queue_redraw()

func _start_new_game() -> void:
	_reset_game_state()
	pending_main_menu = false
	if has_node("UI/Root/MainMenu"):
		$UI/Root/MainMenu.visible = false
	add_log("新一轮广寒前哨任务开始。")
	add_log("按 F5 保存，F9 读取，F10 重新开始。")
	_update_ui()
	queue_redraw()

func _apply_save_data(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	is_moon_night = bool(data.get("is_moon_night", false))
	game_over = bool(data.get("game_over", false))
	supply_waiting = bool(data.get("supply_waiting", false))
	supply_order = _copy_dictionary(data.get("supply_order", {}))
	next_supply_request_day = int(data.get("next_supply_request_day", 1))
	supply_travel_days = int(data.get("supply_travel_days", 3))
	player_pos = _dict_to_vector2(data.get("player_pos", _vector2_to_dict(Vector2(300, 420))))
	player_facing = _dict_to_vector2(data.get("player_facing", _vector2_to_dict(Vector2.DOWN)))
	selected_crop = String(data.get("selected_crop", "potato"))
	selected_tool = String(data.get("selected_tool", "sampler"))
	build_mode = bool(data.get("build_mode", false))
	selected_build = String(data.get("selected_build", ""))
	unlocked_techs.clear()
	var saved_techs: Array = data.get("unlocked_techs", [])
	for tech_id in saved_techs:
		unlocked_techs.append(String(tech_id))
	completed_missions.clear()
	var saved_missions: Array = data.get("completed_missions", [])
	for mission_id in saved_missions:
		completed_missions.append(String(mission_id))
	operator = _deserialize_operator(data.get("operator", data.get("crew", _serialize_operator())))
	backpack = _copy_float_dictionary(data.get("backpack", _default_backpack()), _default_backpack())
	robot_task = String(data.get("robot_task", "idle"))
	solar_dust = float(data.get("solar_dust", 0.12))
	oxygen_wear = float(data.get("oxygen_wear", 0.08))
	next_module_uid = int(data.get("next_module_uid", 1))
	next_collectable_uid = int(data.get("next_collectable_uid", 1))
	resources = _default_resources()
	var saved_resources: Dictionary = data.get("resources", {})
	for key: String in saved_resources.keys():
		resources[key] = float(saved_resources[key])
	modules = _deserialize_modules(data.get("modules", []))
	collectables = _deserialize_collectables(data.get("collectables", []))
	_paint_interior_tiles()
	log_lines.clear()
	var saved_logs: Array = data.get("log_lines", [])
	for entry in saved_logs:
		log_lines.append(String(entry))
	if has_node("UI/Root/SupplyPanel"):
		$UI/Root/SupplyPanel.visible = false
	_sync_scene_instances()

func _serialize_modules() -> Array:
	var result: Array = []
	for module: Dictionary in modules:
		result.append({
			"uid": int(module["uid"]),
			"type": String(module["type"]),
			"cell": _vector2i_to_dict(module["cell"]),
			"fixed": bool(module["fixed"]),
			"crop": String(module.get("crop", "")),
			"age": int(module.get("age", 0)),
			"leaking": bool(module.get("leaking", false)),
		})
	return result

func _deserialize_modules(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = value
		result.append({
			"uid": int(data.get("uid", 0)),
			"type": String(data.get("type", "hab")),
			"cell": _dict_to_vector2i(data.get("cell", {"x": 0, "y": 0})),
			"fixed": bool(data.get("fixed", false)),
			"crop": String(data.get("crop", "")),
			"age": int(data.get("age", 0)),
			"leaking": bool(data.get("leaking", false)),
		})
	return result

func _serialize_collectables() -> Array:
	var result: Array = []
	for item: Dictionary in collectables:
		result.append({
			"uid": int(item["uid"]),
			"kind": String(item["kind"]),
			"type": String(item["type"]),
			"pos": _vector2_to_dict(item["pos"]),
			"amount": float(item["amount"]),
			"depleted": bool(item["depleted"]),
		})
	return result

func _deserialize_collectables(values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in values:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = value
		result.append({
			"uid": int(data.get("uid", 0)),
			"kind": String(data.get("kind", "collectable")),
			"type": String(data.get("type", "regolith")),
			"pos": _dict_to_vector2(data.get("pos", {"x": 0.0, "y": 0.0})),
			"amount": float(data.get("amount", 0.0)),
			"depleted": bool(data.get("depleted", false)),
		})
	return result

func _serialize_operator() -> Dictionary:
	return {
		"name": String(operator.get("name", "林舟")),
		"health": float(operator.get("health", 100.0)),
		"morale": float(operator.get("morale", 100.0)),
		"fatigue": float(operator.get("fatigue", 0.0)),
	}

func _deserialize_operator(value) -> Dictionary:
	if typeof(value) == TYPE_ARRAY:
		var legacy_values: Array = value
		if not legacy_values.is_empty() and typeof(legacy_values[0]) == TYPE_DICTIONARY:
			var legacy: Dictionary = legacy_values[0]
			return {
				"name": String(legacy.get("name", "林舟")),
				"health": float(legacy.get("health", 100.0)),
				"morale": float(legacy.get("morale", 100.0)),
				"fatigue": 12.0,
			}
	if typeof(value) != TYPE_DICTIONARY:
		return _default_operator()
	var data: Dictionary = value
	return {
		"name": String(data.get("name", "林舟")),
		"health": float(data.get("health", 100.0)),
		"morale": float(data.get("morale", 100.0)),
		"fatigue": float(data.get("fatigue", 0.0)),
	}

func _save_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, clamp(slot, 1, SAVE_SLOTS)]

func _select_save_slot(slot: int) -> void:
	current_save_slot = clamp(slot, 1, SAVE_SLOTS)
	add_log("当前存档槽：%d。" % current_save_slot)
	_refresh_main_menu()
	_update_ui()

func _slot_summary(slot: int) -> String:
	var path := _save_path(slot)
	if not FileAccess.file_exists(path):
		return "空槽"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "无法读取"
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "损坏"
	var data: Dictionary = parsed
	var saved_resources: Dictionary = data.get("resources", {})
	return "第 %d 天 | 氧 %.0f | 食 %.0f" % [
		int(data.get("day", 1)),
		float(saved_resources.get("oxygen", 0.0)),
		float(saved_resources.get("food", 0.0)),
	]

func _vector2_to_dict(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}

func _dict_to_vector2(value) -> Vector2:
	if typeof(value) != TYPE_DICTIONARY:
		return Vector2.ZERO
	return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))

func _vector2i_to_dict(value: Vector2i) -> Dictionary:
	return {"x": value.x, "y": value.y}

func _dict_to_vector2i(value) -> Vector2i:
	if typeof(value) != TYPE_DICTIONARY:
		return Vector2i.ZERO
	return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))

func _copy_dictionary(value) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var result := {}
	for key in value.keys():
		result[key] = value[key]
	return result

func _copy_float_dictionary(value, defaults: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	if typeof(value) != TYPE_DICTIONARY:
		return result
	var data: Dictionary = value
	for key: String in data.keys():
		result[key] = float(data[key])
	return result

func _check_game_state() -> void:
	var failed: Array[String] = []
	for key: String in ["power", "oxygen", "water", "food", "pressure"]:
		if resources[key] <= 0.0:
			failed.append(resource_names[key])
	if resources["co2"] >= 115.0:
		failed.append("二氧化碳过量")
	if failed.size() > 0:
		game_over = true
		add_log("基地失守：%s 归零。请调整补给和维护优先级后重试。" % _join_strings(failed, ", "))
	if day > 30 and not game_over:
		add_log("30 天生存目标完成。下一步可以扩展机器人劳动力、舱外任务和本地工业链。")

func _next_supply_day() -> int:
	if supply_waiting:
		return day
	if not supply_order.is_empty():
		return int(supply_order["arrival_day"])
	return next_supply_request_day

func _module_counts() -> Dictionary:
	var counts := {
		"hab": 0,
		"greenhouse": 0,
		"solar": 0,
		"battery": 0,
		"life_support": 0,
		"workshop": 0,
		"airlock": 0,
		"regolith_plant": 0,
		"ice_processor": 0,
		"supply": 0,
	}
	for module: Dictionary in modules:
		counts[module["type"]] += 1
	return counts

func _leaking_module_count() -> int:
	var count := 0
	for module: Dictionary in modules:
		if module.get("leaking", false):
			count += 1
	return count

func _pick_pressurized_module() -> Dictionary:
	var candidates: Array[Dictionary] = []
	for module: Dictionary in modules:
		if _is_pressurized_module(module["type"]):
			candidates.append(module)
	if candidates.is_empty():
		return {}
	return candidates[randi() % candidates.size()]

func _is_pressurized_module(module_type: String) -> bool:
	return module_type in ["hab", "greenhouse", "battery", "life_support", "workshop", "airlock"]

func _module_has_interior(module_type: String) -> bool:
	return module_type in ["hab", "greenhouse", "battery", "life_support", "workshop", "airlock"]

func _can_player_move_to(pos: Vector2) -> bool:
	var min_pos := MAP_ORIGIN + Vector2(5, 5)
	var max_pos := MAP_ORIGIN + Vector2(MAP_W * TILE - 5, MAP_H * TILE - 5)
	if pos.x < min_pos.x or pos.y < min_pos.y or pos.x > max_pos.x or pos.y > max_pos.y:
		return false
	var currently_inside := _is_player_inside_pressurized_module()
	var target_inside := _is_pressurized_point(pos)
	if currently_inside and not target_inside and not _eva_precheck_ok():
		return false
	var samples := [
		pos,
		pos + Vector2(player_radius * 0.7, 0),
		pos + Vector2(-player_radius * 0.7, 0),
		pos + Vector2(0, player_radius * 0.7),
		pos + Vector2(0, -player_radius * 0.7),
	]
	for sample: Vector2 in samples:
		if not _is_walkable_point(sample):
			return false
	return true

func _is_pressurized_point(pos: Vector2) -> bool:
	for module: Dictionary in modules:
		if not _is_pressurized_module(module["type"]):
			continue
		if module.get("leaking", false):
			continue
		if _module_rect(module).has_point(pos):
			return true
	return false

func _eva_precheck_ok() -> bool:
	if resources["suit_o2"] >= 35.0 and resources["suit_integrity"] >= 25.0:
		return true
	if eva_warning_cooldown <= 0.0:
		add_log("出舱检查未通过：宇航服氧气至少 35%，耐久至少 25%。请先到气闸复压、补氧、除尘。")
		eva_warning_cooldown = 3.0
	return false

func _is_walkable_point(pos: Vector2) -> bool:
	for module: Dictionary in modules:
		var rect := _module_rect(module)
		if not rect.has_point(pos):
			continue
		if not _module_has_interior(module["type"]):
			return false
		if _module_inner_rect(module).has_point(pos):
			return true
		return _is_module_door_gap(pos, module)
	return true

func _module_inner_rect(module: Dictionary) -> Rect2:
	return _module_rect(module).grow(-12.0)

func _is_module_door_gap(pos: Vector2, module: Dictionary) -> bool:
	var rect := _module_rect(module)
	var door_half := 20.0
	var edge := 14.0
	var center := rect.get_center()
	var doors: Array[String] = _module_door_sides(module)
	var on_left: bool = doors.has("left") and abs(pos.x - rect.position.x) <= edge and abs(pos.y - center.y) <= door_half
	var on_right: bool = doors.has("right") and abs(pos.x - rect.end.x) <= edge and abs(pos.y - center.y) <= door_half
	var on_top: bool = doors.has("top") and abs(pos.y - rect.position.y) <= edge and abs(pos.x - center.x) <= door_half
	var on_bottom: bool = doors.has("bottom") and abs(pos.y - rect.end.y) <= edge and abs(pos.x - center.x) <= door_half
	return on_left or on_right or on_top or on_bottom

func _module_door_sides(module: Dictionary) -> Array[String]:
	if not _module_has_interior(module["type"]):
		return []
	if module["type"] == "airlock":
		return ["left", "right", "top", "bottom"]
	var sides: Array[String] = []
	var def: Dictionary = module_defs[module["type"]]
	var cell: Vector2i = module["cell"]
	var size: Vector2i = def["size"]
	var current := Rect2i(cell, size)
	for other: Dictionary in modules:
		if int(other["uid"]) == int(module["uid"]):
			continue
		if not _module_has_interior(other["type"]):
			continue
		var other_def: Dictionary = module_defs[other["type"]]
		var other_rect := Rect2i(other["cell"], other_def["size"])
		if current.position.x == other_rect.position.x + other_rect.size.x and _vertical_overlap(current, other_rect):
			sides.append("left")
		if current.position.x + current.size.x == other_rect.position.x and _vertical_overlap(current, other_rect):
			sides.append("right")
		if current.position.y == other_rect.position.y + other_rect.size.y and _horizontal_overlap(current, other_rect):
			sides.append("top")
		if current.position.y + current.size.y == other_rect.position.y and _horizontal_overlap(current, other_rect):
			sides.append("bottom")
	return sides

func _vertical_overlap(a: Rect2i, b: Rect2i) -> bool:
	return a.position.y < b.position.y + b.size.y and b.position.y < a.position.y + a.size.y

func _horizontal_overlap(a: Rect2i, b: Rect2i) -> bool:
	return a.position.x < b.position.x + b.size.x and b.position.x < a.position.x + a.size.x

func _player_build_cell() -> Vector2i:
	var local := player_pos - MAP_ORIGIN
	var x := int(floor(local.x / TILE))
	var y := int(floor(local.y / TILE))
	return Vector2i(clamp(x, 0, MAP_W - 1), clamp(y, 0, MAP_H - 1))

func _cell_to_world(cell: Vector2i) -> Vector2:
	return MAP_ORIGIN + Vector2(cell.x * TILE, cell.y * TILE)

func _module_rect(module: Dictionary) -> Rect2:
	var def: Dictionary = module_defs[module["type"]]
	var cell: Vector2i = module["cell"]
	var size: Vector2i = def["size"]
	return Rect2(_cell_to_world(cell), Vector2(size.x * TILE - 2, size.y * TILE - 2))

func _can_place(module_type: String, cell: Vector2i) -> bool:
	var def: Dictionary = module_defs[module_type]
	var size: Vector2i = def["size"]
	if cell.x < 0 or cell.y < 0 or cell.x + size.x > MAP_W or cell.y + size.y > MAP_H:
		return false
	var candidate: Rect2i = Rect2i(cell, size)
	for module: Dictionary in modules:
		var other_def: Dictionary = module_defs[module["type"]]
		var other_cell: Vector2i = module["cell"]
		var other_size: Vector2i = other_def["size"]
		var other: Rect2i = Rect2i(other_cell, other_size)
		if candidate.intersects(other):
			return false
	return true

func _is_connected_placement(module_type: String, cell: Vector2i) -> bool:
	var def: Dictionary = module_defs[module_type]
	var size: Vector2i = def["size"]
	var candidate: Rect2i = Rect2i(cell, size)
	for module: Dictionary in modules:
		var other_def: Dictionary = module_defs[module["type"]]
		var other_cell: Vector2i = module["cell"]
		var other_size: Vector2i = other_def["size"]
		var other: Rect2i = Rect2i(other_cell, other_size)
		if _rects_touch(candidate, other):
			return true
	return false

func _rects_touch(a: Rect2i, b: Rect2i) -> bool:
	var horizontal_touch := (a.position.x + a.size.x == b.position.x or b.position.x + b.size.x == a.position.x)
	var vertical_overlap := a.position.y < b.position.y + b.size.y and b.position.y < a.position.y + a.size.y
	var vertical_touch := (a.position.y + a.size.y == b.position.y or b.position.y + b.size.y == a.position.y)
	var horizontal_overlap := a.position.x < b.position.x + b.size.x and b.position.x < a.position.x + a.size.x
	return (horizontal_touch and vertical_overlap) or (vertical_touch and horizontal_overlap)

func _setup_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)

	var top := Label.new()
	top.name = "Top"
	top.position = Vector2(18, 12)
	top.size = Vector2(1050, 60)
	top.add_theme_font_size_override("font_size", 20)
	root.add_child(top)

	var hint := Label.new()
	hint.name = "Hint"
	hint.position = Vector2(18, 646)
	hint.size = Vector2(820, 42)
	hint.add_theme_font_size_override("font_size", 18)
	root.add_child(hint)

	var log := RichTextLabel.new()
	log.name = "Log"
	log.position = Vector2(905, 20)
	log.size = Vector2(350, 310)
	log.fit_content = false
	log.scroll_following = true
	root.add_child(log)

	var controls := Label.new()
	controls.name = "Controls"
	controls.position = Vector2(905, 340)
	controls.size = Vector2(350, 86)
	controls.text = "WASD/方向键：移动\nE：交互/采集/建造\nN：进入下一天\nB：建造模式\nF5/F9/F10：保存/读取/新局"
	root.add_child(controls)

	var supply_status := Label.new()
	supply_status.name = "SupplyStatus"
	supply_status.position = Vector2(905, 430)
	supply_status.size = Vector2(350, 70)
	supply_status.add_theme_font_size_override("font_size", 16)
	root.add_child(supply_status)

	var life_status := Label.new()
	life_status.name = "LifeStatus"
	life_status.position = Vector2(905, 485)
	life_status.size = Vector2(350, 62)
	life_status.add_theme_font_size_override("font_size", 16)
	root.add_child(life_status)

	var operator_status := Label.new()
	operator_status.name = "OperatorStatus"
	operator_status.position = Vector2(905, 542)
	operator_status.size = Vector2(350, 76)
	operator_status.add_theme_font_size_override("font_size", 15)
	root.add_child(operator_status)

	var mission_status := Label.new()
	mission_status.name = "MissionStatus"
	mission_status.position = Vector2(905, 615)
	mission_status.size = Vector2(350, 44)
	mission_status.add_theme_font_size_override("font_size", 15)
	root.add_child(mission_status)

	var eva_tasks := RichTextLabel.new()
	eva_tasks.name = "EvaTasks"
	eva_tasks.position = Vector2(360, 390)
	eva_tasks.size = Vector2(500, 104)
	eva_tasks.fit_content = false
	eva_tasks.scroll_active = false
	eva_tasks.add_theme_font_size_override("normal_font_size", 14)
	root.add_child(eva_tasks)

	var tech_panel := HBoxContainer.new()
	tech_panel.name = "TechPanel"
	tech_panel.position = Vector2(18, 504)
	tech_panel.size = Vector2(850, 38)
	root.add_child(tech_panel)
	for tech_id: String in _tech_order():
		var button := Button.new()
		button.text = _tech_button_text(tech_id)
		button.pressed.connect(_research_tech.bind(tech_id))
		tech_panel.add_child(button)

	var crop_panel := HBoxContainer.new()
	crop_panel.name = "CropPanel"
	crop_panel.position = Vector2(18, 550)
	crop_panel.size = Vector2(330, 38)
	root.add_child(crop_panel)
	for crop_name: String in crop_defs.keys():
		var button := Button.new()
		button.text = crop_defs[crop_name]["name"]
		button.pressed.connect(_select_crop.bind(crop_name))
		crop_panel.add_child(button)

	var tool_panel := HBoxContainer.new()
	tool_panel.name = "ToolPanel"
	tool_panel.position = Vector2(18, 590)
	tool_panel.size = Vector2(330, 38)
	root.add_child(tool_panel)
	for tool_name: String in ["sampler", "brush", "repair"]:
		var button := Button.new()
		button.text = tool_defs[tool_name]["name"]
		button.pressed.connect(_select_tool.bind(tool_name))
		tool_panel.add_child(button)

	var build_panel := HBoxContainer.new()
	build_panel.name = "BuildPanel"
	build_panel.position = Vector2(360, 590)
	build_panel.size = Vector2(430, 38)
	root.add_child(build_panel)
	for module_type: String in ["solar", "battery", "greenhouse", "life_support", "workshop", "airlock", "regolith_plant", "ice_processor"]:
		var button := Button.new()
		button.text = module_defs[module_type]["name"]
		button.pressed.connect(_select_build.bind(module_type))
		build_panel.add_child(button)

	var next_day := Button.new()
	next_day.name = "NextDay"
	next_day.text = "进入下一天"
	next_day.position = Vector2(790, 588)
	next_day.size = Vector2(110, 40)
	next_day.pressed.connect(_advance_day)
	root.add_child(next_day)

	var supply_panel := PanelContainer.new()
	supply_panel.name = "SupplyPanel"
	supply_panel.position = Vector2(390, 130)
	supply_panel.size = Vector2(470, 210)
	supply_panel.visible = false
	root.add_child(supply_panel)
	var box := VBoxContainer.new()
	box.name = "Box"
	supply_panel.add_child(box)
	var title := Label.new()
	title.text = "地球补给申请：选择本次 300kg 货单"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	var b1 := Button.new()
	b1.text = "申请生存包：食物 + 水 + 氧气"
	b1.pressed.connect(func(): _choose_supply("survival"))
	box.add_child(b1)
	var b2 := Button.new()
	b2.text = "申请建设包：维修件 + 电池 + 除尘耗材"
	b2.pressed.connect(func(): _choose_supply("build"))
	box.add_child(b2)
	var b3 := Button.new()
	b3.text = "申请农业包：水培耗材 + 温室备件"
	b3.pressed.connect(func(): _choose_supply("farm"))
	box.add_child(b3)

	var save_panel := HBoxContainer.new()
	save_panel.name = "SavePanel"
	save_panel.position = Vector2(905, 655)
	save_panel.size = Vector2(330, 38)
	root.add_child(save_panel)
	for slot in range(1, SAVE_SLOTS + 1):
		var slot_button := Button.new()
		slot_button.text = "槽 %d" % slot
		slot_button.pressed.connect(_select_save_slot.bind(slot))
		save_panel.add_child(slot_button)
	var save_button := Button.new()
	save_button.text = "保存"
	save_button.pressed.connect(_save_game)
	save_panel.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "读取"
	load_button.pressed.connect(_load_game)
	save_panel.add_child(load_button)
	var new_button := Button.new()
	new_button.text = "新开局"
	new_button.pressed.connect(_start_new_game)
	save_panel.add_child(new_button)

func _setup_main_menu() -> void:
	var menu := PanelContainer.new()
	menu.name = "MainMenu"
	menu.position = Vector2(340, 110)
	menu.size = Vector2(600, 430)
	$UI/Root.add_child(menu)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 10)
	menu.add_child(box)
	var title := Label.new()
	title.text = "广寒前哨"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "月球生存、温室种植与基地扩建模拟"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	for slot in range(1, SAVE_SLOTS + 1):
		var row := HBoxContainer.new()
		row.name = "SlotRow%d" % slot
		box.add_child(row)
		var choose := Button.new()
		choose.name = "Slot%d" % slot
		choose.custom_minimum_size = Vector2(380, 40)
		choose.pressed.connect(_select_save_slot.bind(slot))
		row.add_child(choose)
		var load := Button.new()
		load.text = "读取"
		load.pressed.connect(func():
			current_save_slot = slot
			_load_game()
		)
		row.add_child(load)
	var start := Button.new()
	start.text = "从当前槽开始新任务"
	start.custom_minimum_size = Vector2(0, 44)
	start.pressed.connect(_start_new_game)
	box.add_child(start)
	var close := Button.new()
	close.text = "继续当前模拟"
	close.pressed.connect(func():
		pending_main_menu = false
		menu.visible = false
		_update_ui()
	)
	box.add_child(close)
	_refresh_main_menu()

func _select_crop(crop_name: String) -> void:
	selected_crop = crop_name
	add_log("已选择作物：%s。" % crop_defs[crop_name]["name"])
	_update_ui()

func _update_ui() -> void:
	if not has_node("UI/Root"):
		return
	var phase := "月夜" if is_moon_night else "月昼"
	var counts: Dictionary = _module_counts()
	var power_cap: float = 120.0 + float(counts["battery"]) * 35.0
	$UI/Root/Top.text = "广寒前哨 | 第 %d 天 | %s | 电力 %.0f/%.0f  氧气 %.0f  水 %.0f  食物 %.0f  维修件 %.0f  完整度 %.0f%%  月尘 %d%%" % [
		day, phase, resources["power"], power_cap, resources["oxygen"], resources["water"], resources["food"],
		resources["parts"], resources["integrity"], int(solar_dust * 100)
	]
	$UI/Root/SupplyStatus.text = _supply_status_text()
	$UI/Root/LifeStatus.text = "舱压 %.0f%%  CO2 %.0f  湿度 %.0f%%\n宇航服 O2 %.0f%% 耐久 %.0f%% 月尘 %.0f%%  %s" % [
		resources["pressure"], resources["co2"], resources["humidity"],
		resources["suit_o2"], resources["suit_integrity"], resources["suit_dust"],
		"舱内" if _is_player_inside_pressurized_module() else "舱外"
	]
	$UI/Root/OperatorStatus.text = _operator_status_text()
	$UI/Root/MissionStatus.text = _mission_status_text()
	$UI/Root/EvaTasks.text = _eva_tasks_text()
	_update_tech_buttons()
	_refresh_main_menu()
	var hint := "工具：%s | 作物：%s | 背包 %.0f/%.0f：%s | 月壤 %.0f 水冰 %.0f 样本 %.0f。" % [
		tool_defs[selected_tool]["name"], crop_defs[selected_crop]["name"],
		_backpack_load(), backpack_capacity, _backpack_summary(),
		resources["regolith"], resources["ice"], resources["samples"]
	]
	if build_mode and selected_build != "":
		var def: Dictionary = module_defs[selected_build]
		var cost: Dictionary = def["cost"]
		hint = "建造模式：%s | 成本：维修件 %.0f、电力 %.0f | 靠近空地按 E，Esc 取消。" % [def["name"], cost["parts"], cost["power"]]
	elif not interact_target.is_empty():
		if interact_target.has("kind") and interact_target["kind"] == "collectable":
			hint = "月面采集点：按 E 使用 %s。%s" % [tool_defs[selected_tool]["name"], tool_defs[selected_tool]["hint"]]
		elif interact_target.has("kind") and interact_target["kind"] == "facility":
			hint = "%s：%s" % [_facility_name(interact_target["facility"]), _facility_hint(interact_target["facility"])]
		else:
			var def: Dictionary = module_defs[interact_target["type"]]
			if interact_target.get("leaking", false):
				hint = "%s：舱段漏气。切换维修枪并按 E 封堵，消耗 2 维修件。" % def["name"]
			else:
				hint = "%s：%s" % [def["name"], def["hint"]]
	$UI/Root/Hint.text = hint
	$UI/Root/Log.text = _join_strings(log_lines, "\n")

func _update_tech_buttons() -> void:
	if not has_node("UI/Root/TechPanel"):
		return
	var tech_ids := _tech_order()
	var buttons := $UI/Root/TechPanel.get_children()
	for i in range(min(tech_ids.size(), buttons.size())):
		var button: Button = buttons[i]
		button.text = _tech_button_text(tech_ids[i])
		button.disabled = _has_tech(tech_ids[i])

func _tech_order() -> Array[String]:
	return ["change_samples", "queqiao_relay", "yutu_robot", "closed_ecology", "precision_landing", "robot_assist"]

func _operator_status_text() -> String:
	return "前哨员：%s\n健康 %.0f  精神 %.0f  疲劳 %.0f\n机器人：%s" % [
		operator.get("name", "林舟"),
		float(operator.get("health", 100.0)),
		float(operator.get("morale", 100.0)),
		float(operator.get("fatigue", 0.0)),
		_robot_task_name(robot_task) if (_has_tech("robot_assist") or _has_tech("yutu_robot")) else "待解锁"
	]

func _mission_status_text() -> String:
	var active := ""
	for mission_id: String in mission_defs.keys():
		if not completed_missions.has(mission_id):
			var mission: Dictionary = mission_defs[mission_id]
			active = "%s：%s" % [mission["name"], mission["desc"]]
			break
	if active == "":
		active = "阶段任务全部完成。"
	return "任务 %d/%d：%s" % [completed_missions.size(), mission_defs.size(), active]

func _eva_tasks_text() -> String:
	var tasks: Array[String] = []
	var supply_pods := _active_collectable_count("supply_pod")
	var ice_nodes := _active_collectable_count("ice")
	var external_repairs := _external_repair_count()
	if supply_pods > 0:
		tasks.append("回收补给舱：%d 个信标，氧气>35%%" % supply_pods)
	if ice_nodes > 0:
		tasks.append("采集水冰：%d 处，工具：采样铲" % ice_nodes)
	if solar_dust >= 0.22:
		tasks.append("清理太阳能板：月尘 %d%%，工具：除尘刷" % int(solar_dust * 100))
	if external_repairs > 0:
		tasks.append("维修外部设备：%d 个目标，工具：维修枪" % external_repairs)
	if tasks.is_empty():
		tasks.append("暂无紧急出舱任务。可巡检水冰、太阳能板和补给信标。")
	var suit_line := "宇航服：氧 %.0f%% 耐久 %.0f%% 月尘 %.0f%%" % [
		resources["suit_o2"], resources["suit_integrity"], resources["suit_dust"]
	]
	return "出舱任务 V1\n%s\n%s" % [_join_strings(tasks.slice(0, 3), "\n"), suit_line]

func _active_collectable_count(item_type: String) -> int:
	var count := 0
	for item: Dictionary in collectables:
		if item["depleted"]:
			continue
		if item["type"] == item_type:
			count += 1
	return count

func _external_repair_count() -> int:
	var count := 0
	for module: Dictionary in modules:
		if module.get("leaking", false):
			count += 1
			continue
		if module["type"] in ["regolith_plant", "ice_processor"] and resources["integrity"] < 70.0:
			count += 1
	return count

func _refresh_main_menu() -> void:
	if not has_node("UI/Root/MainMenu/Box"):
		return
	for slot in range(1, SAVE_SLOTS + 1):
		var button_path := "UI/Root/MainMenu/Box/SlotRow%d/Slot%d" % [slot, slot]
		if has_node(button_path):
			var button: Button = get_node(button_path)
			var marker := ">" if slot == current_save_slot else " "
			button.text = "%s 存档槽 %d：%s" % [marker, slot, _slot_summary(slot)]

func _tech_button_text(tech_id: String) -> String:
	var tech: Dictionary = tech_defs[tech_id]
	if _has_tech(tech_id):
		return "%s 已解锁" % tech["name"]
	var cost: Dictionary = tech["cost"]
	var parts: Array[String] = []
	for key: String in cost.keys():
		parts.append("%s %.0f" % [resource_names.get(key, key), float(cost[key])])
	return "%s（%s）" % [tech["name"], _join_strings(parts, " / ")]

func _supply_status_text() -> String:
	if supply_waiting:
		var pos := _dict_to_vector2(supply_order.get("landing_pos", _vector2_to_dict(Vector2.ZERO)))
		return "补给状态：%s 已着陆\n信标：%.0f, %.0f；出舱取货。" % [supply_order.get("name", "补给舱"), pos.x, pos.y]
	if not supply_order.is_empty():
		var eta: int = max(0, int(supply_order["arrival_day"]) - day)
		return "补给状态：%s 在途\nETA：%d 天（第 %d 天抵达）" % [supply_order["name"], eta, supply_order["arrival_day"]]
	if day >= next_supply_request_day:
		return "补给状态：可申请\n前往降落区按 E 提交货单。"
	return "补给状态：等待通信窗口\n下一次申请：第 %d 天" % next_supply_request_day

func add_log(text: String) -> void:
	log_lines.append("D%d  %s" % [day, text])
	while log_lines.size() > 12:
		log_lines.pop_front()
	if has_node("UI/Root/Log"):
		$UI/Root/Log.text = _join_strings(log_lines, "\n")

func _join_strings(values: Array, separator: String) -> String:
	var result := ""
	for i in range(values.size()):
		if i > 0:
			result += separator
		result += str(values[i])
	return result
