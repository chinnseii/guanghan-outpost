# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Claude Code（代 Codex，宇航服系统 + 一处 UI 面板 Bug 修复）

## 正在进行

（暂无——本轮"宇航服系统 SuitManager v1"已实现完成。开始前确认过
`git status`/`CURRENT.md` 均无 Codex 新的并发改动，工作过程中也没有再
出现新的并发改动。）

## 本轮完成（Claude Code，代 Codex）：宇航服系统 SuitManager v1

- **新增 `scripts/managers/SuitManager.gd`**，注册为 autoload
  `/root/SuitManager`。核心字段全部按需求文档：`is_suit_worn`/
  `suit_storage_state`（`ready`/`worn`/`carried`/`servicing`，`carried`
  是预留态，本版没有转移函数到达它）/`suit_level`（1–5）/`suit_oxygen`
  +`suit_oxygen_capacity`/`suit_power`+`suit_power_capacity`/
  `suit_speed_multiplier`（0.8 起步）/`wear_time_minutes`/
  `remove_to_station_time_minutes`（都是 15）。
  - `wear_suit()`/`remove_suit_to_service_station()`：**唯一推进正式
    `TimeManager` 的两处**，各 15 分钟；脱下只切状态到 `servicing`，
    **不会自动恢复**氧气/电力，必须再走维护流程。
  - `consume_suit_resources(minutes, activity_type)`：`indoor_worn`
    3/2、`eva_normal`（默认）8/6、`eva_heavy` 12/10（氧气/电力，每小时），
    未穿戴时直接空转，不推进任何时间。
  - `get_actual_minutes(base_minutes)`：`ceil(base/speed_multiplier)`，
    需求文档的算例（60 分钟 × 0.8 倍率 = 75 分钟）已用临时脚本验证。
  - `upgrade_suit_speed()`/`update_suit_speed_multiplier()`：
    0.80/0.85/0.90/0.95/1.00 五级，`min(..., 1.0)` 硬 clamp，5 级后
    升级直接返回 false。
  - `can_start_eva()`：`is_suit_worn && oxygen>=20 && power>=20`；
    `SuitManager` 本身**不**判定紧急返航/杀死玩家，只报数值和状态。
  - `refill_suit_oxygen()`/`recharge_suit_power()`/`can_service_suit_full()`/
    `service_suit_full()`：氧气每点 0.01 W + 0.02 E，电力每点 0.03 E；
    `service_suit_full()` 先整体过一遍 `can_service_suit_full()` 再动手，
    避免"水扣了电没扣够"的半失败状态。完全耗空补满 = 1.0 W + 5.0 E，
    跟需求文档第十五节算例逐项匹配（已验证）。
- **`WaterSystemManager.gd` 新增 `consume_water_checked(amount, reason="")
  -> bool`，`PowerSystemManager.gd` 新增
  `consume_energy_checked(amount, reason="") -> bool`**：需求文档要的
  "资源不足返回 false"契约，两个 Manager 已有的
  `consume_energy()`/`consume_plant_water()`/`apply_action_cost()` 都是
  "无条件扣款+clamp 到 0"语义，其他调用方依赖这个行为，所以选择新增而不是
  修改，避免动到 `WaterSystemManager.process_ice()` 等既有调用点。
- **`project.godot`**：`[autoload]` 追加 `SuitManager`。
- **`main.gd`**：新增 Suit Debug 分组（穿戴、脱下挂入维护位、模拟舱外
  行动/高强度舱外行动、清空氧气电力、完整维护、升级速度、查看状态、
  重置）。
- **存档接入**：`scripts/ui/suit_panel.gd`（`U` 键，位置见下）、
  `sprint06_base_scene.gd`/`training_manager.gd` 都追加了 `SuitState`
  字段 + `_suit_manager()` helper，写法对齐已有的 `InventoryState` 处理。
- 设计参考文档已同步更新：文末新增"宇航服系统 SuitManager"一节。

## 顺手修复的 Bug（发现于本轮，属于更早一次多方合并提交遗留的问题）

