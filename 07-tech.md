# 技术实现

## 1. 技术选型

| 部分 | 推荐方案 | 备选 |
|------|----------|------|
| 引擎 | Unity | Godot, Cocos2d-x |
| 平台 | PC优先 | 后续移植移动端 |
| 存档 | JSON本地 | 可选云存档 |

## 2. 核心系统架构

```
GameManager
├── BattleSystem (战斗逻辑)
├── TowerManager (塔层状态)
├── CardManager (卡牌系统)
├── UIManager (界面控制)
└── SaveManager (存档管理)
```

## 3. 核心类设计

### 枚举定义
```csharp
public enum RPSChoice { Rock, Scissors, Paper }
public enum BattleResult { Win, Lose, Draw }
public enum CardType { Attack, Defense, Skill }
public enum CardRarity { Common, Rare, Legendary }
```

### 玩家数据
```csharp
[System.Serializable]
public class PlayerData {
    public int hp;
    public int maxHp = 50;
    public int attack = 10;
    public int defense = 2;
    public int rage = 0;
    public int maxRage = 100;
    public int gold = 0;
    public int floor = 1;
    public int winStreak = 0;
    public List<Card> deck = new List<Card>();
    public List<Card> hand = new List<Card>();
}
```

### 敌人数据
```csharp
[System.Serializable]
public class EnemyData {
    public string id;
    public string name;
    public int hp;
    public int maxHp;
    public int attack;
    public int defense;
    public int rage = 0;
    public EnemyType type; // Normal, Elite, Boss
    public int[] choiceWeights = { 33, 33, 34 }; // 石头/剪刀/布倾向%
    public List<Skill> skills = new List<Skill>();
}
```

### 卡牌数据
```csharp
[System.Serializable]
public class Card {
    public string id;
    public string name;
    public string description;
    public CardType type;
    public CardRarity rarity;
    public int cost;
    public int damage;
    public int defense;
    public int rageGain;
    public bool isPermanent = true;
}

[System.Serializable]
public class Skill {
    public string id;
    public string name;
    public SkillType type; // Active, Passive, Reaction
    public int cost;
    public int damage;
    public string effect;
}
```

## 4. 战斗系统核心逻辑

### 伤害计算
```csharp
public int CalculateDamage(int attack, int defense, RPSChoice playerChoice, 
                           RPSChoice enemyChoice, int winStreak) {
    float multiplier = 1.0f;
    
    // 克制系数
    if ((playerChoice == RPSChoice.Rock && enemyChoice == RPSChoice.Scissors) ||
        (playerChoice == RPSChoice.Scissors && enemyChoice == RPSChoice.Paper) ||
        (playerChoice == RPSChoice.Paper && enemyChoice == RPSChoice.Rock)) {
        multiplier = 1.5f; // 胜利
    } else if (playerChoice == enemyChoice) {
        multiplier = 0.75f; // 平局
    } else {
        multiplier = 0.5f; // 失败
    }
    
    // 连胜加成
    float streakBonus = 1.0f;
    if (winStreak >= 3) streakBonus = 1.2f;
    if (winStreak >= 5) streakBonus = 1.5f;
    if (winStreak >= 7) streakBonus = 2.0f;
    
    // 随机波动
    float random = UnityEngine.Random.Range(0.9f, 1.1f);
    
    int baseDamage = (attack - defense);
    if (baseDamage < 1) baseDamage = 1;
    
    return Mathf.RoundToInt(baseDamage * multiplier * streakBonus * random);
}
```

### 敌人AI决策
```csharp
public RPSChoice GetEnemyChoice(EnemyData enemy) {
    // 60%固定倾向 + 30%浮动 + 10%随机
    int roll = UnityEngine.Random.Range(1, 101);
    
    if (roll <= 60) {
        // 固定倾向
        return GetWeightedChoice(enemy.choiceWeights);
    } else if (roll <= 90) {
        // 可被影响（简化版本：随机）
        return (RPSChoice)UnityEngine.Random.Range(0, 3);
    } else {
        // 完全随机
        return (RPSChoice)UnityEngine.Random.Range(0, 3);
    }
}
```

## 5. 存档结构

```json
{
  "version": "0.1.0",
  "run": {
    "floor": 5,
    "player": {
      "hp": 30,
      "maxHp": 50,
      "attack": 10,
      "defense": 2,
      "rage": 20,
      "gold": 50,
      "deck": [],
      "hand": [],
      "winStreak": 2
    },
    "relics": [],
    "history": []
  },
  "unlocks": {
    "characters": ["default"],
    "cards": []
  },
  "stats": {
    "wins": 10,
    "losses": 23,
    "totalDamageDealt": 500,
    "totalWinStreak": 7
  }
}
```

## 6. Unity工程结构

```
Assets/
├── Scripts/
│   ├── Core/
│   │   ├── GameManager.cs
│   │   ├── BattleSystem.cs
│   │   ├── TowerManager.cs
│   │   └── SaveManager.cs
│   ├── Entities/
│   │   ├── Player.cs
│   │   ├── Enemy.cs
│   │   └── Card.cs
│   ├── UI/
│   │   ├── UIManager.cs
│   │   ├── BattleUI.cs
│   │   └── CardDisplay.cs
│   └── Utils/
│       ├── DamageCalculator.cs
│       └── AIController.cs
├── Prefabs/
│   ├── Cards/
│   ├── Enemies/
│   └── UI/
├── Data/
│   ├── Cards/
│   │   └── CardData.asset
│   ├── Enemies/
│   │   └── EnemyData.asset
│   └── Dialogs/
└── Resources/
    └── Localization/
```

## 7. 本地化方案

支持语言:
- [x] 简体中文
- [x] 英文
- [x] 日文

### 本地化键名示例
```csharp
// 格式: 类别_编号
card_001_name = "石头"
card_001_desc = "造成100%攻击力的石头伤害"
enemy_steam_worker = "蒸汽劳工"
boss_grop = "齿轮执政官"
```

## 8. 性能目标

| 指标 | 目标 |
|------|------|
| 启动时间 | < 3秒 |
| 战斗加载 | < 1秒 |
| 内存占用 | < 200MB |
| 帧率 | 60 FPS |

## 9. 开发工具

### 卡牌编辑器
- Unity ScriptableObject + 自定义Editor
- 支持Excel导入
- 运行时热重载

### 平衡性测试
- AI模拟对战脚本
- 批量测试：1000次/分钟
- 输出胜率/伤害/回合数统计
