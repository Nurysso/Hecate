import QtQuick
import com.hecate.settings

Rectangle {
    id: root
    property bool checked
    signal toggled

    implicitWidth: 52
    implicitHeight: 32
    radius: height / 2
    color: checked ? Theme.primary : Theme.surface_container_highest
    border.width: checked ? 0 : 2
    border.color: Theme.outline
    Behavior on color { CAnim {} }

    StateLayer { onClicked: root.toggled() }

    Rectangle {
        width: root.checked ? 24 : 16
        height: width
        radius: width / 2
        x: root.checked ? root.width - width - 4 : 8
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Theme.on_primary : Theme.outline
        Behavior on x { Anim {} }
        Behavior on width { Anim {} }
        Behavior on color { CAnim {} }
    }
}
