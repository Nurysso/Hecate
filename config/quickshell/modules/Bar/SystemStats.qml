import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: systemUsageContainer

    property bool isHorizontal: true
    property bool cpuEnabled: true
    property bool memoryEnabled: true
    property bool tempEnabled: true

    // Actual system data
    property real cpuPercent: 0
    property real ramPercent: 0
    // property real cpuTempPercent: 0

    implicitWidth: bgRect.implicitWidth
    implicitHeight: bgRect.implicitHeight

    // CPU Usage Process Component
    Component {
        id: cpuProcessComponent
        Process {
            running: true
            command: ["sh", "-c", "top -bn2 -d 0.5 | grep 'Cpu(s)' | tail -1 | awk '{print $2}' | cut -d'%' -f1"]

            stdout: SplitParser {
                onRead: function(data) {
                    var usage = parseFloat(data.trim());
                    if (!isNaN(usage)) {
                        cpuPercent = usage / 100;
                    }
                }
            }
        }
    }

    // RAM Usage Process Component
    Component {
        id: ramProcessComponent
        Process {
            running: true
            command: ["sh", "-c", "free | grep Mem | awk '{print ($3/$2) * 100.0}'"]

            stdout: SplitParser {
                onRead: function(data) {
                    var usage = parseFloat(data.trim());
                    if (!isNaN(usage)) {
                        ramPercent = usage / 100;
                    }
                }
            }
        }
    }

    // Temperature Process Component
    // Component {
    //     id: tempProcessComponent
    //     Process {
    //         running: true
    //         command: ["sh", "-c", "sensors 2>/dev/null | grep -E 'Package id 0|Tdie|Tctl' | head -1 | awk '{print $4}' | sed 's/+//;s/°C//' || echo '0'"]

    //         stdout: SplitParser {
    //             onRead: function(data) {
    //                 var temp = parseFloat(data.trim());
    //                 if (!isNaN(temp) && temp > 0) {
    //                     cpuTempPercent = Math.min(temp / 100, 1.0);
    //                 }
    //             }
    //         }
    //     }
    // }

    // Update timer
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (cpuEnabled) cpuProcessComponent.createObject(systemUsageContainer);
            if (memoryEnabled) ramProcessComponent.createObject(systemUsageContainer);
            if (tempEnabled) tempProcessComponent.createObject(systemUsageContainer);
        }
    }

    Rectangle {
        id: bgRect
        color: "#2a2a2a"
        radius: 8
        implicitWidth: child.implicitWidth + 16
        implicitHeight: 32
    }

    RowLayout {
        id: child
        anchors.centerIn: parent
        spacing: 4

        // CPU Section
        Item {
            id: cpuIndicator
            visible: cpuEnabled
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            rotation: !isHorizontal ? 270 : 0

            Canvas {
                id: cpuCanvas
                anchors.fill: parent

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    const cx = width / 2;
                    const cy = height / 2;
                    const r = (width - 2) / 2;
                    const start = -Math.PI / 2;
                    const end = start + 2 * Math.PI * cpuPercent;

                    ctx.lineWidth = 2;
                    ctx.lineCap = "round";

                    // Background ring
                    ctx.strokeStyle = "#3a3a3a";
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                    ctx.stroke();

                    // Progress ring
                    ctx.strokeStyle = "#4a90e2";
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, start, end);
                    ctx.stroke();
                }

                Connections {
                    target: systemUsageContainer
                    function onCpuPercentChanged() {
                        cpuCanvas.requestPaint();
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: ""
                font.pixelSize: 10
                font.bold: true
                color: "#ffffff"
            }
        }

        Text {
            visible: cpuEnabled && isHorizontal
            text: Math.round(cpuPercent * 100) + "%"
            color: "white"
            font.pixelSize: 12
        }

        // Memory Section
        Item {
            id: memoryIndicator
            visible: memoryEnabled
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.leftMargin: 4
            rotation: !isHorizontal ? 270 : 0

            Canvas {
                id: memoryCanvas
                anchors.fill: parent

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    const cx = width / 2;
                    const cy = height / 2;
                    const r = (width - 2) / 2;
                    const start = -Math.PI / 2;
                    const end = start + 2 * Math.PI * ramPercent;

                    ctx.lineWidth = 2;
                    ctx.lineCap = "round";

                    // Background ring
                    ctx.strokeStyle = "#3a3a3a";
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                    ctx.stroke();

                    // Progress ring
                    ctx.strokeStyle = "#50c878";
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, start, end);
                    ctx.stroke();
                }

                Connections {
                    target: systemUsageContainer
                    function onRamPercentChanged() {
                        memoryCanvas.requestPaint();
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: ""
                font.pixelSize: 10
                font.bold: true
                color: "#ffffff"
            }
        }

        Text {
            visible: memoryEnabled && isHorizontal
            text: Math.round(ramPercent * 100) + "%"
            color: "white"
            font.pixelSize: 12
        }

        // Temperature Section
       // Item {
       //     id: tempIndicator
       //     visible: tempEnabled
       //     Layout.preferredWidth: 24
       //     Layout.preferredHeight: 24
       //     Layout.leftMargin: 4
       //     rotation: !isHorizontal ? 270 : 0

       //     Canvas {
       //         id: tempCanvas
       //         anchors.fill: parent

       //         onPaint: {
       //             const ctx = getContext("2d");
       //             ctx.clearRect(0, 0, width, height);

       //             const cx = width / 2;
       //             const cy = height / 2;
       //             const r = (width - 2) / 2;
       //             const start = -Math.PI / 2;
       //             const end = start + 2 * Math.PI * cpuTempPercent;

       //             ctx.lineWidth = 2;
       //             ctx.lineCap = "round";

       //             // Background ring
       //             ctx.strokeStyle = "#3a3a3a";
       //             ctx.beginPath();
       //             ctx.arc(cx, cy, r, 0, 2 * Math.PI);
       //             ctx.stroke();

       //             // Progress ring
       //             ctx.strokeStyle = "#ff6b6b";
       //             ctx.beginPath();
       //             ctx.arc(cx, cy, r, start, end);
       //             ctx.stroke();
       //         }

       //         Connections {
       //             target: systemUsageContainer
       //             function onCpuTempPercentChanged() {
       //                 tempCanvas.requestPaint();
       //             }
       //         }
       //     }

       //     Text {
       //         anchors.centerIn: parent
       //         text: "T"
       //         font.pixelSize: 10
       //         font.bold: true
       //         color: "#ffffff"
       //     }
       // }

        // Text {
        //     visible: tempEnabled && isHorizontal
        //     text: Math.round(cpuTempPercent * 100) + "%"
        //     color: "white"
        //     font.pixelSize: 12
        // }
    }
}
