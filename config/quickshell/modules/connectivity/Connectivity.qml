import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.config
import qs.components
import qs.services

Panel {
    id: root
    name: "connectivity"
    docked: true

    ColumnLayout {
        id: col
        width: 380
        spacing: Theme.gap
        readonly property var adapter: Bluetooth.defaultAdapter

        Component.onCompleted: {
            if (Net.wifi) Net.wifi.scannerEnabled = true
            if (adapter?.enabled) adapter.discovering = true
        }
        Component.onDestruction: {
            if (Net.wifi) Net.wifi.scannerEnabled = false
            if (adapter) adapter.discovering = false
        }

        component Header: RowLayout {
            property string title
            property string unavailable
            property bool checked
            signal toggled
            Layout.fillWidth: true
            Layout.leftMargin: Theme.gap
            StyledText { Layout.fillWidth: true; text: parent.title; font.pixelSize: Theme.fontSize + 2; font.weight: Font.DemiBold }
            StyledText { text: parent.unavailable; visible: text; color: Theme.on_surface_variant }
            Toggle { visible: !parent.unavailable; checked: parent.checked; onToggled: parent.toggled() }
        }

        component Section: ListView {
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, 260)
            clip: true
            spacing: 2
            displaced: Displaced {}
        }

        Header {
            title: "Wi-Fi"
            unavailable: Networking.backend === NetworkBackendType.None ? "Needs NetworkManager" : Net.wifi ? "" : "No Wi-Fi device"
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }

        Section {
            visible: Networking.wifiEnabled && !!Net.wifi
            model: ScriptModel {
                values: (Net.wifi?.networks.values ?? []).filter(n => n.name)
                    .sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength)
            }

            delegate: ColumnLayout {
                id: net
                required property WifiNetwork modelData
                property bool asking
                property string error
                readonly property bool secure: modelData.security !== WifiSecurityType.Open
                width: ListView.view.width
                spacing: 4

                Connections {
                    target: net.modelData
                    function onConnectionFailed(reason) { net.error = ConnectionFailReason.toString(reason); net.asking = net.secure }
                }

                Tile {
                    Layout.fillWidth: true
                    icon: Net.strength(net.modelData.signalStrength)
                    title: net.modelData.name
                    subtitle: net.error || (net.modelData.stateChanging ? "Connecting…" : net.modelData.connected ? "Connected" : net.modelData.known ? "Saved" : "")
                    fg: net.modelData.connected ? root.accent : Theme.on_surface
                    onClicked: {
                        net.error = ""
                        if (net.modelData.connected) net.modelData.disconnect()
                        else if (net.modelData.known || !net.secure) net.modelData.connect()
                        else net.asking = !net.asking
                    }
                    Icon { text: Theme.icon.lock; visible: net.secure; color: Theme.on_surface_variant; font.pixelSize: 14 }
                }

                SearchField {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 6
                    visible: net.asking
                    icon: Theme.icon.lock
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    onVisibleChanged: if (visible) forceActiveFocus()
                    onAccepted: {
                        net.modelData.connectWithPsk(text)
                        net.asking = false
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.margins: Theme.gap; implicitHeight: 1; color: Theme.outline_variant }

        Header {
            title: "Bluetooth"
            unavailable: col.adapter ? "" : "No adapter"
            checked: col.adapter?.enabled ?? false
            onToggled: if (col.adapter) col.adapter.enabled = !col.adapter.enabled
        }

        Section {
            visible: col.adapter?.enabled ?? false
            model: ScriptModel {
                values: (col.adapter?.devices.values ?? []).filter(d => d.paired || d.deviceName)
                    .sort((a, b) => b.connected - a.connected || b.paired - a.paired || a.name.localeCompare(b.name))
            }

            delegate: Tile {
                required property BluetoothDevice modelData
                readonly property var kind: [["audio", "headphones"], ["input-keyboard", "keyboard"], ["input-mouse", "mouse"], ["phone", "phone"], ["input-gaming", "gamepad"]]
                    .find(k => modelData.icon.startsWith(k[0]))
                width: ListView.view.width
                icon: Theme.icon[kind?.[1] ?? "bt"]
                title: modelData.name
                subtitle: modelData.pairing ? "Pairing…"
                    : modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
                    : modelData.connected ? "Connected" + (modelData.batteryAvailable ? ` · ${Math.round(modelData.battery * 100)}%` : "")
                    : modelData.paired ? "Paired" : ""
                fg: modelData.connected ? root.accent : Theme.on_surface
                onClicked: modelData.connected ? modelData.disconnect() : modelData.paired ? modelData.connect() : modelData.pair()
            }
        }
    }
}
