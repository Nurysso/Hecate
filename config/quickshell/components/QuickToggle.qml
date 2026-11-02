import QtQuick
import QtQuick.Layouts
import qs.config

// Control center tile: icon, title and state. Clicking toggles it; with `more` set, the chevron
// end opens its details instead.
Rectangle {
    id: root
    property string icon
    property string title
    property string subtitle
    property bool checked
    property bool more
    property color accent: Theme.primary
    readonly property color fg: checked ? Theme.on_primary_container : Theme.on_surface
    signal toggled
    signal expand

    implicitWidth: Theme.px(180)
    implicitHeight: Theme.px(60)
    radius: Theme.radiusSmall
    color: checked ? Theme.primary_container : Theme.layer
    Behavior on color { CAnim {} }

    StateLayer { tint: root.fg; onClicked: root.toggled() }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.px(11)
        anchors.rightMargin: Theme.px(root.more ? 4 : 11)
        spacing: Theme.px(10)

        Rectangle {
            implicitWidth: Theme.px(38)
            implicitHeight: Theme.px(38)
            radius: width / 2
            color: root.checked ? root.accent : Theme.layerHigh
            Behavior on color { CAnim {} }
            Icon { anchors.centerIn: parent; text: root.icon; color: root.checked ? Theme.contrast(root.accent) : Theme.on_surface }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText { Layout.fillWidth: true; text: root.title; color: root.fg; font.weight: Font.DemiBold; font.pixelSize: Theme.fontSize - 1 }
            StyledText {
                Layout.fillWidth: true
                visible: text
                text: root.subtitle
                color: root.checked ? Theme.alpha(root.fg, 0.8) : Theme.on_surface_variant
                font.pixelSize: Theme.fontSmall
            }
        }

        Rectangle {
            visible: root.more
            implicitWidth: Theme.px(32)
            implicitHeight: Theme.px(44)
            radius: Theme.radiusTiny
            color: "transparent"
            Icon { anchors.centerIn: parent; text: Theme.icon.chevronRight; color: root.fg }
            StateLayer { tint: root.fg; onClicked: root.expand() }
        }
    }
}
