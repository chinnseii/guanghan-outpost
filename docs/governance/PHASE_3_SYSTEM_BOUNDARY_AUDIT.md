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

## 16. Independent review reconciliation（P3-02R · 2026-07-11 · 基线 `ceafe6c`）

> Codex 独立只读复核提出 6 项问题；本节由 Claude 逐项按 `文件:行号`/方法独立核验，给 `CONFIRMED / PARTIAL / NOT_CONFIRMED` + 证据 + 最终结论。原审计 §1–§15b 证据保留不删。

### 16.1 Codex 六项发现逐项核验

**① PowerSystemManager 恢复后未同步 BaseStatusManager.power — CONFIRMED（P2，非 P1）**
- 证据：`PowerSystemManager.gd:458-469` `deserialize()` 是**唯一**不调用 `_sync_base_status_power()` 的状态变更路径；对照 `reset_to_arrival`(:60)、`advance_power_time`(:93)、`apply_action_cost`(:104)、`consume_energy`(:357)、`debug_*`(:346/377/408) 全部在改值后 `_sync_base_status_power()`。`deserialize()` 仅以 `power_system_changed.emit()`(:469) 收尾。
- canonical 恢复值：`PowerSystemManager.current_energy` → `get_power_percent()`（:150）。compatibility mirror：`BaseStatusManager.power`（`BaseStatusManager.gd:22` 自有字段 + `set_power_percent()` :81 写入）。
- `BaseStatusManager.power` 的 reader：`_apply_temperature_change`(:99-106，power 阈值决定温度乘子)、`_apply_health_environment_effects`(:151-154，morale 扣减)、`get_specialist_hint`/label（显示）。**两个玩法 reader 都只在 `advance_base_time()`(:66) 内运行**，而 TimeManager 每 tick 先调 `PowerSystemManager.advance_power_time()`（已 sync）再调 `BaseStatusManager.advance_base_time()` → **下一次时间推进必然重新同步**。
- 为何 P2 非 P1：正常恢复时 `base_status_state.json` 与 `power_system_state.json` 是**同刻一致快照**（每次改值都先 sync 再各自 `_save_state()`），故 mirror 恢复即一致；仅在"部分档缺失/一方 fallback `reset_to_arrival`"的边缘才短期偏离，且首个 time tick 自愈。**无 reader 在恢复与首 tick 之间做玩法判断**。→ 现状 **P2 显示/短窗风险**；但在方案 C（bundle restore + mirror 重算）下必须显式补"canonical→重算 mirror"阶段，列为 **P3-03a 设计约束**。

**② BaseStatusManager 职责摘要仍把氧气写成其汇总状态 — CONFIRMED（IMPLEMENTATION_DOC_MISMATCH）**
- 代码事实：`BaseStatusManager.serialize()`(:396-405) 字段 = power/pressure/temperature/power_system_status/thermal_control_status/seal_status/last_plant_recovered_bonus_active — **无任何 oxygen 字段**；注释 `:187` 明确"Oxygen/CO2 no longer factor in here — see AirSystemManager"。
- 氧气 canonical owner = **AirSystemManager**（`AirSystemManager.gd:47` `oxygen_generator_status`、制氧/CO2 系统 + `serialize` :512）。电力 canonical owner = **PowerSystemManager**；`BaseStatusManager.power` = 兼容镜像。
- 文档缺陷：`SYSTEM_REGISTRY.md:24` 摘要写"电力/氧气/舱压/温度四档汇总状态"——会误导 Agent 认为 BaseStatus 拥有氧气与电力。→ 已在 §16.4 / SYSTEM_REGISTRY 最小修订。

