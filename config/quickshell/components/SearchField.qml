import QtQuick
import QtQuick.Controls.Basic
import qs.config

TextField {
    id: root
    property string icon: Theme.icon.search

    implicitHeight: Theme.px(48)
    leftPadding: Theme.px(48)
    rightPadding: Theme.pad
    color: Theme.on_surface
    placeholderTextColor: Theme.on_surface_variant
    selectionColor: Theme.primary
    selectedTextColor: Theme.on_primary
    font.family: Theme.font
    font.pixelSize: Theme.fontLarge

    background: Rectangle {
        radius: Theme.radiusSmall
        color: Theme.layer
        border.width: Math.max(1, Theme.px(2))
        border.color: root.activeFocus ? Theme.alpha(Theme.primary, 0.8) : "transparent"
        Behavior on border.color { CAnim {} }

        Icon {
            text: root.icon
            color: root.activeFocus ? Theme.primary : Theme.on_surface_variant
            font.pixelSize: Theme.px(20)
            anchors.left: parent.left
            anchors.leftMargin: Theme.px(15)
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
