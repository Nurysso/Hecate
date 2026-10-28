import QtQuick
import qs.config

// Horizontal progress bar; value is 0..1.
Rectangle {
    id: root
    property real value
    property color fill: Theme.primary

    implicitHeight: 6
    radius: height / 2
    color: Theme.surface_container_highest

    Rectangle {
        width: Math.max(parent.height, parent.width * Math.max(0, Math.min(root.value, 1)))
        height: parent.height
        radius: parent.radius
        color: root.fill
        visible: root.value > 0
        Behavior on width { Anim {} }
        Behavior on color { CAnim {} }
    }
}
