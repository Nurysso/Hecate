// widgets/SystemInfoWidget.qml - Dial-based system information widget
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root

    implicitWidth: 420
    implicitHeight: 480
    visible: true
    color: "transparent"
    mask: Region { item: container }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-sysinfo"

    anchors {
        top: true
        left: true
    }
    margins {
        top: 20
    }

    // Colors
    property string primaryColor: ColorManager.primaryColor
    property string accentColor: ColorManager.accentColor
    property string mutedColor: ColorManager.mutedColor
    property string warningColor: "#E5A564"
    property string criticalColor: "#E55564"

    // CPU metrics
    property real cpuUsage: 0
    property real cpuTemp: 0
    property string cpuFreq: "0.0 GHz"
    property var cpuCores: []

    // RAM metrics
    property real ramUsage: 0
    property real ramTotal: 16
    property real ramUsed: 0

    // GPU metrics
    property real gpuUsage: 0
    property real gpuTemp: 0
    property real gpuPower: 0
    property real gpuMemUsed: 0
    property real gpuMemTotal: 8
    property string gpuName: "AMD GPU"

    Component.onCompleted: {
        let cores = []
        for (let i = 0; i < 16; i++) cores.push(0)
        cpuCores = cores
    }

    // CPU Usage
    Process {
        id: cpuReader
        command: ["sh", "-c", "top -bn2 -d 0.5 | grep '%Cpu' | tail -n1 | awk '{print 100-$8}'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const usage = parseFloat(data.trim())
                if (!isNaN(usage)) cpuUsage = usage
            }
        }
    }

    // CPU Frequency
    Process {
        id: cpuFreqReader
        command: ["sh", "-c", "grep 'cpu MHz' /proc/cpuinfo | head -n1 | awk '{printf \"%.2f GHz\", $4/1000}'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const freq = data.trim()
                if (freq.length > 0) cpuFreq = freq
            }
        }
    }

    // CPU Temperature
    Process {
        id: cpuTempReader
        command: ["sh", "-c", "sensors | grep -E 'Tctl|Tdie|Package id' | head -n1 | grep -oP '\\+\\K[0-9.]+' | head -n1"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const temp = parseFloat(data.trim())
                if (!isNaN(temp)) cpuTemp = temp
            }
        }
    }

    // Per-core CPU usage
    Process {
        id: cpuCoresReader
        command: ["sh", "-c", "mpstat -P ALL 1 1 | awk '/Average/ && $2 ~ /[0-9]/ {print 100-$NF}'"]
        running: false
        property string coresData: ""
        stdout: SplitParser { onRead: data => coresData += data }
        onRunningChanged: {
            if (!running && coresData) {
                const lines = coresData.trim().split('\n')
                let cores = []
                for (let i = 0; i < lines.length && i < 32; i++) {
                    const usage = parseFloat(lines[i])
                    if (!isNaN(usage)) cores.push(usage)
                }
                if (cores.length > 0) cpuCores = cores
                coresData = ""
            }
        }
    }

    // RAM Usage
    Process {
        id: ramReader
        command: ["sh", "-c", "free -g | awk '/^Mem:/ {printf \"%.1f %.1f\", $3, $2}'"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(' ')
                if (parts.length >= 2) {
                    ramUsed = parseFloat(parts[0])
                    ramTotal = parseFloat(parts[1])
                    ramUsage = (ramUsed / ramTotal) * 100
                }
            }
        }
    }

    // GPU Info
    Process {
        id: gpuReader
        command: ["sh", "-c", "GPU_USAGE=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -n1); GPU_TEMP=$(sensors 2>/dev/null | grep -i 'edge\\|junction' | head -n1 | grep -oP '\\+\\K[0-9.]+' | head -n1); GPU_POWER=$(cat /sys/class/drm/card*/device/hwmon/hwmon*/power1_average 2>/dev/null | head -n1); if [ -n \"$GPU_POWER\" ]; then GPU_POWER=$(echo \"scale=1; $GPU_POWER / 1000000\" | bc); else GPU_POWER=0; fi; VRAM_USED=$(cat /sys/class/drm/card*/device/mem_info_vram_used 2>/dev/null | head -n1); VRAM_TOTAL=$(cat /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null | head -n1); if [ -n \"$VRAM_USED\" ] && [ -n \"$VRAM_TOTAL\" ]; then VRAM_USED_GB=$(echo \"scale=2; $VRAM_USED / 1073741824\" | bc); VRAM_TOTAL_GB=$(echo \"scale=2; $VRAM_TOTAL / 1073741824\" | bc); else VRAM_USED_GB=0; VRAM_TOTAL_GB=8; fi; GPU_NAME=$(lspci | grep -i vga | grep -i amd | cut -d':' -f3 | xargs); [ -z \"$GPU_NAME\" ] && GPU_NAME=\"AMD GPU\"; echo \"${GPU_USAGE:-0},${GPU_TEMP:-0},${GPU_POWER:-0},${VRAM_USED_GB:-0},${VRAM_TOTAL_GB:-8},${GPU_NAME}\""]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(',')
                if (parts.length >= 6) {
                    gpuUsage = parseFloat(parts[0])
                    gpuTemp = parseFloat(parts[1])
                    gpuPower = parseFloat(parts[2])
                    gpuMemUsed = parseFloat(parts[3])
                    gpuMemTotal = parseFloat(parts[4])
                    gpuName = parts[5] || "AMD GPU"
                }
            }
        }
    }

    // Update timer
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuReader.running = true
            cpuFreqReader.running = true
            cpuTempReader.running = true
            ramReader.running = true
            gpuReader.running = true
            if (Math.random() < 0.5) cpuCoresReader.running = true
        }
    }

    Item {
        id: container
        anchors.fill: parent

Grid {
    anchors.fill: parent
    columns: 2        // two items per row
    rowSpacing: 20
    columnSpacing: 20

            // CPU Dial
            Item {
                  width: parent.width / 2 - 20
                height: 140

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Item {
                        width: 120
                        height: 120
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Background circle
                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.lineWidth = 8
                                ctx.strokeStyle = root.mutedColor
                                ctx.globalAlpha = 0.2
                                ctx.beginPath()
                                ctx.arc(width/2, height/2, 50, 0.75 * Math.PI, 2.25 * Math.PI)
                                ctx.stroke()
                            }
                        }

                        // Progress arc
                        Canvas {
                            id: cpuCanvas
                            anchors.fill: parent

                            property real value: root.cpuUsage
                            property string dialColor: root.cpuUsage > 80 ? root.criticalColor :
                                                       root.cpuUsage > 60 ? root.warningColor :
                                                       root.accentColor
                            onValueChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                ctx.lineWidth = 8
                                ctx.strokeStyle = color
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                var startAngle = 0.75 * Math.PI
                                var endAngle = startAngle + (1.5 * Math.PI * (value / 100))
                                ctx.arc(width/2, height/2, 50, startAngle, endAngle)
                                ctx.stroke()
                            }

                            Behavior on value {
                                NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
                            }
                        }

                        // Center content
                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: root.cpuUsage.toFixed(0) + "%"
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                font.family: "monospace"
                                color: root.primaryColor
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "CPU"
                                font.pixelSize: 11
                                color: root.mutedColor
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16

                        Text {
                            text: root.cpuFreq
                            font.pixelSize: 12
                            font.family: "monospace"
                            color: root.mutedColor
                        }

                        Text {
                            text: root.cpuTemp.toFixed(0) + "°C"
                            font.pixelSize: 12
                            font.family: "monospace"
                            color: root.cpuTemp > 85 ? root.criticalColor :
                                   root.cpuTemp > 75 ? root.warningColor :
                                   root.mutedColor
                        }
                    }
                }
            }

            // RAM Dial
            Item {
                        width: parent.width / 2 - 20

                height: 140

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Item {
                        width: 120
                        height: 120
                        anchors.horizontalCenter: parent.horizontalCenter

                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.lineWidth = 8
                                ctx.strokeStyle = root.mutedColor
                                ctx.globalAlpha = 0.2
                                ctx.beginPath()
                                ctx.arc(width/2, height/2, 50, 0.75 * Math.PI, 2.25 * Math.PI)
                                ctx.stroke()
                            }
                        }

                        Canvas {
                            id: ramCanvas
                            anchors.fill: parent

                            property real value: root.ramUsage

                            // Add explicit color property that updates immediately
                            property string dialColor: root.ramUsage > 85 ? root.criticalColor :
                                                    root.ramUsage > 70 ? root.warningColor :
                                                    root.accentColor

                            onValueChanged: requestPaint()
                            onDialColorChanged: requestPaint()  // Add this trigger

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                // Use the property instead of calculating inline
                                ctx.lineWidth = 8
                                ctx.strokeStyle = dialColor
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                var startAngle = 0.75 * Math.PI
                                var endAngle = startAngle + (1.5 * Math.PI * (value / 100))
                                ctx.arc(width/2, height/2, 50, startAngle, endAngle)
                                ctx.stroke()
                            }

                            Behavior on value {
                                NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: root.ramUsage.toFixed(0) + "%"
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                font.family: "monospace"
                                color: root.primaryColor
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "RAM"
                                font.pixelSize: 11
                                color: root.mutedColor
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    Text {
                        text: root.ramUsed.toFixed(1) + " / " + root.ramTotal.toFixed(0) + " GB"
                        font.pixelSize: 12
                        font.family: "monospace"
                        color: root.mutedColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // GPU Dial
            Item {
                        width: parent.width / 2 - 20

                height: 140

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Item {
                        width: 120
                        height: 120
                        anchors.horizontalCenter: parent.horizontalCenter

                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.lineWidth = 8
                                ctx.strokeStyle = root.mutedColor
                                ctx.globalAlpha = 0.2
                                ctx.beginPath()
                                ctx.arc(width/2, height/2, 50, 0.75 * Math.PI, 2.25 * Math.PI)
                                ctx.stroke()
                            }
                        }

                        Canvas {
                            id: gpuCanvas
                            anchors.fill: parent

                            property real value: root.gpuUsage
                             property string dialColor: root.gpuUsage > 80 ? root.criticalColor :
                                                    root.gpuUsage > 60 ? root.warningColor :
                                                    root.accentColor
                            onValueChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.lineWidth = 8
                                ctx.strokeStyle = dialColor
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                var startAngle = 0.75 * Math.PI
                                var endAngle = startAngle + (1.5 * Math.PI * (value / 100))
                                ctx.arc(width/2, height/2, 50, startAngle, endAngle)
                                ctx.stroke()
                            }

                            Behavior on value {
                                NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: root.gpuUsage.toFixed(0) + "%"
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                font.family: "monospace"
                                color: root.primaryColor
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "GPU"
                                font.pixelSize: 11
                                color: root.mutedColor
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16

                        Text {
                            visible: root.gpuPower > 0
                            text: root.gpuPower.toFixed(0) + "W"
                            font.pixelSize: 12
                            font.family: "monospace"
                            color: root.mutedColor
                        }

                        Text {
                            text: root.gpuTemp.toFixed(0) + "°C"
                            font.pixelSize: 12
                            font.family: "monospace"
                            color: root.gpuTemp > 85 ? root.criticalColor :
                                   root.gpuTemp > 75 ? root.warningColor :
                                   root.mutedColor
                        }

                        Text {
                            text: root.gpuMemUsed.toFixed(1) + "GB"
                            font.pixelSize: 12
                            font.family: "monospace"
                            color: root.mutedColor
                        }
                    }
                }
            }
        }
    }
}
