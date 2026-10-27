import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.components

// Open windows: click focuses, middle-click closes, scroll cycles.
Pill {
    id: root
    widget: "windows"
    readonly property var cfg: Config.widget(widget)
    readonly property string scope: cfg.scope ?? "workspace"   // "workspace", "monitor" or "all"
    readonly property string titles: cfg.titles ?? "active"    // "none", "active" or "all"
    readonly property int maxTitle: cfg.max_title ?? 24
    readonly property color accent: Config.color(widget, "color", Theme.primary)
    readonly property var monitor: Hyprland.monitorFor(QsWindow.window?.screen)
    readonly property var windows: Hyprland.toplevels.values.filter(t => t.wayland && (
        scope === "all" ? true
        : scope === "monitor" ? t.monitor === monitor
        : t.workspace?.id === monitor?.activeWorkspace?.id))

    visible: windows.length > 0
    Component.onCompleted: Hyprland.refreshToplevels()

    function cycle(step) {
        const i = windows.findIndex(t => t.wayland.activated)
        windows[(i + step + windows.length) % windows.length].wayland.activate()
    }

    WheelHandler { onWheel: e => root.cycle(e.angleDelta.y > 0 ? -1 : 1) }

    Repeater {
        model: root.windows

        Rectangle {
            id: win
            required property HyprlandToplevel modelData
            readonly property bool active: modelData.wayland?.activated ?? false
            readonly property string appId: modelData.wayland?.appId ?? ""
            readonly property string iconPath: Quickshell.iconPath(DesktopEntries.heuristicLookup(appId)?.icon ?? appId, true)
            readonly property bool showTitle: root.titles === "all" || root.titles === "active" && active || hover.containsMouse
            readonly property string title: modelData.title.length > root.maxTitle ? modelData.title.slice(0, root.maxTitle - 1) + "…" : modelData.title

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: row.implicitWidth + 16
            implicitHeight: 28
            radius: height / 2
            color: active ? Theme.alpha(root.accent, 0.18) : "transparent"
            Behavior on implicitWidth { Anim {} }
            Behavior on color { CAnim {} }

            StateLayer {
                id: hover
                tint: root.accent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: e => e.button === Qt.MiddleButton ? win.modelData.wayland.close() : win.modelData.wayland.activate()
            }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 6

                IconImage { visible: win.iconPath; source: win.iconPath; implicitSize: 18; anchors.verticalCenter: parent.verticalCenter }
                Icon { visible: !win.iconPath; text: Theme.icon.apps; color: root.fg; anchors.verticalCenter: parent.verticalCenter }
                StyledText {
                    visible: win.showTitle
                    text: win.title
                    color: win.active ? root.accent : root.fg
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: win.active ? Font.Medium : Font.Normal
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Urgent windows get a dot
            Rectangle {
                visible: win.modelData.urgent
                anchors.top: parent.top
                anchors.right: parent.right
                width: 6
                height: 6
                radius: 3
                color: Theme.error
            }
        }
    }
}
