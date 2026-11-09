#!/usr/bin/env python3
"""Draw the README's SVGs into this directory.

GitHub strips CSS from READMEs, so the styling lives in these images. Text is
converted to outlines, so they look the same without Noto Sans installed.

    pip install -r .github/requirements.txt
    python .github/readme/generate.py

Needs Noto Sans and JetBrains Mono (see requirements.txt). Re-run after bumping version.txt. PALETTE is
a copy of ~/.cache/hecate/theme.json for the wallpaper in the screenshots; it is
frozen on purpose, so changing wallpaper doesn't change the README.
"""
from pathlib import Path

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

OUT = Path(__file__).parent
ROOT = OUT.parent.parent

PALETTE = {
    "primary": "#f5b2e1",
    "primary_fixed": "#ffd7f1",
    "on_primary": "#4e1e45",
    "primary_container": "#68355c",
    "secondary": "#dcbed0",
    "secondary_container": "#56404f",
    "tertiary": "#f5b9a3",
    "source_color": "#a57497",
    "background": "#181216",
    "surface_container_low": "#201a1e",
    "surface_container": "#241e22",
    "surface_container_high": "#2f282c",
    "surface_container_highest": "#3a3337",
    "on_surface": "#ecdfe5",
    "on_surface_variant": "#d2c2ca",
    "outline": "#9b8d94",
    "outline_variant": "#4f444a",
}
P = PALETTE

FONTS = {
    "regular": "/usr/share/fonts/noto/NotoSans-Regular.ttf",
    "semibold": "/usr/share/fonts/noto/NotoSans-Medium.ttf",
    "bold": "/usr/share/fonts/noto/NotoSans-Bold.ttf",
    "mono": "/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Regular.ttf",
}
_loaded = {}


def font(name):
    if name not in _loaded:
        f = TTFont(FONTS[name])
        _loaded[name] = (f, f.getGlyphSet(), f.getBestCmap(), f["head"].unitsPerEm)
    return _loaded[name]


def measure(s, size, face="regular", tracking=0):
    f, _, cmap, upem = font(face)
    hmtx = f["hmtx"]
    return sum(hmtx[cmap[ord(c)]][0] * size / upem + tracking for c in s) - tracking


def text(s, x, y, size, fill, face="regular", anchor="start", tracking=0, opacity=None):
    """One outlined run of text. x, y is the baseline."""
    _, glyphs, cmap, upem = font(face)
    width = measure(s, size, face, tracking)
    x -= {"start": 0, "middle": width / 2, "end": width}[anchor]
    scale = size / upem
    pen = SVGPathPen(glyphs, ntos=lambda v: f"{v:.2f}".rstrip("0").rstrip("."))
    for c in s:
        name = cmap[ord(c)]
        glyphs[name].draw(TransformPen(pen, (scale, 0, 0, -scale, x, y)))
        x += glyphs[name].width * scale + tracking
    extra = f' opacity="{opacity}"' if opacity else ""
    return f'<path fill="{fill}"{extra} d="{pen.getCommands()}"/>'


def wrap(s, size, width, face="regular"):
    lines, line = [], ""
    for word in s.split():
        trial = f"{line} {word}".strip()
        if measure(trial, size, face) > width and line:
            lines.append(line)
            line = word
        else:
            line = trial
    return lines + [line]


def moon(cx, cy, r, fill):
    """A crescent, the mark that stands in for 🌙."""
    tx, ty = cx + 0.5 * r, 0.866 * r
    return (
        f'<path fill="{fill}" d="M{tx:.2f} {cy - ty:.2f}A{r} {r} 0 1 0 {tx:.2f} {cy + ty:.2f}'
        f'A{r * 0.9:.2f} {r * 0.9:.2f} 0 0 1 {tx:.2f} {cy - ty:.2f}Z"/>'
    )


def svg(name, w, h, title, body, defs=""):
    defs = f"<defs>{defs}</defs>" if defs else ""
    (OUT / f"{name}.svg").write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:g}" height="{h:g}" '
        f'viewBox="0 0 {w:g} {h:g}" role="img" aria-label="{title}">'
        f"<title>{title}</title>{defs}{body}</svg>\n"
    )


