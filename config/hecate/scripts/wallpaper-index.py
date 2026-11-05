#!/usr/bin/env python3
"""Indexes a wallpaper folder for the picker: thumbnails and dominant colours, kept in a SQLite cache.

Usage: wallpaper-index.py <dir>

Output, one line at a time (tab separated), so the picker can show the grid straight away:
  P <0|1>                              1 when Pillow is installed (colours need it)
  F <path> <name> <thumb> <colors> <mtime>   one wallpaper; colors is "#rrggbb,#rrggbb,..." most to least
                                       present, mtime is when the file last changed, in seconds

Everything already in the cache is printed first. Only files that are new or edited (path, mtime or
size changed) get a thumbnail and colours, a few at a time at low priority, and are printed as they
finish. Files that are gone are dropped along with their thumbnail.

Cache: ~/.cache/hecate/wallpapers.db and ~/.cache/hecate/wallthumbs/<sha1 of path|mtime|size>.jpg.
Thumbnails come from vipsthumbnail (shrink-on-load, never decodes a whole 8K image) or else Pillow.
Colours are read from the small thumbnail with Pillow. Without Pillow the picker still works, minus
colours: one critical notification (once) asks for it, and rows are filled in once it is installed.
"""
import hashlib
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    from PIL import Image, ImageOps
except ImportError:
    Image = None

EXTS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif"}
SIZE = 480
SWATCHES = 6
SCHEMA = 1
HECATE = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "hecate")
THUMBS = os.path.join(HECATE, "wallthumbs")
DB = os.path.join(HECATE, "wallpapers.db")
NOTICE = os.path.join(HECATE, ".pillow-notified")

lock = threading.Lock()


def emit(*parts):
    with lock:
        sys.stdout.write("\t".join(parts) + "\n")
        sys.stdout.flush()


def scan(root):
    out = {}
    with os.scandir(root) as it:
        for e in it:
            if os.path.splitext(e.name)[1].lower() not in EXTS:
                continue
            try:
                if e.is_file():
                    st = e.stat()
                    out[e.path] = (st.st_mtime_ns, st.st_size)
            except OSError:
                pass
    return out


def thumb_path(path, mtime, size):
    return os.path.join(THUMBS, hashlib.sha1(f"{path}|{mtime}|{size}".encode()).hexdigest() + ".jpg")


def build(src, dst):
    tmp = f"{dst}.{os.getpid()}.{threading.get_ident()}.tmp.jpg"
    try:
        if shutil.which("vipsthumbnail"):
            subprocess.run(["nice", "-n", "15", "vipsthumbnail", src, "-s", f"{SIZE}x{SIZE}", "-o", f"{tmp}[Q=80,strip]"],
                           check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)
        else:
            with Image.open(src) as im:
                im.draft("RGB", (SIZE * 2, SIZE * 2))  # JPEG shrink-on-load; a no-op for other formats
                im = ImageOps.exif_transpose(im).convert("RGB")
                im.thumbnail((SIZE, SIZE))
                im.save(tmp, "JPEG", quality=80)
        os.replace(tmp, dst)
        return True
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        return False


def colors(thumb):
    """The thumbnail's main colours as hex, most to least present."""
    try:
        with Image.open(thumb) as im:
            im = im.convert("RGB")
            im.thumbnail((64, 64))
            q = im.quantize(colors=SWATCHES, method=Image.Quantize.MEDIANCUT)
            pal = q.getpalette()
            return ["#%02x%02x%02x" % tuple(pal[i * 3:i * 3 + 3]) for _, i in sorted(q.getcolors(), reverse=True)]
    except Exception:
        return []


def notify_once():
    if os.path.exists(NOTICE):
        return
    try:
        os.makedirs(HECATE, exist_ok=True)
        open(NOTICE, "w").close()
        subprocess.run(["notify-send", "-u", "critical", "Hecate wallpapers",
                        "Install Pillow (python-pillow on Arch, python3-pillow on Fedora) to group wallpapers by colour."],
                       check=False, timeout=10)
    except (OSError, subprocess.SubprocessError):
        pass


def connect():
    os.makedirs(THUMBS, exist_ok=True)
    db = sqlite3.connect(DB, timeout=30, isolation_level=None)
    db.execute("PRAGMA journal_mode=WAL")
    if db.execute("PRAGMA user_version").fetchone()[0] != SCHEMA:  # only a cache: rebuild on a new layout
        db.execute("DROP TABLE IF EXISTS wall")
        db.execute("PRAGMA user_version=%d" % SCHEMA)
    # colors is a JSON array, or NULL until Pillow has looked at the thumbnail
    db.execute("CREATE TABLE IF NOT EXISTS wall (path TEXT PRIMARY KEY, dir TEXT, name TEXT, mtime_ns INTEGER,"
               " size INTEGER, thumb TEXT, colors TEXT)")
    return db


def main():
    root = os.path.realpath(os.path.expanduser(sys.argv[1])) if len(sys.argv) > 1 else ""
    if not os.path.isdir(root):
        return
    pillow = Image is not None
    emit("P", "1" if pillow else "0")
    if not pillow:
        notify_once()
    can_thumb = pillow or bool(shutil.which("vipsthumbnail"))

    db = connect()
    files = scan(root)
    known = {r[0]: r[1:] for r in db.execute("SELECT path, mtime_ns, size, thumb, colors FROM wall WHERE dir=?", (root,))}

    def row_out(path, name, thumb, cols, mtime):
        emit("F", path, name, thumb, ",".join(json.loads(cols)) if cols else "", str(mtime // 10**9))

    todo = []
    for path, (mtime, size) in sorted(files.items(), key=lambda f: os.path.basename(f[0]).casefold()):
        name = os.path.splitext(os.path.basename(path))[0]
        thumb = thumb_path(path, mtime, size) if can_thumb else path
        old = known.get(path)
        fresh = old and old[0] == mtime and old[1] == size and old[2] == thumb and (not can_thumb or os.path.exists(thumb))
        if fresh and (old[3] is not None or not pillow):
            row_out(path, name, thumb, old[3], mtime)
        else:
            todo.append((path, name, mtime, size, thumb))

    for path in known.keys() - files.keys():
        db.execute("DELETE FROM wall WHERE path=?", (path,))

    def work(item):
        path, name, mtime, size, thumb = item
        if can_thumb and not os.path.exists(thumb) and not build(path, thumb):
            thumb = path  # undecodable: the original stands in
        return path, name, mtime, size, thumb, json.dumps(colors(thumb)) if pillow else None

    with ThreadPoolExecutor(max_workers=max(1, (os.cpu_count() or 2) // 2)) as pool:
        for done in as_completed([pool.submit(work, t) for t in todo]):
            path, name, mtime, size, thumb, cols = done.result()
            db.execute("INSERT OR REPLACE INTO wall VALUES (?,?,?,?,?,?,?)", (path, root, name, mtime, size, thumb, cols))
            row_out(path, name, thumb, cols, mtime)

    # thumbnails nothing refers to any more (edited or removed files, or the cache from before the database)
    used = {r[0] for r in db.execute("SELECT thumb FROM wall")}
    for e in os.scandir(THUMBS):
        if e.path not in used and e.name.endswith(".jpg") and ".tmp." not in e.name:
            try:
                os.unlink(e.path)
            except OSError:
                pass


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        pass