**③ SuitManager 与 PlayerStateManager 同持 is_suit_worn — CONFIRMED（owner 明确，SYNC_COMPLETE 运行时，restore-recompute 建议）**
- `CANONICAL_OWNER = SuitManager`（**代码事实，非推荐**）：`SuitManager.gd:375-386` 注释"SuitManager stays the source of truth"；`_sync_player_state_suit_worn()` 在**每条** `is_suit_worn` 变更后调用——`reset_to_arrival`(:84)、`wear_suit`(:96)、`wear_suit_training`(:122)、`remove_suit_to_service_station`(:133)、`remove..._training`(:149)、`deserialize`(:461)。
- `COMPATIBILITY_MIRROR = PlayerStateManager.is_suit_worn`（`PlayerStateManager.gd:39-42` 注释"cached mirror"；`set_suit_worn`(:155) 仅被 SuitManager 推送与 boot 拉取 `sync_suit_state_from_suit_manager()`(:164) 调用；PlayerState **从不独立决定** suit-worn）。
- 写入路径：SuitManager→PlayerState = **SYNC_COMPLETE**（全路径覆盖）。反向不存在（PlayerState 不写回）。boot 顺序问题由 `PlayerStateManager._ready()`(:58-59) 拉取自愈。
- 唯一缺口：PlayerState **冗余持久化** `is_suit_worn`（`serialize` :261 / `deserialize` :269），restore 时不回读 SuitManager → 与 Power 同类"restore 后 mirror 应重算"问题。→ 结论 **`FINAL_OWNER(SuitManager) / SYNC_COMPLETE(runtime) / RESTORE_RECOMPUTE(建议)`**，P2，**不产生新用户决策**（owner 由系统职责已定）。**未见正在发生的确定性数据损坏**。

**④ DoorStateManager 正式旧基地接入 — CONFIRMED = `FORMAL_BASE_NOT_CONNECTED`**
- Autoload 已注册（`project.godot:36`）。`reset_to_arrival`(:16-159) 注册的门**数据**覆盖正式旧基地（control_room↔power_room/air_system_room/water/greenhouse/rest 等）。
- 唯一**消费者** = `scripts/training/training_base_map.gd:322/720/726`（`try_pass_door`）→ **TRAINING_CONNECTED**。全仓 `scripts/base/**` 及正式旧基地场景 = **零** DoorStateManager 引用（导航静态零命中）。
- 门状态**不进正式 full save**：`sprint06_base_scene.gd` 零 `DoorState` 引用 → 仅经 `door_state.json` 自存。
- 结论：`TRAINING_CONNECTED` + `FORMAL_BASE_NOT_CONNECTED`；full-save 归属 = 当前"自存/scene-local，未纳入 Full Save"。→ 接入属**功能**，排 **P3-04**（若涉正式场景替换则 P3-05）；本轮不接入。与 `SYSTEM_REGISTRY.md:34/56-57` 既有"未全接"判断一致。

**⑤ legacy 局部 TimeManager / GameStateManager 同名 — CONFIRMED = `LEGACY_LOCAL_NAME_COLLISION`（P2/P3，不升 P1）**
- `main.gd:909-914` 与 `arrival_landing_scene.gd:81-85` 用 `preload("res://scripts/game_state_manager.gd")`/`preload("res://scripts/time_manager.gd")`（**小写遗留脚本**）`.new()` 并 `.name = "TimeManager"/"GameStateManager"`，`add_child` 到各自 legacy 场景根。
- autoload `TimeManager` 指向 `scripts/managers/TimeManager.gd`（`project.godot:24`），**脚本不同**；GameStateManager 无 autoload 条目。
- 无运行冲突证据：两处均经**成员变量**（`time_manager`/`game_state_manager`）调用，`main.gd`/`arrival` **零** `get_node("TimeManager")`/`get_node("GameStateManager")` 字符串查找（静态零命中）→ 不会误绑 `/root` autoload。仅 legacy 场景运行。
- 结论：`LEGACY_LOCAL_NAME_COLLISION` + 潜在 `DEBUGGING_AMBIGUITY`（编辑器节点树同名）；**非 `RUNTIME_CONFLICT`**。→ P2/P3 隔离风险，归 **P3-05 Legacy 隔离**，不升 P1。

