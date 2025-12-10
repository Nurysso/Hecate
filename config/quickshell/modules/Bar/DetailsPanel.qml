import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: detailsPanel
    anchors.fill: parent

    property string activePanelType: ""
    property var pillParent: null

    // CPU Panel
    Rectangle {
        visible: activePanelType === "cpu"
        width: 280
        height: cpuContent.implicitHeight + theme.padding * 2

        x: pillParent ? pillParent.mapToItem(detailsPanel.parent, 0, 0).x + pillParent.width - width : 0
        y: pillParent ? pillParent.mapToItem(detailsPanel.parent, 0, 0).y + pillParent.height + 4 : 0

        radius: theme.radius
        color: theme.bgDark
        border.width: 1
        border.color: theme.yellow
        z: 1000

        ColumnLayout {
            id: cpuContent
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
                    text: (systemStats.cpuUsage || 0) + "%"
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
                    text: systemStats.kernelVersion || "Unknown"
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
                    width: parent.width * ((systemStats.cpuUsage || 0) / 100)
                    height: parent.height
                    radius: parent.radius
                    color: theme.yellow
                }
            }
        }
    }

    // Memory Panel
    Rectangle {
        visible: activePanelType === "memory"
        width: 280
        height: memContent.implicitHeight + theme.padding * 2

        x: pillParent ? pillParent.mapToItem(detailsPanel.parent, 0, 0).x + pillParent.width - width : 0
        y: pillParent ? pillParent.mapToItem(detailsPanel.parent, 0, 0).y + pillParent.height + 4 : 0

        radius: theme.radius
        color: theme.bgDark
        border.width: 1
        border.color: theme.cyan
        z: 1000

        ColumnLayout {
            id: memContent
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
                    text: (systemStats.memUsage || 0) + "%"
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
                    text: (systemStats.memUsage || 0) > 80 ? "High" : (systemStats.memUsage || 0) > 50 ? "Normal" : "Low"
                    color: (systemStats.memUsage || 0) > 80 ? theme.red : theme.green
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
                    width: parent.width * ((systemStats.memUsage || 0) / 100)
                    height: parent.height
                    radius: parent.radius
                    color: theme.cyan
                }
            }
        }
    }

    // Disk Panel
    Rectangle {
        visible: activePanelType === "disk"
        width: 280
        height: diskContent.implicitHeight + theme.padding * 2

        x: pillParent ? pillParent.mapToItem(detailsPanel.parent, 0, 0).x + pillParent.width - width : 0
        y: pillParent ? pillParent.mapToItem(detailsPanel.parent, 0, 0).y + pillParent.height + 4 : 0

        radius: theme.radius
        color: theme.bgDark
        border.width: 1
        border.color: theme.blue
        z: 1000

        ColumnLayout {
            id: diskContent
            anchors.fill: parent
            anchors.margins: theme.padding
            spacing: theme.spacing

            Text {
                text: theme.iconDisk + " Disk Information"
                color: theme.blue
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
                    text: (systemStats.diskUsage || 0) + "%"
                    color: theme.fg
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                    font.bold: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Mount:"
                    color: theme.fgDark
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                    Layout.preferredWidth: 100
                }
                Text {
                    text: "/"
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
                    width: parent.width * ((systemStats.diskUsage || 0) / 100)
                    height: parent.height
                    radius: parent.radius
                    color: theme.blue
                }
            }
        }
    }

    // Volume Panel
    Rectangle {
        visible: activePanelType === "volume"
        width: 280
        height: volContent.implicitHeight + theme.padding * 2

        x: pillParent ? pillParent.mapToItem(detailsPanel.parent, 0, 0).x + pillParent.width - width : 0
        y: pillParent ? pillParent.mapToItem(detailsPanel.parent, 0, 0).y + pillParent.height + 4 : 0

        radius: theme.radius
        color: theme.bgDark
        border.width: 1
        border.color: theme.purple
        z: 1000

        ColumnLayout {
            id: volContent
            anchors.fill: parent
            anchors.margins: theme.padding
            spacing: theme.spacing

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: theme.iconVolume + " Volume Control"
                    color: theme.purple
                    font.pixelSize: theme.fontSize
                    font.family: theme.fontFamily
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: (systemStats.volumeLevel || 0) + "%"
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
                    width: parent.width * ((systemStats.volumeLevel || 0) / 100)
                    height: parent.height
                    radius: parent.radius
                    color: theme.purple
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
                    text: (systemStats.volumeMuted || false) ? "Muted" : "Active"
                    color: (systemStats.volumeMuted || false) ? theme.red : theme.green
                    font.pixelSize: theme.fontSize - 1
                    font.family: theme.fontFamily
                    font.bold: true
                }
            }
        }
    }

    // Click outside to close
    MouseArea {
        enabled: activePanelType !== ""
        anchors.fill: parent
        onClicked: activePanelType = ""
        z: 999
    }

    // Helper functions
    function setVolume(percent) {
        var decimal = (percent / 100).toFixed(2)
        Qt.createQmlObject('
            import Quickshell.Io;
            import QtQuick;
            Process {
                command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "' + decimal + '"]
                running: true
            }
        ', detailsPanel)
    }

    function toggleMute() {
        Qt.createQmlObject('
            import Quickshell.Io;
            import QtQuick;
            Process {
                command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
                running: true
            }
        ', detailsPanel)
    }
}
