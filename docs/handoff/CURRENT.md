# 当前状态（滚动文档，每次覆盖重写）

更新时间：2026-07-07
更新人：Claude Code（代 Codex，物品品质系统）

## 正在进行

（暂无——本轮"物品品质系统 v1"已实现完成。开始本轮工作前确认过
`git status`/`CURRENT.md` 均无 Codex 新的并发改动，工作过程中也没有再出现
新的并发改动，属于单人顺序推进的一轮，不是像上一轮那样的多方合并快照。）

## 本轮完成（Claude Code，代 Codex）：物品品质系统 v1

- **`scripts/data/ItemDatabase.gd` 新增 `const QUALITY_LEVELS`**（5 级）：
  1 劣质 `#D6D6D6` / 2 普通 `#4A90E2` / 3 稀有 `#9B5DE5` / 4 史诗 `#D6A23A` /
  5 传奇 `#D94A4A`（用的是需求方给的"冷色克制"配色，不是网游感更重的高
  饱和第一组）。
- **33 个物品全部新增 `"quality": <1-5>` 字段**（本轮自行分配，需求文档
  没给逐条数值）：种子 5 种 + 金属碎片/温室基质 = 1；基础食物 3 种/两种
  基础消耗品/大部分材料/两个默认工具/系统资源编号 6 种 = 2；番茄/大豆/
  三种预留消耗品/三个耐久工具 = 3；便携电池包 = 4；目前没有 5 级物品。
- **新增静态 helper**：`get_quality(item_id)`（缺失兜底 2）/
  `quality_name_for_level(level)` / `quality_color_for_level(level)` /
  `get_quality_name(item_id)` / `get_quality_color(item_id)` /
  `colored_display_name(item_id)`（返回 `[color=#RRGGBB]名字[/color]`，**这是
  唯一对外接口**，所有显示物品名的地方都必须调这一个函数，不要自己拼颜色）。
- **改用 `colored_display_name()` 的调用点**：
  - `InventoryManager._stack_lines_for_category()` / `_durable_lines()`。
  - `ItemContainer.slot_label()`（`BackpackManager`/`StorageManager` 的
    `_slot_lines()` 都经过它）。
  - `SupplyManager._item_display_name()`（真实物品才上色，"月球车"这个
    特殊强制货物条目和查无此 ID 时保持纯文本不上色）。
- **把渲染这些文本的 Label 换成 RichTextLabel（`bbcode_enabled = true`）**，
  否则 `[color=...]` 标签会原样显示成文字：
  - `scripts/ui/inventory_panel.gd`（`B` 键库存面板）。
  - `scripts/ui/backpack_storage_panel.gd`（背包/仓库面板，Codex 的文件，
    本轮为了让品质颜色能显示出来而改动，只改了 Label→RichTextLabel 这一处
    渲染层，没有动任何按钮/业务逻辑）。
  - `SupplyManager`/`RepairManager` 走的是 `main.gd` 的 `add_log()`
    Debug 日志，那个 `TaskLog` 本来就是 `RichTextLabel(bbcode_enabled=true)`
    ，不需要改渲染节点。
- **`RepairManager.gd` 本轮未改动**：它目前完全不显示任何物品/材料的
  `display_name`（只显示 `item_id` 和数量），没有可以接入颜色的地方；等它
  以后真的显示物品名时，直接调用 `ItemDatabase.colored_display_name()`
  即可，不需要另外发的一套颜色。
- **v1 明确只做外观，不影响任何数值**：不碰 `effects`/`weight`/
  `max_durability`/`durability_loss_per_use`/维修成功率/任何结算逻辑。
  需求文档提到的"后续可扩展作用"（食物按品质给不同恢复量等）本轮全部
  没有做，只留了 `quality` 字段和等级表方便以后接。
- 设计参考文档已同步更新：第八节"物品系统"里新增"物品品质 Quality"子
  小节（在"面板文本"和"存档"之间），记录了等级表、33 个物品的等级分布、
  唯一接口 `colored_display_name()`、每个调用点、以及"只做外观不做数值"
  的边界。没有改动 Codex 自己加的"八点五""八点六"和"维修系统 v1"章节。

## 验证

- Godot 4.7 headless：`main.tscn` +
  `OldBaseInteriorScene`/`OldGreenhouseScene`/`Day02StartScene`/
  `WeekRoutineStartScene`/`SolarArrayExteriorScene`/`Training_03_PowerRepair`/
  `FinalAssessmentScene` 共 8 个共用场景反复加载，均无 `SCRIPT ERROR`/
  `Parse Error`。
- 临时脚本（未提交，验证后已删除）跑通了：全部 33 个物品的 `quality` 都在
  1–5 区间；未知 item_id 的品质/名字正确兜底成 2/普通；五级名字/颜色表跟
  需求文档逐字匹配；`colored_display_name()` 的 BBCode 包裹格式正确；
  `InventoryManager.panel_status_text()` 里堆叠物品行和耐久工具行都带上了
  正确的颜色标签；`ItemContainer.slot_label()` 输出跟 `InventoryManager`
  用的是同一个颜色（验证了同一个 item_id 在两条路径上颜色一致，满足"背包/
  仓库/库存读取同一套颜色"的要求）；`SupplyManager._item_display_name()`
  对真实物品上色、对未知 ID 保持纯文本。

## 已知问题 / 暂不覆盖范围

- 品质等级第一版是本轮按"越基础越低阶"的直觉手动分配的，不是需求文档
  逐条给定的数值，系统设计如果要重新分配，直接改 `ItemDatabase.gd` 里
  `ITEMS` 对应条目的 `"quality"` 数字即可，不需要改结构。
- `RepairManager` 目前还没有任何物品名显示逻辑可以接入颜色，等它有 UI
  面板显示材料清单时需要单独接入（调用同一个 `colored_display_name()`）。
- 品质对数值的所有扩展作用（食物恢复量、工具最大耐久、材料维修成功率、
  补给重量/获取难度、植物收获加成）本轮全部没有做，纯粹是 UI 装饰。
- 以下延续自上一轮（物品系统 + Codex 并发的 Supply/Backpack/Storage/
  Repair 系统）的已知问题仍然有效，未在本轮改动：物品系统没有背包容量/
  负重/格子摆放/装备栏/腐坏/复杂合成/工具维修/批量烹饪/交易；旧的固定
  `eat`/`nutrition_drink` 行动仍未被 `InventoryManager.eat_item()` 取代，
  两条路径并存；`RepairManager` 仍只有系统骨架 + Debug 入口，没有正式
  玩家可见 UI。完整清单见
  `docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md` 第九节。

## 先别碰

- `scripts/managers/BackpackManager.gd` / `StorageManager.gd` /
  `SupplyManager.gd` / `RepairManager.gd` / `scripts/data/FaultDatabase.gd`
  的业务逻辑仍是 Codex 自己推进的系统，本轮只改了
  `backpack_storage_panel.gd` 里 Label→RichTextLabel 这一处纯渲染层代码
  （为了让品质颜色显示出来），没有碰任何按钮/流程/数据结构，其余部分
  照旧留给 Codex。
- `scripts/data/ItemDatabase.gd` / `scripts/managers/InventoryManager.gd`
  本轮继续由 Claude Code 维护，改前照旧先
  `git log --oneline -- <file>`。
