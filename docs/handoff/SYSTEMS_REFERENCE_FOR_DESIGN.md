# 广寒前哨 · 核心数值系统参考（交给系统设计用）

本文档汇总当前已实现的七套核心数值系统：**时间系统 / 玩家健康系统 / 基地状态系统 /
电力系统 / 水资源系统 / 空气系统 / 植物生长系统**。所有数值直接摘自源码（截至
"水资源系统"实现完成，`AirSystemManager` 的制氧输出会被 `WaterSystemManager`
的供水满足率节流），不是设计草稿。如果要基于这些系统做新一轮设计，请以本文档 +
源码为准，不要凭记忆假设数值。

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
- `scripts/systems/PlantGrowthManager.gd`（autoload `/root/PlantGrowthManager`）
- `scripts/data/PlantCropData.gd`（纯数据，`preload()` 引用，无 autoload）

七者的调用顺序（`TimeManager.advance_time(minutes, reason)` 内部）：

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
> 特意选择保留、未做进一步清理的一处技术债，见第八节。

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
不完全一致，见第八节。）

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
见第八节已知问题）
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
收获时：
```
HealthManager.fullness  += harvest_fullness
HealthManager.nutrition += harvest_nutrition
HealthManager.morale    += harvest_morale
```
（三项各自单独 clamp 到 0–100，走 `HealthManager.adjust_stat()`）

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

## 八、尚未覆盖 / 明确没做的东西（新设计如果要动，请先确认这些坑）

- **温度系统只有基地整体一个值**，没有分房间/分舱段温度；植物、健康、空气
  系统都读的是同一个 `BaseStatusManager.temperature`。
- **温室补光等级（植物系统）仍是独立数值**，跟旧基地场景里那些叙事型布尔
  标志（`PartialWaterCycleRestored` 等）完全没有打通，也没有玩家可操作的 UI
  （只有 Debug 按钮）。植物用水已经不再是独立数值了（见 WaterSystemManager），
  但补光还是。
- **进食、喝营养液现在会扣可用水**（水资源系统实现完成后），但**不扣除任何
  "食物"本身的库存数量**——代码里仍有 `# TODO: deduct food resource` 注释，
  没有一个"食物"资源系统，`eat` 这个动作可以无限次执行，只要有水就一直有
  "食物"可吃。惰性气体第一版同样不能生产，只能靠"旧基地遗留 + 地球补给"的
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
