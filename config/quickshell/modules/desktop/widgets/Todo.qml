import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components

// A checklist kept in a plain markdown file ("- [ ] task" / "- [x] task"), so you can edit it by hand
// too: changes to the file show up here at once. Click a task to tick it, type in the field and press
// Enter to add one.
// [desktop.todo] file, max (tasks shown)
Card {
    id: root
    widget: "todo"

    readonly property string file: Config.expand(cfg.file ?? "~/.local/share/hecate/todo.md")
    readonly property int max: Math.max(1, Math.min(30, Number(cfg.max ?? 8) || 8))
    property var items: []   // [{ done, text }] in file order

    readonly property int remaining: items.filter(i => !i.done).length
    readonly property int finished: items.length - remaining
    // open tasks first, each keeping its place in the file
    readonly property var ordered: items.map((it, i) => ({ done: it.done, text: it.text, i: i })).sort((a, b) => (a.done - b.done) || (a.i - b.i))

    function parse(src) {
        const out = []
        for (const line of src.split("\n")) {
            const m = line.match(/^\s*[-*]\s*\[([ xX])\]\s*(.+?)\s*$/)
            if (m) out.push({ done: m[1] !== " ", text: m[2] })
        }
        return out
    }
    function commit(list) {
        items = list
        store.setText(list.map(i => `- [${i.done ? "x" : " "}] ${i.text}`).join("\n") + "\n")
    }
    function add(text) {
        text = text.replace(/\s+/g, " ").trim()
        if (text) commit([...items, { done: false, text: text }])
    }
    function toggle(i) { commit(items.map((it, j) => j === i ? { done: !it.done, text: it.text } : it)) }
    function remove(i) { commit(items.filter((_, j) => j !== i)) }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", file.slice(0, file.lastIndexOf("/"))])

    FileView {
        id: store
        path: root.file
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.items = root.parse(text())
        onLoadFailed: root.items = []
    }

    CardHeader {
        icon: Theme.icon.check
        title: "Todo"
        accent: root.accent
        StyledText {
            visible: root.items.length > 0
            text: root.remaining ? root.remaining + " left" : "all done"
            color: Theme.on_surface_variant
            font.pixelSize: Theme.fontSmall
        }
        IconButton {
            visible: root.finished > 0
            size: Theme.px(28)
            icon: Theme.icon.clearAll
            fg: Theme.on_surface_variant
            onClicked: root.commit(root.items.filter(i => !i.done))
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.px(2)

        Repeater {
            model: root.ordered.slice(0, root.max)

            Item {
                id: row
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Theme.px(36)

                HoverHandler { id: hover }
                StateLayer { radius: Theme.radiusSmall; onClicked: root.toggle(row.modelData.i) }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.px(8)
                    anchors.rightMargin: Theme.px(4)
                    spacing: Theme.px(10)

                    Rectangle {
                        implicitWidth: Theme.px(20)
                        implicitHeight: Theme.px(20)
                        radius: width / 2
                        color: row.modelData.done ? root.accent : "transparent"
                        border.width: row.modelData.done ? 0 : Math.max(1, Theme.px(2))
                        border.color: Theme.outline
                        Behavior on color { CAnim {} }
                        Icon {
                            anchors.centerIn: parent
                            visible: row.modelData.done
                            text: Theme.icon.check
                            color: Theme.contrast(root.accent)
                            font.pixelSize: Theme.px(13)
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.text
                        font.strikeout: row.modelData.done
                        color: row.modelData.done ? Theme.on_surface_variant : Theme.on_surface
                    }

                    IconButton {
                        size: Theme.px(28)
                        icon: Theme.icon.close
                        fg: Theme.on_surface_variant
                        opacity: hover.hovered ? 1 : 0
                        onClicked: root.remove(row.modelData.i)
                    }
                }
            }
        }

        StyledText {
            visible: root.items.length > root.max
            text: `+ ${root.items.length - root.max} more in ${root.file.replace(Config.home, "~")}`
            color: Theme.on_surface_variant
            font.pixelSize: Theme.fontSmall
            Layout.leftMargin: Theme.px(8)
        }
        StyledText {
            visible: root.items.length === 0
            text: "Nothing to do"
            color: Theme.on_surface_variant
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.px(6)
            Layout.bottomMargin: Theme.px(6)
        }
    }

    SearchField {
        Layout.fillWidth: true
        implicitHeight: Theme.px(40)
        font.pixelSize: Theme.fontSize
        icon: Theme.icon.plus
        placeholderText: "Add a task"
        onAccepted: { root.add(text); text = "" }
        Keys.onEscapePressed: focus = false
    }
}
