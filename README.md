# Guanghan Outpost / 广寒前哨

## 当前状态：行动推进制时间系统 + 驻留者状态 + 基地状态系统

在国家训练与旧基地流程之上，新增了三套底层系统，为后续把"旧沙盒的种田/建造
系统"和"正式叙事流程"结合起来的重构打地基：

- **时间系统**（`scripts/managers/TimeManager.gd`，autoload `/root/TimeManager`）：
  - 时间不随现实时间流逝，只在玩家执行明确行动（移动、诊断、维修、发送报告、
    睡觉等）时通过统一的 `advance_time(minutes, reason)` 推进。
  - 月面阶段分月夜末期 / 月昼作业期 / 月夜期三段：抵达时是 Day 01 06:40 月夜
    末期，距月昼约 7 天；阶段切换时旧基地场景会显示一次系统提示
    （"月面日出确认"/"月面日落确认"）。
  - HUD：右上角常驻小面板（旧基地/温室/第一周）、训练模块左上角常驻任务卡
    （压缩单行），都显示 Day / 时分 / 月面状态 / 距下次切换剩余时间。
  - F12 开发菜单提供时间调试项（+15 分钟 / +1 小时 / +6 小时 / 跳到月昼 /
    跳到月夜 / 重置 Day 01）。
- **驻留者状态**（`scripts/managers/HealthManager.gd`）：精力、饱腹、营养，
  会影响行动的时间/精力消耗倍率；HUD 里跟时间信息拼在同一张常驻小面板/任务
  卡里，一行"驻留者状态：精力 XX / 饱腹 XX"。
- **基地状态系统**（`scripts/managers/BaseStatusManager.gd`）：电力/氧气/舱压
  （0-100）、温度（摄氏度），加供电系统/生命支持/温控系统/密封状态四档
  （OFFLINE/CRITICAL/BASIC/STABLE）。按月夜/月昼、设备状态、电力对氧气与
  温控的联动规则结算，轻/重维修方法只改状态档位和一次性数值、不自己推进
  时间。默认隐藏，`Tab` 打开旧基地场景里的详细面板（`scripts/ui/base_status_panel.gd`）。
  面板会读取申请时选的教育背景（机械工程/材料科学/医学/植物科学）给出对应的
  专业提示文字，不提供数值加成。
- **PlayerController 移动底座**（`scripts/controllers/player_controller_2d.gd` /
  `interaction_area_2d.gd`）：训练模块和旧基地的移动/交互判定统一到这两个
  脚本，移动会按跨越的格数推进时间。
- **训练设备道具化**：训练模块里的供电面板、控制台、植物舱、补光灯、舱门等
  设备，从手写 `_draw()` 程序绘制迁移到跟旧基地/温室共用的可复用道具场景
  （`scripts/props/reference_prop.gd` + `scenes/props/training/`），设备的
  fault/repairing/restored 等状态通过同一套 `status_text` 机制驱动，旧场景
  行为不受影响。

三套 Manager 的存档字段都并入了旧基地（`sprint06_progress.json`）和训练进度
（`training_progress.json`）的既有存档结构，没有另开一套独立存档体系。

仍不包含：完整的精力/饱腹/心理数值结算平衡、密封与温控的实际维修交互入口、
白昼采集与月夜生存的核心循环玩法——这些是下一阶段的内容。

## 旧版沙盒原型

项目最早期有一套完整跑通的种田/建造/资源结算/机器人沙盒原型（V0.1 - V0.31A），
目前跟上面这条正式流程完全断开，只能从 F12 开发菜单进入。详细系统清单、操作
方式和沙盒专属的旧版 Foundation Manager，见
[`docs/LEGACY_SANDBOX_PROTOTYPE.md`](docs/LEGACY_SANDBOX_PROTOTYPE.md)。

## 当前状态：Sprint 08.7.1 训练沉浸感与 HUD 简化补丁

