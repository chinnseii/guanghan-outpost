# Sprint 04: National Training

# 《广寒前哨 Guanghan Outpost》

Version: 0.1
Status: Ready for Codex
Owner: Codex / Technical Director
Recommended Branch: `feature/sprint-04-national-training`

Related Docs:

* `/docs/PROJECT_BRIEF.md`
* `/docs/sprints/SPRINT_03_PROLOGUE_APPLICATION.md`
* `/docs/art/APP-002A/`
* `/docs/art/TS-001/`
* `/docs/art/TS-002/`

---

## 0. Sprint Goal

Sprint 04 的目标是实现《广寒前哨》的国家训练序列。

玩家在 Sprint 03 中已经完成：

```text
申请加入广寒计划
↓
资格初审通过
↓
进入国家训练序列
```

Sprint 04 要完成：

```text
国家训练序列
↓
基础操作训练
↓
气闸训练
↓
供电维修训练
↓
生命支持训练
↓
植物诊断训练
↓
最终考核
↓
任务派遣通知书
↓
接受月面派遣
↓
黑屏文字
↓
进入 ArrivalCinematicScene
```

本 Sprint 的核心不是做普通教程。

本 Sprint 的核心是让玩家感受到：

> 我不是点了按钮就去了月球。
> 我接受了训练。
> 我通过了考核。
> 所以我才有资格被派往广寒前哨。

---

## 1. Important Scope Clarification

Sprint 04 是正式 New Game 流程的一部分。

但本 Sprint 仍然不做完整第一小时月球内容。

### Included

本 Sprint 包含：

* Training Entry
* Training Hub / Training Room
* Suit Control Training
* Airlock Procedure Training
* Power Repair Training
* Life Support Training
* Plant Diagnosis Training
* Final Assessment
* Mission Assignment Notice
* Accept Moon Assignment
* Black Screen Text
* Transition to ArrivalCinematicScene

### Explicitly Out of Scope

本 Sprint 不做：

* 完整发射动画
* 火箭 / 飞船飞行动画
* 完整月球基地探索
* 第一株植物正式剧情
* 完整农作物系统
* 完整生命支持模拟
* 完整供电系统
* 自动化
* 科技树
* 居民
* 采矿
* 建筑升级
* 战斗
* 长夜系统

训练中的供电、氧气、水、植物状态，都可以是 **scripted simulation values**。
不要在 Sprint 04 中实现完整生存系统。

---

## 2. Required Flow

Sprint 04 的正式流程：

```text
TrainingPlaceholderScene
↓
TrainingStartScene
↓
TrainingModule_01_SuitControl
↓
TrainingModule_02_AirlockProcedure
↓
TrainingModule_03_PowerRepair
↓
TrainingModule_04_LifeSupport
↓
TrainingModule_05_PlantDiagnosis
↓
FinalAssessmentScene
↓
MissionAssignmentNoticeScene
↓
Accept Moon Assignment
↓
Black Screen Text
↓
ArrivalCinematicScene
```

可以用一个 TrainingHubScene 管理模块入口，也可以按顺序线性推进。
当前建议：**线性推进**，避免 Sprint 04 过大。

---

## 3. Tone Direction

国家训练不是游戏化教程。

不要使用：

```text
很好！
太棒了！
任务完成！
获得奖励！
```

训练系统的语气应当是：

```text
正式
冷静
清晰
程序化
可信
```

推荐称呼：

```text
国家深空生命科学中心训练控制系统
```

简称：

```text
训练控制系统
```

不要使用“教官大喊”式表达。
不要使用热血口号。

---

## 4. Training UI Direction

训练 UI 可以复用 Sprint 03 的深空终端风格。

训练 HUD 应该包含：

```text
训练阶段
当前目标
氧气模拟值
电力模拟值
生命支持状态
提示信息
```

但不要做复杂 UI。

### Example

```text
训练阶段：气闸流程
当前目标：关闭内舱门
氧气模拟值：98%
舱压状态：稳定
```

---

# P0 Issues

---

## Issue 01: Training Entry Integration

### Goal

将 Sprint 03 的 TrainingPlaceholderScene 接入真正训练流程。

### Requirement

点击：

```text
进入训练序列
```

后进入：

```text
TrainingStartScene
```

不再只显示占位文本。

### TrainingStartScene Text

```text
国家训练序列启动。

候选人档案已同步。
训练编号：GHT-2068-0421

本训练将验证你在月面长期驻留任务中的基础操作能力。
```

