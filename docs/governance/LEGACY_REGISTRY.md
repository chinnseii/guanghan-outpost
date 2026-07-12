# LEGACY_REGISTRY · 遗留系统与存档边界

> 治理审计初稿 · 只读 · 2026-07-11
> 每条遗留判断都附**调用证据**；无证据的一律标 UNKNOWN，不臆断"可删"。

## A. 遗留代码分层

### A1. 旧沙盒本体（LEGACY_PLAYABLE，仅 Dev 可进）
- `scripts/main.gd` 内联的沙盒玩法（种植/建造/资源/机器人/科技/背包）。
- 入口证据：仅 Dev 菜单「Start Survival Sandbox」→ `_start_new_game()`（`main.gd:3734`）。
- 文档佐证：`docs/LEGACY_SANDBOX_PROTOTYPE.md`（"与正式流程完全断开"）。

### A2. 沙盒/原型基座脚本（LEGACY_PLAYABLE — 仍被 main.gd 或 arrival 引用）
| 脚本 | 引用方（证据） | 判定 |
|---|---|---|
| `scripts/save_manager.gd` | 仅 `main.gd` | LEGACY_PLAYABLE |
| `scripts/game_state_manager.gd` | `main.gd`, `arrival/*` | LEGACY_PLAYABLE（arrival 用法待核，见 UNKNOWN） |
| `scripts/time_manager.gd`（小写沙盒时钟） | `main.gd`, `arrival/*` | LEGACY_PLAYABLE（**与正式 `TimeManager.gd` 撞名但无关**，见下） |
| `scripts/camera_manager.gd` | `main.gd`, `arrival_landing` | LEGACY_PLAYABLE |
| `scripts/ui_manager.gd` | `main.gd`, `arrival_landing` | LEGACY_PLAYABLE |
| `scripts/event_manager.gd` | `main.gd`, `arrival/*` | LEGACY_PLAYABLE |
| `scripts/audio_manager.gd` | `main.gd`, `arrival/*` | LEGACY_PLAYABLE |
| `scripts/robot_task_manager.gd` | 仅 `main.gd` | LEGACY_PLAYABLE |
| `scripts/asset_catalog.gd` | `*_visual.gd`（沙盒视觉） | LEGACY_PLAYABLE |
| `scripts/audio_feedback.gd` | `main.gd`, `arrival/*` | LEGACY_PLAYABLE |
| `scripts/module_visual.gd` / `collectable_visual.gd` / `robot_visual.gd` | 沙盒场景 | LEGACY_PLAYABLE |
| `scripts/player_visual.gd` | `arrival_landing`, `player.tscn` | LEGACY_PLAYABLE |
| `scripts/lighting_manager.gd` | `arrival_landing` | LEGACY_PLAYABLE |
| `scripts/interaction_detector.gd` / `interactable.gd` / `light_zone.gd` | 互相/沙盒 | LEGACY_PLAYABLE（`interaction_detector` 无外部引用→ 见 UNKNOWN） |

> **关键澄清（防误判）**：正式 Manager 里的 `_time_manager()` helper 返回 `/root/TimeManager` autoload（如 `PenaltyManager.gd:96`、`SupplyManager.gd:570`、`sprint06_base_scene.gd:1783`），**不引用**小写 `time_manager.gd`。因此小写 `time_manager.gd` 的现役面只有 `main.gd`+`arrival`，不要因为"很多文件里出现 time_manager 字样"就以为它被正式流程依赖。已用 `grep` 逐处核实（`scripts/managers/*` 的 `time_manager` 均为局部变量/helper 名）。

### A3. COMPATIBILITY（只为存档兼容保留，不可当场景用）
- `TrainingManager.MODULE_01/02/04/05/06`（`training_manager.gd:14-24`）：命名的 `Training_0X_*.tscn` 场景文件**已删除**（commit `f4d5795 "Delete superseded standalone training scenes and their capture tools"`），常量仅供 `_remap_legacy_training_scene()`（`training_manager.gd:439`）识别旧存档里的 `CurrentSceneAfterTraining` 并重定向到 `TrainingBaseMap`。代码注释已明确 "Never pass them to change_scene_to_file()"（`training_manager.gd:8-13`）。→ **COMPATIBILITY**，保留，勿"清理"。

## B. 存档与状态真相审计（任务 D）

