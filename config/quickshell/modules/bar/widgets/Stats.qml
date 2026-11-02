import QtQuick
import qs.config
import qs.components
import qs.services

// Compact system readings, picked with [widgets.stats] show = ["cpu", "mem", "gpu", "temp"].
// Each turns tertiary above 70% and error above 90%.
Pill {
    id: root
    widget: "stats"
    spacing: Theme.px(12)

    readonly property var items: ({
        cpu: { icon: Theme.icon.cpu, text: Math.round(SysStats.cpu * 100) + "%", value: SysStats.cpu },
        mem: { icon: Theme.icon.memory, text: Math.round(SysStats.mem * 100) + "%", value: SysStats.mem },
        gpu: { icon: Theme.icon.gpu, text: Math.round(SysStats.gpu * 100) + "%", value: SysStats.gpu, hidden: !SysStats.hasGpu },
        temp: { icon: Theme.icon.thermometer, text: Math.round(SysStats.cpuTemp) + "°", value: SysStats.cpuTemp / 100, hidden: isNaN(SysStats.cpuTemp) }
    })
    tooltip: `${SysStats.cpuName}\nMemory ${(SysStats.memUsed / 1073741824).toFixed(1)} of ${(SysStats.memTotal / 1073741824).toFixed(1)} GiB`

    Repeater {
        model: (root.cfg.show ?? ["cpu", "mem"]).filter(k => root.items[k] && !root.items[k].hidden)

        Row {
            required property string modelData
            readonly property var item: root.items[modelData]
            readonly property color tint: item.value > 0.9 ? Theme.error : item.value > 0.7 ? Theme.tertiary : root.fg
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.px(5)
            Icon { text: parent.item.icon; color: parent.tint; font.pixelSize: Theme.px(16); anchors.verticalCenter: parent.verticalCenter }
            StyledText {
                text: parent.item.text
                color: parent.tint
                font.weight: Font.Medium
                font.features: { "tnum": 1 }
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
