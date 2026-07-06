# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Claude Code（代 Codex，宇航服整备室后续 Bug 排查）

## 正在进行

用户反馈"宇航服整备室"（`Training_01_SuitControl.tscn`）进入后角色会
自动向上移动，操作上感觉"只能左右移动"。**本轮加了一个针对性的防御性
修复，但没有能力在这个环境里交互式运行游戏确认根因，需要用户实际测试
反馈是否解决**。

## 本轮完成（Claude Code，代 Codex）：疑似"残留输入状态"防御性修复

- 分析：`training_module_scene.gd` 的 `_move_player()` 每帧用
  `Input.get_axis("ui_up","ui_down")`/`Input.get_axis("ui_left","ui_right")`
  轮询移动方向——这段代码本身**这次完全没有改动**（跟上一轮"训练第一
  房间"改造之前一模一样），所有训练模块都共用同一个 `_move_player()`。
  Godot 的输入动作状态是全局的，不是按场景隔离的——如果玩家是通过按
  Enter/方向键点击上一个场景的按钮（比如 `TrainingStartScene` 的"开始
  训练"按钮，或者上一个训练模块退出提示的确认）进入这个房间，那个按键
  在 `change_scene_to_file()` 切场景瞬间可能还没收到"松开"事件，导致
  新场景里 `Input.get_axis()` 读到一个"卡住"的方向，看起来就是"自动
  往一个方向走，且按反方向键也拉不回来"（因为卡住的输入状态没有被清掉，
  一直在跟真实按键"打架"）。
- 修复：`_ready()` 新增 `_release_stale_movement_input()`，在
  `_ensure_input_actions()` 之后立即执行，对 `ui_up`/`ui_down`/
  `ui_left`/`ui_right`/`interact`/`mission_panel`/`ui_cancel`/`ui_accept`
  这几个本场景关心的 action 全部调用 `Input.action_release(...)`，相当于
  强制"松开"一遍，清空任何从上个场景带过来的残留状态。**这个修复是通用
  的，接入点在所有训练模块共用的 `_ready()`，不是只针对宇航服整备室**——
  如果根因确实是"残留输入"，其余 5 个训练模块理论上也会受益，即使它们
  目前没有被专门报告过这个问题。
- **重要：这是一个基于最合理推测的防御性修复，不是确认过根因的修复**——
  我没有能力在这个开发环境里交互式运行 Godot 游戏、实际按键测试，只能
  通过读代码推理。如果用户测试后问题仍然存在，说明根因是别的东西（比如
  连接了会漂移的手柄、真实卡键、或者其他我没考虑到的因素），需要用户
  提供更多信息（是不是每次进入都会发生、其他训练房间是否也有同样现象、
  是用鼠标还是键盘点的"开始训练"按钮）才能继续排查。

## 验证

- Godot 4.7 headless：全部 6 个训练模块场景
  （`Training_01_SuitControl`~`05`/`FinalAssessmentScene`）加载均无
  `SCRIPT ERROR`/`Parse Error`。
- **没有能力验证这个修复是否真的解决了用户报告的移动问题**——headless
  模式不模拟按键输入/场景切换时序，这类"残留输入状态"问题本质上需要
  交互式测试才能确认，这次只能确认修复没有引入新的编译错误。

## 已知问题 / 暂不覆盖范围

- 上一轮"训练第一房间：宇航服整备室"的已知问题（训练宇航服状态可能
  泄漏进正式任务、密封/通信字段纯展示、模拟气闸舱复用已有 airlock_procedure
  模块）仍然有效，本轮没有变化，详见
  `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`。
- 本轮的移动 Bug 修复**待用户确认是否解决**，如果没解决需要用户提供更多
  复现细节。

## 先别碰

- `scripts/managers/BackpackManager.gd` / `StorageManager.gd` /
  `SupplyManager.gd` / `RepairManager.gd` / `scripts/data/FaultDatabase.gd`
  仍是 Codex 自己推进的系统，本轮完全没有碰。
- `scripts/data/ItemDatabase.gd` / `scripts/managers/InventoryManager.gd`
  本轮也没有碰，继续由 Claude Code 维护（改前先
  `git log --oneline -- <file>`）。
