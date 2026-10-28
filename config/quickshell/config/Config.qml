pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string path: home + "/.config/hecate/hecate.toml"
    property var toml: ({})

    readonly property var bar: Object.assign({
        left: ["launcher", "workspaces", "windows"],
        center: ["clock"],
        right: ["media", "volume", "battery", "tray", "connectivity", "notifications", "clipboard", "wallpaper", "power"]
    }, toml.bar)
    readonly property var desktop: Object.assign({
        monitor: "",
        left: ["clock", "weather", "audio"],
        right: ["system", "github", "apps"]
    }, toml.desktop)
    readonly property string font: toml.theme?.font ?? "Inter"
    readonly property string wallpaperDir: expand(toml.wallpaper?.dir ?? "~/Pictures/Wallpapers")

    function expand(path) { return path.replace(/^~/, home) }

    function widget(name) { return toml.widgets?.[name] ?? {} }

    // value may be an M3 token name ("tertiary") or any Qt color ("#ff8800")
    function tint(v, fallback) { return v ? (Theme[v] ?? v) : fallback }
    function color(name, key, fallback) { return tint(widget(name)[key], fallback) }

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
        stdout: StdioCollector { onStreamFinished: if (text) root.toml = JSON.parse(text) }
        stderr: StdioCollector { onStreamFinished: if (text) console.warn("hecate.toml not loaded, keeping previous settings:\n" + text) }
    }
}
