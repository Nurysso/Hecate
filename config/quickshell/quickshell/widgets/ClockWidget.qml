import Quickshell
import Quickshell.Wayland
import QtQuick
import "../utils"

PanelWindow {
    id: root

    implicitWidth:  420
    implicitHeight: 160
    visible: true
    color: "transparent"
    mask: Region { item: content }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-clock"
    WlrLayershell.exclusiveZone: -1

    anchors { bottom: true; right: true }
    margins { bottom: 14; right: 18 }

    // State
    property int    h12:       0
    property int    hFull:     0
    property int    minVal:    0
    property int    secVal:    0
    property string ampm:      "AM"
    property int    dayOfMonth: 1
    property string dayName:   ""
    property string monthName: ""
    property int    yearVal:   2025

    readonly property var dAYS:
        ["SUN","MON","TUE","WED","THU","FRI","SAT"]
    readonly property var mONTHS:
        ["JAN","FEB","MAR","APR","MAY","JUN",
         "JUL","AUG","SEP","OCT","NOV","DEC"]

    function refresh() {
        const now = new Date()
        hFull      = now.getHours()
        h12        = hFull % 12 || 12
        minVal     = now.getMinutes()
        // secVal     = now.getSeconds()
        ampm       = hFull >= 12 ? "PM" : "AM"
        dayOfMonth = now.getDate()
        dayName    = dAYS[now.getDay()]
        monthName  = mONTHS[now.getMonth()]
        yearVal    = now.getFullYear()
    }

    Timer {
        interval: 1000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Root item
    Item {
        readonly property real rv: Reveal.fade(0, 220)   // delay, span
        opacity: rv
        transform: Translate { y: (1 - rv) * 14 }
        id: content
        anchors.fill: parent

        // Left: concentric arc clock
        Item {
            id: arcClock
            width: 160; height: 160
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            ArcRing {
                anchors.fill: parent
                radius: 72
                progress: root.h12 / 12
                trackColor:  Qt.rgba(1,1,1,0.07)
                fillColor:   ColorManager.accentColor
                strokeWidth: 5
            }
            ArcRing {
                anchors.fill: parent
                radius: 58
                progress: root.minVal / 60
                trackColor:  Qt.rgba(1,1,1,0.07)
                fillColor: ColorManager.accentColor
                // fillColor:   Qt.rgba(ColorManager.accent.r,
                //                     ColorManager.accent.g,
                //                     ColorManager.accent.b, 0.55)
                strokeWidth: 4
            }
            //ArcRing {
            //    anchors.fill: parent
            //    radius: 45
            //    progress: root.secVal / 60
            //   trackColor:  Qt.rgba(1,1,1,0.05)
            //    fillColor:   Qt.rgba(ColorManager.accent.r,
            //                         ColorManager.accent.g,
            //                          ColorManager.accent.b, 0.30)
            //     strokeWidth: 2
            //}

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: String(root.h12).padStart(2,'0') + ":" +
                          String(root.minVal).padStart(2,'0')
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    font.family: "monospace"
                    color: ColorManager.fgColor
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.ampm
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    font.family: "monospace"
                    color: ColorManager.accentColor
                    opacity: 0.75
                }
            }
        }

        // Vertical separator
        Rectangle {
            width: 1; height: 80
            color: ColorManager.mutedColor
            opacity: 0.2
            anchors.left: arcClock.right
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
        }

        // Right: date block
        Item {
            anchors.left: arcClock.right
            anchors.leftMargin: 38
            anchors.verticalCenter: parent.verticalCenter
            width: 200
            height: 130

            // Big day-of-month number
            Text {
                id: dayNumText
                text: String(root.dayOfMonth).padStart(2,'0')
                font.pixelSize: 56
                font.weight: Font.Bold
                font.family: "monospace"
                color: ColorManager.fgColor
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 14
            }

            // Day / Month / Year stacked beside number
            Column {
                anchors.left: dayNumText.right
                anchors.leftMargin: 12
                anchors.top: parent.top
                anchors.topMargin: 20
                spacing: 3

                Text {
                    text: root.dayName
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    font.family: "monospace"
                    color: ColorManager.fgColor
                }
                Text {
                    text: root.monthName
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    font.letterSpacing: 1.5
                    font.family: "monospace"
                    color: ColorManager.fgDimColor
                }
                Text {
                    text: root.yearVal
                    font.pixelSize: 10
                    font.family: "monospace"
                    color: ColorManager.mutedColor
                    opacity: 0.6
                }
            }

            // Progress bars (hour + minute)
            Column {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                spacing: 7
                width: 130

                ProgressBar {
                    barWidth: 120
                    label: "HR"
                    progress: root.h12 / 12
                    barColor: ColorManager.accentColor
                }
                ProgressBar {
                    barWidth: 120
                    label: "MIN"
                    progress: root.minVal / 60
                    barColor: ColorManager.accentColor
                    //barColor: Qt.rgba(ColorManager.accent.r,
                    //                  ColorManager.accent.g,
                                    //  ColorManager.accent.b, 0.55)
                }
            }
        }
    }

    // ArcRing component
    component ArcRing: Item {
        property real  radius:      60
        property real  progress:    0.5
        property color trackColor:  Qt.rgba(1,1,1,0.07)
        property color fillColor:   "white"
        property real  strokeWidth: 4

        Canvas {
            anchors.fill: parent
            property real  prog: parent.progress
            property color fc:   parent.fillColor
            property color tc:   parent.trackColor
            property real  sw:   parent.strokeWidth
            property real  r:    parent.radius

            onProgChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                const cx = width / 2, cy = height / 2
                const start = -Math.PI / 2
                ctx.lineWidth = sw
                ctx.lineCap   = "round"
                ctx.strokeStyle = tc.toString()
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                ctx.stroke()
                if (prog > 0) {
                    ctx.strokeStyle = fc.toString()
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, start, start + 2 * Math.PI * Math.min(prog, 1.0))
                    ctx.stroke()
                }
            }
        }
    }

    // ProgressBar component
    component ProgressBar: Item {
        property real   progress: 0
        property real   barWidth: 100
        property string label:    ""
        property color  barColor: "white"

        implicitWidth:  barWidth + 32
        implicitHeight: 3

        Rectangle {
            width: barWidth; height: 3; radius: 2
            color: Qt.rgba(1,1,1,0.07)
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            width: barWidth * Math.min(parent.progress, 1.0)
            height: 3; radius: 2
            color: parent.barColor
            anchors.verticalCenter: parent.verticalCenter
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: barWidth + 8
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            font.pixelSize: 9
            font.family: "monospace"
            font.letterSpacing: 0.5
            color: ColorManager.mutedColor
            opacity: 0.5
        }
    }
}
