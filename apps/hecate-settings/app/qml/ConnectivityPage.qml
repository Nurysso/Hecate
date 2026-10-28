import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import com.hecate.settings

ScrollView {
    id: page
    readonly property var wifi: JSON.parse(conn.wifi || "{}")
    readonly property var bt: JSON.parse(conn.bluetooth || "{}")
    readonly property var audio: JSON.parse(conn.audio || "{}")
    readonly property var connected: (wifi.networks ?? []).find(n => n.connected) ?? null
    readonly property var wifiIcons: ["\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"]
    property string prompt

    function strength(s) { return wifiIcons[Math.min(3, Math.floor((s ?? 0) / 25))] }

    Connectivity { id: conn }

    onVisibleChanged: if (visible) conn.refresh()
    Component.onCompleted: Qt.callLater(() => { if (visible) conn.refresh() })
    onAudioChanged: volume.value = Math.min(1, audio.volume ?? 0)
    contentWidth: availableWidth

    component Card: Rectangle {
        property bool available: true
        default property alias content: inner.data
        implicitHeight: inner.implicitHeight + Theme.pad * 3
        radius: Theme.radius
        color: Theme.surface_container_low
        border.color: Theme.outline_variant
        opacity: available ? 1 : 0.6

        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: Theme.pad * 1.5
            spacing: Theme.gap
        }
    }

    component Title: StyledText {
        color: Theme.primary
        font.weight: Font.DemiBold
        font.pixelSize: Theme.fontSize + 4
        Layout.fillWidth: true
    }

    component Note: StyledText {
        color: Theme.on_surface_variant
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        Layout.fillWidth: true
    }

    component Error: Note {
        color: Theme.error
        visible: text !== ""
    }

    component Glyph: StyledText {
        font.family: Theme.iconFont
        font.pixelSize: 18
        color: Theme.on_surface_variant
    }

    component Row: Rectangle {
        default property alias content: row.data
        property bool highlight
        Layout.fillWidth: true
        implicitHeight: row.implicitHeight + Theme.pad
        radius: Theme.radiusSmall
        color: highlight ? Theme.secondary_container : Theme.surface_container

        RowLayout {
            id: row
            anchors.fill: parent
            anchors.leftMargin: Theme.pad
            anchors.rightMargin: Theme.gap
            spacing: Theme.pad
        }
    }

    ColumnLayout {
        width: page.availableWidth
        spacing: Theme.pad

        Card {
            Layout.fillWidth: true
            available: conn.networkAvailable

            RowLayout {
                Layout.fillWidth: true
                Title { text: "Network" }
                PillButton {
                    visible: conn.networkAvailable
                    text: conn.wifiBusy === "refresh" ? "Refreshing…" : "Refresh"
                    enabled: conn.wifiBusy === ""
                    color: Theme.surface_container_highest
                    fg: Theme.on_surface
                    onClicked: conn.refresh()
                }
            }
            Note { visible: !conn.networkAvailable; text: conn.networkReason || "Checking NetworkManager…" }
            Error { text: conn.networkAvailable ? conn.wifiError : "" }

            Row {
                visible: conn.networkAvailable && !!page.wifi.wired
                highlight: true

                Glyph { text: "\u{f0200}"; color: Theme.on_secondary_container }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    StyledText { text: page.wifi.wired ?? ""; font.weight: Font.Medium; color: Theme.on_secondary_container }
                    StyledText { text: "Wired"; font.pixelSize: Theme.fontSize - 2; color: Theme.on_secondary_container }
                }
            }
            Note {
                visible: conn.networkAvailable && page.wifi.networks !== undefined && !page.wifi.iface
                text: "No Wi-Fi adapter found"
            }
            Note {
                visible: conn.networkAvailable && !!page.wifi.iface && (page.wifi.networks ?? []).length === 0
                text: "No Wi-Fi networks in range"
            }

            Row {
                visible: conn.networkAvailable && page.wifi.connection !== undefined && page.wifi.connection !== null
                highlight: true

                Glyph { text: page.strength(page.connected?.signal); color: Theme.on_secondary_container }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    StyledText { text: page.wifi.connection ?? ""; font.weight: Font.Medium; color: Theme.on_secondary_container }
                    StyledText { text: page.wifi.state ?? ""; font.pixelSize: Theme.fontSize - 2; color: Theme.on_secondary_container }
                }
                PillButton {
                    text: conn.wifiBusy === "disconnect" ? "Disconnecting…" : "Disconnect"
                    enabled: conn.wifiBusy === ""
                    onClicked: conn.wifiDisconnect()
                }
            }

            Repeater {
                model: conn.networkAvailable ? (page.wifi.networks ?? []).filter(n => !n.connected) : []

                ColumnLayout {
                    id: net
                    required property var modelData
                    readonly property bool asking: page.prompt === modelData.ssid
                    Layout.fillWidth: true
                    spacing: 4

                    Row {
                        Accessible.role: Accessible.Button
                        Accessible.name: "Connect to " + net.modelData.ssid + (net.modelData.secure ? ", secured" : "")

                        StateLayer {
                            parent: parent.parent
                            enabled: conn.wifiBusy === ""
                            onClicked: {
                                if (net.modelData.secure) page.prompt = net.asking ? "" : net.modelData.ssid
                                else conn.wifiConnect(net.modelData.ssid, "")
                            }
                        }
                        Glyph { text: page.strength(net.modelData.signal) }
                        StyledText { text: net.modelData.ssid; Layout.fillWidth: true }
                        StyledText {
                            visible: conn.wifiBusy === net.modelData.ssid
                            text: "Connecting…"
                            color: Theme.primary
                            font.pixelSize: Theme.fontSize - 2
                        }
                        Glyph { visible: net.modelData.secure; text: "\u{f033e}"; font.pixelSize: 14 }
                        StyledText {
                            text: net.modelData.signal + "%"
                            color: Theme.on_surface_variant
                            font.pixelSize: Theme.fontSize - 2
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    RowLayout {
                        visible: net.asking
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.pad
                        spacing: Theme.gap

                        Field {
                            id: password
                            Layout.fillWidth: true
                            echoMode: TextInput.Password
                            placeholderText: "Password, or leave empty if saved"
                            Accessible.name: "Password for " + net.modelData.ssid
                            onAccepted: connect.clicked()
                        }
                        PillButton {
                            text: "Cancel"
                            color: Theme.surface_container_highest
                            fg: Theme.on_surface
                            onClicked: page.prompt = ""
                        }
                        PillButton {
                            id: connect
                            text: "Connect"
                            enabled: conn.wifiBusy === ""
                            onClicked: {
                                conn.wifiConnect(net.modelData.ssid, password.text)
                                password.text = ""
                                page.prompt = ""
                            }
                        }
                    }
                }
            }
        }

        Card {
            Layout.fillWidth: true
            available: conn.bluetoothAvailable

            RowLayout {
                Layout.fillWidth: true
                Title { text: "Bluetooth" }
                PillButton {
                    visible: conn.bluetoothAvailable
                    text: conn.bluetoothBusy === "scan" ? "Scanning…" : "Scan"
                    enabled: conn.bluetoothBusy === ""
                    color: Theme.surface_container_highest
                    fg: Theme.on_surface
                    onClicked: conn.btScan()
                }
            }
            Note { visible: !conn.bluetoothAvailable; text: conn.bluetoothReason || "Checking Bluetooth…" }
            Error { text: conn.bluetoothAvailable ? conn.bluetoothError : "" }
            Note { visible: conn.bluetoothAvailable && (page.bt.paired ?? []).length === 0; text: "No paired devices" }

            Repeater {
                model: conn.bluetoothAvailable ? page.bt.paired ?? [] : []

                Row {
                    id: device
                    required property var modelData
                    highlight: modelData.connected

                    Glyph { text: device.modelData.connected ? "\u{f00b1}" : "\u{f00af}"; color: device.modelData.connected ? Theme.on_secondary_container : Theme.on_surface_variant }
                    StyledText {
                        text: device.modelData.name
                        color: device.modelData.connected ? Theme.on_secondary_container : Theme.on_surface
                        Layout.fillWidth: true
                    }
                    StyledText {
                        visible: conn.bluetoothBusy === device.modelData.mac
                        text: device.modelData.connected ? "Disconnecting…" : "Connecting…"
                        color: Theme.primary
                        font.pixelSize: Theme.fontSize - 2
                    }
                    Toggle {
                        checked: device.modelData.connected
                        enabled: conn.bluetoothBusy === ""
                        opacity: enabled ? 1 : 0.5
                        Accessible.role: Accessible.CheckBox
                        Accessible.name: device.modelData.name + (checked ? ", connected" : ", disconnected")
                        onToggled: checked ? conn.btDisconnect(device.modelData.mac) : conn.btConnect(device.modelData.mac)
                    }
                }
            }

            StyledText {
                visible: conn.bluetoothAvailable && (page.bt.nearby ?? []).length > 0
                text: "Nearby, pair them with bluetoothctl"
                color: Theme.on_surface_variant
                font.pixelSize: Theme.fontSize - 2
                Layout.topMargin: Theme.gap
            }
            Repeater {
                model: conn.bluetoothAvailable ? page.bt.nearby ?? [] : []

                Row {
                    required property var modelData

                    Glyph { text: "\u{f00af}" }
                    StyledText { text: parent.parent.modelData.name; Layout.fillWidth: true }
                    StyledText {
                        text: parent.parent.modelData.mac
                        color: Theme.on_surface_variant
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }
        }

        Card {
            Layout.fillWidth: true
            available: conn.audioAvailable

            Title { text: "Audio" }
            Note { visible: !conn.audioAvailable; text: "No audio server found" }
            Error { text: conn.audioAvailable ? conn.audioError : "" }

            RowLayout {
                visible: conn.audioAvailable && page.audio.volume !== undefined
                Layout.fillWidth: true
                spacing: Theme.pad

                Glyph {
                    text: page.audio.muted ? "\u{f0581}" : ["\u{f057f}", "\u{f0580}", "\u{f057e}"][Math.min(2, Math.floor(volume.value * 3))]
                    font.pixelSize: 22
                }
                Slider {
                    id: volume
                    Layout.fillWidth: true
                    stepSize: 0.01
                    Accessible.role: Accessible.Slider
                    Accessible.name: "Volume"
                    onReleased: v => conn.setVolume(v)
                }
                StyledText {
                    text: Math.round(volume.value * 100) + "%"
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignRight
                }
                StyledText { text: "Mute"; color: Theme.on_surface_variant }
                Toggle {
                    checked: page.audio.muted ?? false
                    Accessible.role: Accessible.CheckBox
                    Accessible.name: "Mute"
                    onToggled: conn.toggleMute()
                }
            }

            StyledText {
                visible: conn.audioAvailable && (page.audio.sinks ?? []).length > 1
                text: "Output"
                color: Theme.on_surface_variant
                font.pixelSize: Theme.fontSize - 2
                Layout.topMargin: Theme.gap
            }
            Flow {
                visible: conn.audioAvailable && (page.audio.sinks ?? []).length > 1
                Layout.fillWidth: true
                spacing: Theme.gap

                Repeater {
                    model: page.audio.sinks ?? []

                    PillButton {
                        required property var modelData
                        readonly property bool on: modelData.name === page.audio.default
                        text: modelData.description
                        color: on ? Theme.primary : Theme.surface_container_highest
                        fg: on ? Theme.on_primary : Theme.on_surface
                        Accessible.name: modelData.description + (on ? ", current output" : "")
                        onClicked: if (!on) conn.setSink(modelData.name)
                    }
                }
            }
        }
    }
}
