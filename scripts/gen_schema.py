import json
import re
import sys
import urllib.request

BASE = "https://raw.githubusercontent.com/hyprwm/hyprland-wiki/main/content/configuring/"
PAGES = ["core/config-options.md", "layouts/dwindle-layout.md", "layouts/master-layout.md",
         "layouts/scrolling-layout.md", "layouts/monocle-layout.md", "core/animations.md"]
TYPES = {"gradient": "color", "color/gradient": "color"}


def fetch(page):
    return urllib.request.urlopen(BASE + page, timeout=30).read().decode()


def default(raw, typ):
    d = raw.strip().strip("`").strip()
    if d in ("[[Empty]]", "[[Auto]]", ""):
        return None
    if typ == "bool":
        return d == "true"
    try:
        if typ == "int":
            return int(d)
        if typ == "float":
            return float(d)
    except ValueError:
        return d
    return d.strip('"')


def parse(text):
    out, cat = [], None
    for line in text.splitlines():
        m = re.match(r"Category: `([\w.-]+)`", line)
        if line.startswith("#"):
            cat = None
        if m:
            cat = m[1]
        elif cat and line.startswith("| ") and not line.startswith(("| Name", "| ---", "| string")):
            p = [c.strip() for c in line.strip().strip("|").split("|")]
            typ = TYPES.get(p[-3], p[-3])
            row = {"name": f"{cat}.{p[0]}", "type": typ, "default": default(p[-2], typ),
                   "description": "|".join(p[1:-3]), "category": cat.split(".")[0].title(),
                   "is_dynamic": False}
            lim = re.fullmatch(r"\[(-?\d+(?:\.\d+)?) - (-?\d+(?:\.\d+)?)\]", p[-1].strip("` "))
            if lim and typ in ("int", "float"):
                row["min"], row["max"] = float(lim[1]), float(lim[2])
            out.append(row)
        m = re.search(r"↳ (\w+) - (.*)", line)
        if m:
            out.append({"name": f"animation.{m[1]}", "type": "string", "default": None,
                        "description": m[2], "category": "Animations", "is_dynamic": True})
    return out


if __name__ == "__main__":
    schema = [v for page in PAGES for v in parse(fetch(page))]
    names = [v["name"] for v in schema]
    assert len(names) == len(set(names)), "duplicate variable names"
    json.dump(schema, open(sys.argv[1] if len(sys.argv) > 1 else "config_schema.json", "w"), indent=2)
    print(f"{len(schema)} variables")
