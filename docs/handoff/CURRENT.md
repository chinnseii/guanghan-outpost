# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Codex

## 正在进行

（暂无，PlayerController Foundation Sprint 已完成本地实现与基础验证，待提交 / 推送）

## 最近完成

- **Codex**：完成“小 Sprint：统一 PlayerController + 交互 Area2D + 移动距离计时”的第一版底座。
  - 新增 `scripts/controllers/player_controller_2d.gd`：
    - 统一处理输入方向、移动速度、边界 clamp。
    - 内置移动距离累计，默认每 64px 视作 1 个 tile step。
    - 每累计 1 个 step 调用 `TimeManager.advance_time(action_minutes("move"), "move")`。
    - 支持 top-left 坐标模式（训练模块）和 center 坐标模式（旧基地）。
  - 新增 `scripts/controllers/interaction_area_2d.gd`：
    - 作为未来真实 `Area2D` 交互节点的语义入口。
    - 当前先提供静态矩形适配函数：靠近矩形、进入矩形、从 top-left 计算脚点 / 中心点。
  - 训练模块移动已接入 `GuanghanPlayerController2D`：
    - 保留原有模块边界、气闸完成后的单向限制、步骤状态机和 HUD 逻辑。
    - 移动耗时不再依赖步骤完成，而是按实际移动距离累计。
  - 旧基地 / 旧温室 / 第一周移动已接入 `GuanghanPlayerController2D`：
    - 保留原有 HUD 安全区边界和房间边界。
    - 旧基地当前仍按中心点移动，不引入正式碰撞体积，避免改变可走范围。
  - 训练模块和旧基地的“靠近 / 进入目标区”判定改为通过 `GuanghanInteractionArea2D` 静态适配函数。

- **Claude Code**：上一轮接手时间系统的 HUD 显示部分。
  - `scripts/base/sprint06_base_scene.gd`：新增独立右上角 `time_hud_panel` / `time_hud_label`。
  - `scripts/training/training_module_scene.gd`：在常驻 `minimal_hud` 中加入 `minimal_time_label`。
  - 未触碰 `TimeManager.gd` 核心逻辑。

- **Codex**：上一轮实现第一版行动推进制时间系统。
  - 新增 `/root/TimeManager` autoload。
  - 初始时间：Day 01 06:40，月夜末期，距月昼 7 天。
  - 关键交互已接入耗时：植物诊断、维修 / 恢复、整理 / 检查、发送报告、睡觉 / 休息。

## 对共用核心文件的改动记录

- **Codex 本次触碰了第一档共用核心文件**：
  - `scripts/training/training_module_scene.gd`
    - 已按规则先查看 `git log --oneline -- scripts/training/training_module_scene.gd`。
    - 注意到最近 `35b1d8b Give the action-based time display its own HUD widgets` 改过 HUD，因此本次避开 HUD 结构，只接入移动/交互适配。
    - 新增 controller 调用分支，保留旧训练步骤状态机和目标配置。
  - `scripts/base/sprint06_base_scene.gd`
    - 已按规则先查看 `git log --oneline -- scripts/base/sprint06_base_scene.gd`。
    - 注意到最近 `35b1d8b` 改过时间 HUD，因此本次避开 HUD 结构，只接入移动/交互适配。
    - 旧基地使用 center 坐标模式，并保留原有可走边界。
- `scripts/props/reference_prop.gd`：本次未触碰。
- `scripts/training/training_manager.gd`：本次未触碰。

## 验证

- `git diff --check`：通过，仅有 CRLF 工作区提示。
- Godot headless 场景加载通过：
  - `res://scenes/main.tscn`
  - `res://scenes/training/Training_02_AirlockProcedure.tscn`
  - `res://scenes/training/Training_05_PlantDiagnosis.tscn`
  - `res://scenes/base/OldBaseInteriorScene.tscn`

## 已知问题 / 暂不覆盖范围

- 本次是第一版移动底座，不是完整 `CharacterBody2D + TileMap collision` 迁移。
- 旧基地仍使用脚本绘制房间与中心点移动；正式家具碰撞、门碰撞、TileMap 碰撞后续单独 Sprint 做。
- `InteractionArea2D` 当前主要作为语义适配层和未来节点化入口，现有训练/旧基地仍通过绘制控件和矩形目标运行。
- 移动耗时已接入训练模块与旧基地主线，但早期 `scripts/main.gd` 沙盒和 Arrival 场景尚未统一迁移。
- 未做截图验收；本次只做底层验证和场景加载验证。

## 先别碰

（暂无）
