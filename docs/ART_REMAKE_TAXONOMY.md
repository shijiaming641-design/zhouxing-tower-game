# 美术包重制分类规范 v1

这份文档用于重新制作并替换当前项目美术包。目标是让资源分类清晰、命名稳定、尺寸统一，并能直接接入 `ArtRegistry`。

## 1. 总目录

```text
assets/
├── ui/                 # 时代 UI 与页面皮肤
├── characters/         # 玩家角色
├── enemies/            # 敌人与 Boss
├── items/              # 装备、器物、时代秘器
├── icons/              # 系统、战斗、状态、交互图标
├── effects/            # 战斗反馈、命中特效、胜负反馈
├── reference/          # 通用 UI 组件与设计参考
└── audio/              # 音乐与音效
```

## 2. UI 分类

UI 是当前项目最重要的换皮层，建议按时代分开。

```text
assets/ui/
├── qin/
├── song/
└── china/
```

每个时代内部固定为：

```text
assets/ui/<era>/
├── backgrounds/
├── frames/
├── seals/
├── nodes/
├── buttons/
├── cards/
└── overlays/
```

### 2.1 页面背景 `backgrounds`

用途：主菜单、地图、战斗、商店、营寨、事件、结算等页面底图。

建议尺寸：`1280x720`。

命名：

```text
<era>_main_menu_bg.png
<era>_map_bg.png
<era>_battle_bg.png
<era>_shop_bg.png
<era>_rest_bg.png
<era>_event_bg.png
<era>_result_bg.png
```

当前必须优先做：

```text
qin_main_menu_bg.png
qin_map_bg.png
qin_battle_bg.png
song_main_menu_bg.png
song_map_bg.png
song_battle_bg.png
china_main_menu_bg.png
china_map_bg.png
china_battle_bg.png
```

### 2.2 页面框架 `frames`

用途：大页面边框、战斗 HUD 框、商店底板、营寨面板、弹窗框。

建议尺寸：

- 全屏框：`1280x720`
- 大面板：`1024x560`
- 中面板：`640x360`
- 小面板：`320x180`

命名：

```text
<era>_menu_frame.png
<era>_battle_frame.png
<era>_shop_panel.png
<era>_rest_panel.png
<era>_event_panel.png
<era>_overlay_frame.png
<era>_result_panel.png
```

### 2.3 章印与标题 `seals`

用途：时代卷章印、页面标题章、地图卷章、战斗卷章。

建议尺寸：

- 小章：`128x40`
- 中章：`192x56`
- 大章：`256x72`

命名：

```text
<era>_main_menu_seal.png
<era>_map_seal.png
<era>_battle_seal.png
<era>_shop_seal.png
<era>_rest_seal.png
<era>_event_seal.png
```

注意：章印可以带字，其他 UI 框尽量不要把文字画死。

### 2.4 地图节点 `nodes`

用途：杀戮尖塔式地图节点。

建议尺寸：`64x64` 或 `96x96`，透明底。

命名：

```text
<era>_node_battle.png
<era>_node_shop.png
<era>_node_rest.png
<era>_node_event.png
<era>_node_boss.png
```

可选状态：

```text
<era>_node_battle_locked.png
<era>_node_battle_available.png
<era>_node_battle_cleared.png
```

### 2.5 按钮 `buttons`

用途：主菜单按钮、返回、开始、继续、刷新、购买、强化等。

建议尺寸：

- 大按钮：`320x96`
- 中按钮：`180x64`
- 小图标按钮：`64x64`

命名：

```text
<era>_button_large.png
<era>_button_medium.png
<era>_button_icon.png
<era>_button_hover.png
<era>_button_pressed.png
<era>_button_disabled.png
```

如果预算有限，先做通用：

```text
assets/reference/button_frame_common.png
```

### 2.6 卡牌与物品卡 `cards`

用途：商店商品卡、装备卡、背包格、布局卡、角色卡。

建议尺寸：

- 商品卡：`280x184`
- 装备卡：`360x120`
- 布局卡：`420x110`
- 角色卡：`220x320`

命名：

```text
<era>_shop_card.png
<era>_equipment_card.png
<era>_combo_card.png
<era>_character_card.png
<era>_card_locked.png
<era>_card_selected.png
```

