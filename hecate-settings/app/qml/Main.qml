import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import com.hecate.settings

ApplicationWindow {
    id: win
    width: 1100
    height: 720
    visible: true
    title: "Hecate Settings [BETA]"
    color: Theme.background

    property var all: []
    property var ignored: []
    property var binds: []
    property var curves: []
    property bool hooked: true
    property string error
    property string category
    readonly property var categories: [...new Set(all.map(s => s.category))]
    readonly property int page: search.text ? 0 : category === "Keybinds" ? 1 : category === "Curves" ? 2 : 0
    readonly property var shown: {
        const q = search.text.toLowerCase()
        return all.filter(s => q ? (s.name + " " + s.description).toLowerCase().includes(q) : s.category === category)
    }

    function reload() {
        const d = JSON.parse(backend.load())
        error = d.error ?? ""
        all = d.settings ?? []
        ignored = d.ignored ?? []
        binds = d.binds ?? []
        curves = d.curves ?? []
        hooked = d.hooked ?? true
        if (!category) category = categories[0] ?? ""
    }

    Backend { id: backend }
    Component.onCompleted: reload()

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: Theme.pad

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 240
            radius: Theme.radius
            color: Theme.surface_container
            border.color: Theme.outline_variant

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.pad
                spacing: Theme.gap

                StyledText {
                    text: "Hecate Settings"
                    color: Theme.primary
                    font.pixelSize: Theme.fontSize + 6
                    font.weight: Font.DemiBold
                    Layout.margins: Theme.gap
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: win.categories.concat(["Keybinds", "Curves"])

                    delegate: Rectangle {
                        id: pill
                        required property string modelData
                        readonly property bool active: !search.text && modelData === win.category
                        width: ListView.view.width
                        height: 44
                        radius: height / 2
                        color: active ? Theme.secondary_container : "transparent"
                        Behavior on color { CAnim {} }

                        StateLayer { onClicked: { search.text = ""; win.category = pill.modelData } }
                        StyledText {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.pad + 4
                            text: pill.modelData
                            color: pill.active ? Theme.on_secondary_container : Theme.on_surface_variant
                            font.weight: pill.active ? Font.Medium : Font.Normal
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.pad

            Field {
                id: search
                icon: "\u{f0349}"
                placeholderText: "Search all settings"
                Layout.fillWidth: true
                implicitHeight: 52
            }

            Rectangle {
                visible: win.error || !win.hooked
                Layout.fillWidth: true
                implicitHeight: banner.implicitHeight + Theme.pad * 2
                radius: Theme.radiusSmall
                color: win.error ? Theme.error_container : Theme.tertiary_container

                RowLayout {
                    id: banner
                    anchors.fill: parent
                    anchors.margins: Theme.pad

                    StyledText {
                        text: win.error || "Changes go to hecate_overrides.lua. Add it to hyprland.lua so they survive a reload."
                        color: win.error ? Theme.on_error_container : Theme.on_tertiary_container
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        visible: !win.error
                        implicitWidth: label.implicitWidth + Theme.pad * 2
                        implicitHeight: 36
                        radius: 18
                        color: Theme.tertiary
                        StateLayer { tint: Theme.on_tertiary; onClicked: { backend.hook(); win.reload() } }
                        StyledText {
                            id: label
                            anchors.centerIn: parent
                            text: "Add it"
                            color: Theme.on_tertiary
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: win.page

                ListView {
                    clip: true
                    spacing: Theme.gap
                    model: win.shown
                    boundsBehavior: Flickable.StopAtBounds
                    onModelChanged: Qt.callLater(positionViewAtBeginning)
                    ScrollBar.vertical: ScrollBar {
                        contentItem: Rectangle { implicitWidth: 6; radius: 3; color: Theme.outline_variant }
                    }

                    delegate: SettingRow {
                        width: ListView.view.width
                        mismatch: win.ignored.includes(modelData.name)
                        onEdited: v => backend.set(modelData.name, JSON.stringify(v))
                    }
                }

                KeybindsPage {
                    binds: win.binds
                    onSave: (old, bind) => {
                        backend.setBind(old, JSON.stringify(bind))
                        win.reload()
                    }
                }

                CurvesPage {
                    curves: win.curves
                    onSave: (name, def) => {
                        backend.setCurve(name, JSON.stringify(def))
                        win.reload()
                    }
                }
            }
        }
    }
}