### B1. 存档文件清单（全部在 `user://saves/` 除特别说明）
| 文件 | 写入者 | 内容 |
|---|---|---|
| `application_profile.json` | AcademicBackgroundManager / application_flow_scene | 申请资料/教育背景 |
| `training_progress.json` | TrainingManager | 训练进度 **+ 全部 Manager 状态快照**（`default_data()` 内 `TimeState/HealthState/AirSystemState/PowerSystemState/WaterSystemState/Inventory/Backpack/Storage/PlantGrowth/Suit/PlayerStateManager` 等，`training_manager.gd:88-113`） |
| `sprint06_progress.json` | sprint06_base_scene | 正式旧基地/第一周进度 |
| `time_state.json`,`health_state.json`,`air_system_state.json`,`backpack_state.json`,`storage_state.json`,`supply_state.json`,`repair_state.json`,… | **各 Manager 自己的 `save_state()`** | 单系统状态 |
| `save_N.json`（slot 1-3） | `main.gd` 沙盒 | 沙盒存档 |
| `arrival_prototype_save.json`（`user://` 根，非 saves/） | arrival 场景 | 抵达原型状态 |

### B2. 双重存档机制风险 🔴（核心发现）
每个 Manager **同时**支持两条持久化路径：
1. **自存**：`save_state()`/`load_state()` 各写自己的 `*_state.json`（如 `AirSystemManager.gd:534-553`）。
2. **被快照**：`serialize()`/`deserialize()` 被 `TrainingManager`（`training_progress.json`）**和** `sprint06_base_scene` 打包进大存档。

→ 同一状态可能被写进多个文件；训练存档与正式(sprint06)存档**是分离的两套快照**。`training_manager.gd:_read_progress_data()` 的长注释（`training_manager.gd` 约 96-113 行上方）已记录一个真实踩坑：mid-session 误调 `load_progress()` 会用旧快照覆盖 live manager（宇航服穿戴状态被重置）。这说明"谁是某状态的唯一真相源"目前**并不清晰**。

### B3. 场景切换时的状态传递
- 训练→正式 靠存档字段 `CurrentSceneAfterTraining`（`training_manager.gd:default_data`）+ `MODULE_SCENES` remap，不直接传内存对象。
- Manager 全是 autoload，跨场景内存常驻，因此场景切换主要靠 autoload 内存 + 落盘快照双轨。

### B4. 文档 vs 源码一致性
- `SYSTEMS_REFERENCE_FOR_DESIGN.md` 覆盖了全部现役 Manager（章节见 DOCUMENT_REGISTRY），与源码结构一致度高。
- **未发现**明显的文档-源码行为冲突（本阶段抽查范围内）；但存档"真相源"边界文档化不足 → 记为 Phase 3 待补，不擅改。

### B5. 改 Manager 的兼容风险（供后续 Phase 3）
- 任何改 Manager `serialize()/deserialize()` 结构的改动，会同时影响：该 Manager 自存文件 + `training_progress.json` + `sprint06_progress.json` 三处，且旧存档需 remap。**改前必须评估三处**。

## C. UNKNOWN（证据不足，明确挂起）
1. ~~`arrival/*` 对 `game_state_manager.gd` 是真调用还是仅 preload 未用~~ → **P3-05 已核实：真调用**（`arrival_landing_scene.gd:53` change_state、`:333` change_state、`:440` serialize、`:465` deserialize）。RESOLVED。
2. `scripts/interaction_detector.gd` 外部无引用（仅 `interactable.gd` 与它互引），是否彻底 orphan —— 需确认。
3. `ArrivalLandingScene` → **P3-05 已核实：DEV_ONLY**（仅 `main.gd:3751`「Dev Only: Arrival Landing」按钮进入，正式抵达走 `ArrivalCinematicScene`）。`BaseInterior_Test.tscn` 仍无入口证据（见 SCENE_REGISTRY）。

## D. P3-05 Legacy 运行路径隔离（2026-07-12 · 基线 `0a1c1af`）

> 本轮**不删除** legacy、**不接入**正式基地 DoorStateManager、**不改** schema。只做隔离 + 命名去歧义 + 文档化。改动仅：局部节点名重命名 + 作用域注释 + 专项测试。

### D1. Legacy 运行路径清单

