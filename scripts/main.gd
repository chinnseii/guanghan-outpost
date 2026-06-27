extends Node2D

const TILE := 48
const MAP_W := 22
const MAP_H := 13
const MAP_ORIGIN := Vector2(50, 70)
const PLAYER_SPEED := 190.0
const SAVE_PATH := "user://guanghan_outpost_save.json"

var day := 1
var is_moon_night := false
var game_over := false
var supply_waiting := false
var supply_order: Dictionary = {}
var next_supply_request_day := 1
var supply_travel_days := 3

var player_pos := Vector2(300, 420)
var player_radius := 14.0
var player_facing := Vector2.DOWN
var walk_phase := 0.0
var interact_target: Dictionary = {}

var selected_crop := "potato"
var selected_tool := "sampler"
var build_mode := false
var selected_build := ""
var log_lines: Array[String] = []

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

var modules: Array[Dictionary] = []
var collectables: Array[Dictionary] = []

func _ready() -> void:
	_setup_input_map()
	_reset_game_state()
	_setup_ui()
	add_log("广寒前哨上线。玉兔工程车完成自动部署，但系统仍需人工调试。")
	add_log("V0.5：新增舱段连通和漏气事故。新模块必须贴近已有基地。")
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
	player_pos = Vector2(300, 420)
	player_facing = Vector2.DOWN
	walk_phase = 0.0
	interact_target = {}
	selected_crop = "potato"
	selected_tool = "sampler"
	build_mode = false
	selected_build = ""
	solar_dust = 0.12
	oxygen_wear = 0.08
	next_module_uid = 1
	next_collectable_uid = 1
	resources = _default_resources()
	modules.clear()
	collectables.clear()
	log_lines.clear()
	_setup_starting_base()
	_setup_collectables()
	if has_node("UI/Root/SupplyPanel"):
		$UI/Root/SupplyPanel.visible = false

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
	}

func _setup_starting_base() -> void:
	modules.clear()
	_add_module("solar", Vector2i(2, 1), true)
	_add_module("hab", Vector2i(4, 5), true)
	_add_module("life_support", Vector2i(8, 6), true)
	_add_module("greenhouse", Vector2i(11, 3), true)
	_add_module("supply", Vector2i(17, 7), true)

func _process(delta: float) -> void:
	if game_over:
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_pos += input * PLAYER_SPEED * delta
	if input.length() > 0.01:
		player_facing = input.normalized()
		walk_phase += delta * 10.0
	player_pos.x = clamp(player_pos.x, MAP_ORIGIN.x + 5.0, MAP_ORIGIN.x + MAP_W * TILE - 5.0)
	player_pos.y = clamp(player_pos.y, MAP_ORIGIN.y + 5.0, MAP_ORIGIN.y + MAP_H * TILE - 5.0)
	_find_interaction()
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
	_draw_moon_surface()
	_draw_collectables()
	_draw_modules()
	_draw_build_ghost()
	_draw_player()

func _draw_moon_surface() -> void:
	draw_rect(Rect2(0, 0, 1150, 720), Color("#17191f"))
	for x in range(MAP_W):
		for y in range(MAP_H):
			var p := MAP_ORIGIN + Vector2(x * TILE, y * TILE)
			var shade := 0.18 + float((x * 17 + y * 11) % 7) * 0.012
			draw_rect(Rect2(p, Vector2(TILE - 2, TILE - 2)), Color(shade, shade, shade + 0.02))
	for i in range(18):
		var cx := 90 + (i * 157) % 980
		var cy := 95 + (i * 83) % 510
		draw_circle(Vector2(cx, cy), 10 + (i % 4) * 5, Color(0.08, 0.085, 0.095, 0.45))

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
	if interact_target.get("leaking", false):
		_repair_module_leak(interact_target)
		_update_ui()
		return
	match String(interact_target["type"]):
		"greenhouse":
			_use_greenhouse(interact_target)
		"solar":
			_clean_solar()
		"life_support":
			_repair_life_support()
		"supply":
			_collect_supply()
		"workshop":
			_use_workshop()
		_:
			var def: Dictionary = module_defs[interact_target["type"]]
			add_log("%s 运转正常。" % def["name"])
	_update_ui()

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
	add_log("已封堵 %s 漏点，舱压恢复稳定。" % def["name"])

