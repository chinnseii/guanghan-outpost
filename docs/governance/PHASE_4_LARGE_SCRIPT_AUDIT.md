# Phase 4 Large Script Audit

> P4-01 · 只读审计与拆分计划 · 2026-07-12 · 基线 `1f53659`（Phase 3 已推送 + tag `system-boundary-cleanup-complete-2026-07-12`；main == origin/main）
> **本轮零代码改动**：只读代码、产出计划。证据用 `文件:行号`/方法/字段。**"缩短行数"不是目标，"职责边界"才是。**

## 1. Scope
审计超大脚本的职责块、依赖与共享可变状态、可安全抽离的边界、不可拆区域、测试保护需求，并给出 Phase 4 拆分顺序与**唯一的 P4-02 推荐**。不拆代码、不新建 controller、不改场景/存档/信号/节点路径。

## 2. Script Size Inventory（`wc -l`，2026-07-12）
scripts/ 全量 29,739 行。Top：`main.gd` 5182 · `training/training_module_scene.gd` 3417 · `base/sprint06_base_scene.gd` 2556 · `training/training_base_map.gd` 2255 · `data/ItemDatabase.gd` 859 · `application/application_flow_scene.gd` 811 · `managers/AirSystemManager.gd` 610 · `systems/PlantGrowthManager.gd` 609 · `training/training_manager.gd` 591 · `managers/SupplyManager.gd` 584。

## 3. Oversized Script Ranking（按 P0/P1/P2/P3 标准）
- **P0 (≥4000)**：`main.gd` (5182) — Phase 4 首要对象。
- **P1 (2000–3999)**：`training_module_scene.gd` (3417)、`sprint06_base_scene.gd` (2556)、`training_base_map.gd` (2255)。
- **P2 (1000–1999)**：**无**。
- **P3 (600–999)，仅关键**：`application_flow_scene.gd` (811, 正式申请流程)、`training_manager.gd` (591, 全局 checkpoint/路由——虽短但关键)。`ItemDatabase.gd`(859) 等数据库=纯数据，天然大，**不拆**。Manager (400–610) 单一职责，**不在 Phase 4 范围**。
- **修正 GPT 指令**：原指令点名 sprint06 + training_manager，但实测 `training_module_scene.gd`(3417) 与 `training_base_map.gd`(2255) 才是更大的 P1。本审计覆盖全部 P0+P1。

## 4. main.gd Responsibility Map（5182 行 · 333 funcs · 90 成员变量 · 15 个 /root Manager）
运行角色 = **正式主菜单 + Legacy 沙盒 root + Dev hub 的混装**（`extends Node2D`，`scenes/main.tscn`）。

| # | 职责块 | 行号/方法证据 | 运行角色 |
|---|---|---|---|
| B1 | 生命周期/输入/绘制 | `_ready`:359, `_process`:525, `_unhandled_input`:553, `_draw`:589 | mixed |
| B2 | **Legacy 局部 manager 创建** | `_setup_audio`:910（建 Sandbox* 节点）, `_setup_entity_root`:887 | legacy |
| B3 | 沙盒机器人 AI | `_process_robot_queue`:608 … `_skip_robot_task`:765 | legacy |
| B4 | 沙盒 tilemap/渲染 | `_setup_moon_tile_map`:1033, `_paint_*`:1110-1117, `_draw_*`:1132-1259 | legacy |
| B5 | 沙盒交互/设施 | `_find_interaction`:1269, `_interact`:1355, `_use_*`:1418-1592, build:1609 | legacy |
| B6 | 沙盒移动/碰撞/建造几何 | `_can_player_move_to`:2681 … `_rects_touch`:2869 | legacy(纯逻辑) |
| B7 | **沙盒槽位存档** | `_save_game`:2250, `_load_game`:2316, `_apply_save_data`, `_serialize_*`:2460-2528, `_save_path`:2549 | legacy(save) |
| B8 | 值类型/字典工具 | `_vector2_to_dict`:2580 … `_copy_bool_dictionary`:2613 | 纯静态工具 |
| B9 | 沙盒 UI 构建 | `_setup_ui`:2876, `_make_*_panel`:3165-3213, 任务日志/目标追踪:3269-3469, 面板文本:3475-3542 | legacy(UI) |
| B10 | **主菜单构建** | `_setup_main_menu`:3542, `_make_title_button`:3647, `_refresh_main_menu`:5141 | 正式(UI) |
| B11 | **Dev 工具**（菜单+调试动作） | `_dev_add`:3660, `_setup_dev_menu`:3714, `_make_dev_button`:3941, **~150 个 `_debug_*`:3948-4499** | **dev-only** |
| B12 | **正式流程路由** | `_start_application_flow`:4510, `_start_clean_new_stay`:4516, `_continue_mission`:4521, `_has_*_progress`:4546-4566, `_clear/_reset_demo_progress`:4595-4606, `_show_new_game_confirmation`:4613 | **正式(route+restore)** |
| B13 | 沙盒 HUD/状态/目标文本 | `_update_ui`:4715 … `add_log`:5169 | legacy(UI) |

