import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components

// Session menu over the whole screen. Arrows (or the mouse) pick, Enter confirms, Esc or a click
// on the backdrop cancels. Actions run ~/.config/hypr/scripts/power.sh.
Panel {
    id: root
    name: "power"
    kind: "fullscreen"
    padded: false

    ColumnLayout {
        id: menu
        spacing: Theme.px(36)
        property int current: 0
        property real uptime
        readonly property var actions: [
            { id: "lock", label: "Lock", icon: Theme.icon.lock },
            { id: "suspend", label: "Suspend", icon: Theme.icon.suspend },
            { id: "exit", label: "Log out", icon: Theme.icon.logout },
            { id: "reboot", label: "Restart", icon: Theme.icon.reboot },
            { id: "shutdown", label: "Shut down", icon: Theme.icon.power }
        ]

        function run(i) {
            GlobalStates.close()
            Quickshell.execDetached([Config.home + "/.config/hypr/scripts/power.sh", actions[i].id])
        }

        focus: true
        Keys.onLeftPressed: current = (current + actions.length - 1) % actions.length
        Keys.onRightPressed: current = (current + 1) % actions.length
        Keys.onTabPressed: current = (current + 1) % actions.length
        Keys.onReturnPressed: run(current)
        Keys.onEnterPressed: run(current)

        FileView { path: "/proc/uptime"; onLoaded: menu.uptime = parseFloat(text()) }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.px(6)
            Avatar { Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: Theme.px(10); size: Theme.px(92) }
            StyledText { Layout.alignment: Qt.AlignHCenter; text: Quickshell.env("USER"); font.pixelSize: Theme.fontTitle + 4; font.weight: Font.DemiBold }
            StyledText {
                readonly property int mins: Math.floor(menu.uptime / 60)
                Layout.alignment: Qt.AlignHCenter
                text: "Up for " + (mins >= 1440 ? Math.floor(mins / 1440) + "d " : "") + Math.floor(mins % 1440 / 60) + "h " + mins % 60 + "m"
                color: Theme.on_surface_variant
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.px(20)

            Repeater {
                model: menu.actions

                Column {
                    id: action
                    required property var modelData
                    required property int index
                    readonly property bool active: menu.current === index
                    spacing: Theme.px(12)

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Theme.px(96)
                        height: width
                        radius: action.active ? Theme.px(32) : width / 2
                        color: action.active ? root.accent : Theme.alpha(Theme.on_surface, 0.1)
                        border.width: action.active ? 0 : 1
                        border.color: Theme.hairline
                        Behavior on radius { Anim {} }
                        Behavior on color { CAnim {} }

                        Icon {
                            anchors.centerIn: parent
                            text: action.modelData.icon
                            font.pixelSize: Theme.px(36)
                            color: action.active ? Theme.contrast(root.accent) : Theme.on_surface
                            scale: action.active ? 1.08 : 1
                            Behavior on scale { Anim {} }
                        }

                        StateLayer {
                            tint: action.active ? Theme.contrast(root.accent) : Theme.on_surface
                            onContainsMouseChanged: if (containsMouse) menu.current = action.index
                            onClicked: menu.run(action.index)
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: action.modelData.label
                        color: action.active ? Theme.on_surface : Theme.on_surface_variant
                        font.weight: action.active ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }

        Hints {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.px(8)
            keys: [["←→", "choose"], ["↵", "confirm"], ["esc", "cancel"]]
        }
    }
}
