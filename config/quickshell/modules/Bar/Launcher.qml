import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    Layout.preferredWidth: 32
    Layout.preferredHeight: 32
    radius: theme.radiusSmall
    color: "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Text {
        text: "󰣙"
        color: mouseArea.containsMouse ? theme.accent : theme.fg
        font.pixelSize: 20
        font.family: "Symbols Nerd Font"
        anchors.centerIn: parent

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Component {
        id: processComponent
        Process {
            running: true
            command: ["rofi", "-show", "drun", "-config", `${Quickshell.env("HOME")}/.config/rofi/config-icon-grid.rasi`]
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            // Create a new instance of the process
            processComponent.createObject(parent);
        }
    }

    // Subtle scale animation on click
    scale: mouseArea.pressed ? 0.9 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutCubic
        }
    }
}
