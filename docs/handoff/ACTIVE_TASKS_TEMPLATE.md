# ACTIVE_TASKS · 并行/交替任务登记板（模板）

> **本文件只是结构模板，不代表当前任务状态。当前任务状态见 [`ACTIVE_TASKS.md`](ACTIVE_TASKS.md)。**
> 复制本模板为 `docs/handoff/ACTIVE_TASKS.md` 使用。
> 用途：并行（模式 C）与交替（模式 B）时登记谁在做什么、锁了哪些文件。
> 规则：开工前登记并检查冲突；有冲突就停下协商，不抢改。收工/合并后清掉自己的条目。
> 详见 `docs/governance/AGENT_WORKFLOW.md` 与 `SHARED_FILE_REGISTRY.md`。

## 当前进行中的任务

### 任务 <编号/短名>
- **Agent**: Codex / Claude Code
- **模式**: A 单人 / B 交替 / C 并行
- **分支**: `feat/<agent>-<task>`（worktree: `../wo-x-<agent>-<task>`）
- **起始 commit**: `<hash>`
- **任务描述**: <一句话>
- **🔒 锁定的文件（一级共享，独占）**:
  - `scripts/...`
- **声明会改的文件（二级共享）**:
  - `scripts/...`
- **会动的 autoload**: <名称 / 无>（改 `project.godot` autoload 段？是/否）
- **会动的存档结构**: <training_progress / sprint06_progress / *_state.json 字段 / 无>
- **会动的公共场景**: <main.tscn / base 共用 / 训练 hub / 无>
- **并行 6 条件自查**（模式 C 必填，全 ✅ 才可并行）:
  - [ ] 不改相同文件
  - [ ] 不改相同 autoload
  - [ ] 不改相同存档结构
  - [ ] 不改相同数据库 schema
  - [ ] 不改相同公共场景
  - [ ] 无隐含结算顺序依赖（Time/Movement/TrainingTime/Penalty 链）
- **状态**: 进行中 / 待复核 / 待合并
- **未完成项 / 风险**: <列出>

---

## 交接单（模式 B 用，交接时填）
```
## 接力单 · <任务名> · <日期>
- From → To: <A> → <B>
- 起始 commit: <hash>
- 结束 commit: <hash>（工作已提交到此；禁止用未提交工作区接力）
- 修改文件: <列表>
- 新增/变更接口: <函数签名/信号/autoload>
- 存档变化: <字段/是否需 remap>
- 共用文件: <tier-1/2，原因>
- 验证结果: <headless 退出码 / 实测结论>
- 未完成项: <列出>
- 风险 / 坑: <列出>
```

## 合并登记（模式 C 用）
- **合并负责人**: <固定一人>
- **合并顺序**: 先小改/不碰共用 → 后大改
- **组合树验证**: 合并后在 `main` 跑完整 `lunar-base-verify`，结果: <待填>
- **冲突处理**: 出现冲突即停，摆出双边 diff 由负责人裁决，禁止 --ours/--theirs 擅自覆盖
