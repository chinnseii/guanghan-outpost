# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Claude Code（场景/UI 会话，正常职责，非代打）

## 正在进行

（暂无）

## 最近完成

- **Claude Code**：修了 Base Status System v1 UI 面板（`BaseStatusPanel`）的越界
  bug。它在 `_setup_base_status_panel()` 里的位置是 `Vector2(1250, 690)`，尺寸
  `420x300`，右边缘到 1670、下边缘到 990，超出 1600x900 视口——Tab 打开后
  面板右下角整块被裁掉，专业提示和后两项系统状态（温控/密封）完全看不到。
  改成了 `Vector2(1170, 180)`，紧贴右上角时间面板下方，四项基地状态 + 四个
  系统状态档位都能完整显示。用 `tools/capture_base_status_panel_check.gd`
  截图确认。这是我这次唯一的改动，Base Status System 本身的逻辑没有碰。

- **（下面这一段是"Claude Code 代 Codex"那次会话留的，未改动，供参考）**

- **Claude Code（代 Codex）**：实现 Base Status System v1（基地状态系统）。
  - 新增 `scripts/managers/BaseStatusManager.gd`，并在 `project.godot` 注册为
    `/root/BaseStatusManager`（放在 `TimeManager`/`HealthManager` 之后）。
  - 四项基地状态：电力 `power`、氧气 `oxygen`、舱压 `pressure`（均 0–100，越高
    越好）、温度 `temperature`（摄氏度，-40~60 clamp）。
  - 四个设备状态枚举 `SystemStatus`（OFFLINE/CRITICAL/BASIC/STABLE）：
    `power_system_status`、`life_support_status`、`thermal_control_status`、
    `seal_status`。
  - 抵达初始值：电力 42、氧气 68、舱压 76、温度 14℃；供电/生命支持/温控 =
    Critical，密封 = Basic（与需求文档第四节一致）。
  - `advance_base_time(minutes)`：不自己推进时间，只做结算；电力/氧气/舱压/
    温度按月夜/月昼、设备状态、电力对氧气与温控的倍率、舱压对氧气与温度的
    附加影响分别结算，规则数值来自需求文档第八节。
  - 轻/重维修方法（`repair_power_light/heavy`、`repair_life_support_light/heavy`、
    `repair_thermal_light/heavy`、`repair_seal_light/heavy`）：只改变设备状态
    档位 + 一次性数值增量，不推进时间——时间仍由调用方通过 TimeManager 推进。
  - `set_last_plant_recovered(true)`：温室最后一株植物脱离 Critical 时触发，
    氧气 +0.01/小时的小加成 + 一次性心理 +2（通过 HealthManager.adjust_stat）。
  - 专业提示 `get_specialist_hint()`：读取 `application_profile.json` 的
    `EducationBackground`，机械工程/材料科学/医学/植物科学四类文字提示，
    不提供任何数值加成。
  - `panel_status_text()` / `compact_hud_text()` / `debug_values_text()` /
    各 `get_*_label()`：文本分段规则来自需求文档第六节。
  - 存档：`user://saves/base_status_state.json`，独立文件，同时接入
    旧基地/温室/第一周存档（`sprint06_progress.json`）与训练进度存档
    （`training_progress.json`）的 `BaseStatusState` 字段。
  - Debug 支持：主菜单开发菜单新增基地状态 Debug 按钮（电力/氧气/舱压/温度
    加减、四个系统状态循环 Critical→Basic→Stable、重置 Day 01、设为最低稳定
    状态）。原有 Time Debug 的 +1h/+6h/跳到月昼/跳到月夜按钮现在会自动带动
    基地状态结算，未新增重复按钮。
  - UI：新增 `scripts/ui/base_status_panel.gd`（`BaseStatusPanel`，
    `PanelContainer`，纯代码构建，风格参照 `base_player_overlay.gd`），在
    `sprint06_base_scene.gd` 中通过 Tab 键开关，默认隐藏，不常驻 HUD。

## 对共用核心文件的改动记录（第一档文件，已按规则先查 git log 再改）

