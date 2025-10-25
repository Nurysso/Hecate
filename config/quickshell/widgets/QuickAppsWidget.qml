// widgets/QuickAppsWidget.qml - Enhanced quick apps launcher
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "."

PanelWindow {
    id: root

    implicitWidth: 260
    implicitHeight: Math.max(70, contentHeight)
    visible: true
    color: "transparent"
    mask: Region { item: container }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-apps"

    anchors {
        top: true
        right: true
    }
    margins {
        top: 280
        right: 20
    }

    property string primaryColor: ColorManager.primaryColor
    property string accentColor: ColorManager.accentColor
    property string mutedColor: ColorManager.mutedColor
    property var appsList: []
    property int contentHeight: appsList.length * 56 + 40
    property string appsContent: ""

    // Apps config loader
    Process {
        id: appsReader
        command: ["cat", `${Quickshell.env("HOME")}/.config/hecate/quickapps.conf`]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (appsContent) appsContent += "\n" + data
                else appsContent = data
            }
        }

        onRunningChanged: {
            if (!running && appsContent) {
                const content = appsContent.trim()
                let lines = content.split('\n')

                // Handle single-line files
                if (lines.length === 1 && lines[0].length > 50) {
                    lines = []
                    const regex = /([A-Za-z0-9]+)=([a-z\-]+)/g
                    let match
                    while ((match = regex.exec(content)) !== null) {
                        if (match[1] && match[2]) {
                            lines.push(match[1] + "=" + match[2])
                        }
                    }
                }

                let newAppsList = []
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim()
                    if (!line || line.startsWith('#')) continue

                    const equalIndex = line.indexOf('=')
                    if (equalIndex > 0) {
                        const name = line.substring(0, equalIndex).trim()
                        const command = line.substring(equalIndex + 1).trim()
                        if (name && command) {
                            newAppsList.push({ name: name, command: command })
                        }
                    }
                }

                appsList = newAppsList
                contentHeight = Math.max(70, newAppsList.length * 56 + 40)
                appsContent = ""
            }
        }
    }

    // App launcher
    Process {
        id: launcher
        running: false
    }

    // Reload timer
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            appsReader.running = true
        }
    }

    Item {
        id: container
        anchors.fill: parent

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 6

            Repeater {
                model: root.appsList

                Item {
                    width: parent.width
                    height: 50

                    Rectangle {
                        id: appButton
                        anchors.fill: parent
                        color: "transparent"
                        radius: 12

                        // Subtle background on hover
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: root.primaryColor
                            opacity: mouseArea.containsMouse ? 0.70 : 0.0

                            Behavior on opacity {
                                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                            }
                        }

                        // Active/pressed state
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: root.accentColor
                            opacity: mouseArea.pressed ? 0.25 : 0.0

                            Behavior on opacity {
                                NumberAnimation { duration: 100 }
                            }
                        }

                        // Left accent border
//                        Rectangle {
//                            width: 3
//                            height: parent.height - 12
//                            anchors.left: parent.left
//                            anchors.leftMargin: 6
//                            anchors.verticalCenter: parent.verticalCenter
//                            radius: 2
//                            color: root.accentColor
//                            opacity: mouseArea.containsMouse ? 1.0 : 0.0
//
//                            Behavior on opacity {
//                                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
//                            }
//                    }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 14
                            spacing: 12

                            // App name
                            Text {
                                text: modelData.name
                               font.pixelSize: mouseArea.containsMouse ? 19 : 18
                                font.weight: mouseArea.containsMouse ? Font.DemiBold : Font.Normal
                                font.letterSpacing: 0.3
                                color: mouseArea.containsMouse ? "#0a0a0a" : root.accentColor
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: mouseArea.containsMouse ? 1.0 : 0.3
                                Behavior on opacity {
                                    NumberAnimation { duration: 200 }
                                }

                                Behavior on font.weight {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                            // Subtle arrow indicator
                            Text {
                                text: "→"
                                font.pixelSize: 16
                                color: mouseArea.containsMouse ? "#0a0a0a" : root.accentColor
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: mouseArea.containsMouse ? 1 : 0.0

                                transform: Translate {
                                    x: mouseArea.containsMouse ? 0 : -8
                                    Behavior on x {
                                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation { duration: 200 }
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                launcher.command = ["sh", "-c", modelData.command]
                                launcher.running = true
                            }
                        }

                        // Subtle scale on press
                        scale: mouseArea.pressed ? 0.97 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }

                    // Separator line between items (except last)
   //                 Rectangle {
   //                     visible: index < root.appsList.length - 1
   //                     width: parent.width - 32
   //                     height: 1
   //                     anchors.bottom: parent.bottom
   //                     anchors.horizontalCenter: parent.horizontalCenter
   //                     color: root.mutedColor
   //                     opacity: mouseArea.containsMouse ? 1.0 : 0.3
   //                 }
                }
            }
        }

        // Subtle container hint - appears on any hover
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: 14
            color: root.primaryColor
            border.width: 1
            opacity: {
                for (let i = 0; i < appsRepeater.count; i++) {
                    let item = appsRepeater.itemAt(i)
                    if (item && item.children[0].children[4].containsMouse) {
                        return 0.15
                    }
                }
                return 0.0
            }

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }
    }

    // Reference to repeater for border logic
    property var appsRepeater: container.children[0].children[0]
}
