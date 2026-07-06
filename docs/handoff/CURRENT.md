# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Claude Code（本轮临时顶替 Codex 的游戏逻辑/Manager/数据/流程职责——Codex
临时无 token，由 Claude Code 在独立会话中代打这部分；同一时间另一个 Claude Code
会话仍在并行做场景/UI/美术。Codex 恢复后请按下方记录核对，不要误以为是
Codex 自己之前做的）

## 正在进行

（暂无，"水资源系统"设计已实现完成，本轮改动已提交）

## 最近完成

- **Claude Code（代 Codex）**：完成水资源系统实现。
  - **新增 `scripts/managers/WaterSystemManager.gd`**，注册为
    `/root/WaterSystemManager`（放在 `PowerSystemManager` 之后、
    `AirSystemManager` 之前，settlement 顺序：Power → Water → Base → Air →
    Plant → Health(+Power/+Water 一次性行动耗电耗水)）。管理：
    - `current_water`（抵达 42 W）/ `water_capacity`（=水箱模块数×40，抵达
      80 W）/ `water_tank_module_count`（抵达 2）/ `current_ice`（抵达 0 I）/
      `ice_capacity`（=冰仓模块数×60，抵达 120 I）/
      `ice_storage_module_count`（抵达 2）/ `water_recycling_level`（抵达 1，
      0–4）/ `water_recycling_efficiency`（抵达 1.0）/
      `ice_processing_efficiency`（抵达 1.0，只降低冰处理耗电，不提高水产出
      比例——1 I 恒等于 1 W，按需求文档明确要求不做"凭空造水"）。
    - 冰处理 `process_ice(amount)`：on-demand 动作（不是每小时自动结算的
      一部分），限于当前冰量/水箱剩余空间/当前电力可负担量三者取最小值，
      电力扣除走 `PowerSystemManager.consume_energy()`（新增的通用扣电接口）。
    - 水循环回收率 = `min(基础回收率[0/15/30/45/60%] × 效率倍率, 80%)`，硬
      上限 80%。可回收耗水（生活用水+植物供水）按 `需求×(1-回收率)` 实际
      扣款；不可回收耗水（制氧）全额扣款。数学上证明"每笔单独打折"和需求
      文档"日终批量结算"等价，所以没做批处理。
    - 每小时结算：基础生活用水（0.025W/h，可回收，连续缺水≥24h 每小时追加
      `morale -2/24`）+ 制氧耗水（读 `AirSystemManager.get_water_load()`，
      不可回收，算出"供水满足率"）。
    - 一次性行动耗水：进食 0.10W / 营养液 0.20W（可回收，尽力而为不硬阻断，
      跟 PowerSystemManager 的一次性行动耗电走同一套简化）。
    - 植物供水**不在**上面的每小时结算里，而是挂在 PlantGrowthManager 自己
      的每日循环上（详见 PlantGrowthManager 改动）。
    - 存档 `user://saves/water_system_state.json`，同时接入旧基地/温室/第一周
      存档与训练进度存档的 `WaterSystemState` 字段。
  - **AirSystemManager 的 O₂ 产出新增"供水满足率"节流**：
    `WaterSystemManager.get_oxygen_water_satisfaction()`（0–1，水完全不够时
    为 0，只剩人类呼吸的固定消耗，不影响消耗侧只影响产出侧）。新增
    `get_water_load()`（制氧模块耗水，跟已有的 `get_air_power_load()` 共用
    `SUPPLY_TARGETS` 常量字典，新增了 `water_load` 键，避免重复维护同一张表）。
  - **PowerSystemManager** 新增 `consume_energy(amount)`（通用扣电接口，供
    冰处理这类"变动量算不出固定值"的场景调用）和
    `_water_power_load()`（水循环运行耗电，读
    `WaterSystemManager.get_water_power_load()`，纳入总负载）。
  - **PlantGrowthManager 的水条件判断完全重构**：`_water_ok(crop)` 现在是
    纯 peek（调用 `WaterSystemManager.can_supply_plant_water()`，UI/专业提示
    随便调用不会消耗水）；真正的每日一次真实扣款走新增的
    `_consume_daily_plant_water(crop)`（调用
    `WaterSystemManager.consume_plant_water()`），只在
    `_process_daily_growth_for_slot()` 里调用一次。旧字段
    `water_cycle_level` **现在纯装饰**，只在 WaterSystemManager 缺失时当
    兜底判断用。新增 `get_daily_water_demand()`（当前所有作物每日需水总和，
    供水面板展示）和 `get_highest_planted_water_requirement()`（供水系统的
    植物科学专业提示判断"番茄还在不在场"）。
  - **UI**：新增 `scripts/ui/water_system_panel.gd`，在 `sprint06_base_scene.gd`
    里用新按键 `I` 开关。屏幕右侧已经被 Base(Tab,1170/180)、Plant(G,1170/500,
    仅温室)、Air(O,740/180)、Power(P,740/500) 占满 2×2 网格，水面板做窄了
    （330 宽而非 420）塞进 HUD 安全区和空气面板之间的空隙
    （`Vector2(400, 180)`）。
  - **Debug 支持**：主菜单开发菜单新增 Water Debug 分组（水/冰加减、加水箱
    模块/加冰仓模块、水循环等级循环、"处理 20 冰"（对应需求文档自己的算例）/
    "处理全部冰"、重置 Day 01、设为最低稳定状态）。
  - 设计参考文档 `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md` 已同步更新
    （按用户要求，新增/改动数值系统时必须同步这份文档）：新增第六节"水资源
    系统 WaterSystemManager"，空气系统章节补充供水满足率节流机制和
    `get_water_load()`，电力系统章节补充 `consume_energy()` 和
    `_water_power_load()`，植物生长系统章节的"水"条件描述完全重写，
    "尚未覆盖"清单新增了几条水系统特有的简化点。

