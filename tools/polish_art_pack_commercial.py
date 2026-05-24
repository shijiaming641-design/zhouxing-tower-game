#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
import zipfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont


SRC = Path("/Users/xiaoshizi/Desktop/zhouxing_art_pack_v3")
OUT = Path("/Users/xiaoshizi/Desktop/zhouxing_art_pack_commercial_v1")
ZIP = Path("/Users/xiaoshizi/Desktop/zhouxing_art_pack_commercial_v1.zip")


def font(size: int) -> ImageFont.ImageFont:
    for candidate in [
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/STHeiti Light.ttc",
        "/Library/Fonts/Arial Unicode.ttf",
    ]:
        try:
            return ImageFont.truetype(candidate, size)
        except Exception:
            pass
    return ImageFont.load_default()


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def alpha_bbox(img: Image.Image):
    if img.mode != "RGBA":
        return None
    return img.getchannel("A").getbbox()


def add_pixel_outline(img: Image.Image, color=(20, 16, 12, 210), width=2) -> Image.Image:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    alpha = img.getchannel("A")
    outline = alpha.filter(ImageFilter.MaxFilter(width * 2 + 1))
    ring = ImageChops.subtract(outline, alpha)
    out_layer = Image.new("RGBA", img.size, color)
    out_layer.putalpha(ring)
    result = Image.alpha_composite(out_layer, img)
    return result


def add_soft_shadow(img: Image.Image, offset=(6, 8), blur=7, opacity=86) -> Image.Image:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    alpha = img.getchannel("A")
    shadow_alpha = alpha.filter(ImageFilter.GaussianBlur(blur))
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shifted = Image.new("L", img.size, 0)
    shifted.paste(shadow_alpha, offset)
    shadow.putalpha(shifted.point(lambda p: min(opacity, p)))
    return Image.alpha_composite(shadow, img)


def polish_sprite(path: Path) -> None:
    img = Image.open(path).convert("RGBA")
    bbox = alpha_bbox(img)
    if bbox is None:
        return
    result = add_pixel_outline(img, width=1)
    if "frames" not in path.parts and "spritesheets" not in path.parts:
        result = add_soft_shadow(result)
    save(result, path)


