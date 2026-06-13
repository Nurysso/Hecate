import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../utils"

Item {
    id: root

    property real cpuPercent: 0
    property real ramPercent: 0

    implicitWidth: pill.implicitWidth
    implicitHeight: 28

    // Processes

    Component {
        id: cpuProc
        Process {
            running: true
            command: ["sh", "-c", "top -bn2 -d 0.3 | grep 'Cpu(s)' | tail -1 | awk '{print $2}' | cut -d'%' -f1"]
            stdout: SplitParser {
                onRead: data => {
                    const v = parseFloat(data.trim())
                    if (!isNaN(v)) root.cpuPercent = Math.min(v / 100, 1.0)
                }
            }
        }
    }

    Component {
        id: ramProc
        Process {
            running: true
            command: ["sh", "-c", "free | awk '/Mem/{printf \"%.1f\", ($3/$2)*100}'"]
            stdout: SplitParser {
                onRead: data => {
                    const v = parseFloat(data.trim())
                    if (!isNaN(v)) root.ramPercent = Math.min(v / 100, 1.0)
                }
            }
        }
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.createObject(root)
            ramProc.createObject(root)
        }
    }

    // UI

    Rectangle {
        id: pill
        implicitWidth: row.implicitWidth + 12
        implicitHeight: 24
        anchors.centerIn: parent
        radius: 6
        color: Qt.rgba(1, 1, 1, 0.04)
        border.width: 0.5
        border.color: Qt.rgba(1, 1, 1, 0.07)

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6

            // CPU ring + label
            RingIndicator {
                value: root.cpuPercent
                ringColor: ColorManager.accentColor
                label: "C"
            }
            Text {
                text: Math.round(root.cpuPercent * 100) + "%"
                color: ColorManager.mutedColor
                font.pixelSize: 11
                font.family: ColorManager.fontFamily
            }

            // RAM ring + label
            RingIndicator {
                value: root.ramPercent
                ringColor: "#89ddff"
                label: "M"
            }
            Text {
                text: Math.round(root.ramPercent * 100) + "%"
                color: ColorManager.mutedColor
                font.pixelSize: 11
                font.family: ColorManager.fontFamily
            }
        }
    }

    // Ring sub-component

    component RingIndicator: Item {
        property real value: 0
        property color ringColor: ColorManager.accentColor
        property string label: ""

        Layout.preferredWidth: 18
        Layout.preferredHeight: 18

        Canvas {
            id: cv
            anchors.fill: parent

            property real val: parent.value
            property color rc: parent.ringColor

            onValChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                const cx = width / 2, cy = height / 2, r = (width - 2.5) / 2
                const start = -Math.PI / 2

                // Track
                ctx.lineWidth = 2; ctx.lineCap = "round"
                ctx.strokeStyle = "#2a2a35"
                ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.stroke()

                // Fill
                if (val > 0) {
                    ctx.strokeStyle = rc.toString()
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, start, start + 2 * Math.PI * val)
                    ctx.stroke()
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: parent.label
            font.pixelSize: 7
            font.weight: Font.Bold
            color: "#888"
        }
    }
}
