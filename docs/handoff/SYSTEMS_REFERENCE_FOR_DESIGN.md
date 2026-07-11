# 广寒前哨 · 核心数值系统参考（交给系统设计用）

本文档汇总当前已实现的八套核心数值系统：**时间系统 / 玩家健康系统 / 基地状态系统 /
电力系统 / 水资源系统 / 空气系统 / 植物生长系统 / 物品系统**。所有数值直接摘自源码
（截至"物品系统"实现完成，植物收获不再直接回血，改成产出食物类物品，吃了才回血），
不是设计草稿。如果要基于这些系统做新一轮设计，请以本文档 + 源码为准，不要凭记忆
假设数值。

## 文档职责

本文件是**系统玩法规则、数值与设计约束**的权威参考，回答：系统如何影响玩家和基地运行、玩法规则/状态/阈值/数值、系统之间的设计交互、UI/训练/反馈的产品要求、设计层面的接口预期。

**不承担**：哪个脚本现役、Manager 生命周期治理、`legacy`/`compatibility` 注册状态、共用文件锁、Agent owner、清理优先级、Git/协作流程。这些是系统身份与治理层面的真相，见 [`SYSTEM_REGISTRY.md`](../governance/SYSTEM_REGISTRY.md)。

> 本文档出现的脚本名/系统名用于说明**设计对应关系**，不替代 `SYSTEM_REGISTRY.md` 的现役状态判断——不要因为这里提到某个 Manager 名就断定它仍现役（现役与否以 [`SYSTEM_REGISTRY.md`](../governance/SYSTEM_REGISTRY.md) 为准）。

代码位置：
- `scripts/managers/TimeManager.gd`（autoload `/root/TimeManager`）
- `scripts/managers/HealthManager.gd`（autoload `/root/HealthManager`）
- `scripts/managers/BaseStatusManager.gd`（autoload `/root/BaseStatusManager`）——
  只管舱压/温度 + `power` 兼容字段，**不再自己计算电力，也不管氧气**
- `scripts/managers/PowerSystemManager.gd`（autoload `/root/PowerSystemManager`）——
  太阳能板/电池/负载/科技效率的完整电力模型，结算后把 `power_percent` 写入
  `BaseStatusManager.power` 做兼容
- `scripts/managers/WaterSystemManager.gd`（autoload `/root/WaterSystemManager`）——
  可用水/月球冰的库存、冰处理、水循环回收，向电力系统报告耗电，向空气系统
  的制氧模块报告耗水并回传"供水满足率"
- `scripts/managers/AirSystemManager.gd`（autoload `/root/AirSystemManager`）——
  管 O₂/CO₂/惰性气体，从 BaseStatusManager 拆分出来的系统
- `scripts/systems/PlantGrowthManager.gd`（autoload `/root/PlantGrowthManager`）——
  收获现在只产出物品，不再直接改健康数值，实际回血发生在吃的时候
- `scripts/data/PlantCropData.gd`（纯数据，`preload()` 引用，无 autoload）——每种
  作物新增 `harvest_item_id` 字段，指向 ItemDatabase 里的食物条目
- `scripts/data/ItemDatabase.gd`（纯数据，`preload()` 引用，无 autoload，参考
  `PlantCropData.gd` 同款写法避免 `class_name` 缓存问题）
- `scripts/managers/InventoryManager.gd`（autoload `/root/InventoryManager`）——
  库存增删、吃/用物品、耐久工具，见第八节

七套挂在结算链上的系统，调用顺序（`TimeManager.advance_time(minutes, reason)`
内部）：

```
玩家执行一个行动
  → HealthManager.adjusted_action_minutes()     先按精力算这次行动实际耗时
  → total_minutes += 实际耗时                    时钟推进
  → PowerSystemManager.advance_power_time()      电力最先结算（含水循环耗电），
                                                  并把 power_percent 同步写入
                                                  BaseStatusManager.power
  → WaterSystemManager.advance_water_time()      水资源结算（生活用水+制氧耗水），
                                                  算出这一 tick 的"制氧供水满足率"
  → BaseStatusManager.advance_base_time()        舱压/温度结算（读取已同步的 power）
  → AirSystemManager.advance_air_time()          空气系统结算（O2/CO2/惰性气体），
                                                  O2 产出会被供水满足率节流
  → PlantGrowthManager.advance_plant_time()      植物生长再结算（水条件的真实
                                                  扣水发生在这里，向 WaterSystemManager
                                                  按需请求，不是走上面的 hourly tick）
  → HealthManager.apply_action_cost()            结算这次行动本身的健康消耗
  → PowerSystemManager.apply_action_cost()       结算这次行动的一次性耗电
  → WaterSystemManager.apply_action_cost()       结算这次行动的一次性耗水（进食/营养液）
```

---

## 一、时间系统 TimeManager

### 定位
唯一的时间源。**不随现实时间流逝**，只在玩家执行明确行动时通过
`advance_time(minutes, reason)` 推进；其余三套系统都挂在这个推进事件上结算，
自己不会主动推进时间。

### 月面时间线
- 抵达时刻：Day 01 06:40，处于"月夜末期"。
- 一个完整月面周期 = 42 天（`FULL_LUNAR_CYCLE_MINUTES = 42 * 1440`）。
- 三段阶段（`lunar_phase`）：
  - `night_late` 月夜末期：周期第 0–7 天（`DAYLIGHT_START_MINUTE = 7*1440`）
  - `daylight` 月昼作业期：周期第 7–21 天（`NIGHT_START_MINUTE = 21*1440`）
  - `night` 月夜期：周期第 21–42 天
- 阶段切换时会生成一次性提示文案（`_phase_notice_text`），目前只有中文台词，
  没有数值：
  - 进入月昼：`月面日出确认。太阳高度角上升。太阳能阵列输入恢复。外部作业窗口开启。广寒前哨进入月昼作业期。`
  - 进入月夜：`月面日落确认。太阳能输入下降。外部作业风险上升。基地进入月夜节能准备。请确认电力、水、氧气与食物储备。`

### 行动耗时表（`action_minutes()`，单位：分钟）

| 行动 | 耗时 |
|---|---|
| 移动一格 `move` | 1 |
| 标准睡眠 `sleep_standard` | 360（6 小时） |
| 进食 `eat` | 30 |
| 喝营养液 `nutrition_drink` | 15 |
| 短娱乐 `entertainment_short` | 60 |
| 长娱乐 `entertainment_long` | 120 |
| 轻维修 `repair_light` | 30 |
| 重维修 `repair_heavy` | 60 |
| 短采集 `explore_short` | 120 |
| 长采集 `explore_long` | 240 |
| 植物诊断 `plant_diagnosis` | 15 |
| 整理物资 `organize_supplies` | 30 |
| 发送报告 `send_report` | 15 |

这个耗时会先被 `HealthManager.adjusted_action_minutes()` 按精力倍率放大（见下一节），
移动和 `debug_jump_*` 不触发健康行动消耗。

### 存档
`user://saves/time_state.json`：`total_minutes / current_day / hour / minute /
lunar_phase / minutes_until_phase_change`。

---

## 二、玩家健康系统 HealthManager

### 定位
驻留者的四项个人状态，全部 0–100，clamp。**不是生存判定，只是效率修饰**——
目前没有"精力归零死亡"这类硬失败。

### 负重能力 v1

`HealthManager` 现在也提供玩家身体层面的负重上限，不负责背包格子、不负责物品重量计算，也不直接施加惩罚。

字段：
- `base_carry_capacity = 50.0`：基础最大负重，单位 CU（Carry Unit / 携行单位）。
- `effective_carry_capacity`：当前有效负重上限，由健康状态实时计算。
- `carry_health_score`：`min(energy, fullness, nutrition)`。
- `carry_health_multiplier`：健康状态对负重上限的倍率。

倍率：
- `carry_health_score >= 70`：`1.0`
- `40–69`：`0.9`
- `20–39`：`0.75`
- `0–19`：`0.6`

接口：
- `get_carry_health_multiplier() -> float`
- `get_effective_carry_capacity() -> float`

`morale` 不直接影响负重上限。`base_carry_capacity` 进入 `health_state.json` 存档；`effective_carry_capacity`、`carry_health_score`、`carry_health_multiplier` 不需要存档，随时可重算。

### 四项数值与抵达初始值

| 状态 | 初始值 | 含义 |
|---|---|---|
| `energy` 精力 | 80 | 影响行动耗时倍率 |
| `fullness` 饱腹 | 80 | 影响精力消耗倍率 |
| `nutrition` 营养 | 85 | 影响睡眠恢复倍率 |
| `morale` 心理 | 75 | 影响睡眠恢复倍率；也被基地状态系统间接扣减 |

### 行动结算表（每次行动对四项的增减，单位：绝对值，负值会再乘"精力消耗倍率"）

| 行动 | 精力 | 饱腹 | 营养 | 心理 | 备注 |
|---|---|---|---|---|---|
| 标准睡眠 | `+70 × 营养睡眠倍率 × 心理睡眠倍率` | −15 | −5 | +5 | 恢复量是唯一受倍率**加成**的项 |
| 进食 | −1 | +45 | −2 | +2 | |
| 营养液 | 0 | +5 | +25 | −1 | |
| 短娱乐 | +5 | −5 | −2 | +20 | |
| 长娱乐 | +10 | −10 | −3 | +35 | |
| 植物诊断（正面结果） | −2 | −1 | 0 | +1 | |
| 植物诊断（负面结果） | −2 | −1 | 0 | −2 | |
| 整理物资 | −4 | −3 | 0 | 0 | |
| 发送报告（正面） | −1 | −1 | 0 | +2 | |
| 发送报告（负面） | −1 | −1 | 0 | −2 | |
| 轻维修 | −8 | −4 | −1 | −2 | |
| 重维修 | −16 | −8 | −2 | −5 | |
| 短采集 | −25 | −15 | −3 | −5 | |
| 长采集 | −45 | −30 | −6 | −10 | |

### 倍率规则

**行动耗时倍率**（只影响 repair_light/heavy、explore_short/long、
organize_supplies、plant_diagnosis 这几类行动的分钟数，`ceil` 取整）：
- 精力 ≥40：×1.0
- 精力 20–39：×1.25
- 精力 <20：×1.5

**精力消耗倍率**（只影响上表里"精力"一栏的负值，正值/其他项不受影响）：
```
fullness_multiplier（饱腹）：
  ≥70：×1.0   40–69：×1.2   20–39：×1.4   <20：×1.6
× environment_multiplier（来自 BaseStatusManager，默认 1.0，见下）
```

**睡眠恢复倍率**（只影响标准睡眠的精力恢复量 70）：
- 营养睡眠倍率：营养≥70→×1.0，≥40→×0.8，≥20→×0.6，<20→×0.4
- 心理睡眠倍率：心理≥40→×1.0，≥20→×0.8，<20→×0.6

### 与基地状态系统 / 空气系统的耦合（`get_energy_cost_multiplier()`）
```
最终精力消耗倍率 = fullness_multiplier
                × BaseStatusManager.get_temperature_energy_multiplier()
                × AirSystemManager.get_air_energy_multiplier()
```
任一 Manager 不存在时对应项默认 1.0（不影响旧行为）。氧气/CO₂ 已经从
`BaseStatusManager` 完全移出，`BaseStatusManager` 现在只贡献温度倍率；具体数值见
第三节"精力消耗温度倍率"和第四节"空气系统对健康系统的能耗倍率影响"。

### 文案分段（HUD 用，四项各自独立）
精力：≥70 良好 / ≥40 疲惫 / ≥20 严重疲惫 / <20 危险疲惫
饱腹：≥70 正常 / ≥40 有些饿 / ≥20 饥饿 / <20 严重饥饿
营养：≥70 良好 / ≥40 偏低 / ≥20 不足 / <20 严重不足
心理：≥70 稳定 / ≥40 低压 / ≥20 低落 / <20 危险

### 专业提示（仅"医学"背景，不加数值）
条件优先级（从上到下第一个满足的生效）：
1. 精力<40 且 营养<70 且 心理<40 → 提示营养+心理是瓶颈
2. 精力<40 → 提示精力不足
3. 饱腹<40 → 提示不建议高消耗行动
4. 营养<70 → 提示睡前先补营养液
5. 心理<40 → 提示睡前先娱乐
6. 都不满足 → 泛用"可维持基础工作"文案

### 存档
`user://saves/health_state.json`：`energy / fullness / nutrition / morale`。

---

## 三、基地状态系统 BaseStatusManager

### 定位
基地作为生命维持环境的抽象状态，**不做真实工程仿真**。三个设备档位决定
舱压/温度每小时变化率，设备档位只能靠"维修"改变（维修本身不推进时间，由
调用方另外推进 TimeManager）。

> 氧气/CO₂/惰性气体已经完全拆分到 `AirSystemManager`（见第四节），
> `life_support_status` 已删除，替换为 AirSystemManager 里的
> `oxygen_generator_status`/`co2_filter_status`/`air_circulation_status`。
>
> **电力（`power`）也已经不再由 BaseStatusManager 自己结算**——真正的太阳能/
> 电池/负载模型现在完全在 `PowerSystemManager`（见第五节）。`power` 变量
> 本身还留在 BaseStatusManager 上，但只是一个**兼容字段**：
> `PowerSystemManager.advance_power_time()` 每次结算后调用
> `BaseStatusManager.set_power_percent(value)` 直接赋值，`power` 不再有
> 自己的每小时变化率函数。这样做是为了不用改动所有原本读
> `BaseStatusManager.power` 的地方（温度倍率计算、AirSystemManager 的电力
> 倍率、HealthManager 的环境倍率）——它们全都不用动，继续读同一个变量即可。
>
> `power_system_status`（供电系统 CRITICAL/BASIC/STABLE 档位）连同
> `repair_power_light/heavy()` **仍然保留但已经变成纯装饰性字段**——它不再
> 影响任何电力数值结算（那是 `PowerSystemManager.solar_array_status` 的
> 职责），只是继续显示在 BaseStatusManager 自己的面板/专业提示里，避免破坏
> 现有的 `PowerPanelRepaired`/`BasePowerRestored` 维修交互流程。这是本次
> 特意选择保留、未做进一步清理的一处技术债，见第九节。

### 三项数值与抵达初始值（0–100，越高越好；温度用摄氏度，clamp −40~60）

| 状态 | 初始值 | 结算方 |
|---|---|---|
| `power` 电力 | 42（现在由 PowerSystemManager 算出后写入，见第五节） | PowerSystemManager |
| `pressure` 舱压 | 76 | BaseStatusManager |
| `temperature` 温度 | 14℃（舒适目标 21℃） | BaseStatusManager |

### 三个设备档位（`SystemStatus`：OFFLINE < CRITICAL < BASIC < STABLE）与初始值

| 设备 | 初始档位 | 现在的作用 |
|---|---|---|
| `power_system_status` 供电系统 | CRITICAL | **纯装饰，不影响任何结算**（见上） |
| `thermal_control_status` 温控系统 | CRITICAL | 影响温度效果 + 向 PowerSystemManager 报告耗电 |
| `seal_status` 密封状态 | BASIC | 影响舱压 + AirSystemManager 的惰性气体消耗 |

### 每小时变化率

**舱压** 只看密封档位：OFFLINE −0.20 / CRITICAL −0.06 / BASIC −0.02 /
STABLE 0

**温度** = 阶段+温控档位的基础变化（月夜偏冷、月昼偏热或"拉向目标温度"）×
电力倍率 + 舱压附加，每小时：

| 温控档位 | 月夜 | 月昼 |
|---|---|---|
| OFFLINE | −0.35（固定速率） | +0.20（固定速率） |
| CRITICAL | −0.15（固定速率） | +0.05（固定速率） |
| BASIC | 向 18℃ 靠近，上限 0.10 | 向 21℃ 靠近，上限 0.15 |
| STABLE | 向 21℃ 靠近，上限 0.25 | 向 21℃ 靠近，上限 0.25 |

电力倍率（乘在上面所有温控速率上）：电力≥70→×1.0，≥40→×0.75，≥20→×0.4，
<20→×0（温控几乎失效）

舱压附加（直接相加，不受电力倍率影响）：
- 舱压≥70：0
- 舱压 40–69：月夜 −0.03 / 月昼 +0.02
- 舱压 20–39：月夜 −0.08 / 月昼 +0.05
- 舱压 0–19：月夜 −0.15 / 月昼 +0.10

### 维修行动（只改档位 + 一次性数值，不推进时间；档位必须严格满足前置才会跳档）

| 维修 | 档位变化 | 一次性数值 |
|---|---|---|
| 供电轻维修 | CRITICAL→BASIC | 电力 +3 |
| 供电重维修 | BASIC→STABLE | 电力 +5 |
| 温控轻维修 | CRITICAL→BASIC | 温度向 18℃ 靠近，单次最多 1.0℃ |
| 温控重维修 | BASIC→STABLE | 温度向 21℃ 靠近，单次最多 1.5℃ |
| 密封轻修补 | CRITICAL→BASIC | 舱压 +3 |
| 密封重修补 | BASIC→STABLE | 舱压 +5 |

（对应的 30/60 分钟耗时由调用方通过 `TimeManager.advance_time()` 另外推进，
`BaseStatusManager` 本身不管时间。供电轻/重维修现在**只改 `power_system_status`
装饰性字段和 `power`（会被下一次 PowerSystemManager 结算覆盖），不再产生
持续效果**；温控、密封只有方法 + Debug 按钮，没有场景交互入口。原本挂在这里的
"生命支持轻/重维修"已经迁移成 AirSystemManager 的
`repair_oxygen_generator_light/heavy`，旧基地场景里 `MinimalLifeSupportStable`
那个交互现在改叫 AirSystemManager 上的这两个方法。）

### 新增：向电力系统报告耗电（`get_thermal_power_load()`）
温控档位对应的每小时耗电（供 `PowerSystemManager` 汇总负载用，跟上面"温控
效果"的档位是同一个字段，两件事分开算）：
```
OFFLINE 0 / CRITICAL 0.06 / BASIC 0.10 / STABLE 0.16   (E/小时)
```

### 对健康系统的反向影响（每小时，累加成一次 `morale` 调整）
- 电力 0–19：心理 −0.08/小时；电力 20–39：−0.03/小时
- 舱压 0–19：心理 −0.10/小时；舱压 20–39：−0.05/小时
- 温度"危险"（<10℃ 或 >32℃）：心理 −0.05/小时

### 对健康系统"精力消耗倍率"的影响（`get_temperature_energy_multiplier()`）
```
舒适(18–26℃)→×1.0；危险(<10℃或>32℃)→×1.25；其余→×1.1
```
（这个方法之前叫 `get_environment_energy_multiplier()` 且内含氧气倍率；氧气
部分已经完全移到 AirSystemManager，方法也改了名字，HealthManager 里两个倍率
分开调用、相乘。）

### 文案分段
电力：≥70 供电稳定 / ≥40 供电紧张 / ≥20 低电力 / <20 电力危机
舱压：≥70 舱压稳定 / ≥40 轻微泄压 / ≥20 明显泄压 / <20 气密危机
温度：18–26 舒适 / 10–17.99 偏冷 / 5–9.99 低温危险 / <5 严重低温 /
26.01–32 偏热 / 32.01–35 高温危险 / >35 严重高温
设备档位：OFFLINE=离线（密封显示"破损"）/ CRITICAL=危急 / BASIC=基础运行
（密封"基础密封"）/ STABLE=稳定运行（密封"稳定密封"）

### 专业提示（只读玩家自己的教育背景，不加数值，四选一互斥）
- 机械工程：电力<70 或 温控非 STABLE → 建议优先恢复供电（不再提生命支持，
  那部分诊断挪到 AirSystemManager 自己的机械工程提示里）
- 材料科学：舱压<80 或 密封非 STABLE → 提示密封老化风险
- 医学：温度不在 18–26 或 电力≤19 → 提示低温/电力危机增加精力消耗（氧气相关
  的医学提示已经完全移到 AirSystemManager）
- 植物科学：温度不在 18–26 或 电力<70 或 最后一株植物尚未脱离 Critical →
  提示植物恢复会延迟

### 存档
`user://saves/base_status_state.json`：`power / pressure / temperature /
power_system_status / thermal_control_status / seal_status /
last_plant_recovered_bonus_active`。（`oxygen` 和 `life_support_status`
已经从这个文件里删除。）

---

## 四、空气系统 AirSystemManager（新拆分出来的系统）

### 定位
舱内空气组成——是否可呼吸——跟"基地结构是否稳定"完全分开管理。
**不做真实气体方程/分压计算**，只做可调的抽象变化率。

### 核心变量与抵达初始值

| 变量 | 初始值 | 说明 |
|---|---|---|
| `o2_percent` O₂ 浓度 | 20.4% | 百分比，不是 0–100 抽象值 |
| `co2_percent` CO₂ 浓度 | 0.42% | |
| `inert_gas_percent` 惰性气体比例 | 79.18%（= `100 - o2 - co2`，每次变动后重新计算，不能独立赋值） | 舱内空气构成的一部分 |
| `inert_gas_reserve` 惰性气体储备 | 55.0（0–100） | 独立库存，不是每日呼吸消耗的资源，只在密封泄漏/补压时消耗，**第一版不能生产** |

### 三个设备档位（沿用 OFFLINE<CRITICAL<BASIC<STABLE，但这是 AirSystemManager
自己的枚举，不直接依赖 BaseStatusManager 的脚本）与初始值

| 设备 | 初始档位 |
|---|---|
| `oxygen_generator_status` 制氧模块 | CRITICAL |
| `co2_filter_status` CO₂过滤模块 | CRITICAL |
| `air_circulation_status` 空气循环系统 | BASIC |

