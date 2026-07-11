# Phase 3 Save Ownership Decision · 存档真相源与数据 owner 定稿

> Phase 3 P3-02 · 治理/设计定稿（**零代码、零存档格式修改**）· 2026-07-11 · 基线 `6be3192`
> 本文件为 P3-03 代码修复的**唯一决策依据**。证据用 `文件:行号`/字段/方法；推荐方案与"已实现事实"严格区分。
> 术语：**Canonical Owner**（运行时唯一权威持有）· **Authorized Writer**（经公开 API 改 owner 状态）· **Persistence Provider**（`serialize()` 输出自身状态）· **Save Orchestrator**（决定何时收集 provider 成完整快照）· **Storage Writer**（写文件）· **Restore Orchestrator**（决定读哪个快照/恢复顺序/禁止越权覆盖）· **Restore Target**（`deserialize()` 应用自身状态）· **Checkpoint**（训练/任务/场景局部快照，**≠** 完整游戏存档真相）。**"持有 serialize 方法" ≠ "拥有全局存档真相"。**

## 1. 决策范围
定稿：核心数据 owner / writer / reader / 持久化与恢复权 / 三类 save 层职责 / 架构方案推荐 / 恢复顺序 / 兼容策略 / 用户决策项 / P3-03 边界。**不改代码、不改 JSON、不写迁移。**

## 2. P3-01 证据摘要
- 20 autoload 全现役；**跨系统写入全部经公开方法，0 直接外部字段写**（PenaltyManager 仅分发）；无依赖环、无 P0。
- 核心 P1 = 同一 Manager 状态同时进 `*_state.json`（自存）+ `training_progress.json` + `sprint06_progress.json`，restore 顺序决定覆盖（详见 `PHASE_3_SYSTEM_BOUNDARY_AUDIT.md` §7）。

## 3. 持久化管线分类（重分类，避免"所有 JSON 都是冲突"）

| 类 | 文件 | Writer | 数据范围 | 进主流程? | 可能覆盖核心 Manager? | 真相源竞争? |
|---|---|---|---|---|---|---|
| **A 核心游戏进度** | `sprint06_progress.json` | sprint06_base_scene | 全 Manager 快照 + Task | ✓（正式主线存档） | ✓ | **是（与自存竞争）** |
| A | `training_progress.json` | training_manager | 训练上下文 + 全 Manager 快照 | ✓（训练阶段） | ✓ | **是** |
| A | `*_state.json`（15 个） | 各 Manager `save_state()`（部分自动写） | 单 Manager 自身状态 | ✓ | ✓ | **是** |
| **B 档案/申请** | `application_profile.json` | AcademicBackground/application flow | 申请资料/教育背景/外观 | ✓（前置身份） | ✗ | 否（独立身份数据，非玩法进度） |
| **C Legacy/沙盒** | `save_N.json`（slot） | main.gd 沙盒 | 沙盒玩法 | ✗（仅 Dev 沙盒） | ✗（不碰正式 Manager） | 否 |
| C | `arrival_prototype_save.json` | arrival 场景 | 抵达原型 | ✗（原型/Dev） | ✗ | 否 |

**结论**：真相源竞争**只在 A 类**（核心进度）内部；B/C 不参与、不覆盖正式 Manager。→ 本轮聚焦 A 类。

## 4. 数据 owner 矩阵（核心域）

> 说明：所有 writer 均**经公开 API**（P3-01 证据）。"Duplicate current storage" = 当前该状态被写进的多个文件。

