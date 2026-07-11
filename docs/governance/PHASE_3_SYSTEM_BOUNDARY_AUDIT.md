# Phase 3 System Boundary Audit · 系统边界只读审计

> Phase 3 P3-01 · 只读审计 · 2026-07-11 · 基线 `bdfdfe1`（tag `document-governance-complete-2026-07-11`）
> 本文件是 Phase 3 系统边界清洗的**现状基线**。所有判断附代码证据（`文件:行号`/字段/方法/调用），不臆测 owner。
> **本轮零代码修改**；发现的问题只记录，不修。系统状态权威仍是 `SYSTEM_REGISTRY.md`，本表补充"实际接入 + 数据 owner + 存档真相"层。

## 1. 审计范围与基线
- 范围：`project.godot` autoload、`scripts/managers/**`、`scripts/systems/**`、save/load 调用路径、跨系统调用。
- 基线：HEAD `bdfdfe1`，工作区干净。交叉核对 `SYSTEM_REGISTRY.md`（状态）、`LEGACY_REGISTRY.md`（遗留）、`SYSTEMS_REFERENCE_FOR_DESIGN.md`（设计）。

## 2. 执行摘要
- **20 个 autoload**（`project.godot` [autoload] 段），均 REGISTERED_AND_USED（引用数见 `SYSTEM_REGISTRY` §A）。
- **跨系统写入全部经公开方法**（`get_node_or_null("/root/XxxManager")` + `has_method` + `.call(...)`）——**0 处直接外部字段写、0 处共享可变引用**。这是 Phase 3 最重要的低风险信号。
- **核心风险（P1）**：有状态 Manager 的数据同时持久化到 **① 自己的 `*_state.json`** 与 **② 训练快照 `training_progress.json`** 与 **③ 任务快照 `sprint06_progress.json`**（后两者经 `.call("deserialize", ...)` 恢复）→ 同一状态 2–3 处真相源、load 时哪份生效取决于顺序。`training_manager.gd` 自身注释已记录一次 mid-session load 覆盖 live manager 的踩坑。
- **无 P0（无正在发生的存档损坏）**：游戏可正常存读；风险是"真相源不唯一"，非"数据已损坏"。

## 3. Manager 与 Autoload 清单（20 autoload）

