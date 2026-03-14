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
│   ├── MapSystem.cs          # 地图系统 ⭐ 新增
│   ├── ShopSystem.cs         # 商店系统 ⭐ 新增
│   ├── ProgressionSystem.cs  # 局外成长系统 ⭐ 新增
│   ├── DamageCalculator.cs    # 伤害计算
│   ├── SaveManager.cs         # 存档管理
│   └── Constants.cs           # 常量定义
├── Entities/
│   ├── Player.cs        # 玩家
│   ├── Enemy.cs         # 敌人
│   ├── Card.cs          # 卡牌
│   ├── EnemySkill.cs    # 敌人技能
│   └── Item.cs          # 道具
├── Data/
│   ├── CardDatabase.cs  # 卡牌数据库
│   └── GameData.cs      # 游戏数据
├── UI/
│   └── (UI资源)
├── Packages/
├── ProjectSettings/
└── docs/
    └── system-design/   # 系统设计文档
```

---

## ✨ 已实现功能

### 核心战斗
- ✅ 猜拳出招（✊○ / ✌️△ / ✋□）
- ✅ 猜拳克制判定
- ✅ 连招系统（3个序列触发特殊效果）
- ✅ 伤害计算
- ✅ 暴击机制

### 地图探索
- ✅ 地图节点生成
- ✅ 节点类型（战斗/商店/休息/事件/BOSS）
- ✅ 层级连接
- ✅ 难度递增

### 商店系统
- ✅ 装备商店
- ✅ 道具商店
- ✅ 商品随机生成
- ✅ 稀有度系统
- ✅ 购买/刷新机制

### 成长系统
- ✅ 人员存储器货币
- ✅ 解锁项目树
- ✅ 5种角色选择
- ✅ 角色属性差异
- ✅ 周目系统

---

## 📋 待实现功能

| 功能 | 优先级 | 状态 |
|------|--------|------|
| 装备系统 | 🟡 中 | 待完善 |
| 道具系统 | 🟡 中 | 待完善 |
| AI行为模式 | 🟡 中 | 待完善 |
| 音效系统 | 🟢 低 | 待实现 |
| 教程系统 | 🟡 中 | 待完善 |
| 成就系统 | 🟢 低 | 待实现 |
| 设置菜单 | 🟢 低 | 待实现 |

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

详细系统设计见 [`docs/system-design/`](docs/system-design/) 目录：

- 01-map-system.md - 地图系统
- 02-shop-system.md - 商店系统
- 03-progression-system.md - 局外成长系统
- 04-equipment-system.md - 装备系统
- 05-item-system.md - 道具系统
- 06-enemy-ai.md - AI行为模式
- 07-audio-system.md - 音效系统
- 08-tutorial-system.md - 教程系统
- 09-achievement-system.md - 成就系统
- 10-settings-system.md - 设置菜单

---

## 👥 开发团队

- **主策划**: 佳明
- **AI 助手**: 麻辣烫 🎮

---

## 📄 License

MIT License

---

*循环不息，周行不止*
