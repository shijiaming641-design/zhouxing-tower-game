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

## 3. 存档结构

```json
{
  "version": "0.1.0",
  "run": {
    "floor": 5,
    "player": {"hp": 30, "gold": 50, "deck": []},
    "relics": [],
    "history": []
  },
  "unlocks": {"characters": ["default"], "cards": []},
  "stats": {"wins": 10, "losses": 23}
}
```

## 4. 本地化方案

支持语言:
- [x] 简体中文
- [ ] 英文
- [ ] 日文

## 5. 性能目标

- 启动时间 < 3秒
- 战斗加载 < 1秒
- 内存占用 < 200MB

## 6. 开发工具需求
- 卡牌数据编辑器 (Excel/ScriptableObject)
- 平衡性测试工具 (模拟对战)
