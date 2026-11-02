import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// CPU, memory and GPU gauges, per-thread load, then VRAM, disk and GPU power.
Card {
    id: root
    widget: "system"

    // >70% shifts to tertiary, >90% to error
    function level(v) { return v > 0.9 ? Theme.error : v > 0.7 ? Theme.tertiary : root.accent }
    function gib(bytes) { return (bytes / 1073741824).toFixed(1) }

    CardHeader {
        icon: Theme.icon.cpu
        title: SysStats.cpuName
        accent: root.accent
        StyledText {
            readonly property int mins: Math.floor(SysStats.uptime / 60)
            text: "up " + (mins >= 1440 ? Math.floor(mins / 1440) + "d " : "") + Math.floor(mins % 1440 / 60) + "h " + mins % 60 + "m"
            color: Theme.on_surface_variant
            font.pixelSize: Theme.fontSmall
        }
    }

    component Gauge: ColumnLayout {
        id: gauge
        property real value
        property string label
        property string detail
        property bool available: true
        spacing: Theme.px(4)
        Layout.fillWidth: true

        Item {
            implicitWidth: Theme.px(92)
            implicitHeight: Theme.px(92)
            Layout.alignment: Qt.AlignHCenter
            Ring { anchors.fill: parent; value: gauge.available ? gauge.value : 0; thickness: Theme.px(8); color: root.level(gauge.value) }
            StyledText {
                anchors.centerIn: parent
                text: gauge.available ? Math.round(gauge.value * 100) + "%" : "—"
                font.pixelSize: Theme.px(20)
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
        }
        StyledText { text: gauge.label; font.weight: Font.Medium; Layout.alignment: Qt.AlignHCenter }
        StyledText { text: gauge.detail; color: Theme.on_surface_variant; font.pixelSize: Theme.fontTiny; Layout.alignment: Qt.AlignHCenter }
    }

    RowLayout {
        spacing: 0
        Gauge {
            label: "CPU"
            value: SysStats.cpu
            detail: (isNaN(SysStats.cpuTemp) ? "" : Math.round(SysStats.cpuTemp) + "°C  ·  ") + SysStats.ghz.toFixed(1) + " GHz"
        }
        Gauge {
            label: "Memory"
            value: SysStats.mem
            detail: `${root.gib(SysStats.memUsed)} / ${root.gib(SysStats.memTotal)} GiB`
        }
        Gauge {
            label: "GPU"
            available: SysStats.hasGpu
            value: SysStats.gpu
            detail: isNaN(SysStats.gpuTemp) ? "" : Math.round(SysStats.gpuTemp) + "°C"
        }
    }

    // Per-thread load
    ColumnLayout {
        spacing: Theme.px(6)
        RowLayout {
            StyledText { text: "Threads"; color: Theme.on_surface_variant; font.pixelSize: Theme.fontSmall; Layout.fillWidth: true }
            StyledText { text: SysStats.cores.length; color: Theme.outline; font.pixelSize: Theme.fontSmall }
        }
        Row {
            id: threads
            Layout.fillWidth: true
            height: Theme.px(36)
            spacing: Theme.px(4)
            readonly property real barW: SysStats.cores.length ? (width - spacing * (SysStats.cores.length - 1)) / SysStats.cores.length : 0

            Repeater {
                model: SysStats.cores
                Rectangle {
                    required property real modelData
                    width: threads.barW
                    height: threads.height
                    radius: Math.min(width / 2, Theme.px(4))
                    color: Theme.layerHigh

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(Theme.px(4), parent.height * modelData)
                        radius: parent.radius
                        color: root.level(modelData)
                        Behavior on height { Anim {} }
                        Behavior on color { CAnim {} }
                    }
                }
            }
        }
    }

    component Stat: RowLayout {
        property string icon
        property string label
        property string text
        property real value: -1
        spacing: Theme.gap
        Layout.fillWidth: true
        Icon { text: parent.icon; color: root.accent; font.pixelSize: Theme.px(16); Layout.preferredWidth: Theme.px(20) }
        StyledText { text: parent.label; color: Theme.on_surface_variant; Layout.preferredWidth: Theme.px(52) }
        Meter { visible: parent.value >= 0; value: parent.value; fill: root.level(parent.value); Layout.fillWidth: true }
        Item { visible: parent.value < 0; Layout.fillWidth: true }
        StyledText { text: parent.text; font.pixelSize: Theme.fontSmall; font.features: { "tnum": 1 } }
    }

    ColumnLayout {
        spacing: Theme.gap
        Stat {
            visible: SysStats.hasGpu && SysStats.vramTotal > 0
            icon: Theme.icon.memory; label: "VRAM"
            value: SysStats.vramUsed / SysStats.vramTotal
            text: `${root.gib(SysStats.vramUsed)} / ${root.gib(SysStats.vramTotal)} GiB`
        }
        Stat { icon: Theme.icon.disk; label: "Disk"; value: SysStats.disk; text: `${root.gib(SysStats.diskUsed)} / ${root.gib(SysStats.diskSize)} GiB` }
        Stat {
            visible: !isNaN(SysStats.gpuPower)
            icon: Theme.icon.bolt; label: "Power"
            text: SysStats.gpuPower.toFixed(0) + " W" + (isNaN(SysStats.gpuFan) ? "" : "  ·  " + SysStats.gpuFan + " rpm")
        }
    }
}
