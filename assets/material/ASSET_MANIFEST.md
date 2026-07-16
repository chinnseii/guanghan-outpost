# 广寒前哨｜模块化基地素材清单

## 文件与格式

| 文件 | 用途 |
| --- | --- |
| `lunar_base_modular_atlas.png` | 2048×2048 透明底图集，低饱和冷蓝灰月面工业像素素材。 |
| `lunar_base_modular_atlas.json` | 116 个切片的坐标、原始尺寸和语义化名称。JSON 的 `meta.image` 已指向同名图集。 |
| `door_sign_suit_helmet.png` | 独立透明 PNG；宇航服整备室门的头盔方向铭牌。 |
| `door_sign_air_fan.png` | 独立透明 PNG；空气系统控制室门的风扇方向铭牌。 |

图集保留 Smart Sprite Sheet Packer 的 4 px padding、1 px extrusion、无旋转导出设置。`sprite.png` 与 `sprite.json` 已改为上列正式名称。

## 命名规则

`类别_对象_状态_变体`

- 全小写英文、snake_case。
- 状态只在有实际视觉差异时使用，例如 `critical`、`stable`、`withered`、`dim`。
- 同类变体用清晰的功能后缀，不使用无意义的编号作为主名称。
- JSON 的 frame key 即开发接入时应使用的资源标识，例如 `floor_plate_plain.png`。

## 分类索引

### 地板与地面细节

`floor_plate_plain`、`floor_plate_seamed`、`floor_plate_center_seam`、`floor_plate_cross_seam`、`floor_plate_quad`、`floor_plate_diamond`、`floor_plate_worn_hazard`、`floor_plate_hazard_corner`、`floor_plate_cracked`、`floor_plate_damaged`、`floor_grate_square`、`floor_vent_rectangular`、`decal_hazard_stripe_diagonal`、`decal_floor_hazard_scuffs`、`decal_maintenance_papers`、`decal_poster_set`。

### 墙体、门与结构

`wall_corner_inner_top_left`、`wall_corner_inner_top_right`、`wall_corner_inner_bottom_left`、`wall_corner_inner_bottom_right`、`wall_corner_outer_left`、`wall_corner_outer_top_right`、`wall_corner_outer_bottom_left`、`wall_segment_horizontal`、`wall_segment_short`、`wall_connector_t`、`wall_cap_end`。

`door_standard_center`、`door_airlock_plain`、`door_airlock_status`、`door_airlock_a01`、`door_airlock_vertical`。

独立门向铭牌：`door_sign_suit_helmet.png`（宇航服整备室）、`door_sign_air_fan.png`（空气系统控制室）。配电房与训练温室分别使用图集内的 `ui_icon_power`、`ui_icon_plant`。

### 温室、生命支持与基地道具

`plant_chamber_tall_lit`、`plant_chamber_tall_dim`、`plant_chamber_tall_warning`、`plant_chamber_narrow`、`hydroponic_rack_empty`、`hydroponic_rack_dual`、`hydroponic_rack_withered`、`plant_pot_large`、`plant_pot_medium`、`grow_light_dual`、`grow_light_pair`、`equipment_life_support`。

`prop_utility_crate_set`、`prop_workbench_maintenance`、`prop_notice_board`、`prop_storage_locker`、`prop_storage_locker_small`、`prop_storage_crate_medium`、`prop_storage_crate_small`、`prop_tool_crate`、`prop_document_set`。

### 管线、设备与控制台

`pipe_corner_large`、`pipe_straight_long`、`pipe_elbow_short`、`pipe_elbow_long`、`pipe_support_vertical`、`pipe_support_tall`、`pipe_junction_t`、`equipment_pipe_valve`、`equipment_pipe_endcap`、`equipment_pump_vertical`。

`console_command_center`、`console_navigation_radar`、`console_terminal_compact`、`console_status_panel`、`console_cabinet_compact`、`console_service_horizontal`、`equipment_power_cabinet`、`equipment_control_panel`、`equipment_control_cabinet`、`equipment_cabinet_narrow`、`vent_floor_horizontal`。

### 显示器、外部环境与 UI

`monitor_power_output`、`monitor_oxygen_system`、`monitor_water_cycle`、`monitor_greenhouse_critical`、`monitor_greenhouse_stable`、`monitor_greenhouse_status`、`monitor_alert_critical`、`monitor_status_narrow`、`monitor_log_day12`。

`solar_panel_array_wide`、`solar_panel_array_tilted`、`solar_panel_array_compact`、`solar_panel_array_damaged`、`moon_rock_large`、`moon_rock_medium`、`moon_rock_small`、`moon_rock_cluster`。

`ui_icon_health`、`ui_icon_temperature`、`ui_icon_habitat_status`、`ui_icon_water`、`ui_icon_oxygen`、`ui_icon_power`、`ui_icon_greenhouse_status`、`ui_icon_signal`、`ui_icon_warning`、`ui_icon_plant`、`ui_icon_plant_recovering`、`ui_icon_habitat_outline`、`ui_icon_confirm`、`ui_icon_system_offline`、`ui_icon_wrench`、`ui_icon_wrench_alt`。

### 调色板参考

`palette_moon_gray`、`palette_ice_blue`、`palette_steel_blue`、`palette_panel_blue`、`palette_life_green`、`palette_deep_green`、`palette_warning_amber`、`palette_warning_red`、`palette_warm_white`。

## Godot 接入说明

1. 使用 `lunar_base_modular_atlas.json` 读取 frame 的 `frame` 矩形，而不是依赖旧的 `icon_001.png` 等编号。
2. TileMap 地板优先使用 `floor_*` 与 `decal_*`；门、设备和 UI 图标保持为独立 Sprite2D / TextureRect 资源。
3. 导入设置建议关闭纹理过滤（Nearest），保留透明像素；不要按图集整体缩放后再切片。
4. 告警使用 `palette_warning_amber` / `palette_warning_red`，生态与稳定状态使用 `palette_life_green`，避免给所有设备附加同等亮度的发光效果。

## 注意

本目录仍是**图集 + 描述 JSON**，不是 116 张独立 PNG。若需要逐张文件交给 Godot 以外的工具，按 JSON 的 frame key 导出即可，导出的文件名应与该 key 保持一致。
