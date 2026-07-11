# 当前项目状态 / Current Project Status

> 本文件是**项目当前状态的唯一权威来源**（滚动文档，完成一个主要批次后覆盖更新）。
> 完整历史见 [`../archive/`](../archive/)（`plans/` `sprints/` `reviews/` `demos/`）；系统事实见 Registry / Reference（下方导航）。
> 更新时间：2026-07-12。

## 当前阶段

**Phase 3 · 系统边界清洗：进行中**（P3-01 审计、P3-02 存档 owner 定稿、P3-02R 独立复核对账、P3-03a 恢复一致性缺口修复均完成；P3-03b 待启动）。

- Phase 0（工程治理基线）/ Phase 1（仓库卫生）/ Phase 2（文档治理）：**均已完成**。
- Phase 3（系统边界清洗）：**进行中**——P3-03a 已完成；Phase 3 尚未完成。
- Phase 4+（大脚本拆分、Skill、双 Agent）：尚未开始（编号以 [`../governance/CLEANUP_PLAN.md`](../governance/CLEANUP_PLAN.md) 为准）。

## 最近稳定基线

- **Phase 1 已推送基线**：commit `3a69f90`，tag `repository-hygiene-complete-2026-07-11`（仓库卫生完成点）。
- **Phase 2 完成基线**：本收口提交，tag `document-governance-complete-2026-07-11`（Phase 2 完成 commit 与 tag 在本轮提交与推送后形成；此处不写未知 hash）。
- 工作区将在 P3-03a 收口提交后恢复干净。

## 最近完成

P3-03a 恢复一致性缺口修复：
- `PowerSystemManager.deserialize()` 恢复后立即同步 `BaseStatusManager.power` 兼容镜像。
- `SuitManager.deserialize()` 在 `suit_changed` 前同步 `PlayerStateManager.is_suit_worn` 镜像。
- `TrainingManager.read_progress()` 成为公共无副作用查询入口；外部纯查询调用已迁移，`load_progress()` 保留为真实恢复入口。
- `TrainingManager.finalize_restore()` 建立恢复收尾点，重算 Power/Suit 兼容镜像，幂等且不推进时间/不消耗资源/不触发惩罚/不自动保存。
- 专项测试 39/39 通过；Godot editor parse + headless smoke 通过；本地存档与备份 SHA-256 一致。

## 当前工作

- **最近完成：P3-03a**（owner transfer：Claude Code → Codex）。详见 [`../governance/PHASE_3_SYSTEM_BOUNDARY_AUDIT.md`](../governance/PHASE_3_SYSTEM_BOUNDARY_AUDIT.md) §17、[`../governance/PHASE_3_SAVE_OWNERSHIP_DECISION.md`](../governance/PHASE_3_SAVE_OWNERSHIP_DECISION.md) §17。
- **当前阶段：Phase 3**。P3-03b Full Save Orchestrator 正式化尚未开始。

## 当前风险与已知待办

> 详细批次与依赖以 [`../governance/DOCUMENT_GOVERNANCE_AUDIT.md`](../governance/DOCUMENT_GOVERNANCE_AUDIT.md) 与 [`../governance/CLEANUP_PLAN.md`](../governance/CLEANUP_PLAN.md) 为准，此处只列项目级风险。

- `SYSTEMS_REFERENCE_FOR_DESIGN.md`（2800+ 行）偏长，未来需渐进精简（非阻塞）。
- 当前主要风险：Manager 自存 `*_state.json` 与 bundle（`training_progress.json` / `sprint06_progress.json`）多真相源仍存在；P3-03b/c 继续处理。
- 月面 EVA 的已知 deferred 风险（EVA activity 名称、返航估算模型、地表玩家位置未持久化）见 `CLEANUP_PLAN.md` 附录 A。
- 系统侧 deferred：训练门运行时注册、`DoorStateManager` 未接入正式旧基地导航（见 `SYSTEM_REGISTRY.md`）；`PenaltyDatabase` 预设小、`severity` 未接 UI、`apply_penalty` 无回滚事务语义。

## 下一步

**唯一优先事项：P3-03b —— Full Save Orchestrator 正式化**（明确正式 Full Save 入口、恢复顺序、`schema_version`、canonical owner restore、derived/mirror recompute）。随后 P3-03c 自存降级 → P3-03d checkpoint 越域裁剪。P3-03a 已完成；不要声称 P3-03b 已完成。
（Phase 编号以 `CLEANUP_PLAN.md` 为准：Phase 3=系统边界、4=大脚本拆分、5=Skill、6=双 Agent。）

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
