# AI行为模式设计

> 版本：1.0  
> 日期：2026-03-14  
> 状态：已完成

---

## 1. 概述

AI行为模式定义了敌人如何做出决策，增加战斗的多样性和策略深度。

---

## 2. 行为类型

### 2.1 行为枚举

```csharp
public enum AIBehavior
{
    Random,      // 随机出招
    Aggressive,  // 激进攻击型
    Defensive,   // 防守优先型
    Adaptive,    // 适应型（学习玩家）
    Tactical,    // 战术型（根据血量调整）
    Boss         // BOSS特殊AI
}
```

### 2.2 行为特点

| 类型 | 特点 | 适合敌人 |
|------|------|----------|
| Random | 完全随机 | 简单敌人 |
| Aggressive | 优先攻击 | 进攻型敌人 |
| Defensive | 优先防御 | 辅助型敌人 |
| Adaptive | 学习玩家习惯 | 精英敌人 |
| Tactical | 根据情况调整 | BOSS |
| Boss | 多阶段 | BOSS战 |

---

## 3. 行为逻辑

### 3.1 随机型

```csharp
// 完全随机
public MoveType GetRandomMove()
{
    return (MoveType)Random.Range(0, 3);
}
```

### 3.2 激进型

```
权重分配:
- 攻击出招: 60%
- 防守出招: 20%
- 随机: 20%
```

### 3.3 防守型

```
权重分配:
- 防守出招: 60%
- 攻击出招: 20%
- 随机: 20%
```

### 3.4 适应型

```csharp
// 记录玩家习惯
private List<MoveType> playerHistory;

public MoveType GetAdaptiveMove()
{
    // 分析玩家最近出招
    var mostUsed = AnalyzePlayerPattern();
    
    // 克制玩家常用出招
    return GetCounterMove(mostUsed);
}
```

### 3.5 战术型

```csharp
public MoveType GetTacticalMove()
{
    // 根据血量百分比决策
    float hpPercent = currentHP / maxHP;
    
    if (hpPercent > 0.7) return MoveType.Aggressive;  // 高血量激进
    else if (hpPercent > 0.3) return MoveType.Balanced; // 中血量均衡
    else return MoveType.Desperate; // 低血量拼命
}
```

---

## 4. 难度分级

### 4.1 难度枚举

```csharp
public enum AIDifficulty
{
    Easy,      // 简单
    Normal,    // 普通
    Hard,      // 困难
    Nightmare  // 噩梦
}
```

### 4.2 难度参数

| 难度 | 准确率 | 暴击率 | 特殊行为 |
|------|--------|--------|----------|
| Easy | 30% | 5% | 无 |
| Normal | 50% | 10% | 基础 |
| Hard | 70% | 15% | 进阶 |
| Nightmare | 90% | 20% | 完整 |

### 4.3 难度调整

```csharp
public void AdjustDifficulty(AIDifficulty difficulty)
{
    switch(difficulty)
    {
        case AIDifficulty.Easy:
            predictionAccuracy = 0.3f;
            critRate = 0.05f;
            break;
        case AIDifficulty.Normal:
            predictionAccuracy = 0.5f;
            critRate = 0.1f;
            break;
        case AIDifficulty.Hard:
            predictionAccuracy = 0.7f;
            critRate = 0.15f;
            break;
        case AIDifficulty.Nightmare:
            predictionAccuracy = 0.9f;
            critRate = 0.2f;
            break;
    }
}
```

---

## 5. BOSS特殊AI

### 5.1 BOSS阶段

```csharp
public enum BossPhase
{
    Phase1,    // 第一阶段
    Phase2,    // 第二阶段
    Phase3     // 第三阶段(狂暴)
}
```

### 5.2 阶段转换条件

| BOSS | Phase 1→2 | Phase 2→3 |
|------|------------|------------|
| 核心守卫 | HP<70% | HP<30% |
| 清除程序 | 战斗5回合后 | HP<50% |
| 数据吞噬者 | 玩家使用连招后 | HP<40% |

### 5.3 BOSS特殊机制

```csharp
// 示例：核心守卫
public class CoreGuardianAI : EnemyAI
{
    // 信物机制：没有密钥时无法造成有效伤害
    public override int CalculateDamage()
    {
        if (!player.HasKeyItem)
        {
            return 1;  // 最低伤害
        }
        return base.CalculateDamage() * 2;
    }
    
    // 每3回合释放一次技能
    public override void SpecialAbility()
    {
        if (turnCount % 3 == 0)
        {
            // 全屏攻击
            DealDamageToAll(10);
        }
    }
}
```

---

## 6. 代码结构

### 6.1 核心类

```csharp
// AI行为基类
public abstract class EnemyAI
{
    public AIBehavior behavior;
    public AIDifficulty difficulty;
    
    public abstract MoveType DecideMove();
    public virtual int CalculateDamage() { ... }
    public virtual void SpecialAbility() { ... }
}

// AI管理器
public class AISystem
{
    private EnemyAI currentAI;
    
    public void SetBehavior(AIBehavior behavior);
    public void SetDifficulty(AIDifficulty difficulty);
    public MoveType GetAIMove();
    public void UpdateAI();
}
```

### 6.2 文件位置

```
Entities/
└── EnemyAI.cs    # AI行为类
Core/
└── AISystem.cs   # AI系统
```

---

## 7. 敌人类型示例

### 7.1 普通敌人

| 敌人 | 行为 | 难度 |
|------|------|------|
| 巡逻机器人 | Random | Easy |
| 监控者 | Tactical | Normal |
| 清除程序 | Aggressive | Normal |

### 7.2 精英敌人

| 敌人 | 行为 | 难度 |
|------|------|------|
| 数据吞噬者 | Adaptive | Hard |
| 防火墙 | Defensive | Hard |

### 7.3 BOSS

| BOSS | 行为 | 机制 |
|------|------|------|
| 核心守卫 | Boss | 信物+阶段转换 |
| 清道夫 | Boss | 召唤小怪 |
| 主脑 | Boss | 全部机制 |

---

## 8. 后续扩展

- [ ] AI学习系统
- [ ] 隐藏行为模式
- [ ] 语音/动作反馈
- [ ] 战斗评价系统
