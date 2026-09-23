#!/usr/bin/env python3
"""Alt sekme cubugunun pixel art ikonlarini uretir.

Neden: Material'in hazir simgeleri oyunun pixel diline yabanci ve fazla
sade duruyordu. Bes ikon 16x16 pixel haritasi olarak burada; renk uygulamada
veriliyor (secili altin, pasif gri), bu yuzden PNG'ler beyaz cizilir ve
Flutter tarafinda `color` ile boyanir.

Cikti 4x buyutulmus (64x64): Flutter FilterQuality.none ile keskin kalir,
kucultme sirasinda kenar bulanmaz.

Kullanim:  python3 tools/make_tab_icons.py
Cikti:     app/assets/icons/tab_*.png
"""

from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "app" / "assets" / "icons"
SCALE = 4

# "#" dolu, "." bos. Her ikon 16 satir x 16 sutun.
ICONS = {
    # Ofis: iki bloklu is hani, pencereler, kapi, catida tabela.
    "tab_office": [
        "................",
        "....########....",
        "....#......#....",
        "....########....",
        "..############..",
        "..#.##.##.##.#..",
        "..#..........#..",
        "..#.##.##.##.#..",
        "..#..........#..",
        "..#.##.##.##.#..",
        "..#..........#..",
        "..#.##.###.##.#.",
        "..#....#.#...#..",
        "..#....#.#...#..",
        "################",
        "................",
    ],
    # Havuz: kasa (safe), kadran ve kol.
    "tab_pool": [
        "................",
        ".##############.",
        ".#............#.",
        ".#.########...#.",
        ".#.#......#...#.",
        ".#.#..##..#.#.#.",
        ".#.#.####.#.#.#.",
        ".#.#.####.#...#.",
        ".#.#..##..#.#.#.",
        ".#.#......#...#.",
        ".#.########...#.",
        ".#............#.",
        ".##############.",
        "..##........##..",
        "................",
        "................",
    ],
    # Piyasa: eksen ve yukselen kirik cizgi, ucunda ok.
    "tab_market": [
        "................",
        "..#.............",
        "..#..........###",
        "..#...........##",
        "..#..........#.#",
        "..#.........#...",
        "..#....#...#....",
        "..#...#.#.#.....",
        "..#..#...#......",
        "..#.#...........",
        "..##............",
        "..#.............",
        "..#.............",
        "..#############.",
        "................",
        "................",
    ],
    # Medya: megafon ve ses dalgalari.
    "tab_media": [
        "................",
        "..........#.....",
        ".........##.....",
        "........###...#.",
        "..#####.###..#..",
        "..#...#####..#..",
        "..#...#####.#.#.",
        "..#...#####.#.#.",
        "..#...#####..#..",
        "..#####.###..#..",
        "...#.#..###...#.",
        "...#.#...##.....",
        "...#.#....#.....",
        "...###..........",
        "................",
        "................",
    ],
    # Koruma: kalkan, ortasinda kilit.
    "tab_protection": [
        "................",
        "..############..",
        ".#............#.",
        ".#............#.",
        ".#....####....#.",
        ".#...#....#...#.",
        ".#...#....#...#.",
        ".#..########..#.",
        ".#..#......#..#.",
        ".#..#..##..#..#.",
        "..#.#..##..#.#..",
        "..#.########.#..",
        "...#........#...",
        "....#......#....",
        ".....######.....",
        "................",
    ],
}


def render(rows):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(rows):
        assert len(row) == 16, f"{y}. satir 16 karakter degil"
        for x, ch in enumerate(row):
            if ch == "#":
                px[x, y] = (255, 255, 255, 255)
    return img.resize((16 * SCALE, 16 * SCALE), Image.NEAREST)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, rows in ICONS.items():
        assert len(rows) == 16, f"{name} 16 satir degil"
        render(rows).save(OUT / f"{name}.png")
    print(f"{len(ICONS)} ikon uretildi -> {OUT}")


if __name__ == "__main__":
    main()