**⑥ TrainingManager load_progress / _read_progress_data 边界 — CONFIRMED**
- `_read_progress_data()`（`training_manager.gd:113`，`static`）= **只读 JSON**、无 live-manager 副作用（:113-126）。
- `load_progress()`（:128，`static`）= 先 `_read_progress_data()` 再对 **12 个 live Manager** `.call("deserialize", …)`（:130-165）→ **有恢复副作用**。注释 :99-112 已记录踩坑（mid-session 调用会用旧快照覆盖 live，宇航服被重置，`mark_module_completed` 已改用 `_read_progress_data`）。
- 残留 query-语义误用 load_progress()：`training_status()`(:372)、`training_failure_reason()`(:375)——但二者**全仓零调用**（dead API，已核 `grep` 无 caller）→ 当前**不造成**活损坏。其余 `load_progress()` caller（`main.gd:4507/4520` has-progress 检查、`accept_assignment`/`set_opening_flow_stage`/`continue_scene_path`/`start_training`、三处场景 boot）均在 **boot/转场（restore-ish）** 上下文。
- 结论：边界正式化写入决策——`_read_progress_data = read-only query`、`load_progress = state-restoring operation（应仅由 Restore Orchestrator 调用）`；P3-03a 应把 `training_status()/training_failure_reason()` 改指 `_read_progress_data` 或删除。当前 **P2/hygiene**，非活损坏。

### 16.2 修订后数据 owner 状态（不再用单一 FINAL 抹平同步风险）

| 数据域 | Owner | 状态分类 | 依据 |
|---|---|---|---|
| 电力 | PowerSystemManager | **OWNER_FINAL_BUT_SYNC_RISK** | deserialize 不同步 BaseStatus.power 镜像（§16.1①），P2 |
| 宇航服 worn | SuitManager | **OWNER_FINAL_BUT_SYNC_RISK** | PlayerState 镜像冗余持久化、restore 不回读（§16.1③），P2 |
| 门状态 | DoorStateManager | **OWNER_FINAL；正式基地接入 = UNRESOLVED** | 训练已接、正式基地零消费、未入 full save（§16.1④） |
| 氧气 | AirSystemManager | OWNER_FINAL | BaseStatus 无氧气字段（§16.1②） |
| 舱压/温度 | BaseStatusManager | OWNER_FINAL | 直接状态 |
| Inventory ↔ Backpack 记账 | Inventory / Backpack | **DECISION_PENDING（P2 字段级追踪）** | §5 未决 #1，P3-04 前核实 |
| 游戏时间/训练时间 | TimeManager / TrainingTimeManager | OWNER_FINAL（真相源模型 DECISION_PENDING） | SEPARATE_CLOCKS+NO_SYNC |
| 惩罚历史 | 无持久化 owner | OWNER_FINAL（不持久化） | PenaltyManager 分发器 |
| 玩家位置(地表) | 场景局部 | USER_DECISION（是否持久化） | 未持久化 |

统计：**OWNER_FINAL = 12**（时间×2/健康/氧/水/压/温/补给/仓储/植物/维修/任务 + 申请档案，另计）；**OWNER_FINAL_BUT_SYNC_RISK = 2**（电力、宇航服）；**DECISION_PENDING = 2**（Inventory↔Backpack 记账、Full Save 真相源模型）；**UNRESOLVED = 1**（Door 正式基地接入）；**USER_DECISION = 2**（玩家位置持久化、旧档兼容）。**"UNRESOLVED=0"的原表述作废**——owner 已知不等于同步/接入已定稿。

### 16.3 修订风险统计

