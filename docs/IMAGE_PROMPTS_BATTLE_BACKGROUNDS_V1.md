# 秦 / 宋 / 中国 战斗背景生成提示词 v1

用途：用于 GPT Image / gpt-image-2 生成三张战斗背景图。

统一规格：

```text
size: 1280x720
style: clear painterly background, not pixel art
usage: Godot battle scene background
layout: upper two-thirds combat stage, lower third reserved for UI
requirements: no characters, no text, no logo, no watermark
```

## 1. 秦卷战斗背景

```text
new Chinese historical fantasy roguelike game art, refined Chinese historical visual language, clear readable shapes, premium indie game asset, cohesive art direction, restrained ornament, high contrast focal point, no modern UI clutter, no photorealism, no anime excess, game-ready background.

side-view roguelike battle background, Chinese historical battlefield atmosphere, wide empty center for characters, upper two-thirds combat stage, lower third reserved for UI, cinematic depth, readable silhouettes, no clutter, high resolution, painterly background, not pixel art.

Qin battlefield, black and crimson color theme, dark earth, bronze shields, red military banners, distant Qin army silhouettes, smoke and dust, angular fortress shadows, tiger tally motif subtly carved on stone, austere military pressure, law and conquest atmosphere, solemn and powerful.

Composition requirements: 1280x720, empty center for player and enemy sprites, left and right sides can have environmental props but must not block character silhouettes, lower third must be clean and darker for UI readability, no characters in foreground, no text, no logo, no watermark.

Negative prompt: low quality, blurry, muddy, photorealistic, 3d render, western fantasy, japanese anime style, sci-fi neon, modern buildings, modern weapons, unreadable composition, too much foreground detail, text, watermark, logo, characters, portrait, UI buttons
```

文件建议命名：

```text
assets/backgrounds/qin/battle_qin_01.png
```

## 2. 宋卷战斗背景

```text
new Chinese historical fantasy roguelike game art, refined Chinese historical visual language, clear readable shapes, premium indie game asset, cohesive art direction, restrained ornament, high contrast focal point, no modern UI clutter, no photorealism, no anime excess, game-ready background.

side-view roguelike battle background, Chinese historical battlefield atmosphere, wide empty center for characters, upper two-thirds combat stage, lower third reserved for UI, cinematic depth, readable silhouettes, no clutter, high resolution, painterly background, not pixel art.

Song dynasty frontier camp and city-wall battlefield, celadon green, porcelain white, muted gold and warm lantern light, distant city wall silhouette, river trade route in the far background, wooden defenses, military tents, soft mist, restrained armor props, defensive atmosphere, elegant but tense, refined civil culture under military pressure.

Composition requirements: 1280x720, empty center for player and enemy sprites, background should feel calmer and more strategic than Qin, left and right sides can include camp props and lanterns but must not crowd the play area, lower third must be clean and darker for UI readability, no characters in foreground, no text, no logo, no watermark.

Negative prompt: low quality, blurry, muddy, photorealistic, 3d render, western fantasy, japanese anime style, sci-fi neon, modern buildings, modern weapons, unreadable composition, too much foreground detail, text, watermark, logo, characters, portrait, UI buttons
```

文件建议命名：

```text
assets/backgrounds/song/battle_song_01.png
```

## 3. 中国卷战斗背景

```text
new Chinese historical fantasy roguelike game art, refined Chinese historical visual language, clear readable shapes, premium indie game asset, cohesive art direction, restrained ornament, high contrast focal point, no modern UI clutter, no photorealism, no anime excess, game-ready background.

side-view roguelike battle background, Chinese historical battlefield atmosphere, wide empty center for characters, upper two-thirds combat stage, lower third reserved for UI, cinematic depth, readable silhouettes, no clutter, high resolution, painterly background, not pixel art.

final Chinese historical fantasy battlefield, mountain and river symbolism, crimson and gold accents, dark ink clouds, old map fragments drifting in the distance, archive paper texture, steel and fire details, solemn endgame pressure, layered historical echoes, vast mountain-river silhouette, heroic but heavy atmosphere, final chapter feeling.

Composition requirements: 1280x720, empty center for player and enemy sprites, stronger contrast than Qin and Song but still readable, distant symbolic scenery only, lower third must be clean and darker for UI readability, no characters in foreground, no text, no logo, no watermark.

Negative prompt: low quality, blurry, muddy, photorealistic, 3d render, western fantasy, japanese anime style, sci-fi neon, modern buildings, modern weapons, unreadable composition, too much foreground detail, text, watermark, logo, characters, portrait, UI buttons
```

文件建议命名：

```text
assets/backgrounds/china/battle_china_01.png
```

## 生成建议

建议每个时代先生成 4 张候选图，再选 1 张作为主背景。选择标准：

- 中心是否足够空，能放玩家和敌人立绘。
- 下三分之一是否干净，能放布局按钮、装备、机括 UI。
- 三个时代色系是否明显不同。
- 背景是否没有文字、角色、现代物件。
- 缩小到游戏内尺寸后是否仍清楚。

