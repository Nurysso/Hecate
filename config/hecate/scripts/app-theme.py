#!/usr/bin/env python3
"""Recolor Materia-dark (GTK 3/4) and MateriaDark (Kvantum/Qt) with the wallpaper palette.

Reads the M3 colors set-wallpaper.sh writes to ~/.cache/hecate/theme.json and writes:
  ~/.local/share/themes/Hecate        GTK theme (gtk-theme-name=Hecate)
  ~/.config/gtk-4.0/gtk.css           symlink to the Hecate GTK4 css (libadwaita ignores the theme name)
  ~/.config/Kvantum/Hecate            Kvantum theme (theme=Hecate)
  ~/.cache/hecate/palette.png         grid of the palette's colors, for a quick look or fastfetch's logo
Without theme.json the stock Materia colors are kept, so the themes always exist.
"""
import json
import re
import shutil
import struct
import zlib
from pathlib import Path

HOME = Path.home()
GTK_SRC = Path("/usr/share/themes/Materia-dark")
KV_SRC = Path("/usr/share/Kvantum/MateriaDark")
GTK_OUT = HOME / ".local/share/themes/Hecate"
KV_OUT = HOME / ".config/Kvantum/Hecate"

# Materia's palette -> the M3 token that replaces it
CHROMA = {"8ab4f8": "primary", "f28b82": "error", "c58af9": "tertiary", "ce93d8": "tertiary"}
# Materia's grays by level; grays between two levels are interpolated, 0x00 stays black
GRAYS = {0x00: None, 0x12: "surface", 0x1e: "surface_container", 0x27: "surface_container_high",
         0x2e: "surface_container_highest", 0xdf: "on_surface", 0xff: "on_surface"}


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):  # t of a, 1 - t of b
    return tuple(round(x * t + y * (1 - t)) for x, y in zip(a, b))


def load_palette():
    try:
        theme = json.loads((HOME / ".cache/hecate/theme.json").read_text())
    except (OSError, ValueError):
        theme = {}
    def tok(name, fallback):
        v = theme.get(name, "")
        return rgb(v[1:]) if re.fullmatch(r"#[0-9a-fA-F]{6}", v) else fallback
    chroma = {rgb(k): tok(v, rgb(k)) for k, v in CHROMA.items()}
    grays = {g: (g, g, g) if v is None else tok(v, (g, g, g)) for g, v in GRAYS.items()}
    return chroma, grays


def make_recolor(chroma, grays):
    levels = sorted(grays)

    def gray(v):
        lo = max(l for l in levels if l <= v)
        hi = min(l for l in levels if l >= v)
        return grays[lo] if lo == hi else mix(grays[hi], grays[lo], (v - lo) / (hi - lo))

    cache = {}

    def recolor(c):
        if c not in cache:
            cache[c] = _recolor(c)
        return cache[c]

    def _recolor(c):
        if c in chroma:
            return chroma[c]
        if max(c) - min(c) <= 1:
            return gray(round(sum(c) / 3))
        # Shades Materia derives from an accent: t of the accent blended into a gray
        for src, dst in chroma.items():
            for i in range(1, 100):
                t = i / 100
                g = [(x - t * s) / (1 - t) for x, s in zip(c, src)]
                if min(g) >= -2 and max(g) <= 257 and max(g) - min(g) <= 4:
                    return mix(dst, gray(min(255, max(0, round(sum(g) / 3)))), t)
        return c
    return recolor


def recolor_text(text, recolor):
    def hexsub(m):
        h = m.group(1)
        full = "".join(ch * 2 for ch in h) if len(h) == 3 else h[:6]
        r = recolor(rgb(full.lower()))
        return "#%02x%02x%02x" % r + (h[6:] if len(h) == 8 else "")

    def rgbsub(m):
        r = recolor(tuple(int(x) for x in m.group(2, 3, 4)))
        return "%s(%d, %d, %d%s" % (m.group(1), *r, m.group(5))

    text = re.sub(r"#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b", hexsub, text)
    return re.sub(r"(rgba?)\(\s*(\d+),\s*(\d+),\s*(\d+)(\s*[,)])", rgbsub, text)


