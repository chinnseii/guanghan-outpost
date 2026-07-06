# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Claude Code（代 Codex，训练专用时间系统）

## 正在进行

（暂无——本轮"训练专用时间系统 v1"已实现完成。开始前确认过
`git status`/`CURRENT.md` 均无 Codex 新的并发改动，工作过程中也没有再
出现新的并发改动。）

## 本轮完成（Claude Code，代 Codex）：训练专用时间系统 v1

- **新增 `scripts/managers/TrainingTimeManager.gd`**，注册为 autoload
  `/root/TrainingTimeManager`。核心字段：`archive_limit_minutes`（默认
  480）/`elapsed_minutes`/`remaining_minutes`/`training_time_active`/
  `training_time_paused`/`time_log`。接口全部按需求文档给的清单实现：
  `start_training_time`/`stop_training_time`/`pause_training_time`/
  `resume_training_time`/`advance_training_time`/`check_training_timeout`/
  `get_elapsed_minutes`/`get_remaining_minutes`/`get_archive_limit_minutes`/
  `get_remaining_time_text`（`HH:MM` 格式）/`get_time_log`。
  `advance_training_time()` 有 active/paused/minutes<=0 三道空转防护，
  `remaining_minutes` 硬 clamp ≥0。存档 `user://saves/training_time_state.json`
  （需求文档说这个可选，本次还是按项目统一习惯做了）。
- **`scripts/training/training_manager.gd` 新增 4 个 static 方法**：
  `are_required_modules_completed()`（检查五个核心训练模块，**不含**
  `final_assessment`——那是必修模块全部完成后的结算步骤本身）、
  `fail_training(reason)`（写 `TrainingStatus="failed"` +
  `TrainingFailureReason`，更新申请档案状态为"候选人档案已归档"，停掉
  训练时间，带幂等保护防止重复处理）、`training_status()`/
  `training_failure_reason()` 两个查询方法。`default_data()` 新增
  `TrainingStatus`/`TrainingFailureReason` 两个字段。`start_training()`
  现在会同步调 `TrainingTimeManager.start_training_time()`；
  `reset_progress()` 现在会把训练时间也重置回初始态（清零后立即停止，
  不留一个悄悄在跑的倒计时）。
- **`scripts/training/training_module_scene.gd`（5 个训练模块 + 最终考核
  共用的场景脚本）改造**：
  - `_advance_time_for_step()`：推进调用从
    `TimeManager.advance_time()` 换成
    `TrainingTimeManager.advance_training_time()`——**这是本次唯一改动了
    实际调用点的地方**，训练场景现在完全不会推进正式月球时间。
  - `_time_hud_text()`：从显示 `TimeManager.compact_hud_text()`（正式
    月昼/日期）改成显示
    `"训练归档时限：剩余 %s" % TrainingTimeManager.get_remaining_time_text()`，
    按需求文档统一叫"训练归档时限"，不叫"教程倒计时"/"考试时间"/
    "Game Over 倒计时"。
  - `_finish_module()`：`module_id == "final_assessment"` 完成时额外调
    `TrainingTimeManager.stop_training_time()`（训练通过，停止倒计时，
    避免考核通过后时间继续走还触发一次误报的超时失败）。
  - `_default_time_minutes_for_step()`/`_action_minutes()` 里对
    `TimeManager.action_minutes()` 的只读查表**故意保留没改**——那只是
    读一张耗时常量表，不推进任何时间，不违反"训练不碰正式系统"的边界。
- **`project.godot`**：`[autoload]` 追加 `TrainingTimeManager`。
- **`main.gd`**：新增 Training Time Debug 分组（查看状态、开始 480 分钟、
  +30/+360 分钟推进、暂停、恢复、强制超时）。
- 设计参考文档已同步更新：文末新增"训练专用时间系统 TrainingTimeManager"
  一节（跟在 Codex 的"维修系统 v1"后面，同样是不带编号的追加章节，没有
  对已有章节做任何改动/重新编号）。

## 验证

- Godot 4.7 headless：`main.tscn` + 全部 7 个训练场景
  （`TrainingStartScene`/`Training_01`~`05`/`FinalAssessmentScene`）+
  `OldBaseInteriorScene`/`OldGreenhouseScene`/`Day02StartScene`/
  `WeekRoutineStartScene`/`SolarArrayExteriorScene` 共 12 个场景全部
  headless 加载，均无 `SCRIPT ERROR`/`Parse Error`。
- 临时脚本（未提交，验证后已删除）跑通了 10 项：默认归档时限 480 分钟；
  `advance_training_time()` 正确推进训练时钟且完全不改动
  `TimeManager.serialize()` 的快照（前后哈希一致，证明官方时间系统真的
  零接触）；剩余时间硬 clamp 在 0；`time_log` 正确记录
  `minutes/reason/elapsed_after/remaining_after`；必修模块未完成时超时
  正确触发 `fail_training("archive_time_expired")` 并停止时钟，再次确认
  `TimeManager` 快照仍未变；必修模块全部完成后超时**不会**失败；
  `pause_training_time()` 让推进完全不生效，`resume_training_time()` 恢复
  正常；`get_remaining_time_text()` 的 `HH:MM` 格式正确
  （450 剩余 → `"00:30"`）；序列化/反序列化往返一致。

## 已知问题 / 暂不覆盖范围

- **没有专门的训练失败结算场景/UI**：失败原因和时间消耗复盘目前只能
  通过代码查询（`TrainingManager.training_status()`/
  `training_failure_reason()`、`TrainingTimeManager.get_time_log()`），
  需求文档给的失败文案（"候选人档案已归档。结果：派遣资格未激活。"）和
  "主要时间损耗"复盘界面都没有对应场景把它们显示出来。
- **训练健康、训练资源模拟没有做**：训练场景目前仍然直接读/演正式
  `HealthManager`（`_health_hud_text()` 没有改），需求文档提到的
  `training_health_state`/`TrainingResourceScenario` 隔离层这次完全
  没有实现。
- **训练维修/训练植物没有接正式 `RepairManager`/`PlantGrowthManager`**：
  各训练模块的步骤数据还是各自场景脚本手写的固定剧本，需求文档第十五、
  十六节的隔离规则暂时不适用（因为还没有对应的真实耦合）。
- 详细边界说明和数值见
  `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`（文末"训练专用时间系统
  TrainingTimeManager"一节）。

## 先别碰

- `scripts/managers/BackpackManager.gd` / `StorageManager.gd` /
  `SupplyManager.gd` / `RepairManager.gd` / `scripts/data/FaultDatabase.gd`
  仍是 Codex 自己推进的系统，本轮完全没有碰。
- `scripts/data/ItemDatabase.gd` / `scripts/managers/InventoryManager.gd`
  本轮也没有碰，继续由 Claude Code 维护（改前先
  `git log --oneline -- <file>`）。
