# Guanghan Outpost / 广寒前哨

一个用于逐步迭代的 Godot 4 月球基地农业生存原型。

## 当前版本：V0.31 月面作业体验

当前主线版本开始打磨“出舱前要想清楚去哪”的玩法体验：出舱任务面板升级为 V2，会按建议顺序显示回收补给、采集水冰、清理太阳能板、维修外部设备和回储物柜入库；每个任务会显示距离、风险和需要的工具；目标追踪支持在多个任务点之间切换。V0.31A 素材规范和脚本拆分准备作为并行副线保留记录。

## 当前方向更新

项目方向已收束为“让生命，在从未存在生命的地方生长”。接下来优先按照 `docs/PROJECT_BRIEF.md` 和 `docs/art/TS-001/README.md` 推进：先完成可复用 Foundation，再做第一小时体验。不要继续优先堆复杂科技树、机器人自动化和大规模资源循环。

当前重点是降低“画面太抽象”的感觉：玩家不再只是一个点，已经替换为第一版像素宇航员 sprite，带 4 方向和 2 帧步行动画；月面、舱内地板、模块边界、门、补给舱和采集点都做了对比度与尺寸重整；模块增加类型色条，资源点增加更醒目的底座/信标，让玩家更容易看懂自己是谁、站在哪里、附近有什么。

已包含：

- 星露谷式俯视移动
- 第一版像素宇航员角色 sprite：4 方向、2 帧步行动画、低氧/舱外状态提示
- 项目方向文档：`docs/PROJECT_BRIEF.md`
- 第一张目标截图说明：`docs/art/TS-001/README.md`
- Sprint 01 Foundation 清单：`docs/SPRINT_01_FOUNDATION.md`
- 默认窗口：1600×900
- 地图格子和舱内模块尺寸已放大，提高可读性
- 右侧信息栏与地图区域分离，减少遮挡
- 地图相机缩放：`Z` 放大，`X` 缩小
- UI 缩放：`[` 缩小，`]` 放大
- 右侧提供地图/UI 缩放按钮
- 缩放设置会进入存档
- 广寒前哨基础地图
- 电力、氧气、水、食物、维修件、设备完整度
- 舱压、宇航服氧气、二氧化碳、温室湿度
- 每日资源结算
- 土豆、藻类、菌菇三种作物
- 温室种植与作物成长
- 月尘导致太阳能效率下降
- 制氧与水回收设备磨损
- 地球补给提前申请系统
- 每 7 天开放一次补给申请窗口
- 申请后的补给约 3 天后抵达，可能小概率延迟
- 补给抵达后会出现偏差落点，需要根据信标出舱回收
- 第 14 天开始的月夜压力
- 可建造模块：太阳能阵列、电池舱、小型温室、生命维持舱、维修工作台、气闸舱、月壤提氧机、冰矿处理器
- 气闸舱可补满宇航服氧气
- 舱外行动会持续消耗宇航服氧气
- 舱外行动会积累宇航服月尘污染，并缓慢损耗宇航服耐久
- 出舱前会检查宇航服氧气和耐久，低于阈值会阻止离舱
- 返舱后可通过气闸复压、补氧、除尘和耐久检查
- 站在未漏气的加压舱段内会恢复宇航服氧气
- 舱压会受漏气和生命维持能力影响
- 前哨员每日消耗食物、水和氧气，并产生二氧化碳
- 温室湿度会影响作物生长
- 月壤提氧机可消耗月壤和电力生产氧气
- 冰矿处理器可消耗水冰和电力生产水
- 新建模块必须贴近已有基地模块
- 模块数量会影响每日资源结算
- 微陨石可能导致居住舱、温室、电池舱、生命维持舱或维修工作台漏气
- 漏气舱段会显示红色警戒框，并每天额外消耗氧气、降低完整度
- 切换到维修枪，靠近漏气舱段按 `E` 可消耗维修件封堵
- 保存/读取系统
- 主菜单和 3 个存档槽
- 存档路径：`user://saves/slot_1.json` 至 `user://saves/slot_3.json`
- Foundation Manager 第一轮：GameState、Time、Camera、UI、Event、Audio 已有集中入口
- Resource 数据底座：ItemData、LifeEntityData、StructureData、InteractableData、DialogueData、SceneEventData
- 可保存日期、资源、玩家位置、模块、作物、漏气、采集点、补给订单、任务、前哨员状态和日志
- 玩家、模块和采集点已拆成独立 Godot 场景，主脚本同步数据层与显示层
- 舱内设施第一版：
  - 居住舱：床铺、储物柜、控制台
  - 生命维持舱：气体/水循环罐、控制台、管线
  - 维修工作台：工作台、储物柜、机器人充电桩
  - 气闸舱：舱门框、除尘光带、宇航服架
