# Sprint 04 Module 02

# Airlock Procedure Training

# 《广寒前哨 Guanghan Outpost》

Status: Ready for Codex
Related Sprint: Sprint 04 National Training
Based on Visual Standard: `/docs/art/TR-001/`

---

## 0. Goal

Module 02 的目标是实现：

# 气闸流程训练

# Airlock Procedure Training

玩家需要学习：

> 进入气闸、关闭内舱门、启动舱压流程、等待舱压稳定、打开外舱门、离开气闸。

这不是普通“开门教程”。

气闸在《广寒前哨》中是非常重要的概念：

> 它是生命环境和月球真空之间的边界。

本模块要让玩家第一次意识到：

* 门不是随便开的；
* 舱压必须稳定；
* 内舱门和外舱门不能同时打开；
* 流程顺序很重要；
* 未来进入月球基地时，这套流程会再次出现。

---

## 1. Scene

Create or update:

```text
/scenes/training/Training_02_AirlockProcedure.tscn
```

Use the same visual blockout standard as Module 01.

This scene should look like a training room, not an abstract UI panel.

---

## 2. Required Room Layout

The room should be divided into three clear zones:

```text
Training Room Interior
↓
Airlock Chamber
↓
Exterior Simulation Zone
```

Recommended layout:

```text
左侧：训练室内部
中间：气闸舱
右侧：月面外部模拟区 / 真空模拟区
```

### Required Objects

```text
InnerDoor
AirlockChamber
OuterDoor
PressureConsole
PressureStatusDisplay
TrainingExit
Player
```

### Visual Meaning

* InnerDoor：训练室进入气闸的门
* AirlockChamber：中间缓冲舱
* OuterDoor：通往外部模拟区的门
* PressureConsole：控制舱压流程的终端
* PressureStatusDisplay：显示“舱压状态”
* Exterior Simulation Zone：外部真空/月面环境模拟区

Use placeholder art, but make each object visually understandable.

Do not use plain colored squares only.

---

## 3. Visual Direction

Follow TR-001:

* dark aerospace training room
* floor tiles
* wall boundary
* controlled lighting
* official training environment
* low-saturation blue for system markers
* warm yellow for current interactive focus
* red/orange only for warning
* avoid green for doors or exits

### Important Color Rule

Do not use green to show “door available” or “exit”.

Green should be reserved for life / plants in this project.

Use:

```text
blue = training / system guidance
amber = current interaction
red-orange = warning / wrong order
white/cyan = stable status
```

---

## 4. Training Flow

Module 02 must be staged.

Do not allow all interactions from the start.

### Stage 01: Enter Airlock Chamber

Objective:

```text
进入气闸室
```

Hint:

```text
请移动至气闸室内部。
```

Behavior:

* InnerDoor is open.
* OuterDoor is locked.
* Player moves into AirlockChamber.

When player enters chamber, advance to Stage 02.

---

### Stage 02: Close Inner Door

Objective:

```text
关闭内舱门
```

Hint:

```text
请靠近内舱门控制面板并按 E。
```

Behavior:

* Player interacts with InnerDoor or its control panel.
* InnerDoorClosed = true.
* InnerDoor visually changes to closed state.
* OuterDoor remains locked.

Training line:

```text
内舱门已关闭。
```

Advance to Stage 03.

---

### Stage 03: Start Pressure Simulation

Objective:

```text
启动舱压模拟
```

Hint:

```text
请使用舱压控制台。
```

Behavior:

* Player interacts with PressureConsole.
* PressureStatus = Stabilizing.
* Show short progress text or progress bar.

Training line:

```text
舱压模拟开始。
```

Advance to Stage 04.

---

### Stage 04: Wait for Pressure Stable

Objective:

```text
等待舱压稳定
```

Hint:

```text
请等待舱压状态稳定。
```

Behavior:

* After short delay, PressureStatus = Stable.
* PressureStatusDisplay shows:

```text
舱压状态：稳定
```

Training line:

```text
舱压稳定。
外舱门已解锁。
```

Advance to Stage 05.

---

### Stage 05: Open Outer Door

Objective:

