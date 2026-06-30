# 迭代计划

## V0.1 原型骨架

- 单场景 Godot 4 项目
- 俯视角玩家移动
- 广寒前哨基础地图
- 温室、太阳能阵列、生命维持设备、补给降落区
- 每日资源结算
- 土豆、藻类、菌菇三种作物
- 月尘、维修、地球补给、月夜压力

## V0.2 基地建造

已完成：

- 按 `B` 打开/关闭建造模式
- 底部建造按钮选择模块
- 建造预览格显示可放置/不可放置
- 建造消耗维修件和电力
- 新增可建造模块：
  - 太阳能阵列
  - 电池舱
  - 小型温室
  - 制氧与水回收
  - 维修工作台
- 模块数量影响每日资源结算

后续可增强：

- 舱段必须与核心舱连通
- 模块有独立耐久和气密性
- 拆除/移动模块
- 建造队列和机器人施工时间

## V0.3 星露谷式手感

已完成：

- 加入玩家朝向和简单步行动画
- 加入工具：采样铲、除尘刷、维修枪
- 除尘和维修需要对应工具
- 加入可采集点：月壤、水冰样本、陨石金属、特殊月壤样本
- 加入新资源：月壤、水冰、科研样本

后续可增强：

- 把当前脚本画图替换为正式素材
- 加入工具升级和使用耗时
- 加入出舱氧气/宇航服耐久消耗

## V0.4 地球补给规划

已完成：

- 补给改为提前申请
- 每 7 天开放一次申请窗口
- 每批补给有重量、到达时间和货单类型
- 补给约 3 天后抵达，小概率延迟 1 天
- HUD 显示在途补给和 ETA
- 补给抵达后需要前往降落区领取

后续可增强：

- 玩家提前申请更细粒度的自定义货单
- 地球预算/信誉影响补给质量
- 加入补给舱落点偏差，需要出舱取货
- 加入中秋/春节等地球通信事件

## V0.5 真实月球系统

已完成：

- 新建模块必须贴近已有基地模块
- 有气压的舱段可能被微陨石击中并漏气
- 漏气舱段显示红色警戒框
- 漏气每天额外消耗氧气并降低完整度
- 使用维修枪可消耗维修件封堵漏点

后续可增强：

- 月壤提氧
- 水冰采集与冰矿处理
- 更完整的舱压、气闸和外出氧气消耗
- 辐射风暴
- 前哨员健康、精神状态、低重力影响

## V0.6 保存与读取

已完成：

- `F5` 保存当前局
- `F9` 读取存档
- `F10` 新开局
- 右侧 UI 按钮：保存、读取、新开局
- 存档写入 `user://guanghan_outpost_save.json`
- 保存日期、资源、玩家位置、模块、作物、漏气、采集点、补给订单和日志

后续可增强：

- 多存档槽
- 主菜单
- 自动保存
- 存档版本迁移

## V0.7 TileMap 月面地形

已完成：

- 使用 Godot `TileMapLayer` 替换脚本绘制的月面网格
- 运行时生成月面 `TileSet`
- 生成 4 种月壤地表 tile
- 保留 22x13 基地网格和现有建造/采集逻辑

后续可增强：

- 使用正式像素素材替换运行时生成 tile
- 增加 TileMap 碰撞层
- 增加舱内/舱外地形层
- 增加道路、电缆、管线 tile

## V0.8 中国探月科技线

已完成：

- 嫦娥样本数据库：消耗科研样本和月壤解锁
- 嫦娥样本数据库效果：采样收益提高，作物收获额外 +15%
- 鹊桥中继：消耗科研样本和维修件解锁
- 鹊桥中继效果：补给运输缩短 1 天，并降低发射延迟概率
- 玉兔机器人：消耗维修件和月壤解锁
- 玉兔机器人效果：每天自动巡视，少量采集月壤，并缓慢清理太阳能板月尘
- 科技状态进入保存/读取系统

后续可增强：

- 玉兔机器人自动搬运补给
- 鹊桥中继解锁月背任务
- 嫦娥样本数据库解锁月壤改良配方
- 广寒温室：高级密封农业模块

## V0.9 生命维持闭环

已完成：

- 新增资源：舱压、宇航服氧气、二氧化碳、温室湿度
- 新增模块：气闸舱、月壤提氧机、冰矿处理器
- 气闸舱可消耗电力和氧气补满宇航服氧气
- 舱外行动持续消耗宇航服氧气
- 站在未漏气的加压舱段内可恢复宇航服氧气
- 漏气会降低舱压，生命维持设备会恢复舱压
- 前哨员每日产生二氧化碳
- 作物生长消耗二氧化碳，并受温室湿度影响
- 月壤提氧机可消耗月壤和电力生产氧气
- 冰矿处理器可消耗水冰和电力生产水

后续可增强：

- 更细的独立舱压与隔离闸门
- 宇航服耐久与舱外任务时间
- 温室温度、营养液、病害
- CO2 过滤器和氧气/氢气电解链

## V0.10 前哨运营层

已完成：

- 加入主菜单
- 加入 3 个存档槽
- 存档内容扩展到任务、前哨员状态和补给舱落点
- 玩家、模块、采集点拆成独立 Godot 场景
- 主脚本同步数据层与独立显示场景，后续可替换正式 Sprite/动画
- 科技树扩展：
  - 闭环生态控制
  - 精确着陆雷达
  - 机器人协作协议
