# PROJECT_MAP · 项目入口与流程地图

> 治理审计初稿 · 只读结论 · 生成日期 2026-07-11
> 所有结论均基于 `project.godot` / 场景引用 / 代码调用，不凭文件名猜测。
> 证据格式：`文件:行号`。

## 0. 仓库与项目边界（先确认再谈流程）

| 项 | 结论 | 证据 |
|---|---|---|
| 唯一推荐 Git 仓库根 | `outputs/lunar_base_godot/` | 该目录 `.git` 有效，`origin=https://github.com/chinnseii/guanghan-outpost.git`，`branch main`，646 个跟踪文件 |
| 唯一推荐 Godot 项目根 | `outputs/lunar_base_godot/` | `project.godot` 唯一存在于此 |
| 其他 Git 痕迹 | 仓库树根 `wo-x/.git` 是**空壳**（只有 `info/exclude`，无 HEAD/objects/refs），由 claude-code-runtime 生成（`exclude` 首行 `# claude-code-runtime`） | `wo-x/.git/info/exclude` |
| Agent 误操作风险 | 若在 `wo-x/` 根运行 `git` 命令会 `fatal: not a git repository`（空壳无效）；必须 `git -C outputs/lunar_base_godot` 或先 `cd` 进项目根 | 实测 `git -C wo-x status` 报 fatal |
| 其他易混目录 | `wo-x/.agents`（空）、`wo-x/work`（空）、`wo-x/.codex/config.toml`（36B）、`wo-x/.claude`（本机 harness 配置） | 均非仓库根 |

**结论**：所有 Claude Code / Codex 的 Git 与 Godot 命令都必须在 `outputs/lunar_base_godot/` 执行。**本阶段不删除任何 `.git`**（空壳 `wo-x/.git` 的处置留待 CLEANUP_PLAN Phase 1 确认）。

## 1. 启动与主菜单

- **run/main_scene** = `res://scenes/main.tscn`（`project.godot:18`）
- `main.tscn` 只挂一个脚本 `scripts/main.gd`（`scenes/main.tscn:3-6`）
- `main.gd`（**5156 行**）身兼两职：
  1. **启动主菜单 + 流程路由器**（`_setup_main_menu()` `main.gd:3527`；`_ready` 调 `_setup_main_menu()` `main.gd:365`）
  2. **旧版生存沙盒本体**（种植/建造/资源/机器人，Sprint 01 原型，全部逻辑内联在本文件）

主菜单按钮（`main.gd:3582-3628`）：
- 「开始新驻留」→ `_start_application_flow()`（`main.gd:3582` → `4495`）→ 正式流程
- 「继续」ContinueButton → `TrainingManager.continue_scene_path()`（`main.gd:4509`）或 sprint06 存档
- 「开发入口 / Debug」→ `_toggle_dev_menu()`（`main.gd:3589`）→ Dev 菜单

## 2. 正式主线流程（主菜单可直达，无需 Dev）

顺序与"pre-09 flow audit"一致（`docs/archive/reviews/pre09_flow_audit.md`）。

| # | 流程段 | 起始场景 | 关键脚本 | 主要 Manager | 存档入口 | 切到下一段 | 当前可进入 |
|---|---|---|---|---|---|---|---|
| 1 | 申请表 | `scenes/application/ApplicationStartScene.tscn` | `application_flow_scene.gd` | AcademicBackgroundManager | `application_profile.json` (`application_flow_scene.gd:3`) | → TrainingStartScene (`:412`) | ✅ |
| 2 | 国家训练（小地图 hub） | `scenes/training/TrainingStartScene.tscn` → `TrainingBaseMap.tscn` | `training_start_scene.gd` / `training_base_map.gd` / `training_module_scene.gd` | TrainingManager / TrainingTimeManager / SuitManager / RepairManager / AirSystemManager 等 | `training_progress.json` (`training_manager.gd:4`) | 训练完成 → MissionAssignmentNotice (`training_base_map.gd:1319`) | ✅ |
| 2b | 训练模块 03：太阳能阵列（独立场景，从气闸外门进入） | `scenes/training/SolarArrayTrainingField.tscn` | `training_module_scene.gd` | RepairManager / SuitManager | 同训练存档 | 出口自动穿越回 hub | ✅ |
| 3 | 派遣通知书 | `scenes/training/MissionAssignmentNoticeScene.tscn` | `mission_assignment_notice_scene.gd` | TrainingManager | 同训练存档 | → 黑屏 (`opening_flow_manager.gd:12`) | ✅ |
| 4 | 派遣黑屏转场 | `scenes/training/AssignmentBlackScreenScene.tscn` | `assignment_black_screen_scene.gd` / `opening_flow_manager.gd` | — | — | → ArrivalCinematic (`opening_flow_manager.gd:28`) | ✅ |
| 5 | 月面抵达 / 看到地球 | `scenes/arrival/ArrivalCinematicScene.tscn`（另有 `ArrivalLandingScene.tscn`） | `arrival_cinematic_scene.gd` / `arrival_landing_scene.gd` | **遗留** game_state_manager/event_manager/audio_manager 等（沙盒基座） | `arrival_prototype_save.json`(`arrival_cinematic_scene.gd:3`) | → BaseAirlockEntry (`arrival_cinematic_scene.gd:141`) | ✅ |
| 6 | 旧基地气闸进入 | `scenes/base/BaseAirlockEntryScene.tscn` | `sprint06_base_scene.gd` | Base/Air/Water/Power/Health/Time/Supply/Repair… | `sprint06_progress.json` (`sprint06_base_scene.gd:3`) | 场景内推进 | ✅ |
| 7 | 旧基地内部 / 系统恢复 / 最后一株植物 | `OldBaseCore_ArtSlice.tscn` / `OldGreenhouseScene.tscn` | `sprint06_base_scene.gd`（10 场景共用） | PlantGrowthManager 等 | 同 sprint06 | → Day01End → Day02 → WeekRoutine | ✅ |
| 8 | Day01/Day02/第一周日常 | `Day01EndScene`/`Day02StartScene`/`Day02EndScene`/`WeekRoutineStartScene`/`WeekRoutineEndScene` | `sprint06_base_scene.gd` | 同上 | 同 sprint06 (`sprint06_base_scene.gd:1491/1511/1551`) | → Phase02 | ✅ |
| 9 | 第一周结束 / Phase 02 占位 | `scenes/base/Phase02PlaceholderScene.tscn` | `phase02_placeholder_scene.gd` | — | — | → 返回主菜单 (`phase02_placeholder_scene.gd:52`) | ✅（demo 终点） |

