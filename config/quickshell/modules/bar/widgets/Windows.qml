import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.components

// Open windows: click focuses, middle-click closes, scroll cycles.
Pill {
    id: root
    widget: "windows"
    interactive: false
    spacing: Theme.px(2)
    padding: Theme.px(2)

    readonly property string scope: cfg.scope ?? "workspace"   // "workspace", "monitor" or "all"
    readonly property string titles: cfg.titles ?? "active"    // "none", "active" or "all"
    readonly property int maxTitle: cfg.max_title ?? 24
    readonly property color accent: Config.color(widget, "color", Theme.primary)
    readonly property var monitor: Hyprland.monitorFor(QsWindow.window?.screen)
    function inScope(t) {
        return !!t.wayland && (scope === "all" ? true
            : scope === "monitor" ? t.monitor === monitor
            : t.workspace?.id === monitor?.activeWorkspace?.id)
    }
    readonly property var windows: Hyprland.toplevels.values.filter(inScope)

    visible: windows.length > 0
    Component.onCompleted: Hyprland.refreshToplevels()

    function cycle(step) {
        const i = windows.findIndex(t => t.wayland.activated)
        windows[(i + step + windows.length) % windows.length].wayland.activate()
    }

    WheelHandler { onWheel: e => root.cycle(e.angleDelta.y > 0 ? -1 : 1) }

    Repeater {
        // Every toplevel keeps its delegate so windows grow in and shrink out instead of popping
        model: Hyprland.toplevels

        Rectangle {
            id: win
            required property HyprlandToplevel modelData
            readonly property bool active: modelData.wayland?.activated ?? false
            readonly property string appId: modelData.wayland?.appId ?? ""
            readonly property bool shown: root.inScope(modelData)
            property real grow: shown ? 1 : 0
            Behavior on grow { Anim {} }
            readonly property bool showTitle: root.titles === "all" || root.titles === "active" && active || hover.containsMouse
            readonly property string title: modelData.title.length > root.maxTitle ? modelData.title.slice(0, root.maxTitle - 1) + "…" : modelData.title

            anchors.verticalCenter: parent.verticalCenter
            visible: grow > 0.01
            opacity: grow
            clip: true
            implicitWidth: (row.implicitWidth + Theme.px(14)) * grow
            implicitHeight: root.height - Theme.px(8)
            radius: Math.min(height / 2, Theme.radiusTiny * 1.5)
            color: active ? Theme.alpha(root.accent, 0.16) : "transparent"
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

                AppIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    app: win.appId
                    implicitSize: Theme.px(18)
                }
                Item {
                    // Title slides out of the icon on hover (or when titles asks for it)
                    id: reveal
                    property real amount: win.showTitle ? 1 : 0
                    Behavior on amount { Anim {} }
                    anchors.verticalCenter: parent.verticalCenter
                    width: (label.implicitWidth + Theme.px(7)) * amount
                    height: label.implicitHeight
                    clip: true
                    visible: amount > 0.01

                    StyledText {
                        id: label
                        x: Theme.px(7)
                        opacity: reveal.amount
                        text: win.title
                        color: win.active ? root.accent : root.fg
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: win.active ? Font.DemiBold : Font.Normal
                    }
                }
            }

            // Urgent windows get a dot
            Rectangle {
                visible: win.modelData.urgent
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Theme.px(2)
                width: Theme.px(7)
                height: width
                radius: width / 2
                color: Theme.error
            }
        }
    }
}