### O₂ 每小时变化
```
o2_delta = (人类呼吸固定值 + 制氧模块产出×电力倍率×供水满足率 + 最后一株植物加成) × 小时数
```
- 人类呼吸：固定 −0.015%/小时（不受供水满足率节流，那是"产出"侧的事，不是
  "消耗"侧）
- 制氧模块产出：OFFLINE 0.000 / CRITICAL +0.010 / BASIC +0.025 / STABLE +0.040
  （单位 %/小时，乘电力倍率、乘供水满足率）
- 电力倍率（读 `BaseStatusManager.power`）：≥70→×1.0，≥40→×0.8，≥20→×0.5，
  <20→×0.0
- **供水满足率**（`WaterSystemManager.get_oxygen_water_satisfaction()`，见第六节
  "水资源系统"）：0–1 之间，反映上一次 `WaterSystemManager.advance_water_time()`
  结算时制氧耗水有没有被完全满足；水完全够用时为 1.0（不节流），水完全不够时
  为 0.0（O₂ 产出侧完全归零，只剩人类呼吸的固定消耗）。`WaterSystemManager`
  不存在时默认 1.0（不影响旧行为）。
- 最后一株植物加成：`BaseStatusManager.last_plant_recovered_bonus_active`
  为真时 +0.002%/小时（AirSystemManager 不自己存这个 flag，直接读
  BaseStatusManager 的）

### 新增：向水系统报告耗水（`get_water_load()`）
制氧模块的每小时耗水，跟 `get_air_power_load()` 的"制氧耗电"共用同一个
`SUPPLY_TARGETS` 常量字典（新增了 `water_load` 键，`WaterSystemManager` 调用
这个方法读取，而不是自己再维护一份表）：
```
off 0 / eco 0.004 / standard 0.008 / rich 0.014 / emergency 0.030   (W/小时)
```

### CO₂ 每小时变化
```
co2_delta = (人类呼吸产生 + 过滤模块效果×电力倍率×空气循环倍率 + 最后一株植物吸收) × 小时数
```
- 人类呼吸产生：固定 +0.006%/小时
- CO₂过滤模块：OFFLINE 0.000 / CRITICAL −0.003 / BASIC −0.008 / STABLE −0.014
- 空气循环倍率（只乘在过滤效果上，不影响人类呼吸产生）：OFFLINE ×0.5 /
  CRITICAL ×0.75 / BASIC ×1.0 / STABLE ×1.15
- 最后一株植物吸收：植物恢复后 −0.001%/小时
- `co2_percent` 结果 clamp ≥0（没有理论上限，只有显示分段）

### 惰性气体每小时变化（v1 只接了密封泄漏 + 自动补压两件事）
```
密封档位（读 BaseStatusManager.seal_status）决定储备消耗速率：
  STABLE 0 / BASIC -0.01 / CRITICAL -0.04 / OFFLINE -0.12   (每小时)
```
当 `BaseStatusManager.pressure < 70` 且 `inert_gas_reserve > 0` 时自动补压：
```
本小时消耗储备 = min(剩余储备, 0.20 × 小时数)
舱压获得 = 消耗储备 × (0.15 / 0.20)
```
这两个 0.15 / 0.20 的具体数值是**本次实现自己定的 v1 占位值**（原始需求文档
把这个换算率留空，只说"可以自动补压"），系统设计如果要调整节奏，直接改
`AirSystemManager.gd` 里的 `REPRESSURIZE_PRESSURE_RATE` /
`REPRESSURIZE_RESERVE_COST` 两个常量即可，不用改结构。
气闸损失、事故排气第一版没有实现（没有对应的玩法交互）。

### O₂ 文案分段
20.0–22.0：氧气理想 / 19.5–19.9：氧气偏低 / 18.0–19.4：缺氧 /
16.0–17.9：严重缺氧 / <16.0：氧气危机 / >22.0：供氧过量

**没有富氧惩罚**：>22% 只有资源提示文案（"当前供氧高于生活需求，水电消耗
增加"），不影响精力消耗倍率、不扣心理、不加"火灾风险"。这是本系统的硬性
设计约束。

### CO₂ 文案分段
0.00–0.30：空气清洁 / 0.31–0.50：CO₂偏高 / 0.51–1.00：CO₂积累 /
1.01–3.00：CO₂危险 / 3.01–4.00：CO₂紧急 / >4.00：CO₂危机

### 惰性气体储备文案分段
70–100：缓冲气体充足 / 40–69：缓冲气体紧张 / 20–39：缓冲气体不足 /
0–19：缓冲气体危机

### 对健康系统"精力消耗倍率"的影响（`get_air_energy_multiplier()`）
```
O2 倍率 × CO2 倍率
O2 倍率：≥19.5→×1.0；18.0–19.4→×1.2；16.0–17.9→×1.35；<16.0→×1.5
CO2 倍率：≤0.50→×1.0；0.51–1.00→×1.1；1.01–3.00→×1.2；>3.00→×1.4
```
高氧（>22%）不进入这个计算，永远不会推高倍率。

### 对健康系统"心理"的影响（每小时，累加成一次 `morale` 调整，与
BaseStatusManager 自己的心理效果是两次独立的 `adjust_stat` 调用）
```
O2 18.0–19.4：−0.02/小时；16.0–17.9：−0.05/小时；<16.0：−0.10/小时
CO2 0.51–1.00：−0.02/小时；1.01–3.00：−0.05/小时；>3.00：−0.10/小时
```
O2 >22% 不扣心理。

### 维修行动（只改档位 + 一次性数值，不推进时间）

| 维修 | 档位变化 | 一次性数值 |
|---|---|---|
| 制氧模块轻维修 | CRITICAL→BASIC | O₂ +0.4% |
| 制氧模块重维修 | BASIC→STABLE | O₂ +0.6% |
| CO₂过滤轻维修 | CRITICAL→BASIC | CO₂ −0.10%（clamp ≥0） |
| CO₂过滤重维修 | BASIC→STABLE | CO₂ −0.15%（clamp ≥0） |
| 空气循环轻维修 | CRITICAL→BASIC | 无一次性数值，只跳档 |
| 空气循环重维修 | BASIC→STABLE | 无一次性数值，只跳档 |

一次性数值是**本次新增的 v1 占位值**（原始需求文档没有给这部分具体数字，
只给了氧气发生器/CO₂过滤器的每小时速率），系统设计如果要重新平衡这几个
一次性维修量，直接改对应 `repair_*` 方法即可。目前旧基地场景里
`MinimalLifeSupportStable` 这个既有交互点触发的是
`repair_oxygen_generator_light()`；CO₂过滤、空气循环都只有 Debug 按钮，
没有场景交互入口。

### 供氧目标档位（`supply_target_mode`）
```
off 关闭 / eco 节能(目标21% 中的19.8) / standard 标准(21.0，默认) /
rich 充足(22.5) / emergency 应急(24.0)
```
**电力系统改造后这个字段已经不再是纯预留**——它现在直接决定制氧模块向
`PowerSystemManager` 报告的耗电量（见下方"向电力系统报告耗电"），是"油门"，跟
`oxygen_generator_status`（设备健康档位，决定实际产出速率）是两个独立维度：
```
off 0 / eco 0.03 / standard 0.06 / rich 0.10 / emergency 0.18   (E/小时)
```
仍然**不影响 O₂ 产出速率本身**（那仍然只看 `oxygen_generator_status`），也
还没接水消耗——按需求文档"如果尚未实现真实水资源，先只增加电力压力"的说明，
目前只接了电力这一半。

### 新增：向电力系统报告耗电（`get_air_power_load()`）
三个空气设备各自的每小时耗电，加总后报给 `PowerSystemManager`：
```
制氧模块：由 supply_target_mode 决定（见上）
CO₂过滤模块（按 co2_filter_status）：OFFLINE 0 / CRITICAL 0.03 / BASIC 0.06 / STABLE 0.10
空气循环系统（按 air_circulation_status）：OFFLINE 0 / CRITICAL 0.02 / BASIC 0.04 / STABLE 0.07
```

### 专业提示（只读教育背景，不加数值，四选一互斥）
- 医学：CO₂>0.50% 且 O₂≥19.5% → 提示"CO₂超标，睡眠恢复受影响"；O₂<19.5%
  或 CO₂>0.50% → 提示"低氧和CO₂积累都增加精力消耗，建议先判断该睡觉/补氧/
  处理过滤"
- 机械工程：电力<70 且 三个空气设备任一非 STABLE → 提示"效率下降主因是供电
  不足"；否则任一非 STABLE → 提示"设备尚未全部稳定，建议逐一恢复"
- 材料科学：舱压<80 或 密封非 STABLE 或 惰性气体储备<70 → 提示"空气异常可能
  是密封泄漏导致惰性气体持续损失"
- 植物科学：**无条件**显示"当前植物规模只能提供微弱缓冲，不能替代CO₂过滤
  模块"（这是唯一一个不做条件判断、总是显示的专业提示，因为它是一个恒定
  事实而不是"当前是否异常"的诊断）

### 存档
`user://saves/air_system_state.json`：`o2_percent / co2_percent /
inert_gas_reserve / oxygen_generator_status / co2_filter_status /
air_circulation_status / supply_target_mode`。（`inert_gas_percent` 不单独
存，反序列化后会从 o2/co2 重新算。）

### UI / Debug
`scripts/ui/air_system_panel.gd`，旧基地场景里用 `O` 键开关（Tab=基地状态，
G=植物面板仅温室场景生效，O=空气面板/P=电力面板不限场景）。Debug 菜单：
O₂/CO₂/惰性气体储备加减、三个设备档位循环、供氧目标档位循环、重置 Day 01、
设为最低稳定状态。新增 `debug_set_supply_target(mode_id)`（直接设置，供
`PowerSystemManager.debug_set_power_mode()` 的"一键预设"调用，循环按钮
`debug_cycle_supply_target()` 还在，两者并存）。

---

## 五、电力系统 PowerSystemManager（新拆分出来的系统）

### 定位
太阳能板/电池/负载/科技效率的完整电力模型，取代原本 `BaseStatusManager`
里那个"0–100 抽象电力值 + 供电档位速率表"的简化实现。**不做真实瓦特/千瓦时
仿真**，统一用游戏抽象单位 `E`。结算完成后把百分比写回
`BaseStatusManager.power`（兼容旧读者），自己不再由 BaseStatusManager 反向
驱动。

### 核心变量与抵达初始值

| 变量 | 初始值 | 说明 |
|---|---|---|
| `current_energy` 当前电量 | 50.0 E | |
| `battery_module_count` 电池模块数 | 2 | 每个模块 60 E |
| `base_battery_capacity` 基础容量 | 120.0 E（= `battery_module_count × 60`，跟着模块数联动重算） | |
| `storage_efficiency` 储能效率 | 1.0 | 科技档位，只影响容量上限 |
| `battery_capacity` 实际容量 | 120.0 E（= `base_battery_capacity × storage_efficiency`） | |
| `solar_panel_count` 太阳能板数 | 2 | |
| `solar_array_status` 太阳能阵列状态 | CRITICAL（AirSystemManager 同款本地
  `SystemStatus` 枚举，跟 BaseStatusManager 的枚举不共享脚本引用） | 只影响
  发电速度，不影响容量 |
| `charging_efficiency` 充电效率 | 1.0 | 科技档位，只影响太阳能转化效率 |
| `current_power_mode` 当前电力模式 | "standard" | 纯描述性字段，记录最近一次
  应用的"推荐电力模式"预设，见下 |

`power_percent = current_energy / battery_capacity × 100`，抵达时
`50/120 ≈ 41.67%`，这就是 `BaseStatusManager.power` 现在的实际来源（不再是
硬编码的 42，`TimeManager.reset_to_arrival()` 里特意让 BaseStatusManager 先
重置成旧的 42、PowerSystemManager 再重置并覆写成精确的 41.67，两者可能有
±1 的肉眼差异，是设计上认可的近似）。

### 电池容量设计
```
battery_capacity = battery_module_count × 60.0 × storage_efficiency
```
加电池模块或升级储能效率**只提高上限，绝不给当前电量凭空充电**（`current_energy`
在这两个操作后原样保留，只做防溢出 clamp）。

### 太阳能发电
```
solar_generation =（仅月昼，月夜/月夜末期恒为 0）
    solar_panel_count × 0.35 × 太阳能阵列倍率 × charging_efficiency
```
太阳能阵列倍率：OFFLINE ×0.00 / CRITICAL ×0.35 / BASIC ×0.70 / STABLE ×1.00

### 每小时结算
```
hours = minutes / 60.0
current_energy += (solar_generation - power_load) × hours     # 月昼
current_energy -= power_load × hours                          # 月夜/月夜末期
current_energy = clamp(current_energy, 0.0, battery_capacity)
power_percent = current_energy / battery_capacity × 100.0
BaseStatusManager.power = power_percent                        # 兼容同步
```

### 当前负载（`power_load`，每小时汇总，由各系统自行报告）
```
power_load = 0.03（基地最低运行，PowerSystemManager 自己的固定项）
           + AirSystemManager.get_air_power_load()             # 制氧+CO2过滤+空气循环
           + BaseStatusManager.get_thermal_power_load()        # 温控
           + PlantGrowthManager.get_greenhouse_light_power_load()  # 夜间补光，月昼恒为 0
           + WaterSystemManager.get_water_power_load()         # 水循环运行耗电（见第六节）
```
补光耗电用的是`greenhouse_light_system_level`这个"目标档位"本身，不是被电力
拉低后的"实际有效光照等级"——即使电力不够导致补光效果打折，耗电仍按目标档位
计算（"设备在努力尝试达到这个等级，即使打了折扣依然在耗电"）。
`PlantGrowthManager.greenhouse_zone_count`（默认 1，预留字段，无扩建 UI）会
乘进补光耗电总量，为未来温室扩建预留。

### 一次性行动耗电（`apply_action_cost()`，跟 HealthManager 的行动结算同一批
reason 字符串，与"持续耗电"完全独立）
```
发送报告 0.5 / 短娱乐 0.8 / 长娱乐 1.5 / 轻维修 0.3 / 重维修 0.8 /
整理物资 0.1 / 植物诊断 0.1 / 短外出采集 0.5 / 长外出采集 1.0    (E)
```

### 新增：通用扣电接口（`consume_energy(amount)`）
供跨系统的"变动量事先算不出来、不是固定 lookup 表"的场景调用，目前唯一的
调用方是 `WaterSystemManager.process_ice()`（冰处理耗电，金额取决于处理了
多少冰）。跟已有的 `debug_adjust_energy()` 行为完全一样（clamp + 同步
`BaseStatusManager.power`），只是换了个不带"debug_"前缀的名字给正式玩法
代码调用，语义上更清楚。

### 科技效率档位（Debug 循环切换，`debug_cycle_storage_efficiency()` /
`debug_cycle_charging_efficiency()`）
```
储能效率：1.0(基础储能) → 1.15(改良电池管理) → 1.30(高密度储能模块)
        → 1.50(月面低温储能优化) → 1.80(先进储能网络) → 循环回 1.0
充电效率：1.0(基础充电控制) → 1.15(太阳能追踪算法) → 1.25(月尘清洁涂层)
        → 1.40(高效功率调节器) → 1.60(先进太阳能阵列管理) → 循环回 1.0
```

### 电量百分比文案分段（`get_power_label()`，比 BaseStatusManager 自己的旧
4 档文案更细，`70–100`那一档定义相同）
```
70–100：供电稳定 / 40–69：供电紧张 / 20–39：低电力 /
5–19：电力危机 / 0–4：断电边缘
```
（`BaseStatusManager.get_power_label()` 本身没有跟着改成 5 档，两处文案现在
不完全一致，见第九节。）

### 低电量提醒（面板文本追加，不阻塞任何行动，不会强制 Game Over）
- `power_percent < 20%` 且（供氧目标=应急 或 温控=STABLE 或 补光等级≥4）→
  追加"电量偏低，仍在运行高耗电设置"警告。
- `power_percent < 5%` → 追加"建议切换到最低维持模式"提醒。
- 电量为 0 时"温控/制氧/CO₂过滤/补光全部停止"这条效果**不需要专门代码**——
  BaseStatusManager/AirSystemManager 自己现有的"电力<20 时效果打折或归零"
  倍率表在 `power_percent=0` 时已经自然打到最低，这里只是复用既有机制，没有
  新增强制关闭逻辑。

### "推荐电力模式"预设（`debug_set_power_mode(mode_id)`，Debug 菜单四个按钮）
```
extreme_saving 极限省电：AirSystemManager 供氧目标→eco，温室补光等级→0
standard 标准维持：供氧目标→standard，补光等级→0
standard_night_light 标准维持+夜间2级补光：供氧目标→standard，补光等级→2
high_load_greenhouse 高负载温室：供氧目标→rich，补光等级→4
```
只调这两个"可以直接拨动的旋钮"（供氧目标 + 补光等级）；温控/CO₂过滤/空气
循环都是维修驱动的设备档位，不属于"模式切换"能碰的范围，预设不touch它们。

### 净变化 / 预计充满 / 预计耗尽（面板文本，`panel_status_text()`）
```
净变化 = solar_generation - power_load
预计充满 =（净变化>0 且未满时）(battery_capacity - current_energy) / 净变化，小时数向上取整后转"天+小时"
预计耗尽 =（净变化<0 且电量>0时）current_energy / |净变化|，同样格式
```

### 专业提示（只读教育背景，不加数值，四选一互斥）
- 机械工程：白昼下电量已经顶满（发电溢出）→ 建议扩容电池；电池容量≥180 且
  太阳能阵列非 STABLE → 建议修阵列
- 材料科学：太阳能阵列非 STABLE → 提示月尘/老化导致输出低于理论值
- 医学：电量<40% → 提示省电模式会降低温控/空气处理能力，增加精力消耗
- 植物科学：夜间且补光等级≥3 且按当前净变化预计撑不到 240 小时（10 天）就
  耗尽 → 点名小麦/番茄可能光照不足

### 存档
`user://saves/power_system_state.json`：`current_energy /
base_battery_capacity / battery_capacity / battery_module_count /
solar_panel_count / solar_array_status / storage_efficiency /
charging_efficiency / current_power_mode`。

### UI / Debug
`scripts/ui/power_system_panel.gd`，`P` 键开关，位置在温室面板同一行、空气
面板正下方（(740,500)，跟 (1170,500) 的植物面板对称）。Debug 菜单：电量
加减、加太阳能板/加电池模块（各一个"+1"按钮而非任意数量输入框）、太阳能
阵列档位循环、储能/充电效率循环、四个电力模式预设按钮、重置 Day 01、设为
最低稳定状态（4 电池模块/240 E 容量/220 E 电量/4 块 STABLE 太阳能板——落在
"月昼结束电量：200–240 E"目标区间）。

---

## 六、水资源系统 WaterSystemManager（新拆分出来的系统）

### 定位
基地里两种资源——可用水（`current_water`，能直接用）和月球冰（`current_ice`，
要处理才能用）——的库存、上限、冰处理、水循环回收。**不做真实水分子循环**，
核心是制造"水要留给人还是植物、留给植物还是制氧"的取舍。**水不会凭空恢复**：
只能靠外部采集系统调 `add_ice()`/`add_water()`，或靠冰处理 `process_ice()`
转化；水循环只降低净消耗，不产生新水。

### 核心变量与抵达初始值

| 变量 | 初始值 | 说明 |
|---|---|---|
| `current_water` 当前可用水 | 42.0 W | |
| `water_capacity` 可用水上限 | 80.0 W（= `water_tank_module_count × 40`） | |
| `water_tank_module_count` 水箱模块数 | 2 | 每模块 +40 W |
| `current_ice` 当前月球冰 | 0.0 I | |
| `ice_capacity` 冰仓上限 | 120.0 I（= `ice_storage_module_count × 60`） | |
| `ice_storage_module_count` 冰仓模块数 | 2 | 每模块 +60 I |
| `water_recycling_level` 水循环等级 | 1（0–4） | 决定基础回收率，见下 |
| `water_recycling_efficiency` 水循环效率 | 1.0 | 科技倍率，乘在基础回收率上 |
| `ice_processing_efficiency` 冰处理效率 | 1.0 | 科技倍率，**只降低处理耗电，不提高
  水产出比例**（1 I 恒等于 1 W，故意不做"凭空造水"） |

加水箱/冰仓模块**只提高对应上限，不凭空增加当前存量**（跟电池模块的规则
完全一致）。

### 冰处理（`process_ice(requested_amount) -> float`，on-demand 动作，**不是
每小时自动结算的一部分**——需求文档没给处理动作本身的时间成本，这里也没有
调用 `TimeManager`，跟 BaseStatusManager/AirSystemManager 的 `repair_*()`
一样，是纯粹的状态变更方法，等后续场景交互接上时由调用方自己决定要不要花
时间）
```
1 I → 1 W（ICE_TO_WATER_RATIO 恒为 1.0）
处理 1 I 耗电 = 0.05 E / ice_processing_efficiency
可处理量 = min(请求量, 当前冰量, 水箱剩余空间, 当前电力可负担的量)
```
消耗的电力通过 `PowerSystemManager.consume_energy()`（新增的通用扣电接口，
见第五节）直接扣，不经过 `apply_action_cost()` 的固定 lookup 表，因为处理量
是变动的。

### 水循环回收率
```
基础回收率：0级 0% / 1级 15% / 2级 30% / 3级 45% / 4级 60%
实际回收率 = min(基础回收率 × water_recycling_efficiency, 0.80)   # 硬上限 80%
```
可回收耗水（生活用水、植物供水）的**实际扣款** = 需求量 × (1 − 实际回收率)；
不可回收耗水（制氧）全额扣款，不打折。数学上"每笔单独打折"和需求文档举例
里"每日汇总后一次性打折"是等价的（回收率是线性乘数，可以分配律拆开），
所以实现上没有做"日终批量结算"，每次扣款当场按当前回收率打折，效果相同。

