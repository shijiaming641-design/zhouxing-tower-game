# 装备系统设计

> 版本：1.0  
> 日期：2026-03-14  
> 状态：已完成

---

## 1. 概述

装备系统为玩家提供属性加成和特殊效果，是提升战力的重要途径。

---

## 2. 装备类型

### 2.1 装备槽位

| 槽位 | 数量(初始) | 数量(最大) | 说明 |
|------|------------|------------|------|
| 武器 | 1 | 1 | 增加攻击力 |
| 护甲 | 1 | 1 | 增加防御 |
| 饰品 | 0 | 3 | 特殊效果 |

### 2.2 装备枚举

```csharp
public enum EquipmentType
{
    Weapon,     // 武器
    Armor,      // 护甲
    Accessory   // 饰品
}
```

---

## 3. 稀有度

### 3.1 稀有度等级

| 等级 | 名称 | 颜色 | 概率 | 属性数量 |
|------|------|------|------|----------|
| 1 | 普通 | 白色 | 60% | 1-2 |
| 2 | 精良 | 蓝色 | 25% | 2-3 |
| 3 | 稀有 | 紫色 | 10% | 3-4 |
| 4 | 传说 | 金色 | 5% | 4-5 |

### 3.2 稀有度加成

| 稀有度 | 基础属性加成 | 特殊效果概率 |
|--------|--------------|--------------|
| 普通 | 1.0x | 0% |
| 精良 | 1.5x | 10% |
| 稀有 | 2.5x | 30% |
| 传说 | 5.0x | 50% |

---

## 4. 属性系统

### 4.1 基础属性

| 属性 | 说明 | 装备类型 |
|------|------|----------|
| Attack | 攻击力 | 武器 |
| Defense | 防御力 | 护甲 |
| MaxHP | 最大生命 | 全部 |
| CritRate | 暴击率 | 饰品 |
| CritDamage | 暴击伤害 | 武器 |
| Block | 格挡值 | 护甲 |

### 4.2 特殊效果

| 效果 | 说明 | 触发条件 |
|------|------|----------|
| LifeSteal | 吸血 | 攻击时 |
| Reflect | 反射 | 受到攻击 |
| Poison | 中毒 | 攻击时 |
| Freeze | 冰冻 | 攻击时 |
| Dodge | 闪避 | 被攻击时 |

---

## 5. 装备数据

### 5.1 武器示例

```csharp
// 武器
public static Equipment IronSword = new Equipment
{
    ID = "weapon_001",
    Name = "铁剑",
    Type = EquipmentType.Weapon,
    Rarity = Rarity.Common,
    Attack = 3,
    Price = 50
};

public static Equipment DragonBlade = new Equipment
{
    ID = "weapon_010",
    Name = "龙刃",
    Type = EquipmentType.Weapon,
    Rarity = Rarity.Legendary,
    Attack = 15,
    CritRate = 10%,
    SpecialEffect = "火焰附加",
    Price = 1000
};
```

### 5.2 护甲示例

```csharp
public static Equipment LeatherArmor = new Equipment
{
    ID = "armor_001",
    Name = "皮甲",
    Type = EquipmentType.Armor,
    Rarity = Rarity.Common,
    Defense = 2,
    MaxHP = 10,
    Price = 50
};
```

### 5.3 饰品示例

```csharp
public static Equipment PowerRing = new Equipment
{
    ID = "accessory_001",
    Name = "力量戒指",
    Type = EquipmentType.Accessory,
    Rarity = Rarity.Rare,
    Attack = 5,
    CritRate = 5%,
    Price = 200
};
```

---

## 6. 装备获取

### 6.1 获取途径

| 途径 | 概率 | 说明 |
|------|------|------|
| 战斗掉落 | 10-30% | 击败敌人获得 |
| 商店购买 | 100% | 用金币购买 |
| 宝藏节点 | 100% | 地图宝藏 |
| 事件奖励 | 100% | 随机事件 |

### 6.2 生成算法

```csharp
public Equipment GenerateEquipment(int level, Rarity rarity)
{
    // 根据等级和稀有度生成装备
    // 基础属性 = 等级 × 稀有度系数
    // 可能附加特殊效果
}
```

---

## 7. 代码结构

### 7.1 核心类

```csharp
// 装备类
[System.Serializable]
public class Equipment
{
    public string ID;
    public string Name;
    public EquipmentType Type;
    public Rarity Rarity;
    
    // 基础属性
    public int Attack;
    public int Defense;
    public int MaxHP;
    public float CritRate;
    public float CritDamage;
    public int Block;
    
    // 特殊效果
    public SpecialEffect Effect;
    
    // 价格
    public int Price;
}

// 装备管理器
public class EquipmentSystem
{
    private Equipment[] equipped;  // 已装备
    private List<Equipment> inventory;  // 背包
    
    public bool Equip(Equipment eq);
    public bool Unequip(EquipmentType type);
    public List<Equipment> GetInventory();
    public int GetTotalAttack();
    public int GetTotalDefense();
}
```

### 7.2 文件位置

```
Entities/
└── Equipment.cs    # 装备类
Core/
└── EquipmentSystem.cs    # 装备系统
```

---

## 8. UI设计

### 8.1 装备栏界面

```
┌─────────────────────────────────────┐
│  🎒 背包              💰 500      │
├─────────────────────────────────────┤
│  装备栏:                              │
│  ┌─────┐ ┌─────┐ ┌─────┐           │
│  │ ⚔️  │ │ 🛡️  │ │ 💍 │           │
│  │ 剑  │ │ 皮甲│ │ -  │           │
│  └─────┘ └─────┘ └─────┘           │
├─────────────────────────────────────┤
│  背包:                               │
│  [┌─────┐][┌─────┐][┌─────┐]      │
│  │铁剑 │││布衣 │││戒指 │      │
│  │蓝+2 │││绿+1 │││紫+3 │      │
│  └─────┘└─────┘└─────┘            │
└─────────────────────────────────────┘
```

### 8.2 装备信息

```
┌─────────────────────┐
│  🗡️ 龙刃 (传说)    │
│  攻击: +15         │
│  暴击率: +10%      │
│  特效: 火焰附加    │
├─────────────────────┤
│  [装备] [出售 500] │
└─────────────────────┘
```

---

## 9. 后续扩展

- [ ] 装备强化系统
- [ ] 装备合成系统
- [ ] 套装效果
- [ ] 装备外观
