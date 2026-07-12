# Phase 3 Closure Report

> 2026-07-12 · Phase 3「系统边界清洗」正式收口 · 基线 `d1b0802`（+ 本轮 P3-06 收口提交）
> 只总结**最终状态**；逐轮流水见各任务节与 Git 历史。权威细节仍在 `PHASE_3_SYSTEM_BOUNDARY_AUDIT.md` / `PHASE_3_SAVE_OWNERSHIP_DECISION.md`。

## 1. Scope
厘清 20 个 autoload/Manager 的职责与数据 owner、统一存档真相源、修复恢复一致性、隔离 Legacy 运行路径——**不重写玩法、不改存档 schema、不删 legacy、不接入正式基地门**。为 Phase 4 大脚本拆分建立稳定基线。

## 2. Completed Tasks
P3-01（系统边界只读审计）· P3-02（存档 owner 定稿）· P3-02R（独立复核对账）· P3-03a（恢复一致性缺口）· P3-03b（Full Save Orchestrator 正式化）· P3-03c + P3-03cV（Manager 自存降级 + 生命周期修复）· P3-03d（checkpoint 作用域裁剪）· P3-04（Manager 职责边界厘清）· P3-05（Legacy 运行路径隔离）· P3-06（全量回归 + 收口，本轮）。

## 3. Final System Ownership
- **电力** canonical = `PowerSystemManager`；`BaseStatusManager.power` = 单向兼容镜像（`sync_power_mirror_from_power_system()`，`set_power_percent()` 为兼容包装）。
- **氧气/CO2/空气** = `AirSystemManager`；**舱压/温度** = `BaseStatusManager`（不再持氧气）。
- **宇航服** canonical = `SuitManager.is_suit_worn`；`PlayerStateManager.is_suit_worn` = 单向兼容镜像（`sync_suit_worn_mirror_from_suit_manager()`）。
- **物品**：`InventoryManager`=数量型全局物资账（+训练专用容器）；`BackpackManager`=玩家随身槽位；`StorageManager`=基地仓储槽位。Backpack↔Storage 转移为**原子 take/add/reject-rollback**，并返回 source/destination/rollback 元数据（数量语义不变）。
- **时间**：`TimeManager`=正式行动制时钟；`TrainingTimeManager`=训练局部时钟；`MovementTimeManager`=按上下文路由。训练时间不回写正式时间。
- **门**：`DoorStateManager` 仅训练地图接入；正式旧基地 = `FORMAL_BASE_NOT_CONNECTED`。
- **惩罚**：`PenaltyManager` = 分发器/不持久化。

## 4. Final Save Architecture（方案 C 分层，已实现）
- **Full Save**：`user://saves/full_save.json`，`FullSaveOrchestrator` 是**唯一**正式完整恢复入口（`restore_full_save()`），schema v1、原子写。
- **Training Checkpoint**：`training_progress.json`，`TrainingManager`，只承训练作用域。
- **Manager 自存** `*_state.json`：**已降级**——Full Restore 期最终胜出，local `load_state()` 不晚覆盖；保留为 fallback/debug 镜像，未删除。
- **Legacy**：sandbox `slot_N.json`、arrival `arrival_prototype_save.json`、`sprint06_progress.json`（只读 best-effort）。`restore_full_save()` **拒绝** legacy_source、**不读** sandbox/arrival 文件。
- 旧本地档兼容 = **NO_COMPATIBILITY_REQUIRED**（用户批准）+ 实施前备份 + 一次性 best-effort 读取。

## 5. Checkpoint Boundaries
- Training Checkpoint 只恢复训练进度/临时宇航服/TrainingTime/训练专用 Inventory 容器；legacy global 字段仅作 metadata、**不**回写正式 Time/Health/Power/Inventory 等。
- Mission/Scene checkpoint 不越权恢复全局 Manager；正式完整恢复只经 Full Save Orchestrator。