- **P0：0**（无正在发生的存档/核心状态损坏；Suit/Power 均无活损坏）。
- **P1：1** — 存档真相源不唯一（原 P1 保留，归 P3-03）。
- **P2：6** — ① 电力 restore mirror 不同步；② 宇航服镜像 restore-recompute 缺口；③ Inventory↔Backpack 双记账待核；④ Time/TrainingTime 结束同步（按现有设计=NO_SYNC，待确认）；⑤ legacy 同名节点隔离；⑥ TrainingManager load/read API 边界（含 2 个 dead query 函数）。
- **P3：3** — ① PlayerState 自引用 helper 冗余；② 遗留 save 管线（沙盒 slot/arrival_prototype）并存断开；③ Door 正式基地接入（功能待排期，作为 UNRESOLVED 亦列此）。
- **IMPLEMENTATION_DOC_MISMATCH：1** — `SYSTEM_REGISTRY.md:24` BaseStatus 摘要含氧气/电力（§16.1②，已最小修订）。

### 16.4 SYSTEM_REGISTRY 最小修正项（证据充分）
- BaseStatusManager 摘要收紧：舱压/温度为直接状态；电力为 PowerSystemManager 同步的兼容镜像；氧气由 AirSystemManager 管理（BaseStatus 无氧气字段）。
- 标注 canonical owner / compatibility mirror：Power（Power↔BaseStatus.power）、Suit（Suit↔PlayerState.is_suit_worn）。
- Door 正式基地接入状态标注 `FORMAL_BASE_NOT_CONNECTED`（训练已接）。
- 未大规模重写 Registry。

## 17. P3-03a 恢复一致性修复状态（2026-07-12 · 基线 `6354ef7`）

> 本节记录 §16 所列缺口在 P3-03a 的处置。**这是 Phase 3 首个改代码的批次**（前序均为文档）。

- **Power 兼容镜像缺口（§16.1① P2）= 已修**：`PowerSystemManager.deserialize()` 现在在 emit 前调 `_sync_base_status_power()`（canonical→mirror 单向）。专项测试 A 验证：deserialize 能量后 `BaseStatusManager.power` 立即等于 `get_power_percent()`。
- **Suit restore 镜像（§16.1③ P2）= 已修/已验**：`SuitManager.deserialize()` 改为先同步 `PlayerStateManager.is_suit_worn` 再 emit；专项测试 B 验证双向值一致。owner 仍 `SuitManager`（canonical），mirror 不回写。
- **read/restore API 边界（§16.1⑥ P2）= 已落实**：新增公开 `TrainingManager.read_progress()`（无副作用）；`training_status()`/`training_failure_reason()`（dead）与 `fail_training()`（mid-session timeout，契约禁触 mission managers）改用只读路径。外部纯查询调用（`main.gd`、3 个训练场景、`training_base_map.gd`、`TaskManager.gd`）已全部改为 `read_progress()`；外部 `_read_progress_data()` 调用为 0。测试 C/静态扫描验证只读查询零 live-manager 变更。
- **restore-complete = 已建**：`TrainingManager.finalize_restore()`（幂等、无副作用）在 `load_progress()` 收尾统一重算 Power/Suit 镜像；测试 D/E 验证恢复仍生效且 finalize 不动 time/health/supply/energy。
- **P1 多真相源 = 仍未解决**：Manager 自存 `*_state.json` + `training_progress` + `sprint06_progress` 冗余仍在；**P3-03b（Full Save Orchestrator 正式化 + schema_version）/ P3-03c（自存降级）负责**。本轮**未**加 schema_version、**未**停用/删除任何自存文件、**未**改 JSON 结构。
- **P3-03b 未开始**：Full Save Orchestrator 正式化、schema_version、Manager 自存降级仍是下一任务范围。
- **文档/实现差异（§16.1② `SYSTEM_REGISTRY:24`）**：P3-02R 已修订，本轮无新增 mismatch。

