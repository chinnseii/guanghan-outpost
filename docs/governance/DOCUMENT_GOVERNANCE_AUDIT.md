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
- **命名不一致**：治理文档简称 "SYSTEMS_REFERENCE" ≠ 真实文件名 —— **P2-05 已修正**（CLEANUP_PLAN 3 处、SKILL_ARCHITECTURE 4 处；DOCUMENT_REGISTRY 3 处随其 P2-09 重写一并修）。

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
| P2-04 | CURRENT 校正 | ✅ 完成 | CURRENT.md（55→68 行，内容重构） | 在 P2-05 系统事实确认后定稿 |
| P2-05 | 系统文档职责声明 + 命名/引用修复 | ✅ 完成 | SYSTEM_REGISTRY + SYSTEMS_REFERENCE_FOR_DESIGN + CLEANUP_PLAN/SKILL_ARCHITECTURE 命名修复 | 先于 P2-04 定稿 |
| P2-06 | ACTIVE_TASKS 正式落地（IDLE） | ✅ 完成 | 新建 `docs/handoff/ACTIVE_TASKS.md` + 模板加指针 | 独立 |
| P2-07 | 历史文档分类归档 | ✅ 完成 | `git mv` 17 文档 → `docs/archive/{plans,sprints,reviews,demos}/` | **先于 P2-08** |
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

## 13. P2-05 执行记录 · 系统文档职责边界

**两份系统文档最终职责**（已在各自开头加"文档职责"声明 + 双向链接）：
- `SYSTEM_REGISTRY.md`（`docs/governance/`）：系统**身份/状态/边界/治理**——是否现役、对应 Manager/Autoload、数据所有权、依赖、迁移与治理风险。不承担玩法规则/数值/UI/接口示例。
- `SYSTEMS_REFERENCE_FOR_DESIGN.md`（`docs/handoff/`）：系统**玩法规则/数值/设计约束**——玩家如何感知、规则/阈值/数值、设计交互、UI/训练/反馈要求。不承担现役判定/生命周期/共用锁/owner/清理优先级；并声明"其脚本名仅表设计对应，不替代 REGISTRY 的现役判断"。

**双向引用**：REGISTRY → `../handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`；REFERENCE → `../governance/SYSTEM_REGISTRY.md`；均在文档靠前"文档职责"节，路径经验证可解析。含"该读哪份/冲突时以谁为准"的 Agent 阅读规则（写入两份声明，未新建规则文档）。

**命名引用审计**：搜索到 "SYSTEMS_REFERENCE" 简称 10 处（CLEANUP_PLAN 3 + SKILL_ARCHITECTURE 4 + DOCUMENT_REGISTRY 3）。**已修 7**（CLEANUP_PLAN、SKILL_ARCHITECTURE → 全名）；**保留/延后 3**（DOCUMENT_REGISTRY，随其 P2-09 重写一并修，避免重复 churn）。无错误 `.md` 路径链接、无失效链接。审计文档自身对 "SYSTEMS_REFERENCE" 的 meta 引述属描述问题本身，未改。

**内容冲突审计**（两份系统文档只读对比）：
- NO_CONFLICT：Manager 名称/现役状态/owner/存档归属主干一致。REFERENCE 对 `game_state_manager.gd`（"从未注册 autoload"）、`AreaManager`（"项目里不存在，未来若增"）的表述与 REGISTRY 判定**一致**，非冲突。
- TERMINOLOGY_MISMATCH：仅"SYSTEMS_REFERENCE"简称问题（已修）。
- RESPONSIBILITY_OVERLAP：两份都列 Manager——属**有意分层**（状态 vs 行为），已由职责声明澄清，非缺陷。
- STALE_REFERENCE：0。 FACT_CONFLICT：**0**。 NEEDS_REVIEW：0。

**留给 Phase 3**：无系统 owner/存档归属/现役判定/数值冲突需处理（本轮 0 项）。仅记一个非阻塞观察：`SYSTEMS_REFERENCE_FOR_DESIGN.md`（2800+ 行）偏长、含较多实现细节，未来可评估是否精简，但**本轮不动内容**。

**P2-04 前置条件**：满足——系统事实（现役/边界/数值分层）已确认无冲突，CURRENT 校正（P2-04）可据此定稿。

## 14. P2-04 执行记录 · CURRENT 校正

- **规模**：`CURRENT.md` 55 → 68 行（**内容重构**，非缩行——旧版是异常简短的 Sprint 级开发日志；行数略增，但删除了过期流水、补齐了标准状态结构）。
- **删除的过期职责**：2026-07-08 的 Sprint 级"本轮完成"（门/惩罚/训练交互实现细节）、"触碰的共用文件"逐条 diff、以及 **已失效的"工作区仍有大量 .import/.uid 噪声"**（Phase 1 已清零，属 STALE 移除）。
- **保留/重述**：当前阶段（Phase 2）、最近**已推送**稳定基线（commit `3a69f90` / tag `repository-hygiene-complete-2026-07-11`）、最近完成、当前工作、项目级风险（指向权威文档而非展开）、唯一下一步（P2-06）、6 项权威导航、更新规则。
- **CURRENT-unique 历史事实**（`git grep` 确认仅存于 CURRENT，本轮**保全**，未删）：① 验证 gotcha `--check-only --path .` 不带 `--script` 会挂住；② 用户"不主动截图"偏好。二者压缩保留在"沿用的工作约定"节，并标注为未来应迁入规范/协作文档的候选。
- **CURRENT 状态**：由旧的"Sprint 滚动日志"正式确立为 **AUTHORITATIVE**（当前状态唯一权威来源），不再承担完整历史/changelog/系统数值。
- **链接**：8 个相对链接全部有效；无 `ACTIVE_TASKS.md` 失效链接（文字标注 P2-06 创建）；用真实名 `SYSTEMS_REFERENCE_FOR_DESIGN.md`。
- **权威文档冲突**：核对 PROJECT_BRIEF / SYSTEM_REGISTRY / SYSTEMS_REFERENCE_FOR_DESIGN / SCENE_REGISTRY / CLEANUP_PLAN，无事实冲突；未修改任何权威系统文档。
- **P2-06 准入**：满足（可开始 ACTIVE_TASKS 落地）。