| # | Autoload 名 | 脚本 | class_name | 自存文件 | 入训练快照 | 入 sprint06 快照 | 接入状态 | 治理状态(Registry) |
|---|---|---|---|---|---|---|---|---|
| 1 | AcademicBackgroundManager | managers/AcademicBackgroundManager.gd | GuanghanAcademicBackgroundManager | application_profile.json | — | — | REGISTERED_AND_USED | ACTIVE |
| 2 | TimeManager | managers/TimeManager.gd | GuanghanTimeManager | time_state.json | ✓(TimeState) | ✓ | REGISTERED_AND_USED | ACTIVE |
| 3 | HealthManager | managers/HealthManager.gd | GuanghanHealthManager | health_state.json | ✓ | ✓ | REGISTERED_AND_USED | ACTIVE |
| 4 | BaseStatusManager | managers/BaseStatusManager.gd | GuanghanBaseStatusManager | base_status_state.json | ✓ | ✓ | REGISTERED_AND_USED | ACTIVE |
| 5 | PowerSystemManager | managers/PowerSystemManager.gd | GuanghanPowerSystemManager | power_system_state.json | ✓ | ✓ | REGISTERED_AND_USED | ACTIVE |
| 6 | WaterSystemManager | managers/WaterSystemManager.gd | GuanghanWaterSystemManager | water_system_state.json | ✓ | ✓ | REGISTERED_AND_USED | ACTIVE |
| 7 | AirSystemManager | managers/AirSystemManager.gd | GuanghanAirSystemManager | air_system_state.json | ✓ | ✓ | REGISTERED_AND_USED | ACTIVE |
| 8 | PlantGrowthManager | systems/PlantGrowthManager.gd | GuanghanPlantGrowthManager | plant_growth_state.json | ✓ | ✓ | REGISTERED_AND_USED | ACTIVE |
| 9 | InventoryManager | managers/InventoryManager.gd | GuanghanInventoryManager | inventory_state.json | ✓ | ✓ | REGISTERED_AND_USED | ACTIVE ⚠ |
| 10 | BackpackManager | managers/BackpackManager.gd | GuanghanBackpackManager | backpack_state.json | ✓ | ✓ | REGISTERED_AND_USED | ACTIVE ⚠ |
| 11 | StorageManager | managers/StorageManager.gd | GuanghanStorageManager | storage_state.json | ✓ | ✓ | REGISTERED_AND_USED | ACTIVE ⚠ |
| 12 | SupplyManager | managers/SupplyManager.gd | GuanghanSupplyManager | supply_state.json | ✓ | ✓ | REGISTERED_AND_USED | ACTIVE |
| 13 | RepairManager | managers/RepairManager.gd | GuanghanRepairManager | repair_state.json | ✓? | ✓? | REGISTERED_AND_USED | ACTIVE |
| 14 | DoorStateManager | managers/DoorStateManager.gd | GuanghanDoorStateManager | door_state.json | — | ? | REGISTERED_AND_USED | ACTIVE(未全接) |
| 15 | TrainingTimeManager | managers/TrainingTimeManager.gd | GuanghanTrainingTimeManager | training_time_state.json | ✓ | — | REGISTERED_AND_USED | ACTIVE |
| 16 | SuitManager | managers/SuitManager.gd | GuanghanSuitManager | suit_state.json | ✓(SuitState) | ✓ | REGISTERED_AND_USED | ACTIVE |
| 17 | MovementTimeManager | managers/MovementTimeManager.gd | GuanghanMovementTimeManager | —（转发器，无自存） | — | — | REGISTERED_AND_USED | ACTIVE(路由) |
| 18 | PlayerStateManager | managers/PlayerStateManager.gd | GuanghanPlayerStateManager | —（无自存文件；仅 serialize 入快照） | ✓(PlayerStateManagerState) | ? | REGISTERED_AND_USED | ACTIVE |
| 19 | PenaltyManager | managers/PenaltyManager.gd | GuanghanPenaltyManager | —（**dispatcher，不持久化**） | — | — | REGISTERED_AND_USED | ACTIVE(新) |
| 20 | TaskManager | managers/TaskManager.gd | GuanghanTaskManager | 入 sprint06（SPRINT06_SAVE_PATH） | — | ✓ | REGISTERED_AND_USED | ACTIVE(未全接) |

- **非 autoload 但相关**：数据库 `data/*Database.gd`（ItemDatabase/FaultDatabase/TaskDatabase/PenaltyDatabase/Door*Database/PlantCropData）= RESOURCE_ONLY/静态数据；`data/foundation/*.tres` = RESOURCE_ONLY。`tools/capture_*` = TEST_ONLY。遗留基座（`scripts/*_manager.gd` 小写等）见 §10。
- ✓? / ? = 需 P3-02 逐字段核实（本轮未逐一打开每个 default_data）。

## 4. 系统职责边界

