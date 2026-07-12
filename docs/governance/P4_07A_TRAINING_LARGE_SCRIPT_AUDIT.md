# P4-07A Training Large Script Audit

> P4-07A · 只读审计 + characterization · 2026-07-12 · 基线 `592b602`
> **零生产代码移动。** 证据用 `文件:行号`/方法/字段/计数。目标：判定唯一下一步（A/B/C/D）。

## 1. Scope
审计 `scripts/training/training_module_scene.gd`(3417) 与 `scripts/training/training_base_map.gd`(2255)；关联只读 `training_manager.gd`（static checkpoint API）、SuitManager/RepairManager/InventoryManager（`/root` 查询）。对应 `.tscn` 仅只读（两脚本 UI 全为动态 `add_child` 构建，不挂 .tscn 节点）。

## 2. File Size and Runtime Roles
| 文件 | 行 | funcs | 成员 var | 运行角色 | 挂载 |
|---|---:|---:|---:|---|---|
| `training_module_scene.gd` | 3417 | 133 | 40 | 单脚本驱动 6 个训练模块（含最终考核） | `SolarArrayTrainingField.tscn`/`FinalAssessmentScene.tscn` 等 |
| `training_base_map.gd` | 2255 | 125 | 45 | 训练 hub 多房间地图 | `TrainingBaseMap.tscn` |
- **关键共性**：两者 `$Node` 硬路径 = **0**、tween = **0**、UI 全动态 `add_child`（60 / 54）。→ UI 抽离**无需改 .tscn**（P4-04 模式适用）。

## 3. training_module_scene Responsibility Map
| 块 | 行号/方法 | 分类 |
|---|---|---|
| 生命周期/输入/移动 | `_ready`:727, `_process`:770, `_unhandled_input`:784, `_move_player`:1597, `_ensure_input_actions`:799 | KEEP（移动/输入主循环） |
| **UI 构建（chrome）** | `_build_screen`:833, `_build_training_overlays`:928, `_build_diagnosis_modal`:966, `_build_suit_status_panel`:973, `_build_briefing_modal`:1081, `_build_pause_panel`:1122, `_build_interaction_panel`:1159 | **UI_ONLY（动态创建，存 node 引用）** |
| **UI toggle/refresh/sync** | `_toggle_suit_status_panel`:1018, `_refresh_suit_status_panel`:1028, `_toggle_mission_panel`:1192, `_toggle_pause_menu`:1206, `_sync_overlay_visibility`:1218, `_update_hud`:2680, `_update_room_prompt`:2090 | DERIVED_UI（读 Manager/state 显示） |
| **UI→flow 按钮** | 页脚"保存训练进度"→`set_current_module`:925, `_on_confirm_suit_status_pressed`→`_complete_step`:1053, 确认弹窗 `_show_wear/return_suit_confirm_dialog`:2338/2374 | FLOW_COUPLED（按钮推进训练/写 checkpoint） |
| 房间/区域布局 | `_build_training_area`:1233 + 各 `_*_room_target`:1324-1516 | STATE/LAYOUT（模块特定几何，flow 耦合） |
| 步骤/交互状态机 | `_check_auto_steps`:1626, `_current_step`:1687, `_complete_step`:1693, `_try_interact`:1642, `_finish_module`:1923(→`mark_module_completed`) | STATE_MUTATION / TASK_ADVANCE |
| Manager/checkpoint | `TrainingManagerScript.set_current_module`:731/925, `.mark_module_completed`:1926；`_suit_manager`/`_repair_manager`/`_training_inventory_manager`（/root） | CHECKPOINT / MANAGER_ACCESS |
- 回答：UI 构建 ~500-600 行（含 chrome + modal shells），module/step 状态机 ~600+ 行，交互/移动 ~200 行，checkpoint 调用 3 处（731/925/1926）。只读 UI：`_refresh_suit_status_panel`（读 SuitManager + module_id）、`_update_hud`。按钮直接推进训练：页脚 checkpoint 按钮、suit 确认→`_complete_step`。可改 intent/callback：确认/checkpoint 按钮可注入 callback。

