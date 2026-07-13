# CLEANUP_PLAN · 渐进式清洗路线图

> 治理审计初稿 · 只读产出（本文件不执行任何清洗）· 2026-07-11
> 原则：渐进 / 每次一个清晰问题 / 可独立验证 / 可独立回滚 / 不混入新功能 / 优先降风险而非"目录好看"。
> 排序按**风险与依赖**，不按整洁度。所有操作在 `outputs/lunar_base_godot/`。

---

## Phase 0 · 冻结与基线（先做，零代码改动）
- **目标**：建立可回滚的治理基线，锁住当前真相。
- **前置条件**：无。
- **具体任务**：
  1. 暂停新增功能，宣布进入治理期。
  2. 确认仓库根 = `outputs/lunar_base_godot/`（PROJECT_MAP §0）。
  3. **处理未提交工作区**：当前 `scripts/main.gd` 与 `scripts/surface/lunar_surface_scene.gd` 有未提交改动，且分支 ahead of origin 1 commit。先由作者确认这些改动意图，commit 或 stash，使工作区对**源码**干净（截图 `.import` churn 单独处理，见 Phase 1）。
  4. 打治理基线 tag：`git tag governance-baseline-2026-07-11`。
  5. 本 `docs/governance/*` 初稿提交（纯新增文档）。
- **禁止事项**：改任何源码/场景/配置/`.gitignore`；删任何 `.git`。
- **验证方法**：`git status` 中 `.gd/.tscn/.godot`/`project.godot` 无未决改动；tag 存在。
- **完成标准**：基线 tag + 治理文档入库 + 源码工作区干净。
- **回滚方案**：删 tag 即可（未动代码）。
- **风险**：未提交的 main.gd 改动若被误 stash 丢失 → 先让作者确认再动。

## Phase 1 · 仓库卫生（低风险，独立可回滚）
- **目标**：消除 Git 噪声与不一致，不碰源码。
- **前置条件**：Phase 0 完成。
- **具体任务**（每项单独一个 commit）：
  1. **`.gd.uid` 一致化**：现状 58 个 `.uid` 已跟踪、35 个未跟踪（新旧不一致；DoorState/Penalty/Task 的 uid 已跟踪，旧 manager 的未跟踪）。Godot 4 约定 `.uid` 应跟踪 → 统一 `git add` 全部 `.gd.uid`。
  2. **截图 `.png.import` churn**：118 modified + 87 untracked 几乎全是 `docs/screenshots/**` 与 `docs/art/**` 的 `.png.import`。决策二选一（须作者确认）：(a) 跟踪并一次性提交、之后忽略其再生变化；或 (b) 从版本库移除 `docs/**/*.png.import` 并在 `.gitignore` 忽略。**倾向 (b)**：截图 import 元数据对游戏运行无意义。
  3. **`.godot_appdata/` 处置**：未跟踪也未忽略，是本机 Godot appdata（launch 脚本相关）。确认为本机产物后加入 `.gitignore`。
  4. **`wo-x/.git` 空壳**：claude-code-runtime 生成，非项目仓库。**本阶段仅记录，不删**；如确认无用由人类删。
  5. **大 AI 概念图**（`docs/art/**` 单文件最大 2.4MB `ChatGPT` 图）：确认是否需入库，或迁项目外/用 Git LFS。
- **禁止事项**：改源码；改现役 `.import`/`.uid` 之外的资源；删仍被场景引用的资产。
- **验证方法**：`git status` 干净；`--headless --editor --quit --path .` 无 import 报错；正式流程仍可跑。
- **完成标准**：`git status` 只剩有意的改动；`.uid` 一致；截图 churn 不再污染 diff。
- **回滚方案**：每项独立 commit，`git revert` 单条。
- **风险**：误忽略了 Godot 真正需要的 `.import`（**只处理 `docs/**` 下截图 import，不动 `assets/**` 的**）。

## Phase 2 · 文档治理（低风险）
- **目标**：六类真相各归其位，消除职责重叠（DOCUMENT_REGISTRY §E/§F）。
- **前置条件**：Phase 1 完成。
- **具体任务**：
  1. README 收敛为门面（是什么/怎么跑/指向 PROJECT_BRIEF·SYSTEMS_REFERENCE_FOR_DESIGN.md·CURRENT），把"当前状态"段移除，状态只留 CURRENT.md。
  2. `ITERATION_PLAN.md` 从项目根迁入 `docs/`，标注为历史归档。
  3. 给 `docs/sprints/*`、`LEGACY_SANDBOX_PROTOTYPE.md` 明确"历史归档"标头。
  4. 08.x 收尾后合并/归档 `pre09_flow_audit.md` 与 `KNOWN_ISSUES_PRE09.md`。
- **禁止事项**：删仍可能被引用的文档；改 PROJECT_BRIEF / SYSTEMS_REFERENCE_FOR_DESIGN.md 的**内容**（只加归位标注）。
- **验证方法**：人工通读；确认无文档互相矛盾；链接不断。
- **完成标准**：产品/系统/数值/状态/历史/证据六类各有唯一主文档。
- **回滚方案**：文档改动 `git revert`；迁移用 `git mv` 保留历史。
- **风险**：迁移破坏他处引用路径 → 迁移后全仓 grep 旧路径。