| 系统 | 边界分类 | 证据 / 说明 |
|---|---|---|
| PenaltyManager | **PASS_THROUGH_ONLY / dispatcher** | `apply_penalty()`（PenaltyManager.gd:26）扇出到 `_apply_time/_apply_health/_apply_energy_cost/_apply_remove_items/_apply_supply`（:35-39），全部经 `.call("advance_time"/"adjust_stat"/"consume_energy"/…)`（:96-121）。**不持有他系统核心数值、不直接写字段**。Phase 0 对它"直接改多个 Manager 内部字段"的担忧**未被证实**。 |
| Time / TrainingTime / Movement | **MINOR_OVERLAP（有意分层）** | Time=正式时钟、TrainingTime=训练时钟、Movement=移动→时间的路由（训练转 `advance_training_time`、正式转 `advance_time`）。非重复实现；训练结束的两时钟同步需 P3-02 核实。 |
| Inventory / Backpack / Storage | **UNKNOWN_BOUNDARY（待核）** | 三者各自 autoload + 各自 `*_state.json`。是否对"同一件物品在哪"存在双记账 = Phase 0 遗留 UNRESOLVED，本轮仍未证实/证伪 → P3-02 专项。 |
| Air / Water / Base / Power | **CLEAR_BOUNDARY（分层）** | Air/Water/Power 从 BaseStatus 拆出（`SYSTEMS_REFERENCE`），各管一域；每小时 morale 扣减经 PenaltyManager 路由（Air/Base/Water → `/root/PenaltyManager`）。 |
| Suit / Repair / Door | CLEAR_BOUNDARY | Suit=宇航服穿脱/EVA 门禁；Repair=维修 v1(+FaultDatabase)；Door=门编号/状态（Door → Suit 读穿服状态做门禁）。Door 未接入正式旧基地导航（`SYSTEM_REGISTRY`）。 |
| Task | CLEAR_BOUNDARY | 统一目标/进度视图；持久化进 sprint06；依赖 Supply。 |
| 存档编排（sprint06_base_scene / training_manager） | **MAJOR_OVERLAP（跨领域）** | 这两个不是 Manager，但同时承担"场景驱动 + 全 Manager 状态快照收集/恢复"（见 §7），是存档真相分散的来源。 |

## 5. 数据所有权矩阵（重点域）

| 数据域 | Canonical owner | Writers | Persistence owner（写哪个文件） | Restore owner | 置信 | 证据 |
|---|---|---|---|---|---|---|
| 游戏时间 | TimeManager | TimeManager(`advance_time`)、经 Penalty/Movement 路由 | **多处**：time_state.json(自) + training_progress + sprint06_progress | 各 bundle `.deserialize` + 自 `load_state` | MEDIUM | TimeManager.gd:81/154/271；sprint06:2450 |
| 训练时间 | TrainingTimeManager | 同上(训练上下文) | training_time_state.json + training_progress | 同 | MEDIUM | TrainingTimeManager |
| 玩家健康(精力/饱腹/营养/morale) | HealthManager | HealthManager(`adjust_stat`/`consume_energy`)、Penalty 路由 | health_state.json + 两快照 | 同 | MEDIUM | HealthManager；Penalty:105-121 |
| 氧/水/电/舱压/温度 | Air/Water/Power/BaseStatusManager | 各自 + Penalty(morale) | 各自 *_state.json + 两快照 | 同 | MEDIUM | 各 manager serialize |
| 背包 / 仓储 / 物品 | Backpack / Storage / Inventory（**边界待核**） | 各自 + Penalty(`_apply_remove_items`) | 各自 *_state.json + 两快照 | 同 | **LOW/UNRESOLVED** | Penalty:139-140 |
| 补给 | SupplyManager | Supply + Penalty(supply) | supply_state.json + 两快照 | 同 | MEDIUM | Supply |
| 宇航服 | SuitManager | Suit + 训练流程 | suit_state.json + 两快照 | 同 | MEDIUM | Suit |
| 维修 | RepairManager | Repair | repair_state.json + 快照? | 同 | MEDIUM | Repair |
| 惩罚记录 | **无持久化 owner** | PenaltyManager(仅分发) | **不入存档**（效果由被作用系统各自持久化） | — | HIGH | PenaltyManager 无 serialize |
| 任务/训练进度 | TaskManager / TrainingManager | 各自 | sprint06_progress / training_progress | 各自 | MEDIUM | TaskManager:136；training_manager |
| 门状态 | DoorStateManager | Door | door_state.json | Door load_state | MEDIUM | Door serialize |
| 玩家当前区域/上下文 | PlayerStateManager | PlayerState | 仅入快照(PlayerStateManagerState)、无独立文件 | bundle | MEDIUM | 无 *_state.json |
| 申请档案/教育背景 | AcademicBackgroundManager | 申请流程 | application_profile.json | AcademicBackground | HIGH | AcademicBackground:5 |
| 玩家位置(地表) | **无持久化**（地表场景不存位置） | lunar_surface_scene | — | — | HIGH | CLEANUP_PLAN 附录 A |

