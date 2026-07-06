# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Claude Code

## 正在进行

- **Codex**：实现 Action-Based Time System（`scripts/managers/TimeManager.gd`，
  行动推进时间、月面阶段 NIGHT_LATE/DAYLIGHT/NIGHT、存档接入）。
  - **重要架构纠正**：spec 原文说"如果已有 GameState/SaveManager，请接入
    现有结构"——但 `scripts/game_state_manager.gd` / `scripts/save_manager.gd`
    是遗留代码，只有 `main.gd`（Sprint 01 沙盒）和 `scripts/arrival/*`
    （Sprint 02 原型）在用，跟当前主线（申请→训练→抵达→旧基地→Day02→
    第一周）完全无关。当前主线是每个场景各自写自己的存档 JSON
    （`sprint06_base_scene.gd` 写 `user://saves/sprint06_progress.json`，
    `training_module_scene.gd` 走 `training_manager.gd` 的存档）。
    时间状态应该并入这两条现有存档路径，不要接到 game_state_manager.gd
    上（那样时间系统会跟正式流程脱节，等于没做）。
- **Claude Code**：等 Codex 的 `TimeManager` 落地并推送后，再接 HUD 时间显示
  （Day/时分/月面阶段/距切换剩余时间 + 阶段切换弹窗）。本次会话未动代码，
  纯等待交接。

## 最近完成

- **Codex**：已阅读并确认 `docs/handoff/COLLABORATION_RULES.md` 与本文件。
  - 本次只做协作规则同步，没有修改游戏逻辑、场景或共用核心脚本。
  - 后续触碰第一档共用核心文件前，会先执行 `git log --oneline -- <文件路径>`，必要时查看最近相关 commit。
  - 后续改共用文件时默认使用新增可选参数 / 新增分支方式，保留旧默认行为。

- **Claude Code**：训练模块设备接入可复用道具场景（`reference_prop.gd` 体系）。
  - 涉及文件：`scripts/props/reference_prop.gd`、
    `scripts/training/training_module_scene.gd`、
    `scripts/base/sprint06_base_scene.gd`（改了共用文件 `_spawn_prop()`，
    新增了一个尾部可选参数 `status_text_value`，旧调用不受影响）。
  - 新增 `scenes/props/training/*.tscn`（6 个训练专用道具场景）。
  - 删除了 `scenes/props/old_base_art/`（确认全仓库零引用的死代码）。
  - commit: `1ab59de`（删除死代码）、`92dc74a`（道具桥接主改动）。
  - 已推送到 `origin/feature/sprint-04-national-training`。

## 对共用核心文件的改动记录

- 本次 Codex 规则同步没有触碰共用核心文件。
- `scripts/props/reference_prop.gd`：给 `console`/`power_panel`/`door`/
  `plant_chamber`/`grow_light` 的绘制函数加了 `status_text` 驱动的多状态
  渲染分支。**规则**：`status_text` 为空时完全走原逻辑，不影响旧场景
  （`OldPowerPanel.tscn` 等）。以后要给这几个 kind 加新状态，去改这个文件
  里对应函数的 `match status_text:` 分支，不要在别处再写一套。
- `scripts/base/sprint06_base_scene.gd` 的 `_spawn_prop()`：新增了
  `status_text_value := ""` 尾部可选参数（第 7 个参数），用于把状态字符串
  传给 `ReferenceProp` 实例。旧调用不用改。

## 已知问题 / 暂不覆盖范围

- P2（环境叙事细节：标签、磨损、灰尘等）还没做。
- `suit_control` / `life_support` / `final_assessment` 三个训练模块虽然复用
  了已验证过的 kind（console/power_panel 等），但没有像 power_repair /
  plant_diagnosis / airlock_procedure 那样逐一截图复核过。
- 一次性验证脚本留在了 `tools/capture_power_repair_prop_bridge_check.gd`、
  `tools/capture_plant_diagnosis_prop_bridge_check.gd`、
  `tools/capture_airlock_prop_bridge_check.gd`，可以重新运行来复核视觉状态。

## 先别碰

（暂无）
