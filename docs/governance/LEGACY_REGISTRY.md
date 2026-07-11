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
1. `arrival/*` 对 `game_state_manager.gd` 是真调用还是仅 preload 未用 —— 未逐函数核实。
2. `scripts/interaction_detector.gd` 外部无引用（仅 `interactable.gd` 与它互引），是否彻底 orphan —— 需确认。
3. `ArrivalLandingScene` / `BaseInterior_Test.tscn` 是否仍在任何可达路径 —— 见 SCENE_REGISTRY。
