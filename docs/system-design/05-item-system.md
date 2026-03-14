# 道具系统设计

> 版本：1.0  
> 日期：2026-03-14  
> 状态：已完成

---

## 1. 概述

道具系统管理背包中的消耗品和特殊物品，玩家可以在战斗中使用道具来获取优势。

---

## 2. 道具类型

### 2.1 道具枚举

```csharp
public enum ItemType
{
    Consumable,  // 消耗品
    Key,         // 钥匙/信物
    Material,    // 材料
    Special      // 特殊物品
}
```

### 2.2 分类说明

| 类型 | 说明 | 使用次数 |
|------|------|----------|
| 消耗品 | 一次性使用 | 1次 |
| 钥匙 | 开启特定门/事件 | 永久 |
| 材料 | 合成/升级用 | 永久 |
| 特殊 | 特殊效果 | 根据类型 |

---

## 3. 道具数据

### 3.1 消耗品

| 道具ID | 名称 | 效果 | 价格 |
|--------|------|------|------|
| item_hp_01 | 生命药水 | 恢复20HP | 30 |
| item_hp_02 | 生命药水(大) | 恢复50HP | 70 |
| item_energy_01 | 能量药水 | 恢复10能量 | 30 |
| item_buff_atk | 力量药水 | 攻击+3，持续3回合 | 50 |
| item_buff_def | 防御药水 | 防御+3，持续3回合 | 50 |
| item_cure | 解毒药 | 解除中毒状态 | 40 |
| item_revive | 复活药 | 战斗开始时自动复活1次 | 100 |

### 3.2 钥匙/信物

| 道具ID | 名称 | 用途 | 获得 |
|--------|------|------|------|
| key_boss_01 | 密钥碎片 | 开启BOSS门 | 战斗奖励 |
| key_secret_01 | 神秘钥匙 | 开启隐藏房间 | 事件奖励 |
| key_event_01 | 机关钥匙 | 解锁机关 | 探索获得 |

### 3.3 材料

| 道具ID | 名称 | 用途 | 价格 |
|--------|------|------|------|
| mat_gem_01 | 能量宝石 | 合成装备 | 100 |
| mat_ore_01 | 铁矿 | 合成装备 | 50 |
| mat_herb_01 | 药草 | 合成药水 | 20 |

---

## 4. 背包系统

### 4.1 背包容量

| 等级 | 初始格子 | 最大格子 |
|------|----------|----------|
| 1 | 6 | 20 |
| 2 | +4 | 24 |
| 3 | +4 | 28 |
| 4 | +4 | 32 |

### 4.2 堆叠规则

| 道具类型 | 堆叠上限 |
|----------|----------|
| 消耗品 | 99 |
| 钥匙 | 1 |
| 材料 | 99 |
| 特殊 | 1 |

---

## 5. 使用机制

### 5.1 战斗内使用

```csharp
// 战斗中使用道具
public bool UseItemInBattle(Item item)
{
    if (!item.IsUsableInBattle) return false;
    
    // 应用效果
    ApplyItemEffect(item);
    
    // 消耗数量
    item.Count--;
    
    return true;
}
```

### 5.2 战斗外使用

- 可以在任意时间使用
- 部分道具只能在战斗外使用

### 5.3 自动使用

| 道具 | 自动使用条件 |
|------|--------------|
| 复活药 | 战斗开始时 |
| 生命药水(低HP) | HP<30%时 |

---

## 6. 代码结构

### 6.1 核心类

```csharp
// 道具基类
[System.Serializable]
public class Item
{
    public string ID;
    public string Name;
    public ItemType Type;
    public int Count;
    public int MaxStack;
    public int Price;
    public bool IsUsableInBattle;
    public bool IsUsableOutsideBattle;
    
    // 效果
    public int HPHeal;
    public int EnergyHeal;
    public int AttackBuff;
    public int DefenseBuff;
    public SpecialEffect Effect;
}

// 背包管理器
public class ItemSystem
{
    private Item[] inventory;
    private int inventorySize;
    
    public bool AddItem(Item item);
    public bool RemoveItem(string itemId, int count = 1);
    public bool UseItem(string itemId);
    public List<Item> GetItems();
    public int GetEmptySlots();
}
```

### 6.2 文件位置

```
Entities/
└── Item.cs    # 道具类
Core/
└── ItemSystem.cs    # 道具系统
```

---

## 7. UI设计

### 7.1 背包界面

```
┌─────────────────────────────────────┐
│  🎒 背包 (6/20)        💰 500    │
├─────────────────────────────────────┤
│  ┌─────┐┌─────┐┌─────┐┌─────┐   │
│  │ 💊  ││ 💎  ││ 🔑 ││ 🗝️  │   │
│  │ 5   ││ 3   ││ 1   ││ 1   │   │
│  └─────┘└─────┘└─────┘└─────┘   │
│  ┌─────┐┌─────┐┌─────┐┌─────┐   │
│  │ 🪨  ││ 🧪  ││    ││    │   │
│  │ 10  ││ 2   ││    ││    │   │
│  └─────┘└─────┘└─────┘└─────┘   │
├─────────────────────────────────────┤
│  选择一个道具使用                    │
└─────────────────────────────────────┘
```

### 7.2 道具提示

```
┌─────────────────────┐
│  💊 生命药水       │
│  恢复20点生命值    │
│  数量: 5           │
├─────────────────────┤
│  [使用] [出售 30]  │
└─────────────────────┘
```

---

## 8. 后续扩展

- [ ] 道具合成
- [ ] 道具强化
- [ ] 随机附魔
- [ ] 限时道具
