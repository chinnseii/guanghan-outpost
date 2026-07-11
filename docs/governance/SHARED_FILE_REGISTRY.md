# SHARED_FILE_REGISTRY · 多 Agent 冲突审计

> 治理审计初稿 · 只读 · 2026-07-11
> 目的：划出 Claude Code / Codex **不该并行乱改**的区域。分档与 `docs/handoff/COLLABORATION_RULES.md` 对齐并用本审计复核。

## 一级共享文件（修改前必须"加锁"：同一时刻只允许一个 Agent 改）

| 文件 | 复用面（证据） | 为什么危险 |
|---|---|---|
| `scripts/props/reference_prop.gd` (411) | **48 处**场景/脚本引用（旧基地/温室/太阳能/训练四线） | 全项目复用面最广；一处改动波及四条线 |
| `scripts/base/sprint06_base_scene.gd` (2599) | **10 个正式场景**共用（`SCENE_*` `:7-14`） | Sprint06/07/08 全部日常流程跑在这一个脚本 |
| `scripts/training/training_module_scene.gd` (3417) | 驱动 6 个训练模块 | 训练核心；逻辑+绘制混装，易互相踩 |
| `scripts/training/training_base_map.gd` (2255) | 训练 hub（多房间+门+惩罚+宇航服） | 近期高频改动区 |
| `scripts/training/training_manager.gd` (566) | 5 训练脚本 + `main.gd` 共用 + **存档结构** | 改存档结构会波及三处存档文件 + 旧存档 remap |
| `scripts/main.gd` (5156) | 主菜单路由 + 沙盒本体 | 菜单是所有正式流程入口；任何人碰主菜单都在此 |
| `project.godot` | 全局 autoload/main_scene | 加 autoload = 全局副作用；两人同时加会冲突 |
| `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md` | 系统/数值唯一真相 | 数值改动都要写这里，易并发冲突 |
| `docs/handoff/CURRENT.md` | 滚动状态（覆盖写） | 两人同时覆盖会互相丢失 |

**加锁方式（并行模式下）**：在 `docs/handoff/ACTIVE_TASKS.md` 声明"我锁定文件 X"，另一 Agent 见锁即不碰该文件；无锁工具时以 ACTIVE_TASKS 声明为准。

## 二级共享文件（可改，但必须在任务记录/CURRENT.md 声明）

| 文件/组 | 复用面 | 规则 |
|---|---|---|
| Autoload Manager 群（`TimeManager`/`HealthManager`/`Base/Air/Water/Power`/`Suit`/`Repair`/`Supply`/`Inventory`/`Backpack`/`Storage`/`Plant`/`PlayerState`/`Penalty`/`Task`/`Door`/…） | 各 8-22 引用 | 默认只增不改（新增可选参数/分支）；改 `serialize/deserialize` 视同一级（波及存档） |
| `scripts/training/opening_flow_manager.gd` | 2 处共用、范围小 | 小但易漏改一处 |
| `scripts/ui/popup_modal.gd` | 训练/多处共用弹窗 | 改样式会波及多屏 |
| `scripts/controllers/player_controller_2d.gd` / `interaction_area_2d.gd` | 训练+旧基地共用移动底座 | 改移动/交互判定波及两线 |
| `scripts/data/*Database.gd`（Item/Fault/Task/Penalty/Door*） | 各系统数据源 | 加数据条目安全；改结构须声明 |
| `README.md` | 门面文档 | 两人都可能顺手改状态段 |

## 三级 / 独立文件（适合并行开发，冲突概率低）

- 单一场景专属脚本：`application_flow_scene.gd`、`arrival_*`、`lunar_surface_scene.gd`、`phase02_placeholder_scene.gd`、各 `scenes/props/*` 小道具场景与其独立脚本。
- 遗留基座脚本（`game_state_manager.gd` 等 A2 组）：只要不复活沙盒，改它们不影响主线（但也别顺手删）。
- 各自新增的 `docs/sprints/SPRINT_XX.md`、新增独立 UI 面板。

## Claude Code 与 Codex 不应并行修改的区域（硬冲突源）

1. **同一个一级共享文件**（上表任一）。
2. **同一个 autoload 的 `serialize/deserialize` 或注册**（`project.godot` autoload 段）。
3. **同一存档结构**：`training_progress.json` / `sprint06_progress.json` 的字段（由 `training_manager.gd` / `sprint06_base_scene.gd` 定义）。
4. **同一数据库结构**（非新增条目、而是改 schema）。
5. **同一公共场景**：`main.tscn`（菜单）、10 个 base 共用场景、训练 hub。
6. **有隐含结算顺序依赖的系统**：Time↔Movement↔TrainingTime↔Penalty 的推进链（改一处时序影响全链）。

> 角色默认分工（`COLLABORATION_RULES.md`）：Codex 主责逻辑/Manager/数据/流程，Claude Code 主责场景/UI/节点/资源/美术管线——但**按任务不按目录**，谁接任务谁负责到底，跨到对方常改文件也直接改，改完在 CURRENT.md 记一笔。
