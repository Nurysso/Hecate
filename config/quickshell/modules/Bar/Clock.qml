import Quickshell
import QtQuick
import QtQuick.Layouts

Rectangle {
    Layout.preferredHeight: theme.barHeight - 12
    Layout.preferredWidth: clockLayout.implicitWidth + theme.padding * 2
    radius: theme.radiusSmall
    color: theme.bg

    property var currentTime: new Date()

    Timer {
        interval: 1000 // Update every second
        running: true
        repeat: true
        onTriggered: currentTime = new Date()
    }

    RowLayout {
        id: clockLayout
        anchors.centerIn: parent
        spacing: theme.spacingSmall

        Text {
            text: Qt.formatDateTime(currentTime, "hh:mmap") + "·" +
                  Qt.formatDateTime(currentTime, "ddd ") +
                  Qt.formatDateTime(currentTime, "M/dd")
            color: theme.fg
            font.pixelSize: theme.fontSize
            font.family: theme.fontFamily
            font.weight: Font.Medium
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        cursorShape: Qt.PointingHandCursor
        onEntered: parent.color = Qt.lighter(theme.bgLight, 1.15)
        onExited: parent.color = theme.bgLight
    }
}