### 水循环耗电（`get_water_power_load()`，供 PowerSystemManager 汇总负载）
```
0级 0 / 1级 0.02 / 2级 0.04 / 3级 0.07 / 4级 0.11   (E/小时)
```

### 每小时结算（`advance_water_time()`，在 PowerSystemManager 之后、
BaseStatusManager 之前运行，这样 AirSystemManager 稍后读到的"供水满足率"
是这一 tick 刚算好的）
- **基础生活用水**：0.025 W/小时（= 0.6 W/天），可回收。连续 24 小时以上
  拿不到足额生活用水时，每小时追加 `HealthManager.adjust_stat("morale",
  -2.0/24.0)`（等效"缺水超过一天，心理每天 -2"，只要缺水持续就一直扣，不是
  只扣一次）。
- **制氧耗水**：读 `AirSystemManager.get_water_load()`（0/0.004/0.008/0.014/
  0.030 W/小时，按供氧目标档位），**不可回收**。满足不了全部需求时只扣走
  实际可用的部分，并记录"供水满足率" = 实际扣款 / 需求量（0–1），提供给
  AirSystemManager 节流 O₂ 产出（见第四节）。

### 一次性行动耗水（`apply_action_cost()`，可回收，跟 HealthManager/
PowerSystemManager 的行动结算同一批 reason 字符串；**不会阻塞 `eat`/
`nutrition_drink` 这两个健康行动本身**——水不够时只是尽力打折扣款到 0，
不会让玩家"喝不了营养液"，需求文档里"营养液不可用"这条硬门槛本次没做，
见第九节已知问题）
```
进食 eat：0.10 W
营养液 nutrition_drink：0.20 W
```

### 植物供水（不在上面的"每小时结算"里，而是挂在 PlantGrowthManager 自己的
每日结算循环上——见第七节"环境输入"）
```
每株作物每日需水 = water_requirement（0–4） × 0.35 W
```
`PlantGrowthManager._water_ok(crop)` 现在是**纯 peek**（只读
`can_supply_plant_water()`，检查折扣后的实际成本够不够，不消耗任何水，UI/
专业提示可以随便调用不会有副作用）；真正的每日一次真实扣款走
`WaterSystemManager.consume_plant_water(amount) -> bool`，只在
`PlantGrowthManager._process_daily_growth_for_slot()` 里调用一次，返回值
直接决定这一天"水"这一项打分是否达标。`PlantGrowthManager.water_cycle_level`
这个旧字段**现在是纯装饰性的**（跟 BaseStatusManager.power_system_status
同一处境）——只在 WaterSystemManager 缺失时当兜底判断用，正常情况下完全
不参与植物的水条件判断。

### 电量/水量文案分段
```
70–100%：水储备稳定 / 40–69%：水储备紧张 / 20–39%：低水量 /
5–19%：水危机 / 0–4%：水耗尽边缘
```
`water_percent < 20%` 时面板追加强提醒；`< 5%` 时追加"建议切换节水模式"。
**水量为 0 不会强制 Game Over**，也没有专门写"强制关闭设备"的代码——制氧
产出的节流完全靠上面的"供水满足率"机制自然发生。

### 面板文本（`panel_status_text()`）显示的"今日预计耗水/净耗水/预计耗尽"
是纯展示用的预测，不消耗任何东西：
```
今日预计耗水 = 生活用水×24 + 制氧耗水×24 + PlantGrowthManager.get_daily_water_demand()
预计净耗水 = 可回收部分×(1-实际回收率) + 不可回收部分（制氧）
预计耗尽 = 当前水量 / 预计净耗水，取整天数
```

### 专业提示（只读教育背景，不加数值，四选一互斥）
- 植物科学：水量<40% 且已种了水需求≥3 的作物（番茄）→ 提示"不建议继续种
  番茄"；否则水循环等级≤1 → 提示"生菜/小麦能撑，番茄会成为主要耗水点"
- 机械工程：水循环等级≥3 且电力<40% → 提示"降至基础回收"；有冰但水箱有
  空间且电力<20% → 提示"瓶颈是冰处理耗电，不是水量"
- 材料科学：水量<70% 或冰仓不足 70% 满 → 提示"水箱老化/冰仓隔热影响处理
  效率"（第一版只做文案，没有真实损耗机制）
- 医学：水量<40% → 提示"营养液调配受影响，不建议高消耗外出"

### 存档
`user://saves/water_system_state.json`：`current_water / water_capacity /
water_tank_module_count / current_ice / ice_capacity /
ice_storage_module_count / water_recycling_level /
water_recycling_efficiency / ice_processing_efficiency`。（供水满足率、
生活用水缺水计时是运行时派生值，不落盘，读档后重新从 0 开始计。）

### UI / Debug
`scripts/ui/water_system_panel.gd`，`I` 键开关。因为屏幕右侧已经被
Base(Tab)/Plant(G)/Air(O)/Power(P) 占满 2×2 网格，水面板做窄了一些
（330 宽而不是 420），塞进 HUD 安全区和空气面板之间的空隙
（`Vector2(400, 180)`）。Debug 菜单：可用水/月球冰加减、加水箱模块/加冰仓
模块、水循环等级循环、"处理 20 冰"（对应需求文档自己的算例）、"处理全部
冰"、重置 Day 01、设为最低稳定状态（3 水箱/3 冰仓模块、100 W/60 I、
水循环等级 2）。

---

## 七、植物生长系统 PlantGrowthManager

### 定位
多地块（`slot_id: String` → 植物实例的 `Dictionary`）的作物生长系统，**每满
1440 累计游戏分钟才结算一次**（不是实时/不是每帧），由
`TimeManager.advance_time()` 驱动累加分钟数。跟旧的"最后一株植物"叙事系统
（在 `sprint06_base_scene.gd` 里）完全独立，没有互相引用。

### 环境输入（三项，每项只看"够不够"，从不判断"过量"）
- **水**：**已经从"本系统独立抽象"改为真实资源**（水资源系统实现完成后）。
  `_water_ok(crop)` 现在是纯 peek，调用
  `WaterSystemManager.can_supply_plant_water(需求量)`；每日真正的扣款走
  `WaterSystemManager.consume_plant_water(需求量)`，需求量 =
  `water_requirement（0–4） × 0.35 W`。旧字段 `water_cycle_level`
  （0–4，默认 1，Debug 仍可调）**现在纯装饰**，只在 WaterSystemManager 缺失
  时当兜底判断用，正常情况下不参与水条件判断——详见第六节"水资源系统"。
- **光照等级**：
  - 月昼：恒定 4，不耗电。
  - 月夜：`greenhouse_light_system_level`（0–4，默认 1，Debug 可调）
    再按 `BaseStatusManager.power` 衰减：
    电力≥70 不衰减；40–69 −1；20–39 −2；<20 强制 `min(等级, 1)`。
    最终 clamp 到 0–4。
- **温度**：直接读 `BaseStatusManager.temperature`，没有温室独立温度。

### 新增：向电力系统报告耗电（`get_greenhouse_light_power_load()`）
月昼恒为 0（自然光免费）；月夜按`greenhouse_light_system_level`**这个目标
档位本身**（不是被电力衰减后的"有效光照等级"）计算，再乘
`greenhouse_zone_count`（默认 1，预留字段，未来温室扩建用，目前没有扩建
UI）：
```
0 级 0.00 / 1 级 0.04 / 2 级 0.08 / 3 级 0.14 / 4 级 0.22   (E/小时/区)
```

### 新增：向水系统报告需水量（供 WaterSystemManager 的展示/专业提示用，
两者都是纯查询，不消耗任何东西）
```
get_daily_water_demand() -> float
  # 当前所有存活、未收获植物的每日需水总和，用于水面板"今日预计耗水"
get_highest_planted_water_requirement() -> int
  # 当前所有存活、未收获植物里最高的 water_requirement 档位（0-4），
  # 供水系统的植物科学专业提示判断"番茄还在不在场"
```

### 五种作物数值（`scripts/data/PlantCropData.gd`）

| 作物 | 生长天数 | 水需求(0-4) | 光需求(0-4) | 适宜温度 | 收获饱腹 | 收获营养 | 收获心理 | 可再收获 |
|---|---|---|---|---|---|---|---|---|
| 生菜 lettuce | 3 | 1 | 2 | 16–24℃ | +18 | +8 | +6 | 否 |
| 土豆 potato | 6 | 2 | 2 | 14–24℃ | +45 | +10 | +3 | 否 |
| 小麦 wheat | 8 | 1 | 4 | 15–26℃ | +35 | +8 | +2 | 否 |
| 番茄 tomato | 7 | 3 | 4 | 18–26℃ | +22 | +18 | +10 | 是，成熟后每 3 天可再收获，最多额外收获 3 次 |
| 大豆 soybean | 9 | 2 | 3 | 18–27℃ | +30 | +30 | +4 | 否 |

收获对应的物品 ID（`harvest_item_id`，见第八节 ItemDatabase）：生菜→`FO-CR-001`
/ 土豆→`FO-CR-002` / 小麦→`FO-CR-003` / 番茄→`FO-CR-004` / 大豆→`FO-CR-005`。
上表里"收获饱腹/收获营养/收获心理"三列现在只是这几个食物条目 `effects`
数值的历史出处标注，`harvest()` 本身不再读这三列。

### 每日结算规则
水/光/温度各自"达标"记 1 分（`water_cycle_level ≥ 需求` / `有效光照 ≥ 需求` /
`min_temperature ≤ 温度 ≤ max_temperature`），总分 0–3：

| 总分 | 生长进度 `growth_progress_days` | 压力 `stress` |
|---|---|---|
| 3（全满足） | +1.0 天 | −1 |
| 2 | +0.5 天 | 不变 |
| 1 | +0 | +1 |
| 0 | +0 | +2 |

`stress` clamp ≥0。健康状态由 `stress` 映射：0–1 Healthy / 2–3 Stressed /
4–5 Withering / ≥6 Dead。**Dead 后彻底停止生长，不再结算**。

**光照高于需求不会有任何惩罚**——系统只判断"够不够"，没有"光照过强"逻辑，
这是本系统的一条硬性设计约束（新设计不应该加）。

### 成熟与收获
`growth_progress_days ≥ growth_days` → 阶段变为 `Mature`（可收获）。

**收获不再直接回血**（物品系统实现完成后的改动）：收获只调用
`InventoryManager.add_item(harvest_item_id, 1)` 把对应食物加进库存，
`harvest_fullness/harvest_nutrition/harvest_morale` 三个旧字段还留在
`PlantCropData.gd` 里但 `harvest()` 已经不读它们了——`ItemDatabase.gd` 里
对应食物条目的 `effects` 字典是这三个数字的新家（两处数值故意保持一致，
但概念上已经分开：前者是"这株作物收获时长什么样"，后者是"吃这个食物能补多少"）。
玩家必须再调用 `InventoryManager.eat_item(harvest_item_id)` 才会真正加健康值，
详见第八节。

番茄（`repeat_harvest = true`）收获后，若额外收获次数 `extra_harvests_used <
3`：进度清零、重新进入 3 天的"再收获周期"（`is_reharvest_cycle = true`，这
时候成熟目标不再是 7 天而是 3 天）；用满 3 次后终结为 `Harvested`。其余四种
作物收获一次即终结为 `Harvested`。

### 生长阶段字符串
`Seed 种子` → `Sprout 幼苗`（进度<25% 目标） → `Growing 生长期`（≥25%）→
`Mature 成熟可收获` → `Harvested 已收获` / `Dead 枯死`（终态，不可逆）。

### 专业提示（仅"植物科学"背景，不加数值）
只判断玩家自己聚焦地块（`last_sown_slot_id`）的水/光/温度是否达标，输出类似：
- 三项全满足：`水循环、光照与温度均满足当前作物需求。`（若光照超出需求，追加
  `当前光照等级高于作物需求，不会造成额外风险。`）
- 只有光照不足：指出"当前问题来自光照不足"，并给出基于当前分数的"预计 N 天
  内成熟"估算（分数 3→1.0 天/天，分数 2→0.5 天/天，分数 0/1→"生长停滞，无法
  预计"）。
- 光照超出需求但其他项不满足：明确说"不会造成额外风险"，再指出真正的限制
  因素（水循环 / 温度偏低 / 温度偏高）。

### Debug 支持
播种五种作物、循环水循环等级(0→1→2→3→4→0)、循环补光等级(同)、强制成熟当前
地块、收获当前地块、清空所有地块；"推进植物生长 1/3 天"直接复用
`TimeManager.advance_time(1440/4320, ...)`（会连带结算基地状态和健康），
"切换月昼/月夜"复用已有的 Time Debug 跳转按钮，"设置基地温度"复用已有的
Base Debug 温度按钮。

### 存档
`user://saves/plant_growth_state.json`：`accumulated_growth_minutes /
water_cycle_level / greenhouse_light_system_level / last_sown_slot_id /
plants`（`plants` 是 slot_id → 植物实例的完整字典，每个实例含
`crop_id / growth_progress_days / stress / stage / health_state /
extra_harvests_used / is_reharvest_cycle / total_harvest_count / last_score`）。

---

## 八、物品系统 ItemDatabase / InventoryManager（新拆分出来的系统）

### 定位
库存持有——玩家身上/基地里到底有什么东西、能不能吃/用/耐久还剩多少——跟
"这个数值本身怎么结算"完全分开管理。**不挂在 `TimeManager.advance_time()`
的每小时结算链上**，纯粹被动响应"加入/移除/吃/用"这几个动作，本身没有
"每小时变化率"。**第一版明确不做**：背包容量/负重、网格式摆放、装备栏、
物品腐坏/过期、品质分档/随机词缀、复杂合成、工具维修、批量烹饪、玩家间
交易——这些都不在本轮范围内，见文件末尾"尚未覆盖"清单。

### 两套存储结构
```
stack_items: Dictionary        # item_id (String) -> 数量 (int)
durable_items: Dictionary      # instance_id (String) -> {item_id, current_durability,
                                #   max_durability, state}
```
可堆叠物品用 `item_id` 直接记数量；**有耐久度的物品必须走 `durable_items`**，
因为两把外观相同的钻具耐久可能不一样，不能合并成一个数字——`add_item()`
会直接拒绝 `has_durability = true` 的物品，只能通过 `add_durable_item()`
加入。`instance_id` 格式 `"tool_%04d"`（如 `tool_0001`），从 1 自增。

### item_id 命名格式
`<大类前缀>-<子类前缀>-<编号>`，如 `FO-CR-001`（食物-作物-001）。大类前缀：
`FO` 食物 / `SD` 种子 / `CN` 消耗品 / `MT` 材料 / `TL` 工具 / `RS` 系统资源
（`CP` 部件 / `SP` 样本 / `QI` 任务物品是预留前缀，第一版没有实际条目）。

### 完整物品清单（`scripts/data/ItemDatabase.gd`，`const ITEMS`，共 33 条）

**食物 FOOD（5 种，对应五种作物收获，`can_eat=true`，`use_time_minutes=30`）**

| item_id | 名称 | effects（fullness/nutrition/morale） |
|---|---|---|
| FO-CR-001 | 生菜 | +18 / +8 / +6 |
| FO-CR-002 | 土豆 | +45 / +10 / +3 |
| FO-CR-003 | 小麦 | +35 / +8 / +2 |
| FO-CR-004 | 番茄 | +22 / +18 / +10 |
| FO-CR-005 | 大豆 | +30 / +30 / +4 |

（跟第七节作物表里的"收获饱腹/营养/心理"三列数值完全一致，是同一组数字
在两个文件里的两份记录——`PlantCropData.gd` 那三列现在只是历史出处标注，
真正生效的是这里的 `effects`。）

**种子 SEED（5 种，对应五种作物，`can_eat=false`，`effects={}`，第一版播种
不强制消耗种子，数据先留着）**：SD-CR-001 生菜种子 / SD-CR-002 土豆种薯 /
SD-CR-003 小麦种子 / SD-CR-004 番茄种子 / SD-CR-005 大豆种子。

**消耗品 CONSUMABLE（5 种）**

| item_id | 名称 | can_eat | effects | use_time | 备注 |
|---|---|---|---|---|---|
| CN-FD-001 | 压缩食物 | 是 | fullness+35/nutrition+5/morale−1 | 30 | 应急口粮，心理是负的 |
| CN-FD-002 | 营养液包 | 是 | fullness+5/nutrition+25/morale−1 | 15 | 对应旧 `nutrition_drink` |
| CN-MD-001 | 医疗包 | 否 | `{}` | 15 | 医疗系统预留，暂无效果 |
| CN-OX-001 | 应急氧气瓶 | 否 | `{}` | 5 | 空气系统补氧预留，暂无效果 |
| CN-IG-001 | 小型惰性气体罐 | 否 | `{}` | 5 | 空气系统预留，暂无效果 |

**材料 MATERIAL（6 种，全部 `can_use=false`，第一版没有任何系统真正读取
它们，纯库存占位，供未来维修/建造消耗）**：MT-ME-001 金属碎片 / MT-EL-001
电子零件 / MT-SE-001 密封材料 / MT-FI-001 过滤材料 / MT-IN-001 绝缘材料 /
MT-GL-001 温室基质。

**工具 TOOL（6 种，两个子类）**
- `subcategory="default"`（宇航服自带，**不进入库存**，`storage_type="default"`）：
  TL-EX-001 基础采集工具 / TL-SC-001 手持扫描仪。
- `subcategory="durable"`（真正进 `durable_items`，`use_model="durable"`，
  必须走 `add_durable_item()`/`use_durable_item()`）：

| item_id | 名称 | max_durability | 每次耗损 | broken_when_zero |
|---|---|---|---|---|
| TL-EX-002 | 便携钻具 | 100 | 10 | 是 |
| TL-RP-001 | 密封修补枪 | 60 | 10 | 是 |
| TL-RP-002 | 切割工具 | 80 | 8 | 是 |
| TL-BT-001 | 便携电池包 | 100 | 15 | 是（电力系统外出供电预留，暂无效果） |

**系统资源 ID RS（6 种，`category="resource"`，`storage_type="system"`，
**从不通过 InventoryManager 增删**，纯粹是给"其他系统自己的真实数值"起
一个统一命名，方便未来 UI/交易/合成系统按 `item_id` 引用而不用关心它到底
存在哪个 Manager 里）**：RS-IC-001 月球冰→`WaterSystemManager.current_ice`
/ RS-WA-001 可用水→`WaterSystemManager.current_water` / RS-EN-001 电力→
`PowerSystemManager.current_energy` / RS-OX-001 氧气→
`AirSystemManager.o2_percent` / RS-CO-001 二氧化碳→
`AirSystemManager.co2_percent` / RS-IG-001 惰性缓冲气体→
`AirSystemManager.inert_gas_reserve`。

### 吃/用流程（避免"双重回血"的关键设计）
```
eat_item(item_id) -> bool     # 仅 can_eat=true 的物品
  1. 校验 can_eat + 库存足够
  2. remove_item(item_id, 1)
  3. TimeManager.advance_time(use_time_minutes, "eat_item")
  4. HealthManager.apply_item_effects(item.effects)

use_item(item_id) -> bool     # can_use=true 且 use_model != "durable" 的物品
  1. 校验 can_use + use_model 不是 durable + 库存足够
  2. 若 consumable=true 才 remove_item(item_id, 1)（种子/消耗品会被消耗，
     未来非消耗性道具可以 consumable=false 保留在库存里）
  3. TimeManager.advance_time(use_time_minutes, "use_item")
  4. HealthManager.apply_item_effects(item.effects)
```
**关键点：`eat_item`/`use_item` 推进时间用的 reason 字符串是 `"eat_item"`/
`"use_item"`，跟 `HealthManager.apply_action_cost()`/
`WaterSystemManager.apply_action_cost()` 里原有的固定档 `"eat"`/
`"nutrition_drink"` case 完全不匹配**——这是故意的，为了不触发旧的固定
回血/耗水逻辑造成"吃一次加两次血"。`HealthManager.apply_item_effects(effects)`
是本次新增的方法，内部就是对 `effects` 字典逐项调用已有的
`adjust_stat()`，本身不做任何 clamp/存档之外的特殊逻辑，回血走的还是
统一入口。

`WaterSystemManager._action_water_cost()` 新增了 `"eat_item"` 这个 case，
金额沿用旧的 `EAT_WATER_COST`（跟原来的 `"eat"` 一样），这是刻意的
简化决定：不管吃的是收获来的新鲜食物还是营养液包（`CN-FD-002`），
统一按普通进食耗水计算，**没有对营养液包单独区分更低/更高的耗水量**，
详见第九节已知问题。旧的 `HealthManager.apply_action_cost()` 里
`"eat"`/`"nutrition_drink"` 两个固定 case、以及 `TimeManager` 行动耗时表
里的 `eat`/`nutrition_drink` 两个 30/15 分钟行动**原样保留、完全没有
删除**——它们是独立于物品系统之外的老机制（不需要库存、无限次可用，
第九节已知问题里提到过的"没有食物库存"技术债），跟新的 `eat_item()` 流程
并存，是两条互不干扰的路径。

### 耐久工具流程
```
add_durable_item(item_id) -> String        # 返回新 instance_id，非耐久物品返回 ""
use_durable_item(instance_id) -> bool      # 扣 durability_loss_per_use，
                                            # 归零且 broken_when_zero 时 state="broken"
repair_durable_item(instance_id, amount)   # 耐久 clamp 到 [0, max]，>0 时状态改回 normal
get_durable_item_state(instance_id) -> Dictionary
```
已损坏（`state="broken"`）的实例调用 `use_durable_item()` 直接返回
`false`，不会进一步扣到负数。`last_durable_instance_id` 记录最近一次
`add_durable_item()` 的实例，供 Debug 菜单"使用最后一个耐久物品"按钮用。