## 6. Manager Mirror Rules
- 兼容镜像**单向**（canonical → mirror），镜像**从不回写** canonical。
- Restore 收尾 `TrainingManager.finalize_restore()`（幂等、无副作用）在 `load_progress()` 末统一重算 Power/Suit 镜像。
- 只读查询用 `read_progress()`（无副作用）；`load_progress()` 仅用于真实恢复。

## 7. Legacy Isolation
- Sandbox（`main.gd`）/ Arrival 原型（`arrival_landing_scene.gd`）/ Arrival 电影（`arrival_cinematic_scene.gd`）的局部管理器节点名已加 `Sandbox…`/`ArrivalPrototype…`/`ArrivalCinematic…` 前缀；全仓与正式 autoload 撞名 = **0**。均仅经成员变量访问、无名字路径查找、无 `/root/*` 混用。
- 正式 Continue 只走 Full Save；训练续档只走 TrainingManager；legacy sandbox-slot 仅无正式档时的末位回退（不被依赖）。sandbox/arrival 仅 Dev/沙盒面板可达，不在正式 Continue/New Game 主流程。

## 8. Test Evidence（P3-06 全量复跑）
| 专项测试 | 结果 |
|---|---|
| P3-03a restore consistency | 39/39 |
| P3-03b full save orchestrator | 50/50 |
| P3-03c manager local-save demotion | 33/33 |
| P3-03d checkpoint scope | 25/25 |
| P3-04 manager responsibility boundary | 33/33 |
| P3-05 legacy runtime isolation（含 cinematic） | 36/36 |
| **合计** | **216/216** |
- Godot editor parse EXIT 0；headless smoke EXIT 0；无 parse/SCRIPT ERROR、无新增 warning、无生成噪声。
- 真实 `user://saves/` SHA-256 前后一致；无 `p3_06*`/`.tmp`/`.bak` 残留；无 JSON 进入 Git。

## 9. Closed Risks
多真相源 P1 · Power mirror restore 缺口 · Suit mirror restore 缺口 · checkpoint 越权恢复 · legacy runtime 混淆 + 局部节点撞名（含 P3-06 修复的 cinematic 残留）· formal-continue 与 legacy-restore 混用 · Manager local 晚覆盖 Full Restore。**P0 = 0。**

## 10. Remaining Risks
- 无 P0、无阻塞 P1。剩余为已知**非回归**项：`interaction_detector` 是否 orphan、`BaseInterior_Test` 入口（UNKNOWN，证据不足，不臆断可删）；产品层 Inventory↔Backpack 关系（运行时无双记账风险，属设计问题）。

## 11. Deferred Work
- **DEFERRED_TO_PHASE_4**：`main.gd`（5165 行）、`sprint06_base_scene.gd` 大脚本拆分。
- **DEFERRED_TO_FEATURE_WORK**：DoorStateManager 正式旧基地接入；legacy 文件物理删除；`interaction_detector`/`BaseInterior_Test` 结案。

## 12. Phase 4 Entry Criteria
- Phase 3 系统边界/存档真相/恢复一致性/职责边界/legacy 隔离均已定稿并回归通过（本报告）。
- Full Save 为唯一正式恢复真相、镜像单向、checkpoint 作用域清晰——大脚本拆分时有稳定契约可依。
- 建议 Phase 4 首个目标：`main.gd` 菜单/路由 与 沙盒本体解耦（`SCENE_REGISTRY.md` §B1 已标"收益最大、风险最低"）。**需用户显式启动，勿自动开始。**

## 13. Final Repository State
- 收口提交：`fix: close Phase 3 regression gaps`（P3-06；含 cinematic 命名修复 + 测试扩展 + 收口文档）。
- working tree clean；main ahead origin/main = 11；behind 0；未 push、未 tag；ACTIVE_TASKS = IDLE。
- Phase 3 = **COMPLETE**；Phase 4 = **READY（未启动）**。