- 阶段任务目标：
  - 稳住第一周
  - 第一座温室
  - 原位制氧
  - 出舱取货
  - 前哨员稳定
- 加入单人前哨员健康、精神状态和疲劳
- 劳动力路线调整为机器人扩展，不再新增其他常驻人员
- 机器人协作协议降低重复劳动压力
- 补给抵达后生成偏差落点补给舱
- 精确着陆雷达和鹊桥中继会降低落点偏差
- 玩家需要出舱到信标位置回收补给舱

后续可增强：

- 舱内/舱外分层地图与碰撞
- 正式像素素材、动画和音效
- 前哨员疲劳、低重力健康事件和机器人劳动力系统
- 补给舱搬运耗时、载重和玉兔自动搬运
- 将主脚本继续拆成 Resource 数据表和 Manager 节点

## V0.11 舱内/舱外分层与碰撞

已完成：

- 增加舱内地板 `TileMapLayer`
- 月面与舱内地板分层显示
- 模块外壳加入基础碰撞
- 可进入模块保留舱门通道和内部可行走区
- 普通加压舱段只在贴近相邻舱段的一侧开连通门
- 气闸舱作为主要舱内/舱外出入口
- 太阳能阵列、补给区、月壤提氧机、冰矿处理器作为舱外设备阻挡移动
- 模块视觉升级为第一版正式素材场景：
  - 外壳
  - 舱内地板边框
  - 根据连通关系显示舱门标识
  - 设备细节
- 单人前哨员设定替代多人常驻设定
- 科技线从“岗位轮换制度”调整为“机器人协作协议”

后续可增强：

- 真正的舱门开关与气密隔离
- 舱内家具、床铺、控制台和储物柜
- 电缆、管线、道路 TileMap
- 机器人实体、机器人充电桩和任务队列

## V0.12 出舱任务系统 V1

已完成：

- 增加出舱任务面板
- 任务面板动态显示当前可执行的出舱目标：
  - 回收补给舱
  - 采集水冰
  - 清理太阳能板
  - 维修外部设备
- 宇航服状态扩展：
  - 氧气
  - 耐久
  - 月尘污染
- 舱外行动会持续消耗氧气、积累月尘污染，并缓慢损耗宇航服耐久
- 出舱前会检查宇航服氧气和耐久
- 宇航服氧气低于 35% 或耐久低于 25% 时阻止离舱
- 返舱时提示复压检查
- 气闸循环现在会补氧、复压、除尘并恢复少量宇航服耐久
- 回收补给舱、采集水冰、清理太阳能板、外部维修会增加不同程度的月尘污染
- 外部维修可用于太阳能阵列、月壤提氧机、冰矿处理器等舱外设备

后续可增强：

- 背包、载重和多次搬运
- 补给舱开箱和分批回收
- 低氧倒计时、太阳风暴、微陨石短时警报
- 玉兔和搬运机器人接管部分出舱任务
- 出舱任务日志、奖励和失败后果

## V0.13 舱内设施与像素素材 V1

已完成：

- 舱内模块视觉细化
- 居住舱加入：
  - 床铺
  - 储物柜
  - 控制台
- 生命维持舱加入：
  - 气体/水循环罐
  - 控制台
  - 管线
- 维修工作台加入：
  - 工作台
  - 储物柜
  - 机器人充电桩
- 气闸舱加入：
  - 舱门框
  - 除尘光带
  - 宇航服架
- 电池舱加入更清晰的电池组显示
- 模块地板加入像素风格网格和块面细节
- 控制台、机器人充电桩等设施加入简单闪烁动画
- 增加程序生成的交互占位音效：
  - 气闸循环
  - 维修
  - 除尘
  - 采集
  - 补给回收
  - 保存/读取

后续可增强：

- 把代码绘制设施拆成独立 sprite 资源
- 添加正式音效和环境音
- 让床铺、控制台、储物柜、机器人充电桩具备独立交互功能
- 舱内家具占用格子和碰撞
- 机器人充电桩接入机器人任务队列

## V0.14 舱内设施玩法化

已完成：

- 舱内设施可被独立交互命中
- 床铺功能：
  - 恢复疲劳
  - 小幅恢复健康和精神
  - 消耗少量食物和水
- 控制台功能：
  - 查看基地关键状态
  - 查看漏气数量
  - 查看补给信标数量
  - 查看背包负重和机器人任务
- 储物柜功能：
  - 管理出舱背包
  - 将背包里的月壤、水冰、样本和维修件转入基地库存
- 出舱背包系统：
  - 月面采集资源先进入背包
  - 背包容量限制为 12
  - 背包满时需要回储物柜入库
- 机器人充电桩功能：
  - 切换机器人任务
  - 支持待机、自动采样、自动巡检、补给搬运
- 机器人任务每日生效：
  - 自动采样增加月壤
  - 自动巡检降低月尘并恢复设备完整度
  - 补给搬运辅助补给回收或整理备件
- 存档扩展：
  - 保存背包内容
  - 保存当前机器人任务

后续可增强：

- 独立背包 UI 面板
- 储物柜选择性存取
- 控制台独立页面和趋势图
- 床铺推进时间或触发睡眠事件
- 机器人实体出现在地图上并执行可见路径

## V0.15 新手引导与当前目标

已完成：

