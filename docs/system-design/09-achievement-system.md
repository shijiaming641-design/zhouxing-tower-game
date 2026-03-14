# 成就系统设计

> 版本：1.0  
> 日期：2026-03-14  
> 状态：已完成

---

## 1. 概述

成就系统为玩家提供额外目标，增加游戏的可玩性和成就感。

---

## 2. 成就分类

### 2.1 分类枚举

```csharp
public enum AchievementCategory
{
    Battle,     // 战斗成就
    Explore,    // 探索成就
    Collection, // 收集成就
    Special,    // 特殊成就
    Hidden      // 隐藏成就
}
```

### 2.2 难度等级

| 等级 | 名称 | 完成率(预估) |
|------|------|--------------|
| ★ | 铜成就 | 80% |
| ★★ | 银成就 | 50% |
| ★★★ | 金成就 | 20% |
| ★★★★ | 钻石成就 | 5% |

---

## 3. 成就列表

### 3.1 战斗成就

| 成就ID | 名称 | 条件 | 奖励 |
|--------|------|------|------|
| battle_001 | 初战告捷 | 击败第一个敌人 | 10💎 |
| battle_002 | 连胜3场 | 连续击败3个敌人 | 20💎 |
| battle_005 | 无伤通关 | 不受伤害通过一层 | 50💎 |
| battle_010 | 越级挑战 | 击败高于自己5级的敌人 | 30💎 |
| battle_020 | 零封BOSS | BOSS战0伤害胜利 | 100💎 |

### 3.2 探索成就

| 成就ID | 名称 | 条件 | 奖励 |
|--------|------|------|------|
| explore_001 | 首次探索 | 进入第二层 | 10💎 |
| explore_005 | 商店顾客 | 在商店消费100金币 | 20💎 |
| explore_010 | 地图大师 | 探索所有节点类型 | 30💎 |
| explore_020 | 周目达成 | 完成第1周目 | 50💎 |

### 3.3 收集成就

| 成就ID | 名称 | 条件 | 奖励 |
|--------|------|------|------|
| collect_001 | 收藏家 | 拥有10件装备 | 20💎 |
| collect_005 | 连招大师 | 解锁所有基础连招 | 30💎 |
| collect_010 | 装备达人 | 拥有5件紫色装备 | 50💎 |
| collect_020 | 全收集 | 解锁所有内容 | 200💎 |

### 3.4 特殊成就

| 成就ID | 名称 | 条件 | 奖励 |
|--------|------|------|------|
| special_001 | 首次升级 | 首次升级 | 10💎 |
| special_005 | 欧皇 | 抽卡获得传说 | 30💎 |
| special_010 | 速通 | 30分钟内通关 | 100💎 |
| special_020 | 无敌 | 100连胜 | 500💎 |

### 3.5 隐藏成就

| 成就ID | 名称 | 条件 | 奖励 |
|--------|------|------|------|
| hidden_001 | 秘密发现 | 发现隐藏房间 | 50💎 |
| hidden_005 | 背刺 | 从背后攻击敌人 | 20💎 |
| hidden_010 | 命运 | 打出33%概率技能成功 | 100💎 |

---

## 4. 代码结构

### 4.1 核心类

```csharp
// 成就数据
[System.Serializable]
public class Achievement
{
    public string ID;
    public string Name;
    public string Description;
    public AchievementCategory Category;
    public int Difficulty;  // 1-5星
    public int Reward;     // 人员存储器奖励
    public AchievementCondition Condition;
    
    public bool IsCompleted;
    public DateTime? CompletedTime;
}

// 成就管理器
public class AchievementSystem
{
    private List<Achievement> achievements;
    private Dictionary<string, Achievement> achievementMap;
    
    public void CheckAchievement(string achievementId);
    public void UnlockAchievement(string achievementId);
    public List<Achievement> GetCompletedAchievements();
    public int GetTotalReward();
}
```

### 4.2 条件检查

```csharp
// 成就条件基类
public abstract class AchievementCondition
{
    public abstract bool Check();
}

// 示例：击败敌人条件
public class DefeatEnemyCondition : AchievementCondition
{
    public int EnemyCount;
    public int RequiredCount;
    
    public override bool Check()
    {
        return EnemyCount >= RequiredCount;
    }
}
```

### 4.3 文件位置

```
Data/
└── AchievementData.cs    # 成就数据
Core/
└── AchievementSystem.cs  # 成就系统
```

---

## 5. UI设计

### 5.1 成就界面

```
┌─────────────────────────────────────┐
│  🏆 成就                    5/30  │
├─────────────────────────────────────┤
│  全部  战斗  探索  收集  隐藏     │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ ★★★ 无伤通关              │   │
│  │ 不受伤害通过一层            │   │
│  │ [未完成]         50💎      │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ ★★ 连胜3场                │   │
│  │ 连续击败3个敌人             │   │
│  │ [完成] ✓         20💎      │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### 5.2 成就解锁弹窗

```
┌─────────────────────────────────┐
│  🎉 成就解锁!                    │
├─────────────────────────────────┤
│                                 │
│      ★★★ 无伤通关 ★★★         │
│                                 │
│    不受伤害通过一层              │
│                                 │
│        +50 💎 人员存储器         │
│                                 │
│         [确认]                   │
└─────────────────────────────────┘
```

---

## 6. 奖励机制

### 6.1 奖励发放

```csharp
public void GiveReward(Achievement achievement)
{
    // 添加人员存储器
    PlayerData.MemoryFragments += achievement.Reward;
    
    // 显示通知
    ShowUnlockNotification(achievement);
}
```

### 6.2 奖励统计

| 成就类型 | 预计总奖励 |
|----------|------------|
| 战斗 | 200💎 |
| 探索 | 150💎 |
| 收集 | 300💎 |
| 特殊 | 600💎 |
| 隐藏 | 200💎 |
| **总计** | **1450💎** |

---

## 7. 后续扩展

- [ ] 成就徽章展示
- [ ] 成就排行榜
- [ ] 动态成就(每周)
- [ ] 成就分享功能
