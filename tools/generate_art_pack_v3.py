#!/usr/bin/env python3
from __future__ import annotations

import math
import shutil
import zipfile
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter, ImageFont


OUT = Path("/Users/xiaoshizi/Desktop/zhouxing_art_pack_v3")
ZIP = Path("/Users/xiaoshizi/Desktop/zhouxing_art_pack_v3.zip")

ERAS = {
    "qin": {
        "name": "秦",
        "bg": (62, 42, 28),
        "panel": (74, 50, 34),
        "accent": (190, 132, 62),
        "title": (246, 218, 150),
        "sky": ((130, 100, 78), (222, 174, 112)),
    },
    "song": {
        "name": "宋",
        "bg": (27, 43, 52),
        "panel": (36, 60, 66),
        "accent": (96, 152, 162),
        "title": (220, 236, 224),
        "sky": ((76, 114, 126), (198, 218, 204)),
    },
    "china": {
        "name": "中国",
        "bg": (42, 36, 32),
        "panel": (70, 48, 32),
        "accent": (214, 166, 76),
        "title": (255, 228, 142),
        "sky": ((92, 66, 48), (224, 134, 72)),
    },
}

ROLES = {
    "doctor": {"cn": "御医", "robe": (58, 102, 96), "trim": (218, 198, 138), "prop": "herb"},
    "artisan": {"cn": "工匠", "robe": (62, 82, 100), "trim": (194, 166, 118), "prop": "hammer"},
    "merchant": {"cn": "商人", "robe": (70, 54, 42), "trim": (224, 178, 72), "prop": "coin"},
    "farmer": {"cn": "农民", "robe": (100, 112, 72), "trim": (198, 176, 94), "prop": "grain"},
    "wanderer": {"cn": "游侠", "robe": (48, 48, 46), "trim": (164, 46, 38), "prop": "sword"},
}

LEGACY_ROLE = {
    "doctor": "doctor",
    "artisan": "hacker",
    "merchant": "merchant",
    "farmer": "farmer",
    "wanderer": "wanderer",
}

ENEMIES = {
    "basic": [
        "enemy_basic_tian",
        "enemy_basic_ren",
        "enemy_basic_di",
        "enemy_basic_soldier",
        "enemy_basic_trainee",
        "enemy_basic_guard",
    ],
    "elite": [
        "enemy_elite_switch",
        "enemy_elite_guardian",
        "enemy_elite_counter",
        "enemy_elite_dual",
        "enemy_elite_tactician",
    ],
    "advanced": [
        "enemy_advanced_mind",
        "enemy_advanced_assault",
        "enemy_advanced_mimic",
        "enemy_advanced_sage",
        "enemy_advanced_master",
    ],
    "boss": [
        "enemy_boss_qin",
        "enemy_boss_qin_phase2",
        "enemy_boss_song",
        "enemy_boss_song_phase2",
        "enemy_boss_china",
        "enemy_boss_china_phase2",
    ],
}

ACTIONS = {
    "idle": 4,
    "attack": 4,
    "hurt": 3,
    "heal": 4,
    "death": 5,
}


def ensure(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def save(img: Image.Image, path: Path) -> None:
    ensure(path)
    img.save(path)


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


def upscale(img: Image.Image, scale: int) -> Image.Image:
    return img.resize((img.width * scale, img.height * scale), Image.Resampling.NEAREST)


def outline(draw: ImageDraw.ImageDraw, xy, text: str, fnt, fill, stroke=(28, 22, 18, 230), width=2):
    draw.text(xy, text, font=fnt, fill=fill, stroke_width=width, stroke_fill=stroke, anchor="mm")


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size)
    pix = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        col = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3)) + (255,)
        for x in range(w):
            pix[x, y] = col
    return img


