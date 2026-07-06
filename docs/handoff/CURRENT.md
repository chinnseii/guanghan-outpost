# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Claude Code（本轮临时顶替 Codex 的游戏逻辑/Manager/数据/流程职责——Codex
临时无 token，由 Claude Code 在独立会话中代打这部分；同一时间另一个 Claude Code
会话仍在并行做场景/UI/美术。Codex 恢复后请按下方记录核对，不要误以为是
Codex 自己之前做的）

## 正在进行

（暂无，Plant Growth System v1 已完成，本轮改动已提交）

## 最近完成

- **Claude Code（代 Codex）**：实现 Plant Growth System v1（植物生长系统）。
  - 新增 `scripts/systems/PlantGrowthManager.gd`，在 `project.godot` 注册为
    `/root/PlantGrowthManager`（放在 `BaseStatusManager` 之后）。
  - 新增 `scripts/data/PlantCropData.gd`：生菜/土豆/小麦/番茄/大豆五种作物的
    静态数据（生长天数、水/光需求档位、适宜温度、收获饱腹/营养/心理、
    番茄的多次收获参数），无 `class_name`，通过 `preload()` 常量在
    `PlantGrowthManager` 里引用（踩过一次 `class_name` 全局缓存还没建好导致
    headless 解析失败的坑，见下方"已知问题"，所以这两个新文件都不依赖
    `class_name` 跨文件引用）。
  - 植物只在 `TimeManager.advance_time()` 推进后按累计分钟数结算，每满 1440
    分钟做一次"日结算"，不是实时生长——`advance_plant_time(minutes)` 由
    `TimeManager` 调用，`PlantGrowthManager` 自己不推进时间。
  - 月昼/月夜光照：月昼固定满级自然光（等级 4）且不耗电；月夜光照等级取自
    `greenhouse_light_system_level`（0–4，独立于 `BaseStatusManager` 的四档
    枚举，是本次新增的第五种"温室补光"抽象），再按 `BaseStatusManager.power`
    的四个电力区间做衰减（70–100 不衰减，40–69 -1，20–39 -2，0–19 强制
    ≤1）。
  - 水循环等级 `water_cycle_level`（0–4）是本次新增的独立抽象，不接现有的
    `PartialWaterCycleRestored` 等旧温室叙事标志（没有可复用的数值系统，见
    已知问题）。
  - 温度直接读 `BaseStatusManager.temperature`，无温室独立温度。
  - 每日结算：水/光/温度各达标 +1 分，按 3/2/1/0 分对应
    `growth_progress_days` 增量与 `stress` 增减（规则来自需求文档第七节）；
    `stress` clamp 到 ≥0；`health_state` 由 `stress` 映射
    Healthy/Stressed/Withering/Dead；Dead 后停止生长。
  - **光照高于需求不会扣分/不会生病**——只判断"够不够"，不判断"是否过强"，
    严格按需求文档第四节/第十六节执行，没有做任何"光照过强"惩罚。
  - 成熟规则：`growth_progress_days >= growth_days` 进入 Mature；收获时
    `HealthManager.adjust_stat` 分别加饱腹/营养/心理；番茄
    `repeat_harvest=true`，收获后若 `extra_harvests_used < 3` 则重置进度、
    进入新的 3 天再收获周期，否则终结为 Harvested。
  - 专业提示 `get_specialist_hint()`：只有 `EducationBackground == "植物科学"`
    才返回文字，不提供任何数值加成；光照满足或超过需求时明确提示"不会造成
    额外风险"，不产生"光照过强"话术。
  - 存档：`user://saves/plant_growth_state.json` 独立文件，同时接入旧基地/
    温室/第一周存档（`sprint06_progress.json`）与训练进度存档
    （`training_progress.json`）的 `PlantGrowthState` 字段，写法对齐已有的
    `BaseStatusState`。
  - Debug 支持：主菜单开发菜单新增播种生菜/土豆/小麦/番茄/大豆、循环切换
    水循环等级/温室补光等级（0→1→2→3→4→0）、强制成熟当前作物、收获当前
    作物、清空温室作物；"推进植物生长 1/3 天"复用 `_debug_advance_time`
    （直接推进 TimeManager 真实时间，会连带结算 BaseStatusManager 和
    HealthManager，语义上更一致）；"切换月昼/月夜"复用已有 Time Debug
    跳转按钮；"设置基地温度"复用已有 Base Debug 温度按钮，均未重复新增。
  - UI：新增 `scripts/ui/plant_growth_panel.gd`（`PanelContainer`，纯代码
    构建，风格与 `base_status_panel.gd` 一致），在 `sprint06_base_scene.gd`
    里用新按键 G（`toggle_plant_status` action）开关，只在温室场景
    （`scene_kind == "greenhouse"`）生效，默认隐藏、显示"最近播种/当前
    焦点"的那株作物（`last_sown_slot_id`），不做多地块选择 UI。
  - 与"最后一株植物"系统的联动：本次**没有**改动
    `sprint06_base_scene.gd` 里原有的 `LastPlantStable` 相关叙事逻辑，
    `PlantGrowthManager` 是完全独立的新系统（多地块 `Dictionary`，key 为
    slot_id），两者暂不交叉引用——按需求文档"如已有 LastPlantSystem，请不要
    重写"的要求，只做了并行新增，没有做形式联动（见已知问题）。

