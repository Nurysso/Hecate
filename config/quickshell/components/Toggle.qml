import QtQuick
import qs.config

// On/off switch.
Rectangle {
    id: root
    property bool checked
    signal toggled

    implicitWidth: Theme.px(46)
    implicitHeight: Theme.px(28)
    radius: height / 2
    color: checked ? Theme.primary : Theme.layerHigh
    border.width: checked ? 0 : Math.max(1, Theme.px(2))
    border.color: Theme.outline
    Accessible.role: Accessible.CheckBox
    Accessible.checked: checked
    Behavior on color { CAnim {} }

    StateLayer { onClicked: root.toggled() }

    Rectangle {
        width: root.checked ? root.height - Theme.px(8) : root.height - Theme.px(14)
        height: width
        radius: width / 2
        x: root.checked ? root.width - width - Theme.px(4) : Theme.px(7)
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Theme.on_primary : Theme.outline
        Behavior on x { Anim {} }
        Behavior on width { Anim {} }
        Behavior on color { CAnim {} }
    }
}
