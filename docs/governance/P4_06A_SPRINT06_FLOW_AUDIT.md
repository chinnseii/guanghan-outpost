# P4-06A Sprint06 Flow Audit

> P4-06A · 只读审计 + characterization · 2026-07-12 · 基线 `bda3d13`
> **零生产流程代码移动。** 证据用 `文件:行号`/方法/字段。目标：判定 P4-06B 唯一下一步（A/B/C）。

## 1. Scope
审计 `scripts/base/sprint06_base_scene.gd`（2307 行）的日程检查、日常任务、周例行、任务阶段推进、场景切换触发与相关 scene-local 状态；关联只读 `full_save_orchestrator.gd`、`TimeManager`。**不扩大到无直接调用关系的系统**（sprint06 的任务进度不经 TaskManager——见 §5）。

## 2. Runtime Execution Order（实测）
```
_process(delta)                     # 每帧
  → _move_player(delta)             # 移动主循环（推进 movement/mission time）
  → _update_target()                # 委托 BaseNavigationController，写 current_target
  → _update_ui()                    # HUD 文本 + _hud.refresh_open_panels()
_unhandled_input(交互键)
  → _interact()                     # 守卫 sequence_running（首行）→ 按 scene_kind + 日程谓词分派
     → _interact_{interior|greenhouse|week_*|day02_*}()   # 读 current_target
        → _complete_daily_check(key,text) / _complete_day02_check(...)
           → 前置门禁（必须先 DailyConsoleChecked）
           → _begin_equipment_interaction(kind, target, ..., after)   # ASYNC
              → 设 interaction_running/sequence_running/input_enabled + 交互 UI
              → [duration 后] 应用 updates 到 state + 执行 after 回调
                 → after 写 state["DailyInspectionsComplete"] + ai_text
        → (报告发送 / *_end 场景) → _finish_day_one/two/week_day()   # ASYNC
           → 写 state 完成标志
           → _advance_action_time("sleep_standard")   # 写 TimeManager
           → _save_state()                            # 写 Full Save
           → _consume_time_phase_notice()
           → input_enabled=false + message/ai text
           → await 计时/tween 淡出
           → get_tree().change_scene_to_file(next)    # 切场景
```
**关键顺序**：谓词判断 → （异步）设备交互 → state 变更（多在 async after 内）→ 完成序列写 state → 推进时间 → 存档 → 淡出 → 切场景。**顺序依赖真实存在**：`_complete_daily_check` 的 `DailyInspectionsComplete` 只在 async after 内、且 `_daily_checks_complete()` 为真时置位；`_finish_*` 的 state 写必须在 `_save_state` 之前、切场景之前。

## 3. Method Inventory（分类）
| Method | Lines | Class | Reads | Writes | Manager/Save | Async | Transition |
|---|---:|---|---|---|---|---|---|
| `_current_day` | 2 | **PURE_PREDICATE** | state | — | — | — | — |
| `_task_line` | 2 | **PURE_PREDICATE** | state | — | — | — | — |
| `_daily_required_keys` | 14 | **SCHEDULE_CHECK (pure)** | day | — | — | — | — |
| `_daily_checks_complete` | 5 | **PURE_PREDICATE** | day, state | — | — | — | — |
| `_day02_inspections_complete` | 5 | **PURE_PREDICATE** | state | — | — | — | — |
| `_day_label`/`_daily_report_label`/`_daily_checklist_text` | ~35 | **UI_ONLY (pure text)** | day, state | — | — | — | — |
| `_reset_daily_flags` | 15 | STATE_TRANSITION | day | ~12 state | — | — | — |
| `_complete_daily_check` | 13 | TASK_ADVANCE + ASYNC | state, current_target | state (async) | — | ✓ | — |
| `_complete_day02_check` | ~15 | TASK_ADVANCE + ASYNC | state | state (async) | — | ✓ | — |
| `_interact` (+ `_interact_*`) | ~200 | TASK_ADVANCE / NAVIGATION_TRIGGER | scene_kind, current_target, state | state | — | ✓ (finish) | via finish |
| `_begin_equipment_interaction` | ~120 | **ASYNC_SEQUENCE** | — | state (updates), interaction_running/sequence_running/input_enabled, UI | — | — | — |
| `_finish_day_one/two/week_day` | ~80 | **ASYNC_SEQUENCE + SAVE_COUPLED + MANAGER_WRITE** | day, state | state, input_enabled, message/ai | `_advance_action_time`, `_save_state` | ✓✓ | ✓ change_scene |
| `_transition_to` | 7 | ASYNC_SEQUENCE + NAVIGATION | fade_rect | input_enabled, sequence_running | — | ✓ | ✓ change_scene |
| `_interaction_target_rect` | ~60 | SCHEDULE_CHECK + FLOW | current_target, day, state | — | — | — | — |
| `_advance_action_time` | ~10 | MANAGER_WRITE | — | — | TimeManager write | — | — |
| `_save_state`/`_load_state` | ~12 | SAVE_COUPLED | state | state (load) | FullSaveOrchestrator | — | — |

