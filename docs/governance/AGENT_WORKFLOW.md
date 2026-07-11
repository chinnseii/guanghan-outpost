# AGENT_WORKFLOW · Claude Code 与 Codex 协作体系

> 治理审计初稿 · 只读 · 2026-07-11
> 三种模式：A 单 Agent、B 交替、C 并行。所有 Git 命令都在 `outputs/lunar_base_godot/` 执行。

## 通用铁律
- Git/Godot 根 = `outputs/lunar_base_godot/`。禁止在 `wo-x/` 根跑 git（空壳会 fatal）。
- 一级共享文件（见 SHARED_FILE_REGISTRY）改前必须 `git log --oneline -- <file>` 抽查。
- 默认"只增不改"：新增可选参数/分支，保留旧默认行为。
- 改 Manager `serialize/deserialize` 或存档字段 = 高风险，视同一级共享。
- 收工前更新 `CURRENT.md`（覆盖写，保持简短）。

## 模式 A：单 Agent 负责（默认）
适用：小 bug、单系统改动、单独 UI、独立文档。

- **实施负责人**：接任务的那个 Agent，对本任务涉及的**所有**文件负责到底（跨到对方常改文件也直接改，改完 CURRENT.md 记一笔）。
- **复核者**：另一个 Agent 或人类。复核**可以直接改代码**（小修），但改完必须写清"复核时改了 X，原因 Y"。
- **交接**：单人任务无需正式交接单，CURRENT.md 一行即可。
- **何时提交**：`lunar-base-verify` 通过（headless 解析 0 退出 + 实测新逻辑）后提交；用户要求才 push。
- 提交信息尾注明是否碰了共用文件。

## 模式 B：交替工作（分析→实现→复查→回归）
适用：一个 Agent 出分析/方案，另一个实现，再回体验/结构检查，最后回归。

**硬规则：禁止用未提交工作区接力。** 每次交接前当前 Agent 必须先 commit（干净工作区），把 commit hash 交给下一个。

### 标准接力单格式（`docs/handoff/ACTIVE_TASKS.md` 或交接消息）
```
## 接力单 · <任务名> · <日期>
- From → To: Codex → Claude Code
- 起始 commit: <hash>（对方从这里 checkout）
- 结束 commit: <hash>（本段工作已提交到这）
- 修改文件: <列表>
- 新增/变更接口: <函数签名/信号/autoload>
- 存档变化: <哪些 *_state.json / progress.json 字段变了；是否需 remap>
- 共用文件: <碰了哪些 tier-1/tier-2，原因>
- 验证结果: <headless 退出码 / 实测结论>
- 未完成项: <明确列出>
- 风险 / 坑: <明确列出>
```

### 交替时序
1. A 分析 → 提交方案文档（无代码或仅骨架）→ 交接单。
2. B 从 A 的结束 commit 实现 → verify → 提交 → 交接单。
3. A 回来做体验/结构复查 → 小修则提交，大问题回写工单。
4. B 最终回归（全流程跑通）→ 提交 → 更新 CURRENT.md。

## 模式 C：并行工作（Git branch + worktree）
适用：两个**互不相关**的任务，可同时推进。

### 结构
- `main` 始终保持干净、可跑、可合并基线；**没人直接在 main 上改**。
- 每个 Agent 一条独立分支 + 独立 worktree：
  - `git worktree add ../wo-x-codex-<task>  -b feat/codex-<task>`
  - `git worktree add ../wo-x-claude-<task> -b feat/claude-<task>`
  - worktree 建在**项目根之外**（如 `wo-x/` 下同级），避免 Godot 扫到两份。
- 各自 worktree 有独立 `.godot/`（导入缓存），互不干扰。

### 允许并行的条件（全部满足才可并行）
1. 不改相同文件（尤其 SHARED_FILE_REGISTRY 一级/二级）。
2. 不改相同 autoload（不同时动 `project.godot` autoload 段）。
3. 不改相同存档结构（`training_progress.json` / `sprint06_progress.json` 字段）。
4. 不改相同数据库 schema。
5. 不改相同公共场景（`main.tscn`、10 个 base 共用场景、训练 hub）。
6. 无隐含结算顺序依赖（Time/Movement/TrainingTime/Penalty 链只允许一个人碰）。

> 任一条不满足 → **不并行，退回模式 B**。

### Active Tasks 记录
- `docs/handoff/ACTIVE_TASKS.md`（模板见 `docs/handoff/ACTIVE_TASKS_TEMPLATE.md`）实时登记：谁 / 哪个分支 / 锁定哪些文件 / 预计动的 autoload 与存档。
- 开工前登记并检查是否与对方声明冲突；有冲突就停下协商，不抢改。

### 合并
- **合并负责人**：固定一人（建议人类或指定 Agent），不是谁先做完谁合。
- **合并顺序**：先合"改动面小/不碰共用文件"的分支，再合大改分支，减少冲突。
- **合并后组合树验证**：合完在 `main` 上跑一次完整 `lunar-base-verify`（headless 全项目导入 + 正式流程实测），确认两条改动**组合**后仍正确（各自分支通过 ≠ 合并后通过）。
- **冲突处理**：出现冲突就**停下**，把两边 diff 摆出来让负责人裁决，**禁止**擅自 `--theirs/--ours` 覆盖对方工作。

### 收尾
- 合并并验证通过后删分支/worktree（`git worktree remove`），清空 ACTIVE_TASKS 对应条目，更新 CURRENT.md。

## 模式选择速查
- 任务小 / 单系统 → **A**。
- 任务有明确"设计→实现→回归"阶段，或涉及一级共享文件 → **B**（串行、干净 commit 接力）。
- 两个真正独立、满足全部 6 条并行条件 → **C**。
- 拿不准 → 默认 **B**，比 C 安全。