- 增加左上角“当前目标”面板
- 第一日引导流程：
  - 查看控制台
  - 前往气闸补氧/除尘
  - 出舱采集月面资源
  - 回储物柜入库
  - 去温室种植第一批作物
  - 去补给降落区申请补给
  - 进入下一天
- 当前目标会根据玩家是否完成关键动作自动推进
- 完成新手流程后，目标面板会根据当前基地状态给出战略建议：
  - 电力偏低
  - 食物偏低
  - 氧气偏低
  - 存在漏气
  - 补给舱已落地
  - 背包有物资
  - 月夜将至
- 新手引导进度进入保存/读取系统
- 开局日志改为任务简报，提示玩家先看左上角目标

后续可增强：

- 更正式的新手弹窗和高亮箭头
- 第一次操作时高亮控制台/气闸/储物柜/温室
- 可开关的帮助面板
- 失败原因解释和复盘提示

## V0.16 大画面与可读性

已完成：

- 默认窗口从 1280×720 调整到 1600×900
- 地图格子从 48 放大到 56
- 舱段、舱内家具、角色与地图细节整体变大
- 右侧信息栏移到地图外侧，减少 UI 覆盖地图
- 底部按钮区下移，给地图和任务面板留出更多空间
- 主菜单和补给申请面板重新居中

后续可增强：

- 增加设置项：小/中/大 UI 缩放
- 增加相机缩放快捷键
- 进一步整理控制台、背包、任务为独立页面

## V0.17 相机与 UI 缩放

已完成：

- 增加 `Camera2D` 跟随玩家
- 地图缩放：
  - `Z` 放大地图
  - `X` 缩小地图
  - 右侧按钮也可调整
- UI 缩放：
  - `[` 缩小 UI
  - `]` 放大 UI
  - 右侧按钮也可调整
- 右侧显示当前地图缩放和 UI 缩放比例
- 缩放设置进入保存/读取系统

后续可增强：

- 缩放预设：小/中/大
- 鼠标滚轮缩放地图
- UI 响应式重排
- 控制台/背包/任务独立窗口

## V0.18 搬运、机器人队列与舱外风险

已完成：

- 补给舱不再一键领取
- 补给舱保存剩余货物清单
- 玩家每次只能按背包剩余容量搬运一部分补给
- 背包满时必须回储物柜入库
- 补给状态显示剩余货物和信标坐标
- 机器人充电桩改为任务队列
- 机器人每日消耗电力执行队列中的一个任务
- 机器人任务：
  - 自动采样
  - 自动巡检
  - 补给搬运
- 搬运机器人可从补给舱自动转运一批货物
- 舱外风险事件：
  - 低氧倒计时提醒
  - 太阳风暴预警
  - 微陨石短时警报
  - 太阳风暴期间舱外氧气消耗和月尘污染上升
  - 微陨石预警期间宇航服耐久损耗上升
  - 月尘污染会提高气闸返舱维护成本
- 风险状态和机器人队列进入保存/读取系统

后续可增强：

- 独立补给舱开箱 UI
- 补给货物按箱/桶/氧罐显示在地图上
- 机器人实体可见化和路径移动
- 太阳风暴倒计时 UI
- 微陨石避险舱内等待机制

## V0.19 可见机器人、独立页面与舱内交互

已完成：

- 增加独立机器人场景 `scenes/robot.tscn`
- 增加机器人视觉脚本 `scripts/robot_visual.gd`
- 机器人会在地图上显示，并根据当前任务向采样点、外部设备或补给舱移动
- 机器人位置、目标点和移动状态进入保存/读取系统
- 控制台打开独立基地状态页面
- 储物柜打开独立背包/入库页面
- 补给舱打开独立货物页面，显示在途、已落地和剩余货物状态
- 舱内床铺、储物柜、控制台和机器人充电桩加入交互高亮
- 舱内家具加入第一版碰撞，占用空间更明确
- 提示音逻辑拆到 `scripts/audio_feedback.gd`
- 存档路径和槽位摘要逻辑开始拆到 `scripts/save_manager.gd`

后续可增强：

- 机器人按实时任务队列移动并完成工作，而不是主要跨天结算
- 给机器人移动添加路径线、任务图标和完成动画
- 把代码绘制家具逐步替换为独立 sprite 资源
- 添加环境氛围音、气闸音效、脚步声和工具音效
- 继续拆分 `main.gd`：资源表、任务系统、机器人系统、UI 页面管理器

## V0.20 新手任务卡、实时机器人与音效入口

已完成：

- 左上角“当前目标”升级为今日任务卡
- 任务卡明确显示：
  - 行动
  - 原因
  - 完成条件
- 第一次进入游戏时，地图箭头会依次指向：
  - 控制台
  - 气闸
  - 月面采集点
  - 储物柜
  - 温室
  - 补给区
- 机器人队列改为实时执行：
  - 任务入队后自动启动
  - 机器人移动到目标点
  - 到达后才结算采样、巡检或搬运效果
- 机器人移动时显示可见路径线和目标点脉冲
- 机器人任务完成时显示日志反馈并播放对应提示音
- 音效系统扩展为命名事件入口：
  - 环境氛围
  - 气闸
  - 工具
  - 搬运
  - 机器人
  - 脚步
- 新增 `scripts/robot_task_manager.gd`
- 机器人任务名称和可运行判断开始从 `main.gd` 拆出
- 旧的跨天机器人任务结算逻辑已移除，避免和实时队列冲突

