# DOCUMENT_GOVERNANCE_AUDIT · 文档治理审计与迁移依据（Phase 2）

> Phase 2 治理审计 · 2026-07-11 · 基线 `repository-hygiene-complete-2026-07-11`（`3a69f90`）
> **生命周期**：本文件是 Phase 2 文档治理的**审计与迁移依据**——记录发现、冲突、证据、用户决策与迁移批次。Phase 2 完成后转为**历史治理记录**；长期有效的"当前文档职责与索引"由 `docs/governance/DOCUMENT_REGISTRY.md` 维护。未来 Agent **不要**把本审计当作永久实时注册表。
> P2-01 为只读审计；P2-02（本次）固化用户决策并作为 Phase 2 正式执行基线。

## 1. 审计范围与总量
- 全部 tracked 文档：44 个 `.md`（无 txt/rst/json/yaml）；根级 2（README.md、ITERATION_PLAN.md）+ `docs/` 下 42；合计约 11,000+ 行。
- **无 `CLAUDE.md`、无 `AGENTS.md`**（协作/仓库规则实际在 `docs/handoff/COLLABORATION_RULES.md` 与 `docs/governance/*`）。
- 最大文档：`SYSTEMS_REFERENCE_FOR_DESIGN.md` 2812、`ITERATION_PLAN.md` 1460、`SPRINT_04_NATIONAL_TRAINING.md` 1004、`README.md` 555、`Sprint04_Module02_AirlockProcedure.md` 524。

## 2. 用户决策（Phase 2 正式治理原则）

1. **历史 Sprint 文档**：**全部保留并归档**（不只留里程碑版）。理由：含实现过程/验收依据/历史问题/决策，对回归、追责、理解遗留系统有价值；归档后不再承担当前真相、不增日常上下文负担。归入 `docs/archive/sprints/`。
2. **CURRENT 的 changelog**：允许保留**极短的"最近稳定基线"区**（当前稳定 commit / tag / 最近完成 Phase / 最近一次重大结构变化），**不**维护长期 changelog、完整 Sprint 历史、数十条版本日志或久已完成的工作。
3. **README 读者**：主要面向**新加入的开发协作者**，同时保留**一小段面向普通读者的游戏概念介绍**。README 核心职责 = ①项目是什么 ②当前技术栈 ③如何启动 ④当前稳定状态 ⑤权威文档导航 ⑥最小协作入口。**不再承担**：完整 Sprint 历史 / 完整 Manager 清单 / 长篇系统实现 / 详细协作规章 / 多份当前状态 / 旧功能流水账。
4. **验收截图与 demo 报告**：**当前全部保留、不设自动删除期限**（存储成本可控、是产品验收与视觉方向证据、回归时有对照价值）；但属历史证据、非当前状态真相。归入 `docs/archive/reviews/` 与 `docs/archive/demos/`；**图片**继续留在 `docs/screenshots/`、`docs/art/`（除非后续另做素材治理）。
5. **archive 目录**：正式采用分类归档结构（**本轮只写方案，不创建、不移动**）：
   ```
   docs/archive/
   ├── plans/     # ITERATION_PLAN 等旧计划
   ├── sprints/   # docs/sprints/* + SPRINT_01_FOUNDATION
   ├── reviews/   # pre09_flow_audit / SPRINT_01_FOUNDATION_REVIEW
   └── demos/     # demo 测试计划 / 已知问题
   ```

## 3. 六类真相源（最终确定）

| 类 | 唯一文件 | 职责 |
|---|---|---|
| **A 产品方向** | `docs/PROJECT_BRIEF.md` | 产品愿景 / 核心主题 / 玩家身份 / 体验调性 / 设计原则 / 产品非目标 |
| **B 当前项目状态** | `docs/handoff/CURRENT.md` | 当前阶段 / 当前稳定基线 / 最近里程碑 / 当前风险 / 下一步；**不**承担完整历史（含决策 2 的极短基线区） |
| **C 系统真相（分层）** | 状态/边界 = `docs/governance/SYSTEM_REGISTRY.md`；行为/设计 = `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md` | REGISTRY：系统是否现役 / Manager 所属 / 职责边界 / owner / legacy-compat 状态 / 系统间关系。REFERENCE：玩法规则 / 数值 / 接口行为 / 设计约束 / 具体如何工作。**两者须在 P2-05 互加引用与职责声明** |
| **D 场景结构** | `docs/governance/SCENE_REGISTRY.md` | 主场景 / 场景入口 / 场景状态 / 场景职责 / legacy 场景 / Chunk 与地图结构 |
| **E 当前任务** | `docs/handoff/ACTIVE_TASKS.md` | 当前任务 / owner / 分支-worktree / 文件锁 / 状态 / 阻塞 / 交接信息（P2-06 正式创建，见 §5） |
| **F 历史记录** | `docs/archive/`（plans/sprints/reviews/demos） | Sprint / review / report / 旧计划 |