本轮不进入 Sprint 09，只打磨国家训练段落的呈现方式：
- 训练模块进入时显示入口简报，确认后进入可移动训练舱。
- 常驻左侧任务面板默认隐藏，训练中只保留小型当前目标 HUD。
- `Tab` 打开 / 关闭任务面板。
- `Esc` 打开暂停菜单：继续训练 / 查看任务 / 返回主菜单。
- 底部“保存训练进度 / 返回主菜单”不再作为训练中的常驻按钮。
- 模块完成后需要走到训练出口，按 `E / Enter` 进入下一阶段。
- 最终考核完成后需要走到考核出口，按 `E / Enter` 查看任务派遣通知。
- 新增说明文档：`docs/sprints/SPRINT_08_7_1_TRAINING_IMMERSION_HUD_MINIMAL_PATCH.md`

## 最新补丁：Sprint 08.7.1 Addendum + Sprint 08.7.2

本轮继续不进入 Sprint 09，只打磨现有 Demo 的交互可信度：
- 设备交互加入短暂过程反馈：锁移动、角色进入扫描/维修姿态、设备高亮、进度条结束后才更新状态。
- 对地报告发送先显示通信链路 / 传输队列，再保存报告已发送状态。
- 旧基地中央控制台、供电面板、供电重启、生命支持、日常巡检与报告终端已接入轻量交互反馈。
- 新增植物诊断视图：植物近景图 + 传感器提示 + 维护动作选择。
- 新增诊断占位图：`assets/art/plants/diagnostics/last_plant_*.png`
- 文档：
  - `docs/sprints/SPRINT_08_7_1_EQUIPMENT_INTERACTION_FEEDBACK.md`
  - `docs/sprints/SPRINT_08_7_2_PLANT_VISUAL_DIAGNOSIS_PATCH.md`

## 当前状态：Sprint 08.7 编辑器内可试玩 Demo 封装

当前目标是 Godot 编辑器内自测：按 Run 后从主菜单正常开始，完整玩到第一周结束与 Phase 02 占位页。本阶段不导出 Windows exe，不创建安装包，不进入 Sprint 09。

本轮新增：

- 主菜单版本号：`v0.5-editor-playtest`
- 主菜单输入提示：移动、交互、取消、开发菜单
- `开始新驻留` 在已有进度时显示确认，并可清理 Demo 进度后从头开始
- `继续驻留` 支持申请、训练、旧基地、第一周与旧存档槽进度
- 隐藏开发菜单新增 `Dev Only: Reset Demo Progress`
- 新增 Demo 文档：
  - `docs/sprints/SPRINT_08_7_FIRST_PLAYABLE_DEMO_PACKAGING.md`
  - `docs/demo/FIRST_PLAYABLE_DEMO_TEST_PLAN.md`
  - `docs/demo/KNOWN_ISSUES_PRE09.md`
- 新增 08.7 验收截图脚本：`tools/capture_sprint08_7_demo_packaging.gd`

## 已冻结：Sprint 08.6 序章流程与叙事打磨

已完成序章链路收束：主菜单正式入口、申请系统、资格初审、国家训练、任务派遣、月面抵达、旧基地、最后一株植物、Day 02、第一周巡检、第一周结束与 Phase 02 占位提示。Sprint 08.6 不进入 Sprint 09；外部太阳能阵列评估仍是下一阶段内容。

本轮新增：

- `Phase02PlaceholderScene`：第一周结束后显示“Phase 02：重建广寒前哨 / 下一阶段任务：外部太阳能阵列评估”。
- `Dev Only: Day 07 Report Test`：隐藏开发菜单中的周报流程回归入口。
- `docs/sprints/SPRINT_08_6_PROLOGUE_FLOW_NARRATIVE_POLISH.md`
- `docs/reviews/pre09_flow_audit.md`
- `docs/text/PROLOGUE_TEXT_STYLE_GUIDE.md`
- `tools/capture_sprint08_6_acceptance.gd`：输出 16 张序章验收截图到 `docs/screenshots/sprint08_6_acceptance/`。

一个用于逐步迭代的 Godot 4 月球基地农业生存原型。

## 当前版本：V0.6-dev 旧基地与最后一株植物

当前主线版本把正式玩家入口和开发入口分离：启动后进入 MAIN-001 风格的安静标题屏，正常菜单只显示申请、继续、档案、设置和退出；所有测试入口移动到 F12 开发菜单。Sprint 04 国家训练序列已经包含五个脚本训练模块、最终考核、任务派遣通知和接受派遣后的黑屏到抵达淡入流程。Sprint 05A 聚焦现有开场竖切打磨。Sprint 06 新增玩家抵达月球后进入旧基地、恢复基础系统、发现并稳定最后一株植物的第一小时核心体验。

