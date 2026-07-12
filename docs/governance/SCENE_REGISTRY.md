# SCENE_REGISTRY · 场景与大型脚本审计

> 治理审计初稿 · 只读 · 2026-07-11
> 本阶段**不拆分**任何脚本，只标注"可提取的稳定职责边界"。

## A. 主要流程场景（root 脚本 / 职责 / 复用）

| 场景 (.tscn) | root 脚本 | 职责 | 被哪些流程用 | 复用? | 状态 |
|---|---|---|---|---|---|
| `scenes/main.tscn` | `scripts/main.gd` (5156) | 主菜单+路由+**旧沙盒本体** | 启动/主菜单/沙盒 | 单场景多职责 | ACTIVE + LEGACY 混装 ⚠ |
| `scenes/application/ApplicationStartScene.tscn` | `application_flow_scene.gd` (811) | 申请全流程 | 正式段1 | 否 | ACTIVE |
| `scenes/application/TrainingPlaceholderScene.tscn` | `training_placeholder_scene.gd` (43) | 申请→训练占位跳板 | 正式段1↔2 | 否 | ACTIVE（占位） |
| `scenes/training/TrainingStartScene.tscn` | `training_start_scene.gd` (71) | 训练入口 | 正式段2 | 否 | ACTIVE |
| `scenes/training/TrainingBaseMap.tscn` | `training_base_map.gd` (2255) | 训练小地图 hub（多房间走门切换） | 正式段2 | 否 | ACTIVE |
| `scenes/training/SolarArrayTrainingField.tscn` | `training_module_scene.gd` (3417) | 训练模块 03（太阳能维修，独立场景） | 正式段2b | **是**（同脚本驱动6模块） | ACTIVE |
| `scenes/training/FinalAssessmentScene.tscn` | `training_module_scene.gd` | 最终考核 | 正式段2 | 是 | ACTIVE |
| `scenes/training/MissionAssignmentNoticeScene.tscn` | `mission_assignment_notice_scene.gd` (241) | 派遣通知书 | 正式段3 | 否 | ACTIVE |
| `scenes/training/AssignmentBlackScreenScene.tscn` | `assignment_black_screen_scene.gd` (54) | 黑屏转场 | 正式段4 | 否 | ACTIVE |
| `scenes/arrival/ArrivalCinematicScene.tscn` | `arrival_cinematic_scene.gd` (386) | 抵达/看地球（正式路径） | 正式段5 | 否（跑遗留基座） | ACTIVE（LEGACY 基座） |
| `scenes/arrival/ArrivalLandingScene.tscn` | `arrival_landing_scene.gd` (472) | 着陆原型 | Dev / 早期抵达 | 否 | **UNKNOWN**（是否在正式路径） |
| `scenes/base/BaseAirlockEntryScene.tscn` 等 **10 个 base 场景** | `sprint06_base_scene.gd` (2599) | 旧基地/温室/Day01-02/第一周/太阳能外景/美术切片 | 正式段6-8 | **是（10 场景共用 1 脚本）** | ACTIVE（tier-1） |
| `scenes/base/OldBaseCore_ArtSlice.tscn` (22行,最大 tscn) | `sprint06_base_scene.gd`(+`art_slice_marker_layer.gd`) | 旧基地美术切片 | 正式段7 | 是 | ACTIVE |
| `scenes/base/Phase02PlaceholderScene.tscn` | `phase02_placeholder_scene.gd` (53) | Demo 终点占位 | 正式段9 | 否 | ACTIVE（占位） |
| `scenes/surface/LunarSurfaceScene.tscn` | `lunar_surface_scene.gd` (416) | 月面 EVA 播种 | Dev（新播种） | 否 | ACTIVE（早期，有未提交改动） |
| `scenes/base/BaseInterior_Test.tscn` | `arrival/base_interior_test.gd` (25) | 测试场景 | Dev/测试 | 否 | **DEPRECATED_CANDIDATE**（见下） |
| `scenes/base/Phase02PlaceholderScene.tscn`… | | | | | |

### 沙盒/原型场景（LEGACY_PLAYABLE，仅 Dev 或沙盒用）
`scenes/player.tscn`、`scenes/robot.tscn`、`scenes/module_visual.tscn`、`scenes/collectable_visual.tscn` — 由 `main.gd` 沙盒 preload（`main.gd:22-25`）。`player.tscn` 也被 `arrival_landing_scene.gd` 用。

### Props 场景（可复用组件，ACTIVE）
`scenes/props/greenhouse/*`、`scenes/props/old_base/*`、`scenes/props/solar_array/*`、`scenes/props/training/*` — 共 ~50 个小道具场景，多数挂 `reference_prop.gd`，是美术道具化的复用底座。ACTIVE。

## B. 大型脚本职责剖析（体积≠问题，看实际承担的职责）