| 数据域 | Canonical Owner | Authorized Writers | Persistence Provider | Restore Target | Full Save | Checkpoint | Duplicate storage | 置信 | Decision |
|---|---|---|---|---|---|---|---|---|---|
| 游戏时间 | TimeManager | TimeManager、Penalty/Movement(路由) | TimeManager | TimeManager | ✓ | mission | time_state + 两快照 | HIGH | FINAL(owner)；真相源见 §11 |
| 训练时间 | TrainingTimeManager | 训练上下文 | 同 | 同 | ✗(训练局部) | training | training_time_state + training_progress | HIGH | FINAL |
| 玩家健康 | HealthManager | Health、Penalty | 同 | 同 | ✓ | mission | health_state + 两快照 | HIGH | FINAL |
| 玩家区域/上下文 | PlayerStateManager | PlayerState | 同 | 同 | ✓ | mission | 仅快照(无自存文件) | HIGH | FINAL |
| 氧/水/电/基地状态 | Air/Water/Power/BaseStatusManager | 各自、Penalty(morale) | 各自 | 各自 | ✓ | mission | 各 *_state + 两快照 | HIGH | FINAL |
| 补给 | SupplyManager | Supply、Penalty | 同 | 同 | ✓ | mission | supply_state + 两快照 | HIGH | FINAL |
| 背包(随身) | BackpackManager | Backpack、Penalty(移除) | 同 | 同 | ✓ | mission | backpack_state + 两快照 | HIGH | FINAL |
| 仓储(基地) | StorageManager | Storage | 同 | 同 | ✓ | mission | storage_state + 两快照 | HIGH | FINAL |
| 库存(数量账) | InventoryManager | Inventory、消费系统(Water/Plant) | 同 | 同 | ✓ | mission | inventory_state + 两快照 | MEDIUM | FINAL(owner)；与 Backpack 关系见 §5 |
| 宇航服 | SuitManager | Suit、训练流程 | 同 | 同 | ✓ | mission+training | suit_state + 两快照 | HIGH | FINAL |
| 维修 | RepairManager | Repair | 同 | 同 | ✓ | mission | repair_state + 快照 | MEDIUM | FINAL |
| 任务进度 | TaskManager | Task | Task(入 sprint06) | Task | ✓ | mission | sprint06 | MEDIUM | FINAL |
| 门状态 | DoorStateManager | Door | 同 | 同 | ✓? | mission? | door_state | MEDIUM | FINAL(owner)；接入正式导航属功能 |
| 植物/温室 | PlantGrowthManager | Plant、消费(Inventory) | 同 | 同 | ✓ | mission | plant_growth_state + 两快照 | HIGH | FINAL |
| 惩罚记录 | **无持久化 owner** | — | **无**（PenaltyManager 不 serialize） | — | ✗ | ✗ | 无 | HIGH | FINAL（不持久化，见 §7） |
| 移动/行动消耗 | 无独立状态（路由） | MovementTimeManager | 无 | — | ✗ | ✗ | 无 | HIGH | FINAL |
| 玩家位置(地表) | 场景局部 | lunar_surface_scene | **无**（当前不存位置） | — | ✗ | scene | 无 | HIGH | USER_DECISION(是否持久化，见 §13) |
| 申请档案/教育背景 | AcademicBackgroundManager | 申请流程 | 同 | 同 | 独立(B 类) | — | application_profile | HIGH | FINAL |

- **UNRESOLVED：0**（每域有 owner）；MEDIUM 项在 §5/§11 说明；FINAL 指"owner 已定"，真相源模型待 §13 用户确认。

## 5. Inventory / Backpack / Storage
- **Backpack**（`slots`/`backpack_level`/`backpack_capacity_slots`）= 玩家随身、槽位制。
- **Storage**（`slots`/`storage_level`）= 基地仓库、槽位制。
- **Inventory**（`stack_items` item_id→qty、`durable_items`、`training_containers`）= 数量账 + 训练房间隔离容器，被 Water/Plant 消费系统读用（`InventoryManager` 被 `WaterSystemManager`/`PlantGrowthManager`/`ItemDatabase` 引用）。
- **转移协议存在且原子**：`BackpackManager.transfer_slot_to_storage()`（:108）用 `ItemContainer.take_from_slot`（从背包扣）→ `storage.add_existing_slot`（入仓库），拒收则退回背包；`StorageManager.transfer_slot_to_backpack()`（:82）反向。**take-then-add + rollback，非双记账。**
- **结论**：Backpack ↔ Storage = **`CLEAR_SEPARATION` + `TRANSFER_PROTOCOL_REQUIRED`（已实现）**。
- **1 个 MEDIUM 待核（非损坏）**：Inventory 的 `stack_items` 与 Backpack 的 `slots` 是否对**同一物品**双记账（拾取入哪、消费读哪未逐路径追）。分类 **可能 `DERIVED_VIEW` 或独立关注点**；列 **P2**（`PHASE_3_SYSTEM_BOUNDARY_AUDIT.md` 未决 #1），P3-04 前做字段级追踪确认，**不阻塞 P3-02/03**。

