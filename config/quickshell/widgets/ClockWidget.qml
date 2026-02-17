import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "../utils"

PanelWindow {
    id: root
    implicitWidth: 520
    implicitHeight: 120
    visible: true
    color: "transparent"
    mask: Region { item: container }
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-clock"
    WlrLayershell.exclusiveZone: -1

    property int visibilityCheckCount: 0
    Timer {
        id: persistenceTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!root.visible) {
                root.visibilityCheckCount++
                root.visible = true
                if (root.visibilityCheckCount > 3) root.visibilityCheckCount = 0
            } else {
                root.visibilityCheckCount = 0
            }
        }
    }

    Component.onCompleted: { visible = true }

    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 10
        right: 16
    }

    // Time parts
    property string hourStr: ""
    property string minuteStr: ""
    property string ampm: ""
    property string monthStr: ""
    property string dayNumStr: ""
    property string dayNameStr: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            const days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
            const months = ["JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE",
                            "JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
            const h = now.getHours()
            root.ampm = h >= 12 ? "PM" : "AM"
            const h12 = h % 12 || 12
            root.hourStr = String(h12).padStart(2, '0')
            root.minuteStr = String(now.getMinutes()).padStart(2, '0')
            root.monthStr = months[now.getMonth()]
            root.dayNumStr = String(now.getDate())
            root.dayNameStr = days[now.getDay()]
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: "transparent"

        Row {
            anchors.centerIn: parent
            spacing: 0

            // ── Left: HH : MM ──
            Row {
                id: timeRow
                spacing: 0
                anchors.verticalCenter: parent.verticalCenter

                // Hours
                Text {
                    text: root.hourStr
                    font.pixelSize: 80
                    font.weight: Font.Bold
                    color: ColorManager.fgColor
                    anchors.verticalCenter: parent.verticalCenter
                    style: Text.Raised
                    styleColor: "#000000"
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                // Colon separator in accent color
                Text {
                    text: ":"
                    font.pixelSize: 80
                    font.weight: Font.Bold
                    color: ColorManager.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                    style: Text.Raised
                    styleColor: "#000000"
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                // Minutes
                Text {
                    text: root.minuteStr
                    font.pixelSize: 80
                    font.weight: Font.Bold
                    color: ColorManager.fgColor
                    anchors.verticalCenter: parent.verticalCenter
                    style: Text.Raised
                    styleColor: "#000000"
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                // AM/PM stacked to top-right of time
                Text {
                    text: root.ampm
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    color: ColorManager.fgDimColor
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    leftPadding: 6
                    style: Text.Raised
                    styleColor: "#000000"
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            // ── Vertical divider ──
            Rectangle {
                width: 1
                height: 70
                color: ColorManager.mutedColor
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.6
                anchors.margins: 0
                Component.onCompleted: {
                    // small horizontal margins via x offset
                }
            }

            // ── Right: MONTH / Day number / Day name ──
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                leftPadding: 14

                Text {
                    text: root.monthStr
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                    color: ColorManager.fgColor
                    style: Text.Raised
                    styleColor: "#000000"
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Text {
                    text: root.dayNumStr
                    font.pixelSize: 32
                    font.weight: Font.Bold
                    color: ColorManager.fgColor
                    style: Text.Raised
                    styleColor: "#000000"
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Text {
                    text: root.dayNameStr
                    font.pixelSize: 15
                    font.weight: Font.Normal
                    color: ColorManager.fgDimColor
                    style: Text.Raised
                    styleColor: "#000000"
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }
    }
}
