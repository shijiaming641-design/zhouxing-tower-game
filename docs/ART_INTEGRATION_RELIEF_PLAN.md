# Godot 美术接入降压方案

这份文档不是讲美术风格，而是讲 `如何减少返工`。

当前项目最消耗心力的原因，不是“图不够好”，而是：

1. 结构还在变
2. 贴图还没定
3. 文本区和装饰区没有严格分层

只要这三件事同时发生，UI 就会不断回头调。

所以这份方案的目标只有一个：

**先锁结构，再换贴图；先定挂点，再谈精修。**

---

## 一、执行原则

### 1. 先锁版心，不锁花纹

先固定：

- 标题区
- 列表区
- 详情区
- 按钮区
- 美术承接区

不要先固定：

- 角花
- 纹样
- 边框细节
- 光效
- 装饰图标

原因很简单：花纹会换，版心不能一直换。

### 2. 先接“容器”，不接“最终图”

每个界面都先有：

- `背景挂点`
- `边框挂点`
- `卡面挂点`
- `徽记挂点`
- `按钮底图挂点`

这些挂点先存在，哪怕里面只是纯色或空白节点。

这样后面美术资源进来时，改的是内容，不是结构。

### 3. 每次只定一个模板页

当前最适合作为模板页的是：

- [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:64)

原因：

1. 它同时包含标题、列表、详情、按钮、卡面。
2. 它是最典型的“系统页”。
3. 它调顺了，后面的角色页、商店页、图鉴页都能照着套。

结论：

**先把初始布局页做成模板，再复制方法到其他界面。**

---

## 二、初始布局页的锁定边界

以下内容建议直接锁死，不再频繁改位置和尺寸。

### A. 必锁结构

这些区域后续只允许换图或微调透明度，不再改布局逻辑：

1. `顶部区`
   - 标题
   - 槽位状态
   - 局外修正信息

2. `上方编组区`
   - 已备布局槽位
   - 每个槽位的宽高
   - 槽位之间的间距

3. `左列列表区`
   - 外框位置和宽度
   - Scroll 容器位置和宽度
   - 单卡高度
   - 卡片内部三段式结构

4. `右列详情区`
   - 标题位置
   - 详情框尺寸
   - 名字 / 序列 / 摘要的层级顺序

5. `底部按钮区`
   - 返回
   - 起兵开局
   - 图例/说明按钮

### B. 可换美术，不改结构

这些地方应该以后只改素材，不改排布：

1. `背景图`
   - [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:76)

2. `左列大框贴图`
   - [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:221)

3. `单卡浅底承接区`
   - [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:580)

4. `详情面板边框与底图`
   - [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:251)

5. `按钮底图 / hover 底图`
   - [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:326)

---

## 三、初始布局页推荐的美术接入层

这页建议固定成 4 层。

### 第 1 层：结构层

职责：

- 决定位置
- 决定尺寸
- 决定交互

包括：

- VBox/HBox
- ScrollContainer
- Button
- PanelContainer
- Label

这层不要因为贴图变化而改逻辑。

### 第 2 层：承接层

职责：

- 给贴图留干净的承载面

当前已经有一部分：

- 左列列表外框
- 单卡浅底承接区
- 详情区外框

这层的核心原则：

**哪怕最终贴图还没来，也要先有“画布”。**

### 第 3 层：贴图层

职责：

- 放底图
- 放边框
- 放纹样
- 放章纹

这层以后优先用：

- `TextureRect`
- 必要时配 `PanelContainer`

不建议让贴图直接取代结构节点。

### 第 4 层：信息层

职责：

- 显示文本
- 显示状态
- 显示规则信息

这层必须永远压在贴图层之上。

结论：

**以后任何美术接入，都不要跳过“承接层”直接把图压进文本层。**

---

## 三点五、当前已命名挂点

为了减少沟通损耗，初始布局页里已经补了一批明确挂点，后续接图优先使用这些节点名。

### 页面级挂点

- `ComboSelectBackground`
- `TitleBackdrop`
- `TopBand`
- `BottomAccentBand`
- `BottomPlate`
- `ComboListFrame`
- `ComboListScroll`
- `DetailFrame`
- `DetailFrameTexture`
- `DetailSummaryPlate`

### 列表卡级挂点

每张卡会以 `ComboCard_<combo_id>` 命名，例如：

- `ComboCard_penetrating_strike`
- `ComboCard_qin_tiger_push`

卡内统一挂点：

- `CardArtPlate`
- `CardArtTexture`
- `CardContent`
- `CardSequenceWrap`
- `CardSequenceLabel`
- `CardTextWrap`
- `CardNameLabel`
- `CardRoleLabel`
- `CardStatusWrap`
- `CardCooldownLabel`
- `CardStateLabel`
- `CardInfoButton`

结论：

**后续如果美术说“我要换左列卡底”“我要接详情框底纹”，可以直接对节点名，不要再靠相对位置描述。**

---

## 四、初始布局页当前推荐工作流

### 阶段 1：停调结构

当前这页先进入“结构冻结”状态：

- 不再左右挪主区块
- 不再改列宽大逻辑
- 不再改详情和列表的对位关系

只允许：

- 替换图片
- 调透明度
- 调颜色
- 调边距 4 到 12 像素级别

### 阶段 2：接静态底图

顺序建议：

1. 先接页面背景
2. 再接左列外框
3. 再接单卡底纹
4. 最后接详情框底图

不要一开始就接按钮花纹和角花。

### 阶段 3：接卡面资产

卡面美术优先级：

1. 卡片底面
2. 卡片边框
3. 序列装饰
4. 状态区角标
5. hover/selected 特效

### 阶段 4：最后再做发光和动态

只有在静态贴图稳定后，才做：

- hover 光
- 选中光
- 微弱呼吸
- 进入动画

不然每换一次图都要重调动态。

---

## 五、明确哪些地方以后不要再动

为了减压，下面这些以后建议直接视为“冻结”。

### 不要再频繁动的内容

1. 左列整体宽度
   - 当前以 [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:221) 到 [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:235) 为基准

2. 单卡高度
   - 当前单卡基准在 [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:558)

3. 右侧详情框位置
   - 当前基准在 [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:251)

4. 上方编组槽位位置
   - 当前基准在 [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:194)

5. 底部主按钮位置
   - 当前基准在 [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:326) 和 [combo_select.gd](/Users/xiaoshizi/.openclaw/workspace/zhouxing-godot/scenes/ui/combo_select.gd:358)

这些不锁，后面一切美术接入都会变成返工。

---

## 六、推荐的后续接入顺序

不要再多界面并行。

建议顺序：

1. `初始布局页`
   - 做成模板页

2. `角色选择页`
   - 套同样的标题区、列表区、详情区逻辑

3. `主菜单`
   - 套同样的按钮底图和信息层逻辑

4. `图鉴页`
   - 套同样的面板/滚动区逻辑

5. `战斗 UI`
   - 最后做

原因：

战斗 UI 的动态最多，最容易把你拖进无限细修。

---

## 七、你现在最该做什么

不是继续一个像素一个像素调。

而是：

1. 把初始布局页当成模板页
2. 接第一轮静态底图
3. 只改承接层，不改结构层
4. 做完后截图确认版心
5. 再复制到其他系统页

一句话总结：

**以后美术接入，默认只换图，不动骨架；默认只改承接层，不回头拆结构。**
