# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Claude Code（本轮临时顶替 Codex 的游戏逻辑/Manager/数据/流程职责——Codex
临时无 token，由 Claude Code 在独立会话中代打这部分；同一时间另一个 Claude Code
会话仍在并行做场景/UI/美术。Codex 恢复后请按下方记录核对，不要误以为是
Codex 自己之前做的）

## 正在进行

（暂无，"空气系统拆分与基地系统改造"重构已完成，本轮改动已提交）

## 最近完成

- **Claude Code（代 Codex）**：完成空气系统拆分与基地系统改造。
  - **BaseStatusManager 移除氧气职责**：删掉 `oxygen` 变量、`life_support_status`
    档位、`_apply_oxygen_change()`、`repair_life_support_light/heavy()`、
    `get_oxygen_label()`；`get_environment_energy_multiplier()` 改名为
    `get_temperature_energy_multiplier()`，只保留温度倍率，氧气倍率完全移出。
    现在只管电力/舱压/温度 + 供电/温控/密封三个设备档位。
  - **新增 `scripts/managers/AirSystemManager.gd`**，注册为
    `/root/AirSystemManager`（放在 `BaseStatusManager` 之后、
    `PlantGrowthManager` 之前）。管理：
    - `o2_percent`（抵达 20.4%）、`co2_percent`（抵达 0.42%）、
      `inert_gas_percent`（= `100 - o2 - co2`，每次结算后重算，不单独存档）、
      `inert_gas_reserve`（抵达 55.0，独立库存，第一版不能生产，只在密封
      泄漏/自动补压时消耗）。
    - 三个设备档位：`oxygen_generator_status`/`co2_filter_status`/
      `air_circulation_status`（初始 CRITICAL/CRITICAL/BASIC），用
      AirSystemManager 自己的局部 `SystemStatus` 枚举（跟 BaseStatusManager
      的枚举顺序一致但不共享脚本引用，避免跨文件 class_name 依赖）。
    - O₂/CO₂ 每小时结算：人类呼吸固定值 + 设备产出（乘电力倍率，CO₂ 还要乘
      空气循环倍率）+ 最后一株植物微弱加成（读
      `BaseStatusManager.last_plant_recovered_bonus_active`，不自己存一份）。
    - 惰性气体：密封档位决定储备每小时消耗速率；舱压<70 且储备>0 时自动消耗
      储备帮基地补压（换算率是本次自定的 v1 占位值，已在参考文档里标注）。
    - **无富氧惩罚**：O₂>22% 只有资源提示文案，不影响精力消耗倍率、不扣心理。
    - 制氧模块/CO₂过滤/空气循环三组维修方法（只改档位+一次性数值，不推进
      时间，跟 BaseStatusManager 维修方法同一套写法）。
    - 供氧目标档位 `supply_target_mode`（关闭/节能/标准/充足/应急）：预留
      字段，只存档 + 显示 + Debug 循环，暂不影响任何数值结算。
    - 四种教育背景的专业提示（医学/机械工程/材料科学/植物科学），不加数值。
    - 存档 `user://saves/air_system_state.json`，同时接入旧基地/温室/第一周
      存档与训练进度存档的 `AirSystemState` 字段。
  - **HealthManager** 的 `get_energy_cost_multiplier()` 改为
    `fullness_multiplier × BaseStatusManager.get_temperature_energy_multiplier()
    × AirSystemManager.get_air_energy_multiplier()`，任一 Manager 缺失时对应
    项退化为 1.0。
  - **UI**：新增 `scripts/ui/air_system_panel.gd`，在 `sprint06_base_scene.gd`
    里用新按键 `O` 开关（Tab=基地状态面板，G=植物面板仅温室场景生效，
    O=空气面板不限场景），默认隐藏，位置 `Vector2(740, 180)`，跟另外两个
    面板都在 1600x900 视口内不重叠。
  - **Debug 支持**：主菜单开发菜单新增 Air Debug 分组（O₂/CO₂/惰性气体储备
    加减、三个设备档位循环、供氧目标档位循环、重置 Day 01、设为最低稳定
    状态），并删除了原来 Base Debug 里的 Oxygen 加减按钮和 Life Support
    档位循环按钮（因为对应字段已经不在 BaseStatusManager 上）。
  - 设计参考文档 `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md` 已同步更新
    （按用户要求，新增/改动数值系统时必须同步这份文档）：BaseStatusManager
    章节改为只含电力/舱压/温度，新增独立的空气系统章节，健康系统章节的耦合
    公式和"尚未覆盖"清单也一并更新。

## 对共用核心文件的改动记录（第一档文件，已按规则先查 git log 再改）

- `scripts/managers/BaseStatusManager.gd`：移除 `oxygen`/`life_support_status`
  相关的全部代码（变量、结算函数、维修方法、标签、存档字段、专业提示里引用
  氧气的分支），保留电力/舱压/温度三项 + 三个设备档位的其余逻辑完全不变。