> **命名纪律**：治理文档一律用真实文件名 `SYSTEMS_REFERENCE_FOR_DESIGN.md`，**不再**用含糊简称 "SYSTEMS_REFERENCE"。

## 4. DOCUMENT_REGISTRY 与本审计的关系（订正）
早期草稿误将 `DOCUMENT_REGISTRY.md` 标为 `DUPLICATE`。**订正**——二者职责不同，**都保留、不合并、不删除**：

| 文件 | 性质 | 状态 | 动作 |
|---|---|---|---|
| `DOCUMENT_GOVERNANCE_AUDIT.md`（本文件） | Phase 2 治理审计报告：发现/冲突/证据/用户决策/迁移批次；Phase 2 完成后转历史；不需日常维护 | `ACTIVE_SUPPORTING`（Phase 2 后转 `HISTORICAL`） | KEEP_AS_SUPPORT |
| `DOCUMENT_REGISTRY.md` | 长期维护的**当前文档注册表**：有效文档 / 职责 / 权威等级 / 生命周期；文档新增/重写/归档时持续更新；Agent 用它快速判断该读哪份 | `AUTHORITATIVE` | **REWRITE**（P2-09，归档+引用修复完成后） |

## 5. ACTIVE_TASKS 落地时机（订正）
早期草稿写"进入并行/交替时再落地"。**订正为：Phase 2 中正式创建 `docs/handoff/ACTIVE_TASKS.md`（P2-06），即使无进行中任务也明确记录 EMPTY/IDLE 状态。**
理由：Claude 与 Codex 已存在交替工作需求；模板不能承担当前任务真相；空任务板也能明确"当前无活动任务"；避免 Agent 把旧交接/模板误当现役任务。
长期关系：`ACTIVE_TASKS_TEMPLATE.md` = 建新任务板的结构模板；`ACTIVE_TASKS.md` = 当前任务/锁/负责人/状态的唯一真相。

## 6. 文档分类表（修订后状态）

> 每份文档保留一个**主要状态**；建议动作独立记录（不为凑数强贴单一风险标签）。

| 路径 | 主要状态 | 建议动作 |
|---|---|---|
| `docs/PROJECT_BRIEF.md` | AUTHORITATIVE | KEEP_AS_AUTHORITY（A 产品） |
| `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md` | AUTHORITATIVE | KEEP_AS_AUTHORITY（C 行为，P2-05 加边界声明） |
| `docs/governance/SYSTEM_REGISTRY.md` | AUTHORITATIVE | KEEP_AS_AUTHORITY（C 状态，P2-05 加边界声明） |
| `docs/governance/SCENE_REGISTRY.md` | AUTHORITATIVE | KEEP_AS_AUTHORITY（D 场景） |
| `docs/handoff/CURRENT.md` | AUTHORITATIVE | KEEP_AS_AUTHORITY（B 状态，P2-04 校正+极短基线区） |
| `docs/handoff/COLLABORATION_RULES.md` | AUTHORITATIVE | KEEP_AS_AUTHORITY（协作，与 AGENT_WORKFLOW 分工） |
| `docs/governance/DOCUMENT_REGISTRY.md` | AUTHORITATIVE | **REWRITE**（P2-09；当前文档注册表，非重复） |
| `docs/governance/DOCUMENT_GOVERNANCE_AUDIT.md`（本文件） | ACTIVE_SUPPORTING | KEEP_AS_SUPPORT（Phase 2 后→HISTORICAL） |
| `docs/governance/{PROJECT_MAP,LEGACY_REGISTRY,SHARED_FILE_REGISTRY,AGENT_WORKFLOW,SKILL_ARCHITECTURE,CLEANUP_PLAN,REPOSITORY_HYGIENE_AUDIT}.md` | ACTIVE_SUPPORTING | KEEP_AS_SUPPORT |
| `docs/handoff/ACTIVE_TASKS_TEMPLATE.md` | ACTIVE_SUPPORTING | KEEP_AS_SUPPORT（据此在 P2-06 建 `ACTIVE_TASKS.md`） |
| `docs/SPRITE_GUIDE.md` / `docs/text/PROLOGUE_TEXT_STYLE_GUIDE.md` | ACTIVE_SUPPORTING | KEEP_AS_SUPPORT（美术/文案规范） |
| `docs/design/LUNAR_SURFACE_MAP.md` | ACTIVE_SUPPORTING | KEEP_AS_SUPPORT（在建；完成后要点并入 SYSTEMS_REFERENCE_FOR_DESIGN） |
| `docs/art/*/README.md`（6）+ `docs/art/ASSET_OLD_BASE_ART_SLICE.md` | ACTIVE_SUPPORTING | KEEP_AS_SUPPORT（随资产走） |
| `docs/LEGACY_SANDBOX_PROTOTYPE.md` | HISTORICAL(权威) | KEEP_AS_SUPPORT（遗留解释唯一权威，勿删/勿归档失联） |
| `README.md` | **AUTHORITATIVE_ENTRY**（P2-03B 后：开发协作者入口/导航页，不再承担当前状态真相） | KEEP_AS_AUTHORITY（入口页；曾 CONFLICTING，已 REWRITE） |
| `ITERATION_PLAN.md` | **HISTORICAL/STALE** | **ARCHIVE**（P2-07 → `docs/archive/plans/`；主要动作是归档） |
| `docs/SPRINT_01_FOUNDATION.md` | HISTORICAL | ARCHIVE（→ sprints/） |
| `docs/reports/SPRINT_01_FOUNDATION_REVIEW.md` | HISTORICAL | ARCHIVE（→ reviews/） |
| `docs/reviews/pre09_flow_audit.md` | HISTORICAL | ARCHIVE（→ reviews/） |
| `docs/demo/{FIRST_PLAYABLE_DEMO_TEST_PLAN,KNOWN_ISSUES_PRE09}.md` | HISTORICAL | ARCHIVE（→ demos/；KNOWN_ISSUES 部分并入 CURRENT backlog） |
| `docs/sprints/*.md`（9，含 Sprint04_Module02） | HISTORICAL | ARCHIVE（→ sprints/） |