func _use_workshop() -> void:
	if resources["power"] < 4:
		add_log("电力不足，维修工作台无法打印零件。")
		return
	resources["power"] -= 4
	resources["parts"] = min(99.0, resources["parts"] + 1)
	add_log("维修工作台打印了 1 个维修件。")

func _collect_supply() -> void:
	if supply_waiting:
		_receive_supply()
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

func _collect_surface_item(item: Dictionary) -> void:
	if selected_tool != "sampler":
		add_log("需要先选择采样铲。")
		return
	var amount: float = item["amount"]
	match String(item["type"]):
		"regolith":
			resources["regolith"] += amount
			add_log("采集月壤 +%.0f。未来可用于月壤提氧和防辐射覆盖。" % amount)
		"ice":
			resources["ice"] += amount
			resources["water"] += amount * 2.0
			add_log("采集水冰样本 +%.0f，水 +%.0f。" % [amount, amount * 2.0])
		"meteor":
			resources["parts"] += amount
			resources["samples"] += 1.0
			add_log("回收陨石金属：维修件 +%.0f，科研样本 +1。" % amount)
		"sample":
			resources["samples"] += amount
			add_log("采集特殊月壤样本 +%.0f。嫦娥样本数据库可用于后续科技线。" % amount)
	item["depleted"] = true

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
	var crew_food: float = 7.0
	var crew_water: float = max(2.5, 5.0 - float(counts["life_support"]) * 0.8)
	var crew_oxygen: float = max(3.5, 6.0 - float(counts["life_support"]) * 0.7)
	resources["power"] += solar_gain - base_power_use
	resources["oxygen"] -= crew_oxygen + oxygen_wear * 8.0
	resources["water"] -= crew_water
	resources["food"] -= crew_food
	resources["integrity"] -= 1.0 + solar_dust * 1.8 + float(modules.size()) * 0.04
	var leaking_count := _leaking_module_count()
	if leaking_count > 0:
		resources["oxygen"] -= float(leaking_count) * 8.0
		resources["integrity"] -= float(leaking_count) * 2.0
		add_log("警报：%d 个舱段漏气，氧气正在流失。" % leaking_count)
	if counts["workshop"] > 0:
		resources["parts"] = min(99.0, resources["parts"] + 0.25 * float(counts["workshop"]))
	solar_dust = min(0.65, solar_dust + randf_range(0.02, 0.06))
	oxygen_wear = min(0.45, oxygen_wear + randf_range(0.01, 0.04))
	_process_crop_day()
	_process_supply_window()
	_process_random_event()
	for key: String in ["power", "oxygen", "water", "food", "integrity"]:
		resources[key] = clamp(resources[key], 0.0, power_cap if key == "power" else 120.0)
	add_log("第 %d 天开始。%s" % [day, "月夜中，太阳能归零。" if is_moon_night else "月昼，太阳能可用。"])
	_check_game_state()
	_update_ui()
	queue_redraw()

func _process_crop_day() -> void:
	for module: Dictionary in modules:
		if module["type"] != "greenhouse" or module["crop"] == "":
			continue
		module["age"] += 1
		var crop_def: Dictionary = crop_defs[module["crop"]]
		resources["oxygen"] += crop_def["oxygen"] if not is_moon_night else crop_def["oxygen"] * 0.35
		if module["age"] >= crop_def["days"]:
			resources["food"] += crop_def["food"]
			add_log("%s 成熟收获：食物 +%d。" % [crop_def["name"], int(crop_def["food"])])
			module["crop"] = ""
			module["age"] = 0