### Art Reference Integration：OB / GH / SOLAR

已完成第一版结构准备：

- 已读取并对齐 `docs/art/OB-001/`、`GH-001/`、`GH-002/`、`SOLAR-001/` 的 README 方向。
- 未使用目标截图作为整张背景，只作为布局、色彩、光照、资产结构参考。
- 新增可替换素材目录：
  - `assets/art/reference/`
  - `assets/art/old_base/`
  - `assets/art/greenhouse/`
  - `assets/art/solar_array/`
  - `assets/art/player/astronaut/`
  - `assets/art/ui/`
- 新增通用占位 prop 脚本：`scripts/props/reference_prop.gd`
- 新增可复用 prop scenes：
  - `scenes/props/old_base/`
  - `scenes/props/greenhouse/`
  - `scenes/props/solar_array/`
  - `scenes/props/ui/`
- 已按 ASSET-001 补齐模块化素材目录：旧基地 tiles / walls / doors / props / consoles / decals，温室 racks / plant_chamber / plant_states / grow_lights / monitors，太阳能阵列 panels / cables / supports / rocks / decals。
- 已建立 ASSET-001 要求的第一批独立 prop 场景名，包括 `OldFloorTile`、`OldWallModule`、`OldBaseDoor`、三种最后植物状态、补光灯开关状态、植物监测屏 Critical / Stable、太阳能板 Dusty / Tilted / Damaged、断开线缆、支架、脚印和维修标记。
- `OldBaseInteriorScene` 开始使用模块化厚墙框架、地板、控制台、供电面板、生命支持、温室门、储物柜、维护贴纸、日志标记、灯板和灰尘脚印。
- `OldGreenhouseScene` 开始使用开放水培架、中央工程植物舱、植物监测屏、补光灯和水循环面板。
- 温室支持 `Critical` / `Stable` 两种视觉状态；只有最后一株植物在中央工程植物舱内，不给所有植物套玻璃罩。
- 新增 `SolarArrayExteriorScene` 作为 Sprint 09 前的外部太阳能阵列视觉灰盒准备。
- F12 开发菜单新增 `Solar Array Exterior` 入口。
- 视觉验收截图工具输出到 `docs/screenshots/art_reference_integration/`。

仍不包含：

- 最终像素美术。
- 完整太阳能阵列维修玩法。
- 完整电网、建造、库存或种植系统。

### Sprint 08 第一周生存节奏

已完成第一版：

- 新增 Sprint 08 规格文档：`docs/sprints/SPRINT_08_WEEK_ONE_SURVIVAL_RHYTHM.md`
- 新增 `WeekRoutineStartScene` 和 `WeekRoutineEndScene`。
- Day 02 结束后进入 Day 03。
- Day 03-07 共用轻量日常模板：
  - 早间简报
  - 中央控制台
  - 今日巡检 checklist
  - 当日重点
  - 对地报告
  - 返回居住舱休息
- Day 03：重复巡检，建立“日常本身就是工作”的节奏。
- Day 04：水循环低流量提醒。
- Day 05：供电负载限制提醒。
- Day 06：最后一株植物出现轻微恢复迹象。
- Day 07：第一周状态复核与第一周驻留报告。
- 第一周完成后保存 `WeekOneCompleted = true`，不进入 Day 08 正式内容。
- F12 开发菜单新增 Week Routine Start / End。
- 验收截图输出到 `docs/screenshots/sprint08_acceptance/`。

仍不包含：

- 完整种植系统。
- 完整资源消耗模拟。
- 完整库存、补给、建造、科技树或自动化。
- Day 08 正式内容。

### Sprint 07 Day 02 日常巡检与对地报告

已完成第一版：

- 新增 Sprint 07 规格文档：`docs/sprints/SPRINT_07_DAY02_ROUTINE_EARTH_REPORT.md`
- 新增 `Day02StartScene` 和 `Day02EndScene`。
- Day 01 休息后会进入 Day 02 早间淡入与 AI 状态简报。
- Day 02 复用旧基地和旧温室，不新增完整经营系统。
- 中央控制台可生成 D02 状态摘要和今日巡检清单。
- 今日巡检包含：
  - 检查供电面板
  - 检查生命支持控制台
  - 检查水循环状态
  - 检查最后一株植物
  - 发送 Day 02 对地报告