- 舱内设施玩法：
  - 床铺：恢复疲劳、健康和精神，消耗少量食物与水
  - 控制台：查看基地状态、补给信标、背包和机器人任务
  - 储物柜：将出舱背包里的月面资源入库
  - 机器人充电桩：切换机器人任务
- 出舱采集资源会先进入背包，回到储物柜后才进入基地库存
- 补给舱货物会保留剩余清单，玩家需要按背包容量分批搬运
- 大件补给不能一键拿完，背包满时必须回储物柜入库
- 机器人任务：待机、玉兔采样、维护巡检、搬运补给
- 机器人充电桩支持任务队列，每天执行队列中的一个任务
- 搬运机器人可从落地补给舱自动转运一批货物
- 舱外风险事件：
  - 低氧倒计时提醒
  - 太阳风暴预警，提高出舱消耗和月尘压力
  - 微陨石短时警报，提高外部耐久风险
  - 月尘污染会提高气闸返舱维护成本
- 模块素材升级为更清晰的像素风块面
- 控制台和机器人充电桩有简单闪烁动画
- 关键交互加入程序生成的占位提示音
- 机器人已经拆成独立场景 `scenes/robot.tscn`，会显示在基地地图中
- 机器人执行采样、巡检、搬运任务时会向最近目标点移动
- 机器人位置、目标点和移动状态会进入存档
- 今日目标升级为“今日任务卡”：行动、原因、完成条件分开显示
- 第一次进入游戏时，地图箭头会依次指向控制台、气闸、月面采集点、储物柜、温室和补给区
- 新增任务日志面板，显示新手流程每一步的完成状态
- 当前任务会在任务日志中高亮，已完成任务会标记为 `[x]`
- 氧气不足、背包满、工具错误、建造失败等情况会显示行动化提示
- 地图引导箭头增加目标圈和远距离引导线
- 当前引导目标离开视野时，屏幕边缘会显示方向和距离提示
- 任务日志支持“简略/展开”切换
- 任务日志会记录新手步骤完成、阶段目标完成和每日长期目标历史
- 第一次进入新局会显示 UI 遮罩，并高亮左上角今日任务卡
- 首次引导遮罩、任务日志展开状态和历史记录会进入保存/读取系统
- 机器人队列改为实时执行：入队后会启动任务、移动到目标点、到达后结算
- 机器人移动时会显示可见路径线和目标点脉冲
- 机器人采样、巡检、搬运完成时会给出日志和音效反馈
- 机器人任务命名/可运行判断拆到 `scripts/robot_task_manager.gd`
- 机器人拥有独立电量，执行任务和返回充电桩会消耗电量
- 电量低时机器人会暂停当前任务，把任务放回队首，并返回充电点
- 机器人充电期间暂停任务队列，充满后继续执行
- 机器人电量、充电状态会进入保存/读取系统
- 机器人任务面板显示当前任务、队列、电量、目标地点和状态
- 机器人任务面板支持取消任务
- 机器人任务面板支持“搬运优先 / 巡检优先 / 采样优先”
- 机器人任务面板显示机器人类型和最近一次失败/跳过原因
- 没有落地补给舱时，搬运补给任务会自动跳过并写入日志
- 补给舱货物已经搬空时，搬运补给任务会自动跳过并说明原因
- 玉兔采样目标耗尽时，会重新选择最近的月壤、水冰或科研样本点
- 玉兔采样、维护巡检、搬运补给已经拆成三条命名能力线
- 机器人失败提示会进入保存/读取系统
- 三类机器人拥有不同外观：
  - 玉兔采样车
  - 维护机器人
  - 搬运机器人
- 机器人会显示任务状态灯和电量条
- 维护机器人只有在月尘、漏气或完整度损耗需要处理时才会出动，否则自动跳过并说明原因
- 机器人任务完成会显示短暂屏幕反馈和地图标记
- 新增“目标栈”面板：合并当前目标、出舱任务和长期目标
- 可按 `T` 或点击追踪按钮切换关键目标自动居中/追踪
- 可按 `Y` 或点击切换目标按钮，在多个可追踪任务点之间轮换
- 新手任务、阶段任务和机器人任务完成会有短暂屏幕反馈
- 提示音逻辑已拆到 `scripts/audio_feedback.gd`，后续可替换正式音效
- 音效入口扩展为命名事件：环境氛围、气闸、工具、搬运、机器人、脚步
- 存档路径和存档槽摘要已开始拆到 `scripts/save_manager.gd`
- 第一批独立 PNG sprite 资源：
  - `assets/sprites/facilities/bed.png`
  - `assets/sprites/facilities/storage.png`
  - `assets/sprites/facilities/console.png`
  - `assets/sprites/facilities/robot_charger.png`
