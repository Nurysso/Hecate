import QtQuick
import com.hecate.settings

Item {
    id: root
    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: 0
    signal released(real value)

    implicitWidth: 220
    implicitHeight: 32
    readonly property real fraction: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 16
        radius: 8
        color: Theme.surface_container_highest

        Rectangle {
            width: Math.max(parent.height, root.fraction * (parent.width - 8))
            height: parent.height
            radius: 8
            color: Theme.primary
        }
    }

    Rectangle {
        x: root.fraction * (root.width - width)
        width: 4
        height: 32
        radius: 2
        color: Theme.primary
        scale: area.pressed ? 0.8 : 1
        Behavior on scale { Anim { duration: Theme.animFast } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function pick(x) {
            const f = Math.max(0, Math.min(1, x / width))
            let v = root.from + f * (root.to - root.from)
            if (root.stepSize > 0) v = Math.round(v / root.stepSize) * root.stepSize
            root.value = Number(v.toFixed(4))
        }

        onPressed: m => pick(m.x)
        onPositionChanged: m => { if (pressed) pick(m.x) }
        onReleased: root.released(root.value)
    }
}