### 收获→物品的耦合（详见第七节）
`PlantGrowthManager.harvest()` 只调用
`InventoryManager.add_item(harvest_item_id, 1)`，不再直接改
`HealthManager` 的任何数值——**这是本次最大的行为变化**：以前收获番茄
立刻加 22 饱腹/18 营养/10 心理，现在收获只进库存，玩家必须再手动
`eat_item("FO-CR-004")` 才会真正回血。

### 面板文本（`panel_status_text()`）
按 食物/种子/消耗品/材料 四个分类分组显示数量，工具单独一段显示
`当前耐久/最大耐久（正常/损坏）`，全部为空时显示"暂无物品。"。

### 物品品质 Quality（v1，纯 UI 装饰，不影响任何数值）
每个物品新增 `quality`（int，1–5）字段，`ItemDatabase.gd` 顶部
`const QUALITY_LEVELS` 是唯一的等级→名字/颜色对照表：

| 等级 | 品质 | 颜色 |
|---|---|---|
| 1 | 劣质 | `#D6D6D6` |
| 2 | 普通 | `#4A90E2` |
| 3 | 稀有 | `#9B5DE5` |
| 4 | 史诗 | `#D6A23A` |
| 5 | 传奇 | `#D94A4A` |

用的是需求文档给的"冷色克制"第二组配色（跟《广寒前哨》整体美术基调更搭，
而不是网游感更重的高饱和第一组）。33 个物品目前的等级分布：种子(5) + 金属
碎片/温室基质 = 劣质(1)；基础食物三种(生菜/土豆/小麦)/两种基础消耗品(压缩
食物/营养液包)/大部分材料/两个默认工具/系统资源编号(6) = 普通(2)；番茄/
大豆/三种"预留"消耗品(医疗包/氧气瓶/惰性气体罐)/三个耐久工具(钻具/修补枪/
切割工具) = 稀有(3)；便携电池包 = 史诗(4)；目前没有物品是传奇(5)（等级
本身已经预留，留给后续内容）。这些等级是本次实现自己按"越基础越低阶"的
直觉分配的（需求文档没有给出具体每个物品的等级），系统设计如果要重新分配
不需要改任何结构，直接改 `ITEMS` 里对应条目的 `"quality"` 数字即可。

`quality` 缺失时（理论上不会发生，因为本次已经给全部 33 条数据都写了这
个字段，只是为了给以后新增物品兜底）自动按 2（普通）处理，通过
`ItemDatabase.get_quality(item_id)` 的 `.get("quality", 2)` 兜底实现，不
会抛错。

**唯一的对外接口是 `ItemDatabase.colored_display_name(item_id)`**——返回
`"[color=#RRGGBB]物品名[/color]"` 这个 BBCode 包裹后的字符串，所有需要显示
物品名的地方都必须调用这一个函数，不要自己拼颜色，这样才能保证"背包、
仓库、补给、维修界面都读取同一套颜色"这条硬性要求。渲染这个字符串的
Control 节点必须是 `RichTextLabel` 且 `bbcode_enabled = true`——普通
`Label` 不解析 BBCode，会把 `[color=...]` 标签原样显示成文字。本次已经
接入的调用点：
- `InventoryManager._stack_lines_for_category()` / `_durable_lines()`
  （渲染节点：`scripts/ui/inventory_panel.gd`，已从 `Label` 换成
  `RichTextLabel`）。
- `ItemContainer.slot_label()`（`scripts/managers/BackpackManager.gd`/
  `StorageManager.gd` 的 `_slot_lines()` 都调用它，渲染节点：
  `scripts/ui/backpack_storage_panel.gd`，同样已从 `Label` 换成
  `RichTextLabel`）。
- `SupplyManager._item_display_name()`（渲染路径是 `debug_values_text()`
  → `main.gd.add_log()`，那个 `TaskLog` 本来就是
  `RichTextLabel(bbcode_enabled=true)`，不用改渲染节点）。
- `RepairManager.gd` 目前完全不显示任何物品/材料的 `display_name`（只显示
  `item_id` 和数量，见第九节维修系统的"已知问题"），所以本次没有改动它——
  等它真正显示物品名的那天，直接调用同一个 `colored_display_name()` 即可，
  不需要另外发明一套颜色。

**v1 明确只做外观，不做数值联动**：品质不影响 `effects`/`weight`/
`max_durability`/`durability_loss_per_use`/维修成功率/任何结算逻辑。需求
文档列出的"后续可扩展作用"（食物按品质给不同恢复量、工具按品质给不同
最大耐久、材料按品质影响维修成功效果、补给按品质影响重量/获取难度、
植物收获按品质给不同心理/营养）本轮**全部没有实现**，只是留了
`quality` 这个字段和等级表，方便以后接。

### 存档
`user://saves/inventory_state.json`：`stack_items / durable_items /
last_durable_instance_id / next_durable_instance_number`。`reset_to_arrival()`
清空成完全空库存——**需求文档没有提到 Day 01 抵达时给初始物品**，第一版
按字面理解为空库存起步，新设计如果要给起始物资，直接在 `reset_to_arrival()`
里追加几个 `add_item()`/`add_durable_item()` 调用即可。

### UI / Debug
`scripts/ui/inventory_panel.gd`，`B` 键开关，位置紧跟在水面板下方
（`Vector2(400, 500)`，跟水面板同宽 330，凑成右侧 3×2 网格里的最后一格：
Water/Air/Base 一行，Inventory/Power/Plant 一行）。Debug 菜单：加食物/
种子/消耗品/材料各一套样本、加一把便携钻具、吃生菜、吃营养液包、使用
最后一个耐久物品、重置到 Day 01。

---

## 八点五、背包与仓库系统 BackpackManager / StorageManager

### 定位
背包/仓库是物品系统之外的新容器层：`ItemDatabase.gd` 仍然只定义物品属性，旧
`InventoryManager.gd` 暂时保留为兼容系统；新系统通过只读查询 ItemDatabase 的
`item_id/category/subcategory/stackable/max_stack/use_model/has_durability/weight`
来决定格子、堆叠和可存放规则。

代码位置：
- `scripts/systems/ItemContainer.gd`：通用 slot/堆叠/排序算法，无 autoload。
- `scripts/managers/BackpackManager.gd`（autoload `/root/BackpackManager`）：随身背包。
- `scripts/managers/StorageManager.gd`（autoload `/root/StorageManager`）：基地仓库。
- `scripts/ui/backpack_storage_panel.gd`：旧基地内 B 键打开的轻量面板。

### 容量与升级
背包第一版限制格子数，并计算当前携行重量与负重等级；负重系统本身不直接施加惩罚。

背包等级：
1. 应急收纳包：12 格
2. 小型采集包：16 格
3. 标准外勤包：24 格
4. 扩展外勤包：32 格
5. 重型采集包：40 格
6. 工程外勤包：48 格

仓库等级：
1. 旧基地储物柜：60 格
2. 整理后的储物区：90 格
3. 标准仓储舱：140 格
4. 扩展仓储舱：220 格
5. 自动分拣仓库：320 格
6. 大型货物舱：500 格

升级接口已预留：
- `BackpackManager.upgrade_backpack()`
- `StorageManager.upgrade_storage()`

第一版不消耗材料，后续再接入建造/升级成本。

### 负重计算 v1

负重系统归属在 `BackpackManager`，但最大承重必须从 `HealthManager.get_effective_carry_capacity()` 读取。

`BackpackManager` 暴露：
- `get_current_carry_weight() -> float`
- `get_max_carry_weight() -> float`
- `get_load_percent() -> float`
- `get_load_level() -> int`

计算方式：
```gdscript
current_carry_weight = sum(ItemDatabase.weight * slot.quantity)
max_carry_weight = max(HealthManager.get_effective_carry_capacity(), 1.0)
load_percent = current_carry_weight / max_carry_weight * 100.0
```

`load_level` 分段：
- 1：`0–49%`，轻装
- 2：`50–74%`，负重
- 3：`75–99%`，重载
- 4：`>=100%`，超载

注意：本系统只输出 `load_level`，不直接修改精力、饱腹、营养、行动耗时、移动速度、外出风险或采集效率。后续系统如果需要惩罚，只读：
```gdscript
var level := BackpackManager.get_load_level()
```

### Slot 结构
背包和仓库都保存 `slots: Array`，空格为 `null`。

普通物品：
```gdscript
{
    "item_id": String,
    "quantity": int,
    "instance_id": ""
}
```

耐久物品：
```gdscript
{
    "item_id": String,
    "quantity": 1,
    "instance_id": String,
    "current_durability": float,
    "max_durability": float,
    "state": "normal" 或 "broken"
}
```

### 堆叠与排序
可堆叠物品按 `ItemDatabase.max_stack` 自动合并和拆堆。耐久物品永远不合并，每件占
1 格。

排序顺序：
`food -> consumable -> seed -> material -> tool -> component -> specimen -> quest_item -> resource -> other`
同类内部按 `subcategory -> item_id` 排序；耐久物品再按 `state` 和耐久度排序。

### 允许存放规则
背包和仓库都允许：食物、种子、材料、工具、消耗品、样本、任务物品、小型部件。

仓库不直接存系统资源：
`RS-WA-001 / RS-IC-001 / RS-EN-001 / RS-OX-001 / RS-CO-001 / RS-IG-001`
这些真实数值仍由对应 Manager 管理。

例外：`RS-IC-001` 月球冰可以临时进入背包，用于未来外出采集链路；回基地后通过
`BackpackManager.deposit_ice_to_water_system()` 转入 `WaterSystemManager.current_ice`。
仓库不会长期保存月球冰。

### 转移与使用
背包到仓库：
- `BackpackManager.transfer_slot_to_storage(slot_index, amount := -1)`
- `BackpackManager.deposit_all_to_storage()`

仓库到背包：
- `StorageManager.transfer_slot_to_backpack(slot_index, amount := -1)`

食物可以从背包或仓库食用：
- `BackpackManager.eat_item(item_id)` / `eat_first_food()`
- `StorageManager.eat_item(item_id)` / `eat_first_food()`

食用流程使用 `TimeManager.advance_time(use_time_minutes, "eat_item")`，然后调用
`HealthManager.apply_item_effects(effects)`。不调用旧的固定 `"eat"` / `"nutrition_drink"`
健康恢复逻辑，避免双重恢复。

### 与植物收获的关系
`PlantGrowthManager.harvest()` 现在优先调用 `StorageManager.add_item(harvest_item_id, 1)`。
如果 `StorageManager` 不存在，则回退到旧 `InventoryManager.add_item()`，保留旧默认路径。
仓库满且无法接收时，收获返回 `false`，不会把植物标记为已收获。

### 存档
独立存档：
- `user://saves/backpack_state.json`
- `user://saves/storage_state.json`

旧基地/训练进度聚合存档也会额外写入：
- `BackpackState`
- `StorageState`

---

## 八点六、地球补给系统 SupplyManager

### 定位
`SupplyManager` 是地球定期补给的排期和订单系统，不自己推进时间，不直接操作背包。它只负责：
- 什么时候补给到达
- 补给清单什么时候截止
- 玩家自由选择的补给是否超重
- 强制货物占用多少重量
- 到货后交给仓库、资源系统或特殊解锁记录

代码位置：
- `scripts/managers/SupplyManager.gd`（autoload `/root/SupplyManager`）

### 时间规则
补给系统挂在 `TimeManager.advance_time()` 后面。`TimeManager` 每次推进行动时间后调用：
```gdscript
SupplyManager.check_supply_events(previous_minutes, total_minutes)
```

事件判断使用区间跨越：
```gdscript
previous_minutes < event_time and event_time <= current_minutes
```

这样一次睡眠、维修或 debug 跳时跨过截止/到达时间，也不会漏掉补给事件。

常量：
- `SUPPLY_INTERVAL_MINUTES = 10080`（7 天）
- `SUPPLY_LOCK_BEFORE_MINUTES = 4320`（提前 3 天截止）
- `DEFAULT_SUPPLY_WEIGHT_LIMIT = 300.0`
- `FORCED_ITEM_WEIGHT_RATIO = 1.0 / 3.0`

开局第一批补给：
- 到达：`total_minutes = 10080`，即 Day 08 06:40
- 截止：`total_minutes = 5760`，即 Day 05 06:40
- 强制货物：`QI-VE-001` 月球车

### 订单结构
每个补给订单保存在 `supplies: Array` 中，字段：
```gdscript
{
    "supply_id": String,
    "supply_index": int,
    "arrival_time_minutes": int,
    "deadline_time_minutes": int,
    "status": String,
    "weight_limit": float,
    "reserved_weight": float,
    "free_weight_limit": float,
    "forced_items": Array,
    "selected_items": Dictionary,
    "confirmed": bool
}
```

状态：
- `draft`：草稿，可编辑
- `confirmed`：已确认，截止前仍可修改
- `locked`：已锁定，等待到达
- `missed`：未确认，已错过
- `delivered`：已送达

修改草稿会自动把 `confirmed` 设回 `false`，需要重新确认。

### 重量规则
每次补给默认总重量上限为 `300 CU`。

若本批次有强制货物：
```gdscript
reserved_weight = weight_limit / 3.0
free_weight_limit = weight_limit - reserved_weight
```

第一批月球车占用 `100 / 300 CU`，玩家可自由选择 `200 CU`。

玩家自由选择物品重量：
```gdscript
item_weight = item.supply_weight if exists else item.weight
selected_weight = sum(item_weight * amount)
```

接口：
- `get_selected_weight(supply := {})`
- `get_reserved_weight(supply := {})`
- `get_free_weight_limit(supply := {})`
- `get_remaining_weight(supply := {})`
- `get_item_supply_weight(item_id)`

### 可选补给白名单
当前没有修改 `ItemDatabase.gd`。`SupplyManager.is_item_supply_allowed(item_id)` 会先读取未来可能存在的：
```gdscript
supply_allowed = true
```

如果字段不存在，则使用 `SupplyManager` 内部第一版白名单：
- `CN-FD-001` 压缩食物
- `CN-FD-002` 营养液包
- `SD-CR-001` 到 `SD-CR-005` 五种作物种子
- `MT-ME-001` 金属碎片
- `MT-EL-001` 电子零件
- `MT-SE-001` 密封材料
- `MT-FI-001` 过滤材料
- `MT-IN-001` 绝缘材料
- `CN-MD-001` 医疗包
- `CN-OX-001` 应急氧气瓶
- `CN-IG-001` 小型惰性气体罐

月球车和后续剧情强制物品不走自由选择列表。

### 到货分发
`deliver_supply()` 先处理强制物品，再处理玩家选择物品。

分发规则：
- 强制物品 / `QI-*`：写入 `unlocked_special_items`。第一批月球车会额外记录 `has_lunar_rover = true`。
- 普通物品：调用 `StorageManager.add_item(item_id, amount)`。
- 耐久物品：如果未来加入自由补给白名单，调用 `StorageManager.add_durable_item(item_id)` 逐件入库。
- 系统资源：
  - `RS-WA-001` → `WaterSystemManager.add_water(amount)`
  - `RS-IC-001` → `WaterSystemManager.add_ice(amount)`
  - `RS-IG-001` → `AirSystemManager.adjust_stat("inert_gas_reserve", amount)`
  - `RS-OX-001` → `AirSystemManager.adjust_stat("o2_percent", amount)`

如果仓库无法接收或对应系统不存在，剩余物品进入：
```gdscript
pending_supply_items[item_id] += amount
```

### 存档
独立存档：
- `user://saves/supply_state.json`

字段：
- `supply_index`
- `supplies`
- `supply_weight_limit`
- `forced_supply_items`
- `unlocked_special_items`
- `pending_supply_items`
- `last_notice`

主菜单试玩清进度列表已包含 `supply_state.json`。

## 九、尚未覆盖 / 明确没做的东西（新设计如果要动，请先确认这些坑）

- **温度系统只有基地整体一个值**，没有分房间/分舱段温度；植物、健康、空气
  系统都读的是同一个 `BaseStatusManager.temperature`。
- **温室补光等级（植物系统）仍是独立数值**，跟旧基地场景里那些叙事型布尔
  标志（`PartialWaterCycleRestored` 等）完全没有打通，也没有玩家可操作的 UI
  （只有 Debug 按钮）。植物用水已经不再是独立数值了（见 WaterSystemManager），
  但补光还是。
- **旧的固定 `eat`/`nutrition_drink` 行动仍然原样保留，没有被物品系统取代**：
  `HealthManager.gd` 里那两个固定 case、`TimeManager` 行动耗时表里对应的
  30/15 分钟条目、`# TODO: deduct food resource` 注释都还在——这条行动依然
  可以无限次执行，只要有水就一直有"食物"可吃，**不消耗 `InventoryManager`
  里的任何库存**。物品系统实现完成后，新增的 `InventoryManager.eat_item()`
  是一条完全独立、需要真实库存物品的平行路径（见第八节），两条路径并存，
  没有互相替代——新设计如果想让"吃"这个动作真正读库存，需要把旧基地场景/
  Debug 菜单里调用 `HealthManager.apply_action_cost("eat")` 的地方改成调用
  `InventoryManager.eat_item(具体 item_id)`，这个改造本次没有做。惰性气体
  第一版同样不能生产，只能靠"旧基地遗留 + 地球补给"的
  叙事设定维持一个初始储备。月球冰同理第一版没有实际的"外出采集"系统在生产
  它——`WaterSystemManager.add_ice()` 只是一个空接口，等外出采集系统实现后
  才会真正被调用，目前只能靠 Debug 菜单模拟"采到了多少冰"。
- **"最后一株植物"叙事系统**（`sprint06_base_scene.gd` 里的
  `LastPlantStable` 等）跟 `PlantGrowthManager` 是两套并行独立的系统，只有
  一个单向信号：最后一株植物脱离 Critical 时，往 `BaseStatusManager` 报一次
  `set_last_plant_recovered(true)`（一次性心理 +2）；`AirSystemManager` 再
  从 `BaseStatusManager` 读这个 flag 算自己的 O₂/CO₂ 微弱加成，没有更深的
  双向联动，也没有反过来影响植物系统本身。
- **密封、温控（BaseStatusManager）以及 CO₂过滤、空气循环
  （AirSystemManager）目前都没有场景内的维修交互入口**，只有方法和 Debug
  按钮；只有制氧模块（AirSystemManager，接的是旧基地
  `MinimalLifeSupportStable` 那个既有交互点）真正接了玩法效果。
- **`power_system_status`（BaseStatusManager 的"供电系统"档位）以及
  `repair_power_light/heavy()` 现在是纯装饰性字段/方法**：旧基地场景里
  `PowerPanelRepaired`/`BasePowerRestored` 这两个既有交互点仍然会调用它们，
  维修文案照常播放，`power_system_status` 照常从 CRITICAL 跳到 BASIC/STABLE，
  **但这个跳档已经不影响任何电力数值**——真正决定发电速度的是
  `PowerSystemManager.solar_array_status`（现在只能靠 Debug 菜单调），玩家
  在旧基地做的"供电维修"目前只是叙事上的仪式感，没有电力系统层面的实际
  效果。这是本次改造特意选择的技术债（保留旧交互不报错，而不是删掉/改写
  旧钩子），下一轮如果要让"修供电面板"这个既有玩法动作真正影响新电力系统，
  需要决定是把 `power_system_status` 完全废弃、还是把它重新映射成
  `solar_array_status` 的另一套写法。
- **惰性气体的"自动补压"换算率（0.15 / 0.20）是本次实现自己定的 v1 占位值**，
  原始需求文档没有给这部分具体数字；空气设备维修的一次性数值同理是本次
  新增的占位值（原文档只给了每小时速率，没给维修瞬间的数值）；电力系统的
  "推荐电力模式"预设数值（`current_energy` 初始 50/太阳能板 2/电池模块 2 等）
  已经是需求文档给定的明确数字，但"设为最低稳定状态"debug 按钮的具体目标值
  （4 电池模块/220 E/4 块 STABLE 太阳能板）是本次按"月昼结束电量：200–240 E"
  这条设计目标自己选的落点，非逐字数字。系统设计如果要重新平衡，直接改
  对应文件里的常量/方法即可，不用改结构。
- **没有失败/死亡结局**：健康值、基地状态、空气状态、电力状态目前都只是
  效率修饰或文案变化，没有任何数值触发游戏结束。电量为 0 时温控/制氧/CO₂
  过滤/补光"停止"这条效果，是靠既有的"电力<20%时效果打折/归零"倍率表自然
  达成，没有专门写"电量=0 强制关闭设备"的代码。
- **温室没有"走到某块地播种/收获"的场景交互**，`PlantGrowthManager` 的
  `slot_id` 目前只能靠 Debug 菜单赋值（约定 slot_id = crop_id，即同一种作物
  同一时间只能有一块地）。
- **电力系统、水资源系统都没有玩家可操作的面板控件**：加太阳能板/电池模块/
  水箱/冰仓模块、切换供氧目标档位、切换电力模式预设、处理冰，目前全部只能
  通过 Debug 菜单触发，没有场景内的"购买/建造/处理/切换"交互。
- **"喝营养液不可用"这条硬门槛没做**：需求文档里"水量为 0 时营养液无法调配"
  是一个动作层面的强制阻断，本次实现的 `WaterSystemManager.apply_action_cost()`
  只是尽力打折扣款到 0（水不够就扣到 0，不会让水变负数），**不会阻止玩家
  继续喝营养液**——跟 PowerSystemManager 的一次性行动耗电走的是同一种"尽力
  而为、不做硬门槛"简化，两者一致但都没有实现需求文档里提到的"某个资源为 0
  时某个具体动作被禁用"这条规则。
