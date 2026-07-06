# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Claude Code（代 Codex，训练模块 03：月面太阳能板维修）

## 本轮完成：训练模块 03「太阳能阵列训练场」

按用户给的完整开发指令实现了训练第三房间的全部内容。**沿用既有
module_id `"power_repair"`**，新场景文件
`res://scenes/training/SolarArrayTrainingField.tscn`（旧的
`Training_03_PowerRepair.tscn` 原样保留、不再引用）。完整设计细节见
`docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`「训练第三房间：太阳能阵列
训练场」一节，这里只列要点：

- **入场门禁**：`SuitManager.is_suit_worn == false` 时阻止进入，
  `briefing_modal` 替换成错误提示 + 返回主菜单。
- **7 步任务链**：确认宇航服外勤状态（Tab）→ 移动到故障点 → 检查（E，
  15 分钟固定档，消耗宇航服氧气/电力各 -2、精力 -2）→ 4 选项维修方案面板
  → 正确选项修复 → 供电 Critical→Basic → 出口。
- **新故障卡 `FA-TR-SOLAR-001`**（`FaultDatabase.gd`，4 个选项）+
  `RepairManager.apply_repair_option(fault_id, option_id, context)`
  训练分支（全新入口，`attempt_repair()`等既有正式流程函数一字未动）：
  只认 `FaultDatabase` + `InventoryManager` 的训练容器 + 
  `TrainingTimeManager` + `SuitManager`/`HealthManager`，绝不碰真实
  `TimeManager`/`StorageManager`/`BaseStatusManager`。
- **训练容器**：`InventoryManager.gd` 新增 `training_03_parts` 概念
  （`create_container`/`add_item_to_container`/`remove_item_from_container`/
  `has_item_in_container`/`get_container_item_count`/`clear_container`），
  完全独立于真实背包/`StorageManager`，不参与存档。
- **新物品** `TR-MT-001` 通用备件 / `TR-MT-002` 训练电子元件
  （`ItemDatabase.gd`，training-only）。
- **训练备件耗尽 -> 直接判负**：`TrainingManagerScript.fail_training(
  "training_03_parts_depleted")`，跟既有的训练档案超时失败走同一个出口。

## 本轮顺手修复的真实 Bug：`TrainingManager.load_progress()` 吃掉跨模块宇航服状态

写入场门禁时发现并确认：`set_current_module()`/`mark_module_completed()`
都是先 `load_progress()` 再 `save_progress()`，而 `load_progress()` 会把
`SuitState`（以及 Time/Health/BaseStatus 等全部状态）无条件
`deserialize()` 回活的 manager——用临时脚本实测复现：模块一穿好宇航服后，
模块一 `_finish_module()` 一调 `mark_module_completed()`，
`is_suit_worn` 就被悄悄改回 `false`（因为读到的是模块一**入场时**存的
旧快照）。**这不是本轮新增的问题，是从 `SuitManager` 上线那次就存在的
坑**，只是之前没有任何训练房间的逻辑依赖"宇航服状态跨模块存活"，这次
的入场门禁第一次真正踩上。

**修复**（`scripts/training/training_manager.gd`，纯新增）：拆出私有
`_read_progress_data()`（只读 JSON + merge 进默认值，无 manager 副作用），
`set_current_module()`/`mark_module_completed()` 改调它而不是
`load_progress()`；`load_progress()` 本身签名和行为完全不变，其余调用方
（`assignment_black_screen_scene.gd`/`mission_assignment_notice_scene.gd`/
`main.gd`）不受影响。已用临时脚本验证：穿服 -> 模块完成 -> 下一模块
入场，`is_suit_worn` 全程保持 `true`。

## 验证

- Godot 4.7 headless：新场景 + 其余全部 9 个既有场景（`main.tscn`/5 个
  训练模块/考核/通知/黑屏）逐一 `--quit`，均无 `SCRIPT ERROR`/
  `Parse Error`/`Nonexistent function`。
- 临时脚本（未提交，验证后已删除）覆盖：
  1. `FA-TR-SOLAR-001` 4 个选项的耗时/材料/氧气/电力/精力数值逐条对照
     需求文档第十三节精确匹配。
  2. 入场门禁：未穿服 `entry_blocked=true`，穿服后 `entry_blocked=false`。
  3. 穿服状态跨 `mark_module_completed()`/`set_current_module()` 存活
     （上面那个 Bug 的回归测试）。
  4. 错误选项 -> 正确选项的完整流程（材料扣减、时间推进、资源扣减、
     `fault_fixed` 正确）。
  5. 高风险选项独立验证耗时/资源扣减。
  6. 训练备件耗尽后维修失败、`fault_fixed` 仍为 false。
  7. `TimeManager.serialize()` 前后完全一致（训练维修零污染正式时间
     系统）。

## 已知问题 / 暂不覆盖范围

- D 选项「强行切换满功率输入」目前只有文案层面的"稳定性下降"，没有实际
  数值/状态惩罚——第一版按需求文档"不要炸毁设备，保持克制"故意保留
  克制，下一轮如果要加真实惩罚需要另外设计。
- `_read_progress_data()` 拆分只修了 `set_current_module()`/
  `mark_module_completed()` 这两个已知会撞见"live 状态领先于快照"的
  调用点；`start_training()`（训练最开始只调一次）仍用原始
  `load_progress()`，本次没有动它（那个时间点还不存在状态领先的情况，
  风险低）。
- 训练宇航服状态可能"泄漏"进正式任务这个更早的已知问题没有变化（详见
  `SYSTEMS_REFERENCE_FOR_DESIGN.md`「训练第一房间」一节）。

## 先别碰 / 本轮触碰说明

- 本轮**打破了上一轮"RepairManager.gd / FaultDatabase.gd 是 Codex 自己
  推进的系统，不要碰"的约定**——这是用户本轮需求文档明确要求的（复用
  维修系统而不是新建一套训练维修管理器），改动方式是纯新增
  （`apply_repair_option()` 等新函数 + 一张新故障卡），`attempt_repair()`/
  `apply_repair_success()`/`apply_repair_failure()`/既有 16 张故障卡
  一字未动。如果 Codex 这轮也在并行推进这两个文件，合并时请重点核对
  `RepairManager.gd` 底部新增的 `apply_repair_option()` 及其私有 helper、
  以及 `FaultDatabase.gd` 里的 `"FA-TR-SOLAR-001"` 条目。
- `scripts/managers/BackpackManager.gd` / `StorageManager.gd` /
  `SupplyManager.gd` 本轮仍然完全没有碰，继续由 Codex 维护。
- `scripts/data/ItemDatabase.gd` / `scripts/managers/InventoryManager.gd`
  本轮新增了 training-only 的两个物品和"训练容器"接口，继续由 Claude
  Code 维护（改前先 `git log --oneline -- <file>`）。
