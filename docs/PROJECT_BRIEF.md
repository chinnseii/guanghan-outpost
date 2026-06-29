# Project Brief / 项目方向

Version: 0.1
Status: Draft for collaborators

## Core

《广寒前哨 Guanghan Outpost》不是普通的月球种田游戏。它的核心是：

> 让生命，在从未存在生命的地方生长。

所有代码、系统、UI、地图、交互和素材都应该服务这个核心。建筑只是容器，生命才是主角。

## Pitch

玩家作为中国“广寒计划”的常驻开拓者，在月球上修复旧基地、恢复生命支持、救活上一位开拓者留下的最后一株植物，并逐步把一座孤独的前哨变成人类在月球上的第一个家。

## Design Pillars

- Life First：生命高于建筑。资源、舱段、科技和机器人都应该最终服务生命。
- Hope Before Efficiency：希望高于效率。第一小时不要追求自动化和最优解。
- Relay Before Hero：接力高于英雄。玩家继承前人的失败、数据和希望。
- Home Before Base：家高于基地。旧基地应该有生活痕迹，而不只是机器集合。
- Silence Has Value：沉默也是体验。关键场景不要总用任务和弹窗催促玩家。

## Green Frontier

绿境不是基地范围，也不是探索范围。

绿境指生命能够持续存在、成长，并最终孕育下一代生命的区域。

- Engineering Reach：玩家可以抵达、建设、采集和维修的区域。
- Green Frontier：被密闭、供氧、供热、供水、供能和防辐射后，生命可以真正存在的区域。

玩家真正扩张的不是地图，而是绿境。

## First Hour

Vertical Slice 0.1 的目标情绪是：

1. 孤独
2. 希望
3. 接力

第一小时建议流程：

1. 广寒计划申请表
2. 国家培训
3. 最终考核
4. 录取通知书
5. 接受使命
6. 发射
7. 着陆月球
8. 第一次看到地球
9. 运输船离开
10. 进入旧基地
11. 发现前人生活痕迹
12. 恢复生命支持
13. 修复第一块太阳能板
14. 找到上一位开拓者留下的最后一株植物
15. 救活它
16. 第一天夜晚结束

第一小时暂不优先做居民、自动化、复杂科技树、复杂建造、采矿、战斗、大地图探索或建筑升级。

## First Plant Rule

第一株植物不是玩家种出来的，而是玩家救活的。

它来自上一位开拓者，是基地里最后一点还没有完全消失的生命。它应该是普通、虚弱、甚至有点枯黄的植物。它的重要性不来自神秘品种，而来自它坚持到了玩家抵达。

第一小时的核心任务不是“种植”，而是：

> 让生命不要在这里结束。

## Visual Direction

当前项目方向是 2D Modern Pixel Art / 现代叙事像素风。

- 月球：冷灰、黑、低饱和。
- 地球：高饱和蓝，全图最醒目的颜色。
- 基地灯光：暖黄，代表人类生活。
- 绿境：绿色，代表生命，早期必须稀有。
- UI：克制、工程化，不做赛博霓虹。

重要规则：

- 地球永远是蓝色的，代表玩家离开的家。
- 基地灯光永远是暖的，代表玩家正在创造的新家。
- 绿色必须稀有，第一小时里几乎只属于那一株植物。

## Current Priority

当前不要继续堆完整游戏内容，优先做 Foundation。

Sprint 01 Foundation 的目标是搭好以后所有系统都能复用的底层结构：

- Fixed Camera System
- TileMap Layer Framework
- Player Movement
- Interaction System
- Game State Machine
- Save System
- Day / Time System
- Lighting System
- UI Manager
- Data Driven Framework
- Scene Structure

Sprint 01 不要求好玩，要求以后不返工。

## Golden Rule

不要为了当前 Demo 写死代码。

代码命名和边界应该为植物、居民、生态、长夜、绿境、多舱段基地、申请者系统和文明成长预留空间。