- 前四项巡检可按任意顺序完成，全部完成后才解锁对地报告。
- 对地报告终端支持报告预览、发送、通信延迟与地面确认。
- Day 02 可返回居住舱休息并显示 `第 2 天结束`。
- Day 02 状态保存到 `user://saves/sprint06_progress.json`。
- F12 开发菜单新增 Day 02 Start / Day 02 End 入口。
- 验收截图工具现在输出到 `docs/screenshots/sprint07_acceptance/`。

仍不包含：

- 完整时间系统。
- 完整资源消耗。
- 完整种植成长。
- 完整通信系统。
- Day 03 正式内容。

### Sprint 06 旧基地与最后一株植物

已完成：

- 新增 Sprint 06 规格文档：`docs/sprints/SPRINT_06_OLD_BASE_AND_LAST_PLANT.md`
- 新增正式链路：
  - `ArrivalCinematicScene`
  - `BaseAirlockEntryScene`
  - `OldBaseInteriorScene`
  - `OldGreenhouseScene`
  - `Day01EndScene`
- `ArrivalCinematicScene` 的 `E / Enter 前往基地气闸` 现在进入旧基地气闸流程。
- `ArrivalLandingScene` 的基地气闸入口也接到新气闸流程。
- 新增旧基地气闸 scripted sequence：
  - 外舱门已关闭。
  - 舱压建立中。
  - 氧气交换完成。
  - 内舱门已解锁。
- 进入旧基地后 AI 克制显示：
  - `欢迎回来。`
  - `广寒前哨，等待新的开拓者，已经很久了。`
- 新增旧基地第一房间灰盒：
  - 气闸出口
  - 中央控制台
  - 旧供电面板
  - 供电重启控制台
  - 生命支持控制台
  - 通往旧温室的门
  - 旧储物柜、值班表和少量灰尘痕迹
- 新增旧基地 scripted 状态：
  - `BaseEntered`
  - `BasePowerRestored`
  - `MinimalLifeSupportStable`
  - `GreenhouseUnlocked`
  - `LastPlantDiscovered`
  - `LastPlantDiagnosed`
  - `GrowLightRestored`
  - `PartialWaterCycleRestored`
  - `LastPlantStable`
  - `Day01Completed`
- 中央控制台可查看基地状态摘要，并显示第一条前人日志碎片 `17-A`。
- 可按顺序恢复基础供电、最低生命支持，并解锁旧温室门。
- 新增旧温室灰盒：
  - 旧水培架
  - 枯萎植物槽
  - 损坏补光灯
  - 水循环面板
  - 植物监测屏
  - 诊断终端
  - 中央植物舱与最后一株植物
- 玩家可以发现、观察、诊断最后一株植物，恢复补光和最低水循环。
- 最后一株植物可以从 `Critical` 稳定为 `Stable`，不显示经验值、奖励或成就。
- 新增 Day 01 End 居住舱角落与休息交互。
- Sprint 06 状态保存到 `user://saves/sprint06_progress.json`。
- 主菜单“继续任务”可识别 Sprint 06 存档。
- F12 开发菜单新增 Sprint 06 场景入口。
- 验收截图工具已更新为 Sprint 06，输出到 `docs/screenshots/sprint06_acceptance/`。
- Sprint 06 验收补丁已完成：
  - 气闸加入内外舱门形状、三段状态灯和更安全的流程文本位置。
  - 旧基地加入 `GHO-03 / LIFE SUPPORT BAY` 标识、维护贴纸、储物柜标签、脚印灰尘和 `LOG 17-A` 标记。
  - 最后一株植物的 `Critical` / `Stable` 状态现在有更明确的颜色、叶片姿态、补光和监测屏差异。
  - Day 01 End 房间加入更清晰的休息舱、床边暖光、地球窗、旧杯子、墙面便签和个人储物箱。

截图命令：

```powershell
& "C:\Users\csw83\Documents\Codex\tools\Godot_v4.7-stable_win64_console.exe" --audio-driver Dummy --path . -s tools/capture_acceptance.gd
```

