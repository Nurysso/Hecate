// widgets/ClockWidget.qml - Enhanced clock widget (fixed)
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "."

PanelWindow {
    id: root

    implicitWidth: 420
    implicitHeight: 220
    visible: true
    color: "transparent"
    mask: Region { item: container }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-clock"

    anchors {
        top: true
        right: true
    }
    margins {
        top: 20
        right: 20
    }

    property string currentDay: ""
    property string currentTime: ""
    property string currentDate: ""
    property string primaryColor: ColorManager.primaryColor
    property string accentColor: ColorManager.accentColor
    property string mutedColor: ColorManager.mutedColor

    // Clock update timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            const now = new Date()
            const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            const months = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]

            root.currentDay = days[now.getDay()]
            root.currentTime = String(now.getHours()).padStart(2, '0') + ":" +
                         String(now.getMinutes()).padStart(2, '0') + ":" +
                         String(now.getSeconds()).padStart(2, '0')
            root.currentDate = months[now.getMonth()] + " " + now.getDate() + ", " + now.getFullYear()
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: "transparent"
        opacity: 1

        Column {
            anchors.centerIn: parent
            spacing: 20

            // Day
            Text {
                text: root.currentDay
                font.pixelSize: 32
                font.weight: Font.Bold
                font.letterSpacing: 2
                color: root.mutedColor
                anchors.horizontalCenter: parent.horizontalCenter

                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
            }

            // Time
            Text {
                text: root.currentTime
                font.pixelSize: 68
                font.weight: Font.Bold
                font.family: "monospace"
                color: root.primaryColor
                anchors.horizontalCenter: parent.horizontalCenter

                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
            }

            // Date
            Text {
                text: root.currentDate
                font.pixelSize: 24
                font.weight: Font.Medium
                font.letterSpacing: 1
                color: root.accentColor
                anchors.horizontalCenter: parent.horizontalCenter

                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
            }
        }
    }
}
