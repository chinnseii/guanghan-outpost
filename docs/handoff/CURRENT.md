# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Claude Code（代 Codex，训练第一房间：宇航服整备室）

## 正在进行

（暂无——本轮"训练第一房间：宇航服整备室"已实现完成。开始前确认过
`git status`/`CURRENT.md` 均无 Codex 新的并发改动，工作过程中也没有再
出现新的并发改动。）

## 本轮完成（Claude Code，代 Codex）：训练第一房间重构

- **沿用既有 `module_id "suit_control"`（`Training_01_SuitControl.tscn`）**，
  没有新建场景文件、没有改名成需求文档建议的 `"spacesuit_preparation"`——
  重命名会牵动 `TrainingManager` 整条围绕现有 5 个必修模块写死的逻辑
  （`are_required_modules_completed()`/`default_data()`/`MODULE_SCENES`），
  没有功能收益，改用重新配置这一个模块在
  `training_module_scene.gd`（5 个训练模块共用的场景脚本）通用步骤引擎
  上的内容。
- **新 4 步流程**：移动到宇航服整备架（"suit_rack"，复用既有
  `ToolStation.tscn` 道具场景）→ 按 E 弹出穿戴确认弹窗（新步骤类型
  `wear_suit_confirm`，复用 plant_control 的弹窗基础设施）→ 按 Tab 打开
  宇航服状态面板（新步骤类型 `suit_status_panel`，`Tab` 这个既有的
  `mission_panel` action 现在按当前步骤类型条件分支，其余模块的 Tab
  行为完全没变）→ 门锁靠步骤顺序 + `requires`/`blocked_hint` 实现（没有
  新建门节点/锁定状态机，跟 `airlock_procedure` 模块的 "outer_door" 同款
  写法）进入模拟气闸舱（复用已存在的 `airlock_procedure` 模块，不是新
  场景）。
- **`SuitManager.gd` 新增**：`suit_seal_status`/`suit_comm_status`（纯
  展示字段）、`wear_suit_training()`（跟 `wear_suit()` 同样的前置条件，
  但推进 `TrainingTimeManager` 而不是正式 `TimeManager`，已用临时脚本
  验证正式时间快照完全不变）、`get_suit_status_for_ui()`（返回需求文档
  给的七个字段名）。`panel_status_text()` 顺带扩展成两行，加了密封/通信
  ——这个改动也影响正式游戏里已有的 `scripts/ui/suit_panel.gd`（`U` 键），
  因为是同一个 `SuitManager` 实例。**没有新增 `is_suit_worn() -> bool`
  方法**——`SuitManager` 已经有同名公开字段 `is_suit_worn`，GDScript
  不允许字段和方法同名，调用方应直接读字段。
- **`training_module_scene.gd`**：`_suit_control_config()` 整个替换成新
  4 步流程；`_suit_control_hint()` 改成按 `step.type` 匹配（原来按
  `step.target` 匹配，因为新流程里两个新步骤共用同一个 target
  "suit_rack"）；`_try_interact()` 新增两个分支（`suit_status_panel` 早退
  提示、`wear_suit_confirm` 弹窗）；新增
  `_show_wear_suit_confirm_dialog()`/`_build_suit_status_panel()`/
  `_toggle_suit_status_panel()`/`_refresh_suit_status_panel()`/
  `_on_confirm_suit_status_pressed()`/`_suit_manager()`；
  `_toggle_mission_panel()`/`_sync_overlay_visibility()` 各加了几行做
  条件分支和新面板的可见性同步，其余 5 个模块的既有行为完全没动。

## 与正式宇航服系统的边界（需求文档三选一，选了最简单那条）

训练和正式任务**共用同一个 `SuitManager` 实例，不做数据隔离**——需求
文档给的三种做法里最简单的一条。`TrainingManager.reset_progress()`
已经会重置 `SuitManager`（正式宇航服系统上线时接的），但**正式任务真正
开局的 `TimeManager.reset_to_arrival()` 那条链目前没有自动重置
`SuitManager`**（这是既有的、正式宇航服系统本来就没接的缺口，不是本轮
新引入的）。也就是说：如果玩家训练时穿了宇航服、没点"重置训练进度"就
直接进正式任务，训练时的宇航服状态会带进去——见下方已知问题，本轮没有
堵上这个口子。

## 验证

- Godot 4.7 headless：`Training_01_SuitControl.tscn`（本轮改动最大的
  场景）+ `main.tscn` + 其余 6 个训练场景
  （`TrainingStartScene`/`Training_02`~`05`/`FinalAssessmentScene`）+
  `OldBaseInteriorScene`/`OldGreenhouseScene` 共 9 个场景 headless 加载，
  均无 `SCRIPT ERROR`/`Parse Error`。
- 临时脚本（未提交，验证后已删除）跑通了 6 项：训练宇航服初始状态精确
  匹配需求文档给的默认值（ready/未穿戴/100/100/normal/online/0.80x）；
  `wear_suit_training()` 精确推进 `TrainingTimeManager` 15 分钟且完全不
  改变正式 `TimeManager` 的序列化快照；已穿戴时拒绝重复穿戴；
  `get_suit_status_for_ui()` 返回全部七个字段；`panel_status_text()`
  包含密封/通信/速度倍率文本；**直接实例化
  `Training_01_SuitControl.tscn` 场景，读取其真实 `module_data`**，确认
  4 个步骤的 type/target/state_updates/requires 精确匹配新流程设计（不
  只是脚本层面测试孤立函数，是连同场景配置一起验证的）。

## 已知问题 / 暂不覆盖范围

- **训练宇航服状态可能"泄漏"进正式任务**（见上方"边界"一节）：下一轮
  如果要堵上，需要在"接受派遣"那类正式任务真正开始的流程里显式调一次
  `SuitManager.reset_to_arrival()`，本轮没有做这个改动，不确定是否会跟
  未来"玩家保留升级过的宇航服进入正式任务"这类设计冲突，留给下一轮决定。
- `suit_seal_status`/`suit_comm_status` 纯展示，没有任何机制会改变或
  读取它们做判断，只是为了满足面板显示要求新增的两个字段。
- 第二训练区"模拟气闸舱"复用的是已存在的 `airlock_procedure` 模块，不是
  需求文档提到的全新 `AirlockSimulationRoom.tscn`，本轮没有改动
  `airlock_procedure` 模块本身。
- 详细流程/接口见
  `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`（文末"训练第一房间：
  宇航服整备室"一节）。

## 先别碰

- `scripts/managers/BackpackManager.gd` / `StorageManager.gd` /
  `SupplyManager.gd` / `RepairManager.gd` / `scripts/data/FaultDatabase.gd`
  仍是 Codex 自己推进的系统，本轮完全没有碰。
- `scripts/data/ItemDatabase.gd` / `scripts/managers/InventoryManager.gd`
  本轮也没有碰，继续由 Claude Code 维护（改前先
  `git log --oneline -- <file>`）。