## Phase 3 · 系统边界清洗（中高风险，逐系统）— ✅ COMPLETE（2026-07-12，收口见 `PHASE_3_CLOSURE_REPORT.md`）
- **状态**：**COMPLETE**。P3-01/02/02R/03a/03b/03c/03cV/03d/04/05/06 全部完成；全部专项测试通过；无 P0；下一步 = Phase 4 大脚本拆分。
- **目标**：厘清 Manager 职责与存档真相源，不重写。
- **前置条件**：Phase 0-2 完成；SYSTEM_REGISTRY / LEGACY_REGISTRY 已评审。
- **P3-01 审计结论（2026-07-11，详见 `PHASE_3_SYSTEM_BOUNDARY_AUDIT.md`）**：20 autoload 全现役；**跨系统写入全部经公开方法、0 处直接外部字段写**（PenaltyManager 仅分发）；无依赖环、无 P0。**核心 P1 = 存档真相源不唯一**（Manager 状态同进 `*_state.json` + `training_progress` + `sprint06_progress`，load 顺序覆盖）。
- **P3-02 决策结论（2026-07-11，详见 `PHASE_3_SAVE_OWNERSHIP_DECISION.md`）**：每核心域 owner 定稿（UNRESOLVED=0）；Backpack↔Storage=CLEAR_SEPARATION（转移协议已实现，非双记账）；Time/TrainingTime=SEPARATE_CLOCKS+NO_SYNC；Penalty=分发器/不持久化。**推荐存档架构 = 方案 C（分层：单一 Full Save bundle 为 restore 真相，Manager 自存降级）**。**用户待决 2 项**（Full Save 权威模型、旧档兼容）；其余按现有设计确认。P0=0，P1 仍存待 P3-03。
- **P3-02R 独立复核对账结论（2026-07-11，详见 `PHASE_3_SYSTEM_BOUNDARY_AUDIT.md` §16 / `PHASE_3_SAVE_OWNERSHIP_DECISION.md` §16）**：Codex 六项发现全部独立核验（Power deserialize 不同步 BaseStatus.power = P2；BaseStatus 摘要含氧气 = 文档修正；Suit 双持有但 SuitManager 明确 canonical、运行时 SYNC_COMPLETE；Door `FORMAL_BASE_NOT_CONNECTED`；legacy 同名节点无运行冲突；TrainingManager read/restore API 边界）。**"UNRESOLVED=0"作废**——细化为 OWNER_FINAL_BUT_SYNC_RISK（电力、宇航服）/ DECISION_PENDING（Inventory↔Backpack 记账、Full Save 真相源模型）/ UNRESOLVED（Door 正式基地接入）。**P0=0；P1=1（真相源不唯一）；P2=6；P3=3。**
- **批次顺序**：P3-02 ✅ → P3-02R ✅ → P3-03a ✅（Power/Suit mirror 同步、restore-complete、read/restore API 边界）→ **P3-03b Full Save Orchestrator 正式化（+schema_version，下一步）** → P3-03c Manager 自存降级 → P3-03d checkpoint 越域裁剪 → P3-04（职责重叠清洗 + Inventory/Backpack 字段核实 + Door 正式基地接入）→ P3-05（Legacy 隔离，含同名局部节点）→ P3-06（回归收口）。
- **P3-03a 完成记录（2026-07-12）**：恢复一致性与只读查询边界已落地；专项测试 39/39、Godot editor/smoke 均通过；本地存档备份 SHA-256 一致。**P1 多真相源仍存在**，P3-03b/c 继续处理；P3-03c/d 未开始。
- **具体任务**（每个系统独立 PR，串行）：
  1. **文档化存档真相源**：为每个状态明确"唯一真相源 = 该 Manager 自存 or 训练/ sprint06 快照"，写进 SYSTEMS_REFERENCE_FOR_DESIGN.md，消除 LEGACY_REGISTRY §B2 的双重记账不清。
  2. **Inventory/Backpack/Storage 边界核实**：确认是否存在双记账（SYSTEM_REGISTRY §B2 UNKNOWN），只在确认后再谈是否收敛。
  3. **UNKNOWN 结案**：`interaction_detector.gd` 是否 orphan、`BaseInterior_Test.tscn`/`ArrivalLandingScene` 是否可达、`arrival` 对 `game_state_manager` 的真实用法（LEGACY_REGISTRY §C）。逐一给证据。
  4. **DoorStateManager 接入正式导航**（`CURRENT.md:54` 已知未接）——属功能，**排到治理期之后**，此处仅登记。