## 附：P3-03a 改动核验
- 实现变更：`scripts/managers/PowerSystemManager.gd`、`scripts/managers/SuitManager.gd`、`scripts/training/training_manager.gd`、纯查询调用点（`scripts/main.gd`、`scripts/training/assignment_black_screen_scene.gd`、`mission_assignment_notice_scene.gd`、`training_base_map.gd`、`training_module_scene.gd`、`scripts/managers/TaskManager.gd`）+ 新增 `tests/p3_03a_restore_consistency_test.gd`(+`.uid`)；未改 `project.godot`、`scenes/**`、`assets/**`、任何 `.tscn/.tres/.res/.json`；无 autoload 增删。
- Godot `--headless --editor --quit` 与 `--headless --path . --quit` EXIT=0；专项测试 39/39 通过；实测本地存档在测试后与备份 SHA-256 全一致（零污染）。
- （P3-01/P3-02/P3-02R 的零改动核验历史见各自节，此处不复述。）
# P3-03b Full Save Orchestrator Status (2026-07-12 · baseline `e09eff8`)

- Formal Full Save entry: `scripts/systems/full_save_orchestrator.gd` (non-Autoload static service). `scripts/base/sprint06_base_scene.gd` is now a scene adapter that supplies/receives `scene_state`.
- Authoritative file: `user://saves/full_save.json`. `sprint06_progress.json` is legacy best-effort only; `training_progress.json` remains the training checkpoint and is not read by Full Restore.
- P1 multi-source status: partially mitigated, not fully solved. Complete progress now has one authoritative bundle and one orchestrated write/restore path, but Manager self-save `*_state.json` still exists and still auto-writes. Until P3-03c, classify as `P1 mitigated / pending self-save downgrade`, not fully resolved.
- Restore order risk: Power restores after BaseStatus and Suit restores after PlayerState; finalization recomputes mirrors from canonical owners, so stale mirrors do not overwrite canonical state. Door remains excluded because the formal base is not connected to DoorStateManager.
- Call-site changes: `main.gd` base continue path no longer calls `TrainingManager.load_progress()`; `TaskManager._mission_progress()` reads Orchestrator `scene_state`; `TrainingManager._base_continue_scene_path()` queries Orchestrator continue path.
- Boundaries untouched: no `project.godot` change, no new Autoload, no Manager self-save removal, no Training Checkpoint trimming, no formal-base Door integration, no Inventory/Backpack business logic change.
- Verification: P3-03b 50/50, P3-03a 39/39, real saves still match the P3-03a backup by SHA-256, and no formal `full_save.json` or backup noise was generated by tests.

# P3-03c Boundary Update (2026-07-12)

- Auto-load audit result: formal core Managers that run `_ready() -> load_state()` are `TimeManager`, `HealthManager`, `BaseStatusManager`, `PowerSystemManager`, `WaterSystemManager`, `AirSystemManager`, `InventoryManager`, `BackpackManager`, `StorageManager`, `SuitManager`, `SupplyManager`, `RepairManager`, and `PlantGrowthManager`. These now gate local `load_state()` behind `FullSaveOrchestrator.should_skip_manager_local_restore()`.
- Remaining auto-loads intentionally not treated as formal complete-progress authority: `DoorStateManager` (`door_state.json`, training/local and formal base not connected) and `TrainingTimeManager` (`training_time_state.json`, training-local clock).
- Formal restore boundary: `FullSaveOrchestrator.restore_full_save()` validates provider availability first, applies canonical provider state in explicit order, finalizes Power/Suit mirrors, then marks restore complete. After that point, downgraded Manager-local reads cannot reload `*_state.json` over Full Save state.
- Cross-system write status unchanged: no new direct foreign field writes were introduced; changes are API/static guard calls only.
- Remaining P3 risk: checkpoint scope trimming is still pending P3-03d, and Door formal-base integration remains outside Full Save until its feature integration is scheduled.
- P3-03cV correction: the Full Restore completed flag is no longer an unresettable process-wide blocker. `FullSaveOrchestrator.reset_formal_restore_session()` clears the guard for new-game/demo-reset flows, while restored sessions still block late Manager-local `load_state()`.
- Verification: Godot editor parse EXIT 0; Godot headless smoke EXIT 0; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; real saves SHA unchanged from pre-test baseline.

# P3-03d Boundary Update (2026-07-12)

