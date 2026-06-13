import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../utils"

Item {
    id: root
    implicitWidth: col.implicitWidth + ColorManager.padding * 2
    implicitHeight: ColorManager.barHeight

    property var now: new Date()

    Timer {
        interval: 10000   // update every 10 s is plenty for hh:mm
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 0

        Text {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "h:mm ap")
            color: ColorManager.fgColor
            font.pixelSize: ColorManager.fontSize
            font.family: ColorManager.fontFamily
            font.weight: Font.Medium
            renderType: Text.NativeRendering
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "ddd d MMM")
            color: ColorManager.mutedColor
            font.pixelSize: ColorManager.fontSize - 2
            font.family: ColorManager.fontFamily
            renderType: Text.NativeRendering
            opacity: 0.7
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.opacity = 0.8
        onExited:  root.opacity = 1.0
    }

    Behavior on opacity { NumberAnimation { duration: 120 } }
}