def marble_defs(w, h, rx, seed):
    """The swirled pink clouds of the wallpaper, drawn with noise, not an image."""
    return f"""
<clipPath id="clip"><rect width="{w}" height="{h}" rx="{rx}"/></clipPath>
<linearGradient id="sky" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0" stop-color="{P['source_color']}"/>
  <stop offset=".3" stop-color="{P['primary']}"/>
  <stop offset=".55" stop-color="{P['secondary']}"/>
  <stop offset="1" stop-color="{P['primary_container']}"/>
</linearGradient>
<filter id="marble" x="-20%" y="-40%" width="140%" height="180%">
  <feGaussianBlur in="SourceGraphic" stdDeviation="46" result="soft"/>
  <feTurbulence type="fractalNoise" baseFrequency=".0034 .0105" numOctaves="5" seed="{seed}" result="noise"/>
  <feDisplacementMap in="soft" in2="noise" scale="340" xChannelSelector="R" yChannelSelector="G"/>
  <feGaussianBlur stdDeviation="2.5"/>
</filter>"""


def marble(w, h):
    blobs = [
        (0.16, 0.25, 0.26, 0.6, P["primary_fixed"], 0.9),
        (0.42, 0.8, 0.3, 0.55, P["primary_container"], 0.85),
        (0.66, 0.15, 0.22, 0.5, P["tertiary"], 0.75),
        (0.88, 0.62, 0.26, 0.7, P["secondary_container"], 0.95),
        (0.04, 0.95, 0.2, 0.5, P["source_color"], 0.9),
    ]
    shapes = "".join(
        f'<ellipse cx="{x * w:.0f}" cy="{y * h:.0f}" rx="{rx * w:.0f}" ry="{ry * h:.0f}" '
        f'fill="{c}" opacity="{o}"/>'
        for x, y, rx, ry, c, o in blobs
    )
    return (
        '<g clip-path="url(#clip)"><g filter="url(#marble)">'
        f'<rect x="-300" y="-300" width="{w + 600}" height="{h + 600}" fill="url(#sky)"/>'
        f"{shapes}</g></g>"
    )


def glass(x, y, w, h, rx, opacity=0.8):
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" '
        f'fill="{P["surface_container"]}" fill-opacity="{opacity}" '
        f'stroke="{P["on_surface"]}" stroke-opacity=".14"/>'
    )


def hero(name, version, codename, title, tagline, lines):
    w, h = 1280, 440
    bar = glass(20, 20, 190, 46, 23)
    bar += moon(47, 43, 11, P["primary"])
    bar += f'<rect x="72" y="31" width="44" height="24" rx="12" fill="{P["primary"]}"/>'
    bar += "".join(
        f'<circle cx="{x}" cy="43" r="6" fill="{P["outline"]}"/>' for x in (134, 158, 182)
    )

    label = f"v{version}  {codename}"
    pill_w = measure(label, 18, "semibold") + 52
    bar += glass((w - pill_w) / 2, 20, pill_w, 46, 23)
    bar += text(label, w / 2, 49, 18, P["on_surface"], "semibold", "middle")

    bar += glass(w - 210, 20, 190, 46, 23)
    swatches = (P["primary"], P["secondary"], P["tertiary"], P["source_color"])
    bar += "".join(
        f'<circle cx="{w - 184 + i * 30}" cy="43" r="9" fill="{c}"/>'
        for i, c in enumerate(swatches)
    )
    bar += (
        f'<circle cx="{w - 44}" cy="43" r="15" fill="{P["primary_container"]}"/>'
        f'<circle cx="{w - 44}" cy="43" r="6" fill="none" stroke="{P["primary"]}" stroke-width="2.4"/>'
    )

    title_w = measure(title, 92, "bold")
    tx = w / 2 - title_w / 2 + 36
    card = glass(250, 104, 780, 288, 32, 0.84)
    card += moon(tx - 54, 190, 36, P["primary"])
    card += text(title, tx, 222, 92, P["on_surface"], "bold")
    card += text(tagline, w / 2, 286, 32, P["primary"], "semibold", "middle")
    for y, line in zip((331, 360), lines):
        card += text(line, w / 2, y, 21, P["on_surface_variant"], anchor="middle")

    svg(name, w, h, f"{title}. {tagline}",
        marble(w, h) + bar + card, marble_defs(w, h, 32, 11))