**退出/返回**：几乎所有正式场景都有「返回主菜单」按钮 → `res://scenes/main.tscn`（如 `training_base_map.gd:1796,1926`、`training_module_scene.gd:926,1156,2651`、`mission_assignment_notice_scene.gd:228`）。

## 3. 开发 / Debug 入口（Dev 菜单，仅 owner 用）

`_setup_dev_menu()`（`main.gd:3699`）注册大量「Dev Only」直达按钮（`main.gd:3733-3896`），可跳到任意单场景，包括：
- **Start Survival Sandbox** → `_start_new_game()`（`main.gd:3734`）= 进入旧沙盒玩法（见 §4）
- Arrival Cinematic / Landing、Lunar Surface (EVA seed)、Base Airlock、Old Base Interior、Old Base Art Slice、Old Greenhouse、Day01/02、Week Routine、Solar Array Exterior、Training Start、Training Module 01/03、Final Assessment、Mission Assignment 等

触发键：`new_game` 绑定 `F10`（`main.gd:382`）；Dev 菜单切换在 `_toggle_dev_menu`（README 提及 F12）。

## 4. 旧沙盒流程（LEGACY，已与主线断开）

- 入口：**仅** Dev 菜单「Start Survival Sandbox」→ `_start_new_game()`（`main.gd:2345`）
- 本体：`main.gd` 内联的种植/建造/资源结算/机器人/背包/科技系统（`resources`/`modules`/`collectables`/`robot_*` 等大量成员变量 `main.gd:75-341`）
- 支撑脚本（遗留基座）：`save_manager.gd` / `game_state_manager.gd` / `time_manager.gd`(小写沙盒版) / `camera_manager.gd` / `ui_manager.gd` / `event_manager.gd` / `audio_manager.gd` / `robot_task_manager.gd` / `module_visual.gd` / `collectable_visual.gd` / `asset_catalog.gd`
- 存档：`user://saves/save_N.json`（slot 制，`SAVE_SLOTS=3` `main.gd:8`，`_save_path(slot)`）
- 文档：`docs/LEGACY_SANDBOX_PROTOTYPE.md` 明确声明"与正式流程完全断开，只能 F12 进入"
- 退出：沙盒内 `lunar_surface_scene.gd:322` 等回 `main.tscn`

## 5. 月面地表 EVA（新播种，早期）

- 场景：`scenes/surface/LunarSurfaceScene.tscn`，脚本 `lunar_surface_scene.gd`（416 行）
- 入口：Dev 菜单「Lunar Surface (EVA seed)」（`main.gd:3737`）
- 状态：最新 commit `5e4b0cb "Lunar surface map seed: near-base EVA slice + scrollable dev menu"` 引入；`main.gd` 与 `lunar_surface_scene.gd` 目前**有未提交的工作区改动**（见 SHARED_FILE_REGISTRY / CLEANUP_PLAN Phase 0）。设计见 `docs/design/LUNAR_SURFACE_MAP.md`。

## 6. 流程切换机制小结

- 段间切换统一走 `get_tree().change_scene_to_file(...)`；训练 hub 内部房间用门 + `_switch_room()` 而非换场景（`training_base_map.gd:5,489,1027`）。
- 训练完成后目标场景由存档字段 `CurrentSceneAfterTraining` 决定，**不直接 `change_scene`**（`training_manager.gd:13`），并对已删除的旧模块场景做 `_remap_legacy_training_scene()` 兜底（见 LEGACY_REGISTRY）。

## 7. 未确认项

- `ArrivalCinematicScene` vs `ArrivalLandingScene`：两者都存在且都能到 BaseAirlock；正式流程默认走 Cinematic（`opening_flow_manager.gd:28`），Landing 疑似更早的抵达原型/Dev 专用，**证据不足以判定 Landing 是否仍在正式路径**，标 UNKNOWN，见 SCENE_REGISTRY。