def add_vignette(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    w, h = img.size
    vignette = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(vignette)
    for i in range(90):
        alpha = int(150 * (i / 90) ** 2)
        d.rectangle((i * w // 180, i * h // 180, w - i * w // 180, h - i * h // 180), outline=alpha, width=max(1, w // 320))
    vignette = ImageChops.invert(vignette).filter(ImageFilter.GaussianBlur(44))
    dark = Image.new("RGBA", (w, h), (0, 0, 0, 82))
    dark.putalpha(ImageChops.invert(vignette).point(lambda p: min(110, p)))
    img = Image.alpha_composite(img, dark)
    grain = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grain)
    step = 5
    for y in range(0, h, step):
        for x in range(0, w, step):
            a = ((x * 17 + y * 31) % 23)
            if a < 4:
                gd.point((x, y), fill=(255, 230, 180, 10))
    img = Image.alpha_composite(img, grain)
    return ImageEnhance.Contrast(img).enhance(1.06)


def polish_background(path: Path) -> None:
    img = Image.open(path).convert("RGBA")
    img = add_vignette(img)
    img = ImageEnhance.Color(img).enhance(1.04)
    img = ImageEnhance.Sharpness(img).enhance(1.18)
    save(img, path)


def polish_ui_panel(path: Path) -> None:
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    d = ImageDraw.Draw(img, "RGBA")
    # Edge highlights and subtle ornamental corner marks.
    d.rounded_rectangle((8, 8, w - 8, h - 8), radius=max(6, min(w, h) // 18), outline=(255, 228, 150, 54), width=max(1, min(w, h) // 120))
    corner = max(14, min(w, h) // 10)
    for sx, sy in [(1, 1), (-1, 1), (1, -1), (-1, -1)]:
        x = 12 if sx > 0 else w - 12
        y = 12 if sy > 0 else h - 12
        d.line((x, y, x + sx * corner, y), fill=(244, 196, 92, 132), width=2)
        d.line((x, y, x, y + sy * corner), fill=(244, 196, 92, 132), width=2)
    save(img, path)


def make_preview(root: Path) -> None:
    samples = [
        ("秦背景", "assets/ui/qin/backgrounds/qin_main_menu_bg.png"),
        ("宋地图", "assets/ui/song/backgrounds/song_map_bg.png"),
        ("中国战斗", "assets/ui/china/backgrounds/china_battle_bg.png"),
        ("御医攻击", "assets/characters/doctor/frames/attack/doctor_attack_01.png"),
        ("工匠待机", "assets/characters/artisan/frames/idle/artisan_idle_00.png"),
        ("商人恢复", "assets/characters/merchant/frames/heal/merchant_heal_02.png"),
        ("农民受伤", "assets/characters/farmer/frames/hurt/farmer_hurt_01.png"),
        ("游侠死亡", "assets/characters/wanderer/frames/death/wanderer_death_02.png"),
        ("秦Boss", "assets/enemies/boss/frames/enemy_boss_qin/attack/enemy_boss_qin_attack_02.png"),
        ("宋Boss", "assets/enemies/boss/frames/enemy_boss_song/hurt/enemy_boss_song_hurt_01.png"),
        ("中国二阶段", "assets/enemies/boss/frames/enemy_boss_china_phase2/idle/enemy_boss_china_phase2_idle_00.png"),
        ("卡牌框", "assets/reference/card_common.png"),
    ]
    board = Image.new("RGBA", (1280, 900), (24, 20, 18, 255))
    d = ImageDraw.Draw(board)
    f = font(22)
    d.text((36, 26), "周行 商用打磨版 commercial_v1 预览", font=font(30), fill=(246, 218, 150, 255))
    cw, ch = 300, 250
    for idx, (title, rel) in enumerate(samples):
        x = 35 + (idx % 4) * cw
        y = 86 + (idx // 4) * ch
        d.rounded_rectangle((x, y, x + 270, y + 220), radius=14, fill=(50, 42, 34, 255), outline=(210, 166, 82, 255), width=2)
        im = Image.open(root / rel).convert("RGBA")
        if "backgrounds" in rel:
            im.thumbnail((240, 165), Image.Resampling.LANCZOS)
        else:
            im.thumbnail((240, 165), Image.Resampling.NEAREST)
        board.alpha_composite(im, (x + 15 + (240 - im.width) // 2, y + 18 + (165 - im.height) // 2))
        d.text((x + 135, y + 194), title, font=f, fill=(232, 216, 180, 255), anchor="mm")
    save(board.convert("RGB"), root / "preview_board.png")


def write_commercial_docs(root: Path, stats: dict) -> None:
    report = root / "COMMERCIAL_QA_REPORT.md"
    report.write_text(
        "# Commercial QA Report\n\n"
        "本包是对 `zhouxing_art_pack_v3` 的商业化打磨版本，重点处理：边缘、描边、阴影、UI 高光、背景质感、动作帧完整性和交付文档。\n\n"
        "## 统计\n\n"
        f"- PNG 数量：{stats['png_count']}\n"
        f"- 角色/敌人动作帧目录检查：{stats['action_sets']} 组\n"
        f"- 缺失动作组：{len(stats['missing_actions'])}\n\n"
        "## 已执行的打磨\n\n"
        "- 透明角色、敌人、Boss 增加统一像素描边，减少背景上发虚。\n"
        "- 角色/敌人立绘增加轻投影，但 individual frames 和 spritesheets 保持透明可动画化。\n"
        "- 背景图增加轻暗角、细颗粒和锐度提升，保持非像素清晰背景。\n"
        "- UI 面板、卡牌、按钮增加角部高光与边缘层次。\n"
        "- 重新生成 preview board，便于快速验收。\n\n"
        "## 商用注意\n\n"
        "这些资产由本地程序化脚本生成，未引入第三方素材文件。商用前仍建议做一次人工美术审阅，确认风格、文化表达、商标与平台规范风险。\n",
        encoding="utf-8",
    )
    license_note = root / "LICENSE_COMMERCIAL_NOTES.md"
    license_note.write_text(
        "# Commercial Notes\n\n"
        "- 资源由项目本地脚本生成，不包含外部版权图片。\n"
        "- 可作为游戏 Demo、商店页、宣传测试和后续美术外包基底使用。\n"
        "- 若要正式商业发行，建议让美术或法务做一次最终审阅。\n"
        "- 若后续替换为人工绘制或外包资源，请保留同名路径以免改代码。\n",
        encoding="utf-8",
    )


def collect_stats(root: Path) -> dict:
    pngs = list((root / "assets").rglob("*.png"))
    missing = []
    action_sets = 0
    for base in [root / "assets" / "characters", root / "assets" / "enemies"]:
        for frames_dir in base.rglob("frames"):
            # Character: frames/action/*.png. Enemy: frames/name/action/*.png.
            for actor_dir in frames_dir.iterdir():
                if not actor_dir.is_dir():
                    continue
                if actor_dir.name in {"idle", "attack", "hurt", "heal", "death"}:
                    parent = frames_dir
                    actor = frames_dir.parent.name
                    actions_root = parent
                    break
                actor = actor_dir.name
                actions_root = actor_dir
                for action in ["idle", "attack", "hurt", "heal", "death"]:
                    if not (actions_root / action).exists() or not list((actions_root / action).glob("*.png")):
                        missing.append(f"{actor}:{action}")
                action_sets += 1
    return {"png_count": len(pngs), "missing_actions": missing, "action_sets": action_sets}


def make_zip(root: Path, zip_path: Path) -> None:
    if zip_path.exists():
        zip_path.unlink()
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for path in root.rglob("*"):
            if path.is_file():
                z.write(path, path.relative_to(root.parent))


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"Missing source pack: {SRC}")
    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SRC, OUT)

    for path in (OUT / "assets").rglob("*.png"):
        parts = path.parts
        rel = path.relative_to(OUT).as_posix()
        if "/backgrounds/" in rel:
            polish_background(path)
        elif "/frames/" in rel or "/spritesheets/" in rel or "/characters/" in rel or "/enemies/" in rel:
            polish_sprite(path)
        elif "/ui/" in rel or "/reference/" in rel:
            polish_ui_panel(path)
        elif "/icons/" in rel or "/items/" in rel or "/effects/" in rel:
            polish_sprite(path)

    stats = collect_stats(OUT)
    write_commercial_docs(OUT, stats)
    make_preview(OUT)
    make_zip(OUT, ZIP)
    print(f"polished_dir={OUT}")
    print(f"polished_zip={ZIP}")
    print(json.dumps(stats, ensure_ascii=False))


if __name__ == "__main__":
    main()