## 4. training_base_map Responsibility Map
| 块 | 行号/方法 | 分类 |
|---|---|---|
| 生命周期/输入/toast | `_ready`:125, `_process`:145, `_input`/`_unhandled_input`:182/187, `_show_toast`:158 | KEEP |
| 区域构建 + 门注册 | `_build_all_areas`:222, `_register_training_doors`:282, 门 helper:318-386 | SCENE_TREE_COUPLED + DoorStateManager |
| **导航/房间切换** | `_route_initial_area`:400, area configs:496-652, `_load_area`:652, `_switch_room`:691, `_try_pass_training_door`:713, `_check_door_crossing`:762 | SCENE_TREE_COUPLED（动态换房，非换场景） |
| **UI 构建（与 module_scene 平行但已分化）** | `_build_screen`:1706, `_build_training_overlays`:1800, `_build_briefing_modal`:1847, `_build_pause_panel`:1889, `_build_interaction_panel`:1929, `_build_diagnosis_modal`:1955, `_build_suit_status_panel`:1959 | UI_ONLY（动态） |
| UI toggle/refresh + modal | `_toggle_*`:1578-1633, `_refresh_suit_status_panel`:1599, `_show_*_modal`:1487-1571, `_sync_overlay_visibility`:1651, `_update_hud`:1668, `_update_room_prompt`:2119 | DERIVED_UI / FLOW_COUPLED |
| 步骤/交互 | `_complete_step`:999, `_on_area_task_complete`:1029, `_try_interact*`:828-950 | STATE_MUTATION |
- 回答：地图/房间/导航 ~700 行、UI ~500 行、训练状态 ~500 行。`_switch_room`/门/房间入口**强依赖 SceneTree**（`_load_area` 动态建/销毁房间节点）。中控室↔房间靠 `_switch_room`（换节点，非换场景）。直接处理任务状态（`_complete_step`/`_on_area_task_complete`）。持大量节点引用（45 成员 var）。有纯 room/entry mapping（area configs），但与 door/scene-tree 绑定。适合：抽 UI（与 module_scene 同款）；纯导航计算受 scene-tree 限制。

## 5. Shared State Matrix（高风险）
| Field | File | Writers | Readers | Groups | Saved | Risk |
|---|---|---|---|---|---|---|
| `module_id`/`module_data` | module | `_ready` | UI 构建/refresh/flow | UI+flow | checkpoint | HIGH_COUPLING |
| `step_index`/`completed`/current step | both | `_complete_step`/`_finish` | UI 可见性/interact/HUD | 状态机+UI | checkpoint | HIGH_COUPLING · ORDER_DEPENDENT |
| `suit_status_panel_visible` / overlay flags | both | toggle | `_sync_overlay_visibility`/build | UI | no | SCENE_LOCAL |
| ~29 UI node 引用（`objective_label`/`hud_label`/`suit_status_modal`/…） | both | build | update/toggle/refresh | UI | no | NODE_REFERENCE |
| `current_area`/room/door state | base_map | `_switch_room`/door | nav/interact | 导航 | (训练局部) | SCENE_TREE_COUPLED |
| input/sequence/interaction lock | both | flow | `_process`/input | 输入锁 | no | ORDER_DEPENDENT |
| training time / suit / temp inventory | both | flow | HUD/refresh | Manager | Training Checkpoint | MANAGER_CANONICAL（读为主） |
- **无 P0/P1 双持有**：训练进度 canonical 在 `training_progress.json`（TrainingManager，P3 定稿）；场景只在 checkpoint 点写（`set_current_module`/`mark_module_completed`）。UI 节点引用是 DERIVED_UI，不是第二份玩法状态。

## 6. SceneTree Coupling
| 指标 | module_scene | base_map |
|---|---:|---:|
| `$Node` 硬路径 | 0 | 0 |
| `%UniqueNode` | 39 | 17 |
| `get_node` | 40 | 24 |
| `add_child`（动态创建） | 60 | 54 |
| tween | 0 | 0 |
| await | 2 | 5 |
| `.connect(` | 21 | 17 |
| `change_scene_to_file` | 9 | 8 |
| TrainingManager 调用 | 18 | 20 |
- UI 全动态创建 → **presenter 可像 P4-04 一样由脚本动态创建、注入 UI 根/host、不改 .tscn**。`%UniqueNode`/`get_node` 主要指向 `/root/*Manager`（合法 autoload）与本地建的节点。`_switch_room`（base_map）动态建/销毁房间 → scene-ownership 敏感，机械搬移有风险。

