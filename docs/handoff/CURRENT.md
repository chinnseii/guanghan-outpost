# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Codex

## 正在进行

（暂无，Resident Health System v1 已完成；本轮完成训练 minimal HUD 健康显示排版修正，待提交 / 推送）

## 最近完成

- **Codex**：完成训练 minimal HUD 的时间 + 健康显示排版修正。
  - 文件：`scripts/training/training_module_scene.gd`
  - 之前：`minimal_time_label` 把时间信息与健康摘要全部用 `·` 拼成一条长文本，390px 宽度下容易自动换行过挤。
  - 现在：`minimal_time_label` 使用 `_minimal_resident_status_text()`：
    - 第一行：时间信息压缩显示。
    - 第二行：驻留者健康摘要。
  - 任务卡高度暂不继续增加，避免左上常驻卡压迫训练画面。
  - 尝试用窗口模式生成截图时被工具审批/额度拦截，因此没有新增验收截图；已通过 Godot headless 加载 `Training_03_PowerRepair.tscn` 验证脚本不报错。

- **Codex**：实现 Resident Health System v1。
  - 新增 `scripts/managers/HealthManager.gd`，并在 `project.godot` 注册为 `/root/HealthManager`。
  - `HealthManager` 负责四项驻留者健康状态：
    - 精力 `energy`
    - 饱腹 `fullness`
    - 营养 `nutrition`
    - 心理 `morale`
  - 所有健康值统一为 0-100，数值越低状态越差，并在每次结算后 clamp。
  - 初始抵达值：精力 80、饱腹 80、营养 85、心理 75。
  - 健康状态会保存到独立文件：`user://saves/health_state.json`。
  - 训练进度存档额外写入 / 恢复字段：`HealthState`。
  - 旧基地 / 温室 / 第一周存档额外写入 / 恢复字段：`HealthState`。
  - `TimeManager.advance_time()` 中央流程会先询问健康倍率，再推进时间，再调用健康结算；`HealthManager` 本身不直接推进时间。
  - 已实现行动结算：睡觉、进食、营养液、短/长娱乐、植物诊断、整理物资、发送报告、轻/重维修、短/长采集。
  - 已实现轻量惩罚：低精力增加部分行动耗时，低饱腹增加精力消耗，低营养/低心理降低睡眠恢复。
  - 旧基地右上状态 HUD 与训练 HUD 显示简洁健康摘要，不显示四条大状态条。
  - 主菜单开发菜单新增健康 Debug 按钮。

- **Codex**：上一轮完成 PlayerController Foundation Sprint。
  - 新增 `scripts/controllers/player_controller_2d.gd`。
  - 新增 `scripts/controllers/interaction_area_2d.gd`。
  - 训练模块与旧基地移动已接入统一移动距离计时底座。

## 对共用核心文件的改动记录

- **Codex 本次触碰了第一档共用核心文件**：
  - `scripts/training/training_module_scene.gd`
    - 已按规则先查看 `git log --oneline -- scripts/training/training_module_scene.gd`。
    - 本次只调整 `minimal_time_label` 的显示格式：时间压缩一行，健康摘要单独一行。
    - 未改训练步骤状态机、交互流程或模块配置。
- 近期健康系统实现中也触碰过：
  - `scripts/base/sprint06_base_scene.gd`
    - 已接入 `HealthState` 保存/读取，并把健康摘要合并进既有右上状态面板。
  - `scripts/training/training_manager.gd`
    - 已在训练进度中附带 `HealthState`，并在 reset 时同步重置 HealthManager。
- `scripts/props/reference_prop.gd`：本次未触碰。

## 验证

- `git diff --check -- scripts/training/training_module_scene.gd docs/handoff/CURRENT.md`：通过，仅有 CRLF 提示。
- Godot headless 场景加载通过：
  - `res://scenes/training/Training_03_PowerRepair.tscn`

## 已知问题 / 暂不覆盖范围

- 本轮没有生成新的视觉截图：窗口模式截图被工具审批/额度拦截。
- 本次不实现完整 ResidentStatusPanel；只保留常驻 HUD 的简洁健康摘要。
- 本次不把健康消耗接入移动距离；移动仍只通过 TimeManager 计时。
- 本次不重构 PlayerController、不迁移 CharacterBody2D、不做 TileMap collision。
- Godot 在本地刷新了大量已跟踪 `.import` 文件，它们不属于本次逻辑，提交时不要暂存。

## 先别碰

（暂无）