按钮：

```text
开始训练
返回主菜单
```

### Acceptance Criteria

* Sprint 03 资格初审结果页可以进入 TrainingStartScene。
* TrainingStartScene 可以进入第一个训练模块。
* 不破坏当前存档流程。

---

## Issue 02: Training State Data

### Goal

建立训练流程状态数据。

### Required Data

至少保存：

```text
TrainingStarted
CurrentTrainingModule
SuitControlCompleted
AirlockProcedureCompleted
PowerRepairCompleted
LifeSupportCompleted
PlantDiagnosisCompleted
FinalAssessmentCompleted
MissionAssignmentAccepted
```

### Requirement

训练进度必须接入 SaveManager。

### Acceptance Criteria

* 玩家完成训练模块后状态被保存。
* 读档后不会丢失训练进度。
* 可以从当前训练模块继续。

---

## Issue 03: Training Module 01 — Suit Control

### Goal

训练玩家基础操作。

### Scene

```text
/scenes/training/Training_01_SuitControl.tscn
```

### Player Actions

玩家需要完成：

```text
1. 移动到指定区域
2. 与训练终端交互
3. 查看宇航服状态
4. 返回训练出口
```

### Required System Usage

* PlayerController
* Interaction System
* UIManager
* EventManager
* GameStateManager

### Training Control Lines

```text
训练模块一：宇航服基础控制。

请移动至标记区域。
请与训练终端交互。
正在读取宇航服状态。
状态稳定。
模块完成。
```

### Acceptance Criteria

* 玩家能移动。
* 玩家能按 E 交互。
* 玩家完成指定目标后进入下一个模块。
* 不需要复杂动画。

---

## Issue 04: Training Module 02 — Airlock Procedure

### Goal

训练玩家气闸流程。

### Scene

```text
/scenes/training/Training_02_AirlockProcedure.tscn
```

### Required Objects

* InnerDoor
* AirlockChamber
* OuterDoor
* PressureConsole

### Player Actions

玩家需要按顺序完成：

```text
1. 进入气闸室
2. 关闭内舱门
3. 启动舱压模拟
4. 等待舱压稳定
5. 打开外舱门
6. 退出气闸
```

### Important

这是训练模拟，不需要完整舱压系统。
可以用 scripted state 伪造：

```text
InnerDoorClosed = true
PressureStable = true
OuterDoorUnlocked = true
```

### Training Control Lines

```text
训练模块二：气闸流程。

进入气闸室。
关闭内舱门。
舱压模拟开始。
舱压稳定。
外舱门已解锁。
流程完成。
```

### Acceptance Criteria

* 玩家不能在内舱门未关闭时打开外舱门。
* 玩家必须按正确顺序完成。
* 如果操作顺序错误，显示冷静提示，不惩罚。

错误提示示例：

```text
流程顺序错误。请先关闭内舱门。
```

---

## Issue 05: Training Module 03 — Power Repair

### Goal

训练玩家基础维修流程。

### Scene

```text
/scenes/training/Training_03_PowerRepair.tscn
```

### Required Objects

* DamagedPowerPanel
* ToolStation
* PowerConsole
* TestLight

### Player Actions

```text
1. 从工具台获取维修工具
2. 检查损坏的供电面板
3. 执行维修交互
4. 在控制台重启供电
5. 观察测试灯亮起
```

### Important

不要实现完整维修小游戏。
当前只需要：

* 工具获取状态
* 维修进度条或等待交互
* 供电状态变化
* 灯光开关反馈

### Training Control Lines

```text
训练模块三：供电维修。

请从工具台取用维修工具。
检测到供电面板故障。
开始维修。
维修完成。
请重启供电。
供电恢复。
```

### Acceptance Criteria

* 没有工具时不能维修。
* 维修后 PowerRestored = true。
* TestLight 从关闭变为开启。
* LightingManager 被用于表现灯光恢复。

---

## Issue 06: Training Module 04 — Life Support

### Goal

训练玩家理解生命支持系统的基础关系。

### Scene

```text
/scenes/training/Training_04_LifeSupport.tscn
```

### Required Objects

* LifeSupportConsole
* OxygenDisplay
* WaterDisplay
* TemperatureDisplay
* PowerDisplay

### Player Actions

```text
1. 打开生命支持控制台
2. 查看氧气、水、电力、温度状态
3. 启动稳定程序
4. 等待状态变为稳定
```

