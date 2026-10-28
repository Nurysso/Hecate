import qs.config
import qs.components
import qs.services

Pill {
    widget: "notifications"
    icon: Notifs.list.length ? Theme.icon.bellBadge : Theme.icon.bell
    label: Notifs.list.length || ""
    onClicked: GlobalStates.toggle("notifications")
}
