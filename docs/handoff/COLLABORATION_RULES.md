# 协作规则 / Codex + Claude Code + GPT

本文档几乎不变（规则本身），会跟着实际磨合调整。每次开工前先看这份，再看
`docs/handoff/CURRENT.md`（那份是当前状态，会被频繁覆盖重写）。

## 角色

- **Codex**：主责游戏逻辑、交互、Manager、数据、流程。
- **Claude Code**：主责场景搭建、UI、节点结构、资源组织、动画、灯光、美术资产管线。
- **GPT**：产品经理 / 设计评审。不读代码，只读文档和游戏截图。负责：
  - 把玩家（人类）反馈的 bug 口述整理成结构化工单。
  - 审核 Codex / Claude 提交的验收报告（文字 + 截图），判断是否符合
    `docs/PROJECT_BRIEF.md` 的方向和调性。
  - **不判断一个 bug/任务该归 Codex 还是 Claude** —— GPT 没有代码可读，判断不准，
    这个决定交给人类，看当时找谁干活方便就找谁。

## 分工不是按目录，是按任务/模块

这个项目里逻辑代码和视觉代码经常写在同一个 `.gd` 文件里（例如
`scripts/training/training_module_scene.gd` 一半是步骤判定逻辑，一半是设备的
`_draw()` 绘制代码）。所以：

- 不按"谁能碰哪个目录"分工，按"谁在负责这个任务"分工。
- 谁接了一个任务，就对这个任务涉及的**所有**文件负责到底，哪怕碰到通常
  属于对方的文件也没关系——碰完在 `CURRENT.md` 里记一笔即可，不要为了守着
  目录边界而把一个任务拆成两半分头做。

## 共用核心文件——谁都可能碰，但要小心

这份清单是按实际引用数（`grep` 每个文件被多少个不同场景/脚本用到）核实过的，
不是凭印象写的，2026-07-06 更新。

**第一档：真正跨 sprint 共用，改之前必须按下面的规则来**

- `scripts/props/reference_prop.gd` —— 目前被 48 处场景/脚本引用，覆盖旧基地、
  温室、太阳能阵列、训练模块四条线，是整个项目里复用面最广的文件。
- `scripts/base/sprint06_base_scene.gd` —— 被 10 个场景共用（旧基地、旧温室、
  Day01/Day02、Week Routine 开始/结束、太阳能阵列外景、美术切片版本），
  Sprint 06/07/08 的日常流程基本都跑在这一个脚本上。
- `scripts/training/training_module_scene.gd` —— 驱动全部 6 个训练模块
  （suit_control / airlock_procedure / power_repair / life_support /
  plant_diagnosis / final_assessment），Sprint 04 的核心。
- `scripts/training/training_manager.gd` —— 训练进度存档/读取，被 5 个训练相关
  脚本 + `main.gd`（继续任务判断）共用。
- `scripts/training/opening_flow_manager.gd` —— 接受派遣后黑屏转场逻辑，被
  `assignment_black_screen_scene.gd` 和 `mission_assignment_notice_scene.gd`
  两处共用，范围小但容易漏改一处。

**第二档：过去以为是"共用基础设施"，实际已经是遗留代码，不影响当前主线**

`game_state_manager.gd`、`time_manager.gd`、`camera_manager.gd`、
`ui_manager.gd`、`event_manager.gd`、`audio_manager.gd`、`save_manager.gd`、
`asset_catalog.gd`、`audio_feedback.gd`、`robot_task_manager.gd` 这一批
（README 里叫"Foundation Manager"）——查证后发现只有 `scripts/main.gd`
（Sprint 01 沙盒）和 `scripts/arrival/*`（Sprint 02 抵达原型）在用，
`application/`、`training/`、`base/`（也就是现在主菜单实际能走到的正式流程）
完全不依赖它们。除非哪天要复活沙盒玩法，否则改这批文件不影响当前主线开发，
不需要按第一档的规则谨慎对待，但也别顺手删掉——`main.gd` 还在用。

规则（针对第一档文件）：

1. **改之前**：先跑 `git log --oneline -- <文件路径>`（几秒钟出结果），看最近
   有没有人改过；如果有，针对那一两个 commit 用 `git show <commit> -- <文件>`
   看一眼改了什么——不用去读对方完整的任务记录/PR 描述，这一步就够了。
2. **默认只增不改**：优先用新增可选参数、新增 `if/match` 分支的方式扩展，
   老的调用路径/老的默认行为原样保留。例如加新状态时用
   `if status_text.is_empty(): <原有逻辑不动> else: <新逻辑>`，而不是直接
   重写整个函数。
3. 改完这类文件，在 commit message 或 `CURRENT.md` 里明确写出"改了共用文件 X，
   原因是 Y"，方便对方下次一眼看到。

## `docs/handoff/CURRENT.md` 怎么用

- 这是滚动状态文档，**每次覆盖重写，不是往后追加**——保持简短，只写"现在
  是什么状态"，不是历史记录（历史记录已经有 `docs/archive/sprints/*.md` 在存了）。
- 开工前读一遍，收工前更新一遍。
- 内容包括：正在进行的任务/负责人/涉及文件、最近对共用文件的改动、已知坑、
  "先别碰"清单。

## 人类玩测 → GPT 出工单 → 分给 Codex 或 Claude 的流程

1. 人类玩游戏发现问题，口述给 GPT（现象、复现步骤最好带上）。
2. GPT 整理成结构化工单：现象 / 复现步骤 / 预期表现 / 实际表现。**不指派归属**。
3. 人类把工单丢给当前在用的 Codex 或 Claude，谁接了谁按上面"共用文件"规则
   处理，即使要跨到对方常改的文件也直接改，改完记一笔。

## 提交给 GPT 审核的报告格式

沿用项目已有的 sprint 文档习惯（`docs/archive/sprints/*.md` 的"已完成 / 仍不包含"
写法），不用新发明格式：

- 这次做了什么（人话描述，不是代码 diff）
- 前后对比截图——最好是跑固定脚本生成的（例如
  `tools/capture_*_prop_bridge_check.gd` 这类一次性验证脚本），保证可以
  重新生成复核，而不是手动摆拍
- 明确写"还没覆盖 / 已知问题"清单

GPT 的审核只覆盖产品/体验层面（符不符合方向、看着顺不顺），不能替代
Codex 和 Claude 之间对彼此代码的交叉核实——截图有可能"看着对但底层是错的"
（状态绑定错了但画面恰好没露馅），这种问题只有回去读代码才能发现。
