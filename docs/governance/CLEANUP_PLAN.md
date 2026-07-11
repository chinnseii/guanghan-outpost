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
  1. README 收敛为门面（是什么/怎么跑/指向 BRIEF·SYSTEMS_REFERENCE·CURRENT），把"当前状态"段移除，状态只留 CURRENT.md。
  2. `ITERATION_PLAN.md` 从项目根迁入 `docs/`，标注为历史归档。
  3. 给 `docs/sprints/*`、`LEGACY_SANDBOX_PROTOTYPE.md` 明确"历史归档"标头。
  4. 08.x 收尾后合并/归档 `pre09_flow_audit.md` 与 `KNOWN_ISSUES_PRE09.md`。
- **禁止事项**：删仍可能被引用的文档；改 PROJECT_BRIEF / SYSTEMS_REFERENCE 的**内容**（只加归位标注）。
- **验证方法**：人工通读；确认无文档互相矛盾；链接不断。
- **完成标准**：产品/系统/数值/状态/历史/证据六类各有唯一主文档。
- **回滚方案**：文档改动 `git revert`；迁移用 `git mv` 保留历史。
- **风险**：迁移破坏他处引用路径 → 迁移后全仓 grep 旧路径。

## Phase 3 · 系统边界清洗（中高风险，逐系统）
- **目标**：厘清 Manager 职责与存档真相源，不重写。
- **前置条件**：Phase 0-2 完成；SYSTEM_REGISTRY / LEGACY_REGISTRY 已评审。
- **具体任务**（每个系统独立 PR，串行）：
  1. **文档化存档真相源**：为每个状态明确"唯一真相源 = 该 Manager 自存 or 训练/ sprint06 快照"，写进 SYSTEMS_REFERENCE，消除 LEGACY_REGISTRY §B2 的双重记账不清。
  2. **Inventory/Backpack/Storage 边界核实**：确认是否存在双记账（SYSTEM_REGISTRY §B2 UNKNOWN），只在确认后再谈是否收敛。
  3. **UNKNOWN 结案**：`interaction_detector.gd` 是否 orphan、`BaseInterior_Test.tscn`/`ArrivalLandingScene` 是否可达、`arrival` 对 `game_state_manager` 的真实用法（LEGACY_REGISTRY §C）。逐一给证据。
  4. **DoorStateManager 接入正式导航**（`CURRENT.md:54` 已知未接）——属功能，**排到治理期之后**，此处仅登记。
- **禁止事项**：一次动多个 Manager 的 serialize；把遗留 A2 脚本"顺手删"（仍被 main/arrival 引用）；改存档结构不做 remap。
- **验证方法**：改任一 serialize/deserialize 后，三处存档（自存/训练/sprint06）+ 旧存档 remap 全测；`lunar-base-verify` 全流程。
- **完成标准**：每个状态有书面唯一真相源；UNKNOWN 清零或有明确结论。
- **回滚方案**：逐系统 PR，可单独 revert；存档结构改动保留旧字段读兼容。
- **风险**：🔴 存档兼容——改 schema 会让旧存档失效；必须保留读旧路径。

## Phase 4 · 大型脚本渐进拆分（高风险，一次一个职责）
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

## Phase 5 · Skill 建设（低风险）
- **目标**：按 SKILL_ARCHITECTURE 分批落地。
- **前置条件**：治理文档稳定。
- **具体任务**：
  1. 第一批：`task-intake`、`change-planning`、`handoff`（+已有 conventions/verify）。
  2. 第二批：`feature-design`、`product-review`。
  3. 治理期临时：`architecture-audit`、`cleanup-migration`。
- **禁止事项**：为凑数建 Skill；两个 Skill 抢同一阶段；硬编码本机绝对路径。
- **验证方法**：每个 Skill 的 description 做误触发检查（skill-creator 评测）。
- **完成标准**：闭环"入口→规划→写码→验证→交接"可用。
- **回滚方案**：删 Skill 目录，无代码副作用。
- **风险**：description 太宽导致误触发 → 收紧。

## Phase 6 · 双 Agent 试运行（验证流程本身）
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
