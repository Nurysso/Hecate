import QtQuick
import Quickshell
import qs.config
import qs.components

Panel {
    id: root
    name: "power"

    Row {
        id: row
        property int current: 0
        readonly property var actions: [
            { id: "lock", label: "Lock", icon: Theme.icon.lock },
            { id: "suspend", label: "Suspend", icon: Theme.icon.suspend },
            { id: "exit", label: "Log out", icon: Theme.icon.logout },
            { id: "reboot", label: "Reboot", icon: Theme.icon.reboot },
            { id: "shutdown", label: "Shut down", icon: Theme.icon.power }
        ]

        function run(i) {
            GlobalStates.panel = ""
            Quickshell.execDetached([Config.home + "/.config/hypr/scripts/power.sh", actions[i].id])
        }

        spacing: Theme.gap * 1.5
        focus: true
        Keys.onLeftPressed: current = (current + actions.length - 1) % actions.length
        Keys.onRightPressed: current = (current + 1) % actions.length
        Keys.onReturnPressed: run(current)

        Repeater {
            model: row.actions

            Rectangle {
                id: btn
                required property var modelData
                required property int index
                readonly property bool active: row.current === index
                width: 112
                height: 128
                radius: active ? 48 : Theme.radius
                color: active ? root.accent : Theme.surface_container_high
                Behavior on radius { Anim {} }
                Behavior on color { CAnim {} }

                StateLayer {
                    tint: btn.active ? Theme.on_primary : Theme.on_surface
                    onClicked: row.run(btn.index)
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btn.modelData.icon
                        font.pixelSize: 36
                        color: btn.active ? Theme.on_primary : Theme.on_surface
                        scale: btn.active ? 1.1 : 1
                        Behavior on scale { Anim {} }
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btn.modelData.label
                        color: btn.active ? Theme.on_primary : Theme.on_surface_variant
                    }
                }
            }
        }
    }
}
