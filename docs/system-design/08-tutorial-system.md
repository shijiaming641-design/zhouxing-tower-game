# 教程系统设计

> 版本：1.0  
> 日期：2026-03-14  
> 状态：已完成

---

## 1. 概述

教程系统帮助新玩家理解游戏机制，通过渐进式引导让玩家快速上手。

---

## 2. 教程类型

### 2.1 教程分类

| 类型 | 触发方式 | 内容 |
|------|----------|------|
| 强制教程 | 首次游戏 | 必须完成 |
| 提示教程 | 首次遇到 | 可跳过 |
| 进阶教程 | 条件触发 | 可跳过 |
| 百科 | 随时查阅 | 可跳过 |

### 2.2 教程阶段

```
第1章 → 第2章 → 第3章 → 第4章 → 通关
```

---

## 3. 教程内容

### 3.1 第一章：猜拳基础

```
目标：学会猜拳战斗

1. 介绍三元素
   - ○ 圆：克制△
   - △ 三角：克制□
   - □ 方：克制○

2. 实战练习
   - 击败1个敌人

3. 奖励
   - 解锁连招系统
```

### 3.2 第二章：连招入门

```
目标：理解连招机制

1. 什么是连招
   - 按顺序出招触发效果
   
2. 练习连招
   - △→○→□ = 闪电突袭

3. 奖励
   - 获得基础连招
```

### 3.3 第三章：商店与道具

```
目标：学会使用商店

1. 介绍商店
   - 购买装备
   
2. 购买道具
   - 购买生命药水

3. 使用道具
   - 在战斗中使用
```

### 3.4 第四章：BOSS挑战

```
目标：理解BOSS机制

1. BOSS特点
   - 更强敌人
   - 信物机制

2. 战斗策略
   - 躲避技能
   - 抓住时机进攻

3. 通关
   - 击败BOSS
```

---

## 4. 触发机制

### 4.1 自动触发

```csharp
// 首次遇到新机制时触发
public void CheckTutorialTrigger(TutorialTrigger trigger)
{
    if (!IsTutorialCompleted(trigger))
    {
        ShowTutorial(trigger);
    }
}
```

### 4.2 触发条件

| 教程ID | 触发条件 | 场景 |
|--------|----------|------|
| tuto_rock | 首次战斗 | 战斗场景 |
| tuto_combo | 首次输入连招 | 战斗场景 |
| tuto_shop | 首次到达商店 | 商店场景 |
| tuto_rest | 首次到达休息点 | 休息场景 |
| tuto_boss | 首次遇到BOSS | BOSS场景 |

---

## 5. 教程UI

### 5.1 弹窗样式

```
┌─────────────────────────────────┐
│  📖 教程提示                     │
├─────────────────────────────────┤
│                                 │
│   猜拳规则：                     │
│   ○ 克制 △                       │
│   △ 克制 □                       │
│   □ 克制 ○                       │
│                                 │
│        [下一步 →]                │
└─────────────────────────────────┘
```

### 5.2 引导高亮

```csharp
// 高亮指定UI元素
public void HighlightUI(string elementName)
{
    // 添加发光效果
    // 箭头指向
}
```

---

## 6. 代码结构

### 6.1 核心类

```csharp
// 教程数据
[System.Serializable]
public class TutorialData
{
    public string ID;
    public string Title;
    public List<string> Steps;
    public TutorialTrigger Trigger;
    public bool IsRequired;
}

// 教程管理器
public class TutorialSystem
{
    private List<TutorialData> tutorials;
    private HashSet<string> completedTutorials;
    
    public void CheckTrigger(TutorialTrigger trigger);
    public void ShowTutorial(string tutorialId);
    public void CompleteTutorial(string tutorialId);
    public bool IsTutorialCompleted(string tutorialId);
}
```

### 6.2 文件位置

```
Data/
└── TutorialData.cs    # 教程数据
Core/
└── TutorialSystem.cs   # 教程系统
```

---

## 7. 跳过机制

### 7.1 跳过条件

```csharp
public bool CanSkipTutorial()
{
    // 已完成过一次
    // 或玩家选择跳过
    return HasCompletedBefore || PlayerChooseToSkip;
}
```

### 7.2 跳过奖励

```
跳过教程 → 获得50金币补偿
```

---

## 8. 百科系统

### 8.1 百科内容

| 分类 | 内容 |
|------|------|
| 战斗 | 伤害计算、暴击机制 |
| 角色 | 职业特点 |
| 装备 | 稀有度、属性 |
| 敌人 | 敌人图鉴 |
| 成就 | 成就列表 |

### 8.2 入口

- 主菜单 → 百科
- 游戏内 → 暂停 → 百科

---

## 9. 后续扩展

- [ ] 动态教程(根据玩家行为)
- [ ] 视频教程
- [ ] 外部链接
- [ ] 成就奖励展示