仍不包含：

- 完整基地建造。
- 完整种植系统。
- 作物成长周期或收获系统。
- 库存经济。
- 居民系统。
- 科技树。
- 机器人自动化。
- 完整长期生命支持模拟。
- 完整电网系统。

### Sprint 05A 竖切打磨

已完成：

- 修正申请档案状态流转：
  - 填写申请：`待提交`
  - 提交后审核：`审核中`
  - 资格初审后：`已通过资格初审`
  - 进入训练：`训练序列中`
  - 最终考核后：`已通过最终考核`
  - 接受月面派遣后：`已接受月面派遣`
- 旧存档中的 `已通过初步评估` 会转换为当前正确状态，不再出现在申请表填写页。
- 申请审核页按顺序显示：申请已提交、资格审核、教育背景匹配、训练计划生成、候选人档案建立、审核完成。
- 资格初审结果和任务派遣通知补充文书编号、候选人、档案状态、签发单位和日期。
- 任务派遣通知日期暂与申请系统保持一致：`2068-04-12`。
- 最终考核房间重新分区，供电、生命支持、植物舱和考核终端在画面中更分离，减少标签拥挤。
- 抵达月球场景降低 HUD 存在感，去除玩家到地球的调试感连线，缩小并提亮地球冷光，增强远处基地暖灯，让玩家更像站在月面凝视地球。
- 抵达月球的地球观察文本会先单独显示，结束后才显示 `E / Enter 前往基地气闸`。
- 训练模块门、锁定状态和标签字号做了轻量统一。
- 保留验收截图工具：`tools/capture_acceptance.gd`，用于生成当前竖切验收截图。

截图命令：

```powershell
& "C:\Users\csw83\Documents\Codex\tools\Godot_v4.7-stable_win64_console.exe" --audio-driver Dummy --path . -s tools/capture_acceptance.gd
```

注意：截图需要非 headless 模式；`--headless` 下 Godot dummy viewport 无法保存画面。

仍不包含：

- 新剧情内容。
- 第一株植物序列。
- 作物系统扩展。
- 完整生存系统。
- 发射动画或地月转移段。

## 运行方式

1. 安装 Godot 4.x。
2. 打开 Godot Project Manager。
3. 导入本文件夹里的 `project.godot`。
4. 点击运行。

也可以双击：

```text
launch_godot.bat
```

## Sprint 02 Arrival Prototype

This is a development-only playable prototype, not the final New Game flow.

Current final-flow intention:

```text
New Game -> Application -> National Training -> Final Assessment -> Mission Acceptance -> Launch -> ArrivalLandingScene
```

For now, the main menu exposes `Dev Entry: Arrival Prototype` so TS-001 and TS-002 can be tested directly.

Implemented:

- `res://scenes/arrival/ArrivalLandingScene.tscn`
- `res://scenes/base/BaseInterior_Test.tscn`
- TS-001 moon arrival test scene with transport ship, Earth, distant old base, cargo, cables, tracks, solar panel placeholder and minimal HUD.
- TS-002 Observe Earth event: stay still in the trigger area for 5 seconds, HUD fades, camera locks briefly, AI line plays, and the event is saved as fired.
- Airlock prompt: `E 进入气闸`, then transition to `BaseInterior_Test`.
- Arrival prototype save/load through F5/F9 at `user://arrival_prototype_save.json`.
- Foundation review report: `docs/reports/SPRINT_01_FOUNDATION_REVIEW.md`.

## Sprint 02 Revision 01: Arrival Layout & Feel

Revision 01 keeps Arrival as a development-only prototype, but improves the first-read composition.

- Arrival scene now uses a darker, wider lunar surface instead of a medium-grey test-board feel.
- Earth is moved into a separate sky layer so it reads as background/sky, not an interactable map object.
- Camera follow target is offset so the player is lower-left/lower-middle rather than perfectly centered.
- Transport ship is larger, lower-left, and includes ramp, engine glow and landing scorch placeholders.
- Distant base and airlock are farther ahead with warm lights so they read as the next destination.
- Moon surface now has simple footprints, tire tracks, cables, cargo, rocks, craters, dust and solar-panel silhouettes.
- ObserveEarthEvent starts false on scene start and only triggers after staying still in the observe area for about 5 seconds.
- Debug panel is separate from the minimal HUD and can be toggled with F3.

