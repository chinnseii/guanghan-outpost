# SKILL_ARCHITECTURE · Skill 架构规划

> 治理审计初稿 · 只读 · 2026-07-11
> **本阶段不批量创建 Skill**，只评估必要性与边界。
> 原则：系统的**具体设计内容**放系统文档（`SYSTEMS_REFERENCE_FOR_DESIGN.md`），Skill 只负责"执行某类工作的方法"。不给每个 Manager 建 Skill。description 必须够明确防误触发。不写死本机绝对路径。

## 已存在的 Skill（现状）
- ✅ `lunar-base-godot-conventions` — 本项目 GDScript/场景/autoload/数据库写改规范 + 共用文件"下手前"谨慎规则。**保留**，是 `lunar-base-feature-design` 相关能力的落点。
- ✅ `lunar-base-verify` — headless 解析检查、前后对比截图、合并后自查、更新 CURRENT/SYSTEMS_REFERENCE_FOR_DESIGN.md。**保留**，覆盖候选 7。

## 候选 Skill 评估

| # | 候选 | 解决什么 | 触发 / 不触发 | 输入→输出 | 读哪些文档 | 与谁重叠 | 判定 |
|---|---|---|---|---|---|---|---|
| 1 | `lunar-base-task-intake` | 把人类/GPT 的口述 bug/需求整理成结构化工单（现象/复现/预期/实际，不指派归属） | 触发：收到未结构化反馈。不触发：已有明确工单/直接改代码 | 口述→工单.md | COLLABORATION_RULES, PROJECT_BRIEF | 与 playtest-bug-report 部分重叠 | **第一批** |
| 2 | `lunar-base-feature-design` | 新系统/功能的设计（边界、数值、存档影响）落成设计稿 | 触发：加新系统。不触发：改 bug/纯 UI 微调 | 需求→设计稿 | SYSTEMS_REFERENCE_FOR_DESIGN.md, PROJECT_BRIEF | 与 conventions（写码规范）分工清晰 | **第二批** |
| 3 | `lunar-base-godot-conventions` | 本项目写码/场景约定 | 已存在 | — | — | — | **已有，保留** |
| 4 | `lunar-base-change-planning` | 改动前的规划：查 git log、判 tier-1、只增不改策略、存档兼容评估、回滚点 | 触发：要动共用文件/Manager/存档。不触发：独立新文件 | 任务→变更计划 | SHARED_FILE_REGISTRY, COLLABORATION_RULES | 与 conventions 有交集但聚焦"规划+锁"，价值独立 | **第一批** |
| 5 | `lunar-base-playtest-bug-report` | 玩测中记录 bug 证据 | 触发：玩测发现问题。不触发：设计讨论 | 玩测→bug 报告 | — | 与 task-intake 重叠明显 | **合并进 #1**（不单建） |
| 6 | `lunar-base-gameplay-feedback` | 体验/调性评审（是否符合 BRIEF 五支柱） | 触发：产品评审。不触发：代码正确性 | 截图/描述→评审意见 | PROJECT_BRIEF | 与 product-review 重复 | **合并进 #11** |
| 7 | `lunar-base-verify` | 验证/交付纪律 | 已存在 | — | — | — | **已有，保留** |
| 8 | `lunar-base-handoff` | 交接（起止 commit/改动文件/新接口/存档变化/共用文件/风险/未完成） | 触发：交替/并行收工交接。不触发：单人连续作业 | 工作→交接单 | AGENT_WORKFLOW, CURRENT | 与 verify 边界：verify 管"对不对"，handoff 管"怎么交" | **第一批** |
| 9 | `lunar-base-architecture-audit` | 本次这种全局治理审计 | 触发：治理/结构复审。不触发：日常开发 | 仓库→治理文档 | 全部 governance | 独一份 | **治理期临时**（用完转低频） |
| 10 | `lunar-base-cleanup-migration` | 执行 CLEANUP_PLAN 的单步迁移（渐进/可回滚） | 触发：执行某个 cleanup phase。不触发：加功能 | phase→迁移 PR | CLEANUP_PLAN | 与 change-planning 边界：这个专做"治理迁移" | **治理期临时** |
| 11 | `lunar-base-product-review` | GPT 视角产品/调性审核（读文档+截图，不读码） | 触发：验收报告评审。不触发：技术实现 | 报告→通过/打回 | PROJECT_BRIEF, sprint docs | 吸收 #6 | **第二批** |

## 分批结论

### 立即创建（第一批 — 治理与协作骨架）
1. `lunar-base-task-intake`（含 playtest-bug-report 能力）
2. `lunar-base-change-planning`
3. `lunar-base-handoff`
> 加上已有的 `lunar-base-godot-conventions` + `lunar-base-verify`，构成"入口→规划→写码→验证→交接"闭环。

### 第二批创建（功能设计与评审）
4. `lunar-base-feature-design`
5. `lunar-base-product-review`（含 gameplay-feedback）

### 治理期临时使用（治理结束后降频/停用）
6. `lunar-base-architecture-audit`
7. `lunar-base-cleanup-migration`

### 暂不创建（合并或无独立价值）
- `lunar-base-playtest-bug-report` → 并入 task-intake
- `lunar-base-gameplay-feedback` → 并入 product-review
- 任何 "每个 Manager 一个 Skill" 的想法 → 拒绝，系统细节归 SYSTEMS_REFERENCE_FOR_DESIGN.md

## 反模式提醒
- 不为凑数建 Skill；不让两个 Skill 负责同一阶段（intake vs bug-report、product-review vs feedback 已合并）。
- Skill 里不硬编码 `C:\Users\...` 绝对路径；用 `res://` / 项目相对路径。
- 系统"应该怎么设计"写文档，Skill 只写"怎么做这类活"。
