# 当前项目状态 / Current Project Status

> 本文件是**项目当前状态的唯一权威来源**（滚动文档，完成一个主要批次后覆盖更新）。
> 完整历史见 [`../sprints/`](../sprints/) 与 [`../archive/`](../archive/)；系统事实见 Registry / Reference（下方导航）。
> 更新时间：2026-07-11。

## 当前阶段

**Phase 2 · 文档治理**（进行中）。目标：减少文档重复、明确各文档职责与真相源、降低 Agent 上下文负担。

- Phase 0（工程治理基线）：已完成。
- Phase 1（仓库卫生）：已完成。
- Phase 2（文档治理）：进行中（见下"当前工作"）。
- Phase 3+（系统边界/存档真相、大脚本拆分等）：尚未开始。

## 最近稳定基线

- **最近已推送稳定基线**：commit `3a69f90`，tag `repository-hygiene-complete-2026-07-11`（Phase 1 仓库卫生完成点，已 push 到 origin/main）。
- **当前本地进展**：Phase 2 文档治理提交在本地累积、**尚未 push**（更新此文时 `main` 领先 `origin/main` 数个提交——具体数量随提交变化，不是长期事实）。
- 工作区当前干净（无未提交源码/噪声）。

## 最近完成

- Phase 1 仓库卫生：换行规范化（`.gitattributes`）、docs 图片隔离（`.gdignore`）、清除 152 个 docs `.import`、补交 35 个 `.gd.uid`。
- Phase 2 至今：文档全量审计与六类真相源确认；README 由 555 行收敛到 89 行（改为开发协作者入口/导航页）；README-only 的 Sprint 03 / 05A 历史已归档到 `../archive/sprints/`；`SYSTEM_REGISTRY.md` 与 `SYSTEMS_REFERENCE_FOR_DESIGN.md` 的职责边界已声明并互链。

## 当前工作

- **本轮（P2-04）**：校正并收敛本 `CURRENT.md`，使其成为当前状态唯一权威来源。
- Phase 2 尚未完成；当前无玩法功能开发混入（纯文档/仓库治理）。

## 当前风险与已知待办

> 详细批次与依赖以 [`../governance/DOCUMENT_GOVERNANCE_AUDIT.md`](../governance/DOCUMENT_GOVERNANCE_AUDIT.md) 与 [`../governance/CLEANUP_PLAN.md`](../governance/CLEANUP_PLAN.md) 为准，此处只列项目级风险。

- `ACTIVE_TASKS.md` 尚未创建（并行/交替任务的当前真相缺位）——待 P2-06。
- 历史文档尚未归档、跨文档引用（含 `SPRINT_04→SPRINT_03` 死链）尚未统一修复——待 P2-07 / P2-08。
- `DOCUMENT_REGISTRY.md` 待重写（P2-09）；`SYSTEMS_REFERENCE_FOR_DESIGN.md`（2800+ 行）偏长，未来需渐进精简。
- Phase 3 的系统边界与存档真相、Phase 4 的大型脚本拆分尚未开始。
- 月面 EVA 的已知 deferred 风险（EVA activity 名称、返航估算模型、地表玩家位置未持久化）见 `CLEANUP_PLAN.md` 附录 A。
- 系统侧 deferred：训练门运行时注册、`DoorStateManager` 未接入正式旧基地导航（见 `SYSTEM_REGISTRY.md`）；`PenaltyDatabase` 预设小、`severity` 未接 UI、`apply_penalty` 无回滚事务语义。

## 下一步

**唯一优先事项：P2-06 —— 创建 `docs/handoff/ACTIVE_TASKS.md`**，建立当前任务、owner、分支/worktree、文件锁与交接状态的唯一来源。
（随后：P2-07 历史归档 → P2-08 引用修复 → P2-09 `DOCUMENT_REGISTRY` 重写 → P2-10 验收/push/tag。）

## 权威文档导航

| 内容 | 文档 |
|---|---|
| 产品方向 | [`../PROJECT_BRIEF.md`](../PROJECT_BRIEF.md) |
| 系统状态与边界 | [`../governance/SYSTEM_REGISTRY.md`](../governance/SYSTEM_REGISTRY.md) |
| 系统行为与数值 | [`SYSTEMS_REFERENCE_FOR_DESIGN.md`](SYSTEMS_REFERENCE_FOR_DESIGN.md) |
| 场景结构 | [`../governance/SCENE_REGISTRY.md`](../governance/SCENE_REGISTRY.md) |
| 文档治理计划 | [`../governance/DOCUMENT_GOVERNANCE_AUDIT.md`](../governance/DOCUMENT_GOVERNANCE_AUDIT.md) |
| 历史记录 | [`../archive/`](../archive/) · [`../sprints/`](../sprints/) |

## 沿用的工作约定（CURRENT-unique，待未来迁入规范文档）

- **验证**：单脚本 `--headless --path . --check-only --script res://<path>.gd`；全项目 `--headless --editor --quit --path .`；启动冒烟 `--headless --path . --quit`。**坑**：`--check-only --path .` 不带 `--script` 在本机不会退出（会挂在主菜单），别用。
- **截图偏好**：用户会自己试玩验收，除非明确要求，否则**不主动截图、不新增截图脚本**。

## 更新规则

- 只保留当前阶段与最近稳定基线；完成一个主要批次后更新本文件。
- 历史内容移入 `../archive/` / `../sprints/`，不在此长期累积；不复制 Registry / 系统数值 / Sprint 全文。
- 每次更新检查 commit/tag 与"下一步"；当前任务细节以后由 `ACTIVE_TASKS.md`（P2-06 创建）管理。