### Important

不要实现完整生命支持模拟。
只实现训练脚本状态：

```text
OxygenStatus = Low
WaterStatus = Stable
PowerStatus = Restored
TemperatureStatus = Low
LifeSupportStatus = Stabilizing
LifeSupportStatus = Stable
```

### Training Control Lines

```text
训练模块四：生命支持系统。

生命支持不是单一设备。
氧气、水、电力与温度必须同时稳定。

请打开生命支持控制台。
检测到氧气偏低。
检测到温度偏低。
启动稳定程序。
生命支持状态：稳定。
```

### Acceptance Criteria

* 玩家能看到四项状态。
* 玩家能启动稳定程序。
* 状态从异常变为稳定。
* UI 表现清楚，但不复杂。

---

## Issue 07: Training Module 05 — Plant Diagnosis

### Goal

训练玩家观察植物状态，为后续“最后一株植物”做铺垫。

### Scene

```text
/scenes/training/Training_05_PlantDiagnosis.tscn
```

### Required Objects

* TrainingPlant
* PlantScanner
* NutrientConsole
* GrowLight

### Player Actions

```text
1. 观察训练植物
2. 使用扫描器读取状态
3. 选择诊断结果
4. 调整补光或营养方案
5. 植物状态稳定
```

### Diagnosis Options

可以提供三个简单选项：

```text
缺水
光照不足
根区温度异常
```

初版正确答案建议：

```text
光照不足
```

### Training Control Lines

```text
训练模块五：植物状态诊断。

植物不会主动报警。
你需要学会观察。

请扫描训练植物。
叶片颜色偏浅。
生长灯输出不足。
请调整补光方案。
植物状态趋于稳定。
```

### Important

这不是完整种植系统。
不要实现作物成长周期。
只做诊断与状态变化。

### Acceptance Criteria

* 玩家可以扫描植物。
* 玩家可以选择诊断项。
* 选择正确后进入调整步骤。
* 训练植物状态从 Warning 变为 Stable。
* 为后续第一株植物剧情打下认知基础。

---

# Final Assessment

---

## Issue 08: Final Assessment Scene

### Goal

实现最终考核。

最终考核不是答题。
它是一个小型模拟事故。

### Scene

```text
/scenes/training/FinalAssessmentScene.tscn
```

### Scenario

训练控制系统启动模拟事故：

```text
模拟事故开始。

供电下降。
生命支持不稳定。
植物舱状态异常。
```

玩家需要综合使用前面学过的内容。

### Required Steps

玩家必须按顺序完成：

```text
1. 从工具台获取维修工具
2. 修复供电面板
3. 重启供电
4. 打开生命支持控制台
5. 启动稳定程序
6. 扫描植物
7. 判断植物异常
8. 调整补光方案
9. 返回考核终端提交结果
```

### Failure Handling

不要设计成硬核失败。

如果玩家操作顺序错误，提示：

```text
流程不完整。请检查供电、生命支持与植物舱状态。
```

如果玩家长时间没有操作，可以提示：

```text
提示：生命支持稳定通常依赖供电状态。
```

### Pass Text

```text
最终考核完成。

供电恢复。
生命支持稳定。
植物舱状态稳定。

候选人具备进入月面长期驻留任务训练后阶段的基础资格。
```

### Acceptance Criteria

* 玩家必须综合使用前面训练过的交互。
* 完成后 FinalAssessmentCompleted = true。
* 进入 MissionAssignmentNoticeScene。
* 不需要复杂评分。
* 不显示 A/B/C 等级。

---

# Mission Assignment

---

## Issue 09: Mission Assignment Notice

### Goal

玩家通过最终考核后，收到真正的任务派遣通知。

注意：

Sprint 03 的“资格初审结果”不是录取通知书。
Sprint 04 通过最终考核后，才出现正式派遣。

### Scene

```text
/scenes/training/MissionAssignmentNoticeScene.tscn
```

### Title

```text
广寒计划任务派遣通知书
```

### Body Text

```text
致 [PlayerName]：

你已完成国家深空生命科学中心训练序列，
并通过最终考核。

经广寒计划任务委员会确认，
你将被派往月球 · 广寒前哨，
执行长期驻留与生命支持建设任务。

任务地点：月球 · 广寒前哨
任务类型：长期驻留 / 生命支持建设
任务身份：常驻开拓者

广寒前哨已经等待新的开拓者很久了。
```

### Buttons