## 6. 跨系统写入
- **全部 API_MEDIATED_WRITE**（经 `get_node_or_null("/root/XxxManager")` + `has_method` + `.call(方法, 参数)`）。
- 广扫 `Manager.<field> =` 直接外部字段写：**0 命中**（含 `/root/...` 与 class-name 两种写法）。
- 分类统计：DIRECT_FOREIGN_WRITE **0**、SHARED_MUTABLE_REFERENCE **0**（未见 Manager 间传 mutable Dictionary/Resource 引用做写入）、AUTHORIZED/API_MEDIATED_WRITE = 全部。
- 主要写入枢纽：**PenaltyManager**（→ Time/TrainingTime/Health/Backpack/Storage/Supply/PlayerState 共 7，均方法调用）。

## 7. 存档真相源与调用链

**并存的存档管线（6 条）**：
1. **每 Manager 自存**：每个有状态 Manager `save_state()`→ 自己的 `user://saves/<x>_state.json`；部分在状态变化时自动写（如 TimeManager `advance_time`→`_save_state()`，TimeManager.gd:81/271）。
2. **训练快照**：`training_manager.gd`（`serialize`/`deserialize`；`training_progress.json`）——`default_data()` 打包 TimeState/HealthState/…/SuitState/PlayerStateManagerState。
3. **任务快照**：`sprint06_base_scene.gd` `_save_state`/`_load_state`（`sprint06_progress.json`）——`_load_state()` 逐一 `manager.call("deserialize", state.get("<X>State"))`（:2450-2480，约 12 个 Manager）+ TaskManager。
4. **申请档案**：`application_profile.json`（AcademicBackground/application flow）。
5. **沙盒**（LEGACY）：`main.gd` slot 存档（`save_N.json`）。
6. **抵达原型**（LEGACY）：`arrival_prototype_save.json`。

调用链（正式主线，实测）：
```
[save] 场景(sprint06_base_scene/training_manager) → 各 Manager.serialize() → 组装 <X>State 字典 → 写 <bundle>.json
       同时：各 Manager.save_state() → 各 <x>_state.json（独立、并存）
[load] 各 Manager.load_state() ← 各 <x>_state.json（autoload/进场时）
       场景 _load_state() → 各 Manager.deserialize(bundle 的 <X>State) ← <bundle>.json（覆盖 live）
```
- **问题**：同一状态在 `<x>_state.json` 与 `<bundle>.json` 两处，load 时**后执行者覆盖前者**。`training_manager.gd` 的 `_read_progress_data()` 注释记录：mid-session 误调 `load_progress()` 会用旧快照覆盖 live（宇航服穿戴被重置）。→ **真相源不唯一（P1）**。

## 8. 存档数据分类
- `PERSISTENT_CANONICAL`：各 Manager 的核心域（time/health/air/water/power/base/supply/suit/repair/inventory/backpack/storage/plant/door/task/训练进度/申请档案）。
- `PERSISTENT_DERIVED`（疑似，待核）：同一 Manager 状态被写进 2–3 个文件（自存 + 训练 + sprint06），非首份即冗余。
- `SESSION_ONLY`：PenaltyManager 分发上下文；MovementTime 路由。
- `SCENE_LOCAL`：地表玩家位置（不入存档）。
- `LEGACY_SAVE_FIELD`：`已通过初步评估`→当前状态的兼容转换（应用档案）、沙盒 slot、arrival_prototype。
- `UNKNOWN`：Inventory/Backpack/Storage 是否重复记账。

## 9. Autoload 初始化与依赖 / Manager 依赖图

