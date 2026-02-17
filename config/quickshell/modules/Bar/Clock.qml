import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../utils"

Item {
    id: clockContainer

    // This tells the RowLayout in the main file how big the clock is
    implicitWidth: clockText.implicitWidth + (ColorManager.padding * 2)
    implicitHeight: ColorManager.barHeight

    property var currentTime: new Date()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: currentTime = new Date()
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: Qt.formatDateTime(currentTime, "h:mm ap")
        color: ColorManager.fgColor
        font.pixelSize: ColorManager.fontSize
        font.family: ColorManager.fontFamily
        // Added renderType to prevent text "shaking" or width jumping
        renderType: Text.NativeRendering
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: clockText.opacity = 1.0
        onExited: clockText.opacity = 0.9
    }
}