## Sprint 02 Direction Adjustment: Cinematic Scene Split

Arrival is now split into two prototype scenes:

- `res://scenes/arrival/ArrivalCinematicScene.tscn`: emotional TS-001 / TS-002 opening tableau with sky, Earth, horizon, transport ship, small player figure, distant warm base lights and the Observe Earth moment.
- `res://scenes/arrival/ArrivalLandingScene.tscn`: top-down gameplay prototype for free movement, airlock interaction, save/load validation and base entry.

The main menu dev entry now opens `ArrivalCinematicScene` first. After Observe Earth triggers, press `E` or `Enter` to continue into the top-down ArrivalLandingScene.

This keeps the cinematic target screenshot separate from the gameplay map instead of forcing both jobs into one scene.

## ArrivalCinematicScene Polish Pass

- AI dialogue now appears as lower subtitles instead of covering Earth.
- Earth is smaller, brighter, and has a colder rim glow.
- Transport ship silhouette has clearer engineering panels, landing struts, ramp shape, engine afterglow and light moon dust.
- Player is drawn as a small back-facing figure looking toward Earth and the distant base.
- Continue prompt now reads `E / Enter 前往基地气闸`.
- HUD is dimmer by default; debug remains hidden unless toggled with F3.

## Sprint 03 Prologue & Application

The formal New Game flow now starts with an application instead of sending the player directly to the Moon.

Implemented:

- Main menu entry: `Apply to Project Guanghan`.
- Continue entry: `Continue Mission`, which reopens the saved application flow.
- Application UI shell for the National Deep Space Life Science Center / Project Guanghan.
- Basic identity page: name, birth year, gender display.
- Education background page with six non-buff options.
- Appearance placeholder page for simple body/skin/hair/suit marking presets.
- Submit/review flow with short formal processing lines.
- Preliminary eligibility review result page with player name.
- `进入训练序列` handoff after preliminary approval.
- Accept mission / withdraw mission assignment and the 17-pioneer black screen are deferred until after training/final assessment.
- `TrainingStartScene` for Sprint 04 handoff; `TrainingPlaceholderScene` remains only as a compatibility/dev entry.
- Player profile save file: `user://saves/application_profile.json`.

Out of scope remains launch, inventory, mining, robots, tech tree, RPG stats and education-background buffs for the application flow.

## Sprint 03 Revision 02: Application Result Flow

- Sprint 03 now ends at preliminary eligibility approval, not mission acceptance.
- The former admission/final-choice flow is replaced by `资格初审结果 / PRELIMINARY ELIGIBILITY REVIEW`.
- The result page explains that Moon assignment is only possible after national training and final assessment.
- Buttons are `进入训练序列` and `返回主菜单`.
- `进入训练序列` now opens `TrainingStartScene`.
- The accept-mission black screen has been removed from the Sprint 03 route and deferred to a later sprint.

## APP-002A Application UI Update

- Basic Information gender options now only include `男` and `女`.
- Sensitive real-world fields are not requested.
- Basic Information shows system-generated mission fields: application ID, candidate file status, and mission identity.
- Character preview is removed from Basic Information and appears only on `03 外观与标识`.
- The preview is labeled `开拓者预览 / PIONEER PREVIEW`.
- The preview focuses on astronaut suit, patch, suit ID, name initials, and marking color.
- Gender affects visual body preset only and does not affect stats, abilities, or gameplay bonuses.
- Added the note: `外观仅用于角色显示与任务档案，不影响能力。`

## Sprint 03 Minor Patch Before Acceptance

- Training placeholder text now says the national training sequence is initializing and candidate profile sync should be confirmed.
- The training placeholder keeps a dev entry, renamed to `开发入口：进入月球抵达原型`.
- Appearance & Marking now stores suit ID, patch ID and name initials as separate fields.
- Submit Application now requires all three confirmation checkboxes before `提交申请` is enabled.
- Review processing includes candidate file creation and review completion before moving to preliminary eligibility review.
- Preliminary Eligibility Review is formatted as a formal notice addressed to the current player name.

## Sprint 03 Final UI Bugfix / Polish