**依赖边（`/root/XxxManager` 调用，均 direct method call）**：
```
AirSystemManager   → PenaltyManager
BaseStatusManager  → PenaltyManager
WaterSystemManager → PenaltyManager
DoorStateManager   → SuitManager
TaskManager        → SupplyManager
PenaltyManager     → TimeManager, TrainingTimeManager, HealthManager,
                     BackpackManager, StorageManager, SupplyManager, PlayerStateManager
Movement(从代码)   → TimeManager / TrainingTimeManager（路由）
Suit/Repair(从代码)→ TrainingTimeManager / TimeManager（推进时间）
```
- **环检测**：Air/Base/Water → Penalty → (Time/Health/Backpack/Storage/Supply/…)。Penalty 不回调 Air/Base/Water/Door/Task → **未发现依赖环（ACYCLIC）**（本轮基于 `/root/` helper 扫描；signal 边未穷尽，标注 MEDIUM）。
- **ORDER_DEPENDENCY**：跨系统调用一律运行时 `get_node_or_null` 惰性取，**不依赖 autoload 注册顺序**（低风险）。
- `PlayerStateManager.gd` 出现 `/root/PlayerStateManager` 自引用 → 需 P3-02 确认是否 helper 返回自身/冗余（HIDDEN_DEPENDENCY 低风险，P3）。

## 10. Legacy / Compatibility 状态（核对 LEGACY_REGISTRY）
- 遗留基座（小写 `time_manager.gd`/`game_state_manager.gd`/`camera_manager.gd`/`ui_manager.gd`/`event_manager.gd`/`audio_manager.gd`/`save_manager.gd`/`robot_task_manager.gd`/`asset_catalog.gd`/`audio_feedback.gd`/各 `*_visual.gd`）：**LEGACY_REFERENCED / LEGACY_RUNTIME_ACTIVE(仅经 Dev/arrival)**——仅 `main.gd`(沙盒) 与 `arrival/*` 引用，正式主线不依赖（LEGACY_REGISTRY §A2）。**不允许删除**；正式主线的 `_time_manager()` helper 返回 `/root/TimeManager` autoload，非小写遗留。
- COMPATIBILITY：`TrainingManager.MODULE_01/02/04/05/06` = 纯存档 remap 常量（对应场景已删），`COMPATIBILITY_REQUIRED`。
- SAFE_TO_QUARANTINE 候选：`BaseInterior_Test.tscn`/`base_interior_test.gd`、`ArrivalLandingScene`——仍 UNKNOWN（入口未确认，SCENE_REGISTRY），本轮不动。
- DELETE_CANDIDATE：**0**（无充分证据）。

## 11. 文档与实现不一致（IMPLEMENTATION_DOC_MISMATCH）
- **无重大不一致**：`SYSTEM_REGISTRY` 的 20 autoload、状态与本轮代码证据一致；`LEGACY_REGISTRY` 的遗留判定与引用扫描一致；PenaltyManager 的"仅分发"与 `SYSTEMS_REFERENCE` 一致。
- 轻微：`SYSTEM_REGISTRY` 未显式记"存档双写/多真相源"这一跨系统事实（属本审计新增层，非 Registry 错误）。→ 不改 Registry，本审计承载。

## 12. 风险分级
- **P0**：**0**（无正在发生的存档/核心状态损坏）。
- **P1（1）**：**存档真相源不唯一**——Manager 状态同时进 `*_state.json` + `training_progress` + `sprint06_progress`，load 顺序决定覆盖；`training_manager` 注释记录过一次 live 被旧快照覆盖。影响：跨场景/续档时状态可能取到非最新份。修复前置：先定"每状态唯一真相源"（P3-02），再消冗余写（P3-03）。需用户决策：以 bundle 为准还是以自存为准。
- **P2（2）**：① Inventory/Backpack/Storage 边界/双记账 UNRESOLVED（需逐字段核实）；② 训练/正式双时钟结束同步待核。
- **P3（2）**：① PlayerState 自引用 helper 冗余；② 遗留 save 管线（沙盒 slot、arrival_prototype）与主线并存但断开。

每项 P1/P2 均"未在正式流程造成已知崩溃"，属**结构性/续档风险**，非即时故障。