## 6. Time / TrainingTime
- **游戏时间 owner = TimeManager；训练时间 owner = TrainingTimeManager**（独立）。
- 训练是**正式任务之前的独立阶段**；未发现 `training_manager` 在训练结束时调用 `advance_time` 同步正式时间。正式时间从抵达 Day 01 06:40 起算（`SYSTEMS_REFERENCE`）。
- checkpoint：training_progress 存 TrainingTime；sprint06 存 Time。
- Movement/Suit/Repair 按上下文选时钟（训练调 `advance_training_time`，正式调 `advance_time`；由 MovementTime 路由）。
- **结论**：**`SEPARATE_CLOCKS` + `NO_SYNC`**（训练时间不进位正式时间）。置信 MEDIUM（基于"未发现同步"+顺序阶段设计）；§13 请用户按现有设计确认。

## 7. PenaltyManager
- **正式记录**：PenaltyManager **不是任何核心数值 owner**；`apply_penalty()`（:26）仅解析 + 分发（`_apply_time/_apply_health/_apply_energy_cost/_apply_remove_items/_apply_supply`），全部经目标 Manager 公开 API（`.call("advance_time"/"adjust_stat"/…)`）；**不 serialize 他系统状态、无自存文件**。
- **惩罚历史**：当前**不持久化**；后果由被作用 Manager 各自持久化。
- **回滚**：当前无（`apply_penalty` 无事务语义）——属**未来扩展**，非当前产品需求。
- **结论**：PenaltyManager = **dispatcher/PASS_THROUGH（FINAL）**；惩罚历史**保持不持久化**（§13 请确认）。

## 8. Full Save 与 Checkpoint 作用域

| 保存动作 | 包含 | 不包含 | 触发 | 编排 | 文件 | 跨场景恢复 | 覆盖全局资源 | 生命周期 |
|---|---|---|---|---|---|---|---|---|
| **Full Save**（正式进度） | 全核心 Manager + Task + 身份引用 | 沙盒/arrival/纯 UI 缓存 | 玩家存/关键节点 | Save Orchestrator（当前 = sprint06_base_scene，应正式化） | `sprint06_progress.json`（当前即事实全存档） | ✓ | ✓（**经 Restore Orchestrator**） | 直到覆盖/新档 |
| **Training Checkpoint** | 训练进度 + 训练上下文 + 训练相关 Manager 快照 | 正式任务进度 | 训练阶段推进 | training_manager | `training_progress.json` | 训练内 | **不应**覆盖正式任务域 | 训练结束/清档 |
| **Mission/Scene Checkpoint** | 当前任务/场景短期状态 | 与自身无关的全局域 | 场景内 | 场景脚本 | （当前混入 sprint06） | 有限 | **不应**越域 | 场景内 |

- **关键发现**：`sprint06_progress.json` 当前**同时**充当"任务 checkpoint"与"事实上的 Full Save"（`_load_state` 恢复~12 个全局 Manager，:2450-2480）——**超出"单场景 checkpoint"作用域**。这正是要在 P3-03 正式化的点：把它明确定义为 **Full Save（正式化 Save/Restore Orchestrator）**，而非隐式的场景 checkpoint。
- `training_progress.json` 也打包了全 Manager 状态（含非训练域），同样超范围——训练 checkpoint 不应携带正式任务真相。

## 9. 架构方案对比

**方案 A — Manager 自存为唯一真相**：各 `*_state.json` 权威，bundle 仅存元数据/引用；Restore 依次 `load_state()`。
- 优点：改动小、Manager 自洽。缺点：**无原子性**（15 文件分别写，中途崩溃→半档）、**无版本一致性**、跨 Manager 一致性弱、bundle 退化。→ `NOT_RECOMMENDED`。

**方案 B — 统一 bundle 为唯一真相**：单 bundle 存完整进度；Manager 只 `serialize/deserialize`、**不再自写文件**。
- 优点：原子、一致、单一真相。缺点：需**移除所有 Manager 自写**（改动面大）、训练/任务 bundle 需先拆分"完整存档 vs 局部 checkpoint"、一次性程度高。→ `VIABLE_ALTERNATIVE`（终态理想，但迁移偏大爆改）。

