import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import com.hecate.settings

ApplicationWindow {
    id: win
    width: 1100
    height: 720
    minimumWidth: 900
    minimumHeight: 600
    visible: true
    title: "Hecate Settings [BETA]"
    color: Theme.background

    property var all: []
    property var ignored: []
    property var binds: []
    property var curves: []
    property bool hooked: true
    property string error
    property string tab: "Home"
    readonly property var tabs: ["Home", "Decoration", "Animation", "Keybinds", "Monitors", "Connectivity"]
    readonly property var groups: [
        { title: "Rounding", keys: ["decoration.rounding", "decoration.rounding_power"] },
        { title: "Gaps", keys: ["general.gaps_in", "general.gaps_out", "general.gaps_workspaces"] },
        { title: "Borders", keys: ["general.border_size", "general.col.active_border", "general.col.inactive_border"] },
        { title: "Opacity", keys: ["decoration.active_opacity", "decoration.inactive_opacity"] },
        { title: "Blur & Shadows", keys: [
            "decoration.blur.enabled", "decoration.blur.size", "decoration.blur.passes", "decoration.blur.vibrancy",
            "decoration.shadow.enabled", "decoration.shadow.range", "decoration.shadow.render_power", "decoration.shadow.color"
        ] }
    ]
    readonly property var found: {
        const q = search.text.toLowerCase()
        return q ? all.filter(s => (s.name + " " + s.description).toLowerCase().includes(q)) : []
    }

    function reload() {
        const d = JSON.parse(backend.load())
        error = d.error ?? ""
        all = d.settings ?? []
        ignored = d.ignored ?? []
        binds = d.binds ?? []
        curves = d.curves ?? []
        hooked = d.hooked ?? true
    }

    Backend { id: backend }
    Component.onCompleted: reload()

    onClosing: close => {
        if (!backend.isDirty) return
        close.accepted = false
        discard.open()
    }

    Dialog {
        id: discard
        anchors.centerIn: parent
        modal: true
        padding: Theme.pad * 1.5
        background: Rectangle { radius: Theme.radius; color: Theme.surface_container_high; border.color: Theme.outline_variant }

        contentItem: ColumnLayout {
            spacing: Theme.pad

            StyledText { text: "You have unsaved changes. Discard them?" }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Theme.gap

                PillButton {
                    text: "Cancel"
                    color: Theme.surface_container_highest
                    fg: Theme.on_surface
                    onClicked: discard.close()
                }
                PillButton {
                    text: "Discard"
                    color: Theme.error
                    fg: Theme.on_error
                    onClicked: { backend.revert(); win.close() }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: Theme.pad

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.pad

            StyledText {
                text: "Hecate Settings"
                color: Theme.primary
                font.pixelSize: Theme.fontSize + 6
                font.weight: Font.DemiBold
                Layout.preferredWidth: 200
                leftPadding: Theme.pad
            }
            Field {
                id: search
                icon: "\u{f0349}"
                placeholderText: "Search everything…"
                Layout.fillWidth: true
                implicitHeight: 52
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.pad

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 200
                radius: Theme.radius
                color: Theme.surface_container
                border.color: Theme.outline_variant

                ListView {
                    anchors.fill: parent
                    anchors.margins: Theme.pad
                    spacing: 4
                    interactive: false
                    model: win.tabs

                    delegate: Rectangle {
                        id: pill
                        required property string modelData
                        readonly property bool active: !search.text && modelData === win.tab
                        width: ListView.view.width
                        height: 44
                        radius: height / 2
                        color: active ? Theme.secondary_container : "transparent"
                        Behavior on color { CAnim {} }

                        StateLayer { onClicked: { search.text = ""; win.tab = pill.modelData } }
                        Rectangle {
                            visible: pill.active
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 4
                            height: 20
                            radius: 2
                            color: Theme.primary
                        }
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

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.pad

                Rectangle {
                    visible: win.error !== ""
                    Layout.fillWidth: true
                    implicitHeight: errorText.implicitHeight + Theme.pad * 2
                    radius: Theme.radiusSmall
                    color: Theme.error_container

                    StyledText {
                        id: errorText
                        anchors.fill: parent
                        anchors.margins: Theme.pad
                        text: win.error
                        color: Theme.on_error_container
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: search.text ? win.tabs.length : win.tabs.indexOf(win.tab)

                    HomePage {
                        hooked: win.hooked
                        onHook: { backend.hook(); win.reload() }
                    }

                    ListView {
                        clip: true
                        spacing: Theme.pad
                        model: win.groups
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {
                            contentItem: Rectangle { implicitWidth: 6; radius: 3; color: Theme.outline_variant }
                        }

                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            width: ListView.view.width
                            implicitHeight: rows.implicitHeight + Theme.pad * 3
                            radius: Theme.radius
                            color: Theme.surface_container_low
                            border.color: Theme.outline_variant

                            ColumnLayout {
                                id: rows
                                anchors.fill: parent
                                anchors.margins: Theme.pad * 1.5
                                spacing: Theme.gap

                                StyledText {
                                    text: card.modelData.title
                                    color: Theme.primary
                                    font.weight: Font.DemiBold
                                    font.pixelSize: Theme.fontSize + 4
                                    bottomPadding: Theme.gap
                                }
                                Repeater {
                                    model: card.modelData.keys.map(k => win.all.find(s => s.name === k)).filter(s => s)

                                    SettingRow {
                                        Layout.fillWidth: true
                                        mismatch: win.ignored.includes(modelData.name)
                                        onEdited: v => backend.set(modelData.name, JSON.stringify(v))
                                    }
                                }
                            }
                        }
                    }

                    CurvesPage {
                        curves: win.curves
                        onSave: (name, def) => {
                            backend.setCurve(name, JSON.stringify(def))
                            win.reload()
                        }
                    }

                    KeybindsPage {
                        binds: win.binds
                        onSave: (old, bind) => {
                            backend.setBind(old, JSON.stringify(bind))
                            win.reload()
                        }
                    }

                    MonitorsPage {}

                    ConnectivityPage {}

                    ListView {
                        clip: true
                        spacing: Theme.gap
                        model: win.found
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
                }

                Rectangle {
                    visible: backend.isDirty
                    Layout.fillWidth: true
                    implicitHeight: actions.implicitHeight + Theme.pad * 2
                    radius: Theme.radius
                    color: Theme.surface_container_high
                    border.color: Theme.outline_variant

                    RowLayout {
                        id: actions
                        anchors.fill: parent
                        anchors.margins: Theme.pad
                        spacing: Theme.gap

                        StyledText {
                            Layout.fillWidth: true
                            text: "Unsaved changes"
                        }
                        PillButton {
                            text: "Revert"
                            color: Theme.surface_container_highest
                            fg: Theme.on_surface
                            onClicked: { backend.revert(); win.reload() }
                        }
                        PillButton {
                            text: "Apply"
                            onClicked: backend.apply()
                        }
                    }
                }
            }
        }
    }
}
