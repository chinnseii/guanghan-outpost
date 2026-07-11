# 当前项目状态 / Current Project Status

> 本文件是项目当前状态的滚动权威摘要。更新日期：2026-07-12。

## 当前阶段

**Phase 3 · 系统边界清洗：进行中。**

- Phase 0 / Phase 1 / Phase 2 已完成。
- Phase 3 已完成：P3-01 系统边界审计、P3-02 存档 owner 定稿、P3-02R 独立复核对账、P3-03a 恢复一致性修复、P3-03b Full Save Orchestrator 正式化。
- Phase 3 未完成：P3-03c Manager 自存降级、P3-03d checkpoint 作用域裁剪、后续 P3-04/P3-05/P3-06。

## 最近完成

P3-03b Full Save Orchestrator formalization：

- 新增非 Autoload `scripts/systems/full_save_orchestrator.gd`。
- 正式完整进度 authoritative 文件为 `user://saves/full_save.json`。
- Full Save bundle schema v1 已建立：`schema_version`、`save_kind`、`metadata`、`canonical_state`、`scene_state`、`player_context`、`target_scene`。
- `sprint06_base_scene.gd` 改为 scene adapter：触发 `_save_state()` / `_load_state()`，但 Manager 收集、写入、读取、校验、恢复顺序都交给 Orchestrator。
- 旧 `sprint06_progress.json` 降为 legacy/unversioned best-effort 读取来源，不再是 authoritative Full Save。
- `training_progress.json` 仍是训练 checkpoint；Full Restore 不读取 training progress，也不调用 `TrainingManager.load_progress()`。
- restore order 显式化，并在末尾执行 Power/Suit compatibility mirror finalize。
- Manager 自存 `*_state.json` 未删除、未停用、未改格式，留给 P3-03c。

## 当前风险

- P1 多真相源风险已被 P3-03b 部分缓解，但尚未彻底消除：完整进度已有唯一 Full Save bundle/入口；Manager 自存仍会存在并写盘，P3-03c 前不能宣称完全解决。
- Training Checkpoint 仍保留较宽字段，P3-03d 前不裁剪。
- DoorStateManager 训练门已接入，但正式旧基地仍未接入；Door 未纳入核心 Full Save。
- Inventory / Backpack / Storage 字段级边界仍需后续核实。
- 月面 EVA deferred 风险仍见 `docs/governance/CLEANUP_PLAN.md` 附录 A。

## 下一步

唯一优先事项：**P3-03c — Manager 自存降级**。

目标是在不破坏现有运行时 owner 和 `serialize/deserialize` 的前提下，把 `*_state.json` 从“正式完整进度 restore 真相源”降级为过渡层 / session cache / dev fallback。不要在 P3-03c 里提前做 P3-03d checkpoint 裁剪。

## 验证基线

- P3-03b 专项：`tests/p3_03b_full_save_orchestrator_test.gd`，50/50 pass。
- P3-03a 回归：`tests/p3_03a_restore_consistency_test.gd`，39/39 pass。
- P3-03b 测试只写临时 `p3_03b_test_*` 文件并清理；正式 `full_save.json` 未由测试生成。
- 本地 `user://saves` 与 P3-03a 备份 `saves_backup_before_p3_03a_2026-07-11` SHA-256 仍一致。
- 除非用户明确要求，不主动截图。

## 权威文档导航

| 内容 | 文档 |
|---|---|
| 产品方向 | `docs/PROJECT_BRIEF.md` |
| 系统身份与边界 | `docs/governance/SYSTEM_REGISTRY.md` |
| Phase 3 系统边界审计 | `docs/governance/PHASE_3_SYSTEM_BOUNDARY_AUDIT.md` |
| Full Save / owner 决策 | `docs/governance/PHASE_3_SAVE_OWNERSHIP_DECISION.md` |
| 清理路线图 | `docs/governance/CLEANUP_PLAN.md` |
| 协作任务板 | `docs/handoff/ACTIVE_TASKS.md` |
