import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// A panel's window. kind "popover" hangs off the bar beneath the widget that opened it and slides out
// of the bar like a drawer; "modal" sits centered over a dimmed screen; "fullscreen" covers the screen.
// The content Component is only built while the panel shows.
PanelWindow {
    id: root
    required property string name
    property string kind: "popover"
    property string side: "right"     // where a popover sits when no bar widget opened it: left, center, right
    property bool padded: true
    // The content's size. Layouts work out their own implicit size, so a panel states its width here,
    // and its height when it shouldn't follow the content (0: follow it, up to the screen's height).
    property int contentWidth
    property int contentHeight
    default property Component content
    readonly property bool open: GlobalStates.panel === name
    readonly property color accent: Config.color(name, "color", Theme.primary)
    readonly property bool popover: kind === "popover"
    readonly property bool fullscreen: kind === "fullscreen"
    readonly property int edge: Math.max(Theme.barMargin, Theme.gap)          // screen edges and bar to the panel
    readonly property int padding: padded ? Theme.pad : 0
    readonly property int maxContentHeight: height - (popover ? Theme.barExtent : 0) - edge * 2 - padding * 2
    property real shown
    property string output
    property real anchorX: -1          // center of the bar widget it hangs from, -1 for none

    onOpenChanged: {
        if (open) {
            output = GlobalStates.screen
            const a = GlobalStates.anchor
            anchorX = a && a.QsWindow.window?.screen?.name === output ? a.mapToItem(null, a.width / 2, 0).x : -1
        }
        reveal.stop()
        reveal.to = open ? 1 : 0
        reveal.duration = open ? Theme.anim : Theme.animFast
        reveal.easing.bezierCurve = open ? Theme.curve : Theme.curveExit
        reveal.start()
    }
    NumberAnimation { id: reveal; target: root; property: "shown"; easing.type: Easing.BezierSpline }

    screen: Quickshell.screens.find(s => s.name === output) ?? Quickshell.screens[0]
    visible: shown > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hecate-" + name
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // A popover's blur follows the drawer as it moves; the others drop theirs as soon as they start closing
    BackgroundEffect.blurRegion: Region { regions: Theme.blur && (root.open || root.popover) ? [card.blur] : [] }
    // Popovers leave the bar clickable, so a click on another bar widget switches straight to its panel
    mask: Region {
        width: root.width
        height: root.height
        Region {
            intersection: Intersection.Subtract
            y: Theme.barBottom ? root.height - Theme.barExtent : 0
            width: root.popover ? root.width : 0
            height: Theme.barExtent
        }
    }

    // Window-wide, so Escape closes the panel whichever item holds focus
    Shortcut { sequence: "Escape"; enabled: root.open; onActivated: GlobalStates.close() }

    // Dims (modal, fullscreen) and closes on a click outside the card
    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.close()

        Rectangle {
            anchors.fill: parent
            color: Theme.scrim
            opacity: root.popover ? 0 : root.shown * (root.fullscreen ? 0.4 : 0.28)
        }
    }

    Glass {
        id: card
        property real fullWidth: root.fullscreen ? root.width : loader.width + root.padding * 2
        property real fullHeight: root.fullscreen ? root.height : loader.height + root.padding * 2
        Behavior on fullHeight { enabled: root.shown === 1; Anim {} }
        readonly property real grow: root.popover || root.fullscreen ? 1 : 0.9 + 0.1 * root.shown

        width: fullWidth * grow
        height: root.popover ? fullHeight * root.shown : fullHeight * grow
        x: root.fullscreen ? 0
            : !root.popover ? (root.width - width) / 2
            : root.anchorX >= 0 ? Math.max(root.edge, Math.min(root.width - width - root.edge, root.anchorX - width / 2))
            : root.side === "left" ? root.edge : root.side === "center" ? (root.width - width) / 2 : root.width - width - root.edge
        y: root.fullscreen ? 0
            : !root.popover ? (root.height - height) * 0.42
            : Theme.barBottom ? root.height - Theme.barExtent - root.edge - height : Theme.barExtent + root.edge
        clip: true
        radius: root.fullscreen ? 0 : Theme.radiusLarge
        tint: Config.color(root.name, "background", root.fullscreen ? Theme.surface_container_lowest : Theme.surface_container)
        border.width: root.fullscreen ? 0 : Config.theme.border ? 1 : 0
        // Modals fade only on the way out, after their blur has gone; fullscreen fades both ways
        opacity: root.fullscreen ? root.shown : root.popover || root.open ? 1 : root.shown

        // Clicks on the card don't close it; a fullscreen card is all backdrop, so there they do
        MouseArea { anchors.fill: parent; onClicked: if (root.fullscreen) GlobalStates.close() }

        Loader {
            id: loader
            width: root.contentWidth || (item ? item.implicitWidth : 0)
            height: Math.min(root.contentHeight || (item ? item.implicitHeight : 0), root.maxContentHeight)
            // a popover's content rides the drawer's far edge; the others stay centered
            x: (card.width - width) / 2
            y: !root.popover ? (card.height - height) / 2
                : Theme.barBottom ? root.padding : card.height - card.fullHeight + root.padding
            opacity: root.popover ? Math.min(1, root.shown * 1.6) : root.shown
            scale: root.fullscreen ? 0.94 + 0.06 * root.shown : 1
            focus: true
            active: root.visible
            sourceComponent: root.content
        }
    }
}
