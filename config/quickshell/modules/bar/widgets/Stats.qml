import QtQuick
import qs.config
import qs.components
import qs.services

// Compact system readings, picked with [widgets.stats] show = ["cpu", "mem", "gpu", "temp"].
Pill {
    id: root
    widget: "stats"

    readonly property var items: ({
        cpu: { icon: Theme.icon.cpu, text: Math.round(SysStats.cpu * 100) + "%", value: SysStats.cpu },
        mem: { icon: Theme.icon.memory, text: Math.round(SysStats.mem * 100) + "%", value: SysStats.mem },
        gpu: { icon: Theme.icon.gpu, text: Math.round(SysStats.gpu * 100) + "%", value: SysStats.gpu, hidden: !SysStats.hasGpu },
        temp: { icon: Theme.icon.thermometer, text: Math.round(SysStats.cpuTemp) + "°", value: SysStats.cpuTemp / 100, hidden: isNaN(SysStats.cpuTemp) }
    })

    Repeater {
        model: (Config.widget(root.widget).show ?? ["cpu", "mem"]).filter(k => root.items[k] && !root.items[k].hidden)

        Row {
            required property string modelData
            readonly property var item: root.items[modelData]
            readonly property color tint: item.value > 0.9 ? Theme.error : item.value > 0.7 ? Theme.tertiary : root.fg
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Icon { text: parent.item.icon; color: parent.tint; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
            StyledText {
                text: parent.item.text
                color: parent.tint
                font.features: { "tnum": 1 }
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