func _process_supply_window() -> void:
	if not supply_order.is_empty() and day >= int(supply_order["arrival_day"]):
		supply_waiting = true
		add_log("%s 已抵达补给降落区。前往降落区接收。" % supply_order["name"])
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
	if randf() < 0.15:
		delay += 1
		add_log("地面发射排程拥堵，本批补给延迟 1 天。")
	supply_order = {
		"kind": kind,
		"name": def["name"],
		"arrival_day": day + delay,
		"requested_day": day,
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
	add_log("接收 %s：%s。" % [def["name"], def["desc"]])
	supply_order.clear()
	supply_waiting = false
	_update_ui()

func _save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
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
	add_log("已保存到 %s。" % SAVE_PATH)
	_update_ui()

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		add_log("没有找到存档。")
		_update_ui()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
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
	add_log("已读取存档。")
	_update_ui()
	queue_redraw()

func _start_new_game() -> void:
	_reset_game_state()
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
	log_lines.clear()
	var saved_logs: Array = data.get("log_lines", [])
	for entry in saved_logs:
		log_lines.append(String(entry))
	if has_node("UI/Root/SupplyPanel"):
		$UI/Root/SupplyPanel.visible = false

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

func _check_game_state() -> void:
	var failed: Array[String] = []
	for key: String in ["power", "oxygen", "water", "food"]:
		if resources[key] <= 0.0:
			failed.append(resource_names[key])
	if failed.size() > 0:
		game_over = true
		add_log("基地失守：%s 归零。请调整补给和维护优先级后重试。" % _join_strings(failed, ", "))
	if day > 30 and not game_over:
		add_log("30 天生存目标完成。下一步可以加入船员、月壤提氧和外出采集。")

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
	return module_type in ["hab", "greenhouse", "battery", "life_support", "workshop"]

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
	controls.size = Vector2(350, 120)
	controls.text = "WASD/方向键：移动\nE：交互/采集/建造\nN：进入下一天\nB：建造模式\nF5/F9/F10：保存/读取/新局"
	root.add_child(controls)

	var supply_status := Label.new()
	supply_status.name = "SupplyStatus"
	supply_status.position = Vector2(905, 455)
	supply_status.size = Vector2(350, 74)
	supply_status.add_theme_font_size_override("font_size", 16)
	root.add_child(supply_status)

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
	for module_type: String in ["solar", "battery", "greenhouse", "life_support", "workshop"]:
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
	save_panel.position = Vector2(905, 535)
	save_panel.size = Vector2(330, 38)
	root.add_child(save_panel)
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
	var hint := "工具：%s | 作物：%s | 月壤 %.0f 水冰 %.0f 样本 %.0f。" % [
		tool_defs[selected_tool]["name"], crop_defs[selected_crop]["name"],
		resources["regolith"], resources["ice"], resources["samples"]
	]
	if build_mode and selected_build != "":
		var def: Dictionary = module_defs[selected_build]
		var cost: Dictionary = def["cost"]
		hint = "建造模式：%s | 成本：维修件 %.0f、电力 %.0f | 靠近空地按 E，Esc 取消。" % [def["name"], cost["parts"], cost["power"]]
	elif not interact_target.is_empty():
		if interact_target.has("kind") and interact_target["kind"] == "collectable":
			hint = "月面采集点：按 E 使用 %s。%s" % [tool_defs[selected_tool]["name"], tool_defs[selected_tool]["hint"]]
		else:
			var def: Dictionary = module_defs[interact_target["type"]]
			if interact_target.get("leaking", false):
				hint = "%s：舱段漏气。切换维修枪并按 E 封堵，消耗 2 维修件。" % def["name"]
			else:
				hint = "%s：%s" % [def["name"], def["hint"]]
	$UI/Root/Hint.text = hint
	$UI/Root/Log.text = _join_strings(log_lines, "\n")

func _supply_status_text() -> String:
	if supply_waiting:
		return "补给状态：%s 已抵达\n前往降落区按 E 接收。" % supply_order.get("name", "补给舱")
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