- 第二批独立 PNG sprite 资源：
  - `assets/sprites/facilities/airlock_door.png`
  - `assets/sprites/facilities/life_support_tank.png`
  - `assets/sprites/facilities/greenhouse_bed.png`
  - `assets/sprites/facilities/solar_panel.png`
- 舱内床铺、储物柜、控制台、机器人充电桩已改为优先使用 PNG sprite 绘制
- 气闸门、生命维持罐、温室种植床、太阳能板已改为优先使用 PNG sprite 绘制
- sprite 加载失败时保留程序绘制回退，降低资源导入风险
- PNG 加载支持未导入素材直接读取，避免新增资源时刷导入错误
- 事件音保留命名入口；常驻环境底噪暂时关闭，后续替换为正式音频文件后再恢复
- 气闸、工具、搬运、机器人事件使用更有辨识度的短音型
- 玩家移动时会按步频播放轻脚步声
- 第三批独立 PNG sprite 资源：
  - `assets/sprites/robots/yutu_sample.png`
  - `assets/sprites/robots/maintenance_bot.png`
  - `assets/sprites/robots/hauler_bot.png`
  - `assets/sprites/collectables/regolith_node.png`
  - `assets/sprites/collectables/ice_node.png`
  - `assets/sprites/collectables/meteor_node.png`
  - `assets/sprites/collectables/sample_node.png`
  - `assets/sprites/collectables/supply_pod.png`
- 月面采集点和补给舱改为优先使用独立 sprite，并显示类型状态点
- 新增 `docs/SPRITE_GUIDE.md`，记录设施、机器人、采集点的 sprite 尺寸和颜色规范
- 第四批独立 PNG sprite 资源：
  - `assets/sprites/player/astronaut_walk.png`
- 玩家显示从抽象圆点升级为像素宇航员，并根据移动方向播放简单双帧步行动画
- 月面 tile 色调调暗并增加冷灰层次，舱内地板提高亮度和结构线，舱内/舱外更容易区分
- 模块视觉增加外壳阴影、粗边框、门标识和类型色条，居住舱、气闸、温室、生命维持、工作台、太阳能和补给区更容易辨认
- 月面资源点和补给舱视觉尺寸放大，并增加底座、信标和状态徽标，提高远距离识别度
- 控制台、储物柜/背包、补给舱货物各有独立信息页面
- 按 `Esc` 可关闭独立信息页面
- 舱内床铺、储物柜、控制台和机器人充电桩加入交互高亮
- 舱内家具加入第一版碰撞，占用空间更明确
- 月面地表使用 Godot `TileMapLayer`
- 舱内地板使用独立 `TileMapLayer`
- 模块外壳、工业设备、补给区、太阳能阵列加入基础碰撞
- 普通加压舱段只能通过相邻舱段的连通门通行
- 气闸舱提供舱内/舱外出入口
- 模块门标识会根据真实连通关系显示
- 运行时生成月面 `TileSet` 和 4 种月壤地表 tile
- 地图仍保持 22x13 基地网格，后续可继续接正式像素素材和碰撞层
- 中国探月科技线：
  - 嫦娥样本数据库：提高采样收益，作物收获额外 +15%
  - 鹊桥中继：补给运输缩短 1 天，并降低发射延迟概率
  - 玉兔机器人：每天自动巡视，少量采集月壤，并缓慢清理太阳能板月尘
  - 闭环生态控制：改善生命维持稳定性
  - 精确着陆雷达：降低补给舱落点偏差
  - 机器人协作协议：降低前哨员压力，预留机器人劳动力线
- 科技解锁状态会进入存档
- 阶段任务目标：第一周、第一座温室、原位制氧、出舱取货、前哨员稳定
- 出舱任务面板 V2：回收补给舱、采集水冰、清理太阳能板、维修外部设备和回储物柜入库会显示建议顺序、距离、风险和工具
- 单人前哨员系统：健康、精神状态、疲劳
- 劳动力扩展方向改为机器人，而不是新增其他常驻人员
- 新手引导/当前目标：
  - 先看控制台
  - 去气闸补氧
  - 出舱采集资源
  - 回储物柜入库
  - 去温室种植
  - 去补给区申请补给
  - 进入下一天