`sprint06_base_scene.gd` 的 `_setup_inventory_panel()`/
`_toggle_inventory_panel()` 一直在实例化 `BackpackStoragePanelScript`
而不是 `InventoryPanelScript`——`const InventoryPanelScript` 那行预加载
常量整个从文件里消失了。根因是"物品系统"那次合并提交（`37d2c3b`）双方
并发编辑了同一个函数/变量名，只留下了其中一份，从那次提交起 **`B` 键
实际打开的是背包/仓库面板，物品库存面板完全没有入口**，两个面板一直在
共用同一个键位和变量。本次顺手修复：
- 恢复 `InventoryPanelScript` 预加载常量，`B` 键改回真正打开物品库存
  面板（位置不变，`Vector2(400, 500)`）。
- 给背包/仓库面板（520×430，放不进 330 宽的网格格子）单独开了新变量
  `backpack_storage_panel`、新函数
  `_setup_backpack_storage_panel()`/`_toggle_backpack_storage_panel()`、
  新键位 `K`、大致居中的新位置 `Vector2(540, 235)`。
- 纯 UI 层修复，没有改动 `BackpackManager`/`StorageManager`/
  `InventoryManager` 任何业务逻辑。

## UI 面板 / 按键一览（本轮更新后）

3×2 网格（1600×900 视口，x=400–1590，y=180–800，已完全占满）：
Water(I,400/180)/Air(O,740/180)/Base(Tab,1170/180) 一行，
Inventory(B,400/500)/Power(P,740/500)/Plant(G,1170/500) 一行。
网格外：Backpack/Storage（K，大致居中 540/235，520×430 大面板）、
Suit（U，网格正下方的横条 400/810，1170×78）。

## 验证

- Godot 4.7 headless：`main.tscn` +
  `OldBaseInteriorScene`/`OldGreenhouseScene`/`Day02StartScene`/
  `WeekRoutineStartScene`/`SolarArrayExteriorScene`/`Training_03_PowerRepair`/
  `FinalAssessmentScene` 共 8 个场景 headless 加载，均无 `SCRIPT ERROR`/
  `Parse Error`（含面板布线改动后的复核）。
- 临时脚本（未提交，验证后已删除）跑通了 13 项：抵达初始值精确匹配；
  `wear_suit()` 精确推进真实 `TimeManager` 15 分钟且拒绝重复穿戴；
  `consume_suit_resources()` 三档强度（indoor_worn/eva_normal/eva_heavy）
  的每小时耗率精确匹配，未穿戴时完全空转；`can_start_eva()` 正确要求
  穿戴+氧气≥20+电力≥20；升级路线 0.80→0.85→0.90→0.95→1.00 精确匹配且
  5 级后拒绝继续升级；`get_actual_minutes(60)` 在 0.8 倍率下精确等于 75
  （需求文档给的算例）；`refill_suit_oxygen()`/`recharge_suit_power()`
  从完全耗空分别精确消耗 1.0 W/2.0 E 和 3.0 E；`service_suit_full()` 完全
  耗空补满精确消耗 1.0 W + 5.0 E 总计；资源不足时 `service_suit_full()`
  正确拒绝且不发生半失败式的部分扣款；序列化/反序列化往返一致。

## 已知问题 / 暂不覆盖范围

- **没有真正的"外出系统"接入**：`consume_suit_resources()`/
  `can_start_eva()`/`get_actual_minutes()` 都是完整可用的接口，但目前
  只有 Debug 菜单的"模拟舱外行动"按钮在调用它们，没有玩家可操作的场景
  内出舱流程。
- **`suit_storage_state = "carried"`（脱下但未挂入维护位）没有对应的
  转移函数**——本版 `remove_suit_to_service_station()` 是"脱下+挂入"
  合并成的单一原子动作，没有做更细的两段式流程。
- 宇航服部件损坏细分、耐久系统、多套宇航服、随机故障、战斗模块——按
  需求文档明确列出的"本次不做"清单，第一版完全没有涉及。
- 详细数值/接口清单见
  `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`（文末"宇航服系统
  SuitManager"一节）。

## 先别碰

- `scripts/managers/BackpackManager.gd` / `StorageManager.gd` /
  `SupplyManager.gd` / `RepairManager.gd` / `scripts/data/FaultDatabase.gd`
  仍是 Codex 自己推进的系统，本轮只修了 `sprint06_base_scene.gd` 里
  backpack/storage 面板的键位与实例化对象归属（见上）这一处 UI 层 Bug，
  没有改动这几个 Manager 自己的业务逻辑。
- `scripts/data/ItemDatabase.gd` / `scripts/managers/InventoryManager.gd`
  本轮也没有碰，继续由 Claude Code 维护（改前先
  `git log --oneline -- <file>`）。
