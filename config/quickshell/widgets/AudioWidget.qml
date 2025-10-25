// widgets/AudioWidget.qml - Enhanced audio control widget with Cava
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root

    implicitWidth: 440
    implicitHeight: 420
    visible: true
    color: "transparent"
    mask: Region { item: container }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-audio"

    anchors {
        bottom: true
        left: true
    }
    margins {
        bottom: 10
        left: 10
    }

    property string primaryColor: ColorManager.primaryColor
    property string accentColor: ColorManager.accentColor
    property string mutedColor: ColorManager.mutedColor
    property string songTitle: ""
    property string artist: ""
    property real position: 0
    property real length: 100
    property bool isPlaying: false
    property var visualizerBars: []

    Component.onCompleted: {
        let bars = []
        for (let i = 0; i < 50; i++) {
            bars.push(0.05)
        }
        root.visualizerBars = bars
    }

    // Cava audio visualizer
    Process {
        id: cavaReader
        command: ["sh", "-c", "cava -p ~/.config/cava/config_widget 2>/dev/null | while IFS= read -r line; do echo \"$line\"; done"]
        running: true
        property int lineCount: 0

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                cavaReader.lineCount++

                const values = data.trim().split(';')
                if (values.length > 0) {
                    let bars = []
                    for (let i = 0; i < 50; i++) {
                        if (i < values.length && values[i] !== '') {
                            const val = parseInt(values[i])
                            if (!isNaN(val)) {
                                const normalized = Math.min(Math.max(val / 100, 0.05), 1.0)
                                bars.push(normalized)
                            } else {
                                bars.push(0.05)
                            }
                        } else {
                            bars.push(0.05)
                        }
                    }
                    root.visualizerBars = bars
                }
            }
        }

        stderr: SplitParser {
            onRead: data => {
                console.log("Audio/Cava stderr:", data)
            }
        }

        onRunningChanged: {
            if (!running) {
                console.log("Audio: Cava stopped (processed " + lineCount + " lines), restarting in 3s...")
                lineCount = 0
                restartCavaTimer.start()
            }
        }
    }

    Timer {
        id: restartCavaTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: {
            console.log("Audio: Restarting cava...")
            cavaReader.running = true
        }
    }

    // Media info reader
    Process {
        id: mediaReader
        command: ["playerctl", "metadata", "--format", "{{title}}|{{artist}}|{{position}}|{{mpris:length}}|{{status}}"]
        running: false
        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                mediaReader.output = data.trim()
            }
        }

        onRunningChanged: {
            if (!running && output) {
                const parts = output.split('|')
                if (parts.length >= 5) {
                    root.songTitle = parts[0] || "Unknown"
                    root.artist = parts[1] || "Unknown Artist"
                    root.position = parseInt(parts[2]) / 1000000 || 0
                    root.length = parseInt(parts[3]) / 1000000 || 100
                    root.isPlaying = parts[4] === "Playing"
                }
                output = ""
            }
        }
    }

    // Playerctl command executor
    Process {
        id: playerctl
        running: false
    }

    // Media info update timer
    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            mediaReader.running = true
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: "transparent"

        Column {
            anchors.fill: parent
            spacing: 0

            // Visualizer section with enhanced styling
            Rectangle {
                width: parent.width
                height: 260
                color: "transparent"

                // Visualizer bars
                Row {
                    width: parent.width - 50
                    height: parent.height - 50
                    spacing: 3
                    anchors.centerIn: parent
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 25

                    Repeater {
                        model: root.visualizerBars

                        Rectangle {
                            width: (parent.width - (49 * parent.spacing)) / 50
                            height: parent.height * modelData
                            anchors.bottom: parent.bottom

                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: root.primaryColor
                                }
                                GradientStop {
                                    position: 0.6
                                    color: root.primaryColor
                                    ColorAnimation on color {
                                        from: root.primaryColor
                                        to: Qt.lighter(root.primaryColor, 1.3)
                                        duration: 1000
                                        running: root.isPlaying
                                        loops: Animation.Infinite
                                    }
                                }
                                GradientStop {
                                    position: 1.0
                                    color: "transparent"
                                }
                            }

                            radius: width / 2
                            opacity: root.isPlaying ? 0.95 : 0.15

                            Behavior on height {
                                NumberAnimation { duration: 50; easing.type: Easing.OutCubic }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: 400 }
                            }
                        }
                    }
                }
            }

            // Song info and controls
            Rectangle {
                width: parent.width
                height: 160
                color: "transparent"

                Column {
                    anchors.fill: parent
                    anchors.topMargin: 10
                    anchors.leftMargin: 30
                    anchors.rightMargin: 30
                    spacing: 20

                    // Song info with icon
                    Row {
                        width: parent.width
                        spacing: 14

                        Column {
                            width: parent.width - 56
                            spacing: 6
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: root.songTitle
                                font.pixelSize: 20
                                font.weight: Font.Bold
                                color: root.accentColor
                                width: parent.width
                                elide: Text.ElideRight

                                Behavior on color {
                                    ColorAnimation { duration: 300 }
                                }
                            }

                            Text {
                                text: root.artist || "Unknown Artist"
                                font.pixelSize: 14
                                color: root.mutedColor
                                width: parent.width
                                elide: Text.ElideRight
                                opacity: 0.7
                                visible: root.artist !== ""
                            }
                        }
                    }

                    // Controls with enhanced styling
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16

                        Repeater {
                            model: [
                                { icon: "⏮", cmd: "previous", size: 48 },
                                { icon: root.isPlaying ? "⏸" : "▶", cmd: "play-pause", size: 64 },
                                { icon: "⏭", cmd: "next", size: 48 }
                            ]

                            Rectangle {
                                width: modelData.size
                                height: width
                                color: mouseArea.pressed ? Qt.darker(root.primaryColor, 1.1) :
                                       mouseArea.containsMouse ? root.primaryColor : "transparent"
                                radius: width / 2
                                opacity: mouseArea.containsMouse || mouseArea.pressed ? 1.0 :
                                         (index === 1 ? 0.2 : 0.12)

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }

                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }

                                // Pulsing border for play button
                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    radius: parent.radius
                                    border.color: root.primaryColor
                                    border.width: index === 1 ? 2 : 0
                                    opacity: index === 1 ? 0.5 : 0

                                    SequentialAnimation on opacity {
                                        running: root.isPlaying && index === 1
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.3; duration: 1500; easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 0.5; duration: 1500; easing.type: Easing.InOutQuad }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.pixelSize: index === 1 ? 30 : 22
                                    color: mouseArea.containsMouse || mouseArea.pressed ? "#0a0a0a" : root.primaryColor

                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                }

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        console.log("Audio: Executing playerctl", modelData.cmd)
                                        playerctl.command = ["playerctl", modelData.cmd]
                                        playerctl.running = true
                                    }
                                }

                                // Scale on press
                                scale: mouseArea.pressed ? 0.95 : 1.0
                                Behavior on scale {
                                    NumberAnimation { duration: 100 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