- **水不足时"该优先满足生活用水还是制氧"没有权重分配，完全按结算顺序决定**：
  `advance_water_time()` 里生活用水在制氧耗水之前结算，水快耗尽时生活用水
  永远先把剩余的水领走，制氧只能分到结算顺序之后剩下的部分（可能是 0）。
  这是一个隐性的"生活用水优先级更高"设计，不是需求文档明确要求的，只是
  实现顺序的自然结果，系统设计如果想要更公平的分配（按比例分水）需要重构
  这部分。
- **材料科学专业提示"水箱老化/冰仓隔热"只是文案，没有真实的模块老化/损耗
  机制**（需求文档自己也说"第一版可只做文案，不做真实损耗"）。
## 维修系统 v1：RepairManager

新增运行时：
- `scripts/managers/RepairManager.gd`
- Autoload：`/root/RepairManager`
- 存档：`user://saves/repair_state.json`

新增数据表：
- `scripts/data/FaultDatabase.gd`

设计边界：
- 维修不再是简单点击立即修复，而是“故障卡 -> 症状阅读 -> 三选一维修方案 -> 时间/材料结算 -> 成功或失败反馈”。
- 本版不做 QTE、不做真实工程谜题、不做职业数值加成、不做工具耐久深度系统。
- 正确方案会消耗设定时间和仓库材料，然后解除故障。
- 错误方案会消耗时间，可能消耗材料，严重故障会记录 `worsening`。
- 可选诊断会消耗 15 分钟，并排除一个错误方案，但不会直接告诉玩家正确答案。

系统关系：
```text
FaultDatabase
-> RepairManager active_faults
-> TimeManager.advance_time(...)
-> StorageManager.get_item_count/remove_item
-> BaseStatusManager / AirSystemManager / WaterSystemManager / PowerSystemManager 轻量效果
```

材料来源：
- 第一版只从 `StorageManager` 扣除材料。
- 未修改 `ItemDatabase.gd` 和 `InventoryManager.gd`。
- 维修材料 ID 使用现有/规划物品 ID：`MT-ME-001`、`MT-EL-001`、`MT-SE-001`、`MT-FI-001`、`MT-IN-001`、`MT-GL-001`、`CN-IG-001`。

主要接口：
- `add_fault(fault_id)`
- `remove_fault(fault_id)`
- `get_active_faults()`
- `get_fault_data(fault_id)`
- `diagnose_fault(fault_id)`
- `attempt_repair(fault_id, option_id)`
- `debug_values_text()`

已录入故障卡：
- 供电：`FA-PO-001`、`FA-PO-002`、`FA-PO-003`
- 空气：`FA-AIR-001`、`FA-AIR-002`、`FA-AIR-003`
- 密封：`FA-SEAL-001`、`FA-SEAL-002`
- 温控：`FA-THERM-001`、`FA-THERM-002`、`FA-THERM-003`
- 水系统：`FA-WATER-001`、`FA-WATER-002`、`FA-WATER-003`
- 温室：`FA-GH-001`、`FA-GH-002`

当前限制：
- RepairManager 已能作为底层系统工作，但还没有正式场景 UI。
- 开发菜单提供了维修调试入口：查看状态、加入测试材料、加入测试故障、诊断首个故障、尝试正确/错误维修、重置维修状态。
- 系统效果仍是轻量占位：部分 wrong/success 会调整电量、水、舱压、温度、空气读数，但不做完整故障持续结算。

---

## 训练专用时间系统 TrainingTimeManager

### 定位
地面候选人选拔训练阶段专用的时间预算，**跟正式 `TimeManager` 完全隔离**。
训练发生在 Day 01 06:40 之前的地球阶段，绝不能推进正式
`TimeManager.total_minutes`、月昼/月夜周期、`BaseStatusManager`、
`PlantGrowthManager`，也不消耗正式仓库物资——这是本系统存在的唯一理由。

代码位置：
- `scripts/managers/TrainingTimeManager.gd`（autoload `/root/TrainingTimeManager`）
- `scripts/training/training_manager.gd`（新增
  `are_required_modules_completed()`/`fail_training(reason)`/
  `training_status()`/`training_failure_reason()` 四个 static 方法，训练
  通过/失败判断仍然归它管，`TrainingTimeManager` 只管时间）

### 核心字段与抵达初始值
| 字段 | 初始值 | 说明 |
|---|---|---|
| `archive_limit_minutes` | 480（8 小时） | 训练归档总时限 |
| `elapsed_minutes` | 0 | 训练已用时间 |
| `remaining_minutes` | 480 | 训练剩余时间，硬 clamp ≥0 |
| `training_time_active` | false | 训练时间是否在跑；`start_training_time()` 前一直是 false |
| `training_time_paused` | false | 暂停时 `advance_training_time()` 直接不生效（连日志都不写） |
| `time_log` | `[]` | 每次推进都追加一条 `{minutes, reason, elapsed_after, remaining_after}`，供失败复盘 |

### 生命周期
```
TrainingManager.start_training()          # 点"开始训练"按钮时调用，同时
                                            # 调 TrainingTimeManager.start_training_time()
  → advance_training_time(minutes, reason) # 每个训练步骤唯一的推进入口
  → check_training_timeout()               # 每次推进后自动检查
TrainingManager.mark_module_completed("final_assessment", ...)
  → 训练通过：TrainingTimeManager.stop_training_time()
TrainingTimeManager.check_training_timeout() 触发失败
  → TrainingManager.fail_training("archive_time_expired")
  → 内部再调 TrainingTimeManager.stop_training_time()
```
`start_training_time(limit_minutes := 480)` 每次调用都会把
`elapsed_minutes`/`time_log` 清零重置——这是"开始一轮新训练"的语义，不是
"继续上一轮"。`training_module_scene.gd`（5 个训练模块 + 最终考核共用的
场景脚本）只在场景切换时调用
`TrainingManagerScript.set_current_module(module_id)`，**不会**重新调
`start_training_time()`，所以训练时间预算是跨越 6 个训练场景累计的同一个
480 分钟，不会因为切场景被重置。

### 超时判断
```
check_training_timeout():
    remaining_minutes > 0                          → 直接返回，什么都不做
    TrainingManager.are_required_modules_completed() → 直接返回（时间到但
                                                        必修模块已完成 = 
                                                        通过/结算，不是失败）
    否则 → TrainingManager.fail_training("archive_time_expired")
```
`are_required_modules_completed()` 检查的是五个核心训练模块（宇航服基础
控制/气闸流程/供电维修/生命支持/植物状态诊断），**不含
`final_assessment`**——最终考核是必修模块全部完成之后的结算步骤本身，
不是跟训练归档时限赛跑的对象之一。`fail_training(reason)` 有幂等保护
（已经是 `"failed"` 状态时直接返回），避免同一次超时被反复处理。

### 训练行动耗时（`training_module_scene.gd` 的 `_advance_time_for_step()`）
训练步骤数据可以给每一步显式指定 `time_minutes`/`time_reason`；没指定时
落回 `_default_time_minutes_for_step()` 按步骤类型/目标关键词猜一个耗时
（这个猜测逻辑本次没有改动，仍然会读 `TimeManager.action_minutes()` 当
"耗时常量表"来源——**这是纯只读查表，不推进任何时间，不违反隔离原则**，
本次特意保留没有重写成训练自己的一张表，避免不必要的重复维护）。真正
推进的调用点已经从 `TimeManager.advance_time()` 换成
`TrainingTimeManager.advance_training_time()`，这是本次唯一改动了实际
调用点的地方。需求文档第九节给出的建议耗时表（打开训练终端 5 分钟、
标准维修 60 分钟、严重维修 120 分钟等）目前主要体现在各训练模块自己的
步骤数据里显式设置的 `time_minutes`，没有另外抄一份到
`TrainingTimeManager.gd` 里。

### 训练时间 HUD
`training_module_scene.gd._time_hud_text()` 已经从显示
`TimeManager.compact_hud_text()`（正式月昼/日期）改成显示
`"训练归档时限：剩余 %s" % TrainingTimeManager.get_remaining_time_text()`
（格式 `HH:MM`），按需求文档规定统一叫"训练归档时限"，不叫"教程倒计时"/
"考试时间"/"Game Over 倒计时"。

### 失败处理
`fail_training(reason)` 只是把 `TrainingStatus="failed"` /
`TrainingFailureReason=reason` 写进训练进度存档（`training_progress.json`），
调用 `update_candidate_file_status("候选人档案已归档")` 更新申请档案状态
文案，并停掉训练时间。**本次没有新增失败结算场景/UI**——需求文档给出的
失败文案（"候选人档案已归档。结果：派遣资格未激活。"）和失败复盘
（读 `get_time_log()` 汇总"主要时间损耗"）目前只是数据层面可查询
（`TrainingManager.training_status()`/`training_failure_reason()`/
`TrainingTimeManager.get_time_log()`），没有对应的场景把它们显示出来，
这是留给下一轮 UI 工作的缺口，见文末已知问题。

### 训练与正式系统的边界（逐条对照需求文档第十三～十七节）
- 不推进正式 `TimeManager.total_minutes`/月昼月夜：本次把
  `training_module_scene.gd` 里唯一的时间推进调用点换成了
  `TrainingTimeManager`，`TimeManager.advance_time()` 在训练场景里完全
  没有调用点了。
- 不推进 `BaseStatusManager`/`PlantGrowthManager`：这两个系统只在
  `TimeManager.advance_time()` 的结算链里才会被推进（见第一节调用顺序），
  训练场景既然不再调用它，自然也不会间接推进这两个。
- 训练健康/训练资源模拟（需求文档第十四、十七节提到的
  `training_health_state`/`TrainingResourceScenario`）**本次没有实现**——
  训练场景目前用的还是正式 `HealthManager`（`_health_hud_text()` 仍然读
  `HealthManager.compact_hud_text()`），需求文档自己也说"第一版更推荐简单
  做法"，但连"简单做法"（训练健康状态只存在 TrainingManager 中）这次都
  没做，是本次特意没碰的范围，见已知问题。
- 训练维修/训练植物的独立副本（需求文档第十五、十六节）**本次没有实现**——
  各训练模块目前复用的还是自己场景脚本里手写的步骤数据，不是真的接了
  `RepairManager`/`PlantGrowthManager` 的故障卡/生长规则再套一层"训练材料/
  训练植物不影响正式系统"的隔离，这两节提到的边界规则暂时是不适用的
  （因为还没有对应的真实耦合发生）。

### 存档
`user://saves/training_time_state.json`：`archive_limit_minutes /
elapsed_minutes / remaining_minutes / training_time_active /
training_time_paused / time_log`。需求文档原文说"如果训练不能中途存档，
可以不做训练时间存档"——本次还是按项目里其他 Manager 的统一存档习惯做了，
不会因为不存档而导致别的地方报错，纯粹是为了跟其他系统写法一致。
`training_progress.json`（`training_manager.gd` 自己的存档）新增了
`TrainingStatus`/`TrainingFailureReason` 两个字段。

### UI / Debug
还没有正式的训练时间面板（需求文档也没有要求新场景，只要求"UI 可以读取
剩余训练时间"，这点通过 `_time_hud_text()` 已经满足）。主菜单开发菜单
新增 Training Time Debug 分组：查看状态、开始（480 分钟）、+30/+360 分钟
推进、暂停、恢复、强制超时（直接把剩余时间打到 0 并触发一次超时检查）。

### 已知问题 / 暂不覆盖范围
- 没有专门的训练失败结算场景/UI，失败原因和时间消耗复盘目前只能通过代码
  查询（`TrainingManager.training_status()`/`training_failure_reason()`、
  `TrainingTimeManager.get_time_log()`），没有玩家能直接看到的界面。
- 训练健康状态、训练资源模拟（水/电/氧气/CO₂/温度）目前都还是直接读/演
  正式系统的 `HealthManager`，需求文档提到的"训练副本不污染正式初始值"
  这条边界目前没有实际耦合场景需要它生效。
- 训练维修/训练植物没有接正式 `RepairManager`/`PlantGrowthManager` 的
  故障卡/生长规则，各训练模块的步骤数据仍然是各自场景脚本手写的固定
  剧本，不是动态生成的。
- `_default_time_minutes_for_step()` 的耗时猜测逻辑仍然读
  `TimeManager.action_minutes()` 当常量表（纯只读，不推进任何时间），
  没有另外抄一份训练专用的耗时表；需求文档第九节的建议耗时数字主要靠
  各步骤数据自己的 `time_minutes` 字段体现，不是这张查表的责任。

---

## 宇航服系统 SuitManager

### 定位
舱外行动（EVA）前后的完整闭环——穿戴、舱外消耗、脱下、维护补给——独立
管理宇航服自己的氧气/电力储备，跟基地舱内空气（`AirSystemManager`）、
基地电力（`PowerSystemManager`）是两套完全不同的数值，只在维护环节单向
消耗基地资源。第一版明确不做：宇航服部件损坏细分、耐久系统、多套宇航服、
随机故障、战斗模块，速度倍率上限硬性锁在 1.0（不会做超过 1.0 的加成）。

代码位置：`scripts/managers/SuitManager.gd`（autoload `/root/SuitManager`）。

### 核心字段与抵达初始值
| 字段 | 初始值 | 说明 |
|---|---|---|
| `is_suit_worn` | false | |
| `suit_storage_state` | `"ready"` | `ready`/`worn`/`carried`/`servicing` 四态，`carried`（脱下但未挂入维护位）本版没有对应的转移函数，是留给未来更细流程的预留态 |
| `suit_level` | 1 | 1–5，决定速度倍率 |
| `suit_oxygen` / `suit_oxygen_capacity` | 100.0 / 100.0 | |
| `suit_power` / `suit_power_capacity` | 100.0 / 100.0 | |
| `suit_speed_multiplier` | 0.8 | 硬 clamp ≤1.0 |
| `wear_time_minutes` | 15 | |
| `remove_to_station_time_minutes` | 15 | |

### 穿戴 / 脱下（唯一推进正式 `TimeManager` 的两个动作）
```
wear_suit() -> bool
  只有 suit_storage_state == "ready" 才成立
  TimeManager.advance_time(15, "wear_spacesuit")
  is_suit_worn = true; suit_storage_state = "worn"

remove_suit_to_service_station() -> bool
  只有 is_suit_worn == true 才成立（本版没做"只脱下不挂入"的中间态）
  TimeManager.advance_time(15, "remove_suit_to_service_station")
  is_suit_worn = false; suit_storage_state = "servicing"
```
**回基地不会自动恢复宇航服**——脱下只是把状态从 `worn` 切到 `servicing`，
氧气/电力完全不变，必须再调 `service_suit_full()`（或
`refill_suit_oxygen()`/`recharge_suit_power()`）才会真正补给。

### 穿戴后资源消耗（`consume_suit_resources(minutes, activity_type)`）
```
indoor_worn：氧气 3/小时、电力 2/小时
eva_normal（默认）：氧气 8/小时、电力 6/小时
eva_heavy：氧气 12/小时、电力 10/小时
```
按 `minutes/60.0 * 每小时速率` 结算，`suit_oxygen`/`suit_power` 硬 clamp
≥0。**未穿戴时直接空转**（`is_suit_worn == false` 立即返回，不扣任何
数值）。这个函数本身**不**推进 `TimeManager`——它只是"消耗宇航服自己的
数值"，时间推进由调用方（未来的外出/EVA 系统）自己先调
`TimeManager.advance_time()`，再调这个函数，两者独立。

### 速度倍率与升级路线
```
get_actual_minutes(base_minutes) -> int
  actual_minutes = ceil(base_minutes / suit_speed_multiplier)
  例：60 分钟基础耗时 × 初代 0.8 倍率 = 75 分钟（需求文档给的算例，已用
  临时验证脚本跑通）

upgrade_suit_speed() -> bool      # suit_level >= 5 时返回 false，不升级
  1 初代舱外服 0.80 / 2 关节助力改良 0.85 / 3 平衡负载结构 0.90 /
  4 低阻力外勤服 0.95 / 5 完整外勤升级 1.00（min() 硬 clamp，绝不会超过 1.0）
```
`get_actual_minutes()` 是本次新增的公共 helper（需求文档只给了倒推公式，
没给函数名）——未来外出系统的推荐调用顺序是：先算 `actual_minutes =
get_actual_minutes(base_minutes)`，再 `TimeManager.advance_time(actual_minutes,
reason)`，再 `SuitManager.consume_suit_resources(actual_minutes,
activity_type)`，三步用的都是同一个"打了折"之后的真实分钟数。

### EVA 出舱限制
```
can_start_eva() -> bool
  is_suit_worn && suit_oxygen >= 20 && suit_power >= 20
```
`SuitManager` 本身**只负责数值归零和状态提示，不直接判定紧急返航/健康
恶化/杀死玩家**——那是未来外出系统读 `suit_oxygen`/`suit_power` 之后自己
决定的事，见需求文档第十八节。

### 维护位补给（唯一会消耗基地真实资源的地方）
```
refill_suit_oxygen() -> bool
  missing_oxygen = suit_oxygen_capacity - suit_oxygen
  water_cost = missing_oxygen * 0.01   （水，W）
  power_cost = missing_oxygen * 0.02   （电，E）
  两者都够才真正扣款，扣完 suit_oxygen 补满

recharge_suit_power() -> bool
  missing_power = suit_power_capacity - suit_power
  power_cost = missing_power * 0.03    （电，E）

can_service_suit_full() -> bool   # 只读检查，不扣款
service_suit_full() -> bool
  先 can_service_suit_full() 整体过一遍（水/电两项加总的账单都验证过才
  往下走），再依次调 refill_suit_oxygen()/recharge_suit_power()，全部
  成功后 suit_storage_state = "ready"；只要中途任何一步不够，直接整体
  失败、servicing 状态不变、已经检查过的资源一分钱都不会被扣
  （不会出现"水扣了、电没扣够"这种半失败状态）
```
一套完全耗空（0/0）的宇航服补满 = 100×0.01 + 100×0.02 + 100×0.03 = 1.0 W
+ 5.0 E，跟需求文档第十五节给的算例完全一致（已用临时验证脚本逐项跑通）。
**本版没有额外的维护耗时**——`remove_suit_to_service_station()` 的 15
分钟已经算作"脱下+挂入"的完整耗时，`service_suit_full()` 本身不再推进
`TimeManager`，按需求文档第十七节"第一版不建议加"执行。

### 新增的跨系统接口（`WaterSystemManager`/`PowerSystemManager`）
需求文档第二十一节要求"资源不足返回 false"这个契约，但两个 Manager 已有
的 `consume_energy(amount)`（`PowerSystemManager`，供
`WaterSystemManager.process_ice()` 调用，无条件扣款+clamp 到 0，不做
拒绝判断）和整体的 `apply_action_cost()`/`consume_plant_water()`（都会
打折扣款到 0，同样不做硬拒绝）都不是这个契约，为了不改变这两个既有函数
的行为（其他调用方依赖"总是成功、只是 clamp"这个语义），本次是**新增**
而不是**修改**：
```
WaterSystemManager.consume_water_checked(amount, reason="") -> bool
  amount<=0 直接 true；current_water < amount 直接 false（不扣款）；
  否则原价（不打折）扣款并返回 true
PowerSystemManager.consume_energy_checked(amount, reason="") -> bool
  同样的"不够就整体拒绝，够了原价扣款"语义
```
`reason` 两边都不参与任何分支判断，只是为了未来调试/日志可读性传进去的。
这两个新函数目前只有 `SuitManager` 在用，其余既有调用点
（`WaterSystemManager.process_ice()`、`consume_plant_water()`、
`apply_action_cost()`）完全没有改动。

### 与负重系统的关系
按需求文档第二十节明确要求，本版**不做**宇航服影响负重上限——负重仍然
只由 `HealthManager`/`BackpackManager` 决定，`SuitManager` 完全不参与
负重计算。

### 存档
`user://saves/suit_state.json`：`is_suit_worn / suit_storage_state /
suit_level / suit_oxygen / suit_oxygen_capacity / suit_power /
suit_power_capacity / suit_speed_multiplier`，跟需求文档第二十三节给的
字段列表逐字一致。同时接入 `sprint06_base_scene.gd`（10 个场景共用）的
`SuitState` 字段和 `training_manager.gd` 的 `SuitState` 字段，写法对齐
已有的 `InventoryState` 处理。

### UI / Debug
`scripts/ui/suit_panel.gd`，`U` 键开关。**没有塞进现有的 3×2 面板网格**
（Water/Air/Base 一行、Inventory/Power/Plant 一行已经把 1600×900 视口
里 x=400–1590、y=180–800 这块区域完全占满了）——改成一条更矮更宽的横条，
放在网格下方唯一剩下的空隙 `Vector2(400, 810)`，宽度 1170（跟网格总宽对齐）、
高度 78，只显示两行压缩文本（状态+氧气+电力一行、速度倍率一行）。Debug
菜单新增 Suit Debug 分组：穿戴、脱下挂入维护位、模拟一次舱外行动（普通/
高强度，会按当前速度倍率打折耗时后再推进真实时间+消耗宇航服资源）、
清空氧气电力（方便测试出舱限制）、完整维护、升级速度、查看状态、重置。

### 顺手修复的 Bug（发现于本次布置 Suit 面板时，属于更早一次多方合并
提交里遗留的既有问题，不是本次新引入的）
`sprint06_base_scene.gd` 里 `_setup_inventory_panel()`/
`_toggle_inventory_panel()` 用的变量名是 `inventory_panel`，但实际
`new()` 出来的是 `BackpackStoragePanelScript`（Codex 的背包/仓库面板），
不是 `InventoryPanelScript`（Claude Code 的物品库存面板）——`const
InventoryPanelScript` 这行预加载常量整个从文件里消失了。根因是"物品系统
提交（37d2c3b）"那次两边并发编辑同一个函数/变量名，最终只留下了其中一份，
从那次提交起，**`B` 键实际打开的是背包/仓库面板，物品库存面板完全没有
入口**（两个面板长期共用同一个变量和同一个 15 分钟前就该独立的键位）。
本次顺手修复：恢复 `InventoryPanelScript` 预加载常量和 `B` 键→物品库存
面板的原始绑定，给背包/仓库面板单独开了一个新变量
`backpack_storage_panel` + 新键位 `K`（因为它是 520×430 的大面板，放不进
330 宽的网格格子，改成大致居中摆放在 `Vector2(540, 235)`）。这是纯粹的
UI 层修复，没有改动 `BackpackManager`/`StorageManager`/`InventoryManager`
任何一个的业务逻辑。

