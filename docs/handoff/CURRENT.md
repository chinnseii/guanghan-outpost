# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Codex（修复返舱后再次进气闸无法回中控）

## 本轮完成：Airlock Return Door Fix

用户反馈：
- 完成返舱流程、进入一次训练中控室后，再回到气闸舱，内舱门不能再返回中控室。

根因：
- 返舱流程 `_apply_airlock_return_flow()` 会临时移除气闸舱 `inner_door` 的 `door_to`，避免增压完成前直接走回中控室。
- 返舱最后一步“打开内舱门”完成后，场景会切回训练中控室，但此前移除的 `door_to` 没有恢复。
- 玩家之后再次进入气闸舱时，内舱门看起来仍在，但底层已不是可穿越门。

实现：
- 修改 `scripts/training/training_base_map.gd`
  - 新增 `_restore_airlock_inner_door_walkthrough()`。
  - 返舱完成后恢复 `inner_door`：
    - `door_to = "hub"`
    - `door_spawn = Vector2(90, 300)`
    - `door_press = "ui_right"`
    - `door_blocked_by_state = "InnerDoorClosed"`
  - 同步状态：
    - `InnerDoorClosed = false`
    - `InnerDoorUnlocked = true`
    - `InnerDoorOpenedAfterEva = true`
  - 返舱完成后重新 `_register_training_doors()`，确保恢复后的内舱门也注册到 DoorStateManager。

保留行为：
- 返舱增压完成前，内舱门仍不能直接走穿。
- 完成返舱后，从中控室再回气闸舱，玩家可以继续向右顶内舱门返回中控室。
- DoorStateManager 仍只负责门注册、锁定状态、通过判定，不移动玩家、不切场景、不推进时间。

## 触碰的共用文件

- `scripts/training/training_base_map.gd`
  - 开工前已执行：
    - `git log --oneline -- scripts/training/training_base_map.gd`
  - 本轮属于训练小地图气闸门状态修复，沿用已有可选门字段 `door_to` / `door_spawn` / `door_press` / `door_blocked_by_state`，没有重写训练模块引擎。

本轮未修改：
- `scripts/training/training_module_scene.gd`
- `scripts/training/training_manager.gd`
- `scripts/props/reference_prop.gd`
- `scripts/base/sprint06_base_scene.gd`

## 当前 Door System 状态

已有底层文件：
- `scripts/data/DoorTypeDatabase.gd`
- `scripts/data/DoorAssetDatabase.gd`
- `scripts/managers/DoorStateManager.gd`

已注册 autoload：
- `DoorStateManager="*res://scripts/managers/DoorStateManager.gd"`

训练系统当前接入方式：
- DoorStateManager 负责训练门注册、锁定状态、通过判定、返回目标区域与出生点编号。
- TrainingBaseMap 负责实际房间切换、玩家坐标放置、训练进度与模块解锁。
- TrainingBaseMap 在通过训练门后调用 `close_door_after_pass()`，避免运行态门保持打开。
- 返舱流程完成后，TrainingBaseMap 会恢复并重新注册气闸内舱门的中控室通路。

## 验证

已通过：
- `C:\Users\csw83\Documents\Codex\tools\Godot_v4.7-stable_win64.exe --headless --check-only --path .`
- `C:\Users\csw83\Documents\Codex\tools\Godot_v4.7-stable_win64.exe --headless --path . --quit`

两条命令退出码均为 0。

## 用户偏好记录

- 用户明确表示以后不需要 Codex 主动截图，用户会自己试玩验收。
- 后续除非用户明确要求截图，否则不要新增截图脚本或跑截图验收。

## 已知问题 / 后续建议

- 训练门目前是运行时由 TrainingBaseMap 注册到 DoorStateManager；训练门状态不单独持久化为正式基地门状态。
- 训练小地图仍保留自己的模块解锁规则；DoorStateManager 是统一门状态层，不替代训练任务系统。
- DoorStateManager 尚未接入正式旧基地房间切换；当前正式门数据主要是状态层预置，还没有成为旧基地实际导航入口。
- 工作区仍有大量历史 `.import` / `.uid` / 素材与截图相关未跟踪或修改文件，本轮未处理。