- 引导进度会进入存档
- 补给抵达后会生成偏差落点补给舱，需要检查宇航服氧气后出舱回收
- 玩家有面向方向和简单步行动画
- 工具系统：采样铲、除尘刷、维修枪
- 月面采集点：月壤、水冰样本、陨石金属、特殊月壤样本
- 月壤、水冰、科研样本会进入资源栏，给后续科技线预留空间

## 运行方式

1. 安装 Godot 4.x。
2. 打开 Godot Project Manager。
3. 导入本文件夹里的 `project.godot`。
4. 点击运行。

也可以双击：

```text
launch_godot.bat
```

## 操作

- `WASD` / 方向键：移动
- `E`：与附近设施交互；建造模式下用于放置模块
- `N`：进入下一天
- `Z` / `X`：放大/缩小地图
- `[` / `]`：缩小/放大 UI
- `T`：切换关键目标自动居中/追踪
- `Y`：切换下一个追踪目标
- `B`：打开/关闭建造模式
- `F5`：保存
- `F9`：读取
- `F10`：新开局
- `Esc`：取消建造
- 左上角当前目标：照着做可以完成第一天基础循环
- 底部作物按钮：选择温室作物
- 底部工具按钮：选择采样铲、除尘刷或维修枪
- 底部建造按钮：选择要建造的基地模块
- 右侧按钮：选择存档槽、保存、读取、新开局
- 底部科技按钮：研究嫦娥样本数据库、鹊桥中继、玉兔机器人、闭环生态控制、精确着陆雷达、机器人协作协议
- 靠近补给降落区按 `E`：申请下一批补给，或查看已着陆补给舱信标
- 靠近偏差落点补给舱按 `E`：出舱回收补给
- 靠近气闸舱按 `E`：气闸循环，补满宇航服氧气
- 靠近床铺按 `E`：休整，恢复疲劳
- 靠近控制台按 `E`：查看基地状态
- 靠近储物柜按 `E`：将背包资源入库
- 靠近机器人充电桩按 `E`：把机器人任务加入队列
- 出舱前确保宇航服氧气不少于 35%，耐久不少于 25%
- 靠近月壤提氧机按 `E`：消耗月壤和电力提取氧气
- 靠近冰矿处理器按 `E`：消耗水冰和电力处理成水

## 当前玩法目标

撑过 30 天。玩家需要在短期生存和长期建设之间取舍：

- 食物、水、氧气要够
- 舱压和宇航服氧气不能见底
- 二氧化碳不能积累过高
- 温室湿度要保持在适合作物生长的区间
- 太阳能板要清洁
- 生命维持设备要维修
- 在补给通信窗口提前申请合适货单
- 补给在途期间要靠现有库存撑住
- 补给抵达后根据信标出舱回收偏差落点补给舱
- 第 14 天后进入月夜，太阳能归零，电力压力上升
- 用维修件和电力扩建基地，让温室、能源和生命维持能力逐步提升
- 留意红框漏气舱段，及时用维修枪封堵
- 出舱采集月壤、水冰和陨石金属，为后续月壤提氧、科技线和制造系统积累资源
- 用月壤、科研样本和维修件解锁中国探月科技，改善农业、补给和自动化
- 照顾前哨员健康、精神状态和疲劳，逐步用机器人分担劳动
- 完成阶段任务，逐步把前哨从“活下来”推向“稳定运营”

## V0.31 月面作业体验

- 出舱任务面板升级为 V2，会按建议顺序显示任务。
- 回收补给舱、采集水冰、清理太阳能板、维修外部设备、回储物柜入库都会进入可追踪目标列表。
- 每个出舱任务会显示距离、风险和建议工具。
- 风险会参考距离、宇航服氧气、宇航服耐久、月尘、太阳风暴和微陨石预警。
- `T` 控制目标追踪开关，`Y` 或“切换目标”按钮可以在多个任务点之间轮换。
- 目标追踪索引会进入保存/读取系统。

## V0.31A 素材规范和脚本拆分准备

这次不是核心玩法版本，重点是把现有像素素材整理成更容易维护的工程结构。

- 更新 `docs/SPRITE_GUIDE.md`，补充玩家、机器人、设施、采集点和 UI 图标的尺寸规范。
- 新增 `scripts/asset_catalog.gd`，集中管理玩家、机器人、设施、采集点 sprite 路径和常用状态色。
- `player_visual.gd`、`robot_visual.gd`、`module_visual.gd`、`collectable_visual.gd` 改为从素材目录表读取路径。
- 保留现有 PNG 加载回退逻辑：优先使用 Godot 导入资源，失败时直接读取 PNG，仍然有程序绘制兜底。
- 没有改动核心玩法、资源结算、机器人任务或存档结构。

