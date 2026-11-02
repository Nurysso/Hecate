import QtQuick
import Quickshell
import qs.config

// Hover hint just off the bar, under a button (above it when the bar sits at the bottom).
PopupWindow {
    id: root
    required property Item target
    property string text
    readonly property int offset: Theme.barInset + Theme.gap / 2

    anchor.item: target
    anchor.rect.y: -offset
    anchor.rect.width: target.width
    anchor.rect.height: target.height + offset * 2
    anchor.edges: Theme.barBottom ? Edges.Top : Edges.Bottom
    anchor.gravity: Theme.barBottom ? Edges.Top : Edges.Bottom
    implicitWidth: label.implicitWidth + Theme.px(20)
    implicitHeight: label.implicitHeight + Theme.px(12)
    color: "transparent"
    visible: true

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusTiny
        color: Theme.surface_container_highest
        border.width: Config.theme.border ? 1 : 0
        border.color: Theme.hairline
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { Anim { duration: Theme.animFast } }

        StyledText {
            id: label
            anchors.centerIn: parent
            text: root.text
            font.pixelSize: Theme.fontSmall
        }
    }
}
