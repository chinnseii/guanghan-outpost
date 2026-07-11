# REPOSITORY_HYGIENE_AUDIT · 仓库卫生审计与 Phase 1 执行记录

> 分类审计 + 执行结果 · 2026-07-11
> 审计基线：`governance-baseline-2026-07-11`（commit `16f6969`）。
> 本文档已随 P1-01~P1-05 执行完毕后修订（P1-06），订正了早期对 116 个 `.import` 根因的表述。

## 0. 结论先行（TL;DR）
- **116 个 modified `.import` 是零内容改动**：工作区、index blob、HEAD blob 三方字节完全一致，均为 LF。异常来自 **index stat 缓存**里残留的旧 CRLF 文件尺寸（缓存 size 比磁盘大 = CR 字节数），使 `git diff-files` 判定 stat-dirty；系统级 `core.autocrlf=true` 阻止普通 `git update-index --refresh` 自愈。**不是**换行内容差异、也不是导入参数变化。
- **正式资产健康**：`assets/` 70 张图 ↔ 70 个 tracked `.import`，一一对应、无缺失、无真实改动。
- **docs 图片从不被游戏引用**（`res://docs` 全项目零命中）→ 用 `.gdignore` 从源头停止 Godot 导入。
- **35 个未跟踪 `.gd.uid` 全部对应"已跟踪的现役脚本"**，已补交；tracked `.gd.uid` 59 → 94。

## 1. 当前 Git 噪声总览（审计时 238 项）

| 类型 | Git 状态 | 数量 | 所在目录 |
|---|---|---|---|
| `.png.import` | tracked **modified** | 116 | `assets/art` 53 + `docs/**` 63 |
| `.png.import` | untracked | 87 | `docs/**`（全部） |
| `.gd.uid` | untracked | 35 | `scripts/**` 32 + `tools/**` 3 |
| **合计** | | **238** | |

- 无其它类型未跟踪文件；无 `.tscn.uid`（Godot 把场景 uid 内联进 `.tscn` 头）。

### 1.1 modified `.import` 的根因（订正）
早期本文档曾表述为"core.autocrlf=true 造成的 CRLF 内容 churn / 缺少 `.gitattributes`"。**经 P1-01A 深入诊断，该表述不准确，订正如下：**

- **三方字节一致**：对全部 116 个，`sha256(worktree) == sha256(index blob) == sha256(HEAD blob)`（116/116），且 `git hash-object --no-filters` 与 index blob hash 相同；`git ls-files --eol` 显示 `i/lf w/lf`。**不存在任何换行字节差异**。
- **真正异常 = index stat 缓存陈旧**：`git ls-files --debug` 显示 index 缓存 `size` 比磁盘文件**恰好大 CR 字节数**（抽样：1018 vs 978、1041 vs 1001、1050 vs 1010，均 Δ40 = 该文件约 40 行的 CR）。即缓存记录的是"CRLF 时代"的尺寸，而磁盘早已是 LF、blob 也始终是 LF。`git status`/`diff-files` 走 stat 快路径（size 不符）→ 标 modified；`git diff` 比内容 → 为空。
- **为何普通 refresh 无法自愈**：系统级 `core.autocrlf=true` 下，index 的 LF blob 在 checkout 时会被 smudge 成 CRLF，git 认为 LF 工作树"不等于 checkout 应有形态"，于是 `git update-index --refresh` 报 `needs update` 而不刷新 stat。
- **修复方式与实测**：新增仓库级 `.gitattributes`（`* text=auto eol=lf`）+ 受控 `git add --renormalize .`。因全仓 **0 个 tracked 文件在 index 中是 CRLF**（`i/crlf`=0，`i/lf`=437），renormalize **未改写任何已有 tracked 文件内容**——staged 中最终**只有 `.gitattributes`**，116 假象状态被刷新后消失。**证据**：659 个已有 tracked 文件的 blob-hash 指纹前后完全相同（`3f24034d…`）。

## 2. `.gd.uid` 分类（最终结果）

**统一事实**：35 个对应 `.gd` 均存在且已跟踪；`.uid` 在 Git 历史中从未被跟踪（纯首次新增）；全局唯一（与仓库既有 136 个 UID 零碰撞）；单行合法 `uid://`；无外部 `uid://` 引用（脚本按 path 引用，UID 用于跨机器/未来移动稳定性）。

| 状态 | 数量 | 动作 | 说明 |
|---|---|---|---|
| ACTIVE | 32 | TRACK | managers 16 / ui 8 / data 3 / controllers 2 / systems 2 / training 1 |
| TOOL | 3 | TRACK | `tools/capture_*` 3 个；源 `.gd` 已 tracked、另有 5 个同类 capture `.uid` 已 tracked，补交求一致 |
| **合计** | **35** | **TRACK** | 无孤儿、无重复、无非法格式、无未跟踪/已删源脚本 → 无 DELETE_CANDIDATE、无 NEEDS_REVIEW |