---

## 移动时间系统 MovementTimeManager

### 定位
移动本身也是一次行动——走路会消耗时间，速度受身体状态/宇航服/负重/地形
影响。**不做**：每格强制 1 分钟（室内移动会很痛苦）、移动直接大量扣精力、
摔倒/随机事故、复杂寻路时间预估、坐标级真实物理速度、交通工具系统。

代码位置：`scripts/managers/MovementTimeManager.gd`（autoload
`/root/MovementTimeManager`）。**没有新建"玩家移动管理器"**——这个项目
已经有一个跨场景共用的 `scripts/controllers/player_controller_2d.gd`
（`RefCounted`，每帧算像素位移、按 64px 一档累积"步数"再报给时间系统），
本次是把这个既有控制器的"报时间"落点从直连 `TimeManager.advance_time()`
改成可选委托给 `MovementTimeManager`，而不是另起一套移动追踪。

### 核心字段
| 字段 | 初始值 |
|---|---|
| `base_move_tiles_per_minute` | 10.0（1 格 = 0.1 分钟） |
| `movement_time_buffer` | 0.0 |
| `min_move_multiplier` | 0.30（总倍率硬下限） |

### 速度倍率四项（`get_final_move_multiplier(terrain_type)`）
```
health（读 HealthManager.get_movement_health_multiplier()，新增接口）：
  energy≥40 → 1.0 / 20–39 → 0.8 / <20 → 0.67
  （跟 get_action_time_multiplier()/get_carry_health_multiplier() 是三张
  完全独立的表，同样读 energy 但服务不同系统，不共用阈值/数值——
  fullness/nutrition/morale 故意不参与，fullness 已经通过精力消耗倍率
  间接影响移动能力，nutrition/morale 只管睡眠恢复）
suit（读 SuitManager）：
  未穿戴 → 1.0（哪怕背着/放着也不减速）；穿戴 → 读
  SuitManager.get_suit_speed_multiplier()（0.80→1.00 五级，本身已经
  clamp ≤1.0）
load（读 BackpackManager.get_load_level()，这个接口本来就已经存在，
  不是本次新增）：
  1 轻装→1.00 / 2 有负担→0.95 / 3 重载→0.85 / 4 超载→0.70
terrain（调用方传入字符串，本系统只做查表）：
  indoor→1.00 / old_base_clutter→0.85 / lunar_flat→0.75 / lunar_rough→0.60
```
四项相乘后 `max(总倍率, 0.30)`——需求文档给的第三个算例（精力 18→0.67 ×
宇航服 0.8 × 超载 0.70 × 月面崎岖 0.60 ≈ 0.225）已经用临时脚本验证会被
压到 0.30 下限，30 格实际耗时精确等于 10 分钟。

### 移动耗时累计池
```
calculate_move_minutes(tile_count, terrain_type) -> float
  = tile_count / (base_move_tiles_per_minute × final_multiplier)

on_player_moved_tiles(tile_count, terrain_type="indoor", context="mission")
  movement_time_buffer += calculate_move_minutes(...)
  flush_movement_time(terrain_type, context)

flush_movement_time(terrain_type="indoor", context="mission")
  buffer < 1.0 → 直接返回，不推进任何时间
  否则取整数分钟推进对应时间系统，小数部分留在 buffer 里
```
需求文档给的三个算例（20 格室内=2 分钟；30 格月面平坦+初代宇航服=5 分钟；
精力低+超载+宇航服+月面崎岖 30 格=10 分钟）均已用临时脚本逐项验证。
**没有做 `movement_time_buffer` 存档**——需求文档第二十三节明确说"第一版
不存也可以，因为损失的只是小于 1 分钟的累计移动时间"，本次采纳这个建议，
`MovementTimeManager` 完全不写 `user://saves/`。

### 正式阶段 vs 训练阶段（`context` 参数，没有用 `GameState.current_context`）
需求文档建议读一个全局 `GameState.current_context`，但这个项目里
`scripts/game_state_manager.gd` 虽然存在，**从来没有注册成 autoload**
（`project.godot` 里没有它），也没有任何脚本在用它做 training/mission
分支判断。本次没有新增这个 autoload 依赖，而是让调用方（场景脚本自己
知道自己是训练场景还是正式场景）显式传一个 `context` 字符串：
```
"mission"（默认）→ TimeManager.advance_time(minutes, "move")
"training"       → TrainingTimeManager.advance_training_time(minutes, "training_move")
```
`"move"` 这个 reason 字符串是复用既有的（`player_controller_2d.gd` 原本
就用它），`TimeManager` 的 `_apply_health_action_cost()`/
`_apply_power_action_cost()`/`_apply_water_action_cost()` 三处已经把
`reason == "move"` 排除在外，所以走路不会意外触发任何固定的一次性
健康/电力/水消耗，只单纯推进时间——这是本来就有的行为，没有改动。

### 顺手修复的 Bug：训练场景移动此前一直在推进正式 TimeManager
`training_module_scene.gd`（5 个训练模块+最终考核共用）的
`_move_player()`/`_ensure_player_controller()` 一直把 `_time_manager()`
（正式 TimeManager）传给 `player_controller_2d.gd` 的 `set_time_manager()`
/`configure()`，而控制器内部按 64px 一档、每档固定 1 分钟直接调
`time_manager.advance_time()`——也就是说，**训练阶段玩家走路这件事，
从"训练时间系统 v1"那次改造开始就一直在悄悄推进正式月球任务的
`TimeManager.total_minutes`**，完全没有被那次改造覆盖到（那次只处理了
`_advance_time_for_step()`，也就是脚本化的交互步骤，没有想到移动本身
是另一条独立的报时路径）。本次顺手修了：`training_module_scene.gd` 现在
额外调用 `player_controller.set_movement_time_manager(_movement_time_manager())`
并把 `movement_context` 设成 `"training"`，训练场景的移动从此走
`TrainingTimeManager`，不会再碰正式时间。已用临时脚本验证："mission"
上下文移动完全不改变 `TrainingTimeManager.serialize()` 快照，
"training" 上下文移动完全不改变 `TimeManager.serialize()` 快照——两个
方向都测过。

### `player_controller_2d.gd` 的改动（新增字段，行为向后兼容）
```
var movement_time_manager: Node   # 新增，可选
var terrain_type := "indoor"      # 新增，可选
var movement_context := "mission" # 新增，可选
```
`_advance_time_steps(steps)` 现在**优先**委托给
`movement_time_manager.on_player_moved_tiles(steps, terrain_type,
movement_context)`（如果这个字段被设置过）；**只有在没有任何场景调用
`set_movement_time_manager()` 时**才会落回原来的"每步固定 1 分钟直连
`time_manager.advance_time()`"逻辑——这条 fallback 路径完全没有删除，
保证即使未来有其他调用方没跟着接入 `MovementTimeManager`，也不会突然
连时间都不推进了，只是拿不到新的倍率/训练隔离效果。`sprint06_base_scene.gd`
（10 个场景共用）和 `training_module_scene.gd` 都已经接入。

### 地形判定（没有逐格地图，按场景默认）
目前没有任何"每个格子是什么地形"的数据，`terrain_type` 是**按场景**给的
默认值，不是玩家走到哪个格子动态判断：
```
sprint06_base_scene.gd._current_terrain_type()：
  scene_kind == "solar_array" → "lunar_flat"（目前只有
  SolarArrayExteriorScene.tscn 用这个 scene_kind）
  其余全部 → "indoor"
training_module_scene.gd：训练房间固定 "indoor"
```
`old_base_clutter`/`lunar_rough` 两档目前没有任何场景在用，是给以后细分
地形预留的等级。

### 宇航服资源消耗（`get_suit_activity_type(terrain_type)`）
```
terrain_type ∈ {lunar_flat, lunar_rough} → "eva_normal"（不管穿没穿，
  但 SuitManager.consume_suit_resources() 本身在未穿戴时是空转，
  两层判断不会互相冲突）
否则：SuitManager.is_suit_worn → "indoor_worn"；未穿戴 → "none"（不消耗）
```
`flush_movement_time()` 用**实际取整推进的分钟数**（不是原始格数）调用
`SuitManager.consume_suit_resources(whole_minutes, activity_type)`——移动
越慢，实际耗时越长，消耗自然越多，不需要额外换算。

### 存档
无。`MovementTimeManager` 只有一个纯运行时累计池，本次决定不落盘
（见上）。`base_move_tiles_per_minute`/`min_move_multiplier` 也不存档，
它们目前只是常量性质的调参字段。

### UI / Debug
**没有新增专属 UI 面板**（现有 3×2 网格 + Backpack/Storage + Suit 已经
把可用的屏幕空间占满，这个系统本身也没有需要玩家频繁查看的状态，需求
文档自己也只是"建议"而非"必须"做 UI）。主菜单开发菜单新增 Movement
Debug 分组：查看状态（含当前健康/宇航服/负重倍率）、模拟 10 格室内
移动、模拟 30 格月面平坦移动、模拟 30 格月面崎岖移动、重置。

---

## 训练第一房间：宇航服整备室

### 定位
训练第一房间重构——教玩家"行动会消耗时间、出发前必须确认宇航服状态"。
**沿用既有 module_id `"suit_control"`**（`Training_01_SuitControl.tscn`），
**没有**新建独立场景文件或改名成 `"spacesuit_preparation"`：需求文档建议
的新 module_id 会牵动 `TrainingManager.are_required_modules_completed()`/
`default_data()`/`MODULE_SCENES` 和整条存档兼容路径（这些都是围绕现有
5 个必修模块写死的），重命名没有带来任何功能收益，只有风险，所以选择
在既有 `training_module_scene.gd`（5 个训练模块+最终考核共用的场景脚本）
的通用"步骤数组"引擎上重新配置这一个模块的内容，而不是另起一套系统。

### 新的 4 步流程（`_suit_control_config()`）
```gdscript
"targets": [
    {"id": "suit_rack", "kind": "tool_station", "label": "宇航服整备架", ...},
    {"id": "exit", "label": "模拟气闸舱入口", ...},
],
"steps": [
    {"type": "move", "target": "suit_rack", "objective": "移动到宇航服整备架", ...},
    {"type": "wear_suit_confirm", "target": "suit_rack", "objective": "按 E 穿戴宇航服", ...},
    {"type": "suit_status_panel", "target": "suit_rack", "objective": "按 Tab 查看宇航服状态面板",
     "state_updates": {"SuitStatusConfirmed": true, "ExitDoorUnlocked": true}, ...},
    {"type": "interact", "target": "exit", "objective": "进入模拟气闸舱",
     "requires": {"ExitDoorUnlocked": true}, "blocked_hint": "请先确认宇航服状态。", ...},
],
```
`"suit_rack"` 的 `"kind": "tool_station"` 复用了既有的
`res://scenes/props/training/ToolStation.tscn` 道具场景（没有新建美术
资产——道具/场景美术不在这次改动范围内，`kind` 缺省会退化成 `id` 本身，
而 `"suit_rack"` 不是任何已知 kind，会画不出东西，所以必须显式指定）。
删掉了原来的 `"marker"` 目标和它对应的"移动到标记区域"步骤——新流程第
一步直接就是"移动到宇航服整备架"，不需要额外的标记点。

**门锁完全靠步骤顺序 + `requires`/`blocked_hint` 实现，没有引入新的
"门"节点/锁定状态机**：`training_module_scene.gd` 的步骤引擎本来就是
严格按 `step_index` 顺序推进的（`_try_interact()` 永远只处理
`_current_step()`），玩家在完成前三步之前物理上够不着最后一步的 "exit"
——`requires: {"ExitDoorUnlocked": true}` 是跟着 `airlock_procedure` 模块
里 "outer_door" 步骤同款的belt-and-suspenders 写法（那个模块的
"PressureStable"/"InnerDoorClosed" 检查同样technically 已经被顺序保证了，
这里跟随既有代码风格）。

### 两个新增的步骤类型
```
wear_suit_confirm：
  E 键在 "suit_rack" 附近触发 _show_wear_suit_confirm_dialog()——复用跟
  plant_control 步骤同一套弹窗基础设施（scrim + PanelContainer + 按钮），
  只是换成"确认穿戴"/"取消"两个按钮而不是选项列表。"确认穿戴"调用
  SuitManager.wear_suit_training()（见下），成功才 _complete_step()。

suit_status_panel：
  不通过 E 触发（E 按下时只提示"请按 Tab 查看宇航服状态面板。"，跟
  diagnosis 步骤类型的早退模式一样）。Tab 键（既有的 "mission_panel"
  action，所有模块通用）现在做了条件分支：_toggle_mission_panel() 检查
  当前步骤类型是不是 "suit_status_panel"，是的话打开新的
  suit_status_modal（而不是常规的任务总览 left_panel），其余所有模块的
  Tab 行为完全没变。面板内容来自
  SuitManager.get_suit_status_for_ui()，"确认状态"按钮点击后调
  _on_confirm_suit_status_pressed() -> _complete_step()（顺带触发
  state_updates 里的 ExitDoorUnlocked=true）。
```

### `SuitManager.gd` 新增（跟正式宇航服系统共用同一个实例，见下"边界"）
```
wear_suit_training() -> bool
  跟 wear_suit() 一样的前置条件（suit_storage_state == "ready"），但推进
  的是 TrainingTimeManager.advance_training_time(15, "training_wear_spacesuit")，
  不是正式 TimeManager。已用临时脚本验证：调用后正式 TimeManager 的
  serialize() 快照完全不变，TrainingTimeManager 的 elapsed_minutes 精确
  +15。

get_suit_status_for_ui() -> Dictionary
  返回 oxygen/oxygen_capacity/power/power_capacity/speed_multiplier
  五个键。
```

**后续更新（应用户要求移除）**：最初这一轮曾加过
`suit_seal_status`/`suit_comm_status` 两个纯展示字段（密封状态/通信
链路，需求文档给的示例字段名，没有任何机制读取它们做判断），以及
`_seal_label()`/`_comm_label()`、`get_suit_status_for_ui()`/
`panel_status_text()`/`serialize()`/`deserialize()`里对应的展示/存档
分支，还有 `training_module_scene.gd` 状态面板文案里的"密封状态"/
"通信链路"两行和 `_suit_seal_label()`/`_suit_comm_label()`。用户后来
明确要求去掉这两个概念，已整体移除（`SuitManager.gd`/
`training_module_scene.gd` 都改了，`scripts/ui/suit_panel.gd` 只读
`panel_status_text()` 聚合文本，未受影响）。旧存档里如果残留
`suit_seal_status`/`suit_comm_status` 键，`deserialize()`的
`data.get(key, default)`模式会安全忽略，不会报错。
**没有新增 `is_suit_worn() -> bool` 方法**——需求文档建议这个接口名，但
`SuitManager` 已经有一个同名的公开字段 `is_suit_worn: bool`（正式宇航服
系统那次加的），GDScript 不允许同一个类里字段和方法同名，调用方应该直接
读这个字段（`suit_manager.get("is_suit_worn")`），不需要额外包一层方法。

### 与正式宇航服系统的边界（需求文档第十八节三选一，选的是最简单那条）
需求文档给了三种做法（`SuitManager` 支持 training context / 独立的
`TrainingSuitState` / 训练直接用 `SuitManager`，正式任务开始前重置）。
本次选的是第三种——**训练和正式任务共用同一个 `SuitManager` 实例，不做
数据隔离**，理由：
- `TrainingManager.reset_progress()`（"重置训练进度"debug 按钮 already
  wired）已经会重置 `SuitManager`（正式宇航服系统上线时就接进去了）。
- 正式任务真正的开局重置路径是 `TimeManager.reset_to_arrival()`
  那条链——`SuitManager.reset_to_arrival()` 目前**没有**被这条链自动
  调用（正式宇航服系统本来就没接进 `TimeManager`/`BaseStatusManager` 那条
  reset 链，只被 `sprint06_base_scene.gd`/`training_manager.gd` 各自的
  存档 load/save 路径覆盖）。也就是说：如果玩家在训练里穿了宇航服，然后
  不经过"重置训练进度"直接进入正式任务，训练时留下的宇航服状态
  （`is_suit_worn=true` 等）会带进正式任务——**这是本次已知的、故意没有
  堵上的缺口**，见下方已知问题。

### 存档
`suit_state.json` 新增 `suit_seal_status`/`suit_comm_status` 两个字段
（跟其余字段一起走同一个 `serialize()`/`deserialize()`）。

### 已知问题 / 暂不覆盖范围
- **训练宇航服状态可能"泄漏"进正式任务**：见上方"边界"一节——
  `SuitManager` 没有被正式任务开局的 `TimeManager.reset_to_arrival()`
  链自动重置，如果玩家训练时穿了宇航服、没点"重置训练进度"就直接进入
  正式任务，`is_suit_worn`/`suit_oxygen` 等会带着训练时的值进入正式游戏。
  下一轮如果要彻底堵上，需要在正式任务真正开始的那个时间点（`accept_assignment()`
  或类似的"接受派遣"流程）显式调一次
  `SuitManager.reset_to_arrival()`，本次没有做这个改动（不确定这是不是
  会跟正式任务里"玩家已经拥有升级过的宇航服"这类未来设计冲突，留给下一轮
  决定）。
- `suit_seal_status`/`suit_comm_status` 纯展示，没有任何机制会改变它们
  或读取它们做判断——完全是为了满足需求文档"面板要显示密封/通信"这条
  UI 要求新增的两个字段。
- 第二训练区"模拟气闸舱"复用的是**已经存在**的 `airlock_procedure` 模块
  （`Training_02_AirlockProcedure.tscn`），不是需求文档提到的全新
  `AirlockSimulationRoom.tscn`——`_suit_control_config()` 的
  `"next_module"`/`"next_scene"` 本来就指向它，本次没有改动
  `airlock_procedure` 模块本身的任何内容。

## 训练第三房间：太阳能阵列训练场

### 定位
训练模块 03——"月面太阳能板维修"。教玩家：出舱后宇航服资源持续消耗、
故障排查是"诊断选择"不是"按按钮"、选错方向会浪费训练时间和备件。
**沿用既有 module_id `"power_repair"`**（`PowerRepairCompleted` 存档字段/
`MODULE_SCENES` 条目不变），但换成全新场景文件
`res://scenes/training/SolarArrayTrainingField.tscn`
（`training_module_scene.gd` 里 `_power_config()` 整个换了新内容）。旧的
`Training_03_PowerRepair.tscn` 原样保留、未删除、不再被引用。理由同训练
房间一保留 `"suit_control"`：改名会牵动
`TrainingManager.are_required_modules_completed()`/`default_data()`/
`MODULE_SCENES` 和存档兼容路径，没有功能收益。

### 入场门禁：必须已经穿好宇航服
`_ready()` 里新增：若 `module_id == "power_repair"` 且尚未通关，检查
`SuitManager.is_suit_worn`；为 `false` 就把新的 `entry_blocked: bool` 设
为 `true`，`_process()`/`_unhandled_input()` 提前 return（禁止移动/交互），
并把已有的 `briefing_modal`（原本是"确认，开始训练"简报）内容整体替换成
"无法进入训练"错误 + 单个"返回主菜单"按钮（`_show_entry_blocked_dialog()`，
复用同一个 modal 节点，不是新建弹窗系统）。

### 顺手挖到的一个真实 Bug：`TrainingManager.load_progress()` 会吃掉跨模块的宇航服状态
写入场门禁时发现：**`set_current_module()`/`mark_module_completed()` 都是
先 `load_progress()` 再 `save_progress()`**，而 `load_progress()` 除了读
存档 flag，还会把 `TimeState`/`HealthState`/…/`SuitState` 等全部
`deserialize()` 回各个 manager——也就是说，每次调用都会把"当前存档里最后
一次 `save_progress()` 时的快照"强制盖回活的 manager 上。之前没人发现，
是因为训练房间一~二都没有任何逻辑依赖"穿宇航服"这件事跨模块存活；
本模块的入场门禁第一次真正依赖它，一测就复现：模块一入场时
`set_current_module("suit_control")` 先把 `is_suit_worn=false` 存进
`training_progress.json`；玩家随后穿上宇航服（只改了 live 内存 +
`suit_state.json`，没碰 `training_progress.json`）；模块一结束时
`mark_module_completed()` 又 `load_progress()` 一次，把
`training_progress.json` 里那份**穿之前**的旧快照重新解码回
`SuitManager`，`is_suit_worn` 被悄悄改回 `false`——玩家实际穿了，
但活着的 manager 状态被撤销了，模块三的门禁就会永远拦下所有人。

**修复**（`training_manager.gd`，纯新增，`load_progress()` 对外行为不变）：
拆出一个新的私有 `_read_progress_data() -> Dictionary`，只做"读 JSON、
merge 进 `default_data()`"这一步，不带任何 manager 反序列化副作用；
`load_progress()` 本身保持原样（先调 `_read_progress_data()`，再照旧对
每个 manager 调 `deserialize()`）——凡是真的需要"从磁盘整体恢复"的调用方
（`assignment_black_screen_scene.gd`/`mission_assignment_notice_scene.gd`/
`main.gd` 的状态查询）完全不受影响。只把 `set_current_module()` 和
`mark_module_completed()` 内部改成调 `_read_progress_data()`——这两个函数
本来就只是想读/改存档 flag，不需要也不该顺带把活的 manager 状态重置成
上一次快照。已用临时脚本验证：`wear_suit_training()` → 同一 session 内
`mark_module_completed()` → `set_current_module()`（下一模块入场），
`is_suit_worn` 全程保持 `true`。