def chip(name, label, value, accent):
    h, pad, size = 36, 15, 15
    lw = measure(label, size, "semibold") + pad * 2
    vw = measure(value, size, "bold") + pad * 2
    w = lw + vw
    defs = f'<clipPath id="c"><rect width="{w:.1f}" height="{h}" rx="{h / 2}"/></clipPath>'
    body = (
        f'<g clip-path="url(#c)"><rect width="{w:.1f}" height="{h}" fill="{P["surface_container_high"]}"/>'
        f'<rect x="{lw:.1f}" width="{vw:.1f}" height="{h}" fill="{accent}"/></g>'
        + text(label, pad, 23.5, size, P["on_surface"], "semibold")
        + text(value, lw + pad, 23.5, size, P["on_primary"], "bold")
    )
    svg(f"chip-{name}", round(w, 1), h, f"{label}: {value}", body, defs)


def pill(name, label, filled=False):
    h, size = 44, 17
    w = measure(label, size, "semibold") + 44
    fill = P["primary"] if filled else P["surface_container"]
    stroke = P["primary"] if filled else P["outline_variant"]
    ink = P["on_primary"] if filled else P["on_surface"]
    body = (
        f'<rect x=".75" y=".75" width="{w - 1.5:.1f}" height="{h - 1.5}" rx="{(h - 1.5) / 2}" '
        f'fill="{fill}" stroke="{stroke}" stroke-width="1.5"/>'
        + text(label, w / 2, 28, size, ink, "semibold", "middle")
    )
    svg(f"nav-{name}", round(w, 1), h, label, body)


def card(n, title, where, blurb, accent):
    w, h, pad = 400, 320, 32
    defs = (
        f'<radialGradient id="glow" cx=".12" cy="0" r="1">'
        f'<stop offset="0" stop-color="{accent}" stop-opacity=".3"/>'
        f'<stop offset="1" stop-color="{accent}" stop-opacity="0"/></radialGradient>'
    )
    body = (
        f'<rect x="1" y="1" width="{w - 2}" height="{h - 2}" rx="28" fill="{P["surface_container"]}"/>'
        f'<rect x="1" y="1" width="{w - 2}" height="{h - 2}" rx="28" fill="url(#glow)" '
        f'stroke="{P["outline_variant"]}" stroke-width="2"/>'
        f'<circle cx="{pad + 26}" cy="{pad + 26}" r="26" fill="{accent}"/>'
        + text(str(n), pad + 26, pad + 37, 30, P["on_primary"], "bold", "middle")
        + text(title, pad, 142, 40, P["on_surface"], "bold")
        + text(where.upper(), pad, 176, 16, accent, "bold", tracking=1.6)
    )
    for i, line in enumerate(wrap(blurb, 22, w - pad * 2)):
        body += text(line, pad, 218 + i * 31, 22, P["on_surface_variant"])
    svg(f"card-{n}", w, h, f"{title}, {where}. {blurb}", body, defs)


def divider():
    w, h = 1280, 28
    defs = f"""<linearGradient id="l"><stop offset="0" stop-color="{P['primary']}" stop-opacity="0"/>
<stop offset="1" stop-color="{P['primary']}"/></linearGradient>
<linearGradient id="r"><stop offset="0" stop-color="{P['tertiary']}"/>
<stop offset="1" stop-color="{P['tertiary']}" stop-opacity="0"/></linearGradient>"""
    body = (
        f'<rect x="120" y="13" width="490" height="2" fill="url(#l)"/>'
        f'<rect x="670" y="13" width="490" height="2" fill="url(#r)"/>'
        + moon(640, 14, 11, P["source_color"])
    )
    svg("divider", w, h, "", body, defs)