```text
打开外舱门
```

Hint:

```text
请靠近外舱门并按 E。
```

Behavior:

* Player interacts with OuterDoor.
* OuterDoorOpen = true.
* Exterior Simulation Zone becomes accessible.

Training line:

```text
外舱门已打开。
```

Advance to Stage 06.

---

### Stage 06: Exit to Exterior Simulation Zone

Objective:

```text
进入外部模拟区
```

Hint:

```text
请移动至外部模拟区。
```

Behavior:

* Player moves into Exterior Simulation Zone.
* Module02Completed = true.

Training line:

```text
气闸流程完成。
```

Then activate TrainingExit or continue to next module.

---

## 5. Incorrect Operation Handling

This module must teach order.

If player attempts wrong actions, do not punish.
Show calm procedural warning.

### Example 01

If player tries to open OuterDoor before InnerDoorClosed:

```text
流程顺序错误。请先关闭内舱门。
```

### Example 02

If player tries to open OuterDoor before PressureStable:

```text
舱压尚未稳定。外舱门保持锁定。
```

### Example 03

If player leaves chamber before completing sequence:

```text
气闸流程尚未完成。
```

No damage.
No failure screen.
No dramatic alarm unless later required.

---

## 6. HUD Requirements

Left training HUD should show:

```text
训练模块二：气闸流程
当前目标：[current objective]
氧气模拟值：98%
电力模拟值：稳定
舱压状态：[未启动 / 稳定中 / 稳定]
提示信息：[current hint]
```

When pressure is stabilizing, update:

```text
舱压状态：稳定中
```

When complete:

```text
舱压状态：稳定
```

---

## 7. Room Labels and Interaction Prompts

Use minimal labels.

Recommended labels:

```text
内舱门
气闸室
舱压控制台
外舱门
外部模拟区
```

Interaction prompt examples:

```text
E 关闭内舱门
E 使用舱压控制台
E 打开外舱门
```

Do not rely only on labels.
Objects should be visually distinct.

---

## 8. Required State Variables

At minimum:

```text
Module02Started
PlayerInsideAirlock
InnerDoorClosed
PressureSimulationStarted
PressureStable
OuterDoorUnlocked
OuterDoorOpen
Module02Completed
```

These can be implemented inside TrainingManager or module-specific script.

No need for full real pressure simulation yet.

---

## 9. Save / Load Requirement

Training progress should save:

```text
CurrentTrainingModule = AirlockProcedure
CurrentAirlockStage
InnerDoorClosed
PressureStable
OuterDoorOpen
Module02Completed
```

If save/load is too much for sub-stage at this point, at least save:

```text
Module02Completed
CurrentTrainingModule
```

But do not lose completed module status.

---

## 10. Transition to Next Module

After completion, show:

```text
模块完成：进入下一训练模块
```

Next module will be:

```text
Training_03_PowerRepair
```

If Module 03 is not ready, temporary button can show:

```text
下一模块尚未开放
```

or return to TrainingStartScene.

---

## 11. Do Not Expand Scope

Do not implement:

* real oxygen consumption
* real decompression damage
* full EVA system
* full suit pressure system
* complex door animation
* failure/death state
* cinematic cutscene
* external lunar gameplay

This is a training simulation.

Keep it simple, procedural, and readable.

---

## 12. Definition of Done

Module 02 is complete when:

* [ ] Scene looks like a training room with an airlock chamber
* [ ] Player can enter airlock chamber
* [ ] Inner door can be closed
* [ ] Pressure simulation can be started
* [ ] Pressure status changes to stable
* [ ] Outer door unlocks only after pressure is stable
* [ ] Player can enter exterior simulation zone
* [ ] Wrong order interactions show calm procedural warnings
* [ ] HUD updates current objective and pressure status
* [ ] Module02Completed is set after completion
* [ ] Next module transition is available or safely placeholdered
* [ ] No full survival / oxygen / EVA system is implemented

---

## 13. Final Intent

This module should teach the player:

> 气闸不是普通的门。
> 它是人类能否在月球活下去的边界。

Keep it formal.
Keep it clear.
Keep it playable.
