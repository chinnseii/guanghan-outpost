# Sprint 06: Old Base & Last Plant

旧基地与最后一株植物

《广寒前哨 Guanghan Outpost》

Version: 0.1  
Status: Ready for Codex  
Owner: Codex / Technical Director  
Recommended Branch: `feature/sprint-06-old-base-last-plant`

## Sprint Goal

Sprint 06 的目标是实现玩家抵达月球后进入旧基地的第一段核心体验。

当前正式流程：

```text
ArrivalCinematicScene
→ BaseAirlockEntryScene
→ OldBaseInteriorScene
→ RestoreBasicPower
→ RestoreMinimalLifeSupport
→ OldGreenhouseScene
→ LastPlantDiscovery
→ LastPlantDiagnosis
→ RestoreGrowLightAndWater
→ LastPlantStable
→ Day01EndScene
```

本 Sprint 的核心不是扩展基地玩法，而是让玩家第一次感受到：

```text
广寒前哨不是一座空基地。
它曾经有人生活过。
现在，只剩下一株植物还在等人回来。
```

## Scope

Included:

- 旧基地入口
- 气闸进入流程
- AI 初次基地内对话
- 旧基地核心房间灰盒
- 基础供电恢复
- 基础生命支持恢复
- 旧温室入口
- 最后一株植物
- 植物诊断
- 补光恢复
- 水循环恢复
- 植物稳定状态
- Day 01 End

Out of scope:

- 完整基地建造
- 完整种植系统
- 作物成长周期
- 收获系统
- 库存经济
- 居民系统
- 科技树
- 采矿
- 自动化
- 机器人系统
- 完整长期生命支持模拟
- 完整电网系统
- 月昼 / 长夜完整循环
- 大型剧情分支
- 多个 NPC

所有供电、生命支持、植物状态都可以是 scripted simulation values。

## Definition Of Done

- [ ] 玩家可以从月面进入基地气闸
- [ ] 气闸进入流程可用
- [ ] AI 说“欢迎回来”
- [ ] 玩家可以探索旧基地第一房间
- [ ] 中央控制台显示基地状态
- [ ] 玩家可以恢复基础供电
- [ ] 基地灯光发生变化
- [ ] 玩家可以恢复最低生命支持
- [ ] 温室门在条件满足后解锁
- [ ] 玩家可以进入旧温室
- [ ] 最后一株植物可以被发现
- [ ] 玩家可以诊断最后一株植物
- [ ] 玩家可以恢复补光
- [ ] 玩家可以恢复最低水循环
- [ ] 最后一株植物状态从 Critical 变为 Stable
- [ ] 不显示经验值 / 奖励 / 成就
- [ ] 玩家可以结束 Day 01
- [ ] Sprint 06 状态可保存
- [ ] 没有完整种植系统
- [ ] 没有完整基地建造系统
- [ ] 没有居民系统
- [ ] 没有科技树

## Final Instruction

Sprint 06 是《广寒前哨》第一小时的情绪核心。

不要把它做成普通任务链：

```text
修电
修氧
修植物
睡觉
```

它真正要表达的是：

```text
前人没有完成的事，轮到你接住。
月球上第一件值得庆祝的事，不是基地启动，
而是一株植物还活着。
```

Keep it quiet.  
Keep it restrained.  
Make the player want to protect the plant.
