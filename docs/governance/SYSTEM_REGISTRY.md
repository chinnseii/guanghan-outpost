# SYSTEM_REGISTRY · Manager / Autoload 审计

> 治理审计初稿 · 只读 · 2026-07-11
> 状态取值：`ACTIVE`（正式流程现役）/ `COMPATIBILITY`（仅为存档/旧路径兼容保留）/ `LEGACY_PLAYABLE`（仅遗留可玩流程用）/ `DEPRECATED_CANDIDATE`（疑似废弃，须列引用证据）/ `UNKNOWN`。
> 引用数 = `grep -rl` 命中的不同文件数（已排除自身定义文件）；用于佐证现役性，非精确调用数。

## A. 已注册 Autoload（`project.godot:21-42`，共 20 个）

| # | 名称 / class_name | 路径 | 引用文件数 | 核心职责 | 参与存档 | 状态 |
|---|---|---|---|---|---|---|
| 1 | AcademicBackgroundManager | `scripts/managers/AcademicBackgroundManager.gd` | 3 | 申请阶段教育背景（机械/材料/医学/植物），只给提示文字不给数值加成 | `application_profile.json` | ACTIVE |
| 2 | TimeManager / GuanghanTimeManager | `scripts/managers/TimeManager.gd` | **22（最高）** | 行动推进制时间（`advance_time(min,reason)`）、月夜/月昼阶段 | `time_state.json` + 训练/sprint06 快照 | ACTIVE |
| 3 | HealthManager / GuanghanHealthManager | `scripts/managers/HealthManager.gd` | 19 | 精力/饱腹/营养，影响行动倍率 | `health_state.json` + 快照 | ACTIVE |
| 4 | BaseStatusManager / GuanghanBaseStatusManager | `scripts/managers/BaseStatusManager.gd` | 12 | 电力/氧气/舱压/温度四档汇总状态 | 有 serialize | ACTIVE |
| 5 | PowerSystemManager / GuanghanPowerSystemManager | `scripts/managers/PowerSystemManager.gd` | 14 | 电力系统（从 BaseStatus 拆出） | 有 | ACTIVE |
| 6 | WaterSystemManager / GuanghanWaterSystemManager | `scripts/managers/WaterSystemManager.gd` | 14 | 水资源系统（拆出） | 有 | ACTIVE |
| 7 | AirSystemManager / GuanghanAirSystemManager | `scripts/managers/AirSystemManager.gd` | 13 | 空气/制氧系统（拆出） | `air_system_state.json` | ACTIVE |
| 8 | PlantGrowthManager / GuanghanPlantGrowthManager | `scripts/systems/PlantGrowthManager.gd` | 9 | 植物生长/最后一株植物 | 有 | ACTIVE |
| 9 | InventoryManager / GuanghanInventoryManager | `scripts/managers/InventoryManager.gd` | 10 | 物品系统（配 ItemDatabase） | 有 | ACTIVE ⚠重叠 |
| 10 | BackpackManager / GuanghanBackpackManager | `scripts/managers/BackpackManager.gd` | 8 | 背包（EVA 携带，容量/重量） | `backpack_state.json` | ACTIVE ⚠重叠 |
| 11 | StorageManager / GuanghanStorageManager | `scripts/managers/StorageManager.gd` | 11 | 基地仓库存储 | `storage_state.json` | ACTIVE ⚠重叠 |
| 12 | SupplyManager / GuanghanSupplyManager | `scripts/managers/SupplyManager.gd` | 4 | 地球补给（下单/延迟/取消/重量惩罚） | `supply_state.json` | ACTIVE |
| 13 | RepairManager / GuanghanRepairManager | `scripts/managers/RepairManager.gd` | 5 | 维修 v1（配 FaultDatabase） | `repair_state.json` | ACTIVE |
| 14 | DoorStateManager / GuanghanDoorStateManager | `scripts/managers/DoorStateManager.gd` | **1（最低）** | 门编号/状态（配 DoorType/DoorAsset DB） | 有 | ACTIVE（新，见注） |
| 15 | TrainingTimeManager | `scripts/managers/TrainingTimeManager.gd` | 9 | 训练专用时钟（`advance_training_time`） | 有 | ACTIVE ⚠与 TimeManager 并存 |
| 16 | SuitManager / GuanghanSuitManager | `scripts/managers/SuitManager.gd` | 13 | 宇航服穿脱/EVA 门禁 | 有 | ACTIVE |
| 17 | MovementTimeManager | `scripts/managers/MovementTimeManager.gd` | 8 | 移动按格推进时间，路由到 Time 或 TrainingTime | 无（转发器） | ACTIVE ⚠与 TimeManager 并存 |
| 18 | PlayerStateManager | `scripts/managers/PlayerStateManager.gd` | 8 | 玩家当前状态注册表 | 有 serialize | ACTIVE |
| 19 | PenaltyManager / GuanghanPenaltyManager | `scripts/managers/PenaltyManager.gd` | 7 | 统一惩罚分派（时间/健康/背包/补给），按 training/mission 路由时钟 | 无（分派器） | ACTIVE（新） |
| 20 | TaskManager / GuanghanTaskManager | `scripts/managers/TaskManager.gd` | 2 | 统一目标/进度视图（训练已接，任务侧 phase2） | 有 | ACTIVE（新，未全接） |

## B. 重点重叠系统分析（结合调用证据，非删除建议）