### B1. `scripts/main.gd` — 5156 行 🔴 最高结构风险
承担职责（严重混装）：
- 主菜单 UI 构建 + 路由（`_setup_main_menu`/`_setup_dev_menu` 3527-3896）
- **旧沙盒游戏全逻辑**：地图/TileMap、玩家移动、建造、资源结算、机器人、背包、科技、补给、月夜（`main.gd:75-341` 大量成员 + 后续实现）
- 存档（slot 制 `_save_path`/save/load 2253-2548）
- 输入处理、`_draw` 相关、Dev 工具

**可提取的稳定职责边界（本次不拆）**：
1. `MainMenuController`（主菜单+Dev菜单 UI/路由）——与沙盒逻辑无耦合，最先可拆。
2. `SandboxGame`（整个沙盒玩法本体）——独立成 `scenes/sandbox/` 一个场景+脚本，让 `main.tscn` 只剩菜单。
3. `SandboxSaveIO`（slot 存档读写）。
> 拆分收益最大、风险最低的是 **#1 菜单与沙盒解耦**（菜单是正式流程入口，沙盒是遗留）。

### B2. `scripts/training/training_module_scene.gd` — 3417 行 🟠
职责：驱动全部训练模块的**步骤判定逻辑** + 设备 `_draw()` 绘制 + 弹窗 + 存档字段（`MODULE_SCENES`/`default_data` 相关，含 legacy 常量 `:3187,3271,3297`）。
**可提取边界**：模块步骤数据（每模块的 step 定义/next_scene）与"绘制/交互运行时"分离；但 `COLLABORATION_RULES.md:40` 标其为 tier-1，改动须谨慎。

### B3. `scripts/base/sprint06_base_scene.gd` — 2599 行 🟠
职责：10 个正式场景（气闸/旧基地/温室/Day01-02/第一周/太阳能外景/美术切片）共用的**通用场景驱动**：玩家控制装配（`:688-701`）、场景常量路由（`:7-14`）、存档读写（`:2439-2518`）、时间/交互。
**可提取边界**：场景配置数据（每个 SCENE_ 的道具/交互清单）与通用运行时分离。tier-1，谨慎。

### B4. `scripts/training/training_base_map.gd` — 2255 行 🟠
职责：训练 hub 多房间（走门 `_switch_room` 而非换场景 `:489,1027`）、气闸压力状态门禁、宇航服流程、惩罚接线（`CURRENT.md:26`）。tier-1（近期高频改动）。

### B5. 其余较大脚本（ACTIVE，暂无拆分紧迫性）
`ItemDatabase.gd`(859,纯数据)、`application_flow_scene.gd`(811)、`AirSystemManager.gd`(606)、`PlantGrowthManager.gd`(605)、`SupplyManager.gd`(580)、`training_manager.gd`(566)。数据库类天然大，不算结构问题。

## C. DEPRECATED_CANDIDATE / UNKNOWN 场景（须证据，不删）

- `scenes/base/BaseInterior_Test.tscn` + `scripts/arrival/base_interior_test.gd`(25)：命名含 "Test"，引用 `game_state_manager`/`time_manager`（遗留基座）。**未在 main.gd Dev 菜单或正式路由中找到入口**。→ DEPRECATED_CANDIDATE，须确认是否有其他入口后再处置（Phase 3）。
- `scenes/arrival/ArrivalLandingScene.tscn`：~~UNKNOWN~~ → **P3-05 已核实：DEV_ONLY / LEGACY_PROTOTYPE**。唯一入口是 `main.gd:3751`「Dev Only: Arrival Landing」按钮；正式抵达走 `ArrivalCinematicScene`。不在正式可达路径。保留（Dev 可运行），不删。
- `scenes/props/*` 中是否有未被任何场景 instance 的孤儿道具场景：**本阶段未逐一核实**，标记为 Phase 1 待查。

## D. P3-05 Legacy 运行路径隔离（2026-07-12）

- **正式路径场景**（formal）：`ApplicationStartScene`（正式新局入口）、`scenes/base/*`（sprint06 正式段，Full Save 域）、正式续档经 `FullSaveOrchestrator.continue_scene_path()`。
- **训练场景**（training）：`TrainingStartScene`/`TrainingBaseMap`/训练模块/`MissionAssignmentNoticeScene`/`AssignmentBlackScreenScene`（Training Checkpoint 域，经 `TrainingManager`）。
- **Legacy sandbox**：`scenes/main.tscn` 内联沙盒（`_start_new_game`，沙盒 save_panel + Dev 菜单）。存档 `slot_N.json`，局部管理器节点已重命名 `Sandbox…`。DEV/LEGACY_PLAYABLE。
- **Arrival prototype**：`ArrivalLandingScene.tscn`（`main.gd:3751` Dev 按钮）。存档 `arrival_prototype_save.json`，局部节点已重命名 `ArrivalPrototype…`。DEV_ONLY / LEGACY_PROTOTYPE。
- **可达性**：sandbox / arrival 均**不可从正式 Continue/New Game 主流程进入**（仅 Dev/沙盒面板）。正式与 legacy 入口在脚本层已分离并加注释标识；本轮不改菜单 UI。
- 详见 `LEGACY_REGISTRY.md` §D。