后续可增强：

- 任务卡扩展为可展开任务日志
- 给第一次操作加入屏幕边缘提示、遮罩和 UI 高亮
- 机器人任务支持取消、暂停、优先级调整
- 机器人增加电量、充电等待和任务失败反馈
- 将家具和设备替换为真正的独立 PNG/sprite 资源
- 添加循环环境音、气闸完整音效、脚步声和工具声采样
- 继续拆分 `main.gd`：资源表、任务系统、UI 页面管理器

## V0.21 第一批独立家具 Sprite

已完成：

- 新增第一批独立 PNG sprite 资源：
  - `assets/sprites/facilities/bed.png`
  - `assets/sprites/facilities/storage.png`
  - `assets/sprites/facilities/console.png`
  - `assets/sprites/facilities/robot_charger.png`
- `scripts/module_visual.gd` 改为优先使用 PNG sprite 绘制：
  - 床铺
  - 储物柜
  - 控制台
  - 机器人充电桩
- 保留程序绘制回退：
  - PNG 加载失败时仍然能显示旧版设施图形
  - 避免资源导入问题导致项目无法启动
- 控制台和机器人充电桩仍保留状态灯动画叠加

后续可增强：

- 将气闸、生命维持罐、温室种植床、太阳能板替换为独立 sprite
- 建立统一的 sprite atlas 或 TileSet 资源
- 加入正式音效采样，而不是程序生成提示音
- 继续将模块视觉逻辑拆分为更独立的资产/渲染管理脚本

## V0.22 新手引导第二轮与任务日志

已完成：

- 新增任务日志面板 `TaskLog`
- 任务日志显示新手流程：
  - 查看控制台
  - 气闸检查
  - 采集资源
  - 储物柜入库
  - 温室种植
  - 申请补给
  - 进入下一天
- 已完成任务显示 `[x]`
- 当前任务显示 `[>]` 并高亮说明
- 今日任务卡新增“提示”行，用于显示最近一次失败原因和下一步行动
- 常见卡点会给出行动化提示：
  - 氧气/耐久不足不能出舱
  - 背包容量不足
  - 未选择采样铲
  - 建造距离太近
  - 建造空间不足
  - 建造未贴近基地
  - 建造资源不足
- 地图引导箭头增强：
  - 目标圈更明显
  - 远距离目标会显示从玩家到目标的引导线
- PNG sprite 加载改为优先使用 Godot 导入资源，避免导出警告

后续可增强：

- 任务日志支持展开/折叠
- 加入屏幕边缘目标提示
- 给第一次操作加入 UI 遮罩和按钮高亮
- 将失败提示整理为独立 TutorialManager

## V0.23 机器人电量与任务面板

已完成：

- 新增机器人电量 `robot_battery`
- 新增机器人充电状态 `robot_charging`
- 机器人执行任务移动时会消耗电量
- 电量低时会暂停当前任务
- 被暂停的当前任务会放回队列最前方
- 机器人低电量时会返回充电点
- 充电期间暂停任务队列
- 充满后继续执行队列
- 机器人电量和充电状态进入保存/读取系统
- 新增机器人任务面板 `RobotPanel`
- 面板显示：
  - 当前状态
  - 当前任务
  - 电量
  - 目标地点
  - 任务队列
- 面板操作：
  - 取消当前/排队任务
  - 搬运优先
  - 巡检优先
  - 采样优先
- 控制台状态页显示机器人状态和电量

后续可增强：

- 机器人电量条和充电动画

## V0.24 机器人任务失败与类型分化

已完成：

- 新增机器人最近问题提示 `robot_failure_note`
- 机器人任务面板显示机器人类型
- 机器人任务面板显示最近一次失败/跳过原因
- 搬运补给任务开始前会检查落地补给舱
- 没有落地补给舱时，搬运补给自动跳过并写入日志
- 补给舱货物已经搬空时，搬运补给自动跳过并写入日志
- 搬运任务失败时不再给予“零件安慰奖”
- 玉兔采样任务开始前会检查可用月壤、水冰或科研样本点
- 玉兔采样到达后会复核目标是否仍存在
- 如果采样目标被提前采完，玉兔会重新选择最近资源点继续执行
- 玉兔采样成功后会消耗对应采集点，并根据类型产出月壤、水冰或科研样本
- `scripts/robot_task_manager.gd` 新增机器人类型命名接口
- 玉兔采样、维护巡检、搬运补给三条能力线在命名和面板上分化
- 机器人失败提示进入保存/读取系统

后续可增强：

- 为三类机器人加入不同 sprite 或状态灯
- 维护机器人只在有月尘、漏气或完整度损耗时优先出动
- 机器人任务失败可在地图目标点附近显示短提示

## V0.25 引导体验打磨

已完成：

- 新增屏幕边缘目标提示 `EdgeHint`
- 当前新手目标离开视野时，边缘提示显示方向和距离
- 边缘提示跟随相机缩放、UI 缩放和玩家移动实时刷新
- 新增任务日志折叠状态 `task_log_expanded`
- 任务日志支持简略/展开切换
- 简略模式显示当前任务和最近历史
- 展开模式显示完整新手流程和更多历史
- 新增任务历史 `task_history`
- 任务历史记录新手步骤完成
- 任务历史记录阶段目标完成
- 任务历史记录每日长期目标建议
- 新增首次引导遮罩 `IntroOverlay`
- 第一次进入新局时遮罩高亮左上角今日任务卡
- 遮罩说明黄色目标、高亮箭头和屏幕边缘提示的用途
- 首次遮罩是否看过、任务日志展开状态和历史记录进入保存/读取系统

