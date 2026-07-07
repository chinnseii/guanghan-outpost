# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Codex（任务派遣通知书按钮文案与返回行为调整）

## 本轮完成：任务派遣通知书“暂缓派遣”改为“返回主菜单”

用户反馈：
- 任务派遣通知书页面左侧按钮“暂缓派遣”不符合当前试玩流程。
- 需要改成“返回主菜单”。

实现：
- `scripts/training/mission_assignment_notice_scene.gd`
  - 左侧按钮文案从 `暂缓派遣` 改为 `返回主菜单`。
  - 按钮回调从 `_decline_assignment` 改为 `_return_to_main_menu`。
  - 新增 `_return_to_main_menu()`，跳转到 `res://scenes/main.tscn`。
  - 未改动“接受月面派遣”流程。

## 相关上轮状态

仍保留上一轮已完成内容：
- 训练房间完成后也继续检测门触发，解决完成温室任务后无法回中控室的问题。
- 空气系统控制室门位 / 出生点修正。
- 水循环状态移到训练温室。
- 电力显示移到配电房。
- 空气系统房间移除通风单元。
- 生命支持核心改为墙面状态栏，未稳定时偏黄色提示。
- 氧气/温度改为两个可交互终端：`制氧终端`、`温控终端`。
- 生命支持控制台显示氧气与温度异常；医学背景追加专业提示。
- 新增 `life_control` 交互分支，不改变已有 `plant_control` / `pressure_choice` 默认行为。

## 触碰的共用文件

本轮修改的是独立任务派遣通知书脚本，不属于协作规则中第一档共用核心文件。

实际修改：
- `scripts/training/mission_assignment_notice_scene.gd`
- `docs/handoff/CURRENT.md`

未修改：
- `scripts/training/training_base_map.gd`
- `scripts/training/training_module_scene.gd`
- `scripts/training/training_manager.gd`
- `scripts/props/reference_prop.gd`

## 验证

已用 Godot 4.7 headless 验证：
- `--headless --check-only --path .`

退出码 0。

## 用户偏好记录

- 用户明确表示：以后不需要 Codex 主动截图，用户会自己试玩验收。
- 后续除非用户明确要求截图，否则不要新增截图脚本或跑截图验收。

## 已知问题 / 后续建议

- 训练小地图仍是“房间切换 + 门触发区”的结构，不是真正连续大地图。
- 后续如果继续重排房间，应同步检查所有 `door_spawn` 是否落在门触发区外侧，避免刚切房间就被再次触发。
- 工作区仍有大量历史 `.import` / `.uid` / 素材与截图相关未跟踪或修改文件，本轮未处理。

## 追加（Claude Code，代 Codex）：气闸舱内舱门"开着时可走回"（用户实测反馈）

用户反馈：气闸舱里内舱门还没关闭时，走上去应该能直接回到室内（靠近时
出现"E 关闭内舱门"提示，继续往门里走则返回训练中控室），而不是撞墙。

实现（`training_base_map.gd`）：
- 内舱门目标新增三个通用门属性：`door_to: "hub"`（走穿回中控室，与
  Codex 返舱流程完成后直接回中控室的既有行为一致）、
  `door_blocked_by_state: "InnerDoorClosed"`（"关闭内舱门"步骤完成后
  通道即封闭）、`door_press: "ui_right"`（必须主动向东顶着门走才触发，
  防止出生点/任务目标与门触发区重叠时误穿——这是新增的通用防误触发
  机制，其它门也可用）。
- `_check_door_crossing()` 支持上述两个新字段。
- 返舱流程 `_apply_airlock_return_flow()` 会摘掉内舱门的 `door_to`：
  返舱时内舱门必须保持封闭直到增压完成（最后一步 E 交互自己会切回
  中控室）。
- 删掉了冗余的第一步"进入内舱门"（玩家本来就是刚走进气闸舱，该步在
  出生点上会瞬间自动完成，毫无感知；且它的判定区与新的走穿通道冲突）。
  没有任何逻辑依赖它的 PlayerInsideAirlock 状态键。
- 出舱流程中内舱门关闭后显示"锁定"贴片（`_target_flow_locked()`），
  让"通道已封闭"可见。
- 整备室→气闸舱的 `door_spawn` 从 (650,300) 挪到 (580,300)，出生点
  脚部判定不再落在内舱门触发区内。
- 临时脚本（已删）验证：站在门里不按方向键不会误穿；开门状态顶着门走
  确实回到中控室；InnerDoorClosed 后通道封闭；返舱流程无 door_to。

本 commit 同时包含 Codex 本轮未提交的并行改动（房间相对布局重排、
返舱增压流程、任务派遣通知书按钮改"返回主菜单"、太阳能场景出口右移并
改名"返回气闸外舱门"）——与内舱门修复落在同一批文件里，无法干净拆分，
已一起过全场景 headless 验证（0 错误）。