## Sprint 01 Foundation 第一轮

- 新增 `docs/SPRINT_01_FOUNDATION.md`，把 Sprint 01 issue list 转成项目内 checklist。
- 新增 `GameStateManager`、`TimeManager`、`CameraManager`、`UIManager`、`EventManager`、`AudioManager`。
- 新增通用交互接口占位 `Interactable` 和 `InteractionDetector`。
- 新增 Resource 数据类型：`ItemData`、`LifeEntityData`、`StructureData`、`InteractableData`、`DialogueData`、`SceneEventData`。
- 新增测试数据：`data/foundation/test_life_entity.tres` 和 `data/foundation/test_structure.tres`。
- 现有主场景已轻量接入 GameState、Time、Camera、UI、Event 和 Audio 管理器。
- 存档开始保存 Foundation managers 的状态。

## 下一步建议

1. Sprint 01 Foundation：
   - 建立 `FoundationTestMap` 测试场景。
   - 将玩家移动拆为 `PlayerController.gd`，支持启用/禁用输入。
   - 将现有 E 键交互逐步迁到 `Interactable` / `InteractionDetector`。
2. TS-001 可运行灰盒：
   - 用现有 TileMap 和像素素材搭出“运输船离开、远处旧基地、地球可见”的测试场景。
   - 保持 HUD 极简，只显示宇航服状态、时间和环境信息。
   - 不写死剧情，先验证镜头、光照、UI 层级和氛围。
3. 第一小时体验设计：
   - 设计“进入旧基地、发现生活痕迹、恢复生命支持、救活最后一株植物”的状态流。
   - 明确第一株植物不是种出来的，而是救活的。
   - 暂缓复杂科技树、机器人自动化和大规模资源循环。
4. 素材目录继续收口：
   - 补充 UI 图标目录，例如氧气、电量、时间、辐射、补给。
   - 后续新增素材先登记到 `scripts/asset_catalog.gd`。
   - 将 TS-001 的颜色脚本同步到 `docs/SPRITE_GUIDE.md`。

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

Out of scope remains training gameplay, final assessment, launch, inventory, mining, robots, tech tree, RPG stats and education-background buffs.

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
- Accepting the moon assignment sets training state, shows the quiet 17-pioneer black screen, then transitions to `ArrivalCinematicScene`.
- Temporary decline keeps the candidate file and returns to the menu.
- Training progress is saved to `user://saves/training_progress.json` and `Continue Mission` routes to the current training state.
- Dev Only menu entries are available for Training Start, Final Assessment, Mission Assignment Notice, reset training progress and Arrival Cinematic.

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
- Main menu now includes `Dev Only: Training Module 03 Power Repair` for direct testing.
- Module 03 acceptance polish strengthens restored-power feedback, clarifies the damaged panel warning read and updates the exit hint copy.
- This remains a scripted training simulation only; no full electrical grid, tool inventory, durability or repair minigame was added.

## Sprint 04 Module 04: Life Support

- Module 04 now uses the TR-001 training-room visual standard instead of abstract colored blocks.
- The room includes semantic placeholder props for life support console, oxygen/water/power/temperature displays, life support core, ventilation unit and training exit.
- The staged flow is scripted: open console, read four simulated statuses, start stabilization, wait for stable life support, confirm the environment and exit to Module 05.
- HUD life-support state updates through `未稳定 / 稳定中 / 稳定`, with oxygen and temperature starting low.
- Wrong-order actions show calm procedural hints; there is no failure screen or punishment.
- Main menu now includes `Dev Only: Training Module 04 Life Support` for direct testing.
- This remains a scripted training simulation only; no full oxygen, water, temperature or base-wide life support model was added.

## Sprint 04 Module 05: Plant Diagnosis

- Module 05 now uses the TR-001 training-room visual standard instead of abstract colored blocks.
- The room includes semantic placeholder props for training plant chamber, plant scanner, nutrient/light console, grow light, plant status display and training exit.
- The staged flow is scripted: observe plant, scan plant, choose diagnosis, adjust grow light, wait for plant status stability and exit to final assessment.
- HUD plant state updates through `异常 / 稳定中 / 稳定`.
- Wrong diagnosis gives calm feedback and asks the player to re-check scan information.
- Main menu now includes `Dev Only: Training Module 05 Plant Diagnosis` for direct testing.
- This remains a scripted diagnosis module only; no crop growth, watering, nutrients, harvest or greenhouse management system was added.