后续可增强：

- 任务完成时加入短暂屏幕反馈和音效差异
- 当前目标支持手动追踪/取消追踪
- 将新手引导逻辑拆成独立 TutorialManager

## V0.26 正式素材下一轮

已完成：

- 新增第二批独立 PNG sprite 资源：
  - `assets/sprites/facilities/airlock_door.png`
  - `assets/sprites/facilities/life_support_tank.png`
  - `assets/sprites/facilities/greenhouse_bed.png`
  - `assets/sprites/facilities/solar_panel.png`
- `scripts/module_visual.gd` 新增第二批素材路径常量
- 气闸门优先使用 `airlock_door.png`
- 生命维持罐优先使用 `life_support_tank.png`
- 温室种植床优先使用 `greenhouse_bed.png`
- 太阳能板优先使用 `solar_panel.png`
- 第二批 sprite 保留程序绘制回退
- PNG 加载支持未导入素材直接读取，避免新增资源时刷导入错误
- `scripts/audio_feedback.gd` 增加持续环境底噪
- 气闸、工具、搬运、机器人事件改为短音型
- 玩家移动时加入轻脚步声
- 音频节点退出时会主动停止并释放 stream，避免验证时出现退出警告

后续可增强：

- 给机器人、补给舱、月面采集点制作独立 sprite
- 建立统一 sprite 尺寸和命名规范
- 将程序生成音效替换为正式采样音效文件

## V0.27 机器人玩法深化

已完成：

- `scripts/robot_visual.gd` 接入三类机器人独立 sprite
- 玉兔采样、维护巡检、搬运补给使用不同外观
- 机器人显示状态灯：
  - 绿色：执行/可用
  - 蓝色：充电
  - 橙红：低电
- 机器人显示电量条
- 机器人完成采样、维护、搬运时显示屏幕反馈
- 机器人完成任务时在地图位置显示短暂完成标记
- 维护机器人只在月尘、漏气或完整度损耗时出动
- 无维护目标时，维护任务自动跳过并说明原因

## V0.28 任务体验继续打磨

已完成：

- 新增短暂屏幕完成反馈 `CompletionToast`
- 新增短暂地图完成标记
- 新手任务、阶段任务和机器人任务完成都会触发反馈
- 新增“目标栈”面板 `ObjectiveStack`
- 目标栈合并显示：
  - 当前目标
  - 出舱任务
  - 长期目标
  - 追踪状态
- 新增关键目标追踪开关 `objective_tracking`
- `T` 键可切换目标自动居中/追踪
- UI 追踪按钮可切换目标追踪
- 目标追踪状态进入保存/读取系统

## V0.29 正式素材第三轮

已完成：

- 新增机器人 sprite：
  - `assets/sprites/robots/yutu_sample.png`
  - `assets/sprites/robots/maintenance_bot.png`
  - `assets/sprites/robots/hauler_bot.png`
- 新增采集点/补给舱 sprite：
  - `assets/sprites/collectables/regolith_node.png`
  - `assets/sprites/collectables/ice_node.png`
  - `assets/sprites/collectables/meteor_node.png`
  - `assets/sprites/collectables/sample_node.png`
  - `assets/sprites/collectables/supply_pod.png`
- `scripts/collectable_visual.gd` 优先使用独立 sprite 绘制月面资源和补给舱
- 采集点加入类型状态点，水冰、样本、陨石、补给更容易分辨
- 新增 `docs/SPRITE_GUIDE.md`
- 建立设施、机器人、采集点 sprite 尺寸规范和状态颜色规范

## V0.30 可读性与美术方向重整

已完成：

- 新增第一版玩家角色 sprite：
  - `assets/sprites/player/astronaut_walk.png`
- 玩家显示从抽象圆点升级为像素宇航员
- 宇航员支持 4 方向和 2 帧步行动画
- 玩家低氧时显示红色提示圈，舱外状态显示蓝色宇航服外轮廓
- 月面 tile 色调改为更冷、更暗，减少和舱内地板混在一起的问题
- 舱内地板提高亮度和结构线，舱内/舱外分层更容易辨认
- 模块视觉增加外壳阴影、粗边框、门标识和类型色条
- 居住舱、气闸、温室、生命维持、工作台、太阳能和补给区拥有更明确的视觉身份
- 月面采集点和补给舱视觉尺寸放大
- 资源点增加底座、信标和状态徽标，提高远距离识别度
- 环境音 playback 改为按需获取，避免退出验证时残留 Godot 播放对象

## V0.31A 素材规范和脚本拆分准备

已完成：

- 重写 `docs/SPRITE_GUIDE.md`，用中文整理当前 sprite 目录、命名、尺寸、颜色和接入规则。
- 新增 `scripts/asset_catalog.gd`，集中记录玩家、机器人、设施、采集点 sprite 路径。
- `scripts/asset_catalog.gd` 同时收纳常用状态色，给后续 UI 图标和视觉脚本留统一入口。
- `scripts/player_visual.gd`、`scripts/robot_visual.gd`、`scripts/module_visual.gd`、`scripts/collectable_visual.gd` 改为从 catalog 加载 PNG。
- 保留原有加载策略：优先使用 `.import` 导入资源，失败时直接读 PNG；如果 PNG 不可用，视觉脚本仍使用程序绘制回退。
- 没有调整核心玩法、任务结算、地图布局或存档数据。

