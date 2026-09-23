#!/usr/bin/env python3
"""Uygulama simgesini uretir.

Sembol: oyunun bas harfi V. Kalin, keskin uclu, altin gradyan dolgulu, kalin
koyu konturlu. Ikinci surumde harf, oyun icindeki tycoon dugmeleri gibi
kabartmali: sol ust kenari acik altin, sag alt kenari koyu altin. Arkasinda
oyunun panel dili: koyu yesil zemin, icinde kabartmali bir cerceve.

Neden harf: resimli semboller (Ponzi egrisi, el sikisma, kart evi, balon)
40 piksele indiginde okunmuyordu. Neden altin: oyunun konusu para; koyu
magaza ikonlarinin arasinda da en cok goze carpan renk.

Kontur neden "damgalama" ile ciziliyor: ImageDraw.line kalin cizgiyi sivri
koselerde yuvarlayip centik birakiyordu (ilk surumde V'nin sol ust kosesinde
altin dolgu konturun disina tasti). Dolu sekli bir daire boyunca kaydirip
ust uste basmak, her koseyi ayni kalinlikta ve ayni bicimde sisiriyor.

Cizim 2x buyutulup kuculuyor (supersampling), boylece egik kenarlar
puruzsuz. Bu simge pixel art degil; oyunun ici pixel, kapagi degil.

Kullanim:  python3 tools/make_icon.py
           cd app && dart run flutter_launcher_icons
Cikti:     app/assets/icon/icon.png            (1024, iOS ve magaza)
           app/assets/icon/icon_foreground.png (Android uyarlanabilir katman)
           docs/icon.png                       (web sayfalari)
"""

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "app" / "assets" / "icon"
DOCS = ROOT / "docs"

N = 1024
SS = 2          # supersampling carpani
W = N * SS

# Oyun icindeki Px paletiyle ayni degerler (app/lib/ui/pixel.dart).
INK = (5, 8, 7)               # kontur ve golge
BG = (11, 16, 14)             # zemin
PANEL = (22, 32, 27)          # cerceve ici
LIGHT = (46, 64, 54)          # kabartma isigi
GOLD_HI = (255, 214, 92)      # harfin ustu
GOLD_LO = (184, 134, 11)      # harfin dibi
GOLD_EDGE_HI = (255, 240, 184)  # harfin sol ust ic kenari
GOLD_EDGE_LO = (150, 96, 12)    # harfin sag alt ic kenari

OUTLINE_W = 0.050             # kontur kalinligi, kenar uzunluguna oran
BEVEL_W = 0.022               # harfin ic kabartma bandi
FRAME_INSET = 0.095           # cercevenin kenardan payi
FRAME_W = 0.020               # cerceve kalinligi


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
    half = size * 0.60 * scale / 2
    stroke = size * 0.20 * scale
    y0 = size * 0.24 * scale + pad
    y1 = size * 0.80 * scale + pad
    return [
        (cx - half, y0),
        (cx - half + stroke, y0),
        (cx, y1 - stroke * 0.72),
        (cx + half - stroke, y0),
        (cx + half, y0),
        (cx, y1),
    ]


def _mask(poly):
    m = Image.new("L", (W, W), 0)
    ImageDraw.Draw(m).polygon(poly, fill=255)
    return m


def _dilate(mask, radius, steps=180):
    """Maskeyi her yone `radius` kadar sisirir: daire boyunca damgalama."""
    out = mask.copy()
    for i in range(steps):
        a = 2 * math.pi * i / steps
        dx, dy = round(radius * math.cos(a)), round(radius * math.sin(a))
        out = ImageChops.lighter(out, ImageChops.offset(mask, dx, dy))
    return out


def _draw_v(canvas, scale=1.0):
    """Kontur, altin yuz, sonra ic kabartma bantlari."""
    poly = _v_shape(W, scale=scale)
    face = _mask(poly)
    outline = _dilate(face, int(W * OUTLINE_W * scale))
    canvas.paste(Image.new("RGB", (W, W), INK), (0, 0), outline)
    canvas.paste(_gradient(W, GOLD_HI, GOLD_LO), (0, 0), face)

    # Kabartma: yuzu sag alta kaydirinca acikta kalan sol ust serit isik,
    # sol uste kaydirinca kalan sag alt serit golge. Dugmelerdeki kenarla
    # ayni mantik.
    d = int(W * BEVEL_W * scale)
    hi = ImageChops.subtract(face, ImageChops.offset(face, d, d))
    lo = ImageChops.subtract(face, ImageChops.offset(face, -d, -d))
    canvas.paste(Image.new("RGB", (W, W), GOLD_EDGE_HI), (0, 0), hi)
    canvas.paste(Image.new("RGB", (W, W), GOLD_EDGE_LO), (0, 0), lo)
    return canvas


def _frame(canvas):
    """Zeminde kabartmali panel cercevesi: oyunun panel dili.

    iOS koseleri yuvarlayarak kirpar; cerceve icerde kaldigi icin kirpilmaz.
    """
    draw = ImageDraw.Draw(canvas)
    p = int(W * FRAME_INSET)
    w = int(W * FRAME_W)
    draw.rectangle([p, p, W - p, W - p], fill=PANEL)
    # Sol ve ust: isik. Sag ve alt: golge.
    draw.rectangle([p, p, W - p, p + w], fill=LIGHT)
    draw.rectangle([p, p, p + w, W - p], fill=LIGHT)
    draw.rectangle([p, W - p - w, W - p, W - p], fill=INK)
    draw.rectangle([W - p - w, p, W - p, W - p], fill=INK)
    return canvas


def build_icon():
    return _draw_v(_frame(Image.new("RGB", (W, W), BG)))


def build_foreground():
    """Android uyarlanabilir katman.

    Sistem kenarlardan kirpiyor; harf guvenli alanda kalsin diye kucultulup
    saydam zemine yerlestiriliyor. Cerceve yok: zemin rengi pubspec'teki
    adaptive_icon_background degerinden gelir.
    """
    art = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    return _draw_v(art, scale=0.62)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    icon = build_icon().resize((N, N), Image.LANCZOS).convert("RGBA")
    icon.save(OUT / "icon.png")
    if DOCS.exists():
        icon.save(DOCS / "icon.png")
    build_foreground().resize((N, N), Image.LANCZOS).save(OUT / "icon_foreground.png")
    print(f"simge uretildi -> {OUT}")


if __name__ == "__main__":
    main()
