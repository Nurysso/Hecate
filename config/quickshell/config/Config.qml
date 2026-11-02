pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Settings from ~/.config/hecate/hecate.toml ($HECATE_CONFIG overrides the path), with defaults filled in.
// The file is reread on save. Each section is replaced only when its own values change, so editing one
// widget doesn't rebuild the bar or refetch the desktop cards. Bad values fall back to the default with a
// warning in `qs log`; a TOML syntax error keeps the last good settings.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string path: Quickshell.env("HECATE_CONFIG") || home + "/.config/hecate/hecate.toml"
    property bool ready   // false until the file has been read once (or found missing)

    property var theme: normalize({}).theme
    property var bar: normalize({}).bar
    property var desktop: normalize({}).desktop
    property var widgets: ({})
    property string wallpaperDir: normalize({}).wallpaperDir

    readonly property var panels: ["launcher", "control", "notifications", "calendar", "connectivity", "power", "clipboard", "emoji", "wallpaper"]

    function expand(p) { return String(p).replace(/^~/, home) }

    function widget(name) { return widgets[name] ?? {} }

    // value may be an M3 token name ("tertiary") or any Qt color ("#ff8800", "tomato")
    function tint(v, fallback) { return v ? (Theme[v] ?? v) : fallback }
    function color(name, key, fallback) { return tint(widget(name)[key], fallback) }

    function normalize(t) {
        const warn = (where, v, why) => console.warn(`hecate.toml: ${where} = ${JSON.stringify(v)} ${why}, using the default`)
        const num = (s, k, d, lo, hi) => {
            const v = t[s]?.[k]
            if (v === undefined) return d
            const n = Number(v)
            if (typeof v === "boolean" || isNaN(n)) { warn(`[${s}] ${k}`, v, "isn't a number"); return d }
            return Math.max(lo, Math.min(hi, n))
        }
        const bool = (s, k, d) => {
            const v = t[s]?.[k]
            if (v === undefined) return d
            if (typeof v !== "boolean") { warn(`[${s}] ${k}`, v, "isn't true or false"); return d }
            return v
        }
        const pick = (s, k, d, allowed) => {
            const v = t[s]?.[k]
            if (v === undefined) return d
            if (!allowed.includes(v)) { warn(`[${s}] ${k}`, v, `isn't one of ${allowed.join(", ")}`); return d }
            return v
        }
        const strings = (s, k, d) => {
            const v = t[s]?.[k]
            if (v === undefined) return d
            if (!Array.isArray(v)) { warn(`[${s}] ${k}`, v, "isn't a list"); return d }
            return v.filter(x => typeof x === "string")
        }
        const names = (s, k, d) => strings(s, k, d).filter(x => /^[a-z][A-Za-z0-9]*$/.test(x))   // widget file names
        const blur = bool("theme", "blur", true)
        return {
            theme: {
                font: typeof t.theme?.font === "string" && t.theme.font ? t.theme.font : "Inter",
                scale: num("theme", "scale", 1, 0.5, 3),
                rounding: num("theme", "rounding", 16, 0, 48),
                blur: blur,
                opacity: num("theme", "opacity", blur ? 0.78 : 0.94, 0, 1),
                border: bool("theme", "border", true),
                animations: bool("theme", "animations", true),
                speed: num("theme", "animation_speed", 1, 0.1, 10)
            },
            bar: {
                position: pick("bar", "position", "top", ["top", "bottom"]),
                style: pick("bar", "style", "islands", ["islands", "floating", "full"]),
                height: num("bar", "height", 40, 24, 96),
                margin: num("bar", "margin", -1, 0, 64),   // -1: follow Hyprland's gaps_out
                monitors: strings("bar", "monitors", []),
                left: names("bar", "left", ["launcher", "workspaces", "windows"]),
                center: names("bar", "center", ["clock"]),
                right: names("bar", "right", ["media", "tray", "status", "notifications", "power"])
            },
            desktop: Object.assign({}, t.desktop, {
                monitor: typeof t.desktop?.monitor === "string" ? t.desktop.monitor : "",
                left: names("desktop", "left", ["clock", "weather", "audio"]),
                right: names("desktop", "right", ["system", "github", "apps"])
            }),
            widgets: t.widgets && typeof t.widgets === "object" ? t.widgets : {},
            wallpaperDir: expand(typeof t.wallpaper?.dir === "string" ? t.wallpaper.dir : "~/Pictures/Wallpapers")
        }
    }

    function apply(toml) {
        const n = normalize(toml)
        for (const k of ["theme", "bar", "desktop", "widgets", "wallpaperDir"])
            if (JSON.stringify(root[k]) !== JSON.stringify(n[k])) root[k] = n[k]
        ready = true
    }

    FileView {
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: parser.running = true
    }

    Process {
        id: parser
        running: true
        command: ["python3", "-c", "import json,sys,tomllib; print(json.dumps(tomllib.load(open(sys.argv[1], 'rb'))))", root.path]
        stdout: StdioCollector { onStreamFinished: if (text) root.apply(JSON.parse(text)) }
        stderr: StdioCollector {
            onStreamFinished: {
                if (!text) return
                if (text.includes("FileNotFoundError")) root.apply({})
                else console.warn("hecate.toml not loaded, keeping the previous settings:\n" + text)
            }
        }
        onExited: code => { if (code !== 0) root.ready = true }   // bad TOML on first read: run on defaults
    }
}