回答关键问题：
1. main.gd = **混合**（正式主菜单 B10 + 正式路由 B12 + Dev hub B11 + Legacy 沙盒本体 B1-B9,B13）。
2. 正式职责：B10 主菜单、B12 正式路由（→ FullSaveOrchestrator/TrainingManager/ApplicationStartScene）。
3. legacy/dev 职责：B2-B9,B13（沙盒）、B11（dev）。
4. 可独立抽离：**B11（Dev 工具）** 最独立（dev-only、对沙盒玩法字段零写、只调 `/root/*Manager` debug API + `add_log`）；B8（纯工具）；B12（小而边界清晰但触正式 restore）。
5. 依赖大量共享字段：B7 沙盒存档（读写 20+ 沙盒字段）、B9/B13 UI（读大量沙盒状态）。
6. 可机械搬移：B11、B8。
7. 需先引接口：B7（需先聚合沙盒状态结构）、B9/B13。
8. 等 Phase 5/6：整个沙盒本体的场景化（B3-B6）属大工程。

## 5. sprint06_base_scene.gd Responsibility Map（2556 · 159 funcs · 12 Manager）
10 个正式 base 场景共用的场景驱动（`SCENE_REGISTRY §B3`，tier-1）。
- **场景/道具/美术初始化**：`_setup_modular_props`:140, `_setup_art_slice_*`:166-197, `_tile_floor/_tile_wall`:235-252, `_setup_old_base/greenhouse/solar_props`:273-306。
- **UI/HUD 面板层（大块，高内聚）**：`_setup_ui`:325, ~14 组 `_setup_*_panel`/`_toggle_*_panel`（base status/plant/air/power/water/inventory/backpack-storage/suit）:420-538, `_setup_plant_diagnosis_ui`:538。
- **场景控制/移动**：`_setup_scene_defaults`:603, `_start_scene`:633, `_process`:646, `_move_player`:684, `_update_target`:719。
- **任务/日程流程**：day02/week routine:746-756, `_daily_checks_complete`:771, `_complete_daily_check`:777, `_day02_inspections_complete`:840。
- **Full Save 调用**：`restore_full_save(self)` @ :2438（唯一正式恢复入口之一）。
回答：场景控制(B)/任务流程(day/week)/UI(面板层)/save orchestration(:2438)/设备交互 各自成块；scene-local 状态 vs Manager-owned 状态需逐字段核（P3 已把核心域归 Manager）；Phase 3 过渡 glue 主要在 save 调用处（已收敛）。

## 6. training_module_scene.gd + training_base_map.gd（P1）
- **`training_module_scene.gd`(3417)**：驱动 6 训练模块。块：UI 构建（`_build_screen`:833, overlays/modal/panel:928-1233 — 最大块）、房间布局（`_build_training_area`:1233, 各 `_*_room_target`:1324-1516）、步骤/交互流（`_complete_step`:1693, `_finish_module`:1923）、manager helpers。
- **`training_base_map.gd`(2255)**：训练 hub 多房间。块：区域构建+门注册（`_build_all_areas`:222, `_register_training_doors`:282）、导航（`_route_initial_area`:400, area configs:496-652, `_switch_room`:691, `_try_pass_training_door`:713）、步骤/交互流（`_complete_step`:999, `_on_area_task_complete`:1029）。
- 共同模式：**UI 构建 + 导航/区域 + 步骤流 + 时间/manager helper** 混在一脚本 → 与 sprint06 同构，最自然的边界是 **UI/HUD 表现层 与 流程/导航逻辑 分离**。