## 7. TrainingManager and Checkpoint Boundaries
- Checkpoint 写点少而明确：module_scene `set_current_module`(731 `_ready` / 925 页脚按钮) + `mark_module_completed`(1926 `_finish_module`)；base_map 类似（`_on_area_task_complete`）。**UI 候选不承担 checkpoint**——页脚/确认按钮经 callback 表达 intent，checkpoint 调用留场景。
- 正式 **Full Save 不被训练脚本引用**（训练用 `training_progress.json`，非 `full_save.json`）——已核（本审计只见 `TrainingManagerScript.*`，无 `FullSaveOrchestrator`）。

## 8. UI-only Candidates
两脚本各有一套动态 UI chrome（背景/左面板/objective/hud/hint/log 标签 + minimal HUD + briefing/pause/interaction/diagnosis/suit modal）。module_scene 存 ~29 UI 节点引用于成员 var（`_build_screen` 等赋值）。这是 **P4-04 re-expose 模式**的直接候选：presenter 动态构建 + 回指场景 label var + 注入 UI-intent callback（确认/checkpoint 按钮）。**注意**：两脚本的 modal 已**分化**（`_build_briefing_modal` 非逐字相同），共享 presenter 需先对齐，风险更高。

## 9. Flow-coupled and Unsafe Areas
- module_scene：`_build_training_area` + 各 room_target（模块几何）、step 状态机、`_complete_step`/`_finish_module`、确认→`_complete_step`、`_move_player`、输入锁。
- base_map：`_switch_room`/`_load_area`/门注册/房间导航（SceneTree 动态建销）、`_on_area_task_complete`、门穿越。
- 均 order/scene-tree/checkpoint 耦合 → KEEP。

## 10. Extraction Candidate Cards

### Candidate: TrainingModuleScreenPresenter (module_scene) — 推荐 CHARACTERIZE_FIRST → EXTRACT
- Source: `training_module_scene.gd` §UI 构建 + toggle/refresh/sync
- Source methods: `_build_screen`(chrome 部分)/`_build_training_overlays`/`_build_briefing_modal`/`_build_pause_panel`/`_build_interaction_panel`/`_build_diagnosis_modal`/`_build_suit_status_panel` + `_toggle_*`/`_refresh_suit_status_panel`/`_sync_overlay_visibility`
- Approx lines: ~350-500 · Expected reduction: ~300-400
- Responsibility: 动态构建训练屏 UI + toggle/refresh；持 UI 节点引用
- Inputs: host（UI 根 add_child）、module_data、SuitManager（refresh）、UI-intent callbacks（save-progress / suit-confirm / pause / mission-toggle）
- Outputs: 构建的节点（re-expose 给场景 label var）
- UI nodes: ~29 · Writes gameplay state: **否**（confirm/checkpoint 经 callback） · Async: 无 · Scene resource changes: **无**（动态）
- Extraction risk: **MEDIUM**（tier-1、按钮 flow-wired、`_build_training_area` 布局须留场景、modal 初值读 `completed`/step）
- Test strategy: characterization（build_ui 动态实例化 + 节点存在 + toggle + refresh 文本 + 静态边界 presenter 不写 checkpoint/step）
- Recommendation: **CHARACTERIZE_FIRST**（P4-07B 抽此，先补 characterization，用注入 callback，不移 `_build_training_area`/状态机）

### Candidate: TrainingBaseScreenPresenter (base_map) — DEFER
- 与上同款 UI，但与 `_switch_room`/房间导航交织，且两脚本 modal 已分化。Extraction risk: MEDIUM-HIGH。Recommendation: **DEFER**（待 module 版 presenter 稳定后，再评估共享/复用）。

### Candidate: TrainingRoomNavigation (base_map) — KEEP
- `_switch_room`/`_load_area`/门注册/房间导航。强 SceneTree 动态建销 + DoorState。Extraction risk: HIGH。Recommendation: **KEEP**。

### Candidate: TrainingModuleLayoutBuilder (`_build_training_area` + room_target) — DEFER
- 模块特定几何 + 交互目标定义，与 step/flow 绑定。Extraction risk: HIGH。Recommendation: **DEFER**。

