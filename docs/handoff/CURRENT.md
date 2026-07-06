# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Claude Code（代 Codex，移动时间系统 + 一处训练时间隔离 Bug 修复）

## 正在进行

（暂无——本轮"移动时间系统 MovementTimeManager v1"已实现完成。开始前
确认过 `git status`/`CURRENT.md` 均无 Codex 新的并发改动，工作过程中也
没有再出现新的并发改动。）

## 本轮完成（Claude Code，代 Codex）：移动时间系统 MovementTimeManager v1

- **新增 `scripts/managers/MovementTimeManager.gd`**，注册为 autoload
  `/root/MovementTimeManager`。核心字段：`base_move_tiles_per_minute`
  （10.0）/`movement_time_buffer`（0.0）/`min_move_multiplier`（0.30）。
  - `calculate_move_minutes(tile_count, terrain_type)`：四项倍率
    （健康×宇航服×负重×地形）相乘后 clamp 到 0.30 下限，需求文档给的
    三个算例（20 格室内=2 分钟；30 格月面平坦+初代宇航服=5 分钟；低精力
    +超载+宇航服+月面崎岖 30 格=10 分钟）全部用临时脚本逐项验证过。
  - `on_player_moved_tiles(tile_count, terrain_type, context)`/
    `flush_movement_time(...)`：累计到 `movement_time_buffer`，满 1
    分钟才推进对应时间系统，小数部分留在池里。`context`（`"mission"`/
    `"training"`）决定推进 `TimeManager` 还是 `TrainingTimeManager`——
    需求文档建议用全局 `GameState.current_context`，但这个项目里
    `GameState` 从来没注册成 autoload，本次没有引入这个新依赖，改成
    调用方显式传参（场景脚本自己知道自己是训练还是正式场景）。
  - 宇航服消耗：地形是 `lunar_flat`/`lunar_rough` 时按 `eva_normal`
    结算，否则穿戴时按 `indoor_worn`，未穿戴不消耗；用的是**实际取整
    推进的分钟数**，不是原始格数。
  - 没有做 `movement_time_buffer` 存档——需求文档第二十三节明确允许
    第一版不存，本次采纳。
- **`HealthManager.gd` 新增 `get_movement_health_multiplier()`**：
  energy≥40→1.0 / 20–39→0.8 / <20→0.67，是独立于
  `get_action_time_multiplier()`/`get_carry_health_multiplier()` 的第三张
  表，fullness/nutrition/morale 故意不参与。
- **`BackpackManager.get_load_level()` 本来就已经存在**（Codex 之前的
  背包/负重系统自带），本次只是读取，没有新增或改动。
- **`player_controller_2d.gd`（跨场景共用的移动控制器）新增可选字段**
  `movement_time_manager`/`terrain_type`/`movement_context`：
  `_advance_time_steps()` 现在优先委托给
  `MovementTimeManager.on_player_moved_tiles()`，只有在没有场景调用
  `set_movement_time_manager()` 时才落回原来的"每步固定 1 分钟直连
  `TimeManager`"逻辑（fallback 完全没删，向后兼容）。
- **`project.godot`**：`[autoload]` 追加 `MovementTimeManager`。
- **`main.gd`**：新增 Movement Debug 分组（查看状态、模拟 10 格室内/
  30 格月面平坦/30 格月面崎岖移动、重置）。

## 顺手修复的 Bug（发现于本轮，属于"训练时间系统"上一轮改造遗留的
覆盖遗漏）

`training_module_scene.gd` 的 `_move_player()`/`_ensure_player_controller()`
一直把正式 `TimeManager` 传给 `player_controller_2d.gd`——控制器内部
按 64px 一档、每档固定 1 分钟直接推进它。**训练阶段玩家走路这件事，从
"训练时间系统 v1"那次改造起就一直在悄悄推进正式月球任务的
`TimeManager.total_minutes`**，因为那次改造只处理了脚本化交互步骤的
`_advance_time_for_step()`，完全没想到移动本身是另一条独立报时路径。
本次顺手修复：`training_module_scene.gd` 现在额外调用
`player_controller.set_movement_time_manager(_movement_time_manager())`
并把 `movement_context` 设成 `"training"`，训练场景的移动从此走
`TrainingTimeManager`，不会再碰正式时间。已用临时脚本双向验证：
mission 上下文移动完全不改变 `TrainingTimeManager` 快照，training
上下文移动完全不改变 `TimeManager` 快照。

## 验证

- Godot 4.7 headless：`main.tscn` + 全部 6 个共用基地场景
  （`OldBaseInteriorScene`/`OldGreenhouseScene`/`Day02StartScene`/
  `WeekRoutineStartScene`/`SolarArrayExteriorScene`）+ 全部 7 个训练场景
  （`TrainingStartScene`/`Training_01`~`05`/`FinalAssessmentScene`）共
  13 个场景 headless 加载，均无 `SCRIPT ERROR`/`Parse Error`（这批场景
  全都经过 `player_controller_2d.gd`，是本轮改动覆盖面最广的一次）。
- 临时脚本（未提交，验证后已删除）跑通了 10 项：抵达基线四项倍率全部
  1.0；需求文档三个算例（2/5/10 分钟）精确匹配；buffer 只在累计满 1
  分钟才推进真实 `TimeManager`（5+5 格室内验证）；mission/training 两个
  方向的上下文隔离互不污染对方的时间系统快照；宇航服氧气消耗按**实际
  取整推进的分钟数**（不是原始格数，用 `TimeManager` 真实的
  `total_minutes` 差值反推校验，规避了 0.8×0.75 这类十进制小数在浮点
  下不精确导致的边界抖动）在月面地形按 eva_normal 速率精确扣款；室内
  穿戴按 indoor_worn 速率扣款，未穿戴完全不扣；移动全程不直接改动
  `HealthManager.energy`。

## 已知问题 / 暂不覆盖范围

- **没有逐格地形数据**：`terrain_type` 是按场景给的默认值
  （`scene_kind == "solar_array"` → `lunar_flat`，其余 → `indoor`），
  `old_base_clutter`/`lunar_rough` 两档目前没有任何场景在用，是预留
  等级。
- **没有新增专属 UI 面板**：现有 3×2 网格 + Backpack/Storage + Suit 已经
  占满屏幕空间，这个系统本身也不是玩家需要频繁查看的状态；需求文档
  自己也只是"建议"而非"必须"做 UI。
- **`movement_time_buffer` 不存档**：读档后会丢失小于 1 分钟的累计移动
  时间，需求文档明确允许第一版这样做。
- 每格强制 1 分钟、移动直接扣精力、摔倒/事故、复杂寻路预估、坐标级
  真实物理速度、交通工具——按需求文档"本次不要做"清单，全部没有涉及。
- 详细数值/接口清单见
  `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`（文末"移动时间系统
  MovementTimeManager"一节）。

## 先别碰

- `scripts/managers/BackpackManager.gd` / `StorageManager.gd` /
  `SupplyManager.gd` / `RepairManager.gd` / `scripts/data/FaultDatabase.gd`
  仍是 Codex 自己推进的系统，本轮只读取了 `BackpackManager.get_load_level()`
  这一个已有的公开接口，没有改动它的实现。
- `scripts/data/ItemDatabase.gd` / `scripts/managers/InventoryManager.gd`
  本轮也没有碰，继续由 Claude Code 维护（改前先
  `git log --oneline -- <file>`）。