后续建议：

- V0.31B 可以补充 `assets/sprites/ui/`，优先做工具、资源、警告和任务追踪图标。
- 后续新增素材先写入 `scripts/asset_catalog.gd`，避免视觉脚本继续散落路径常量。
- 等 tile 素材稳定后，再考虑把月面地表、舱内地板和 UI 图标纳入同一份素材规范。
- `main.gd` 下一轮只建议继续拆低风险内容，例如 UI 文案表或素材/颜色表，不建议同时动任务系统大逻辑。

## V0.31 月面作业体验

已完成：

- 出舱任务面板升级为 V2，会按建议顺序显示当前可执行任务。
- 回收补给舱、采集水冰、清理太阳能板、维修外部设备、回储物柜入库都会进入可追踪目标列表。
- 每个任务显示距离、风险等级和建议工具。
- 风险等级会参考距离、宇航服氧气、宇航服耐久、月尘、太阳风暴和微陨石预警。
- 新增 `Y` 键和“切换目标”按钮，用于在多个追踪目标之间轮换。
- `T` 继续控制目标追踪开关。
- 当前追踪目标索引进入保存/读取系统。
- 常驻生成式环境底噪暂时关闭，避免 Godot 退出验证时残留 `AudioStreamGeneratorPlayback`；事件提示音仍保留。

## Direction Lock：生命优先与 TS-001

已完成：

- 新增 `docs/PROJECT_BRIEF.md`，记录项目核心方向：
  - 让生命，在从未存在生命的地方生长
  - Life First
  - Hope Before Efficiency
  - Relay Before Hero
  - Home Before Base
  - Silence Has Value
- 新增 `docs/art/TS-001/README.md`，记录第一张目标截图：
  - 玩家第一次踏上月球
  - 地球作为视觉中心
  - 运输船在身后准备离开
  - 旧基地在远方发出微弱暖光
  - HUD 极简，强调孤独、距离和希望
- 明确第一小时不优先做居民、自动化、复杂科技树、复杂建造、采矿、战斗、大地图探索或建筑升级。
- 明确第一株植物不是玩家种出来的，而是玩家救活的。
- 后续开发优先从“堆系统内容”切换为“Foundation + 第一小时体验”。

## Sprint 01 Foundation 第一轮

已完成：

- 新增 `docs/SPRINT_01_FOUNDATION.md`，将 Sprint 01 Issue List 转成项目内 checklist。
- 新增 `scripts/game_state_manager.gd`：
  - Boot
  - MainMenu
  - Application
  - Training
  - Launch
  - Landing
  - MoonSurface
  - BaseInterior
  - Sleep
- 新增 `scripts/time_manager.gd`，支持 Day / Hour / Minute / Time Scale / Pause。
- 新增 `scripts/camera_manager.gd`，集中管理固定镜头、跟随、缩放和未来镜头锁定。
- 新增 `scripts/ui_manager.gd`，提供 UI Root、HUD、Prompt、Dialogue 占位入口。
- 新增 `scripts/event_manager.gd`，支持事件触发、一次性事件和事件状态保存。
- 新增 `scripts/audio_manager.gd`，集中转发现有 UI / 事件音频入口。
- 新增 `scripts/interactable.gd` 和 `scripts/interaction_detector.gd`，为统一 E 键交互系统预留接口。
- 新增 Resource 数据类型：
  - `ItemData`
  - `LifeEntityData`
  - `StructureData`
  - `InteractableData`
  - `DialogueData`
  - `SceneEventData`
- 新增测试数据：
  - `data/foundation/test_life_entity.tres`
  - `data/foundation/test_structure.tres`
- `main.gd` 已轻量接入 GameState、Time、Camera、UI、Event 和 Audio managers。
- 存档开始保存 Foundation managers 的状态。

## 当前下一步建议

1. Sprint 01 Foundation：
   - 建立 `FoundationTestMap` 测试场景
   - 将玩家移动拆为 `PlayerController.gd`，支持启用/禁用输入
   - 将现有 E 键交互逐步迁到 `Interactable` / `InteractionDetector`
2. TS-001 可运行灰盒：
   - 用现有 TileMap 和像素素材搭出“运输船离开、远处旧基地、地球可见”的测试场景
   - 保持 HUD 极简，只显示宇航服状态、时间和环境信息
   - 不写死剧情，先验证镜头、光照、UI 层级和氛围
3. 第一小时体验设计：
   - 设计进入旧基地、发现生活痕迹、恢复生命支持、救活最后一株植物的状态流
   - 明确第一株植物不是种出来的，而是救活的
   - 暂缓复杂科技树、机器人自动化和大规模资源循环
4. 素材目录继续收口：
   - 补充 UI 图标目录，例如氧气、电量、时间、辐射、补给
   - 后续新增素材先登记到 `scripts/asset_catalog.gd`
   - 将 TS-001 的颜色脚本同步到 `docs/SPRITE_GUIDE.md`

## Sprint 02 Arrival Playable Prototype

Status: in progress / dev prototype.

