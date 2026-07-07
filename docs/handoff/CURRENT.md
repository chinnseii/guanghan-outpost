# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Claude Code（代 Codex，训练小型地图重构）

## 本轮完成：训练小型地图（`TrainingBaseMap.tscn`）

用户反馈现在的训练系统"地图感"很乱——6 个训练关卡各自是独立场景文件，靠
脚本切场景衔接，不是能自由走动的一张地图，跟期待的星露谷式体验差距很大。
按用户给的完整需求文档（7 个区域、hub 结构、门锁解锁顺序、区域数据字段、
"气闸"术语要求等），把训练系统改造成一张小型可走动地图：

- 新场景 `scenes/training/TrainingBaseMap.tscn` + 全新脚本
  `scripts/training/training_base_map.gd`——**完全不修改**
  `training_module_scene.gd` 的引擎代码，只是从它 preload 出来的脚本对象
  上直接引用几个自包含的可视化内部类（房间地板/target 图标/玩家精灵），
  避免重复画美术又不牵动它的引擎。
- 6 个房间同场景内切换：训练中控室（hub，新内容）/宇航服整备室/模拟气闸舱/
  配电房/空气系统控制室/训练温室，走到门口自动触发房间切换，没有黑屏/
  读条，视觉上就是"走过去"。
- 门锁从已有的 6 个训练完成标记直接推导，**只新增了一个持久化字段**
  （`PowerRepairUnlockToastShown`，用来让"太阳能阵列基础输出已恢复"提示
  只弹一次）。
- **关键偏离点**：训练 03（太阳能阵列训练场）继续留在独立场景
  `SolarArrayTrainingField.tscn`，一个字节没动——它背后的宇航服检查/维修
  材料仓库/故障诊断逻辑太复杂太脆弱，硬塞进大厅引擎风险很高，且用户自己
  的需求文档第十七条已经明确允许这个做法。衔接点是气闸舱的外舱门，返回
  时会精确落在气闸舱内侧（呼应需求"训练03完成后玩家需要通过气闸返回室内"）。
- 完整细节（每个房间的门锁字段/入场路由/宇航服归位设计/已知简化范围）见
  `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`「训练小型地图」一节。

## 触碰的共用文件

- `scripts/training/training_manager.gd`：`MODULE_SCENES` 里 5 个模块 id
  改指向新大厅场景（`power_repair` 不变）；新增 `TRAINING_BASE_MAP` 常量、
  `PowerRepairUnlockToastShown` 存档字段、`dev_force_unlock_up_to()` 
  dev-only 辅助函数。`set_current_module()`/`mark_module_completed()`/
  `are_required_modules_completed()` 逻辑本身未改动。
- `scripts/training/training_module_scene.gd`：只改了 `_power_config()`
  里的一行 `"next_scene"`（指向新大厅而不是旧的 `MODULE_04`）。该文件的
  其余全部内容（引擎、其余 5 个 `_*_config()`、对话框逻辑）未改动，继续
  原样支撑 `SolarArrayTrainingField.tscn`/`FinalAssessmentScene.tscn`。
- `scripts/main.gd`：6 个"Dev Only: Training Module NN"按钮里的 5 个改
  指向新大厅，并在跳转前调用新增的 `dev_force_unlock_up_to()`（避免开发者
  跳进大厅发现目标房间显示"锁定"）；新增"Dev Only: Training Base Map (Hub)"
  按钮；训练 03/最终考核两个按钮完全未改动。

## 验证

- Godot 4.7 headless：新场景 + 太阳能阵列 + 最终结算 + 训练起始 + 任务
  通知 + 黑屏 + 5 个旧独立训练场景 + 主菜单，逐一 `--quit`，均无
  `SCRIPT ERROR`/`Parse Error`。
- 临时脚本（未提交，验证后已删除）覆盖：
  1. 门锁解锁顺序完全按需求文档校验（初始只有中控室+宇航服整备室 → 训练
     01 完成解锁气闸 → 训练 03 完成解锁配电房，且正确落在气闸舱出生点
     （不是直接跳进配电房）→ 训练 04/05/06 依次解锁空气系统/温室，全部
     确认，最后 `are_required_modules_completed()` 为 true。
  2. 未穿宇航服无法进入模拟气闸舱（提示"该区域需要穿戴宇航服。"），穿好后
     可以进入——顺带发现并修复了一个真实缺口：`_route_initial_area()`
     （存档恢复/场景直接加载时决定初始房间）原本没有重新做宇航服检查，
     只有玩家主动"走门"才会检查；已加固为路由到需要宇航服的房间时也会
     二次校验，不满足则退回宇航服整备室。
  3. 训练时间系统零污染：`TimeManager.serialize()` 前后完全一致。
  4. 房间内任务完成后不触发场景重载（`current_area_id` 不变，只是解锁下
     一个房间），确认了"已经在大厅时不要重新 change_scene_to_file"这条
     设计要求生效。

## 已知问题 / 暂不覆盖范围

- 这是"房间面板互斥切换"，不是真正连续可行走的 2D 世界/摄像机——同一时刻
  只有一个房间是活的，走门触发切换而不是无缝滚动地图。是本轮明确的降
  范围决定（需求文档自己也写了"训练地图不是探索地图"），如果以后想要更
  接近星露谷的无缝体验，需要专门做一版真正的 2D 世界/摄像机/寻路系统，
  工作量会大很多；这次先把"能走来走去、门锁解锁"这个核心体验做出来。
  用户目前反馈的诉求是"训练模块先做一个小地图"，这一版按此完整交付。
- 原引擎里每个 target 的精细视觉状态展示（比如生命支持面板逐步变色）没有
  逐一移植，只保留了房间整体地板状态的开关（供电恢复/生命支持稳定/植物
  稳定等）——纯视觉简化，不影响任何判定逻辑。
- 旧的 5 个独立训练场景文件（`Training_01/02/04/05/06_*.tscn`）原样保留、
  不再被 `MODULE_SCENES` 引用，但仍是完整可运行的场景（各自的
  `_*_config()` 函数没有删除）。
- 训练 03「强行切换满功率输入」高风险选项目前仍只有文案层面的效果，没有
  实际惩罚——这是更早一轮的已知简化，本轮没有涉及。

## 先别碰 / 本轮触碰说明

- 本轮完全没有碰 `scripts/managers/RepairManager.gd`/
  `scripts/data/FaultDatabase.gd`/`scripts/managers/InventoryManager.gd`/
  `scripts/data/ItemDatabase.gd`（训练 03 的维修系统），也没有碰
  `scripts/managers/AcademicBackgroundManager.gd`（Codex 上一轮加的候选人
  学术背景系统）——这些都跟本轮的地图重构无关。
- `scripts/training/training_module_scene.gd` 只改了一行（见上），其余
  3400+ 行原样保留，继续由训练 03/最终考核两个场景使用；如果 Codex 后续
  要继续改这个文件本身的引擎逻辑，请注意它现在同时被"旧的、不再默认进入
  但仍可运行的 5 个独立场景"和"太阳能阵列/最终考核"共用。
