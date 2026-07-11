# 当前项目状态 / Current Project Status

> 本文件是**项目当前状态的唯一权威来源**（滚动文档，完成一个主要批次后覆盖更新）。
> 完整历史见 [`../archive/`](../archive/)（`plans/` `sprints/` `reviews/` `demos/`）；系统事实见 Registry / Reference（下方导航）。
> 更新时间：2026-07-11。

## 当前阶段

**Phase 2 · 文档治理：已完成，准备进入下一治理阶段。**

- Phase 0（工程治理基线）：已完成。
- Phase 1（仓库卫生）：已完成。
- Phase 2（文档治理）：**已完成**（P2-01~P2-10 全部收口）。
- Phase 3（系统边界清洗）及之后：**尚未开始**（阶段定义以 [`../governance/CLEANUP_PLAN.md`](../governance/CLEANUP_PLAN.md) 为准）。

## 最近稳定基线

- **Phase 1 已推送基线**：commit `3a69f90`，tag `repository-hygiene-complete-2026-07-11`（仓库卫生完成点）。
- **Phase 2 完成基线**：本收口提交，tag `document-governance-complete-2026-07-11`（Phase 2 完成 commit 与 tag 在本轮提交与推送后形成；此处不写未知 hash）。
- 工作区干净（无未提交源码/噪声）。

## 最近完成

Phase 2 文档治理（本阶段成果）：
- README 收敛（555 → 89 行，改为开发协作者入口/导航页）；本 `CURRENT.md` 校正为当前状态唯一权威。
- 系统文档职责分层：`SYSTEM_REGISTRY.md`（状态/边界）与 `SYSTEMS_REFERENCE_FOR_DESIGN.md`（玩法/数值）声明并互链。
- `ACTIVE_TASKS.md` 落地（任务/锁/交接唯一真相）。
- 17 份历史文档归档到 `../archive/{plans,sprints,reviews,demos}/`，全仓文档链接修复。
- `DOCUMENT_REGISTRY.md` 重写为长期文档职责/权威/生命周期注册表。

## 当前工作

- **本轮（P2-10）**：Phase 2 收口——最终验收、推送 Phase 2 提交、创建完成 tag。**Phase 2 收口完成。**
- 当前无玩法功能开发混入（纯文档/仓库治理）。

## 当前风险与已知待办

> 详细批次与依赖以 [`../governance/DOCUMENT_GOVERNANCE_AUDIT.md`](../governance/DOCUMENT_GOVERNANCE_AUDIT.md) 与 [`../governance/CLEANUP_PLAN.md`](../governance/CLEANUP_PLAN.md) 为准，此处只列项目级风险。

- `SYSTEMS_REFERENCE_FOR_DESIGN.md`（2800+ 行）偏长，未来需渐进精简（非阻塞）。
- Phase 3 的系统边界与存档真相、Phase 4 的大型脚本拆分尚未开始。
- 月面 EVA 的已知 deferred 风险（EVA activity 名称、返航估算模型、地表玩家位置未持久化）见 `CLEANUP_PLAN.md` 附录 A。
- 系统侧 deferred：训练门运行时注册、`DoorStateManager` 未接入正式旧基地导航（见 `SYSTEM_REGISTRY.md`）；`PenaltyDatabase` 预设小、`severity` 未接 UI、`apply_penalty` 无回滚事务语义。

## 下一步

**唯一优先事项：Phase 3 —— 系统边界清洗**（厘清 Manager 职责与存档真相源，逐系统、中高风险；先文档化每个状态的唯一存档真相源、核实 Inventory/Backpack/Storage 边界，见 [`../governance/CLEANUP_PLAN.md`](../governance/CLEANUP_PLAN.md) Phase 3）。
（Phase 编号以 `CLEANUP_PLAN.md` 为准：Phase 3 = 系统边界清洗、Phase 4 = 大脚本拆分、Phase 5 = Skill 建设、Phase 6 = 双 Agent 试运行。Phase 3 尚未开始。）

## 权威文档导航

| 内容 | 文档 |
|---|---|
| 产品方向 | [`../PROJECT_BRIEF.md`](../PROJECT_BRIEF.md) |
| 系统状态与边界 | [`../governance/SYSTEM_REGISTRY.md`](../governance/SYSTEM_REGISTRY.md) |
| 系统行为与数值 | [`SYSTEMS_REFERENCE_FOR_DESIGN.md`](SYSTEMS_REFERENCE_FOR_DESIGN.md) |
| 场景结构 | [`../governance/SCENE_REGISTRY.md`](../governance/SCENE_REGISTRY.md) |
| 文档治理计划 | [`../governance/DOCUMENT_GOVERNANCE_AUDIT.md`](../governance/DOCUMENT_GOVERNANCE_AUDIT.md) |
| 历史记录 | [`../archive/`](../archive/)（sprints / plans / reviews / demos） |

## 沿用的工作约定（CURRENT-unique，待未来迁入规范文档）

- **验证**：单脚本 `--headless --path . --check-only --script res://<path>.gd`；全项目 `--headless --editor --quit --path .`；启动冒烟 `--headless --path . --quit`。**坑**：`--check-only --path .` 不带 `--script` 在本机不会退出（会挂在主菜单），别用。
- **截图偏好**：用户会自己试玩验收，除非明确要求，否则**不主动截图、不新增截图脚本**。

## 更新规则

- 只保留当前阶段与最近稳定基线；完成一个主要批次后更新本文件。
- 历史内容移入 `../archive/` / `../sprints/`，不在此长期累积；不复制 Registry / 系统数值 / Sprint 全文。
- 每次更新检查 commit/tag 与"下一步"；当前任务细节以后由 `ACTIVE_TASKS.md`（P2-06 创建）管理。
