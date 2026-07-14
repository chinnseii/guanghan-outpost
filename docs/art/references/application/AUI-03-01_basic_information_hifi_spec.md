# AUI-03-01 基础信息页高保真样板

## Reference Image

AUI-03-01_basic_information_hifi_reference.png

## Approved Product Fields

Editable required fields:
- 姓名
- 性别
- 出生年份

System-generated fields:
- 申请编号
- 候选人编号
- 档案状态
- 任务身份

Removed:
- 联系方式

## Required Progress Behavior

- 当前页面必填项总数：3
- 初始状态：0 / 3
- 姓名、性别、出生年份各完成一项，进度加 1
- 圆环与文本必须使用同一个真实状态
- 3 / 3 且校验通过后，“下一步”可用

## Validation Status

- 0–2 / 3：待完成
- 3 / 3 且存在无效内容：需检查
- 3 / 3 且校验通过：已完成

## Visual Rules

- 页面打开时姓名框默认不是 Focus，除非现有产品逻辑明确自动聚焦
- Active 步骤保持当前冷蓝高亮
- 下一步 Disabled 状态必须明显弱化
- 不使用霓虹、呼吸动画或大面积发光
- 页面布局以参考图为准
- 右侧任务信息图必须由真实 Control / Texture 节点组成
- 禁止把整张参考图直接作为页面背景

## Scope

This reference applies only to:
- 01 基础信息页
- 通用顶部结构
- 当前步骤导航
- 当前页面表单
- 系统生成字段
- 任务信息区
- 固定底部操作栏

Out of scope:
- 02 学术背景
- 03 外观与标识
- 04 提交申请
- 资格初审结果页
- Completed / Submitted 状态
- 全局 Theme 重构