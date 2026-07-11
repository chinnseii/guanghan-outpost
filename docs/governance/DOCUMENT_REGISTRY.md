# DOCUMENT_REGISTRY · 文档审计

> 治理审计初稿 · 只读 · 2026-07-11
> 真相类型：**产品方向** / **系统边界** / **数值** / **当前状态** / **历史归档** / **验收证据**。
> 本阶段不删除、不移动任何文档，只给"推荐定位"。

## A. 长期真相类（保留，权威）

| 文档 | 职责 | 真相类型 | 有效? | 推荐定位 | 备注 |
|---|---|---|---|---|---|
| `docs/PROJECT_BRIEF.md` | 产品方向/调性/五大支柱/First Plant | 产品方向 | ✅ 有效 | 长期真相（唯一产品北极星） | Version 0.1 Draft，内容仍准 |
| `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`(161KB) | 全部现役系统的边界+数值（22+ 章，Time/Health/BaseStatus/Air/Power/Water/Plant/Item/Backpack/Supply/Repair/TrainingTime/Suit/Movement/PlayerState/Door/Penalty/Task） | 系统边界 + 数值 | ✅ 有效 | 长期真相（系统/数值唯一权威） | 与源码一致度高；user memory 要求"数值系统变更即更新此文件" |
| `docs/handoff/COLLABORATION_RULES.md` | 角色分工 + tier-1 共用文件 + 改动规则 | 流程规则 | ✅ 有效 | 长期真相（协作规则） | 已核实引用数（2026-07-06），与本审计一致 |

## B. 当前状态类（滚动覆盖，短期）

| 文档 | 职责 | 真相类型 | 有效? | 推荐定位 |
|---|---|---|---|---|
| `docs/handoff/CURRENT.md` | 本轮完成/触碰的共用文件/已知坑（**每次覆盖重写**） | 当前状态 | ✅（2026-07-08） | 短期状态，勿当历史 |
| `docs/demo/KNOWN_ISSUES_PRE09.md` | Sprint09 前已知问题 | 当前状态 | ✅ | 短期状态 |
| `docs/reviews/pre09_flow_audit.md` | 08.6 流程复审 | 当前状态/验收 | ✅ | 短期状态，08.x 结束后可归档 |

## C. 历史归档类（保留但应标记为历史）

| 文档 | 真相类型 | 推荐定位 |
|---|---|---|
| `docs/LEGACY_SANDBOX_PROTOTYPE.md` | 历史归档（沙盒 V0.1-0.31A） | 历史归档（权威解释遗留代码，勿删） |
| `ITERATION_PLAN.md`(59KB, 项目根) | 历史迭代计划 V0.1→ | 历史归档；⚠**位于项目根而非 docs/**，建议 Phase 2 迁 `docs/` |
| `docs/sprints/*.md`（Sprint 01/04/06/07/08.x 等 14 份） | 历史归档（各 Sprint 记录） | 历史归档 |
| `docs/reports/SPRINT_01_FOUNDATION_REVIEW.md` | 历史归档 | 历史归档 |
| `docs/design/LUNAR_SURFACE_MAP.md` | 设计（在建：月面地图） | 系统边界（进行中）→ 完成后并入 SYSTEMS_REFERENCE |
| `docs/art/ASSET_OLD_BASE_ART_SLICE.md`,`docs/art/*/README.md` | 美术资产说明 | 参考类（随资产走） |
| `docs/text/PROLOGUE_TEXT_STYLE_GUIDE.md` | 文案风格 | 长期真相（文案规范，小范围） |
| `docs/SPRITE_GUIDE.md` | 美术规范 | 长期真相（美术规范） |
| `docs/demo/FIRST_PLAYABLE_DEMO_TEST_PLAN.md` | 测试计划 | 短期/历史 |

## D. 验收证据类

| 位置 | 内容 | 推荐定位 |
|---|---|---|
| `docs/screenshots/**`（sprint03/05a/06/07/08/08.5/08.6/08.7*/playthrough_20260630/prop_bridge_check/…，数百张 PNG） | 各轮验收/回归截图 | 验收证据 |
| `docs/art/**` 的大 PNG（含 `ChatGPT` AI 概念图，单文件最大 2.4MB） | AI 概念图 / 美术参考 | 验收/参考证据（体积大，见 SHARED_FILE_REGISTRY / Git 卫生） |

## E. 主要问题（职责混乱 / 可能过期）

1. **README.md（33KB，项目根）职责过载 🟠**：既写"当前状态"（"当前状态：行动推进制时间系统…"）又当系统说明书。当前状态与 `CURRENT.md` 重叠、与 `SYSTEMS_REFERENCE` 重叠。→ 建议 Phase 2 把 README 收敛为"项目是什么 + 怎么跑 + 指向 PROJECT_BRIEF/SYSTEMS_REFERENCE/CURRENT"的门面，状态内容不在这维护。
2. **`ITERATION_PLAN.md` 与 `docs/sprints/*` 重叠**：都是历史迭代记录，且 ITERATION_PLAN 在根目录。→ Phase 2 归档并迁入 docs/。
3. **`docs/reviews/pre09_flow_audit.md` 与 `KNOWN_ISSUES_PRE09.md` 部分重叠**（都讲 08.x 已知问题/流程）——非冲突，但 Sprint09 落地后应合并或归档。
4. **产品方向真相唯一、清晰**（PROJECT_BRIEF），**系统真相唯一、清晰**（SYSTEMS_REFERENCE）——这两条主干健康，问题集中在"当前状态"被 README/CURRENT/reviews 三处分散。

## F. 六类真相的推荐归位
- 产品方向真相 → `PROJECT_BRIEF.md`（唯一）
- 系统边界真相 → `SYSTEMS_REFERENCE_FOR_DESIGN.md`（唯一）
- 数值真相 → `SYSTEMS_REFERENCE_FOR_DESIGN.md`（同上，含数值章节）
- 当前任务状态 → `CURRENT.md`（唯一滚动）+ 未来 `docs/handoff/ACTIVE_TASKS.md`（并行时）
- 历史记录 → `docs/sprints/*` + `LEGACY_SANDBOX_PROTOTYPE.md` + `ITERATION_PLAN.md`(迁入后)
- 验收证据 → `docs/screenshots/**`