### 状态统计（修订前 → 修订后）
- AUTHORITATIVE：6 → **7**（DOCUMENT_REGISTRY 由 DUPLICATE 改为 AUTHORITATIVE）。
- ACTIVE_SUPPORTING：~18 → ~18（本审计明确列为 ACTIVE_SUPPORTING）。
- HISTORICAL：~15 → ~15（含 ITERATION_PLAN，主要动作 ARCHIVE）。
- CONFLICTING：1（README）。 DUPLICATE：1 → **0**（订正）。 STALE：并入 ITERATION_PLAN 的 HISTORICAL 口径。 UNKNOWN：0。
- **README 判定口径**：主状态记 `CONFLICTING`（顶部进度与 CURRENT 冲突 + 多份当前状态并存），动作 `REWRITE`；不重复记 STALE。
- **ITERATION_PLAN 判定口径**：主状态记 `HISTORICAL`（append-only 历史日志），其"当前下一步"失效属 STALE 特征，动作统一 `ARCHIVE`。

## 7. 重复 / 冲突 / 失效引用（保留自 P2-01）
- **重复**：Manager 列表（权威只应 SYSTEM_REGISTRY+SYSTEMS_REFERENCE_FOR_DESIGN）；Sprint 历史（README 复制了 `docs/sprints/*`）；"当前状态"（README×CURRENT×ITERATION_PLAN）；协作规则（README 复制 COLLABORATION_RULES）。
- **冲突**：README 顶部进度（08.7.x/"V0.6-dev"）vs CURRENT（07-08 更近、约定滚动源）→ **CURRENT 可信**；ITERATION_PLAN L832"当前下一步" vs CLEANUP_PLAN/CURRENT → **前者失效**。无数值/存档实质矛盾。
- **README REWRITE 前置**：Sprint 03/05 历史**只在 README** 有（无独立 sprint 文档）→ 收敛前必须先把这两段抽出保存（见 §8）。
- 🔴 **失效引用**：`docs/sprints/SPRINT_04_NATIONAL_TRAINING.md:13` → 不存在的 `SPRINT_03_PROLOGUE_APPLICATION.md`。
- **命名不一致**：治理文档简称 "SYSTEMS_REFERENCE" ≠ 真实文件名（P2-05 修正）。

