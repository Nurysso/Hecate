import QtQuick
import Quickshell.Bluetooth
import qs.config
import qs.components
import qs.services

Pill {
    id: root
    widget: "connectivity"
    icon: Net.icon
    onClicked: GlobalStates.toggle("connectivity")

    Icon {
        readonly property var adapter: Bluetooth.defaultAdapter
        text: !adapter?.enabled ? Theme.icon.btOff : adapter.devices.values.some(d => d.connected) ? Theme.icon.btOn : Theme.icon.bt
        color: root.fg
    }
}