## 对共用核心文件的改动记录（第一档文件，已按规则先查 git log 再改）

- `scripts/managers/TimeManager.gd`：
  - `advance_time()` 里在 `_apply_base_status_time()` 之后、
    `_apply_health_action_cost()` 之前新增 `_apply_plant_growth_time()`
    调用。
  - `reset_to_arrival()` 追加对 `PlantGrowthManager.reset_to_arrival()` 的
    级联调用，写法与已有的 Health/BaseStatus 级联一致。
- `scripts/base/sprint06_base_scene.gd`（10 个场景共用）：
  - `_save_state()`/`_load_state()` 追加 `PlantGrowthState`
    序列化/反序列化，对齐已有的 `BaseStatusState` 处理方式。
  - 新增 G 键（`toggle_plant_status`）开关新的 `PlantGrowthPanel`，面板
    位置 `Vector2(1170, 500)`（避开另一会话刚修过的
    `BaseStatusPanel` 在 `Vector2(1170, 180)` 的区域，二者都在
    1600x900 视口内不重叠），只在 `_setup_ui()`/`_unhandled_input()`/
    `_update_ui()` 各加了几行，没有动现有的 greenhouse 交互逻辑
    （`_interact_greenhouse()` 等一律未改）。
- `scripts/training/training_manager.gd`：
  - `default_data()`/`load_progress()`/`save_progress()`/`reset_progress()`
    追加 `PlantGrowthState` 字段，写法对齐已有的 `BaseStatusState` 处理。
- `scripts/props/reference_prop.gd`：本次未触碰。

## 验证

- Godot 4.7 headless 逐个加载并确认无 `SCRIPT ERROR`/`Parse Error`：
  `main.tscn`、`OldBaseInteriorScene.tscn`、`OldGreenhouseScene.tscn`、
  `Day02StartScene.tscn`、`WeekRoutineStartScene.tscn`、
  `SolarArrayExteriorScene.tscn`、`Training_03_PowerRepair.tscn`、
  `FinalAssessmentScene.tscn`。
- 临时脚本（未提交，验证后已删除）跑通了：生菜在理想条件下推进 3 天后
  正常生长（受当天温度波动影响，进度/分数符合水/光/温度三项打分公式）；
  番茄强制成熟→收获→自动进入再收获周期→用满 3 次额外收获后终结为
  Harvested、心理/饱腹/营养奖励只在真正处于 Mature 时才发放；小麦在夜间
  弱光+低电力+持续多日后 `stress` 累积到 6，`health_state`/`stage`
  正确变为 Dead 且不再继续生长；存档序列化/反序列化往返后水循环等级、
  地块字典都正确恢复。
- 验证过程中发现并修复一个 debug 工具的边界问题：`debug_force_mature_current()`
  原本会把已经处于终态 `Harvested` 的地块强制拉回 `Mature`，配合
  "收获当前作物" 按钮反复点击可以无限刷饱腹/营养/心理奖励（正常玩法走不到
  这条路径，只有连点 debug 按钮才会触发）；已加 `stage == "Harvested"` 时
  直接跳过的判断，回归测试确认奖励不再重复发放。

## 已知问题 / 暂不覆盖范围

- `water_cycle_level`（水循环等级）和 `greenhouse_light_system_level`
  （温室补光等级）都是本次新增的独立数值抽象，默认值 1，只能通过 debug
  菜单调整——没有接入旧温室场景里原有的 `PartialWaterCycleRestored` 等
  叙事型布尔标志，因为那些标志本身不是数值系统，没有可直接复用的结构。
- 没有做真正的"温室多地块"交互 UI（走进某块地、点击播种/收获）——本次的
  播种/收获只能通过 Debug 菜单触发；`PlantGrowthPanel` 显示的是
  `last_sown_slot_id`（最近一次播种的地块），不是"玩家当前站在哪块地前"。
  场景里加地块拾取交互属于更深的场景/UI 工作，留给下一轮或场景/UI 会话。
  另外，温度目前只能靠 `BaseStatusManager` 侧的维修/时间结算间接影响，
  水循环等级和补光等级还完全没有面向玩家的操作 UI（只有 Debug 按钮）——
  如果要让玩家自己调节水循环/补光，需要场景/UI 那边再搭一层交互控件。
- 与"最后一株植物"系统（`LastPlantStable` 等）暂无交叉引用——两个系统
  并行存在，没有互相影响对方的判定，符合"预留接口但不强行耦合"的要求。
- 新文件（`PlantCropData.gd`、`PlantGrowthManager.gd`）都避免了跨文件用
  裸类名（`class_name`）互相引用——之前做 Base Status System 时踩过一次坑：
  新脚本的 `class_name` 要等 Godot 编辑器扫描一次项目后才会进全局缓存，纯
  headless 运行会报 `Could not find type X in current scope`；这次新数据类
  干脆不写 `class_name`，全部走 `preload()` 常量。
- Godot 在本地会刷新大量已跟踪 `.import` 文件和生成 `.uid`/`.godot_appdata/`，
  它们不属于本次改动，提交时未暂存。

## 先别碰

（暂无）