- **禁止事项**：一次动多个 Manager 的 serialize；把遗留 A2 脚本"顺手删"（仍被 main/arrival 引用）；改存档结构不做 remap。
- **验证方法**：改任一 serialize/deserialize 后，三处存档（自存/训练/sprint06）+ 旧存档 remap 全测；`lunar-base-verify` 全流程。
- **完成标准**：每个状态有书面唯一真相源；UNKNOWN 清零或有明确结论。
- **回滚方案**：逐系统 PR，可单独 revert；存档结构改动保留旧字段读兼容。
- **风险**：🔴 存档兼容——改 schema 会让旧存档失效；必须保留读旧路径。

## Phase 4 · 大型脚本渐进拆分（高风险，一次一个职责）— ✅ COMPLETE（2026-07-12，收口见 `PHASE_4_CLOSURE_REPORT.md`）
- **P4-01 审计结论（详见 `PHASE_4_LARGE_SCRIPT_AUDIT.md`）**：实测 P0=`main.gd`(5182)；P1=`training_module_scene.gd`(3417)/`sprint06_base_scene.gd`(2556)/`training_base_map.gd`(2255)。4 个大场景脚本均 HIGH_FAN_OUT + SCENE_TREE_COUPLED 但 fan-in 低（利于拆）；`training_manager`(591) 是 HIGH_FAN_IN static hub，靠后。
- **P4-02 唯一推荐（修订原"MainMenuController 首拆"）**：先抽 **`main.gd` 的 DevToolsController**（dev 菜单 + ~150 `_debug_*`，~840 行/~16%）。理由：**dev-only、对正式玩法/存档/恢复零影响**、共享状态最低、近乎纯 relocation、可独立 revert——比 MainMenuController/FormalFlowRouter 更安全（后者触正式路由/restore，排 P4-03）。
- **执行顺序（最终）**：P4-01 audit → P4-02 DevTools → P4-03 FormalFlowRouter → P4-04 sprint06 HUD presenter → P4-05 sprint06 navigation computation → P4-06A/B sprint06 schedule evaluator → P4-07A/B training module screen presenter → P4-08 regression/save-baseline/closure。原计划中的 sandbox slot-save aggregation 与 training_manager checkpoint IO 均延期，不作为 Phase 4 阻塞项。
- **P4-02 ✅ DONE（2026-07-12）**：`DevToolsController` 抽出（`scripts/controllers/dev_tools_controller.gd`，876 行），`main.gd` **5182→4346（−836/~16%）**；90 funcs 移出（dev 菜单 + 全部 `_debug_*`），`_debug_reset_time` 作为 SHARED_HELPER 留 main（formal new-game 用），非 Autoload、正式流程不依赖它。测试 `p4_02` 22/22 + Phase3 全量绿 + 真实存档 SHA 不变。
- **P4-03 ✅ DONE（2026-07-12）**：`FormalFlowRouter` 抽出（`scripts/controllers/formal_flow_router.gd`，133 行，`class_name`/RefCounted，非 Autoload）。移出 10 个正式路由方法（continue_mission + 全部进度谓词 + new-game/clear）；续档优先级 **Full Save→Training→legacy slot→notice** 完全不变；只读谓词用 `read_progress()`、router 不调 `load_progress()`。依赖注入（callbacks，利于测试），0 wrapper（5 调用点直接改线）。`main.gd` **4346→4302（净 −44）**。新增 `p4_03` 27/27，并迁移 p3_05/p4_02/p3_03c/p3_03a 断言。真实存档 SHA 不变。
- **P4-04 ✅ DONE（2026-07-12，调整原计划）**：原计划 P4-04=sandbox 存档聚合，**延期**（legacy/dev、20+ 共享字段、收益低）；改为抽 `sprint06_base_scene.gd` 的 **`BaseHudPanelPresenter`**（`scripts/controllers/base_hud_panel_presenter.gd`，263 行，RefCounted，非 Autoload）。移出全部 HUD/状态面板 UI 构建 + 8 面板 toggle + `refresh_open_panels`；场景 `_setup_ui` 用 **re-expose** 把 flow 更新的 label 节点回指自身 var（更新点全不变=安全）；plant-diagnosis（按钮驱动玩法）与 save/flow/导航留场景。`sprint06_base_scene.gd` **2556→2331（净 −225）**。新增 `p4_04` 35/35，全绿。
- **P4-05 ✅ DONE（2026-07-12，P4-05A 接口准备范围）**：抽 `sprint06_base_scene.gd` 可安全分离的**导航计算**为无状态 `BaseNavigationController`（`scripts/controllers/base_navigation_controller.gd`，49 行，`class_name`/RefCounted）。移出 `_current_terrain_type`/`_near`/`_update_target` 计算，场景保留薄委托 + flow-coupled 部分。`sprint06_base_scene.gd` **2331→2308（净 −24）**。新增 `p4_05` 30/30，全绿。
- **P4-06A ✅ DONE（2026-07-12，只读审计 + characterization，零流程代码移动）**：审计 sprint06 日程/任务/切场景/异步/存档耦合 → `P4_06A_SPRINT06_FLOW_AUDIT.md`。关键发现：sprint06 任务进度持于 scene-local `state`（Full Save scene_state），**非** TaskManager，无双持有、无 P0/P1；完成/finish 序列为 async+time+save+切场景（KEEP），纯谓词/文本可安全分离。新增 `p4_06a` 26/26（源码分析，不启动场景），全绿，真实存档 SHA 不变。**唯一下一步结论：A — SAFE_EVALUATOR_EXTRACTION**。
- **P4-06B ✅ DONE（2026-07-12）**：抽无状态 `Sprint06ScheduleEvaluator`（`scripts/controllers/sprint06_schedule_evaluator.gd`，66 行，`class_name`/RefCounted，零成员状态）——8 个纯函数（`current_day`/`required_daily_keys`/`daily_checks_complete`/`day02_inspections_complete`/`task_line`/`day_label`/`daily_report_label`/`daily_checklist_text`）。场景保留薄委托，全部 mutation/async/finish/transition/save/输入锁未动。字符串逐字等价 + Dictionary 不变性测试锁定。`sprint06_base_scene.gd` **2307→2268（净 −39）**。新增 `p4_06b` 41/41，迁移 `p4_06a` 28/28，全绿，真实存档 SHA 不变。
- **P4-07A ✅ DONE（2026-07-12，只读审计 + characterization，零代码移动）**：审计 `training_module_scene.gd`(3417)/`training_base_map.gd`(2255) → `P4_07A_TRAINING_LARGE_SCRIPT_AUDIT.md`。关键：两脚本 UI 全动态 `add_child`（无 `$` 硬路径、无 tween）→ UI presenter 抽离**无需改 .tscn**（P4-04 模式）；UI flow-wired（按钮→checkpoint/step）；无 P0/P1（训练进度 canonical 在 training_progress.json）。新增 `p4_07a` 30/30（源码分析，不启动场景），全绿，SHA 不变。**唯一结论：A — EXTRACT_TRAINING_MODULE_UI**（`TrainingModuleScreenPresenter`，~300-400 行，CHARACTERIZE_FIRST）；此后剩余训练逻辑（状态机 + base_map 房间导航）强耦合 → 建议 **CLOSE_PHASE_4**。**下一步 P4-07B**：抽 training_module UI presenter（先 characterize）。
- **P4-07B ✅ DONE（2026-07-12）**：抽 `TrainingModuleScreenPresenter`（`scripts/controllers/training_module_screen_presenter.gd`，501 行，`class_name`/RefCounted，非 Autoload）。移出 `training_module_scene.gd` 的显示层 screen chrome、minimal HUD、briefing/pause/interaction 面板、popup shell、suit-status panel、entry-blocked briefing、overlay/HUD/interaction display；场景保留 `_build_training_area`、room target/layout、movement/input locks、step state、`_complete_step`/`_finish_module`、checkpoint 写入和所有正确/错误选项判定。`training_module_scene.gd` **3417→3114（净 −303）**。新增 `p4_07b` 20/20，迁移 `p4_07a` 32/32，全绿。`training_base_map.gd`、场景、`project.godot`、schema、玩法数值未动。**建议下一步：Phase 4 close-out；不要自动开始 P4-08。**
- **P4-08 ✅ DONE（2026-07-12）**：Phase 4 全量回归、存档基线重建与收口完成。新增 `PHASE_4_CLOSURE_REPORT.md`。全部 P3/P4 专项测试通过（454/454），Godot editor/smoke EXIT 0。当前真实存档先备份到 `saves_backup_before_p4_08_2026-07-12_234110`（19/19 SHA 匹配），测试后所有 SHA 仍不变，仅 manager/training JSON mtime 刷新；结论 `SAVE_BASELINE_STABLE_WITH_EXPECTED_MIRROR_REFRESH`。Phase 4 COMPLETE；下一步 Phase 5 — Skill 建设，未启动。
- **目标**：给 4 个巨型脚本减负，**不大爆炸重写**。
- **前置条件**：Phase 3 相关系统边界已清。
- **具体任务**（严格一次一个，每步独立回归+回滚点）：
  1. **首选 `main.gd` 菜单/沙盒解耦**（SCENE_REGISTRY §B1 #1）：抽出 `MainMenuController`，`main.tscn` 只留菜单，沙盒本体迁 `scenes/sandbox/`。收益最高、耦合最低。
  2. 之后视情况：`training_module_scene.gd` 步骤数据外提；`sprint06_base_scene.gd` 场景配置外提。每次只提一个稳定职责。