def draw_background(era: str, page: str) -> Image.Image:
    e = ERAS[era]
    img = gradient((1280, 720), e["sky"][0], e["sky"][1])
    d = ImageDraw.Draw(img, "RGBA")

    sun_col = (*e["title"], 72)
    d.ellipse((890, 70, 1130, 310), fill=sun_col)
    for i in range(9):
        y = 220 + i * 36
        alpha = 42 - i * 3
        d.polygon([(0, y + 60), (180, y - 30), (390, y + 46), (640, y - 20), (1280, y + 80), (1280, 720), (0, 720)], fill=(22, 28, 32, max(alpha, 16)))

    if era == "qin":
        for x in range(90, 1180, 145):
            d.rectangle((x, 315, x + 70, 470), fill=(58, 44, 34, 160))
            d.polygon([(x - 12, 315), (x + 35, 286), (x + 82, 315)], fill=(86, 58, 40, 190))
        d.line((0, 510, 1280, 470), fill=(92, 66, 42, 130), width=8)
    elif era == "song":
        for x in range(40, 1280, 180):
            d.polygon([(x, 430), (x + 80, 350), (x + 170, 430)], fill=(46, 76, 82, 130))
            d.rectangle((x + 34, 430, x + 136, 514), fill=(42, 66, 70, 150))
        for y in range(520, 720, 24):
            d.arc((-80, y - 40, 1360, y + 80), 0, 180, fill=(210, 232, 226, 36), width=2)
    else:
        for x in range(0, 1280, 210):
            d.rectangle((x + 50, 305, x + 112, 514), fill=(50, 42, 36, 150))
            d.polygon([(x + 30, 305), (x + 82, 260), (x + 134, 305)], fill=(92, 54, 34, 170))
        d.rectangle((0, 500, 1280, 720), fill=(48, 35, 28, 100))

    page_tint = {
        "main_menu": (255, 230, 160, 20),
        "map": (120, 180, 150, 22),
        "battle": (196, 68, 44, 28),
        "shop": (218, 156, 74, 24),
        "rest": (94, 170, 114, 24),
        "event": (130, 110, 180, 22),
        "result": (255, 210, 120, 30),
    }.get(page, (255, 255, 255, 0))
    d.rectangle((0, 0, 1280, 720), fill=page_tint)
    d.rectangle((0, 590, 1280, 720), fill=(*e["bg"], 130))
    return img.filter(ImageFilter.GaussianBlur(0.25))


