# 随机事件系统文档

## 概述

随机事件系统为游戏增加了丰富的随机性和策略深度。玩家在地图上遇到事件节点时，将触发好事或坏事事件，部分事件需要通过战斗来获得更好的结果。

## 事件分类

### 好事件（Good Events）

| 事件类型 | 描述 | 结算方式 | 备注 |
|---------|------|---------|------|
| 生命祝福 | 血量+2 | 直接生效 | 算1次胜利 |
| 力量祝福 | 攻击+1 | 直接生效 | 算1次胜利 |
| 守护祝福 | 护甲+2 | 直接生效 | 算1次胜利 |
| 精准祝福 | 暴击率+20% | 直接生效 | 算1次胜利 |
| 金币奖励 | +10金币 | 直接生效 | 算1次胜利 |
| 随机装备 | 根据战斗结果获得装备 | 2回合战斗 | 2胜=红，1胜=蓝，0胜=白 |
| 商店折扣 | 商店打折 | 2回合战斗 | 2胜=7折，1胜=8折，0胜=9折 |

### 坏事件（Bad Events）

| 事件类型 | 描述 | 结算方式 | 备注 |
|---------|------|---------|------|
| 生命削弱 | 血量-2 | 四选一 | 玩家选择属性 |
| 力量削弱 | 攻击-1 | 四选一 | 玩家选择属性 |
| 守护削弱 | 护甲-2 | 四选一 | 玩家选择属性 |
| 精准削弱 | 暴击率-20% | 四选一 | 玩家选择属性 |
| 技能封印 | 禁用1个连招 | 直接生效 | 随机禁用已装备的连招 |
| 装备损失 | 丢失装备 | 二选一 | 可直接丢失或战斗决定 |
| 金币损失 | 丢失5金币 | 直接生效 | 直接扣除 |

## 战斗规则

### 决定性战斗（好事/坏事）
- **一局定胜负**：胜=好事，败=坏事
- 平局需重新比试

### 奖励战斗（随机装备/商店折扣/装备损失）
- **2回合对战**
- **第1回合不计入结果**
- 根据第2、3回合的胜利次数决定最终奖励

#### 战斗结果计算

**随机装备/商店折扣（好事件）：**
| 胜利次数 | 奖励 |
|---------|------|
| 2胜 | 最高品质（红色装备/7折） |
| 1胜 | 中等品质（蓝色装备/8折） |
| 0胜 | 基础品质（白色装备/9折） |

**装备损失（坏事件）：**
| 胜利次数 | 损失 |
|---------|------|
| 2胜 | 最小损失（白色装备） |
| 1胜 | 中等损失（蓝色装备） |
| 0胜 | 最大损失（红色装备） |

## 系统架构

### 核心组件

1. **RandomEventManager** (`autoload/random_event_manager.gd`)
   - 管理事件生成、选择、结算
   - 处理战斗逻辑
   - 通过信号与UI和其他系统通信

2. **事件场景** (`scenes/ui/event_scene.tscn` + `event_scene.gd`)
   - 好事件/坏事件选择界面
   - 属性选择（四选一）
   - 装备损失选项

3. **事件战斗场景** (`scenes/ui/event_battle_scene.tscn` + `event_battle_scene.gd`)
   - 2回合战斗界面
   - 实时显示战斗进度和结果

### 信号通信

```gdscript
# 好事件信号
signal good_event_triggered(event_type: String, event_data: Dictionary)

# 坏事件信号
signal bad_event_triggered(event_type: String, event_data: Dictionary)

# 事件战斗信号
signal event_battle_started(is_good_event: bool, context: Dictionary)
signal event_battle_round_result(round_num: int, player_move: int, enemy_move: int, won: bool)
signal event_battle_ended(wins: int, is_good_event: bool, context: Dictionary)

# 事件结算信号
signal event_attribute_changed(attribute: String, value: int)
signal event_gold_changed(amount: int)
signal event_discount_changed(discount: float)
signal event_equipment_lost(item: Dictionary, via_battle: bool)
signal event_skill_disabled(combo_id: String)
signal event_battle_reward(reward_type: String, item_data: Dictionary)
```

## 使用方法

### 触发事件
事件在玩家选择地图上的事件节点（❓）时触发：
1. 先进行一局**决定性战斗**决定好事还是坏事
2. 根据结果显示对应的好事件或坏事件

### 好事件流程
```
决定性好事件战斗胜利
    ↓
显示随机好事列表
    ↓
┌────────────────────────────────────┐
│ 立即生效事件（选择后直接获得奖励）  │
│ 或                                  │
│ 战斗事件（进入2回合战斗获得更好奖励）│
└────────────────────────────────────┘
    ↓
返回地图继续游戏
```

### 坏事件流程
```
决定性战斗失败
    ↓
显示随机坏事
    ↓
┌────────────────────────────────────────┐
│ 四选一事件（选择要减少的属性）          │
│ 或                                      │
│ 装备损失（二选一：直接丢失/战斗决定）   │
│ 或                                      │
│ 直接生效事件                            │
└────────────────────────────────────────┘
    ↓
返回地图继续游戏
```

## 配置

### 稀有度配置

```gdscript
const RARITY_NAMES: Array[String] = ["白色", "蓝色", "红色"]
const RARITY_COLORS: Array[Color] = [
    Color(0.9, 0.9, 0.9),   # 白色
    Color(0.5, 0.7, 1.0),   # 蓝色
    Color(1.0, 0.5, 0.5)    # 红色
]
```

### 商店折扣配置

```gdscript
const DISCOUNT_2_WINS: float = 0.7   # 2胜 = 7折
const DISCOUNT_1_WIN: float = 0.8     # 1胜 = 8折
const DISCOUNT_0_WIN: float = 0.9     # 0胜 = 9折
```

## 文件列表

| 文件 | 描述 |
|-----|------|
| `autoload/random_event_manager.gd` | 事件管理器核心逻辑 |
| `autoload/event_bus.gd` | 全局事件总线（已更新信号） |
| `scenes/ui/event_scene.tscn` | 事件场景界面 |
| `scenes/ui/event_scene.gd` | 事件场景脚本 |
| `scenes/ui/event_battle_scene.tscn` | 事件战斗场景界面 |
| `scenes/ui/event_battle_scene.gd` | 事件战斗场景脚本 |
| `scenes/main.gd` | 主控制器（已集成事件系统） |

## 待优化项

1. **暴击率系统**：当前暴击标记是通过特殊变量 `_crit_bonus` 实现，建议与 GameState 集成
2. **技能封印**：当前是通过长时间冷却模拟，建议添加更优雅的禁用机制
3. **事件预览**：战斗前可以显示更详细的结果预览
4. **动画效果**：为事件结果添加适当的动画反馈