**方案 C — 分层存档（推荐）**：
- **Full Save = 单一 authoritative bundle**（正式化现 `sprint06_progress.json` 为 Full Save，由 Save/Restore Orchestrator 管）；
- **Manager `*_state.json` = 降级为 session/开发缓存或 write-through，不作为核心进度的 restore 真相**（restore 时 bundle 唯一权威，Manager 自存不参与覆盖 mission 域）；
- **Training checkpoint** 只存训练上下文；**Mission/Scene checkpoint** 只存自身作用域；
- 核心状态一次 load 只由 Full Save 恢复一次；checkpoint 不越域。
- 优点：**贴合现有代码**（Manager 已有 serialize、sprint06 已做 bundle-restore-wins）、runtime-owner 与 file-writer 分离、原子（单 bundle）、**可分批迁移**（先正式化 Orchestrator + 定 restore 顺序 → 再逐 Manager 停止"自存作为 restore 真相"）、不必新建大一统 SaveManager。缺点：需明确"自存文件的新定位"、过渡期可能 dual-read。→ **`RECOMMENDED`**。

## 10. 推荐方案：C（分层存档）
- **为何适合当前规模**：项目已是"Manager serialize + 场景 orchestrator"结构，C 只是**正式化并去歧义**，非重写；编辑器内 demo、无正式玩家存档，迁移风险低。
- **降覆盖风险**：restore 真相唯一（Full Save bundle），Manager 自存不再在 mission restore 中竞争覆盖 → 消除 P1。
- **多场景/训练**：训练/任务 checkpoint 明确作用域，互不越域。
- **避免 Manager 变文件 IO owner**：Manager 保留 `serialize/deserialize`（provider/target），**写盘交给 Storage Writer/Orchestrator**。
- **未来迁移友好 + 分批**：见 §14。**改动规模中等、可分批、可回滚**。旧存档兼容见 §12。

## 11. 恢复顺序与权限

**建议恢复阶段（P3-03 实现，本轮仅设计）**：
```
1. 读取并校验 Full Save 元数据（含未来 schema version）
2. 恢复静态身份/申请档案（application_profile，B 类）
3. 恢复核心资源与玩家状态（Time/Health/PlayerState/Air/Water/Power/Base/Supply/Suit/Repair/Inventory/Backpack/Storage/Plant/Door/Task）
4. 加载目标场景
5. 恢复场景局部状态
6. 恢复玩家位置（若采纳持久化）
7. 重算派生值
8. 发一次 restore-complete 信号
9. UI 刷新
```
- **当前已存在**：步骤 3 的批量 `deserialize`（sprint06_base_scene `_load_state` :2450-2480）、步骤 4 场景加载。
- **当前顺序问题**：Manager 在 autoload/进场时各自 `load_state()`（读自存）**先**发生，场景 `deserialize`（读 bundle）**后**覆盖——两来源都动 mission 核心域 → 违反"一次 load 只一个来源"。
- **deserialize 副作用**：`training_manager` 注释记录 mid-session `load_progress()` 会用旧快照覆盖 live（宇航服被重置）→ 恢复期应**抑制**部分 Manager 的变更信号/自动写盘。

**恢复权限矩阵**（原则：checkpoint/场景**不得**恢复不属于自身作用域的全局域，除非经 Restore Orchestrator 授权）：

| 数据域 | Full Save 恢复 | Training Checkpoint 恢复 | Mission Checkpoint 恢复 | Scene 直接恢复 |
|---|---|---|---|---|
| 全核心 Manager（时间/健康/资源/物品/宇航服/植物…） | ✓ | 仅训练相关子集 | ✗（应经 Orchestrator） | ✗ |
| 训练进度/训练时间 | ✓ | ✓ | ✗ | ✗ |
| 任务进度(Task) | ✓ | ✗ | ✓(自身) | ✗ |
| 场景局部/玩家位置 | ✓(若持久化) | ✗ | 有限 | ✓(自身) |
- **疑似越权点**：`sprint06_progress.json` 作为"场景/任务 checkpoint"却恢复全 12 Manager（越出场景作用域）——P3-03 正式化为 Full Save 后即合规。