## 4. Shared State Matrix（高风险字段）
| Field | Writers | Readers | Order-dependent | Manager mirror | Save ownership | Candidate owner |
|---|---|---|---|---|---|---|
| `state` (Dictionary) | `_reset_daily_flags`, `_complete_*`, `_finish_*`, `_begin_equipment_interaction`, `_load_state` | ~全部谓词/UI/interact/rect | **YES**（Day flags 顺序置位） | 无（非 Manager） | **Full Save scene_state（canonical）** | 场景（保留）；谓词可只读它 |
| `current_target` | `_update_target`（nav） | `_interact_*`, `_interaction_target_rect`, `_complete_daily_check` | YES（先算后用） | — | 不入 Full Save（每帧重算） | 场景 |
| `scene_kind` | `_setup_scene_defaults` | 分派/谓词/rect/nav | 入场设定 | — | scene-local | 场景 |
| `sequence_running` | `_interact`守卫, `_begin_equipment_interaction`, `_transition_to`, finish | `_interact`, `_process` | **YES**（锁输入） | — | scene-local | 场景 |
| `input_enabled` | finish/transition/equipment | `_process`/input | YES | — | scene-local | 场景 |
| `interaction_running` | `_begin_equipment_interaction` | 守卫重入 | YES | — | scene-local | 场景 |
| `message_text`/`ai_text` | 各流程 | `_update_ui` | 帧内多写 | — | scene-local | 场景 |
- `state` 跨 >3 职责块读写 → **HIGH_COUPLING**，但其**只读**面（谓词/UI 文本）可安全分离。`sequence_running`/`input_enabled`/`interaction_running` = ORDER_DEPENDENT 输入锁，**KEEP**。

## 5. Manager Boundaries
- **TaskManager 非 sprint06 canonical**：sprint06 的日常/任务阶段进度全部持于 scene-local `state` dict（键如 `DailyConsoleChecked`/`Day01Completed`/`WeekOneCompleted`），经 `FullSaveOrchestratorScript.save_full_save(state, …)` 落 Full Save 的 scene_state。**未发现** sprint06 任务状态在 Scene 与某 Manager 双持有。TaskManager 仅训练侧使用。
- 流程方法的 Manager 触点：**只读 TimeManager**（阶段判断）；**写**仅 `_advance_action_time`（推进正式时间，`_finish_*` 内）+ `_save_state`（Full Save）。谓词/文本方法**零 Manager 调用、零 state 写**。
- 无直接外部字段写；无 Phase-3-遗留 glue 残留（Full Save 调用已是 P3 定稿的 `save_full_save`/`restore_full_save`）。

## 6. Schedule Logic
`_daily_required_keys(day)` 是纯映射表（day 3/4/5/6/7 → 4 键集合，默认 `["DailyConsoleChecked"]`）。`_daily_checks_complete()` = 该表全在 state 为真。`_day02_inspections_complete()` = 4 个 Day02 键。`_daily_checklist_text()`/`_day_label()`/`_daily_report_label()` = 纯文本（day+state）。全部**无副作用**。

## 7. Mission-State Logic
阶段推进（`_complete_daily_check` → `DailyInspectionsComplete`；`_finish_*` → `Day0XCompleted`/`WeekOneCompleted`）**与异步序列、存档、切场景强绑定**，且依赖帧内/回调置位顺序。**不可与流程分离**。

## 8. Transition and Async Coupling
`_finish_day_one/two/week_day` 与 `_begin_equipment_interaction`、`_transition_to` 全含 `await`（计时器/tween），且 finish 在 await 之间穿插 state 写 + save + 切场景。异步序列 = **ASYNC_SEQUENCE，KEEP_IN_SCENE**（抽离会破坏时序/淡出/存档点）。

## 9. Save/Restore Coupling
`_save_state()` 在每个 `_finish_*` 内（阶段边界存档）；`_load_state()` 经 `restore_full_save(self)`。存档顺序（state 写 → save → 切场景）是 P3 定稿契约，**不得改动**。谓词/文本抽离**不触碰**存档路径。

## 10. Extraction Candidates

