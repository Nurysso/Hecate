import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    Layout.preferredHeight: theme.barHeight - 8
    Layout.preferredWidth: statsLayout.implicitWidth + theme.padding * 2

    radius: theme.radiusSmall
    color: theme.bgLight

    property string activePanel: "" // "cpu", "memory", "volume", or ""

    RowLayout {
        id: statsLayout
        anchors.centerIn: parent
        spacing: theme.spacing

        // CPU
        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: cpuLayout.implicitWidth + 12
            radius: theme.radiusSmall
            color: activePanel === "cpu" ? theme.yellow : "transparent"
            opacity: activePanel === "cpu" ? 0.2 : 1.0

            RowLayout {
                id: cpuLayout
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: theme.iconCpu
                    color: theme.yellow
                    font.pixelSize: theme.iconSize
                    font.family: theme.fontFamily
                }
                Text {
                    text: (SystemStats.cpuUsage || 0) + "%"
                    color: theme.fg
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = activePanel === "cpu" ? 0.2 : 1.0
                onClicked: activePanel = activePanel === "cpu" ? "" : "cpu"
            }
        }

        Rectangle { width: 1; height: 14; color: theme.muted; opacity: 0.5 }

        // Memory
        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: memLayout.implicitWidth + 12
            radius: theme.radiusSmall
            color: activePanel === "memory" ? theme.cyan : "transparent"
            opacity: activePanel === "memory" ? 0.2 : 1.0

            RowLayout {
                id: memLayout
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: theme.iconMemory
                    color: theme.cyan
                    font.pixelSize: theme.iconSize
                    font.family: theme.fontFamily
                }
                Text {
                    text: (SystemStats.memUsage || 0) + "%"
                    color: theme.fg
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = activePanel === "memory" ? 0.2 : 1.0
                onClicked: activePanel = activePanel === "memory" ? "" : "memory"
            }
        }

        Rectangle { width: 1; height: 14; color: theme.muted; opacity: 0.5 }

        // Volume
        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: volLayout.implicitWidth + 12
            radius: theme.radiusSmall
            color: activePanel === "volume" ? theme.green : "transparent"
            opacity: activePanel === "volume" ? 0.2 : 1.0

            RowLayout {
                id: volLayout
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: (SystemStats.volumeMuted || false) ? theme.iconVolumeMute : theme.iconVolume
                    color: (SystemStats.volumeMuted || false) ? theme.red : theme.green
                    font.pixelSize: theme.iconSize
                    font.family: theme.fontFamily
                }
                Text {
                    text: (SystemStats.volumeLevel || 0) + "%"
                    color: theme.fg
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = activePanel === "volume" ? 0.2 : 1.0
                onClicked: activePanel = activePanel === "volume" ? "" : "volume"
            }
        }
    }

    // CPU Details Panel
    Rectangle {
        visible: activePanel === "cpu"
        width: 280
        height: cpuDetails.implicitHeight + theme.padding * 2

        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.right: parent.right

        radius: theme.radius
        color: theme.bgDark
        border.width: 1
        border.color: theme.yellow

        ColumnLayout {
            id: cpuDetails
            anchors.fill: parent
            anchors.margins: theme.padding
            spacing: theme.spacing

            Text {
                text: theme.iconCpu + " CPU Information"
                color: theme.yellow
                font.pixelSize: theme.fontSize
                font.family: theme.fontFamily
                font.bold: true
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: theme.muted }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Usage:"
                    color: theme.fgDark
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                    Layout.preferredWidth: 100
                }
                Text {
                    text: (SystemStats.cpuUsage || 0) + "%"
                    color: theme.fg
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                    font.bold: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Kernel:"
                    color: theme.fgDark
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                    Layout.preferredWidth: 100
                }
                Text {
                    text: SystemStats.kernelVersion || "Unknown"
                    color: theme.fg
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 20
                radius: 3
                color: theme.muted
                Rectangle {
                    width: parent.width * ((SystemStats.cpuUsage || 0) / 100)
                    height: parent.height
                    radius: parent.radius
                    color: theme.yellow
                }
            }
        }
    }

    // Memory Details Panel
    Rectangle {
        visible: activePanel === "memory"
        width: 280
        height: memDetails.implicitHeight + theme.padding * 2

        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.right: parent.right

        radius: theme.radius
        color: theme.bgDark
        border.width: 1
        border.color: theme.cyan

        ColumnLayout {
            id: memDetails
            anchors.fill: parent
            anchors.margins: theme.padding
            spacing: theme.spacing

            Text {
                text: theme.iconMemory + " Memory Information"
                color: theme.cyan
                font.pixelSize: theme.fontSize
                font.family: theme.fontFamily
                font.bold: true
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: theme.muted }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Usage:"
                    color: theme.fgDark
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                    Layout.preferredWidth: 100
                }
                Text {
                    text: (SystemStats.memUsage || 0) + "%"
                    color: theme.fg
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                    font.bold: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Status:"
                    color: theme.fgDark
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                    Layout.preferredWidth: 100
                }
                Text {
                    text: (SystemStats.memUsage || 0) > 80 ? "High" : (SystemStats.memUsage || 0) > 50 ? "Normal" : "Low"
                    color: (SystemStats.memUsage || 0) > 80 ? theme.red : theme.green
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                    font.bold: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 20
                radius: 3
                color: theme.muted
                Rectangle {
                    width: parent.width * ((SystemStats.memUsage || 0) / 100)
                    height: parent.height
                    radius: parent.radius
                    color: theme.cyan
                }
            }
        }
    }

    // Volume Control Panel
    Rectangle {
        visible: activePanel === "volume"
        width: 280
        height: volDetails.implicitHeight + theme.padding * 2

        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.right: parent.right

        radius: theme.radius
        color: theme.bgDark
        border.width: 1
        border.color: theme.green

        ColumnLayout {
            id: volDetails
            anchors.fill: parent
            anchors.margins: theme.padding
            spacing: theme.spacing

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: theme.iconVolume + " Volume Control"
                    color: theme.green
                    font.pixelSize: theme.fontSize
                    font.family: theme.fontFamily
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: (SystemStats.volumeLevel || 0) + "%"
                    color: theme.fg
                    font.pixelSize: theme.fontSize
                    font.family: theme.fontFamily
                    font.bold: true
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: theme.muted }

            // Volume slider
            Rectangle {
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: theme.muted

                Rectangle {
                    width: parent.width * ((SystemStats.volumeLevel || 0) / 100)
                    height: parent.height
                    radius: parent.radius
                    color: theme.green
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        var percent = Math.max(0, Math.min(100, Math.round(100 * mouse.x / width)))
                        setVolume(percent)
                    }
                }
            }

            // Volume preset buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: theme.spacingSmall

                Repeater {
                    model: [
                        { label: "Mute", value: -1 },
                        { label: "25%", value: 25 },
                        { label: "50%", value: 50 },
                        { label: "75%", value: 75 },
                        { label: "100%", value: 100 }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: theme.radiusSmall
                        color: theme.bgLight
                        border.width: 1
                        border.color: theme.muted

                        Text {
                            text: modelData.label
                            color: theme.fg
                            font.pixelSize: theme.fontSize - 2
                            font.family: theme.fontFamily
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: parent.color = Qt.lighter(theme.bgLight, 1.2)
                            onExited: parent.color = theme.bgLight
                            onClicked: {
                                if (modelData.value === -1) {
                                    toggleMute()
                                } else {
                                    setVolume(modelData.value)
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Status:"
                    color: theme.fgDark
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                }
                Text {
                    text: (SystemStats.volumeMuted || false) ? "Muted" : "Active"
                    color: (SystemStats.volumeMuted || false) ? theme.red : theme.green
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                    font.bold: true
                }
            }
        }
    }

    // Click outside to close panel
    MouseArea {
        enabled: activePanel !== ""
        parent: root.parent
        anchors.fill: parent
        onClicked: activePanel = ""
        z: -1
    }

    // Helper functions
    function setVolume(percent) {
        var decimal = (percent / 100).toFixed(2)
        var proc = Qt.createQmlObject('
            import Quickshell.Io;
            import QtQuick;
            Process {
                command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "' + decimal + '"]
                running: true
            }
        ', root)
    }

    function toggleMute() {
        var proc = Qt.createQmlObject('
            import Quickshell.Io;
            import QtQuick;
            Process {
                command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
                running: true
            }
        ', root)
    }
}
