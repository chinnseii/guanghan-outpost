# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Claude Code（代 Codex，训练模块 player_start 生成点 Bug——已实测确认修复）

## 正在进行

用户反馈"宇航服整备室"进入后角色自动向上移动。上一轮先做了一个基于推测
的防御性修复（清空残留输入状态），**本轮用模拟输入的临时脚本实际跑通了
整条链路，找到并确认修复了一个真正的、影响全部 6 个训练模块的 Bug**
（详见下）。仍然建议用户实测确认"自动向上走"这个具体症状是否已经解决，
因为不能排除是"卡键/手柄漂移"这类我这次也无法模拟的成因单独或同时存在。

## 本轮完成（Claude Code，代 Codex）：`Dictionary.merge()` 不生效 Bug

- **根因（已用临时脚本实测确认，不是推测）**：`training_module_scene.gd`
  的 6 个模块配置函数（`_suit_control_config()`/`_airlock_config()`/
  `_power_config()`/`_life_support_config()`/`_plant_config()`/
  `_assessment_config()`）都是 `var data := _base_config()` 之后
  `data.merge({...每个模块自己的 title/player_start/targets/steps...})`。
  Godot 4 的 `Dictionary.merge(other, overwrite := false)` **默认不覆盖
  已存在的键**——而 `_base_config()` 本身就先设置了
  `"player_start": Vector2(62, 420)` 当默认值。也就是说**这 6 个模块各自
  配置的 `player_start`（比如宇航服整备室的 `Vector2(420,310)`）从来没有
  真正生效过**，全部静默落回 `(62,420)` 这个默认生成点——这不是本轮
  训练第一房间改造引入的新问题，是从这几个 `.merge()` 调用第一次被写出来
  那天就存在的，只是这次因为改了宇航服整备室的内容才被注意到。
  - 用一个独立的临时脚本直接测试 `Dictionary.merge()` 的默认行为，
    实测确认：`base.merge({"player_start": ..., ...})` 在 key 已存在时
    确实不覆盖。
  - 又直接实例化 `Training_01_SuitControl.tscn` 场景（不是孤立测试
    字典逻辑，是跑真实场景的 `_ready()`），确认修复前
    `module_data.player_start`/实际 `player.position` 都是 `(62,420)`，
    不是配置里写的 `(420,310)`。
- **修复**：6 处 `.merge({...})` 全部改成 `.merge({...}, true)`，显式传
  `overwrite=true`。已用同一个临时脚本逐一实例化全部 6 个训练场景
  （`Training_01`~`05`/`FinalAssessmentScene`），确认修复后每个模块的
  `player.position` 精确匹配各自配置的 `player_start`（此前全部 6 个都
  错误地卡在 `(62,420)`）。

## 上一轮的防御性修复（仍然保留，本轮额外用模拟输入验证了原理成立）

`_release_stale_movement_input()`（清空场景切换时可能残留的 `ui_up`/
`ui_down`等按键状态）上一轮是基于推测加的，本轮用临时脚本做了完整的
模拟输入实测：
- 确认"一个没有被释放的 `Input.action_press('ui_up')`"确实会让
  `Input.get_axis('ui_up','ui_down')` 一直返回 `-1.0`，且这会让玩家
  每帧持续向上漂移——跟用户描述的症状完全吻合（已用临时脚本让角色在
  30 帧内静止不动 vs. 卡键后 20 帧内精确向上漂移 ~38.8 像素，对照验证）。
  这确认了"卡住的输入状态会导致这个具体症状"这个因果链是成立的。
  这个修复目前发生在游戏进入训练房间前
- 确认 `_release_stale_movement_input()` 确实能清除**场景加载之前**就已经
  卡住的输入状态（模拟"上个场景按 Enter 点按钮，切场景时按键还没释放"
  这个具体成因）。
- **诚实说明**：这个修复只能处理"残留自上一个场景"这一种成因。如果
  卡键的真正原因是"进了房间之后才卡住"（比如连接的手柄摇杆本身有漂移，
  或者物理按键真的粘住了），这个修复帮不上忙——这点已用临时脚本单独验证
  过（模拟"_ready() 跑完之后才卡键"，角色确实会持续漂移，且这个修复
  对这种情况无效，因为它只在 `_ready()` 时执行一次）。

## 验证

- Godot 4.7 headless：全部 6 个训练模块场景 headless 加载均无
  `SCRIPT ERROR`/`Parse Error`。
- 临时脚本（未提交，验证后已删除）本轮做了比上一轮更彻底的实测：
  1. 直接测试 `Dictionary.merge()` 默认行为，确认不覆盖已存在键。
  2. 实例化真实场景确认 `player_start` 未生效的具体表现（(62,420) vs
     配置值），改完 `overwrite=true` 后重测，6 个模块全部精确匹配。
  3. 模拟"场景加载前卡键"，确认 `_release_stale_movement_input()`
     确实能清除它。
  4. 模拟"场景加载后才卡键"，确认这种情况下角色确实会持续漂移
     （验证了症状本身的因果链条，而不只是修复本身）。

## 已知问题 / 暂不覆盖范围

- **无法在这个环境里真正交互式运行游戏、按真实键盘/手柄测试**——本轮
  用的是"模拟 `Input.action_press`/直接实例化场景读状态"这种介于纯静态
  分析和真人操作之间的办法，比单纯读代码可信得多，但仍然不能 100%
  排除用户环境里有别的、这次没模拟到的成因（尤其是连接的手柄漂移）。
- `player_start` 这个 Bug 之前影响**全部 6 个训练模块**，不只是宇航服
  整备室——用户之前可能一直没注意到，或者这次因为宇航服整备室的房间
  布局对生成点位置更敏感（比如 `(62,420)` 离这个房间的墙边界比其他房间
  更近）才第一次被明显感知到。
- 上一轮"训练第一房间：宇航服整备室"的其余已知问题（训练宇航服状态
  可能泄漏进正式任务等）没有变化，详见
  `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`。

## 先别碰

- `scripts/managers/BackpackManager.gd` / `StorageManager.gd` /
  `SupplyManager.gd` / `RepairManager.gd` / `scripts/data/FaultDatabase.gd`
  仍是 Codex 自己推进的系统，本轮完全没有碰。
- `scripts/data/ItemDatabase.gd` / `scripts/managers/InventoryManager.gd`
  本轮也没有碰，继续由 Claude Code 维护（改前先
  `git log --oneline -- <file>`）。