- **禁止事项**：同一 PR 里既拆分又加功能；一次拆多个脚本；改变对外可观察行为。
- **验证方法**：拆分前后**行为等价**——同一存档、同一流程、同一截图路径对比；`lunar-base-verify`。
- **完成标准**：目标职责被提取为独立单元，旧调用行为 100% 保留。
- **回滚方案**：每次拆分一个 commit/PR，可整体 revert。
- **风险**：🔴 tier-1 文件（reference_prop/sprint06/training_*）拆分波及多线；先拆耦合最低的 main.gd 菜单。

## Phase 5 · Skill 建设（低风险）— COMPLETE（2026-07-13）
- **目标**：把已验证的治理、Godot 工程、广寒项目、美术与交接流程沉淀为少量可验证 Skill，而不是批量冻结临时提示词。
- **Phase 5 收口结论**：P5-01 至 P5-07 全部 VERIFIED。正式 Skill 数量 = 5，maturity 全部 = `TRIAL`（Phase 5 交付的是 Skill 架构与 TRIAL 套件，不宣称任何 Skill 已 `VALIDATED`；从 `TRIAL` 升至 `VALIDATED` 仍需真实任务验证）。closure 报告见 `PHASE_5_CLOSURE_REPORT.md`；新会话初始化指南见 `docs/handoff/AGENT_SESSION_BOOTSTRAP.md`。Phase 6 名称：`Phase 6 — Agent Collaboration and Skill Field Validation`。Phase 5 closure commit：`docs: close Phase 5 Skill suite`。后续远端冻结已完成：`main` 已 push；完成标签 `skill-suite-complete-2026-07-13` 已创建；Codex Bootstrap 已通过；Claude Code Bootstrap 已通过。Phase 6 进入条件已满足，当前为 READY，尚未开始；Phase 6 用于 field validation。
- **P5-01 状态**：COMPLETE（2026-07-13）。审计报告见 `PHASE_5_SKILL_ARCHITECTURE_AUDIT.md`。本轮只做架构、目录、边界、候选目录和 P5-02 选择；未创建 `skills/`、未创建 `SKILL.md`、未改生产代码。
- **P5-02 状态**：COMPLETE（2026-07-13）。已创建首个正式仓库 Skill：`skills/godot/characterization-first-refactor/SKILL.md`，并建立 `skills/SKILL_REGISTRY.md`。dry run 记录见 `P5_02_CHARACTERIZATION_SKILL_TRIAL.md`。当前 maturity = `TRIAL`，不是 `VALIDATED`。未改生产代码、测试、场景、资源、JSON、真实存档或 `project.godot`。
- **P5-03 状态**：COMPLETE（2026-07-13）。已创建第二个正式仓库 Skill：`skills/core/save-integrity-guard/SKILL.md`，并更新 `skills/SKILL_REGISTRY.md`。dry run 记录见 `P5_03_SAVE_INTEGRITY_SKILL_TRIAL.md`。当前 maturity = `TRIAL`，不是 `VALIDATED`。本 Skill 负责真实用户数据备份、SHA、结构化 JSON 对比、变化分类与禁止机械回滚；与 `characterization-first-refactor` 为 COMPOSABLE 关系。未改生产代码、测试、场景、资源、JSON、真实存档或 `project.godot`。
- **P5-04 状态**：COMPLETE（2026-07-13）。已创建第三个正式仓库 Skill：`skills/core/task-baseline-and-lock/SKILL.md`，并更新 `skills/SKILL_REGISTRY.md`。dry run 记录见 `P5_04_TASK_BASELINE_LOCK_SKILL_TRIAL.md`。当前 maturity = `TRIAL`，不是 `VALIDATED`。本 Skill 负责任务基线确认、ACTIVE_TASKS 登记、单 owner、锁、范围、owner transfer、close-out 与 push/tag 权限边界；与前两项 Skill 为 COMPOSABLE 关系。未改生产代码、测试、场景、资源、JSON、真实存档或 `project.godot`。
- **P5-05 状态**：**VERIFIED**（2026-07-13；Owner Transfer Codex → Claude Code，Codex 触达 usage limit）。已创建第四个正式仓库 Skill、也是首个 Guanghan Project 层 Skill：`skills/guanghan/guanghan-art-design-and-production/SKILL.md`，并更新 `skills/SKILL_REGISTRY.md`。dry run 记录见 `P5_05_GUANGHAN_ART_PRODUCTION_SKILL_TRIAL.md`。当前 maturity = `TRIAL`，不是 `VALIDATED`。**职责边界**：Primary creative agent = **ChatGPT**（视觉设计/生图/风格/交付）；Implementation consumers = **Codex / Claude Code**（读批准规格、接入仓库、切图/命名/导入、配 Godot、搭场景，不擅改视觉方向、不替代主要美术创作）；Final approval = **User**。本 Skill 负责场景美术设计、模块化素材拆分、生成提示词、规格与生产 brief；不负责代码、场景修改、资产导入或最终截图验收。未改生产代码、测试、场景、资源、图片、JSON、真实存档或 `project.godot`。**P5-06 READY**（未启动）。
- **P5-06 状态**：**VERIFIED**（2026-07-13；Owner Claude Code）。已创建第五个正式仓库 Skill、也是第二个 Guanghan Project 层 Skill（review 侧）：`skills/guanghan/guanghan-art-review-and-godot-handoff/SKILL.md`，并更新 `skills/SKILL_REGISTRY.md`。dry run 记录见 `P5_06_GUANGHAN_ART_REVIEW_SKILL_TRIAL.md`。当前 maturity = `TRIAL`，不是 `VALIDATED`。**职责边界**：Primary visual reviewer = **ChatGPT**（读 PROJECT_BRIEF/批准目标，对照目标图·规格·截图，判定风格/比例/像素密度/分层/遮挡/可读性/状态反馈/模块化素材使用，输出结构化修订工单与视觉裁决；不读改代码、不判状态机/存档/信号/Manager/碰撞正确性）；Implementation recipients = **Codex / Claude Code**（接工单、改场景/资源/代码、提供 before/after 截图与工程验证）；Final approval = **User**。dry run 对广寒训练基地宇航服准备室"整图作背景"截图判 **FAIL**，将整图导入判 `REFERENCE_ONLY_MISUSE`(P0)、路径遮挡判 `OCCLUSION_ERROR`(P1)、终端不可读判 `READABILITY_ISSUE`(P1)，输出三条结构化工单（ART-001..003），含代码正确性免责声明，未作任何代码判断。两段式 Art Skill 架构（生产侧 + review 侧）至此成对完成，`SEQUENTIAL_AND_COMPOSABLE`，不合并。未改生产代码、测试、场景、资源、图片、JSON、真实存档或 `project.godot`。**P5-07 未启动**。
- **P5-07 状态**：**VERIFIED**（2026-07-13；Owner Claude Code）。对 5 个正式 Skill 做套件级验证并正式关闭 Phase 5：未创建新 Skill；未把任何 Skill 从 `TRIAL` 升级为 `VALIDATED`。验证结论：正式 SKILL.md = 5，与 Registry/文件系统一致（`REGISTRY_MATCH`）；元数据一致（无 `VALIDATED`，`status`/`maturity` 一致为 `trial`，core Skill 的 `scope: general` 对应 Registry `layer: core` 符合 P5-01 决策）；结构完整（含美术 Skill 的 Agent Responsibilities/视觉方向/Godot 边界/User 批准）；无短期 commit/本地路径/git 状态硬编码；`git add .`/`-A` 均为禁止语义、push/tag 语义正确；5 份 dry-run 证据齐全且结论与 Skill 一致。新增 `PHASE_5_CLOSURE_REPORT.md` 与 `AGENT_SESSION_BOOTSTRAP.md`。Phase 5 = COMPLETE，Phase 6 = READY（未启动）。未 push、未 tag、未新建会话、未修改生产代码/测试/场景/资源/JSON/真实存档/`project.godot`。
- **最终 Skill 层模型**：
  1. Core Governance Skills
  2. Godot Engineering Skills
  3. Guanghan Project Skills
  4. Agent-specific Operating Guides（保留为协作/角色规则，不作为正式 Skill）
