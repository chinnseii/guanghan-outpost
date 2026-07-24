# 《广寒前哨》素材库 V2 规范

适用范围：TR-002 训练中控室。本文是当前 V2 的唯一素材入库标准；TR-001 不在本轮重构范围内。

## 1. 统一尺度

| 类别 | 游戏显示尺寸 | 入库源文件尺寸 | 约束 |
|---|---:|---:|---|
| 地板 Tile | 64×64 | 256×256 | 4× 源图；同一套 TileMap 只能使用此规格 |
| 墙体直段 / 转角 | 64 的整数倍 | 64 的整数倍 | 2–4× 显示缩放；可旋转复用 |
| 横向门 | 128×64 显示 | 256×128 | frame / body / light 分层 |
| 纵向门 | 64×128 显示 | 128×256 | frame / body / light 分层 |
| 中央控制台 | 96–128 宽显示 | 256×192 或 256×256 | 不能超过 2 格地砖宽 |
| 顶部灯具 | 64 或 128 宽显示 | 128×64 或 256×64 | 不烘焙光晕 |
| 方向铭牌 | 32 显示 | 128×128 | 现有四张可复用 |

任何源文件的宽高必须是 64 的整数倍。禁止把 512 或 1024 的写实图直接缩到 64 显示；如有高分辨率母图，必须先离线缩小并验收后才能入库。

## 2. 固定视觉规则

- 扁平像素填色，清楚轮廓，2–3 级明暗；不使用渐变、柔焦、法线贴图感凹凸、照片级划痕或密集铆钉。
- 主色为深蓝灰 / 冷灰；科技蓝仅作细线或屏幕；橙黄只用于警告；绿色只用于生态与稳定状态。
- 地板主材保持安静：只允许一张主板材和一张格栅变体。检修盖、重度磨损、警戒条等改作独立 decal，不得塞满基础地板。
- 墙、门、控制台、灯具必须使用同一像素密度和同一套 2–3 级明暗，不得混用旧版软阴影概念图素材。

## 3. 正式目录与命名

```text
assets/art/training_hub_v2/
  tiles/
  walls/
  doors/
  props/
  lighting/
  decals/
  manifests/
```

命名：`<category>_<object>_<variant>.png`，全小写 ASCII snake_case。

示例：

```text
tiles/floor_plate_plain_01.png
tiles/floor_grate_center_01.png
walls/wall_straight_horizontal_01.png
walls/wall_corner_inner_01.png
doors/door_horizontal_frame_01.png
doors/door_horizontal_body_closed_01.png
doors/door_horizontal_light_strip_01.png
props/console_training_main_01.png
lighting/light_ceiling_bar_01.png
decals/decal_floor_scuff_small_01.png
```

## 4. V1 资源处置状态

经用户与工程侧确认，第一版训练中控室素材已全部移除：

```text
assets/material/
assets/art/training_hub/
```

其中包括旧 Atlas、旧地板、旧门框、旧控制台、旧方向铭牌及其 `.import` 文件。V2 不复用这些资源；方向铭牌也将在 V2 统一尺度下重新制作或作为 V2 新资源重新入库。

工程侧仍需将旧路径引用替换为 V2 路径后再运行导入和截图验证。`.import` 文件由 Godot 自动生成，不单独版本化维护。

## 5. 入库门槛

每个新素材入库前须满足：

1. 尺寸符合上表，PNG RGBA，透明边缘干净。
2. 在 64×64 TileMap 预览中不显得比 80–96px 角色更高密度或更模糊。
3. 可读性优先于纹理；基础 Tile 不带烘焙强光或强阴影。
4. 门必须提供 frame / body / light 三层；铭牌为独立 Sprite。
5. Godot 导入使用 Nearest、关闭 mipmap；开发验证 UV、pivot、状态与碰撞。

Visual PASS 不等于 Code Correctness。
