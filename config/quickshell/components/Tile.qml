import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config

// List row: image or icon, a title and an optional subtitle; extra children sit at the end.
Rectangle {
    id: root
    property string icon
    property string image
    property string title
    property string subtitle
    property bool selected
    property bool rich              // title is StyledText markup (the launcher's match highlight)
    property color fg: Theme.on_surface
    property int iconSize: Theme.px(32)
    default property alias trailing: row.data
    signal clicked

    implicitHeight: Theme.px(56)
    radius: Theme.radiusSmall
    color: selected ? Theme.layerHigh : "transparent"
    Behavior on color { CAnim { duration: Theme.animFast } }

    StateLayer { tint: root.fg; onClicked: root.clicked() }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: Theme.px(12)
        anchors.rightMargin: Theme.px(12)
        spacing: Theme.px(12)

        IconImage { source: root.image; implicitSize: root.iconSize; visible: root.image }
        Icon { text: root.icon; color: root.fg; visible: text && !root.image; Layout.preferredWidth: root.iconSize }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText { text: root.title; color: root.fg; Layout.fillWidth: true; textFormat: root.rich ? Text.StyledText : Text.PlainText }
            StyledText {
                text: root.subtitle
                visible: text
                color: Theme.on_surface_variant
                font.pixelSize: Theme.fontSmall
                Layout.fillWidth: true
            }
        }
    }
}
