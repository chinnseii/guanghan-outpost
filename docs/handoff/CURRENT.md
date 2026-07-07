# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Codex（候选人学术背景系统）

## 本轮完成：候选人学术背景系统

按用户最新指令，把申请流程中的旧“教育背景/职业背景”收敛为独立的
“候选人学术背景”信息优势系统。

第一版只保留 4 个学术背景：

1. 植物科学
2. 机械工程
3. 材料科学
4. 医学

学术背景只影响专业提示，不提供任何数值 Buff。

## 主要改动

- 新增 `scripts/managers/AcademicBackgroundManager.gd`
  - 独立管理学术背景数据、当前选择、标签和专业提示。
  - 暴露 `get_all_backgrounds()`、`set_background()`、
    `get_selected_background_id()`、`get_selected_background_name()`、
    `has_background_selected()`、`has_background_tag()`、
    `get_selected_background_data()`、`get_professional_hint(context_id)`。
  - 当前支持训练 03/04/05/06 的专业提示 context。
- `project.godot`
  - 新增 `AcademicBackgroundManager` autoload。
- `scripts/data/player_profile_data.gd`
  - 新增存档字段 `selected_academic_background_id`。
  - 同时继续保留旧 `EducationBackground` 字段作为中文名称兼容旧系统。
- `scripts/application/application_flow_scene.gd`
  - “02 教育背景”改为“选择候选人学术背景”。
  - 页面只显示 4 个学术背景卡片。
  - 删除申请页里的农业工程 / 生命支持工程旧选项。
  - 选择后需要点击“确认选择”，并通过确认弹窗保存。
  - 保存 `selected_academic_background_id`，同时写入旧 `EducationBackground`
    名称用于兼容旧读法。
  - 页面文案明确写出：学术背景不会提供数值加成，只提供专业提示。
- `scripts/training/training_module_scene.gd`
  - 训练 03 太阳能阵列故障提示改为优先读取
    `AcademicBackgroundManager.get_professional_hint("training_03_solar_array_fault")`。
  - 训练 04 配电房、训练 05 空气系统、训练 06 温室诊断新增专业提示读取。
  - 旧的 Training 03 直读 `EducationBackground` 逻辑保留为兼容 fallback。

## 触碰的共用文件

本轮按协作规则，改动前已查看 git log：

- `scripts/training/training_module_scene.gd`
- `scripts/training/training_manager.gd`

实际只修改了：

- `scripts/training/training_module_scene.gd`

改动方式为新增 `AcademicBackgroundManager` 调用分支与兼容 fallback，没有修改
训练时间、维修材料、宇航服、移动、健康、负重等默认行为。

## 明确没有修改

本轮没有修改以下用户指定禁止改动的系统：

- `scripts/managers/HealthManager.gd`
- `scripts/managers/MovementTimeManager.gd`
- `scripts/managers/RepairManager.gd`
- `scripts/managers/SuitManager.gd`
- `scripts/managers/BackpackManager.gd`
- `scripts/managers/TimeManager.gd`
- `scripts/managers/TrainingTimeManager.gd`

也没有把学术背景接入任何数值惩罚或收益。

## 验证

已用 Godot 4.7 headless 验证：

- `--headless --path . --quit`
- `--headless --check-only --path .`
- `res://scenes/application/ApplicationStartScene.tscn`
- `res://scenes/training/TrainingStartScene.tscn`
- `res://scenes/training/Training_03_PowerRepair.tscn`
- `res://scenes/training/Training_04_PowerDistribution.tscn`
- `res://scenes/training/Training_05_AirSystemControl.tscn`
- `res://scenes/training/Training_06_TrainingGreenhouse.tscn`

以上均退出码 0。

## 已知问题 / 后续建议

- 旧的 BaseStatus / Power / Water / Air / PlantGrowth / Health 等系统里仍有
  直接读取 `EducationBackground` 的兼容逻辑，本轮按用户要求没有修改它们。
  因为申请页会继续写入旧中文名称，这些旧提示不会立刻断。
- 当前专业提示主要进入训练 HUD / 诊断弹窗。后续 UI polish 可以把训练 04/05
  的提示做成更正式的“专业提示”面板，避免左侧 HUD 过长。
- 工作区仍有大量历史 `.import` / `.uid` / 截图相关未跟踪或修改文件，本轮未处理。