### 训练备件容器：`InventoryManager` 新增的"训练容器"概念
不碰真实背包/`StorageManager`，`InventoryManager.gd` 新增一块完全独立的
`training_containers: Dictionary`（`reset_to_arrival()` 会清空，**不**参与
`serialize()`/`deserialize()`，本来就不需要跨存档持久化）：
```gdscript
create_container(container_id) -> void
clear_container(container_id) -> void
add_item_to_container(container_id, item_id, amount:=1) -> bool
remove_item_from_container(container_id, item_id, amount:=1) -> bool
has_item_in_container(container_id, item_id, amount:=1) -> bool
get_container_item_count(container_id, item_id) -> int
```
没有重载现有的 `add_item(item_id, amount)`——需求文档伪代码写的是同名
`add_item("training_03_parts", "TR-MT-001", 2)`，但 GDScript 不支持真正
的方法重载，复用同名不同参数语义是个坑，所以另起了一套明确命名的接口。
模块三场景 `_ready()`（未阻塞时）调用 `_setup_training_03_container()`：
`create_container("training_03_parts")` → `clear_container(...)`（保证重
试也是满配置）→ `TR-MT-001 通用备件 x2` + `TR-MT-002 训练电子元件 x1`。
`_finish_module()` 里 `module_id == "power_repair"` 分支会
`clear_container("training_03_parts")` 收尾。

### 新增物品（`ItemDatabase.gd`，training-only）
`TR-MT-001` 通用备件 / `TR-MT-002` 训练电子元件——`category: "material"`,
`subcategory: "training"`，只在 `training_03_parts` 容器里出现，不会流入
真实背包/仓库。

### 新故障卡：`FA-TR-SOLAR-001`（`FaultDatabase.gd`）
**没有**扩展现有的 `_option()` 静态 helper（16 张既有故障卡在用，改它的
签名风险大于收益）——这张新卡的 4 个选项直接写成 Dictionary 字面量，
带了 `_option()` 没有的字段：`option_type`/`suit_oxygen_cost`/
`suit_power_cost`/`energy_cost`/`result_message`/`new_hint`。四个选项
（`required_items` 字段对正确/错误选项都通用，没有 `_option()` 那套
"错误选项用 `wrong_item_loss`" 的区分——写 `RepairManager` 训练分支时第
一版照抄了 `wrong_item_loss` 字段名，被验证脚本抓到错误选项没扣到材料，
已修正为统一读 `required_items`）：

| 选项 | 类型 | 耗时 | 材料 | 氧气/电力/精力 | 结果 |
|---|---|---|---|---|---|
| A 调整阵列角度 | suboptimal | 30min | 无 | -4/-4/-6 | 不修复，给新线索 |
| B 清理电缆接口 | correct | 30min | 通用备件x1 | -4/-4/-8 | 修复，Critical→Basic |
| C 更换太阳能控制器 | wrong | 45min | 电子元件x1 | -6/-6/-10 | 不修复 |
| D 强行切换满功率输入 | high_risk | 30min | 电子元件x1 | -5/-5/-8 | 不修复，UI 标红+二次确认 |

第一版按需求文档"不要炸毁设备，保持克制"，D 选项只在文案上写"供电系统
稳定性下降"，没有任何实际的"炸毁/永久损坏"效果。

### `RepairManager.gd` 新增：训练分支入口 `apply_repair_option()`
完全新增、平行于既有 `attempt_repair()`/`apply_repair_success()`/
`apply_repair_failure()`（这三个原样未动，仍然是任务向、写死连正式
`StorageManager`/`TimeManager`/`BaseStatusManager` 等系统）：
```gdscript
apply_repair_option(fault_id, option_id, context:={}) -> Dictionary
  context.context != "training" -> 走 _apply_mission_repair_option()（新
    包装，内部调用既有 attempt_repair()，行为对旧调用方完全透明）
  context.context == "training" -> 走 _apply_training_repair_option()：
    只认 FaultDatabase + InventoryManager 的训练容器（context.container_id）
    + TrainingTimeManager.advance_training_time() + SuitManager/HealthManager
    的资源扣减，绝不碰真实 StorageManager/TimeManager/BaseStatusManager等。
  返回 {success, fault_fixed, option_type, message, new_hint}
```
`SuitManager.gd` 新增 `consume_suit_resource_fixed(oxygen_cost, power_cost,
reason)`——跟已有的按小时费率的 `consume_suit_resources()` 不同，这是
"单次定额扣除"（训练里每个检查/维修动作都是固定花费，不是按时长算率）。
`HealthManager.gd` 新增 `consume_energy(amount, reason)`（薄包装
`adjust_stat("energy", -amount)`，训练/正式都能用）。

### 检查动作（15 分钟固定档）
新步骤类型 `inspect_solar_array_confirm`——E 触发
`_show_inspect_solar_array_confirm_dialog()`（复用
`wear_suit_confirm`/`diagnosis_modal_*` 那套弹窗基础设施），确认后
`_confirm_inspect_solar_array()`：`TrainingTimeManager.advance_training_time(15,...)`
+ `SuitManager.consume_suit_resource_fixed(2,2,...)` +
`HealthManager.consume_energy(2,...)`，硬编码这三个数值（不经过
`apply_repair_option()`，因为这只是检查动作不是维修选择）。**这一步和下
一步的诊断面板步骤都显式设了 `"time_minutes": 0`**——
`_default_time_minutes_for_step()` 的兜底关键字匹配（"检查"/"确认"命中
30 分钟档）否则会在 `_complete_step()` 里对本已手动推进过的训练时间
再重复加一次 30 分钟。

### 维修方案面板（`solar_fault_diagnosis` 步骤类型）
不经过 `_try_interact()`（E 键只提示"请在维修方案面板中选择一个排查方向。"，
diagnosis 步骤同款早退），改成 `_update_hud()` 检测到当前步骤类型是
`solar_fault_diagnosis` 就自动弹出 `_show_solar_fault_diagnosis()`
（同样复用 `diagnosis_modal_*`，四个选项按钮动态从
`FaultDatabase.get_fault("FA-TR-SOLAR-001")` 生成；D 选项按钮标红
+ 点击先走 `_show_high_risk_repair_confirm()` 二次确认，不是直接执行）。
按钮点击都走 `_execute_solar_repair_option(option_id)` ->
`RepairManager.apply_repair_option(...)`；`fault_fixed=true` 才
`_complete_step()`，否则面板保留在原地允许重试，并检查
`training_03_parts` 里 `TR-MT-001` 是否耗尽
（`_check_solar_parts_depleted()`）。

### 训练供电状态：`Critical -> Basic`
纯场景本地状态，`module_data["state"]["SolarArrayRepaired"]: bool`——
`training_manager.gd` 是纯静态函数工具类，没有实例变量放
`training_power_status`，需求文档伪代码假设了一个不存在的实例，改用跟其
它所有训练模块状态同款的场景内 state dict 写法，不需要改
`training_manager.gd`。

### 专业提示 / 低资源提示
`_solar_specialist_hint()` 读法跟 `BaseStatusManager.get_specialist_hint()`
一致（`user://saves/application_profile.json` 的 `EducationBackground`），
只提示不改数值/不减耗时/不点破正确答案。`_eva_resource_warning()`
（氧气/电力 <20 只提示不强制失败——真正的失败仍然是
`TrainingTimeManager.check_training_timeout()` 统一触发的训练档案超时，
本模块没有另写超时系统）。

### 失败：训练备件耗尽
`_check_solar_parts_depleted()` 在每次维修尝试后检查：`TR-MT-001`
数量为 0 且故障仍未修复 -> `TrainingManagerScript.fail_training(
"training_03_parts_depleted")`（跟 `TrainingTimeManager` 的
`"archive_time_expired"` 走同一个 `fail_training()` 出口，只是原因字符串
不同——这个函数本身只是打标记 + 停训练计时器，不会自己切场景，跟既有的
超时失败路径行为完全一致）。

### 存档
`training_containers` 不参与持久化（见上）。`FA-TR-SOLAR-001` 的 4 个
选项 Dictionary 字面量不经过 `_option()`，不影响其余故障卡的存档格式。

### 已知问题 / 暂不覆盖范围
- D 选项"强行切换满功率输入"目前只有文案层面的"稳定性下降"，没有实际
  数值/状态惩罚——第一版故意保持克制，不做"炸毁设备"效果，下一轮如果要
  加真实惩罚需要另外设计。
- `TrainingManager.load_progress()`/`_read_progress_data()` 的拆分只修了
  `set_current_module()`/`mark_module_completed()` 这两个已知会在训练
  中途调用、因而会撞见"live 状态领先于上次快照"的调用点；`start_training()`
  仍然用原始 `load_progress()`（这是训练最开始只调一次的入口，当时不存在
  "live 状态已经改变但还没存盘"的情况，风险低，本次没有动它）。

## 训练小型地图：`TrainingBaseMap.tscn` / `training_base_map.gd`

### 定位
应用户要求，把训练系统从"6 个各自独立的整场景关卡，靠脚本切场景衔接"改造成
"一张小型可走动地图"（用户原话：现在的地图系统"跟星露谷不一样"，感觉很乱）。
新场景 `scenes/training/TrainingBaseMap.tscn` + 全新脚本
`scripts/training/training_base_map.gd`——**完全不修改、不复用
`training_module_scene.gd` 的引擎代码**，只是从它 preload 出来的脚本对象上
直接引用几个自包含、无状态耦合的内部可视化类（`TrainingRoomBlockout`/
`AirlockRoomBlockout`/`PowerRepairRoomBlockout`/`LifeSupportRoomBlockout`/
`PlantDiagnosisRoomBlockout`/`TrainingTargetVisual`/`TraineeVisual`，比如
`TrainingModuleSceneScript.AirlockRoomBlockout.new()`），避免重复画一遍
房间美术，但完全不牵动它的 `module_id` 分支引擎。

### 太阳能阵列训练场（训练 03）仍然是独立场景——关键偏离点
训练 03 背后的宇航服穿戴检查/独立维修材料仓库/四选一故障诊断/高风险二次确认
逻辑全部写死在假设"这是一整个独立场景"的旧引擎里，风险高、收益低，因此**保留
`SolarArrayTrainingField.tscn` 完全不变**，衔接点是气闸舱的"外舱门"——
`training_module_scene.gd` 里 `_power_config()` 只改了一行：
`"next_scene"` 从旧的 `MODULE_04` 改成 `TrainingManagerScript.TRAINING_BASE_MAP`
（回到大厅时会精确定位到气闸舱，而不是随便一个房间，见下"入场路由"）。
用户自己的需求文档第十七条已经明确允许这个做法（"如果开发成本更低，优先使用
单场景多区域"/"太阳能阵列训练场也可以作为同场景下的外部区域，或单独场景"）。

### 房间面板切换（不是真的连续 2D 世界，也不是场景重载）
新场景内同时建好 6 个房间：训练中控室（hub，全新内容）/宇航服整备室/模拟
气闸舱/配电房/空气系统控制室/训练温室，但同一时刻只有 `current_area_id`
对应的那个房间的 `training_area` 内容是活的——走到门口（`_check_door_crossing()`
每帧检测玩家是否踩进某个带 `door_to` 字段的 target）触发 `_switch_room()`：
把当前房间的 `step_index`/`state` 存回 `areas[current_area_id]`，重建
`training_area` 的子节点（`_build_training_area()`），把玩家挪到目标房间
的出生点。没有 `change_scene_to_file()`、没有黑屏/读条，视觉上就是"走过去"。

### 每个房间的任务内容
逐字从旧的 `_suit_control_config()`/`_airlock_config()`（仅室内部分）/
`_power_distribution_config()`/`_life_support_config()`/`_plant_config()`
移植 targets/steps/state_updates/requires/blocked_hint（内容照搬，不是
照搬引擎），改动只有：
- 气闸舱最后一步（原来是"走到外部区域"）改成外舱门本身的 `interact` 步骤，
  完成时通过 `step.on_complete = "airlock_procedure"` 触发
  `_on_area_task_complete()` 里的 `change_scene_to_file(MODULE_03)`。
- 每个房间原来"确认后单独再走到 exit 交互一次"的两段式收尾，简化成"最后一步
  完成 = 立刻推进"，去掉了原引擎的 `completed` 二次确认。
- 每个非 hub 房间新增一个 `door_hub`/`door_suit` 之类的门 target，回中控室
  或回宇航服整备室。
- 原引擎那些针对每个 target 的 `status_text`/地板高亮细节没有逐一移植——
  这是本轮明确的降范围决定（"小地图，不是探索/美术展示"），只保留了
  `PowerRepairRoomBlockout`/`LifeSupportRoomBlockout`/`PlantDiagnosisRoomBlockout`
  三个地板类的整体状态开关（`power_on`/`stable`/`plant_stable` 等）。

### 门锁：从已有的 6 个训练完成标记直接推导，没有新存档结构
`_compute_unlocked(area_id, progress)` 每次场景加载时读
`TrainingManager._read_progress_data()` 的 6 个既有 `*Completed` 标记，
直接算出 `areas[area_id].unlocked`——`hub`/`suit_prep_room` 恒为 true，
`airlock_simulation_room` 依赖 `SuitControlCompleted`，
`power_distribution_room` 依赖 `PowerRepairCompleted`，
`air_system_control_room` 依赖 `PowerDistributionCompleted`，
`greenhouse_room` 依赖 `LifeSupportCompleted`。**唯一新增的持久化字段**是
`TrainingManager.default_data()` 里的 `PowerRepairUnlockToastShown: false`
——因为"太阳能阵列基础输出已恢复。请返回基地，进入配电房。"这条提示需要在
玩家从独立场景走回大厅的第一次触发，且只触发一次。锁门/需要宇航服提示
（`该训练区尚未解锁。请先完成当前训练目标。`/`该区域需要穿戴宇航服。`）
逐字照抄需求文档。

移动限制不需要碰共用的 `player_controller_2d.gd`——因为同一时刻只有一个
房间是活的，锁门检查只发生在"要不要允许穿过这扇门"这一步
（`_try_enter_area()`），不是移动系统本身的职责。

### 宇航服归位（训练收尾）
`suit_prep_room` 自己的 3 步（移动/穿戴确认/状态确认）只覆盖训练 01 的开场
流程。归还宇航服不是第 4 步，而是单独一个常驻检查
（`_try_interact_suit_return()`）：只有当
`TrainingManager.are_required_modules_completed()`（6 个模块全部完成）
且玩家站在 `suit_rack` 附近且宇航服仍穿着时才可用，确认后调用
`SuitManager.remove_suit_to_service_station_training()`，成功则
`change_scene_to_file(TrainingManagerScript.FINAL_ASSESSMENT)`——**沿用
`FinalAssessmentScene.tscn` 里 `_suit_return_config()` 已有的终端/结果/
派遣出口三步，完全没有改动那个场景**，好处是不用在大厅里重新实现"查看
训练结果"这一段。

### 入场路由（`_route_initial_area()`）：`CurrentTrainingModule` -> 具体房间
`TrainingManager.MODULE_SCENES` 现在把 `suit_control`/`airlock_procedure`/
`power_distribution`/`life_support`/`plant_diagnosis`/`final_assessment`
全部指向同一个 `TRAINING_BASE_MAP`（`power_repair` 仍单独指向
`SolarArrayTrainingField.tscn`），场景加载时按 `CurrentTrainingModule` 决定
`current_area_id`（例如 `"life_support"` -> `air_system_control_room`）。
有一个特殊分支：如果 `PowerRepairCompleted` 刚变 true 但
`PowerRepairUnlockToastShown` 还没置位，说明玩家是刚从太阳能阵列训练场
走回来的，这时候强制落在 `airlock_simulation_room`（出生点在外舱门内侧，
`Vector2(600,340)`）而不是直接跳到配电房，呼应需求文档"训练03完成后，玩家
需要通过气闸返回室内"，同时补一次性弹出解锁提示、把标记位设为 true。

**防御性加固**：这条路由是直接把玩家放进某个房间，不经过 `_try_enter_area()`
的宇航服检查——如果目标房间 `requires_suit` 但宇航服没穿（正常状态机走不到
这一步，但防止存档被手动改坏），会强制退回 `suit_prep_room`，不会让玩家
凭空出现在一个理论上进不去的房间里。

### 与正式移动/时间系统的边界
`_move_player()` 每帧都设置 `player_controller.terrain_type = "indoor"`、
`player_controller.movement_context = "training"`，走
`MovementTimeManager.on_player_moved_tiles()` 这条现成的路
（`context == "training"` 时只会调 `TrainingTimeManager.advance_training_time()`，
不会碰正式 `TimeManager`——这个分支本来就已经支持训练/正式两种场景，本轮
没有改动 `MovementTimeManager.gd`/`TrainingTimeManager.gd` 一行代码）。

### Dev 菜单
`main.gd` 的"Dev Only: Training Module 01/02/04/05/06"按钮现在都跳到同一个
`TRAINING_BASE_MAP`，跳转前调用新增的
`TrainingManagerScript.dev_force_unlock_up_to(module_id)`（纯 dev 用途，
把目标模块之前的所有完成标记强制置 true，否则跳进大厅会发现目标房间显示
"锁定"）。新增一个"Dev Only: Training Base Map (Hub)"按钮直接进大厅。
"Dev Only: Training Module 03"/"Dev Only: Final Assessment"两个按钮完全
没有改动（仍然各自独立指向 `SolarArrayTrainingField.tscn`/
`FinalAssessmentScene.tscn`）。

### 存档
`areas` 字典（含每个房间的 `step_index`/`state`/`unlocked`）完全是场景本地、
一次性的缓存，每次场景加载都从 `TrainingManager` 的既有 6 个标记重新推导，
不参与持久化——真正持久化的只有 `TrainingManager.default_data()` 里新增的
那一个 `PowerRepairUnlockToastShown` 布尔值。

### 验证
临时脚本（未提交，验证后已删除）覆盖：初始解锁状态（仅中控室+宇航服整备室）
→ 训练01完成解锁气闸 → 训练03完成解锁配电房+正确落在气闸舱出生点 → 训练04
完成解锁空气系统控制室 → 训练05完成解锁温室 → 训练06完成后
`are_required_modules_completed()` 为 true；未穿宇航服无法进入气闸舱、穿好后
可以进入；`_move_player()` 后 `terrain_type=="indoor"`、
`movement_context=="training"`、`movement_time_manager` 非空；房间内任务
完成不触发场景重载（`current_area_id` 不变但目标房间正确解锁）；正式
`TimeManager.serialize()` 前后完全一致。另外用 headless 逐一加载了全部
训练/主菜单场景，均无 `SCRIPT ERROR`/`Parse Error`。

### 已知问题 / 暂不覆盖范围
- 没有真正的连续 2D 世界/摄像机/寻路——是"房间面板互斥切换"，不是像
  星露谷那样能看到相邻房间、无缝行走的地图。这是本轮明确的降范围决定
  （详见需求文档"训练地图不是探索地图"这条设计原则），如果后续想要更接近
  星露谷的体验，需要专门做一版真正的 2D 世界/摄像机系统，工作量会大很多。
- 原引擎里每个 target 的精细状态展示（比如生命支持面板从"偏低"到"稳定"
  逐步变色）没有逐一搬过来，只留了房间整体地板的开关状态。
- 旧的 `Training_01_SuitControl.tscn`/`Training_02_AirlockProcedure.tscn`/
  `Training_04_PowerDistribution.tscn`/`Training_05_AirSystemControl.tscn`/
  `Training_06_TrainingGreenhouse.tscn` 五个独立场景文件原样保留、不再被
  `MODULE_SCENES` 引用，但仍然是完整可运行的（各自的 `module_id` 配置函数
  在 `training_module_scene.gd` 里没有删除）。

## 玩家状态系统 PlayerStateManager

### 定位
新增 autoload `/root/PlayerStateManager`
（`scripts/managers/PlayerStateManager.gd`），是"玩家此刻处于什么状态"的
统一状态入口/注册表，供 UI、训练系统、地图、交互、宇航服系统查询。
**它只记录与查询状态，不做任何玩法计算**：不算健康、不算宇航服氧气/电力、
不做物品增删或使用效果、不算移动耗时、不算维修结果、不推进任何时间。
这些仍分别归 HealthManager / SuitManager / Inventory+BackpackManager /
MovementTimeManager / RepairManager / TrainingTimeManager。

### 核心字段
```
current_context: String            # "training" / "mission"（只报告用哪套时钟，自己不推时间）
current_area_id / _name / _type    # 区域标识；type 如 interior/airlock/exterior_training/greenhouse/power_room
is_in_pressurized_area: bool
is_in_exterior_area: bool           # = not has_air
is_in_airlock: bool                 # = (area_type == "airlock")
can_move / can_interact / is_busy   # 移动/交互锁
is_suit_worn: bool                  # 宇航服穿戴快照（SuitManager 推送，SuitManager 才是真相源）
held_item_id / selected_hotbar_slot # 当前手持/快捷栏（只记 id，不碰背包）
current_interaction_id/_type/_label # 当前交互目标（"按 E …" 指向的东西）
```

### 主要接口
- Context：`set_context` / `is_training_context` / `is_mission_context` / `get_context`
- 区域：`set_current_area(area_data)` / `set_current_area_by_values(id,name,type,has_air,is_pressurized)` /
  `get_current_area_id` / `get_current_area_name` / `get_current_area_type` /
  `is_exterior_area` / `is_pressurized_area` / `is_airlock_area`
