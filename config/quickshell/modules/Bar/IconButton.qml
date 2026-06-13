// A reusable base for Launcher / Bluetooth / Notification / Power.
// Each component can set `icon`, `iconSize`, and `onActivated`.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../utils"

Rectangle {
    id: root

    property string icon: ""
    property int    iconSize: 18
    property var    command: []
    signal activated()

    Layout.preferredWidth: 28
    Layout.preferredHeight: 28
    radius: 6
    color: mouse.containsMouse
        ? Qt.rgba(ColorManager.accent.r, ColorManager.accent.g, ColorManager.accent.b, 0.1)
        : "transparent"

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: root.iconSize
        font.family: "Symbols Nerd Font"
        color: mouse.containsMouse ? ColorManager.accentColor : ColorManager.fgColor
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Component {
        id: proc
        Process { running: true }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.activated()
            if (root.command.length > 0) {
                const p = proc.createObject(root)
                p.command = root.command
                p.running = true
            }
        }
    }

    scale: mouse.pressed ? 0.88 : 1.0
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
}
