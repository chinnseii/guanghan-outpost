# Sprint 05A · 竖切打磨 / Vertical Slice Polish (Triage)

> 状态：Historical Archive（历史归档，不再承担当前真相）
> 来源：`README.md`（`### Sprint 05A 竖切打磨` 段）+ `ITERATION_PLAN.md`（`## Sprint 05A Vertical Slice Polish Triage` 段）。
> 当前真相：请参见 `docs/handoff/CURRENT.md`；系统详细行为见 `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`。
> 本文件在 Phase 2 文档治理（P2-03A）中提取以保全 Sprint 05A 历史；内容仅来自上述两份既有文档，无新增设计或推测。
> 说明：项目中不存在独立的"Sprint 05"（非 A）文档，README/ITERATION_PLAN 仅有 "Sprint 05A"，故不臆造 Sprint 05 报告。

## 背景
在申请 → 训练 → 抵达 → 旧基地竖切成形后，对这条竖切流程做一轮打磨与问题分诊（triage），统一状态流转、文书排版与抵达氛围。

## 已完成内容
- **申请候选人档案状态流转修正**：填写 `待提交` → 提交后 `审核中` → 资格初审后 `已通过资格初审` → 训练中 `训练序列中` → 最终考核后 `已通过最终考核` → 接受月面派遣后 `已接受月面派遣`。
- 兼容旧存档中的 `已通过初步评估`（转换为当前正确状态，不再出现在申请表填写页）。
- 审核处理页改为按顺序显示预期步骤，移除多余的任务档案查找步骤；最终审核步骤后加入短暂停顿，保证审核文案可读后再转场。
- 资格初审结果与任务派遣通知补充文书元数据：文书编号、候选人、档案状态、签发单位、日期；任务派遣通知日期与申请系统一致：`2068-04-12`。
- 最终考核房间重新分区：供电、生命支持、植物舱、考核终端在画面中更分离，减少标签拥挤。
- 抵达月球（ArrivalCinematic）降低 HUD 存在感、去掉正式流程里的调试感"注视连线"、缩小并提亮地球冷光、增强远处基地暖灯、让玩家在月面显得更小；地球观察文本先单独显示，结束后才显示 `E / Enter 前往基地气闸`。
- 训练模块门、锁定状态与标签字号做了轻量统一。
- 新增可复用验收截图工具：`tools/capture_acceptance.gd`（截图需非 headless 模式；`--headless` 下 Godot dummy viewport 无法保存画面）。

## 当时已知问题 / 明确 Out of Scope
- 不含：新剧情内容、第一株植物序列、作物/生存系统扩展、发射动画或地月转移段。

## 来源说明
本记录合并自 `README.md` 的 `Sprint 05A 竖切打磨` 段与 `ITERATION_PLAN.md` 的 `Sprint 05A Vertical Slice Polish Triage` 段，二者高度一致、互为补充；均为项目内既有历史文档，本文件未引入任何新事实。