```text
暂缓派遣
接受月面派遣
```

### If Temporary Decline

If player selects:

```text
暂缓派遣
```

show:

```text
派遣已暂缓。

候选人档案将保留。
广寒计划仍将等待你的确认。
```

Then return to main menu or TrainingStartScene.

### If Accept

Set:

```text
MissionAssignmentAccepted = true
```

Then show black screen text.

### Acceptance Criteria

* MissionAssignmentNotice appears only after FinalAssessmentCompleted = true.
* Player cannot receive mission assignment before final assessment.
* Accept and decline paths both work.
* State is saved.

---

## Issue 10: Accept Assignment Black Screen

### Goal

实现正式接受月面派遣后的黑屏文字。

This text should appear here, not after Sprint 03 application submission.

### Text Sequence

Use exactly:

```text
感谢你的选择。

在你之前。
已经有17位开拓者。
替人类迈出了这一步。

现在。
轮到你了。
```

### Timing

Show line by line.

Recommended pacing:

```text
感谢你的选择。
pause

在你之前。
pause

已经有17位开拓者。
pause

替人类迈出了这一步。
pause

现在。
pause

轮到你了。
```

### After Sequence

Transition to:

```text
ArrivalCinematicScene
```

For now, no launch animation required.

### Acceptance Criteria

* Text appears only after accepting moon assignment.
* Text uses 17 pioneers.
* Text appears line by line, not all at once.
* No triumphant music.
* After sequence, scene transitions to ArrivalCinematicScene.

---

## Issue 11: Save / Load Integration

### Goal

训练进度必须能保存。

### Save Data

At minimum:

```text
TrainingStarted
CurrentTrainingModule
CompletedTrainingModules
FinalAssessmentCompleted
MissionAssignmentAccepted
CurrentSceneAfterTraining
```

### Acceptance Criteria

* Player can quit during training and continue later.
* Completed modules remain completed.
* FinalAssessmentCompleted persists.
* MissionAssignmentAccepted persists.
* Continue Mission routes the player to the correct training state.

---

## Issue 12: Dev Support

### Goal

保留开发测试入口。

### Dev Entry Options

```text
Go to Training Start
Go to Final Assessment
Go to Mission Assignment Notice
Reset Training Progress
Go to ArrivalCinematicScene
```

### Requirement

Dev entries must be clearly marked Dev Only.

Do not expose these in the normal player flow.

---

# Recommended File Structure

```text
/scenes/training/
  TrainingStartScene.tscn
  Training_01_SuitControl.tscn
  Training_02_AirlockProcedure.tscn
  Training_03_PowerRepair.tscn
  Training_04_LifeSupport.tscn
  Training_05_PlantDiagnosis.tscn
  FinalAssessmentScene.tscn
  MissionAssignmentNoticeScene.tscn

/scripts/training/
  TrainingManager.gd
  TrainingModule.gd
  TrainingObjective.gd
  TrainingAssessment.gd

/resources/training/
  training_module_01_suit_control.tres
  training_module_02_airlock.tres
  training_module_03_power_repair.tres
  training_module_04_life_support.tres
  training_module_05_plant_diagnosis.tres
```

Actual structure may adapt to the current project, but keep it clear.

---

# Definition of Done

Sprint 04 完成标准：

* [ ] Sprint 03 资格初审结果可以进入训练序列
* [ ] TrainingStartScene exists
* [ ] Suit Control training works
* [ ] Airlock Procedure training works
* [ ] Power Repair training works
* [ ] Life Support training works
* [ ] Plant Diagnosis training works
* [ ] Final Assessment works
* [ ] Mission Assignment Notice appears only after final assessment
* [ ] Player can accept moon assignment
* [ ] Player can temporarily decline assignment
* [ ] Accepting assignment shows black screen text
* [ ] Black screen text uses 17 pioneers
* [ ] After black screen, transition to ArrivalCinematicScene
* [ ] Training progress can be saved and loaded
* [ ] No full survival system is implemented
* [ ] No full crop system is implemented
* [ ] No launch animation is required
* [ ] Dev entries are clearly marked Dev Only

---

# Final Instruction

Sprint 04 is not “tutorial content.”

Sprint 04 is the player proving they are ready.

Keep it simple.
Keep it formal.
Keep it playable.

The player should finish Sprint 04 thinking:

> 我不是随便被送上月球的人。
> 我接受过训练。
> 我通过了考核。
> 现在，我要去广寒前哨了。