## 15. P2-06 执行记录 · ACTIVE_TASKS 正式落地

- **模板审计**：`ACTIVE_TASKS_TEMPLATE.md` 字段覆盖 owner/模式/branch/worktree/base-commit/objective/locked/allowed 文件/高风险共用类型/status/blockers/handoff/merge —— **SUFFICIENT**；仅补一行"本文件只是模板，当前状态见 ACTIVE_TASKS.md"指针（MINOR_UPDATE，§XIV 允许），未重写。与 `COLLABORATION_RULES.md` / `AGENT_WORKFLOW.md` 的单人/交替/并行/锁/合并结构一致，无冲突。
- **新建 `docs/handoff/ACTIVE_TASKS.md`（IDLE）**：Board Status `IDLE`、active `0`、locks `0`、handoffs `0`、branch `main`、创建基线 `fdd7422`。无虚构任务/owner/deadline/锁；未把 Phase 2 治理伪装成 Agent 执行任务。含状态枚举、owner/reviewer 规则（非固定角色）、文件锁高风险类别、字段清单、Operating Rules、Recently Closed（空）。
- **三份文档职责**：`CURRENT.md` = 项目级状态；`ACTIVE_TASKS.md` = 执行级状态（任务/锁/交接）；`ACTIVE_TASKS_TEMPLATE.md` = 条目结构模板。板 → 模板 + CURRENT 均建立链接；模板 → 板已补指针。
- **本轮未改** README / CURRENT / 系统文档（CURRENT 里"下一步 = P2-06"暂时落后一轮，按计划在后续状态批次/Phase 2 收口时更新，不在本轮扩范围）。
- **P2-07 准入**：满足。**从下一项真实任务起，必须在 `ACTIVE_TASKS.md` 登记**（含 owner / 锁 / 验证 / 交接）。

## 16. P2-07 执行记录 · 历史文档分类归档

**ACTIVE_TASKS 生命周期**：开工前登记 P2-07（board `ACTIVE`, 1 task, owner=Claude Code, reviewer=User, 锁 17 移动文档 + 板 + 本审计）→ 执行移动/验证 → 收工恢复 `IDLE`（0/0/0），P2-07 入 Recently Closed。**这是 ACTIVE_TASKS 落地后的首个正式任务。**

**归档统计（17 个，全部 Git R100 纯 rename）**：
- **plans（1）**：`ITERATION_PLAN.md` → `docs/archive/plans/`。
- **sprints（12）**：`docs/sprints/*`（11）+ `docs/SPRINT_01_FOUNDATION.md` → `docs/archive/sprints/`。
- **reviews（2）**：`SPRINT_01_FOUNDATION_REVIEW.md`、`pre09_flow_audit.md` → `docs/archive/reviews/`。
- **demos（2）**：`FIRST_PLAYABLE_DEMO_TEST_PLAN.md`、`KNOWN_ISSUES_PRE09.md` → `docs/archive/demos/`。
- 新建子目录 `plans/reviews/demos`（`sprints/` 已存在，含 P2-03A 的 SPRINT_03/05A，原位保留）。

**KEEP_CURRENT（未移动）**：README、PROJECT_BRIEF、CURRENT、ACTIVE_TASKS(+模板)、全部 `docs/governance/*`、SYSTEMS_REFERENCE_FOR_DESIGN、`LEGACY_SANDBOX_PROTOTYPE.md`（遗留解释权威）、`SPRITE_GUIDE.md`、`docs/text/PROLOGUE_TEXT_STYLE_GUIDE.md`、`docs/design/LUNAR_SURFACE_MAP.md`、`docs/art/**`。NEEDS_REVIEW：0。

**内容安全**：17/17 移动前后 SHA-256 **完全一致**（before==after 哈希集合相同）；Git 全部识别为 `R100`（0% 内容差异）；无正文修改；`git diff --check` 干净。

**临时失效引用（P2-08 输入，本轮不修）**：
- 当前入口断链 **3**（`README.md:89` `docs/sprints/`；`CURRENT.md:4` 与 `:57` `../sprints/`——`docs/sprints/` 已空、随提交消失；`docs/archive/` 链接仍有效）。
- 历史内部断链 **1**（`docs/archive/sprints/SPRINT_04_NATIONAL_TRAINING.md:13` → `SPRINT_03_PROLOGUE_APPLICATION.md`，两者现均在 `docs/archive/sprints/`，路径需更新）。
- 其余为治理文档中的**散文提及**（DOCUMENT_REGISTRY 若干 → 随 P2-09 重写修；CLEANUP_PLAN/SHARED_FILE_REGISTRY/COLLABORATION_RULES/PROJECT_MAP 的历史/计划性描述）——非 markdown 断链，P2-08/P2-09 视需要处理。

**P2-08 前置**：满足（路径已稳定；上述断链清单已明确，可修）。

## 附：本轮基线核验
- HEAD=`3a69f90`；main 与 origin/main 同步；tag `repository-hygiene-complete-2026-07-11` 指向 HEAD。
- 本轮仅修改本审计文档一个文件；未改/删/移动 README/CURRENT/ITERATION_PLAN/DOCUMENT_REGISTRY 或任何其他文档，未创建 archive，未移动历史文件，未改源码/场景/资源/配置。