## 11. Test Protection
`tests/p4_07a_training_large_script_audit_test.gd`（源码分析，**不启动训练/基地场景**）：文件存在/行数级别、核心方法存在、checkpoint 调用位置锁定（`set_current_module`/`mark_module_completed` 仍在场景）、UI/flow 边界样本（UI-only build vs flow-coupled confirm vs state mutation vs 移动/输入锁）、SceneTree（无 `$`、无 tween、动态 add_child、无 `.tscn` 依赖）、存档安全（不写 training_progress/full_save/slot；SHA 前后一致）。

## 12. Unique P4-07B Recommendation
**唯一结论：A — EXTRACT_TRAINING_MODULE_UI。**
- 文件：`scripts/training/training_module_scene.gd`。
- 方法：UI chrome 构建（`_build_screen` chrome + `_build_training_overlays` + 4 modal shells + `_build_suit_status_panel`）+ `_toggle_*`/`_refresh_suit_status_panel`/`_sync_overlay_visibility` → 新 `scripts/controllers/training_module_screen_presenter.gd`（非 Autoload，P4-04 re-expose + 注入 UI-intent callback）。
- 预计减少：~300-400 行。新文件：presenter + test。
- 风险：MEDIUM（tier-1、flow-wired 按钮、modal 读 step/`completed`）→ **P4-07B 必须先 characterize，再抽；用注入 callback 表达 save-progress/suit-confirm/pause intent；不移 `_build_training_area`/状态机/`_complete_step`/checkpoint**。
- 不触碰：`_build_training_area`、room_target、step 状态机、`_complete_step`/`_finish_module`、checkpoint（`set_current_module`/`mark_module_completed`）、移动/输入锁、base_map。
- 为何非 B/C/D：B（base_map UI）与房间导航交织且已分化，风险更高（DEFER）；C 未见如 sprint06 schedule 那样干净的纯 evaluator（训练文本多依赖 Manager/step）；D 尚早——存在明确 ~350-500 行动态 UI chrome 可按 P4-04 模式安全抽（无需改 .tscn）。

## 13. Phase 4 Closure Implications
- 若 P4-07B（training module UI）完成后，训练两脚本仍余：状态机 + 房间导航（base_map）+ 布局，均 scene-tree/flow/checkpoint 强耦合 → 那时应 **CLOSE_PHASE_4**（剩余不值得高风险拆分）。
- 无 P0/P1；训练进度 canonical 边界（P3 定稿）未受影响。

## P4-07B Completion Note (2026-07-12)

- **DONE**: extracted `TrainingModuleScreenPresenter` from `training_module_scene.gd` into `scripts/controllers/training_module_screen_presenter.gd` (`class_name`, RefCounted, non-Autoload).
- `training_module_scene.gd` **3417 -> 3114 (net -303)**. The reduction lands within the lower edge of the P4-07A estimate while preserving flow boundaries.
- Moved display-only screen chrome: left mission panel labels, footer buttons, minimal HUD, briefing/pause/interaction panels, popup shell ownership, suit-status panel display, entry-blocked briefing UI, overlay visibility, HUD label assignment, and interaction progress display.
- Kept in scene: `_build_training_area`, room targets/layout, movement/input locks, `step_index`/`completed` state, `_complete_step`, `_finish_module`, `TrainingManagerScript.set_current_module`, `TrainingManagerScript.mark_module_completed`, and all diagnosis/repair option correctness decisions.
- Scope adjustment from the generated instruction: option dialogs that decide correctness and call `_complete_step()` remain in the scene. The presenter owns the popup container API only; it does not own answers, checkpoints, scene changes, or step advancement.
- `training_base_map.gd`, scenes, `project.godot`, Full Save schema, Training Checkpoint schema, and gameplay values were not changed.
- Verification: Godot editor/smoke EXIT 0; P4-07B 20/20; P4-07A 32/32; P4-06B 41/41; P4-06A 28/28; P4-05 30/30; P4-04 35/35; P4-03 27/27; P4-02 22/22; P3-03a 40/40; P3-03b 50/50; P3-03c 34/34; P3-03d 25/25; P3-04 33/33; P3-05 37/37.
- Closure implication remains: after P4-07B, remaining training-script bulk is scene-tree/flow/checkpoint coupled. Recommend Phase 4 close-out rather than starting P4-08 automatically.