### 2.7 弹窗与遮罩 `overlays`

用途：规则页、设置页、图鉴、局外升级、结算弹窗。

命名：

```text
<era>_modal_frame.png
<era>_tooltip_frame.png
<era>_rule_panel.png
<era>_settings_panel.png
<era>_codex_panel.png
<era>_upgrade_panel.png
```

## 3. 角色分类

目录：

```text
assets/characters/
├── doctor/
├── artisan/
├── merchant/
├── farmer/
└── wanderer/
```

当前代码兼容的扁平命名：

```text
doctor_portrait.png
doctor_select.png
doctor_battle.png
hacker_portrait.png
hacker_select.png
hacker_battle.png
merchant_portrait.png
merchant_select.png
merchant_battle.png
farmer_portrait.png
farmer_select.png
farmer_battle.png
wanderer_portrait.png
wanderer_select.png
wanderer_battle.png
```

建议重制时按每个角色细分：

```text
<role>_portrait.png       # 头像，256x256 或 512x512
<role>_select.png         # 选择角色页展示，512x512
<role>_battle.png         # 战斗立绘，512x768
<role>_icon.png           # 小头像，64x64
<role>_passive_icon.png   # 专属被动图标，64x64
```

角色名建议：

- `doctor`：御医
- `artisan`：工匠，当前代码里旧名是 `hacker`
- `merchant`：商人
- `farmer`：农民
- `wanderer`：游侠

## 4. 敌人与 Boss 分类

目录：

```text
assets/enemies/
├── basic/
├── elite/
├── advanced/
└── boss/
```

### 4.1 基础敌

用途：普通战斗节点。

```text
enemy_basic_tian.png
enemy_basic_ren.png
enemy_basic_di.png
enemy_basic_soldier.png
enemy_basic_trainee.png
enemy_basic_guard.png
```

### 4.2 精英敌

用途：精英战斗节点，机制更明确。

```text
enemy_elite_switch.png
enemy_elite_guardian.png
enemy_elite_counter.png
enemy_elite_dual.png
enemy_elite_tactician.png
```

### 4.3 高级敌

用途：中后期战斗节点。

```text
enemy_advanced_mind.png
enemy_advanced_assault.png
enemy_advanced_mimic.png
enemy_advanced_sage.png
enemy_advanced_master.png
```

### 4.4 Boss

用途：时代终点，一阶段/二阶段最好能有视觉差异。

```text
enemy_boss_qin.png
enemy_boss_qin_phase2.png
enemy_boss_song.png
enemy_boss_song_phase2.png
enemy_boss_china.png
enemy_boss_china_phase2.png
```

建议尺寸：`512x512` 或 `768x768`，透明底。

## 5. 装备、器物、秘器分类

目录：

```text
assets/items/
├── icons/
├── equipment/
├── relics/
└── era_sets/
    ├── qin/
    ├── song/
    └── china/
```

### 5.1 通用装备图标

用途：商店、装备栏、背包栏。

建议尺寸：`64x64` 或 `96x96`。

```text
item_sword.png
item_shield.png
item_crystal.png
item_mirror.png
item_potion.png
item_amulet.png
```

### 5.2 具体装备图标

如果之后要把所有装备都独立美术化，建议：

```text
equipment_long_sword.png
equipment_wooden_shield.png
equipment_life_crystal.png
equipment_heart_mirror.png
equipment_demon_blade.png
equipment_blood_tyrant.png
```

### 5.3 时代秘器

当前最少：

```text
qin_item_tiger_tally.png
song_item_trade_ledger.png
china_item_mountain_seal.png
```

扩展建议：

```text
<era>_relic_01.png
<era>_relic_02.png
<era>_relic_03.png
```

## 6. 图标分类

目录：

```text
assets/icons/
├── system/
├── combat/
├── status/
├── resource/
└── action/
```

### 6.1 系统图标 `system`

```text
icon_settings.png
icon_rules.png
icon_sound.png
icon_back.png
icon_close.png
icon_save.png
icon_home.png
```

### 6.2 战斗图标 `combat`

```text
icon_tian.png
icon_ren.png
icon_di.png
icon_attack.png
icon_shield.png
icon_cheat.png
```

建议补充：

