import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Quick settings, hanging under the status widget: toggles, output and input volume (the arrow picks
// the device, the icon mutes), what's playing, and the batteries of connected devices.
Panel {
    id: root
    name: "control"
    contentWidth: Theme.px(420)

    ColumnLayout {
        id: content
        spacing: Theme.px(14)
        property string expanded: ""   // "sink" or "source" while its device list is open
        property real uptime

        FileView { path: "/proc/uptime"; onLoaded: content.uptime = parseFloat(text()) }

        // You, and the session
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.px(4)

            Avatar { Layout.rightMargin: Theme.px(8) }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText { Layout.fillWidth: true; text: Quickshell.env("USER"); font.pixelSize: Theme.fontLarge; font.weight: Font.DemiBold }
                StyledText {
                    readonly property int mins: Math.floor(content.uptime / 60)
                    text: "up " + (mins >= 1440 ? Math.floor(mins / 1440) + "d " : "") + Math.floor(mins % 1440 / 60) + "h " + mins % 60 + "m"
                    color: Theme.on_surface_variant
                    font.pixelSize: Theme.fontSmall
                }
            }
            IconButton { icon: Theme.icon.palette; onClicked: GlobalStates.open("wallpaper") }
            IconButton {
                readonly property var app: DesktopEntries.heuristicLookup("hecate-settings")
                visible: !!app
                icon: Theme.icon.settings
                onClicked: {
                    app.execute()
                    GlobalStates.close()
                }
            }
            IconButton {
                icon: Theme.icon.lock
                onClicked: {
                    GlobalStates.close()
                    Quickshell.execDetached([Config.home + "/.config/hypr/scripts/power.sh", "lock"])
                }
            }
            IconButton { icon: Theme.icon.power; onClicked: GlobalStates.open("power") }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            uniformCellWidths: true
            rowSpacing: Theme.gap
            columnSpacing: Theme.gap

            QuickToggle {
                Layout.fillWidth: true
                accent: root.accent
                icon: Net.icon
                title: Net.wired ? "Network" : "Wi-Fi"
                subtitle: Net.label
                checked: Net.wired || Networking.wifiEnabled
                more: true
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                onExpand: GlobalStates.switchTo("connectivity")
            }
            QuickToggle {
                Layout.fillWidth: true
                accent: root.accent
                icon: Net.btIcon
                title: "Bluetooth"
                subtitle: Net.btLabel
                checked: Net.adapter?.enabled ?? false
                more: !!Net.adapter
                onToggled: if (Net.adapter) Net.adapter.enabled = !Net.adapter.enabled
                onExpand: GlobalStates.switchTo("connectivity")
            }
            QuickToggle {
                Layout.fillWidth: true
                accent: root.accent
                icon: GlobalStates.dnd ? Theme.icon.bellOff : Theme.icon.bell
                title: "Do not disturb"
                subtitle: GlobalStates.dnd ? "Popups held back" : "Off"
                checked: GlobalStates.dnd
                onToggled: GlobalStates.dnd = !GlobalStates.dnd
            }
            QuickToggle {
                Layout.fillWidth: true
                accent: root.accent
                icon: GlobalStates.caffeine ? Theme.icon.coffee : Theme.icon.coffeeOff
                title: "Keep awake"
                subtitle: GlobalStates.caffeine ? "Screen stays on" : "Off"
                checked: GlobalStates.caffeine
                onToggled: GlobalStates.caffeine = !GlobalStates.caffeine
            }
            QuickToggle {
                // power-profiles-daemon; balanced reads as off
                readonly property var order: PowerProfiles.hasPerformanceProfile
                    ? [PowerProfile.Balanced, PowerProfile.Performance, PowerProfile.PowerSaver] : [PowerProfile.Balanced, PowerProfile.PowerSaver]
                Layout.fillWidth: true
                accent: root.accent
                icon: [Theme.icon.powerSaver, Theme.icon.balanced, Theme.icon.performance][PowerProfiles.profile] ?? Theme.icon.balanced
                title: "Power mode"
                subtitle: ["Power saver", "Balanced", "Performance"][PowerProfiles.profile] ?? ""
                checked: PowerProfiles.profile !== PowerProfile.Balanced
                onToggled: PowerProfiles.profile = order[(order.indexOf(PowerProfiles.profile) + 1) % order.length]
            }
            QuickToggle {
                Layout.fillWidth: true
                visible: Hyprland.usingLua
                accent: root.accent
                icon: Theme.icon.gamepad
                title: "Game mode"
                subtitle: GlobalStates.gamemode ? "Effects off" : "Off"
                checked: GlobalStates.gamemode
                onToggled: Hypr.setGamemode(!GlobalStates.gamemode)
            }
        }

        component Volume: ColumnLayout {
            id: vol
            property bool input
            readonly property var node: input ? Audio.source : Audio.sink
            readonly property bool muted: input ? Audio.micMuted : Audio.muted
            readonly property real value: input ? Audio.micVolume : Audio.volume
            readonly property var devices: input ? Audio.sources : Audio.sinks
            readonly property bool open: content.expanded === (input ? "source" : "sink")

            Layout.fillWidth: true
            visible: !!node
            spacing: Theme.px(4)

            RowLayout {
                spacing: Theme.px(8)
                Slider {
                    Layout.fillWidth: true
                    value: vol.value
                    max: vol.input ? 1 : Audio.max
                    step: Audio.step
                    icon: vol.input ? Audio.micIcon : Audio.icon
                    fill: vol.muted ? Theme.outline : root.accent
                    onMoved: v => vol.input ? Audio.setMic(v) : Audio.setVolume(v)
                    onIconClicked: vol.input ? Audio.toggleMic() : Audio.toggleMute()
                }
                StyledText {
                    Layout.preferredWidth: Theme.px(40)
                    horizontalAlignment: Text.AlignRight
                    text: vol.muted ? "Off" : Math.round(vol.value * 100) + "%"
                    color: Theme.on_surface_variant
                    font.pixelSize: Theme.fontSmall
                    font.features: { "tnum": 1 }
                }
                IconButton {
                    size: Theme.px(32)
                    enabled: vol.devices.length > 1
                    icon: vol.open ? Theme.icon.chevronUp : Theme.icon.chevronDown
                    onClicked: content.expanded = vol.open ? "" : vol.input ? "source" : "sink"
                }
            }

            Repeater {
                model: vol.open ? vol.devices : []
                Tile {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Theme.px(40)
                    iconSize: Theme.px(22)
                    icon: vol.input ? Theme.icon.mic : Theme.icon.speaker
                    title: Audio.name(modelData)
                    selected: modelData === vol.node
                    fg: selected ? root.accent : Theme.on_surface
                    onClicked: {
                        if (vol.input) Pipewire.preferredDefaultAudioSource = modelData
                        else Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
            }
        }

        Volume {}
        Volume { input: true }

        // What's playing
        Rectangle {
            readonly property var player: Players.active
            visible: !!player
            Layout.fillWidth: true
            implicitHeight: media.implicitHeight + Theme.px(24)
            radius: Theme.radiusSmall
            color: Theme.layer

            // MPRIS doesn't push position updates
            Timer { running: Players.playing; repeat: true; interval: 1000; onTriggered: Players.active?.positionChanged() }

            RowLayout {
                id: media
                anchors.fill: parent
                anchors.margins: Theme.px(12)
                spacing: Theme.px(12)

                ClippingRectangle {
                    implicitWidth: Theme.px(56)
                    implicitHeight: Theme.px(56)
                    radius: Theme.radiusTiny + Theme.px(2)
                    color: Theme.layerHigh
                    Icon { anchors.centerIn: parent; visible: art.status !== Image.Ready; text: Theme.icon.music; color: root.accent; font.pixelSize: Theme.px(24) }
                    Image {
                        id: art
                        anchors.fill: parent
                        source: Players.active?.trackArtUrl ?? ""
                        sourceSize.width: Theme.px(112)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.px(2)
                    StyledText { Layout.fillWidth: true; text: Players.active?.trackTitle || "Unknown title"; font.weight: Font.DemiBold }
                    StyledText {
                        Layout.fillWidth: true
                        text: Players.active?.trackArtist || Players.active?.identity || ""
                        color: Theme.on_surface_variant
                        font.pixelSize: Theme.fontSmall
                    }
                    Meter {
                        Layout.fillWidth: true
                        Layout.topMargin: Theme.px(6)
                        implicitHeight: Theme.px(4)
                        visible: Players.active?.lengthSupported ?? false
                        value: Players.active && Players.active.length > 0 ? Players.active.position / Players.active.length : 0
                        fill: root.accent
                    }
                }

                IconButton { size: Theme.px(34); icon: Theme.icon.prev; enabled: Players.active?.canGoPrevious ?? false; onClicked: Players.control("previous") }
                IconButton {
                    size: Theme.px(40)
                    filled: true
                    accent: root.accent
                    icon: Players.playing ? Theme.icon.pause : Theme.icon.play
                    onClicked: Players.control("play-pause")
                }
                IconButton { size: Theme.px(34); icon: Theme.icon.next; enabled: Players.active?.canGoNext ?? false; onClicked: Players.control("next") }
            }
        }

        // Batteries of mice, keyboards, headsets and the like that UPower knows about
        Flow {
            readonly property var devices: UPower.devices.values.filter(d => !d.isLaptopBattery && d.isPresent && d.percentage > 0 && d.type !== UPowerDeviceType.LinePower)
            visible: devices.length > 0
            Layout.fillWidth: true
            spacing: Theme.gap

            Repeater {
                model: parent.devices

                Rectangle {
                    id: device
                    required property var modelData
                    readonly property real level: modelData.percentage > 1 ? modelData.percentage / 100 : modelData.percentage
                    readonly property string model: modelData.model ?? ""
                    // UPower files some devices under the wrong type (Logitech receivers call a mouse a
                    // keyboard), so the model name decides when it says what the thing is
                    readonly property string kind: /mouse/i.test(model) ? "mouse" : /keyboard/i.test(model) ? "keyboard"
                        : /head(set|phone)|buds|earphone/i.test(model) ? "headphones"
                        : ({ [UPowerDeviceType.Mouse]: "mouse", [UPowerDeviceType.Keyboard]: "keyboard", [UPowerDeviceType.Headset]: "headphones",
                             [UPowerDeviceType.Headphones]: "headphones", [UPowerDeviceType.Phone]: "phone", [UPowerDeviceType.GamingInput]: "gamepad" })[modelData.type] ?? ""
                    readonly property string name: model.replace(/PID:\S+/i, "").replace(/\b(logitech|wireless|bluetooth|usb)\b/gi, "").replace(/\s+/g, " ").trim()
                        || (kind ? kind[0].toUpperCase() + kind.slice(1) : "Device")
                    // Devices that only know a rough level (no capacity file, just capacity_level) get a word,
                    // since UPower's percentage for them is a placeholder
                    readonly property string sysfs: "/sys/class/power_supply/" + modelData.nativePath
                    property bool exact: true
                    property string rough
                    readonly property bool low: exact ? level <= 0.15 : ["Low", "Critical"].includes(rough)

                    FileView { path: device.sysfs + "/capacity"; printErrors: false; onLoadFailed: device.exact = false }
                    FileView { path: device.sysfs + "/capacity_level"; printErrors: false; onLoaded: device.rough = text().trim() }

                    implicitWidth: chip.implicitWidth + Theme.px(22)
                    implicitHeight: Theme.px(32)
                    radius: height / 2
                    color: Theme.layer

                    Row {
                        id: chip
                        anchors.centerIn: parent
                        spacing: Theme.px(6)
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Theme.px(16)
                            color: device.low ? Theme.error : Theme.on_surface
                            text: device.kind ? Theme.icon[device.kind] : Theme.icon.battery[Math.min(5, Math.floor(device.level * 6))]
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: device.name
                            font.pixelSize: Theme.fontSmall
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: device.exact || !device.rough || device.rough === "Unknown" ? Math.round(device.level * 100) + "%"
                                : ({ Normal: "Good" })[device.rough] ?? device.rough
                            color: device.low ? Theme.error : Theme.on_surface_variant
                            font.pixelSize: Theme.fontSmall
                            font.features: { "tnum": 1 }
                        }
                    }
                }
            }
        }
    }
}
