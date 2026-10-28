pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking
import qs.config

Singleton {
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool wired: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var active: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property string icon: wired ? Theme.icon.ethernet
        : !Networking.wifiEnabled ? Theme.icon.wifiOff
        : active ? strength(active.signalStrength) : Theme.icon.wifiNone

    function strength(s) { return Theme.icon.wifi[Math.min(3, Math.floor(s * 4))] }
}
