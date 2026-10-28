import QtQuick
import com.hecate.settings

MouseArea {
    id: root
    property color tint: Theme.on_surface

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: root.parent?.radius ?? 0
        color: root.tint
        opacity: root.pressed ? 0.14 : root.containsMouse ? 0.08 : 0
        Behavior on opacity { Anim { duration: Theme.animFast } }
    }
}
