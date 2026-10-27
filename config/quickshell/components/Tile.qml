import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config

Rectangle {
    id: root
    property string icon
    property string image
    property string title
    property string subtitle
    property color fg: Theme.on_surface
    default property alias trailing: row.data
    signal clicked

    implicitHeight: 56
    radius: Theme.radiusSmall
    color: "transparent"
    Behavior on color { CAnim {} }

    StateLayer { tint: root.fg; onClicked: root.clicked() }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        IconImage { source: root.image; implicitSize: 32; visible: root.image }
        Icon { text: root.icon; color: root.fg; visible: text && !root.image; Layout.preferredWidth: 32 }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText { text: root.title; color: root.fg; Layout.fillWidth: true }
            StyledText {
                text: root.subtitle
                visible: text
                color: Theme.on_surface_variant
                font.pixelSize: Theme.fontSize - 2
                Layout.fillWidth: true
            }
        }
    }
}