- Application shell now keeps `Header / StepTabs / ContentArea / FooterButtons` in a safer vertical layout.
- The middle content area scrolls when needed, while footer buttons remain visible inside the screen.
- Layout margins were adjusted for clean use at 1600x900 and better usability at 1280x720.
- Submit confirmation checkboxes now use brighter unchecked outlines and restrained blue checked highlights.
- Submit behavior is unchanged: `提交申请` stays disabled until all three confirmation statements are checked.

## Sprint 04 National Training

Sprint 04 adds the formal national training sequence after preliminary eligibility review.

Implemented:

- `TrainingStartScene` replaces the old placeholder as the normal training entry.
- Five scripted training modules: suit control, airlock procedure, power repair, life support and plant diagnosis.
- Final assessment as a small scripted incident sequence using the same training interactions.
- Mission assignment notice appears only after final assessment completion.
- Accepting the moon assignment sets training state, shows the quiet 17-pioneer black screen, then uses `OpeningFlowManager` to fade cleanly into `ArrivalCinematicScene`.
- There is no temporary launch/transfer placeholder in the normal player flow.
- Temporary decline keeps the candidate file and returns to the menu.
- Training progress is saved to `user://saves/training_progress.json` and `Continue Mission` routes to the current training state.
- F12 Dev Menu entries are available for Training Start, Final Assessment, Mission Assignment Notice, reset training progress and Arrival Cinematic.

Scope note:

- Oxygen, power, life support and plant status in Sprint 04 are scripted simulation values only.
- No full survival system, crop growth system, launch animation, mining, automation, tech tree or resident system is implemented in this sprint.

## TR-001 Training Room Visual Blockout

- Training Module 01 now uses a playable national training room blockout instead of a flat UI board.
- The room includes floor tiles, wall boundaries, overhead lights, wall equipment, a training console, a floor marker and an airlock-style exit door.
- The trainee is shown as a simplified astronaut figure rather than a plain square.
- The exit no longer uses green as its primary read; green remains reserved for life/plant semantics.
- The left panel remains the training control HUD, while the right side reads as the gameplay space.
- This pass is visual/readability only; no full oxygen, power, repair, crop, scoring or survival systems were added.

## Sprint 04 Module 01 Minor Polish

- Module 01 HUD hints now separate movement-only marker objectives from E-key terminal interactions.
- Only the current objective is strongly highlighted: marker first, terminal second, exit last.
- Training exit is visible but visually locked until the module reaches the exit step.
- Pressing E at the active exit advances directly to the next training module.
- Player start position was nudged farther inside the training room.
- Marker zone completion now checks the trainee's feet inside the visible marker rectangle instead of using a loose distance trigger.

## Sprint 04 Module 02: Airlock Procedure

- Module 02 now uses a training-room blockout with three readable zones: interior training room, airlock chamber and exterior simulation zone.
- Airlock objects are visually distinct: inner door, chamber, pressure console, pressure status display, outer door and exterior simulation zone.
- The staged flow is scripted: enter chamber, close inner door, start pressure simulation, wait for stable pressure, open outer door and enter exterior simulation zone.
- Wrong-order actions show calm procedural hints instead of failure or damage.
- HUD now reports airlock pressure status as `未启动 / 稳定中 / 稳定`.
- This remains a training simulation only; no real oxygen consumption, decompression damage or full EVA system was added.
- Module 02 polish: chamber walls are thicker, the chamber floor tone is clearer, door locks use `锁定`, and the pressure display now shows `舱压：未启动 / 稳定中 / 稳定`.

## Sprint 04 Module 03: Power Repair

- Module 03 now uses the TR-001 training-room visual standard instead of abstract colored blocks.
- The room includes semantic placeholder props for tool station, damaged power panel, power restart console, test light and training exit.
- The staged flow is scripted: get repair tool, inspect the damaged panel, repair the panel, restart power, observe the test light and exit to the next module.
- HUD power state updates through `故障 / 维修中 / 稳定`.
- Wrong-order actions show calm procedural hints; there is no failure screen or punishment.
- F12 Dev Menu includes `Dev Only: Training Module 03` for direct testing.
- Module 03 acceptance polish strengthens restored-power feedback, clarifies the damaged panel warning read and updates the exit hint copy.
- This remains a scripted training simulation only; no full electrical grid, tool inventory, durability or repair minigame was added.

