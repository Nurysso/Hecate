import QtQuick
import QtQuick.Layouts

Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: theme.barHeight - 8
    Layout.leftMargin: theme.spacing
    Layout.rightMargin: theme.spacing


    color: theme.bg

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: theme.padding
        anchors.rightMargin: theme.padding
        spacing: 8



        // Window title
        Text {
            text: hyprlandInfo.activeWindow || "Desktop"
            color: hyprlandInfo.activeWindow ? theme.fg : theme.fgDark
            font.pixelSize: theme.fontSize
            font.family: theme.fontFamily
            font.italic: !hyprlandInfo.activeWindow
            Layout.fillWidth: true
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
