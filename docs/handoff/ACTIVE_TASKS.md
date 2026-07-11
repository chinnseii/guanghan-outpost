# Active Tasks · 当前任务登记板

> 本文件是**当前任务、负责人、分支/worktree、文件锁、阻塞与交接状态的唯一权威来源**。
> 项目级当前状态见 [`CURRENT.md`](CURRENT.md)；新任务条目结构见 [`ACTIVE_TASKS_TEMPLATE.md`](ACTIVE_TASKS_TEMPLATE.md)；
> 协作模式与共用文件规则见 [`../governance/AGENT_WORKFLOW.md`](../governance/AGENT_WORKFLOW.md)、[`../governance/SHARED_FILE_REGISTRY.md`](../governance/SHARED_FILE_REGISTRY.md)、[`COLLABORATION_RULES.md`](COLLABORATION_RULES.md)。

## Board Status

- **Status**: `IDLE`
- **Active tasks**: `0`
- **Locked files**: `0`
- **Pending handoffs**: `0`
- **Branch**: `main`
- **Board baseline**: `ceafe6c`（创建/上次收工基线，随提交变化，非长期事实）
- **Last updated**: `2026-07-11`

## Active Tasks

当前没有活动任务。

> 开始一个真实任务时，从 `ACTIVE_TASKS_TEMPLATE.md` 复制一条条目填入此处，并把 Board Status 改为 `ACTIVE`。

## File Locks

当前没有文件锁。

> 修改**高风险共用内容**前必须在此登记锁（精确文件/目录 · lock owner · 原因 · 范围 · 释放条件）。高风险类别：
> Autoload / Manager、存档 schema（`training_progress` / `sprint06_progress` / `*_state.json` 字段）、主场景 `scenes/main.tscn`、共用 UI、Registry 文档、`CURRENT.md`、本文件 `ACTIVE_TASKS.md`、共享配置（`project.godot` / `.gitattributes` / `.gitignore`）。一级共用文件清单见 `SHARED_FILE_REGISTRY.md`。

## Pending Handoffs

当前没有待交接事项。

> 交替（模式 B）交接时在此填交接单摘要 + 正式报告路径（完整交接单格式见模板）。

## Recently Closed

### P3-02R — Independent review reconciliation

- Status: `DONE`
- Owner: `Claude Code` ／ Reviewer: `User`
- Result: Codex 六项独立复核发现全部核验并对账进 P3-01/P3-02——Power deserialize 不同步 BaseStatus.power(P2)、BaseStatus 氧气摘要修正、Suit 双持有(SuitManager 明确 canonical)、Door `FORMAL_BASE_NOT_CONNECTED`、legacy 同名节点无运行冲突、TrainingManager read/restore API 边界。owner 细化（"UNRESOLVED=0"作废）；P3-03 拆为 a/b/c/d。
- Verification: 文档-only；Godot editor+smoke EXIT=0；变更全为 `.md`。
- Commit: 见本任务收尾提交（`docs: reconcile save ownership review`）。
- Closed: `2026-07-11`

### P3-02 — Save-source and data-owner finalization

- Status: `DONE`
- Owner: `Claude Code` ／ Reviewer: `User`
- Result: canonical owner / 写入-恢复权 / 三 save 层职责 / 架构方案对比与推荐（方案 C 分层）定稿 → `PHASE_3_SAVE_OWNERSHIP_DECISION.md`。owner UNRESOLVED=0；用户待决 2 项。
- Verification: 文档-only；Godot editor+smoke EXIT=0；变更全为 `.md`。
- Commit: 见本任务收尾提交（`docs: finalize save ownership decisions`）。
- Closed: `2026-07-11`

### P3-01 — System boundaries and save-source audit

- Status: `DONE`
- Owner: `Claude Code` ／ Reviewer: `User`
- Result: 20 autoload/Manager、数据所有权、存档真相源、依赖与遗留边界只读审计 → `PHASE_3_SYSTEM_BOUNDARY_AUDIT.md`。核心发现：跨系统写入全经公开方法（0 直接写）、无 P0；P1=存档真相源不唯一。
- Verification: 代码/运行时文件零改动；Godot editor+smoke EXIT=0；变更全为 `.md`。
- Commit: 见本任务收尾提交（`docs: audit Phase 3 system boundaries`）。
- Closed: `2026-07-11`

### P2-10 — Phase 2 documentation governance close-out

- Status: `DONE`
- Owner: `Claude Code` ／ Reviewer: `User`
- Result: Phase 2 文档治理在本收口提交定稿（CURRENT 更新为 Phase 2 完成、审计转 AUDIT_RECORD、DOCUMENT_REGISTRY 生命周期更新）。
- Verification: 全部本地 Phase 2 验收检查通过（当前权威断链=0、注册表完整、Godot smoke 通过）；push 与 tag 在提交后验证。
- Commit: 见本任务收尾提交（`docs: complete Phase 2 document governance`）。
- Closed: `2026-07-11`

### P2-09 — Document registry rewrite

- Status: `DONE`
- Owner: `Claude Code` ／ Reviewer: `User`
- Result: `DOCUMENT_REGISTRY.md` 重写（57→102 行）：六类真相源、当前入口/治理文档、审计记录、支持文档、4 类 archive、5 类任务阅读顺序、更新规则。
- Verification: 27 链接全有效；NEEDS_REGISTRATION=0；无旧名称/路径残留。
- Commit: 见本任务收尾提交（`docs: rebuild document registry`）。
- Closed: `2026-07-11`

> 最多保留最近 3–5 条已关闭任务摘要；超出即清空，长期记录进 `../archive/` 或 Git 历史。本板不保存长期历史。

## 状态枚举（统一，勿另造重叠词）

- **任务状态**：`PLANNED` / `READY` / `IN_PROGRESS` / `BLOCKED` / `REVIEW` / `DONE` / `CANCELLED`。
- **板级状态**：`IDLE`（无活动任务）/ `ACTIVE`（有活动任务）/ `BLOCKED`（存在阻塞任务）。

## Owner / Reviewer 规则

- 每个任务只有一个 **primary owner**（可为 `Claude Code`、`Codex` 或用户），可选一个 **reviewer**。
- **reviewer 不自动拥有文件修改权**；同一文件不得同时被两个 Agent 修改。
- 产品/体验验收与代码正确性验收**分开**。
- **owner/reviewer 不是固定角色**——不默认 Claude 永远主开发、Codex 永远复核；每个任务按当时安排指定。
- **用户负责最终任务分配与合并决策。**

## 每条任务应记录的字段（结构见模板）

owner · reviewer · 模式(A/B/C) · status · branch · worktree · base/expected commit · 任务描述(objective) · allowed files · locked/shared files · 会动的 autoload/存档/公共场景 · acceptance/验收标准 · verification（Godot parse / headless smoke / 专项测试 / 人工玩测 / Git leak-guard）· blockers · handoff 摘要 + 正式报告路径 · updated。

## Operating Rules

- 开工前必须在本文件登记任务；同一任务只设一个 primary owner。
- 修改共享文件前必须先登记锁；reviewer 不与 owner 同改相同文件。
- 完成后记录 commit、验证结果与交接状态；任务关闭后移入 Recently Closed 或清空为 `IDLE`。
- 本文件只存当前状态与简短摘要，**不保存长期历史**（长期记录进 archive / Git 历史）。
- **本板不虚构 owner / deadline / 文件锁**；无任务时保持 `IDLE`。