- **推荐目录方案（未来 P5-02 起创建）**：
  - `skills/core/<skill-name>/SKILL.md`
  - `skills/godot/<skill-name>/SKILL.md`
  - `skills/guanghan/<skill-name>/SKILL.md`
  - 未来注册表建议：`skills/SKILL_REGISTRY.md`
- **Wave 1**：`characterization-first-refactor`、`task-baseline-and-lock`、`save-integrity-guard`。
- **Wave 2**：`regression-and-closure`、`system-boundary-audit`、`godot-presenter-extraction`、`guanghan-art-design-and-production`。
- **Wave 3 / deferred**：`owner-transfer-and-handoff`、`godot-controller-extraction`、`guanghan-art-review-and-godot-handoff`、`bug-ticket-formatter`、`product-experience-acceptance`。
- **P5-06 默认建议**：`Guanghan Art Review and Godot Handoff Skill`。理由：Art Skill 架构保持两段式，P5-05 已沉淀生产前设计与素材拆分；下一步应沉淀目标图/截图对照、视觉落地验收和修订工单。若 P5-05 后续真实任务试用暴露问题，则改排 `P5-05R - Guanghan Art Production Skill revision`。
- **禁止事项**：不要批量创建 Skill；不要把项目当前文件列表写死为长期真相；不要用 Skill 取代 ACTIVE_TASKS、CURRENT、用户任务范围或 push/tag 授权；不要在 P5-01 之后自动开始 P5-02。
- **验证方法**：每个 Skill 先 `draft`，真实任务试用后为 `trial`，至少一次高价值或两次重复成功后才标 `validated`，过期则 `deprecated`。

