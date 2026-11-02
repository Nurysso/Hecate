import QtQuick
import qs.config
import qs.components
import qs.services

// Bell with a count of notifications; click for the history.
Pill {
    id: root
    widget: "notifications"
    panel: "notifications"
    readonly property int count: Notifs.list.length

    icon: GlobalStates.dnd ? Theme.icon.bellOff : count ? Theme.icon.bellBadge : Theme.icon.bell
    tooltip: GlobalStates.dnd ? "Do not disturb" : count ? `${count} notification${count === 1 ? "" : "s"}` : "No notifications"

    Rectangle {
        visible: root.count > 0
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: Math.max(implicitHeight, num.implicitWidth + Theme.px(10))
        implicitHeight: Theme.px(18)
        radius: height / 2
        color: Config.color(root.widget, "color", Theme.primary)
        StyledText {
            id: num
            anchors.centerIn: parent
            text: root.count > 99 ? "99+" : root.count
            color: Theme.contrast(parent.color)
            font.pixelSize: Theme.fontTiny
            font.weight: Font.Bold
        }
    }
}
