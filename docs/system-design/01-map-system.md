# 地图/关卡系统设计

> 版本：1.0  
> 日期：2026-03-14  
> 状态：已完成

---

## 1. 概述

地图系统是玩家在塔中探索的核心框架，负责生成关卡地图、管理节点和路线选择。

---

## 2. 节点类型

### 2.1 节点枚举

```csharp
public enum NodeType
{
    Combat,        // 普通战斗
    Elite,         // 精英战斗
    Boss,          // BOSS战
    Shop,          // 商店
    Rest,          // 休息点
    Event,         // 随机事件
    Treasure,      // 宝藏
    Secret         // 隐藏房间
}
```

### 2.2 节点属性

| 属性 | 类型 | 说明 |
|------|------|------|
| Type | NodeType | 节点类型 |
| Level | int | 所在层数 |
| IsVisited | bool | 是否已访问 |
| Connections | List<int> | 连接的节点ID |
| EnemyData | Enemy | 敌人数据（战斗用） |
| EventData | Event | 事件数据（事件用） |

---

## 3. 地图结构

### 3.1 塔层设计

```
第4层 ──── BOSS战
   │
 3层 ──── 精英关卡 + 事件
   │
 2层 ──── 普通战斗 + 商店
   │
 1层 ──── 教学关 + 起始
```

### 3.2 每层节点数

| 层数 | 节点数 | 战斗 | 商店 | 休息 | 事件 |
|------|--------|------|------|------|------|
| 1 | 4-5 | 2 | 1 | 1 | 1 |
| 2 | 5-6 | 3 | 1 | 1 | 1 |
| 3 | 6-7 | 3-4 | 1 | 1 | 1-2 |
| 4 | 3 | 1 | 0 | 0 | 2(BOSS) |

---

## 4. 地图生成算法

### 4.1 生成流程

```
1. 初始化空地图
2. 为每层生成节点
3. 随机分配节点类型（按权重）
4. 连接各层节点（确保连通）
5. 标记起点和终点
6. 返回地图数据
```

### 4.2 节点权重

| 节点类型 | 权重（普通层） | 权重（精英层） |
|----------|---------------|---------------|
| Combat | 40% | 30% |
| Elite | 10% | 20% |
| Shop | 15% | 10% |
| Rest | 15% | 15% |
| Event | 15% | 20% |
| Treasure | 5% | 5% |

### 4.3 连接规则

- 每层至少2个节点
- 节点至少有1个前置连接
- 每个节点最多3个后续连接
- 避免环形路径（除非随机事件）
- BOSS节点必须有明确前置

---

## 5. 路线选择

### 5.1 选择机制

玩家在每层结束时选择下一个节点：
- 显示可选路线（高亮）
- 显示节点类型图标
- 鼠标点击选择

### 5.2 路线显示

```
    [战斗] ──── [商店]
       │           │
    [休息] ──── [事件] ──── [BOSS]
```

---

## 6. 难度曲线

### 6.1 敌人强度

| 层数 | 敌人等级 | 血量倍率 | 攻击倍率 |
|------|----------|----------|----------|
| 1 | 1-3 | 1.0x | 1.0x |
| 2 | 3-5 | 1.2x | 1.1x |
| 3 | 5-8 | 1.5x | 1.3x |
| 4 | 8-10 | 2.0x | 1.5x |

### 6.2 奖励倍率

| 层数 | 金币 | 经验 | 掉落率 |
|------|------|------|--------|
| 1 | 1.0x | 1.0x | 10% |
| 2 | 1.2x | 1.2x | 15% |
| 3 | 1.5x | 1.5x | 20% |
| 4 | 2.0x | 2.0x | 30% |

---

## 7. 代码结构

### 7.1 核心类

```csharp
// 地图节点
public class MapNode
{
    public int ID;
    public NodeType Type;
    public int Layer;
    public List<int> NextNodes;
    public bool IsVisited;
    
    // 战斗相关
    public Enemy Enemy;
    
    // 事件相关  
    public GameEvent Event;
}

// 地图管理器
public class MapSystem
{
    private List<MapNode> nodes;
    private int currentLayer;
    private int currentNodeIndex;
    
    public void GenerateMap();
    public List<MapNode> GetAvailableNodes();
    public void SelectNode(int nodeId);
    public MapNode GetCurrentNode();
}
```

### 7.2 文件位置

```
Core/
└── MapSystem.cs    # 地图系统
```

---

## 8. 后续扩展

- [ ] 随机事件库
- [ ] 地图种子系统
- [ ] 特殊路线事件
- [ ] 地图探索成就
