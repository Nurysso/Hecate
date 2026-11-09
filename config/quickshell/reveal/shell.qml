import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// The first thing on screen after login, run once by hecate/scripts/start-desktop.sh and gone afterwards.
// It covers every monitor in black (where hecate-sddm's fade ends), sets the wallpaper and starts the shell
// behind that cover, then opens a circle from the middle of each monitor to show the finished desktop.
// It's its own Quickshell instance so reloading or restarting the shell can't play it again.
ShellRoot {
    id: root

    readonly property string wallpaper: Quickshell.env("HOME") + "/.cache/hecate/wallpaper"
    readonly property int hold: 1000                        // ms on black first: a monitor can stay dark for seconds after Hyprland sets its mode
    readonly property int duration: 900                       // the same circle set-wallpaper.sh asks awww for
    readonly property list<real> curve: [0.45, 0, 0.55, 1, 1, 1]
    readonly property real softEdge: 0.85                     // where the circle's edge starts to darken, as a share of its radius

    property bool covered     // the black is on screen, so nothing behind it can be seen arriving
    property bool wallpaperSet
    property bool barUp
    property bool desktopUp
    property real progress    // 0 is all black, 1 has cleared every corner

    function cover() {
        if (covered) return
        covered = true
        Quickshell.execDetached({ command: ["quickshell"], environment: { HECATE_REVEAL: "1" } })
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "openlayer") return
            if (event.data === "hecate-reveal") root.cover()
            else if (event.data === "hecate-bar") root.barUp = true
            else if (event.data === "hecate-desktop") root.desktopUp = true
        }
    }

    Timer { running: true; interval: 500; onTriggered: root.cover() }   // in case the event came before the socket connected

    Process {
        running: root.covered
        command: ["awww", "img", root.wallpaper, "-t", "none"]
        onExited: root.wallpaperSet = true
    }

    Timer { running: root.wallpaperSet && root.barUp && root.desktopUp; interval: root.hold; onTriggered: open.start() }
    Timer { running: true; interval: root.hold + 4000; onTriggered: open.start() }   // never leave the screen black waiting on the shell

    NumberAnimation {
        id: open
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.duration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: root.curve
        onFinished: Qt.quit()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            readonly property real reach: Math.hypot(width, height) / 2 / root.softEdge

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "hecate-reveal"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}   // empty: clicks and keys reach the desktop from the start

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                visible: root.progress <= 0
            }

            Shape {
                anchors.fill: parent
                visible: root.progress > 0
                preferredRendererType: Shape.GeometryRenderer

                ShapePath {
                    strokeWidth: -1
                    startX: 0
                    startY: 0
                    fillGradient: RadialGradient {
                        centerX: win.width / 2
                        centerY: win.height / 2
                        focalX: centerX
                        focalY: centerY
                        centerRadius: Math.max(1, win.reach * root.progress)
                        GradientStop { position: root.softEdge; color: "#00000000" }
                        GradientStop { position: 1; color: "#ff000000" }
                    }
                    PathLine { x: win.width; y: 0 }
                    PathLine { x: win.width; y: win.height }
                    PathLine { x: 0; y: win.height }
                    PathLine { x: 0; y: 0 }
                }
            }
        }
    }
}
