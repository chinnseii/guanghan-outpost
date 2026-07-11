# Sprint 03 · 序章与广寒计划申请 / Prologue & Application

> 状态：Historical Archive（历史归档，不再承担当前真相）
> 来源：`README.md`（Sprint 03 Prologue & Application / Revision 02 / APP-002A / Minor Patch Before Acceptance / Final UI Bugfix 段）+ `ITERATION_PLAN.md`（Sprint 03 对应段）。
> 当前真相：请参见 `docs/handoff/CURRENT.md`；系统详细行为见 `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md`。
> 本文件在 Phase 2 文档治理（P2-03A）中，从 README/ITERATION_PLAN 提取以保全 Sprint 03 历史；内容仅来自这两份已有文档，未新增设计或推测。

## 背景
正式 New Game 流程改为**先从"广寒计划申请"开始**，而不是直接把玩家送上月球。Sprint 03 交付这条申请/序章流程的第一个可玩版本，衔接到 Sprint 04 国家训练。

## 当时目标
- 在抵达月球之前，加入申请表 → 资格初审 → 进入训练的前置叙事流程。
- 只做流程与 UI 骨架，不引入发射、库存、科技等系统。

## 已完成内容

**场景与脚本**
- `res://scenes/application/ApplicationStartScene.tscn`、`res://scenes/application/TrainingPlaceholderScene.tscn`
- `scripts/application/application_flow_scene.gd`、`scripts/application/training_placeholder_scene.gd`、`scripts/data/player_profile_data.gd`

**主菜单**
- 新增 `Apply to Project Guanghan`（申请）与 `Continue Mission`（继续，重开已存申请流程）。
- 旧沙盒 / 抵达原型入口保留但标为 `Dev Only`。

**申请 UI（National Deep Space Life Science Center / Project Guanghan）**
- 基本身份页：姓名、出生年份、性别显示。
- 教育背景页：六个**不带数值加成**的选项（education background 仅作 context 保存，无 RPG 属性/加成）。
- 外观标识页：身体/肤色/发型/宇航服标识占位预设。
- 提交/审核流程（简短正式的处理文案）→ 资格初审结果页（含玩家姓名）。
- 玩家档案存档：`user://saves/application_profile.json`（含 submitted/accepted 状态、当前步骤、申请后下一场景）。

**APP-002A 申请 UI 更新**
- 性别只保留 `男` / `女`；不索取国籍、证件号、紧急联系人等现实敏感字段。
- 基本信息页新增系统生成字段：Application ID、候选人档案状态、任务身份。
- 角色/宇航服预览从基本信息页移到 `03 外观与标识`，改名 `开拓者预览 / PIONEER PREVIEW`，聚焦宇航服、徽章、suit ID、姓名缩写、标识色。
- 明确 `外观仅用于角色显示与任务档案，不影响能力。`；性别仅影响视觉体型预设。

**Revision 02 申请结果流程**
- Sprint 03 结束在**资格初审**（`资格初审结果 / PRELIMINARY ELIGIBILITY REVIEW`），不再到"接受使命"。
- 移除 `接受使命` / `放弃申请` 与即时的接受使命黑屏（延后到后续 sprint）。
- 结果页说明：正式月面派遣只能在国家训练与最终考核之后；按钮 `进入训练序列` / `返回主菜单`；`进入训练序列` → `TrainingStartScene`。

**Minor Patch / Final UI Bugfix**
- 训练占位页文案改为"国家训练序列正在初始化、需确认候选人档案同步"；dev 按钮改名 `开发入口：进入月球抵达原型`。
- 外观与标识把 suit ID / patch ID / 姓名缩写拆成独立字段。
- 提交申请需勾选三个确认复选框后 `提交申请` 才可用；审核流程以 `正在建立候选人档案` / `审核完成` 收尾；资格初审改为写给玩家姓名的正式通知。
- 申请壳层布局稳定为 `Header / StepTabs / ContentArea / FooterButtons`，中部内容可滚动、页脚按钮常驻可见；边距适配 1600×900 与 1280×720；复选框视觉打磨。

## 当时已知问题 / 明确 Out of Scope
- 接受使命、放弃月面派遣、17 位开拓者黑屏 —— 延后到训练/最终考核之后。
- 申请流程不含：发射、库存、采矿、机器人、科技树、RPG 数值、教育背景加成。

## 来源说明
本记录合并自 `README.md` 的 Sprint 03 系列段落（UI/流程细节）与 `ITERATION_PLAN.md` 的 Sprint 03 段落（文件/存档字段细节）。二者互补，均为项目内既有历史文档，本文件未引入任何新事实。历史遗留的失效引用 `SPRINT_04_NATIONAL_TRAINING.md → SPRINT_03_PROLOGUE_APPLICATION.md` 的最终指向由 Phase 2 P2-08（引用修复）统一处理。
