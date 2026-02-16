import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: clockContainer
    Layout.preferredHeight: theme.barHeight
    Layout.preferredWidth: clockText.implicitWidth + theme.padding * 2

    property var currentTime: new Date()

    Timer {
        interval: 60000 // Update every minute
        running: true
        repeat: true
        onTriggered: currentTime = new Date()
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: Qt.formatDateTime(currentTime, "h:mm ap")
        color: theme.fg
        font.pixelSize: theme.fontSize
        font.family: theme.fontFamily
        font.weight: Font.Normal
        opacity: 0.9
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: clockText.opacity = 1.0
        onExited: clockText.opacity = 0.9
    }

    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }
}