```text
icon_combo.png
icon_crit.png
icon_break_armor.png
icon_victory.png
icon_defeat.png
icon_draw.png
```

### 6.3 状态图标 `status`

用途：灼烧、减速、护盾、增伤、虚弱、Boss 二阶段。

```text
status_burn.png
status_slow.png
status_armor.png
status_attack_up.png
status_weak.png
status_boss_phase.png
```

### 6.4 资源图标 `resource`

```text
resource_gold.png
resource_material.png
resource_memory.png
resource_hp.png
resource_attack.png
resource_armor.png
```

### 6.5 行为图标 `action`

用途：按钮图标。

```text
action_start.png
action_continue.png
action_next.png
action_buy.png
action_refresh.png
action_upgrade.png
action_equip.png
action_unequip.png
action_heal.png
action_craft.png
```

## 7. 战斗反馈特效分类

当前项目最需要强化的是反馈感。建议单独出 `effects`。

目录：

```text
assets/effects/
├── hit/
├── shield/
├── combo/
├── result/
└── particles/
```

建议资源：

```text
hit_slash_01.png
hit_spark_01.png
shield_break_01.png
combo_flash_01.png
victory_stamp.png
defeat_stamp.png
draw_stamp.png
boss_phase_flash.png
```

如果做序列帧：

```text
hit_spark_01_00.png
hit_spark_01_01.png
hit_spark_01_02.png
```

## 8. 通用 UI 组件 `reference`

这些是跨时代复用的基础件，能显著降低接图成本。

```text
assets/reference/
├── title_back_common.png
├── divider_line_common.png
├── corner_stud_common.png
├── chapter_box_common.png
├── bottom_bar_common.png
├── chip_common.png
├── card_common.png
├── button_frame_common.png
└── tooltip_frame_common.png
```

建议不要把 `reference` 当废稿目录，它应该是“通用组件库”。

## 9. 音频分类

虽然这份主要讲美术，但完整资源包建议保留音频目录。

```text
assets/audio/
├── bgm/
├── ambient/
├── sfx/
└── ui/
```

### 9.1 BGM

```text
menu.wav
battle.wav
shop.wav
rest.wav
event_neutral.wav
event_good_1.wav
event_good_2.wav
event_good_3.wav
event_bad.wav
```

### 9.2 环境音

```text
battle_urgency.wav
shop_forge.wav
rest_fire.wav
```

### 9.3 反馈音效

```text
sfx_attack_metal_hit.wav
sfx_armor_break.wav
sfx_enemy_death.wav
sfx_cheat_charge.wav
sfx_cheat_burst.wav
sfx_win.wav
sfx_lose.wav
```

## 10. 优先级

### 第一优先级：Demo 直接可见

```text
ui/<era>/backgrounds/
ui/<era>/frames/
ui/<era>/seals/
characters/
enemies/boss/
icons/combat/
icons/system/
items/icons/
reference/card_common.png
reference/button_frame_common.png
```

### 第二优先级：提升质感

```text
ui/<era>/buttons/
ui/<era>/cards/
ui/<era>/overlays/
effects/
items/equipment/
icons/status/
icons/resource/
```

### 第三优先级：扩内容体量

```text
enemies/basic/
enemies/elite/
enemies/advanced/
items/era_sets/
characters/<role>_passive_icon.png
boss_phase2.png
```

## 11. 交付规则

- 文件格式统一用 `PNG`。
- 默认透明底，背景图除外。
- 不要使用中文文件名。
- 不要在文件名里写 `final`、`new`、`v2`。
- 文案不要画死进按钮、卡牌、面板里，除非它是章印或标题图。
- 同一分类资源尺寸必须统一。
- 同一时代资源必须有统一色系。
- `qin`、`song`、`china` 三个时代必须同名同结构，方便代码按时代切换。

## 12. 推荐最终交付结构

```text
zhouxing_art_pack_v2/
├── assets/
│   ├── ui/
│   │   ├── qin/
│   │   ├── song/
│   │   └── china/
│   ├── characters/
│   ├── enemies/
│   ├── items/
│   ├── icons/
│   ├── effects/
│   ├── reference/
│   └── audio/
├── asset_manifest.md
└── preview_board.png
```

`asset_manifest.md` 应写清楚每张图的用途、尺寸、是否透明底、是否已接入代码。