- 已在 P1-05 全部补交，tracked `.gd.uid` 由 59 增至 **94**（覆盖全部脚本）。

## 3. `.import` 分类（最终结果）

| 组 | 审计数量 | 是否游戏必需 | 结果 |
|---|---|---|---|
| `assets/**` 正式资产 import | 70 tracked（其中 53 曾显示 modified） | 是（可复现导入必需） | 保持 TRACK；modified 属 stat 假象，已随 `.gitattributes` 刷新消除，未提交任何内容翻转 |
| `docs/art` + `docs/screenshots` import（tracked） | **65**（art 8 + screenshots 57；其中 63 曾 modified） | 否 | 已在 P1-03 `git rm` 移除（工作树+index） |
| `docs/**` import（untracked） | **87**（art 1 + screenshots 86） | 否 | 已在 P1-04 删除；Godot 重扫**未复生**（`.gdignore` 生效） |
| 其它目录 `.import` | 0 | — | — |

- **计数订正**：早期"docs tracked 63"是**处于 modified 的子集**；tracked docs `.import` 的**真实总数是 65**（另 2 个当时未显示 modified）。
- 无 Godot-3 风格 `.import/` 目录（`.gitignore` 里的 `.import/` 行对本 Godot 4 项目是**空规则**，见 §6.1）。

## 4. docs 为什么被 Godot 扫描 + 方案（已落地 B）
- Godot 默认扫描项目根下所有目录 → 给 `docs/**` 图片生成 `.import`。代码搜索确认 docs 图片**从不被游戏 load/preload**（`res://docs` 零命中），纯验收证据 + 设计参考。
- **已采用方案 B**：`docs/screenshots/.gdignore` + `docs/art/.gdignore`（各空文件）。Godot 停止导入这两个目录（图片仅存于此二处）；图片本身继续在 Git 里作证据，路径与 capture/交接流程不变。
- **capture 不受影响**：capture 工具用 `image.save_png("res://docs/…")` + `DirAccess.make_dir_recursive_absolute(globalize_path(…))` 写盘，是文件 I/O，不经资源导入系统；`.gdignore` 只停导入、不阻止写入。P1-03/P1-04 后 editor 重扫零复生，已实证。

## 5. 正式资产风险
- `assets/**`：70 张源图 ↔ 70 个 tracked `.import`，1:1 无缺失（missing=0）；editor 重扫指纹不变（`eb4a9210…`），0 真实修改。**正式资产健康，无高风险项。**
- 提醒：CRLF/stat 假象修掉后，任何仍显示 modified 的 `assets/*.import` 才是真实 import 变化，需人工确认。

## 6. `.gitignore` / `.godot/` / `.godot_appdata/` / 外层 `.git`

### 6.1 `.gitignore` 审计（只读）
现有规则已忽略：`.godot/`、`*.translation`、`builds/`/`exports/`/`*.pck`/`*.zip`/`*.exe`/`*.app`、`.DS_Store`/`Thumbs.db`、`*.tmp`、`*.log`、`*.bak`。
- **未忽略但建议加**：`.godot_appdata/`（见 §6.3）。
- **冗余无效项**：`.import/` 是 Godot-3 目录规则；本项目无 `.import/` 目录（Godot 4 用 `*.import` sidecar），该行**不匹配任何东西 → 冗余、非有害**，建议删除以免误导（现状不误伤 `assets/*.import`，实测 tracked-ok）。
- **无误伤**：`.gd.uid` / 正式 `.import` / `assets` / `scenes` / `docs/governance` 均 `check-ignore` 为 tracked-ok，无规则错误忽略它们。
- 临时验证脚本无专用忽略规则（一次性脚本按"跑完即删"人工处理，已执行）。

### 6.2 `.godot/`
已被忽略，0 跟踪文件。无需动作。

### 6.3 `.godot_appdata/`
- 路径存在：`.godot_appdata/Godot/app_userdata/Guanghan Outpost/{logs,saves}`；总 1 个文件（一个 `godot.log`），约 5K；最近改动 2026-07-06。
- **未被 `.gitignore` 忽略**；当前唯一文件是 `.log`（被 `*.log` 命中），故不出现在 untracked 列表。
- 代码/launcher 不引用；属**本机 Godot 用户数据目录**（app_userdata，含 logs 与 user:// 存档位）。当前 `saves/` 为空。
- **无重要源数据**：只有本机日志；即便日后有存档也是本机 playthrough 状态、非项目资产；删除后 Godot 运行会自动重建。
- **结论：建议 IGNORE**（`.gitignore` 加 `.godot_appdata/`）。原因：`saves/` 下未来若产生 `.json` 存档**不**被 `*.log` 覆盖，会冒成 untracked 噪声；显式忽略整个目录可根治。风险低。

