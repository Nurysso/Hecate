pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.config

Singleton {
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool wired: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var active: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property string icon: wired ? Theme.icon.ethernet
        : !Networking.wifiEnabled ? Theme.icon.wifiOff
        : active ? strength(active.signalStrength) : Theme.icon.wifiNone
    readonly property string label: wired ? "Ethernet" : !Networking.wifiEnabled ? "Off" : active?.name ?? "Disconnected"

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btConnected: adapter?.devices.values.filter(d => d.connected) ?? []
    readonly property string btIcon: !adapter?.enabled ? Theme.icon.btOff : btConnected.length ? Theme.icon.btOn : Theme.icon.bt
    readonly property string btLabel: !adapter ? "Unavailable" : !adapter.enabled ? "Off"
        : btConnected.length === 1 ? btConnected[0].name : btConnected.length ? btConnected.length + " devices" : "On"

    function strength(s) { return Theme.icon.wifi[Math.min(3, Math.floor(s * 4))] }
}