## 对共用核心文件的改动记录（第一档文件，已按规则先查 git log 再改）

- `scripts/managers/AirSystemManager.gd`：`SUPPLY_TARGETS` 常量字典追加
  `water_load` 键；新增 `get_water_load()`、`_water_satisfaction_multiplier()`、
  `_water_system_manager()`；`_apply_o2_change()` 里给 `generator_rate` 追加
  乘 `_water_satisfaction_multiplier()`（默认 1.0，WaterSystemManager 缺失
  时不影响旧行为）。O₂/CO₂ 的其余结算逻辑完全未改动。
- `scripts/managers/PowerSystemManager.gd`：新增
  `consume_energy(amount)`、`_water_power_load()`、`_water_system_manager()`；
  `_total_power_load()` 追加 `_water_power_load()` 项。其余逻辑完全未改动。
- `scripts/systems/PlantGrowthManager.gd`：`_water_ok(crop)` 内部实现改为
  查询 WaterSystemManager（原有签名/调用方不变）；新增
  `_consume_daily_plant_water(crop)`、`_plant_daily_water_amount(crop)`、
  `get_daily_water_demand()`、`get_highest_planted_water_requirement()`、
  `_water_system_manager()`；`_process_daily_growth_for_slot()` 里的评分逻辑
  从"读 `_water_ok()`"改成"调用 `_consume_daily_plant_water()`"（这是本次
  唯一改动了实际调用点的地方，其余全是新增方法）。生长/收获/专业提示的
  其余逻辑完全未改动。
- `scripts/managers/TimeManager.gd`：`advance_time()` 在
  `_apply_power_system_time()` 之后、`_apply_base_status_time()` 之前新增
  `_apply_water_system_time()`；在 `_apply_power_action_cost()` 之后新增
  `_apply_water_action_cost()`。`reset_to_arrival()` 里
  `WaterSystemManager.reset_to_arrival()` 排在 `AirSystemManager` 之前、
  `PowerSystemManager` 之后（顺序本身不影响正确性，因为 Water 的 reset
  不反向同步任何其他 Manager 的字段，纯粹跟随既有习惯摆放）。
- `scripts/base/sprint06_base_scene.gd`（10 个场景共用）：
  - `_save_state()`/`_load_state()` 追加 `WaterSystemState`
    序列化/反序列化，对齐已有的 `PowerSystemState` 处理方式。
  - 新增 I 键（`toggle_water_status`）开关新的 `WaterSystemPanel`，只在
    `_setup_ui()`/`_unhandled_input()`/`_update_ui()` 各加了几行，没有动
    现有的交互逻辑。
