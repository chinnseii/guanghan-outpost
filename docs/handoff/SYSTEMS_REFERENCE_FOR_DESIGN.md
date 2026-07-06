# 广寒前哨 · 核心数值系统参考（交给系统设计用）

本文档汇总当前已实现的四套核心数值系统：**时间系统 / 玩家健康系统 / 基地状态系统 /
植物生长系统**。所有数值直接摘自源码（截至 commit `b6d5c75`），不是设计草稿。
如果要基于这些系统做新一轮设计，请以本文档 + 源码为准，不要凭记忆假设数值。

代码位置：
- `scripts/managers/TimeManager.gd`（autoload `/root/TimeManager`）
- `scripts/managers/HealthManager.gd`（autoload `/root/HealthManager`）
- `scripts/managers/BaseStatusManager.gd`（autoload `/root/BaseStatusManager`）
- `scripts/systems/PlantGrowthManager.gd`（autoload `/root/PlantGrowthManager`）
- `scripts/data/PlantCropData.gd`（纯数据，`preload()` 引用，无 autoload）

四者的调用顺序（`TimeManager.advance_time(minutes, reason)` 内部）：

```
玩家执行一个行动
  → HealthManager.adjusted_action_minutes()   先按精力算这次行动实际耗时
  → total_minutes += 实际耗时                  时钟推进
  → BaseStatusManager.advance_base_time()      基地状态先结算
  → PlantGrowthManager.advance_plant_time()    植物生长再结算
  → HealthManager.apply_action_cost()          最后结算这次行动本身的健康消耗
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

### 与基地状态系统的耦合（`get_energy_cost_multiplier()`）
```
最终精力消耗倍率 = fullness_multiplier × BaseStatusManager.get_environment_energy_multiplier()
```
`BaseStatusManager` 不存在时该项默认 1.0（不影响旧行为）。具体环境倍率数值见
第三节"精力消耗环境倍率"。

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
基地作为生命维持环境的四项抽象状态，**不做真实工程仿真**。四个设备档位决定
每小时变化率，设备档位只能靠"维修"改变（维修本身不推进时间，由调用方另外
推进 TimeManager）。

### 四项数值与抵达初始值（0–100，越高越好；温度用摄氏度，clamp −40~60）

| 状态 | 初始值 |
|---|---|
| `power` 电力 | 42 |
| `oxygen` 氧气 | 68 |
| `pressure` 舱压 | 76 |
| `temperature` 温度 | 14℃（舒适目标 21℃） |

### 四个设备档位（`SystemStatus`：OFFLINE < CRITICAL < BASIC < STABLE）与初始值

| 设备 | 初始档位 |
|---|---|
| `power_system_status` 供电系统 | CRITICAL |
| `life_support_status` 生命支持 | CRITICAL |
| `thermal_control_status` 温控系统 | CRITICAL |
| `seal_status` 密封状态 | BASIC |

### 每小时变化率

**电力**（按月夜/月昼、供电档位）：

| 供电档位 | 月夜 | 月昼 |
|---|---|---|
| OFFLINE | −0.60 | −0.20 |
| CRITICAL | −0.35 | +0.10 |
| BASIC | −0.18 | +0.35 |
| STABLE | −0.10 | +0.60 |

**氧气** = `(生命支持基础速率 × 电力倍率 + 舱压附加) + 最后一株植物加成`，
每小时：

生命支持基础速率：OFFLINE −0.30 / CRITICAL −0.08 / BASIC +0.02 / STABLE +0.08

电力倍率：电力≥70→×1.0，≥40→×0.8，≥20→×0.5，<20→（若基础速率为正则强制
为 0，若为负则×1.5）

舱压附加（与电力倍率无关，直接相加）：舱压≥70→0，≥40→−0.03，≥20→−0.10，
<20→−0.25

最后一株植物加成：`set_last_plant_recovered(true)` 触发后恒定 +0.01/小时

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
| 生命支持轻维修 | CRITICAL→BASIC | 氧气 +4 |
| 生命支持重维修 | BASIC→STABLE | 氧气 +6 |
| 温控轻维修 | CRITICAL→BASIC | 温度向 18℃ 靠近，单次最多 1.0℃ |
| 温控重维修 | BASIC→STABLE | 温度向 21℃ 靠近，单次最多 1.5℃ |
| 密封轻修补 | CRITICAL→BASIC | 舱压 +3 |
| 密封重修补 | BASIC→STABLE | 舱压 +5 |

（对应的 30/60 分钟耗时由调用方通过 `TimeManager.advance_time()` 另外推进，
`BaseStatusManager` 本身不管时间。目前只有供电、生命支持在实际旧基地流程里
接了这两个方法；温控、密封只有方法 + Debug 按钮，没有场景交互入口。）

### 对健康系统的反向影响（每小时，累加成一次 `morale` 调整）
- 电力 0–19：心理 −0.08/小时；电力 20–39：−0.03/小时
- 舱压 0–19：心理 −0.10/小时；舱压 20–39：−0.05/小时
- 温度"危险"（<10℃ 或 >32℃）：心理 −0.05/小时

### 对健康系统"精力消耗倍率"的影响（`get_environment_energy_multiplier()`）
```
温度倍率 × 氧气倍率
温度倍率：舒适(18–26℃)→×1.0；危险(<10℃或>32℃)→×1.25；其余→×1.1
氧气倍率：≤19→×1.5；<40→×1.2；否则×1.0
```

### 文案分段
电力：≥70 供电稳定 / ≥40 供电紧张 / ≥20 低电力 / <20 电力危机
氧气：≥70 氧气稳定 / ≥40 氧气偏低 / ≥20 氧气不足 / <20 氧气危险
舱压：≥70 舱压稳定 / ≥40 轻微泄压 / ≥20 明显泄压 / <20 气密危机
温度：18–26 舒适 / 10–17.99 偏冷 / 5–9.99 低温危险 / <5 严重低温 /
26.01–32 偏热 / 32.01–35 高温危险 / >35 严重高温
设备档位：OFFLINE=离线（密封显示"破损"）/ CRITICAL=危急 / BASIC=基础运行
（密封"基础密封"）/ STABLE=稳定运行（密封"稳定密封"）

### 专业提示（只读玩家自己的教育背景，不加数值，四选一互斥）
- 机械工程：电力<70 或 生命支持/温控 非 STABLE → 建议优先恢复供电
- 材料科学：舱压<80 或 密封非 STABLE → 提示密封老化风险
- 医学：温度不在 18–26 或 氧气<70 或 电力≤19 → 提示低温/低氧增加精力消耗
- 植物科学：温度不在 18–26 或 电力<70 或 最后一株植物尚未脱离 Critical →
  提示植物恢复会延迟

### 存档
`user://saves/base_status_state.json`：`power / oxygen / pressure /
temperature / power_system_status / life_support_status /
thermal_control_status / seal_status / last_plant_recovered_bonus_active`。

---

## 四、植物生长系统 PlantGrowthManager

### 定位
多地块（`slot_id: String` → 植物实例的 `Dictionary`）的作物生长系统，**每满
1440 累计游戏分钟才结算一次**（不是实时/不是每帧），由
`TimeManager.advance_time()` 驱动累加分钟数。跟旧的"最后一株植物"叙事系统
（在 `sprint06_base_scene.gd` 里）完全独立，没有互相引用。

### 环境输入（三项，每项只看"够不够"，从不判断"过量"）
- **水循环等级** `water_cycle_level`：0–4，本系统独立抽象，默认 1，只能靠
  Debug 菜单调（`debug_set_water_level`/`debug_cycle_water_level`），没有
  接入任何现有的水循环叙事标志。
- **光照等级**：
  - 月昼：恒定 4，不耗电。
  - 月夜：`greenhouse_light_system_level`（0–4，默认 1，Debug 可调）
    再按 `BaseStatusManager.power` 衰减：
    电力≥70 不衰减；40–69 −1；20–39 −2；<20 强制 `min(等级, 1)`。
    最终 clamp 到 0–4。
- **温度**：直接读 `BaseStatusManager.temperature`，没有温室独立温度。

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

## 五、尚未覆盖 / 明确没做的东西（新设计如果要动，请先确认这些坑）

- **温度系统只有基地整体一个值**，没有分房间/分舱段温度；植物、健康都读的是
  同一个 `BaseStatusManager.temperature`。
- **水循环等级 / 温室补光等级是全新的独立数值**，跟旧基地场景里那些叙事型
  布尔标志（`PartialWaterCycleRestored` 等）完全没有打通，也没有玩家可操作
  的 UI（只有 Debug 按钮）。
- **没有真正的库存/资源消耗系统**：进食、喝营养液等行动目前不扣除任何物品
  数量（代码里有 `# TODO: deduct food resource` 注释）。
- **"最后一株植物"叙事系统**（`sprint06_base_scene.gd` 里的
  `LastPlantStable` 等）跟 `PlantGrowthManager` 是两套并行独立的系统，只有
  一个单向信号（最后一株植物脱离 Critical 时，往 `BaseStatusManager` 报一次
  `set_last_plant_recovered(true)`，带来氧气 +0.01/小时 和一次性心理 +2），
  没有更深的双向联动。
- **密封、温控目前没有场景内的维修交互入口**，只有方法和 Debug 按钮。
- **没有失败/死亡结局**：四个健康值、四个基地状态值目前都只是效率修饰或
  文案变化，没有任何数值触发游戏结束。
- **温室没有"走到某块地播种/收获"的场景交互**，`PlantGrowthManager` 的
  `slot_id` 目前只能靠 Debug 菜单赋值（约定 slot_id = crop_id，即同一种作物
  同一时间只能有一块地）。