# Palette swatches, left to right and top to bottom: accents, their containers, then the surfaces and text
SWATCHES = [
    "primary", "secondary", "tertiary", "error", "primary_container", "secondary_container",
    "tertiary_container", "error_container", "surface_dim", "surface", "surface_container", "surface_container_high",
    "surface_container_highest", "surface_bright", "on_surface", "on_surface_variant", "outline", "outline_variant",
]
COLS, CELL, GAP, RADIUS = 6, 96, 8, 18


def write_palette(path):
    """A transparent PNG of rounded swatches, built with the standard library only (no Pillow/ImageMagick)."""
    try:
        theme = json.loads((HOME / ".cache/hecate/theme.json").read_text())
    except (OSError, ValueError):
        return
    colors = [rgb(theme[k][1:]) for k in SWATCHES if re.fullmatch(r"#[0-9a-fA-F]{6}", str(theme.get(k, "")))]
    if not colors:
        return
    rows = -(-len(colors) // COLS)
    width, height = COLS * CELL + (COLS + 1) * GAP, rows * CELL + (rows + 1) * GAP

    def inside(x, y):  # x, y inside one cell: false in the rounded-off corners
        dx = RADIUS - min(x, CELL - 1 - x)
        dy = RADIUS - min(y, CELL - 1 - y)
        return dx <= 0 or dy <= 0 or dx * dx + dy * dy <= RADIUS * RADIUS

    mask = [[inside(x, y) for x in range(CELL)] for y in range(CELL)]
    raw = bytearray()
    for py in range(height):
        raw.append(0)  # filter: none
        row, y = divmod(py - GAP, CELL + GAP)
        in_row = py >= GAP and y < CELL and row < rows
        for px in range(width):
            col, x = divmod(px - GAP, CELL + GAP)
            i = row * COLS + col
            if in_row and px >= GAP and x < CELL and col < COLS and i < len(colors) and mask[y][x]:
                raw += bytes(colors[i]) + b"\xff"
            else:
                raw += b"\0\0\0\0"

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_bytes(png)
    tmp.replace(path)


def link(target, path):
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)
    path.symlink_to(target)


def write(path, text):  # atomic, so running apps never read half a file
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text)
    tmp.replace(path)


def main():
    write_palette(HOME / ".cache/hecate/palette.png")
    recolor = make_recolor(*load_palette())

    if GTK_SRC.is_dir():
        for ver in ("gtk-3.0", "gtk-4.0"):
            out = GTK_OUT / ver
            out.mkdir(parents=True, exist_ok=True)
            write(out / "gtk.css", recolor_text((GTK_SRC / ver / "gtk.css").read_text(), recolor))
            for sub in ("assets", "icons"):
                if (GTK_SRC / ver / sub).is_dir():
                    link(GTK_SRC / ver / sub, out / sub)
        if (GTK_SRC / "gtk-2.0").is_dir():
            link(GTK_SRC / "gtk-2.0", GTK_OUT / "gtk-2.0")
        write(GTK_OUT / "index.theme",
              "[Desktop Entry]\nType=X-GNOME-Metatheme\nName=Hecate\n"
              "Comment=Materia-dark recolored from the wallpaper\n\n"
              "[X-GNOME-Metatheme]\nGtkTheme=Hecate\nIconTheme=breeze-dark\n")
        gtk4 = HOME / ".config/gtk-4.0"
        gtk4.mkdir(parents=True, exist_ok=True)
        link(GTK_OUT / "gtk-4.0/gtk.css", gtk4 / "gtk.css")
        link(GTK_SRC / "gtk-4.0/assets", gtk4 / "assets")

    if KV_SRC.is_dir():
        KV_OUT.mkdir(parents=True, exist_ok=True)
        write(KV_OUT / "Hecate.svg", recolor_text((KV_SRC / "MateriaDark.svg").read_text(), recolor))
        write(KV_OUT / "Hecate.kvconfig", recolor_text((KV_SRC / "MateriaDark.kvconfig").read_text(), recolor))


if __name__ == "__main__":
    main()
