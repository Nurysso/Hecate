import QtQuick
import qs.config
import qs.components
import qs.services

// Network and Bluetooth state; click for the Wi-Fi & Bluetooth panel.
Pill {
    id: root
    widget: "connectivity"
    panel: "connectivity"
    icon: Net.icon
    tooltip: `${Net.label}  ·  Bluetooth ${Net.btLabel.toLowerCase()}`

    Icon { text: Net.btIcon; color: root.fg; anchors.verticalCenter: parent.verticalCenter }
}
