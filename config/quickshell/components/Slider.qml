import QtQuick
import qs.config

// A thick rounded slider with its icon riding inside the fill. value runs 0..max; drag, click or
// scroll to change it, and it reports the new value through moved(). Clicking the icon emits
// iconClicked() instead (mute, for volume).
Rectangle {
    id: root
    property real value
    property real max: 1
    property real step: 0.05
    property string icon
    property color fill: Theme.primary
    readonly property real fraction: Math.max(0, Math.min(1, value / max))
    signal moved(real value)
    signal iconClicked

    implicitWidth: Theme.px(240)
    implicitHeight: Theme.px(36)
    radius: height / 2
    color: Theme.layerHigh

    function set(x) { moved(Math.max(0, Math.min(1, x / width)) * max) }

    Rectangle {
        width: Math.max(parent.height, parent.width * root.fraction)
        height: parent.height
        radius: parent.radius
        color: root.fill
        Behavior on width { enabled: !drag.pressed; Anim { duration: Theme.animFast } }
        Behavior on color { CAnim {} }
    }

    Icon {
        x: (parent.height - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: Theme.on_primary
        font.pixelSize: Math.round(parent.height * 0.5)
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: e => root.set(e.x)
        onPositionChanged: e => { if (pressed) root.set(e.x) }
    }

    MouseArea {
        width: parent.height
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.iconClicked()
    }

    WheelHandler { onWheel: e => root.moved(Math.max(0, Math.min(root.max, root.value + (e.angleDelta.y > 0 ? root.step : -root.step)))) }
}