## 7. training_manager.gd 评估（591，是否 Phase 4 拆）
- 现状（P3-03 已清边界）：`_read_progress_data`(只读)/`load_progress`(恢复)/`finalize_restore`/`read_progress`/`save_progress`/`reset_progress` + 模块路由 `set_current_module`/`mark_module_completed` + 场景 remap `_remap_legacy_training_scene` + 静态常量。
- 已因 P3-03a/d 清晰：read vs restore API 边界、finalize、checkpoint 作用域。
- 可抽出：checkpoint 文件 IO（`_read_progress_data`/`save_progress`）与 flow/路由分离为 `TrainingCheckpointIO` + `TrainingFlow`。
- **判断：Phase 4 不优先**。591 行、单一 static 工具、职责已收敛、且拆分会动 checkpoint API（P3-03 刚定稿，风险/收益不划算）。**保留到 main/sprint06 之后**（若拆，属靠后批次）。

## 8. Dependency Matrix（大脚本 × 边类型）
| 脚本 | 行 | /root Manager 数 | 主要出边类型 | fan-in（外部依赖其方法） | 分类 |
|---|---|---|---|---|---|
| main.gd | 5182 | 15 | AUTOLOAD_LOOKUP, SCENE_NODE_PATH(`$UI/...`), SHARED_FIELD(90 vars), FILE_IO(slot), STATIC_CALL(FullSave/Training) | 低（是 root 场景，几乎无人调它） | HIGH_FAN_OUT · SHARED_MUTABLE_STATE · SCENE_TREE_COUPLED |
| sprint06_base_scene.gd | 2556 | 12 | AUTOLOAD_LOOKUP, SCENE_NODE_PATH, STATIC_CALL(restore_full_save), SIGNAL | 低（10 场景挂它，但无脚本调其方法） | HIGH_FAN_OUT · SCENE_TREE_COUPLED |
| training_module_scene.gd | 3417 | 9 | AUTOLOAD_LOOKUP, SCENE_NODE_PATH, STATIC_CALL(TrainingManager) | 低 | SCENE_TREE_COUPLED |
| training_base_map.gd | 2255 | 10 | AUTOLOAD_LOOKUP(含 DoorStateManager), SCENE_NODE_PATH, STATIC_CALL | 低 | SCENE_TREE_COUPLED |
| training_manager.gd | 591 | 13 | STATIC_CALL, FILE_IO, AUTOLOAD_LOOKUP | **高**（main + 多训练场景 + TaskManager 调其 static API） | STATIC_UTILITY · HIGH_FAN_IN · FILE_IO_COUPLED |
- 关键：4 个大场景脚本都是 **HIGH_FAN_OUT + SCENE_TREE_COUPLED**、fan-in 低（利于拆——改它们不波及外部调用者）。`training_manager` 反之是 HIGH_FAN_IN 的 static hub（拆它会波及 API，故靠后）。

## 9. Shared State Hotspots
- **main.gd 90 个成员变量**同时服务沙盒玩法/UI 节点引用/机器人/建造/补给/HUD/菜单——`_update_ui`(4715)、`_save_game`(2250)、`_draw`(589) 各读数十字段。UI 节点引用（`$UI/...` 经 `has_node`）与业务状态混存。
- 高风险字段（示例）：`game_state_manager`/`time_manager`/…（Sandbox* 局部 manager，B2 建、B3-B13 用）、`current_save_slot`（B7/B12）、`day`/`resources`/`backpack`/`modules`/`collectables`（B3-B9,B13 多处读写）。
- **B11 Dev 工具是少数低共享块**：`_debug_*` 主要经 `/root/*Manager` + `add_log`，几乎不碰上述沙盒字段 → 抽离影响面小。
- **B12 正式路由**共享 `current_save_slot`/`_load_game`/`add_log`/`_refresh_main_menu` 若干，但数量有限（<10）。
- 规则：若候选需共享 20+ 字段才能拆，标 **NOT_READY**（B7 沙盒存档即属此）。

## 10. Extraction Candidates（卡片）