Important boundary: ArrivalLandingScene is currently a development test entry, not the permanent New Game opening. The future canonical flow is still planned as Application -> National Training -> Final Assessment -> Mission Acceptance -> Launch -> Arrival.

Completed:

- Added `docs/reports/SPRINT_01_FOUNDATION_REVIEW.md`.
- Added `res://scenes/arrival/ArrivalLandingScene.tscn`.
- Added `res://scenes/base/BaseInterior_Test.tscn`.
- Added `scripts/arrival/arrival_landing_scene.gd`.
- Added `scripts/arrival/base_interior_test.gd`.
- Added `scripts/lighting_manager.gd` and `scripts/light_zone.gd` as the first lighting framework pass.
- Added main menu `Dev Entry: Arrival Prototype` button for direct testing.
- TS-001 prototype includes player movement, moon TileMapLayer, transport ship, Earth, distant base, airlock, engineering traces and minimal HUD.
- TS-002 Observe Earth event triggers after standing still in the target area for 5 seconds, weakens HUD, locks the camera briefly, shows the AI line and saves the one-shot event state.
- Airlock interaction shows `E 进入气闸` and switches to `BaseInterior_Test`.
- F5/F9 arrival prototype save/load stores scene, player position, game state, time, ObserveEarthEvent and airlock entry state.

Still intentionally out of scope:

- Full first-hour flow.
- Application/training/assessment/launch sequence.
- Automation, robots, mining, tech tree, construction upgrades and complex UI.
- Final art/audio for TS-001 and TS-002.

## Sprint 02 Revision 01: Arrival Layout & Feel

Status: complete.

Completed:

- Removed the grey-board feeling from Arrival by darkening and widening the lunar surface.
- Added a separate sky layer for Earth so it reads as sky/background rather than a map prop.
- Re-composed the first view: Earth high, old base far ahead, transport ship behind/left, player lower in the frame.
- Reworked transport ship placeholder with ramp, engine glow and landing scorch marks.
- Reworked distant base and airlock with warmer light and greater distance.
- Added restrained moon work-site detail: footprints, tire tracks, cables, cargo, rocks, craters, dust and solar-panel silhouette.
- Confirmed ObserveEarthEvent is false at scene start and only flips after the player waits inside the trigger area.
- Added F3 debug panel toggle and separated debug readout from the player HUD.

Still intentionally out of scope:

- Application, training, launch sequence, inventory, mining, robots, tech tree, automation and final art/audio.

## Sprint 02 Direction Adjustment: Arrival Cinematic Scene Split

Status: complete.

Completed:

- Added `res://scenes/arrival/ArrivalCinematicScene.tscn`.
- Added `scripts/arrival/arrival_cinematic_scene.gd`.
- Split responsibilities:
  - `ArrivalCinematicScene` handles TS-001 / TS-002 mood, Earth in sky, transport ship, player silhouette, distant base and Observe Earth.
  - `ArrivalLandingScene` remains the top-down gameplay prototype for movement, airlock and base entry.
- Main menu dev entry now starts with `ArrivalCinematicScene`.
- Cinematic scene hides debug by default, keeps only minimal HUD, and supports F3 debug toggle.
- ObserveEarthEvent can trigger in the cinematic scene after the player remains still for 5 seconds.
- The event saves to the arrival prototype save file and does not repeat after load.
- After the cinematic moment, `E` / `Enter` transitions to `ArrivalLandingScene`.

Out of scope remains unchanged: no application flow, training, launch sequence, inventory, mining, robots, tech tree or final art/audio.

## ArrivalCinematicScene Polish Pass

Status: complete.

Completed:

- Moved Observe Earth AI line to lower subtitle placement.
- Reduced Earth size by roughly 10-15% and increased blue brightness/cold rim glow.
- Strengthened transport ship readability with engineering panel lines, landing struts, a clearer ramp, engine afterglow and moon dust.
- Adjusted the player into a back-facing, still silhouette aimed toward Earth/base.
- Changed the continue prompt to `E / Enter 前往基地气闸`.
- Lowered HUD presence and kept debug hidden by default behind F3.

No new gameplay systems were added.

## Sprint 03 Prologue & Application

Status: complete first playable pass.

Completed:

- Added `res://scenes/application/ApplicationStartScene.tscn`.
- Added `res://scenes/application/TrainingPlaceholderScene.tscn`.
- Added `scripts/application/application_flow_scene.gd`.
- Added `scripts/application/training_placeholder_scene.gd`.
- Added `scripts/data/player_profile_data.gd`.
- Main menu now offers `Apply to Project Guanghan` and `Continue Mission`.
- Direct sandbox/arrival entries remain available but are labeled `Dev Only`.
- Application flow includes identity, education, appearance, review, preliminary eligibility result and training placeholder.
- Player profile saves to `user://saves/application_profile.json`, including submitted/accepted state, current step and next scene after application.
- Education background is saved as context only; no numerical bonuses or RPG attributes were added.
- Accept mission, withdraw Moon assignment, and the 17-pioneer black screen are deferred until after training/final assessment.

Deferred to Sprint 04+:

- National training gameplay.
- Final assessment.
- Launch sequence.
- Any plant, backpack, mining, automation, resident, tech tree or RPG-stat systems.

## APP-002A Application UI Update

Status: complete.

Completed:

- Reduced gender choices to `男` and `女`.
- Confirmed the form does not ask for nationality, ID number, emergency contact, or other real-world sensitive fields.
- Added system-generated mission fields to the profile and Basic Information page:
  - Application ID
  - Candidate file status
  - Mission identity
