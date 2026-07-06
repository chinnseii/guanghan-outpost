# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Codex + Claude Code（代 Codex，物品系统）——两边在同一份未提交工作区
里并行工作，本次是把双方改动合并成一次快照提交。已确认两边改动在文件层面
互相独立（不同函数/不同区块），已跑过 headless 验证确认整体能正常启动，
详情见下方"验证"和"对共用核心文件的改动记录"。

## 正在进行

- 开局方向正在调整为"玩家先依赖登陆飞船求生仓，7 天内接管旧基地"（Codex）。
  本轮只做了抵达电影场景的轻量表达改动，完整求生仓倒计时/返航节点/补给链
  门槛暂未实现。
- 物品系统（ItemDatabase / InventoryManager）本轮由 Claude Code 完整实现
  完成，不再是"进行中"。之前"先别碰 ItemDatabase.gd / InventoryManager.gd"
  的提示本轮已解除，两个文件已完工并通过验证。

## Codex 本轮完成：维修/故障系统 v1 基础

- **新增 `scripts/data/FaultDatabase.gd`**：16 张故障卡，覆盖电力/空气/密封/
  温控/水/温室六个子系统。
- **新增 `scripts/managers/RepairManager.gd`**，注册为 autoload
  `/root/RepairManager`。运行时状态含 active/resolved、诊断次数、已排除的
  错误维修选项、尝试次数、严重故障恶化计数、最近一次结果/提示文案。
  - `diagnose_fault(fault_id)`：耗时 15 分钟（`TimeManager.advance_time(15,
    "fault_diagnosis")`），排除一个错误选项但不直接揭示正确答案。
  - `attempt_repair(fault_id, option_id)`：正确维修消耗时间/材料并解决故障；
    错误维修消耗时间、可能消耗材料，严重故障会记录"恶化"。
  - 维修材料只从 `StorageManager` 扣除。
  - 轻量跨系统效果（`BaseStatusManager.adjust_stat`/
    `AirSystemManager.adjust_stat`/`WaterSystemManager.debug_adjust_water`/
    `PowerSystemManager.debug_adjust_energy`）。
  - 存档 `user://saves/repair_state.json`，已加入 Demo 进度清除列表。
  - `main.gd` 新增 Repair Debug 分组（显示状态/播种材料/加样例故障/诊断
    第一个/正确尝试第一个/错误尝试第一个/重置）。
  - 目前**只有系统骨架 + Debug 入口，没有正式的玩家可见维修面板 UI**；
    未解决故障的持续影响目前只是数据存在，没有接"随时间持续恶化"的结算；
    错误/正确效果刻意做得很轻，没有做完整的电力/空气/水失效模拟；严重
    维修失败只记录 `worsening`，还没有接到任何失败态判定。
  - Codex 自己的验证记录：本轮 headless 校验没能跑完（第一次运行在打开
    `user://logs` 时超时/崩溃，重试又被环境用量限制拒绝），已经手动加强了
    GDScript 类型安全，但还需要在能跑 Godot 的时候补一次 parse/check。
    **Claude Code 已经代跑了这次验证**（见下方"验证"），确认
    `RepairManager`/`FaultDatabase` 能正常加载，`main.tscn` 反复 headless
    启动无 `SCRIPT ERROR`/`Parse Error`。
  - 本轮 Codex 明确没有碰的文件：`reference_prop.gd`、
    `training_module_scene.gd`、`training_manager.gd`、
    `opening_flow_manager.gd`、`sprint06_base_scene.gd`；也没有碰物品系统
    归属文件：`ItemDatabase.gd`/`InventoryManager.gd`/`BackpackManager.gd`/
    `StorageManager.gd`。

## Codex 上一轮完成：抵达电影场景表达调整

