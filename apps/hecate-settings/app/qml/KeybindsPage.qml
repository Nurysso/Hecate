import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import com.hecate.settings

ColumnLayout {
    id: page
    property var binds: []
    signal save(string old, var bind)

    property var editing: null
    property var mods: []
    property string key
    readonly property var modNames: ["SUPER", "SHIFT", "CTRL", "ALT"]
    readonly property string keys: mods.concat(key ? [key] : []).join(" + ")
    readonly property bool conflict: key !== "" && binds.some(b => b.keys.toLowerCase() === keys.toLowerCase() && b.keys !== editing?.keys)
    readonly property var sorted: {
        const order = {}
        binds.forEach((b, i) => { if (!(b.section in order)) order[b.section] = i })
        return binds.slice().sort((a, b) => order[a.section] - order[b.section])
    }

    function action(d) {
        if (!d) return "Lua function"
        return d.path + " " + d.args.map(a => typeof a === "string" ? a : JSON.stringify(a)).join(" ")
    }

    // shortcut: only these keys are recognised, add Qt.Key_* names here as needed
    function keyName(e) {
        const named = {
            [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "Return", [Qt.Key_Tab]: "Tab", [Qt.Key_Space]: "Space",
            [Qt.Key_Print]: "Print", [Qt.Key_Escape]: "Escape", [Qt.Key_Delete]: "Delete", [Qt.Key_Backspace]: "BackSpace",
            [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Up]: "up", [Qt.Key_Down]: "down",
            [Qt.Key_BracketLeft]: "bracketleft", [Qt.Key_BracketRight]: "bracketright",
            [Qt.Key_Comma]: "comma", [Qt.Key_Period]: "period", [Qt.Key_Slash]: "slash", [Qt.Key_Minus]: "minus", [Qt.Key_Equal]: "equal"
        }
        if (named[e.key]) return named[e.key]
        if (e.key >= Qt.Key_F1 && e.key <= Qt.Key_F12) return "F" + (e.key - Qt.Key_F1 + 1)
        if ((e.key >= Qt.Key_A && e.key <= Qt.Key_Z) || (e.key >= Qt.Key_0 && e.key <= Qt.Key_9)) return String.fromCharCode(e.key)
        return ""
    }

    function edit(b) {
        const parts = b.keys.split(" + ")
        editing = b
        key = parts.pop()
        mods = parts.map(p => p.toUpperCase())
        command.text = b.dispatcher.path === "exec_cmd" ? b.dispatcher.args[0] ?? "" : ""
    }

    function reset() {
        editing = null
        mods = []
        key = ""
        command.text = ""
    }

    function submit() {
        const base = editing ?? { section: "Custom", description: "", opts: null }
        const dispatcher = command.text ? { path: "exec_cmd", args: [command.text] } : base.dispatcher
        save(editing?.keys ?? "", Object.assign({}, base, { keys, dispatcher }))
        reset()
    }

    spacing: Theme.pad

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: form.implicitHeight + Theme.pad * 2
        radius: Theme.radius
        color: Theme.surface_container
        border.color: page.editing ? Theme.primary : Theme.outline_variant
        Behavior on border.color { CAnim {} }

        ColumnLayout {
            id: form
            anchors.fill: parent
            anchors.margins: Theme.pad
            spacing: Theme.gap * 1.5

            StyledText {
                text: page.editing ? "Edit " + page.editing.keys : "New keybind"
                font.weight: Font.Medium
                font.pixelSize: Theme.fontSize + 2
            }

            Flow {
                Layout.fillWidth: true
                spacing: Theme.gap

                Repeater {
                    model: page.modNames

                    PillButton {
                        required property string modelData
                        readonly property bool on: page.mods.includes(modelData)
                        text: modelData
                        color: on ? Theme.secondary_container : Theme.surface_container_highest
                        fg: on ? Theme.on_secondary_container : Theme.on_surface_variant
                        onClicked: page.mods = on ? page.mods.filter(m => m !== modelData) : page.modNames.filter(m => m === modelData || page.mods.includes(m))
                    }
                }

                Field {
                    width: 220
                    implicitHeight: 36
                    readOnly: true
                    text: page.key
                    placeholderText: activeFocus ? "Press a key…" : "Click, then press a key"
                    invalid: page.conflict
                    Accessible.name: "Key"
                    Keys.onPressed: e => {
                        const k = page.keyName(e)
                        if (k) {
                            page.key = k
                            e.accepted = true
                        }
                    }
                }
            }

            Field {
                id: command
                Layout.fillWidth: true
                placeholderText: page.editing && page.editing.dispatcher.path !== "exec_cmd"
                    ? "Shell command, or leave empty to keep " + page.action(page.editing.dispatcher)
                    : "Shell command, e.g. kitty"
                Accessible.name: "Command"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.gap

                StyledText {
                    Layout.fillWidth: true
                    text: page.conflict ? page.keys + " is already bound" : page.keys
                    color: page.conflict ? Theme.error : Theme.on_surface_variant
                }
                PillButton {
                    visible: page.editing !== null
                    text: "Cancel"
                    color: Theme.surface_container_highest
                    fg: Theme.on_surface
                    onClicked: page.reset()
                }
                PillButton {
                    text: page.editing ? "Save" : "Add"
                    enabled: page.key !== "" && (command.text !== "" || page.editing !== null)
                    onClicked: page.submit()
                }
            }
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Theme.gap
        model: page.sorted
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            contentItem: Rectangle { implicitWidth: 6; radius: 3; color: Theme.outline_variant }
        }

        delegate: Column {
            id: entry
            required property var modelData
            required property int index
            width: ListView.view.width
            spacing: Theme.gap

            StyledText {
                visible: entry.index === 0 || page.sorted[entry.index - 1].section !== entry.modelData.section
                text: entry.modelData.section || "Other"
                color: Theme.primary
                font.weight: Font.Medium
                topPadding: entry.index === 0 ? 0 : Theme.pad
                leftPadding: Theme.gap
            }

            Rectangle {
                width: parent.width
                implicitHeight: row.implicitHeight + Theme.pad * 2
                radius: Theme.radiusSmall
                color: page.editing?.keys === entry.modelData.keys ? Theme.secondary_container : Theme.surface_container
                Behavior on color { CAnim {} }

                RowLayout {
                    id: row
                    anchors.fill: parent
                    anchors.margins: Theme.pad
                    spacing: Theme.pad

                    Flow {
                        Layout.preferredWidth: 280
                        spacing: 4

                        Repeater {
                            model: entry.modelData.keys.split(" + ")

                            Rectangle {
                                required property string modelData
                                implicitWidth: cap.implicitWidth + Theme.pad
                                implicitHeight: 28
                                radius: 8
                                color: Theme.surface_container_highest
                                border.color: Theme.outline_variant

                                StyledText {
                                    id: cap
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    font.pixelSize: Theme.fontSize - 2
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: entry.modelData.description || page.action(entry.modelData.dispatcher)
                        }
                        StyledText {
                            Layout.fillWidth: true
                            visible: entry.modelData.description !== ""
                            text: page.action(entry.modelData.dispatcher)
                            color: Theme.on_surface_variant
                            font.pixelSize: Theme.fontSize - 2
                        }
                        StyledText {
                            visible: entry.modelData.dynamic
                            text: "Set by a script, edit it in your config"
                            color: Theme.tertiary
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }

                    PillButton {
                        visible: !entry.modelData.dynamic
                        icon: "\u{f03eb}"
                        color: "transparent"
                        fg: Theme.on_surface_variant
                        Accessible.name: "Edit " + entry.modelData.keys
                        onClicked: page.edit(entry.modelData)
                    }
                    PillButton {
                        visible: !entry.modelData.dynamic
                        icon: "\u{f09e7}"
                        color: "transparent"
                        fg: Theme.error
                        Accessible.name: "Delete " + entry.modelData.keys
                        onClicked: page.save(entry.modelData.keys, null)
                    }
                }
            }
        }
    }
}