- Moved character/suit preview out of Basic Information and into `03 外观与标识`.
- Renamed the preview to `开拓者预览 / PIONEER PREVIEW`.
- Updated preview focus to suit, patch, suit ID, name initials, and marking color.
- Added explicit notes that appearance is display/record only and does not affect ability.
- Gender only changes visual body preset options.

## Sprint 03 Revision 02: Application Result Flow

Status: complete.

Completed:

- Replaced the former admission/final-choice ending with `资格初审结果 / PRELIMINARY ELIGIBILITY REVIEW`.
- Removed `接受使命` and `放弃申请` from the Sprint 03 application flow.
- Removed the immediate accept-mission black screen route from Sprint 03.
- Result page now states that official Moon assignment can happen only after national training and final assessment.
- Result page buttons are `进入训练序列` and `返回主菜单`.
- `进入训练序列` now goes to `TrainingStartScene`.

## Sprint 03 Minor Patch Before Acceptance

Status: complete.

Completed:

- Updated the training placeholder copy to say the national training sequence is initializing and candidate profile sync should be confirmed.
- Renamed the training placeholder dev button to `开发入口：进入月球抵达原型`.
- Separated suit ID, patch ID and name initials in the Appearance & Marking data path.
- Changed the Submit Application confirmations into three required checkboxes.
- Disabled `提交申请` until all three confirmation statements are checked.
- Confirmed the review sequence ends with `正在建立候选人档案` and `审核完成`.
- Adjusted Preliminary Eligibility Review into a formal notice addressed to the player name.

Still out of scope:

- Sprint 04 training gameplay.
- Final assessment.
- Accept Mission / 17-pioneer black screen.

## Sprint 03 Final UI Bugfix / Polish

Status: complete.

Completed:

- Changed the application shell to keep the footer buttons outside the scrollable content area.
- Added a scrollable middle content area so oversized pages do not push navigation buttons off-screen.
- Reduced fixed minimum widths in the header, step tabs and page columns for cleaner 1600x900 presentation and usable 1280x720 presentation.
- Improved Submit Application checkbox visibility with clearer unchecked outlines, checked icons and restrained blue active-state styling.
- Kept the existing submit gating logic: all three confirmation statements must be checked before `提交申请` enables.

Still out of scope:

- Sprint 04 training gameplay.
- Any application-flow redesign beyond this acceptance polish.

## Sprint 04 National Training

Status: complete first playable pass.

Completed:

- Added `TrainingManager` for training progress save/load at `user://saves/training_progress.json`.
- Added `TrainingStartScene` as the normal handoff after Sprint 03 preliminary eligibility review.
- Added scripted training modules:
  - Suit Control
  - Airlock Procedure
  - Power Repair
  - Life Support
  - Plant Diagnosis
- Added `FinalAssessmentScene` as a small scripted incident sequence, not a quiz and not a full simulation.
- Added `MissionAssignmentNoticeScene`, gated behind final assessment completion.
- Added temporary decline and accept assignment paths.
- Added assignment black screen text with 17 pioneers, shown only after accepting the moon assignment.
- Added transition from the black screen into `ArrivalCinematicScene`.
- Updated `Continue Mission` to route to the current application/training state.
- Added clearly marked Dev Only training entries in the main menu.

Implementation scope:

- Oxygen, power, life support and plant values are scripted training states only.
- No full survival system, full crop system, launch animation, mining, automation, tech tree or resident system was added.

Next polish candidates:

- Replace training target rectangles with more readable room props.
- Add small terminal beeps and restrained status animations.
- Add a compact progress overview on TrainingStartScene.

## TR-001 Training Room Visual Blockout

Status: complete for Training Module 01.

Completed:

- Converted Training Module 01's right-side play area from abstract target blocks into a readable training room blockout.
- Added scripted placeholder room visuals: floor tile grid, cool-grey wall boundary, overhead training lights and small wall equipment panels.
- Replaced the module-one target blocks with semantic placeholder props:
  - Training console with screen and controls.
  - Floor marker/decal with dashed outline and target reticle.
  - Airlock-style training exit door using cold white/blue and weak amber highlight instead of green.
- Replaced the player square with a simplified astronaut trainee silhouette.
- Added a local `E 交互` / `E 使用训练终端` room prompt near interactable targets.
- Kept the left side as a training control HUD and kept the existing movement/interact/module-complete logic.

Still out of scope:

- Full oxygen, power, repair, crop or scoring systems.
- Complex animation or final art.
- Expanding later training modules beyond the shared visual direction.

## Sprint 04 Module 01 Minor Polish

Status: complete.

Completed:

- Clarified Module 01 objective hints so the marker zone reads as movement-only and only the training terminal asks for E interaction.
- Added current-target visual hierarchy: marker, terminal and exit are highlighted only when they are the active objective.
- Kept the exit visible from the start but visually locked until the module reaches the exit step.
- Changed the active exit interaction so pressing E advances directly to the next training module.
- Nudged the player start position farther inside the training room.
- Fixed marker-zone completion so the trainee must enter the visible marker rectangle; loose distance checks are no longer used for movement zones.
- Added a temporary F3 trigger-debug overlay for marker-zone alignment checks.

Still out of scope:

- New training systems.
- Full survival, oxygen, power, repair or crop simulation.