def palette():
    swatches = [
        ("primary", P["primary"]),
        ("secondary", P["secondary"]),
        ("tertiary", P["tertiary"]),
        ("source", P["source_color"]),
        ("container", P["primary_container"]),
        ("surface high", P["surface_container_high"]),
        ("surface", P["background"]),
        ("on surface", P["on_surface"]),
    ]
    w, h, pad, gap = 1280, 330, 44, 16
    size = (w - pad * 2 - gap * (len(swatches) - 1)) / len(swatches)
    body = (
        f'<rect x="1" y="1" width="{w - 2}" height="{h - 2}" rx="30" fill="{P["surface_container"]}" '
        f'stroke="{P["outline_variant"]}" stroke-width="2"/>'
        + text("One wallpaper, one palette", pad, 74, 34, P["on_surface"], "bold")
        + text("matugen pulled these from the wallpaper in the screenshots. This page is drawn in them too.",
               pad, 110, 22, P["on_surface_variant"])
    )
    for i, (name, color) in enumerate(swatches):
        x = pad + i * (size + gap)
        body += (
            f'<rect x="{x:.1f}" y="140" width="{size:.1f}" height="104" rx="20" fill="{color}" '
            f'stroke="{P["on_surface"]}" stroke-opacity=".16"/>'
            + text(name, x + 4, 274, 19, P["on_surface"], "semibold")
            + text(color, x + 4, 300, 17, P["outline"], "mono")
        )
    svg("palette", w, h, "The theme palette, generated from the wallpaper", body)


def footer():
    w, h = 1280, 210
    body = marble(w, h) + glass(190, 40, 900, 130, 28, 0.84)
    line = "Fork it, change it, send a pull request."
    lw = measure(line, 36, "bold")
    x = w / 2 - lw / 2 + 26
    body += moon(x - 36, 104, 19, P["primary"])
    body += text(line, x, 118, 36, P["on_surface"], "bold")
    svg("footer", w, h, line, body, marble_defs(w, h, 30, 23))


def main():
    version, codename = (ROOT / "version.txt").read_text().split(maxsplit=1)
    codename = codename.strip()

    hero("hero", version, codename, "Hecate", "Hyprland, set up your way.", (
        "Tell the installer what you use. Change it later in a settings app.",
        "Go as deep as you like in one TOML file."))
    hero("hero-shell", version, codename, "Hecate Shell", "Frosted glass for Hyprland.", (
        "A bar, panels and desktop widgets that follow your wallpaper,",
        "talk to Hyprland directly, and answer to a single file."))
    chip("version", f"v{version}", codename, P["primary"])
    chip("hyprland", "Hyprland", "Lua config", P["secondary"])
    chip("arch", "Arch", "supported", P["primary"])
    chip("fedora", "Fedora", "new", P["tertiary"])
    chip("license", "License", "MIT", P["secondary"])
    chip("quickshell", "Quickshell", "0.3+", P["primary"])
    chip("hyprland-lua", "Hyprland", "0.55+ · Lua", P["secondary"])
    chip("colors", "Colors", "Material You", P["tertiary"])
    chip("config", "Config", "hecate.toml", P["primary"])

    pill("install", "Install", filled=True)
    pill("customize", "Customize")
    pill("settings", "Settings app")
    pill("toml", "hecate.toml")
    pill("keys", "Keybindings")
    pill("help", "Troubleshooting")
    pill("shell", "Shell docs")
    for tool in ("Hyprland", "Quickshell", "CXX-Qt", "matugen"):
        pill(f"tool-{tool.lower()}", tool)

    card(1, "Asked once", "When you install",
         "Pick your terminal, shell, browser and profile. It installs exactly that.", P["primary"])
    card(2, "Clicked", "In Hecate Settings",
         "Gaps, blur, animations, keybinds, monitors, widgets. Every change previews live.", P["tertiary"])
    card(3, "Written", "In hecate.toml",
         "One file for the details. Save it and the desktop updates on the spot.", P["secondary"])

    divider()
    palette()
    footer()


if __name__ == "__main__":
    main()
