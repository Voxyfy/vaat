#!/usr/bin/env python3
"""Ofis sahnesinin pixel art sprite'larini uretir.

Neden script: elle cizilmis PNG'ler yerine uretici kod tutuyoruz. Palet tek
yerden degisiyor, tum parcalar ayni olcekte ve ayni renk dunyasinda kaliyor,
yeni mobilya eklemek birkac satir.

Kullanim:  python3 tools/make_sprites.py
Cikti:     app/assets/sprites/*.png
"""

from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "app" / "assets" / "sprites"

# Palet. Oyunun koyu yesil temasiyla uyumlu, sinirli ve tutarli.
P = {
    ".": (0, 0, 0, 0),          # saydam
    "k": (14, 20, 18, 255),     # en koyu
    "d": (31, 42, 37, 255),     # duvar
    "D": (24, 33, 29, 255),     # duvar golge
    "z": (58, 68, 60, 255),     # zemin
    "Z": (50, 59, 52, 255),     # zemin varyant
    "a": (107, 74, 47, 255),    # ahsap
    "A": (74, 51, 32, 255),     # ahsap koyu
    "m": (74, 90, 82, 255),     # metal
    "M": (58, 70, 64, 255),     # metal koyu
    "p": (216, 212, 192, 255),  # kagit
    "e": (46, 204, 113, 255),   # ekran / vurgu
    "E": (26, 122, 69, 255),    # ekran koyu
    "t": (200, 155, 106, 255),  # ten
    "T": (160, 120, 80, 255),   # ten golge
    "y": (62, 125, 79, 255),    # bitki
    "Y": (44, 92, 58, 255),     # bitki koyu
    "s": (40, 48, 52, 255),     # ayakkabi / koyu detay
    "w": (235, 235, 230, 255),  # beyaz
}


def draw(rows, palette=None):
    """Karakter izgarasini PNG'ye cevirir."""
    pal = palette or P
    h = len(rows)
    w = len(rows[0])
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(rows):
        assert len(row) == w, f"satir {y} genisligi tutmuyor"
        for x, ch in enumerate(row):
            px[x, y] = pal[ch]
    return img


def save(name, img):
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{name}.png")
    return name


# --- Zemin ve duvar ---------------------------------------------------------

FLOOR = [
    "zzzzzzzzzzzzzzzz",
    "zZzzzzzzzZzzzzzz",
    "zzzzzzzzzzzzzzzz",
    "zzzzZzzzzzzzZzzz",
    "zzzzzzzzzzzzzzzz",
    "zzzzzzzZzzzzzzzz",
    "zzzzzzzzzzzzzzzz",
    "Zzzzzzzzzzzzzzzz",
    "zzzzzzzzzzzzzzzz",
    "zzzZzzzzzzzZzzzz",
    "zzzzzzzzzzzzzzzz",
    "zzzzzzzzzzzzzzzz",
    "zzzzzzzzZzzzzzzz",
    "zzZzzzzzzzzzzzzz",
    "zzzzzzzzzzzzzzzz",
    "zzzzzzzzzzzzzzzz",
]

WALL = [
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dDddddddddddddDd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dDddddddddddddDd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dDddddddddddddDd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dddddddddddddddd",
]

# Zemine bitisik duvar sirasi. Supurgelik yalniz burada, boylece duvar
# yukari dogru tekrar ederken cizgi olusmuyor.
WALL_BASE = [
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dDddddddddddddDd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "dddddddddddddddd",
    "DDDDDDDDDDDDDDDD",
    "MMMMMMMMMMMMMMMM",
    "MMMMMMMMMMMMMMMM",
    "DDDDDDDDDDDDDDDD",
    "kkkkkkkkkkkkkkkk",
]

# --- Mobilya (16x16) --------------------------------------------------------

