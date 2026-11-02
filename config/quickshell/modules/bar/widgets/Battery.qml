import QtQuick
import Quickshell.Services.UPower
import qs.config
import qs.components

// Laptop battery; hidden on machines without one. Hover for the time left.
Pill {
    id: root
    widget: "battery"
    readonly property var device: UPower.displayDevice
    readonly property real level: device.percentage > 1 ? device.percentage / 100 : device.percentage
    readonly property bool charging: device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged
    readonly property bool low: !charging && level <= (cfg.low ?? 15) / 100

    function duration(s) {
        const m = Math.round(s / 60)
        return m >= 60 ? `${Math.floor(m / 60)}h ${m % 60}m` : `${m}m`
    }

    visible: device.isLaptopBattery
    fg: low ? Theme.error : Config.color(widget, "color", Theme.on_surface)
    icon: charging ? Theme.icon.batteryCharging : Theme.icon.battery[Math.min(5, Math.floor(level * 6))]
    label: Math.round(level * 100) + "%"
    tooltip: device.state === UPowerDeviceState.FullyCharged ? "Fully charged"
        : charging ? (device.timeToFull > 0 ? `Full in ${duration(device.timeToFull)}` : "Charging")
        : device.timeToEmpty > 0 ? `${duration(device.timeToEmpty)} left` : ""
}
