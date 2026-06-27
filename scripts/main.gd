extends Node2D

const TILE := 48
const PLAYER_SPEED := 190.0
const MAP_W := 22
const MAP_H := 13

var day := 1
var is_moon_night := false
var selected_crop := "土豆"
var greenhouse_crop := ""
var crop_age := 0
var greenhouse_slots := 2
var supply_waiting := false
var game_over := false

var resources := {
	"电力": 76.0,
	"氧气": 82.0,
	"水": 68.0,
	"食物": 50.0,
	"维修件": 5.0,
	"完整度": 88.0,
}

var solar_dust := 0.12
var oxygen_wear := 0.08
var player_pos := Vector2(300, 420)
var player_radius := 14.0
var interact_target := {}
var log_lines: Array[String] = []

var stations := [
	{"id": "greenhouse", "name": "小型温室", "rect": Rect2(560, 205, 185, 120), "hint": "E：播种/查看作物"},
	{"id": "solar", "name": "太阳能阵列", "rect": Rect2(150, 130, 210, 95), "hint": "E：清理月尘"},
	{"id": "oxygen", "name": "制氧与水回收", "rect": Rect2(410, 380, 170, 110), "hint": "E：维修设备"},
	{"id": "supply", "name": "补给降落区", "rect": Rect2(850, 395, 190, 125), "hint": "E：接收地球补给"},
	{"id": "hab", "name": "居住舱", "rect": Rect2(250, 310, 145, 105), "hint": "广寒前哨核心舱"},
]

var crop_defs := {
	"土豆": {"days": 4, "water": 5.0, "oxygen": 2.0, "food": 22.0, "note": "可靠主粮"},
	"藻类": {"days": 2, "water": 3.0, "oxygen": 10.0, "food": 7.0, "note": "产氧强，口感差"},
	"菌菇": {"days": 3, "water": 2.0, "oxygen": 0.0, "food": 13.0, "note": "低光照可生产"},
}

func _ready() -> void:
	_setup_input_map()
	_setup_ui()
	add_log("广寒前哨上线。玉兔工程车完成自动部署，但系统仍需人工调试。")
	add_log("目标：撑过 30 天，并让温室开始稳定产出。")
	_update_ui()

func _setup_input_map() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("advance_day", [KEY_N])