### Candidate: Sprint06ScheduleEvaluator — 推荐 EXTRACT
- Responsibility: 纯日程/任务谓词与清单文本（无副作用）
- Source methods: `_current_day`, `_daily_required_keys`, `_daily_checks_complete`, `_day02_inspections_complete`, `_task_line`, `_day_label`, `_daily_report_label`, `_daily_checklist_text`
- Approx lines: ~70
- Inputs: `state: Dictionary`（+ 由其派生的 day）
- Outputs: int / bool / Array[String] / String
- Reads: 仅 `state`
- Writes: 无
- Side effects: 无 · Async: 无 · Shared fields: 只读 `state` · Manager deps: 无 · Save implications: 无
- Extraction difficulty: **LOW** · Regression risk: **LOW**
- Can be extracted alone: **YES**（场景保留薄委托，传 `state`）
- Required tests: 纯函数单元（day 3-7 键集、完成判定、Day02 判定、清单文本）——**无需启动场景**
- Recommended action: **EXTRACT**（P4-06B）

### Candidate: MissionCompletionEffects (`_complete_*` + `_finish_*`)
- Responsibility: 阶段完成写 state + 时间 + 存档 + 切场景
- Side effects: state 写 / Manager 写 / Full Save / async fade / change_scene
- Extraction difficulty: **HIGH** · Regression risk: **HIGH** · Async: ✓✓
- Recommended action: **KEEP_IN_SCENE**（顺序/异步/存档强耦合）

### Candidate: EquipmentInteractionSequence (`_begin_equipment_interaction`)
- Responsibility: 异步设备交互 + 输入锁 + 交互 UI + 延时后应用 updates/after
- Side effects: 输入锁 / UI / state / `after` 回调 · Async: ✓
- Extraction difficulty: **HIGH**（await + 场景节点 + 回调）· Regression risk: **HIGH**
- Recommended action: **DEFER**（若拆需先建交互 UI/锁的接口，风险高收益低）

## 11. Unsafe-to-Split Areas
`_finish_day_*`、`_begin_equipment_interaction`、`_transition_to`、`_interact*` 主分派、`_save_state`/`_load_state`、`_process`/输入锁字段（`sequence_running`/`input_enabled`/`interaction_running`）、`_interaction_target_rect`（day/state 密集）。均 order/async/save 强耦合。

## 12. Characterization Coverage
`tests/p4_06a_sprint06_flow_characterization_test.gd`（源码分析 + 纯逻辑锁定，**不启动基地场景**）：执行顺序（谓词先于 mutation、mutation 先于 save/transition、`_interact` 首行守卫、完成置位在 async after 内）；日程表（day 3/4/5/6/7 键集）；完成边界（门禁 DailyConsoleChecked、`DailyInspectionsComplete` 触发、`_daily_checks_complete` 结构）；Manager/save 边界（`_save_state` 用 FullSaveOrchestrator、`_transition_to` 在场景、nav/HUD/router 不承担 task flow）；存档安全（SHA 不变）。

## 13. P4-06B Recommendation
**唯一结论：A — SAFE_EVALUATOR_EXTRACTION。** ✅ **已执行（P4-06B，2026-07-12，commit 见收尾）**：抽出 `scripts/controllers/sprint06_schedule_evaluator.gd`（无状态 RefCounted，8 纯方法：`current_day`/`required_daily_keys`/`daily_checks_complete`/`day02_inspections_complete`/`task_line`/`day_label`/`daily_report_label`/`daily_checklist_text`）。场景保留薄委托，全部 mutation/async/finish/transition/save/输入锁**仍在场景**（未触碰）。字符串逐字等价、Dictionary 不变性经测试锁定。`sprint06_base_scene.gd` 2307→2268（净 −39）。测试 `p4_06b` 41/41，`p4_06a` characterization 迁移后 28/28。
- 抽出 `scripts/controllers/sprint06_schedule_evaluator.gd`（无状态 RefCounted，~70 行）：`current_day(state)`、`required_daily_keys(day)`、`daily_checks_complete(day, state)`、`day02_inspections_complete(state)`、`task_line(label,key,state)`、`day_label(state)`、`daily_report_label(state)`、`daily_checklist_text(state)`。
- 场景保留薄委托（`_daily_checks_complete()` → `_schedule.daily_checks_complete(_current_day(), state)`），行为不变。
- **不触碰**：`_complete_*`、`_finish_*`、`_begin_equipment_interaction`、`_transition_to`、`_save_state`/`_load_state`、输入锁字段、`state` 的写入方。
- 预计 `sprint06_base_scene.gd` 减 ~60-70 行；测试为纯函数（无场景启动、无存档）。

## 14. Remaining Risks
- 无 P0/P1。sprint06 阶段进度为 scene-local + Full Save，**无双持有缺口**（本轮未发现需即修的缺口）。
- 剩余大部分 sprint06 流程（完成/异步/切场景）**按设计保留在场景**；Phase 4 对其收益低、风险高，建议仅做 evaluator 抽离后即止于 sprint06，转向其它大脚本（training UI）或延期项。