## Phase 6 · 双 Agent 试运行（验证流程本身）— IN PROGRESS（P6-01 COMPLETE，2026-07-13）
- **P6-01 状态**：COMPLETE。首次真实 field validation 记录在 `P6_01_AGENT_COLLABORATION_FIELD_VALIDATION.md`；以 Codex/Claude Code 的新会话 Bootstrap、P5-08 任务登记/阻塞/恢复/关闭与独立 reviewer 边界为证据，主要验证 `task-baseline-and-lock`。文档/Git scope、Godot 4.7 editor/smoke 与 Claude Code read-only review 均通过；本轮仅治理 Markdown，不升级任何 Skill，不开始 P6-02，不 push/tag。
- **目标**：用两个真正独立的小任务实测 AGENT_WORKFLOW 模式 C。
- **前置条件**：Phase 0-5 关键项完成；ACTIVE_TASKS 模板就位。
- **具体任务**：
  1. 选两个满足全部 6 条并行条件的小任务（如：一个改独立 UI 面板、一个加一条 PenaltyDatabase 数据），确保不碰同一文件/autoload/存档/公共场景。
  2. 各建独立分支+worktree，登记 ACTIVE_TASKS。
  3. 走完锁→实现→交接→合并→组合树验证全流程。
- **禁止事项**：并行改一级共享文件；擅自覆盖对方合并冲突。
- **验证方法**：合并后 `main` 完整回归；两任务组合正确。
- **完成标准**：一次成功的无冲突并行 + 合并 + 组合验证。
- **回滚方案**：任一分支可弃（未合入 main）。
- **风险**：任务其实不独立（隐藏依赖）→ 试运行前用并行 6 条件自查。