| 项目 | Arrival 原型 | Sandbox 沙盒 |
|---|---|---|
| Entry scene | `scenes/arrival/ArrivalLandingScene.tscn` | `scenes/main.tscn`（沙盒面板/Dev 菜单内） |
| Entry script | `scripts/arrival/arrival_landing_scene.gd` | `scripts/main.gd`（`_start_new_game` :2360） |
| Runtime purpose | prototype | sandbox (dev) |
| 入口 | **DEV_ONLY**：`main.gd:3751`「Dev Only: Arrival Landing」 | **DEV/沙盒**：沙盒 save_panel「新开局」(`:3134`) + Dev 菜单「Start Survival Sandbox」(`:3749`) |
| Local managers（局部节点） | GameStateManager/TimeManager/Camera/UI/Event/AudioFeedback/Audio/Lighting（均 `.new()` 子节点） | GameStateManager/TimeManager/Camera/UI/Event/Audio/SaveManager/AudioFeedback/RobotTask（均 `.new()` 子节点） |
| Formal autoload 访问 | **无**（完全 self-contained，零 `/root/*`） | 仅 **Dev 调试工具** 经 `/root/*Manager` 只读（`main.gd:3936+`）；沙盒玩法本体不碰 |
| Save file | `user://arrival_prototype_save.json`（`user://` 根） | `user://saves/slot_N.json`（`_save_path` :2536） |
| Restore path | `_load_arrival()`（仅自身文件） | `_load_game()`（仅自身 slot 文件） |
| Reachable from formal flow | 否（正式抵达走 ArrivalCinematicScene） | 否（正式新局走 `_start_application_flow`→ApplicationStartScene；正式续档走 FullSave/Training） |
| Status | LEGACY_PROTOTYPE / DEV_ONLY | LEGACY_PLAYABLE / DEV |
| Isolation action（本轮） | 局部节点名 → `ArrivalPrototype{Time,GameState}Manager`；save/`_setup` 加作用域注释 | 局部节点名 → `Sandbox{Time,GameState}Manager`；save/continue-fallback 加作用域注释 |
| Delete status | KEEP（DEV 原型，仍可运行） | KEEP（仍被引用，`docs/LEGACY_SANDBOX_PROTOTYPE.md` 记录） |

### D2. 局部 Manager 同名隔离
- **唯一真实撞名**：局部节点 `"TimeManager"` vs 正式 autoload `/root/TimeManager`（局部是实时沙盒钟 `scripts/time_manager.gd`；正式是行动制 `scripts/managers/TimeManager.gd`，不同脚本）。其余局部名（GameStateManager/Camera/UI/Event/Audio/SaveManager/RobotTask/Lighting）**均非 autoload**，不撞名。
- 处置：main.gd/arrival 的局部 `TimeManager`/`GameStateManager` 节点名分别改为 `Sandbox…`/`ArrivalPrototype…` 前缀。**安全依据**：两文件对这些管理器**只经成员变量**访问，全仓零 `get_node("TimeManager")`/`$TimeManager`/`%TimeManager` 名字路径查找（已 grep 证实），故改节点名不影响运行。正式 autoload 访问一律 `/root/…`，与局部彻底分离。

### D3. Legacy 存档隔离（验证结论，非本轮新造）
- 文件命名空间互不重叠：Full Save=`full_save.json`（FullSaveOrchestrator）／Training=`training_progress.json`／Sandbox=`slot_N.json`／Arrival=`arrival_prototype_save.json`／Legacy sprint06=`sprint06_progress.json`（只读 best-effort）。
- FullSaveOrchestrator **不读** arrival/sandbox 文件；`restore_full_save()` **拒绝** `legacy_source`（P3-03d，`full_save_orchestrator.gd:118-119`）。
- Sandbox/Arrival 存档**只写自身文件**、**只 (de)serialize 自身局部管理器**，从不写 `full_save.json`、从不碰 `/root/*Manager`（`main.gd:_save_game/_load_game`、`arrival:_save_arrival/_load_arrival`）。
- 正式续档 `_continue_mission`：FullSave→Training→（末位）legacy slot 回退。前两者为正式路径；legacy slot 仅在**无** FullSave/训练/申请档时的最后回退，正式流程**不依赖**它（已加注释标明）。

### D4. 本轮未处理（明确留后）
- legacy 文件物理删除、Inventory/Backpack/Storage 重构、DoorStateManager 正式基地接入、大脚本拆分（main.gd 5165 行属 Phase 4）、UNKNOWN #2 `interaction_detector` orphan、`BaseInterior_Test` 入口确认。