- 更新 `scripts/arrival/arrival_cinematic_scene.gd`：初始提示改为"停下，
  透过舷窗望向地球"；观察地球台词改为"透过求生仓舷窗，可以看见地球"；
  前景从月面运输船剪影改成求生仓舷窗/内舱框架/工程面板；玩家仍可停下观察
  地球，结束后仍显示 `E / Enter 前往基地气闸`；场景跳转目标未变，仍进入
  `BaseAirlockEntryScene`。

## Codex 工作区里仍在推进、本轮未展开的系统（供后续参考）

- 地球补给系统 v1：`scripts/managers/SupplyManager.gd`、`SupplyManager`
  autoload、`TimeManager.advance_time()` 里的补给事件检查、
  `supply_state.json`、F12 Supply Debug。
- 背包/仓库/负重系统 v1：`BackpackManager`、`StorageManager`、
  `ItemContainer`、`HealthManager` 负重上限字段（`base_carry_capacity`/
  `effective_carry_capacity`/`carry_health_score`/`carry_health_multiplier`）。

## Claude Code 本轮完成：物品系统 v1

- **新增 `scripts/data/ItemDatabase.gd`**（纯数据，`extends RefCounted`，无
  `class_name`，`preload()` 引用，对齐 `PlantCropData.gd` 写法避免 class_name
  缓存问题）：`const ITEMS` 共 33 条，覆盖食物(5)/种子(5)/消耗品(5)/材料(6)/
  工具(6，含2个默认工具+4个耐久工具)/系统资源编号(6)。详细字段/数值见
  `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md` 第八节。
- **新增 `scripts/managers/InventoryManager.gd`**，注册为 autoload
  `/root/InventoryManager`。`stack_items`（item_id→数量）+ `durable_items`
  （instance_id→{item_id, current_durability, max_durability, state}）两套
  结构；`add_item`/`remove_item`/`has_item`/`get_item_count`/`eat_item`/
  `use_item`/`add_durable_item`/`use_durable_item`/`repair_durable_item`/
  `get_durable_item_state`/`panel_status_text`/序列化/Debug helper 全部按
  需求文档接口清单实现。**不挂在 `TimeManager.advance_time()` 的每小时结算
  链上**，纯被动响应动作。
- **`PlantGrowthManager.harvest()` 改造为"只产物品，不再直接回血"**：调用
  `InventoryManager.add_item(harvest_item_id, 1)`，不再直接调
  `HealthManager.adjust_stat()`。`PlantCropData.gd` 五种作物新增
  `harvest_item_id` 字段（`FO-CR-001`~`FO-CR-005`），旧的
  `harvest_fullness/nutrition/morale` 三个字段保留但 `harvest()` 已不读，
  这三个数字的新家是 `ItemDatabase.gd` 对应食物条目的 `effects`。
- **`HealthManager.gd` 新增 `apply_item_effects(effects: Dictionary)`**：
  给 `InventoryManager` 调用，内部走已有的 `adjust_stat()` 逐项应用，不绕过
  clamp/存档/信号。
- **`WaterSystemManager._action_water_cost()` 新增 `"eat_item"` case**，
  金额沿用 `EAT_WATER_COST`，让 `eat_item()` 推进时间时也会正确耗水（旧
  `"eat"`/`"nutrition_drink"` case 完全没动，两条路径独立）。
- **避免双重回血的关键设计**：`eat_item()`/`use_item()` 推进 `TimeManager`
  用的 reason 是 `"eat_item"`/`"use_item"`，故意不匹配
  `HealthManager.apply_action_cost()`/`WaterSystemManager.apply_action_cost()`
  里原有的固定 `"eat"`/`"nutrition_drink"` case，避免"吃一次加两次血"。
- **UI**：新增 `scripts/ui/inventory_panel.gd`，`sprint06_base_scene.gd` 里
  用新按键 `B` 开关，位置 `(400, 500)`，紧跟在水面板 `(400,180)` 下方，凑成
  右侧 3×2 网格的最后一格。
