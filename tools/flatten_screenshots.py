#!/usr/bin/env python3
"""Ekran goruntulerindeki alfa kanalini kaldirir.

App Store Connect saydamlik iceren ekran goruntusunu kabul etmiyor ve bunu
olcu hatasi gibi genel bir mesajla bildiriyor. Flutter'in
`RepaintBoundary.toImage` cagrisi her zaman RGBA uretiyor; kareler gorsel
olarak tamamen opak olsa bile kanal dosyada duruyor.

Kanal dusurulurken zemin rengi altina konuyor (oyunun zemini, Px.bg).
Dogrudan `convert("RGB")` saydam pikselleri siyaha cevirir; bugun opak
karelerde fark etmez ama ileride yari saydam bir oge girerse leke birakir.

Kullanim:  python3 tools/flatten_screenshots.py
"""

from pathlib import Path

from PIL import Image

BG = (11, 16, 14)  # app/lib/ui/pixel.dart -> Px.bg
ROOT = Path(__file__).resolve().parent.parent / "screenshots"


def flatten(path: Path) -> bool:
    with Image.open(path) as img:
        if img.mode != "RGBA":
            return False
        base = Image.new("RGB", img.size, BG)
        base.paste(img, mask=img.split()[3])
        base.save(path, "PNG", optimize=True)
    return True


def main() -> None:
    changed = 0
    for path in sorted(ROOT.glob("ios-*/*.png")):
        if flatten(path):
            changed += 1
            print(f"  alfa kaldirildi: {path.relative_to(ROOT.parent)}")
    print(f"{changed} dosya duzlestirildi.")


if __name__ == "__main__":
    main()
