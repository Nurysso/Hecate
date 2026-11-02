import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services

// Workspaces on this bar's monitor: click to switch, scroll to step through them.
// [widgets.workspaces] style = "dots", "numbers" or "icons" (each workspace's apps); count = N keeps
// 1..N shown even when empty; special = false hides the marker for an open special workspace.
Pill {
    id: root
    widget: "workspaces"
    interactive: false
    spacing: style === "dots" ? 0 : Theme.px(2)
    padding: Theme.px(6)

    readonly property var monitor: Hyprland.monitorFor(QsWindow.window?.screen)
    readonly property string style: ["dots", "numbers", "icons"].includes(cfg.style) ? cfg.style : "dots"
    readonly property int count: Math.max(0, Math.min(20, Number(cfg.count) || 0))
    readonly property color accent: Config.color(widget, "color", Theme.primary)
    readonly property int current: monitor?.activeWorkspace?.id ?? -1
    readonly property string special: monitor && (cfg.special ?? true) ? Hypr.specials[monitor.name] ?? "" : ""
    readonly property var ids: {
        const s = new Set(Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === monitor).map(w => w.id))
        for (let i = 1; i <= count; i++) s.add(i)
        return [...s].sort((a, b) => a - b)
    }

    function step(d) {
        if (!ids.length) return
        const i = ids.indexOf(current)
        Hypr.focusWorkspace(ids[(i + d + ids.length) % ids.length])
    }

    WheelHandler { onWheel: e => root.step(e.angleDelta.y > 0 ? -1 : 1) }

    Repeater {
        model: root.ids

        Item {
            id: ws
            required property int modelData
            readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
            readonly property var apps: [...new Set((workspace?.toplevels.values ?? []).map(t => t.wayland?.appId ?? "").filter(a => a))]
            readonly property bool active: modelData === root.current
            readonly property bool urgent: workspace?.urgent ?? false
            readonly property color tone: active ? root.accent : urgent ? Theme.error
                : Theme.alpha(Theme.on_surface, apps.length ? 0.6 : 0.25)

            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: root.height - Theme.px(8)
            implicitWidth: root.style === "dots" ? (active ? Theme.px(30) : Theme.px(16))
                : root.style === "numbers" ? implicitHeight
                : Math.max(implicitHeight, icons.implicitWidth + Theme.px(14))
            Behavior on implicitWidth { Anim {} }

            Rectangle {
                // dots: a dot that stretches into a pill when active; otherwise the button's background
                anchors.centerIn: parent
                width: root.style === "dots" ? parent.width - Theme.px(8) : parent.width
                height: root.style === "dots" ? Theme.px(8) : parent.height
                radius: root.style === "dots" ? height / 2 : Math.min(height / 2, Theme.radiusTiny * 1.5)
                color: root.style === "dots" ? ws.tone
                    : ws.active ? root.accent : hover.containsMouse ? Theme.layerHigh : "transparent"
                Behavior on color { CAnim {} }
            }

            StyledText {
                visible: root.style === "numbers" || root.style === "icons" && !ws.apps.length
                anchors.centerIn: parent
                text: ws.modelData
                color: ws.active ? Theme.contrast(root.accent) : ws.urgent ? Theme.error : Theme.alpha(Theme.on_surface, ws.apps.length ? 0.9 : 0.45)
                font.pixelSize: Theme.fontSmall
                font.weight: ws.active ? Font.Bold : Font.Medium
                font.features: { "tnum": 1 }
            }

            Row {
                id: icons
                visible: root.style === "icons" && ws.apps.length > 0
                anchors.centerIn: parent
                spacing: Theme.px(4)
                Repeater {
                    model: ws.apps.slice(0, 4)
                    AppIcon {
                        required property string modelData
                        app: modelData
                        implicitSize: Theme.px(16)
                    }
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hypr.focusWorkspace(ws.modelData)
            }
        }
    }

    // An open special workspace (scratchpad); click to tuck it away
    Rectangle {
        visible: root.special !== ""
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: implicitHeight
        implicitHeight: root.height - Theme.px(8)
        radius: height / 2
        color: Theme.alpha(root.accent, 0.18)
        Icon { anchors.centerIn: parent; text: Theme.icon.star; color: root.accent; font.pixelSize: Theme.px(14) }
        StateLayer { tint: root.accent; onClicked: Hypr.toggleSpecial(root.special) }
    }
}