- **Debug 支持**：`main.gd` 新增 Inventory Debug 分组（加食物/种子/消耗品/
  材料样本各一套、加一把便携钻具耐久工具、吃生菜、吃营养液包、使用最后一个
  耐久物品、重置到 Day 01）。
- **存档接入**：`sprint06_base_scene.gd`（`_load_state()`/`_save_state()`）
  和 `training_manager.gd`（`default_data()`/`load_progress()`/
  `save_progress()`/`reset_progress()`）都追加了 `InventoryState` 字段 +
  `_inventory_manager()` helper，写法对齐已有的 `WaterSystemState` 处理。
- 设计参考文档同步更新：新增第八节"物品系统"，原"尚未覆盖"章节顺延为
  第九节，修正了插入新章节产生的几处"见第 X 节"交叉引用漂移。

## 顺手修复的 Bug（Claude Code 发现并修复，跟物品系统本身无关，属于工作区
里其他未提交代码的既有问题）

给物品系统跑收尾 headless 验证时，发现只要触发过一次"继续任务"存档读取
路径，就会在 `BackpackManager.deserialize()`/`StorageManager.deserialize()`
里报 `Invalid call. Nonexistent function 'normalize_slots'`，根因是
`scripts/systems/ItemContainer.gd` 里两处经典"`min()`/三元表达式赋值给
`var x := ...` 导致类型推断失败"Parse Error（跟本项目之前在
AirSystemManager.gd/WaterSystemManager.gd 踩过的是同一类问题），编译失败
连带拖垮了预加载它的 `BackpackManager.gd`/`StorageManager.gd`。另外
`SupplyManager.gd._format_time()` 里也有两处同款 Parse Error，导致
`SupplyManager` autoload **完全无法实例化**。已加显式类型标注修复：
- `ItemContainer.gd` `add_existing_slot()` 里 `rejected` 改成
  `var rejected: Variant = ...`（后面会被赋值 `null`，不能是 Dictionary）。
- `ItemContainer.gd` `take_from_slot()` 里 `take_count` 改成显式 `: int`。
- `SupplyManager.gd` `_format_time()` 里 `total_from_start`/`minute`
  改成显式 `: int`。
纯语法层面的机械修复，**没有改动任何背包/仓库/补给系统的行为逻辑**。修复后
`BackpackManager`/`StorageManager`/`SupplyManager` 三个 autoload 都能正常
实例化。之后新加入工作区的 `RepairManager.gd`/`FaultDatabase.gd` 已单独
验证过，没有类似问题。

## 对共用核心文件的改动记录

- `scripts/arrival/arrival_cinematic_scene.gd`（Codex，未改动状态机）。
- `scripts/managers/TimeManager.gd`（Codex：接入 `SupplyManager` 补给事件
  检查；本轮 Claude Code 未再改动这个文件）。
- `scripts/managers/HealthManager.gd`（Codex 的负重字段 + Claude Code 的
  `apply_item_effects()`，两处改动在文件里不同位置，互不冲突）。
- `scripts/data/PlantCropData.gd`（只有 Claude Code：新增 `harvest_item_id`
  字段）。
- `scripts/managers/WaterSystemManager.gd`（只有 Claude Code：新增
  `"eat_item"` 耗水 case）。
- `scripts/systems/PlantGrowthManager.gd`（只有 Claude Code：`harvest()`
  改为只产物品）。
- `scripts/systems/ItemContainer.gd` / `scripts/managers/SupplyManager.gd`
  （Codex 的功能代码 + Claude Code 顺手修的 4 处类型推断 Parse Error，
  详见上方"顺手修复的 Bug"）。
- `scripts/base/sprint06_base_scene.gd`（Codex 的 Backpack/Storage 面板 +
  存档字段，Claude Code 的 Inventory 面板 + 存档字段，各自新增独立函数块，
  没有互相修改对方代码）。