## 12. 兼容策略
- **JSON 无 schema version**（全仓零 `version`/`schema` 字段）。
- 当前**无正式玩家存档**（编辑器内 demo，Dev 可 Reset Demo Progress）。
- **建议：`NO_COMPATIBILITY_REQUIRED`（对既有本地档）+ 未来 `VERSIONED_MIGRATION_REQUIRED`**：P3-03 起在 Full Save 写入 `schema_version`；过渡期 Restore Orchestrator 可 best-effort 读旧 bundle（缺字段用 `default_data()` 兜底，多余字段忽略）；确认新档正常后停止读 Manager 自存作为 restore 真相；**改前备份旧 `user://saves/`**（本地，非仓库）。
- §13 请用户确认是否需要保留对现有本地 demo 档的兼容（默认否）。

## 13. 用户决策项（5，均附推荐）

1. **Full Save 权威模型** — 选项：A 自存为真 / B 统一 bundle / **C 分层（推荐）**。推荐 **C**：贴合现状、消除 P1、可分批。体验影响：无（对玩家透明）；成本：中等、可分批。不决策风险：P1 存档覆盖持续。→ **可按现有设计确认（sprint06 已 bundle-restore-wins）**。
2. **训练时间是否同步正式时间** — 推荐 **NO_SYNC（SEPARATE_CLOCKS）**。体验：训练为独立前置阶段，不占用正式游戏时间；成本：0（保持现状）。→ **可按现有设计确认**。
3. **Checkpoint 是否允许恢复全局资源** — 推荐 **否**（仅 Full Save 经 Orchestrator 恢复全局；checkpoint 限自身作用域）。→ **可按现有设计确认**（把 sprint06 正式化为 Full Save）。
4. **是否保留旧本地存档兼容** — 推荐 **NO_COMPATIBILITY_REQUIRED**（无正式玩家档、编辑器 demo 可重置）。若你要保留任何本地测试档，改为 BEST_EFFORT。→ **需你确认**。
5. **惩罚历史是否跨存档保留** — 推荐 **否**（PenaltyManager 是分发器，后果已由目标 Manager 持久化）。→ **可按现有设计确认**。

> 真正需要你主动拍板的其实只有 **#1（确认采纳 C）** 与 **#4（兼容策略）**；#2/#3/#5 是"按现有设计确认"。

## 14. P3-03 实施边界（本轮不实现）
- **要改**：① 正式化 **Save/Restore Orchestrator**（把 `sprint06_progress.json` 定义为 Full Save，明确恢复顺序 §11）；② 让 Manager 自存 `*_state.json` **不再作为 mission restore 真相**（restore 只由 Full Save 一次性应用；自存降级为 session/write-through 或移除自动读）；③ Full Save 加 `schema_version`；④ 恢复期抑制副作用信号/自动写盘。
- **不改**：Manager 的 `serialize/deserialize` 数据形状（保持兼容）；training/application/legacy 管线（除明确越域裁剪）；跨系统调用（已 API-mediated、无需动）；玩法数值。
- **分批**：P3-03a 正式化 Orchestrator + 恢复顺序（不删自存，仅"bundle 为 restore 真相"）→ P3-03b 逐 Manager 停止"自存作 restore 真相"+ 加 schema_version → P3-03c 越域 checkpoint 裁剪。
- **回滚点**：每子批独立 PR、可 revert；改 serialize/deserialize 保留旧字段读兼容。
- **验收**：存/关/续档回归无覆盖丢失；训练→任务过渡状态正确；`lunar-base-verify` 全流程；无旧档静默损坏。

## 15. 验收标准（本轮 P3-02）
- 每核心域有 owner 或明确 decision（UNRESOLVED=0）✓；writer/restore 权明确 ✓；三 save 层职责不重叠定义 ✓；≥3 方案对比 + 1 推荐（C）✓；用户决策项 ≤8（本轮 5，其中 2 需拍板）✓；**零代码/JSON 修改** ✓。

## 附：本轮零改动核验
- 仅新增/改治理 `.md`；未改 `project.godot`/`scripts`/`scenes`/`resources`/`assets`/任何 `.gd/.tscn/.tres/.json/.uid`。Godot editor+smoke EXIT=0。
