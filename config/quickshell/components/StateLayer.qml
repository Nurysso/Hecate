import QtQuick
import qs.config

// Hover and press feedback for whatever it fills, shaped like its parent.
MouseArea {
    id: root
    property color tint: Theme.on_surface
    property real radius: root.parent?.radius ?? 0

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    Accessible.role: Accessible.Button

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        opacity: !root.enabled ? 0 : root.pressed ? 0.14 : root.containsMouse ? 0.08 : 0
        Behavior on opacity { Anim { duration: Theme.animFast } }
    }
}