- 锁：`set_can_move` / `set_can_interact` / `set_busy` / `can_player_move` / `can_player_interact`
- 宇航服：`set_suit_worn` / `get_is_suit_worn` / `sync_suit_state_from_suit_manager`
- 进入规则：`can_enter_area_requires_suit(bool)` / `can_enter_current_area_rules(area_data)`
- 手持：`set_held_item` / `clear_held_item` / `get_held_item_id` /
  `set_selected_hotbar_slot` / `get_selected_hotbar_slot`
- 交互：`set_current_interaction(id,type,label)` / `clear_current_interaction` /
  `get_current_interaction_id/_type/_label` / `has_current_interaction`
- 生命周期/存档：`reset_to_arrival` / `serialize` / `deserialize`（并入
  `TrainingManager` 的 `PlayerStateManagerState` 存档包；只持久化
  context/area_id/suit/held/hotbar 这几项，交互目标与瞬时锁在进场景后重算）
- 信号：`player_state_changed`（各 setter 变化时发出，UI 可订阅而非轮询）

### 相对 GPT 原始指令的两处优化
1. **`set_busy` 不再连带清空 `can_move`/`can_interact`**：原指令里
   `set_busy(false)` 会把两者强制设回 true——这是坑（打开面板设了
   can_move=false，之后某个无关的 busy 动作结束会误把移动放开）。改为
   `is_busy` 是独立轴，`can_player_move()`/`can_player_interact()` 已经把
   is_busy 一起 AND 进去，清 busy 只恢复面板/过场各自设定的锁，不越权。
2. 各 setter 带"值未变则不发信号/不写"的短路，避免每帧推送（地图的
   `_update_room_prompt` 每帧调 `set_current_interaction`）造成信号刷屏。

### 接线点（本轮已接）
- `SuitManager`：wear/remove（正式+训练四个变体）、reset_to_arrival、
  deserialize 后调 `_sync_player_state_suit_worn()` 推 `set_suit_worn`。
  PlayerStateManager `_ready()` 也会 `sync_suit_state_from_suit_manager()`
  兜底（autoload 顺序：SuitManager 在前、PlayerStateManager 在后）。
- `training_base_map.gd`：`_load_area()` 推 context+area
  （hub 各房间 interior/有气/加压，气闸 type=airlock）；
  `_update_room_prompt()` 推/清 `current_interaction`。
- `training_module_scene.gd`：`_ready()` 推 area——power_repair
  = `solar_array_training_field` / exterior_training / 无气 / 非加压，
  其余（最终结算）= interior。
- 尚无 `AreaManager`（项目里不存在）；未来若新增，进入区域时改由
  `AreaManager.set_current_area(area_data)` 统一推送即可，接口已就绪。

### 存档
并入 `TrainingManager` 的存档包（`default_data()` 新增
`PlayerStateManagerState`；`save_progress`/`load_progress`/`reset_progress`
各加一段，跟其余 12 个 manager 同款模式）。没有单独的 json 文件。

---

## 舱门系统 DoorStateManager / DoorTypeDatabase / DoorAssetDatabase

### 定位
一套三层的舱门编号 / 类型 / 状态系统。**只管门本身：注册、状态、能不能过、
气闸互锁、存档；不移动玩家、不切场景、不推进时间**（穿门后的房间切换、坐标
放置、时间消耗仍由调用方——目前是 `training_base_map.gd`——自己负责）。
这不是"数值系统"，是状态/数据系统，故不计入开头的八套核心，跟 RepairManager /
SuitManager 一样是追加系统。

代码位置：
- `scripts/data/DoorTypeDatabase.gd`（纯数据，`extends RefCounted`，`preload()`
  引用，无 autoload）——门**类型**规则库。
- `scripts/data/DoorAssetDatabase.gd`（纯数据，同款写法，无 autoload）——门
  **美术资源**编号库。
- `scripts/managers/DoorStateManager.gd`（autoload `/root/DoorStateManager`，
  `class_name GuanghanDoorStateManager`）——门**实例**注册表 + 状态 + 判定。

三层关系：**门实例**（有开/锁/电/密封/对接状态）→ 引用**门类型**（定规则：
需不需要宇航服/通电/对接、是不是气闸门）→ 引用**美术资源**（定贴图/动画/
音效/占位尺寸）。

### 第一层：门实例状态字段（`DoorStateManager.register_door()` 归一化后每扇门存的字段）

| 字段 | 类型 | 含义 | 默认/回落 |
|---|---|---|---|
| `door_id` | String | 门唯一编号（必填，空则注册失败，写 `last_notice`） | — |
| `door_name` | String | 显示名 | 回落为 `door_id` |
| `door_type_id` | String | 门类型（指向第二层；非法类型回落默认） | `indoor_sliding_door` |
| `door_asset_id` | String | 美术资源编号（指向第三层） | 空则取该类型 `default_asset_id` |
| `area_a` / `area_b` | String | 门连接的两个区域 id | "" |
| `spawn_from_a_to_b` / `spawn_from_b_to_a` | String | 两个方向穿过后落地的出生点编号 | "" |
| `is_open` | bool | 是否开启 | false |
| `is_locked` | bool | 是否锁定 | false |
| `is_powered` | bool | 是否通电 | true |
| `is_sealed` | bool | 密封是否良好 | 按类型 `has_seal` |
| `is_docking_connected` | bool | 对接是否连通 | true |
| `airlock_group_id` | String | 所属气闸组（互锁分组用） | "" |
| `paired_door_id` | String | 气闸配对门 id（互锁用） | "" |

**通过判定 `can_pass_door(door_id, from_area_id)`** 按顺序检查，任一不过就返回
带中文 `message` 的失败结果（`{success,message,target_area_id,target_spawn_id}`）：
1. 门存在，且 `from_area_id` 等于 `area_a` 或 `area_b`（否则"当前位置不连接该舱门"）；
2. 未锁定（`is_locked`）；
3. 类型 `requires_power` 时须 `is_powered`（否则"舱门未通电"）；
4. 类型 `requires_docking_connected` 时须 `is_docking_connected`（否则"对接状态未确认"）；
5. 类型 `requires_suit_to_pass` 时须 `SuitManager.is_suit_worn`（否则"外部为真空环境，请先穿戴宇航服"）；
6. 类型 `is_airlock_door` 且配对门开着 → 气闸互锁拦截（"请先关闭另一侧舱门"）。

`try_pass_door()` = `can_pass_door()` 通过后把门置 `is_open=true` 并返回目标区域/
出生点；`close_door_after_pass()` 关门，避免运行态门常开。`set_door_open(true)`
本身也带气闸互锁保护（配对门开着就拒绝）。

### 第二层：门类型规则（`DoorTypeDatabase.DOOR_TYPES`，8 种）

每种类型的字段：`display_name` / `default_asset_id` / `requires_suit_to_pass` /
`requires_power` / `has_seal` / `can_lock` / `is_airlock_door` /
`requires_docking_connected`（`DEFAULT_TYPE_ID = "indoor_sliding_door"`）。

| type_id | 名称 | 需宇航服 | 需通电 | 密封 | 可锁 | 气闸门 | 需对接 | 默认资源 |
|---|---|:--:|:--:|:--:|:--:|:--:|:--:|---|
| `indoor_sliding_door` | 室内滑门 | — | ✓ | — | ✓ | — | — | DOOR-A01 |
| `airtight_hatch` | 气密舱门 | — | ✓ | ✓ | ✓ | — | — | HATCH-B01 |
| `greenhouse_hatch` | 温室气密舱门 | — | ✓ | ✓ | ✓ | — | — | HATCH-B02 |
| `airlock_inner_door` | 气闸内门 | — | ✓ | ✓ | ✓ | ✓ | — | AIRLOCK-C01 |
| `airlock_outer_door` | 气闸外门 | ✓ | ✓ | ✓ | ✓ | ✓ | — | AIRLOCK-C02 |
| `docking_hatch` | 对接舱门 | — | ✓ | ✓ | ✓ | — | ✓ | DOCK-D01 |
| `cargo_elevator_door` | 货运电梯门 | — | ✓ | — | ✓ | — | — | ELEV-E01 |
| `bulkhead_door` | 大型舱段隔离门 | — | ✓ | ✓ | ✓ | — | — | BULK-F01 |

（"✓/—" 即 true/false；只有气闸外门 `requires_suit_to_pass=true`，只有对接门
`requires_docking_connected=true`。）

### 第三层：门美术资源（`DoorAssetDatabase.DOOR_ASSETS`，8 个编号）

每个资源编号的字段：`display_name` / `texture_path` / `open_animation` /
`close_animation` / `sound_open` / `sound_close` / `size_tiles`（Vector2i 占位
格数，`DEFAULT_ASSET_ID = "DOOR-A01"`）。编号与占位尺寸：

| asset_id | 名称 | size_tiles |
|---|---|---|
| DOOR-A01 | 普通室内滑门 A01 | 2×3 |
| HATCH-B01 | 气密舱门 B01 | 2×3 |
| HATCH-B02 | 温室舱门 B02 | 2×3 |
| AIRLOCK-C01 | 气闸内门 C01 | 3×4 |
| AIRLOCK-C02 | 气闸外门 C02 | 3×4 |
| DOCK-D01 | 飞船对接舱门 D01 | 3×4 |
| ELEV-E01 | 货运电梯门 E01 | 3×3 |
| BULK-F01 | 大型舱段隔离门 F01 | 4×4 |

`texture_path` 指向 `res://assets/doors/*.png`、`*_animation`/`sound_*` 是字符串
键名——**这些美术/动画/音效资源目前都还没做，只是预置的编号占位**，等美术管线
接上时按编号补资源即可。

### 正式旧基地预置门（`DoorStateManager.reset_to_arrival()` 注册的 10 扇）

抵达时预置的正式基地导航拓扑（`door_id` → 连接）：
- `door_ship_to_cargo`（对接门）：飞船生存舱 ↔ 对接物资舱
- `door_cargo_to_control`（货运电梯门）：对接物资舱 ↔ 中控室
- `door_control_to_power` / `_to_air` / `_to_water` / `_to_greenhouse` / `_to_rest`：
  中控室 ↔ 配电房 / 空气系统室 / 水处理室 / 旧温室 / 休息室
- `door_suitroom_to_airlock`（气闸内门）+ `door_airlock_outer`（气闸外门，初始
  `is_locked=true`）：宇航服整备室 ↔ 气闸舱 ↔ 月面。这两扇同属
  `airlock_group_id="main_airlock"` 且互为 `paired_door_id`，触发气闸互锁。

> 注意：这 10 扇是**状态层预置**，`DoorStateManager` 目前**还没接入正式旧基地
> 的实际房间切换**（旧基地场景还没改用它做导航入口）。它现在真正被"用起来"
> 的地方只有下面的训练小地图。

### 训练小地图接线（`training_base_map.gd`，运行时注册）

`_ready()` 里 `_register_training_doors()` 把训练地图各区域 `targets` 里带
`door_to` 的门**运行时**注册进 `DoorStateManager`（门 id/出生点/类型都能从
target 字段推断，或用 `door_id`/`target_spawn_id`/`door_type_id` 显式覆盖）。
穿门走 `_try_pass_training_door()` → `DoorStateManager.try_pass_door()`，成功后
`_try_enter_area()` 做真正的房间切换 + 坐标放置，再 `close_door_after_pass()`。
`_sync_training_door_locks()` 按区域解锁进度同步门锁。**训练门是运行时注册、
不单独持久化为正式基地门状态**；训练自身的模块解锁规则仍归训练系统，
DoorStateManager 只是统一门状态层，不替代训练任务系统。

同批修的气闸返舱 bug：返舱流程完成后
`_restore_airlock_inner_door_walkthrough()` 恢复气闸内门回中控室的通路并重新
注册，修掉"返舱后再进气闸无法回中控室"。

### 其它接口
- 查询：`has_door` / `get_door`（深拷贝）/ `get_all_doors` / `get_doors_for_area` /
  `is_door_open/locked/powered/sealed` / `is_docking_connected` /
  `get_door_type_id` / `get_door_asset_id` / `get_door_display_name`
- 改状态：`set_door_open/locked/powered/sealed` / `set_docking_connected`
  （门不存在时返回 false + 写 `last_notice`）
- 气闸：`is_paired_airlock_door_open`
- 调试：`debug_values_text()` 逐门打印 open/locked/powered/sealed(/docking) 状态
- 信号：`doors_changed`（注册/改状态时发出）

### 存档
`user://saves/door_state.json`：`{doors, last_notice}`，`doors` 是全部门实例的
深拷贝。`load_state()` 找不到文件时回落 `reset_to_arrival()` 重建 10 扇预置门。
`deserialize()` 逐门走 `register_door()` 重新归一化（老存档缺字段会补默认值）。

---

## 惩罚系统 PenaltyManager / PenaltyDatabase

### 定位
统一管理惩罚的中央调度器 autoload `/root/PenaltyManager`
（`scripts/managers/PenaltyManager.gd`，`class_name GuanghanPenaltyManager`）。
**只做分派，不检测触发条件、不做玩法计算**——各系统检测到该罚时调
`PenaltyManager.apply_penalty(...)`，由它把一条惩罚的各项效果扇出到
时间 / 健康 / 背包仓库 / 地球补给系统。和 PlayerStateManager 一样是路由层，
不是规则引擎。**没有自己的数值**，数值都来自调用方或预设。

代码：
- `scripts/data/PenaltyDatabase.gd`（纯数据 `RefCounted`，preload，无 autoload）——
  命名惩罚预设目录。
- `scripts/managers/PenaltyManager.gd`（autoload）——分派 + 记录 + 信号。

### 入口
`apply_penalty(penalty, overrides := {}) -> Dictionary`
- `penalty`：预设 id（String，查 PenaltyDatabase）或内联描述 Dictionary。
- `overrides`：覆盖到描述上的字段（临时改 context/reason/silent/time_minutes…）。
- 返回 `{applied, effects_applied[], blocked_reason}`；发 `penalty_applied` 信号
  （即使 silent 也发，供 UI 观测）；非 silent 的进 `history`（最近 20 条）+
  写 `last_notice`。

### 惩罚描述字段
| 字段 | 效果 | 对接 |
|---|---|---|
| `penalty_id`/`display_name`/`severity`(minor/major/critical)/`reason` | 元信息 | — |
| `context` | "training"/"mission"/""(空=按 PlayerStateManager.get_context() 自动) | 决定时间路由 |
| `silent` | true 跳过 notice/history（连续环境扣减用） | — |
| `time_minutes` | 扣时间 | 训练→`TrainingTimeManager.advance_training_time`；正式→`TimeManager.advance_time` |
| `health_deltas` `{energy/fullness/nutrition/morale}` | 扣属性（负值） | `HealthManager.adjust_stat` |
| `energy_cost` | 额外耗电式精力 | `HealthManager.consume_energy` |
| `remove_items` `[{item_id,amount,source}]` | 扣物品，source=backpack/storage/any（any 先背包后仓库补差额） | `BackpackManager`/`StorageManager.remove_item`（按 `get_item_count` 钳制） |
| `supply_effect` `{type,...}` | 补给惩罚（见下） | `SupplyManager` |
| `notice_text` | 覆盖默认 notice 文案 | — |

每一路都用 `get_node_or_null` + `has_method` 守卫，目标系统缺失时该效果**优雅
跳过**（不报错），`effects_applied` 里只记实际生效的项。

### 补给惩罚 `supply_effect.type`（对接 SupplyManager 新增的加法式方法）
- `reduce_weight` `{amount}` → `apply_supply_weight_penalty`：下调**当前（即将到来）**
  补给的可用重量（一次性，钳制 ≥0；若草单超限，确认时按既有规则拒绝直到删减）。
- `delay` `{minutes}` → `delay_current_supply`：当前补给到货 + 截止时间同步后推。
- `cancel` → `cancel_current_supply`：复用既有 "missed" 状态作废当前补给窗口
  （下个窗口按原有 `handle_supply_arrival` 机制在本班到货时刻自动排期，
  玩家损失这一轮补给）。
- `force_item` `{supply_index,item_id}` → 既有 `set_forced_supply_item`。

### 已收编的现有惩罚
- **训练答错扣时**：`training_base_map.gd` 的 `_handle_wrong_choice()` 里
  15 分钟扣时（气闸充/降压、电池组处理）改走 PenaltyManager（silent；居中渐隐
  文字仍由训练地图自己出）。带回退：PenaltyManager 缺失时直接扣训练时间。
- **每小时环境 morale 扣减**：`BaseStatusManager`（电力/舱压/温度）、
  `AirSystemManager`（O₂/CO₂）、`WaterSystemManager`（缺水）各自的
  `_apply_health_environment_effects()` 里对 `HealthManager.adjust_stat("morale",…)`
  的每小时调用，改为经各自新增的 `_route_environment_morale()` 走
  PenaltyManager 的 silent 路径（`penalty_id="ambient_environment_morale"`）。
  **数值逐笔不变**：PenaltyManager 收到 `health_deltas.morale` 后就是同一句
  `adjust_stat("morale", delta)`；PenaltyManager 缺失时回退到原直接调用。
  （BaseStatusManager 的"最后一株植物恢复 +2.0 morale"是奖励不是惩罚，未收编。）

### 预设目录 `PenaltyDatabase.PENALTIES`
当前预设：`training_pressure_wrong` / `training_battery_wrong`（训练答错，15 分钟，
training 上下文）、`ambient_environment_morale`（环境每小时 morale，silent）。
静态接口 `has_penalty` / `get_penalty`（会注入 penalty_id）/ `get_display_name` /
`get_severity` / `all_ids`。

### 存档
本身不落盘（`history`/`last_notice` 是运行态派生值，重开重算）。惩罚的**效果**
落在被扣的各系统自己的存档里。

### 待办 / 设计可扩展点
- 预设目录目前很小，正式任务的离散惩罚（超时、事故、误操作后果）可继续往
  `PenaltyDatabase` 加，或调用方内联描述。
- `severity` 目前只进记录/信号，UI 分级展示（颜色/音效）还没做。
- `apply_penalty` 尚未做"部分失败"语义（某一路系统缺失只是跳过，仍算 applied）；
  若将来需要"必须全部生效否则回滚"，要另加事务式包装。

---

## 任务系统 TaskManager / TaskDatabase

### 定位
统一的"**当前目标 / 进度**"查询层 autoload `/root/TaskManager`
（`scripts/managers/TaskManager.gd`，`class_name GuanghanTaskManager`）。
**不持有第二份真相**：各类任务的完成状态**从各自的权威源派生**（查询时读），
所以不会和权威源漂移。和 PlayerStateManager 一样是读/查询层，不驱动 step 引擎、
不推进流程。

代码：
- `scripts/data/TaskDatabase.gd`（纯数据 RefCounted，preload，无 autoload）——任务目录。
- `scripts/managers/TaskManager.gd`（autoload）——查询层 + 信号。

### 任务粒度
**粗粒度**。训练按"模块"、正式任务按"天/周弧"各作一个任务；每个任务内部的
细步骤/清单仍归各自场景引擎（训练 step、sprint06 每日清单），**不下沉到任务系统**。

### 目录 `TaskDatabase.TASKS` + 派生源
| category | 任务 | 完成派生源 |
|---|---|---|
| training | 6 个：`training_suit_control` / `_airlock_procedure` / `_power_repair` / `_power_distribution` / `_life_support` / `_plant_diagnosis` | `TrainingManager._read_progress_data()` 的 flag（如 `SuitControlCompleted`） |
| mission | 3 个：`mission_day_01` / `mission_day_02` / `mission_week_one` | sprint06 存档（`TrainingManager.SPRINT06_SAVE_PATH`）的 flag（`Day01Completed` / `Day02Completed`\|`Day02ReportSent` / `WeekOneCompleted`） |
| supply | **动态单任务** `supply_current`（不在静态目录里，随补给周期复用） | `SupplyManager.get_current_supply()` 的 status（draft/confirmed/locked/delivered/missed） |

任务字段：`title / category / order / prerequisites:[task_id] / completion_flag`
（单 flag）或 `completion_flags_any:[flag]`（任一为真即完成，如 Day02）。

### 状态派生
`get_task_state()` → 完成（flag 命中）/ active（前置都完成、自身未完成）/ locked
（前置未完成）。supply 的 status 映射：delivered→completed、missed→failed、其余→active。

### API
`get_current_objective(category)`（第一个未完成任务的标题，或该类"全完成"文案；
supply 走动态）/ `get_active_task_id(category)` / `get_task_state(task_id)` /
`is_completed(task_id)` / `get_progress(category)`（{completed,total,remaining}）/
`get_all_tasks(category)`（[{task_id,title,state,order}]，供任务面板）/
`notify_progress_changed()`（流程改完权威源后可调，发 `tasks_changed` 信号）。

### 已接线
- `training_base_map.gd` 的 `_global_objective_text()`：模块目标改读
  `get_current_objective("training")`；气闸后归位过场（依赖运行时穿服状态、非模块
  flag）仍留场景；旧链保留作回退。
- 正式任务/补给目前是**派生可查询**，但 sprint06 的 HUD 目标仍由 sprint06 自己的
  `_update_objective()` 细算（TaskManager 提供的是粗粒度弧层视图，不替代它）。

### 存档
本身不落盘（全部派生自各权威源的存档）。

### 待办 / 设计可扩展点
- 尚无任务面板 UI；`get_all_tasks()` 已为它备好（含 supply）。月面地图那版
  任务/探索目标可加 `exploration` 分类接进来。
- mission 目前只覆盖第一周弧（Day01/Day02/Week One）；后续阶段/章节再加。
- `tasks_changed` 信号暂无订阅者；HUD 目前是查询式（在 `_update_hud` 里取）。
