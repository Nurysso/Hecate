import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.components

// Your Hyprland binds, read from keybinds.lua. "--/ Title" starts a category and a trailing "-- text"
// on a bind is its description (the markers the Hecate settings app reads too); binds without one are
// left out. Arrows in the header flip pages.
// [desktop.keybinds] file, rows (binds per page), rotate (seconds between pages, 0 = off), categories
Card {
    id: root
    widget: "keybinds"

    readonly property string file: Config.expand(cfg.file ?? "~/.config/hypr/configs/keybinds.lua")
    readonly property int rows: Math.max(3, Math.min(20, Number(cfg.rows ?? 8) || 8))
    readonly property int rotate: Number(cfg.rotate ?? 0) || 0
    readonly property var only: Array.isArray(cfg.categories) ? cfg.categories.map(c => String(c).toLowerCase()) : []
    readonly property int rowHeight: Theme.px(30)

    property var groups: []
    property int page: 0
    property bool missing

    readonly property var pages: {
        const out = []
        for (const g of groups) {
            if (only.length && !only.includes(g.title.toLowerCase())) continue
            const parts = Math.ceil(g.binds.length / rows)
            for (let i = 0; i < parts; i++)
                out.push({ title: g.title, part: i, parts: parts, binds: g.binds.slice(i * rows, (i + 1) * rows) })
        }
        return out
    }
    readonly property var current: pages[page] ?? null

    onPagesChanged: page = Math.min(page, Math.max(0, pages.length - 1))
    function flip(by) { if (pages.length) page = (page + by + pages.length) % pages.length }

    readonly property var names: ({
        super: "Super", shift: "Shift", ctrl: "Ctrl", alt: "Alt", "return": "↵", space: "Space", tab: "Tab",
        left: "←", right: "→", up: "↑", down: "↓", print: "PrtSc", "delete": "Del", escape: "Esc",
        bracketleft: "[", bracketright: "]", minus: "−", equal: "=", comma: ",", period: ".", slash: "/",
        semicolon: ";", apostrophe: "'", grave: "`", backslash: "\\", mouse_down: "Scroll ↓", mouse_up: "Scroll ↑",
        "mouse:272": "Left click", "mouse:273": "Right click"
    })
    function label(k) {
        const n = names[k.toLowerCase()]
        if (n) return n
        if (/^xf86/i.test(k)) return k.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2")
        return k.length === 1 ? k.toUpperCase() : k
    }

    function parse(src) {
        const out = []
        let group = null
        for (const line of src.split("\n")) {
            const head = line.match(/^--\/\s*(.*?)\s*(?:\(.*\))?\s*$/)
            if (head) { group = { title: head[1], binds: [] }; out.push(group); continue }
            const m = line.match(/^hl\.bind\(\s*((?:mainMod|"[^"]*")(?:\s*\.\.\s*(?:mainMod|"[^"]*"))*)\s*,.*\)\s*--\s*(\S.*?)\s*$/)
            if (!m || !group) continue
            const keys = m[1].split("..").map(s => s.trim()).map(s => s === "mainMod" ? "SUPER" : s.slice(1, -1)).join("")
            group.binds.push({ keys: keys.split(/\s*\+\s*/).filter(k => k).map(label), desc: m[2] })
        }
        return out.filter(g => g.binds.length)
    }

    FileView {
        path: root.file
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { root.groups = root.parse(text()); root.missing = false }
        onLoadFailed: { root.groups = []; root.missing = true }
    }

    Timer {
        running: root.rotate > 0 && root.pages.length > 1
        repeat: true
        interval: Math.max(2, root.rotate) * 1000
        onTriggered: root.flip(1)
    }

    CardHeader {
        icon: Theme.icon.keyboard
        title: root.current ? root.current.title + (root.current.parts > 1 ? `  ${root.current.part + 1}/${root.current.parts}` : "") : "Keybinds"
        accent: root.accent
        IconButton { visible: root.pages.length > 1; size: Theme.px(28); icon: Theme.icon.chevronLeft; fg: Theme.on_surface_variant; onClicked: root.flip(-1) }
        IconButton { visible: root.pages.length > 1; size: Theme.px(28); icon: Theme.icon.chevronRight; fg: Theme.on_surface_variant; onClicked: root.flip(1) }
    }

    // fixed height, so the cards below don't move as pages change
    Item {
        Layout.fillWidth: true
        implicitHeight: root.rows * root.rowHeight

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            visible: !!root.current

            Repeater {
                model: root.current?.binds ?? []

                RowLayout {
                    required property var modelData
                    width: parent.width
                    height: root.rowHeight
                    spacing: Theme.gap

                    StyledText { Layout.fillWidth: true; text: modelData.desc }

                    Row {
                        spacing: Theme.px(4)
                        Repeater {
                            model: modelData.keys
                            Rectangle {
                                required property string modelData
                                implicitWidth: Math.max(Theme.px(24), cap.implicitWidth + Theme.px(12))
                                implicitHeight: Theme.px(24)
                                radius: Theme.radiusTiny
                                color: Theme.layerHigh
                                StyledText {
                                    id: cap
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: Theme.fontSmall
                                    font.weight: Font.Medium
                                    color: Theme.on_surface_variant
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            visible: !root.current
            wrapMode: Text.WordWrap
            text: root.missing ? "No file at " + root.file.replace(Config.home, "~") : "No binds with a \"-- description\" in " + root.file.replace(Config.home, "~")
            color: Theme.on_surface_variant
            font.pixelSize: Theme.fontSmall
        }
    }
}
