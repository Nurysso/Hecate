import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../utils"

Rectangle {
    Layout.preferredWidth: 32
    Layout.preferredHeight: 32
    radius: ColorManager.radiusSmall
    color: "transparent"

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Text {
        text: "⏻"
        color: mouseArea.containsMouse ? ColorManager.accentColor : ColorManager.fgColor
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
            command: ["wlogout"]
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
