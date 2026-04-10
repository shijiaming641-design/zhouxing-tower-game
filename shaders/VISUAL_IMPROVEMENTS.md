# 周行：循环三角 - 视觉效果改进指南

## 当前状态

- ✅ 渲染方式：GL Compatibility + canvas_items stretch
- ✅ 2D UI框架：ColorRect + Label + Button
- ❌ 无自定义着色器
- ❌ 无粒子/动效系统
- ❌ 无后处理效果

## 建议改进

### 1. 发光效果 (Glow Shader) - `glow.shader`

**用途：** 为战斗中的 RPS 符号添加发光效果

**应用方法：**
```gdshader
# 在 Button 节点上设置材质
var mat = ShaderMaterial.new()
mat.shader = load("res://shaders/glow.shader")
mat.set_shader_parameter("glow_color", Color("#FFD700"))
mat.set_shader_parameter("glow_intensity", 1.5)
mat.set_shader_parameter("pulse_speed", 2.0)
$CircleBtn.material = mat
```

**参数说明：**
- `glow_color`: 发光颜色
- `glow_intensity`: 发光强度 (0-3)
- `pulse_speed`: 脉冲速度
- `pulse_amount`: 脉冲幅度 (0-1)

---

### 2. 按钮光晕 (Button Glow Shader) - `button_glow.gdshader`

**用途：** 战斗按钮周围的动态光晕效果

**应用方法：**
```gdshader
# 为 Q/W/E 按钮添加光晕材质
var mat = ShaderMaterial.new()
mat.shader = load("res://shaders/button_glow.gdshader")
mat.set_shader_parameter("glow_color", Color(1.0, 0.95, 0.8, 0.8))
mat.set_shader_parameter("glow_radius", 0.3)
mat.set_shader_parameter("anim_speed", 2.0)
button.material = mat
```

---

### 3. 暗角后处理 (Vignette Shader) - `vignette.gdshader`

**用途：** 增加游戏氛围感

**应用方法：**
```gdshader
# 全局后处理层
var overlay = ColorRect.new()
overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
overlay.mouse_filter = MOUSE_FILTER_IGNORE

var mat = ShaderMaterial.new()
mat.shader = load("res://shaders/vignette.gdshader")
mat.set_shader_parameter("vignette_strength", 0.4)
mat.set_shader_parameter("vignette_radius", 0.7)
overlay.material = mat
add_child(overlay)
```

**参数说明：**
- `vignette_strength`: 暗角强度 (0-1)
- `vignette_radius`: 暗角半径
- `scene_brightness`: 场景亮度调整
- `scene_saturation`: 场景饱和度调整

---

### 4. 战斗特效系统 (Battle Effects) - `battle_effects.gd`

**用途：** 命中粒子、伤害飘字、屏幕震动

**使用方法：**
```gdshader
# 在 battle_scene.gd 的 _ready() 后添加
func _ready() -> void:
    _setup_battle()
    _update_ui()
    
    # 添加战斗特效节点
    var effects = BattleEffects.new()
    add_child(effects)
    
    # 连接按钮
    ...

# 在造成伤害时调用
func _process_turn(player_move: int) -> void:
    ...
    var result = _calculate_result(player_move, enemy_move)
    
    # 添加视觉反馈
    if "命中" in result:
        effects.show_win_effect(Vector2(640, 300), player_move)
        effects.trigger_screen_shake(6.0)
    elif "失误" in result:
        effects.show_damage_number(Vector2(100, 580), actual_damage, true)
        effects.trigger_screen_shake(10.0)
```

---

### 5. 屏幕震动 (Screen Shake) - `screen_shake.gd`

**用途：** 战斗命中/失误时的屏幕震动反馈

**使用方法：**
```gdshader
# 挂载为 battle_scene 的子节点
# 在场景中实例化或用代码添加

var shake = ScreenShake.new()
add_child(shake)

# 触发震动
shake.trigger_shake(amplitude: 8.0, duration: 0.3)
```

---

### 6. 场景色调后处理 (Post Process) - `post_process.gd`

**用途：** 根据不同场景自动调整整体色调

**使用方法：**
```gdshader
var post_process = PostProcessLayer.new()
add_child(post_process)

# 切换场景时
match current_scene:
    "battle":
        post_process.set_scene_tone("battle")
    "shop":
        post_process.set_scene_tone("shop")
    "event":
        post_process.set_scene_tone("event")
```

---

## 优先建议

### 🔴 高优先级（立竿见影）
1. **按钮发光** - `button_glow.gdshader`
   - 简单：只需给三个按钮设置材质
   - 效果明显：RPS按钮会有呼吸光效

2. **屏幕震动** - `screen_shake.gd`
   - 简单：挂载节点 + 一行调用
   - 大幅提升打击感

3. **暗角效果** - `vignette.gdshader`
   - 简单：添加一个全屏 ColorRect
   - 显著提升氛围感

### 🟡 中优先级（显著提升）
4. **伤害数字飘字** - `battle_effects.gd`
   - 需要集成到战斗逻辑
   - 让伤害反馈更直观

5. **命中粒子** - `battle_effects.gd`
   - 配合伤害数字使用
   - 增强胜利满足感

### 🟢 低优先级（锦上添花）
6. **场景色调** - `post_process.gd`
   - 各场景差异化氛围
   - 需要手动切换

7. **连击发光** - `glow.shader`
   - 根据连招触发不同颜色
   - 高级视觉效果

---

## 文件清单

```
shaders/
├── glow.shader           # 通用发光着色器
├── button_glow.gdshader  # 按钮光晕着色器
├── vignette.gdshader     # 暗角着色器
├── screen_shake.gd       # 屏幕震动控制器
├── battle_effects.gd     # 战斗特效系统
└── post_process.gd        # 后处理层控制器
```

## 集成步骤

1. 创建 `shaders/` 文件夹
2. 将以上文件放入
3. 在 `battle_scene.tscn` 添加子节点：
   - `ScreenShake` (使用 screen_shake.gd)
   - `BattleEffects` (使用 battle_effects.gd)
4. 在 main_menu.tscn 和 map_scene.tscn 添加 `PostProcessLayer`
5. 修改 battle_scene.gd 集成特效调用

---

## 示例：最小集成

最简效果只需：
1. `shaders/button_glow.gdshader` → 三个按钮材质
2. `shaders/vignette.gdshader` → 全屏覆盖层

即可让游戏视觉效果提升一个档次！
