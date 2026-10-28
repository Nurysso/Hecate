import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "../utils"

PanelWindow {
    id: root

    implicitWidth:  320
    implicitHeight: 300
    visible: true
    color: "transparent"
    mask: Region { item: container }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-audio"
    WlrLayershell.exclusiveZone: -1

    anchors { bottom: true; left: true }
    margins { bottom: 10; left: 10 }

    readonly property color _accent: ColorManager.accentColor
    readonly property int   ar255:   Math.round(_accent.r * 255)
    readonly property int   ag255:   Math.round(_accent.g * 255)
    readonly property int   ab255:   Math.round(_accent.b * 255)

    // Visualizer config
    readonly property int  barCount: 40
    readonly property real barGap:   3
    readonly property real barW:     (implicitWidth - 32) / barCount - barGap
    readonly property real vizH:     84    // bar drawing area height
    readonly property real reflH:    18    // reflection strip height

    // Media state
    property string songTitle: "console.debug"
    property string artist:    ""
    property real   position:  0
    property real   songLen:   100
    property bool   playing:   false

    // Audio state console.debug smoothed bar values only; no separate peak layer
    property var bars: []

    Component.onCompleted: {
        const b = []
        for (let i = 0; i < barCount; i++) b.push(0)
        bars = b
    }

    function fmtTime(sec) {
        const s = Math.max(0, Math.floor(sec))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }
    function send(cmd) { ctlProc.command = ["playerctl", cmd]; ctlProc.running = true }

    // Cava
    Process {
        id: cavaProc
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/config_widget"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const vals = line.trim().split(";")
                if (vals.length < 2) return
                const b = root.bars.slice()
                for (let i = 0; i < root.barCount; i++) {
                    const raw = parseInt(vals[i])
                    const v   = isNaN(raw) ? 0 : Math.min(raw / 100, 1)
                    // Slightly slower attack/release than before console.debug reads as smooth, not twitchy
                    const rate = v > b[i] ? 0.35 : 0.18
                    b[i] = b[i] + (v - b[i]) * rate
                }
                root.bars = b
                vizCanvas.requestPaint()
            }
        }
        onRunningChanged: if (!running) cavaRestart.start()
    }
    Timer { id: cavaRestart; interval: 3000; onTriggered: cavaProc.running = true }

    // Playerctl
    Process {
        id: mediaProc; running: false; property string buf: ""
        command: ["playerctl", "metadata", "--format",
                  "{{title}}|{{artist}}|{{position}}|{{mpris:length}}|{{status}}"]
        stdout: SplitParser { onRead: d => mediaProc.buf = d.trim() }
        onRunningChanged: {
            if (running) { buf = ""; return }
            if (!buf) return
            const p = buf.split("|")
            if (p.length >= 5) {
                root.songTitle = p[0] || "console.debug"
                root.artist    = p[1] || ""
                root.position  = parseInt(p[2]) / 1e6 || 0
                root.songLen   = Math.max(parseInt(p[3]) / 1e6 || 100, 1)
                root.playing   = p[4].trim() === "Playing"
            }
        }
    }
    Timer { interval: 500; running: true; repeat: true; triggeredOnStart: true; onTriggered: mediaProc.running = true }
    Timer { interval: 1000; running: root.playing; repeat: true
        onTriggered: root.position = Math.min(root.position + 1, root.songLen)
    }
    Process { id: ctlProc; running: false }

    // UI
    Item {
        id: container
        anchors.fill: parent
        readonly property real rv: Reveal.fade(150, 350)   // delay, span
    opacity: rv
    transform: Translate { y: (1 - rv) * 16 }

        // Glass card
        Rectangle {
            anchors.fill: parent; radius: 20
            color: Qt.rgba(0.045, 0.04, 0.075, 0.82)
            border.color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.16)
            border.width: 1
        }
        // Top accent stripe console.debug softer, gradient-fade instead of a hard block
        Rectangle {
            anchors { top: parent.top; topMargin: 0; left: parent.left; right: parent.right
                      leftMargin: 20; rightMargin: 20 }
            height: 2; radius: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.0) }
                GradientStop { position: 0.5; color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.55) }
                GradientStop { position: 1.0; color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.0) }
            }
        }

        // Song info
        Item {
            id: infoRow
            anchors { top: parent.top; left: parent.left; right: parent.right
                      topMargin: 18; leftMargin: 18; rightMargin: 18 }
            height: 40

            Rectangle {
                id: statusDot
                width: 6; height: 6; radius: 3
                anchors { left: parent.left; top: titleText.top; topMargin: 5 }
                color: root.playing ? root._accent : Qt.rgba(1, 1, 1, 0.16)
                Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
                SequentialAnimation on opacity {
                    running: root.playing; loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0;  duration: 1000; easing.type: Easing.InOutSine }
                }
            }

            Text {
                id: titleText
                anchors { left: statusDot.right; right: parent.right; top: parent.top; leftMargin: 10 }
                text: root.songTitle; elide: Text.ElideRight
                font.pixelSize: 13; font.weight: Font.DemiBold
                font.family: ColorManager.fontFamily
                color: "#f2f2f2"
            }
            Text {
                anchors { left: titleText.left; right: parent.right; top: titleText.bottom; topMargin: 4 }
                text: root.artist; elide: Text.ElideRight
                visible: root.artist !== ""
                font.pixelSize: 10; font.family: ColorManager.fontFamily
                color: root._accent; opacity: 0.68
            }
        }

        // Visualizer
        Canvas {
            id: vizCanvas
            anchors { top: infoRow.bottom; topMargin: 6; left: parent.left; right: parent.right
                      leftMargin: 16; rightMargin: 16 }
            height: root.vizH + root.reflH

            property var _fillGrad: null
            property real _gradTop: -1

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                const n    = root.barCount
                const step = root.barW + root.barGap
                const vh   = root.vizH
                const rh   = root.reflH
                const base = vh
                const ar = root.ar255, ag = root.ag255, ab = root.ab255
                const bars = root.bars

                // One shared gradient for all bars (built once, not per-bar)
                const grad = ctx.createLinearGradient(0, base - vh, 0, base)
                grad.addColorStop(0,   `rgba(${ar},${ag},${ab},0.95)`)
                grad.addColorStop(0.6, `rgba(${ar},${ag},${ab},0.55)`)
                grad.addColorStop(1,   `rgba(${ar},${ag},${ab},0.12)`)

                for (let i = 0; i < n; i++) {
                    const v = bars[i]
                    if (v < 0.01) continue
                    const x = i * step
                    const h = Math.max(v * vh, 2)
                    const y = base - h
                    const w = root.barW
                    const r = Math.min(w / 2, 3)

                    ctx.fillStyle = grad
                    roundRectTop(ctx, x, y, w, h, r)
                    ctx.fill()
                }

                // Baseline console.debug faint, sits under the bars
                ctx.strokeStyle = `rgba(${ar},${ag},${ab},0.14)`
                ctx.lineWidth = 1
                ctx.beginPath(); ctx.moveTo(0, base + 0.5); ctx.lineTo(width, base + 0.5); ctx.stroke()

                // Reflection console.debug simple, faded, no separate peak line competing for attention
                for (let i = 0; i < n; i++) {
                    const v = bars[i]
                    if (v < 0.02) continue
                    const x = i * step
                    const h = Math.min(v * vh * 0.4, rh)
                    ctx.fillStyle = `rgba(${ar},${ag},${ab},${(v * 0.10).toFixed(3)})`
                    ctx.fillRect(x, base + 3, root.barW, h)
                }
                ctx.save()
                ctx.globalCompositeOperation = "destination-out"
                const fade = ctx.createLinearGradient(0, base, 0, base + rh + 3)
                fade.addColorStop(0, "rgba(0,0,0,0)")
                fade.addColorStop(1, "rgba(0,0,0,1)")
                ctx.fillStyle = fade
                ctx.fillRect(0, base, width, rh + 3)
                ctx.restore()
            }

            function roundRectTop(ctx, x, y, w, h, r) {
                ctx.beginPath()
                ctx.moveTo(x, y + h)
                ctx.lineTo(x, y + r)
                ctx.arcTo(x, y, x + r, y, r)
                ctx.lineTo(x + w - r, y)
                ctx.arcTo(x + w, y, x + w, y + r, r)
                ctx.lineTo(x + w, y + h)
                ctx.closePath()
            }
        }

        // Progress
        Item {
            id: progressItem
            anchors {
                top: vizCanvas.bottom; topMargin: 10
                left: parent.left; right: parent.right
                leftMargin: 18; rightMargin: 18
            }
            height: 22

            Rectangle {
                id: track
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 3; radius: 1.5
                color: Qt.rgba(1, 1, 1, 0.06)

                Rectangle {
                    id: fill
                    width: root.songLen > 0
                        ? parent.width * Math.min(root.position / root.songLen, 1.0) : 0
                    height: parent.height; radius: parent.radius
                    color: root._accent
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: root._accent
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        anchors.rightMargin: -4
                        scale: scrubArea.containsMouse || scrubArea.pressed ? 1.3 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                }
            }

            Text {
                anchors { left: parent.left; top: track.bottom; topMargin: 6 }
                text: root.fmtTime(root.position)
                font.pixelSize: 9; font.family: ColorManager.fontFamily
                color: Qt.rgba(1, 1, 1, 0.32)
            }
            Text {
                anchors { right: parent.right; top: track.bottom; topMargin: 6 }
                text: root.fmtTime(root.songLen)
                font.pixelSize: 9; font.family: ColorManager.fontFamily
                color: Qt.rgba(1, 1, 1, 0.32)
            }

            MouseArea {
                id: scrubArea
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: mouse => {
                    const s = Math.round((mouse.x / width) * root.songLen)
                    root.position = s
                    ctlProc.command = ["playerctl", "position", String(s)]
                    ctlProc.running = true
                }
            }
        }

        // Controls
        Row {
            anchors { bottom: parent.bottom; bottomMargin: 16; horizontalCenter: parent.horizontalCenter }
            spacing: 20
            CtrlBtn { iconText: "⏮"; onClicked: root.send("previous") }
            CtrlBtn { iconText: root.playing ? "⏸" : "▶"; isMain: true; onClicked: root.send("play-pause") }
            CtrlBtn { iconText: "⏭"; onClicked: root.send("next") }
        }
    }

    component CtrlBtn: Item {
        property string iconText: ""
        property bool   isMain:  false
        signal clicked()

        width: isMain ? 42 : 30; height: width

        Rectangle {
            anchors.fill: parent; radius: width / 2
            color: parent.isMain
                ? Qt.rgba(root._accent.r, root._accent.g, root._accent.b, ma.containsMouse ? 0.20 : 0.13)
                : Qt.rgba(1, 1, 1, ma.containsMouse ? 0.07 : 0.035)
            border.width: 1
            border.color: parent.isMain
                ? Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.4)
                : Qt.rgba(1, 1, 1, 0.07)
            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }

        Text {
            anchors.centerIn: parent
            text: parent.iconText
            font.pixelSize: parent.isMain ? 15 : 11
            color: parent.isMain
                ? root._accent
                : (ma.containsMouse ? root._accent : Qt.rgba(1, 1, 1, 0.36))
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        scale: ma.pressed ? 0.88 : 1.0
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

        MouseArea {
            id: ma; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