## 8. Sprint 03 / 05 引用处理建议（本轮不修）
记录已发现的死链（SPRINT_04→SPRINT_03）。**本轮不改链接**，留 P2-07/P2-08：
1. 先确认 README 中 Sprint 03 的历史内容；
2. 判断是否需提取成独立历史文档；
3. 若内容足够且引用有价值 → 创建**归档版** Sprint 03（放 `docs/archive/sprints/`）；
4. 若只是误写 → 改指实际存在的历史入口；
5. **不得凭空创建没有事实内容的 Sprint 报告**。
6. Sprint 05 同样检查，但**不因编号缺失就机械补文件**。

## 9. Phase 2 执行批次（修订后顺序）

| 批次 | 内容 | 状态 | 允许改文件 | 依赖 / 并行 |
|---|---|---|---|---|
| P2-01 | 文档全量只读审计 | ✅ 完成 | 仅新增本审计 | — |
| P2-02 | 真相源确认与审计基线提交 | 🔄 本轮 | 仅本审计 | — |
| P2-03A | 保全 README-only Sprint 历史 | ✅ 完成 | 新增 `docs/archive/sprints/*` + 本审计 | 先于 P2-03B |
| P2-03B | README 收敛 | ✅ 完成 | README.md（555→89 行） | — |
| P2-04 | CURRENT 校正 | 待 | CURRENT.md | **在 P2-05 系统事实确认后定稿** |
| P2-05 | 系统文档职责声明 + 命名/引用修复 | 待 | SYSTEM_REGISTRY + SYSTEMS_REFERENCE_FOR_DESIGN | 先于 P2-04 定稿 |
| P2-06 | ACTIVE_TASKS 正式落地（EMPTY/IDLE） | 待 | 新建 `docs/handoff/ACTIVE_TASKS.md` | 独立，可与 P2-03 并行 |
| P2-07 | 历史文档分类归档 | 待 | `git mv` → `docs/archive/{plans,sprints,reviews,demos}/` | **先于 P2-08** |
| P2-08 | 全仓文档链接与导航修复 | 待 | 各文档引用 | **必须在 P2-07 之后** |
| P2-09 | DOCUMENT_REGISTRY 重写 | 待 | DOCUMENT_REGISTRY.md | **在归档+引用修复之后**（否则注册表立即过期） |
| P2-10 | 文档治理验收、push 与 tag | 待 | 收口提交 + tag | 最后统一验收 |

**并行/依赖小结**：P2-03 ∥ P2-06（文件不重叠）；P2-04 在 P2-05 之后定稿；P2-07 → P2-08 → P2-09（严格串行，路径先稳定再修引用再更新注册表）；P2-10 最后。每批独立提交，不为减批次混入大量文件。

## 10. 待用户决策（剩余）
五项主决策已在 §2 固化。**剩余仅一项**需在 P2-04 时确认：
- CURRENT 的"最近稳定基线区"具体保留哪几条（当前 tag `repository-hygiene-complete-2026-07-11` + 最近完成 Phase 1 是默认候选）——可在 P2-04 顺带确认，非阻塞。

## 11. P2-03A 执行记录 · README-only Sprint 历史保全

**目标**：在 README 收敛（P2-03B）前，确保 README 中无独立文档承载的 Sprint 历史不丢失。

**关键发现**：`ITERATION_PLAN.md` 内含一份**近乎完整的平行 Sprint 变更日志**（Sprint 02/03/04/05A + 06/07/08），与 README 的 Sprint 段**互补**（README 偏 UI/文案措辞，ITERATION_PLAN 偏文件路径/存档字段）。由于 ITERATION_PLAN 后续只归档、不删除，README 的 Sprint 历史**substantively 已被 ITERATION_PLAN 承载**。

**README Sprint 段来源映射**：

| README 段 | 对应 Sprint | 独立 sprint 文档? | ITERATION_PLAN 覆盖 | 分类 | 处理 |
|---|---|---|---|---|---|
| L335-389 Arrival Prototype/Rev01/Split/Polish | Sprint 02 | 无 | **完整**（L851-930，含同样的构图/氛围/文件细节） | FULLY_DUPLICATED | 不新建（由 ITERATION_PLAN 归档承载）；README 可安全裁剪 |
| L390-447 Prologue&Application/Rev02/APP-002A/Patch/Bugfix | Sprint 03 | 无 | 大部分（L931-1023，偏实现细节；README 偏 UI 文案） | PARTIALLY_DUPLICATED | **已提取** `docs/archive/sprints/SPRINT_03_PROLOGUE_APPLICATION.md`（合并两源；兼作 SPRINT_04 失效引用的目标名） |
| L285-321 Sprint 05A 竖切打磨 | Sprint 05A | 无 | 高度一致（L1293-1322） | PARTIALLY_DUPLICATED | **已提取** `docs/archive/sprints/SPRINT_05A_VERTICAL_SLICE_POLISH.md`（合并两源） |
| Sprint 04/06/07/08 段 | 04/06/07/08 | **有**（`docs/sprints/*`） | 有 | FULLY_DUPLICATED | 不处理（已有独立文档） |
| 顶部"当前状态"/运行方式/协作 | — | — | — | CURRENT_INFO / GENERAL_PROJECT_INFO | README 收敛时归位到 CURRENT/门面 |

