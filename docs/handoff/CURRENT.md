# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-06
更新人：Claude Code（本轮临时顶替 Codex 的游戏逻辑/Manager/数据/流程职责——Codex
临时无 token，由 Claude Code 在独立会话中代打这部分；同一时间另一个 Claude Code
会话仍在并行做场景/UI/美术。Codex 恢复后请按下方记录核对，不要误以为是
Codex 自己之前做的）

## 正在进行

（暂无，"电力平衡系统"重构已完成，本轮改动已提交）

## 最近完成

- **Claude Code（代 Codex）**：完成电力平衡系统重构。
  - **新增 `scripts/managers/PowerSystemManager.gd`**，注册为
    `/root/PowerSystemManager`（放在 `BaseStatusManager` 之后、
    `AirSystemManager` 之前，settlement 顺序：Power → Base → Air → Plant →
    Health）。管理：
    - `current_energy`（抵达 50 E）/ `battery_module_count`（抵达 2，每模块
      60 E）/ `base_battery_capacity`（=模块数×60）/ `storage_efficiency`
      （抵达 1.0，5 档科技：1.0/1.15/1.30/1.50/1.80）/ `battery_capacity`
      （=基础容量×储能效率）/ `solar_panel_count`（抵达 2）/
      `solar_array_status`（抵达 CRITICAL，独立局部枚举）/
      `charging_efficiency`（抵达 1.0，5 档科技：1.0/1.15/1.25/1.40/1.60）/
      `current_power_mode`（纯描述性字段，记录最近应用的电力模式预设）。
    - 每小时结算：月昼太阳能发电（面板数×0.35×阵列倍率×充电效率）减去总负载；
      月夜/月夜末期只扣负载；结果 clamp 到电池容量。
    - 总负载 = 基地最低运行 0.03 + AirSystemManager 报告的空气耗电 +
      BaseStatusManager 报告的温控耗电 + PlantGrowthManager 报告的夜间补光
      耗电（新增了三个跨 Manager 的"报告耗电"方法，见下）。
    - 一次性行动耗电（发送报告/娱乐/维修/整理物资/植物诊断/外出采集，数值
      来自需求文档），跟 HealthManager 的行动结算同一批 reason 字符串。
    - 加电池模块 / 升级储能效率**只提高容量上限，不凭空增加当前电量**
      （已用临时脚本验证）。
    - 电量百分比文案 5 档（供电稳定/供电紧张/低电力/电力危机/断电边缘），
      低于 20%（且高耗电设置开启）/低于 5% 时面板追加强提醒文案；**电量为 0
      不会强制 Game Over**，也没有专门写"强制关闭设备"的代码——温控/制氧/
      CO₂过滤在低电力时的效果打折/归零，完全靠 BaseStatusManager/
      AirSystemManager 已有的电力倍率表自然达成。
    - 四个"推荐电力模式"Debug 预设（极限省电/标准维持/标准维持+夜间2级补光/
      高负载温室），只调 AirSystemManager 的供氧目标 + PlantGrowthManager
      的补光等级这两个"旋钮"，不碰维修驱动的设备档位。
    - 面板文本含净变化 E/h、预计充满/预计耗尽（按当前净变化线性外推，不管
      未来的月相切换，`不做真实仿真`要求下的简化）。
    - 四种教育背景专业提示（机械工程判断发电瓶颈 vs 电池瓶颈、材料科学提示
      月尘/老化、医学提示省电模式对精力消耗的影响、植物科学提示夜间高补光
      是否撑得到需求文档的"240 小时"标准）。
    - 存档 `user://saves/power_system_state.json`，同时接入旧基地/温室/第一周
      存档与训练进度存档的 `PowerSystemState` 字段。
  - **BaseStatusManager 的 `power` 变量改为兼容字段**：不再自己结算，改由
    `PowerSystemManager.advance_power_time()` 结算后调用新增的
    `set_power_percent(value)` 直接赋值。原来的 `_apply_power_change()`、
    `adjust_stat("power", ...)` 分支已移除；新增 `get_thermal_power_load()`
    供 PowerSystemManager 查询温控耗电（值本身来自需求文档：CRITICAL 0.06/
    BASIC 0.10/STABLE 0.16，OFFLINE 0）。`power_system_status`
    （供电系统 CRITICAL/BASIC/STABLE）连同 `repair_power_light/heavy()`
    **保留但已经变成纯装饰字段**——旧基地场景里 `PowerPanelRepaired`/
    `BasePowerRestored` 那两个交互点仍照常触发它们、文案照常播放，但已经
    不影响任何电力数值（那是 `solar_array_status` 的职责）。这是本次特意
    选择保留、不做进一步清理的技术债，已在设计参考文档里明确标注。
  - **AirSystemManager 的 `supply_target_mode`（关闭/节能/标准/充足/应急）
    从纯预留字段变成真正驱动制氧模块耗电**（0/0.03/0.06/0.10/0.18 E/小时），
    新增 `get_air_power_load()`（制氧+CO₂过滤+空气循环三项耗电加总，CO₂
    过滤/空气循环按各自设备档位取值，制氧按供氧目标取值）和
    `debug_set_supply_target(mode_id)`（直接设置，供电力模式预设调用；原有
    `debug_cycle_supply_target()` 循环按钮仍保留）。O₂ 产出速率本身不受
    供氧目标影响，仍然只看 `oxygen_generator_status`。
  - **PlantGrowthManager** 新增 `greenhouse_zone_count`（默认 1，预留字段，
    未来温室扩建乘数，无扩建 UI）和 `get_greenhouse_light_power_load()`
    （月昼恒 0，月夜按补光等级的"目标档位"本身计算，不是被电力衰减后的
    "有效光照等级"——即使打折依然按目标档位耗电）。
  - **UI**：新增 `scripts/ui/power_system_panel.gd`，在 `sprint06_base_scene.gd`
    里用新按键 `P` 开关，位置 `Vector2(740, 500)`（跟基地状态面板 Tab、
    植物面板 G、空气面板 O 组成 2×2 网格，互不重叠，都在 1600x900 视口内）。
  - **Debug 支持**：主菜单开发菜单新增 Power Debug 分组（电量加减、加太阳能
    板/加电池模块各一个"+1"按钮、太阳能阵列档位循环、储能/充电效率科技档位
    循环、四个电力模式预设、重置 Day 01、设为最低稳定状态），并删除了原来
    Base Debug 里已经失效的 "Power -10/+10" 按钮（那两个按钮调的是
    BaseStatusManager 的旧电力字段，现在会被下一次 tick 的
    PowerSystemManager 结算立即覆盖，留着只会误导人）。
  - 设计参考文档 `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md` 已同步更新
    （按用户要求，新增/改动数值系统时必须同步这份文档）：新增第五节"电力
    系统 PowerSystemManager"，基地状态、空气系统、植物生长三节都补充了各自
    向电力系统"报告耗电"的新增方法，健康系统章节的耦合公式引用节号已更新，
    "尚未覆盖"清单也加入了 `power_system_status` 变成装饰字段等新已知问题。

