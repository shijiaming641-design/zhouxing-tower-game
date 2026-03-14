# 设置菜单系统设计

> 版本：1.0  
> 日期：2026-03-14  
> 状态：已完成

---

## 1. 概述

设置菜单允许玩家自定义游戏体验，包括音量、画质、按键等功能。

---

## 2. 设置分类

### 2.1 设置页面

| 页面 | 内容 |
|------|------|
| 音频 | 音量、音乐 |
| 画面 | 分辨率、画质 |
| 控制 | 按键设置 |
| 游戏 | 难度、语言 |
| 关于 | 版本信息 |

---

## 3. 音频设置

### 3.1 音量滑块

```csharp
public class AudioSettings
{
    [Range(0, 1)] 
    public float masterVolume = 1.0f;    // 主音量
    
    [Range(0, 1)] 
    public float bgmVolume = 0.8f;      // 背景音乐
    
    [Range(0, 1)] 
    public float sfxVolume = 1.0f;      // 音效
    
    [Range(0, 1)] 
    public float voiceVolume = 1.0f;     // 语音
    
    public bool enableSFX = true;
    public bool enableBGM = true;
}
```

### 3.2 预设方案

| 预设 | 主音量 | BGM | SFX | 说明 |
|------|--------|-----|-----|------|
| 静音 | 0 | 0 | 0 | 完全静音 |
| 夜间 | 0.5 | 0.3 | 0.5 | 适合晚上 |
| 标准 | 1.0 | 0.6 | 0.8 | 默认 |
| 沉浸 | 1.0 | 1.0 | 1.0 | 最大音量 |

---

## 4. 画面设置

### 4.1 分辨率选项

```csharp
public class GraphicsSettings
{
    public Resolution[] supportedResolutions = new Resolution[]
    {
        new Resolution { width = 1280, height = 720 },
        new Resolution { width = 1920, height = 1080 },
        new Resolution { width = 2560, height = 1440 },
    };
    
    public Resolution currentResolution;
    public bool fullscreen = true;
    public int qualityLevel = 2;  // 0=低,1=中,2=高
    public bool vsync = true;
    public int targetFPS = 60;
}
```

### 4.2 画质预设

| 预设 | 分辨率 | 特效 | 帧率 |
|------|--------|------|------|
| 省电 | 720p | 关闭 | 30 |
| 均衡 | 1080p | 中 | 60 |
| 画质 | 1440p | 高 | 60 |
| 极致 | 4K | 最高 | 144 |

---

## 5. 按键设置

### 5.1 默认按键

```csharp
public class ControlSettings
{
    // 战斗按键
    public KeyCode moveCircle = KeyCode.A;      // 出圆
    public KeyCode moveTriangle = KeyCode.S;    // 出三角
    public KeyCode moveSquare = KeyCode.D;      // 出方
    
    // 功能按键
    public KeyCode confirm = KeyCode.Space;     // 确认
    public KeyCode cancel = KeyCode.Escape;     // 取消
    public KeyCode menu = KeyCode.Escape;       // 菜单
    public KeyCode inventory = KeyCode.I;        // 背包
    
    // 快捷键
    public KeyCode skill1 = KeyCode.Alpha1;     // 技能1
    public KeyCode skill2 = KeyCode.Alpha2;     // 技能2
    public KeyCode skill3 = KeyCode.Alpha3;     // 技能3
    public KeyCode skill4 = KeyCode.Alpha4;     // 技能4
}
```

### 5.2 按键自定义

```csharp
public void SetKey(string action, KeyCode newKey)
{
    // 检查冲突
    if (IsKeyOccupied(newKey))
    {
        ShowConflictDialog(action);
        return;
    }
    
    // 设置新按键
    controlSettings.SetProperty(action, newKey);
}
```

---

## 6. 游戏设置

### 6.1 难度设置

```csharp
public class GameSettings
{
    public AIDifficulty difficulty = AIDifficulty.Normal;
    public bool tutorialEnabled = true;
    public string language = "zh-CN";
    public bool autoSave = true;
    public bool screenShake = true;
    public bool damageNumbers = true;
    public bool slowMotion = true;
}
```

### 6.2 语言支持

| 语言 | 代码 | 状态 |
|------|------|------|
| 简体中文 | zh-CN | ✅ |
| 繁体中文 | zh-TW | ✅ |
| English | en-US | ✅ |
| 日本語 | ja-JP | 🚧 |

---

## 7. 代码结构

### 7.1 核心类

```csharp
// 设置管理器
public class SettingsManager : MonoBehaviour
{
    public AudioSettings audio;
    public GraphicsSettings graphics;
    public ControlSettings controls;
    public GameSettings game;
    
    public void LoadSettings();
    public void SaveSettings();
    public void ResetToDefault();
    public void ApplySettings();
}
```

### 7.2 文件位置

```
Core/
└── SettingsManager.cs    # 设置管理器
Data/
└── SettingsData.cs     # 设置数据
```

---

## 8. UI设计

### 8.1 设置主界面

```
┌─────────────────────────────────────┐
│  ⚙️ 设置                    [X]   │
├─────────────────────────────────────┤
│  [🔊 音频]  [🖼️ 画面]            │
│  [⌨️ 控制]  [🎮 游戏]            │
│  [ℹ️ 关于]                        │
├─────────────────────────────────────┤
│                                     │
│                                     │
│                                     │
├─────────────────────────────────────┤
│  [恢复默认]      [保存] [取消]     │
└─────────────────────────────────────┘
```

### 8.2 音频设置界面

```
┌─────────────────────────────────────┐
│  ← 返回              🔊 音频设置   │
├─────────────────────────────────────┤
│                                     │
│  主音量   ████████████░░  80%     │
│                                     │
│  音乐    ██████████░░░░░  60%     │
│                                     │
│  音效    ████████████░░░  80%     │
│                                     │
│  语音    ████████████░░░░  80%     │
│                                     │
│  [预设: 标准 ▼]                     │
│                                     │
├─────────────────────────────────────┤
│  [恢复默认]      [保存] [取消]     │
└─────────────────────────────────────┘
```

---

## 9. 数据持久化

### 9.1 保存位置

```csharp
// 保存路径
string savePath = Application.persistentDataPath + "/settings.json";
```

### 9.2 保存格式

```json
{
  "audio": {
    "masterVolume": 0.8,
    "bgmVolume": 0.6,
    "sfxVolume": 0.8
  },
  "graphics": {
    "resolution": "1920x1080",
    "quality": 2,
    "fullscreen": true
  },
  "controls": {
    "moveCircle": "A",
    "moveTriangle": "S"
  }
}
```

---

## 10. 后续扩展

- [ ] 云同步设置
- [ ] 手柄支持
- [ ] 触屏自定义
- [ ] 高级图形选项
