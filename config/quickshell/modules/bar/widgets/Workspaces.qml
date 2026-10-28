import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.components

Pill {
    id: root
    widget: "workspaces"
    readonly property var monitor: Hyprland.monitorFor(QsWindow.window?.screen)
    readonly property color accent: Config.color(widget, "color", Theme.primary)

    Repeater {
        model: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === root.monitor)

        Rectangle {
            required property HyprlandWorkspace modelData
            readonly property bool current: modelData.id === root.monitor?.activeWorkspace?.id
            anchors.verticalCenter: parent.verticalCenter
            width: current ? 32 : 12
            height: 12
            radius: 6
            color: current ? root.accent : modelData.urgent ? Theme.error : Theme.outline
            Behavior on width { Anim {} }
            Behavior on color { CAnim {} }

            // Hyprland's Lua config rejects the plain `workspace N` dispatch that activate() sends
            StateLayer { anchors.margins: -4; onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = "${parent.modelData.id}" })`) }
        }
    }
}