## Sprint 04 Module 04: Life Support

- Module 04 now uses the TR-001 training-room visual standard instead of abstract colored blocks.
- The room includes semantic placeholder props for life support console, oxygen/water/power/temperature displays, life support core, ventilation unit and training exit.
- The staged flow is scripted: open console, read four simulated statuses, start stabilization, wait for stable life support, confirm the environment and exit to Module 05.
- HUD life-support state updates through `未稳定 / 稳定中 / 稳定`, with oxygen and temperature starting low.
- Wrong-order actions show calm procedural hints; there is no failure screen or punishment.
- F12 Dev Menu includes `Dev Only: Training Module 04` for direct testing.
- This remains a scripted training simulation only; no full oxygen, water, temperature or base-wide life support model was added.

## Sprint 04 Module 05: Plant Diagnosis

- Module 05 now uses the TR-001 training-room visual standard instead of abstract colored blocks.
- The room includes semantic placeholder props for training plant chamber, plant scanner, nutrient/light console, grow light, plant status display and training exit.
- The staged flow is scripted: observe plant, scan plant, choose diagnosis, adjust grow light, wait for plant status stability and exit to final assessment.
- HUD plant state updates through `异常 / 稳定中 / 稳定`.
- Wrong diagnosis gives calm feedback and asks the player to re-check scan information.
- F12 Dev Menu includes `Dev Only: Training Module 05` for direct testing.
- This remains a scripted diagnosis module only; no crop growth, watering, nutrients, harvest or greenhouse management system was added.

## Sprint 04 Final Assessment

- Final Assessment now uses a TR-001-style controlled simulation chamber instead of abstract colored blocks.
- The room combines readable zones for 供电区, 生命支持区, 植物舱区 and 考核终端区.
- The staged assessment is scripted: read the assessment terminal, get the repair tool, inspect and repair the power panel, restart power, stabilize life support, observe and scan the plant chamber, choose `光照不足`, adjust grow light, wait for plant stability and submit the result at the assessment terminal.
- HUD status combines power, life support, plant state, oxygen and power simulation values.
- Wrong-order actions show calm assessment hints, including life support before power, plant scan before life support stability, grow-light adjustment before diagnosis and submission before all systems are stable.
- Completion routes to `MissionAssignmentNoticeScene`; it does not launch the player to the Moon.
- This remains a scripted final assessment only; no scoring, fail state, death, random events, full oxygen system, full power system or crop simulation was added.

## Sprint 04 Transition Decision Update

- `MissionAssignmentNoticeScene` no longer hardcodes the post-acceptance scene jump; it routes through `OpeningFlowManager`.
- Current temporary flow is `MissionAssignmentNoticeScene -> AssignmentBlackScreenScene -> fade out -> ArrivalCinematicScene`.
- `OpeningFlowStage` is saved as `AssignmentBlackScreen` when the player accepts and `AwaitingArrivalCinematic` before loading the arrival cinematic.
- Future launch, Earth-Moon transfer and landing scenes are intentionally not represented by fake placeholder text or temporary rocket animation.
- The flow code contains a TODO for inserting `LaunchSequenceScene`, `EarthMoonTransferScene` and `LandingSequenceScene` once the art direction is ready.

## MAIN-001 Title Screen & Main Menu Patch

- Startup now opens to a clean `MainMenu` title screen instead of showing the survival sandbox HUD behind the menu.
- The title screen shows `广寒前哨 / GUANGHAN OUTPOST` and `让生命，在从未存在生命的地方生长。`.
- Normal player buttons are limited to `申请加入广寒计划`, `继续任务`, `档案`, `设置` and `退出`.
- `继续任务` is disabled when no training progress or sandbox save exists.
- `申请加入广寒计划` starts the Sprint 03 application flow.
- All development shortcuts are hidden behind `F12` in `开发菜单 / DEV MENU`.
- The title screen uses a scripted deep-space, Earth, lunar horizon and distant outpost-light background based on `docs/art/MAIN-001`.
- Gameplay HUD, resource bars, task log, controls, minimap-style panels and save-slot controls are hidden on the title screen.
