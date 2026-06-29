# Sprint 01 Foundation

Status: In progress

Goal:

> 搭建《广寒前哨》未来所有系统都能复用的底层框架。

本 Sprint 不追求完整玩法，不实现完整第一小时剧情，不继续扩展机器人、科技树、采矿或建筑升级。

## Current Foundation Pass

已完成第一轮底座接入：

- `scripts/game_state_manager.gd`
  - 集中管理 Boot、MainMenu、Application、Training、Launch、Landing、MoonSurface、BaseInterior、Sleep。
  - 当前状态可保存/读取。
- `scripts/time_manager.gd`
  - 支持 Day / Hour / Minute / Time Scale / Pause。
  - 已接入现有进入下一天逻辑和存档。
- `scripts/camera_manager.gd`
  - 集中管理 Camera2D 配置、跟随、缩放、锁定接口。
  - 已接入现有玩家跟随和目标追踪镜头。
- `scripts/ui_manager.gd`
  - 提供 UI Root 绑定、HUD 显示/隐藏、Prompt/Dialog 占位接口。
- `scripts/event_manager.gd`
  - 提供事件触发、一次性事件、事件状态保存接口。
- `scripts/audio_manager.gd`
  - 提供集中音频入口，并转发到现有 `audio_feedback.gd`。
- `scripts/interactable.gd`
  - 提供未来统一交互对象接口：`can_interact`、`get_interaction_label`、`interact`。
- `scripts/interaction_detector.gd`
  - 提供未来玩家交互检测器占位。
- `scripts/data/*.gd`
  - 新增 `ItemData`、`LifeEntityData`、`StructureData`、`InteractableData`、`DialogueData`、`SceneEventData`。
- `data/foundation/test_life_entity.tres`
  - 测试生命实体数据：最后一株植物。
- `data/foundation/test_structure.tres`
  - 测试结构数据：旧控制台。

## Issue Checklist

- [x] Issue 01 Fixed Camera System：已有 `CameraManager`，已接入现有镜头。
- [ ] Issue 02 Player Movement Controller：现有移动仍在 `main.gd`，待迁移。
- [ ] Issue 03 TileMap Layer Framework：已有月面/舱内 `TileMapLayer`，但还没有统一 Ground/Floor/Structure/Object/Decoration/Collision 场景规范。
- [ ] Issue 04 Interaction System：已有接口脚本，现有交互仍在 `main.gd`，待测试对象接入。
- [x] Issue 05 Game State Machine：已有 `GameStateManager`，已进入存档。
- [x] Issue 06 Save / Load System：现有 3 存档槽可用，已开始保存 Foundation managers。
- [x] Issue 07 Day / Time System：已有 `TimeManager`，已接入进入下一天。
- [ ] Issue 08 Lighting Framework：待新增 `LightingManager` / `LightZone`。
- [~] Issue 09 UI Manager：已有 `UIManager` 占位并绑定 UI Root，待迁移 HUD / Prompt / Dialogue。
- [x] Issue 10 Data Driven Framework：已有 Resource 数据类型和测试数据。
- [ ] Issue 11 Scene Structure：待建立 `/scenes/core`、`/scenes/test/FoundationTestMap.tscn` 等结构。
- [x] Issue 12 Audio Manager Placeholder：已有 `AudioManager` 转发现有音频入口。
- [x] Issue 13 Event Manager Placeholder：已有 `EventManager`，待测试区域接入。
- [ ] Issue 14 Dialogue System Placeholder：待实现。
- [ ] Issue 15 Input Manager：现有输入仍在 `main.gd`，待迁移。

## Next Foundation Steps

1. 建立 `FoundationTestMap` 测试场景。
2. 将玩家移动拆为 `PlayerController.gd`，支持启用/禁用输入。
3. 将现有 E 键交互逐步迁到 `Interactable` / `InteractionDetector`。
4. 新增 `LightingManager.gd` 和至少一个可开关暖光测试对象。
5. 拆出 `UIManager` 的 Prompt、Dialogue、HUD Layer。
