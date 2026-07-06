# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Claude Code

## 正在进行

（暂无）

## 最近完成

- **Claude Code**：接手时间系统的 HUD 显示部分（Codex 已完成 `TimeManager` 核心逻辑）。
  - `scripts/base/sprint06_base_scene.gd`：新增独立的 `time_hud_panel`/`time_hud_label`
    （右上角小面板，`Vector2(1250, 20)`，随 `_hide_gameplay_hud_for_narrative()`
    一起隐藏），把时间信息从"系统状态"大段文字顶部搬出来，移除了
    `_safe_hud_text()` 里原来的 `time_text` 拼接。
  - `scripts/training/training_module_scene.gd`：在常驻的 `minimal_hud`
    （左上角任务卡）里加了 `minimal_time_label`，显示单行压缩格式
    （`_time_hud_text().replace("\n", " · ")`），面板高度相应从 96 调到 118。
  - 截图验证：`tools/capture_time_hud_check.gd`，产出
    `docs/screenshots/prop_bridge_check/31_old_base_time_hud.png` 和
    `32_training_time_hud.png`，确认两处都不跟已有 HUD 元素重叠。
  - 未触碰 `TimeManager.gd` 本身，只读了它已公开的
    `compact_hud_text()`/`consume_phase_notice()`（Codex 已经在两个场景里
    接好的 `_time_hud_text()` 包装函数）。

- **Codex**：实现第一版行动推进制时间系统。
  - 新增正式 autoload：`scripts/managers/TimeManager.gd`，并在 `project.godot` 注册为 `/root/TimeManager`。
  - 初始时间：Day 01 06:40，月面状态为“月夜末期”，距月昼 7 天。
  - 支持统一 `advance_time(minutes, reason)`、行动耗时常量、月昼 / 月夜阶段切换、阶段切换提示、序列化 / 反序列化。
  - 主菜单开发入口新增时间调试按钮：+15 分钟、+1 小时、+6 小时、跳到月昼、跳到月夜、重置 Day 01。
  - `TrainingManager` 保存 / 读取 `TimeState`；接受月面派遣时重置为月面 Day 01，避免地面训练时间污染正式抵达时间线。
  - 旧基地、旧温室、第一周 HUD 顶部显示基地时间、月面状态、距阶段切换时间。
  - 训练 HUD 的系统状态中显示同一套时间信息。
  - 关键交互已接入耗时：植物诊断、维修 / 恢复、整理 / 检查、发送报告、睡觉 / 休息。

## 对共用核心文件的改动记录

- **Codex 本次触碰了第一档共用核心文件**：
  - `scripts/training/training_module_scene.gd`
    - 已按规则先查看 `git log --oneline -- scripts/training/training_module_scene.gd`。
    - 新增 `_advance_time_for_step()`、`_default_time_minutes_for_step()`、`_time_hud_text()` 等分支式辅助函数。
    - 训练步骤完成时按步骤类型推进时间；未改原有步骤状态机默认流程。
    - 自由移动耗时暂未接入，代码内保留 TODO：`connect free movement distance to TimeManager.advance_time(1, "move")`。
  - `scripts/base/sprint06_base_scene.gd`
    - 已按规则先查看 `git log --oneline -- scripts/base/sprint06_base_scene.gd`。
    - 在设备交互完成、植物诊断 / 维护、发送报告、睡觉休息处接入 TimeManager。
    - `_save_state()` 写入 `TimeState`，`_load_state()` 恢复 `TimeState`。
    - HUD 文本顶部追加时间信息，不改旧状态 / 任务文本结构。
  - `scripts/training/training_manager.gd`
    - 训练存档附带 `TimeState`，`reset_progress()` 同步重置 TimeManager 后再保存默认进度。
    - `accept_assignment()` 在读取训练进度后重置月面时间，再保存派遣状态。
- `scripts/props/reference_prop.gd`：本次未触碰。

## 验证

- `git diff --check`：通过，仅有 CRLF 工作区提示。
- Godot headless 场景加载通过：
  - `res://scenes/main.tscn`
  - `res://scenes/base/OldBaseInteriorScene.tscn`
  - `res://scenes/training/Training_05_PlantDiagnosis.tscn`
- `--check-only` 在当前 Godot / 项目组合下会挂到超时，但未输出新的脚本错误；以上关键场景加载均退出码 0。

## 已知问题 / 暂不覆盖范围

- 移动耗时尚未接入自由移动控制器。本次只接入关键交互耗时，并在代码内保留 TODO。
- 本次不包含健康、精力、饱腹、心理、资源消耗、完整白昼采集或月夜生存系统。
- P2 环境叙事细节（标签、磨损、灰尘等）仍未覆盖。
- `suit_control` / `life_support` / `final_assessment` 三个训练模块虽然复用已验证的 kind，但没有像 `power_repair` / `plant_diagnosis` / `airlock_procedure` 那样逐一截图复核。

## 先别碰

（暂无）
