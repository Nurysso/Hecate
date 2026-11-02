import QtQuick
import QtQuick.Layouts
import qs.config

// A card's title row: its icon on a tinted disc, the title, then any children at the end.
RowLayout {
    id: root
    property string icon
    property string title
    property color accent: Theme.primary

    Layout.fillWidth: true
    spacing: Theme.gap

    Rectangle {
        implicitWidth: Theme.px(32)
        implicitHeight: Theme.px(32)
        radius: width / 2
        color: Theme.alpha(root.accent, 0.16)
        Icon { anchors.centerIn: parent; text: root.icon; color: root.accent; font.pixelSize: Theme.px(16) }
    }

    StyledText { Layout.fillWidth: true; text: root.title; font.weight: Font.DemiBold }
}
