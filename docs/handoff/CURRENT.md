# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Codex（训练系统重构）+ Claude Code（代 Codex，宇航服密封/通信字段移除，
以下追加一节，本文档其余内容为 Codex 原文未改动）

## 本轮完成：训练系统重构骨架

按用户新的训练系统指令，把训练主链路从旧的 5 段流程改为：

1. Training 01：宇航服整备室（沿用 `suit_control`）
2. Training 02：气闸流程（沿用 `airlock_procedure`）
3. Training 03：月面太阳能阵列训练场（沿用 Claude Code 上轮的 `power_repair` / `SolarArrayTrainingField.tscn`）
4. Training 04：配电房供电恢复（新增 `power_distribution`）
5. Training 05：训练舱空气恢复（沿用 `life_support`，新场景入口）
6. Training 06：温室植物诊断（沿用 `plant_diagnosis`，新场景入口）
7. 收尾任务：返回宇航服整备室，脱下宇航服并放回维护位
8. 查看训练结果后进入任务派遣通知

## 主要改动

- 新增场景：
  - `res://scenes/training/Training_04_PowerDistribution.tscn`
  - `res://scenes/training/Training_05_AirSystemControl.tscn`
  - `res://scenes/training/Training_06_TrainingGreenhouse.tscn`
- `scripts/training/training_manager.gd`
  - 新增 `MODULE_06`
  - `MODULE_04` 指向配电房
  - `MODULE_05` 指向空气系统控制室
  - `plant_diagnosis` 改为第 6 个模块
  - 新增 `PowerDistributionCompleted`
  - `are_required_modules_completed()` 现在要求 6 个核心训练站完成
  - 读取完成状态改用 `_read_progress_data()`，避免 timeout 检查时反序列化覆盖 live manager 状态
- `scripts/training/training_module_scene.gd`
  - 新增 `power_distribution` 模块配置
  - 03 太阳能阵列完成后跳到 04 配电房
  - 05 空气系统完成后跳到 06 温室
  - 06 温室完成后跳到收尾任务
  - `final_assessment` 当前作为“宇航服归位与维护”收尾场景使用
  - 新增 `return_suit_confirm` 步骤类型
- `scripts/managers/SuitManager.gd`
  - 新增 `remove_suit_to_service_station_training()`
  - 该方法只推进 `TrainingTimeManager.advance_training_time(...)`
  - 不调用正式 `TimeManager.advance_time(...)`
  - 用于训练收尾归位宇航服
- `scripts/main.gd`
  - Dev Menu 的 Training Module 04/05/06 入口已按新编号更新

## 触碰的共用文件

本轮按协作规则，改动前已查看 git log：

- `scripts/training/training_module_scene.gd`
- `scripts/training/training_manager.gd`
- `scripts/managers/SuitManager.gd`

本轮没有修改：

- `scripts/managers/RepairManager.gd`
- `scripts/data/FaultDatabase.gd`
- `scripts/managers/InventoryManager.gd`
- `scripts/data/ItemDatabase.gd`

Claude Code 上轮的 Training Module 03 / `FA-TR-SOLAR-001` 保持不覆盖。

## 验证

已用 Godot 4.7 console headless 单独加载以下场景，均无脚本解析错误：

- `res://scenes/training/Training_04_PowerDistribution.tscn`
- `res://scenes/training/Training_05_AirSystemControl.tscn`
- `res://scenes/training/Training_06_TrainingGreenhouse.tscn`
- `res://scenes/training/FinalAssessmentScene.tscn`

完整 `--check-only` 曾因 Godot 写 `user://logs` 权限/超时问题未作为最终验证依据。

## 已知问题 / 后续建议

- Training 05 空气系统和 Training 06 温室目前复用旧生命支持/植物诊断内部逻辑，只修正了链路、编号和入口；后续可再细化成“制氧 16% -> 20%”和“光照不足”专门流程。
- Training 收尾 HUD 目前部分状态使用 ASCII（`returned` / `servicing` / `pending`），避免本轮中文字符串在 PowerShell 输出中造成编码误判；后续 UI polish 可改回完整中文。
- 旧的 `Training_04_LifeSupport.tscn` / `Training_05_PlantDiagnosis.tscn` 未删除，作为兼容/回退文件保留，但新链路不再引用它们。
- 工作区还有大量 `.import` / `.uid` / 截图相关未跟踪或修改文件，是本轮之前已有的 Godot 自动生成/历史遗留状态；本轮未纳入处理。

## 追加（Claude Code，代 Codex）：移除宇航服"密封状态"/"通信链路"

应用户要求，把 `SuitManager.gd` 里纯展示、无任何机制读取的
`suit_seal_status`/`suit_comm_status` 两个字段整体去掉：

- `SuitManager.gd`：删掉字段声明、`reset_to_arrival()`/
  `remove_suit_to_service_station_training()` 里的重置、
  `_seal_label()`/`_comm_label()`、`get_suit_status_for_ui()`（现在只剩
  oxygen/oxygen_capacity/power/power_capacity/speed_multiplier 五个键）、
  `panel_status_text()`（密封/通信那行去掉，只留速度倍率）、
  `serialize()`/`deserialize()` 里对应的两个键。
- `scripts/training/training_module_scene.gd`：宇航服状态面板文案去掉
  "密封状态"/"通信链路"两行，删掉不再用到的 `_suit_seal_label()`/
  `_suit_comm_label()`。
- `scripts/ui/suit_panel.gd`（正式游戏 `U` 键面板）只读
  `panel_status_text()` 聚合文本，未受影响，无需改动。
- 旧存档（`suit_state.json`）里如果残留这两个键，`deserialize()`的
  `data.get(key, default)`模式会安全忽略，不会报错——已用 headless 扫了
  一遍全部场景（含本轮新加的 04/05/06）确认无解析错误。
- `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`「训练第一房间」一节已
  补充说明这次移除。

本次提交把这两部分改动（Codex 的训练系统重构 + Claude Code 的密封/通信
移除）一起打进同一个 commit，因为改动落在同一批文件里，没法干净拆开；
两边内容互不冲突，已一起过 headless 验证。
