# 美术资源目录与命名规范

这份规范只解决一件事：让 `秦 / 宋 / 中国` 的美术资源可以持续扩内容，同时不把项目目录和代码路径做乱。

## 1. 当前目录结构

```text
assets/
├── backgrounds/
│   ├── battle/
│   ├── main_menu/
│   └── map/
├── characters/
├── enemies/
├── icons/
│   ├── combat/
│   └── system/
├── items/
│   ├── era_sets/
│   │   ├── china/
│   │   ├── qin/
│   │   └── song/
│   └── icons/
├── reference/
└── ui/
    ├── china/
    │   ├── backgrounds/
    │   ├── frames/
    │   ├── nodes/
    │   └── seals/
    ├── qin/
    │   ├── backgrounds/
    │   ├── frames/
    │   ├── nodes/
    │   └── seals/
    └── song/
        ├── backgrounds/
        ├── frames/
        ├── nodes/
        └── seals/
```

## 2. 目录用途

- `assets/characters/`
  - 角色立绘、头像、战斗半身图。
- `assets/enemies/`
  - 敌人和 Boss 立绘。
- `assets/backgrounds/`
  - 跨时代共用的大背景图。
- `assets/ui/<era>/backgrounds/`
  - 时代专属 UI 背景，例如主菜单、地图、战斗底纹。
- `assets/ui/<era>/seals/`
  - 时代章印、标题角标、卷章图。
- `assets/ui/<era>/frames/`
  - 边框、底板、角钉、章框。
- `assets/ui/<era>/nodes/`
  - 地图节点、页签、特殊 UI 小块。
- `assets/items/icons/`
  - 全时代通用器物图标。
- `assets/items/era_sets/<era>/`
  - 时代专属器物图标、套装图。
- `assets/icons/system/`
  - 设置、规则、音效、返回等系统图标。
- `assets/icons/combat/`
  - 天 / 地 / 人、护盾、攻击、机括等战斗图标。
- `assets/reference/`
  - 设计参考图，不直接在游戏里引用。

## 3. 命名规则

统一使用：

- 小写英文
- 下划线分词
- 不要空格
- 不要中文文件名
- 不要在文件名里写版本号 `final/final2/最终版`

推荐格式：

```text
<era>_<page>_<subject>_<variant>.png
```

示例：

- `qin_main_menu_bg.png`
- `qin_map_seal_small.png`
- `song_battle_frame_gold.png`
- `china_node_boss_active.png`
- `qin_item_tiger_tally.png`
- `song_item_trade_ledger.png`
- `china_item_mountain_seal.png`

角色与敌人：

- 角色立绘：
  - `doctor_portrait.png`
  - `merchant_portrait.png`
  - `wanderer_battle.png`
- 敌人立绘：
  - `enemy_basic_tian.png`
  - `enemy_elite_counter.png`
  - `enemy_boss_qin.png`

## 4. 尺寸建议

先统一尺寸，再换资源。否则接入速度会越来越慢。

- 角色头像：
  - `256x256` 或 `512x512`
- 战斗角色半身图：
  - 高度优先，建议 `512x768`
- 敌人立绘：
  - 建议 `512x512`
- UI 章印：
  - 小章印 `128x40`
  - 中章印 `192x56`
- 节点图标：
  - `64x64`
- 器物图标：
  - `64x64` 或 `96x96`
- 大背景：
  - 按 `1280x720` 出图

## 5. 出图要求

- 默认透明底 PNG
- UI 边框和章印不要烘焙大块纯色背景
- 同一组资源的描边粗细尽量一致
- 不要把说明文字画死进大多数 UI 素材里
  - 章印可带字
  - 背景、边框、节点、按钮底板尽量无字

## 6. 时代资源最小交付清单

每个时代先补这 4 组，收益最高：

### 秦

- `assets/ui/qin/backgrounds/qin_main_menu_bg.png`
- `assets/ui/qin/seals/qin_chapter_seal.png`
- `assets/ui/qin/frames/qin_panel_frame.png`
- `assets/ui/qin/nodes/qin_node_battle.png`

### 宋

- `assets/ui/song/backgrounds/song_main_menu_bg.png`
- `assets/ui/song/seals/song_chapter_seal.png`
- `assets/ui/song/frames/song_panel_frame.png`
- `assets/ui/song/nodes/song_node_shop.png`

### 中国

- `assets/ui/china/backgrounds/china_main_menu_bg.png`
- `assets/ui/china/seals/china_chapter_seal.png`
- `assets/ui/china/frames/china_panel_frame.png`
- `assets/ui/china/nodes/china_node_boss.png`

## 7. 代码接入原则

以后代码引用资源时，优先按时代分发，不要在逻辑里到处写死零散路径。

推荐路径模式：

```text
res://assets/ui/<era>/backgrounds/...
res://assets/ui/<era>/seals/...
res://assets/ui/<era>/frames/...
res://assets/items/era_sets/<era>/...
```

其中 `<era>` 固定使用：

- `qin`
- `song`
- `china`

不要混用：

- `qin_dynasty`
- `song_dynasty`
- `modern_china`

## 8. 当前建议的下一步

优先补这几组资源：

1. `秦 / 宋 / 中国` 的主菜单背景图
2. `秦 / 宋 / 中国` 的地图页章印
3. `秦 / 宋 / 中国` 的战斗页边框底板
4. 三个时代各 1 张 Boss 立绘

这样最少投入，就能让现有代码立刻吃到明显的美术提升。