## 对共用核心文件的改动记录（第一档文件，已按规则先查 git log 再改）

- `scripts/managers/BaseStatusManager.gd`：移除 `_apply_power_change()` 和
  `adjust_stat()` 里的 `"power"` 分支；新增 `set_power_percent(value)`（供
  PowerSystemManager 调用的兼容同步入口）和 `get_thermal_power_load()`
  （温控耗电查询）。`power` 变量本身、`power_system_status`、
  `repair_power_light/heavy()`、相关面板文本/专业提示分支**全部原样保留**
  （现在是装饰性字段，见上）。舱压/温度的既有结算逻辑完全未改动。
- `scripts/managers/AirSystemManager.gd`：`SUPPLY_TARGETS` 常量字典追加
  `power_load` 键（每档一个数值，不影响原有的 `target_o2` 键）；新增
  `get_air_power_load()`/`_oxygen_generator_power_load()`/
  `_co2_filter_power_load()`/`_air_circulation_power_load()`/
  `debug_set_supply_target()`；`panel_status_text()` 里"供氧目标"那一行的
  文案从"预留，尚未接入耗电/耗水"改成显示实际耗电数值。O₂/CO₂/惰性气体的
  结算逻辑完全未改动。
- `scripts/systems/PlantGrowthManager.gd`：新增 `greenhouse_zone_count`
  字段（默认 1，纳入 `reset_to_arrival()`/`serialize()`/`deserialize()`）
  和 `get_greenhouse_light_power_load()`。生长/收获/专业提示逻辑完全未改动。
