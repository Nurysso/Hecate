import QtQuick
import Quickshell.Services.UPower
import qs.config
import qs.components
import qs.services

// Network, Bluetooth, volume and battery at a glance; click for the control center, scroll for volume.
Pill {
    id: root
    widget: "status"
    panel: "control"
    spacing: Theme.px(10)
    readonly property var battery: UPower.displayDevice
    readonly property real level: battery.percentage > 1 ? battery.percentage / 100 : battery.percentage
    readonly property bool charging: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged

    tooltip: `${Net.label}  ·  Volume ${Audio.muted ? "muted" : Math.round(Audio.volume * 100) + "%"}`
        + (battery.isLaptopBattery ? `  ·  Battery ${Math.round(level * 100)}%` : "")

    WheelHandler { onWheel: e => e.angleDelta.y > 0 ? Audio.raise() : Audio.lower() }

    Icon { anchors.verticalCenter: parent.verticalCenter; text: Net.icon; color: root.fg; font.pixelSize: Theme.px(17) }
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: Net.adapter?.enabled ?? false
        text: Net.btIcon
        color: root.fg
        font.pixelSize: Theme.px(17)
    }
    Icon { anchors.verticalCenter: parent.verticalCenter; visible: !!Audio.sink; text: Audio.icon; color: root.fg; font.pixelSize: Theme.px(17) }
    Icon {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.battery.isLaptopBattery
        text: root.charging ? Theme.icon.batteryCharging : Theme.icon.battery[Math.min(5, Math.floor(root.level * 6))]
        color: !root.charging && root.level <= (Config.widget("battery").low ?? 15) / 100 ? Theme.error : root.fg
        font.pixelSize: Theme.px(17)
    }
}