func _add_key_action(action_name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key: int in keys:
		var event := InputEventKey.new()
		event.keycode = key
		InputMap.action_add_event(action_name, event)

func _process(delta: float) -> void:
	if game_over:
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_pos += input * PLAYER_SPEED * delta
	player_pos.x = clamp(player_pos.x, 55.0, 1095.0)
	player_pos.y = clamp(player_pos.y, 90.0, 625.0)
	_find_interaction()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not game_over:
		_interact()
	if event.is_action_pressed("advance_day") and not game_over:
		_advance_day()

func _draw() -> void:
	_draw_moon_surface()
	_draw_base()
	_draw_player()

func _draw_moon_surface() -> void:
	draw_rect(Rect2(0, 0, 1150, 720), Color("#17191f"))
	for x in range(MAP_W):
		for y in range(MAP_H):
			var p := Vector2(50 + x * TILE, 70 + y * TILE)
			var shade := 0.18 + float((x * 17 + y * 11) % 7) * 0.012
			draw_rect(Rect2(p, Vector2(TILE - 2, TILE - 2)), Color(shade, shade, shade + 0.02))
	for i in range(18):
		var cx := 90 + (i * 157) % 980
		var cy := 95 + (i * 83) % 510
		draw_circle(Vector2(cx, cy), 10 + (i % 4) * 5, Color(0.08, 0.085, 0.095, 0.45))

func _draw_base() -> void:
	for station: Dictionary in stations:
		var rect: Rect2 = station["rect"]
		var fill := Color("#28313f")
		if station["id"] == "greenhouse":
			fill = Color("#244638")
		elif station["id"] == "solar":
			fill = Color("#263b57")
		elif station["id"] == "supply":
			fill = Color("#3d3530")
		elif station["id"] == "oxygen":
			fill = Color("#30384a")
		if interact_target == station:
			draw_rect(rect.grow(5), Color("#e7c66b"), false, 3)
		draw_rect(rect, fill)
		draw_rect(rect, Color("#a7b3c5"), false, 2)
		if station["id"] == "greenhouse":
			_draw_greenhouse(rect)
		elif station["id"] == "solar":
			_draw_solar(rect)
		elif station["id"] == "supply":
			draw_circle(rect.get_center(), 32, Color("#a76f45"))
			draw_rect(Rect2(rect.position + Vector2(68, 25), Vector2(54, 74)), Color("#d0d6df"), false, 3)
		elif station["id"] == "hab":
			draw_circle(rect.get_center(), 42, Color("#596575"))
			draw_rect(rect, Color("#d8e0eb"), false, 2)

func _draw_greenhouse(rect: Rect2) -> void:
	for i in range(greenhouse_slots):
		var bed := Rect2(rect.position + Vector2(20 + i * 72, 35), Vector2(52, 48))
		draw_rect(bed, Color("#223026"))
		draw_rect(bed, Color("#74b77a"), false, 2)
		if greenhouse_crop != "":
			var growth: float = min(1.0, float(crop_age + 1) / float(crop_defs[greenhouse_crop]["days"]))
			draw_circle(bed.get_center(), 7 + 13 * growth, Color("#71d46f"))

func _draw_solar(rect: Rect2) -> void:
	for i in range(4):
		var panel := Rect2(rect.position + Vector2(14 + i * 48, 18), Vector2(38, 58))
		draw_rect(panel, Color("#365f95"))
		draw_rect(panel, Color("#94bdeb"), false, 1)
	var dust_alpha: float = clamp(solar_dust, 0.0, 0.7)
	draw_rect(rect, Color(0.72, 0.72, 0.66, dust_alpha))

func _draw_player() -> void:
	draw_circle(player_pos, player_radius + 4, Color("#1b222d"))
	draw_circle(player_pos, player_radius, Color("#f2f0da"))
	draw_circle(player_pos + Vector2(4, -3), 5, Color("#7fb8ff"))

func _find_interaction() -> void:
	interact_target = {}
	for station: Dictionary in stations:
		var rect: Rect2 = station["rect"].grow(24)
		if rect.has_point(player_pos):
			interact_target = station
			return

func _interact() -> void:
	if interact_target.is_empty():
		add_log("附近没有可操作目标。")
		return
	match interact_target["id"]:
		"greenhouse":
			_use_greenhouse()
		"solar":
			_clean_solar()
		"oxygen":
			_repair_life_support()
		"supply":
			_collect_supply()
		_:
			add_log("%s 运转正常。" % interact_target["name"])
	_update_ui()

func _use_greenhouse() -> void:
	if greenhouse_crop == "":
		var def: Dictionary = crop_defs[selected_crop]
		if resources["水"] < def["water"]:
			add_log("水不足，无法种植 %s。" % selected_crop)
			return
		resources["水"] -= def["water"]
		greenhouse_crop = selected_crop
		crop_age = 0
		add_log("在小型温室种下 %s。%s。" % [selected_crop, def["note"]])
	else:
		var def: Dictionary = crop_defs[greenhouse_crop]
		add_log("%s 生长进度 %d/%d 天。" % [greenhouse_crop, crop_age, def["days"]])

func _clean_solar() -> void:
	if resources["维修件"] < 1:
		add_log("缺少维修件，无法进行除尘维护。")
		return
	resources["维修件"] -= 1
	solar_dust = max(0.0, solar_dust - 0.28)
	add_log("清理太阳能阵列。月尘覆盖降至 %d%%。" % int(solar_dust * 100))

func _repair_life_support() -> void:
	if resources["维修件"] < 1:
		add_log("维修件不足，制氧与水回收系统只能继续带病运行。")
		return
	resources["维修件"] -= 1
	resources["完整度"] = min(100.0, resources["完整度"] + 12.0)
	oxygen_wear = max(0.0, oxygen_wear - 0.12)
	add_log("完成一次生命维持系统维护。")

func _collect_supply() -> void:
	if not supply_waiting:
		add_log("降落区暂无补给。下一次窗口：第 %d 天。" % _next_supply_day())
		return
	_show_supply_choices()

func _advance_day() -> void:
	day += 1
	is_moon_night = day >= 14 and day < 22
	var crew_food := 7.0
	var crew_water := 5.0
	var crew_oxygen := 6.0
	var solar_gain := 24.0 * (1.0 - solar_dust)
	if is_moon_night:
		solar_gain = 0.0
	var power_use := 18.0
	if is_moon_night:
		power_use += 14.0
	resources["电力"] += solar_gain - power_use
	resources["氧气"] -= crew_oxygen + oxygen_wear * 8.0
	resources["水"] -= crew_water
	resources["食物"] -= crew_food
	resources["完整度"] -= 1.0 + solar_dust * 1.8
	solar_dust = min(0.65, solar_dust + randf_range(0.02, 0.06))
	oxygen_wear = min(0.45, oxygen_wear + randf_range(0.01, 0.04))
	_process_crop_day()
	_process_supply_window()
	_process_random_event()
	for key: String in ["电力", "氧气", "水", "食物", "完整度"]:
		resources[key] = clamp(resources[key], 0.0, 120.0)
	if resources["维修件"] > 99:
		resources["维修件"] = 99
	add_log("第 %d 天开始。%s" % [day, "月夜中，太阳能归零。" if is_moon_night else "月昼，太阳能可用。"])
	_check_game_state()
	_update_ui()
	queue_redraw()

func _process_crop_day() -> void:
	if greenhouse_crop == "":
		return
	crop_age += 1
	var def: Dictionary = crop_defs[greenhouse_crop]
	if not is_moon_night:
		resources["氧气"] += def["oxygen"]
	else:
		resources["氧气"] += def["oxygen"] * 0.35
	if crop_age >= def["days"]:
		resources["食物"] += def["food"]
		add_log("%s 成熟收获：食物 +%d。" % [greenhouse_crop, int(def["food"])])
		greenhouse_crop = ""
		crop_age = 0

func _process_supply_window() -> void:
	if day % 7 == 0:
		supply_waiting = true
		add_log("地球补给舱进入降落窗口。前往降落区接收。")

func _process_random_event() -> void:
	if day == 5:
		add_log("月尘静电附着增强，太阳能效率开始下降。")
	if day == 11:
		add_log("地面控制提醒：月夜将在第 14 天开始，请提前储电。")
	if randf() < 0.12:
		resources["完整度"] -= 5.0
		add_log("微小冲击触发舱体巡检，设备完整度下降。")

func _show_supply_choices() -> void:
	$UI/SupplyPanel.visible = true

func _choose_supply(kind: String) -> void:
	if not supply_waiting:
		return
	if kind == "survival":
		resources["食物"] += 28
		resources["水"] += 20
		resources["氧气"] += 22
		add_log("接收生存补给：食物、水、氧气增加。")
	elif kind == "build":
		resources["维修件"] += 6
		resources["电力"] += 18
		solar_dust = max(0.0, solar_dust - 0.12)
		add_log("接收建设补给：维修件、电池单元和除尘耗材到位。")
	elif kind == "farm":
		resources["水"] += 10
		greenhouse_slots = min(4, greenhouse_slots + 1)
		add_log("接收农业补给：温室耗材到位，种植槽 +1。")
	supply_waiting = false
	$UI/SupplyPanel.visible = false
	_update_ui()

func _check_game_state() -> void:
	var failed: Array[String] = []
	for key: String in ["电力", "氧气", "水", "食物"]:
		if resources[key] <= 0.0:
			failed.append(key)
	if failed.size() > 0:
		game_over = true
		add_log("基地失守：%s 归零。请调整补给和维护优先级后重试。" % _join_strings(failed, ", "))
	if day > 30 and not game_over:
		add_log("30 天生存目标完成。下一步可以加入基地扩建、船员和月壤提氧。")

func _next_supply_day() -> int:
	return day + (7 - day % 7)

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
	top.size = Vector2(1040, 56)
	top.add_theme_font_size_override("font_size", 22)
	root.add_child(top)
	var hint := Label.new()
	hint.name = "Hint"
	hint.position = Vector2(18, 646)
	hint.size = Vector2(760, 42)
	hint.add_theme_font_size_override("font_size", 18)
	root.add_child(hint)
	var log := RichTextLabel.new()
	log.name = "Log"
	log.position = Vector2(905, 20)
	log.size = Vector2(350, 320)
	log.fit_content = false
	log.scroll_following = true
	root.add_child(log)
	var controls := Label.new()
	controls.name = "Controls"
	controls.position = Vector2(905, 350)
	controls.size = Vector2(350, 120)
	controls.text = "WASD/方向键：移动\nE：交互\nN：进入下一天\n按钮：选择下一批补给/作物"
	root.add_child(controls)
	var crop_panel := HBoxContainer.new()
	crop_panel.name = "CropPanel"
	crop_panel.position = Vector2(18, 590)
	crop_panel.size = Vector2(520, 38)
	root.add_child(crop_panel)
	for crop_name: String in crop_defs.keys():
		var button := Button.new()
		button.text = crop_name
		button.pressed.connect(_select_crop.bind(crop_name))
		crop_panel.add_child(button)
	var next_day := Button.new()
	next_day.name = "NextDay"
	next_day.text = "进入下一天"
	next_day.position = Vector2(650, 588)
	next_day.size = Vector2(130, 40)
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
	title.text = "地球补给到达：选择本次 300kg 货单"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	var b1 := Button.new()
	b1.text = "生存包：食物 + 水 + 氧气"
	b1.pressed.connect(func(): _choose_supply("survival"))
	box.add_child(b1)
	var b2 := Button.new()
	b2.text = "建设包：维修件 + 电池 + 除尘耗材"
	b2.pressed.connect(func(): _choose_supply("build"))
	box.add_child(b2)
	var b3 := Button.new()
	b3.text = "农业包：温室耗材 + 种植槽"
	b3.pressed.connect(func(): _choose_supply("farm"))
	box.add_child(b3)

func _select_crop(crop_name: String) -> void:
	selected_crop = crop_name
	add_log("已选择作物：%s。" % crop_name)
	_update_ui()

func _update_ui() -> void:
	if not has_node("UI/Root"):
		return
	var phase := "月夜" if is_moon_night else "月昼"
	$UI/Root/Top.text = "广寒前哨 | 第 %d 天 | %s | 电力 %.0f  氧气 %.0f  水 %.0f  食物 %.0f  维修件 %.0f  完整度 %.0f%%  月尘 %d%%" % [
		day, phase, resources["电力"], resources["氧气"], resources["水"], resources["食物"],
		resources["维修件"], resources["完整度"], int(solar_dust * 100)
	]
	var hint := "靠近设施按 E 交互。当前作物：%s。" % selected_crop
	if not interact_target.is_empty():
		hint = "%s：%s" % [interact_target["name"], interact_target["hint"]]
	$UI/Root/Hint.text = hint
	$UI/Root/Log.text = _join_strings(log_lines, "\n")

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