**分类统计**：FULLY_DUPLICATED（Sprint 02 + 04/06/07/08）、PARTIALLY_DUPLICATED（Sprint 03、05A）、README_ONLY（0，无任何 Sprint 事实只在 README 而不在 ITERATION_PLAN）、NEEDS_REVIEW（0）。

**新增文件（仅 2，无凭空补写）**：
- `docs/archive/sprints/SPRINT_03_PROLOGUE_APPLICATION.md`（源：README + ITERATION_PLAN Sprint 03）
- `docs/archive/sprints/SPRINT_05A_VERTICAL_SLICE_POLISH.md`（源：README + ITERATION_PLAN Sprint 05A）
- 新建目录 `docs/archive/`、`docs/archive/sprints/`（plans/reviews/demos 留待后续实际归档时创建，避免空目录）。

**未提取项及理由**：Sprint 02 = FULLY_DUPLICATED（ITERATION_PLAN L851-930 已含相同构图/氛围/文件细节，且 ITERATION_PLAN 后续归档保留）→ 不建冗余文件；无独立"Sprint 05"（仅 05A），不臆造。

**README 收敛无信息丢失前提**：**已满足**。README 待裁剪的 Sprint 历史，或已有独立 sprint 文档（04/06/07/08）、或由 ITERATION_PLAN 承载（02，随后归档）、或已提取为专门归档（03/05A）。P2-03B 可安全进行。

**本轮不修改 README、不修 SPRINT_04 失效引用**（引用修复归 P2-08）。

## 12. P2-03B 执行记录 · README 收敛

- **规模**：README `555 → 89` 行（约 −84%）。目标区间 120-220 未强制；89 行更短但覆盖全部 8 项必需职责（介绍/状态摘要/技术栈/启动/结构/文档导航/协作规则/历史入口），无必需内容遗漏，属有意精简。
- **删除的职责**：4 段"当前状态"、Sprint 02-08 详细变更流水账、旧沙盒/系统实现细节、重复 Manager 清单、重复协作规章、失效的"下一步建议"、过时版本号（如 "V0.6-dev"）。
- **保留/重述的职责**：项目一句话概念、当前状态**摘要**（指向 CURRENT）、技术栈（Godot 4.7/GDScript/2D 像素/Git/Claude+Codex）、快速启动+验证命令、关键目录、权威文档导航表、最小协作规则（6 条）、历史入口。
- **README 状态转变**：`CONFLICTING` → `AUTHORITATIVE_ENTRY`（开发协作者入口/导航页）；**不再承担当前状态真相**（明确写"最新状态以 CURRENT.md 为准"）。
- **历史保全确认**：Sprint 02（ITERATION_PLAN，后续归档）/ 03（`docs/archive/sprints/SPRINT_03_PROLOGUE_APPLICATION.md`）/ 04/06/07/08（`docs/sprints/*`）/ 05A（`docs/archive/sprints/SPRINT_05A_VERTICAL_SLICE_POLISH.md`）—— 均在位，README 删除的历史无一成为仓库唯一缺失。
- **链接**：README 16 个相对链接全部有效（含 `docs/archive/`、`docs/sprints/` 目录链接）；无 `CLAUDE.md`/`AGENTS.md`/裸 `SYSTEMS_REFERENCE.md` 链接；`ACTIVE_TASKS.md` 以文字说明"P2-06 创建"、未做失效链接。
- **下一批建议**：P2-05（系统文档职责声明 + 命名/引用修复）；可并行 P2-06（ACTIVE_TASKS 落地）。

## 附：本轮基线核验
- HEAD=`3a69f90`；main 与 origin/main 同步；tag `repository-hygiene-complete-2026-07-11` 指向 HEAD。
- 本轮仅修改本审计文档一个文件；未改/删/移动 README/CURRENT/ITERATION_PLAN/DOCUMENT_REGISTRY 或任何其他文档，未创建 archive，未移动历史文件，未改源码/场景/资源/配置。
