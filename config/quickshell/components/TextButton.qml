import QtQuick
import qs.config

// Small rounded button with a label and an optional icon.
Rectangle {
    id: root
    property string text
    property string icon
    property color fg: Theme.on_surface
    signal clicked

    implicitWidth: row.implicitWidth + Theme.px(24)
    implicitHeight: Theme.px(32)
    radius: height / 2
    color: Theme.layerHigh

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.px(6)
        Icon { visible: text; text: root.icon; color: root.fg; font.pixelSize: Theme.px(16); anchors.verticalCenter: parent.verticalCenter }
        StyledText { text: root.text; color: root.fg; font.weight: Font.Medium; font.pixelSize: Theme.fontSmall + 1; anchors.verticalCenter: parent.verticalCenter }
    }

    StateLayer { tint: root.fg; onClicked: root.clicked() }
}
