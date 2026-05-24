# 第一批 12 张图最小交付包

这份文档只服务一个目标：先用最少的 12 张图，把 `秦 / 宋 / 中国` 三卷的观感拉开。

配套文档：
- [ART_ASSET_GUIDE.md](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/docs/ART_ASSET_GUIDE.md)
- [ART_ASSET_CHECKLIST.md](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/docs/ART_ASSET_CHECKLIST.md)

## 一、为什么先做这 12 张

这 12 张图直接覆盖 3 个最高频页面：

1. 主菜单
2. 地图页
3. 战斗页

玩家一进游戏、进地图、进战斗，就会立刻感知 `秦 / 宋 / 中国` 的时代差异。  
这批图不碰零碎小图标，收益最高，接入成本最低。

## 二、12 张图清单

### 1. 主菜单背景图 3 张

- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/ui/qin/backgrounds/qin_main_menu_bg.png`
- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/ui/song/backgrounds/song_main_menu_bg.png`
- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/ui/china/backgrounds/china_main_menu_bg.png`

用途：
- 主菜单背景底图

建议内容：
- `秦`：军阵、铜黑、边军压境、诏令感
- `宋`：城防、绢纸、楼阁、市舶、文气
- `中国`：山河、终局、龙脉、复归、赤金感

尺寸：
- `1280x720`

要求：
- 可以带氛围纹理
- 不要把按钮文字画死
- 中央区域尽量留视觉呼吸空间

---

### 2. 地图页章印 3 张

- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/ui/qin/seals/qin_map_seal.png`
- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/ui/song/seals/song_map_seal.png`
- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/ui/china/seals/china_map_seal.png`

用途：
- 地图页右上或标题区的时代章印

建议内容：
- `秦`：东出、军令、玄黑铜印
- `宋`：市舶、文治、墨青印
- `中国`：山河、终局、赤金印

尺寸：
- 建议 `192x56`

要求：
- 透明底 PNG
- 可带字
- 描边和章框清晰

---

### 3. 战斗页边框底板 3 张

- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/ui/qin/frames/qin_battle_frame.png`
- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/ui/song/frames/song_battle_frame.png`
- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/ui/china/frames/china_battle_frame.png`

用途：
- 战斗页的整页氛围边框、底板装饰

建议内容：
- `秦`：兵符、甲片、铜角、军令纹
- `宋`：卷轴、绢边、城砖、墨线
- `中国`：山河纹、鼎纹、终局裂纹、薪火纹

尺寸：
- 建议 `1280x720`

要求：
- 中央尽量空
- 左右侧栏和底栏可以有装饰
- 不要把血条、按钮位置画死

---

### 4. Boss 立绘 3 张

- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/enemies/enemy_boss_qin.png`
- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/enemies/enemy_boss_song.png`
- [ ] `/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/assets/enemies/enemy_boss_china.png`

用途：
- 战斗页右侧敌方 Boss 立绘

建议内容：
- `秦`：战主、铁甲、军律、压迫
- `宋`：守势、权谋、城防、拖杀
- `中国`：终局共主、百代叠影、复合感

尺寸：
- 建议 `512x512`

要求：
- 透明底 PNG
- 适合放进右侧敌方立绘卡
- 不要把背景做死

## 三、交付标准

这 12 张图只要满足下面 5 条，就可以直接接：

1. 文件名严格按上面路径
2. PNG 格式
3. 尺寸符合建议值
4. 不把整页文案写死进图里
5. 时代视觉差异明显

## 四、接入后会立刻变化的页面

这 12 张图接进去后，马上能看到变化的页面：

1. 主菜单
2. 地图页
3. 战斗页 Boss 区
4. 战斗整体时代氛围

## 五、制作顺序建议

如果美术时间很紧，按这个顺序出：

1. 先出 3 张主菜单背景
2. 再出 3 张地图章印
3. 再出 3 张 Boss 立绘
4. 最后出 3 张战斗边框底板

原因：
- 主菜单背景最容易立刻见效
- 地图章印最快体现时代切换
- Boss 立绘最直接增强战斗辨识度
- 战斗底板是锦上添花，但工作量相对更高

## 六、交付后我这边可以直接做的事

这 12 张图到位后，我可以直接继续：

1. 把主菜单按时代自动切背景
2. 把地图页按时代自动切章印
3. 把战斗页按时代自动切 Boss 立绘
4. 把战斗页按时代自动切边框底板