---

## 依赖与顺序小结
Phase 0 →（1 与 2 可并行，均低风险）→ 3（逐系统）→ 4（逐脚本，依赖 3）；5 可与 3/4 并行；6 最后。
**先做仓库卫生和文档治理拿到低风险收益，再碰 Manager/存档/大脚本这些高风险区。**

---

## 附录 A · 治理待办 backlog（deferred issues）

> 审计/复核中发现但**当前刻意不修**的问题，记录在此避免遗漏，处置留到对应 Phase 或专项任务。
> 记录 ≠ 授权修改；动这些之前仍按共用文件/存档规则走。

### 月面地表（NearBaseChunk 复核期发现，来源：Sprint 06.7 之后的月面分块工作）
1. **EVA activity 名称不一致**：`scripts/surface/lunar_surface_scene.gd` 调 `consume_suit_resources("eva_move" / "eva_idle")`，但 `SuitManager.ACTIVITY_RATES` 只有 `indoor_worn / eva_normal / eva_heavy`，故这两个名字静默回退到 `eva_normal`——move 与 idle 当前耗氧/耗电相同。修的时候要决定是"给 SuitManager 加 eva_move/eva_idle 速率"还是"地表改用现有 activity 名"，属改 Manager，走系统边界规则。
2. **HUD 返航估算与真实耗氧模型不一致**：`_oxygen_needed_to_return()` 用按像素线性估算（`dist × 0.012`），而真实消耗主要按**时间 × activity rate**结算。导致"该返航"警告偏保守，与实际可走距离脱节。标定时两者应统一到同一模型。
3. **地表玩家位置与 Chunk 状态尚未持久化**：当前地表场景完全不保存玩家位置。未来区域存档至少需要：`current_region_id` / `current_chunk_id` / `player_local_position` / `chunk_state`。属正式存档结构扩展，动之前先停下确认（勿擅改存档 schema）。

> 归属：#1 属 Phase 3（系统边界/Manager）；#2 属数值标定（试玩后）；#3 属 Phase 3 存档边界。三项均**不**在月面分块结构的本轮范围内。
# P3-03b Completion Note (2026-07-12)

- P3-03b is complete: non-Autoload `FullSaveOrchestrator`, authoritative `user://saves/full_save.json`, schema v1, provider manifest, explicit restore order, atomic write, legacy sprint06 best-effort, and compatibility mirror finalize are implemented.
- Verification: P3-03b 50/50 and P3-03a regression 39/39.
- Remaining Phase 3 order: P3-03c Manager self-save downgrade next, then P3-03d checkpoint scope trimming. Manager self-save still exists and the P1 multi-source risk is only partially mitigated, not fully gone.

# P3-03c Status Note (2026-07-12)

- P3-03c code/docs are implemented: formal core Manager self-saves are downgraded from restore authority by making local `load_state()` skip after Full Restore in-progress/completed state.
- `full_save.json` remains the formal continue/restore truth source. Manager-local files remain for fallback/debug/write-through compatibility.
- `main.gd` formal continue no longer calls `TrainingManager.load_progress()`; training/dev legacy APIs remain.
- P3-03cV found and fixed the lifecycle gap where a completed Full Restore could otherwise suppress Manager-local fallback for the rest of the process. Runtime verification now passes: Godot editor parse EXIT 0, Godot headless smoke EXIT 0, P3-03a 39/39, P3-03b 50/50, P3-03c 33/33, and real saves SHA stayed unchanged from the pre-test baseline.
- Remaining Phase 3 order: P3-03d checkpoint scope trimming is ready to schedule next; it was not started during P3-03cV.

# P3-03d Completion Note (2026-07-12)

- P3-03d is complete: Training Checkpoint is scoped to training-owned data only, legacy global fields are metadata-only, and `save_progress()` strips global Manager snapshots.
- Full Save remains the only formal complete-progress restore source. `sprint06_progress.json` no longer serves as automatic fallback for missing `full_save.json`; explicit legacy read remains available, but formal restore rejects legacy sources.
- Verification: Godot editor parse EXIT 0; Godot headless smoke EXIT 0; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; P3-03d 25/25; real saves SHA unchanged from pre-test baseline.
- Remaining Phase 3 order: P3-03 can close after review; P3-04 is ready to schedule next.