- `scripts/managers/HealthManager.gd`：`get_energy_cost_multiplier()` 内部
  改为分别调用 `BaseStatusManager.get_temperature_energy_multiplier()` 和
  新增的 `AirSystemManager.get_air_energy_multiplier()`，两者相乘；fullness
  分段数值本身未改动。
- `scripts/managers/TimeManager.gd`：`advance_time()` 在
  `_apply_base_status_time()` 之后、`_apply_plant_growth_time()` 之前新增
  `_apply_air_system_time()` 调用；`reset_to_arrival()` 追加对
  `AirSystemManager.reset_to_arrival()` 的级联调用。
- `scripts/base/sprint06_base_scene.gd`（10 个场景共用）：
  - `_save_state()`/`_load_state()` 追加 `AirSystemState` 序列化/反序列化。
  - `_sync_base_status_from_state()` 拆成两部分：`BaseStatusManager` 的
    `PowerPanelRepaired`/`BasePowerRestored`/最后一株植物加成钩子保持不变；
    原来挂在 `BaseStatusManager` 上的 `MinimalLifeSupportStable` →
    `repair_life_support_light` 那个钩子，改成挂到 `AirSystemManager` 的
    `repair_oxygen_generator_light`（新增一次性 applied 标记
    `AirSystemOxygenGeneratorLightApplied`，避免重复触发）。
  - 新增 O 键（`toggle_air_status`）开关新的 `AirSystemPanel`，只在
    `_setup_ui()`/`_unhandled_input()`/`_update_ui()` 各加了几行，没有动
    greenhouse/interior 的既有交互逻辑。
- `scripts/training/training_manager.gd`：`default_data()`/`load_progress()`/
  `save_progress()`/`reset_progress()` 追加 `AirSystemState` 字段，写法对齐
  已有的 `BaseStatusState` 处理。
- `scripts/props/reference_prop.gd`：本次未触碰。

## 验证

- Godot 4.7 headless 逐个加载并确认无 `SCRIPT ERROR`/`Parse Error`：
  `main.tscn`、`OldBaseInteriorScene.tscn`、`OldGreenhouseScene.tscn`、
  `Day02StartScene.tscn`、`WeekRoutineStartScene.tscn`、
  `SolarArrayExteriorScene.tscn`、`Training_03_PowerRepair.tscn`、
  `FinalAssessmentScene.tscn`。
- 过程中先遇到一次真实的 Parse Error（`min()` 返回值在严格模式下无法推断
  类型，导致 `pressure_gain`/`reserve_used` 报错，AirSystemManager 整个
  autoload 加载失败），已通过显式类型标注 `: float` 修复并重新验证通过。
- 临时脚本（未提交，验证后已删除）跑通了：抵达初始值精确匹配需求文档
  （O₂ 20.4% / CO₂ 0.42% / 惰性气体 79.18% / 储备 55）；24 小时结算下 O₂/CO₂
  按设备档位正确变化；制氧/过滤/循环三组维修正确跳档并生效；O₂ 推到 30%
  （供氧过量）时能耗倍率精确为 1.0（无富氧惩罚），推到危险区间（O₂15%+
  CO₂3.5%）时能耗倍率精确为 1.5×1.4=2.1，心理按预期速率下降；密封 CRITICAL
  下惰性气体储备消耗速率、自动补压对舱压的回升幅度都与手算结果完全一致；
  序列化/反序列化往返正确。
- 未跑图形界面截图（本次未涉及新视觉资产，新增的空气面板默认隐藏、按 O
  打开；截图验收留给人类玩测或下一轮）。

## 已知问题 / 暂不覆盖范围

- 供氧目标档位（`supply_target_mode`）是纯预留字段，不影响任何数值结算，
  也没有玩家可操作的面板控件（只有 Debug 循环切换）——按需求文档"如果尚未
  实现真实水资源，先只记录预留字段"的说明保留为占位。
- CO₂过滤模块、空气循环系统（AirSystemManager）以及温控、密封
  （BaseStatusManager）都还没有场景内的维修交互入口，只有方法 + Debug
  按钮；目前只有供电（BaseStatusManager）和制氧模块（AirSystemManager，
  接的是旧基地 `MinimalLifeSupportStable` 那个既有交互点）真正接了玩法。
- 惰性气体自动补压的换算率（0.15/0.20）、空气设备维修的一次性数值都是本次
  实现自定的 v1 占位值，原始需求文档没有给这部分具体数字，已在
  `SYSTEMS_REFERENCE_FOR_DESIGN.md` 里明确标注为"占位值，可以直接改常量
  调整"。
- 水循环等级、温室补光等级（PlantGrowthManager）依旧是独立数值，跟这次的
  空气系统没有关联——植物系统读的是自己的 `water_cycle_level`，不是空气
  系统的任何数值。
- Godot 在本地会刷新大量已跟踪 `.import` 文件和生成 `.uid`/`.godot_appdata/`，
  它们不属于本次改动，提交时未暂存。

## 先别碰

（暂无）