- `scripts/training/training_manager.gd`：`default_data()`/`load_progress()`/
  `save_progress()`/`reset_progress()` 追加 `WaterSystemState` 字段，写法
  对齐已有的 `PowerSystemState` 处理。
- `scripts/props/reference_prop.gd`：本次未触碰。

## 验证

- Godot 4.7 headless 逐个加载并确认无 `SCRIPT ERROR`/`Parse Error`：
  `main.tscn`、`OldBaseInteriorScene.tscn`、`OldGreenhouseScene.tscn`、
  `Day02StartScene.tscn`、`WeekRoutineStartScene.tscn`、
  `SolarArrayExteriorScene.tscn`、`Training_03_PowerRepair.tscn`、
  `FinalAssessmentScene.tscn`。
- 又踩到一次同款 `min()`/三元表达式类型推断 Parse Error（这次在
  `WaterSystemManager.gd` 里有 6 处），已通过显式 `: float` 类型标注全部
  修复并重新验证通过——以后新写涉及 `min()`/`max()`/三元表达式赋值给 `var`
  的地方，记得直接标类型，省得每次都要在 headless 加载失败后才发现。
- 临时脚本（未提交，验证后已删除）跑通了：抵达初始值精确匹配（42/80W、
  0/120I、回收率15%）；回收率硬上限 80% 生效（4 级×效率 2.0 本应 120% 被
  压到 80%）；24 小时纯生活用水结算精确匹配 `-0.6×0.85=-0.51`；标准供氧
  1 小时耗水精确匹配 `0.02125+0.008=0.02925`；水量耗尽时制氧供水满足率
  正确降到 0，O₂ 产出侧完全归零（只剩人类呼吸消耗）；冰处理受水箱空间/
  电力双重限制的结果精确匹配手算；加水箱/冰仓模块不凭空增加当前存量；
  植物面板文本多次调用不消耗水（纯 peek），每日结算的真实扣款金额精确匹配
  `生活用水×0.85 + 番茄需水×0.85 + 制氧耗水`（三项相加验证过）。全程只有
  上面提到的类型推断问题，逻辑本身未发现缺陷。
- 未跑图形界面截图（本次未涉及新视觉资产，新增的水资源面板默认隐藏、按 I
  打开；截图验收留给人类玩测或下一轮）。

## 已知问题 / 暂不覆盖范围

- **"喝营养液不可用"这条硬门槛没做**：水不够时 `WaterSystemManager` 只是
  尽力打折扣款到 0，不会阻止玩家继续执行 `eat`/`nutrition_drink` 动作，
  跟 PowerSystemManager 的一次性行动耗电走同一套"尽力而为、不做硬门槛"简化。
- **水不足时"生活用水 vs 制氧"没有按比例分配，完全按结算顺序决定**：
  `advance_water_time()` 里生活用水先结算，水快耗尽时制氧只能分到剩下的
  部分（可能是 0）。这是实现顺序的自然结果，不是需求文档明确要求的优先级；
  如果要做更公平的分配需要重构这部分。
- **材料科学"水箱老化/冰仓隔热"专业提示只是文案**，没有真实的模块老化/
  损耗机制（需求文档自己也说第一版可以只做文案）。
- **`WaterSystemManager.add_ice()`/`add_water()` 目前只有 Debug 菜单在调**，
  没有真正的"外出采集"系统在生产月球冰——这两个方法是留给未来采集系统的
  空接口，调用方尚不存在。
- `BaseStatusManager.power_system_status`（供电系统档位）在电力系统重构后
  已经是纯装饰字段，本次未处理；`BaseStatusManager.get_power_label()` 仍是
  旧的 4 档文案，没有跟着 `PowerSystemManager.get_power_label()` 的新 5 档
  同步更新——两处历史遗留问题延续到本轮，未做进一步清理。
- Godot 在本地会刷新大量已跟踪 `.import` 文件和生成 `.uid`/`.godot_appdata/`，
  它们不属于本次改动，提交时未暂存。

## 先别碰

（暂无）
