# 周行：循环三角 (ZhouXing: Cycle Triangle)

蒸汽朋克 Roguelike 猜拳策略游戏

## 项目结构

```
Assets/
├── Scripts/
│   ├── Core/           # 核心系统
│   │   ├── Enums.cs           # 枚举定义
│   │   ├── GameManager.cs     # 游戏管理器
│   │   ├── GameSetup.cs      # 游戏初始化
│   │   └── SceneController.cs # 场景管理
│   ├── Combat/         # 战斗系统
│   │   └── RpsCombatSystem.cs # 猜拳战斗系统
│   ├── Player/        # 玩家系统
│   │   └── PlayerController.cs # 玩家控制器
│   ├── Enemies/       # 敌人系统
│   │   ├── Enemy.cs           # 敌人基础类
│   │   ├── EnemyAI.cs         # 敌人AI
│   │   └── EnemySpawner.cs    # 敌人生成器
│   ├── UI/            # UI系统
│   │   ├── CombatUIManager.cs  # 战斗UI管理
│   │   └── MainMenuUI.cs      # 主菜单UI
│   ├── Effects/       # 特效系统
│   │   └── EffectManager.cs   # 效果管理器
│   ├── Data/          # 数据结构
│   │   └── CharacterData.cs   # 角色数据
│   └── Utils/         # 工具类
│       └── GameUtils.cs       # 游戏工具
├── Scenes/            # 场景文件
├── Prefabs/           # 预制体
├── Materials/         # 材质
├── Sprites/           # 精灵图
├── Audio/             # 音频
└── Editor/            # 编辑器脚本
```

## 核心机制

### 猜拳战斗
- 石头 → 剪刀 → 布 → 石头（循环克制）
- 胜利：造成1.5倍伤害
- 平局：各造成50%伤害
- 失败：造成0.5倍伤害

### 连胜系统
- 3连胜：+20%伤害，获得临时卡牌
- 5连胜：+50%伤害，治疗10%生命
- 7连胜：+100%伤害，额外行动一次

### 敌人AI
- 可见倾向系统：显示敌人出拳概率
- 行为模式：根据敌人类型调整策略
- 高级AI：30%几率预判玩家

## 开发团队

- 策划：周行工作室
- 开发：AI助手
- 设计：shijiaming641

## 版本

- 当前版本：0.1.0
- 目标平台：PC, iOS, Android, Web

## 许可证

MIT License
