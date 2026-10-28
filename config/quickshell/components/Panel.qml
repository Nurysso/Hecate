import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config

// Overlay that animates a card in and builds its content only while shown.
PanelWindow {
    id: root
    required property string name
    property bool docked
    default property Component content
    readonly property bool open: GlobalStates.panel === name
    readonly property color accent: Config.color(name, "color", Theme.primary)

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    visible: open || card.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hecate-" + name
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Window-wide, so Escape closes the panel whichever item holds focus
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: GlobalStates.panel = ""
    }

    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.panel = ""

        Rectangle {
            anchors.fill: parent
            color: Theme.scrim
            opacity: root.open ? (root.docked ? 0.15 : 0.35) : 0
            Behavior on opacity { Anim {} }
        }
    }

    Rectangle {
        id: card
        x: root.docked ? parent.width - width - Theme.gap * 1.5 : (parent.width - width) / 2
        y: root.docked ? Theme.barHeight : (parent.height - height) / 2
        width: loader.width + Theme.pad * 2
        height: loader.height + Theme.pad * 2
        radius: Theme.radius
        color: Config.color(root.name, "background", Theme.surface_container)
        border.color: Theme.outline_variant
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.92
        transformOrigin: root.docked ? Item.TopRight : Item.Center
        Behavior on opacity { Anim {} }
        Behavior on scale { Anim {} }
        Behavior on height { Anim {} }
        Behavior on color { CAnim {} }

        MouseArea { anchors.fill: parent }

        Loader {
            id: loader
            x: Theme.pad
            y: Theme.pad
            focus: true
            active: root.visible
            sourceComponent: root.content
        }
    }
}
