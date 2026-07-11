# 广寒前哨 / Guanghan Outpost

一款 Godot 4.7 开发的 2D 像素风**月球基地农业生存**游戏。

玩家作为中国"广寒计划"的常驻开拓者，抵达月球后修复旧基地、恢复生命支持、救活上一位开拓者留下的最后一株植物，并逐步把一座孤独的前哨从依赖地球补给，推向水 / 氧气 / 食物 / 能源的自给闭环。核心不是普通轻松种田，而是"让生命在从未存在生命的地方生长"的孤独、希望与接力。

> 产品方向、调性与设计原则的**权威说明**见 [`docs/PROJECT_BRIEF.md`](docs/PROJECT_BRIEF.md)。本 README 只是开发协作者的入口页，不是产品设定书。

## 当前状态（摘要）

- 已完成 **Phase 1 仓库卫生**治理，基线 tag：`repository-hygiene-complete-2026-07-11`。
- 当前处于 **Phase 2 文档治理**阶段（正在收敛文档职责与真相源）。
- 玩法上，正式主线（申请 → 国家训练 → 抵达月面 → 旧基地 → 第一周 → Phase 02 占位）已可从主菜单完整走通；最早期的沙盒原型已与主线断开，仅 F12 开发菜单可进。

> README 只提供摘要，**最新状态以 [`docs/handoff/CURRENT.md`](docs/handoff/CURRENT.md) 为准**。

## 技术栈

- **Godot 4.7** + **GDScript**
- 2D 像素风（现代叙事像素）
- Git / GitHub 版本管理
- Claude Code / Codex 辅助开发

## 快速启动

1. 安装 **Godot 4.7**。
2. 用 Godot 打开本目录下的 `project.godot`（主场景为 `res://scenes/main.tscn`）。
3. 点击运行；或双击 `launch_godot.bat`（内含本机 Godot 可执行文件路径，按需修改）。

命令行验证（把 `godot` 换成你本机的 Godot 4.7 可执行文件）：

```bash
# 全项目导入 / 解析检查
godot --headless --editor --quit --path .
# 启动冒烟
godot --headless --path . --quit
# 单脚本解析
godot --headless --path . --check-only --script res://<path>.gd
```

> Windows 本机使用具体可执行文件（如 `Godot_v4.7-stable_win64.exe`）。截图类工具需**非 headless** 模式。

## 项目结构

```text
assets/            正式游戏资产（美术/音频等，含跟踪的 .import 导入配置）
scenes/            场景（.tscn）
scripts/           游戏脚本（managers / systems / ui / controllers 等）
tools/             验证与截图工具脚本
docs/              项目文档、设计资料与验收证据
docs/governance/   工程治理、系统/场景注册表与清洗计划
docs/handoff/      当前状态、系统设计参考与协作交接
docs/archive/      历史计划、Sprint、复审与 demo 归档
```

> 完整文件树不在 README 维护；用上面的目录导航到对应文档。

## 权威文档导航

| 需要了解什么 | 权威文档 |
|---|---|
| 产品方向与体验调性 | [`docs/PROJECT_BRIEF.md`](docs/PROJECT_BRIEF.md) |
| 当前项目状态 | [`docs/handoff/CURRENT.md`](docs/handoff/CURRENT.md) |
| 当前任务与文件锁 | `docs/handoff/ACTIVE_TASKS.md`（将在 Phase 2 P2-06 创建；模板见 [`ACTIVE_TASKS_TEMPLATE.md`](docs/handoff/ACTIVE_TASKS_TEMPLATE.md)） |
| 系统状态与边界 | [`docs/governance/SYSTEM_REGISTRY.md`](docs/governance/SYSTEM_REGISTRY.md) |
| 系统行为与数值 | [`docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`](docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md) |
| 场景与流程结构 | [`docs/governance/SCENE_REGISTRY.md`](docs/governance/SCENE_REGISTRY.md) · [`PROJECT_MAP.md`](docs/governance/PROJECT_MAP.md) |
| 遗留系统 / 旧沙盒 | [`docs/governance/LEGACY_REGISTRY.md`](docs/governance/LEGACY_REGISTRY.md) · [`docs/LEGACY_SANDBOX_PROTOTYPE.md`](docs/LEGACY_SANDBOX_PROTOTYPE.md) |
| 文档职责与索引 | [`docs/governance/DOCUMENT_REGISTRY.md`](docs/governance/DOCUMENT_REGISTRY.md) |
| 协作规则 | [`docs/handoff/COLLABORATION_RULES.md`](docs/handoff/COLLABORATION_RULES.md) · [`docs/governance/AGENT_WORKFLOW.md`](docs/governance/AGENT_WORKFLOW.md) |
| 共用文件（改前须知） | [`docs/governance/SHARED_FILE_REGISTRY.md`](docs/governance/SHARED_FILE_REGISTRY.md) |
| 治理与清洗计划 | [`docs/governance/CLEANUP_PLAN.md`](docs/governance/CLEANUP_PLAN.md) |

> 只链接真实存在的文件；本项目**没有** `CLAUDE.md` / `AGENTS.md`，协作规则以上表真实路径为准。

## 开发协作最小规则

1. 开工前先读 [`CURRENT.md`](docs/handoff/CURRENT.md) 与相关 Registry；当前任务/文件锁以后以 `ACTIVE_TASKS.md` 为准。
2. 明确本次任务的修改范围，不顺手改无关系统。
3. 改一级共用文件（见 SHARED_FILE_REGISTRY）前先 `git log` 抽查，默认只增不改。
4. **精确路径暂存**（`git add <path>`），禁止日常 `git add -A`；提交前跑 leak-guard。
5. 新增 `.gd` 与其 `.gd.uid` 一起提交；`docs/` 图片不作为正式 `assets/`。
6. 收工前跑 Godot 解析 / headless 冒烟（见上）；提交/推送前等明确批准。

> 详细协作规章不在 README 复制，见 [`COLLABORATION_RULES.md`](docs/handoff/COLLABORATION_RULES.md) 与 [`AGENT_WORKFLOW.md`](docs/governance/AGENT_WORKFLOW.md)。

## 历史记录

Sprint、旧迭代计划、复审与验收记录保存在 [`docs/archive/`](docs/archive/)（含 `plans/` `sprints/` `reviews/` `demos/`），README **不再维护完整变更日志**。