- `scripts/managers/TimeManager.gd`：`advance_time()` 在 `total_minutes`
  推进后、`_apply_base_status_time()` 之前新增 `_apply_power_system_time()`
  调用；在 `_apply_health_action_cost()` 之后新增 `_apply_power_action_cost()`
  调用。`reset_to_arrival()` 里 `PowerSystemManager.reset_to_arrival()` 特意
  排在 `BaseStatusManager.reset_to_arrival()` **之后**调用——因为
  PowerSystemManager 重置时会把精确算出的 `power_percent`（50/120≈41.67%）
  同步写回 `BaseStatusManager.power`，覆盖掉 BaseStatusManager 自己重置时
  写入的旧硬编码值 42.0，两者顺序不能反。
- `scripts/base/sprint06_base_scene.gd`（10 个场景共用）：
  - `_save_state()`/`_load_state()` 追加 `PowerSystemState`
    序列化/反序列化，对齐已有的 `AirSystemState` 处理方式。
  - 新增 P 键（`toggle_power_status`）开关新的 `PowerSystemPanel`，只在
    `_setup_ui()`/`_unhandled_input()`/`_update_ui()` 各加了几行，没有动
    现有的维修交互逻辑（`PowerPanelRepaired`/`BasePowerRestored` 钩子原样
    保留，指向的仍是 BaseStatusManager 上那两个现在纯装饰性的方法）。
- `scripts/training/training_manager.gd`：`default_data()`/`load_progress()`/
  `save_progress()`/`reset_progress()` 追加 `PowerSystemState` 字段，写法
  对齐已有的 `AirSystemState` 处理。
- `scripts/props/reference_prop.gd`：本次未触碰。

## 验证

- Godot 4.7 headless 逐个加载并确认无 `SCRIPT ERROR`/`Parse Error`：
  `main.tscn`、`OldBaseInteriorScene.tscn`、`OldGreenhouseScene.tscn`、
  `Day02StartScene.tscn`、`WeekRoutineStartScene.tscn`、
  `SolarArrayExteriorScene.tscn`、`Training_03_PowerRepair.tscn`、
  `FinalAssessmentScene.tscn`。
- 临时脚本（未提交，验证后已删除）跑通了：抵达初始值精确匹配（50/120E≈
  41.67%，`BaseStatusManager.power` 同步正确，不再是硬编码的 42）；负载
  加总公式（基础0.03+空气0.13+温控0.06+补光0.04=0.26）跟面板显示完全一致；
  夜间/白昼各推进 1 小时的电量变化跟手算结果精确匹配（含月昼下补光免费、
  月夜下补光按目标档位耗电两种情况）；加电池模块、升级储能效率均确认
  "只提高上限、不凭空充电"；重维修/轻维修跳档正确；四个电力模式预设正确
  跨 Manager 写入了 AirSystemManager 的供氧目标和 PlantGrowthManager 的
  补光等级；5 档电量文案分段、<20%/<5% 低电量提醒文案都在边界值上验证过；
  序列化/反序列化往返正确。全程未发现代码缺陷。
- 未跑图形界面截图（本次未涉及新视觉资产，新增的电力面板默认隐藏、按 P
  打开；截图验收留给人类玩测或下一轮）。

## 已知问题 / 暂不覆盖范围

- `power_system_status`（BaseStatusManager）现在是纯装饰字段，旧基地场景的
  供电维修交互仍会触发它，但不再影响任何电力数值——真正的发电速度只看
  `PowerSystemManager.solar_array_status`（目前只能 Debug 调）。下一轮如果
  要让"修供电面板"这个既有玩法动作真正影响新电力系统，需要决定是废弃
  `power_system_status` 还是把它重新映射到 `solar_array_status`。
- 电力系统完全没有玩家可操作的面板控件（加太阳能板/加电池模块/切换供氧
  目标/切换电力模式），全部只能走 Debug 菜单；供氧目标对电力的耦合已经
  接上，但对水系统的耦合仍是纯占位（水消耗还没有任何系统在管）。
- 惰性气体自动补压换算率、空气/电力设备维修的一次性数值都是本次或上一轮
  实现自定的 v1 占位值，已在 `SYSTEMS_REFERENCE_FOR_DESIGN.md` 里逐条标注
  "占位值，可以直接改常量调整"。
- 温控/密封/CO₂过滤/空气循环仍然没有场景内的维修交互入口，只有制氧模块
  （挂在旧基地既有的 `MinimalLifeSupportStable` 交互点上）和供电（现在是
  装饰性的）接了玩法。
- Godot 在本地会刷新大量已跟踪 `.import` 文件和生成 `.uid`/`.godot_appdata/`，
  它们不属于本次改动，提交时未暂存。

## 先别碰

（暂无）