### 6.4 外层空壳 `.git`（`wo-x/.git`）
- 只读确认：仅 `info/`，**无 HEAD、无 objects**；从 `wo-x/` 根跑 `git rev-parse` → `fatal: not a git repository`（**失败响亮**，不会静默错仓库）。
- 由 claude-code-runtime 生成，删除后很可能自动重建。
- **长期规避（不删除）**：① 在治理文档/协作规则明确唯一仓库根 = `outputs/lunar_base_godot`（已记入治理记忆）；② Skill/Agent 开工前 `git rev-parse --show-toplevel` 校验；③ 所有 git/godot 命令固定从 Godot 项目根执行。

## 7. 仓库卫生规则（已固化）

### 换行规则
- 仓库用 `.gitattributes`：`* text=auto eol=lf`。
- **不**修改用户 system/global `core.autocrlf`；**不**把 `.import`/`.uid` 标成二进制（它们是可读文本，保持文本 + LF）。
- 批量 `git add --renormalize` 必须独立任务、先审查 staged diff 再提交。

### docs 规则
- `docs/art/**`、`docs/screenshots/**` 由 `.gdignore` 隔离；docs 图片进 Git、不进 Godot 导入。
- capture 工具可写入这些目录（文件 I/O）；**禁止游戏运行时 load `res://docs/**`**。

### assets 规则
- `assets/**` 是正式游戏资产；其 `.import` 保留并跟踪；docs `.import` 不跟踪。
- 任何 `assets/*.import` 的**真实**变化必须人工确认后单独提交，不与代码混提。

### UID 规则
- 新 `.gd` 与其 `.gd.uid` 一起提交；**禁止手工编辑 UID**。
- 删除脚本时同时评估其 sidecar；不因脚本属于遗留系统就单独删 UID；新增前检查 UID 全仓唯一。

### Agent 规则
- 用精确路径暂存；**禁止**日常 `git add -A`/`.`；**禁止**未经批准 `git clean -fd`/`reset --hard`/`restore`/`checkout -- <path>`。
- 自动生成文件必须与任务相关才提交；每次提交前跑 leak-guard（`git diff --cached --name-only`）。
- 工作区出现大量文件时先分类（`git diff --ignore-cr-at-eol`/`cmp` 辨假 modified），不猜测。
- 只有获授权者可改 `.gitignore`/`.gitattributes`/`.gdignore`。

## 8. Phase 1 清理批次状态

| 批次 | 状态 | 结果 / commit |
|---|---|---|
| P1-01 换行规范化 | ✅ 完成 | `fb139a8 chore(repo): enforce LF line endings`（仅 `.gitattributes`；116 假象消除；659 blob 指纹不变） |
| P1-02 docs `.gdignore` | ✅ 完成 | `af3b9e0 chore(repo): exclude documentation images from Godot imports`（2 个空 `.gdignore`；editor 零新增 import） |
| P1-03 移除 tracked docs `.import` | ✅ 完成 | `183086a chore(repo): remove tracked documentation imports`（`git rm` 65 个；editor 未复生；assets 不变） |
| P1-04 删除 untracked docs `.import` | ✅ 完成（无 commit） | `rm` 87 个未跟踪文件；从未被 Git 跟踪故无提交；editor 未复生 |
| P1-05 `.gd.uid` 补交 | ✅ 完成 | `9475ffb chore(repo): track existing Godot script UIDs`（35 个；tracked uid 59→94） |
| P1-06 审计文档修订 + 配置确认 | 🔄 进行中 | 本次修订本文档；`.gitignore`/`.godot_appdata`/外层 `.git` 只读确认（见 §6） |
| P1-07 卫生基线收口 | ⏳ 待执行 | 视需要改 `.gitignore` + 固化规则 + 决定何时 push 这批卫生提交 |

> 说明：P1-04 删除的 87 个 docs `.import` **没有 commit**，因为它们从未被 Git 跟踪，删除不产生任何 index/tree 变化。

## 9. 尚未确认的问题
1. `.godot_appdata/` 的确切来源（疑似 launch 重定向 app_userdata），只见到一个被忽略的 `godot.log`，其余用途证据不足。
2. 外层 `wo-x/.git` 由哪个 runtime 组件生成、删除后多久重建——证据不足，故只规避不删。
3. `tools/` capture 工具家族是否长期保留——若决定归档，其 `.gd` 与 `.gd.uid` 归属随之变（本轮按现役 TRACK）。

## 附：Phase 1 执行后工作区
- tracked modified 0；staged 0；untracked 仅本文档（提交后归零）。
- `main` 相对 `origin/main` ahead（P1 卫生提交尚未 push）。
- 全程未改源码/场景/正式资源；未改用户 system/global Git 配置。
