#!/usr/bin/env python3
"""Uygulama simgesini uretir.

Sembol: oyunun bas harfi V. Kalin, keskin uclu, altin gradyan dolgulu, kalin
koyu konturlu; arkasinda neredeyse siyah bir zemin. Referans GTA'nin harf
logolari: govdesi kalin, konturu net, uzaktan taninir.

Neden harf: resimli semboller (Ponzi egrisi, el sikisma, kart evi, balon)
40 piksele indiginde okunmuyordu. Neden altin: oyunun konusu para; koyu
magaza ikonlarinin arasinda da en cok goze carpan renk.

Cizim 2x buyutulup kuculuyor (supersampling), boylece egik kenarlar
puruzsuz. Bu simge pixel art degil; oyunun ici pixel, kapagi degil.

Kullanim:  python3 tools/make_icon.py
           cd app && dart run flutter_launcher_icons
Cikti:     app/assets/icon/icon.png            (1024, iOS ve magaza)
           app/assets/icon/icon_foreground.png (Android uyarlanabilir katman)
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "app" / "assets" / "icon"

N = 1024
SS = 2          # supersampling carpani
W = N * SS

INK = (10, 14, 12)            # kontur ve zeminin dibi
BG_TOP = (26, 34, 30)         # zeminin ustu
GOLD_HI = (255, 214, 92)      # harfin ustu
GOLD_LO = (150, 96, 12)       # harfin dibi

OUTLINE_W = 0.055             # kontur kalinligi, kenar uzunluguna oran


def _gradient(size, top, bottom):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        t = y / size
        row = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(size):
            px[x, y] = row
    return img


def _v_shape(size, scale=1.0):
    """Kalin, genis omuzlu, sivri dipli V.

    Nokta sirasi: sol dis ust, sol ic ust, ic dip, sag ic ust, sag dis ust,
    dis dip. Ic dip dis dipten yukarida, boylece uc sivri cikiyor.
    """
    cx = size / 2
    pad = size * (1 - scale) / 2
    half = size * 0.70 * scale / 2
    stroke = size * 0.205 * scale
    y0 = size * 0.20 * scale + pad
    y1 = size * 0.82 * scale + pad
    return [
        (cx - half, y0),
        (cx - half + stroke, y0),
        (cx, y1 - stroke * 0.72),
        (cx + half - stroke, y0),
        (cx + half, y0),
        (cx, y1),
    ]


def _draw_v(canvas, scale=1.0):
    """Once kalin kontur, sonra altin gradyan dolgu."""
    poly = _v_shape(W, scale=scale)
    draw = ImageDraw.Draw(canvas)
    draw.polygon(poly, fill=INK)
    draw.line(poly + [poly[0]], fill=INK, width=int(W * OUTLINE_W), joint="curve")

    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    canvas.paste(_gradient(W, GOLD_HI, GOLD_LO), (0, 0), mask)
    return canvas


def build_icon():
    return _draw_v(_gradient(W, BG_TOP, INK))


def build_foreground():
    """Android uyarlanabilir katman.

    Sistem kenarlardan kirpiyor; harf guvenli alanda kalsin diye kucultulup
    saydam zemine yerlestiriliyor. Zemin rengi pubspec'teki
    adaptive_icon_background degerinden gelir.
    """
    art = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    return _draw_v(art, scale=0.62)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    build_icon().resize((N, N), Image.LANCZOS).convert("RGBA").save(OUT / "icon.png")
    build_foreground().resize((N, N), Image.LANCZOS).save(OUT / "icon_foreground.png")
    print(f"simge uretildi -> {OUT}")


if __name__ == "__main__":
    main()