- `scripts/base/sprint06_base_scene.gd`（10 个场景共用）：
  - `_save_state()`/`_load_state()` 追加 `BaseStatusState` 序列化/反序列化，
    写法完全对齐已有的 `TimeState`/`HealthState` 处理方式。
  - 新增 `_sync_base_status_from_state()`，在 `_save_state()` 里统一调用，
    用一次性 `BaseStatus*Applied` 标记把既有的
    `PowerPanelRepaired`/`BasePowerRestored`/`MinimalLifeSupportStable`/
    `LastPlantStable` 四个旧状态标志映射成对应的 BaseStatusManager 调用，
    没有改动这四个标志原本的触发时机和文案。
  - 新增 Tab 键（`toggle_base_status` action）开关 `BaseStatusPanel`，只在
    `_setup_ui()`/`_unhandled_input()`/`_update_ui()` 分别加了几行，没有动
    现有的 `_hud_text()`/`_safe_hud_text()` 常驻 HUD 文本。
- `scripts/managers/TimeManager.gd`：
  - `advance_time()` 在 `_update_lunar_phase()` 之后、
    `_apply_health_action_cost()` 之前新增 `_apply_base_status_time()` 调用，
    顺序符合需求文档第七节"先结算基地状态、再结算健康行动消耗"。
  - `reset_to_arrival()` 追加对 `BaseStatusManager.reset_to_arrival()` 的
    级联调用，写法与已有的 HealthManager 级联完全一致。
- `scripts/managers/HealthManager.gd`：
  - `get_energy_cost_multiplier()` 保留原有 fullness 分段数值不变，追加乘以
    `_environment_energy_multiplier()`（读取 BaseStatusManager 的温度/氧气
    倍率，BaseStatusManager 不存在时回退为 1.0，不影响旧行为）。
- `scripts/training/training_manager.gd`：
  - `default_data()`/`load_progress()`/`save_progress()`/`reset_progress()`
    追加 `BaseStatusState` 字段，写法对齐已有的 `HealthState` 处理。
- `scripts/props/reference_prop.gd`：本次未触碰。

## 验证

- Godot 4.7 headless 逐个加载并确认无 `SCRIPT ERROR`/`Parse Error`：
  `OldBaseInteriorScene.tscn`、`OldGreenhouseScene.tscn`、
  `Training_03_PowerRepair.tscn`、`main.tscn`、`Day02StartScene.tscn`、
  `WeekRoutineStartScene.tscn`、`SolarArrayExteriorScene.tscn`、
  `FinalAssessmentScene.tscn`。
- 临时脚本（未提交，验证后已删除）跑通了：抵达初始值、推进 6 小时后电力/
  温度按月夜费率下降、轻/重维修使设备状态升档且立即加值、跳到月昼后供电
  Stable 时电力明显回升、月昼下持续推进后氧气受电力/舱压影响、最后一株
  植物 bonus 生效、"设为最低稳定状态"与"重置 Day 01"互相覆盖正确、寒冷
  温度下 `HealthManager.get_energy_cost_multiplier()` 从 1.0 变为 1.1。
- 未跑图形界面截图（本次未涉及新视觉资产，仅新增一个默认隐藏、按 Tab 打开
  的面板；截图验收留给人类玩测或下一轮）。

## 已知问题 / 暂不覆盖范围

- 密封（气密）目前只有方法 + Debug 按钮，没有接入任何现有玩法交互（旧基地
  流程里没有密封维修的场景/按钮），按需求文档第九节末尾的说明这是允许的。
- 温控系统同样只有方法 + Debug 按钮，没有接入现有交互（现有流程没有温控
  维修点）。
- "植物状态 Critical/Recovering"对植物科学专业提示的判断，用
  `last_plant_recovered_bonus_active` 代理（BaseStatusManager 拿不到温室
  内部的 Critical/Recovering/Stable 细分状态），是一版近似实现。
- 氧气 0–19 的"高风险行动强提醒"目前只体现在 `panel_status_text()` 的警告行
  里，没有强插到具体维修/采集交互的确认弹窗中。
- 未新增 `scenes/ui/BaseStatusPanel.tscn`——面板用纯 GDScript
  （`scripts/ui/base_status_panel.gd`）构建，跟仓库里其它自定义面板
  （`base_player_overlay.gd`、`art_slice_marker_layer.gd`）的既有风格一致。
- Godot 在本地会刷新大量已跟踪 `.import` 文件和生成 `.uid`/`.godot_appdata/`，
  它们不属于本次改动，提交时未暂存。

## 先别碰

（暂无）
