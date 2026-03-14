# 音效/音乐系统设计

> 版本：1.0  
> 日期：2026-03-14  
> 状态：已完成

---

## 1. 概述

音效和音乐系统为游戏提供沉浸式的音频体验，增强玩家代入感。

---

## 2. 音频类型

### 2.1 音频分类

| 类型 | 说明 | 格式 |
|------|------|------|
| BGM | 背景音乐 | MP3/OGG |
| SFX | 音效 | WAV/MP3 |
| VO | 语音 | MP3 |
| AMB | 环境音 | OGG |

### 2.2 音频管理器

```csharp
public enum SoundType
{
    BGM,
    SFX,
    VO,
    AMB
}
```

---

## 3. BGM设计

### 3.1 背景音乐列表

| 场景 | 音乐名称 | 风格 | 时长 |
|------|----------|------|------|
| 标题 | TitleTheme | 电子史诗 | 2:00 |
| 战斗 | BattleTheme1 | 紧张激烈 | 1:30 |
| 战斗2 | BattleTheme2 | 中速 | 1:30 |
| BOSS | BossTheme | 史诗战斗 | 2:30 |
| 商店 | ShopTheme | 轻松 | 1:00 |
| 休息 | RestTheme | 舒缓 | 1:00 |
| 事件 | EventTheme | 神秘 | 1:30 |
| 胜利 | VictoryTheme | 欢快 | 0:30 |
| 失败 | DefeatTheme | 悲伤 | 0:30 |

### 3.2 战斗音乐规则

```
战斗开始 → 播放战斗音乐
BOSS出现 → 切换到BOSS音乐
胜利 → 播放胜利音乐
失败 → 播放失败音乐
```

---

## 4. 音效设计

### 4.1 出招音效

| 动作 | 音效描述 |
|------|----------|
| 出圆(✊) | 低沉打击音 |
| 出三角(✌️) | 尖锐切割音 |
| 出方(✋) | 金属碰撞音 |

### 4.2 战斗音效

| 动作 | 音效描述 |
|------|----------|
| 攻击命中 | 击中音效 |
| 暴击 | 暴击音效(更强) |
| 格挡 | 格挡音效 |
| 受伤 | 受伤音效 |
| 死亡 | 死亡音效 |

### 4.3 UI音效

| 动作 | 音效描述 |
|------|----------|
| 按钮点击 | 短促点击音 |
| 选择 | 确认音 |
| 取消 | 取消音 |
| 获得物品 | 获得音 |

---

## 5. 音量控制

### 5.1 音量设置

```csharp
[System.Serializable]
public class AudioSettings
{
    public float masterVolume = 1.0f;    // 主音量
    public float bgmVolume = 0.8f;      // 背景音乐
    public float sfxVolume = 1.0f;      // 音效
    public float voVolume = 1.0f;       // 语音
    public bool isMuted = false;        // 静音
}
```

### 5.2 预设方案

| 方案 | BGM | SFX | 适用场景 |
|------|-----|-----|----------|
| 安静 | 0.3 | 0.5 | 夜间 |
| 标准 | 0.6 | 0.8 | 默认 |
| 沉浸 | 1.0 | 1.0 | 白天 |

---

## 6. 代码结构

### 6.1 核心类

```csharp
// 音频管理器
public class AudioManager : MonoBehaviour
{
    [Header("音量设置")]
    public float masterVolume = 1.0f;
    public float bgmVolume = 0.8f;
    public float sfxVolume = 1.0f;
    
    [Header("音频剪辑")]
    public AudioClip titleBGM;
    public AudioClip battleBGM;
    public AudioClip bossBGM;
    public AudioClip[] attackSFX;
    public AudioClip[] uiSFX;
    
    private AudioSource bgmSource;
    private AudioSource sfxSource;
    
    public void PlayBGM(AudioClip clip);
    public void PlaySFX(string soundName);
    public void SetVolume(SoundType type, float volume);
}
```

### 6.2 文件位置

```
Assets/
├── Audio/
│   ├── BGM/
│   │   ├── TitleTheme.mp3
│   │   ├── BattleTheme1.mp3
│   │   └── BossTheme.mp3
│   ├── SFX/
│   │   ├── Attack.mp3
│   │   ├── Block.mp3
│   │   └── UI_Click.mp3
│   └── VO/
└── Scripts/
    └── AudioManager.cs
```

---

## 7. 实现建议

### 7.1 音频源设置

```
BGM源: Loop=true, 淡入淡出
SFX源: Loop=false, 即时播放
VO源:  Loop=false, 可中断
AMB源:  Loop=true, 低音量
```

### 7.2 过渡效果

```csharp
// BGM淡入淡出
public void FadeToNewBGM(AudioClip newClip, float fadeTime = 2.0f)
{
    StartCoroutine(FadeCoroutine(newClip, fadeTime));
}
```

---

## 8. 后续扩展

- [ ] 动态音乐系统
- [ ] 3D音效(环绕)
- [ ] 语音本地化
- [ ] 音乐随机组合
