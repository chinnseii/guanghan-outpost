# Document Registry · 文档职责与权威注册表

> 本文件是**当前文档职责、权威等级与生命周期的长期注册表**——Agent 用它快速判断"该读哪份、哪份是某类事实的权威、哪些是历史"。
> 项目当前状态见 [`../handoff/CURRENT.md`](../handoff/CURRENT.md)；当前执行任务见 [`../handoff/ACTIVE_TASKS.md`](../handoff/ACTIVE_TASKS.md)。
> 本注册表**不复制**文档内容/系统数值/Sprint 历史；文档新增、移动、归档或职责变化时更新此表。

## 状态与等级定义

| 状态 | 含义 |
|---|---|
| `AUTHORITATIVE` | 某类事实的**当前唯一权威来源** |
| `ACTIVE_SUPPORTING` | 当前仍在用，但不是唯一真相源 |
| `TEMPLATE` | 只提供结构，不代表当前状态 |
| `HISTORICAL` | 历史记录，只用于追溯，不承担当前真相 |
| `AUDIT_RECORD` | 治理审计/迁移依据，结论修正时才更新 |
| `DEPRECATED_CANDIDATE` | 疑似废弃、尚未批准删除 |

## 六类权威真相源

| 真相类 | 权威文档 | 状态 |
|---|---|---|
| A 产品方向 | [`../PROJECT_BRIEF.md`](../PROJECT_BRIEF.md) | AUTHORITATIVE |
| B 当前项目状态 | [`../handoff/CURRENT.md`](../handoff/CURRENT.md) | AUTHORITATIVE |
| C 系统状态与边界 | [`SYSTEM_REGISTRY.md`](SYSTEM_REGISTRY.md) | AUTHORITATIVE |
| C 系统行为与设计规则 | [`../handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`](../handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md) | AUTHORITATIVE |
| D 场景结构 | [`SCENE_REGISTRY.md`](SCENE_REGISTRY.md) | AUTHORITATIVE |
| E 当前执行任务 | [`../handoff/ACTIVE_TASKS.md`](../handoff/ACTIVE_TASKS.md) | AUTHORITATIVE |
| F 历史记录 | [`../archive/`](../archive/) | HISTORICAL |

> **系统真相是分层的，不是两个冲突的唯一来源**：`SYSTEM_REGISTRY.md` = 身份/现役状态/边界/owner；`SYSTEMS_REFERENCE_FOR_DESIGN.md` = 玩法规则/数值/设计约束。冲突时现役状态以 REGISTRY 为准、玩法规则以 REFERENCE 为准（详见两文档开头的"文档职责"声明）。

## 当前入口与治理文档

| 文档 | 状态 | 负责 | 不负责 | 主要读者 / 更新触发 |
|---|---|---|---|---|
| [`../../README.md`](../../README.md) | AUTHORITATIVE（仓库入口） | 仓库入口 / 启动 / 权威文档导航 | 当前状态详情、系统真相、Sprint 历史、完整协作规则 | 新协作者 ／ 入口/启动/导航变化时 |
| [`PROJECT_MAP.md`](PROJECT_MAP.md) | ACTIVE_SUPPORTING | 流程地图 + 仓库/项目根边界 | 系统数值、场景细节 | 流程/入口变化时 |
| [`LEGACY_REGISTRY.md`](LEGACY_REGISTRY.md) | ACTIVE_SUPPORTING | 遗留系统 + 存档边界 | 现役系统详细行为 | 遗留判定变化时 |
| [`SHARED_FILE_REGISTRY.md`](SHARED_FILE_REGISTRY.md) | ACTIVE_SUPPORTING | 一/二级共用文件、改前须知 | 系统实现 | 共用面变化时 |
| [`AGENT_WORKFLOW.md`](AGENT_WORKFLOW.md) | ACTIVE_SUPPORTING | 单人/交替/并行协作模式 | 具体任务状态 | 协作模式变化时 |
| [`../handoff/COLLABORATION_RULES.md`](../handoff/COLLABORATION_RULES.md) | ACTIVE_SUPPORTING | Codex/Claude/GPT 分工与共用文件规则 | 当前任务状态 | 分工规则调整时 |
| [`SKILL_ARCHITECTURE.md`](SKILL_ARCHITECTURE.md) | ACTIVE_SUPPORTING | Skill 规划 | 系统设计内容 | Skill 规划变化时 |
| [`CLEANUP_PLAN.md`](CLEANUP_PLAN.md) | ACTIVE_SUPPORTING | 分阶段清洗计划 + backlog | 当前状态 | 清洗阶段推进时 |
| [`DOCUMENT_REGISTRY.md`](DOCUMENT_REGISTRY.md)（本文件） | AUTHORITATIVE | 文档职责/权威/生命周期注册 | 文档正文 | 文档新增/移动/归档/职责变化时 |
| [`../handoff/ACTIVE_TASKS_TEMPLATE.md`](../handoff/ACTIVE_TASKS_TEMPLATE.md) | TEMPLATE | 任务条目结构模板 | **不代表当前任务状态**（当前状态见 ACTIVE_TASKS.md） | 任务条目字段调整时 |

## 审计记录