- Training Checkpoint scope is now restricted in `scripts/training/training_manager.gd`.
- `training_progress.json` owned fields: training flags/current module/status, assignment/opening flow flags, `SuitState` as training temporary equipment state, `TrainingTimeState`, and `TrainingInventoryState.training_containers`.
- Legacy global fields from older `training_progress.json` files (`TimeState`, `HealthState`, `BaseStatusState`, `AirSystemState`, `PowerSystemState`, `WaterSystemState`, `InventoryState`, `BackpackState`, `StorageState`, `PlantGrowthState`, `PlayerStateManagerState`) are read as `LegacyGlobalStateFields` metadata only and are not applied to live Managers.
- `TrainingManager.save_progress()` strips those legacy global fields on write.
- `FullSaveOrchestrator.read_bundle()` no longer auto-falls back from missing `full_save.json` to `sprint06_progress.json`.
- Explicit legacy sprint06 reads remain available for best-effort inspection/conversion, but `FullSaveOrchestrator.restore_full_save()` rejects `legacy_source` bundles. Formal restore requires `full_save.json`.
- P1 multi-truth-source risk is now materially reduced for P3-03 scope: formal complete restore is Full Save only; Manager local saves are downgraded; Training Checkpoint cannot restore formal global Manager state.
- Remaining P3 risk: Door formal-base integration is still outside Full Save, and Inventory/Backpack field-level relationship remains a P3-04 audit item.
- Verification: Godot editor parse EXIT 0; Godot headless smoke EXIT 0; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; P3-03d 25/25; real saves SHA unchanged from pre-test baseline; no `p3_03d*` temp files remained.

# P3-04 Boundary Update (2026-07-12)

- Inventory / Backpack / Storage final owner split: `InventoryManager` owns quantity-style global goods (`stack_items`, `durable_items`) and training-only `training_containers`; `BackpackManager` owns player carried slots; `StorageManager` owns base storage slots.
- Backpack/Storage transfer protocol is explicit in API results: `source`, `destination`, `source_slot_index`, `requested_amount`, `returned_to_source`, and `rolled_back`. Existing take/add/reject rollback behavior is unchanged.
- Consumption source remains explicit by owner API: `InventoryManager.remove_item/eat_item/use_item`, `BackpackManager.remove_item/eat_item`, and `StorageManager.remove_item/eat_item` each mutate only their own ledger. P3-04 did not redesign item quantities or storage rules.
- Time split is confirmed: `TimeManager` is formal mission time; `TrainingTimeManager` is training-local time. `MovementTimeManager` routes by context, Suit has mission/training entry points, and Repair keeps explicit formal/training branches. Training time does not write back to formal time.
- BaseStatus compatibility mirrors are clarified: `PowerSystemManager` owns canonical power; `BaseStatusManager.power` is a one-way compatibility mirror updated through `sync_power_mirror_from_power_system()` with `set_power_percent()` kept as a wrapper. `AirSystemManager` owns oxygen/CO2; BaseStatus owns pressure/temperature.
- Suit compatibility mirror is clarified: `SuitManager.is_suit_worn` is canonical; `PlayerStateManager.is_suit_worn` is a cached mirror updated through `sync_suit_worn_mirror_from_suit_manager()` with `set_suit_worn()` kept as a wrapper.
- Door boundary is confirmed unchanged: `DoorStateManager` is used by `training_base_map.gd`; `scripts/base/**` has no `DoorStateManager` references. Formal old-base Door integration remains out of scope and not connected.
- Risk status after P3-04: no P0 found; P1 multi-truth-source risk remains reduced/closed for P3-03 scope; Inventory/Backpack/Storage ownership ambiguity is closed for current runtime design; Door formal-base integration remains a scheduled feature boundary, not a P3-04 implementation.
- Verification: Godot editor parse EXIT 0; Godot headless smoke EXIT 0; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; P3-03d 25/25; P3-04 33/33; real saves SHA unchanged from pre-test baseline.