## 13. Phase 3 建议批次（按风险/依赖，非按 Manager 名）
| 批次 | 目标 | 涉及系统 | 允许文件（预估） | 前置 | 验收 |
|---|---|---|---|---|---|
| **P3-01** 系统边界只读审计 | 本文件（现状基线） | 全部 | 仅治理文档 | Phase 2 完成 | ✅ 本轮完成 |
| **P3-02** 存档真相源与数据 owner 定稿 | 为每状态定唯一真相源；核实 Inventory/Backpack/Storage 双记账、双时钟同步 | 存档相关 Manager + 两编排 | 文档为主（`SYSTEMS_REFERENCE_FOR_DESIGN`/`SYSTEM_REGISTRY` 加真相源列） | P3-01 | owner 表 0 UNRESOLVED |
| **P3-03** P1 冗余写/恢复顺序修复 | 消除同一状态多文件冗余、明确 load 覆盖顺序 | TimeManager 等 + sprint06/training 编排 | 代码（逐系统 PR） | P3-02（需用户定真相源） | 续档回归、无覆盖丢失 |
| **P3-04** Manager 职责重叠清洗 | 处理确认的重叠（如物品三件套若双记账） | 视 P3-02 结果 | 代码 | P3-03 | 边界清晰、回归通过 |
| **P3-05** Compatibility/Legacy 隔离 | 隔离沙盒/arrival 遗留 save 管线、确认可隔离项 | 遗留基座 | 代码/配置 | P3-04 | 主线不受影响 |
| **P3-06** 系统边界回归验证与收口 | 组合回归 + 文档收口 + tag | — | 治理文档 | P3-02~05 | 全绿、push、tag |

## 14. 未决问题（证据不足，明确挂起）
1. Inventory/Backpack/Storage 是否对同一物品双记账（UNRESOLVED，P3-02 逐字段核实）。
2. RepairManager / DoorStateManager / PlayerStateManager 是否真正进入 sprint06 快照（`✓?`/`?`，未逐一打开 default_data 核对）。
3. 训练结束时 Time 与 TrainingTime 的权威/同步方式。
4. `PlayerStateManager` 内 `/root/PlayerStateManager` 自引用的确切用途。
5. `BaseInterior_Test` / `ArrivalLandingScene` 是否仍在任何可达路径（SCENE_REGISTRY UNKNOWN 沿用）。
6. signal 边未穷尽（本轮以 `/root/` 直调为主）；完整 signal 依赖图待 P3-02/03 需要时补。

## 15b. P3-02 决策状态（2026-07-11）
- 已收敛（见 [`PHASE_3_SAVE_OWNERSHIP_DECISION.md`](PHASE_3_SAVE_OWNERSHIP_DECISION.md)）：每核心域 owner 定稿（UNRESOLVED=0）；Backpack↔Storage = CLEAR_SEPARATION+TRANSFER_PROTOCOL（非双记账）；Time/TrainingTime = SEPARATE_CLOCKS+NO_SYNC；PenaltyManager = 分发器/不持久化。
- 仍需用户拍板（2 项）：Full Save 权威模型（推荐**方案 C 分层**）、旧本地档兼容（推荐 NO_COMPATIBILITY_REQUIRED）。
- **P1 仍存在**（存档真相源不唯一），修复归 P3-03；本轮未改代码。
- 1 个 P2 待字段级追踪：Inventory `stack_items` 与 Backpack `slots` 是否双记账（§10 未决 #1，P3-04 前核实）。

## 附：本轮零改动核验
- 本轮仅新增/修改治理 `.md`（本文件 + ACTIVE_TASKS + CLEANUP_PLAN + CURRENT）；未改 `project.godot`、`scripts/**`、`scenes/**`、`assets/**`、任何 `.gd/.tscn/.tres/.uid`。
- Godot `--headless --editor --quit` 与 `--headless --path . --quit` EXIT=0；docs `.import`=0、assets `.import`=70、tracked `.gd.uid`=94、无生成噪声。
