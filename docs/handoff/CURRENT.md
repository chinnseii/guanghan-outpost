# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Claude Code（代 Codex，训练小型地图重构 + 用户实测反馈修复）

## 追加：Tab 被 UI 焦点系统抢走（用户实测反馈，已修复）

用户反馈：新地图里按 Tab 呼不出宇航服状态面板，焦点在底部"保存训练进度"/
"返回主菜单"两个按钮之间切换。根因：Tab 同时是 Godot 内建的
`ui_focus_next`（UI 焦点切换）动作——一旦任何可见按钮持有键盘焦点（比如
鼠标点过底部按钮），GUI 层会先消费 Tab 做焦点遍历，`_unhandled_input()`
永远收不到。更危险的连带问题：按钮持焦点时按 Enter（同时也是"interact"
交互键）会直接触发那个按钮——玩家按 Enter 交互可能误触"返回主菜单"。

修复（双保险）：
1. `training_base_map.gd` 的 Tab 处理从 `_unhandled_input()` 挪到
   `_input()` 并 `set_input_as_handled()`——`_input` 先于 GUI 焦点处理
   执行，无论焦点在哪 Tab 都能正常呼出面板。
2. 新地图全部 12 处动态创建的按钮（底部/简报/暂停/弹窗/状态面板）设为
   `focus_mode = Control.FOCUS_NONE`，按钮从根上不再能持有键盘焦点；
   旧引擎 `training_module_scene.gd` 的 `_add_button()`（太阳能/结算场景
   的底部按钮）同步加了这一行。鼠标点击不受影响。

## 追加：应用户要求删除旧训练场景

用户确认旧场景"不要了"，已删除 8 个不再被引用的旧训练场景文件：
`Training_01_SuitControl` / `Training_02_AirlockProcedure` /
`Training_03_PowerRepair` / `Training_04_PowerDistribution` /
`Training_04_LifeSupport` / `Training_05_AirSystemControl` /
`Training_05_PlantDiagnosis` / `Training_06_TrainingGreenhouse`（.tscn）。
同时删除了 7 个只为这些旧场景服务、删掉场景后就跑不起来的一次性截图采集
工具（`tools/capture_airlock_prop_bridge_check.gd` 等——截图产物本身仍在
`docs/screenshots/` 里，不受影响）。

注意事项：
- `training_manager.gd` 里的 `MODULE_01/02/04/05/06` 常量**保留为纯字符串**
  ——`_remap_legacy_training_scene()` 靠它们识别旧存档里的旧场景路径并重定向
  到新地图，注释已改为"legacy path strings only，禁止再传给
  change_scene_to_file()"。
- `training_module_scene.gd` 里旧模块的 `_suit_control_config()` 等配置
  函数变成了不可达的死代码（没有场景再以这些 module_id 实例化该脚本），
  本轮**没有删**——该脚本仍被太阳能阵列训练场/最终结算场景使用，而且新地图
  还引用它的房间绘制内部类，动它风险大于收益，留给以后专门的清理轮次。
- 删除后 headless 全场景扫描（主菜单/新地图/太阳能/结算/开始/通知/黑屏/
  申请/旧基地）全部 0 错误。

## 追加：用户实测发现的三个问题（已修复）

用户实际运行游戏后反馈：(1) 穿宇航服弹窗的标题错写成"植物舱诊断详情"；
(2) 点"确认穿戴"没反应。排查确认三个根因，全部修复并验证：

1. **"开始训练"还在进旧场景**（最关键）：`training_start_scene.gd` 的
   开始按钮和 `TrainingManager.start_training()` 仍指向旧的
   `Training_01_SuitControl.tscn`，上一轮只改了 `MODULE_SCENES` 没改这两个
   直接引用。已改为进 `TRAINING_BASE_MAP`；同时 `continue_scene_path()`
   新增 `_remap_legacy_training_scene()`，旧存档里残留的旧训练场景路径
   会自动重定向到新地图（太阳能阵列场景除外，它仍是正式场景）。
2. **弹窗标题写死**：旧引擎 `training_module_scene.gd` 的共享弹窗标题
   硬编码"植物舱诊断详情"——穿宇航服/太阳能检查/故障诊断/高风险确认/
   宇航服归位全部显示这个错误标题。新增 `diagnosis_modal_title` 成员 +
   `_set_diagnosis_modal_title()`，7 处 `_show_*` 弹窗各自设置正确标题。
   （模块 03 和最终结算场景仍用这个引擎，所以这个修复不是白做。）
3. **"确认穿戴"没反应**：残留的 `suit_state.json` 里宇航服还是"穿着"
   状态（上一次游玩留下的），`wear_suit_training()` 前置检查
   `suit_storage_state == "ready"` 不满足直接返回 false，而失败提示写进了
   默认隐藏的左侧面板，玩家完全看不到。三层修复：
   - `start_training()` 现在会先 `SuitManager.reset_to_arrival()`（训练
     在地球上全新开始，重置是语义正确的），且顺序在 `save_progress()`
     之前，保证存档里打包的是重置后的状态；
   - 新地图新增常驻可见的 toast 提示条（底部居中，自动消失）——锁门提示/
     需要宇航服提示/解锁通知/穿戴失败原因现在都看得见了（此前全部写在
     隐藏面板里，是通用可见性问题）；
   - 新增两个防卡死兜底：已完成穿戴任务但宇航服未穿时，整备架仍可重新
     穿戴（`_try_interact_suit_wear_fallback()`）；房间任务完成状态现在
     会在场景加载时从存档标记同步（`step_index` 置为已耗尽），避免重进
     地图被要求重穿已穿着的宇航服。
   另外已清空 AppData 里的旧存档（suit_state/training_progress/
   training_time_state），用户下次启动是干净状态。

验证：headless 全场景扫描 0 错误；临时脚本（已删）验证了 start_training
重置宇航服并路由到新地图、旧场景路径重映射（太阳能场景不受影响）、已完成
房间的 step 同步、穿戴兜底在"任务完成但未穿"时可用/已穿时不出现。

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