### Candidate: DevToolsController（main.gd B11）— 推荐首拆
- Source: `scripts/main.gd` B11
- Responsibility: Dev 菜单构建 + ~150 个 `_debug_*` 调试动作（对正式 `/root/*Manager` 的开发期操作）
- Approx lines: ~840（`_dev_add`:3660 → `_toggle_dev_menu`:4499）
- Inputs: host 引用（`add_log`/UI 刷新）、`/root/*Manager`（运行时 lookup）
- Outputs: 日志、manager debug 状态
- Required deps: `/root/*Manager` autoloads、`TrainingManager` static、host 的 `add_log`
- Owned state: 无独立业务状态（仅菜单节点）
- Signals: 无
- Public API: `build_dev_menu(host)` / 保留各 debug 动作
- Extraction difficulty: **LOW-MEDIUM**（数量多但机械、几乎纯 relocation）
- Regression risk: **对正式玩法/存档 = 无**（dev-only，从不被正式流程调用）
- Test protection: 现无 → 需补 characterization（editor parse + dev 工具实例化 + 抽样 debug 调用不崩）
- Can be first: **YES**
- Blocking issues: 无（需迁移 dev-menu 按钮 wiring）
- Recommended phase: **P4-02**

### Candidate: SandboxSlotSaveController（main.gd B7）
- lines ~310；难度 HIGH（读写 20+ 沙盒字段）；风险 MEDIUM（legacy save）；测试无 → **NOT_READY**，需先聚合沙盒状态结构。Recommended: 靠后。

### Candidate: FormalFlowRouter（main.gd B12）
- lines ~100；难度 LOW；**但触正式 restore（`restore_full_save`/`continue_scene_path`）**；有 P3-05 静态测试**部分**守护（断言 `_continue_mission` 用 restore_full_save/read_progress）。风险 MEDIUM（正式 continue 是不能坏的路径）。Recommended: **P4-03**（在 DevTools 上验证抽离手法后再动正式路由；拆时同步更新 P3-05 测试断言路径）。

### Candidate: BaseHudPanelPresenter（sprint06 UI 面板层）
- lines ~280（`_setup_ui`:325 → `_setup_plant_diagnosis_ui`:538 的 setup/toggle 面板组）；难度 MEDIUM（scene-node 构建）；风险 MEDIUM（tier-1 正式场景）；测试无 → 需 UI 存在性 characterization。Recommended: P4 中段（sprint06 首拆）。

### Candidate: BaseNavigation / DailyMissionFlow（sprint06）
- 导航（`_move_player`/`_update_target`/`_switch`）与 day/week 流程（`_daily_checks_*`）各成块；难度 MEDIUM-HIGH（scene-tree + 任务流）；Recommended: sprint06 UI 拆稳后。

### Candidate: TrainingUIBuilder（training_module_scene / training_base_map）
- 两脚本的 `_build_*`/panel/overlay UI 块；难度 MEDIUM；Recommended: 各自 UI 层先于流程层。

## 11. Unsafe-to-Split Areas（本阶段不动）
- main.gd 沙盒本体 B3-B6,B9,B13（90 共享字段、执行顺序耦合、无测试）；B7 沙盒存档（20+ 字段）。
- sprint06 的 Full Save 调用点（P3 刚定稿，勿动 save/restore 顺序）。
- `training_manager` checkpoint API（HIGH_FAN_IN，改动波及多调用者）。
- 任何需要改 `.tscn` 节点路径 / 新建 Autoload / 改存档 schema 的抽离。

## 12. P4-02 Recommendation（唯一）
**P4-02 = 从 `main.gd` 抽出 `DevToolsController`（B11：dev 菜单 + 全部 `_debug_*`）。**
- 为什么最安全：**dev-only**，正式玩家流程从不调用 → 不可能改变玩家体验、存档或恢复（直接满足硬停条件"不改 save/restore、不改玩家体验"）；对沙盒玩法字段零写、只经 `/root/*Manager` debug API + `add_log`，共享状态最低；~150 个函数彼此独立、近乎纯 relocation、可独立 revert。
- 为什么不是 FormalFlowRouter（GPT 示例的 P4-02）：它协调**正式 continue/new-game/full-restore**，是"不能坏"的路径，且指令自身的"延后：涉及正式 save/restore"规则就把它排后——放 **P4-03**，等抽离手法在 inert 的 DevTools 上验证过再动。
- 为什么不是 SandboxSlotSaveController：需共享 20+ 沙盒字段 → NOT_READY。
- 预计减少：`main.gd` **约 840 行（~16%）**。
- 新增文件：`scripts/dev/dev_tools_controller.gd`(+`.uid`)（挂为 main 的子节点，持 host 引用）。
- 修改调用点：`_setup_dev_menu` 的按钮 wiring 随函数迁移；main 保留一个 `_build_dev_menu()` 委托入口（或在 `_ready` 实例化 controller）。
- 不改：正式路由 B12、沙盒玩法、存档、场景资源、`project.godot`、任何 Manager。
- 需要测试：editor parse + smoke（已有）+ 新增 `tests/p4_02_dev_tools_extraction_test.gd`（controller 实例化、抽样 debug 动作不崩、main 不再内联 `_debug_*` 主体、dev 菜单仍可构建）。
- 回滚：单 commit、独立 revert；原可先留 wrapper。
- 证明行为不变：dev 菜单仍构建、抽样 debug 动作产生相同 manager 效果 + 日志；正式 Phase 3 测试（216）全绿不受影响；editor/smoke EXIT 0。