- `scripts/main.gd`（Codex 的 Backpack/Storage/Supply/Repair Debug 分组，
  Claude Code 的 Inventory Debug 分组，各自独立按钮 + handler 函数）。
- `scripts/training/training_manager.gd`（Codex 的 `BackpackState`/
  `StorageState`，Claude Code 的 `InventoryState`，分别追加，写法都对齐
  已有的 `WaterSystemState` 处理）。
- `project.godot`：`[autoload]` 追加了 `InventoryManager`（Claude Code）/
  `BackpackManager`/`StorageManager`/`SupplyManager`/`RepairManager`
  （Codex）五个 autoload。
- `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`：Codex 加了 RepairManager
  v1 的参考条目，Claude Code 加了第八节"物品系统"整节 + 交叉引用修正。

## 验证

- ArrivalCinematicScene headless 加载通过（Codex）。
- Claude Code 本轮验证：`main.tscn` +
  `OldBaseInteriorScene`/`OldGreenhouseScene`/`Day02StartScene`/
  `WeekRoutineStartScene`/`SolarArrayExteriorScene`/`Training_03_PowerRepair`/
  `FinalAssessmentScene` 共 8 个共用场景 headless 加载，反复验证均无
  `SCRIPT ERROR`/`Parse Error`（含修复 ItemContainer.gd/SupplyManager.gd
  前后各跑一遍的对比，以及 RepairManager/FaultDatabase 加入后再跑一遍确认
  它们也没有类似问题）。临时脚本（未提交，验证后已删除）跑通了：库存加/减/
  堆叠、耐久物品拒绝走 `add_item()`、`eat_item()` 正确回血+正确耗水、收获
  只产物品不直接回血（专门断言过"收获前后 HealthManager 数值不变"）、耐久
  工具磨损到 0 后正确进入 broken 状态且拒绝继续使用、
  `InventoryManager` 序列化/反序列化往返一致。

## 已知问题 / 暂不覆盖范围

- 本轮没有实现完整飞船求生仓系统、7 天求生仓倒计时、"补给系统改成求生仓
  返航后才开启"、求生仓内部可交互生活空间（Codex，均为下一轮方向）。
- `ArrivalLandingScene` 仍是旧月面原型表达；正式流程主要使用
  `ArrivalCinematicScene`（Codex）。
- **RepairManager 目前只有系统骨架 + Debug 入口，没有正式玩家可见 UI**，
  故障持续恶化/完整失效模拟/严重维修失败的失败态判定都还没做（Codex）。
- **物品系统没有背包容量/负重、格子摆放、装备栏、物品腐坏/过期、品质/
  随机词条、复杂合成、工具维修、批量烹饪、玩家交易**——按需求文档明确列出
  的"本轮不做"清单，第一版只做了数据定义+库存数量+吃/用+耐久（Claude Code）。
- **旧的固定 `eat`/`nutrition_drink` 行动没有被物品系统取代**，两条吃东西
  的路径（`HealthManager.apply_action_cost("eat")` 固定值 vs
  `InventoryManager.eat_item(item_id)` 真实库存）并存，互不替代，详见
  `SYSTEMS_REFERENCE_FOR_DESIGN.md` 第九节（Claude Code）。
- 详细的物品系统数值/接口清单见
  `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md` 第八节。

## 先别碰

- （已解除）`scripts/data/ItemDatabase.gd` / `scripts/managers/InventoryManager.gd`
  本轮已经完工，不再需要避让，改前照旧先 `git log --oneline -- <file>`。
- `scripts/managers/BackpackManager.gd` / `StorageManager.gd` /
  `SupplyManager.gd` / `RepairManager.gd` / `scripts/data/FaultDatabase.gd`
  都是 Codex 自己正在推进的系统，Claude Code 本轮只顺手修了
  `ItemContainer.gd`/`SupplyManager.gd` 里纯语法层面的类型推断 Parse
  Error，没有改动任何行为逻辑，其余部分不要动，留给 Codex 继续。
