import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Layouts
import com.hecate.settings

ScrollView {
    id: page
    property bool hooked
    signal hook

    readonly property var info: JSON.parse(sys.sysinfo())

    function gib(b) { return b ? (b / 1073741824).toFixed(1) + " GiB" : "Unknown" }

    Backend { id: sys }

    contentWidth: availableWidth

    component Card: Rectangle {
        default property alias content: inner.data
        implicitHeight: inner.implicitHeight + Theme.pad * 3
        radius: Theme.radius
        color: Theme.surface_container_low
        border.color: Theme.outline_variant

        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: Theme.pad * 1.5
            spacing: Theme.gap
        }
    }

    component Title: StyledText {
        color: Theme.primary
        font.weight: Font.DemiBold
        font.pixelSize: Theme.fontSize + 4
    }

    component Note: StyledText {
        color: Theme.on_surface_variant
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        Layout.fillWidth: true
    }

    component Wallpaper: Item {
        id: wall
        property real radius: Theme.radius
        property real dim

        Image {
            id: img
            anchors.fill: parent
            source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
            sourceSize.width: 1200
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        Rectangle {
            id: mask
            anchors.fill: parent
            radius: wall.radius
            layer.enabled: true
            visible: false
        }
        Rectangle {
            anchors.fill: parent
            radius: wall.radius
            color: Theme.surface_container_high
        }
        MultiEffect {
            anchors.fill: parent
            source: img
            maskEnabled: true
            maskSource: mask
            brightness: -wall.dim
            visible: img.status === Image.Ready
        }
    }

    component Chip: Rectangle {
        id: chip
        property string name
        property bool on
        signal picked
        implicitWidth: chipText.implicitWidth + Theme.pad * 1.5
        implicitHeight: 30
        radius: Math.min(height / 2, Theme.radiusSmall)
        color: on ? Theme.primary : Theme.surface_container_highest
        Accessible.role: Accessible.Button
        Accessible.name: name
        Behavior on color { CAnim {} }

        StateLayer { tint: chip.on ? Theme.on_primary : Theme.on_surface; onClicked: chip.picked() }
        StyledText {
            id: chipText
            anchors.centerIn: parent
            text: chip.name
            color: chip.on ? Theme.on_primary : Theme.on_surface
            font.pixelSize: Theme.fontSize - 1
        }
    }

    component LayoutCard: Card {
        id: editor
        property var backend
        property string section
        property var zones: []
        property bool vertical
        property string title
        property string hint
        property var layout: JSON.parse(backend.layout(section))
        property string selected
        property bool failed
        readonly property var hidden: layout.available.filter(n => !zones.some(z => layout[z].includes(n)))

        function save(next) {
            failed = !backend.setLayout(section, JSON.stringify(next))
            if (!failed) layout = Object.assign({}, layout, next)
        }

        function relocate(place) {
            const zs = zones.map(z => layout[z].slice())
            const from = zs.findIndex(a => a.includes(selected))
            if (from < 0) return
            const i = zs[from].indexOf(selected)
            zs[from].splice(i, 1)
            const to = place(zs, from, i)
            zs[to[0]].splice(Math.max(0, Math.min(to[1], zs[to[0]].length)), 0, selected)
            const next = {}
            zones.forEach((z, k) => next[z] = zs[k])
            save(next)
        }

        function move(d) {
            relocate((zs, z, i) => {
                i += d
                if (vertical) return [z, i]
                if (i < 0 && z > 0) return [z - 1, zs[z - 1].length]
                if (i > zs[z].length && z < zs.length - 1) return [z + 1, 0]
                return [z, i]
            })
        }

        function shift(d) {
            relocate((zs, z, i) => {
                const t = Math.max(0, Math.min(z + d, zs.length - 1))
                return [t, t === z ? i : zs[t].length]
            })
        }

        function hide() {
            const next = {}
            zones.forEach(z => next[z] = layout[z].filter(n => n !== selected))
            save(next)
            selected = ""
        }

        function add(name) {
            const last = zones[zones.length - 1]
            const next = {}
            next[last] = layout[last].concat([name])
            save(next)
            selected = name
        }

        Title { text: editor.title }
        Note { text: editor.hint }

        Item {
            Layout.fillWidth: true
            Layout.topMargin: Theme.gap
            implicitHeight: Math.max(stage.implicitHeight + Theme.pad * 2, editor.vertical ? 220 : 0)

            Wallpaper {
                anchors.fill: parent
                visible: editor.vertical
                radius: Theme.radiusSmall
                dim: 0.35
            }
            Rectangle {
                anchors.fill: parent
                visible: !editor.vertical
                radius: Theme.radiusSmall
                color: Theme.surface_container
            }

            RowLayout {
                id: stage
                readonly property real column: 150
                anchors.fill: parent
                anchors.margins: Theme.pad
                spacing: editor.vertical ? Math.max(Theme.pad, width - column * editor.zones.length) : Theme.pad

                Repeater {
                    model: editor.zones

                    ColumnLayout {
                        id: zone
                        required property string modelData
                        Layout.fillWidth: !editor.vertical
                        Layout.preferredWidth: editor.vertical ? stage.column : 0
                        Layout.horizontalStretchFactor: editor.vertical ? -1 : Math.max(1, editor.layout[modelData].length)
                        Layout.alignment: Qt.AlignTop
                        spacing: 4

                        StyledText {
                            text: zone.modelData
                            color: editor.vertical ? "white" : Theme.on_surface_variant
                            font.pixelSize: Theme.fontSize - 3
                        }
                        Flow {
                            id: flow
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: editor.layout[zone.modelData]

                                Chip {
                                    required property string modelData
                                    width: editor.vertical ? flow.width : implicitWidth
                                    implicitHeight: editor.vertical ? 40 : 30
                                    name: modelData
                                    on: editor.selected === modelData
                                    onPicked: editor.selected = on ? "" : modelData
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap

            StyledText {
                Layout.fillWidth: true
                text: editor.failed ? "Couldn't write hecate.toml" : editor.selected || "No widget selected"
                color: editor.failed ? Theme.error : Theme.on_surface_variant
            }
            Repeater {
                model: editor.vertical
                    ? [["\u{f0141}", "Move to left column", () => editor.shift(-1)], ["\u{f0143}", "Move up", () => editor.move(-1)],
                       ["\u{f0140}", "Move down", () => editor.move(1)], ["\u{f0142}", "Move to right column", () => editor.shift(1)]]
                    : [["\u{f0141}", "Move left", () => editor.move(-1)], ["\u{f0142}", "Move right", () => editor.move(1)]]

                PillButton {
                    required property var modelData
                    icon: modelData[0]
                    enabled: editor.selected !== ""
                    color: Theme.surface_container_highest
                    fg: Theme.on_surface
                    Accessible.name: modelData[1]
                    onClicked: modelData[2]()
                }
            }
            PillButton {
                text: "Hide"
                enabled: editor.selected !== ""
                color: Theme.surface_container_highest
                fg: Theme.on_surface
                onClicked: editor.hide()
            }
        }

        StyledText {
            visible: editor.hidden.length > 0
            text: "Hidden, click to add"
            color: Theme.on_surface_variant
            font.pixelSize: Theme.fontSize - 2
            Layout.topMargin: Theme.gap
        }
        Flow {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: editor.hidden

                Chip {
                    required property string modelData
                    name: modelData
                    onPicked: editor.add(modelData)
                }
            }
        }
    }

    ColumnLayout {
        width: page.availableWidth
        spacing: Theme.pad

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(220, width * 0.3)

            Wallpaper { anchors.fill: parent }
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                gradient: Gradient {
                    GradientStop { position: 0.3; color: "transparent" }
                    GradientStop { position: 1; color: Theme.alpha(Theme.scrim, 0.75) }
                }
            }

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Theme.pad * 1.5
                spacing: Theme.pad

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.gap

                    StyledText {
                        text: "Hecate Settings"
                        color: "white"
                        font.pixelSize: Theme.fontSize + 14
                        font.weight: Font.DemiBold
                    }
                    RowLayout {
                        spacing: Theme.gap

                        Rectangle {
                            implicitWidth: 10
                            implicitHeight: 10
                            radius: 5
                            color: page.hooked ? Theme.primary : Theme.tertiary
                        }
                        StyledText {
                            text: page.hooked ? "Overrides active" : "Overrides not loaded, applied changes won't survive a reload"
                            color: "white"
                        }
                        PillButton {
                            visible: !page.hooked
                            text: "Add it"
                            color: Theme.tertiary
                            fg: Theme.on_tertiary
                            onClicked: page.hook()
                        }
                    }
                }
                PillButton {
                    icon: "\u{f02e9}"
                    text: "Change wallpaper"
                    Layout.alignment: Qt.AlignBottom
                    onClicked: sys.openWallpaper()
                }
            }
        }

        Card {
            Layout.fillWidth: true

            Title { text: "System" }

            GridLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.gap
                columns: width > 640 ? 3 : 2
                columnSpacing: Theme.gap
                rowSpacing: Theme.gap

                Repeater {
                    model: [
                        ["OS", page.info.os], ["Kernel", page.info.kernel], ["Hyprland", page.info.hyprland],
                        ["Hecate", page.info.hecate], ["Memory", page.gib(page.info.ram)], ["Disk (/)", page.gib(page.info.disk)]
                    ]

                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        implicitHeight: tile.implicitHeight + Theme.pad * 1.5
                        radius: Theme.radiusSmall
                        color: Theme.surface_container

                        ColumnLayout {
                            id: tile
                            anchors.fill: parent
                            anchors.margins: Theme.pad * 0.75
                            anchors.leftMargin: Theme.pad
                            spacing: 2

                            StyledText {
                                text: parent.parent.modelData[0]
                                color: Theme.on_surface_variant
                                font.pixelSize: Theme.fontSize - 2
                            }
                            StyledText {
                                text: parent.parent.modelData[1] || "Unknown"
                                font.pixelSize: Theme.fontSize + 1
                                font.weight: Font.Medium
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        LayoutCard {
            Layout.fillWidth: true
            backend: sys
            section: "bar"
            zones: ["left", "center", "right"]
            title: "Bar"
            hint: "Click a widget to move or hide it. The bar picks up changes right away."
        }

        LayoutCard {
            Layout.fillWidth: true
            backend: sys
            section: "desktop"
            zones: ["left", "right"]
            vertical: true
            title: "Desktop widgets"
            hint: "Cards on your wallpaper, stacked top to bottom in two columns."
        }
    }
}