| 文档 | 状态 | 说明 |
|---|---|---|
| [`REPOSITORY_HYGIENE_AUDIT.md`](REPOSITORY_HYGIENE_AUDIT.md) | AUDIT_RECORD | Phase 1 仓库卫生审计与执行记录；非当前仓库状态入口；卫生规则变化时才更新 |
| [`DOCUMENT_GOVERNANCE_AUDIT.md`](DOCUMENT_GOVERNANCE_AUDIT.md) | AUDIT_RECORD | Phase 2 文档治理审计与迁移记录；Phase 2 已完成，不再频繁维护；仅事实修正或治理复盘时更新；长期文档职责由本 `DOCUMENT_REGISTRY.md` 维护 |

## 支持性设计文档

| 文档 | 状态 | 服务的任务 |
|---|---|---|
| [`../LEGACY_SANDBOX_PROTOTYPE.md`](../LEGACY_SANDBOX_PROTOTYPE.md) | ACTIVE_SUPPORTING | 遗留沙盒原型的唯一权威解释（LEGACY_REGISTRY/SYSTEM_REGISTRY 引它） |
| [`../SPRITE_GUIDE.md`](../SPRITE_GUIDE.md) | ACTIVE_SUPPORTING | 美术/sprite 规范 |
| [`../text/PROLOGUE_TEXT_STYLE_GUIDE.md`](../text/PROLOGUE_TEXT_STYLE_GUIDE.md) | ACTIVE_SUPPORTING | 序章文案风格 |
| [`../design/LUNAR_SURFACE_MAP.md`](../design/LUNAR_SURFACE_MAP.md) | ACTIVE_SUPPORTING | 月面地图设计（在建；完成后要点并入 SYSTEMS_REFERENCE_FOR_DESIGN） |

> `docs/art/**/README.md`（7 份）= 资产局部说明（LOCAL_README），随资产维护，不在本表逐份登记。

## 历史归档（[`../archive/`](../archive/)）

| 目录 | 内容 | 状态 |
|---|---|---|
| [`../archive/plans/`](../archive/plans/) | 旧迭代计划（`ITERATION_PLAN.md`） | HISTORICAL |
| [`../archive/sprints/`](../archive/sprints/) | 各 Sprint 记录（含 SPRINT_01/03/04/05A/06/07/08.x） | HISTORICAL |
| [`../archive/reviews/`](../archive/reviews/) | 历史复审/验收（Sprint01 review、pre09 flow audit） | HISTORICAL |
| [`../archive/demos/`](../archive/demos/) | demo 测试计划/已知问题 | HISTORICAL |

- archive **只用于历史追溯**，当前事实不得以 archive 为准；需要旧实现背景时才读。
- 新历史文档放入对应分类；截图/图片证据仍在 `docs/screenshots/`、`docs/art/`。

## 按任务类型的阅读顺序（最小集合）

- **新功能 / 产品设计**：PROJECT_BRIEF → CURRENT → 相关 SYSTEMS_REFERENCE_FOR_DESIGN → SYSTEM_REGISTRY → SCENE_REGISTRY → ACTIVE_TASKS。
- **Bug 修复**：CURRENT → ACTIVE_TASKS → SYSTEM_REGISTRY → 相关系统设计参考 →（必要时）archive 历史。
- **场景 / 地图**：CURRENT → ACTIVE_TASKS → SCENE_REGISTRY → PROJECT_MAP → 对应设计支持文档。
- **Agent 交替 / 并行**：ACTIVE_TASKS → AGENT_WORKFLOW → SHARED_FILE_REGISTRY → COLLABORATION_RULES → CURRENT。
- **工程治理 / 清理**：CURRENT → CLEANUP_PLAN → 相关 Registry → 对应 audit record → ACTIVE_TASKS。

> **Token 减负**：先按任务类型选最小文档集；不默认读全部 archive、不默认读完整 Sprint 历史。README 只作入口、CURRENT 只作当前状态、Registry 作边界判断、Reference 作玩法/数值、archive 仅需历史上下文时读。

## 文档更新规则（更新触发条件）

- **README**：入口/启动/权威导航变化时。
- **CURRENT**：主要批次完成、稳定基线或下一步变化时。
- **ACTIVE_TASKS**：任务开始/状态/锁/交接/关闭时**立即**更新。
- **SYSTEM_REGISTRY**：系统身份/owner/现役状态/边界/依赖变化时。
- **SYSTEMS_REFERENCE_FOR_DESIGN**：玩法规则/数值/反馈/设计约束变化时。
- **SCENE_REGISTRY**：场景入口/职责/状态变化时。
- **DOCUMENT_REGISTRY**（本文件）：文档新增/移动/归档/职责或权威等级变化时。
- **Audit records**：仅审计结论/治理结果修正时。

## 已知待治理项

- `DOCUMENT_GOVERNANCE_AUDIT.md` 已在 Phase 2 收口（P2-10）转为 `AUDIT_RECORD`。
- Phase 3+（系统边界/存档真相、大脚本拆分）尚未开始；其待办见 `CLEANUP_PLAN.md` 与 `CURRENT.md`。
- 命名/路径纪律：本表一律用真实文件名（`SYSTEMS_REFERENCE_FOR_DESIGN.md`、`docs/archive/{plans,sprints,reviews,demos}/`），不用 `SYSTEMS_REFERENCE` 简称或旧 `docs/sprints/` 等路径。
