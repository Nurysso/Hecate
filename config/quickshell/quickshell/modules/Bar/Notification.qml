import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../utils"

IconButton {
    id: notifIcon
    icon: ""

    onActivated: NotificationState.toggle()
}