DESK = [
    "................",
    "................",
    "................",
    "....eeeeeee.....",
    "....eEEEEEe.....",
    "....eEeeeEe.....",
    "....eEEEEEe.....",
    "....eeeeeee.....",
    ".....mmmmm......",
    "aaaaaaaaaaaaaa..",
    "AAAAAAAAAAAAAA..",
    "a............a..",
    "a............a..",
    "a............a..",
    "A............A..",
    "................",
]

CABINET = [
    "................",
    "..AAAAAAAAAA....",
    "..aaaaaaaaaa....",
    "..a........a....",
    "..a.pppppp.a....",
    "..a.pppppp.a....",
    "..a........a....",
    "..aaaaaaaaaa....",
    "..a........a....",
    "..a.pppppp.a....",
    "..a.pppppp.a....",
    "..a........a....",
    "..aaaaaaaaaa....",
    "..AAAAAAAAAA....",
    "................",
    "................",
]

PLANT = [
    "................",
    ".......y........",
    "....y.yYy.y.....",
    "...yYyyyyyYy....",
    "...yyyYyYyyy....",
    "....yyyyyyy.....",
    ".....yYyYy......",
    "......yyy.......",
    "......yYy.......",
    "......yYy.......",
    ".....aaaaa......",
    ".....aAAAa......",
    ".....aAAAa......",
    "......AAA.......",
    "................",
    "................",
]

SAFE = [
    "................",
    "..MMMMMMMMMM....",
    "..MmmmmmmmmM....",
    "..Mm.......M....",
    "..Mm..mmm..M....",
    "..Mm.m...m.M....",
    "..Mm.m.e.m.M....",
    "..Mm.m...m.M....",
    "..Mm..mmm..M....",
    "..Mm.......M....",
    "..Mm.......M....",
    "..MmmmmmmmmM....",
    "..MMMMMMMMMM....",
    "................",
    "................",
    "................",
]

# --- Karakter (16x16, 3 kare: idle, adim1, adim2) ---------------------------

def person(shirt, shirt_dark, frame):
    """Tek bir calisan, 16x16.

    Uc kare: duran, sol adim, sag adim. Kollar ten renginde yanlarda duruyor
    ki govde 16 pikselde topak gibi gorunmesin.
    """
    legs = {
        0: ("....ss..ss....", "....ss..ss....", "...ss....ss..."),
        1: ("....ss..ss....", "...ss.....s...", "..ss......ss.."),
        2: ("....ss..ss....", "...s.....ss...", "..ss......ss.."),
    }[frame]
    S, D = shirt, shirt_dark
    rows = [
        "................",
        "......tttt......",
        ".....tttttt.....",
        ".....tTttTt.....",
        ".....tttttt.....",
        "......tttt......",
        "......TTTT......",
        f"....{S*8}....",
        f"...t{S}{D*6}{S}t...",
        f"...t{S}{D*6}{S}t...",
        f"...t{S}{D*6}{S}t...",
        f"....{S*8}....",
        f".....{D*6}.....",
        f".{legs[0]}.",
        f".{legs[1]}.",
        f".{legs[2]}.",
    ]
    return rows


SHIRTS = [("e", "E"), ("m", "M"), ("p", "m"), ("y", "Y"), ("a", "A")]


def main():
    made = []
    made.append(save("floor", draw(FLOOR)))
    made.append(save("wall", draw(WALL)))
    made.append(save("wall_base", draw(WALL_BASE)))
    made.append(save("desk", draw(DESK)))
    made.append(save("cabinet", draw(CABINET)))
    made.append(save("plant", draw(PLANT)))
    made.append(save("safe", draw(SAFE)))

    # Her calisan tipi icin 3 kareli yatay sprite serit.
    for i, (a, b) in enumerate(SHIRTS):
        sheet = Image.new("RGBA", (16 * 3, 16), (0, 0, 0, 0))
        for frame in range(3):
            sheet.paste(draw(person(a, b, frame)), (frame * 16, 0))
        made.append(save(f"person_{i}", sheet))

    print(f"{len(made)} sprite uretildi -> {OUT}")
    for name in made:
        print(" ", name)


if __name__ == "__main__":
    main()
