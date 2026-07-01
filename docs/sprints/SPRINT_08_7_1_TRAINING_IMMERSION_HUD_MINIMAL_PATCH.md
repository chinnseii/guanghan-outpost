# Sprint 08.7.1 Training Immersion & HUD Minimal Patch

Status: Implemented / Awaiting owner review

## Goal

This patch keeps Sprint 08.7 as an editor-playable internal demo and improves the National Training presentation without adding Sprint 09 content.

## Changes

- Training modules now open with an entry briefing modal.
- The permanent left-side training panel is hidden during normal movement.
- A compact in-world HUD shows only the module name and current objective.
- Press `Tab` to recall the full training task/status panel.
- Press `Esc` to open the pause menu.
- The pause menu contains:
  - 继续训练
  - 查看任务
  - 返回主菜单
- Bottom gameplay buttons are hidden during modules.
- Module completion now points the player to the in-world exit.
- Normal module exit prompt: `E / Enter 进入下一阶段`
- Final assessment exit prompt: `E / Enter 查看任务派遣通知`
- Final assessment has an in-world assessment exit for reaching Mission Assignment Notice.

## Updated Scenes

- `scenes/training/Training_01_SuitControl.tscn`
- `scenes/training/Training_02_AirlockProcedure.tscn`
- `scenes/training/Training_03_PowerRepair.tscn`
- `scenes/training/Training_04_LifeSupport.tscn`
- `scenes/training/Training_05_PlantDiagnosis.tscn`
- `scenes/training/FinalAssessmentScene.tscn`

These scenes share `scripts/training/training_module_scene.gd`, so the patch applies consistently.

## Controls

- Mission/task panel: `Tab`
- Pause menu: `Esc`
- Interaction: `E / Enter`

## Scope Guard

This patch does not begin Sprint 09.
It does not add new training systems, survival simulation, inventory, farming, or launch content.
