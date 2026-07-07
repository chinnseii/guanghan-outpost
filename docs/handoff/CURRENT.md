# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-08
更新人：Claude Code（代 Codex）（惩罚系统 + 训练交互/宇航服流程 + 门系统）

## 本轮完成（已提交，未特别说明即已 push）

1. **门系统 DoorStateManager / DoorTypeDatabase / DoorAssetDatabase**（Codex 并行 + 验证提交）。
2. **训练小地图交互反馈重做（6 项）+ 气闸压力状态门禁 + 宇航服归位流程前移**
   （`training_base_map.gd`）：
   - 舱压/电池组答错→关弹窗 + 提示 + 扣 15 分钟 + 需重新交互；制氧/温控答错→
     居中白色渐隐"呼吸越发困难"/"越发寒冷"；配电控制台改统一弹窗；生命支持
     控制台弹窗按医学背景标注读数。
   - 新增 `AirlockPressureState`（低压→外舱门 / 充压→内舱门）。
   - **宇航服归位移到 EVA 返舱到整备室那一刻**（整备室→中控门在归还前封锁）；
     温室植物诊断完成后**直接结课→派遣通知**，取消末尾归位。
3. **惩罚系统 PenaltyManager / PenaltyDatabase**（新 autoload）：统一分派
   时间/健康/背包仓库/地球补给惩罚，按 training/mission 上下文自动路由时钟。
   已收编：训练答错扣时、BaseStatus/Air/Water 每小时 morale 扣减（silent，
   数值不变）、SupplyManager 三个补给惩罚方法。详见
   `SYSTEMS_REFERENCE_FOR_DESIGN.md` 的"惩罚系统"章节。
4. `training_module_scene.gd`：Codex 并行的 power_repair 出口自动穿越（已单独提交）。

## 触碰的共用文件（tier-1，均加法式；改前已 git log 抽查）

- `scripts/training/training_base_map.gd`：交互反馈 + 压力状态 + 宇航服流程 + 惩罚接线。
- `scripts/training/training_module_scene.gd`：Codex 并行新增出口穿越检查。
- `project.godot`：注册 DoorStateManager、PenaltyManager 两个 autoload（各加一行）。
- `scripts/managers/BaseStatusManager.gd` / `AirSystemManager.gd` /
  `WaterSystemManager.gd`：每小时 morale 扣减改走 PenaltyManager（`_route_environment_morale()`，
  数值逐笔不变，带回退）。
- `scripts/managers/SupplyManager.gd`：新增 `apply_supply_weight_penalty` /
  `delay_current_supply` / `cancel_current_supply`（纯新增函数）。

本轮未修改：`training_manager.gd`、`reference_prop.gd`、`sprint06_base_scene.gd`。

## 验证方式（本轮实测有效，供下轮沿用）

- 单脚本解析：`--headless --path . --check-only --script res://<path>.gd`（秒退，退出码 0）。
- 全项目导入：`--headless --editor --quit --path .`（grep error/parse/SCRIPT ERROR）。
- 启动退出：`--headless --path . --quit`。
- **坑**：`--check-only --path .` 不带 `--script` 在本机不会退出（会跑主菜单挂住），别用。
- 一次性验证脚本（跑完即删）实测新逻辑，不只走查。

## 用户偏好记录

- 用户明确表示以后不需要 Codex/Claude 主动截图，用户会自己试玩验收。
- 后续除非用户明确要求截图，否则不要新增截图脚本或跑截图验收。

## 已知问题 / 后续建议

- 惩罚系统预设目录 `PenaltyDatabase` 目前很小，正式任务离散惩罚可继续加；
  `severity` 尚未接 UI 分级展示；`apply_penalty` 无"部分失败回滚"事务语义。
- 训练门仍运行时注册、不单独持久化；DoorStateManager 尚未接入正式旧基地导航。
- 工作区仍有大量历史 `.import` / `.uid` / 素材与截图相关未跟踪或修改文件，本轮未处理。
