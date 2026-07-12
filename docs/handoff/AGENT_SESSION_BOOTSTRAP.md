# Agent Session Bootstrap

This document is an **Agent-specific Operating Guide**, not a Skill. It tells a fresh Codex or Claude Code session how to initialize against this repository after Phase 5.

## Why a fresh session

After Phase 5 completed, it is recommended to start **new** Codex and Claude Code sessions:

- old sessions keep their history but should not take on new tasks;
- a new session treats the repository documents as the single source of truth;
- a new session does not rely on old chat memory;
- initialization is **read-only**;
- when no Owner is assigned, the session must not modify anything;
- do not read every historical audit report at once;
- read only the Skills a task actually needs.

## Read-only bootstrap sequence (both agents)

Run these read-only steps before doing anything else:

1. `git rev-parse --show-toplevel`
2. `git rev-parse HEAD`
3. `git status -sb`
4. read `docs/handoff/CURRENT.md`
5. read `docs/handoff/ACTIVE_TASKS.md`
6. read `docs/governance/CLEANUP_PLAN.md`
7. read `skills/SKILL_REGISTRY.md`

Do not modify files during bootstrap.

## Codex new-session template

```text
你正在接管《广寒前哨》仓库的新 Codex 会话。
不要依赖旧聊天记录，以当前仓库为唯一事实来源。

先只读执行：
1. git rev-parse --show-toplevel
2. git rev-parse HEAD
3. git status -sb
4. 读取 docs/handoff/CURRENT.md
5. 读取 docs/handoff/ACTIVE_TASKS.md
6. 读取 docs/governance/CLEANUP_PLAN.md
7. 读取 skills/SKILL_REGISTRY.md

规则：
- 先确认仓库路径；
- 每个修改任务必须先登记 ACTIVE_TASKS；
- 任务指令决定本次基线、Owner、范围与 commit；
- Skill 只规定执行方法；
- 只读取任务明确需要的 Skill；
- 不自行扩大范围；
- 不自动 push/tag；
- 不使用 git add . 或 git add -A；
- 发现基线不一致、工作区污染或并行冲突时停止；
- User 拥有最终验收权。

初始化后只汇报：
- repository root
- HEAD
- ahead/behind
- working tree
- current phase
- ACTIVE_TASKS
- formal Skill count
- 是否可以接收任务

不要修改文件。
```

## Claude Code new-session template

```text
你正在接管《广寒前哨》仓库的新 Claude Code 会话。
不要依赖旧聊天记录，以仓库文档和 Skill 为唯一事实来源。

先只读执行：
1. git rev-parse --show-toplevel
2. git rev-parse HEAD
3. git status -sb
4. 读取 docs/handoff/CURRENT.md
5. 读取 docs/handoff/ACTIVE_TASKS.md
6. 读取 docs/governance/CLEANUP_PLAN.md
7. 读取 skills/SKILL_REGISTRY.md

协作规则：
- 一个任务只有一个 primary owner；
- 未被指定为 Owner 时不得修改；
- Reviewer 默认只评审；
- owner transfer 保持同一任务 ID；
- Task prompt 决定当前范围；
- Skill 决定执行方法；
- 只读取任务指定 Skill；
- 不自动修复 reviewer 发现的问题；
- 不自动 push/tag；
- 发现工作区不干净、基线漂移、文件锁重叠时停止；
- User 拥有最终决定权。

初始化后只汇报：
- repository root
- HEAD
- ahead/behind
- working tree
- current phase
- ACTIVE_TASKS
- formal Skill count
- 当前是否为 Owner
- 是否可以接收任务

不要修改文件。
```

## New-session read-only acceptance quiz

```text
读取 skills/SKILL_REGISTRY.md。
只读回答：
1. 当前有哪些正式 Skill；
2. Godot Presenter 抽离应调用哪些 Skill；
3. 运行可能触发真实 user-data 写入时应额外调用哪个 Skill；
4. Skill、任务指令与 ACTIVE_TASKS 的关系；
5. 未被指定为 Owner 时能否修改；
6. Reviewer 能否直接提交修复；
7. 是否可以自行 push/tag；
8. 美术资源主要由谁生产；
9. 美术落地截图主要由谁评审；
10. 视觉 PASS 是否代表代码正确。
不要修改仓库。
```

Expected answers:

1. Five formal Skills: `task-baseline-and-lock`, `save-integrity-guard`, `characterization-first-refactor`, `guanghan-art-design-and-production`, `guanghan-art-review-and-godot-handoff`.
2. Presenter extraction: `task-baseline-and-lock` + `characterization-first-refactor`; add `save-integrity-guard` if the run may write real user data.
3. Real user-data write risk: also invoke `save-integrity-guard`.
4. The task prompt sets baseline/owner/scope/commit; the Skill only defines method; ACTIVE_TASKS records live ownership and locks. Neither Skill nor prompt replaces ACTIVE_TASKS registration.
5. Not the Owner: cannot modify.
6. Reviewer: does not auto-fix by default.
7. push/tag: not performed autonomously; requires explicit user authorization.
8. Art production: ChatGPT.
9. Art landing screenshot review: ChatGPT.
10. Engineering landing: Codex / Claude Code; final approval: User. A visual PASS does **not** mean the code is correct.
