import QtQuick
import qs.config

// Round icon button; filled ones take the accent.
Rectangle {
    id: root
    property string icon
    property bool filled
    property color accent: Theme.primary
    property color fg: filled ? Theme.contrast(accent) : Theme.on_surface
    property int size: Theme.px(36)
    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: filled ? accent : "transparent"
    opacity: enabled ? 1 : 0.38
    Behavior on color { CAnim {} }

    Icon {
        anchors.centerIn: parent
        text: root.icon
        color: root.fg
        font.pixelSize: Math.round(root.size * 0.5)
    }

    StateLayer { tint: root.fg; onClicked: root.clicked() }
}