（不存在"无安全候选"的情况；`NO_SAFE_EXTRACTION_YET` **不适用**。）

## 13. Recommended Sequence（基于实际代码，非照抄示例）
| 批次 | 目标 | 预计文件 | 风险 | 测试 | 回滚 | 并行? | Owner | 需用户决策? |
|---|---|---|---|---|---|---|---|---|
| **P4-02** | main.gd → DevToolsController | +`scripts/dev/dev_tools_controller.gd`,`main.gd`,+test | LOW | p4_02 + editor/smoke + Phase3 回归 | 单 commit revert | 否 | Claude | 否 |
| P4-03 | main.gd → FormalFlowRouter | `main.gd`,+router,+test,更新 p3_05 断言 | MEDIUM | p4_03 + p3_05 + smoke | 单 commit | 否（依赖 P4-02 手法） | Claude | 否 |
| P4-04 | main.gd → SandboxState 聚合 + SandboxSlotSaveController | `main.gd`,+sandbox_save | MEDIUM-HIGH | p4_04 slot round-trip | 单 commit | 否 | Claude | 是（沙盒是否值得投入） |
| P4-05 | sprint06 → BaseHudPanelPresenter | `sprint06_base_scene.gd`,+presenter | MEDIUM | UI 存在性 characterization + smoke | 单 commit | 与 main 批次可并行（不同文件） | Claude | 否 |
| P4-06 | sprint06 → BaseNavigation / DailyMissionFlow | `sprint06_base_scene.gd`,+controllers | MEDIUM-HIGH | 正式 base 链路回归 | 单 commit | 否 | Claude | 否 |
| P4-07 | training_module_scene / training_base_map → TrainingUIBuilder | 两脚本,+builder | MEDIUM | 训练链路 + Phase3 回归 | 单 commit | 与 sprint06 批次可并行 | Claude | 否 |
| P4-08 | (可选) training_manager → CheckpointIO/Flow | `training_manager.gd`,+io | MEDIUM（HIGH_FAN_IN） | 全 Phase3 checkpoint 回归 | 单 commit | 否 | Claude | 是（是否动 P3 刚定稿的 API） |
| P4-09 | Phase 4 回归与收口 | docs | — | 全量 | — | — | Claude | — |
- 并行性：main.gd 批次（P4-02/03/04）与 sprint06/training 批次（P4-05/06/07）**改不同文件**，理论可并行；但同一 owner 串行更稳，建议串行。

## 14. Test Protection Plan
| 候选 | 已有测试 | 缺失 | 拆前必补 | 拆后必跑 |
|---|---|---|---|---|
| DevToolsController | 无（仅 editor parse 覆盖语法） | 行为特征测试 | `p4_02`：controller 实例化、抽样 debug 调用不崩、main 无内联 `_debug_*`、dev 菜单可建 | p4_02 + editor/smoke + Phase3 216 全量 |
| FormalFlowRouter | **部分**（p3_05 断言 `_continue_mission` 用 restore_full_save/read_progress） | 路由分支测试 | `p4_03` + 迁移 p3_05 断言到新文件 | p4_03 + p3_05 + p3_03b + smoke |
| sprint06 面板/导航 | 无 | UI 存在性 + 导航 characterization | 对应 characterization | 该 test + p3_03d/p3_04 + smoke |
- 复用：P3-03a/b/c/d(147)、P3-04(33)、P3-05(36)、editor/smoke —— 每批必须保持全绿。新增测试**本轮只规划、不实现**。

