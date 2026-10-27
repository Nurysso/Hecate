import QtQuick
import QtQuick.Controls.Basic
import qs.config

TextField {
    id: root
    property string icon: Theme.icon.search

    implicitHeight: 52
    leftPadding: 52
    rightPadding: Theme.pad
    color: Theme.on_surface
    placeholderTextColor: Theme.on_surface_variant
    selectionColor: Theme.primary
    selectedTextColor: Theme.on_primary
    font.family: Theme.font
    font.pixelSize: Theme.fontSize + 1

    background: Rectangle {
        radius: height / 2
        color: Theme.surface_container_highest
        border.width: 2
        border.color: root.activeFocus ? Theme.primary : "transparent"
        Behavior on border.color { CAnim {} }

        Icon {
            text: root.icon
            color: root.activeFocus ? Theme.primary : Theme.on_surface_variant
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
