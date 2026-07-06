# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Codex

## 正在进行

（暂无，Resident Health System v1 已完成本地实现与基础验证，待提交 / 推送）

## 最近完成

- **Codex**：实现 Resident Health System v1。
  - 新增 `scripts/managers/HealthManager.gd`，并在 `project.godot` 注册为 `/root/HealthManager`。
  - 四项健康状态：
    - 精力 `energy`
    - 饱腹 `fullness`
    - 营养 `nutrition`
    - 心理 `morale`
  - 所有健康值统一为 0-100，数值越低状态越差，并在每次结算后 clamp。
  - 初始抵达值：精力 80、饱腹 80、营养 85、心理 75。
  - 已实现行动结算：
    - 睡觉
    - 进食
    - 喝营养液
    - 短 / 长娱乐
    - 植物诊断（稳定/恢复为正反馈，异常/Critical 为负反馈）
    - 整理物资
    - 发送报告
    - 轻 / 重维修
    - 短 / 长采集
  - 已实现轻量惩罚机制：
    - 精力低时，维修 / 采集 / 整理 / 植物诊断耗时增加。
    - 饱腹低时，行动造成的精力消耗增加。
    - 营养低时，睡眠恢复精力减少。
    - 心理低时，睡眠恢复精力减少。
  - `HealthManager` 不直接推进时间；`TimeManager.advance_time()` 中央流程会先询问健康倍率，再推进时间，再调用健康结算。
  - `TimeManager` 已支持 `plant_diagnosis_positive` / `plant_diagnosis_negative`、`send_report_positive` / `send_report_negative` 的基础耗时别名。
  - 旧基地 / 温室 / 第一周存档写入并恢复 `HealthState`。
  - 训练进度存档写入并恢复 `HealthState`。
  - 旧基地右上状态 HUD 与训练 minimal HUD 显示简洁健康摘要。
  - 主菜单开发菜单新增健康 Debug：
    - 四项状态 +/-20
    - 重置健康
    - 设置危险状态
    - 执行睡觉 / 进食 / 营养液 / 短娱乐 / 轻维修 / 短采集
  - 新开驻留 / 重置演示进度会清理并重置 `health_state.json`。

- **Codex**：上一轮完成 PlayerController Foundation Sprint。
  - 新增 `scripts/controllers/player_controller_2d.gd`。
  - 新增 `scripts/controllers/interaction_area_2d.gd`。
  - 训练模块与旧基地移动已接入统一移动距离计时底座。

## 对共用核心文件的改动记录

- **Codex 本次触碰了第一档共用核心文件**：
  - `scripts/training/training_module_scene.gd`
    - 已按规则先查看 `git log --oneline -- scripts/training/training_module_scene.gd`。
    - 本次只把健康摘要合并进既有 minimal HUD / 详情 HUD 文本，不改训练步骤状态机。
  - `scripts/base/sprint06_base_scene.gd`
    - 已按规则先查看 `git log --oneline -- scripts/base/sprint06_base_scene.gd`。
    - 本次接入 `HealthState` 保存/读取，并把健康摘要合并进既有右上状态面板。
    - 植物诊断根据植物状态传入 positive/negative 健康结算 action。
  - `scripts/training/training_manager.gd`
    - 已按规则先查看 `git log --oneline -- scripts/training/training_manager.gd`。
    - 本次在训练进度中附带 `HealthState`，并在 reset 时同步重置 HealthManager。
- `scripts/props/reference_prop.gd`：本次未触碰。

## 验证

- `git diff --check`：通过，仅有 CRLF / `.import` 工作区提示。
- Godot headless 场景加载通过：
  - `res://scenes/main.tscn`
  - `res://scenes/training/Training_05_PlantDiagnosis.tscn`
  - `res://scenes/base/OldBaseInteriorScene.tscn`
  - `res://scenes/base/WeekRoutineStartScene.tscn`

## 已知问题 / 暂不覆盖范围

- 本次不实现疾病、受伤、辐射、死亡、随机 debuff、复杂心理事件。
- 本次不扣除真实食物/营养液资源；代码内保留 TODO，等库存/物资系统接入。
- 本次不把健康消耗接入移动距离；移动仍只通过 TimeManager 计时。
- 本次不重构 PlayerController、不迁移 CharacterBody2D、不做 TileMap collision。
- 常驻 UI 只显示简洁健康摘要；完整 ResidentStatusPanel 仍留待后续。
- Godot 在本地刷新了大量已跟踪 `.import` 文件，它们不属于本次健康系统逻辑，提交时不要暂存。

## 先别碰

（暂无）