## 15. Phase 4 Rules（统一拆分规则）
1) 一次只拆一个职责块；2) 不同时改玩法；3) 不同时改 UI 设计；4) 不改存档 schema；5) 不改场景资源；6) 每批一个 commit；7) 每批可独立 revert；8) 原方法可先留 wrapper；9) 先抽纯逻辑再抽 scene-tree 强耦合；10) 不新建 Autoload（除非另批准——controller 用普通子节点/RefCounted）；11) 不在 Phase 4 顺手删 legacy；12) 目标是职责边界，不是单纯缩行。

## 16. Risks
- **P0**：无。
- **P1**：拆分破坏 `$`/`get_node` 场景节点路径；生命周期函数（`_ready`/`_process`/`_unhandled_input`）顺序/归属变化；save/restore 调用顺序被无意改动（尤其 P4-03/04）。
- **P2**：信号连接重复/丢失（dev 按钮 wiring）；状态在 main 与新 controller 间双持有；wrapper 与新实现不同步；输入被 main 与 controller 重复处理。
- **P3**：debug/legacy/formal 路由串线；测试覆盖不足（多数大块无专项测试 → 拆前先补 characterization）。
- 本轮只建立基线，不关闭风险。

## P4-02 Completion Note (2026-07-12)

- **DONE**: extracted `DevToolsController` from `main.gd` → `scripts/controllers/dev_tools_controller.gd` (876 lines). `main.gd` **5182 → 4346 (−836 / ~16%)**. Diff: 14 insertions / 850 deletions in `main.gd`, no EOL churn.
- **Moved (90 funcs)**: the dev-menu builder (`build_menu` [was `_setup_dev_menu`], `_dev_add`, `_dev_group_name_for`, `_dev_group_content`, `_make_dev_button`) + all `_debug_*` actions. Controller `extends Node`, created/held by `main.gd`, **not** an Autoload (`/root/DevToolsController` absent).
- **Dependency injection**: `setup(host, menu_parent)` — `host`=main (for `add_log` forwarder, `_refresh_main_menu` forwarder, and 5 shared formal callbacks wired via `Callable(_host, ...)`: `_reset_demo_progress_from_dev`, `_start_new_game`, `_start_day07_report_test`, `_debug_reset_time`, `_clear_current_save`); `menu_parent`=main's `$UI/Root`. Managers reached via `/root/*Manager` lookups (dev tools inherently operate on live autoloads). No canonical state copied.
- **Kept in main (SHARED_HELPER)**: `_debug_reset_time` (called by formal `_start_clean_new_stay`/`_reset_demo_progress_from_dev`) — so the formal flow never depends on the controller. Thin `_toggle_dev_menu` wrapper retained (delegates to controller; preserves F12 + title-button call sites unchanged).
- **Formal isolation verified**: formal continue/new-game/Full Save/training/sandbox/arrival paths unchanged; controller is not a dependency of any of them.
- **Test**: `tests/p4_02_dev_tools_controller_test.gd` (22/22) — instantiation/non-autoload, menu builds (171 buttons), toggle, a sampled Power debug action (with file self-restore), and main.gd static boundary (only `_debug_reset_time` remains; formal router + `restore_full_save` + sandbox save untouched).
- **Verification**: Godot editor/smoke EXIT 0; P4-02 22/22; P3-03a 39/39, P3-03b 50/50, P3-03c 33/33, P3-03d 25/25, P3-04 33/33, P3-05 36/36; real saves SHA-256 unchanged.
- **Next: P4-03 — extract `FormalFlowRouter` from `main.gd`** (formal continue/new-game routing; MEDIUM risk — touches formal restore, so migrate the P3-05 static assertions to the new file). The extraction pattern is now proven on the inert DevTools block.

## 附：验收标准（本轮 P4-01）
所有 P0+P1 脚本已清点并映射职责块（附行号）✓；依赖/共享状态热点已识别 ✓；抽离候选有边界卡片（main/sprint06 各 ≥3）✓；不可拆区域已列 ✓；测试保护需求已定义 ✓；分阶段拆分顺序 + 唯一 P4-02 推荐 ✓；**零生产代码改动** ✓。
