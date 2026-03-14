# 周行：循环三角

> 猜拳策略 Roguelike 爬塔游戏

---

## 🎮 游戏简介

在同步心理战中预判 AI，于循环宿命里构建连招，为人类存续而爬塔。

玩家将通过经典的猜拳（✊○ / ✌️△ / ✋□）机制与 AI 进行策略对战，收集连招、击败敌人、攀登塔顶！

---

## 📁 项目结构

```
zhouxing-game/
├── Assets/
│   ├── Scenes/          # Unity 场景
│   │   ├── MainMENU.unity      # 主菜单
│   │   ├── BattleScene.unity   # 战斗场景
│   │   └── TutorialScene.unity  # 教程场景
│   ├── Scripts/         # 脚本 (预留)
│   └── Resources/       # 资源
├── Core/
│   ├── BattleSystem.cs       # 战斗系统
│   ├── MapSystem.cs          # 地图系统 ✅
│   ├── ShopSystem.cs         # 商店系统 ✅
│   ├── ProgressionSystem.cs  # 局外成长系统 ✅
│   ├── EquipmentSystem.cs    # 装备系统 ✅
│   ├── ItemSystem.cs        # 道具系统 ✅
│   ├── EnemyAI.cs           # AI行为模式 ✅
│   ├── UIManager.cs         # UI管理器 ✅
│   ├── UIPanels.cs          # 界面面板 ✅
│   ├── DamageCalculator.cs   # 伤害计算
│   ├── SaveManager.cs        # 存档管理
│   └── Constants.cs          # 常量定义
├── Entities/
│   ├── Player.cs        # 玩家
│   ├── Enemy.cs        # 敌人
│   ├── Card.cs         # 卡牌/连招
│   ├── EnemySkill.cs   # 敌人技能
│   └── Item.cs        # 道具
├── Data/
│   ├── CardDatabase.cs  # 卡牌数据库
│   └── GameData.cs    # 游戏数据
├── UI/
│   └── (UI资源)
├── Packages/
├── ProjectSettings/
└── docs/
    └── system-design/  # 系统设计文档
```

---

## ✨ 已实现功能

### 核心战斗
- ✅ 猜拳出招（✊○ / ✌️△ / ✋□）
- ✅ 猜拳克制判定
- ✅ 连招系统（3个序列触发特殊效果）
- ✅ 伤害计算、暴击机制

### 地图探索
- ✅ 4层关卡（战斗/商店/休息/事件/BOSS）
- ✅ 节点随机生成
- ✅ 难度递增

### 商店系统
- ✅ 装备/道具/神秘商店
- ✅ 稀有度系统（白/蓝/紫/金）
- ✅ 购买/刷新机制

### 成长系统
- ✅ 人员存储器货币
- ✅ 10+解锁项目
- ✅ 5种角色选择
- ✅ 周目奖励

### 装备系统
- ✅ 3种装备类型（武器/护甲/饰品）
- ✅ 4级稀有度
- ✅ 10+特殊效果

### 道具系统
- ✅ 4种类型（消耗品/钥匙/材料/特殊）
- ✅ 堆叠系统
- ✅ Buff效果

### AI行为模式
- ✅ 6种AI类型（随机/激进/防守/适应/战术/BOSS）
- ✅ 4级难度
- ✅ BOSS阶段机制

### UI系统
- ✅ 主菜单界面
- ✅ 战斗界面
- ✅ 商店界面
- ✅ 背包界面
- ✅ 地图界面
- ✅ 设置界面

---

## 🎯 核心机制

### 猜拳规则
```
✊○ 圆 > ✌️△ 三角 > ✋□ 方 > ✊○ 圆
```

### 连招示例
| 序列 | 名称 | 效果 |
|------|------|------|
| △→○→□ | 闪电突袭 | 3点真实伤害 |
| □→□→△ | 稳固防御 | 3点格挡+反弹 |
| ○→△→△ | 能量充能 | 攻击+2 |

### 角色选择
| 角色 | 特点 |
|------|------|
| 探索者 | 预知地图 |
| 长生者 | 复活1次 |
| 冒险家 | 经验加成 |
| 剑士 | 高暴击 |
| 坦克 | 高防御 |

---

## 🛠️ 开发环境

- **引擎**: Unity 2022+
- **语言**: C#
- **目标平台**: PC (Steam) / iOS / Android

---

## 📚 设计文档

详细系统设计见 [`docs/system-design/`](docs/system-design/) 目录

---

## 👥 开发团队

- **主策划**: 佳明
- **AI 助手**: 麻辣烫 🎮

---

## 📄 License

MIT License

---

*循环不息，周行不止*