def panel_asset(era: str, label: str, size=(1280, 720), alpha=196) -> Image.Image:
    e = ERAS[era]
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    pad = min(max(6, min(size) // 28), max(2, min(size[0], size[1]) // 4))
    radius = max(2, min(18, min(size) // 4))
    d.rounded_rectangle((pad, pad, size[0] - pad, size[1] - pad), radius=radius, fill=(*e["panel"], alpha), outline=(*e["accent"], 230), width=max(1, min(size) // 80))
    inner_pad = min(pad * 2, max(2, min(size[0], size[1]) // 3))
    if size[0] - inner_pad > inner_pad and size[1] - inner_pad > inner_pad:
        d.rounded_rectangle((inner_pad, inner_pad, size[0] - inner_pad, size[1] - inner_pad), radius=max(2, radius // 2), outline=(*e["title"], 88), width=1)
    if size[0] > 250 and size[1] > 120:
        outline(d, (size[0] // 2, pad + 24), label, font(24), (*e["title"], 220), width=1)
    return img


def seal_asset(era: str, text: str, size=(192, 72)) -> Image.Image:
    e = ERAS[era]
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle((8, 8, size[0] - 8, size[1] - 8), radius=12, fill=(*e["panel"], 240), outline=(*e["accent"], 255), width=3)
    d.rounded_rectangle((16, 16, size[0] - 16, size[1] - 16), radius=8, outline=(*e["title"], 150), width=1)
    outline(d, (size[0] // 2, size[1] // 2), text, font(28), (*e["title"], 255), width=1)
    return img


def small_ui_asset(era: str, kind: str, size=(128, 128), text="") -> Image.Image:
    e = ERAS[era]
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    if kind == "node_boss":
        d.regular_polygon((size[0] // 2, size[1] // 2, size[0] // 2 - 12), 6, rotation=math.pi / 6, fill=(*e["panel"], 245), outline=(*e["accent"], 255))
    else:
        d.rounded_rectangle((10, 10, size[0] - 10, size[1] - 10), radius=18, fill=(*e["panel"], 238), outline=(*e["accent"], 250), width=3)
    symbols = {"battle": "战", "shop": "商", "rest": "营", "event": "闻", "boss": "灾"}
    outline(d, (size[0] // 2, size[1] // 2), text or symbols.get(kind.replace("node_", ""), "令"), font(42), (*e["title"], 255), width=2)
    return img


def icon_asset(symbol: str, palette: tuple[int, int, int] = (220, 180, 92)) -> Image.Image:
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle((6, 6, 58, 58), radius=12, fill=(42, 38, 32, 230), outline=(*palette, 255), width=2)
    outline(d, (32, 32), symbol, font(28), (250, 230, 170, 255), width=1)
    return img


def draw_pixel_actor(kind: str, colors: dict, action: str, frame: int, boss: bool = False) -> Image.Image:
    base = Image.new("RGBA", (128, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(base, "RGBA")
    cx = 64 + (2 if action == "attack" else 0) * frame
    bob = int(math.sin(frame * 1.2) * 2) if action == "idle" else 0
    if action == "hurt":
        cx -= 4
    if action == "death":
        cx += frame * 7
    robe = colors.get("robe", (72, 72, 72))
    trim = colors.get("trim", (210, 160, 80))
    skin = (232, 176, 126)
    hair = (42, 34, 28)
    if boss:
        robe = tuple(min(255, int(c * 0.8 + 42)) for c in robe)
        trim = (232, 194, 82)

    if action == "death":
        d.ellipse((cx - 34, 108, cx + 42, 130), fill=(*robe, 220), outline=(*trim, 200))
        d.ellipse((cx + 20, 92, cx + 58, 126), fill=skin, outline=(62, 42, 30, 220))
        d.line((cx - 12, 102, cx + 34, 118), fill=(*trim, 230), width=4)
        return upscale(base, 3)

    d.ellipse((cx - 26, 18 + bob, cx + 26, 70 + bob), fill=skin, outline=(64, 42, 32, 220))
    d.pieslice((cx - 30, 10 + bob, cx + 30, 60 + bob), 180, 360, fill=hair)
    d.rectangle((cx - 34, 58 + bob, cx + 34, 122 + bob), fill=(*robe, 245), outline=(36, 30, 26, 230))
    d.line((cx - 28, 68 + bob, cx + 28, 112 + bob), fill=(*trim, 230), width=3)
    d.line((cx + 28, 68 + bob, cx - 28, 112 + bob), fill=(*trim, 150), width=2)
    d.ellipse((cx - 14, 43 + bob, cx - 8, 49 + bob), fill=(30, 24, 20))
    d.ellipse((cx + 8, 43 + bob, cx + 14, 49 + bob), fill=(30, 24, 20))

    arm_y = 78 + bob
    if action == "attack":
        d.line((cx + 26, arm_y, cx + 58, arm_y - 26 - frame * 2), fill=skin, width=7)
        d.line((cx + 48, arm_y - 20, cx + 82, arm_y - 54), fill=(*trim, 255), width=4)
        d.polygon([(cx + 82, arm_y - 54), (cx + 72, arm_y - 49), (cx + 76, arm_y - 62)], fill=(230, 230, 220, 255))
    elif action == "heal":
        glow = 80 + frame * 35
        d.ellipse((cx - 46, 26, cx + 46, 118), outline=(116, 230, 150, glow), width=4)
        d.line((cx + 24, arm_y, cx + 44, arm_y - 8), fill=skin, width=7)
    elif action == "hurt":
        d.line((cx + 24, arm_y, cx + 40, arm_y + 8), fill=skin, width=7)
        d.polygon([(cx - 38, 35), (cx - 28, 30), (cx - 32, 46)], fill=(235, 60, 42, 220))
    else:
        d.line((cx + 24, arm_y, cx + 42, arm_y + 4), fill=skin, width=7)
    d.line((cx - 24, arm_y, cx - 42, arm_y + (6 if action != "attack" else -10)), fill=skin, width=7)

    prop = colors.get("prop", "")
    if prop == "herb":
        d.line((cx - 46, arm_y - 8, cx - 54, arm_y - 38), fill=(66, 140, 72), width=3)
        d.ellipse((cx - 62, arm_y - 40, cx - 48, arm_y - 28), fill=(76, 166, 82))
    elif prop == "hammer":
        d.line((cx - 42, arm_y - 4, cx - 62, arm_y - 36), fill=(116, 80, 44), width=4)
        d.rectangle((cx - 70, arm_y - 44, cx - 50, arm_y - 32), fill=(94, 96, 98))
    elif prop == "coin":
        d.ellipse((cx - 58, arm_y - 34, cx - 38, arm_y - 14), fill=(224, 176, 54), outline=(90, 60, 22))
    elif prop == "grain":
        d.line((cx - 42, arm_y, cx - 68, arm_y - 42), fill=(174, 126, 42), width=3)
        for i in range(4):
            d.ellipse((cx - 72 + i * 6, arm_y - 48 + i * 6, cx - 62 + i * 6, arm_y - 38 + i * 6), fill=(220, 170, 70))
    elif prop == "sword":
        d.line((cx - 42, arm_y, cx - 70, arm_y - 36), fill=(214, 214, 210), width=4)

    if boss:
        d.arc((cx - 42, 4, cx + 42, 86), 200, 340, fill=(*trim, 230), width=5)
        d.rectangle((cx - 26, 16, cx + 26, 28), fill=(40, 34, 30), outline=(*trim, 220))
    return upscale(base, 3)


def crop_center(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    src = img.copy()
    src.thumbnail(size, Image.Resampling.NEAREST)
    canvas.alpha_composite(src, ((size[0] - src.width) // 2, (size[1] - src.height) // 2))
    return canvas


def make_sheet(frames: list[Image.Image]) -> Image.Image:
    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.alpha_composite(frame, (i * w, 0))
    return sheet


def write_character_assets() -> list[dict]:
    rows = []
    for role, data in ROLES.items():
        role_dir = OUT / "assets" / "characters" / role
        frames_by_action = {}
        for action, count in ACTIONS.items():
            frames = []
            for i in range(count):
                img = draw_pixel_actor(role, data, action, i)
                frame_path = role_dir / "frames" / action / f"{role}_{action}_{i:02d}.png"
                save(img, frame_path)
                rows.append(asset_row(frame_path, "character_frame", "common", f"{img.width}x{img.height}", "yes", "planned"))
                frames.append(img)
            frames_by_action[action] = frames
            sheet = make_sheet(frames)
            sheet_path = role_dir / "spritesheets" / f"{role}_{action}_sheet.png"
            save(sheet, sheet_path)
            rows.append(asset_row(sheet_path, "character_spritesheet", "common", f"{sheet.width}x{sheet.height}", "yes", "planned"))

        battle = crop_center(frames_by_action["idle"][0], (512, 768))
        portrait = crop_center(frames_by_action["idle"][0].crop((80, 10, 300, 230)), (256, 256))
        select = crop_center(frames_by_action["idle"][1], (512, 512))
        icon = crop_center(portrait, (128, 128)).resize((256, 256), Image.Resampling.NEAREST)
        passive = icon_asset(data["cn"][0], data["trim"])
        passive = passive.resize((256, 256), Image.Resampling.NEAREST)
        for suffix, img, use in [
            ("battle", battle, "character_battle"),
            ("portrait", portrait, "character_portrait"),
            ("select", select, "character_select"),
            ("icon", icon, "character_icon"),
            ("passive_icon", passive, "character_passive_icon"),
        ]:
            p = role_dir / f"{role}_{suffix}.png"
            save(img, p)
            rows.append(asset_row(p, use, "common", f"{img.width}x{img.height}", "yes", "yes"))
        legacy = LEGACY_ROLE[role]
        for suffix in ["battle", "portrait", "select"]:
            src = role_dir / f"{role}_{suffix}.png"
            dst = OUT / "assets" / "characters" / f"{legacy}_{suffix}.png"
            ensure(dst)
            shutil.copyfile(src, dst)
            rows.append(asset_row(dst, f"legacy_{suffix}", "common", image_size(dst), "yes", "yes"))
    return rows


def enemy_colors(name: str, tier: str) -> dict:
    base = {
        "basic": (86, 82, 72),
        "elite": (98, 58, 52),
        "advanced": (58, 74, 96),
        "boss": (82, 44, 38),
    }[tier]
    if "tian" in name:
        base = (58, 84, 120)
    elif "ren" in name:
        base = (126, 74, 44)
    elif "di" in name or "guard" in name:
        base = (68, 96, 68)
    elif "china" in name:
        base = (118, 52, 42)
    elif "song" in name:
        base = (42, 88, 98)
    elif "qin" in name:
        base = (104, 72, 42)
    return {"robe": base, "trim": (212, 170, 72), "prop": "sword"}


def write_enemy_assets() -> list[dict]:
    rows = []
    for tier, names in ENEMIES.items():
        for name in names:
            boss = tier == "boss"
            e_dir = OUT / "assets" / "enemies" / tier
            frames_by_action = {}
            for action, count in ACTIONS.items():
                frames = []
                for i in range(count):
                    img = draw_pixel_actor(name, enemy_colors(name, tier), action, i, boss=boss)
                    frame_path = e_dir / "frames" / name / action / f"{name}_{action}_{i:02d}.png"
                    save(img, frame_path)
                    rows.append(asset_row(frame_path, "enemy_frame", "common", f"{img.width}x{img.height}", "yes", "planned"))
                    frames.append(img)
                frames_by_action[action] = frames
                sheet = make_sheet(frames)
                sheet_path = e_dir / "spritesheets" / f"{name}_{action}_sheet.png"
                save(sheet, sheet_path)
                rows.append(asset_row(sheet_path, "enemy_spritesheet", "common", f"{sheet.width}x{sheet.height}", "yes", "planned"))

            portrait = crop_center(frames_by_action["idle"][0], (512, 512))
            tier_path = e_dir / f"{name}.png"
            flat_path = OUT / "assets" / "enemies" / f"{name}.png"
            save(portrait, tier_path)
            save(portrait, flat_path)
            rows.append(asset_row(tier_path, "enemy_portrait", "common", "512x512", "yes", "yes"))
            rows.append(asset_row(flat_path, "enemy_portrait_legacy", "common", "512x512", "yes", "yes"))
    return rows


def write_ui_assets() -> list[dict]:
    rows = []
    pages = ["main_menu", "map", "battle", "shop", "rest", "event", "result"]
    for era in ERAS:
        for page in pages:
            p = OUT / "assets" / "ui" / era / "backgrounds" / f"{era}_{page}_bg.png"
            save(draw_background(era, page), p)
            rows.append(asset_row(p, "ui_background", era, "1280x720", "no", "yes" if page in ["main_menu", "map", "battle"] else "planned"))
        for frame in ["menu_frame", "battle_frame", "shop_panel", "rest_panel", "event_panel", "overlay_frame", "result_panel"]:
            p = OUT / "assets" / "ui" / era / "frames" / f"{era}_{frame}.png"
            save(panel_asset(era, frame.replace("_", " ")), p)
            rows.append(asset_row(p, "ui_frame", era, "1280x720", "yes", "yes" if frame in ["menu_frame", "battle_frame", "shop_panel", "rest_panel", "overlay_frame"] else "planned"))
        for seal in ["main_menu", "map", "battle", "shop", "rest", "event"]:
            p = OUT / "assets" / "ui" / era / "seals" / f"{era}_{seal}_seal.png"
            save(seal_asset(era, f"{ERAS[era]['name']}卷"), p)
            rows.append(asset_row(p, "ui_seal", era, image_size(p), "yes", "yes" if seal in ["main_menu", "map", "battle"] else "planned"))
        for node in ["battle", "shop", "rest", "event", "boss"]:
            p = OUT / "assets" / "ui" / era / "nodes" / f"{era}_node_{node}.png"
            save(small_ui_asset(era, f"node_{node}"), p)
            rows.append(asset_row(p, "map_node", era, "128x128", "yes", "yes"))
        for btn in ["large", "medium", "icon", "hover", "pressed", "disabled"]:
            p = OUT / "assets" / "ui" / era / "buttons" / f"{era}_button_{btn}.png"
            alpha = 150 if btn == "disabled" else 230
            save(panel_asset(era, "", (320 if btn == "large" else 180 if btn == "medium" else 64, 96 if btn == "large" else 64), alpha), p)
            rows.append(asset_row(p, "ui_button", era, image_size(p), "yes", "planned"))
        for card in ["shop_card", "equipment_card", "combo_card", "character_card", "card_locked", "card_selected"]:
            p = OUT / "assets" / "ui" / era / "cards" / f"{era}_{card}.png"
            save(panel_asset(era, "", (280, 184), 220), p)
            rows.append(asset_row(p, "ui_card", era, "280x184", "yes", "planned"))
        for overlay in ["modal_frame", "tooltip_frame", "rule_panel", "settings_panel", "codex_panel", "upgrade_panel"]:
            p = OUT / "assets" / "ui" / era / "overlays" / f"{era}_{overlay}.png"
            size = (720, 420) if overlay != "tooltip_frame" else (360, 180)
            save(panel_asset(era, overlay.replace("_", " "), size, 230), p)
            rows.append(asset_row(p, "ui_overlay", era, image_size(p), "yes", "planned"))
    return rows


def write_icons_items_effects() -> list[dict]:
    rows = []
    icon_defs = {
        "icons/system": {
            "icon_settings": "设",
            "icon_rules": "规",
            "icon_sound": "音",
            "icon_back": "返",
            "icon_close": "关",
            "icon_save": "存",
            "icon_home": "家",
        },
        "icons/combat": {
            "icon_tian": "天",
            "icon_ren": "人",
            "icon_di": "地",
            "icon_attack": "攻",
            "icon_shield": "盾",
            "icon_cheat": "机",
            "icon_combo": "连",
            "icon_crit": "暴",
            "icon_break_armor": "碎",
            "icon_victory": "胜",
            "icon_defeat": "败",
            "icon_draw": "平",
        },
        "icons/status": {
            "status_burn": "燃",
            "status_slow": "缓",
            "status_armor": "甲",
            "status_attack_up": "强",
            "status_weak": "弱",
            "status_boss_phase": "变",
        },
        "icons/resource": {
            "resource_gold": "金",
            "resource_material": "材",
            "resource_memory": "忆",
            "resource_hp": "命",
            "resource_attack": "攻",
            "resource_armor": "甲",
        },
        "icons/action": {
            "action_start": "起",
            "action_continue": "续",
            "action_next": "进",
            "action_buy": "买",
            "action_refresh": "刷",
            "action_upgrade": "升",
            "action_equip": "装",
            "action_unequip": "卸",
            "action_heal": "愈",
            "action_craft": "锻",
        },
    }
    for folder, items in icon_defs.items():
        for name, symbol in items.items():
            p = OUT / "assets" / folder / f"{name}.png"
            save(icon_asset(symbol), p)
            rows.append(asset_row(p, "icon", "common", "64x64", "yes", "yes" if name in ["icon_tian", "icon_ren", "icon_di", "icon_attack", "icon_shield", "icon_cheat", "icon_settings", "icon_rules", "icon_sound", "icon_back"] else "planned"))

    item_defs = {
        "items/icons": {
            "item_sword": "剑",
            "item_shield": "盾",
            "item_crystal": "晶",
            "item_mirror": "镜",
            "item_potion": "药",
            "item_amulet": "符",
        },
        "items/equipment": {
            "equipment_long_sword": "长",
            "equipment_wooden_shield": "木",
            "equipment_life_crystal": "命",
            "equipment_heart_mirror": "心",
            "equipment_demon_blade": "魔",
            "equipment_blood_tyrant": "血",
        },
        "items/relics": {
            "qin_relic_01": "秦",
            "song_relic_01": "宋",
            "china_relic_01": "中",
        },
    }
    for folder, items in item_defs.items():
        for name, symbol in items.items():
            p = OUT / "assets" / folder / f"{name}.png"
            save(icon_asset(symbol, (214, 166, 78)), p)
            rows.append(asset_row(p, "item", "common", "64x64", "yes", "planned"))
    era_items = {
        "qin": ("qin_item_tiger_tally", "虎"),
        "song": ("song_item_trade_ledger", "账"),
        "china": ("china_item_mountain_seal", "山"),
    }
    for era, (name, symbol) in era_items.items():
        p = OUT / "assets" / "items" / "era_sets" / era / f"{name}.png"
        save(icon_asset(symbol, ERAS[era]["accent"]), p)
        rows.append(asset_row(p, "era_item", era, "64x64", "yes", "yes"))

    ref_defs = {
        "title_back_common": (320, 72),
        "divider_line_common": (240, 20),
        "corner_stud_common": (32, 32),
        "chapter_box_common": (192, 72),
        "bottom_bar_common": (1280, 96),
        "chip_common": (128, 48),
        "card_common": (280, 184),
        "button_frame_common": (320, 96),
        "tooltip_frame_common": (360, 180),
    }
    for name, size in ref_defs.items():
        p = OUT / "assets" / "reference" / f"{name}.png"
        save(panel_asset("qin", "", size, 218), p)
        rows.append(asset_row(p, "reference", "common", image_size(p), "yes", "yes" if name in ["card_common", "button_frame_common"] else "planned"))

    effect_defs = [
        ("effects/combo/combo_flash_01.png", "连"),
        ("effects/hit/hit_slash_01.png", "斩"),
        ("effects/hit/hit_spark_01.png", "火"),
        ("effects/particles/boss_phase_flash.png", "变"),
        ("effects/result/victory_stamp.png", "胜"),
        ("effects/result/defeat_stamp.png", "败"),
        ("effects/result/draw_stamp.png", "平"),
        ("effects/shield/shield_break_01.png", "碎"),
    ]
    for rel, symbol in effect_defs:
        p = OUT / "assets" / rel
        img = icon_asset(symbol, (236, 190, 72)).resize((128, 128), Image.Resampling.NEAREST)
        save(img, p)
        rows.append(asset_row(p, "effect", "common", "128x128", "yes", "planned"))
    return rows


def image_size(path: Path) -> str:
    with Image.open(path) as img:
        return f"{img.width}x{img.height}"


def asset_row(path: Path, use: str, era: str, size: str, transparent: str, integrated: str) -> dict:
    return {
        "file": str(path.relative_to(OUT)),
        "use": use,
        "era": era,
        "size": size,
        "transparent": transparent,
        "integrated": integrated,
    }


def write_docs(rows: list[dict]) -> None:
    readme = OUT / "README.md"
    readme.write_text(
        "# zhouxing_art_pack_v3\n\n"
        "完整美术 UI 整合包。包含清晰非像素背景、像素风透明角色/敌人/Boss、多动作帧、UI、图标、物品、特效与 manifest。\n\n"
        "动作帧统一包含：idle、attack、hurt、heal、death。\n"
        "角色与敌人同时提供 individual frames 与 spritesheet。\n",
        encoding="utf-8",
    )
    manifest = OUT / "asset_manifest.md"
    lines = [
        "# asset_manifest.md",
        "",
        "| file | use | era | size | transparent | integrated_in_code |",
        "|---|---|---|---|---|---|",
    ]
    for row in sorted(rows, key=lambda r: r["file"]):
        lines.append(f"| `{row['file']}` | {row['use']} | {row['era']} | {row['size']} | {row['transparent']} | {row['integrated']} |")
    manifest.write_text("\n".join(lines) + "\n", encoding="utf-8")


def make_zip() -> None:
    if ZIP.exists():
        ZIP.unlink()
    with zipfile.ZipFile(ZIP, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for path in OUT.rglob("*"):
            if path.is_file():
                z.write(path, path.relative_to(OUT.parent))


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    rows: list[dict] = []
    rows.extend(write_ui_assets())
    rows.extend(write_character_assets())
    rows.extend(write_enemy_assets())
    rows.extend(write_icons_items_effects())
    write_docs(rows)
    make_zip()
    print(f"generated_dir={OUT}")
    print(f"generated_zip={ZIP}")
    print(f"asset_count={len(rows)}")


if __name__ == "__main__":
    main()
