import QtQuick
import QtQuick.Controls.Basic
import com.hecate.settings

TextField {
    id: root
    property string icon
    property bool invalid

    implicitHeight: 44
    leftPadding: icon ? 48 : Theme.pad
    rightPadding: Theme.pad
    color: Theme.on_surface
    placeholderTextColor: Theme.on_surface_variant
    selectionColor: Theme.primary
    selectedTextColor: Theme.on_primary
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    selectByMouse: true

    background: Rectangle {
        radius: height / 2
        color: Theme.surface_container_highest
        border.width: 2
        border.color: root.invalid ? Theme.error : root.activeFocus ? Theme.primary : "transparent"
        Behavior on border.color { CAnim {} }

        StyledText {
            visible: root.icon
            text: root.icon
            font.family: Theme.iconFont
            font.pixelSize: 18
            color: root.activeFocus ? Theme.primary : Theme.on_surface_variant
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
