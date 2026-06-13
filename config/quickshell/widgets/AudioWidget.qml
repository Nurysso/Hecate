import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "../utils"

PanelWindow {
    id: root

    implicitWidth:  300
    implicitHeight: 320
    visible: true
    color: "transparent"
    mask: Region { item: container }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-audio"
    WlrLayershell.exclusiveZone: -1

    anchors { bottom: true; left: true }
    margins { bottom: 10; left: 10 }

    // Accent color  typed property forces .r/.g/.b availability in Canvas ──
    readonly property color _accent: ColorManager.accentColor
    readonly property int   ar255:   Math.round(_accent.r * 255)
    readonly property int   ag255:   Math.round(_accent.g * 255)
    readonly property int   ab255:   Math.round(_accent.b * 255)

    // Visualizer config
    readonly property int  barCount: 46
    readonly property real barW:     implicitWidth / barCount
    readonly property real vizH:     108   // bar drawing area height
    readonly property real reflH:    28    // reflection strip height

    // Media state
    property string songTitle: "—"
    property string artist:    ""
    property real   position:  0
    property real   songLen:   100
    property bool   playing:   false

    // Audio state
    property var bars:    []   // smoothed bar values 0–1
    property var peaks:   []   // peak-hold values
    property var peakAge: []   // frames since last peak update

    Component.onCompleted: {
        const b = [], p = [], pa = []
        for (let i = 0; i < barCount; i++) { b.push(0); p.push(0); pa.push(0) }
        bars = b; peaks = p; peakAge = pa
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
                const b = root.bars.slice(), p = root.peaks.slice(), pa = root.peakAge.slice()
                for (let i = 0; i < root.barCount; i++) {
                    const raw = parseInt(vals[i])
                    const v   = isNaN(raw) ? 0 : Math.min(raw / 100, 1)
                    b[i] = b[i] * 0.55 + v * 0.45          // exponential smoothing
                    if (b[i] >= p[i]) { p[i] = b[i]; pa[i] = 0 }
                    else { pa[i]++; if (pa[i] > 14) p[i] = Math.max(0, p[i] - 0.022) }
                }
                root.bars = b; root.peaks = p; root.peakAge = pa
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
                root.songTitle = p[0] || "—"
                root.artist    = p[1] || ""
                root.position  = parseInt(p[2]) / 1e6 || 0
                root.songLen   = Math.max(parseInt(p[3]) / 1e6 || 100, 1)
                root.playing   = p[4].trim() === "Playing"
            }
            vizCanvas.requestPaint()
        }
    }
    Timer { interval: 500; running: true; repeat: true; triggeredOnStart: true; onTriggered: mediaProc.running = true }
    Timer { interval: 1000; running: root.playing; repeat: true
        onTriggered: { root.position = Math.min(root.position + 1, root.songLen); vizCanvas.requestPaint() }
    }
    Process { id: ctlProc; running: false }

    // UI
    Item {
        id: container
        anchors.fill: parent

        // Glass card
        Rectangle {
            anchors.fill: parent; radius: 18
            color: Qt.rgba(0.04, 0.03, 0.08, 0.80)
            border.color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.22)
            border.width: 1
        }
        // Top accent stripe (inset from corners so it doesn't overflow radius)
        Rectangle {
            anchors { top: parent.top; topMargin: 1; left: parent.left; right: parent.right
                      leftMargin: 18; rightMargin: 18 }
            height: 1.5
            color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.6)
        }

        // Song info
        Item {
            id: infoRow
            anchors { top: parent.top; left: parent.left; right: parent.right
                      topMargin: 14; leftMargin: 16; rightMargin: 16 }
            height: 44

            // Pulsing status dot
            Rectangle {
                id: statusDot
                width: 6; height: 6; radius: 3
                anchors { left: parent.left; top: titleText.top; topMargin: 4 }
                color: root.playing ? root._accent : Qt.rgba(1, 1, 1, 0.18)
                Behavior on color { ColorAnimation { duration: 400 } }
                SequentialAnimation on scale {
                    running: root.playing; loops: Animation.Infinite
                    NumberAnimation { to: 1.7; duration: 750; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 750; easing.type: Easing.InOutSine }
                }
            }

            Text {
                id: titleText
                anchors { left: statusDot.right; right: parent.right; top: parent.top; leftMargin: 9 }
                text: root.songTitle; elide: Text.ElideRight
                font.pixelSize: 13; font.weight: Font.Medium
                font.family: ColorManager.fontFamily
                color: "#f0f0f0"
            }
            Text {
                anchors { left: titleText.left; right: parent.right; top: titleText.bottom; topMargin: 5 }
                text: root.artist; elide: Text.ElideRight
                visible: root.artist !== ""
                font.pixelSize: 10; font.family: ColorManager.fontFamily
                color: root._accent; opacity: 0.72
            }
        }

        // Visualizer
        Canvas {
            id: vizCanvas
            anchors { top: infoRow.bottom; left: parent.left; right: parent.right }
            height: root.vizH + root.reflH + 8

            onPaint: {
                const ctx   = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                const n     = root.barCount
                const bw    = root.barW
                const vh    = root.vizH
                const rh    = root.reflH
                const base  = vh             // y of the baseline
                const ar    = root.ar255
                const ag    = root.ag255
                const ab    = root.ab255
                const bars  = root.bars
                const peaks = root.peaks

                // Pass 1: soft glow (wide, very faint)
                for (let i = 0; i < n; i++) {
                    const v = bars[i]; if (v < 0.04) continue
                    const x = i * bw
                    const h = v * vh
                    ctx.fillStyle = `rgba(${ar},${ag},${ab},${(v * 0.06).toFixed(3)})`
                    ctx.fillRect(x - bw * 0.5, base - h * 1.05, bw * 2, h * 1.05)
                }

                // Pass 2: main bars (gradient, bottom-up)
                for (let i = 0; i < n; i++) {
                    const v = bars[i]; if (v < 0.008) continue
                    const x = i * bw
                    const h = v * vh
                    const y = base - h

                    const g = ctx.createLinearGradient(0, y, 0, base)
                    g.addColorStop(0,    `rgba(${ar},${ag},${ab},${Math.min(v * 1.05, 0.95).toFixed(3)})`)
                    g.addColorStop(0.5,  `rgba(${ar},${ag},${ab},${(v * 0.55).toFixed(3)})`)
                    g.addColorStop(1,    `rgba(${ar},${ag},${ab},0.06)`)
                    ctx.fillStyle = g
                    ctx.fillRect(x + 0.8, y, bw - 1.6, h)

                    // bright top cap (simulates bloom)
                    ctx.fillStyle = `rgba(255,255,255,${(v * 0.22).toFixed(3)})`
                    ctx.fillRect(x + 0.8, y, bw - 1.6, 1.5)
                }

                // Pass 3: peak bezier curve (glowing)
                ctx.save()
                ctx.shadowColor = `rgba(${ar},${ag},${ab},0.75)`
                ctx.shadowBlur  = 6
                ctx.strokeStyle = `rgba(${ar},${ag},${ab},0.9)`
                ctx.lineWidth   = 1.5
                ctx.beginPath()
                for (let i = 0; i < n; i++) {
                    const cx = i * bw + bw * 0.5
                    const cy = base - (peaks[i] || 0) * vh
                    if (i === 0) {
                        ctx.moveTo(cx, cy)
                    } else {
                        const px = (i - 1) * bw + bw * 0.5
                        const py = base - (peaks[i - 1] || 0) * vh
                        const mx = (px + cx) / 2
                        ctx.bezierCurveTo(mx, py, mx, cy, cx, cy)
                    }
                }
                ctx.stroke()
                ctx.restore()

                // Baseline
                ctx.strokeStyle = `rgba(${ar},${ag},${ab},0.20)`
                ctx.lineWidth   = 0.5
                ctx.beginPath(); ctx.moveTo(0, base); ctx.lineTo(width, base); ctx.stroke()

                // Pass 4: reflection bars
                for (let i = 0; i < n; i++) {
                    const v = bars[i]; if (v < 0.015) continue
                    const x = i * bw
                    const h = Math.min(v * vh * 0.30, rh)
                    ctx.fillStyle = `rgba(${ar},${ag},${ab},${(v * 0.12).toFixed(3)})`
                    ctx.fillRect(x + 0.8, base + 1, bw - 1.6, h)
                }

                // Fade reflection to transparent with destination-out
                ctx.save()
                ctx.globalCompositeOperation = "destination-out"
                const fade = ctx.createLinearGradient(0, base, 0, base + rh)
                fade.addColorStop(0,   "rgba(0,0,0,0)")
                fade.addColorStop(0.5, "rgba(0,0,0,0.4)")
                fade.addColorStop(1,   "rgba(0,0,0,1)")
                ctx.fillStyle = fade
                ctx.fillRect(0, base, width, rh)
                ctx.restore()
            }
        }

        // Progress
        Item {
            id: progressItem
            anchors {
                top: vizCanvas.bottom; topMargin: 4
                left: parent.left; right: parent.right
                leftMargin: 16; rightMargin: 16
            }
            height: 24

            Rectangle {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                anchors.verticalCenterOffset: -5
                height: 2; radius: 1
                color: Qt.rgba(1, 1, 1, 0.07)

                Rectangle {
                    width: root.songLen > 0
                        ? parent.width * Math.min(root.position / root.songLen, 1.0) : 0
                    height: 2; radius: 1
                    color: root._accent
                    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.Linear } }

                    // Scrub dot + ring
                    Rectangle {
                        width: 9; height: 9; radius: 4.5
                        color: root._accent
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        anchors.rightMargin: -4.5
                        Rectangle {
                            anchors.centerIn: parent
                            width: 15; height: 15; radius: 7.5
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.38)
                        }
                    }
                }
            }

            Text {
                anchors { left: parent.left; bottom: parent.bottom }
                text: root.fmtTime(root.position)
                font.pixelSize: 9; font.family: ColorManager.fontFamily
                color: Qt.rgba(1, 1, 1, 0.28)
            }
            Text {
                anchors { right: parent.right; bottom: parent.bottom }
                text: root.fmtTime(root.songLen)
                font.pixelSize: 9; font.family: ColorManager.fontFamily
                color: Qt.rgba(1, 1, 1, 0.28)
            }

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
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
            anchors { bottom: parent.bottom; bottomMargin: 14; horizontalCenter: parent.horizontalCenter }
            spacing: 18
            CtrlBtn { iconText: "⏮"; onClicked: root.send("previous") }
            CtrlBtn { iconText: root.playing ? "⏸" : "▶"; isMain: true; onClicked: root.send("play-pause") }
            CtrlBtn { iconText: "⏭"; onClicked: root.send("next") }
        }
    }

    // CtrlBtn
    component CtrlBtn: Item {
        property string iconText: ""
        property bool   isMain:  false
        signal clicked()

        width: isMain ? 44 : 32; height: width

        Rectangle {
            anchors.fill: parent; radius: width / 2
            color: parent.isMain
                ? Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.14)
                : Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: parent.isMain
                ? Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.45)
                : Qt.rgba(1, 1, 1, 0.08)
        }

        // Breathing pulse ring (only when playing, only on main button)
        Rectangle {
            visible: parent.isMain && root.playing
            width: parent.width + 12; height: parent.height + 12
            radius: width / 2
            anchors.centerIn: parent
            color: "transparent"
            border.width: 1.5
            border.color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b, 0.6)
            SequentialAnimation on opacity {
                running: parent.visible; loops: Animation.Infinite
                NumberAnimation { to: 0.06; duration: 1100; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.75; duration: 1100; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on scale {
                running: parent.visible; loops: Animation.Infinite
                NumberAnimation { to: 1.14; duration: 1100; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0;  duration: 1100; easing.type: Easing.InOutSine }
            }
        }

        Text {
            anchors.centerIn: parent
            text: parent.iconText
            font.pixelSize: parent.isMain ? 16 : 12
            color: parent.isMain
                ? root._accent
                : (ma.containsMouse ? root._accent : Qt.rgba(1, 1, 1, 0.38))
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        scale: ma.pressed ? 0.87 : 1.0
        Behavior on scale { NumberAnimation { duration: 75; easing.type: Easing.OutCubic } }

        MouseArea {
            id: ma; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