# P3-04 Completion Note (2026-07-12)

- P3-04 is complete: Manager responsibility overlap cleanup clarified current canonical owners and mirror/transfer boundaries without changing schemas, scenes, gameplay values, or `project.godot`.
- Inventory/Backpack/Storage: current design is `InventoryManager` for quantity global goods, `BackpackManager` for player carried slots, and `StorageManager` for base storage slots. Backpack/Storage transfers now expose source/destination/rollback metadata while preserving existing atomic rollback behavior.
- Time: formal mission actions route to `TimeManager`; training actions route to `TrainingTimeManager`; training completion still does not implicitly sync formal time.
- Mirrors: Power -> BaseStatus and Suit -> PlayerState are documented one-way compatibility mirrors with mirror-specific APIs and compatibility wrappers.
- Door: training map remains connected to `DoorStateManager`; formal old-base Door integration remains out of scope and should be handled by a later feature task, not by P3-04 cleanup.
- Verification: Godot editor parse EXIT 0; Godot headless smoke EXIT 0; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; P3-03d 25/25; P3-04 33/33; real saves SHA unchanged from pre-test baseline.
- Remaining Phase 3 order: P3-05 legacy isolation is ready to schedule next.

# P3-05 Completion Note (2026-07-12)

- P3-05 is complete: legacy sandbox (`main.gd`) and arrival prototype (`arrival_landing_scene.gd`) runtime paths are isolated from formal autoloads, Full Save, and the formal continue flow — without deleting legacy, integrating formal-base Door, or changing any schema/gameplay/`project.godot`.
- Same-name isolation: the one real collision (local `TimeManager` node vs `/root/TimeManager`) is resolved by renaming local sandbox/arrival manager nodes to `Sandbox…` / `ArrivalPrototype…`; safe because they are accessed only via member variables (zero node-name path lookups). Adapted from the GPT spec: no new `is_legacy_runtime` mode framework was added — isolation already holds structurally, so only naming + scope comments + a focused test were needed.
- Legacy save isolation verified and documented: distinct file namespaces; `FullSaveOrchestrator` never reads arrival/sandbox files and rejects legacy sprint06 sources; legacy saves never write `full_save.json`. Formal continue depends only on Full Save / Training; the legacy sandbox-slot fallback is a commented last resort.
- Reachability resolved: `ArrivalLandingScene` = DEV_ONLY (`main.gd:3751`); arrival genuinely calls `game_state_manager` (prior UNKNOWN resolved). sandbox/arrival not reachable from the formal Continue/New-Game path.
- Verification: Godot editor parse EXIT 0; Godot headless smoke EXIT 0; P3-05 32/32; P3-03a 39/39; P3-03b 50/50; P3-03c 33/33; P3-03d 25/25; P3-04 33/33; real saves SHA unchanged.
- Remaining Phase 3 order: **P3-06 (Phase 3 regression sweep + closure)** is ready to schedule next. ~~Phase 3 is NOT closed yet.~~ (superseded by the P3-06 note below.) Deferred beyond Phase 3: legacy file deletion, DoorState formal-base integration, `main.gd` large-script split (Phase 4).

# P3-06 Completion Note (2026-07-12) — Phase 3 CLOSED

- **Phase 3 is COMPLETE.** Full regression re-run: P3-03a 39/39, P3-03b 50/50, P3-03c 33/33, P3-03d 25/25, P3-04 33/33, P3-05 36/36; Godot editor/smoke EXIT 0; real `user://saves/` SHA-256 unchanged; no residue.
- Minimal regression fix this round: renamed a residual legacy node-name collision in `arrival_cinematic_scene.gd` (missed by P3-05). Repo-wide `name = "TimeManager"/"GameStateManager"` = 0. This is the only code change in P3-06; everything else is verification + documentation.
- **Closed risks**: multi-truth-source P1; Power/Suit mirror restore gaps; checkpoint over-restore; legacy runtime confusion + node-name collision; formal-continue-vs-legacy-restore mixing; manager-local late overwrite of Full Restore.
- **Deferred (NOT closed, tracked, not regressions)**: DoorState formal old-base integration (feature work) → DEFERRED_TO_FEATURE_WORK; `main.gd` (5165) + `sprint06_base_scene.gd` large-script split → **DEFERRED_TO_PHASE_4**; legacy file physical deletion → DEFERRED_TO_FEATURE_WORK; `interaction_detector` orphan + `BaseInterior_Test` entry (UNKNOWN); product-level Inventory↔Backpack relationship.
- **Next phase at that time was Phase 4 — 大型脚本渐进拆分**（now complete as of P4-08; next current phase is Phase 5 — Skill 建设）。
- Closure report: `PHASE_3_CLOSURE_REPORT.md`. Completion commit: this task's closing commit (`fix: close Phase 3 regression gaps`).