### B1. 时间三件套 + 遗留
- **TimeManager**（autoload，行动推进制，22 引用）= 正式主线时钟。**ACTIVE**。
- **TrainingTimeManager**（autoload，9 引用）= 训练场景专用时钟。SuitManager/RepairManager 在训练上下文调 `advance_training_time`（`SuitManager.gd:114-142`、`RepairManager.gd:321-323`），非训练调 `advance_time`。**ACTIVE**，与 TimeManager 是**有意的双时钟**（训练/正式分离），非重复实现。
- **MovementTimeManager**（autoload，8 引用）= 移动→时间的**路由/转发器**：训练时转 TrainingTime，正式时转 Time（`MovementTimeManager.gd:53-63`）。**ACTIVE**，是协调层不是第四套时钟。
- **`scripts/time_manager.gd`（小写，无 class_name，61 行）** = **沙盒版时间**。经逐一核实：`scripts/managers/*` 里出现的 `_time_manager()` 都是返回 `/root/TimeManager` autoload 的本地 helper（如 `PenaltyManager.gd:96` `get_node_or_null("/root/TimeManager")`），**不是**引用小写 `time_manager.gd`。真正引用小写版的只有 `main.gd`（沙盒）与 `arrival/*`。→ **LEGACY_PLAYABLE**（见 LEGACY_REGISTRY）。

> 结论：时间系统的"三个 autoload"是分层设计（正式时钟 / 训练时钟 / 移动路由），**没有重复实现**，不建议合并。真正的重名混淆是小写 `time_manager.gd`（沙盒）vs `TimeManager.gd`（正式），已被 `docs/LEGACY_SANDBOX_PROTOTYPE.md` 记录。

### B2. 物品三件套：Inventory / Backpack / Storage
- 三者都是 autoload、都有独立存档、都 ACTIVE。职责边界（据 `SYSTEMS_REFERENCE_FOR_DESIGN.md` 第八 / 八点五章）：Inventory=物品定义/总账，Backpack=EVA 随身（容量+重量），Storage=基地仓库。
- ⚠ **潜在重叠**：三者对"同一件物品在哪"的真相边界需交叉验证（是否存在双记账）。**证据不足以判定是否重复**，标记为需在 Phase 3 专项核实，**不在本阶段动**。

### B3. DoorStateManager 引用数=1
- 仅 1 文件引用，但 `CURRENT.md:8,54` 明确它是 Codex 并行新增、"尚未接入正式旧基地导航"（训练门仍运行时注册）。→ **ACTIVE 但未全接**，非 DEPRECATED（有 autoload 注册 + 文档说明其为在建系统）。

## C. 有 class_name 但非 autoload 的系统/数据脚本（现役支撑）

| 名称 | 路径 | 角色 | 状态 |
|---|---|---|---|
| GuanghanItemContainer | `scripts/systems/ItemContainer.gd` | 容器基类 | ACTIVE |
| ItemDatabase | `scripts/data/ItemDatabase.gd` (859) | 物品数据库 | ACTIVE |
| GuanghanFaultDatabase | `scripts/data/FaultDatabase.gd` | 故障数据库（RepairManager 用） | ACTIVE |
| TaskDatabase | `scripts/data/TaskDatabase.gd` | 任务数据库 | ACTIVE |
| PenaltyDatabase | `scripts/data/PenaltyDatabase.gd` | 惩罚预设（当前很小，`CURRENT.md:52`） | ACTIVE |
| DoorTypeDatabase / DoorAssetDatabase | `scripts/data/*.gd` | 门数据库 | ACTIVE |
| PlantCropData | `scripts/data/PlantCropData.gd` | 作物数据 | ACTIVE |
| ReferenceProp | `scripts/props/reference_prop.gd` | **48 引用，全项目复用面最广**（详见 SHARED_FILE_REGISTRY） | ACTIVE（tier-1） |
| GuanghanPlayerController2D / InteractionArea2D | `scripts/controllers/*.gd` | 正式移动/交互底座 | ACTIVE |
| GuanghanPopupModal | `scripts/ui/popup_modal.gd` | 共用弹窗组件 | ACTIVE |
| TrainingManager | `scripts/training/training_manager.gd` | 训练存档/流程 | ACTIVE（tier-1） |
| OpeningFlowManager | `scripts/training/opening_flow_manager.gd` | 派遣后转场 | ACTIVE（tier-1，小范围） |
| BaseStatusPanel / BasePlayerOverlay / ArtSliceMarkerLayer | `scripts/ui,base/*.gd` | 正式 UI/场景层 | ACTIVE |

## D. 遗留基座脚本（仅沙盒 + arrival，非正式主线）

`game_state_manager.gd` / `time_manager.gd` / `camera_manager.gd` / `ui_manager.gd` / `event_manager.gd` / `audio_manager.gd` / `save_manager.gd` / `robot_task_manager.gd` / `asset_catalog.gd` / `audio_feedback.gd` / `module_visual.gd` / `collectable_visual.gd` / `robot_visual.gd` / `player_visual.gd` / `lighting_manager.gd` / `interaction_detector.gd` / `interactable.gd` / `light_zone.gd`

- 引用方仅 `main.gd`（沙盒）与 `scripts/arrival/*`（Sprint 02 抵达原型）。
- **注意**：`arrival/*` 属于**正式主线第 5 段**（§PROJECT_MAP 表），所以这批脚本目前**间接现役** → 统一标 **LEGACY_PLAYABLE**（不是 DEPRECATED_CANDIDATE），详见 LEGACY_REGISTRY。**不建议在本阶段删。**

## E. DEPRECATED_CANDIDATE

- 本阶段**无**可安全标为 DEPRECATED_CANDIDATE 的 Manager。所有遗留脚本都仍被 `main.gd` 或 `arrival/*` 引用（有调用证据），只能标 LEGACY_PLAYABLE。
- 唯一"疑似废弃但需确认"的是 `scripts/game_state_manager.gd` 是否被 `arrival` 真正调用还是仅 preload 未用——证据不足，标 UNKNOWN，留待 Phase 3。
