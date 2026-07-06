# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Claude Code

## 正在进行

（暂无——上一个任务已完成并提交）

## 最近完成

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
